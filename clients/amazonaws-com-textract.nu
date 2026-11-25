# Auto-generated client for Amazon Textract v2018-06-27
# Source: https://api.apis.guru/v2/specs/amazonaws.com/textract/2018-06-27/openapi.json
# Auth: --token flag or $env.AMAZON_TEXTRACT_TOKEN

const CLIENT = {
  base_url: "http://textract.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_TEXTRACT_TOKEN"
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

def base-url-completer [] { ["http://textract.us-east-1.amazonaws.com" "http://textract.us-east-2.amazonaws.com" "http://textract.us-west-1.amazonaws.com" "http://textract.us-west-2.amazonaws.com" "http://textract.us-gov-west-1.amazonaws.com" "http://textract.us-gov-east-1.amazonaws.com" "http://textract.ca-central-1.amazonaws.com" "http://textract.eu-north-1.amazonaws.com" "http://textract.eu-west-1.amazonaws.com" "http://textract.eu-west-2.amazonaws.com" "http://textract.eu-west-3.amazonaws.com" "http://textract.eu-central-1.amazonaws.com" "http://textract.eu-south-1.amazonaws.com" "http://textract.af-south-1.amazonaws.com" "http://textract.ap-northeast-1.amazonaws.com" "http://textract.ap-northeast-2.amazonaws.com" "http://textract.ap-northeast-3.amazonaws.com" "http://textract.ap-southeast-1.amazonaws.com" "http://textract.ap-southeast-2.amazonaws.com" "http://textract.ap-east-1.amazonaws.com" "http://textract.ap-south-1.amazonaws.com" "http://textract.sa-east-1.amazonaws.com" "http://textract.me-south-1.amazonaws.com" "https://textract.us-east-1.amazonaws.com" "https://textract.us-east-2.amazonaws.com" "https://textract.us-west-1.amazonaws.com" "https://textract.us-west-2.amazonaws.com" "https://textract.us-gov-west-1.amazonaws.com" "https://textract.us-gov-east-1.amazonaws.com" "https://textract.ca-central-1.amazonaws.com" "https://textract.eu-north-1.amazonaws.com" "https://textract.eu-west-1.amazonaws.com" "https://textract.eu-west-2.amazonaws.com" "https://textract.eu-west-3.amazonaws.com" "https://textract.eu-central-1.amazonaws.com" "https://textract.eu-south-1.amazonaws.com" "https://textract.af-south-1.amazonaws.com" "https://textract.ap-northeast-1.amazonaws.com" "https://textract.ap-northeast-2.amazonaws.com" "https://textract.ap-northeast-3.amazonaws.com" "https://textract.ap-southeast-1.amazonaws.com" "https://textract.ap-southeast-2.amazonaws.com" "https://textract.ap-east-1.amazonaws.com" "https://textract.ap-south-1.amazonaws.com" "https://textract.sa-east-1.amazonaws.com" "https://textract.me-south-1.amazonaws.com" "http://textract.cn-north-1.amazonaws.com.cn" "http://textract.cn-northwest-1.amazonaws.com.cn" "https://textract.cn-north-1.amazonaws.com.cn" "https://textract.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["Textract.AnalyzeDocument"] }
def x-amz-target-completer-1 [] { ["Textract.AnalyzeExpense"] }
def x-amz-target-completer-2 [] { ["Textract.AnalyzeID"] }
def x-amz-target-completer-3 [] { ["Textract.DetectDocumentText"] }
def x-amz-target-completer-4 [] { ["Textract.GetDocumentAnalysis"] }
def x-amz-target-completer-5 [] { ["Textract.GetDocumentTextDetection"] }
def x-amz-target-completer-6 [] { ["Textract.GetExpenseAnalysis"] }
def x-amz-target-completer-7 [] { ["Textract.GetLendingAnalysis"] }
def x-amz-target-completer-8 [] { ["Textract.GetLendingAnalysisSummary"] }
def x-amz-target-completer-9 [] { ["Textract.StartDocumentAnalysis"] }
def x-amz-target-completer-10 [] { ["Textract.StartDocumentTextDetection"] }
def x-amz-target-completer-11 [] { ["Textract.StartExpenseAnalysis"] }
def x-amz-target-completer-12 [] { ["Textract.StartLendingAnalysis"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    analyze-document: "record<DocumentMetadata: record<Pages: int>, Blocks: table<BlockType: string, Confidence: float, Text: string, TextType: string, RowIndex: int, ColumnIndex: int, RowSpan: int, ColumnSpan: int, Geometry: record, Id: string, Relationships: list, EntityTypes: list, SelectionStatus: string, Page: int, Query: record>, HumanLoopActivationOutput: record<HumanLoopArn: string, HumanLoopActivationReasons: list<string>, HumanLoopActivationConditionsEvaluationResults: string>, AnalyzeDocumentModelVersion: string>"
    analyze-expense: "record<DocumentMetadata: record<Pages: int>, ExpenseDocuments: table<ExpenseIndex: int, SummaryFields: list, LineItemGroups: list, Blocks: list>>"
    analyze-id: "record<IdentityDocuments: table<DocumentIndex: int, IdentityDocumentFields: list, Blocks: list>, DocumentMetadata: record<Pages: int>, AnalyzeIDModelVersion: string>"
    detect-document-text: "record<DocumentMetadata: record<Pages: int>, Blocks: table<BlockType: string, Confidence: float, Text: string, TextType: string, RowIndex: int, ColumnIndex: int, RowSpan: int, ColumnSpan: int, Geometry: record, Id: string, Relationships: list, EntityTypes: list, SelectionStatus: string, Page: int, Query: record>, DetectDocumentTextModelVersion: string>"
    get-document-analysis: "record<DocumentMetadata: record<Pages: int>, JobStatus: string, NextToken: string, Blocks: table<BlockType: string, Confidence: float, Text: string, TextType: string, RowIndex: int, ColumnIndex: int, RowSpan: int, ColumnSpan: int, Geometry: record, Id: string, Relationships: list, EntityTypes: list, SelectionStatus: string, Page: int, Query: record>, Warnings: table<ErrorCode: string, Pages: list>, StatusMessage: string, AnalyzeDocumentModelVersion: string>"
    get-document-text-detection: "record<DocumentMetadata: record<Pages: int>, JobStatus: string, NextToken: string, Blocks: table<BlockType: string, Confidence: float, Text: string, TextType: string, RowIndex: int, ColumnIndex: int, RowSpan: int, ColumnSpan: int, Geometry: record, Id: string, Relationships: list, EntityTypes: list, SelectionStatus: string, Page: int, Query: record>, Warnings: table<ErrorCode: string, Pages: list>, StatusMessage: string, DetectDocumentTextModelVersion: string>"
    get-expense-analysis: "record<DocumentMetadata: record<Pages: int>, JobStatus: string, NextToken: string, ExpenseDocuments: table<ExpenseIndex: int, SummaryFields: list, LineItemGroups: list, Blocks: list>, Warnings: table<ErrorCode: string, Pages: list>, StatusMessage: string, AnalyzeExpenseModelVersion: string>"
    get-lending-analysis: "record<DocumentMetadata: record<Pages: int>, JobStatus: string, NextToken: string, Results: table<Page: int, PageClassification: record, Extractions: list>, Warnings: table<ErrorCode: string, Pages: list>, StatusMessage: string, AnalyzeLendingModelVersion: string>"
    get-lending-analysis-summary: "record<DocumentMetadata: record<Pages: int>, JobStatus: string, Summary: record<DocumentGroups: list<record>, UndetectedDocumentTypes: list<string>>, Warnings: table<ErrorCode: string, Pages: list>, StatusMessage: string, AnalyzeLendingModelVersion: string>"
    start-document-analysis: "record<JobId: string>"
    start-document-text-detection: "record<JobId: string>"
    start-expense-analysis: "record<JobId: string>"
    start-lending-analysis: "record<JobId: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["analyze-document" "analyze-expense" "analyze-id" "detect-document-text" "get-document-analysis" "get-document-text-detection" "get-expense-analysis" "get-lending-analysis" "get-lending-analysis-summary" "start-document-analysis" "start-document-text-detection" "start-expense-analysis" "start-lending-analysis" "commands"] | sort) } | get name | first)
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

# Analyzes an input document for relationships between detected items. The types of information returned are as follows: Form data (key-value pairs). The related information is returned in two Block objects, each of type KEY_VALUE_SET: a KEY Block object and a VALUE Block object. For example, Name: Ana Silva Carolina contains a key and value. Name: is the key. Ana Silva Carolina is the value. Table and table cell data. A TABLE Block object contains information about a detected table. A CELL Block object is returned for each cell in a table. Lines and words of text. A LINE Block object contains one or more WORD Block objects. All lines and words that are detected in the document are returned (including text that doesn't have a relationship with the value of FeatureTypes). Signatures. A SIGNATURE Block object contains the location information of a signature in a document. If used in conjunction with forms or tables, a signature can be given a Key-Value pairing or be detected in the cell of a table. Query. A QUERY Block object contains the query text, alias and link to the associated Query results block object. Query Result. A QUERY_RESULT Block object contains the answer to the query and an ID that connects it to the query asked. This Block also contains a confidence score. Selection elements such as check boxes and option buttons (radio buttons) can be detected in form data and in tables. A SELECTION_ELEMENT Block object contains information about a selection element, including the selection status. You can choose which type of analysis to perform by specifying the FeatureTypes list. The output is returned in a list of Block objects. AnalyzeDocument is a synchronous operation. To analyze documents asynchronously, use StartDocumentAnalysis. For more information, see Document Text Analysis (https://docs.aws.amazon.com/textract/latest/dg/how-it-works-analyzing.html).
#
# POST /
# Returns: record<DocumentMetadata: record<Pages: int>, Blocks: table<BlockType: string, Confidence: float, Text: string, TextType: string, RowIndex: int, ColumnIndex: int, RowSpan: int, ColumnSpan: int, Geometry: record, Id: string, Relationships: list, EntityTypes: list, SelectionStatus: string, Page: int, Query: record>, HumanLoopActivationOutput: record<HumanLoopArn: string, HumanLoopActivationReasons: list<string>, HumanLoopActivationConditionsEvaluationResults: string>, AnalyzeDocumentModelVersion: string>
# operationId: AnalyzeDocument
export def "analyze-document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  document: record # The input document, either as bytes or as an S3 object. You pass image bytes to an Amazon Textract API operation by using the Bytes property. For example, you would use the Bytes property to pass a document loaded from a local file system. Image bytes passed by using the Bytes property must be base64 encoded. Your code might not need to encode document file bytes if you're using an AWS SDK to call Amazon Textract API operations. You pass images stored in an S3 bucket to an Amazon Textract API operation by using the S3Object property. Documents stored in an S3 bucket don't need to be base64 encoded. The AWS Region for the S3 bucket that contains the S3 object must match the AWS Region that you use for Amazon Textract operations. If you use the AWS CLI to call Amazon Textract operations, passing image bytes using the Bytes property isn't supported. You must first upload the document to an Amazon S3 bucket, and then call the operation using the S3Object property. For Amazon Textract to process an S3 object, the user must have permission to access the S3 object. — shape: {Bytes?: string, S3Object?: record}
  feature_types: list<string> # A list of the types of analysis to perform. Add TABLES to the list to return information about the tables that are detected in the input document. Add FORMS to return detected form data. Add SIGNATURES to return the locations of detected signatures. To perform both forms and table analysis, add TABLES and FORMS to FeatureTypes. To detect signatures within form data and table data, add SIGNATURES to either TABLES or FORMS. All lines and words detected in the document are included in the response (including text that isn't related to the value of FeatureTypes).
  --human-loop-config: record # Sets up the human review workflow the document will be sent to if one of the conditions is met. You can also set certain attributes of the image before review. — shape: {HumanLoopName: string, FlowDefinitionArn: string, DataAttributes?: record}
  --queries-config: record # shape: {Queries: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Textract.AnalyzeDocument"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Document, var: document}, {name: FeatureTypes, var: feature_types}, {name: HumanLoopConfig, var: human_loop_config}, {name: QueriesConfig, var: queries_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, document: $document, feature_types: $feature_types, human_loop_config: $human_loop_config, queries_config: $queries_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# AnalyzeExpense synchronously analyzes an input document for financially related relationships between text. Information is returned as ExpenseDocuments and seperated as follows: LineItemGroups- A data set containing LineItems which store information about the lines of text, such as an item purchased and its price on a receipt. SummaryFields- Contains all other information a receipt, such as header information or the vendors name.
#
# POST /
# Returns: record<DocumentMetadata: record<Pages: int>, ExpenseDocuments: table<ExpenseIndex: int, SummaryFields: list, LineItemGroups: list, Blocks: list>>
# operationId: AnalyzeExpense
export def "analyze-expense" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  document: record # The input document, either as bytes or as an S3 object. You pass image bytes to an Amazon Textract API operation by using the Bytes property. For example, you would use the Bytes property to pass a document loaded from a local file system. Image bytes passed by using the Bytes property must be base64 encoded. Your code might not need to encode document file bytes if you're using an AWS SDK to call Amazon Textract API operations. You pass images stored in an S3 bucket to an Amazon Textract API operation by using the S3Object property. Documents stored in an S3 bucket don't need to be base64 encoded. The AWS Region for the S3 bucket that contains the S3 object must match the AWS Region that you use for Amazon Textract operations. If you use the AWS CLI to call Amazon Textract operations, passing image bytes using the Bytes property isn't supported. You must first upload the document to an Amazon S3 bucket, and then call the operation using the S3Object property. For Amazon Textract to process an S3 object, the user must have permission to access the S3 object. — shape: {Bytes?: string, S3Object?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Textract.AnalyzeExpense"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Document, var: document}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, document: $document
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Analyzes identity documents for relevant information. This information is extracted and returned as IdentityDocumentFields, which records both the normalized field and value of the extracted text. Unlike other Amazon Textract operations, AnalyzeID doesn't return any Geometry data.
#
# POST /
# Returns: record<IdentityDocuments: table<DocumentIndex: int, IdentityDocumentFields: list, Blocks: list>, DocumentMetadata: record<Pages: int>, AnalyzeIDModelVersion: string>
# operationId: AnalyzeID
export def "analyze-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  document_pages: list # The document being passed to AnalyzeID. — item shape: {Bytes?: string, S3Object?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Textract.AnalyzeID"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DocumentPages, var: document_pages}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, document_pages: $document_pages
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detects text in the input document. Amazon Textract can detect lines of text and the words that make up a line of text. The input document must be in one of the following image formats: JPEG, PNG, PDF, or TIFF. DetectDocumentText returns the detected text in an array of Block objects. Each document page has as an associated Block of type PAGE. Each PAGE Block object is the parent of LINE Block objects that represent the lines of detected text on a page. A LINE Block object is a parent for each word that makes up the line. Words are represented by Block objects of type WORD. DetectDocumentText is a synchronous operation. To analyze documents asynchronously, use StartDocumentTextDetection. For more information, see Document Text Detection (https://docs.aws.amazon.com/textract/latest/dg/how-it-works-detecting.html).
#
# POST /
# Returns: record<DocumentMetadata: record<Pages: int>, Blocks: table<BlockType: string, Confidence: float, Text: string, TextType: string, RowIndex: int, ColumnIndex: int, RowSpan: int, ColumnSpan: int, Geometry: record, Id: string, Relationships: list, EntityTypes: list, SelectionStatus: string, Page: int, Query: record>, DetectDocumentTextModelVersion: string>
# operationId: DetectDocumentText
export def "detect-document-text" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  document: record # The input document, either as bytes or as an S3 object. You pass image bytes to an Amazon Textract API operation by using the Bytes property. For example, you would use the Bytes property to pass a document loaded from a local file system. Image bytes passed by using the Bytes property must be base64 encoded. Your code might not need to encode document file bytes if you're using an AWS SDK to call Amazon Textract API operations. You pass images stored in an S3 bucket to an Amazon Textract API operation by using the S3Object property. Documents stored in an S3 bucket don't need to be base64 encoded. The AWS Region for the S3 bucket that contains the S3 object must match the AWS Region that you use for Amazon Textract operations. If you use the AWS CLI to call Amazon Textract operations, passing image bytes using the Bytes property isn't supported. You must first upload the document to an Amazon S3 bucket, and then call the operation using the S3Object property. For Amazon Textract to process an S3 object, the user must have permission to access the S3 object. — shape: {Bytes?: string, S3Object?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Textract.DetectDocumentText"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Document, var: document}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, document: $document
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the results for an Amazon Textract asynchronous operation that analyzes text in a document. You start asynchronous text analysis by calling StartDocumentAnalysis, which returns a job identifier (JobId). When the text analysis operation finishes, Amazon Textract publishes a completion status to the Amazon Simple Notification Service (Amazon SNS) topic that's registered in the initial call to StartDocumentAnalysis. To get the results of the text-detection operation, first check that the status value published to the Amazon SNS topic is SUCCEEDED. If so, call GetDocumentAnalysis, and pass the job identifier (JobId) from the initial call to StartDocumentAnalysis. GetDocumentAnalysis returns an array of Block objects. The following types of information are returned: Form data (key-value pairs). The related information is returned in two Block objects, each of type KEY_VALUE_SET: a KEY Block object and a VALUE Block object. For example, Name: Ana Silva Carolina contains a key and value. Name: is the key. Ana Silva Carolina is the value. Table and table cell data. A TABLE Block object contains information about a detected table. A CELL Block object is returned for each cell in a table. Lines and words of text. A LINE Block object contains one or more WORD Block objects. All lines and words that are detected in the document are returned (including text that doesn't have a relationship with the value of the StartDocumentAnalysis FeatureTypes input parameter). Query. A QUERY Block object contains the query text, alias and link to the associated Query results block object. Query Results. A QUERY_RESULT Block object contains the answer to the query and an ID that connects it to the query asked. This Block also contains a confidence score. While processing a document with queries, look out for INVALID_REQUEST_PARAMETERS output. This indicates that either the per page query limit has been exceeded or that the operation is trying to query a page in the document which doesn’t exist. Selection elements such as check boxes and option buttons (radio buttons) can be detected in form data and in tables. A SELECTION_ELEMENT Block object contains information about a selection element, including the selection status. Use the MaxResults parameter to limit the number of blocks that are returned. If there are more results than specified in MaxResults, the value of NextToken in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call GetDocumentAnalysis, and populate the NextToken request parameter with the token value that's returned from the previous call to GetDocumentAnalysis. For more information, see Document Text Analysis (https://docs.aws.amazon.com/textract/latest/dg/how-it-works-analyzing.html).
#
# POST /
# Returns: record<DocumentMetadata: record<Pages: int>, JobStatus: string, NextToken: string, Blocks: table<BlockType: string, Confidence: float, Text: string, TextType: string, RowIndex: int, ColumnIndex: int, RowSpan: int, ColumnSpan: int, Geometry: record, Id: string, Relationships: list, EntityTypes: list, SelectionStatus: string, Page: int, Query: record>, Warnings: table<ErrorCode: string, Pages: list>, StatusMessage: string, AnalyzeDocumentModelVersion: string>
# operationId: GetDocumentAnalysis
export def "get-document-analysis" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  job_id: string # A unique identifier for the text-detection job. The JobId is returned from StartDocumentAnalysis. A JobId value is only valid for 7 days.
  --max-results: int # The maximum number of results to return per paginated call. The largest value that you can specify is 1,000. If you specify a value greater than 1,000, a maximum of 1,000 results is returned. The default value is 1,000.
  --next-token: string # If the previous response was incomplete (because there are more blocks to retrieve), Amazon Textract returns a pagination token in the response. You can use this pagination token to retrieve the next set of blocks.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Textract.GetDocumentAnalysis"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobId, var: job_id}, {name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_id: $job_id, max_results: $max_results, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the results for an Amazon Textract asynchronous operation that detects text in a document. Amazon Textract can detect lines of text and the words that make up a line of text. You start asynchronous text detection by calling StartDocumentTextDetection, which returns a job identifier (JobId). When the text detection operation finishes, Amazon Textract publishes a completion status to the Amazon Simple Notification Service (Amazon SNS) topic that's registered in the initial call to StartDocumentTextDetection. To get the results of the text-detection operation, first check that the status value published to the Amazon SNS topic is SUCCEEDED. If so, call GetDocumentTextDetection, and pass the job identifier (JobId) from the initial call to StartDocumentTextDetection. GetDocumentTextDetection returns an array of Block objects. Each document page has as an associated Block of type PAGE. Each PAGE Block object is the parent of LINE Block objects that represent the lines of detected text on a page. A LINE Block object is a parent for each word that makes up the line. Words are represented by Block objects of type WORD. Use the MaxResults parameter to limit the number of blocks that are returned. If there are more results than specified in MaxResults, the value of NextToken in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call GetDocumentTextDetection, and populate the NextToken request parameter with the token value that's returned from the previous call to GetDocumentTextDetection. For more information, see Document Text Detection (https://docs.aws.amazon.com/textract/latest/dg/how-it-works-detecting.html).
#
# POST /
# Returns: record<DocumentMetadata: record<Pages: int>, JobStatus: string, NextToken: string, Blocks: table<BlockType: string, Confidence: float, Text: string, TextType: string, RowIndex: int, ColumnIndex: int, RowSpan: int, ColumnSpan: int, Geometry: record, Id: string, Relationships: list, EntityTypes: list, SelectionStatus: string, Page: int, Query: record>, Warnings: table<ErrorCode: string, Pages: list>, StatusMessage: string, DetectDocumentTextModelVersion: string>
# operationId: GetDocumentTextDetection
export def "get-document-text-detection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  job_id: string # A unique identifier for the text detection job. The JobId is returned from StartDocumentTextDetection. A JobId value is only valid for 7 days.
  --max-results: int # The maximum number of results to return per paginated call. The largest value you can specify is 1,000. If you specify a value greater than 1,000, a maximum of 1,000 results is returned. The default value is 1,000.
  --next-token: string # If the previous response was incomplete (because there are more blocks to retrieve), Amazon Textract returns a pagination token in the response. You can use this pagination token to retrieve the next set of blocks.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Textract.GetDocumentTextDetection"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobId, var: job_id}, {name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_id: $job_id, max_results: $max_results, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the results for an Amazon Textract asynchronous operation that analyzes invoices and receipts. Amazon Textract finds contact information, items purchased, and vendor name, from input invoices and receipts. You start asynchronous invoice/receipt analysis by calling StartExpenseAnalysis, which returns a job identifier (JobId). Upon completion of the invoice/receipt analysis, Amazon Textract publishes the completion status to the Amazon Simple Notification Service (Amazon SNS) topic. This topic must be registered in the initial call to StartExpenseAnalysis. To get the results of the invoice/receipt analysis operation, first ensure that the status value published to the Amazon SNS topic is SUCCEEDED. If so, call GetExpenseAnalysis, and pass the job identifier (JobId) from the initial call to StartExpenseAnalysis. Use the MaxResults parameter to limit the number of blocks that are returned. If there are more results than specified in MaxResults, the value of NextToken in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call GetExpenseAnalysis, and populate the NextToken request parameter with the token value that's returned from the previous call to GetExpenseAnalysis. For more information, see Analyzing Invoices and Receipts (https://docs.aws.amazon.com/textract/latest/dg/invoices-receipts.html).
#
# POST /
# Returns: record<DocumentMetadata: record<Pages: int>, JobStatus: string, NextToken: string, ExpenseDocuments: table<ExpenseIndex: int, SummaryFields: list, LineItemGroups: list, Blocks: list>, Warnings: table<ErrorCode: string, Pages: list>, StatusMessage: string, AnalyzeExpenseModelVersion: string>
# operationId: GetExpenseAnalysis
export def "get-expense-analysis" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  job_id: string # A unique identifier for the text detection job. The JobId is returned from StartExpenseAnalysis. A JobId value is only valid for 7 days.
  --max-results: int # The maximum number of results to return per paginated call. The largest value you can specify is 20. If you specify a value greater than 20, a maximum of 20 results is returned. The default value is 20.
  --next-token: string # If the previous response was incomplete (because there are more blocks to retrieve), Amazon Textract returns a pagination token in the response. You can use this pagination token to retrieve the next set of blocks.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Textract.GetExpenseAnalysis"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobId, var: job_id}, {name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_id: $job_id, max_results: $max_results, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the results for an Amazon Textract asynchronous operation that analyzes text in a lending document. You start asynchronous text analysis by calling StartLendingAnalysis, which returns a job identifier (JobId). When the text analysis operation finishes, Amazon Textract publishes a completion status to the Amazon Simple Notification Service (Amazon SNS) topic that's registered in the initial call to StartLendingAnalysis. To get the results of the text analysis operation, first check that the status value published to the Amazon SNS topic is SUCCEEDED. If so, call GetLendingAnalysis, and pass the job identifier (JobId) from the initial call to StartLendingAnalysis.
#
# POST /
# Returns: record<DocumentMetadata: record<Pages: int>, JobStatus: string, NextToken: string, Results: table<Page: int, PageClassification: record, Extractions: list>, Warnings: table<ErrorCode: string, Pages: list>, StatusMessage: string, AnalyzeLendingModelVersion: string>
# operationId: GetLendingAnalysis
export def "get-lending-analysis" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  job_id: string # A unique identifier for the lending or text-detection job. The JobId is returned from StartLendingAnalysis. A JobId value is only valid for 7 days.
  --max-results: int # The maximum number of results to return per paginated call. The largest value that you can specify is 30. If you specify a value greater than 30, a maximum of 30 results is returned. The default value is 30.
  --next-token: string # If the previous response was incomplete, Amazon Textract returns a pagination token in the response. You can use this pagination token to retrieve the next set of lending results.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Textract.GetLendingAnalysis"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobId, var: job_id}, {name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_id: $job_id, max_results: $max_results, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets summarized results for the StartLendingAnalysis operation, which analyzes text in a lending document. The returned summary consists of information about documents grouped together by a common document type. Information like detected signatures, page numbers, and split documents is returned with respect to the type of grouped document. You start asynchronous text analysis by calling StartLendingAnalysis, which returns a job identifier (JobId). When the text analysis operation finishes, Amazon Textract publishes a completion status to the Amazon Simple Notification Service (Amazon SNS) topic that's registered in the initial call to StartLendingAnalysis. To get the results of the text analysis operation, first check that the status value published to the Amazon SNS topic is SUCCEEDED. If so, call GetLendingAnalysisSummary, and pass the job identifier (JobId) from the initial call to StartLendingAnalysis.
#
# POST /
# Returns: record<DocumentMetadata: record<Pages: int>, JobStatus: string, Summary: record<DocumentGroups: list<record>, UndetectedDocumentTypes: list<string>>, Warnings: table<ErrorCode: string, Pages: list>, StatusMessage: string, AnalyzeLendingModelVersion: string>
# operationId: GetLendingAnalysisSummary
export def "get-lending-analysis-summary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  job_id: string # A unique identifier for the lending or text-detection job. The JobId is returned from StartLendingAnalysis. A JobId value is only valid for 7 days.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Textract.GetLendingAnalysisSummary"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobId, var: job_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts the asynchronous analysis of an input document for relationships between detected items such as key-value pairs, tables, and selection elements. StartDocumentAnalysis can analyze text in documents that are in JPEG, PNG, TIFF, and PDF format. The documents are stored in an Amazon S3 bucket. Use DocumentLocation to specify the bucket name and file name of the document. StartDocumentAnalysis returns a job identifier (JobId) that you use to get the results of the operation. When text analysis is finished, Amazon Textract publishes a completion status to the Amazon Simple Notification Service (Amazon SNS) topic that you specify in NotificationChannel. To get the results of the text analysis operation, first check that the status value published to the Amazon SNS topic is SUCCEEDED. If so, call GetDocumentAnalysis, and pass the job identifier (JobId) from the initial call to StartDocumentAnalysis. For more information, see Document Text Analysis (https://docs.aws.amazon.com/textract/latest/dg/how-it-works-analyzing.html).
#
# POST /
# Returns: record<JobId: string>
# operationId: StartDocumentAnalysis
export def "start-document-analysis" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  document_location: record # The Amazon S3 bucket that contains the document to be processed. It's used by asynchronous operations. The input document can be an image file in JPEG or PNG format. It can also be a file in PDF format. — shape: {S3Object?: record}
  feature_types: list<string> # A list of the types of analysis to perform. Add TABLES to the list to return information about the tables that are detected in the input document. Add FORMS to return detected form data. To perform both types of analysis, add TABLES and FORMS to FeatureTypes. All lines and words detected in the document are included in the response (including text that isn't related to the value of FeatureTypes).
  --client-request-token: string # The idempotent token that you use to identify the start request. If you use the same token with multiple StartDocumentAnalysis requests, the same JobId is returned. Use ClientRequestToken to prevent the same job from being accidentally started more than once. For more information, see Calling Amazon Textract Asynchronous Operations (https://docs.aws.amazon.com/textract/latest/dg/api-async.html).
  --job-tag: string # An identifier that you specify that's included in the completion notification published to the Amazon SNS topic. For example, you can use JobTag to identify the type of document that the completion notification corresponds to (such as a tax form or a receipt).
  --notification-channel: record # The Amazon Simple Notification Service (Amazon SNS) topic to which Amazon Textract publishes the completion status of an asynchronous document operation. — shape: {SNSTopicArn: string, RoleArn: string}
  --output-config: record # Sets whether or not your output will go to a user created bucket. Used to set the name of the bucket, and the prefix on the output file. OutputConfig is an optional parameter which lets you adjust where your output will be placed. By default, Amazon Textract will store the results internally and can only be accessed by the Get API operations. With OutputConfig enabled, you can set the name of the bucket the output will be sent to the file prefix of the results where you can download your results. Additionally, you can set the KMSKeyID parameter to a customer master key (CMK) to encrypt your output. Without this parameter set Amazon Textract will encrypt server-side using the AWS managed CMK for Amazon S3. Decryption of Customer Content is necessary for processing of the documents by Amazon Textract. If your account is opted out under an AI services opt out policy then all unencrypted Customer Content is immediately and permanently deleted after the Customer Content has been processed by the service. No copy of of the output is retained by Amazon Textract. For information about how to opt out, see Managing AI services opt-out policy. (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_ai-opt-out.html) For more information on data privacy, see the Data Privacy FAQ (https://aws.amazon.com/compliance/data-privacy-faq/). — shape: {S3Bucket: string, S3Prefix?: string}
  --kms-key-id: string # The KMS key used to encrypt the inference results. This can be in either Key ID or Key Alias format. When a KMS key is provided, the KMS key will be used for server-side encryption of the objects in the customer bucket. When this parameter is not enabled, the result will be encrypted server side,using SSE-S3.
  --queries-config: record # shape: {Queries: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Textract.StartDocumentAnalysis"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DocumentLocation, var: document_location}, {name: FeatureTypes, var: feature_types}, {name: ClientRequestToken, var: client_request_token}, {name: JobTag, var: job_tag}, {name: NotificationChannel, var: notification_channel}, {name: OutputConfig, var: output_config}, {name: KMSKeyId, var: kms_key_id}, {name: QueriesConfig, var: queries_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, document_location: $document_location, feature_types: $feature_types, client_request_token: $client_request_token, job_tag: $job_tag, notification_channel: $notification_channel, output_config: $output_config, kms_key_id: $kms_key_id, queries_config: $queries_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts the asynchronous detection of text in a document. Amazon Textract can detect lines of text and the words that make up a line of text. StartDocumentTextDetection can analyze text in documents that are in JPEG, PNG, TIFF, and PDF format. The documents are stored in an Amazon S3 bucket. Use DocumentLocation to specify the bucket name and file name of the document. StartTextDetection returns a job identifier (JobId) that you use to get the results of the operation. When text detection is finished, Amazon Textract publishes a completion status to the Amazon Simple Notification Service (Amazon SNS) topic that you specify in NotificationChannel. To get the results of the text detection operation, first check that the status value published to the Amazon SNS topic is SUCCEEDED. If so, call GetDocumentTextDetection, and pass the job identifier (JobId) from the initial call to StartDocumentTextDetection. For more information, see Document Text Detection (https://docs.aws.amazon.com/textract/latest/dg/how-it-works-detecting.html).
#
# POST /
# Returns: record<JobId: string>
# operationId: StartDocumentTextDetection
export def "start-document-text-detection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  document_location: record # The Amazon S3 bucket that contains the document to be processed. It's used by asynchronous operations. The input document can be an image file in JPEG or PNG format. It can also be a file in PDF format. — shape: {S3Object?: record}
  --client-request-token: string # The idempotent token that's used to identify the start request. If you use the same token with multiple StartDocumentTextDetection requests, the same JobId is returned. Use ClientRequestToken to prevent the same job from being accidentally started more than once. For more information, see Calling Amazon Textract Asynchronous Operations (https://docs.aws.amazon.com/textract/latest/dg/api-async.html).
  --job-tag: string # An identifier that you specify that's included in the completion notification published to the Amazon SNS topic. For example, you can use JobTag to identify the type of document that the completion notification corresponds to (such as a tax form or a receipt).
  --notification-channel: record # The Amazon Simple Notification Service (Amazon SNS) topic to which Amazon Textract publishes the completion status of an asynchronous document operation. — shape: {SNSTopicArn: string, RoleArn: string}
  --output-config: record # Sets whether or not your output will go to a user created bucket. Used to set the name of the bucket, and the prefix on the output file. OutputConfig is an optional parameter which lets you adjust where your output will be placed. By default, Amazon Textract will store the results internally and can only be accessed by the Get API operations. With OutputConfig enabled, you can set the name of the bucket the output will be sent to the file prefix of the results where you can download your results. Additionally, you can set the KMSKeyID parameter to a customer master key (CMK) to encrypt your output. Without this parameter set Amazon Textract will encrypt server-side using the AWS managed CMK for Amazon S3. Decryption of Customer Content is necessary for processing of the documents by Amazon Textract. If your account is opted out under an AI services opt out policy then all unencrypted Customer Content is immediately and permanently deleted after the Customer Content has been processed by the service. No copy of of the output is retained by Amazon Textract. For information about how to opt out, see Managing AI services opt-out policy. (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_ai-opt-out.html) For more information on data privacy, see the Data Privacy FAQ (https://aws.amazon.com/compliance/data-privacy-faq/). — shape: {S3Bucket: string, S3Prefix?: string}
  --kms-key-id: string # The KMS key used to encrypt the inference results. This can be in either Key ID or Key Alias format. When a KMS key is provided, the KMS key will be used for server-side encryption of the objects in the customer bucket. When this parameter is not enabled, the result will be encrypted server side,using SSE-S3.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Textract.StartDocumentTextDetection"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DocumentLocation, var: document_location}, {name: ClientRequestToken, var: client_request_token}, {name: JobTag, var: job_tag}, {name: NotificationChannel, var: notification_channel}, {name: OutputConfig, var: output_config}, {name: KMSKeyId, var: kms_key_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, document_location: $document_location, client_request_token: $client_request_token, job_tag: $job_tag, notification_channel: $notification_channel, output_config: $output_config, kms_key_id: $kms_key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts the asynchronous analysis of invoices or receipts for data like contact information, items purchased, and vendor names. StartExpenseAnalysis can analyze text in documents that are in JPEG, PNG, and PDF format. The documents must be stored in an Amazon S3 bucket. Use the DocumentLocation parameter to specify the name of your S3 bucket and the name of the document in that bucket. StartExpenseAnalysis returns a job identifier (JobId) that you will provide to GetExpenseAnalysis to retrieve the results of the operation. When the analysis of the input invoices/receipts is finished, Amazon Textract publishes a completion status to the Amazon Simple Notification Service (Amazon SNS) topic that you provide to the NotificationChannel. To obtain the results of the invoice and receipt analysis operation, ensure that the status value published to the Amazon SNS topic is SUCCEEDED. If so, call GetExpenseAnalysis, and pass the job identifier (JobId) that was returned by your call to StartExpenseAnalysis. For more information, see Analyzing Invoices and Receipts (https://docs.aws.amazon.com/textract/latest/dg/invoice-receipts.html).
#
# POST /
# Returns: record<JobId: string>
# operationId: StartExpenseAnalysis
export def "start-expense-analysis" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  document_location: record # The Amazon S3 bucket that contains the document to be processed. It's used by asynchronous operations. The input document can be an image file in JPEG or PNG format. It can also be a file in PDF format. — shape: {S3Object?: record}
  --client-request-token: string # The idempotent token that's used to identify the start request. If you use the same token with multiple StartDocumentTextDetection requests, the same JobId is returned. Use ClientRequestToken to prevent the same job from being accidentally started more than once. For more information, see Calling Amazon Textract Asynchronous Operations (https://docs.aws.amazon.com/textract/latest/dg/api-async.html)
  --job-tag: string # An identifier you specify that's included in the completion notification published to the Amazon SNS topic. For example, you can use JobTag to identify the type of document that the completion notification corresponds to (such as a tax form or a receipt).
  --notification-channel: record # The Amazon Simple Notification Service (Amazon SNS) topic to which Amazon Textract publishes the completion status of an asynchronous document operation. — shape: {SNSTopicArn: string, RoleArn: string}
  --output-config: record # Sets whether or not your output will go to a user created bucket. Used to set the name of the bucket, and the prefix on the output file. OutputConfig is an optional parameter which lets you adjust where your output will be placed. By default, Amazon Textract will store the results internally and can only be accessed by the Get API operations. With OutputConfig enabled, you can set the name of the bucket the output will be sent to the file prefix of the results where you can download your results. Additionally, you can set the KMSKeyID parameter to a customer master key (CMK) to encrypt your output. Without this parameter set Amazon Textract will encrypt server-side using the AWS managed CMK for Amazon S3. Decryption of Customer Content is necessary for processing of the documents by Amazon Textract. If your account is opted out under an AI services opt out policy then all unencrypted Customer Content is immediately and permanently deleted after the Customer Content has been processed by the service. No copy of of the output is retained by Amazon Textract. For information about how to opt out, see Managing AI services opt-out policy. (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_ai-opt-out.html) For more information on data privacy, see the Data Privacy FAQ (https://aws.amazon.com/compliance/data-privacy-faq/). — shape: {S3Bucket: string, S3Prefix?: string}
  --kms-key-id: string # The KMS key used to encrypt the inference results. This can be in either Key ID or Key Alias format. When a KMS key is provided, the KMS key will be used for server-side encryption of the objects in the customer bucket. When this parameter is not enabled, the result will be encrypted server side,using SSE-S3.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Textract.StartExpenseAnalysis"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DocumentLocation, var: document_location}, {name: ClientRequestToken, var: client_request_token}, {name: JobTag, var: job_tag}, {name: NotificationChannel, var: notification_channel}, {name: OutputConfig, var: output_config}, {name: KMSKeyId, var: kms_key_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, document_location: $document_location, client_request_token: $client_request_token, job_tag: $job_tag, notification_channel: $notification_channel, output_config: $output_config, kms_key_id: $kms_key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts the classification and analysis of an input document. StartLendingAnalysis initiates the classification and analysis of a packet of lending documents. StartLendingAnalysis operates on a document file located in an Amazon S3 bucket. StartLendingAnalysis can analyze text in documents that are in one of the following formats: JPEG, PNG, TIFF, PDF. Use DocumentLocation to specify the bucket name and the file name of the document. StartLendingAnalysis returns a job identifier (JobId) that you use to get the results of the operation. When the text analysis is finished, Amazon Textract publishes a completion status to the Amazon Simple Notification Service (Amazon SNS) topic that you specify in NotificationChannel. To get the results of the text analysis operation, first check that the status value published to the Amazon SNS topic is SUCCEEDED. If the status is SUCCEEDED you can call either GetLendingAnalysis or GetLendingAnalysisSummary and provide the JobId to obtain the results of the analysis. If using OutputConfig to specify an Amazon S3 bucket, the output will be contained within the specified prefix in a directory labeled with the job-id. In the directory there are 3 sub-directories: detailedResponse (contains the GetLendingAnalysis response) summaryResponse (for the GetLendingAnalysisSummary response) splitDocuments (documents split across logical boundaries)
#
# POST /
# Returns: record<JobId: string>
# operationId: StartLendingAnalysis
export def "start-lending-analysis" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  document_location: record # The Amazon S3 bucket that contains the document to be processed. It's used by asynchronous operations. The input document can be an image file in JPEG or PNG format. It can also be a file in PDF format. — shape: {S3Object?: record}
  --client-request-token: string # The idempotent token that you use to identify the start request. If you use the same token with multiple StartLendingAnalysis requests, the same JobId is returned. Use ClientRequestToken to prevent the same job from being accidentally started more than once. For more information, see Calling Amazon Textract Asynchronous Operations (https://docs.aws.amazon.com/textract/latest/dg/api-sync.html).
  --job-tag: string # An identifier that you specify to be included in the completion notification published to the Amazon SNS topic. For example, you can use JobTag to identify the type of document that the completion notification corresponds to (such as a tax form or a receipt).
  --notification-channel: record # The Amazon Simple Notification Service (Amazon SNS) topic to which Amazon Textract publishes the completion status of an asynchronous document operation. — shape: {SNSTopicArn: string, RoleArn: string}
  --output-config: record # Sets whether or not your output will go to a user created bucket. Used to set the name of the bucket, and the prefix on the output file. OutputConfig is an optional parameter which lets you adjust where your output will be placed. By default, Amazon Textract will store the results internally and can only be accessed by the Get API operations. With OutputConfig enabled, you can set the name of the bucket the output will be sent to the file prefix of the results where you can download your results. Additionally, you can set the KMSKeyID parameter to a customer master key (CMK) to encrypt your output. Without this parameter set Amazon Textract will encrypt server-side using the AWS managed CMK for Amazon S3. Decryption of Customer Content is necessary for processing of the documents by Amazon Textract. If your account is opted out under an AI services opt out policy then all unencrypted Customer Content is immediately and permanently deleted after the Customer Content has been processed by the service. No copy of of the output is retained by Amazon Textract. For information about how to opt out, see Managing AI services opt-out policy. (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_ai-opt-out.html) For more information on data privacy, see the Data Privacy FAQ (https://aws.amazon.com/compliance/data-privacy-faq/). — shape: {S3Bucket: string, S3Prefix?: string}
  --kms-key-id: string # The KMS key used to encrypt the inference results. This can be in either Key ID or Key Alias format. When a KMS key is provided, the KMS key will be used for server-side encryption of the objects in the customer bucket. When this parameter is not enabled, the result will be encrypted server side, using SSE-S3.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Textract.StartLendingAnalysis"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DocumentLocation, var: document_location}, {name: ClientRequestToken, var: client_request_token}, {name: JobTag, var: job_tag}, {name: NotificationChannel, var: notification_channel}, {name: OutputConfig, var: output_config}, {name: KMSKeyId, var: kms_key_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, document_location: $document_location, client_request_token: $client_request_token, job_tag: $job_tag, notification_channel: $notification_channel, output_config: $output_config, kms_key_id: $kms_key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
