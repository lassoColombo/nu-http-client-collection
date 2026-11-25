# Auto-generated client for EC2 Image Builder v2019-12-02
# Source: https://api.apis.guru/v2/specs/amazonaws.com/imagebuilder/2019-12-02/openapi.json
# Auth: --token flag or $env.EC2_IMAGE_BUILDER_TOKEN

const CLIENT = {
  base_url: "http://imagebuilder.us-east-1.amazonaws.com"
  token_env_var: "EC2_IMAGE_BUILDER_TOKEN"
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

def base-url-completer [] { ["http://imagebuilder.us-east-1.amazonaws.com" "http://imagebuilder.us-east-2.amazonaws.com" "http://imagebuilder.us-west-1.amazonaws.com" "http://imagebuilder.us-west-2.amazonaws.com" "http://imagebuilder.us-gov-west-1.amazonaws.com" "http://imagebuilder.us-gov-east-1.amazonaws.com" "http://imagebuilder.ca-central-1.amazonaws.com" "http://imagebuilder.eu-north-1.amazonaws.com" "http://imagebuilder.eu-west-1.amazonaws.com" "http://imagebuilder.eu-west-2.amazonaws.com" "http://imagebuilder.eu-west-3.amazonaws.com" "http://imagebuilder.eu-central-1.amazonaws.com" "http://imagebuilder.eu-south-1.amazonaws.com" "http://imagebuilder.af-south-1.amazonaws.com" "http://imagebuilder.ap-northeast-1.amazonaws.com" "http://imagebuilder.ap-northeast-2.amazonaws.com" "http://imagebuilder.ap-northeast-3.amazonaws.com" "http://imagebuilder.ap-southeast-1.amazonaws.com" "http://imagebuilder.ap-southeast-2.amazonaws.com" "http://imagebuilder.ap-east-1.amazonaws.com" "http://imagebuilder.ap-south-1.amazonaws.com" "http://imagebuilder.sa-east-1.amazonaws.com" "http://imagebuilder.me-south-1.amazonaws.com" "https://imagebuilder.us-east-1.amazonaws.com" "https://imagebuilder.us-east-2.amazonaws.com" "https://imagebuilder.us-west-1.amazonaws.com" "https://imagebuilder.us-west-2.amazonaws.com" "https://imagebuilder.us-gov-west-1.amazonaws.com" "https://imagebuilder.us-gov-east-1.amazonaws.com" "https://imagebuilder.ca-central-1.amazonaws.com" "https://imagebuilder.eu-north-1.amazonaws.com" "https://imagebuilder.eu-west-1.amazonaws.com" "https://imagebuilder.eu-west-2.amazonaws.com" "https://imagebuilder.eu-west-3.amazonaws.com" "https://imagebuilder.eu-central-1.amazonaws.com" "https://imagebuilder.eu-south-1.amazonaws.com" "https://imagebuilder.af-south-1.amazonaws.com" "https://imagebuilder.ap-northeast-1.amazonaws.com" "https://imagebuilder.ap-northeast-2.amazonaws.com" "https://imagebuilder.ap-northeast-3.amazonaws.com" "https://imagebuilder.ap-southeast-1.amazonaws.com" "https://imagebuilder.ap-southeast-2.amazonaws.com" "https://imagebuilder.ap-east-1.amazonaws.com" "https://imagebuilder.ap-south-1.amazonaws.com" "https://imagebuilder.sa-east-1.amazonaws.com" "https://imagebuilder.me-south-1.amazonaws.com" "http://imagebuilder.cn-north-1.amazonaws.com.cn" "http://imagebuilder.cn-northwest-1.amazonaws.com.cn" "https://imagebuilder.cn-north-1.amazonaws.com.cn" "https://imagebuilder.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def platform-completer [] { ["Linux" "Windows"] }
def container-type-completer [] { ["DOCKER"] }
def platform-override-completer [] { ["Linux" "Windows"] }
def status-completer [] { ["DISABLED" "ENABLED"] }
def type-completer [] { ["BUILD" "TEST"] }
def format-completer [] { ["SHELL"] }
def owner-completer [] { ["Amazon" "Self" "Shared" "ThirdParty"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    cancel-image-creation: "record<requestId: string, clientToken: string, imageBuildVersionArn: string>"
    create-component: "record<requestId: string, clientToken: string, componentBuildVersionArn: string>"
    create-container-recipe: "record<requestId: string, clientToken: string, containerRecipeArn: string>"
    create-distribution-configuration: "record<requestId: string, clientToken: string, distributionConfigurationArn: string>"
    create-image: "record<requestId: string, clientToken: string, imageBuildVersionArn: string>"
    create-image-pipeline: "record<requestId: string, clientToken: string, imagePipelineArn: string>"
    create-image-recipe: "record<requestId: string, clientToken: string, imageRecipeArn: string>"
    create-infrastructure-configuration: "record<requestId: string, clientToken: string, infrastructureConfigurationArn: string>"
    delete-component: "record<requestId: string, componentBuildVersionArn: string>"
    delete-container-recipe: "record<requestId: string, containerRecipeArn: string>"
    delete-distribution-configuration: "record<requestId: string, distributionConfigurationArn: string>"
    delete-image: "record<requestId: string, imageBuildVersionArn: string>"
    delete-image-pipeline: "record<requestId: string, imagePipelineArn: string>"
    delete-image-recipe: "record<requestId: string, imageRecipeArn: string>"
    delete-infrastructure-configuration: "record<requestId: string, infrastructureConfigurationArn: string>"
    get-component: "record<requestId: string, component: record<arn: string, name: string, version: string, description: string, changeDescription: string, type: string, platform: string, supportedOsVersions: list<string>, state: record<status: string, reason: string>, parameters: list<record>, owner: string, data: string, kmsKeyId: string, encrypted: bool, dateCreated: string, tags: record, publisher: string, obfuscate: bool>>"
    get-component-policy: "record<requestId: string, policy: string>"
    get-container-recipe: "record<requestId: string, containerRecipe: record<arn: string, containerType: string, name: string, description: string, platform: string, owner: string, version: string, components: list<record>, instanceConfiguration: record<image: string, blockDeviceMappings: list>, dockerfileTemplateData: string, kmsKeyId: string, encrypted: bool, parentImage: string, dateCreated: string, tags: record, workingDirectory: string, targetRepository: record<service: string, repositoryName: string>>>"
    get-container-recipe-policy: "record<requestId: string, policy: string>"
    get-distribution-configuration: "record<requestId: string, distributionConfiguration: record<arn: string, name: string, description: string, distributions: list<record>, timeoutMinutes: int, dateCreated: string, dateUpdated: string, tags: record>>"
    get-image: "record<requestId: string, image: record<arn: string, type: string, name: string, version: string, platform: string, enhancedImageMetadataEnabled: bool, osVersion: string, state: record<status: string, reason: string>, imageRecipe: record<arn: string, type: string, name: string, description: string, platform: string, owner: string, version: string, components: list, parentImage: string, blockDeviceMappings: list, dateCreated: string, tags: record, workingDirectory: string, additionalInstanceConfiguration: record>, containerRecipe: record<arn: string, containerType: string, name: string, description: string, platform: string, owner: string, version: string, components: list, instanceConfiguration: record, dockerfileTemplateData: string, kmsKeyId: string, encrypted: bool, parentImage: string, dateCreated: string, tags: record, workingDirectory: string, targetRepository: record>, sourcePipelineName: string, sourcePipelineArn: string, infrastructureConfiguration: record<arn: string, name: string, description: string, instanceTypes: list, instanceProfileName: string, securityGroupIds: list, subnetId: string, logging: record, keyPair: string, terminateInstanceOnFailure: bool, snsTopicArn: string, dateCreated: string, dateUpdated: string, resourceTags: record, instanceMetadataOptions: record, tags: record>, distributionConfiguration: record<arn: string, name: string, description: string, distributions: list, timeoutMinutes: int, dateCreated: string, dateUpdated: string, tags: record>, imageTestsConfiguration: record<imageTestsEnabled: bool, timeoutMinutes: int>, dateCreated: string, outputResources: record<amis: list, containers: list>, tags: record, buildType: string, imageSource: string, scanState: record<status: string, reason: string>, imageScanningConfiguration: record<imageScanningEnabled: bool, ecrConfiguration: record>>>"
    get-image-pipeline: "record<requestId: string, imagePipeline: record<arn: string, name: string, description: string, platform: string, enhancedImageMetadataEnabled: bool, imageRecipeArn: string, containerRecipeArn: string, infrastructureConfigurationArn: string, distributionConfigurationArn: string, imageTestsConfiguration: record<imageTestsEnabled: bool, timeoutMinutes: int>, schedule: record<scheduleExpression: string, timezone: string, pipelineExecutionStartCondition: string>, status: string, dateCreated: string, dateUpdated: string, dateLastRun: string, dateNextRun: string, tags: record, imageScanningConfiguration: record<imageScanningEnabled: bool, ecrConfiguration: record>>>"
    get-image-policy: "record<requestId: string, policy: string>"
    get-image-recipe: "record<requestId: string, imageRecipe: record<arn: string, type: string, name: string, description: string, platform: string, owner: string, version: string, components: list<record>, parentImage: string, blockDeviceMappings: list<record>, dateCreated: string, tags: record, workingDirectory: string, additionalInstanceConfiguration: record<systemsManagerAgent: record, userDataOverride: string>>>"
    get-image-recipe-policy: "record<requestId: string, policy: string>"
    get-infrastructure-configuration: "record<requestId: string, infrastructureConfiguration: record<arn: string, name: string, description: string, instanceTypes: list<string>, instanceProfileName: string, securityGroupIds: list<string>, subnetId: string, logging: record<s3Logs: record>, keyPair: string, terminateInstanceOnFailure: bool, snsTopicArn: string, dateCreated: string, dateUpdated: string, resourceTags: record, instanceMetadataOptions: record<httpTokens: string, httpPutResponseHopLimit: int>, tags: record>>"
    get-workflow-execution: "record<requestId: string, workflowBuildVersionArn: string, workflowExecutionId: string, imageBuildVersionArn: string, type: string, status: string, message: string, totalStepCount: int, totalStepsSucceeded: int, totalStepsFailed: int, totalStepsSkipped: int, startTime: string, endTime: string>"
    get-workflow-step-execution: "record<requestId: string, stepExecutionId: string, workflowBuildVersionArn: string, workflowExecutionId: string, imageBuildVersionArn: string, name: string, description: string, action: string, status: string, rollbackStatus: string, message: string, inputs: string, outputs: string, startTime: string, endTime: string, onFailure: string, timeoutSeconds: int>"
    import-component: "record<requestId: string, clientToken: string, componentBuildVersionArn: string>"
    import-vm-image: "record<requestId: string, imageArn: string, clientToken: string>"
    list-component-build-versions: "record<requestId: string, componentSummaryList: table<arn: string, name: string, version: string, platform: string, supportedOsVersions: list, state: record, type: string, owner: string, description: string, changeDescription: string, dateCreated: string, tags: record, publisher: string, obfuscate: bool>, nextToken: string>"
    list-components: "record<requestId: string, componentVersionList: table<arn: string, name: string, version: string, description: string, platform: string, supportedOsVersions: list, type: string, owner: string, dateCreated: string>, nextToken: string>"
    list-container-recipes: "record<requestId: string, containerRecipeSummaryList: table<arn: string, containerType: string, name: string, platform: string, owner: string, parentImage: string, dateCreated: string, tags: record>, nextToken: string>"
    list-distribution-configurations: "record<requestId: string, distributionConfigurationSummaryList: table<arn: string, name: string, description: string, dateCreated: string, dateUpdated: string, tags: record, regions: list>, nextToken: string>"
    list-image-build-versions: "record<requestId: string, imageSummaryList: table<arn: string, name: string, type: string, version: string, platform: string, osVersion: string, state: record, owner: string, dateCreated: string, outputResources: record, tags: record, buildType: string, imageSource: string>, nextToken: string>"
    list-image-packages: "record<requestId: string, imagePackageList: table<packageName: string, packageVersion: string>, nextToken: string>"
    list-image-pipeline-images: "record<requestId: string, imageSummaryList: table<arn: string, name: string, type: string, version: string, platform: string, osVersion: string, state: record, owner: string, dateCreated: string, outputResources: record, tags: record, buildType: string, imageSource: string>, nextToken: string>"
    list-image-pipelines: "record<requestId: string, imagePipelineList: table<arn: string, name: string, description: string, platform: string, enhancedImageMetadataEnabled: bool, imageRecipeArn: string, containerRecipeArn: string, infrastructureConfigurationArn: string, distributionConfigurationArn: string, imageTestsConfiguration: record, schedule: record, status: string, dateCreated: string, dateUpdated: string, dateLastRun: string, dateNextRun: string, tags: record, imageScanningConfiguration: record>, nextToken: string>"
    list-image-recipes: "record<requestId: string, imageRecipeSummaryList: table<arn: string, name: string, platform: string, owner: string, parentImage: string, dateCreated: string, tags: record>, nextToken: string>"
    list-image-scan-finding-aggregations: "record<requestId: string, aggregationType: string, responses: table<accountAggregation: record, imageAggregation: record, imagePipelineAggregation: record, vulnerabilityIdAggregation: record>, nextToken: string>"
    list-image-scan-findings: "record<requestId: string, findings: table<awsAccountId: string, imageBuildVersionArn: string, imagePipelineArn: string, type: string, description: string, title: string, remediation: record, severity: string, firstObservedAt: string, updatedAt: string, inspectorScore: float, inspectorScoreDetails: record, packageVulnerabilityDetails: record, fixAvailable: string>, nextToken: string>"
    list-images: "record<requestId: string, imageVersionList: table<arn: string, name: string, type: string, version: string, platform: string, osVersion: string, owner: string, dateCreated: string, buildType: string, imageSource: string>, nextToken: string>"
    list-infrastructure-configurations: "record<requestId: string, infrastructureConfigurationSummaryList: table<arn: string, name: string, description: string, dateCreated: string, dateUpdated: string, resourceTags: record, tags: record, instanceTypes: list, instanceProfileName: string>, nextToken: string>"
    list-tags-for-resource: "record<tags: record>"
    tag-resource: "record"
    list-workflow-executions: "record<requestId: string, workflowExecutions: table<workflowBuildVersionArn: string, workflowExecutionId: string, type: string, status: string, message: string, totalStepCount: int, totalStepsSucceeded: int, totalStepsFailed: int, totalStepsSkipped: int, startTime: string, endTime: string>, imageBuildVersionArn: string, message: string, nextToken: string>"
    list-workflow-step-executions: "record<requestId: string, steps: table<stepExecutionId: string, name: string, description: string, action: string, status: string, rollbackStatus: string, message: string, inputs: string, outputs: string, startTime: string, endTime: string>, workflowBuildVersionArn: string, workflowExecutionId: string, imageBuildVersionArn: string, message: string, nextToken: string>"
    put-component-policy: "record<requestId: string, componentArn: string>"
    put-container-recipe-policy: "record<requestId: string, containerRecipeArn: string>"
    put-image-policy: "record<requestId: string, imageArn: string>"
    put-image-recipe-policy: "record<requestId: string, imageRecipeArn: string>"
    start-image-pipeline-execution: "record<requestId: string, clientToken: string, imageBuildVersionArn: string>"
    untag-resource: "record"
    update-distribution-configuration: "record<requestId: string, clientToken: string, distributionConfigurationArn: string>"
    update-image-pipeline: "record<requestId: string, clientToken: string, imagePipelineArn: string>"
    update-infrastructure-configuration: "record<requestId: string, clientToken: string, infrastructureConfigurationArn: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["cancel-image-creation" "create-component" "create-container-recipe" "create-distribution-configuration" "create-image" "create-image-pipeline" "create-image-recipe" "create-infrastructure-configuration" "delete-component" "delete-container-recipe" "delete-distribution-configuration" "delete-image" "delete-image-pipeline" "delete-image-recipe" "delete-infrastructure-configuration" "get-component" "get-component-policy" "get-container-recipe" "get-container-recipe-policy" "get-distribution-configuration" "get-image" "get-image-pipeline" "get-image-policy" "get-image-recipe" "get-image-recipe-policy" "get-infrastructure-configuration" "get-workflow-execution" "get-workflow-step-execution" "import-component" "import-vm-image" "list-component-build-versions" "list-components" "list-container-recipes" "list-distribution-configurations" "list-image-build-versions" "list-image-packages" "list-image-pipeline-images" "list-image-pipelines" "list-image-recipes" "list-image-scan-finding-aggregations" "list-image-scan-findings" "list-images" "list-infrastructure-configurations" "list-tags-for-resource" "tag-resource" "list-workflow-executions" "list-workflow-step-executions" "put-component-policy" "put-container-recipe-policy" "put-image-policy" "put-image-recipe-policy" "start-image-pipeline-execution" "untag-resource" "update-distribution-configuration" "update-image-pipeline" "update-infrastructure-configuration" "commands"] | sort) } | get name | first)
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

# CancelImageCreation cancels the creation of Image. This operation can only be used on images in a non-terminal state.
#
# PUT /CancelImageCreation
# Returns: record<requestId: string, clientToken: string, imageBuildVersionArn: string>
# operationId: CancelImageCreation
export def "cancel-image-creation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  image_build_version_arn: string # The Amazon Resource Name (ARN) of the image that you want to cancel creation for.
  client_token: string # Unique, case-sensitive identifier you provide to ensure idempotency of the request. For more information, see Ensuring idempotency (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/Run_Instance_Idempotency.html) in the Amazon EC2 API Reference.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/CancelImageCreation"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: imageBuildVersionArn, var: image_build_version_arn}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, image_build_version_arn: $image_build_version_arn, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new component that can be used to build, validate, test, and assess your image. The component is based on a YAML document that you specify using exactly one of the following methods: Inline, using the data property in the request body. A URL that points to a YAML document file stored in Amazon S3, using the uri property in the request body.
#
# PUT /CreateComponent
# Returns: record<requestId: string, clientToken: string, componentBuildVersionArn: string>
# operationId: CreateComponent
export def "create-component" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # The name of the component.
  semantic_version: string # The semantic version of the component. This version follows the semantic version syntax. The semantic version has four nodes: <major>.<minor>.<patch>/<build>. You can assign values for the first three, and can filter on all of them. Assignment: For the first three nodes you can assign any positive integer value, including zero, with an upper limit of 2^30-1, or 1073741823 for each node. Image Builder automatically assigns the build number to the fourth node. Patterns: You can use any numeric pattern that adheres to the assignment requirements for the nodes that you can assign. For example, you might choose a software version pattern, such as 1.0.0, or a date, such as 2021.01.01.
  --description: string # Describes the contents of the component.
  --change-description: string # The change description of the component. Describes what change has been made in this version, or what makes this version different from other versions of this component.
  platform: string@platform-completer # The operating system platform of the component.
  --supported-os-versions: list<string> # The operating system (OS) version supported by the component. If the OS information is available, a prefix match is performed against the base image OS version during image recipe creation.
  --data: string # Component data contains inline YAML document content for the component. Alternatively, you can specify the uri of a YAML document file stored in Amazon S3. However, you cannot specify both properties.
  --uri: string # The uri of a YAML component document file. This must be an S3 URL (s3://bucket/key), and the requester must have permission to access the S3 bucket it points to. If you use Amazon S3, you can specify component content up to your service quota. Alternatively, you can specify the YAML document inline, using the component data property. You cannot specify both properties.
  --kms-key-id: string # The ID of the KMS key that is used to encrypt this component.
  --tags: record # The tags that apply to the component.
  client_token: string # The idempotency token of the component.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/CreateComponent"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: semanticVersion, var: semantic_version}, {name: description, var: description}, {name: changeDescription, var: change_description}, {name: platform, var: platform}, {name: supportedOsVersions, var: supported_os_versions}, {name: data, var: data}, {name: uri, var: uri}, {name: kmsKeyId, var: kms_key_id}, {name: tags, var: tags}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, semantic_version: $semantic_version, description: $description, change_description: $change_description, platform: $platform, supported_os_versions: $supported_os_versions, data: $data, uri: $uri, kms_key_id: $kms_key_id, tags: $tags, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new container recipe. Container recipes define how images are configured, tested, and assessed.
#
# PUT /CreateContainerRecipe
# Returns: record<requestId: string, clientToken: string, containerRecipeArn: string>
# operationId: CreateContainerRecipe
export def "create-container-recipe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  container_type: string@container-type-completer # The type of container to create.
  name: string # The name of the container recipe.
  --description: string # The description of the container recipe.
  semantic_version: string # The semantic version of the container recipe. This version follows the semantic version syntax. The semantic version has four nodes: <major>.<minor>.<patch>/<build>. You can assign values for the first three, and can filter on all of them. Assignment: For the first three nodes you can assign any positive integer value, including zero, with an upper limit of 2^30-1, or 1073741823 for each node. Image Builder automatically assigns the build number to the fourth node. Patterns: You can use any numeric pattern that adheres to the assignment requirements for the nodes that you can assign. For example, you might choose a software version pattern, such as 1.0.0, or a date, such as 2021.01.01.
  components: list # Components for build and test that are included in the container recipe. Recipes require a minimum of one build component, and can have a maximum of 20 build and test components in any combination. — item shape: {componentArn: string, parameters?: list}
  --instance-configuration: record # Defines a custom base AMI and block device mapping configurations of an instance used for building and testing container images. — shape: {image?: string, blockDeviceMappings?: list}
  --dockerfile-template-data: string # The Dockerfile template used to build your image as an inline data blob.
  --dockerfile-template-uri: string # The Amazon S3 URI for the Dockerfile that will be used to build your container image.
  --platform-override: string@platform-override-completer # Specifies the operating system platform when you use a custom base image.
  --image-os-version-override: string # Specifies the operating system version for the base image.
  parent_image: string # The base image for the container recipe.
  --tags: record # Tags that are attached to the container recipe.
  --working-directory: string # The working directory for use during build and test workflows.
  target_repository: record # The container repository where the output container image is stored. — shape: {service?: "ECR", repositoryName?: string}
  --kms-key-id: string # Identifies which KMS key is used to encrypt the container image.
  client_token: string # The client token used to make this request idempotent.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/CreateContainerRecipe"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: containerType, var: container_type}, {name: name, var: name}, {name: description, var: description}, {name: semanticVersion, var: semantic_version}, {name: components, var: components}, {name: instanceConfiguration, var: instance_configuration}, {name: dockerfileTemplateData, var: dockerfile_template_data}, {name: dockerfileTemplateUri, var: dockerfile_template_uri}, {name: platformOverride, var: platform_override}, {name: imageOsVersionOverride, var: image_os_version_override}, {name: parentImage, var: parent_image}, {name: tags, var: tags}, {name: workingDirectory, var: working_directory}, {name: targetRepository, var: target_repository}, {name: kmsKeyId, var: kms_key_id}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, container_type: $container_type, name: $name, description: $description, semantic_version: $semantic_version, components: $components, instance_configuration: $instance_configuration, dockerfile_template_data: $dockerfile_template_data, dockerfile_template_uri: $dockerfile_template_uri, platform_override: $platform_override, image_os_version_override: $image_os_version_override, parent_image: $parent_image, tags: $tags, working_directory: $working_directory, target_repository: $target_repository, kms_key_id: $kms_key_id, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new distribution configuration. Distribution configurations define and configure the outputs of your pipeline.
#
# PUT /CreateDistributionConfiguration
# Returns: record<requestId: string, clientToken: string, distributionConfigurationArn: string>
# operationId: CreateDistributionConfiguration
export def "create-distribution-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # The name of the distribution configuration.
  --description: string # The description of the distribution configuration.
  distributions: list # The distributions of the distribution configuration. — item shape: {region: string, amiDistributionConfiguration?: record, containerDistributionConfiguration?: record, licenseConfigurationArns?: list<string>, launchTemplateConfigurations?: list, s3ExportConfiguration?: record, fastLaunchConfigurations?: list}
  --tags: record # The tags of the distribution configuration.
  client_token: string # The idempotency token of the distribution configuration.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/CreateDistributionConfiguration"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: description, var: description}, {name: distributions, var: distributions}, {name: tags, var: tags}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, distributions: $distributions, tags: $tags, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new image. This request will create a new image along with all of the configured output resources defined in the distribution configuration. You must specify exactly one recipe for your image, using either a ContainerRecipeArn or an ImageRecipeArn.
#
# PUT /CreateImage
# Returns: record<requestId: string, clientToken: string, imageBuildVersionArn: string>
# operationId: CreateImage
export def "create-image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --image-recipe-arn: string # The Amazon Resource Name (ARN) of the image recipe that defines how images are configured, tested, and assessed.
  --container-recipe-arn: string # The Amazon Resource Name (ARN) of the container recipe that defines how images are configured and tested.
  --distribution-configuration-arn: string # The Amazon Resource Name (ARN) of the distribution configuration that defines and configures the outputs of your pipeline.
  infrastructure_configuration_arn: string # The Amazon Resource Name (ARN) of the infrastructure configuration that defines the environment in which your image will be built and tested.
  --image-tests-configuration: record # Configure image tests for your pipeline build. Tests run after building the image, to verify that the AMI or container image is valid before distributing it. — shape: {imageTestsEnabled?: bool, timeoutMinutes?: int}
  --enhanced-image-metadata-enabled: oneof<nothing, bool> # Collects additional information about the image being created, including the operating system (OS) version and package list. This information is used to enhance the overall experience of using EC2 Image Builder. Enabled by default.
  --tags: record # The tags of the image.
  client_token: string # The idempotency token used to make this request idempotent.
  --image-scanning-configuration: record # Contains settings for Image Builder image resource and container image scans. — shape: {imageScanningEnabled?: bool, ecrConfiguration?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/CreateImage"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: imageRecipeArn, var: image_recipe_arn}, {name: containerRecipeArn, var: container_recipe_arn}, {name: distributionConfigurationArn, var: distribution_configuration_arn}, {name: infrastructureConfigurationArn, var: infrastructure_configuration_arn}, {name: imageTestsConfiguration, var: image_tests_configuration}, {name: enhancedImageMetadataEnabled, var: enhanced_image_metadata_enabled}, {name: tags, var: tags}, {name: clientToken, var: client_token}, {name: imageScanningConfiguration, var: image_scanning_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, image_recipe_arn: $image_recipe_arn, container_recipe_arn: $container_recipe_arn, distribution_configuration_arn: $distribution_configuration_arn, infrastructure_configuration_arn: $infrastructure_configuration_arn, image_tests_configuration: $image_tests_configuration, enhanced_image_metadata_enabled: $enhanced_image_metadata_enabled, tags: $tags, client_token: $client_token, image_scanning_configuration: $image_scanning_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new image pipeline. Image pipelines enable you to automate the creation and distribution of images.
#
# PUT /CreateImagePipeline
# Returns: record<requestId: string, clientToken: string, imagePipelineArn: string>
# operationId: CreateImagePipeline
export def "create-image-pipeline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # The name of the image pipeline.
  --description: string # The description of the image pipeline.
  --image-recipe-arn: string # The Amazon Resource Name (ARN) of the image recipe that will be used to configure images created by this image pipeline.
  --container-recipe-arn: string # The Amazon Resource Name (ARN) of the container recipe that is used to configure images created by this container pipeline.
  infrastructure_configuration_arn: string # The Amazon Resource Name (ARN) of the infrastructure configuration that will be used to build images created by this image pipeline.
  --distribution-configuration-arn: string # The Amazon Resource Name (ARN) of the distribution configuration that will be used to configure and distribute images created by this image pipeline.
  --image-tests-configuration: record # Configure image tests for your pipeline build. Tests run after building the image, to verify that the AMI or container image is valid before distributing it. — shape: {imageTestsEnabled?: bool, timeoutMinutes?: int}
  --enhanced-image-metadata-enabled: oneof<nothing, bool> # Collects additional information about the image being created, including the operating system (OS) version and package list. This information is used to enhance the overall experience of using EC2 Image Builder. Enabled by default.
  --schedule: record # A schedule configures how often and when a pipeline will automatically create a new image. — shape: {scheduleExpression?: string, timezone?: string, pipelineExecutionStartCondition?: "EXPRESSION_MATCH_ONLY"|"EXPRESSION_MATCH_AND_DEPENDENCY_UPDATES_AVAILABLE"}
  --status: string@status-completer # The status of the image pipeline.
  --tags: record # The tags of the image pipeline.
  client_token: string # The idempotency token used to make this request idempotent.
  --image-scanning-configuration: record # Contains settings for Image Builder image resource and container image scans. — shape: {imageScanningEnabled?: bool, ecrConfiguration?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/CreateImagePipeline"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: description, var: description}, {name: imageRecipeArn, var: image_recipe_arn}, {name: containerRecipeArn, var: container_recipe_arn}, {name: infrastructureConfigurationArn, var: infrastructure_configuration_arn}, {name: distributionConfigurationArn, var: distribution_configuration_arn}, {name: imageTestsConfiguration, var: image_tests_configuration}, {name: enhancedImageMetadataEnabled, var: enhanced_image_metadata_enabled}, {name: schedule, var: schedule}, {name: status, var: status}, {name: tags, var: tags}, {name: clientToken, var: client_token}, {name: imageScanningConfiguration, var: image_scanning_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, image_recipe_arn: $image_recipe_arn, container_recipe_arn: $container_recipe_arn, infrastructure_configuration_arn: $infrastructure_configuration_arn, distribution_configuration_arn: $distribution_configuration_arn, image_tests_configuration: $image_tests_configuration, enhanced_image_metadata_enabled: $enhanced_image_metadata_enabled, schedule: $schedule, status: $status, tags: $tags, client_token: $client_token, image_scanning_configuration: $image_scanning_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new image recipe. Image recipes define how images are configured, tested, and assessed.
#
# PUT /CreateImageRecipe
# Returns: record<requestId: string, clientToken: string, imageRecipeArn: string>
# operationId: CreateImageRecipe
export def "create-image-recipe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # The name of the image recipe.
  --description: string # The description of the image recipe.
  semantic_version: string # The semantic version of the image recipe. This version follows the semantic version syntax. The semantic version has four nodes: <major>.<minor>.<patch>/<build>. You can assign values for the first three, and can filter on all of them. Assignment: For the first three nodes you can assign any positive integer value, including zero, with an upper limit of 2^30-1, or 1073741823 for each node. Image Builder automatically assigns the build number to the fourth node. Patterns: You can use any numeric pattern that adheres to the assignment requirements for the nodes that you can assign. For example, you might choose a software version pattern, such as 1.0.0, or a date, such as 2021.01.01.
  components: list # The components included in the image recipe. — item shape: {componentArn: string, parameters?: list}
  parent_image: string # The base image of the image recipe. The value of the string can be the ARN of the base image or an AMI ID. The format for the ARN follows this example: arn:aws:imagebuilder:us-west-2:aws:image/windows-server-2016-english-full-base-x86/x.x.x. You can provide the specific version that you want to use, or you can use a wildcard in all of the fields. If you enter an AMI ID for the string value, you must have access to the AMI, and the AMI must be in the same Region in which you are using Image Builder.
  --block-device-mappings: list # The block device mappings of the image recipe. — item shape: {deviceName?: string, ebs?: record, virtualName?: string, noDevice?: string}
  --tags: record # The tags of the image recipe.
  --working-directory: string # The working directory used during build and test workflows.
  --additional-instance-configuration: record # In addition to your infrastructure configuration, these settings provide an extra layer of control over your build instances. You can also specify commands to run on launch for all of your build instances. Image Builder does not automatically install the Systems Manager agent on Windows instances. If your base image includes the Systems Manager agent, then the AMI that you create will also include the agent. For Linux instances, if the base image does not already include the Systems Manager agent, Image Builder installs it. For Linux instances where Image Builder installs the Systems Manager agent, you can choose whether to keep it for the AMI that you create. — shape: {systemsManagerAgent?: record, userDataOverride?: string}
  client_token: string # The idempotency token used to make this request idempotent.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/CreateImageRecipe"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: description, var: description}, {name: semanticVersion, var: semantic_version}, {name: components, var: components}, {name: parentImage, var: parent_image}, {name: blockDeviceMappings, var: block_device_mappings}, {name: tags, var: tags}, {name: workingDirectory, var: working_directory}, {name: additionalInstanceConfiguration, var: additional_instance_configuration}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, semantic_version: $semantic_version, components: $components, parent_image: $parent_image, block_device_mappings: $block_device_mappings, tags: $tags, working_directory: $working_directory, additional_instance_configuration: $additional_instance_configuration, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new infrastructure configuration. An infrastructure configuration defines the environment in which your image will be built and tested.
#
# PUT /CreateInfrastructureConfiguration
# Returns: record<requestId: string, clientToken: string, infrastructureConfigurationArn: string>
# operationId: CreateInfrastructureConfiguration
export def "create-infrastructure-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # The name of the infrastructure configuration.
  --description: string # The description of the infrastructure configuration.
  --instance-types: list<string> # The instance types of the infrastructure configuration. You can specify one or more instance types to use for this build. The service will pick one of these instance types based on availability.
  instance_profile_name: string # The instance profile to associate with the instance used to customize your Amazon EC2 AMI.
  --security-group-ids: list<string> # The security group IDs to associate with the instance used to customize your Amazon EC2 AMI.
  --subnet-id: string # The subnet ID in which to place the instance used to customize your Amazon EC2 AMI.
  --logging: record # Logging configuration defines where Image Builder uploads your logs. — shape: {s3Logs?: record}
  --key-pair: string # The key pair of the infrastructure configuration. You can use this to log on to and debug the instance used to create your image.
  --terminate-instance-on-failure: oneof<nothing, bool> # The terminate instance on failure setting of the infrastructure configuration. Set to false if you want Image Builder to retain the instance used to configure your AMI if the build or test phase of your workflow fails.
  --sns-topic-arn: string # The Amazon Resource Name (ARN) for the SNS topic to which we send image build event notifications. EC2 Image Builder is unable to send notifications to SNS topics that are encrypted using keys from other accounts. The key that is used to encrypt the SNS topic must reside in the account that the Image Builder service runs under.
  --resource-tags: record # The tags attached to the resource created by Image Builder.
  --instance-metadata-options: record # The instance metadata options that apply to the HTTP requests that pipeline builds use to launch EC2 build and test instances. For more information about instance metadata options, see Configure the instance metadata options (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-options.html) in the Amazon EC2 User Guide for Linux instances, or Configure the instance metadata options (https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/configuring-instance-metadata-options.html) in the Amazon EC2 Windows Guide for Windows instances. — shape: {httpTokens?: string, httpPutResponseHopLimit?: int}
  --tags: record # The tags of the infrastructure configuration.
  client_token: string # The idempotency token used to make this request idempotent.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/CreateInfrastructureConfiguration"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: description, var: description}, {name: instanceTypes, var: instance_types}, {name: instanceProfileName, var: instance_profile_name}, {name: securityGroupIds, var: security_group_ids}, {name: subnetId, var: subnet_id}, {name: logging, var: logging}, {name: keyPair, var: key_pair}, {name: terminateInstanceOnFailure, var: terminate_instance_on_failure}, {name: snsTopicArn, var: sns_topic_arn}, {name: resourceTags, var: resource_tags}, {name: instanceMetadataOptions, var: instance_metadata_options}, {name: tags, var: tags}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, instance_types: $instance_types, instance_profile_name: $instance_profile_name, security_group_ids: $security_group_ids, subnet_id: $subnet_id, logging: $logging, key_pair: $key_pair, terminate_instance_on_failure: $terminate_instance_on_failure, sns_topic_arn: $sns_topic_arn, resource_tags: $resource_tags, instance_metadata_options: $instance_metadata_options, tags: $tags, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a component build version.
#
# DELETE /DeleteComponent
# Returns: record<requestId: string, componentBuildVersionArn: string>
# operationId: DeleteComponent
export def "delete-component" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --component-build-version-arn: string # The Amazon Resource Name (ARN) of the component build version to delete. (required)
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
    path: "/DeleteComponent"
    query: [{name: componentBuildVersionArn, var: component_build_version_arn, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    component_build_version_arn: $component_build_version_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a container recipe.
#
# DELETE /DeleteContainerRecipe
# Returns: record<requestId: string, containerRecipeArn: string>
# operationId: DeleteContainerRecipe
export def "delete-container-recipe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --container-recipe-arn: string # The Amazon Resource Name (ARN) of the container recipe to delete. (required)
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
    path: "/DeleteContainerRecipe"
    query: [{name: containerRecipeArn, var: container_recipe_arn, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    container_recipe_arn: $container_recipe_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a distribution configuration.
#
# DELETE /DeleteDistributionConfiguration
# Returns: record<requestId: string, distributionConfigurationArn: string>
# operationId: DeleteDistributionConfiguration
export def "delete-distribution-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --distribution-configuration-arn: string # The Amazon Resource Name (ARN) of the distribution configuration to delete. (required)
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
    path: "/DeleteDistributionConfiguration"
    query: [{name: distributionConfigurationArn, var: distribution_configuration_arn, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    distribution_configuration_arn: $distribution_configuration_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an Image Builder image resource. This does not delete any EC2 AMIs or ECR container images that are created during the image build process. You must clean those up separately, using the appropriate Amazon EC2 or Amazon ECR console actions, or API or CLI commands. To deregister an EC2 Linux AMI, see Deregister your Linux AMI (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/deregister-ami.html) in the Amazon EC2 User Guide . To deregister an EC2 Windows AMI, see Deregister your Windows AMI (https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/deregister-ami.html) in the Amazon EC2 Windows Guide . To delete a container image from Amazon ECR, see Deleting an image (https://docs.aws.amazon.com/AmazonECR/latest/userguide/delete_image.html) in the Amazon ECR User Guide.
#
# DELETE /DeleteImage
# Returns: record<requestId: string, imageBuildVersionArn: string>
# operationId: DeleteImage
export def "delete-image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --image-build-version-arn: string # The Amazon Resource Name (ARN) of the Image Builder image resource to delete. (required)
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
    path: "/DeleteImage"
    query: [{name: imageBuildVersionArn, var: image_build_version_arn, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_build_version_arn: $image_build_version_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an image pipeline.
#
# DELETE /DeleteImagePipeline
# Returns: record<requestId: string, imagePipelineArn: string>
# operationId: DeleteImagePipeline
export def "delete-image-pipeline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --image-pipeline-arn: string # The Amazon Resource Name (ARN) of the image pipeline to delete. (required)
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
    path: "/DeleteImagePipeline"
    query: [{name: imagePipelineArn, var: image_pipeline_arn, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_pipeline_arn: $image_pipeline_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an image recipe.
#
# DELETE /DeleteImageRecipe
# Returns: record<requestId: string, imageRecipeArn: string>
# operationId: DeleteImageRecipe
export def "delete-image-recipe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --image-recipe-arn: string # The Amazon Resource Name (ARN) of the image recipe to delete. (required)
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
    path: "/DeleteImageRecipe"
    query: [{name: imageRecipeArn, var: image_recipe_arn, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_recipe_arn: $image_recipe_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an infrastructure configuration.
#
# DELETE /DeleteInfrastructureConfiguration
# Returns: record<requestId: string, infrastructureConfigurationArn: string>
# operationId: DeleteInfrastructureConfiguration
export def "delete-infrastructure-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --infrastructure-configuration-arn: string # The Amazon Resource Name (ARN) of the infrastructure configuration to delete. (required)
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
    path: "/DeleteInfrastructureConfiguration"
    query: [{name: infrastructureConfigurationArn, var: infrastructure_configuration_arn, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    infrastructure_configuration_arn: $infrastructure_configuration_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a component object.
#
# GET /GetComponent
# Returns: record<requestId: string, component: record<arn: string, name: string, version: string, description: string, changeDescription: string, type: string, platform: string, supportedOsVersions: list<string>, state: record<status: string, reason: string>, parameters: list<record>, owner: string, data: string, kmsKeyId: string, encrypted: bool, dateCreated: string, tags: record, publisher: string, obfuscate: bool>>
# operationId: GetComponent
export def "get-component" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --component-build-version-arn: string # The Amazon Resource Name (ARN) of the component that you want to get. Regex requires the suffix /\d+$. (required)
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
    path: "/GetComponent"
    query: [{name: componentBuildVersionArn, var: component_build_version_arn, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    component_build_version_arn: $component_build_version_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a component policy.
#
# GET /GetComponentPolicy
# Returns: record<requestId: string, policy: string>
# operationId: GetComponentPolicy
export def "get-component-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --component-arn: string # The Amazon Resource Name (ARN) of the component whose policy you want to retrieve. (required)
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
    path: "/GetComponentPolicy"
    query: [{name: componentArn, var: component_arn, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    component_arn: $component_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a container recipe.
#
# GET /GetContainerRecipe
# Returns: record<requestId: string, containerRecipe: record<arn: string, containerType: string, name: string, description: string, platform: string, owner: string, version: string, components: list<record>, instanceConfiguration: record<image: string, blockDeviceMappings: list>, dockerfileTemplateData: string, kmsKeyId: string, encrypted: bool, parentImage: string, dateCreated: string, tags: record, workingDirectory: string, targetRepository: record<service: string, repositoryName: string>>>
# operationId: GetContainerRecipe
export def "get-container-recipe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --container-recipe-arn: string # The Amazon Resource Name (ARN) of the container recipe to retrieve. (required)
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
    path: "/GetContainerRecipe"
    query: [{name: containerRecipeArn, var: container_recipe_arn, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    container_recipe_arn: $container_recipe_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the policy for a container recipe.
#
# GET /GetContainerRecipePolicy
# Returns: record<requestId: string, policy: string>
# operationId: GetContainerRecipePolicy
export def "get-container-recipe-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --container-recipe-arn: string # The Amazon Resource Name (ARN) of the container recipe for the policy being requested. (required)
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
    path: "/GetContainerRecipePolicy"
    query: [{name: containerRecipeArn, var: container_recipe_arn, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    container_recipe_arn: $container_recipe_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a distribution configuration.
#
# GET /GetDistributionConfiguration
# Returns: record<requestId: string, distributionConfiguration: record<arn: string, name: string, description: string, distributions: list<record>, timeoutMinutes: int, dateCreated: string, dateUpdated: string, tags: record>>
# operationId: GetDistributionConfiguration
export def "get-distribution-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --distribution-configuration-arn: string # The Amazon Resource Name (ARN) of the distribution configuration that you want to retrieve. (required)
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
    path: "/GetDistributionConfiguration"
    query: [{name: distributionConfigurationArn, var: distribution_configuration_arn, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    distribution_configuration_arn: $distribution_configuration_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an image.
#
# GET /GetImage
# Returns: record<requestId: string, image: record<arn: string, type: string, name: string, version: string, platform: string, enhancedImageMetadataEnabled: bool, osVersion: string, state: record<status: string, reason: string>, imageRecipe: record<arn: string, type: string, name: string, description: string, platform: string, owner: string, version: string, components: list, parentImage: string, blockDeviceMappings: list, dateCreated: string, tags: record, workingDirectory: string, additionalInstanceConfiguration: record>, containerRecipe: record<arn: string, containerType: string, name: string, description: string, platform: string, owner: string, version: string, components: list, instanceConfiguration: record, dockerfileTemplateData: string, kmsKeyId: string, encrypted: bool, parentImage: string, dateCreated: string, tags: record, workingDirectory: string, targetRepository: record>, sourcePipelineName: string, sourcePipelineArn: string, infrastructureConfiguration: record<arn: string, name: string, description: string, instanceTypes: list, instanceProfileName: string, securityGroupIds: list, subnetId: string, logging: record, keyPair: string, terminateInstanceOnFailure: bool, snsTopicArn: string, dateCreated: string, dateUpdated: string, resourceTags: record, instanceMetadataOptions: record, tags: record>, distributionConfiguration: record<arn: string, name: string, description: string, distributions: list, timeoutMinutes: int, dateCreated: string, dateUpdated: string, tags: record>, imageTestsConfiguration: record<imageTestsEnabled: bool, timeoutMinutes: int>, dateCreated: string, outputResources: record<amis: list, containers: list>, tags: record, buildType: string, imageSource: string, scanState: record<status: string, reason: string>, imageScanningConfiguration: record<imageScanningEnabled: bool, ecrConfiguration: record>>>
# operationId: GetImage
export def "get-image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --image-build-version-arn: string # The Amazon Resource Name (ARN) of the image that you want to get. (required)
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
    path: "/GetImage"
    query: [{name: imageBuildVersionArn, var: image_build_version_arn, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_build_version_arn: $image_build_version_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an image pipeline.
#
# GET /GetImagePipeline
# Returns: record<requestId: string, imagePipeline: record<arn: string, name: string, description: string, platform: string, enhancedImageMetadataEnabled: bool, imageRecipeArn: string, containerRecipeArn: string, infrastructureConfigurationArn: string, distributionConfigurationArn: string, imageTestsConfiguration: record<imageTestsEnabled: bool, timeoutMinutes: int>, schedule: record<scheduleExpression: string, timezone: string, pipelineExecutionStartCondition: string>, status: string, dateCreated: string, dateUpdated: string, dateLastRun: string, dateNextRun: string, tags: record, imageScanningConfiguration: record<imageScanningEnabled: bool, ecrConfiguration: record>>>
# operationId: GetImagePipeline
export def "get-image-pipeline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --image-pipeline-arn: string # The Amazon Resource Name (ARN) of the image pipeline that you want to retrieve. (required)
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
    path: "/GetImagePipeline"
    query: [{name: imagePipelineArn, var: image_pipeline_arn, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_pipeline_arn: $image_pipeline_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an image policy.
#
# GET /GetImagePolicy
# Returns: record<requestId: string, policy: string>
# operationId: GetImagePolicy
export def "get-image-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --image-arn: string # The Amazon Resource Name (ARN) of the image whose policy you want to retrieve. (required)
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
    path: "/GetImagePolicy"
    query: [{name: imageArn, var: image_arn, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_arn: $image_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an image recipe.
#
# GET /GetImageRecipe
# Returns: record<requestId: string, imageRecipe: record<arn: string, type: string, name: string, description: string, platform: string, owner: string, version: string, components: list<record>, parentImage: string, blockDeviceMappings: list<record>, dateCreated: string, tags: record, workingDirectory: string, additionalInstanceConfiguration: record<systemsManagerAgent: record, userDataOverride: string>>>
# operationId: GetImageRecipe
export def "get-image-recipe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --image-recipe-arn: string # The Amazon Resource Name (ARN) of the image recipe that you want to retrieve. (required)
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
    path: "/GetImageRecipe"
    query: [{name: imageRecipeArn, var: image_recipe_arn, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_recipe_arn: $image_recipe_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an image recipe policy.
#
# GET /GetImageRecipePolicy
# Returns: record<requestId: string, policy: string>
# operationId: GetImageRecipePolicy
export def "get-image-recipe-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --image-recipe-arn: string # The Amazon Resource Name (ARN) of the image recipe whose policy you want to retrieve. (required)
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
    path: "/GetImageRecipePolicy"
    query: [{name: imageRecipeArn, var: image_recipe_arn, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_recipe_arn: $image_recipe_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an infrastructure configuration.
#
# GET /GetInfrastructureConfiguration
# Returns: record<requestId: string, infrastructureConfiguration: record<arn: string, name: string, description: string, instanceTypes: list<string>, instanceProfileName: string, securityGroupIds: list<string>, subnetId: string, logging: record<s3Logs: record>, keyPair: string, terminateInstanceOnFailure: bool, snsTopicArn: string, dateCreated: string, dateUpdated: string, resourceTags: record, instanceMetadataOptions: record<httpTokens: string, httpPutResponseHopLimit: int>, tags: record>>
# operationId: GetInfrastructureConfiguration
export def "get-infrastructure-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --infrastructure-configuration-arn: string # The Amazon Resource Name (ARN) of the infrastructure configuration that you want to retrieve. (required)
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
    path: "/GetInfrastructureConfiguration"
    query: [{name: infrastructureConfigurationArn, var: infrastructure_configuration_arn, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    infrastructure_configuration_arn: $infrastructure_configuration_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the runtime information that was logged for a specific runtime instance of the workflow.
#
# GET /GetWorkflowExecution
# Returns: record<requestId: string, workflowBuildVersionArn: string, workflowExecutionId: string, imageBuildVersionArn: string, type: string, status: string, message: string, totalStepCount: int, totalStepsSucceeded: int, totalStepsFailed: int, totalStepsSkipped: int, startTime: string, endTime: string>
# operationId: GetWorkflowExecution
export def "get-workflow-execution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --workflow-execution-id: string # Use the unique identifier for a runtime instance of the workflow to get runtime details. (required)
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
    path: "/GetWorkflowExecution"
    query: [{name: workflowExecutionId, var: workflow_execution_id, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workflow_execution_id: $workflow_execution_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the runtime information that was logged for a specific runtime instance of the workflow step.
#
# GET /GetWorkflowStepExecution
# Returns: record<requestId: string, stepExecutionId: string, workflowBuildVersionArn: string, workflowExecutionId: string, imageBuildVersionArn: string, name: string, description: string, action: string, status: string, rollbackStatus: string, message: string, inputs: string, outputs: string, startTime: string, endTime: string, onFailure: string, timeoutSeconds: int>
# operationId: GetWorkflowStepExecution
export def "get-workflow-step-execution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --step-execution-id: string # Use the unique identifier for a specific runtime instance of the workflow step to get runtime details for that step. (required)
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
    path: "/GetWorkflowStepExecution"
    query: [{name: stepExecutionId, var: step_execution_id, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    step_execution_id: $step_execution_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Imports a component and transforms its data into a component document.
#
# PUT /ImportComponent
# Returns: record<requestId: string, clientToken: string, componentBuildVersionArn: string>
# operationId: ImportComponent
export def "import-component" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # The name of the component.
  semantic_version: string # The semantic version of the component. This version follows the semantic version syntax. The semantic version has four nodes: <major>.<minor>.<patch>/<build>. You can assign values for the first three, and can filter on all of them. Filtering: With semantic versioning, you have the flexibility to use wildcards (x) to specify the most recent versions or nodes when selecting the base image or components for your recipe. When you use a wildcard in any node, all nodes to the right of the first wildcard must also be wildcards.
  --description: string # The description of the component. Describes the contents of the component.
  --change-description: string # The change description of the component. This description indicates the change that has been made in this version, or what makes this version different from other versions of this component.
  type: string@type-completer # The type of the component denotes whether the component is used to build the image, or only to test it.
  format: string@format-completer # The format of the resource that you want to import as a component.
  platform: string@platform-completer # The platform of the component.
  --data: string # The data of the component. Used to specify the data inline. Either data or uri can be used to specify the data within the component.
  --uri: string # The uri of the component. Must be an Amazon S3 URL and the requester must have permission to access the Amazon S3 bucket. If you use Amazon S3, you can specify component content up to your service quota. Either data or uri can be used to specify the data within the component.
  --kms-key-id: string # The ID of the KMS key that should be used to encrypt this component.
  --tags: record # The tags of the component.
  client_token: string # The idempotency token of the component.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/ImportComponent"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: semanticVersion, var: semantic_version}, {name: description, var: description}, {name: changeDescription, var: change_description}, {name: type, var: type}, {name: format, var: format}, {name: platform, var: platform}, {name: data, var: data}, {name: uri, var: uri}, {name: kmsKeyId, var: kms_key_id}, {name: tags, var: tags}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, semantic_version: $semantic_version, description: $description, change_description: $change_description, type: $type, format: $format, platform: $platform, data: $data, uri: $uri, kms_key_id: $kms_key_id, tags: $tags, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# When you export your virtual machine (VM) from its virtualization environment, that process creates a set of one or more disk container files that act as snapshots of your VM’s environment, settings, and data. The Amazon EC2 API ImportImage (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_ImportImage.html) action uses those files to import your VM and create an AMI. To import using the CLI command, see import-image (https://docs.aws.amazon.com/cli/latest/reference/ec2/import-image.html) You can reference the task ID from the VM import to pull in the AMI that the import created as the base image for your Image Builder recipe.
#
# PUT /ImportVmImage
# Returns: record<requestId: string, imageArn: string, clientToken: string>
# operationId: ImportVmImage
export def "import-vm-image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # The name of the base image that is created by the import process.
  semantic_version: string # The semantic version to attach to the base image that was created during the import process. This version follows the semantic version syntax. The semantic version has four nodes: <major>.<minor>.<patch>/<build>. You can assign values for the first three, and can filter on all of them. Assignment: For the first three nodes you can assign any positive integer value, including zero, with an upper limit of 2^30-1, or 1073741823 for each node. Image Builder automatically assigns the build number to the fourth node. Patterns: You can use any numeric pattern that adheres to the assignment requirements for the nodes that you can assign. For example, you might choose a software version pattern, such as 1.0.0, or a date, such as 2021.01.01.
  --description: string # The description for the base image that is created by the import process.
  platform: string@platform-completer # The operating system platform for the imported VM.
  --os-version: string # The operating system version for the imported VM.
  vm_import_task_id: string # The importTaskId (API) or ImportTaskId (CLI) from the Amazon EC2 VM import process. Image Builder retrieves information from the import process to pull in the AMI that is created from the VM source as the base image for your recipe.
  --tags: record # Tags that are attached to the import resources.
  client_token: string # Unique, case-sensitive identifier you provide to ensure idempotency of the request. For more information, see Ensuring idempotency (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/Run_Instance_Idempotency.html) in the Amazon EC2 API Reference.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/ImportVmImage"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: semanticVersion, var: semantic_version}, {name: description, var: description}, {name: platform, var: platform}, {name: osVersion, var: os_version}, {name: vmImportTaskId, var: vm_import_task_id}, {name: tags, var: tags}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, semantic_version: $semantic_version, description: $description, platform: $platform, os_version: $os_version, vm_import_task_id: $vm_import_task_id, tags: $tags, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of component build versions for the specified semantic version. The semantic version has four nodes: <major>.<minor>.<patch>/<build>. You can assign values for the first three, and can filter on all of them. Filtering: With semantic versioning, you have the flexibility to use wildcards (x) to specify the most recent versions or nodes when selecting the base image or components for your recipe. When you use a wildcard in any node, all nodes to the right of the first wildcard must also be wildcards.
#
# POST /ListComponentBuildVersions
# Returns: record<requestId: string, componentSummaryList: table<arn: string, name: string, version: string, platform: string, supportedOsVersions: list, state: record, type: string, owner: string, description: string, changeDescription: string, dateCreated: string, tags: record, publisher: string, obfuscate: bool>, nextToken: string>
# operationId: ListComponentBuildVersions
export def "list-component-build-versions" [
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
  component_version_arn: string # The component version Amazon Resource Name (ARN) whose versions you want to list.
  --body-max-results: int # The maximum items to return in a request. (spec name: maxResults)
  --body-next-token: string # A token to specify where to start paginating. This is the NextToken from a previously truncated response. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ListComponentBuildVersions"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: componentVersionArn, var: component_version_arn}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, component_version_arn: $component_version_arn, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of components that can be filtered by name, or by using the listed filters to streamline results. Newly created components can take up to two minutes to appear in the ListComponents API Results. The semantic version has four nodes: <major>.<minor>.<patch>/<build>. You can assign values for the first three, and can filter on all of them. Filtering: With semantic versioning, you have the flexibility to use wildcards (x) to specify the most recent versions or nodes when selecting the base image or components for your recipe. When you use a wildcard in any node, all nodes to the right of the first wildcard must also be wildcards.
#
# POST /ListComponents
# Returns: record<requestId: string, componentVersionList: table<arn: string, name: string, version: string, description: string, platform: string, supportedOsVersions: list, type: string, owner: string, dateCreated: string>, nextToken: string>
# operationId: ListComponents
export def "list-components" [
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
  --owner: string@owner-completer # Filters results based on the type of owner for the component. By default, this request returns a list of components that your account owns. To see results for other types of owners, you can specify components that Amazon manages, third party components, or components that other accounts have shared with you.
  --filters: list # Use the following filters to streamline results: description name platform supportedOsVersion type version — item shape: {name?: string, values?: list<string>}
  --by-name: oneof<nothing, bool> # Returns the list of components for the specified name.
  --body-max-results: int # The maximum items to return in a request. (spec name: maxResults)
  --body-next-token: string # A token to specify where to start paginating. This is the NextToken from a previously truncated response. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ListComponents"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: owner, var: owner}, {name: filters, var: filters}, {name: byName, var: by_name}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, owner: $owner, filters: $filters, by_name: $by_name, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of container recipes.
#
# POST /ListContainerRecipes
# Returns: record<requestId: string, containerRecipeSummaryList: table<arn: string, containerType: string, name: string, platform: string, owner: string, parentImage: string, dateCreated: string, tags: record>, nextToken: string>
# operationId: ListContainerRecipes
export def "list-container-recipes" [
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
  --owner: string@owner-completer # Returns container recipes belonging to the specified owner, that have been shared with you. You can omit this field to return container recipes belonging to your account.
  --filters: list # Use the following filters to streamline results: containerType name parentImage platform — item shape: {name?: string, values?: list<string>}
  --body-max-results: int # The maximum items to return in a request. (spec name: maxResults)
  --body-next-token: string # A token to specify where to start paginating. This is the NextToken from a previously truncated response. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ListContainerRecipes"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: owner, var: owner}, {name: filters, var: filters}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, owner: $owner, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of distribution configurations.
#
# POST /ListDistributionConfigurations
# Returns: record<requestId: string, distributionConfigurationSummaryList: table<arn: string, name: string, description: string, dateCreated: string, dateUpdated: string, tags: record, regions: list>, nextToken: string>
# operationId: ListDistributionConfigurations
export def "list-distribution-configurations" [
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
  --filters: list # You can filter on name to streamline results. — item shape: {name?: string, values?: list<string>}
  --body-max-results: int # The maximum items to return in a request. (spec name: maxResults)
  --body-next-token: string # A token to specify where to start paginating. This is the NextToken from a previously truncated response. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ListDistributionConfigurations"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of image build versions.
#
# POST /ListImageBuildVersions
# Returns: record<requestId: string, imageSummaryList: table<arn: string, name: string, type: string, version: string, platform: string, osVersion: string, state: record, owner: string, dateCreated: string, outputResources: record, tags: record, buildType: string, imageSource: string>, nextToken: string>
# operationId: ListImageBuildVersions
export def "list-image-build-versions" [
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
  image_version_arn: string # The Amazon Resource Name (ARN) of the image whose build versions you want to retrieve.
  --filters: list # Use the following filters to streamline results: name osVersion platform type version — item shape: {name?: string, values?: list<string>}
  --body-max-results: int # The maximum items to return in a request. (spec name: maxResults)
  --body-next-token: string # A token to specify where to start paginating. This is the NextToken from a previously truncated response. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ListImageBuildVersions"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: imageVersionArn, var: image_version_arn}, {name: filters, var: filters}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, image_version_arn: $image_version_arn, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the Packages that are associated with an Image Build Version, as determined by Amazon Web Services Systems Manager Inventory at build time.
#
# POST /ListImagePackages
# Returns: record<requestId: string, imagePackageList: table<packageName: string, packageVersion: string>, nextToken: string>
# operationId: ListImagePackages
export def "list-image-packages" [
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
  image_build_version_arn: string # Filter results for the ListImagePackages request by the Image Build Version ARN
  --body-max-results: int # The maximum items to return in a request. (spec name: maxResults)
  --body-next-token: string # A token to specify where to start paginating. This is the NextToken from a previously truncated response. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ListImagePackages"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: imageBuildVersionArn, var: image_build_version_arn}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, image_build_version_arn: $image_build_version_arn, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of images created by the specified pipeline.
#
# POST /ListImagePipelineImages
# Returns: record<requestId: string, imageSummaryList: table<arn: string, name: string, type: string, version: string, platform: string, osVersion: string, state: record, owner: string, dateCreated: string, outputResources: record, tags: record, buildType: string, imageSource: string>, nextToken: string>
# operationId: ListImagePipelineImages
export def "list-image-pipeline-images" [
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
  image_pipeline_arn: string # The Amazon Resource Name (ARN) of the image pipeline whose images you want to view.
  --filters: list # Use the following filters to streamline results: name version — item shape: {name?: string, values?: list<string>}
  --body-max-results: int # The maximum items to return in a request. (spec name: maxResults)
  --body-next-token: string # A token to specify where to start paginating. This is the NextToken from a previously truncated response. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ListImagePipelineImages"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: imagePipelineArn, var: image_pipeline_arn}, {name: filters, var: filters}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, image_pipeline_arn: $image_pipeline_arn, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of image pipelines.
#
# POST /ListImagePipelines
# Returns: record<requestId: string, imagePipelineList: table<arn: string, name: string, description: string, platform: string, enhancedImageMetadataEnabled: bool, imageRecipeArn: string, containerRecipeArn: string, infrastructureConfigurationArn: string, distributionConfigurationArn: string, imageTestsConfiguration: record, schedule: record, status: string, dateCreated: string, dateUpdated: string, dateLastRun: string, dateNextRun: string, tags: record, imageScanningConfiguration: record>, nextToken: string>
# operationId: ListImagePipelines
export def "list-image-pipelines" [
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
  --filters: list # Use the following filters to streamline results: description distributionConfigurationArn imageRecipeArn infrastructureConfigurationArn name status — item shape: {name?: string, values?: list<string>}
  --body-max-results: int # The maximum items to return in a request. (spec name: maxResults)
  --body-next-token: string # A token to specify where to start paginating. This is the NextToken from a previously truncated response. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ListImagePipelines"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of image recipes.
#
# POST /ListImageRecipes
# Returns: record<requestId: string, imageRecipeSummaryList: table<arn: string, name: string, platform: string, owner: string, parentImage: string, dateCreated: string, tags: record>, nextToken: string>
# operationId: ListImageRecipes
export def "list-image-recipes" [
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
  --owner: string@owner-completer # The owner defines which image recipes you want to list. By default, this request will only show image recipes owned by your account. You can use this field to specify if you want to view image recipes owned by yourself, by Amazon, or those image recipes that have been shared with you by other customers.
  --filters: list # Use the following filters to streamline results: name parentImage platform — item shape: {name?: string, values?: list<string>}
  --body-max-results: int # The maximum items to return in a request. (spec name: maxResults)
  --body-next-token: string # A token to specify where to start paginating. This is the NextToken from a previously truncated response. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ListImageRecipes"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: owner, var: owner}, {name: filters, var: filters}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, owner: $owner, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of image scan aggregations for your account. You can filter by the type of key that Image Builder uses to group results. For example, if you want to get a list of findings by severity level for one of your pipelines, you might specify your pipeline with the imagePipelineArn filter. If you don't specify a filter, Image Builder returns an aggregation for your account. To streamline results, you can use the following filters in your request: accountId imageBuildVersionArn imagePipelineArn vulnerabilityId
#
# POST /ListImageScanFindingAggregations
# Returns: record<requestId: string, aggregationType: string, responses: table<accountAggregation: record, imageAggregation: record, imagePipelineAggregation: record, vulnerabilityIdAggregation: record>, nextToken: string>
# operationId: ListImageScanFindingAggregations
export def "list-image-scan-finding-aggregations" [
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
  --filter: record # A filter name and value pair that is used to return a more specific list of results from a list operation. Filters can be used to match a set of resources by specific criteria, such as tags, attributes, or IDs. — shape: {name?: string, values?: list<string>}
  --body-next-token: string # A token to specify where to start paginating. This is the NextToken from a previously truncated response. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ListImageScanFindingAggregations"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: filter, var: filter}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, filter: $filter, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of image scan findings for your account.
#
# POST /ListImageScanFindings
# Returns: record<requestId: string, findings: table<awsAccountId: string, imageBuildVersionArn: string, imagePipelineArn: string, type: string, description: string, title: string, remediation: record, severity: string, firstObservedAt: string, updatedAt: string, inspectorScore: float, inspectorScoreDetails: record, packageVulnerabilityDetails: record, fixAvailable: string>, nextToken: string>
# operationId: ListImageScanFindings
export def "list-image-scan-findings" [
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
  --filters: list # An array of name value pairs that you can use to filter your results. You can use the following filters to streamline results: imageBuildVersionArn imagePipelineArn vulnerabilityId severity If you don't request a filter, then all findings in your account are listed. — item shape: {name?: string, values?: list<string>}
  --body-max-results: int # The maximum items to return in a request. (spec name: maxResults)
  --body-next-token: string # A token to specify where to start paginating. This is the NextToken from a previously truncated response. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ListImageScanFindings"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of images that you have access to. Newly created images can take up to two minutes to appear in the ListImages API Results.
#
# POST /ListImages
# Returns: record<requestId: string, imageVersionList: table<arn: string, name: string, type: string, version: string, platform: string, osVersion: string, owner: string, dateCreated: string, buildType: string, imageSource: string>, nextToken: string>
# operationId: ListImages
export def "list-images" [
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
  --owner: string@owner-completer # The owner defines which images you want to list. By default, this request will only show images owned by your account. You can use this field to specify if you want to view images owned by yourself, by Amazon, or those images that have been shared with you by other customers.
  --filters: list # Use the following filters to streamline results: name osVersion platform type version — item shape: {name?: string, values?: list<string>}
  --by-name: oneof<nothing, bool> # Requests a list of images with a specific recipe name.
  --body-max-results: int # The maximum items to return in a request. (spec name: maxResults)
  --body-next-token: string # A token to specify where to start paginating. This is the NextToken from a previously truncated response. (spec name: nextToken)
  --include-deprecated: oneof<nothing, bool> # Includes deprecated images in the response list.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ListImages"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: owner, var: owner}, {name: filters, var: filters}, {name: byName, var: by_name}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}, {name: includeDeprecated, var: include_deprecated}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, owner: $owner, filters: $filters, by_name: $by_name, body_max_results: $body_max_results, body_next_token: $body_next_token, include_deprecated: $include_deprecated
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of infrastructure configurations.
#
# POST /ListInfrastructureConfigurations
# Returns: record<requestId: string, infrastructureConfigurationSummaryList: table<arn: string, name: string, description: string, dateCreated: string, dateUpdated: string, resourceTags: record, tags: record, instanceTypes: list, instanceProfileName: string>, nextToken: string>
# operationId: ListInfrastructureConfigurations
export def "list-infrastructure-configurations" [
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
  --filters: list # You can filter on name to streamline results. — item shape: {name?: string, values?: list<string>}
  --body-max-results: int # The maximum items to return in a request. (spec name: maxResults)
  --body-next-token: string # A token to specify where to start paginating. This is the NextToken from a previously truncated response. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ListInfrastructureConfigurations"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of tags for the specified resource.
#
# GET /tags/{resourceArn}
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
    path: "/tags/{resourceArn}"
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

# Adds a tag to a resource.
#
# POST /tags/{resourceArn}
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
  tags: record # The tags to apply to the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tags/{resourceArn}"
    path_params: [{name: resourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of workflow runtime instance metadata objects for a specific image build version.
#
# POST /ListWorkflowExecutions
# Returns: record<requestId: string, workflowExecutions: table<workflowBuildVersionArn: string, workflowExecutionId: string, type: string, status: string, message: string, totalStepCount: int, totalStepsSucceeded: int, totalStepsFailed: int, totalStepsSkipped: int, startTime: string, endTime: string>, imageBuildVersionArn: string, message: string, nextToken: string>
# operationId: ListWorkflowExecutions
export def "list-workflow-executions" [
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
  --body-max-results: int # The maximum items to return in a request. (spec name: maxResults)
  --body-next-token: string # A token to specify where to start paginating. This is the NextToken from a previously truncated response. (spec name: nextToken)
  image_build_version_arn: string # List all workflow runtime instances for the specified image build version resource ARN.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ListWorkflowExecutions"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}, {name: imageBuildVersionArn, var: image_build_version_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body_max_results: $body_max_results, body_next_token: $body_next_token, image_build_version_arn: $image_build_version_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Shows runtime data for each step in a runtime instance of the workflow that you specify in the request.
#
# POST /ListWorkflowStepExecutions
# Returns: record<requestId: string, steps: table<stepExecutionId: string, name: string, description: string, action: string, status: string, rollbackStatus: string, message: string, inputs: string, outputs: string, startTime: string, endTime: string>, workflowBuildVersionArn: string, workflowExecutionId: string, imageBuildVersionArn: string, message: string, nextToken: string>
# operationId: ListWorkflowStepExecutions
export def "list-workflow-step-executions" [
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
  --body-max-results: int # The maximum items to return in a request. (spec name: maxResults)
  --body-next-token: string # A token to specify where to start paginating. This is the NextToken from a previously truncated response. (spec name: nextToken)
  workflow_execution_id: string # The unique identifier that Image Builder assigned to keep track of runtime details when it ran the workflow.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ListWorkflowStepExecutions"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}, {name: workflowExecutionId, var: workflow_execution_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body_max_results: $body_max_results, body_next_token: $body_next_token, workflow_execution_id: $workflow_execution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Applies a policy to a component. We recommend that you call the RAM API CreateResourceShare (https://docs.aws.amazon.com/ram/latest/APIReference/API_CreateResourceShare.html) to share resources. If you call the Image Builder API PutComponentPolicy, you must also call the RAM API PromoteResourceShareCreatedFromPolicy (https://docs.aws.amazon.com/ram/latest/APIReference/API_PromoteResourceShareCreatedFromPolicy.html) in order for the resource to be visible to all principals with whom the resource is shared.
#
# PUT /PutComponentPolicy
# Returns: record<requestId: string, componentArn: string>
# operationId: PutComponentPolicy
export def "put-component-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  component_arn: string # The Amazon Resource Name (ARN) of the component that this policy should be applied to.
  policy: string # The policy to apply.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/PutComponentPolicy"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: componentArn, var: component_arn}, {name: policy, var: policy}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, component_arn: $component_arn, policy: $policy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Applies a policy to a container image. We recommend that you call the RAM API CreateResourceShare (https://docs.aws.amazon.com//ram/latest/APIReference/API_CreateResourceShare.html) to share resources. If you call the Image Builder API PutContainerImagePolicy, you must also call the RAM API PromoteResourceShareCreatedFromPolicy (https://docs.aws.amazon.com//ram/latest/APIReference/API_PromoteResourceShareCreatedFromPolicy.html) in order for the resource to be visible to all principals with whom the resource is shared.
#
# PUT /PutContainerRecipePolicy
# Returns: record<requestId: string, containerRecipeArn: string>
# operationId: PutContainerRecipePolicy
export def "put-container-recipe-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  container_recipe_arn: string # The Amazon Resource Name (ARN) of the container recipe that this policy should be applied to.
  policy: string # The policy to apply to the container recipe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/PutContainerRecipePolicy"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: containerRecipeArn, var: container_recipe_arn}, {name: policy, var: policy}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, container_recipe_arn: $container_recipe_arn, policy: $policy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Applies a policy to an image. We recommend that you call the RAM API CreateResourceShare (https://docs.aws.amazon.com/ram/latest/APIReference/API_CreateResourceShare.html) to share resources. If you call the Image Builder API PutImagePolicy, you must also call the RAM API PromoteResourceShareCreatedFromPolicy (https://docs.aws.amazon.com/ram/latest/APIReference/API_PromoteResourceShareCreatedFromPolicy.html) in order for the resource to be visible to all principals with whom the resource is shared.
#
# PUT /PutImagePolicy
# Returns: record<requestId: string, imageArn: string>
# operationId: PutImagePolicy
export def "put-image-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  image_arn: string # The Amazon Resource Name (ARN) of the image that this policy should be applied to.
  policy: string # The policy to apply.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/PutImagePolicy"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: imageArn, var: image_arn}, {name: policy, var: policy}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, image_arn: $image_arn, policy: $policy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Applies a policy to an image recipe. We recommend that you call the RAM API CreateResourceShare (https://docs.aws.amazon.com/ram/latest/APIReference/API_CreateResourceShare.html) to share resources. If you call the Image Builder API PutImageRecipePolicy, you must also call the RAM API PromoteResourceShareCreatedFromPolicy (https://docs.aws.amazon.com/ram/latest/APIReference/API_PromoteResourceShareCreatedFromPolicy.html) in order for the resource to be visible to all principals with whom the resource is shared.
#
# PUT /PutImageRecipePolicy
# Returns: record<requestId: string, imageRecipeArn: string>
# operationId: PutImageRecipePolicy
export def "put-image-recipe-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  image_recipe_arn: string # The Amazon Resource Name (ARN) of the image recipe that this policy should be applied to.
  policy: string # The policy to apply.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/PutImageRecipePolicy"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: imageRecipeArn, var: image_recipe_arn}, {name: policy, var: policy}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, image_recipe_arn: $image_recipe_arn, policy: $policy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Manually triggers a pipeline to create an image.
#
# PUT /StartImagePipelineExecution
# Returns: record<requestId: string, clientToken: string, imageBuildVersionArn: string>
# operationId: StartImagePipelineExecution
export def "start-image-pipeline-execution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  image_pipeline_arn: string # The Amazon Resource Name (ARN) of the image pipeline that you want to manually invoke.
  client_token: string # The idempotency token used to make this request idempotent.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/StartImagePipelineExecution"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: imagePipelineArn, var: image_pipeline_arn}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, image_pipeline_arn: $image_pipeline_arn, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a tag from a resource.
#
# DELETE /tags/{resourceArn}
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
  --tag-keys: list<string> # The tag keys to remove from the resource. (required)
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
    path: "/tags/{resourceArn}"
    path_params: [{name: resourceArn, var: resource_arn}]
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

# Updates a new distribution configuration. Distribution configurations define and configure the outputs of your pipeline.
#
# PUT /UpdateDistributionConfiguration
# Returns: record<requestId: string, clientToken: string, distributionConfigurationArn: string>
# operationId: UpdateDistributionConfiguration
export def "update-distribution-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  distribution_configuration_arn: string # The Amazon Resource Name (ARN) of the distribution configuration that you want to update.
  --description: string # The description of the distribution configuration.
  distributions: list # The distributions of the distribution configuration. — item shape: {region: string, amiDistributionConfiguration?: record, containerDistributionConfiguration?: record, licenseConfigurationArns?: list<string>, launchTemplateConfigurations?: list, s3ExportConfiguration?: record, fastLaunchConfigurations?: list}
  client_token: string # The idempotency token of the distribution configuration.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/UpdateDistributionConfiguration"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: distributionConfigurationArn, var: distribution_configuration_arn}, {name: description, var: description}, {name: distributions, var: distributions}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, distribution_configuration_arn: $distribution_configuration_arn, description: $description, distributions: $distributions, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an image pipeline. Image pipelines enable you to automate the creation and distribution of images. UpdateImagePipeline does not support selective updates for the pipeline. You must specify all of the required properties in the update request, not just the properties that have changed.
#
# PUT /UpdateImagePipeline
# Returns: record<requestId: string, clientToken: string, imagePipelineArn: string>
# operationId: UpdateImagePipeline
export def "update-image-pipeline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  image_pipeline_arn: string # The Amazon Resource Name (ARN) of the image pipeline that you want to update.
  --description: string # The description of the image pipeline.
  --image-recipe-arn: string # The Amazon Resource Name (ARN) of the image recipe that will be used to configure images updated by this image pipeline.
  --container-recipe-arn: string # The Amazon Resource Name (ARN) of the container pipeline to update.
  infrastructure_configuration_arn: string # The Amazon Resource Name (ARN) of the infrastructure configuration that Image Builder uses to build images that this image pipeline has updated.
  --distribution-configuration-arn: string # The Amazon Resource Name (ARN) of the distribution configuration that Image Builder uses to configure and distribute images that this image pipeline has updated.
  --image-tests-configuration: record # Configure image tests for your pipeline build. Tests run after building the image, to verify that the AMI or container image is valid before distributing it. — shape: {imageTestsEnabled?: bool, timeoutMinutes?: int}
  --enhanced-image-metadata-enabled: oneof<nothing, bool> # Collects additional information about the image being created, including the operating system (OS) version and package list. This information is used to enhance the overall experience of using EC2 Image Builder. Enabled by default.
  --schedule: record # A schedule configures how often and when a pipeline will automatically create a new image. — shape: {scheduleExpression?: string, timezone?: string, pipelineExecutionStartCondition?: "EXPRESSION_MATCH_ONLY"|"EXPRESSION_MATCH_AND_DEPENDENCY_UPDATES_AVAILABLE"}
  --status: string@status-completer # The status of the image pipeline.
  client_token: string # The idempotency token used to make this request idempotent.
  --image-scanning-configuration: record # Contains settings for Image Builder image resource and container image scans. — shape: {imageScanningEnabled?: bool, ecrConfiguration?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/UpdateImagePipeline"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: imagePipelineArn, var: image_pipeline_arn}, {name: description, var: description}, {name: imageRecipeArn, var: image_recipe_arn}, {name: containerRecipeArn, var: container_recipe_arn}, {name: infrastructureConfigurationArn, var: infrastructure_configuration_arn}, {name: distributionConfigurationArn, var: distribution_configuration_arn}, {name: imageTestsConfiguration, var: image_tests_configuration}, {name: enhancedImageMetadataEnabled, var: enhanced_image_metadata_enabled}, {name: schedule, var: schedule}, {name: status, var: status}, {name: clientToken, var: client_token}, {name: imageScanningConfiguration, var: image_scanning_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, image_pipeline_arn: $image_pipeline_arn, description: $description, image_recipe_arn: $image_recipe_arn, container_recipe_arn: $container_recipe_arn, infrastructure_configuration_arn: $infrastructure_configuration_arn, distribution_configuration_arn: $distribution_configuration_arn, image_tests_configuration: $image_tests_configuration, enhanced_image_metadata_enabled: $enhanced_image_metadata_enabled, schedule: $schedule, status: $status, client_token: $client_token, image_scanning_configuration: $image_scanning_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a new infrastructure configuration. An infrastructure configuration defines the environment in which your image will be built and tested.
#
# PUT /UpdateInfrastructureConfiguration
# Returns: record<requestId: string, clientToken: string, infrastructureConfigurationArn: string>
# operationId: UpdateInfrastructureConfiguration
export def "update-infrastructure-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  infrastructure_configuration_arn: string # The Amazon Resource Name (ARN) of the infrastructure configuration that you want to update.
  --description: string # The description of the infrastructure configuration.
  --instance-types: list<string> # The instance types of the infrastructure configuration. You can specify one or more instance types to use for this build. The service will pick one of these instance types based on availability.
  instance_profile_name: string # The instance profile to associate with the instance used to customize your Amazon EC2 AMI.
  --security-group-ids: list<string> # The security group IDs to associate with the instance used to customize your Amazon EC2 AMI.
  --subnet-id: string # The subnet ID to place the instance used to customize your Amazon EC2 AMI in.
  --logging: record # Logging configuration defines where Image Builder uploads your logs. — shape: {s3Logs?: record}
  --key-pair: string # The key pair of the infrastructure configuration. You can use this to log on to and debug the instance used to create your image.
  --terminate-instance-on-failure: oneof<nothing, bool> # The terminate instance on failure setting of the infrastructure configuration. Set to false if you want Image Builder to retain the instance used to configure your AMI if the build or test phase of your workflow fails.
  --sns-topic-arn: string # The Amazon Resource Name (ARN) for the SNS topic to which we send image build event notifications. EC2 Image Builder is unable to send notifications to SNS topics that are encrypted using keys from other accounts. The key that is used to encrypt the SNS topic must reside in the account that the Image Builder service runs under.
  client_token: string # The idempotency token used to make this request idempotent.
  --resource-tags: record # The tags attached to the resource created by Image Builder.
  --instance-metadata-options: record # The instance metadata options that apply to the HTTP requests that pipeline builds use to launch EC2 build and test instances. For more information about instance metadata options, see Configure the instance metadata options (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-options.html) in the Amazon EC2 User Guide for Linux instances, or Configure the instance metadata options (https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/configuring-instance-metadata-options.html) in the Amazon EC2 Windows Guide for Windows instances. — shape: {httpTokens?: string, httpPutResponseHopLimit?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/UpdateInfrastructureConfiguration"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: infrastructureConfigurationArn, var: infrastructure_configuration_arn}, {name: description, var: description}, {name: instanceTypes, var: instance_types}, {name: instanceProfileName, var: instance_profile_name}, {name: securityGroupIds, var: security_group_ids}, {name: subnetId, var: subnet_id}, {name: logging, var: logging}, {name: keyPair, var: key_pair}, {name: terminateInstanceOnFailure, var: terminate_instance_on_failure}, {name: snsTopicArn, var: sns_topic_arn}, {name: clientToken, var: client_token}, {name: resourceTags, var: resource_tags}, {name: instanceMetadataOptions, var: instance_metadata_options}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, infrastructure_configuration_arn: $infrastructure_configuration_arn, description: $description, instance_types: $instance_types, instance_profile_name: $instance_profile_name, security_group_ids: $security_group_ids, subnet_id: $subnet_id, logging: $logging, key_pair: $key_pair, terminate_instance_on_failure: $terminate_instance_on_failure, sns_topic_arn: $sns_topic_arn, client_token: $client_token, resource_tags: $resource_tags, instance_metadata_options: $instance_metadata_options
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
