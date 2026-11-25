# Auto-generated client for Amazon Translate v2017-07-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/translate/2017-07-01/openapi.json
# Auth: --token flag or $env.AMAZON_TRANSLATE_TOKEN

const CLIENT = {
  base_url: "http://translate.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_TRANSLATE_TOKEN"
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

def base-url-completer [] { ["http://translate.us-east-1.amazonaws.com" "http://translate.us-east-2.amazonaws.com" "http://translate.us-west-1.amazonaws.com" "http://translate.us-west-2.amazonaws.com" "http://translate.us-gov-west-1.amazonaws.com" "http://translate.us-gov-east-1.amazonaws.com" "http://translate.ca-central-1.amazonaws.com" "http://translate.eu-north-1.amazonaws.com" "http://translate.eu-west-1.amazonaws.com" "http://translate.eu-west-2.amazonaws.com" "http://translate.eu-west-3.amazonaws.com" "http://translate.eu-central-1.amazonaws.com" "http://translate.eu-south-1.amazonaws.com" "http://translate.af-south-1.amazonaws.com" "http://translate.ap-northeast-1.amazonaws.com" "http://translate.ap-northeast-2.amazonaws.com" "http://translate.ap-northeast-3.amazonaws.com" "http://translate.ap-southeast-1.amazonaws.com" "http://translate.ap-southeast-2.amazonaws.com" "http://translate.ap-east-1.amazonaws.com" "http://translate.ap-south-1.amazonaws.com" "http://translate.sa-east-1.amazonaws.com" "http://translate.me-south-1.amazonaws.com" "https://translate.us-east-1.amazonaws.com" "https://translate.us-east-2.amazonaws.com" "https://translate.us-west-1.amazonaws.com" "https://translate.us-west-2.amazonaws.com" "https://translate.us-gov-west-1.amazonaws.com" "https://translate.us-gov-east-1.amazonaws.com" "https://translate.ca-central-1.amazonaws.com" "https://translate.eu-north-1.amazonaws.com" "https://translate.eu-west-1.amazonaws.com" "https://translate.eu-west-2.amazonaws.com" "https://translate.eu-west-3.amazonaws.com" "https://translate.eu-central-1.amazonaws.com" "https://translate.eu-south-1.amazonaws.com" "https://translate.af-south-1.amazonaws.com" "https://translate.ap-northeast-1.amazonaws.com" "https://translate.ap-northeast-2.amazonaws.com" "https://translate.ap-northeast-3.amazonaws.com" "https://translate.ap-southeast-1.amazonaws.com" "https://translate.ap-southeast-2.amazonaws.com" "https://translate.ap-east-1.amazonaws.com" "https://translate.ap-south-1.amazonaws.com" "https://translate.sa-east-1.amazonaws.com" "https://translate.me-south-1.amazonaws.com" "http://translate.cn-north-1.amazonaws.com.cn" "http://translate.cn-northwest-1.amazonaws.com.cn" "https://translate.cn-north-1.amazonaws.com.cn" "https://translate.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["AWSShineFrontendService_20170701.CreateParallelData"] }
def x-amz-target-completer-1 [] { ["AWSShineFrontendService_20170701.DeleteParallelData"] }
def x-amz-target-completer-2 [] { ["AWSShineFrontendService_20170701.DeleteTerminology"] }
def x-amz-target-completer-3 [] { ["AWSShineFrontendService_20170701.DescribeTextTranslationJob"] }
def x-amz-target-completer-4 [] { ["AWSShineFrontendService_20170701.GetParallelData"] }
def terminology-data-format-completer [] { ["CSV" "TMX" "TSV"] }
def x-amz-target-completer-5 [] { ["AWSShineFrontendService_20170701.GetTerminology"] }
def merge-strategy-completer [] { ["OVERWRITE"] }
def x-amz-target-completer-6 [] { ["AWSShineFrontendService_20170701.ImportTerminology"] }
def display-language-code-completer [] { ["de" "en" "es" "fr" "it" "ja" "ko" "pt" "zh" "zh-TW"] }
def x-amz-target-completer-7 [] { ["AWSShineFrontendService_20170701.ListLanguages"] }
def x-amz-target-completer-8 [] { ["AWSShineFrontendService_20170701.ListParallelData"] }
def x-amz-target-completer-9 [] { ["AWSShineFrontendService_20170701.ListTagsForResource"] }
def x-amz-target-completer-10 [] { ["AWSShineFrontendService_20170701.ListTerminologies"] }
def x-amz-target-completer-11 [] { ["AWSShineFrontendService_20170701.ListTextTranslationJobs"] }
def x-amz-target-completer-12 [] { ["AWSShineFrontendService_20170701.StartTextTranslationJob"] }
def x-amz-target-completer-13 [] { ["AWSShineFrontendService_20170701.StopTextTranslationJob"] }
def x-amz-target-completer-14 [] { ["AWSShineFrontendService_20170701.TagResource"] }
def x-amz-target-completer-15 [] { ["AWSShineFrontendService_20170701.TranslateText"] }
def x-amz-target-completer-16 [] { ["AWSShineFrontendService_20170701.UntagResource"] }
def x-amz-target-completer-17 [] { ["AWSShineFrontendService_20170701.UpdateParallelData"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    create-parallel-data: "record<Name: string, Status: string>"
    delete-parallel-data: "record<Name: string, Status: string>"
    describe-text-translation-job: "record<TextTranslationJobProperties: record<JobId: string, JobName: string, JobStatus: string, JobDetails: record<TranslatedDocumentsCount: int, DocumentsWithErrorsCount: int, InputDocumentsCount: int>, SourceLanguageCode: string, TargetLanguageCodes: list<string>, TerminologyNames: list<string>, ParallelDataNames: list<string>, Message: string, SubmittedTime: string, EndTime: string, InputDataConfig: record<S3Uri: string, ContentType: string>, OutputDataConfig: record<S3Uri: string, EncryptionKey: record>, DataAccessRoleArn: string, Settings: record<Formality: string, Profanity: string>>>"
    get-parallel-data: "record<ParallelDataProperties: record<Name: string, Arn: string, Description: string, Status: string, SourceLanguageCode: string, TargetLanguageCodes: list<string>, ParallelDataConfig: record<S3Uri: string, Format: string>, Message: string, ImportedDataSize: int, ImportedRecordCount: int, FailedRecordCount: int, SkippedRecordCount: int, EncryptionKey: record<Type: string, Id: string>, CreatedAt: string, LastUpdatedAt: string, LatestUpdateAttemptStatus: string, LatestUpdateAttemptAt: string>, DataLocation: record<RepositoryType: string, Location: string>, AuxiliaryDataLocation: record<RepositoryType: string, Location: string>, LatestUpdateAttemptAuxiliaryDataLocation: record<RepositoryType: string, Location: string>>"
    get-terminology: "record<TerminologyProperties: record<Name: string, Description: string, Arn: string, SourceLanguageCode: string, TargetLanguageCodes: list<string>, EncryptionKey: record<Type: string, Id: string>, SizeBytes: int, TermCount: int, CreatedAt: string, LastUpdatedAt: string, Directionality: string, Message: string, SkippedTermCount: int, Format: string>, TerminologyDataLocation: record<RepositoryType: string, Location: string>, AuxiliaryDataLocation: record<RepositoryType: string, Location: string>>"
    import-terminology: "record<TerminologyProperties: record<Name: string, Description: string, Arn: string, SourceLanguageCode: string, TargetLanguageCodes: list<string>, EncryptionKey: record<Type: string, Id: string>, SizeBytes: int, TermCount: int, CreatedAt: string, LastUpdatedAt: string, Directionality: string, Message: string, SkippedTermCount: int, Format: string>, AuxiliaryDataLocation: record<RepositoryType: string, Location: string>>"
    list-languages: "record<Languages: table<LanguageName: string, LanguageCode: string>, DisplayLanguageCode: string, NextToken: string>"
    list-parallel-data: "record<ParallelDataPropertiesList: table<Name: string, Arn: string, Description: string, Status: string, SourceLanguageCode: string, TargetLanguageCodes: list, ParallelDataConfig: record, Message: string, ImportedDataSize: int, ImportedRecordCount: int, FailedRecordCount: int, SkippedRecordCount: int, EncryptionKey: record, CreatedAt: string, LastUpdatedAt: string, LatestUpdateAttemptStatus: string, LatestUpdateAttemptAt: string>, NextToken: string>"
    list-tags-for-resource: "record<Tags: table<Key: string, Value: string>>"
    list-terminologies: "record<TerminologyPropertiesList: table<Name: string, Description: string, Arn: string, SourceLanguageCode: string, TargetLanguageCodes: list, EncryptionKey: record, SizeBytes: int, TermCount: int, CreatedAt: string, LastUpdatedAt: string, Directionality: string, Message: string, SkippedTermCount: int, Format: string>, NextToken: string>"
    list-text-translation-jobs: "record<TextTranslationJobPropertiesList: table<JobId: string, JobName: string, JobStatus: string, JobDetails: record, SourceLanguageCode: string, TargetLanguageCodes: list, TerminologyNames: list, ParallelDataNames: list, Message: string, SubmittedTime: string, EndTime: string, InputDataConfig: record, OutputDataConfig: record, DataAccessRoleArn: string, Settings: record>, NextToken: string>"
    start-text-translation-job: "record<JobId: string, JobStatus: string>"
    stop-text-translation-job: "record<JobId: string, JobStatus: string>"
    tag-resource: "record"
    translate-text: "record<TranslatedText: string, SourceLanguageCode: string, TargetLanguageCode: string, AppliedTerminologies: table<Name: string, Terms: list>, AppliedSettings: record<Formality: string, Profanity: string>>"
    untag-resource: "record"
    update-parallel-data: "record<Name: string, Status: string, LatestUpdateAttemptStatus: string, LatestUpdateAttemptAt: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["create-parallel-data" "delete-parallel-data" "delete-terminology" "describe-text-translation-job" "get-parallel-data" "get-terminology" "import-terminology" "list-languages" "list-parallel-data" "list-tags-for-resource" "list-terminologies" "list-text-translation-jobs" "start-text-translation-job" "stop-text-translation-job" "tag-resource" "translate-text" "untag-resource" "update-parallel-data" "commands"] | sort) } | get name | first)
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

# Creates a parallel data resource in Amazon Translate by importing an input file from Amazon S3. Parallel data files contain examples that show how you want segments of text to be translated. By adding parallel data, you can influence the style, tone, and word choice in your translation output.
#
# POST /
# Returns: record<Name: string, Status: string>
# operationId: CreateParallelData
export def "create-parallel-data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # A custom name for the parallel data resource in Amazon Translate. You must assign a name that is unique in the account and region.
  --description: string # A custom description for the parallel data resource in Amazon Translate.
  parallel_data_config: record # Specifies the format and S3 location of the parallel data input file. — shape: {S3Uri: string, Format: "TSV"|"CSV"|"TMX"}
  --encryption-key: record # The encryption key used to encrypt this object. — shape: {Type: "KMS", Id: string}
  client_token: string # A unique identifier for the request. This token is automatically generated when you use Amazon Translate through an AWS SDK.
  --tags: list # Tags to be associated with this resource. A tag is a key-value pair that adds metadata to a resource. Each tag key for the resource must be unique. For more information, see Tagging your resources (https://docs.aws.amazon.com/translate/latest/dg/tagging.html). — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSShineFrontendService_20170701.CreateParallelData"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: ParallelDataConfig, var: parallel_data_config}, {name: EncryptionKey, var: encryption_key}, {name: ClientToken, var: client_token}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, description: $description, parallel_data_config: $parallel_data_config, encryption_key: $encryption_key, client_token: $client_token, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a parallel data resource in Amazon Translate.
#
# POST /
# Returns: record<Name: string, Status: string>
# operationId: DeleteParallelData
export def "delete-parallel-data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the parallel data resource that is being deleted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSShineFrontendService_20170701.DeleteParallelData"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# A synchronous action that deletes a custom terminology.
#
# POST /
# operationId: DeleteTerminology
export def "delete-terminology" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the custom terminology being deleted.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSShineFrontendService_20170701.DeleteTerminology"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the properties associated with an asynchronous batch translation job including name, ID, status, source and target languages, input/output S3 buckets, and so on.
#
# POST /
# Returns: record<TextTranslationJobProperties: record<JobId: string, JobName: string, JobStatus: string, JobDetails: record<TranslatedDocumentsCount: int, DocumentsWithErrorsCount: int, InputDocumentsCount: int>, SourceLanguageCode: string, TargetLanguageCodes: list<string>, TerminologyNames: list<string>, ParallelDataNames: list<string>, Message: string, SubmittedTime: string, EndTime: string, InputDataConfig: record<S3Uri: string, ContentType: string>, OutputDataConfig: record<S3Uri: string, EncryptionKey: record>, DataAccessRoleArn: string, Settings: record<Formality: string, Profanity: string>>>
# operationId: DescribeTextTranslationJob
export def "describe-text-translation-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  job_id: string # The identifier that Amazon Translate generated for the job. The StartTextTranslationJob operation returns this identifier in its response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSShineFrontendService_20170701.DescribeTextTranslationJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobId, var: job_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides information about a parallel data resource.
#
# POST /
# Returns: record<ParallelDataProperties: record<Name: string, Arn: string, Description: string, Status: string, SourceLanguageCode: string, TargetLanguageCodes: list<string>, ParallelDataConfig: record<S3Uri: string, Format: string>, Message: string, ImportedDataSize: int, ImportedRecordCount: int, FailedRecordCount: int, SkippedRecordCount: int, EncryptionKey: record<Type: string, Id: string>, CreatedAt: string, LastUpdatedAt: string, LatestUpdateAttemptStatus: string, LatestUpdateAttemptAt: string>, DataLocation: record<RepositoryType: string, Location: string>, AuxiliaryDataLocation: record<RepositoryType: string, Location: string>, LatestUpdateAttemptAuxiliaryDataLocation: record<RepositoryType: string, Location: string>>
# operationId: GetParallelData
export def "get-parallel-data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the parallel data resource that is being retrieved.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSShineFrontendService_20170701.GetParallelData"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a custom terminology.
#
# POST /
# Returns: record<TerminologyProperties: record<Name: string, Description: string, Arn: string, SourceLanguageCode: string, TargetLanguageCodes: list<string>, EncryptionKey: record<Type: string, Id: string>, SizeBytes: int, TermCount: int, CreatedAt: string, LastUpdatedAt: string, Directionality: string, Message: string, SkippedTermCount: int, Format: string>, TerminologyDataLocation: record<RepositoryType: string, Location: string>, AuxiliaryDataLocation: record<RepositoryType: string, Location: string>>
# operationId: GetTerminology
export def "get-terminology" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the custom terminology being retrieved.
  --terminology-data-format: string@terminology-data-format-completer # The data format of the custom terminology being retrieved. If you don't specify this parameter, Amazon Translate returns a file with the same format as the file that was imported to create the terminology. If you specify this parameter when you retrieve a multi-directional terminology resource, you must specify the same format as the input file that was imported to create it. Otherwise, Amazon Translate throws an error.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSShineFrontendService_20170701.GetTerminology"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: TerminologyDataFormat, var: terminology_data_format}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, terminology_data_format: $terminology_data_format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates a custom terminology, depending on whether one already exists for the given terminology name. Importing a terminology with the same name as an existing one will merge the terminologies based on the chosen merge strategy. The only supported merge strategy is OVERWRITE, where the imported terminology overwrites the existing terminology of the same name. If you import a terminology that overwrites an existing one, the new terminology takes up to 10 minutes to fully propagate. After that, translations have access to the new terminology.
#
# POST /
# Returns: record<TerminologyProperties: record<Name: string, Description: string, Arn: string, SourceLanguageCode: string, TargetLanguageCodes: list<string>, EncryptionKey: record<Type: string, Id: string>, SizeBytes: int, TermCount: int, CreatedAt: string, LastUpdatedAt: string, Directionality: string, Message: string, SkippedTermCount: int, Format: string>, AuxiliaryDataLocation: record<RepositoryType: string, Location: string>>
# operationId: ImportTerminology
export def "import-terminology" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the custom terminology being imported.
  merge_strategy: string@merge-strategy-completer # The merge strategy of the custom terminology being imported. Currently, only the OVERWRITE merge strategy is supported. In this case, the imported terminology will overwrite an existing terminology of the same name.
  --description: string # The description of the custom terminology being imported.
  terminology_data: record # The data associated with the custom terminology. For information about the custom terminology file, see Creating a Custom Terminology (https://docs.aws.amazon.com/translate/latest/dg/creating-custom-terminology.html). — shape: {File: string, Format: "CSV"|"TMX"|"TSV", Directionality?: "UNI"|"MULTI"}
  --encryption-key: record # The encryption key used to encrypt this object. — shape: {Type: "KMS", Id: string}
  --tags: list # Tags to be associated with this resource. A tag is a key-value pair that adds metadata to a resource. Each tag key for the resource must be unique. For more information, see Tagging your resources (https://docs.aws.amazon.com/translate/latest/dg/tagging.html). — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSShineFrontendService_20170701.ImportTerminology"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: MergeStrategy, var: merge_strategy}, {name: Description, var: description}, {name: TerminologyData, var: terminology_data}, {name: EncryptionKey, var: encryption_key}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, merge_strategy: $merge_strategy, description: $description, terminology_data: $terminology_data, encryption_key: $encryption_key, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides a list of languages (RFC-5646 codes and names) that Amazon Translate supports.
#
# POST /
# Returns: record<Languages: table<LanguageName: string, LanguageCode: string>, DisplayLanguageCode: string, NextToken: string>
# operationId: ListLanguages
export def "list-languages" [
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
  --x-amz-target: string@x-amz-target-completer-7 # required
  --display-language-code: string@display-language-code-completer # The language code for the language to use to display the language names in the response. The language code is en by default.
  --body-next-token: string # Include the NextToken value to fetch the next group of supported languages. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return in each response. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSShineFrontendService_20170701.ListLanguages"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DisplayLanguageCode, var: display_language_code}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, display_language_code: $display_language_code, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides a list of your parallel data resources in Amazon Translate.
#
# POST /
# Returns: record<ParallelDataPropertiesList: table<Name: string, Arn: string, Description: string, Status: string, SourceLanguageCode: string, TargetLanguageCodes: list, ParallelDataConfig: record, Message: string, ImportedDataSize: int, ImportedRecordCount: int, FailedRecordCount: int, SkippedRecordCount: int, EncryptionKey: record, CreatedAt: string, LastUpdatedAt: string, LatestUpdateAttemptStatus: string, LatestUpdateAttemptAt: string>, NextToken: string>
# operationId: ListParallelData
export def "list-parallel-data" [
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
  --x-amz-target: string@x-amz-target-completer-8 # required
  --body-next-token: string # A string that specifies the next page of results to return in a paginated response. (spec name: NextToken)
  --body-max-results: int # The maximum number of parallel data resources returned for each request. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSShineFrontendService_20170701.ListParallelData"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all tags associated with a given Amazon Translate resource. For more information, see Tagging your resources (https://docs.aws.amazon.com/translate/latest/dg/tagging.html).
#
# POST /
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-9 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the given Amazon Translate resource you are querying.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSShineFrontendService_20170701.ListTagsForResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides a list of custom terminologies associated with your account.
#
# POST /
# Returns: record<TerminologyPropertiesList: table<Name: string, Description: string, Arn: string, SourceLanguageCode: string, TargetLanguageCodes: list, EncryptionKey: record, SizeBytes: int, TermCount: int, CreatedAt: string, LastUpdatedAt: string, Directionality: string, Message: string, SkippedTermCount: int, Format: string>, NextToken: string>
# operationId: ListTerminologies
export def "list-terminologies" [
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
  --x-amz-target: string@x-amz-target-completer-10 # required
  --body-next-token: string # If the result of the request to ListTerminologies was truncated, include the NextToken to fetch the next group of custom terminologies. (spec name: NextToken)
  --body-max-results: int # The maximum number of custom terminologies returned per list request. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSShineFrontendService_20170701.ListTerminologies"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of the batch translation jobs that you have submitted.
#
# POST /
# Returns: record<TextTranslationJobPropertiesList: table<JobId: string, JobName: string, JobStatus: string, JobDetails: record, SourceLanguageCode: string, TargetLanguageCodes: list, TerminologyNames: list, ParallelDataNames: list, Message: string, SubmittedTime: string, EndTime: string, InputDataConfig: record, OutputDataConfig: record, DataAccessRoleArn: string, Settings: record>, NextToken: string>
# operationId: ListTextTranslationJobs
export def "list-text-translation-jobs" [
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
  --x-amz-target: string@x-amz-target-completer-11 # required
  --filter: record # Provides information for filtering a list of translation jobs. For more information, see ListTextTranslationJobs. — shape: {JobName?: string, JobStatus?: "SUBMITTED"|"IN_PROGRESS"|"COMPLETED"|"COMPLETED_WITH_ERROR"|"FAILED"|"STOP_REQUESTED"|"STOPPED", SubmittedBeforeTime?: string, SubmittedAfterTime?: string}
  --body-next-token: string # The token to request the next page of results. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return in each page. The default value is 100. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSShineFrontendService_20170701.ListTextTranslationJobs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filter, var: filter}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filter: $filter, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts an asynchronous batch translation job. Use batch translation jobs to translate large volumes of text across multiple documents at once. For batch translation, you can input documents with different source languages (specify auto as the source language). You can specify one or more target languages. Batch translation translates each input document into each of the target languages. For more information, see Asynchronous batch processing (https://docs.aws.amazon.com/translate/latest/dg/async.html). Batch translation jobs can be described with the DescribeTextTranslationJob operation, listed with the ListTextTranslationJobs operation, and stopped with the StopTextTranslationJob operation.
#
# POST /
# Returns: record<JobId: string, JobStatus: string>
# operationId: StartTextTranslationJob
export def "start-text-translation-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --job-name: string # The name of the batch translation job to be performed.
  input_data_config: record # The input configuration properties for requesting a batch translation job. — shape: {S3Uri: string, ContentType: string}
  output_data_config: record # The output configuration properties for a batch translation job. — shape: {S3Uri: string, EncryptionKey?: record}
  data_access_role_arn: string # The Amazon Resource Name (ARN) of an AWS Identity Access and Management (IAM) role that grants Amazon Translate read access to your input data. For more information, see Identity and access management (https://docs.aws.amazon.com/translate/latest/dg/identity-and-access-management.html).
  source_language_code: string # The language code of the input language. Specify the language if all input documents share the same language. If you don't know the language of the source files, or your input documents contains different source languages, select auto. Amazon Translate auto detects the source language for each input document. For a list of supported language codes, see Supported languages (https://docs.aws.amazon.com/translate/latest/dg/what-is-languages.html).
  target_language_codes: list<string> # The target languages of the translation job. Enter up to 10 language codes. Each input file is translated into each target language. Each language code is 2 or 5 characters long. For a list of language codes, see Supported languages (https://docs.aws.amazon.com/translate/latest/dg/what-is-languages.html).
  --terminology-names: list<string> # The name of a custom terminology resource to add to the translation job. This resource lists examples source terms and the desired translation for each term. This parameter accepts only one custom terminology resource. If you specify multiple target languages for the job, translate uses the designated terminology for each requested target language that has an entry for the source term in the terminology file. For a list of available custom terminology resources, use the ListTerminologies operation. For more information, see Custom terminology (https://docs.aws.amazon.com/translate/latest/dg/how-custom-terminology.html).
  --parallel-data-names: list<string> # The name of a parallel data resource to add to the translation job. This resource consists of examples that show how you want segments of text to be translated. If you specify multiple target languages for the job, the parallel data file must include translations for all the target languages. When you add parallel data to a translation job, you create an Active Custom Translation job. This parameter accepts only one parallel data resource. Active Custom Translation jobs are priced at a higher rate than other jobs that don't use parallel data. For more information, see Amazon Translate pricing (http://aws.amazon.com/translate/pricing/). For a list of available parallel data resources, use the ListParallelData operation. For more information, see Customizing your translations with parallel data (https://docs.aws.amazon.com/translate/latest/dg/customizing-translations-parallel-data.html).
  client_token: string # A unique identifier for the request. This token is generated for you when using the Amazon Translate SDK.
  --settings: record # Optional settings that configure the translation output. Use these settings for real time translations and asynchronous translation jobs. — shape: {Formality?: "FORMAL"|"INFORMAL", Profanity?: "MASK"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSShineFrontendService_20170701.StartTextTranslationJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobName, var: job_name}, {name: InputDataConfig, var: input_data_config}, {name: OutputDataConfig, var: output_data_config}, {name: DataAccessRoleArn, var: data_access_role_arn}, {name: SourceLanguageCode, var: source_language_code}, {name: TargetLanguageCodes, var: target_language_codes}, {name: TerminologyNames, var: terminology_names}, {name: ParallelDataNames, var: parallel_data_names}, {name: ClientToken, var: client_token}, {name: Settings, var: settings}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_name: $job_name, input_data_config: $input_data_config, output_data_config: $output_data_config, data_access_role_arn: $data_access_role_arn, source_language_code: $source_language_code, target_language_codes: $target_language_codes, terminology_names: $terminology_names, parallel_data_names: $parallel_data_names, client_token: $client_token, settings: $settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops an asynchronous batch translation job that is in progress. If the job's state is IN_PROGRESS, the job will be marked for termination and put into the STOP_REQUESTED state. If the job completes before it can be stopped, it is put into the COMPLETED state. Otherwise, the job is put into the STOPPED state. Asynchronous batch translation jobs are started with the StartTextTranslationJob operation. You can use the DescribeTextTranslationJob or ListTextTranslationJobs operations to get a batch translation job's JobId.
#
# POST /
# Returns: record<JobId: string, JobStatus: string>
# operationId: StopTextTranslationJob
export def "stop-text-translation-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  job_id: string # The job ID of the job to be stopped.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSShineFrontendService_20170701.StopTextTranslationJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobId, var: job_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates a specific tag with a resource. A tag is a key-value pair that adds as a metadata to a resource. For more information, see Tagging your resources (https://docs.aws.amazon.com/translate/latest/dg/tagging.html).
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
  --x-amz-target: string@x-amz-target-completer-14 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the given Amazon Translate resource to which you want to associate the tags.
  tags: list # Tags being associated with a specific Amazon Translate resource. There can be a maximum of 50 tags (both existing and pending) associated with a specific resource. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSShineFrontendService_20170701.TagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Translates input text from the source language to the target language. For a list of available languages and language codes, see Supported languages (https://docs.aws.amazon.com/translate/latest/dg/what-is-languages.html).
#
# POST /
# Returns: record<TranslatedText: string, SourceLanguageCode: string, TargetLanguageCode: string, AppliedTerminologies: table<Name: string, Terms: list>, AppliedSettings: record<Formality: string, Profanity: string>>
# operationId: TranslateText
export def "translate-text" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  text: string # The text to translate. The text string can be a maximum of 10,000 bytes long. Depending on your character set, this may be fewer than 10,000 characters.
  --terminology-names: list<string> # The name of the terminology list file to be used in the TranslateText request. You can use 1 terminology list at most in a TranslateText request. Terminology lists can contain a maximum of 256 terms.
  source_language_code: string # The language code for the language of the source text. The language must be a language supported by Amazon Translate. For a list of language codes, see Supported languages (https://docs.aws.amazon.com/translate/latest/dg/what-is-languages.html). To have Amazon Translate determine the source language of your text, you can specify auto in the SourceLanguageCode field. If you specify auto, Amazon Translate will call Amazon Comprehend (https://docs.aws.amazon.com/comprehend/latest/dg/comprehend-general.html) to determine the source language. If you specify auto, you must send the TranslateText request in a region that supports Amazon Comprehend. Otherwise, the request returns an error indicating that autodetect is not supported.
  target_language_code: string # The language code requested for the language of the target text. The language must be a language supported by Amazon Translate.
  --settings: record # Optional settings that configure the translation output. Use these settings for real time translations and asynchronous translation jobs. — shape: {Formality?: "FORMAL"|"INFORMAL", Profanity?: "MASK"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSShineFrontendService_20170701.TranslateText"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Text, var: text}, {name: TerminologyNames, var: terminology_names}, {name: SourceLanguageCode, var: source_language_code}, {name: TargetLanguageCode, var: target_language_code}, {name: Settings, var: settings}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, text: $text, terminology_names: $terminology_names, source_language_code: $source_language_code, target_language_code: $target_language_code, settings: $settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a specific tag associated with an Amazon Translate resource. For more information, see Tagging your resources (https://docs.aws.amazon.com/translate/latest/dg/tagging.html).
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
  --x-amz-target: string@x-amz-target-completer-16 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the given Amazon Translate resource from which you want to remove the tags.
  tag_keys: list<string> # The initial part of a key-value pair that forms a tag being removed from a given resource. Keys must be unique and cannot be duplicated for a particular resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSShineFrontendService_20170701.UntagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: TagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a previously created parallel data resource by importing a new input file from Amazon S3.
#
# POST /
# Returns: record<Name: string, Status: string, LatestUpdateAttemptStatus: string, LatestUpdateAttemptAt: string>
# operationId: UpdateParallelData
export def "update-parallel-data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the parallel data resource being updated.
  --description: string # A custom description for the parallel data resource in Amazon Translate.
  parallel_data_config: record # Specifies the format and S3 location of the parallel data input file. — shape: {S3Uri: string, Format: "TSV"|"CSV"|"TMX"}
  client_token: string # A unique identifier for the request. This token is automatically generated when you use Amazon Translate through an AWS SDK.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSShineFrontendService_20170701.UpdateParallelData"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: ParallelDataConfig, var: parallel_data_config}, {name: ClientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, description: $description, parallel_data_config: $parallel_data_config, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
