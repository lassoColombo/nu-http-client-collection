# Auto-generated client for Taxamo v1
# Source: https://api.apis.guru/v2/specs/taxamo.com/1/swagger.json
# Auth: --token flag or $env.TAXAMO_TOKEN

const CLIENT = {
  base_url: "https://api.taxamo.com"
  token_env_var: "TAXAMO_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: token, in: header, header_name: Token, prefix: ""}
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

def base-url-completer [] { ["https://api.taxamo.com"] }
def auth-scheme-completer [] { ["token"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-countries-dict: "record<dictionary: table<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>>"
    get-currencies-dict: "record<dictionary: table<code: string, description: string, isocode: string, isonum: int, minorunits: int>>"
    get-product-types-dict: "record<dictionary: table<code: string>>"
    locate-my-ip: "record<country: record<callingCode: list<string>, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list<string>, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, country_code: string, remote_addr: string>"
    locate-given-ip: "record<country: record<callingCode: list<string>, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list<string>, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, country_code: string, remote_addr: string>"
    get-domestic-summary-report: "record<currency_code: string, domestic_refunds_amount: float, domestic_refunds_tax_amount: float, domestic_sales_amount: float, domestic_tax_amount: float, end_date: string, eu_tax_deducted_refunds: float, eu_tax_deducted_sales: float, global_refunds_amount: float, global_refunds_tax_amount: float, global_sales_amount: float, global_sales_tax_amount: float, start_date: string>"
    get-eu-vies-report: "record<currency_code: string, end_date: string, report: table<amount: float, country_code: string, country_name: string, country_subdivision: string, currency_code: string, skip_moss: bool, tax_amount: float, tax_rate: float, tax_region: string>, start_date: string>"
    get-detailed-refunds: "record<report: table<amount: float, country_code: string, country_name: string, country_subdivision: string, currency_code: string, skip_moss: bool, tax_amount: float, tax_rate: float, tax_region: string>>"
    get-refunds: "record<report: table<amount: float, country_code: string, country_name: string, country_subdivision: string, currency_code: string, skip_moss: bool, tax_amount: float, tax_rate: float, tax_region: string>>"
    get-settlement-summary: "record<summary: record<currency_code: string, end_date: string, fx_rate_date: string, indicative: bool, quarter: string, start_date: string, tax_amount: float, tax_entity_name: string>>"
    get-settlement: "record<end_date: string, fx_rate_date: string, indicative: bool, report: table<amount: float, country_code: string, country_name: string, country_subdivision: string, currency_code: string, skip_moss: bool, tax_amount: float, tax_rate: float, tax_region: string>, start_date: string>"
    get-settlement-stats-by-country: "record<by_country: table<currency_code: string, tax_country_code: string, tax_country_name: string, value: float>>"
    get-settlement-stats-by-taxation-type: "record<by_taxation_type: record<deducted_count: float, eu_b2b: int, eu_taxed: int, taxed_count: float, transactions_count: float>>"
    get-daily-settlement-stats: "record<settlement_daily: table<b2b: int, b2c: int, count: int, day: string, day_raw: string, eu_b2b: int, eu_taxed: int, eu_total: int, untaxed: int>>"
    get-transactions-stats: "record<by_status: record<C: list<record>, N: list<record>>>"
    get-transactions-stats-by-country: "record<by_country: table<currency_code: string, tax_country_code: string, tax_country_name: string, value: float>>"
    calculate-simple-tax: "record<storage_required_fields: table<field_name: string>, tax_required_fields: table<field_name: string>, transaction: record<additional_currencies: record<invoice: record>, amount: float, billing_country_code: string, buyer_credit_card_prefix: string, buyer_email: string, buyer_ip: string, buyer_name: string, buyer_tax_number: string, buyer_tax_number_valid: bool, comments: string, confirm_timestamp: string, countries: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_tax_number: record, by_token: record, detected: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, create_timestamp: string, currency_code: string, custom_data: string, custom_fields: list<record>, custom_id: string, customer_id: string, deducted_tax_amount: float, description: string, evidence: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_payment_method: record, by_tax_number: record, by_token: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, external_key: string, force_country_code: string, fully_informative: bool, invoice_address: record<address_detail: string, building_number: string, city: string, country: string, freeform_address: string, postal_code: string, region: string, street_name: string>, invoice_date: string, invoice_image_url: string, invoice_number: string, invoice_place: string, key: string, kind: string, manual: bool, note: string, order_date: string, original_transaction_key: string, refunded_tax_amount: float, refunded_total_amount: float, source: string, status: string, sub_account_id: string, supply_date: string, tax_amount: float, tax_country_code: string, tax_data: record<us_tax_exemption_certificate: record>, tax_deducted: bool, tax_entity_name: string, tax_number_service: string, tax_supported: bool, tax_timezone: string, test: bool, total_amount: float, transaction_lines: list<record>, verification_token: string>>"
    calculate-tax: "record<storage_required_fields: table<field_name: string>, tax_required_fields: table<field_name: string>, transaction: record<additional_currencies: record<invoice: record>, amount: float, billing_country_code: string, buyer_credit_card_prefix: string, buyer_email: string, buyer_ip: string, buyer_name: string, buyer_tax_number: string, buyer_tax_number_valid: bool, comments: string, confirm_timestamp: string, countries: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_tax_number: record, by_token: record, detected: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, create_timestamp: string, currency_code: string, custom_data: string, custom_fields: list<record>, custom_id: string, customer_id: string, deducted_tax_amount: float, description: string, evidence: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_payment_method: record, by_tax_number: record, by_token: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, external_key: string, force_country_code: string, fully_informative: bool, invoice_address: record<address_detail: string, building_number: string, city: string, country: string, freeform_address: string, postal_code: string, region: string, street_name: string>, invoice_date: string, invoice_image_url: string, invoice_number: string, invoice_place: string, key: string, kind: string, manual: bool, note: string, order_date: string, original_transaction_key: string, refunded_tax_amount: float, refunded_total_amount: float, source: string, status: string, sub_account_id: string, supply_date: string, tax_amount: float, tax_country_code: string, tax_data: record<us_tax_exemption_certificate: record>, tax_deducted: bool, tax_entity_name: string, tax_number_service: string, tax_supported: bool, tax_timezone: string, test: bool, total_amount: float, transaction_lines: list<record>, verification_token: string>>"
    calculate-tax-location: "record<billing_country_code: string, buyer_credit_card_prefix: string, buyer_ip: string, countries: record<by_2003_rules: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, by_billing: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, by_cc: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, by_ip: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, by_tax_number: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, by_token: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, detected: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, forced: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, guessed_from_ip: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, other_commercially_relevant_info: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, self_declaration: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>>, evidence: record<by_2003_rules: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>, by_billing: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>, by_cc: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>, by_ip: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>, by_payment_method: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>, by_tax_number: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>, by_token: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>, forced: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>, guessed_from_ip: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>, other_commercially_relevant_info: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>, self_declaration: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>>, tax_country_code: string, tax_deducted: bool, tax_supported: bool>"
    validate-tax-number: "record<billing_country_code: string, buyer_tax_number: string, buyer_tax_number_valid: bool, tax_deducted: bool>"
    list-transactions: "record<transactions: table<additional_currencies: record, amount: float, billing_country_code: string, buyer_credit_card_prefix: string, buyer_email: string, buyer_ip: string, buyer_name: string, buyer_tax_number: string, buyer_tax_number_valid: bool, comments: string, confirm_timestamp: string, countries: record, create_timestamp: string, currency_code: string, custom_data: string, custom_fields: list, custom_id: string, customer_id: string, deducted_tax_amount: float, description: string, evidence: record, external_key: string, force_country_code: string, fully_informative: bool, invoice_address: record, invoice_date: string, invoice_image_url: string, invoice_number: string, invoice_place: string, key: string, kind: string, manual: bool, note: string, order_date: string, original_transaction_key: string, refunded_tax_amount: float, refunded_total_amount: float, source: string, status: string, sub_account_id: string, supply_date: string, tax_amount: float, tax_country_code: string, tax_data: record, tax_deducted: bool, tax_entity_name: string, tax_number_service: string, tax_supported: bool, tax_timezone: string, test: bool, total_amount: float, transaction_lines: list, verification_token: string>>"
    create-transaction: "record<storage_required_fields: table<field_name: string>, tax_required_fields: table<field_name: string>, transaction: record<additional_currencies: record<invoice: record>, amount: float, billing_country_code: string, buyer_credit_card_prefix: string, buyer_email: string, buyer_ip: string, buyer_name: string, buyer_tax_number: string, buyer_tax_number_valid: bool, comments: string, confirm_timestamp: string, countries: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_tax_number: record, by_token: record, detected: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, create_timestamp: string, currency_code: string, custom_data: string, custom_fields: list<record>, custom_id: string, customer_id: string, deducted_tax_amount: float, description: string, evidence: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_payment_method: record, by_tax_number: record, by_token: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, external_key: string, force_country_code: string, fully_informative: bool, invoice_address: record<address_detail: string, building_number: string, city: string, country: string, freeform_address: string, postal_code: string, region: string, street_name: string>, invoice_date: string, invoice_image_url: string, invoice_number: string, invoice_place: string, key: string, kind: string, manual: bool, note: string, order_date: string, original_transaction_key: string, refunded_tax_amount: float, refunded_total_amount: float, source: string, status: string, sub_account_id: string, supply_date: string, tax_amount: float, tax_country_code: string, tax_data: record<us_tax_exemption_certificate: record>, tax_deducted: bool, tax_entity_name: string, tax_number_service: string, tax_supported: bool, tax_timezone: string, test: bool, total_amount: float, transaction_lines: list<record>, verification_token: string>>"
    cancel-transaction: "record<success: bool>"
    get-transaction: "record<storage_required_fields: table<field_name: string>, tax_required_fields: table<field_name: string>, transaction: record<additional_currencies: record<invoice: record>, amount: float, billing_country_code: string, buyer_credit_card_prefix: string, buyer_email: string, buyer_ip: string, buyer_name: string, buyer_tax_number: string, buyer_tax_number_valid: bool, comments: string, confirm_timestamp: string, countries: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_tax_number: record, by_token: record, detected: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, create_timestamp: string, currency_code: string, custom_data: string, custom_fields: list<record>, custom_id: string, customer_id: string, deducted_tax_amount: float, description: string, evidence: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_payment_method: record, by_tax_number: record, by_token: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, external_key: string, force_country_code: string, fully_informative: bool, invoice_address: record<address_detail: string, building_number: string, city: string, country: string, freeform_address: string, postal_code: string, region: string, street_name: string>, invoice_date: string, invoice_image_url: string, invoice_number: string, invoice_place: string, key: string, kind: string, manual: bool, note: string, order_date: string, original_transaction_key: string, refunded_tax_amount: float, refunded_total_amount: float, source: string, status: string, sub_account_id: string, supply_date: string, tax_amount: float, tax_country_code: string, tax_data: record<us_tax_exemption_certificate: record>, tax_deducted: bool, tax_entity_name: string, tax_number_service: string, tax_supported: bool, tax_timezone: string, test: bool, total_amount: float, transaction_lines: list<record>, verification_token: string>>"
    update-transaction: "record<storage_required_fields: table<field_name: string>, tax_required_fields: table<field_name: string>, transaction: record<additional_currencies: record<invoice: record>, amount: float, billing_country_code: string, buyer_credit_card_prefix: string, buyer_email: string, buyer_ip: string, buyer_name: string, buyer_tax_number: string, buyer_tax_number_valid: bool, comments: string, confirm_timestamp: string, countries: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_tax_number: record, by_token: record, detected: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, create_timestamp: string, currency_code: string, custom_data: string, custom_fields: list<record>, custom_id: string, customer_id: string, deducted_tax_amount: float, description: string, evidence: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_payment_method: record, by_tax_number: record, by_token: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, external_key: string, force_country_code: string, fully_informative: bool, invoice_address: record<address_detail: string, building_number: string, city: string, country: string, freeform_address: string, postal_code: string, region: string, street_name: string>, invoice_date: string, invoice_image_url: string, invoice_number: string, invoice_place: string, key: string, kind: string, manual: bool, note: string, order_date: string, original_transaction_key: string, refunded_tax_amount: float, refunded_total_amount: float, source: string, status: string, sub_account_id: string, supply_date: string, tax_amount: float, tax_country_code: string, tax_data: record<us_tax_exemption_certificate: record>, tax_deducted: bool, tax_entity_name: string, tax_number_service: string, tax_supported: bool, tax_timezone: string, test: bool, total_amount: float, transaction_lines: list<record>, verification_token: string>>"
    confirm-transaction: "record<storage_required_fields: table<field_name: string>, tax_required_fields: table<field_name: string>, transaction: record<additional_currencies: record<invoice: record>, amount: float, billing_country_code: string, buyer_credit_card_prefix: string, buyer_email: string, buyer_ip: string, buyer_name: string, buyer_tax_number: string, buyer_tax_number_valid: bool, comments: string, confirm_timestamp: string, countries: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_tax_number: record, by_token: record, detected: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, create_timestamp: string, currency_code: string, custom_data: string, custom_fields: list<record>, custom_id: string, customer_id: string, deducted_tax_amount: float, description: string, evidence: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_payment_method: record, by_tax_number: record, by_token: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, external_key: string, force_country_code: string, fully_informative: bool, invoice_address: record<address_detail: string, building_number: string, city: string, country: string, freeform_address: string, postal_code: string, region: string, street_name: string>, invoice_date: string, invoice_image_url: string, invoice_number: string, invoice_place: string, key: string, kind: string, manual: bool, note: string, order_date: string, original_transaction_key: string, refunded_tax_amount: float, refunded_total_amount: float, source: string, status: string, sub_account_id: string, supply_date: string, tax_amount: float, tax_country_code: string, tax_data: record<us_tax_exemption_certificate: record>, tax_deducted: bool, tax_entity_name: string, tax_number_service: string, tax_supported: bool, tax_timezone: string, test: bool, total_amount: float, transaction_lines: list<record>, verification_token: string>>"
    email-refund: "record<success: bool>"
    email-invoice: "record<success: bool>"
    list-payments: "record<payments: table<amount: float, payment_information: string, payment_timestamp: string>>"
    create-payment: "record<success: bool>"
    capture-payment: "record<success: bool>"
    list-refunds: "record<refunds: table<amount: float, informative: bool, line_key: string, refund_note_number: string, refund_note_url: string, refund_reason: string, refund_timestamp: string, tax_amount: float, tax_rate: float, total_amount: float>>"
    create-refund: "record<refunded_tax_amount: float, refunded_total_amount: float, tax_amount: float, total_amount: float>"
    unconfirm-transaction: "record<storage_required_fields: table<field_name: string>, tax_required_fields: table<field_name: string>, transaction: record<additional_currencies: record<invoice: record>, amount: float, billing_country_code: string, buyer_credit_card_prefix: string, buyer_email: string, buyer_ip: string, buyer_name: string, buyer_tax_number: string, buyer_tax_number_valid: bool, comments: string, confirm_timestamp: string, countries: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_tax_number: record, by_token: record, detected: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, create_timestamp: string, currency_code: string, custom_data: string, custom_fields: list<record>, custom_id: string, customer_id: string, deducted_tax_amount: float, description: string, evidence: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_payment_method: record, by_tax_number: record, by_token: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, external_key: string, force_country_code: string, fully_informative: bool, invoice_address: record<address_detail: string, building_number: string, city: string, country: string, freeform_address: string, postal_code: string, region: string, street_name: string>, invoice_date: string, invoice_image_url: string, invoice_number: string, invoice_place: string, key: string, kind: string, manual: bool, note: string, order_date: string, original_transaction_key: string, refunded_tax_amount: float, refunded_total_amount: float, source: string, status: string, sub_account_id: string, supply_date: string, tax_amount: float, tax_country_code: string, tax_data: record<us_tax_exemption_certificate: record>, tax_deducted: bool, tax_entity_name: string, tax_number_service: string, tax_supported: bool, tax_timezone: string, test: bool, total_amount: float, transaction_lines: list<record>, verification_token: string>>"
    create-sms-token: "record<success: bool>"
    verify-sms-token: "record<country_code: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-countries-dict" "get-currencies-dict" "get-product-types-dict" "locate-my-ip" "locate-given-ip" "get-domestic-summary-report" "get-eu-vies-report" "get-detailed-refunds" "get-refunds" "get-settlement-summary" "get-settlement" "get-settlement-stats-by-country" "get-settlement-stats-by-taxation-type" "get-daily-settlement-stats" "get-transactions-stats" "get-transactions-stats-by-country" "calculate-simple-tax" "calculate-tax" "calculate-tax-location" "validate-tax-number" "list-transactions" "create-transaction" "cancel-transaction" "get-transaction" "update-transaction" "confirm-transaction" "email-refund" "email-invoice" "list-payments" "create-payment" "capture-payment" "list-refunds" "create-refund" "unconfirm-transaction" "create-sms-token" "verify-sms-token" "commands"] | sort) } | get name | first)
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

# Countries
#
# GET /api/v1/dictionaries/countries
# Returns: record<dictionary: table<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>>
# operationId: getCountriesDict
export def "get-countries-dict" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tax-supported: oneof<nothing, bool> # Should only countries with tax supported be listed?
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/dictionaries/countries"
    query: [{name: tax_supported, var: tax_supported}]
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    tax_supported: $tax_supported
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Currencies
#
# GET /api/v1/dictionaries/currencies
# Returns: record<dictionary: table<code: string, description: string, isocode: string, isonum: int, minorunits: int>>
# operationId: getCurrenciesDict
export def "get-currencies-dict" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/dictionaries/currencies"
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Product types
#
# GET /api/v1/dictionaries/product_types
# Returns: record<dictionary: table<code: string>>
# operationId: getProductTypesDict
export def "get-product-types-dict" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/dictionaries/product_types"
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Locate IP
#
# GET /api/v1/geoip
# Returns: record<country: record<callingCode: list<string>, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list<string>, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, country_code: string, remote_addr: string>
# operationId: locateMyIP
export def "locate-my-ip" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/geoip"
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Locate provided IP
#
# GET /api/v1/geoip/{ip}
# Returns: record<country: record<callingCode: list<string>, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list<string>, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, country_code: string, remote_addr: string>
# operationId: locateGivenIP
export def "locate-given-ip" [
  ip: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/geoip/{ip}"
    path_params: [{name: ip, var: ip}]
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    ip: $ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Calculate domestic summary
#
# GET /api/v1/reports/domestic/summary
# Returns: record<currency_code: string, domestic_refunds_amount: float, domestic_refunds_tax_amount: float, domestic_sales_amount: float, domestic_tax_amount: float, end_date: string, eu_tax_deducted_refunds: float, eu_tax_deducted_sales: float, global_refunds_amount: float, global_refunds_tax_amount: float, global_sales_amount: float, global_sales_tax_amount: float, start_date: string>
# operationId: getDomesticSummaryReport
export def "get-domestic-summary-report" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # Output format. 'xml' and 'csv' values are accepted. Default format - json
  --country-code: string # ISO 2-letter country code which will be used for determining which country is domestic. (required)
  --currency-code: string # ISO 3-letter currency code, e.g. EUR or USD. Defaults to the one assigned to MOSS calculations for a given country code.
  --start-month: string # Period start month in yyyy-MM format. (required)
  --end-month: string # Period end month in yyyy-MM format. (required)
  --fx-date-type: string # Which date should be used for FX.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/reports/domestic/summary"
    query: [{name: format, var: format}, {name: country_code, var: country_code, required: true}, {name: currency_code, var: currency_code}, {name: start_month, var: start_month, required: true}, {name: end_month, var: end_month, required: true}, {name: fx_date_type, var: fx_date_type}]
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    format: $format, country_code: $country_code, currency_code: $currency_code, start_month: $start_month, end_month: $end_month, fx_date_type: $fx_date_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Calculate EU VIES report
#
# GET /api/v1/reports/eu/vies
# Returns: record<currency_code: string, end_date: string, report: table<amount: float, country_code: string, country_name: string, country_subdivision: string, currency_code: string, skip_moss: bool, tax_amount: float, tax_rate: float, tax_region: string>, start_date: string>
# operationId: getEuViesReport
export def "get-eu-vies-report" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --period-length: string # Length of report period. 'month', 'quarter' and 'year' values are accepted. Required only if Large Filer Format is requested.
  --lff-sequence-number: string # Sequence number used to generate report in Large Filer Format. If not specified then '0000000001' will be used.
  --transformation: string # Which transformation should be applied. Please note that transformation will be applied only for xml and csv formats.
  --currency-code: string # ISO 3-letter currency code, e.g. EUR or USD. Defaults to the one assigned to MOSS calculations for a given country code.
  --end-month: string # Period end month in yyyy-MM format. (required)
  --tax-id: string # MOSS-assigned tax ID - if not provided, merchant's national tax number will be used.
  --start-month: string # Period start month in yyyy-MM format. (required)
  --eu-country-code: string # ISO 2-letter country code which will be used for determining which country is domestic. (required)
  --fx-date-type: string # Which date should be used for FX.
  --format: string # Output format. 'xml', 'csv' and 'lff' (only for Ireland) values are accepted as well
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/reports/eu/vies"
    query: [{name: period_length, var: period_length}, {name: lff_sequence_number, var: lff_sequence_number}, {name: transformation, var: transformation}, {name: currency_code, var: currency_code}, {name: end_month, var: end_month, required: true}, {name: tax_id, var: tax_id}, {name: start_month, var: start_month, required: true}, {name: eu_country_code, var: eu_country_code, required: true}, {name: fx_date_type, var: fx_date_type}, {name: format, var: format}]
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    period_length: $period_length, lff_sequence_number: $lff_sequence_number, transformation: $transformation, currency_code: $currency_code, end_month: $end_month, tax_id: $tax_id, start_month: $start_month, eu_country_code: $eu_country_code, fx_date_type: $fx_date_type, format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detailed refunds
#
# GET /api/v1/settlement/detailed_refunds
# Returns: record<report: table<amount: float, country_code: string, country_name: string, country_subdivision: string, currency_code: string, skip_moss: bool, tax_amount: float, tax_rate: float, tax_region: string>>
# operationId: getDetailedRefunds
export def "get-detailed-refunds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # Output format. 'json' or 'csv'. Default value is 'json'
  --country-codes: string # Comma separated list of 2-letter country codes
  --date-from: string # Take only refunds issued at or after the date. Format: yyyy-MM-dd
  --date-to: string # Take only refunds issued at or before the date. Format: yyyy-MM-dd
  --limit: float # Limit (no more than 1000, defaults to 100).
  --offset: float # Offset. Defaults to 0
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/settlement/detailed_refunds"
    query: [{name: format, var: format}, {name: country_codes, var: country_codes}, {name: date_from, var: date_from}, {name: date_to, var: date_to}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    format: $format, country_codes: $country_codes, date_from: $date_from, date_to: $date_to, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch refunds
#
# GET /api/v1/settlement/refunds
# Returns: record<report: table<amount: float, country_code: string, country_name: string, country_subdivision: string, currency_code: string, skip_moss: bool, tax_amount: float, tax_rate: float, tax_region: string>>
# operationId: getRefunds
export def "get-refunds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # Output format. 'csv' value is accepted as well
  --moss-country-code: string # MOSS country code, used to determine currency. If ommited, merchant default setting is used.
  --tax-region: string # Tax region key, defaults to EU for backwards compatibility.
  --date-from: string # Take only refunds issued at or after the date. Format: yyyy-MM-dd (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/settlement/refunds"
    query: [{name: format, var: format}, {name: moss_country_code, var: moss_country_code}, {name: tax_region, var: tax_region}, {name: date_from, var: date_from, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    format: $format, moss_country_code: $moss_country_code, tax_region: $tax_region, date_from: $date_from
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch summary
#
# GET /api/v1/settlement/summary/{quarter}
# Returns: record<summary: record<currency_code: string, end_date: string, fx_rate_date: string, indicative: bool, quarter: string, start_date: string, tax_amount: float, tax_entity_name: string>>
# operationId: getSettlementSummary
export def "get-settlement-summary" [
  quarter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --moss-country-code: string # MOSS country code, used to determine currency. If ommited, merchant default setting is used.
  --tax-region: string # Tax region key
  --start-month: string # Period start month in yyyy-MM format. Either quarter or start-month and end-month have to be provided.
  --end-month: string # Period end month in yyyy-MM format. Either quarter or start-month and end-month have to be provided.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/settlement/summary/{quarter}"
    path_params: [{name: quarter, var: quarter}]
    query: [{name: moss_country_code, var: moss_country_code}, {name: tax_region, var: tax_region}, {name: start_month, var: start_month}, {name: end_month, var: end_month}]
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    quarter: $quarter, moss_country_code: $moss_country_code, tax_region: $tax_region, start_month: $start_month, end_month: $end_month
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch settlement
#
# GET /api/v1/settlement/{quarter}
# Returns: record<end_date: string, fx_rate_date: string, indicative: bool, report: table<amount: float, country_code: string, country_name: string, country_subdivision: string, currency_code: string, skip_moss: bool, tax_amount: float, tax_rate: float, tax_region: string>, start_date: string>
# operationId: getSettlement
export def "get-settlement" [
  quarter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --moss-tax-id: string # MOSS-assigned tax ID - if not provided, merchant's national tax number will be used. Deprecated, please use tax-id.
  --currency-code: string # ISO 3-letter currency code, e.g. EUR or USD. If provided, all amounts will be coerced for this currency. Defaults to region's currency code.
  --end-month: string # Period end month in yyyy-MM format. Either quarter or start-month and end-month have to be provided.
  --tax-id: string # MOSS-assigned tax ID - if not provided, merchant's national tax number will be used. Deprecated, please use tax-id.
  --refund-date-kind-override: string # Set to 'order_date' to show only refunds for the transactions in the selected reporting period. Set to 'refund_timestamp' to show refunds that were created in the selected reporting period. Do not set to use the default region's setting.
  --start-month: string # Period start month in yyyy-MM format. Either quarter or start-month and end-month have to be provided.
  --moss-country-code: string # MOSS country code, used to determine currency/region. If ommited, merchant default setting is used. Deprecated: please use tax-country-code.
  --format: string # Output format. 'csv' value is accepted as well
  --tax-country-code: string # Tax entity country code, used to determine currency/region.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/settlement/{quarter}"
    path_params: [{name: quarter, var: quarter}]
    query: [{name: moss_tax_id, var: moss_tax_id}, {name: currency_code, var: currency_code}, {name: end_month, var: end_month}, {name: tax_id, var: tax_id}, {name: refund_date_kind_override, var: refund_date_kind_override}, {name: start_month, var: start_month}, {name: moss_country_code, var: moss_country_code}, {name: format, var: format}, {name: tax_country_code, var: tax_country_code}]
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    quarter: $quarter, moss_tax_id: $moss_tax_id, currency_code: $currency_code, end_month: $end_month, tax_id: $tax_id, refund_date_kind_override: $refund_date_kind_override, start_month: $start_month, moss_country_code: $moss_country_code, format: $format, tax_country_code: $tax_country_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Settlement by country
#
# GET /api/v1/stats/settlement/by_country
# Returns: record<by_country: table<currency_code: string, tax_country_code: string, tax_country_name: string, value: float>>
# operationId: getSettlementStatsByCountry
export def "get-settlement-stats-by-country" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # Date from in yyyy-MM format. (required)
  --date-to: string # Date to in yyyy-MM format. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/stats/settlement/by_country"
    query: [{name: date_from, var: date_from, required: true}, {name: date_to, var: date_to, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    date_from: $date_from, date_to: $date_to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Settlement by tax type
#
# GET /api/v1/stats/settlement/by_taxation_type
# Returns: record<by_taxation_type: record<deducted_count: float, eu_b2b: int, eu_taxed: int, taxed_count: float, transactions_count: float>>
# operationId: getSettlementStatsByTaxationType
export def "get-settlement-stats-by-taxation-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # Date from in yyyy-MM format. (required)
  --date-to: string # Date to in yyyy-MM format. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/stats/settlement/by_taxation_type"
    query: [{name: date_from, var: date_from, required: true}, {name: date_to, var: date_to, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    date_from: $date_from, date_to: $date_to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Settlement stats over time
#
# GET /api/v1/stats/settlement/daily
# Returns: record<settlement_daily: table<b2b: int, b2c: int, count: int, day: string, day_raw: string, eu_b2b: int, eu_taxed: int, eu_total: int, untaxed: int>>
# operationId: getDailySettlementStats
export def "get-daily-settlement-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --interval: string # Interval type - day, week, month. (required)
  --date-from: string # Date from in yyyy-MM format. (required)
  --date-to: string # Date to in yyyy-MM format. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/stats/settlement/daily"
    query: [{name: interval, var: interval, required: true}, {name: date_from, var: date_from, required: true}, {name: date_to, var: date_to, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    interval: $interval, date_from: $date_from, date_to: $date_to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transaction stats
#
# GET /api/v1/stats/transactions
# Returns: record<by_status: record<C: list<record>, N: list<record>>>
# operationId: getTransactionsStats
export def "get-transactions-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # Date from in yyyy-MM format. (required)
  --date-to: string # Date to in yyyy-MM format. (required)
  --interval: string # Interval. Accepted values are 'day', 'week' and 'month'.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/stats/transactions"
    query: [{name: date_from, var: date_from, required: true}, {name: date_to, var: date_to, required: true}, {name: interval, var: interval}]
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    date_from: $date_from, date_to: $date_to, interval: $interval
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Settlement by country
#
# GET /api/v1/stats/transactions/by_country
# Returns: record<by_country: table<currency_code: string, tax_country_code: string, tax_country_name: string, value: float>>
# operationId: getTransactionsStatsByCountry
export def "get-transactions-stats-by-country" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --global-currency-code: string # Global currency code to use for conversion - in addition to country's currency if rate is available. Conversion is indicative and based on most-recent rate from ECB.
  --date-from: string # Date from in yyyy-MM format. (required)
  --date-to: string # Date to in yyyy-MM format. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/stats/transactions/by_country"
    query: [{name: global_currency_code, var: global_currency_code}, {name: date_from, var: date_from, required: true}, {name: date_to, var: date_to, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    global_currency_code: $global_currency_code, date_from: $date_from, date_to: $date_to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Simple tax
#
# GET /api/v1/tax/calculate
# Returns: record<storage_required_fields: table<field_name: string>, tax_required_fields: table<field_name: string>, transaction: record<additional_currencies: record<invoice: record>, amount: float, billing_country_code: string, buyer_credit_card_prefix: string, buyer_email: string, buyer_ip: string, buyer_name: string, buyer_tax_number: string, buyer_tax_number_valid: bool, comments: string, confirm_timestamp: string, countries: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_tax_number: record, by_token: record, detected: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, create_timestamp: string, currency_code: string, custom_data: string, custom_fields: list<record>, custom_id: string, customer_id: string, deducted_tax_amount: float, description: string, evidence: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_payment_method: record, by_tax_number: record, by_token: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, external_key: string, force_country_code: string, fully_informative: bool, invoice_address: record<address_detail: string, building_number: string, city: string, country: string, freeform_address: string, postal_code: string, region: string, street_name: string>, invoice_date: string, invoice_image_url: string, invoice_number: string, invoice_place: string, key: string, kind: string, manual: bool, note: string, order_date: string, original_transaction_key: string, refunded_tax_amount: float, refunded_total_amount: float, source: string, status: string, sub_account_id: string, supply_date: string, tax_amount: float, tax_country_code: string, tax_data: record<us_tax_exemption_certificate: record>, tax_deducted: bool, tax_entity_name: string, tax_number_service: string, tax_supported: bool, tax_timezone: string, test: bool, total_amount: float, transaction_lines: list<record>, verification_token: string>>
# operationId: calculateSimpleTax
export def "calculate-simple-tax" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-type: string # Product type, according to dictionary /dictionaries/product_types.
  --invoice-address-city: string # Invoice address/postal_code
  --buyer-credit-card-prefix: string # First 6 digits of buyer's credit card prefix.
  --currency-code: string # Currency code for transaction - e.g. EUR. (required)
  --invoice-address-region: string # Invoice address/region
  --unit-price: float # Unit price.
  --quantity: float # Quantity Defaults to 1.
  --buyer-tax-number: string # Buyer's tax number - EU VAT number for example. If using EU VAT number, it is possible to provide country code in it (e.g. IE1234567X) or simply use billing_country_code field for that. In the first case, if billing_country_code value was provided, it will be overwritten with country code value extracted from VAT number - but only if the VAT has been verified properly.
  --force-country-code: string # Two-letter ISO country code, e.g. FR. Use it to force country code for tax calculation.
  --order-date: string # Order date in yyyy-MM-dd format, in merchant's timezone. If provided by the API caller, no timezone conversion is performed. Default value is current date and time. When using public token, the default value is used.
  --amount: float # Amount. Required if total amount or both unit price and quantity are not provided.
  --billing-country-code: string # Billing two letter ISO country code.
  --invoice-address-postal-code: string # Invoice address/postal_code
  --total-amount: float # Total amount. Required if amount or both unit price and quantity are not provided.
  --tax-deducted: oneof<nothing, bool> # If the transaction is in a country supported by Taxamo, but the tax is not calculated due to merchant settings or EU B2B transaction for example.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/tax/calculate"
    query: [{name: product_type, var: product_type}, {name: invoice_address_city, var: invoice_address_city}, {name: buyer_credit_card_prefix, var: buyer_credit_card_prefix}, {name: currency_code, var: currency_code, required: true}, {name: invoice_address_region, var: invoice_address_region}, {name: unit_price, var: unit_price}, {name: quantity, var: quantity}, {name: buyer_tax_number, var: buyer_tax_number}, {name: force_country_code, var: force_country_code}, {name: order_date, var: order_date}, {name: amount, var: amount}, {name: billing_country_code, var: billing_country_code}, {name: invoice_address_postal_code, var: invoice_address_postal_code}, {name: total_amount, var: total_amount}, {name: tax_deducted, var: tax_deducted}]
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    product_type: $product_type, invoice_address_city: $invoice_address_city, buyer_credit_card_prefix: $buyer_credit_card_prefix, currency_code: $currency_code, invoice_address_region: $invoice_address_region, unit_price: $unit_price, quantity: $quantity, buyer_tax_number: $buyer_tax_number, force_country_code: $force_country_code, order_date: $order_date, amount: $amount, billing_country_code: $billing_country_code, invoice_address_postal_code: $invoice_address_postal_code, total_amount: $total_amount, tax_deducted: $tax_deducted
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Calculate tax
#
# POST /api/v1/tax/calculate
# Returns: record<storage_required_fields: table<field_name: string>, tax_required_fields: table<field_name: string>, transaction: record<additional_currencies: record<invoice: record>, amount: float, billing_country_code: string, buyer_credit_card_prefix: string, buyer_email: string, buyer_ip: string, buyer_name: string, buyer_tax_number: string, buyer_tax_number_valid: bool, comments: string, confirm_timestamp: string, countries: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_tax_number: record, by_token: record, detected: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, create_timestamp: string, currency_code: string, custom_data: string, custom_fields: list<record>, custom_id: string, customer_id: string, deducted_tax_amount: float, description: string, evidence: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_payment_method: record, by_tax_number: record, by_token: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, external_key: string, force_country_code: string, fully_informative: bool, invoice_address: record<address_detail: string, building_number: string, city: string, country: string, freeform_address: string, postal_code: string, region: string, street_name: string>, invoice_date: string, invoice_image_url: string, invoice_number: string, invoice_place: string, key: string, kind: string, manual: bool, note: string, order_date: string, original_transaction_key: string, refunded_tax_amount: float, refunded_total_amount: float, source: string, status: string, sub_account_id: string, supply_date: string, tax_amount: float, tax_country_code: string, tax_data: record<us_tax_exemption_certificate: record>, tax_deducted: bool, tax_entity_name: string, tax_number_service: string, tax_supported: bool, tax_timezone: string, test: bool, total_amount: float, transaction_lines: list<record>, verification_token: string>>
# operationId: calculateTax
export def "calculate-tax" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  transaction: record # shape: {additional_currencies?: record, billing_country_code?: string, buyer_credit_card_prefix?: string, buyer_email?: string, buyer_ip?: string, buyer_name?: string, buyer_tax_number?: string, comments?: string, currency_code: string, custom_data?: string, custom_fields?: list, custom_id?: string, customer_id?: string, description?: string, evidence?: record, force_country_code?: string, invoice_address?: record, invoice_date?: string, invoice_number?: string, invoice_place?: string, note?: string, ... (10 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/tax/calculate"
    body: {content_type: "application/json", kind: json, fields: [{name: transaction, var: transaction}]}
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    transaction: $transaction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Calculate location
#
# GET /api/v1/tax/location/calculate
# Returns: record<billing_country_code: string, buyer_credit_card_prefix: string, buyer_ip: string, countries: record<by_2003_rules: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, by_billing: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, by_cc: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, by_ip: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, by_tax_number: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, by_token: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, detected: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, forced: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, guessed_from_ip: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, other_commercially_relevant_info: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, self_declaration: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>>, evidence: record<by_2003_rules: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>, by_billing: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>, by_cc: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>, by_ip: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>, by_payment_method: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>, by_tax_number: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>, by_token: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>, forced: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>, guessed_from_ip: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>, other_commercially_relevant_info: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>, self_declaration: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>>, tax_country_code: string, tax_deducted: bool, tax_supported: bool>
# operationId: calculateTaxLocation
export def "calculate-tax-location" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing-country-code: string # Billing two letter ISO country code.
  --buyer-credit-card-prefix: string # First 6 digits of buyer's credit card prefix.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/tax/location/calculate"
    query: [{name: billing_country_code, var: billing_country_code}, {name: buyer_credit_card_prefix, var: buyer_credit_card_prefix}]
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    billing_country_code: $billing_country_code, buyer_credit_card_prefix: $buyer_credit_card_prefix
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validate VAT number
#
# GET /api/v1/tax/vat_numbers/{tax_number}/validate
# Returns: record<billing_country_code: string, buyer_tax_number: string, buyer_tax_number_valid: bool, tax_deducted: bool>
# operationId: validateTaxNumber
export def "validate-tax-number" [
  tax_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country-code: string # Two-letter ISO country code.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/tax/vat_numbers/{tax_number}/validate"
    path_params: [{name: tax_number, var: tax_number}]
    query: [{name: country_code, var: country_code}]
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    tax_number: $tax_number, country_code: $country_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Browse transactions
#
# GET /api/v1/transactions
# Returns: record<transactions: table<additional_currencies: record, amount: float, billing_country_code: string, buyer_credit_card_prefix: string, buyer_email: string, buyer_ip: string, buyer_name: string, buyer_tax_number: string, buyer_tax_number_valid: bool, comments: string, confirm_timestamp: string, countries: record, create_timestamp: string, currency_code: string, custom_data: string, custom_fields: list, custom_id: string, customer_id: string, deducted_tax_amount: float, description: string, evidence: record, external_key: string, force_country_code: string, fully_informative: bool, invoice_address: record, invoice_date: string, invoice_image_url: string, invoice_number: string, invoice_place: string, key: string, kind: string, manual: bool, note: string, order_date: string, original_transaction_key: string, refunded_tax_amount: float, refunded_total_amount: float, source: string, status: string, sub_account_id: string, supply_date: string, tax_amount: float, tax_country_code: string, tax_data: record, tax_deducted: bool, tax_entity_name: string, tax_number_service: string, tax_supported: bool, tax_timezone: string, test: bool, total_amount: float, transaction_lines: list, verification_token: string>>
# operationId: listTransactions
export def "list-transactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-text: string # Filtering expression
  --offset: int # Offset
  --has-note: oneof<nothing, bool> # Return only transactions with a note field set.
  --key-or-custom-id: string # Taxamo provided transaction key or custom id
  --currency-code: string # Three letter ISO currency code.
  --order-date-to: string # Order date to in yyyy-MM-dd format.
  --sort-reverse: oneof<nothing, bool> # If true, results are sorted in descending order.
  --limit: int # Limit (no more than 1000, defaults to 100).
  --invoice-number: string # Transaction invoice number.
  --tax-country-codes: string # Comma separated list of two letter ISO tax country codes.
  --statuses: string # Comma separated list of of transaction statuses. 'N' - unconfirmed transaction, 'C' - confirmed transaction.
  --original-transaction-key: string # Taxamo provided original transaction key
  --order-date-from: string # Order date from in yyyy-MM-dd format.
  --total-amount-greater-than: string # Return only transactions with total amount greater than given number. Transactions with total amount equal to a given number (e.g. 0) are not returned.
  --format: string # Output format - supports 'csv' value for this operation.
  --total-amount-less-than: string # Return only transactions with total amount less than a given number. Transactions with total amount equal to a given number (e.g. 1) are not returned.
  --tax-country-code: string # Two letter ISO tax country code.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/transactions"
    query: [{name: filter_text, var: filter_text}, {name: offset, var: offset}, {name: has_note, var: has_note}, {name: key_or_custom_id, var: key_or_custom_id}, {name: currency_code, var: currency_code}, {name: order_date_to, var: order_date_to}, {name: sort_reverse, var: sort_reverse}, {name: limit, var: limit}, {name: invoice_number, var: invoice_number}, {name: tax_country_codes, var: tax_country_codes}, {name: statuses, var: statuses}, {name: original_transaction_key, var: original_transaction_key}, {name: order_date_from, var: order_date_from}, {name: total_amount_greater_than, var: total_amount_greater_than}, {name: format, var: format}, {name: total_amount_less_than, var: total_amount_less_than}, {name: tax_country_code, var: tax_country_code}]
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    filter_text: $filter_text, offset: $offset, has_note: $has_note, key_or_custom_id: $key_or_custom_id, currency_code: $currency_code, order_date_to: $order_date_to, sort_reverse: $sort_reverse, limit: $limit, invoice_number: $invoice_number, tax_country_codes: $tax_country_codes, statuses: $statuses, original_transaction_key: $original_transaction_key, order_date_from: $order_date_from, total_amount_greater_than: $total_amount_greater_than, format: $format, total_amount_less_than: $total_amount_less_than, tax_country_code: $tax_country_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Store transaction
#
# POST /api/v1/transactions
# Returns: record<storage_required_fields: table<field_name: string>, tax_required_fields: table<field_name: string>, transaction: record<additional_currencies: record<invoice: record>, amount: float, billing_country_code: string, buyer_credit_card_prefix: string, buyer_email: string, buyer_ip: string, buyer_name: string, buyer_tax_number: string, buyer_tax_number_valid: bool, comments: string, confirm_timestamp: string, countries: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_tax_number: record, by_token: record, detected: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, create_timestamp: string, currency_code: string, custom_data: string, custom_fields: list<record>, custom_id: string, customer_id: string, deducted_tax_amount: float, description: string, evidence: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_payment_method: record, by_tax_number: record, by_token: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, external_key: string, force_country_code: string, fully_informative: bool, invoice_address: record<address_detail: string, building_number: string, city: string, country: string, freeform_address: string, postal_code: string, region: string, street_name: string>, invoice_date: string, invoice_image_url: string, invoice_number: string, invoice_place: string, key: string, kind: string, manual: bool, note: string, order_date: string, original_transaction_key: string, refunded_tax_amount: float, refunded_total_amount: float, source: string, status: string, sub_account_id: string, supply_date: string, tax_amount: float, tax_country_code: string, tax_data: record<us_tax_exemption_certificate: record>, tax_deducted: bool, tax_entity_name: string, tax_number_service: string, tax_supported: bool, tax_timezone: string, test: bool, total_amount: float, transaction_lines: list<record>, verification_token: string>>
# operationId: createTransaction
export def "create-transaction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --manual-mode: oneof<nothing, bool> # Use manual mode, bypassing country detection. Only allowed with private token. This flag allows to use original_transaction_key field
  transaction: record # shape: {additional_currencies?: record, billing_country_code?: string, buyer_credit_card_prefix?: string, buyer_email?: string, buyer_ip?: string, buyer_name?: string, buyer_tax_number?: string, comments?: string, currency_code: string, custom_data?: string, custom_fields?: list, custom_id?: string, customer_id?: string, description?: string, evidence?: record, force_country_code?: string, invoice_address?: record, invoice_date?: string, invoice_number?: string, invoice_place?: string, note?: string, ... (10 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/transactions"
    body: {content_type: "application/json", kind: json, fields: [{name: manual_mode, var: manual_mode}, {name: transaction, var: transaction}]}
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    manual_mode: $manual_mode, transaction: $transaction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete transaction
#
# DELETE /api/v1/transactions/{key}
# Returns: record<success: bool>
# operationId: cancelTransaction
export def "cancel-transaction" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/api/v1/transactions/{key}"
    path_params: [{name: key, var: key}]
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve transaction data.
#
# GET /api/v1/transactions/{key}
# Returns: record<storage_required_fields: table<field_name: string>, tax_required_fields: table<field_name: string>, transaction: record<additional_currencies: record<invoice: record>, amount: float, billing_country_code: string, buyer_credit_card_prefix: string, buyer_email: string, buyer_ip: string, buyer_name: string, buyer_tax_number: string, buyer_tax_number_valid: bool, comments: string, confirm_timestamp: string, countries: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_tax_number: record, by_token: record, detected: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, create_timestamp: string, currency_code: string, custom_data: string, custom_fields: list<record>, custom_id: string, customer_id: string, deducted_tax_amount: float, description: string, evidence: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_payment_method: record, by_tax_number: record, by_token: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, external_key: string, force_country_code: string, fully_informative: bool, invoice_address: record<address_detail: string, building_number: string, city: string, country: string, freeform_address: string, postal_code: string, region: string, street_name: string>, invoice_date: string, invoice_image_url: string, invoice_number: string, invoice_place: string, key: string, kind: string, manual: bool, note: string, order_date: string, original_transaction_key: string, refunded_tax_amount: float, refunded_total_amount: float, source: string, status: string, sub_account_id: string, supply_date: string, tax_amount: float, tax_country_code: string, tax_data: record<us_tax_exemption_certificate: record>, tax_deducted: bool, tax_entity_name: string, tax_number_service: string, tax_supported: bool, tax_timezone: string, test: bool, total_amount: float, transaction_lines: list<record>, verification_token: string>>
# operationId: getTransaction
export def "get-transaction" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/transactions/{key}"
    path_params: [{name: key, var: key}]
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update transaction
#
# PUT /api/v1/transactions/{key}
# Returns: record<storage_required_fields: table<field_name: string>, tax_required_fields: table<field_name: string>, transaction: record<additional_currencies: record<invoice: record>, amount: float, billing_country_code: string, buyer_credit_card_prefix: string, buyer_email: string, buyer_ip: string, buyer_name: string, buyer_tax_number: string, buyer_tax_number_valid: bool, comments: string, confirm_timestamp: string, countries: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_tax_number: record, by_token: record, detected: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, create_timestamp: string, currency_code: string, custom_data: string, custom_fields: list<record>, custom_id: string, customer_id: string, deducted_tax_amount: float, description: string, evidence: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_payment_method: record, by_tax_number: record, by_token: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, external_key: string, force_country_code: string, fully_informative: bool, invoice_address: record<address_detail: string, building_number: string, city: string, country: string, freeform_address: string, postal_code: string, region: string, street_name: string>, invoice_date: string, invoice_image_url: string, invoice_number: string, invoice_place: string, key: string, kind: string, manual: bool, note: string, order_date: string, original_transaction_key: string, refunded_tax_amount: float, refunded_total_amount: float, source: string, status: string, sub_account_id: string, supply_date: string, tax_amount: float, tax_country_code: string, tax_data: record<us_tax_exemption_certificate: record>, tax_deducted: bool, tax_entity_name: string, tax_number_service: string, tax_supported: bool, tax_timezone: string, test: bool, total_amount: float, transaction_lines: list<record>, verification_token: string>>
# operationId: updateTransaction
export def "update-transaction" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --transaction: record # shape: {additional_currencies?: record, amount?: float, billing_country_code?: string, buyer_credit_card_prefix?: string, buyer_email?: string, buyer_ip?: string, buyer_name?: string, buyer_tax_number?: string, buyer_tax_number_valid?: bool, comments?: string, confirm_timestamp?: string, countries?: record, create_timestamp?: string, currency_code: string, custom_data?: string, custom_fields?: list, custom_id?: string, customer_id?: string, deducted_tax_amount?: float, description?: string, ... (33 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/transactions/{key}"
    path_params: [{name: key, var: key}]
    body: {content_type: "application/json", kind: json, fields: [{name: transaction, var: transaction}]}
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    key: $key, transaction: $transaction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Confirm transaction
#
# POST /api/v1/transactions/{key}/confirm
# Returns: record<storage_required_fields: table<field_name: string>, tax_required_fields: table<field_name: string>, transaction: record<additional_currencies: record<invoice: record>, amount: float, billing_country_code: string, buyer_credit_card_prefix: string, buyer_email: string, buyer_ip: string, buyer_name: string, buyer_tax_number: string, buyer_tax_number_valid: bool, comments: string, confirm_timestamp: string, countries: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_tax_number: record, by_token: record, detected: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, create_timestamp: string, currency_code: string, custom_data: string, custom_fields: list<record>, custom_id: string, customer_id: string, deducted_tax_amount: float, description: string, evidence: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_payment_method: record, by_tax_number: record, by_token: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, external_key: string, force_country_code: string, fully_informative: bool, invoice_address: record<address_detail: string, building_number: string, city: string, country: string, freeform_address: string, postal_code: string, region: string, street_name: string>, invoice_date: string, invoice_image_url: string, invoice_number: string, invoice_place: string, key: string, kind: string, manual: bool, note: string, order_date: string, original_transaction_key: string, refunded_tax_amount: float, refunded_total_amount: float, source: string, status: string, sub_account_id: string, supply_date: string, tax_amount: float, tax_country_code: string, tax_data: record<us_tax_exemption_certificate: record>, tax_deducted: bool, tax_entity_name: string, tax_number_service: string, tax_supported: bool, tax_timezone: string, test: bool, total_amount: float, transaction_lines: list<record>, verification_token: string>>
# operationId: confirmTransaction
export def "confirm-transaction" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --transaction: record # shape: {additional_currencies?: record, billing_country_code?: string, buyer_credit_card_prefix?: string, buyer_email?: string, buyer_ip?: string, buyer_name?: string, buyer_tax_number?: string, comments?: string, currency_code?: string, custom_data?: string, custom_fields?: list, custom_id?: string, customer_id?: string, description?: string, evidence?: record, force_country_code?: string, invoice_address?: record, invoice_date?: string, invoice_number?: string, invoice_place?: string, note?: string, ... (10 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/transactions/{key}/confirm"
    path_params: [{name: key, var: key}]
    body: {content_type: "application/json", kind: json, fields: [{name: transaction, var: transaction}]}
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    key: $key, transaction: $transaction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Email credit note
#
# POST /api/v1/transactions/{key}/invoice/refunds/{refund_note_number}/send_email
# Returns: record<success: bool>
# operationId: emailRefund
export def "email-refund" [
  key: string
  refund_note_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --buyer-email: string # Email to send the credit note/refund note. If not provided, transaction.buyer_email will be used.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/transactions/{key}/invoice/refunds/{refund_note_number}/send_email"
    path_params: [{name: key, var: key}, {name: refund_note_number, var: refund_note_number}]
    body: {content_type: "application/json", kind: json, fields: [{name: buyer_email, var: buyer_email}]}
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    key: $key, refund_note_number: $refund_note_number, buyer_email: $buyer_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Email invoice
#
# POST /api/v1/transactions/{key}/invoice/send_email
# Returns: record<success: bool>
# operationId: emailInvoice
export def "email-invoice" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --buyer-email: string # Email to send the invoice. If not provided, transaction.buyer_email will be used.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/transactions/{key}/invoice/send_email"
    path_params: [{name: key, var: key}]
    body: {content_type: "application/json", kind: json, fields: [{name: buyer_email, var: buyer_email}]}
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    key: $key, buyer_email: $buyer_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List payments
#
# GET /api/v1/transactions/{key}/payments
# Returns: record<payments: table<amount: float, payment_information: string, payment_timestamp: string>>
# operationId: listPayments
export def "list-payments" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Max record count (no more than 100, defaults to 10).
  --offset: string # How many records need to be skipped, defaults to 0.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/transactions/{key}/payments"
    path_params: [{name: key, var: key}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    key: $key, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Register a payment
#
# POST /api/v1/transactions/{key}/payments
# Returns: record<success: bool>
# operationId: createPayment
export def "create-payment" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: float # Amount that has been paid. Use negative value to register refunds.
  --payment-information: string # Additional payment information.
  --payment-timestamp: string # When the payment was received in yyyy-MM-dd'T'HH:mm:ss(.SSS)'Z' format (24 hour, UTC timezone). Defaults to current date and time.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/transactions/{key}/payments"
    path_params: [{name: key, var: key}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: payment_information, var: payment_information}, {name: payment_timestamp, var: payment_timestamp}]}
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    key: $key, amount: $amount, payment_information: $payment_information, payment_timestamp: $payment_timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Capture payment
#
# POST /api/v1/transactions/{key}/payments/capture
# Returns: record<success: bool>
# operationId: capturePayment
export def "capture-payment" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/v1/transactions/{key}/payments/capture"
    path_params: [{name: key, var: key}]
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get transaction refunds
#
# GET /api/v1/transactions/{key}/refunds
# Returns: record<refunds: table<amount: float, informative: bool, line_key: string, refund_note_number: string, refund_note_url: string, refund_reason: string, refund_timestamp: string, tax_amount: float, tax_rate: float, total_amount: float>>
# operationId: listRefunds
export def "list-refunds" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/transactions/{key}/refunds"
    path_params: [{name: key, var: key}]
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a refund
#
# POST /api/v1/transactions/{key}/refunds
# Returns: record<refunded_tax_amount: float, refunded_total_amount: float, tax_amount: float, total_amount: float>
# operationId: createRefund
export def "create-refund" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: float # Amount (without tax) to be refunded. Either amount or total amount is required. In case of line key and custom id missing, only total_amount can be used.
  --custom-id: string # Line custom identifier. If neither line key or custom id is provided, the refund amount will be assigned to lines in order.
  --line-key: string # Line identifier. If neither line key or custom id is provided, the refund amount will be assigned to lines in order.
  --refund-reason: string # Refund reason, displayed on the credit note.
  --total-amount: float # Total amount, including tax, to be refunded. Either amount or total amount is required. In case of line key and custom id missing, only total_amount can be used.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/transactions/{key}/refunds"
    path_params: [{name: key, var: key}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: custom_id, var: custom_id}, {name: line_key, var: line_key}, {name: refund_reason, var: refund_reason}, {name: total_amount, var: total_amount}]}
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    key: $key, amount: $amount, custom_id: $custom_id, line_key: $line_key, refund_reason: $refund_reason, total_amount: $total_amount
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Un-confirm the transaction
#
# POST /api/v1/transactions/{key}/unconfirm
# Returns: record<storage_required_fields: table<field_name: string>, tax_required_fields: table<field_name: string>, transaction: record<additional_currencies: record<invoice: record>, amount: float, billing_country_code: string, buyer_credit_card_prefix: string, buyer_email: string, buyer_ip: string, buyer_name: string, buyer_tax_number: string, buyer_tax_number_valid: bool, comments: string, confirm_timestamp: string, countries: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_tax_number: record, by_token: record, detected: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, create_timestamp: string, currency_code: string, custom_data: string, custom_fields: list<record>, custom_id: string, customer_id: string, deducted_tax_amount: float, description: string, evidence: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_payment_method: record, by_tax_number: record, by_token: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, external_key: string, force_country_code: string, fully_informative: bool, invoice_address: record<address_detail: string, building_number: string, city: string, country: string, freeform_address: string, postal_code: string, region: string, street_name: string>, invoice_date: string, invoice_image_url: string, invoice_number: string, invoice_place: string, key: string, kind: string, manual: bool, note: string, order_date: string, original_transaction_key: string, refunded_tax_amount: float, refunded_total_amount: float, source: string, status: string, sub_account_id: string, supply_date: string, tax_amount: float, tax_country_code: string, tax_data: record<us_tax_exemption_certificate: record>, tax_deducted: bool, tax_entity_name: string, tax_number_service: string, tax_supported: bool, tax_timezone: string, test: bool, total_amount: float, transaction_lines: list<record>, verification_token: string>>
# operationId: unconfirmTransaction
export def "unconfirm-transaction" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --transaction: record # shape: {additional_currencies?: record, billing_country_code?: string, buyer_credit_card_prefix?: string, buyer_email?: string, buyer_ip?: string, buyer_name?: string, buyer_tax_number?: string, comments?: string, currency_code?: string, custom_data?: string, custom_fields?: list, custom_id?: string, customer_id?: string, description?: string, evidence?: record, force_country_code?: string, invoice_address?: record, invoice_date?: string, invoice_number?: string, invoice_place?: string, note?: string, ... (10 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/transactions/{key}/unconfirm"
    path_params: [{name: key, var: key}]
    body: {content_type: "application/json", kind: json, fields: [{name: transaction, var: transaction}]}
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    key: $key, transaction: $transaction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create SMS token
#
# POST /api/v1/verification/sms
# Returns: record<success: bool>
# operationId: createSMSToken
export def "create-sms-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  country_code: string # Two letter ISO country code.
  recipient: string # Recipient phone number.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/verification/sms"
    body: {content_type: "application/json", kind: json, fields: [{name: country_code, var: country_code}, {name: recipient, var: recipient}]}
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    country_code: $country_code, recipient: $recipient
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify SMS token
#
# GET /api/v1/verification/sms/{token}
# Returns: record<country_code: string>
# operationId: verifySMSToken
export def "verify-sms-token" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/verification/sms/{token}"
    path_params: [{name: token, var: token_arg}]
    accept: ["application/json"]
    ok: [200]
    auth: token
  } {
    token_arg: $token_arg
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
