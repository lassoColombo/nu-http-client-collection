# Auto-generated client for Amazon Personalize v2018-05-22
# Source: https://api.apis.guru/v2/specs/amazonaws.com/personalize/2018-05-22/openapi.json
# Auth: --token flag or $env.AMAZON_PERSONALIZE_TOKEN

const CLIENT = {
  base_url: "http://personalize.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_PERSONALIZE_TOKEN"
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

def base-url-completer [] { ["http://personalize.us-east-1.amazonaws.com" "http://personalize.us-east-2.amazonaws.com" "http://personalize.us-west-1.amazonaws.com" "http://personalize.us-west-2.amazonaws.com" "http://personalize.us-gov-west-1.amazonaws.com" "http://personalize.us-gov-east-1.amazonaws.com" "http://personalize.ca-central-1.amazonaws.com" "http://personalize.eu-north-1.amazonaws.com" "http://personalize.eu-west-1.amazonaws.com" "http://personalize.eu-west-2.amazonaws.com" "http://personalize.eu-west-3.amazonaws.com" "http://personalize.eu-central-1.amazonaws.com" "http://personalize.eu-south-1.amazonaws.com" "http://personalize.af-south-1.amazonaws.com" "http://personalize.ap-northeast-1.amazonaws.com" "http://personalize.ap-northeast-2.amazonaws.com" "http://personalize.ap-northeast-3.amazonaws.com" "http://personalize.ap-southeast-1.amazonaws.com" "http://personalize.ap-southeast-2.amazonaws.com" "http://personalize.ap-east-1.amazonaws.com" "http://personalize.ap-south-1.amazonaws.com" "http://personalize.sa-east-1.amazonaws.com" "http://personalize.me-south-1.amazonaws.com" "https://personalize.us-east-1.amazonaws.com" "https://personalize.us-east-2.amazonaws.com" "https://personalize.us-west-1.amazonaws.com" "https://personalize.us-west-2.amazonaws.com" "https://personalize.us-gov-west-1.amazonaws.com" "https://personalize.us-gov-east-1.amazonaws.com" "https://personalize.ca-central-1.amazonaws.com" "https://personalize.eu-north-1.amazonaws.com" "https://personalize.eu-west-1.amazonaws.com" "https://personalize.eu-west-2.amazonaws.com" "https://personalize.eu-west-3.amazonaws.com" "https://personalize.eu-central-1.amazonaws.com" "https://personalize.eu-south-1.amazonaws.com" "https://personalize.af-south-1.amazonaws.com" "https://personalize.ap-northeast-1.amazonaws.com" "https://personalize.ap-northeast-2.amazonaws.com" "https://personalize.ap-northeast-3.amazonaws.com" "https://personalize.ap-southeast-1.amazonaws.com" "https://personalize.ap-southeast-2.amazonaws.com" "https://personalize.ap-east-1.amazonaws.com" "https://personalize.ap-south-1.amazonaws.com" "https://personalize.sa-east-1.amazonaws.com" "https://personalize.me-south-1.amazonaws.com" "http://personalize.cn-north-1.amazonaws.com.cn" "http://personalize.cn-northwest-1.amazonaws.com.cn" "https://personalize.cn-north-1.amazonaws.com.cn" "https://personalize.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["AmazonPersonalize.CreateBatchInferenceJob"] }
def x-amz-target-completer-1 [] { ["AmazonPersonalize.CreateBatchSegmentJob"] }
def x-amz-target-completer-2 [] { ["AmazonPersonalize.CreateCampaign"] }
def x-amz-target-completer-3 [] { ["AmazonPersonalize.CreateDataset"] }
def ingestion-mode-completer [] { ["ALL" "BULK" "PUT"] }
def x-amz-target-completer-4 [] { ["AmazonPersonalize.CreateDatasetExportJob"] }
def domain-completer [] { ["ECOMMERCE" "VIDEO_ON_DEMAND"] }
def x-amz-target-completer-5 [] { ["AmazonPersonalize.CreateDatasetGroup"] }
def import-mode-completer [] { ["FULL" "INCREMENTAL"] }
def x-amz-target-completer-6 [] { ["AmazonPersonalize.CreateDatasetImportJob"] }
def x-amz-target-completer-7 [] { ["AmazonPersonalize.CreateEventTracker"] }
def x-amz-target-completer-8 [] { ["AmazonPersonalize.CreateFilter"] }
def x-amz-target-completer-9 [] { ["AmazonPersonalize.CreateMetricAttribution"] }
def x-amz-target-completer-10 [] { ["AmazonPersonalize.CreateRecommender"] }
def x-amz-target-completer-11 [] { ["AmazonPersonalize.CreateSchema"] }
def x-amz-target-completer-12 [] { ["AmazonPersonalize.CreateSolution"] }
def training-mode-completer [] { ["FULL" "UPDATE"] }
def x-amz-target-completer-13 [] { ["AmazonPersonalize.CreateSolutionVersion"] }
def x-amz-target-completer-14 [] { ["AmazonPersonalize.DeleteCampaign"] }
def x-amz-target-completer-15 [] { ["AmazonPersonalize.DeleteDataset"] }
def x-amz-target-completer-16 [] { ["AmazonPersonalize.DeleteDatasetGroup"] }
def x-amz-target-completer-17 [] { ["AmazonPersonalize.DeleteEventTracker"] }
def x-amz-target-completer-18 [] { ["AmazonPersonalize.DeleteFilter"] }
def x-amz-target-completer-19 [] { ["AmazonPersonalize.DeleteMetricAttribution"] }
def x-amz-target-completer-20 [] { ["AmazonPersonalize.DeleteRecommender"] }
def x-amz-target-completer-21 [] { ["AmazonPersonalize.DeleteSchema"] }
def x-amz-target-completer-22 [] { ["AmazonPersonalize.DeleteSolution"] }
def x-amz-target-completer-23 [] { ["AmazonPersonalize.DescribeAlgorithm"] }
def x-amz-target-completer-24 [] { ["AmazonPersonalize.DescribeBatchInferenceJob"] }
def x-amz-target-completer-25 [] { ["AmazonPersonalize.DescribeBatchSegmentJob"] }
def x-amz-target-completer-26 [] { ["AmazonPersonalize.DescribeCampaign"] }
def x-amz-target-completer-27 [] { ["AmazonPersonalize.DescribeDataset"] }
def x-amz-target-completer-28 [] { ["AmazonPersonalize.DescribeDatasetExportJob"] }
def x-amz-target-completer-29 [] { ["AmazonPersonalize.DescribeDatasetGroup"] }
def x-amz-target-completer-30 [] { ["AmazonPersonalize.DescribeDatasetImportJob"] }
def x-amz-target-completer-31 [] { ["AmazonPersonalize.DescribeEventTracker"] }
def x-amz-target-completer-32 [] { ["AmazonPersonalize.DescribeFeatureTransformation"] }
def x-amz-target-completer-33 [] { ["AmazonPersonalize.DescribeFilter"] }
def x-amz-target-completer-34 [] { ["AmazonPersonalize.DescribeMetricAttribution"] }
def x-amz-target-completer-35 [] { ["AmazonPersonalize.DescribeRecipe"] }
def x-amz-target-completer-36 [] { ["AmazonPersonalize.DescribeRecommender"] }
def x-amz-target-completer-37 [] { ["AmazonPersonalize.DescribeSchema"] }
def x-amz-target-completer-38 [] { ["AmazonPersonalize.DescribeSolution"] }
def x-amz-target-completer-39 [] { ["AmazonPersonalize.DescribeSolutionVersion"] }
def x-amz-target-completer-40 [] { ["AmazonPersonalize.GetSolutionMetrics"] }
def x-amz-target-completer-41 [] { ["AmazonPersonalize.ListBatchInferenceJobs"] }
def x-amz-target-completer-42 [] { ["AmazonPersonalize.ListBatchSegmentJobs"] }
def x-amz-target-completer-43 [] { ["AmazonPersonalize.ListCampaigns"] }
def x-amz-target-completer-44 [] { ["AmazonPersonalize.ListDatasetExportJobs"] }
def x-amz-target-completer-45 [] { ["AmazonPersonalize.ListDatasetGroups"] }
def x-amz-target-completer-46 [] { ["AmazonPersonalize.ListDatasetImportJobs"] }
def x-amz-target-completer-47 [] { ["AmazonPersonalize.ListDatasets"] }
def x-amz-target-completer-48 [] { ["AmazonPersonalize.ListEventTrackers"] }
def x-amz-target-completer-49 [] { ["AmazonPersonalize.ListFilters"] }
def x-amz-target-completer-50 [] { ["AmazonPersonalize.ListMetricAttributionMetrics"] }
def x-amz-target-completer-51 [] { ["AmazonPersonalize.ListMetricAttributions"] }
def recipe-provider-completer [] { ["SERVICE"] }
def x-amz-target-completer-52 [] { ["AmazonPersonalize.ListRecipes"] }
def x-amz-target-completer-53 [] { ["AmazonPersonalize.ListRecommenders"] }
def x-amz-target-completer-54 [] { ["AmazonPersonalize.ListSchemas"] }
def x-amz-target-completer-55 [] { ["AmazonPersonalize.ListSolutionVersions"] }
def x-amz-target-completer-56 [] { ["AmazonPersonalize.ListSolutions"] }
def x-amz-target-completer-57 [] { ["AmazonPersonalize.ListTagsForResource"] }
def x-amz-target-completer-58 [] { ["AmazonPersonalize.StartRecommender"] }
def x-amz-target-completer-59 [] { ["AmazonPersonalize.StopRecommender"] }
def x-amz-target-completer-60 [] { ["AmazonPersonalize.StopSolutionVersionCreation"] }
def x-amz-target-completer-61 [] { ["AmazonPersonalize.TagResource"] }
def x-amz-target-completer-62 [] { ["AmazonPersonalize.UntagResource"] }
def x-amz-target-completer-63 [] { ["AmazonPersonalize.UpdateCampaign"] }
def x-amz-target-completer-64 [] { ["AmazonPersonalize.UpdateMetricAttribution"] }
def x-amz-target-completer-65 [] { ["AmazonPersonalize.UpdateRecommender"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    create-batch-inference-job: "record<batchInferenceJobArn: string>"
    create-batch-segment-job: "record<batchSegmentJobArn: string>"
    create-campaign: "record<campaignArn: string>"
    create-dataset: "record<datasetArn: string>"
    create-dataset-export-job: "record<datasetExportJobArn: string>"
    create-dataset-group: "record<datasetGroupArn: string, domain: string>"
    create-dataset-import-job: "record<datasetImportJobArn: string>"
    create-event-tracker: "record<eventTrackerArn: string, trackingId: string>"
    create-filter: "record<filterArn: string>"
    create-metric-attribution: "record<metricAttributionArn: string>"
    create-recommender: "record<recommenderArn: string>"
    create-schema: "record<schemaArn: string>"
    create-solution: "record<solutionArn: string>"
    create-solution-version: "record<solutionVersionArn: string>"
    describe-algorithm: "record<algorithm: record<name: string, algorithmArn: string, algorithmImage: record<name: string, dockerURI: string>, defaultHyperParameters: record, defaultHyperParameterRanges: record<integerHyperParameterRanges: list, continuousHyperParameterRanges: list, categoricalHyperParameterRanges: list>, defaultResourceConfig: record, trainingInputMode: string, roleArn: string, creationDateTime: string, lastUpdatedDateTime: string>>"
    describe-batch-inference-job: "record<batchInferenceJob: record<jobName: string, batchInferenceJobArn: string, filterArn: string, failureReason: string, solutionVersionArn: string, numResults: int, jobInput: record<s3DataSource: record>, jobOutput: record<s3DataDestination: record>, batchInferenceJobConfig: record<itemExplorationConfig: record>, roleArn: string, status: string, creationDateTime: string, lastUpdatedDateTime: string>>"
    describe-batch-segment-job: "record<batchSegmentJob: record<jobName: string, batchSegmentJobArn: string, filterArn: string, failureReason: string, solutionVersionArn: string, numResults: int, jobInput: record<s3DataSource: record>, jobOutput: record<s3DataDestination: record>, roleArn: string, status: string, creationDateTime: string, lastUpdatedDateTime: string>>"
    describe-campaign: "record<campaign: record<name: string, campaignArn: string, solutionVersionArn: string, minProvisionedTPS: int, campaignConfig: record<itemExplorationConfig: record>, status: string, failureReason: string, creationDateTime: string, lastUpdatedDateTime: string, latestCampaignUpdate: record<solutionVersionArn: string, minProvisionedTPS: int, campaignConfig: record, status: string, failureReason: string, creationDateTime: string, lastUpdatedDateTime: string>>>"
    describe-dataset: "record<dataset: record<name: string, datasetArn: string, datasetGroupArn: string, datasetType: string, schemaArn: string, status: string, creationDateTime: string, lastUpdatedDateTime: string>>"
    describe-dataset-export-job: "record<datasetExportJob: record<jobName: string, datasetExportJobArn: string, datasetArn: string, ingestionMode: string, roleArn: string, status: string, jobOutput: record<s3DataDestination: record>, creationDateTime: string, lastUpdatedDateTime: string, failureReason: string>>"
    describe-dataset-group: "record<datasetGroup: record<name: string, datasetGroupArn: string, status: string, roleArn: string, kmsKeyArn: string, creationDateTime: string, lastUpdatedDateTime: string, failureReason: string, domain: string>>"
    describe-dataset-import-job: "record<datasetImportJob: record<jobName: string, datasetImportJobArn: string, datasetArn: string, dataSource: record<dataLocation: string>, roleArn: string, status: string, creationDateTime: string, lastUpdatedDateTime: string, failureReason: string, importMode: string, publishAttributionMetricsToS3: bool>>"
    describe-event-tracker: "record<eventTracker: record<name: string, eventTrackerArn: string, accountId: string, trackingId: string, datasetGroupArn: string, status: string, creationDateTime: string, lastUpdatedDateTime: string>>"
    describe-feature-transformation: "record<featureTransformation: record<name: string, featureTransformationArn: string, defaultParameters: record, creationDateTime: string, lastUpdatedDateTime: string, status: string>>"
    describe-filter: "record<filter: record<name: string, filterArn: string, creationDateTime: string, lastUpdatedDateTime: string, datasetGroupArn: string, failureReason: string, filterExpression: string, status: string>>"
    describe-metric-attribution: "record<metricAttribution: record<name: string, metricAttributionArn: string, datasetGroupArn: string, metricsOutputConfig: record<s3DataDestination: record, roleArn: string>, status: string, creationDateTime: string, lastUpdatedDateTime: string, failureReason: string>>"
    describe-recipe: "record<recipe: record<name: string, recipeArn: string, algorithmArn: string, featureTransformationArn: string, status: string, description: string, creationDateTime: string, recipeType: string, lastUpdatedDateTime: string>>"
    describe-recommender: "record<recommender: record<recommenderArn: string, datasetGroupArn: string, name: string, recipeArn: string, recommenderConfig: record<itemExplorationConfig: record, minRecommendationRequestsPerSecond: int>, creationDateTime: string, lastUpdatedDateTime: string, status: string, failureReason: string, latestRecommenderUpdate: record<recommenderConfig: record, creationDateTime: string, lastUpdatedDateTime: string, status: string, failureReason: string>, modelMetrics: record>>"
    describe-schema: "record<schema: record<name: string, schemaArn: string, schema: string, creationDateTime: string, lastUpdatedDateTime: string, domain: string>>"
    describe-solution: "record<solution: record<name: string, solutionArn: string, performHPO: bool, performAutoML: bool, recipeArn: string, datasetGroupArn: string, eventType: string, solutionConfig: record<eventValueThreshold: string, hpoConfig: record, algorithmHyperParameters: record, featureTransformationParameters: record, autoMLConfig: record, optimizationObjective: record>, autoMLResult: record<bestRecipeArn: string>, status: string, creationDateTime: string, lastUpdatedDateTime: string, latestSolutionVersion: record<solutionVersionArn: string, status: string, creationDateTime: string, lastUpdatedDateTime: string, failureReason: string>>>"
    describe-solution-version: "record<solutionVersion: record<name: string, solutionVersionArn: string, solutionArn: string, performHPO: bool, performAutoML: bool, recipeArn: string, eventType: string, datasetGroupArn: string, solutionConfig: record<eventValueThreshold: string, hpoConfig: record, algorithmHyperParameters: record, featureTransformationParameters: record, autoMLConfig: record, optimizationObjective: record>, trainingHours: float, trainingMode: string, tunedHPOParams: record<algorithmHyperParameters: record>, status: string, failureReason: string, creationDateTime: string, lastUpdatedDateTime: string>>"
    get-solution-metrics: "record<solutionVersionArn: string, metrics: record>"
    list-batch-inference-jobs: "record<batchInferenceJobs: table<batchInferenceJobArn: string, jobName: string, status: string, creationDateTime: string, lastUpdatedDateTime: string, failureReason: string, solutionVersionArn: string>, nextToken: string>"
    list-batch-segment-jobs: "record<batchSegmentJobs: table<batchSegmentJobArn: string, jobName: string, status: string, creationDateTime: string, lastUpdatedDateTime: string, failureReason: string, solutionVersionArn: string>, nextToken: string>"
    list-campaigns: "record<campaigns: table<name: string, campaignArn: string, status: string, creationDateTime: string, lastUpdatedDateTime: string, failureReason: string>, nextToken: string>"
    list-dataset-export-jobs: "record<datasetExportJobs: table<datasetExportJobArn: string, jobName: string, status: string, creationDateTime: string, lastUpdatedDateTime: string, failureReason: string>, nextToken: string>"
    list-dataset-groups: "record<datasetGroups: table<name: string, datasetGroupArn: string, status: string, creationDateTime: string, lastUpdatedDateTime: string, failureReason: string, domain: string>, nextToken: string>"
    list-dataset-import-jobs: "record<datasetImportJobs: table<datasetImportJobArn: string, jobName: string, status: string, creationDateTime: string, lastUpdatedDateTime: string, failureReason: string, importMode: string>, nextToken: string>"
    list-datasets: "record<datasets: table<name: string, datasetArn: string, datasetType: string, status: string, creationDateTime: string, lastUpdatedDateTime: string>, nextToken: string>"
    list-event-trackers: "record<eventTrackers: table<name: string, eventTrackerArn: string, status: string, creationDateTime: string, lastUpdatedDateTime: string>, nextToken: string>"
    list-filters: "record<Filters: table<name: string, filterArn: string, creationDateTime: string, lastUpdatedDateTime: string, datasetGroupArn: string, failureReason: string, status: string>, nextToken: string>"
    list-metric-attribution-metrics: "record<metrics: table<eventType: string, metricName: string, expression: string>, nextToken: string>"
    list-metric-attributions: "record<metricAttributions: table<name: string, metricAttributionArn: string, status: string, creationDateTime: string, lastUpdatedDateTime: string, failureReason: string>, nextToken: string>"
    list-recipes: "record<recipes: table<name: string, recipeArn: string, status: string, creationDateTime: string, lastUpdatedDateTime: string, domain: string>, nextToken: string>"
    list-recommenders: "record<recommenders: table<name: string, recommenderArn: string, datasetGroupArn: string, recipeArn: string, recommenderConfig: record, status: string, creationDateTime: string, lastUpdatedDateTime: string>, nextToken: string>"
    list-schemas: "record<schemas: table<name: string, schemaArn: string, creationDateTime: string, lastUpdatedDateTime: string, domain: string>, nextToken: string>"
    list-solution-versions: "record<solutionVersions: table<solutionVersionArn: string, status: string, creationDateTime: string, lastUpdatedDateTime: string, failureReason: string>, nextToken: string>"
    list-solutions: "record<solutions: table<name: string, solutionArn: string, status: string, creationDateTime: string, lastUpdatedDateTime: string, recipeArn: string>, nextToken: string>"
    list-tags-for-resource: "record<tags: table<tagKey: string, tagValue: string>>"
    start-recommender: "record<recommenderArn: string>"
    stop-recommender: "record<recommenderArn: string>"
    tag-resource: "record"
    untag-resource: "record"
    update-campaign: "record<campaignArn: string>"
    update-metric-attribution: "record<metricAttributionArn: string>"
    update-recommender: "record<recommenderArn: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["create-batch-inference-job" "create-batch-segment-job" "create-campaign" "create-dataset" "create-dataset-export-job" "create-dataset-group" "create-dataset-import-job" "create-event-tracker" "create-filter" "create-metric-attribution" "create-recommender" "create-schema" "create-solution" "create-solution-version" "delete-campaign" "delete-dataset" "delete-dataset-group" "delete-event-tracker" "delete-filter" "delete-metric-attribution" "delete-recommender" "delete-schema" "delete-solution" "describe-algorithm" "describe-batch-inference-job" "describe-batch-segment-job" "describe-campaign" "describe-dataset" "describe-dataset-export-job" "describe-dataset-group" "describe-dataset-import-job" "describe-event-tracker" "describe-feature-transformation" "describe-filter" "describe-metric-attribution" "describe-recipe" "describe-recommender" "describe-schema" "describe-solution" "describe-solution-version" "get-solution-metrics" "list-batch-inference-jobs" "list-batch-segment-jobs" "list-campaigns" "list-dataset-export-jobs" "list-dataset-groups" "list-dataset-import-jobs" "list-datasets" "list-event-trackers" "list-filters" "list-metric-attribution-metrics" "list-metric-attributions" "list-recipes" "list-recommenders" "list-schemas" "list-solution-versions" "list-solutions" "list-tags-for-resource" "start-recommender" "stop-recommender" "stop-solution-version-creation" "tag-resource" "untag-resource" "update-campaign" "update-metric-attribution" "update-recommender" "commands"] | sort) } | get name | first)
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

# Creates a batch inference job. The operation can handle up to 50 million records and the input file must be in JSON format. For more information, see Creating a batch inference job (https://docs.aws.amazon.com/personalize/latest/dg/creating-batch-inference-job.html).
#
# POST /
# Returns: record<batchInferenceJobArn: string>
# operationId: CreateBatchInferenceJob
export def "create-batch-inference-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  job_name: string # The name of the batch inference job to create.
  solution_version_arn: string # The Amazon Resource Name (ARN) of the solution version that will be used to generate the batch inference recommendations.
  --filter-arn: string # The ARN of the filter to apply to the batch inference job. For more information on using filters, see Filtering batch recommendations (https://docs.aws.amazon.com/personalize/latest/dg/filter-batch.html).
  --num-results: int # The number of recommendations to retrieve.
  job_input: record # The input configuration of a batch inference job. — shape: {s3DataSource: record}
  job_output: record # The output configuration parameters of a batch inference job. — shape: {s3DataDestination: record}
  role_arn: string # The ARN of the Amazon Identity and Access Management role that has permissions to read and write to your input and output Amazon S3 buckets respectively.
  --batch-inference-job-config: record # The configuration details of a batch inference job. — shape: {itemExplorationConfig?: record}
  --tags: list # A list of tags (https://docs.aws.amazon.com/personalize/latest/dev/tagging-resources.html) to apply to the batch inference job. — item shape: {tagKey: string, tagValue: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.CreateBatchInferenceJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: jobName, var: job_name}, {name: solutionVersionArn, var: solution_version_arn}, {name: filterArn, var: filter_arn}, {name: numResults, var: num_results}, {name: jobInput, var: job_input}, {name: jobOutput, var: job_output}, {name: roleArn, var: role_arn}, {name: batchInferenceJobConfig, var: batch_inference_job_config}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_name: $job_name, solution_version_arn: $solution_version_arn, filter_arn: $filter_arn, num_results: $num_results, job_input: $job_input, job_output: $job_output, role_arn: $role_arn, batch_inference_job_config: $batch_inference_job_config, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a batch segment job. The operation can handle up to 50 million records and the input file must be in JSON format. For more information, see Getting batch recommendations and user segments (https://docs.aws.amazon.com/personalize/latest/dg/recommendations-batch.html).
#
# POST /
# Returns: record<batchSegmentJobArn: string>
# operationId: CreateBatchSegmentJob
export def "create-batch-segment-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  job_name: string # The name of the batch segment job to create.
  solution_version_arn: string # The Amazon Resource Name (ARN) of the solution version you want the batch segment job to use to generate batch segments.
  --filter-arn: string # The ARN of the filter to apply to the batch segment job. For more information on using filters, see Filtering batch recommendations (https://docs.aws.amazon.com/personalize/latest/dg/filter-batch.html).
  --num-results: int # The number of predicted users generated by the batch segment job for each line of input data.
  job_input: record # The input configuration of a batch segment job. — shape: {s3DataSource: record}
  job_output: record # The output configuration parameters of a batch segment job. — shape: {s3DataDestination: record}
  role_arn: string # The ARN of the Amazon Identity and Access Management role that has permissions to read and write to your input and output Amazon S3 buckets respectively.
  --tags: list # A list of tags (https://docs.aws.amazon.com/personalize/latest/dev/tagging-resources.html) to apply to the batch segment job. — item shape: {tagKey: string, tagValue: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.CreateBatchSegmentJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: jobName, var: job_name}, {name: solutionVersionArn, var: solution_version_arn}, {name: filterArn, var: filter_arn}, {name: numResults, var: num_results}, {name: jobInput, var: job_input}, {name: jobOutput, var: job_output}, {name: roleArn, var: role_arn}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_name: $job_name, solution_version_arn: $solution_version_arn, filter_arn: $filter_arn, num_results: $num_results, job_input: $job_input, job_output: $job_output, role_arn: $role_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a campaign that deploys a solution version. When a client calls the GetRecommendations (https://docs.aws.amazon.com/personalize/latest/dg/API_RS_GetRecommendations.html) and GetPersonalizedRanking (https://docs.aws.amazon.com/personalize/latest/dg/API_RS_GetPersonalizedRanking.html) APIs, a campaign is specified in the request. Minimum Provisioned TPS and Auto-Scaling A transaction is a single GetRecommendations or GetPersonalizedRanking call. Transactions per second (TPS) is the throughput and unit of billing for Amazon Personalize. The minimum provisioned TPS (minProvisionedTPS) specifies the baseline throughput provisioned by Amazon Personalize, and thus, the minimum billing charge. If your TPS increases beyond minProvisionedTPS, Amazon Personalize auto-scales the provisioned capacity up and down, but never below minProvisionedTPS. There's a short time delay while the capacity is increased that might cause loss of transactions. The actual TPS used is calculated as the average requests/second within a 5-minute window. You pay for maximum of either the minimum provisioned TPS or the actual TPS. We recommend starting with a low minProvisionedTPS, track your usage using Amazon CloudWatch metrics, and then increase the minProvisionedTPS as necessary. Status A campaign can be in one of the following states: CREATE PENDING > CREATE IN_PROGRESS > ACTIVE -or- CREATE FAILED DELETE PENDING > DELETE IN_PROGRESS To get the campaign status, call DescribeCampaign (https://docs.aws.amazon.com/personalize/latest/dg/API_DescribeCampaign.html). Wait until the status of the campaign is ACTIVE before asking the campaign for recommendations. Related APIs ListCampaigns (https://docs.aws.amazon.com/personalize/latest/dg/API_ListCampaigns.html) DescribeCampaign (https://docs.aws.amazon.com/personalize/latest/dg/API_DescribeCampaign.html) UpdateCampaign (https://docs.aws.amazon.com/personalize/latest/dg/API_UpdateCampaign.html) DeleteCampaign (https://docs.aws.amazon.com/personalize/latest/dg/API_DeleteCampaign.html)
#
# POST /
# Returns: record<campaignArn: string>
# operationId: CreateCampaign
export def "create-campaign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # A name for the new campaign. The campaign name must be unique within your account.
  solution_version_arn: string # The Amazon Resource Name (ARN) of the solution version to deploy.
  --min-provisioned-tps: int # Specifies the requested minimum provisioned transactions (recommendations) per second that Amazon Personalize will support.
  --campaign-config: record # The configuration details of a campaign. — shape: {itemExplorationConfig?: record}
  --tags: list # A list of tags (https://docs.aws.amazon.com/personalize/latest/dev/tagging-resources.html) to apply to the campaign. — item shape: {tagKey: string, tagValue: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.CreateCampaign"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: solutionVersionArn, var: solution_version_arn}, {name: minProvisionedTPS, var: min_provisioned_tps}, {name: campaignConfig, var: campaign_config}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, solution_version_arn: $solution_version_arn, min_provisioned_tps: $min_provisioned_tps, campaign_config: $campaign_config, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an empty dataset and adds it to the specified dataset group. Use CreateDatasetImportJob (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateDatasetImportJob.html) to import your training data to a dataset. There are three types of datasets: Interactions Items Users Each dataset type has an associated schema with required field types. Only the Interactions dataset is required in order to train a model (also referred to as creating a solution). A dataset can be in one of the following states: CREATE PENDING > CREATE IN_PROGRESS > ACTIVE -or- CREATE FAILED DELETE PENDING > DELETE IN_PROGRESS To get the status of the dataset, call DescribeDataset (https://docs.aws.amazon.com/personalize/latest/dg/API_DescribeDataset.html). Related APIs CreateDatasetGroup (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateDatasetGroup.html) ListDatasets (https://docs.aws.amazon.com/personalize/latest/dg/API_ListDatasets.html) DescribeDataset (https://docs.aws.amazon.com/personalize/latest/dg/API_DescribeDataset.html) DeleteDataset (https://docs.aws.amazon.com/personalize/latest/dg/API_DeleteDataset.html)
#
# POST /
# Returns: record<datasetArn: string>
# operationId: CreateDataset
export def "create-dataset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name for the dataset.
  schema_arn: string # The ARN of the schema to associate with the dataset. The schema defines the dataset fields.
  dataset_group_arn: string # The Amazon Resource Name (ARN) of the dataset group to add the dataset to.
  dataset_type: string # The type of dataset. One of the following (case insensitive) values: Interactions Items Users
  --tags: list # A list of tags (https://docs.aws.amazon.com/personalize/latest/dev/tagging-resources.html) to apply to the dataset. — item shape: {tagKey: string, tagValue: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.CreateDataset"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: schemaArn, var: schema_arn}, {name: datasetGroupArn, var: dataset_group_arn}, {name: datasetType, var: dataset_type}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, schema_arn: $schema_arn, dataset_group_arn: $dataset_group_arn, dataset_type: $dataset_type, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a job that exports data from your dataset to an Amazon S3 bucket. To allow Amazon Personalize to export the training data, you must specify an service-linked IAM role that gives Amazon Personalize PutObject permissions for your Amazon S3 bucket. For information, see Exporting a dataset (https://docs.aws.amazon.com/personalize/latest/dg/export-data.html) in the Amazon Personalize developer guide. Status A dataset export job can be in one of the following states: CREATE PENDING > CREATE IN_PROGRESS > ACTIVE -or- CREATE FAILED To get the status of the export job, call DescribeDatasetExportJob (https://docs.aws.amazon.com/personalize/latest/dg/API_DescribeDatasetExportJob.html), and specify the Amazon Resource Name (ARN) of the dataset export job. The dataset export is complete when the status shows as ACTIVE. If the status shows as CREATE FAILED, the response includes a failureReason key, which describes why the job failed.
#
# POST /
# Returns: record<datasetExportJobArn: string>
# operationId: CreateDatasetExportJob
export def "create-dataset-export-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  job_name: string # The name for the dataset export job.
  dataset_arn: string # The Amazon Resource Name (ARN) of the dataset that contains the data to export.
  --ingestion-mode: string@ingestion-mode-completer # The data to export, based on how you imported the data. You can choose to export only BULK data that you imported using a dataset import job, only PUT data that you imported incrementally (using the console, PutEvents, PutUsers and PutItems operations), or ALL for both types. The default value is PUT.
  role_arn: string # The Amazon Resource Name (ARN) of the IAM service role that has permissions to add data to your output Amazon S3 bucket.
  job_output: record # The output configuration parameters of a dataset export job. — shape: {s3DataDestination: record}
  --tags: list # A list of tags (https://docs.aws.amazon.com/personalize/latest/dev/tagging-resources.html) to apply to the dataset export job. — item shape: {tagKey: string, tagValue: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.CreateDatasetExportJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: jobName, var: job_name}, {name: datasetArn, var: dataset_arn}, {name: ingestionMode, var: ingestion_mode}, {name: roleArn, var: role_arn}, {name: jobOutput, var: job_output}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_name: $job_name, dataset_arn: $dataset_arn, ingestion_mode: $ingestion_mode, role_arn: $role_arn, job_output: $job_output, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an empty dataset group. A dataset group is a container for Amazon Personalize resources. A dataset group can contain at most three datasets, one for each type of dataset: Interactions Items Users A dataset group can be a Domain dataset group, where you specify a domain and use pre-configured resources like recommenders, or a Custom dataset group, where you use custom resources, such as a solution with a solution version, that you deploy with a campaign. If you start with a Domain dataset group, you can still add custom resources such as solutions and solution versions trained with recipes for custom use cases and deployed with campaigns. A dataset group can be in one of the following states: CREATE PENDING > CREATE IN_PROGRESS > ACTIVE -or- CREATE FAILED DELETE PENDING To get the status of the dataset group, call DescribeDatasetGroup (https://docs.aws.amazon.com/personalize/latest/dg/API_DescribeDatasetGroup.html). If the status shows as CREATE FAILED, the response includes a failureReason key, which describes why the creation failed. You must wait until the status of the dataset group is ACTIVE before adding a dataset to the group. You can specify an Key Management Service (KMS) key to encrypt the datasets in the group. If you specify a KMS key, you must also include an Identity and Access Management (IAM) role that has permission to access the key. APIs that require a dataset group ARN in the request CreateDataset (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateDataset.html) CreateEventTracker (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateEventTracker.html) CreateSolution (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateSolution.html) Related APIs ListDatasetGroups (https://docs.aws.amazon.com/personalize/latest/dg/API_ListDatasetGroups.html) DescribeDatasetGroup (https://docs.aws.amazon.com/personalize/latest/dg/API_DescribeDatasetGroup.html) DeleteDatasetGroup (https://docs.aws.amazon.com/personalize/latest/dg/API_DeleteDatasetGroup.html)
#
# POST /
# Returns: record<datasetGroupArn: string, domain: string>
# operationId: CreateDatasetGroup
export def "create-dataset-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name for the new dataset group.
  --role-arn: string # The ARN of the Identity and Access Management (IAM) role that has permissions to access the Key Management Service (KMS) key. Supplying an IAM role is only valid when also specifying a KMS key.
  --kms-key-arn: string # The Amazon Resource Name (ARN) of a Key Management Service (KMS) key used to encrypt the datasets.
  --domain: string@domain-completer # The domain of the dataset group. Specify a domain to create a Domain dataset group. The domain you specify determines the default schemas for datasets and the use cases available for recommenders. If you don't specify a domain, you create a Custom dataset group with solution versions that you deploy with a campaign.
  --tags: list # A list of tags (https://docs.aws.amazon.com/personalize/latest/dev/tagging-resources.html) to apply to the dataset group. — item shape: {tagKey: string, tagValue: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.CreateDatasetGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: roleArn, var: role_arn}, {name: kmsKeyArn, var: kms_key_arn}, {name: domain, var: domain}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, role_arn: $role_arn, kms_key_arn: $kms_key_arn, domain: $domain, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a job that imports training data from your data source (an Amazon S3 bucket) to an Amazon Personalize dataset. To allow Amazon Personalize to import the training data, you must specify an IAM service role that has permission to read from the data source, as Amazon Personalize makes a copy of your data and processes it internally. For information on granting access to your Amazon S3 bucket, see Giving Amazon Personalize Access to Amazon S3 Resources (https://docs.aws.amazon.com/personalize/latest/dg/granting-personalize-s3-access.html). By default, a dataset import job replaces any existing data in the dataset that you imported in bulk. To add new records without replacing existing data, specify INCREMENTAL for the import mode in the CreateDatasetImportJob operation. Status A dataset import job can be in one of the following states: CREATE PENDING > CREATE IN_PROGRESS > ACTIVE -or- CREATE FAILED To get the status of the import job, call DescribeDatasetImportJob (https://docs.aws.amazon.com/personalize/latest/dg/API_DescribeDatasetImportJob.html), providing the Amazon Resource Name (ARN) of the dataset import job. The dataset import is complete when the status shows as ACTIVE. If the status shows as CREATE FAILED, the response includes a failureReason key, which describes why the job failed. Importing takes time. You must wait until the status shows as ACTIVE before training a model using the dataset. Related APIs ListDatasetImportJobs (https://docs.aws.amazon.com/personalize/latest/dg/API_ListDatasetImportJobs.html) DescribeDatasetImportJob (https://docs.aws.amazon.com/personalize/latest/dg/API_DescribeDatasetImportJob.html)
#
# POST /
# Returns: record<datasetImportJobArn: string>
# operationId: CreateDatasetImportJob
export def "create-dataset-import-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  job_name: string # The name for the dataset import job.
  dataset_arn: string # The ARN of the dataset that receives the imported data.
  data_source: record # Describes the data source that contains the data to upload to a dataset. — shape: {dataLocation?: string}
  role_arn: string # The ARN of the IAM role that has permissions to read from the Amazon S3 data source.
  --tags: list # A list of tags (https://docs.aws.amazon.com/personalize/latest/dev/tagging-resources.html) to apply to the dataset import job. — item shape: {tagKey: string, tagValue: string}
  --import-mode: string@import-mode-completer # Specify how to add the new records to an existing dataset. The default import mode is FULL. If you haven't imported bulk records into the dataset previously, you can only specify FULL. Specify FULL to overwrite all existing bulk data in your dataset. Data you imported individually is not replaced. Specify INCREMENTAL to append the new records to the existing data in your dataset. Amazon Personalize replaces any record with the same ID with the new one.
  --publish-attribution-metrics-to-s3: oneof<nothing, bool> # If you created a metric attribution, specify whether to publish metrics for this import job to Amazon S3
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.CreateDatasetImportJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: jobName, var: job_name}, {name: datasetArn, var: dataset_arn}, {name: dataSource, var: data_source}, {name: roleArn, var: role_arn}, {name: tags, var: tags}, {name: importMode, var: import_mode}, {name: publishAttributionMetricsToS3, var: publish_attribution_metrics_to_s3}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_name: $job_name, dataset_arn: $dataset_arn, data_source: $data_source, role_arn: $role_arn, tags: $tags, import_mode: $import_mode, publish_attribution_metrics_to_s3: $publish_attribution_metrics_to_s3
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an event tracker that you use when adding event data to a specified dataset group using the PutEvents (https://docs.aws.amazon.com/personalize/latest/dg/API_UBS_PutEvents.html) API. Only one event tracker can be associated with a dataset group. You will get an error if you call CreateEventTracker using the same dataset group as an existing event tracker. When you create an event tracker, the response includes a tracking ID, which you pass as a parameter when you use the PutEvents (https://docs.aws.amazon.com/personalize/latest/dg/API_UBS_PutEvents.html) operation. Amazon Personalize then appends the event data to the Interactions dataset of the dataset group you specify in your event tracker. The event tracker can be in one of the following states: CREATE PENDING > CREATE IN_PROGRESS > ACTIVE -or- CREATE FAILED DELETE PENDING > DELETE IN_PROGRESS To get the status of the event tracker, call DescribeEventTracker (https://docs.aws.amazon.com/personalize/latest/dg/API_DescribeEventTracker.html). The event tracker must be in the ACTIVE state before using the tracking ID. Related APIs ListEventTrackers (https://docs.aws.amazon.com/personalize/latest/dg/API_ListEventTrackers.html) DescribeEventTracker (https://docs.aws.amazon.com/personalize/latest/dg/API_DescribeEventTracker.html) DeleteEventTracker (https://docs.aws.amazon.com/personalize/latest/dg/API_DeleteEventTracker.html)
#
# POST /
# Returns: record<eventTrackerArn: string, trackingId: string>
# operationId: CreateEventTracker
export def "create-event-tracker" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name for the event tracker.
  dataset_group_arn: string # The Amazon Resource Name (ARN) of the dataset group that receives the event data.
  --tags: list # A list of tags (https://docs.aws.amazon.com/personalize/latest/dev/tagging-resources.html) to apply to the event tracker. — item shape: {tagKey: string, tagValue: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.CreateEventTracker"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: datasetGroupArn, var: dataset_group_arn}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, dataset_group_arn: $dataset_group_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a recommendation filter. For more information, see Filtering recommendations and user segments (https://docs.aws.amazon.com/personalize/latest/dg/filter.html).
#
# POST /
# Returns: record<filterArn: string>
# operationId: CreateFilter
export def "create-filter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the filter to create.
  dataset_group_arn: string # The ARN of the dataset group that the filter will belong to.
  filter_expression: string # The filter expression defines which items are included or excluded from recommendations. Filter expression must follow specific format rules. For information about filter expression structure and syntax, see Filter expressions (https://docs.aws.amazon.com/personalize/latest/dg/filter-expressions.html). (format: password)
  --tags: list # A list of tags (https://docs.aws.amazon.com/personalize/latest/dev/tagging-resources.html) to apply to the filter. — item shape: {tagKey: string, tagValue: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.CreateFilter"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: datasetGroupArn, var: dataset_group_arn}, {name: filterExpression, var: filter_expression}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, dataset_group_arn: $dataset_group_arn, filter_expression: $filter_expression, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a metric attribution. A metric attribution creates reports on the data that you import into Amazon Personalize. Depending on how you imported the data, you can view reports in Amazon CloudWatch or Amazon S3. For more information, see Measuring impact of recommendations (https://docs.aws.amazon.com/personalize/latest/dg/measuring-recommendation-impact.html).
#
# POST /
# Returns: record<metricAttributionArn: string>
# operationId: CreateMetricAttribution
export def "create-metric-attribution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # A name for the metric attribution.
  dataset_group_arn: string # The Amazon Resource Name (ARN) of the destination dataset group for the metric attribution.
  metrics: list # A list of metric attributes for the metric attribution. Each metric attribute specifies an event type to track and a function. Available functions are SUM() or SAMPLECOUNT(). For SUM() functions, provide the dataset type (either Interactions or Items) and column to sum as a parameter. For example SUM(Items.PRICE). — item shape: {eventType: string, metricName: string, expression: string}
  metrics_output_config: record # The output configuration details for a metric attribution. — shape: {s3DataDestination?: record, roleArn: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.CreateMetricAttribution"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: datasetGroupArn, var: dataset_group_arn}, {name: metrics, var: metrics}, {name: metricsOutputConfig, var: metrics_output_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, dataset_group_arn: $dataset_group_arn, metrics: $metrics, metrics_output_config: $metrics_output_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a recommender with the recipe (a Domain dataset group use case) you specify. You create recommenders for a Domain dataset group and specify the recommender's Amazon Resource Name (ARN) when you make a GetRecommendations (https://docs.aws.amazon.com/personalize/latest/dg/API_RS_GetRecommendations.html) request. Minimum recommendation requests per second When you create a recommender, you can configure the recommender's minimum recommendation requests per second. The minimum recommendation requests per second (minRecommendationRequestsPerSecond) specifies the baseline recommendation request throughput provisioned by Amazon Personalize. The default minRecommendationRequestsPerSecond is 1. A recommendation request is a single GetRecommendations operation. Request throughput is measured in requests per second and Amazon Personalize uses your requests per second to derive your requests per hour and the price of your recommender usage. If your requests per second increases beyond minRecommendationRequestsPerSecond, Amazon Personalize auto-scales the provisioned capacity up and down, but never below minRecommendationRequestsPerSecond. There's a short time delay while the capacity is increased that might cause loss of requests. Your bill is the greater of either the minimum requests per hour (based on minRecommendationRequestsPerSecond) or the actual number of requests. The actual request throughput used is calculated as the average requests/second within a one-hour window. We recommend starting with the default minRecommendationRequestsPerSecond, track your usage using Amazon CloudWatch metrics, and then increase the minRecommendationRequestsPerSecond as necessary. Status A recommender can be in one of the following states: CREATE PENDING > CREATE IN_PROGRESS > ACTIVE -or- CREATE FAILED STOP PENDING > STOP IN_PROGRESS > INACTIVE > START PENDING > START IN_PROGRESS > ACTIVE DELETE PENDING > DELETE IN_PROGRESS To get the recommender status, call DescribeRecommender (https://docs.aws.amazon.com/personalize/latest/dg/API_DescribeRecommender.html). Wait until the status of the recommender is ACTIVE before asking the recommender for recommendations. Related APIs ListRecommenders (https://docs.aws.amazon.com/personalize/latest/dg/API_ListRecommenders.html) DescribeRecommender (https://docs.aws.amazon.com/personalize/latest/dg/API_DescribeRecommender.html) UpdateRecommender (https://docs.aws.amazon.com/personalize/latest/dg/API_UpdateRecommender.html) DeleteRecommender (https://docs.aws.amazon.com/personalize/latest/dg/API_DeleteRecommender.html)
#
# POST /
# Returns: record<recommenderArn: string>
# operationId: CreateRecommender
export def "create-recommender" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the recommender.
  dataset_group_arn: string # The Amazon Resource Name (ARN) of the destination domain dataset group for the recommender.
  recipe_arn: string # The Amazon Resource Name (ARN) of the recipe that the recommender will use. For a recommender, a recipe is a Domain dataset group use case. Only Domain dataset group use cases can be used to create a recommender. For information about use cases see Choosing recommender use cases (https://docs.aws.amazon.com/personalize/latest/dg/domain-use-cases.html).
  --recommender-config: record # The configuration details of the recommender. — shape: {itemExplorationConfig?: record, minRecommendationRequestsPerSecond?: int}
  --tags: list # A list of tags (https://docs.aws.amazon.com/personalize/latest/dev/tagging-resources.html) to apply to the recommender. — item shape: {tagKey: string, tagValue: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.CreateRecommender"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: datasetGroupArn, var: dataset_group_arn}, {name: recipeArn, var: recipe_arn}, {name: recommenderConfig, var: recommender_config}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, dataset_group_arn: $dataset_group_arn, recipe_arn: $recipe_arn, recommender_config: $recommender_config, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Amazon Personalize schema from the specified schema string. The schema you create must be in Avro JSON format. Amazon Personalize recognizes three schema variants. Each schema is associated with a dataset type and has a set of required field and keywords. If you are creating a schema for a dataset in a Domain dataset group, you provide the domain of the Domain dataset group. You specify a schema when you call CreateDataset (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateDataset.html). Related APIs ListSchemas (https://docs.aws.amazon.com/personalize/latest/dg/API_ListSchemas.html) DescribeSchema (https://docs.aws.amazon.com/personalize/latest/dg/API_DescribeSchema.html) DeleteSchema (https://docs.aws.amazon.com/personalize/latest/dg/API_DeleteSchema.html)
#
# POST /
# Returns: record<schemaArn: string>
# operationId: CreateSchema
export def "create-schema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name for the schema.
  schema: string # A schema in Avro JSON format.
  --domain: string@domain-completer # The domain for the schema. If you are creating a schema for a dataset in a Domain dataset group, specify the domain you chose when you created the Domain dataset group.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.CreateSchema"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: schema, var: schema}, {name: domain, var: domain}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, schema: $schema, domain: $domain
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates the configuration for training a model. A trained model is known as a solution. After the configuration is created, you train the model (create a solution) by calling the CreateSolutionVersion (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateSolutionVersion.html) operation. Every time you call CreateSolutionVersion, a new version of the solution is created. After creating a solution version, you check its accuracy by calling GetSolutionMetrics (https://docs.aws.amazon.com/personalize/latest/dg/API_GetSolutionMetrics.html). When you are satisfied with the version, you deploy it using CreateCampaign (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateCampaign.html). The campaign provides recommendations to a client through the GetRecommendations (https://docs.aws.amazon.com/personalize/latest/dg/API_RS_GetRecommendations.html) API. To train a model, Amazon Personalize requires training data and a recipe. The training data comes from the dataset group that you provide in the request. A recipe specifies the training algorithm and a feature transformation. You can specify one of the predefined recipes provided by Amazon Personalize. Alternatively, you can specify performAutoML and Amazon Personalize will analyze your data and select the optimum USER_PERSONALIZATION recipe for you. Amazon Personalize doesn't support configuring the hpoObjective for solution hyperparameter optimization at this time. Status A solution can be in one of the following states: CREATE PENDING > CREATE IN_PROGRESS > ACTIVE -or- CREATE FAILED DELETE PENDING > DELETE IN_PROGRESS To get the status of the solution, call DescribeSolution (https://docs.aws.amazon.com/personalize/latest/dg/API_DescribeSolution.html). Wait until the status shows as ACTIVE before calling CreateSolutionVersion. Related APIs ListSolutions (https://docs.aws.amazon.com/personalize/latest/dg/API_ListSolutions.html) CreateSolutionVersion (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateSolutionVersion.html) DescribeSolution (https://docs.aws.amazon.com/personalize/latest/dg/API_DescribeSolution.html) DeleteSolution (https://docs.aws.amazon.com/personalize/latest/dg/API_DeleteSolution.html) ListSolutionVersions (https://docs.aws.amazon.com/personalize/latest/dg/API_ListSolutionVersions.html) DescribeSolutionVersion (https://docs.aws.amazon.com/personalize/latest/dg/API_DescribeSolutionVersion.html)
#
# POST /
# Returns: record<solutionArn: string>
# operationId: CreateSolution
export def "create-solution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name for the solution.
  --perform-hpo: oneof<nothing, bool> # Whether to perform hyperparameter optimization (HPO) on the specified or selected recipe. The default is false. When performing AutoML, this parameter is always true and you should not set it to false.
  --perform-auto-ml: oneof<nothing, bool> # Whether to perform automated machine learning (AutoML). The default is false. For this case, you must specify recipeArn. When set to true, Amazon Personalize analyzes your training data and selects the optimal USER_PERSONALIZATION recipe and hyperparameters. In this case, you must omit recipeArn. Amazon Personalize determines the optimal recipe by running tests with different values for the hyperparameters. AutoML lengthens the training process as compared to selecting a specific recipe.
  --recipe-arn: string # The ARN of the recipe to use for model training. Only specified when performAutoML is false.
  dataset_group_arn: string # The Amazon Resource Name (ARN) of the dataset group that provides the training data.
  --event-type: string # When your have multiple event types (using an EVENT_TYPE schema field), this parameter specifies which event type (for example, 'click' or 'like') is used for training the model. If you do not provide an eventType, Amazon Personalize will use all interactions for training with equal weight regardless of type.
  --solution-config: record # Describes the configuration properties for the solution. — shape: {eventValueThreshold?: string, hpoConfig?: record, algorithmHyperParameters?: record, featureTransformationParameters?: record, autoMLConfig?: record, optimizationObjective?: record}
  --tags: list # A list of tags (https://docs.aws.amazon.com/personalize/latest/dev/tagging-resources.html) to apply to the solution. — item shape: {tagKey: string, tagValue: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.CreateSolution"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: performHPO, var: perform_hpo}, {name: performAutoML, var: perform_auto_ml}, {name: recipeArn, var: recipe_arn}, {name: datasetGroupArn, var: dataset_group_arn}, {name: eventType, var: event_type}, {name: solutionConfig, var: solution_config}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, perform_hpo: $perform_hpo, perform_auto_ml: $perform_auto_ml, recipe_arn: $recipe_arn, dataset_group_arn: $dataset_group_arn, event_type: $event_type, solution_config: $solution_config, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Trains or retrains an active solution in a Custom dataset group. A solution is created using the CreateSolution (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateSolution.html) operation and must be in the ACTIVE state before calling CreateSolutionVersion. A new version of the solution is created every time you call this operation. Status A solution version can be in one of the following states: CREATE PENDING CREATE IN_PROGRESS ACTIVE CREATE FAILED CREATE STOPPING CREATE STOPPED To get the status of the version, call DescribeSolutionVersion (https://docs.aws.amazon.com/personalize/latest/dg/API_DescribeSolutionVersion.html). Wait until the status shows as ACTIVE before calling CreateCampaign. If the status shows as CREATE FAILED, the response includes a failureReason key, which describes why the job failed. Related APIs ListSolutionVersions (https://docs.aws.amazon.com/personalize/latest/dg/API_ListSolutionVersions.html) DescribeSolutionVersion (https://docs.aws.amazon.com/personalize/latest/dg/API_DescribeSolutionVersion.html) ListSolutions (https://docs.aws.amazon.com/personalize/latest/dg/API_ListSolutions.html) CreateSolution (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateSolution.html) DescribeSolution (https://docs.aws.amazon.com/personalize/latest/dg/API_DescribeSolution.html) DeleteSolution (https://docs.aws.amazon.com/personalize/latest/dg/API_DeleteSolution.html)
#
# POST /
# Returns: record<solutionVersionArn: string>
# operationId: CreateSolutionVersion
export def "create-solution-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --name: string # The name of the solution version.
  solution_arn: string # The Amazon Resource Name (ARN) of the solution containing the training configuration information.
  --training-mode: string@training-mode-completer # The scope of training to be performed when creating the solution version. The FULL option trains the solution version based on the entirety of the input solution's training data, while the UPDATE option processes only the data that has changed in comparison to the input solution. Choose UPDATE when you want to incrementally update your solution version instead of creating an entirely new one. The UPDATE option can only be used when you already have an active solution version created from the input solution using the FULL option and the input solution was trained with the User-Personalization (https://docs.aws.amazon.com/personalize/latest/dg/native-recipe-new-item-USER_PERSONALIZATION.html) recipe or the HRNN-Coldstart (https://docs.aws.amazon.com/personalize/latest/dg/native-recipe-hrnn-coldstart.html) recipe.
  --tags: list # A list of tags (https://docs.aws.amazon.com/personalize/latest/dev/tagging-resources.html) to apply to the solution version. — item shape: {tagKey: string, tagValue: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.CreateSolutionVersion"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: solutionArn, var: solution_arn}, {name: trainingMode, var: training_mode}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, solution_arn: $solution_arn, training_mode: $training_mode, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a campaign by deleting the solution deployment. The solution that the campaign is based on is not deleted and can be redeployed when needed. A deleted campaign can no longer be specified in a GetRecommendations (https://docs.aws.amazon.com/personalize/latest/dg/API_RS_GetRecommendations.html) request. For information on creating campaigns, see CreateCampaign (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateCampaign.html).
#
# POST /
# operationId: DeleteCampaign
export def "delete-campaign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  campaign_arn: string # The Amazon Resource Name (ARN) of the campaign to delete.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.DeleteCampaign"}]
    body: {content_type: "application/json", kind: json, fields: [{name: campaignArn, var: campaign_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, campaign_arn: $campaign_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a dataset. You can't delete a dataset if an associated DatasetImportJob or SolutionVersion is in the CREATE PENDING or IN PROGRESS state. For more information on datasets, see CreateDataset (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateDataset.html).
#
# POST /
# operationId: DeleteDataset
export def "delete-dataset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  dataset_arn: string # The Amazon Resource Name (ARN) of the dataset to delete.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.DeleteDataset"}]
    body: {content_type: "application/json", kind: json, fields: [{name: datasetArn, var: dataset_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, dataset_arn: $dataset_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a dataset group. Before you delete a dataset group, you must delete the following: All associated event trackers. All associated solutions. All datasets in the dataset group.
#
# POST /
# operationId: DeleteDatasetGroup
export def "delete-dataset-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  dataset_group_arn: string # The ARN of the dataset group to delete.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.DeleteDatasetGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: datasetGroupArn, var: dataset_group_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, dataset_group_arn: $dataset_group_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the event tracker. Does not delete the event-interactions dataset from the associated dataset group. For more information on event trackers, see CreateEventTracker (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateEventTracker.html).
#
# POST /
# operationId: DeleteEventTracker
export def "delete-event-tracker" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  event_tracker_arn: string # The Amazon Resource Name (ARN) of the event tracker to delete.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.DeleteEventTracker"}]
    body: {content_type: "application/json", kind: json, fields: [{name: eventTrackerArn, var: event_tracker_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, event_tracker_arn: $event_tracker_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a filter.
#
# POST /
# operationId: DeleteFilter
export def "delete-filter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  filter_arn: string # The ARN of the filter to delete.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.DeleteFilter"}]
    body: {content_type: "application/json", kind: json, fields: [{name: filterArn, var: filter_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filter_arn: $filter_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a metric attribution.
#
# POST /
# operationId: DeleteMetricAttribution
export def "delete-metric-attribution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  metric_attribution_arn: string # The metric attribution's Amazon Resource Name (ARN).
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.DeleteMetricAttribution"}]
    body: {content_type: "application/json", kind: json, fields: [{name: metricAttributionArn, var: metric_attribution_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, metric_attribution_arn: $metric_attribution_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deactivates and removes a recommender. A deleted recommender can no longer be specified in a GetRecommendations (https://docs.aws.amazon.com/personalize/latest/dg/API_RS_GetRecommendations.html) request.
#
# POST /
# operationId: DeleteRecommender
export def "delete-recommender" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  recommender_arn: string # The Amazon Resource Name (ARN) of the recommender to delete.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.DeleteRecommender"}]
    body: {content_type: "application/json", kind: json, fields: [{name: recommenderArn, var: recommender_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, recommender_arn: $recommender_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a schema. Before deleting a schema, you must delete all datasets referencing the schema. For more information on schemas, see CreateSchema (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateSchema.html).
#
# POST /
# operationId: DeleteSchema
export def "delete-schema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  schema_arn: string # The Amazon Resource Name (ARN) of the schema to delete.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.DeleteSchema"}]
    body: {content_type: "application/json", kind: json, fields: [{name: schemaArn, var: schema_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, schema_arn: $schema_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes all versions of a solution and the Solution object itself. Before deleting a solution, you must delete all campaigns based on the solution. To determine what campaigns are using the solution, call ListCampaigns (https://docs.aws.amazon.com/personalize/latest/dg/API_ListCampaigns.html) and supply the Amazon Resource Name (ARN) of the solution. You can't delete a solution if an associated SolutionVersion is in the CREATE PENDING or IN PROGRESS state. For more information on solutions, see CreateSolution (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateSolution.html).
#
# POST /
# operationId: DeleteSolution
export def "delete-solution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  solution_arn: string # The ARN of the solution to delete.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.DeleteSolution"}]
    body: {content_type: "application/json", kind: json, fields: [{name: solutionArn, var: solution_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, solution_arn: $solution_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the given algorithm.
#
# POST /
# Returns: record<algorithm: record<name: string, algorithmArn: string, algorithmImage: record<name: string, dockerURI: string>, defaultHyperParameters: record, defaultHyperParameterRanges: record<integerHyperParameterRanges: list, continuousHyperParameterRanges: list, categoricalHyperParameterRanges: list>, defaultResourceConfig: record, trainingInputMode: string, roleArn: string, creationDateTime: string, lastUpdatedDateTime: string>>
# operationId: DescribeAlgorithm
export def "describe-algorithm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  algorithm_arn: string # The Amazon Resource Name (ARN) of the algorithm to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.DescribeAlgorithm"}]
    body: {content_type: "application/json", kind: json, fields: [{name: algorithmArn, var: algorithm_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, algorithm_arn: $algorithm_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the properties of a batch inference job including name, Amazon Resource Name (ARN), status, input and output configurations, and the ARN of the solution version used to generate the recommendations.
#
# POST /
# Returns: record<batchInferenceJob: record<jobName: string, batchInferenceJobArn: string, filterArn: string, failureReason: string, solutionVersionArn: string, numResults: int, jobInput: record<s3DataSource: record>, jobOutput: record<s3DataDestination: record>, batchInferenceJobConfig: record<itemExplorationConfig: record>, roleArn: string, status: string, creationDateTime: string, lastUpdatedDateTime: string>>
# operationId: DescribeBatchInferenceJob
export def "describe-batch-inference-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  batch_inference_job_arn: string # The ARN of the batch inference job to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.DescribeBatchInferenceJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: batchInferenceJobArn, var: batch_inference_job_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, batch_inference_job_arn: $batch_inference_job_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the properties of a batch segment job including name, Amazon Resource Name (ARN), status, input and output configurations, and the ARN of the solution version used to generate segments.
#
# POST /
# Returns: record<batchSegmentJob: record<jobName: string, batchSegmentJobArn: string, filterArn: string, failureReason: string, solutionVersionArn: string, numResults: int, jobInput: record<s3DataSource: record>, jobOutput: record<s3DataDestination: record>, roleArn: string, status: string, creationDateTime: string, lastUpdatedDateTime: string>>
# operationId: DescribeBatchSegmentJob
export def "describe-batch-segment-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  batch_segment_job_arn: string # The ARN of the batch segment job to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.DescribeBatchSegmentJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: batchSegmentJobArn, var: batch_segment_job_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, batch_segment_job_arn: $batch_segment_job_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the given campaign, including its status. A campaign can be in one of the following states: CREATE PENDING > CREATE IN_PROGRESS > ACTIVE -or- CREATE FAILED DELETE PENDING > DELETE IN_PROGRESS When the status is CREATE FAILED, the response includes the failureReason key, which describes why. For more information on campaigns, see CreateCampaign (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateCampaign.html).
#
# POST /
# Returns: record<campaign: record<name: string, campaignArn: string, solutionVersionArn: string, minProvisionedTPS: int, campaignConfig: record<itemExplorationConfig: record>, status: string, failureReason: string, creationDateTime: string, lastUpdatedDateTime: string, latestCampaignUpdate: record<solutionVersionArn: string, minProvisionedTPS: int, campaignConfig: record, status: string, failureReason: string, creationDateTime: string, lastUpdatedDateTime: string>>>
# operationId: DescribeCampaign
export def "describe-campaign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  campaign_arn: string # The Amazon Resource Name (ARN) of the campaign.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.DescribeCampaign"}]
    body: {content_type: "application/json", kind: json, fields: [{name: campaignArn, var: campaign_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, campaign_arn: $campaign_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the given dataset. For more information on datasets, see CreateDataset (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateDataset.html).
#
# POST /
# Returns: record<dataset: record<name: string, datasetArn: string, datasetGroupArn: string, datasetType: string, schemaArn: string, status: string, creationDateTime: string, lastUpdatedDateTime: string>>
# operationId: DescribeDataset
export def "describe-dataset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-27 # required
  dataset_arn: string # The Amazon Resource Name (ARN) of the dataset to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.DescribeDataset"}]
    body: {content_type: "application/json", kind: json, fields: [{name: datasetArn, var: dataset_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, dataset_arn: $dataset_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the dataset export job created by CreateDatasetExportJob (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateDatasetExportJob.html), including the export job status.
#
# POST /
# Returns: record<datasetExportJob: record<jobName: string, datasetExportJobArn: string, datasetArn: string, ingestionMode: string, roleArn: string, status: string, jobOutput: record<s3DataDestination: record>, creationDateTime: string, lastUpdatedDateTime: string, failureReason: string>>
# operationId: DescribeDatasetExportJob
export def "describe-dataset-export-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-28 # required
  dataset_export_job_arn: string # The Amazon Resource Name (ARN) of the dataset export job to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.DescribeDatasetExportJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: datasetExportJobArn, var: dataset_export_job_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, dataset_export_job_arn: $dataset_export_job_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the given dataset group. For more information on dataset groups, see CreateDatasetGroup (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateDatasetGroup.html).
#
# POST /
# Returns: record<datasetGroup: record<name: string, datasetGroupArn: string, status: string, roleArn: string, kmsKeyArn: string, creationDateTime: string, lastUpdatedDateTime: string, failureReason: string, domain: string>>
# operationId: DescribeDatasetGroup
export def "describe-dataset-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-29 # required
  dataset_group_arn: string # The Amazon Resource Name (ARN) of the dataset group to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.DescribeDatasetGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: datasetGroupArn, var: dataset_group_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, dataset_group_arn: $dataset_group_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the dataset import job created by CreateDatasetImportJob (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateDatasetImportJob.html), including the import job status.
#
# POST /
# Returns: record<datasetImportJob: record<jobName: string, datasetImportJobArn: string, datasetArn: string, dataSource: record<dataLocation: string>, roleArn: string, status: string, creationDateTime: string, lastUpdatedDateTime: string, failureReason: string, importMode: string, publishAttributionMetricsToS3: bool>>
# operationId: DescribeDatasetImportJob
export def "describe-dataset-import-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  dataset_import_job_arn: string # The Amazon Resource Name (ARN) of the dataset import job to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.DescribeDatasetImportJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: datasetImportJobArn, var: dataset_import_job_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, dataset_import_job_arn: $dataset_import_job_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes an event tracker. The response includes the trackingId and status of the event tracker. For more information on event trackers, see CreateEventTracker (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateEventTracker.html).
#
# POST /
# Returns: record<eventTracker: record<name: string, eventTrackerArn: string, accountId: string, trackingId: string, datasetGroupArn: string, status: string, creationDateTime: string, lastUpdatedDateTime: string>>
# operationId: DescribeEventTracker
export def "describe-event-tracker" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-31 # required
  event_tracker_arn: string # The Amazon Resource Name (ARN) of the event tracker to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.DescribeEventTracker"}]
    body: {content_type: "application/json", kind: json, fields: [{name: eventTrackerArn, var: event_tracker_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, event_tracker_arn: $event_tracker_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the given feature transformation.
#
# POST /
# Returns: record<featureTransformation: record<name: string, featureTransformationArn: string, defaultParameters: record, creationDateTime: string, lastUpdatedDateTime: string, status: string>>
# operationId: DescribeFeatureTransformation
export def "describe-feature-transformation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  feature_transformation_arn: string # The Amazon Resource Name (ARN) of the feature transformation to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.DescribeFeatureTransformation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: featureTransformationArn, var: feature_transformation_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, feature_transformation_arn: $feature_transformation_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a filter's properties.
#
# POST /
# Returns: record<filter: record<name: string, filterArn: string, creationDateTime: string, lastUpdatedDateTime: string, datasetGroupArn: string, failureReason: string, filterExpression: string, status: string>>
# operationId: DescribeFilter
export def "describe-filter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  filter_arn: string # The ARN of the filter to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.DescribeFilter"}]
    body: {content_type: "application/json", kind: json, fields: [{name: filterArn, var: filter_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filter_arn: $filter_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a metric attribution.
#
# POST /
# Returns: record<metricAttribution: record<name: string, metricAttributionArn: string, datasetGroupArn: string, metricsOutputConfig: record<s3DataDestination: record, roleArn: string>, status: string, creationDateTime: string, lastUpdatedDateTime: string, failureReason: string>>
# operationId: DescribeMetricAttribution
export def "describe-metric-attribution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  metric_attribution_arn: string # The metric attribution's Amazon Resource Name (ARN).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.DescribeMetricAttribution"}]
    body: {content_type: "application/json", kind: json, fields: [{name: metricAttributionArn, var: metric_attribution_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, metric_attribution_arn: $metric_attribution_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a recipe. A recipe contains three items: An algorithm that trains a model. Hyperparameters that govern the training. Feature transformation information for modifying the input data before training. Amazon Personalize provides a set of predefined recipes. You specify a recipe when you create a solution with the CreateSolution (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateSolution.html) API. CreateSolution trains a model by using the algorithm in the specified recipe and a training dataset. The solution, when deployed as a campaign, can provide recommendations using the GetRecommendations (https://docs.aws.amazon.com/personalize/latest/dg/API_RS_GetRecommendations.html) API.
#
# POST /
# Returns: record<recipe: record<name: string, recipeArn: string, algorithmArn: string, featureTransformationArn: string, status: string, description: string, creationDateTime: string, recipeType: string, lastUpdatedDateTime: string>>
# operationId: DescribeRecipe
export def "describe-recipe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  recipe_arn: string # The Amazon Resource Name (ARN) of the recipe to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.DescribeRecipe"}]
    body: {content_type: "application/json", kind: json, fields: [{name: recipeArn, var: recipe_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, recipe_arn: $recipe_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the given recommender, including its status. A recommender can be in one of the following states: CREATE PENDING > CREATE IN_PROGRESS > ACTIVE -or- CREATE FAILED STOP PENDING > STOP IN_PROGRESS > INACTIVE > START PENDING > START IN_PROGRESS > ACTIVE DELETE PENDING > DELETE IN_PROGRESS When the status is CREATE FAILED, the response includes the failureReason key, which describes why. The modelMetrics key is null when the recommender is being created or deleted. For more information on recommenders, see CreateRecommender (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateRecommender.html).
#
# POST /
# Returns: record<recommender: record<recommenderArn: string, datasetGroupArn: string, name: string, recipeArn: string, recommenderConfig: record<itemExplorationConfig: record, minRecommendationRequestsPerSecond: int>, creationDateTime: string, lastUpdatedDateTime: string, status: string, failureReason: string, latestRecommenderUpdate: record<recommenderConfig: record, creationDateTime: string, lastUpdatedDateTime: string, status: string, failureReason: string>, modelMetrics: record>>
# operationId: DescribeRecommender
export def "describe-recommender" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  recommender_arn: string # The Amazon Resource Name (ARN) of the recommender to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.DescribeRecommender"}]
    body: {content_type: "application/json", kind: json, fields: [{name: recommenderArn, var: recommender_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, recommender_arn: $recommender_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a schema. For more information on schemas, see CreateSchema (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateSchema.html).
#
# POST /
# Returns: record<schema: record<name: string, schemaArn: string, schema: string, creationDateTime: string, lastUpdatedDateTime: string, domain: string>>
# operationId: DescribeSchema
export def "describe-schema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  schema_arn: string # The Amazon Resource Name (ARN) of the schema to retrieve.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.DescribeSchema"}]
    body: {content_type: "application/json", kind: json, fields: [{name: schemaArn, var: schema_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, schema_arn: $schema_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a solution. For more information on solutions, see CreateSolution (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateSolution.html).
#
# POST /
# Returns: record<solution: record<name: string, solutionArn: string, performHPO: bool, performAutoML: bool, recipeArn: string, datasetGroupArn: string, eventType: string, solutionConfig: record<eventValueThreshold: string, hpoConfig: record, algorithmHyperParameters: record, featureTransformationParameters: record, autoMLConfig: record, optimizationObjective: record>, autoMLResult: record<bestRecipeArn: string>, status: string, creationDateTime: string, lastUpdatedDateTime: string, latestSolutionVersion: record<solutionVersionArn: string, status: string, creationDateTime: string, lastUpdatedDateTime: string, failureReason: string>>>
# operationId: DescribeSolution
export def "describe-solution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  solution_arn: string # The Amazon Resource Name (ARN) of the solution to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.DescribeSolution"}]
    body: {content_type: "application/json", kind: json, fields: [{name: solutionArn, var: solution_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, solution_arn: $solution_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a specific version of a solution. For more information on solutions, see CreateSolution (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateSolution.html)
#
# POST /
# Returns: record<solutionVersion: record<name: string, solutionVersionArn: string, solutionArn: string, performHPO: bool, performAutoML: bool, recipeArn: string, eventType: string, datasetGroupArn: string, solutionConfig: record<eventValueThreshold: string, hpoConfig: record, algorithmHyperParameters: record, featureTransformationParameters: record, autoMLConfig: record, optimizationObjective: record>, trainingHours: float, trainingMode: string, tunedHPOParams: record<algorithmHyperParameters: record>, status: string, failureReason: string, creationDateTime: string, lastUpdatedDateTime: string>>
# operationId: DescribeSolutionVersion
export def "describe-solution-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  solution_version_arn: string # The Amazon Resource Name (ARN) of the solution version.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.DescribeSolutionVersion"}]
    body: {content_type: "application/json", kind: json, fields: [{name: solutionVersionArn, var: solution_version_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, solution_version_arn: $solution_version_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the metrics for the specified solution version.
#
# POST /
# Returns: record<solutionVersionArn: string, metrics: record>
# operationId: GetSolutionMetrics
export def "get-solution-metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  solution_version_arn: string # The Amazon Resource Name (ARN) of the solution version for which to get metrics.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.GetSolutionMetrics"}]
    body: {content_type: "application/json", kind: json, fields: [{name: solutionVersionArn, var: solution_version_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, solution_version_arn: $solution_version_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of the batch inference jobs that have been performed off of a solution version.
#
# POST /
# Returns: record<batchInferenceJobs: table<batchInferenceJobArn: string, jobName: string, status: string, creationDateTime: string, lastUpdatedDateTime: string, failureReason: string, solutionVersionArn: string>, nextToken: string>
# operationId: ListBatchInferenceJobs
export def "list-batch-inference-jobs" [
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
  --x-amz-target: string@x-amz-target-completer-41 # required
  --solution-version-arn: string # The Amazon Resource Name (ARN) of the solution version from which the batch inference jobs were created.
  --body-next-token: string # The token to request the next page of results. (spec name: nextToken)
  --body-max-results: int # The maximum number of batch inference job results to return in each page. The default value is 100. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.ListBatchInferenceJobs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: solutionVersionArn, var: solution_version_arn}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, solution_version_arn: $solution_version_arn, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of the batch segment jobs that have been performed off of a solution version that you specify.
#
# POST /
# Returns: record<batchSegmentJobs: table<batchSegmentJobArn: string, jobName: string, status: string, creationDateTime: string, lastUpdatedDateTime: string, failureReason: string, solutionVersionArn: string>, nextToken: string>
# operationId: ListBatchSegmentJobs
export def "list-batch-segment-jobs" [
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
  --solution-version-arn: string # The Amazon Resource Name (ARN) of the solution version that the batch segment jobs used to generate batch segments.
  --body-next-token: string # The token to request the next page of results. (spec name: nextToken)
  --body-max-results: int # The maximum number of batch segment job results to return in each page. The default value is 100. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.ListBatchSegmentJobs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: solutionVersionArn, var: solution_version_arn}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, solution_version_arn: $solution_version_arn, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of campaigns that use the given solution. When a solution is not specified, all the campaigns associated with the account are listed. The response provides the properties for each campaign, including the Amazon Resource Name (ARN). For more information on campaigns, see CreateCampaign (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateCampaign.html).
#
# POST /
# Returns: record<campaigns: table<name: string, campaignArn: string, status: string, creationDateTime: string, lastUpdatedDateTime: string, failureReason: string>, nextToken: string>
# operationId: ListCampaigns
export def "list-campaigns" [
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
  --solution-arn: string # The Amazon Resource Name (ARN) of the solution to list the campaigns for. When a solution is not specified, all the campaigns associated with the account are listed.
  --body-next-token: string # A token returned from the previous call to ListCampaigns (https://docs.aws.amazon.com/personalize/latest/dg/API_ListCampaigns.html) for getting the next set of campaigns (if they exist). (spec name: nextToken)
  --body-max-results: int # The maximum number of campaigns to return. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.ListCampaigns"}]
    body: {content_type: "application/json", kind: json, fields: [{name: solutionArn, var: solution_arn}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, solution_arn: $solution_arn, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of dataset export jobs that use the given dataset. When a dataset is not specified, all the dataset export jobs associated with the account are listed. The response provides the properties for each dataset export job, including the Amazon Resource Name (ARN). For more information on dataset export jobs, see CreateDatasetExportJob (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateDatasetExportJob.html). For more information on datasets, see CreateDataset (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateDataset.html).
#
# POST /
# Returns: record<datasetExportJobs: table<datasetExportJobArn: string, jobName: string, status: string, creationDateTime: string, lastUpdatedDateTime: string, failureReason: string>, nextToken: string>
# operationId: ListDatasetExportJobs
export def "list-dataset-export-jobs" [
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
  --x-amz-target: string@x-amz-target-completer-44 # required
  --dataset-arn: string # The Amazon Resource Name (ARN) of the dataset to list the dataset export jobs for.
  --body-next-token: string # A token returned from the previous call to ListDatasetExportJobs for getting the next set of dataset export jobs (if they exist). (spec name: nextToken)
  --body-max-results: int # The maximum number of dataset export jobs to return. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.ListDatasetExportJobs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: datasetArn, var: dataset_arn}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, dataset_arn: $dataset_arn, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of dataset groups. The response provides the properties for each dataset group, including the Amazon Resource Name (ARN). For more information on dataset groups, see CreateDatasetGroup (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateDatasetGroup.html).
#
# POST /
# Returns: record<datasetGroups: table<name: string, datasetGroupArn: string, status: string, creationDateTime: string, lastUpdatedDateTime: string, failureReason: string, domain: string>, nextToken: string>
# operationId: ListDatasetGroups
export def "list-dataset-groups" [
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
  --body-next-token: string # A token returned from the previous call to ListDatasetGroups for getting the next set of dataset groups (if they exist). (spec name: nextToken)
  --body-max-results: int # The maximum number of dataset groups to return. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.ListDatasetGroups"}]
    body: {content_type: "application/json", kind: json, fields: [{name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of dataset import jobs that use the given dataset. When a dataset is not specified, all the dataset import jobs associated with the account are listed. The response provides the properties for each dataset import job, including the Amazon Resource Name (ARN). For more information on dataset import jobs, see CreateDatasetImportJob (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateDatasetImportJob.html). For more information on datasets, see CreateDataset (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateDataset.html).
#
# POST /
# Returns: record<datasetImportJobs: table<datasetImportJobArn: string, jobName: string, status: string, creationDateTime: string, lastUpdatedDateTime: string, failureReason: string, importMode: string>, nextToken: string>
# operationId: ListDatasetImportJobs
export def "list-dataset-import-jobs" [
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
  --x-amz-target: string@x-amz-target-completer-46 # required
  --dataset-arn: string # The Amazon Resource Name (ARN) of the dataset to list the dataset import jobs for.
  --body-next-token: string # A token returned from the previous call to ListDatasetImportJobs for getting the next set of dataset import jobs (if they exist). (spec name: nextToken)
  --body-max-results: int # The maximum number of dataset import jobs to return. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.ListDatasetImportJobs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: datasetArn, var: dataset_arn}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, dataset_arn: $dataset_arn, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of datasets contained in the given dataset group. The response provides the properties for each dataset, including the Amazon Resource Name (ARN). For more information on datasets, see CreateDataset (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateDataset.html).
#
# POST /
# Returns: record<datasets: table<name: string, datasetArn: string, datasetType: string, status: string, creationDateTime: string, lastUpdatedDateTime: string>, nextToken: string>
# operationId: ListDatasets
export def "list-datasets" [
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
  --dataset-group-arn: string # The Amazon Resource Name (ARN) of the dataset group that contains the datasets to list.
  --body-next-token: string # A token returned from the previous call to ListDatasetImportJobs for getting the next set of dataset import jobs (if they exist). (spec name: nextToken)
  --body-max-results: int # The maximum number of datasets to return. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.ListDatasets"}]
    body: {content_type: "application/json", kind: json, fields: [{name: datasetGroupArn, var: dataset_group_arn}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, dataset_group_arn: $dataset_group_arn, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of event trackers associated with the account. The response provides the properties for each event tracker, including the Amazon Resource Name (ARN) and tracking ID. For more information on event trackers, see CreateEventTracker (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateEventTracker.html).
#
# POST /
# Returns: record<eventTrackers: table<name: string, eventTrackerArn: string, status: string, creationDateTime: string, lastUpdatedDateTime: string>, nextToken: string>
# operationId: ListEventTrackers
export def "list-event-trackers" [
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
  --x-amz-target: string@x-amz-target-completer-48 # required
  --dataset-group-arn: string # The ARN of a dataset group used to filter the response.
  --body-next-token: string # A token returned from the previous call to ListEventTrackers for getting the next set of event trackers (if they exist). (spec name: nextToken)
  --body-max-results: int # The maximum number of event trackers to return. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.ListEventTrackers"}]
    body: {content_type: "application/json", kind: json, fields: [{name: datasetGroupArn, var: dataset_group_arn}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, dataset_group_arn: $dataset_group_arn, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all filters that belong to a given dataset group.
#
# POST /
# Returns: record<Filters: table<name: string, filterArn: string, creationDateTime: string, lastUpdatedDateTime: string, datasetGroupArn: string, failureReason: string, status: string>, nextToken: string>
# operationId: ListFilters
export def "list-filters" [
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
  --x-amz-target: string@x-amz-target-completer-49 # required
  --dataset-group-arn: string # The ARN of the dataset group that contains the filters.
  --body-next-token: string # A token returned from the previous call to ListFilters for getting the next set of filters (if they exist). (spec name: nextToken)
  --body-max-results: int # The maximum number of filters to return. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.ListFilters"}]
    body: {content_type: "application/json", kind: json, fields: [{name: datasetGroupArn, var: dataset_group_arn}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, dataset_group_arn: $dataset_group_arn, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the metrics for the metric attribution.
#
# POST /
# Returns: record<metrics: table<eventType: string, metricName: string, expression: string>, nextToken: string>
# operationId: ListMetricAttributionMetrics
export def "list-metric-attribution-metrics" [
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
  --x-amz-target: string@x-amz-target-completer-50 # required
  --metric-attribution-arn: string # The Amazon Resource Name (ARN) of the metric attribution to retrieve attributes for.
  --body-next-token: string # Specify the pagination token from a previous request to retrieve the next page of results. (spec name: nextToken)
  --body-max-results: int # The maximum number of metrics to return in one page of results. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.ListMetricAttributionMetrics"}]
    body: {content_type: "application/json", kind: json, fields: [{name: metricAttributionArn, var: metric_attribution_arn}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, metric_attribution_arn: $metric_attribution_arn, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists metric attributions.
#
# POST /
# Returns: record<metricAttributions: table<name: string, metricAttributionArn: string, status: string, creationDateTime: string, lastUpdatedDateTime: string, failureReason: string>, nextToken: string>
# operationId: ListMetricAttributions
export def "list-metric-attributions" [
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
  --x-amz-target: string@x-amz-target-completer-51 # required
  --dataset-group-arn: string # The metric attributions' dataset group Amazon Resource Name (ARN).
  --body-next-token: string # Specify the pagination token from a previous request to retrieve the next page of results. (spec name: nextToken)
  --body-max-results: int # The maximum number of metric attributions to return in one page of results. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.ListMetricAttributions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: datasetGroupArn, var: dataset_group_arn}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, dataset_group_arn: $dataset_group_arn, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of available recipes. The response provides the properties for each recipe, including the recipe's Amazon Resource Name (ARN).
#
# POST /
# Returns: record<recipes: table<name: string, recipeArn: string, status: string, creationDateTime: string, lastUpdatedDateTime: string, domain: string>, nextToken: string>
# operationId: ListRecipes
export def "list-recipes" [
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
  --x-amz-target: string@x-amz-target-completer-52 # required
  --recipe-provider: string@recipe-provider-completer # The default is SERVICE.
  --body-next-token: string # A token returned from the previous call to ListRecipes for getting the next set of recipes (if they exist). (spec name: nextToken)
  --body-max-results: int # The maximum number of recipes to return. (spec name: maxResults)
  --domain: string@domain-completer # Filters returned recipes by domain for a Domain dataset group. Only recipes (Domain dataset group use cases) for this domain are included in the response. If you don't specify a domain, all recipes are returned.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.ListRecipes"}]
    body: {content_type: "application/json", kind: json, fields: [{name: recipeProvider, var: recipe_provider}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}, {name: domain, var: domain}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, recipe_provider: $recipe_provider, body_next_token: $body_next_token, body_max_results: $body_max_results, domain: $domain
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of recommenders in a given Domain dataset group. When a Domain dataset group is not specified, all the recommenders associated with the account are listed. The response provides the properties for each recommender, including the Amazon Resource Name (ARN). For more information on recommenders, see CreateRecommender (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateRecommender.html).
#
# POST /
# Returns: record<recommenders: table<name: string, recommenderArn: string, datasetGroupArn: string, recipeArn: string, recommenderConfig: record, status: string, creationDateTime: string, lastUpdatedDateTime: string>, nextToken: string>
# operationId: ListRecommenders
export def "list-recommenders" [
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
  --x-amz-target: string@x-amz-target-completer-53 # required
  --dataset-group-arn: string # The Amazon Resource Name (ARN) of the Domain dataset group to list the recommenders for. When a Domain dataset group is not specified, all the recommenders associated with the account are listed.
  --body-next-token: string # A token returned from the previous call to ListRecommenders for getting the next set of recommenders (if they exist). (spec name: nextToken)
  --body-max-results: int # The maximum number of recommenders to return. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.ListRecommenders"}]
    body: {content_type: "application/json", kind: json, fields: [{name: datasetGroupArn, var: dataset_group_arn}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, dataset_group_arn: $dataset_group_arn, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of schemas associated with the account. The response provides the properties for each schema, including the Amazon Resource Name (ARN). For more information on schemas, see CreateSchema (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateSchema.html).
#
# POST /
# Returns: record<schemas: table<name: string, schemaArn: string, creationDateTime: string, lastUpdatedDateTime: string, domain: string>, nextToken: string>
# operationId: ListSchemas
export def "list-schemas" [
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
  --x-amz-target: string@x-amz-target-completer-54 # required
  --body-next-token: string # A token returned from the previous call to ListSchemas for getting the next set of schemas (if they exist). (spec name: nextToken)
  --body-max-results: int # The maximum number of schemas to return. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.ListSchemas"}]
    body: {content_type: "application/json", kind: json, fields: [{name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of solution versions for the given solution. When a solution is not specified, all the solution versions associated with the account are listed. The response provides the properties for each solution version, including the Amazon Resource Name (ARN).
#
# POST /
# Returns: record<solutionVersions: table<solutionVersionArn: string, status: string, creationDateTime: string, lastUpdatedDateTime: string, failureReason: string>, nextToken: string>
# operationId: ListSolutionVersions
export def "list-solution-versions" [
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
  --x-amz-target: string@x-amz-target-completer-55 # required
  --solution-arn: string # The Amazon Resource Name (ARN) of the solution.
  --body-next-token: string # A token returned from the previous call to ListSolutionVersions for getting the next set of solution versions (if they exist). (spec name: nextToken)
  --body-max-results: int # The maximum number of solution versions to return. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.ListSolutionVersions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: solutionArn, var: solution_arn}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, solution_arn: $solution_arn, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of solutions that use the given dataset group. When a dataset group is not specified, all the solutions associated with the account are listed. The response provides the properties for each solution, including the Amazon Resource Name (ARN). For more information on solutions, see CreateSolution (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateSolution.html).
#
# POST /
# Returns: record<solutions: table<name: string, solutionArn: string, status: string, creationDateTime: string, lastUpdatedDateTime: string, recipeArn: string>, nextToken: string>
# operationId: ListSolutions
export def "list-solutions" [
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
  --x-amz-target: string@x-amz-target-completer-56 # required
  --dataset-group-arn: string # The Amazon Resource Name (ARN) of the dataset group.
  --body-next-token: string # A token returned from the previous call to ListSolutions for getting the next set of solutions (if they exist). (spec name: nextToken)
  --body-max-results: int # The maximum number of solutions to return. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.ListSolutions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: datasetGroupArn, var: dataset_group_arn}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, dataset_group_arn: $dataset_group_arn, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of tags (https://docs.aws.amazon.com/personalize/latest/dev/tagging-resources.html) attached to a resource.
#
# POST /
# Returns: record<tags: table<tagKey: string, tagValue: string>>
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
  --x-amz-target: string@x-amz-target-completer-57 # required
  resource_arn: string # The resource's Amazon Resource Name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.ListTagsForResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceArn, var: resource_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a recommender that is INACTIVE. Starting a recommender does not create any new models, but resumes billing and automatic retraining for the recommender.
#
# POST /
# Returns: record<recommenderArn: string>
# operationId: StartRecommender
export def "start-recommender" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  recommender_arn: string # The Amazon Resource Name (ARN) of the recommender to start.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.StartRecommender"}]
    body: {content_type: "application/json", kind: json, fields: [{name: recommenderArn, var: recommender_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, recommender_arn: $recommender_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops a recommender that is ACTIVE. Stopping a recommender halts billing and automatic retraining for the recommender.
#
# POST /
# Returns: record<recommenderArn: string>
# operationId: StopRecommender
export def "stop-recommender" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  recommender_arn: string # The Amazon Resource Name (ARN) of the recommender to stop.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.StopRecommender"}]
    body: {content_type: "application/json", kind: json, fields: [{name: recommenderArn, var: recommender_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, recommender_arn: $recommender_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops creating a solution version that is in a state of CREATE_PENDING or CREATE IN_PROGRESS. Depending on the current state of the solution version, the solution version state changes as follows: CREATE_PENDING > CREATE_STOPPED or CREATE_IN_PROGRESS > CREATE_STOPPING > CREATE_STOPPED You are billed for all of the training completed up until you stop the solution version creation. You cannot resume creating a solution version once it has been stopped.
#
# POST /
# operationId: StopSolutionVersionCreation
export def "stop-solution-version-creation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  solution_version_arn: string # The Amazon Resource Name (ARN) of the solution version you want to stop creating.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.StopSolutionVersionCreation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: solutionVersionArn, var: solution_version_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, solution_version_arn: $solution_version_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a list of tags to a resource.
#
# POST /
# Returns: record
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
  --x-amz-target: string@x-amz-target-completer-61 # required
  resource_arn: string # The resource's Amazon Resource Name (ARN).
  tags: list # Tags to apply to the resource. For more information see Tagging Personalize resources (https://docs.aws.amazon.com/personalize/latest/dev/tagging-resources.html). — item shape: {tagKey: string, tagValue: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.TagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceArn, var: resource_arn}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove tags (https://docs.aws.amazon.com/personalize/latest/dev/tagging-resources.html) that are attached to a resource.
#
# POST /
# Returns: record
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
  --x-amz-target: string@x-amz-target-completer-62 # required
  resource_arn: string # The resource's Amazon Resource Name (ARN).
  tag_keys: list<string> # Keys to remove from the resource's tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.UntagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceArn, var: resource_arn}, {name: tagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a campaign by either deploying a new solution or changing the value of the campaign's minProvisionedTPS parameter. To update a campaign, the campaign status must be ACTIVE or CREATE FAILED. Check the campaign status using the DescribeCampaign (https://docs.aws.amazon.com/personalize/latest/dg/API_DescribeCampaign.html) operation. You can still get recommendations from a campaign while an update is in progress. The campaign will use the previous solution version and campaign configuration to generate recommendations until the latest campaign update status is Active. For more information on campaigns, see CreateCampaign (https://docs.aws.amazon.com/personalize/latest/dg/API_CreateCampaign.html).
#
# POST /
# Returns: record<campaignArn: string>
# operationId: UpdateCampaign
export def "update-campaign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  campaign_arn: string # The Amazon Resource Name (ARN) of the campaign.
  --solution-version-arn: string # The ARN of a new solution version to deploy.
  --min-provisioned-tps: int # Specifies the requested minimum provisioned transactions (recommendations) per second that Amazon Personalize will support.
  --campaign-config: record # The configuration details of a campaign. — shape: {itemExplorationConfig?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.UpdateCampaign"}]
    body: {content_type: "application/json", kind: json, fields: [{name: campaignArn, var: campaign_arn}, {name: solutionVersionArn, var: solution_version_arn}, {name: minProvisionedTPS, var: min_provisioned_tps}, {name: campaignConfig, var: campaign_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, campaign_arn: $campaign_arn, solution_version_arn: $solution_version_arn, min_provisioned_tps: $min_provisioned_tps, campaign_config: $campaign_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a metric attribution.
#
# POST /
# Returns: record<metricAttributionArn: string>
# operationId: UpdateMetricAttribution
export def "update-metric-attribution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --add-metrics: list # Add new metric attributes to the metric attribution. — item shape: {eventType: string, metricName: string, expression: string}
  --remove-metrics: list<string> # Remove metric attributes from the metric attribution.
  --metrics-output-config: record # The output configuration details for a metric attribution. — shape: {s3DataDestination?: record, roleArn: string}
  --metric-attribution-arn: string # The Amazon Resource Name (ARN) for the metric attribution to update.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.UpdateMetricAttribution"}]
    body: {content_type: "application/json", kind: json, fields: [{name: addMetrics, var: add_metrics}, {name: removeMetrics, var: remove_metrics}, {name: metricsOutputConfig, var: metrics_output_config}, {name: metricAttributionArn, var: metric_attribution_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, add_metrics: $add_metrics, remove_metrics: $remove_metrics, metrics_output_config: $metrics_output_config, metric_attribution_arn: $metric_attribution_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the recommender to modify the recommender configuration.
#
# POST /
# Returns: record<recommenderArn: string>
# operationId: UpdateRecommender
export def "update-recommender" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  recommender_arn: string # The Amazon Resource Name (ARN) of the recommender to modify.
  recommender_config: record # The configuration details of the recommender. — shape: {itemExplorationConfig?: record, minRecommendationRequestsPerSecond?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonPersonalize.UpdateRecommender"}]
    body: {content_type: "application/json", kind: json, fields: [{name: recommenderArn, var: recommender_arn}, {name: recommenderConfig, var: recommender_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, recommender_arn: $recommender_arn, recommender_config: $recommender_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
