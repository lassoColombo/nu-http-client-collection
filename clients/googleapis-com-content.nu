# Auto-generated client for Content API for Shopping v2.1
# Source: https://api.apis.guru/v2/specs/googleapis.com/content/v2.1/openapi.json
# Auth: --token flag or $env.CONTENT_API_FOR_SHOPPING_TOKEN

const CLIENT = {
  base_url: "https://shoppingcontent.googleapis.com/content/v2.1"
  token_env_var: "CONTENT_API_FOR_SHOPPING_TOKEN"
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

def base-url-completer [] { ["https://shoppingcontent.googleapis.com/content/v2.1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def purpose-completer [] { ["ACCOUNT_CREDENTIALS_PURPOSE_UNSPECIFIED" "SHOPIFY_INTEGRATION" "SHOPIFY_ORDER_MANAGEMENT"] }
def carrier-code-completer [] { ["CARRIER_CODE_UNSPECIFIED" "FEDEX" "UPS"] }
def view-completer [] { ["CSS" "MERCHANT"] }
def phone-verification-method-completer [] { ["PHONE_CALL" "PHONE_VERIFICATION_METHOD_UNSPECIFIED" "SMS"] }
def online-sales-channel-completer [] { ["GOOGLE_AND_OTHER_WEBSITES" "GOOGLE_EXCLUSIVE" "ONLINE_SALES_CHANNEL_UNSPECIFIED"] }
def order-by-completer [] { ["RETURN_CREATION_TIME_ASC" "RETURN_CREATION_TIME_DESC"] }
def coupon-value-type-completer [] { ["BUY_M_GET_MONEY_OFF" "BUY_M_GET_N_MONEY_OFF" "BUY_M_GET_N_PERCENT_OFF" "BUY_M_GET_PERCENT_OFF" "COUPON_VALUE_TYPE_UNSPECIFIED" "FREE_GIFT" "FREE_GIFT_WITH_ITEM_ID" "FREE_GIFT_WITH_VALUE" "FREE_SHIPPING_OVERNIGHT" "FREE_SHIPPING_STANDARD" "FREE_SHIPPING_TWO_DAY" "MONEY_OFF" "PERCENT_OFF"] }
def offer-type-completer [] { ["GENERIC_CODE" "NO_CODE" "OFFER_TYPE_UNSPECIFIED"] }
def product-applicability-completer [] { ["ALL_PRODUCTS" "PRODUCT_APPLICABILITY_UNSPECIFIED" "SPECIFIC_PRODUCTS"] }
def store-applicability-completer [] { ["ALL_STORES" "SPECIFIC_STORES" "STORE_APPLICABILITY_UNSPECIFIED"] }
def interaction-type-completer [] { ["INTERACTION_CLICK" "INTERACTION_TYPE_UNSPECIFIED"] }
def type-completer [] { ["REPRICING_RULE_TYPE_UNSPECIFIED" "TYPE_COGS_BASED" "TYPE_COMPETITIVE_PRICE" "TYPE_SALES_VOLUME_BASED" "TYPE_STATS_BASED"] }
def template-name-completer [] { ["TEMPLATE1" "TEMPLATE1A" "TEMPLATE1B" "TEMPLATE2" "TEMPLATE3" "TEMPLATE4"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    content-accounts-authinfo: "record<accountIdentifiers: table<aggregatorId: string, merchantId: string>, kind: string>"
    content-accounts-custombatch: "record<entries: table<account: record, batchId: int, errors: record, kind: string>, kind: string>"
    content-accounts-credentials-create: "record<accessToken: string, expiresIn: string, purpose: string>"
    content-accounts-labels-list: "record<accountLabels: table<accountId: string, description: string, labelId: string, labelType: string, name: string>, nextPageToken: string>"
    content-accounts-labels-create: "record<accountId: string, description: string, labelId: string, labelType: string, name: string>"
    content-accounts-labels-patch: "record<accountId: string, description: string, labelId: string, labelType: string, name: string>"
    content-accounts-returncarrier-list: "record<accountReturnCarriers: table<carrierAccountId: string, carrierAccountName: string, carrierAccountNumber: string, carrierCode: string>>"
    content-accounts-returncarrier-create: "record<carrierAccountId: string, carrierAccountName: string, carrierAccountNumber: string, carrierCode: string>"
    content-accounts-returncarrier-patch: "record<carrierAccountId: string, carrierAccountName: string, carrierAccountNumber: string, carrierCode: string>"
    content-accountstatuses-custombatch: "record<entries: table<accountStatus: record, batchId: int, errors: record>, kind: string>"
    content-accounttax-custombatch: "record<entries: table<accountTax: record, batchId: int, errors: record, kind: string>, kind: string>"
    content-datafeeds-custombatch: "record<entries: table<batchId: int, datafeed: record, errors: record>, kind: string>"
    content-datafeedstatuses-custombatch: "record<entries: table<batchId: int, datafeedStatus: record, errors: record>, kind: string>"
    content-liasettings-custombatch: "record<entries: table<batchId: int, errors: record, gmbAccounts: record, kind: string, liaSettings: record, posDataProviders: list>, kind: string>"
    content-liasettings-listposdataproviders: "record<kind: string, posDataProviders: table<country: string, posDataProviders: list>>"
    content-localinventory-custombatch: "record<entries: table<batchId: int, errors: record, kind: string>, kind: string>"
    content-pos-custombatch: "record<entries: table<batchId: int, errors: record, inventory: record, kind: string, sale: record, store: record>, kind: string>"
    content-products-custombatch: "record<entries: table<batchId: int, errors: record, kind: string, product: record>, kind: string>"
    content-productstatuses-custombatch: "record<entries: table<batchId: int, errors: record, kind: string, productStatus: record>, kind: string>"
    content-regionalinventory-custombatch: "record<entries: table<batchId: int, errors: record, kind: string, regionalInventory: record>, kind: string>"
    content-returnaddress-custombatch: "record<entries: table<batchId: int, errors: record, kind: string, returnAddress: record>, kind: string>"
    content-returnpolicy-custombatch: "record<entries: table<batchId: int, errors: record, kind: string, returnPolicy: record>, kind: string>"
    content-shippingsettings-custombatch: "record<entries: table<batchId: int, errors: record, kind: string, shippingSettings: record>, kind: string>"
    content-csses-list: "record<csses: table<cssDomainId: string, cssGroupId: string, displayName: string, fullName: string, homepageUri: string, labelIds: list>, nextPageToken: string>"
    content-csses-get: "record<cssDomainId: string, cssGroupId: string, displayName: string, fullName: string, homepageUri: string, labelIds: list<string>>"
    content-csses-updatelabels: "record<cssDomainId: string, cssGroupId: string, displayName: string, fullName: string, homepageUri: string, labelIds: list<string>>"
    content-accounts-list: "record<kind: string, nextPageToken: string, resources: table<accountManagement: string, adsLinks: list, adultContent: bool, automaticImprovements: record, automaticLabelIds: list, businessInformation: record, conversionSettings: record, cssId: string, googleMyBusinessLink: record, id: string, kind: string, labelIds: list, name: string, sellerId: string, users: list, websiteUrl: string, youtubeChannelLinks: list>>"
    content-accounts-insert: "record<accountManagement: string, adsLinks: table<adsId: string, status: string>, adultContent: bool, automaticImprovements: record<imageImprovements: record<accountImageImprovementsSettings: record, effectiveAllowAutomaticImageImprovements: bool>, itemUpdates: record<accountItemUpdatesSettings: record, effectiveAllowAvailabilityUpdates: bool, effectiveAllowConditionUpdates: bool, effectiveAllowPriceUpdates: bool, effectiveAllowStrictAvailabilityUpdates: bool>, shippingImprovements: record<allowShippingImprovements: bool>>, automaticLabelIds: list<string>, businessInformation: record<address: record<country: string, locality: string, postalCode: string, region: string, streetAddress: string>, customerService: record<email: string, phoneNumber: string, url: string>, koreanBusinessRegistrationNumber: string, phoneNumber: string, phoneVerificationStatus: string>, conversionSettings: record<freeListingsAutoTaggingEnabled: bool>, cssId: string, googleMyBusinessLink: record<gmbAccountId: string, gmbEmail: string, status: string>, id: string, kind: string, labelIds: list<string>, name: string, sellerId: string, users: table<admin: bool, emailAddress: string, orderManager: bool, paymentsAnalyst: bool, paymentsManager: bool, reportingManager: bool>, websiteUrl: string, youtubeChannelLinks: table<channelId: string, status: string>>"
    content-accounts-get: "record<accountManagement: string, adsLinks: table<adsId: string, status: string>, adultContent: bool, automaticImprovements: record<imageImprovements: record<accountImageImprovementsSettings: record, effectiveAllowAutomaticImageImprovements: bool>, itemUpdates: record<accountItemUpdatesSettings: record, effectiveAllowAvailabilityUpdates: bool, effectiveAllowConditionUpdates: bool, effectiveAllowPriceUpdates: bool, effectiveAllowStrictAvailabilityUpdates: bool>, shippingImprovements: record<allowShippingImprovements: bool>>, automaticLabelIds: list<string>, businessInformation: record<address: record<country: string, locality: string, postalCode: string, region: string, streetAddress: string>, customerService: record<email: string, phoneNumber: string, url: string>, koreanBusinessRegistrationNumber: string, phoneNumber: string, phoneVerificationStatus: string>, conversionSettings: record<freeListingsAutoTaggingEnabled: bool>, cssId: string, googleMyBusinessLink: record<gmbAccountId: string, gmbEmail: string, status: string>, id: string, kind: string, labelIds: list<string>, name: string, sellerId: string, users: table<admin: bool, emailAddress: string, orderManager: bool, paymentsAnalyst: bool, paymentsManager: bool, reportingManager: bool>, websiteUrl: string, youtubeChannelLinks: table<channelId: string, status: string>>"
    content-accounts-update: "record<accountManagement: string, adsLinks: table<adsId: string, status: string>, adultContent: bool, automaticImprovements: record<imageImprovements: record<accountImageImprovementsSettings: record, effectiveAllowAutomaticImageImprovements: bool>, itemUpdates: record<accountItemUpdatesSettings: record, effectiveAllowAvailabilityUpdates: bool, effectiveAllowConditionUpdates: bool, effectiveAllowPriceUpdates: bool, effectiveAllowStrictAvailabilityUpdates: bool>, shippingImprovements: record<allowShippingImprovements: bool>>, automaticLabelIds: list<string>, businessInformation: record<address: record<country: string, locality: string, postalCode: string, region: string, streetAddress: string>, customerService: record<email: string, phoneNumber: string, url: string>, koreanBusinessRegistrationNumber: string, phoneNumber: string, phoneVerificationStatus: string>, conversionSettings: record<freeListingsAutoTaggingEnabled: bool>, cssId: string, googleMyBusinessLink: record<gmbAccountId: string, gmbEmail: string, status: string>, id: string, kind: string, labelIds: list<string>, name: string, sellerId: string, users: table<admin: bool, emailAddress: string, orderManager: bool, paymentsAnalyst: bool, paymentsManager: bool, reportingManager: bool>, websiteUrl: string, youtubeChannelLinks: table<channelId: string, status: string>>"
    content-accounts-claimwebsite: "record<kind: string>"
    content-accounts-link: "record<kind: string>"
    content-accounts-listlinks: "record<kind: string, links: table<linkedAccountId: string, services: list>, nextPageToken: string>"
    content-accounts-requestphoneverification: "record<verificationId: string>"
    content-accounts-updatelabels: "record<kind: string>"
    content-accounts-verifyphonenumber: "record<verifiedPhoneNumber: string>"
    content-accountstatuses-list: "record<kind: string, nextPageToken: string, resources: table<accountId: string, accountLevelIssues: list, accountManagement: string, kind: string, products: list, websiteClaimed: bool>>"
    content-accountstatuses-get: "record<accountId: string, accountLevelIssues: table<country: string, destination: string, detail: string, documentation: string, id: string, severity: string, title: string>, accountManagement: string, kind: string, products: table<channel: string, country: string, destination: string, itemLevelIssues: list, statistics: record>, websiteClaimed: bool>"
    content-accounttax-list: "record<kind: string, nextPageToken: string, resources: table<accountId: string, kind: string, rules: list>>"
    content-accounttax-get: "record<accountId: string, kind: string, rules: table<country: string, locationId: string, ratePercent: string, shippingTaxed: bool, useGlobalRate: bool>>"
    content-accounttax-update: "record<accountId: string, kind: string, rules: table<country: string, locationId: string, ratePercent: string, shippingTaxed: bool, useGlobalRate: bool>>"
    content-buyongoogleprograms-get: "record<businessModel: list<string>, customerServicePendingEmail: string, customerServicePendingPhoneNumber: string, customerServicePendingPhoneRegionCode: string, customerServiceVerifiedEmail: string, customerServiceVerifiedPhoneNumber: string, customerServiceVerifiedPhoneRegionCode: string, onlineSalesChannel: string, participationStage: string>"
    content-buyongoogleprograms-patch: "record<businessModel: list<string>, customerServicePendingEmail: string, customerServicePendingPhoneNumber: string, customerServicePendingPhoneRegionCode: string, customerServiceVerifiedEmail: string, customerServiceVerifiedPhoneNumber: string, customerServiceVerifiedPhoneRegionCode: string, onlineSalesChannel: string, participationStage: string>"
    content-collections-list: "record<nextPageToken: string, resources: table<customLabel0: string, customLabel1: string, customLabel2: string, customLabel3: string, customLabel4: string, featuredProduct: list, headline: list, id: string, imageLink: list, language: string, link: string, mobileLink: string, productCountry: string>>"
    content-collections-create: "record<customLabel0: string, customLabel1: string, customLabel2: string, customLabel3: string, customLabel4: string, featuredProduct: table<offerId: string, x: float, y: float>, headline: list<string>, id: string, imageLink: list<string>, language: string, link: string, mobileLink: string, productCountry: string>"
    content-collections-get: "record<customLabel0: string, customLabel1: string, customLabel2: string, customLabel3: string, customLabel4: string, featuredProduct: table<offerId: string, x: float, y: float>, headline: list<string>, id: string, imageLink: list<string>, language: string, link: string, mobileLink: string, productCountry: string>"
    content-collectionstatuses-list: "record<nextPageToken: string, resources: table<collectionLevelIssuses: list, creationDate: string, destinationStatuses: list, id: string, lastUpdateDate: string>>"
    content-collectionstatuses-get: "record<collectionLevelIssuses: table<applicableCountries: list, attributeName: string, code: string, description: string, destination: string, detail: string, documentation: string, resolution: string, servability: string>, creationDate: string, destinationStatuses: table<approvedCountries: list, destination: string, disapprovedCountries: list, pendingCountries: list, status: string>, id: string, lastUpdateDate: string>"
    content-conversionsources-list: "record<conversionSources: table<conversionSourceId: string, expireTime: string, googleAnalyticsLink: record, merchantCenterDestination: record, state: string>, nextPageToken: string>"
    content-conversionsources-create: "record<conversionSourceId: string, expireTime: string, googleAnalyticsLink: record<attributionSettings: record<attributionLookbackWindowInDays: int, attributionModel: string, conversionType: list>, propertyId: string, propertyName: string>, merchantCenterDestination: record<attributionSettings: record<attributionLookbackWindowInDays: int, attributionModel: string, conversionType: list>, currencyCode: string, destinationId: string, displayName: string>, state: string>"
    content-conversionsources-get: "record<conversionSourceId: string, expireTime: string, googleAnalyticsLink: record<attributionSettings: record<attributionLookbackWindowInDays: int, attributionModel: string, conversionType: list>, propertyId: string, propertyName: string>, merchantCenterDestination: record<attributionSettings: record<attributionLookbackWindowInDays: int, attributionModel: string, conversionType: list>, currencyCode: string, destinationId: string, displayName: string>, state: string>"
    content-conversionsources-patch: "record<conversionSourceId: string, expireTime: string, googleAnalyticsLink: record<attributionSettings: record<attributionLookbackWindowInDays: int, attributionModel: string, conversionType: list>, propertyId: string, propertyName: string>, merchantCenterDestination: record<attributionSettings: record<attributionLookbackWindowInDays: int, attributionModel: string, conversionType: list>, currencyCode: string, destinationId: string, displayName: string>, state: string>"
    content-datafeeds-list: "record<kind: string, nextPageToken: string, resources: table<attributeLanguage: string, contentType: string, fetchSchedule: record, fileName: string, format: record, id: string, kind: string, name: string, targets: list>>"
    content-datafeeds-insert: "record<attributeLanguage: string, contentType: string, fetchSchedule: record<dayOfMonth: int, fetchUrl: string, hour: int, minuteOfHour: int, password: string, paused: bool, timeZone: string, username: string, weekday: string>, fileName: string, format: record<columnDelimiter: string, fileEncoding: string, quotingMode: string>, id: string, kind: string, name: string, targets: table<country: string, excludedDestinations: list, feedLabel: string, includedDestinations: list, language: string, targetCountries: list>>"
    content-datafeeds-get: "record<attributeLanguage: string, contentType: string, fetchSchedule: record<dayOfMonth: int, fetchUrl: string, hour: int, minuteOfHour: int, password: string, paused: bool, timeZone: string, username: string, weekday: string>, fileName: string, format: record<columnDelimiter: string, fileEncoding: string, quotingMode: string>, id: string, kind: string, name: string, targets: table<country: string, excludedDestinations: list, feedLabel: string, includedDestinations: list, language: string, targetCountries: list>>"
    content-datafeeds-update: "record<attributeLanguage: string, contentType: string, fetchSchedule: record<dayOfMonth: int, fetchUrl: string, hour: int, minuteOfHour: int, password: string, paused: bool, timeZone: string, username: string, weekday: string>, fileName: string, format: record<columnDelimiter: string, fileEncoding: string, quotingMode: string>, id: string, kind: string, name: string, targets: table<country: string, excludedDestinations: list, feedLabel: string, includedDestinations: list, language: string, targetCountries: list>>"
    content-datafeeds-fetchnow: "record<kind: string>"
    content-datafeedstatuses-list: "record<kind: string, nextPageToken: string, resources: table<country: string, datafeedId: string, errors: list, feedLabel: string, itemsTotal: string, itemsValid: string, kind: string, language: string, lastUploadDate: string, processingStatus: string, warnings: list>>"
    content-datafeedstatuses-get: "record<country: string, datafeedId: string, errors: table<code: string, count: string, examples: list, message: string>, feedLabel: string, itemsTotal: string, itemsValid: string, kind: string, language: string, lastUploadDate: string, processingStatus: string, warnings: table<code: string, count: string, examples: list, message: string>>"
    content-freelistingsprogram-get: "record<globalState: string, regionStatuses: table<disapprovalDate: string, eligibilityStatus: string, onboardingIssues: list, regionCodes: list, reviewEligibilityStatus: string, reviewIneligibilityReason: string, reviewIneligibilityReasonDescription: string, reviewIneligibilityReasonDetails: record, reviewIssues: list>>"
    content-liasettings-list: "record<kind: string, nextPageToken: string, resources: table<accountId: string, countrySettings: list, kind: string>>"
    content-liasettings-get: "record<accountId: string, countrySettings: table<about: record, country: string, hostedLocalStorefrontActive: bool, inventory: record, onDisplayToOrder: record, posDataProvider: record, storePickupActive: bool>, kind: string>"
    content-liasettings-update: "record<accountId: string, countrySettings: table<about: record, country: string, hostedLocalStorefrontActive: bool, inventory: record, onDisplayToOrder: record, posDataProvider: record, storePickupActive: bool>, kind: string>"
    content-liasettings-getaccessiblegmbaccounts: "record<accountId: string, gmbAccounts: table<email: string, listingCount: string, name: string, type: string>, kind: string>"
    content-liasettings-requestgmbaccess: "record<kind: string>"
    content-liasettings-requestinventoryverification: "record<kind: string>"
    content-liasettings-setinventoryverificationcontact: "record<kind: string>"
    content-liasettings-setposdataprovider: "record<kind: string>"
    content-orderinvoices-createchargeinvoice: "record<executionStatus: string, kind: string>"
    content-orderinvoices-createrefundinvoice: "record<executionStatus: string, kind: string>"
    content-orderreports-listdisbursements: "record<disbursements: table<disbursementAmount: record, disbursementCreationDate: string, disbursementDate: string, disbursementId: string, merchantId: string>, kind: string, nextPageToken: string>"
    content-orderreports-listtransactions: "record<kind: string, nextPageToken: string, transactions: table<disbursementAmount: record, disbursementCreationDate: string, disbursementDate: string, disbursementId: string, merchantId: string, merchantOrderId: string, orderId: string, productAmount: record, transactionDate: string>>"
    content-orderreturns-list: "record<kind: string, nextPageToken: string, resources: table<creationDate: string, merchantOrderId: string, orderId: string, orderReturnId: string, returnItems: list, returnPricingInfo: record, returnShipments: list>>"
    content-orderreturns-createorderreturn: "record<executionStatus: string, kind: string, orderReturn: record<creationDate: string, merchantOrderId: string, orderId: string, orderReturnId: string, returnItems: list<record>, returnPricingInfo: record<chargeReturnShippingFee: bool, maxReturnShippingFee: record, refundableItemsTotalAmount: record, refundableShippingAmount: record, totalRefundedAmount: record>, returnShipments: list<record>>>"
    content-orderreturns-get: "record<creationDate: string, merchantOrderId: string, orderId: string, orderReturnId: string, returnItems: table<customerReturnReason: record, itemId: string, merchantRejectionReason: record, merchantReturnReason: record, product: record, refundableAmount: record, returnItemId: string, returnShipmentIds: list, shipmentGroupId: string, shipmentUnitId: string, state: string>, returnPricingInfo: record<chargeReturnShippingFee: bool, maxReturnShippingFee: record<priceAmount: record, taxAmount: record>, refundableItemsTotalAmount: record<priceAmount: record, taxAmount: record>, refundableShippingAmount: record<priceAmount: record, taxAmount: record>, totalRefundedAmount: record<priceAmount: record, taxAmount: record>>, returnShipments: table<creationDate: string, deliveryDate: string, returnMethodType: string, shipmentId: string, shipmentTrackingInfos: list, shippingDate: string, state: string>>"
    content-orderreturns-acknowledge: "record<executionStatus: string, kind: string>"
    content-orderreturns-labels-create: "record<carrier: string, labelUri: string, trackingId: string>"
    content-orderreturns-process: "record<executionStatus: string, kind: string>"
    content-orders-list: "record<kind: string, nextPageToken: string, resources: table<acknowledged: bool, annotations: list, billingAddress: record, customer: record, deliveryDetails: record, id: string, kind: string, lineItems: list, merchantId: string, merchantOrderId: string, netPriceAmount: record, netTaxAmount: record, paymentStatus: string, pickupDetails: record, placedDate: string, promotions: list, refunds: list, shipments: list, shippingCost: record, shippingCostTax: record, status: string, taxCollector: string>>"
    content-orders-get: "record<acknowledged: bool, annotations: table<key: string, value: string>, billingAddress: record<country: string, fullAddress: list<string>, isPostOfficeBox: bool, locality: string, postalCode: string, recipientName: string, region: string, streetAddress: list<string>>, customer: record<fullName: string, invoiceReceivingEmail: string, loyaltyInfo: record<loyaltyNumber: string, name: string>, marketingRightsInfo: record<explicitMarketingPreference: string, lastUpdatedTimestamp: string, marketingEmailAddress: string>>, deliveryDetails: record<address: record<country: string, fullAddress: list, isPostOfficeBox: bool, locality: string, postalCode: string, recipientName: string, region: string, streetAddress: list>, phoneNumber: string>, id: string, kind: string, lineItems: table<adjustments: list, annotations: list, cancellations: list, id: string, price: record, product: record, quantityCanceled: int, quantityDelivered: int, quantityOrdered: int, quantityPending: int, quantityReadyForPickup: int, quantityReturned: int, quantityShipped: int, quantityUndeliverable: int, returnInfo: record, returns: list, shippingDetails: record, tax: record>, merchantId: string, merchantOrderId: string, netPriceAmount: record<currency: string, value: string>, netTaxAmount: record<currency: string, value: string>, paymentStatus: string, pickupDetails: record<address: record<country: string, fullAddress: list, isPostOfficeBox: bool, locality: string, postalCode: string, recipientName: string, region: string, streetAddress: list>, collectors: list<record>, locationId: string, pickupType: string>, placedDate: string, promotions: table<applicableItems: list, appliedItems: list, endTime: string, funder: string, merchantPromotionId: string, priceValue: record, shortTitle: string, startTime: string, subtype: string, taxValue: record, title: string, type: string>, refunds: table<actor: string, amount: record, creationDate: string, reason: string, reasonText: string>, shipments: table<carrier: string, creationDate: string, deliveryDate: string, id: string, lineItems: list, scheduledDeliveryDetails: record, shipmentGroupId: string, status: string, trackingId: string>, shippingCost: record<currency: string, value: string>, shippingCostTax: record<currency: string, value: string>, status: string, taxCollector: string>"
    content-orders-acknowledge: "record<executionStatus: string, kind: string>"
    content-orders-cancel: "record<executionStatus: string, kind: string>"
    content-orders-cancellineitem: "record<executionStatus: string, kind: string>"
    content-orders-capture-order: "record<executionStatus: string>"
    content-orders-instorerefundlineitem: "record<executionStatus: string, kind: string>"
    content-orders-refunditem: "record<executionStatus: string, kind: string>"
    content-orders-refundorder: "record<executionStatus: string, kind: string>"
    content-orders-rejectreturnlineitem: "record<executionStatus: string, kind: string>"
    content-orders-returnrefundlineitem: "record<executionStatus: string, kind: string>"
    content-orders-setlineitemmetadata: "record<executionStatus: string, kind: string>"
    content-orders-shiplineitems: "record<executionStatus: string, kind: string>"
    content-orders-createtestreturn: "record<kind: string, returnId: string>"
    content-orders-updatelineitemshippingdetails: "record<executionStatus: string, kind: string>"
    content-orders-updatemerchantorderid: "record<executionStatus: string, kind: string>"
    content-orders-updateshipment: "record<executionStatus: string, kind: string>"
    content-orders-getbymerchantorderid: "record<kind: string, order: record<acknowledged: bool, annotations: list<record>, billingAddress: record<country: string, fullAddress: list, isPostOfficeBox: bool, locality: string, postalCode: string, recipientName: string, region: string, streetAddress: list>, customer: record<fullName: string, invoiceReceivingEmail: string, loyaltyInfo: record, marketingRightsInfo: record>, deliveryDetails: record<address: record, phoneNumber: string>, id: string, kind: string, lineItems: list<record>, merchantId: string, merchantOrderId: string, netPriceAmount: record<currency: string, value: string>, netTaxAmount: record<currency: string, value: string>, paymentStatus: string, pickupDetails: record<address: record, collectors: list, locationId: string, pickupType: string>, placedDate: string, promotions: list<record>, refunds: list<record>, shipments: list<record>, shippingCost: record<currency: string, value: string>, shippingCostTax: record<currency: string, value: string>, status: string, taxCollector: string>>"
    content-ordertrackingsignals-create: "record<customerShippingFee: record<currency: string, value: string>, deliveryPostalCode: string, deliveryRegionCode: string, lineItems: table<brand: string, gtin: string, lineItemId: string, mpn: string, productDescription: string, productId: string, productTitle: string, quantity: string, sku: string, upc: string>, merchantId: string, orderCreatedTime: record<day: int, hours: int, minutes: int, month: int, nanos: int, seconds: int, timeZone: record<id: string, version: string>, utcOffset: string, year: int>, orderId: string, orderTrackingSignalId: string, shipmentLineItemMapping: table<lineItemId: string, quantity: string, shipmentId: string>, shippingInfo: table<actualDeliveryTime: record, carrierName: string, carrierServiceName: string, earliestDeliveryPromiseTime: record, latestDeliveryPromiseTime: record, originPostalCode: string, originRegionCode: string, shipmentId: string, shippedTime: record, shippingStatus: string, trackingId: string>>"
    content-pos-inventory: "record<contentLanguage: string, gtin: string, itemId: string, kind: string, price: record<currency: string, value: string>, quantity: string, storeCode: string, targetCountry: string, timestamp: string>"
    content-pos-sale: "record<contentLanguage: string, gtin: string, itemId: string, kind: string, price: record<currency: string, value: string>, quantity: string, saleId: string, storeCode: string, targetCountry: string, timestamp: string>"
    content-pos-list: "record<kind: string, resources: table<gcidCategory: list, kind: string, phoneNumber: string, placeId: string, storeAddress: string, storeCode: string, storeName: string, websiteUrl: string>>"
    content-pos-insert: "record<gcidCategory: list<string>, kind: string, phoneNumber: string, placeId: string, storeAddress: string, storeCode: string, storeName: string, websiteUrl: string>"
    content-pos-get: "record<gcidCategory: list<string>, kind: string, phoneNumber: string, placeId: string, storeAddress: string, storeCode: string, storeName: string, websiteUrl: string>"
    content-productdeliverytime-create: "record<areaDeliveryTimes: table<deliveryArea: record, deliveryTime: record>, productId: record<productId: string>>"
    content-productdeliverytime-get: "record<areaDeliveryTimes: table<deliveryArea: record, deliveryTime: record>, productId: record<productId: string>>"
    content-products-list: "record<kind: string, nextPageToken: string, resources: table<additionalImageLinks: list, additionalSizeType: string, adsGrouping: string, adsLabels: list, adsRedirect: string, adult: bool, ageGroup: string, availability: string, availabilityDate: string, brand: string, canonicalLink: string, channel: string, color: string, condition: string, contentLanguage: string, costOfGoodsSold: record, customAttributes: list, customLabel0: string, customLabel1: string, customLabel2: string, customLabel3: string, customLabel4: string, description: string, displayAdsId: string, displayAdsLink: string, displayAdsSimilarIds: list, displayAdsTitle: string, displayAdsValue: float, energyEfficiencyClass: string, excludedDestinations: list, expirationDate: string, externalSellerId: string, feedLabel: string, gender: string, googleProductCategory: string, gtin: string, id: string, identifierExists: bool, imageLink: string, includedDestinations: list, installment: record, isBundle: bool, itemGroupId: string, kind: string, lifestyleImageLinks: list, link: string, linkTemplate: string, loyaltyPoints: record, material: string, maxEnergyEfficiencyClass: string, maxHandlingTime: string, minEnergyEfficiencyClass: string, minHandlingTime: string, mobileLink: string, mobileLinkTemplate: string, mpn: string, multipack: string, offerId: string, pattern: string, pause: string, pickupMethod: string, pickupSla: string, price: record, productDetails: list, productHeight: record, productHighlights: list, productLength: record, productTypes: list, productWeight: record, productWidth: record, promotionIds: list, salePrice: record, salePriceEffectiveDate: string, sellOnGoogleQuantity: string, shipping: list, shippingHeight: record, shippingLabel: string, shippingLength: record, shippingWeight: record, shippingWidth: record, shoppingAdsExcludedCountries: list, sizeSystem: string, sizeType: string, sizes: list, source: string, subscriptionCost: record, targetCountry: string, taxCategory: string, taxes: list, title: string, transitTimeLabel: string, unitPricingBaseMeasure: record, unitPricingMeasure: record>>"
    content-products-insert: "record<additionalImageLinks: list<string>, additionalSizeType: string, adsGrouping: string, adsLabels: list<string>, adsRedirect: string, adult: bool, ageGroup: string, availability: string, availabilityDate: string, brand: string, canonicalLink: string, channel: string, color: string, condition: string, contentLanguage: string, costOfGoodsSold: record<currency: string, value: string>, customAttributes: table<groupValues: list, name: string, value: string>, customLabel0: string, customLabel1: string, customLabel2: string, customLabel3: string, customLabel4: string, description: string, displayAdsId: string, displayAdsLink: string, displayAdsSimilarIds: list<string>, displayAdsTitle: string, displayAdsValue: float, energyEfficiencyClass: string, excludedDestinations: list<string>, expirationDate: string, externalSellerId: string, feedLabel: string, gender: string, googleProductCategory: string, gtin: string, id: string, identifierExists: bool, imageLink: string, includedDestinations: list<string>, installment: record<amount: record<currency: string, value: string>, months: string>, isBundle: bool, itemGroupId: string, kind: string, lifestyleImageLinks: list<string>, link: string, linkTemplate: string, loyaltyPoints: record<name: string, pointsValue: string, ratio: float>, material: string, maxEnergyEfficiencyClass: string, maxHandlingTime: string, minEnergyEfficiencyClass: string, minHandlingTime: string, mobileLink: string, mobileLinkTemplate: string, mpn: string, multipack: string, offerId: string, pattern: string, pause: string, pickupMethod: string, pickupSla: string, price: record<currency: string, value: string>, productDetails: table<attributeName: string, attributeValue: string, sectionName: string>, productHeight: record<unit: string, value: float>, productHighlights: list<string>, productLength: record<unit: string, value: float>, productTypes: list<string>, productWeight: record<unit: string, value: float>, productWidth: record<unit: string, value: float>, promotionIds: list<string>, salePrice: record<currency: string, value: string>, salePriceEffectiveDate: string, sellOnGoogleQuantity: string, shipping: table<country: string, locationGroupName: string, locationId: string, maxHandlingTime: string, maxTransitTime: string, minHandlingTime: string, minTransitTime: string, postalCode: string, price: record, region: string, service: string>, shippingHeight: record<unit: string, value: float>, shippingLabel: string, shippingLength: record<unit: string, value: float>, shippingWeight: record<unit: string, value: float>, shippingWidth: record<unit: string, value: float>, shoppingAdsExcludedCountries: list<string>, sizeSystem: string, sizeType: string, sizes: list<string>, source: string, subscriptionCost: record<amount: record<currency: string, value: string>, period: string, periodLength: string>, targetCountry: string, taxCategory: string, taxes: table<country: string, locationId: string, postalCode: string, rate: float, region: string, taxShip: bool>, title: string, transitTimeLabel: string, unitPricingBaseMeasure: record<unit: string, value: string>, unitPricingMeasure: record<unit: string, value: float>>"
    content-products-get: "record<additionalImageLinks: list<string>, additionalSizeType: string, adsGrouping: string, adsLabels: list<string>, adsRedirect: string, adult: bool, ageGroup: string, availability: string, availabilityDate: string, brand: string, canonicalLink: string, channel: string, color: string, condition: string, contentLanguage: string, costOfGoodsSold: record<currency: string, value: string>, customAttributes: table<groupValues: list, name: string, value: string>, customLabel0: string, customLabel1: string, customLabel2: string, customLabel3: string, customLabel4: string, description: string, displayAdsId: string, displayAdsLink: string, displayAdsSimilarIds: list<string>, displayAdsTitle: string, displayAdsValue: float, energyEfficiencyClass: string, excludedDestinations: list<string>, expirationDate: string, externalSellerId: string, feedLabel: string, gender: string, googleProductCategory: string, gtin: string, id: string, identifierExists: bool, imageLink: string, includedDestinations: list<string>, installment: record<amount: record<currency: string, value: string>, months: string>, isBundle: bool, itemGroupId: string, kind: string, lifestyleImageLinks: list<string>, link: string, linkTemplate: string, loyaltyPoints: record<name: string, pointsValue: string, ratio: float>, material: string, maxEnergyEfficiencyClass: string, maxHandlingTime: string, minEnergyEfficiencyClass: string, minHandlingTime: string, mobileLink: string, mobileLinkTemplate: string, mpn: string, multipack: string, offerId: string, pattern: string, pause: string, pickupMethod: string, pickupSla: string, price: record<currency: string, value: string>, productDetails: table<attributeName: string, attributeValue: string, sectionName: string>, productHeight: record<unit: string, value: float>, productHighlights: list<string>, productLength: record<unit: string, value: float>, productTypes: list<string>, productWeight: record<unit: string, value: float>, productWidth: record<unit: string, value: float>, promotionIds: list<string>, salePrice: record<currency: string, value: string>, salePriceEffectiveDate: string, sellOnGoogleQuantity: string, shipping: table<country: string, locationGroupName: string, locationId: string, maxHandlingTime: string, maxTransitTime: string, minHandlingTime: string, minTransitTime: string, postalCode: string, price: record, region: string, service: string>, shippingHeight: record<unit: string, value: float>, shippingLabel: string, shippingLength: record<unit: string, value: float>, shippingWeight: record<unit: string, value: float>, shippingWidth: record<unit: string, value: float>, shoppingAdsExcludedCountries: list<string>, sizeSystem: string, sizeType: string, sizes: list<string>, source: string, subscriptionCost: record<amount: record<currency: string, value: string>, period: string, periodLength: string>, targetCountry: string, taxCategory: string, taxes: table<country: string, locationId: string, postalCode: string, rate: float, region: string, taxShip: bool>, title: string, transitTimeLabel: string, unitPricingBaseMeasure: record<unit: string, value: string>, unitPricingMeasure: record<unit: string, value: float>>"
    content-products-update: "record<additionalImageLinks: list<string>, additionalSizeType: string, adsGrouping: string, adsLabels: list<string>, adsRedirect: string, adult: bool, ageGroup: string, availability: string, availabilityDate: string, brand: string, canonicalLink: string, channel: string, color: string, condition: string, contentLanguage: string, costOfGoodsSold: record<currency: string, value: string>, customAttributes: table<groupValues: list, name: string, value: string>, customLabel0: string, customLabel1: string, customLabel2: string, customLabel3: string, customLabel4: string, description: string, displayAdsId: string, displayAdsLink: string, displayAdsSimilarIds: list<string>, displayAdsTitle: string, displayAdsValue: float, energyEfficiencyClass: string, excludedDestinations: list<string>, expirationDate: string, externalSellerId: string, feedLabel: string, gender: string, googleProductCategory: string, gtin: string, id: string, identifierExists: bool, imageLink: string, includedDestinations: list<string>, installment: record<amount: record<currency: string, value: string>, months: string>, isBundle: bool, itemGroupId: string, kind: string, lifestyleImageLinks: list<string>, link: string, linkTemplate: string, loyaltyPoints: record<name: string, pointsValue: string, ratio: float>, material: string, maxEnergyEfficiencyClass: string, maxHandlingTime: string, minEnergyEfficiencyClass: string, minHandlingTime: string, mobileLink: string, mobileLinkTemplate: string, mpn: string, multipack: string, offerId: string, pattern: string, pause: string, pickupMethod: string, pickupSla: string, price: record<currency: string, value: string>, productDetails: table<attributeName: string, attributeValue: string, sectionName: string>, productHeight: record<unit: string, value: float>, productHighlights: list<string>, productLength: record<unit: string, value: float>, productTypes: list<string>, productWeight: record<unit: string, value: float>, productWidth: record<unit: string, value: float>, promotionIds: list<string>, salePrice: record<currency: string, value: string>, salePriceEffectiveDate: string, sellOnGoogleQuantity: string, shipping: table<country: string, locationGroupName: string, locationId: string, maxHandlingTime: string, maxTransitTime: string, minHandlingTime: string, minTransitTime: string, postalCode: string, price: record, region: string, service: string>, shippingHeight: record<unit: string, value: float>, shippingLabel: string, shippingLength: record<unit: string, value: float>, shippingWeight: record<unit: string, value: float>, shippingWidth: record<unit: string, value: float>, shoppingAdsExcludedCountries: list<string>, sizeSystem: string, sizeType: string, sizes: list<string>, source: string, subscriptionCost: record<amount: record<currency: string, value: string>, period: string, periodLength: string>, targetCountry: string, taxCategory: string, taxes: table<country: string, locationId: string, postalCode: string, rate: float, region: string, taxShip: bool>, title: string, transitTimeLabel: string, unitPricingBaseMeasure: record<unit: string, value: string>, unitPricingMeasure: record<unit: string, value: float>>"
    content-localinventory-insert: "record<availability: string, customAttributes: table<groupValues: list, name: string, value: string>, instoreProductLocation: string, kind: string, pickupMethod: string, pickupSla: string, price: record<currency: string, value: string>, quantity: int, salePrice: record<currency: string, value: string>, salePriceEffectiveDate: string, storeCode: string>"
    content-regionalinventory-insert: "record<availability: string, customAttributes: table<groupValues: list, name: string, value: string>, kind: string, price: record<currency: string, value: string>, regionId: string, salePrice: record<currency: string, value: string>, salePriceEffectiveDate: string>"
    content-productstatuses-list: "record<kind: string, nextPageToken: string, resources: table<creationDate: string, destinationStatuses: list, googleExpirationDate: string, itemLevelIssues: list, kind: string, lastUpdateDate: string, link: string, productId: string, title: string>>"
    content-productstatuses-get: "record<creationDate: string, destinationStatuses: table<approvedCountries: list, destination: string, disapprovedCountries: list, pendingCountries: list, status: string>, googleExpirationDate: string, itemLevelIssues: table<applicableCountries: list, attributeName: string, code: string, description: string, destination: string, detail: string, documentation: string, resolution: string, servability: string>, kind: string, lastUpdateDate: string, link: string, productId: string, title: string>"
    content-productstatuses-repricingreports-list: "record<nextPageToken: string, repricingProductReports: table<applicationCount: string, buyboxWinningProductStats: record, date: record, highWatermark: record, inapplicabilityDetails: list, lowWatermark: record, orderItemCount: int, ruleIds: list, totalGmv: record, type: string>>"
    content-promotions-create: "record<brand: list<string>, brandExclusion: list<string>, contentLanguage: string, couponValueType: string, freeGiftDescription: string, freeGiftItemId: string, freeGiftValue: record<currency: string, value: string>, genericRedemptionCode: string, getThisQuantityDiscounted: int, id: string, itemGroupId: list<string>, itemGroupIdExclusion: list<string>, itemId: list<string>, itemIdExclusion: list<string>, limitQuantity: int, limitValue: record<currency: string, value: string>, longTitle: string, minimumPurchaseAmount: record<currency: string, value: string>, minimumPurchaseQuantity: int, moneyBudget: record<currency: string, value: string>, moneyOffAmount: record<currency: string, value: string>, offerType: string, orderLimit: int, percentOff: int, productApplicability: string, productType: list<string>, productTypeExclusion: list<string>, promotionDestinationIds: list<string>, promotionDisplayDates: string, promotionDisplayTimePeriod: record<endTime: string, startTime: string>, promotionEffectiveDates: string, promotionEffectiveTimePeriod: record<endTime: string, startTime: string>, promotionId: string, promotionStatus: record<creationDate: string, destinationStatuses: list<record>, lastUpdateDate: string, promotionIssue: list<record>>, promotionUrl: string, redemptionChannel: list<string>, shippingServiceNames: list<string>, storeApplicability: string, storeCode: list<string>, storeCodeExclusion: list<string>, targetCountry: string>"
    content-promotions-get: "record<brand: list<string>, brandExclusion: list<string>, contentLanguage: string, couponValueType: string, freeGiftDescription: string, freeGiftItemId: string, freeGiftValue: record<currency: string, value: string>, genericRedemptionCode: string, getThisQuantityDiscounted: int, id: string, itemGroupId: list<string>, itemGroupIdExclusion: list<string>, itemId: list<string>, itemIdExclusion: list<string>, limitQuantity: int, limitValue: record<currency: string, value: string>, longTitle: string, minimumPurchaseAmount: record<currency: string, value: string>, minimumPurchaseQuantity: int, moneyBudget: record<currency: string, value: string>, moneyOffAmount: record<currency: string, value: string>, offerType: string, orderLimit: int, percentOff: int, productApplicability: string, productType: list<string>, productTypeExclusion: list<string>, promotionDestinationIds: list<string>, promotionDisplayDates: string, promotionDisplayTimePeriod: record<endTime: string, startTime: string>, promotionEffectiveDates: string, promotionEffectiveTimePeriod: record<endTime: string, startTime: string>, promotionId: string, promotionStatus: record<creationDate: string, destinationStatuses: list<record>, lastUpdateDate: string, promotionIssue: list<record>>, promotionUrl: string, redemptionChannel: list<string>, shippingServiceNames: list<string>, storeApplicability: string, storeCode: list<string>, storeCodeExclusion: list<string>, targetCountry: string>"
    content-pubsubnotificationsettings-get: "record<cloudTopicName: string, kind: string, registeredEvents: list<string>>"
    content-pubsubnotificationsettings-update: "record<cloudTopicName: string, kind: string, registeredEvents: list<string>>"
    content-quotas-list: "record<methodQuotas: table<method: string, quotaLimit: string, quotaUsage: string>, nextPageToken: string>"
    content-recommendations-generate: "record<recommendations: table<additionalCallToAction: list, additionalDescriptions: list, creative: list, defaultCallToAction: record, defaultDescription: string, numericalImpact: int, paid: bool, recommendationName: string, subType: string, title: string, type: string>, responseToken: string>"
    content-regions-list: "record<nextPageToken: string, regions: table<displayName: string, geotargetArea: record, merchantId: string, postalCodeArea: record, regionId: string, regionalInventoryEligible: bool, shippingEligible: bool>>"
    content-regions-create: "record<displayName: string, geotargetArea: record<geotargetCriteriaIds: list<string>>, merchantId: string, postalCodeArea: record<postalCodes: list<record>, regionCode: string>, regionId: string, regionalInventoryEligible: bool, shippingEligible: bool>"
    content-regions-get: "record<displayName: string, geotargetArea: record<geotargetCriteriaIds: list<string>>, merchantId: string, postalCodeArea: record<postalCodes: list<record>, regionCode: string>, regionId: string, regionalInventoryEligible: bool, shippingEligible: bool>"
    content-regions-patch: "record<displayName: string, geotargetArea: record<geotargetCriteriaIds: list<string>>, merchantId: string, postalCodeArea: record<postalCodes: list<record>, regionCode: string>, regionId: string, regionalInventoryEligible: bool, shippingEligible: bool>"
    content-reports-search: "record<nextPageToken: string, results: table<bestSellers: record, brand: record, metrics: record, priceCompetitiveness: record, priceInsights: record, productCluster: record, productView: record, segments: record>>"
    content-repricingrules-list: "record<nextPageToken: string, repricingRules: table<cogsBasedRule: record, countryCode: string, effectiveTimePeriod: record, eligibleOfferMatcher: record, languageCode: string, merchantId: string, paused: bool, restriction: record, ruleId: string, statsBasedRule: record, title: string, type: string>>"
    content-repricingrules-create: "record<cogsBasedRule: record<percentageDelta: int, priceDelta: string>, countryCode: string, effectiveTimePeriod: record<fixedTimePeriods: list<record>>, eligibleOfferMatcher: record<brandMatcher: record<strAttributes: list>, itemGroupIdMatcher: record<strAttributes: list>, matcherOption: string, offerIdMatcher: record<strAttributes: list>, skipWhenOnPromotion: bool>, languageCode: string, merchantId: string, paused: bool, restriction: record<floor: record<percentageDelta: int, priceDelta: string>, useAutoPricingMinPrice: bool>, ruleId: string, statsBasedRule: record<percentageDelta: int, priceDelta: string>, title: string, type: string>"
    content-repricingrules-get: "record<cogsBasedRule: record<percentageDelta: int, priceDelta: string>, countryCode: string, effectiveTimePeriod: record<fixedTimePeriods: list<record>>, eligibleOfferMatcher: record<brandMatcher: record<strAttributes: list>, itemGroupIdMatcher: record<strAttributes: list>, matcherOption: string, offerIdMatcher: record<strAttributes: list>, skipWhenOnPromotion: bool>, languageCode: string, merchantId: string, paused: bool, restriction: record<floor: record<percentageDelta: int, priceDelta: string>, useAutoPricingMinPrice: bool>, ruleId: string, statsBasedRule: record<percentageDelta: int, priceDelta: string>, title: string, type: string>"
    content-repricingrules-patch: "record<cogsBasedRule: record<percentageDelta: int, priceDelta: string>, countryCode: string, effectiveTimePeriod: record<fixedTimePeriods: list<record>>, eligibleOfferMatcher: record<brandMatcher: record<strAttributes: list>, itemGroupIdMatcher: record<strAttributes: list>, matcherOption: string, offerIdMatcher: record<strAttributes: list>, skipWhenOnPromotion: bool>, languageCode: string, merchantId: string, paused: bool, restriction: record<floor: record<percentageDelta: int, priceDelta: string>, useAutoPricingMinPrice: bool>, ruleId: string, statsBasedRule: record<percentageDelta: int, priceDelta: string>, title: string, type: string>"
    content-repricingrules-repricingreports-list: "record<nextPageToken: string, repricingRuleReports: table<buyboxWinningRuleStats: record, date: record, impactedProducts: list, inapplicabilityDetails: list, inapplicableProducts: list, orderItemCount: int, ruleId: string, totalGmv: record, type: string>>"
    content-returnaddress-list: "record<kind: string, nextPageToken: string, resources: table<address: record, country: string, kind: string, label: string, phoneNumber: string, returnAddressId: string>>"
    content-returnaddress-insert: "record<address: record<country: string, locality: string, postalCode: string, recipientName: string, region: string, streetAddress: list<string>>, country: string, kind: string, label: string, phoneNumber: string, returnAddressId: string>"
    content-returnaddress-get: "record<address: record<country: string, locality: string, postalCode: string, recipientName: string, region: string, streetAddress: list<string>>, country: string, kind: string, label: string, phoneNumber: string, returnAddressId: string>"
    content-returnpolicy-list: "record<kind: string, resources: table<country: string, kind: string, label: string, name: string, nonFreeReturnReasons: list, policy: record, returnPolicyId: string, returnShippingFee: record, seasonalOverrides: list>>"
    content-returnpolicy-insert: "record<country: string, kind: string, label: string, name: string, nonFreeReturnReasons: list<string>, policy: record<lastReturnDate: string, numberOfDays: string, type: string>, returnPolicyId: string, returnShippingFee: record<currency: string, value: string>, seasonalOverrides: table<endDate: string, name: string, policy: record, startDate: string>>"
    content-returnpolicy-get: "record<country: string, kind: string, label: string, name: string, nonFreeReturnReasons: list<string>, policy: record<lastReturnDate: string, numberOfDays: string, type: string>, returnPolicyId: string, returnShippingFee: record<currency: string, value: string>, seasonalOverrides: table<endDate: string, name: string, policy: record, startDate: string>>"
    content-returnpolicyonline-list: "record<returnPolicies: table<countries: list, itemConditions: list, label: string, name: string, policy: record, restockingFee: record, returnMethods: list, returnPolicyId: string, returnPolicyUri: string, returnReasonCategoryInfo: list>>"
    content-returnpolicyonline-create: "record<countries: list<string>, itemConditions: list<string>, label: string, name: string, policy: record<days: string, type: string>, restockingFee: record<fixedFee: record<currency: string, value: string>, microPercent: int>, returnMethods: list<string>, returnPolicyId: string, returnPolicyUri: string, returnReasonCategoryInfo: table<returnLabelSource: string, returnReasonCategory: string, returnShippingFee: record>>"
    content-returnpolicyonline-get: "record<countries: list<string>, itemConditions: list<string>, label: string, name: string, policy: record<days: string, type: string>, restockingFee: record<fixedFee: record<currency: string, value: string>, microPercent: int>, returnMethods: list<string>, returnPolicyId: string, returnPolicyUri: string, returnReasonCategoryInfo: table<returnLabelSource: string, returnReasonCategory: string, returnShippingFee: record>>"
    content-returnpolicyonline-patch: "record<countries: list<string>, itemConditions: list<string>, label: string, name: string, policy: record<days: string, type: string>, restockingFee: record<fixedFee: record<currency: string, value: string>, microPercent: int>, returnMethods: list<string>, returnPolicyId: string, returnPolicyUri: string, returnReasonCategoryInfo: table<returnLabelSource: string, returnReasonCategory: string, returnShippingFee: record>>"
    content-settlementreports-list: "record<kind: string, nextPageToken: string, resources: table<endDate: string, kind: string, previousBalance: record, settlementId: string, startDate: string, transferAmount: record, transferDate: string, transferIds: list>>"
    content-settlementreports-get: "record<endDate: string, kind: string, previousBalance: record<currency: string, value: string>, settlementId: string, startDate: string, transferAmount: record<currency: string, value: string>, transferDate: string, transferIds: list<string>>"
    content-settlementtransactions-list: "record<kind: string, nextPageToken: string, resources: table<amount: record, identifiers: record, kind: string, transaction: record>>"
    content-shippingsettings-list: "record<kind: string, nextPageToken: string, resources: table<accountId: string, postalCodeGroups: list, services: list, warehouses: list>>"
    content-shippingsettings-get: "record<accountId: string, postalCodeGroups: table<country: string, name: string, postalCodeRanges: list>, services: table<active: bool, currency: string, deliveryCountry: string, deliveryTime: record, eligibility: string, minimumOrderValue: record, minimumOrderValueTable: record, name: string, pickupService: record, rateGroups: list, shipmentType: string>, warehouses: table<businessDayConfig: record, cutoffTime: record, handlingDays: string, name: string, shippingAddress: record>>"
    content-shippingsettings-update: "record<accountId: string, postalCodeGroups: table<country: string, name: string, postalCodeRanges: list>, services: table<active: bool, currency: string, deliveryCountry: string, deliveryTime: record, eligibility: string, minimumOrderValue: record, minimumOrderValueTable: record, name: string, pickupService: record, rateGroups: list, shipmentType: string>, warehouses: table<businessDayConfig: record, cutoffTime: record, handlingDays: string, name: string, shippingAddress: record>>"
    content-shoppingadsprogram-get: "record<globalState: string, regionStatuses: table<disapprovalDate: string, eligibilityStatus: string, onboardingIssues: list, regionCodes: list, reviewEligibilityStatus: string, reviewIneligibilityReason: string, reviewIneligibilityReasonDescription: string, reviewIneligibilityReasonDetails: record, reviewIssues: list>>"
    content-shippingsettings-getsupportedcarriers: "record<carriers: table<country: string, eddServices: list, name: string, services: list>, kind: string>"
    content-shippingsettings-getsupportedholidays: "record<holidays: table<countryCode: string, date: string, deliveryGuaranteeDate: string, deliveryGuaranteeHour: string, id: string, type: string>, kind: string>"
    content-shippingsettings-getsupportedpickupservices: "record<kind: string, pickupServices: table<carrierName: string, country: string, serviceName: string>>"
    content-orders-createtestorder: "record<kind: string, orderId: string>"
    content-orders-advancetestorder: "record<kind: string>"
    content-orders-canceltestorderbycustomer: "record<kind: string>"
    content-orders-gettestordertemplate: "record<kind: string, template: record<deliveryDetails: record<address: record, isScheduledDelivery: bool, phoneNumber: string>, enableOrderinvoices: bool, kind: string, lineItems: list<record>, notificationMode: string, pickupDetails: record<locationCode: string, pickupLocationAddress: record, pickupLocationType: string, pickupPersons: list>, predefinedBillingAddress: string, predefinedDeliveryAddress: string, predefinedEmail: string, predefinedPickupDetails: string, promotions: list<record>, shippingCost: record<currency: string, value: string>, shippingOption: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["content-accounts-authinfo" "content-accounts-custombatch" "content-accounts-credentials-create" "content-accounts-labels-list" "content-accounts-labels-create" "content-accounts-labels-delete" "content-accounts-labels-patch" "content-accounts-returncarrier-list" "content-accounts-returncarrier-create" "content-accounts-returncarrier-delete" "content-accounts-returncarrier-patch" "content-accountstatuses-custombatch" "content-accounttax-custombatch" "content-datafeeds-custombatch" "content-datafeedstatuses-custombatch" "content-liasettings-custombatch" "content-liasettings-listposdataproviders" "content-localinventory-custombatch" "content-pos-custombatch" "content-products-custombatch" "content-productstatuses-custombatch" "content-regionalinventory-custombatch" "content-returnaddress-custombatch" "content-returnpolicy-custombatch" "content-shippingsettings-custombatch" "content-csses-list" "content-csses-get" "content-csses-updatelabels" "content-accounts-list" "content-accounts-insert" "content-accounts-delete" "content-accounts-get" "content-accounts-update" "content-accounts-claimwebsite" "content-accounts-link" "content-accounts-listlinks" "content-accounts-requestphoneverification" "content-accounts-updatelabels" "content-accounts-verifyphonenumber" "content-accountstatuses-list" "content-accountstatuses-get" "content-accounttax-list" "content-accounttax-get" "content-accounttax-update" "content-buyongoogleprograms-get" "content-buyongoogleprograms-patch" "content-buyongoogleprograms-activate" "content-buyongoogleprograms-onboard" "content-buyongoogleprograms-pause" "content-buyongoogleprograms-requestreview" "content-collections-list" "content-collections-create" "content-collections-delete" "content-collections-get" "content-collectionstatuses-list" "content-collectionstatuses-get" "content-conversionsources-list" "content-conversionsources-create" "content-conversionsources-delete" "content-conversionsources-get" "content-conversionsources-patch" "content-conversionsources-undelete" "content-datafeeds-list" "content-datafeeds-insert" "content-datafeeds-delete" "content-datafeeds-get" "content-datafeeds-update" "content-datafeeds-fetchnow" "content-datafeedstatuses-list" "content-datafeedstatuses-get" "content-freelistingsprogram-get" "content-freelistingsprogram-requestreview" "content-liasettings-list" "content-liasettings-get" "content-liasettings-update" "content-liasettings-getaccessiblegmbaccounts" "content-liasettings-requestgmbaccess" "content-liasettings-requestinventoryverification" "content-liasettings-setinventoryverificationcontact" "content-liasettings-setposdataprovider" "content-orderinvoices-createchargeinvoice" "content-orderinvoices-createrefundinvoice" "content-orderreports-listdisbursements" "content-orderreports-listtransactions" "content-orderreturns-list" "content-orderreturns-createorderreturn" "content-orderreturns-get" "content-orderreturns-acknowledge" "content-orderreturns-labels-create" "content-orderreturns-process" "content-orders-list" "content-orders-get" "content-orders-acknowledge" "content-orders-cancel" "content-orders-cancellineitem" "content-orders-capture-order" "content-orders-instorerefundlineitem" "content-orders-refunditem" "content-orders-refundorder" "content-orders-rejectreturnlineitem" "content-orders-returnrefundlineitem" "content-orders-setlineitemmetadata" "content-orders-shiplineitems" "content-orders-createtestreturn" "content-orders-updatelineitemshippingdetails" "content-orders-updatemerchantorderid" "content-orders-updateshipment" "content-orders-getbymerchantorderid" "content-ordertrackingsignals-create" "content-pos-inventory" "content-pos-sale" "content-pos-list" "content-pos-insert" "content-pos-delete" "content-pos-get" "content-productdeliverytime-create" "content-productdeliverytime-delete" "content-productdeliverytime-get" "content-products-list" "content-products-insert" "content-products-delete" "content-products-get" "content-products-update" "content-localinventory-insert" "content-regionalinventory-insert" "content-productstatuses-list" "content-productstatuses-get" "content-productstatuses-repricingreports-list" "content-promotions-create" "content-promotions-get" "content-pubsubnotificationsettings-get" "content-pubsubnotificationsettings-update" "content-quotas-list" "content-recommendations-generate" "content-recommendations-report-interaction" "content-regions-list" "content-regions-create" "content-regions-delete" "content-regions-get" "content-regions-patch" "content-reports-search" "content-repricingrules-list" "content-repricingrules-create" "content-repricingrules-delete" "content-repricingrules-get" "content-repricingrules-patch" "content-repricingrules-repricingreports-list" "content-returnaddress-list" "content-returnaddress-insert" "content-returnaddress-delete" "content-returnaddress-get" "content-returnpolicy-list" "content-returnpolicy-insert" "content-returnpolicy-delete" "content-returnpolicy-get" "content-returnpolicyonline-list" "content-returnpolicyonline-create" "content-returnpolicyonline-delete" "content-returnpolicyonline-get" "content-returnpolicyonline-patch" "content-settlementreports-list" "content-settlementreports-get" "content-settlementtransactions-list" "content-shippingsettings-list" "content-shippingsettings-get" "content-shippingsettings-update" "content-shoppingadsprogram-get" "content-shoppingadsprogram-requestreview" "content-shippingsettings-getsupportedcarriers" "content-shippingsettings-getsupportedholidays" "content-shippingsettings-getsupportedpickupservices" "content-orders-createtestorder" "content-orders-advancetestorder" "content-orders-canceltestorderbycustomer" "content-orders-gettestordertemplate" "commands"] | sort) } | get name | first)
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

# Returns information about the authenticated user.
#
# GET /accounts/authinfo
# Returns: record<accountIdentifiers: table<aggregatorId: string, merchantId: string>, kind: string>
# operationId: content.accounts.authinfo
export def "content-accounts-authinfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/authinfo"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves, inserts, updates, and deletes multiple Merchant Center (sub-)accounts in a single request.
#
# POST /accounts/batch
# Returns: record<entries: table<account: record, batchId: int, errors: record, kind: string>, kind: string>
# operationId: content.accounts.custombatch
export def "content-accounts-custombatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --entries: list # The request entries to be processed in the batch. — item shape: {account?: record, accountId?: string, batchId?: int, force?: bool, labelIds?: list<string>, linkRequest?: record, merchantId?: string, method?: string, overwrite?: bool, view?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/batch"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: entries, var: entries}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, entries: $entries
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uploads credentials for the Merchant Center account. If credentials already exist for this Merchant Center account and purpose, this method updates them.
#
# POST /accounts/{accountId}/credentials
# Returns: record<accessToken: string, expiresIn: string, purpose: string>
# operationId: content.accounts.credentials.create
export def "content-accounts-credentials-create" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-access-token: string # An OAuth access token. (spec name: accessToken)
  --expires-in: string # The amount of time, in seconds, after which the access token is no longer valid. (format: int64)
  --purpose: string@purpose-completer # Indicates to Google how Google should use these OAuth tokens.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{accountId}/credentials"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: accessToken, var: body_access_token}, {name: expiresIn, var: expires_in}, {name: purpose, var: purpose}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body_access_token: $body_access_token, expires_in: $expires_in, purpose: $purpose
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the labels assigned to an account.
#
# GET /accounts/{accountId}/labels
# Returns: record<accountLabels: table<accountId: string, description: string, labelId: string, labelType: string, name: string>, nextPageToken: string>
# operationId: content.accounts.labels.list
export def "content-accounts-labels-list" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # The maximum number of labels to return. The service may return fewer than this value. If unspecified, at most 50 labels will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # A page token, received from a previous `ListAccountLabels` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `ListAccountLabels` must match the call that provided the page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{accountId}/labels"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new label, not assigned to any account.
#
# POST /accounts/{accountId}/labels
# Returns: record<accountId: string, description: string, labelId: string, labelType: string, name: string>
# operationId: content.accounts.labels.create
export def "content-accounts-labels-create" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-account-id: string # Immutable. The ID of account this label belongs to. (format: int64) (spec name: accountId)
  --description: string # The description of this label.
  --name: string # The display name of this label.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{accountId}/labels"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: description, var: description}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body_account_id: $body_account_id, description: $description, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a label and removes it from all accounts to which it was assigned.
#
# DELETE /accounts/{accountId}/labels/{labelId}
# operationId: content.accounts.labels.delete
export def "content-accounts-labels-delete" [
  account_id: string
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> any {
  http-request {
    method: delete
    path: "/accounts/{accountId}/labels/{labelId}"
    path_params: [{name: accountId, var: account_id}, {name: labelId, var: label_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, label_id: $label_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a label.
#
# PATCH /accounts/{accountId}/labels/{labelId}
# Returns: record<accountId: string, description: string, labelId: string, labelType: string, name: string>
# operationId: content.accounts.labels.patch
export def "content-accounts-labels-patch" [
  account_id: string
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-account-id: string # Immutable. The ID of account this label belongs to. (format: int64) (spec name: accountId)
  --description: string # The description of this label.
  --name: string # The display name of this label.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/accounts/{accountId}/labels/{labelId}"
    path_params: [{name: accountId, var: account_id}, {name: labelId, var: label_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: description, var: description}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, label_id: $label_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body_account_id: $body_account_id, description: $description, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists available return carriers in the merchant account.
#
# GET /accounts/{accountId}/returncarrier
# Returns: record<accountReturnCarriers: table<carrierAccountId: string, carrierAccountName: string, carrierAccountNumber: string, carrierCode: string>>
# operationId: content.accounts.returncarrier.list
export def "content-accounts-returncarrier-list" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{accountId}/returncarrier"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Links return carrier to a merchant account.
#
# POST /accounts/{accountId}/returncarrier
# Returns: record<carrierAccountId: string, carrierAccountName: string, carrierAccountNumber: string, carrierCode: string>
# operationId: content.accounts.returncarrier.create
export def "content-accounts-returncarrier-create" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --carrier-account-name: string # Name of the carrier account.
  --carrier-account-number: string # Number of the carrier account.
  --carrier-code: string@carrier-code-completer # The carrier code enum. Accepts the values FEDEX or UPS.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{accountId}/returncarrier"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: carrierAccountName, var: carrier_account_name}, {name: carrierAccountNumber, var: carrier_account_number}, {name: carrierCode, var: carrier_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, carrier_account_name: $carrier_account_name, carrier_account_number: $carrier_account_number, carrier_code: $carrier_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a return carrier in the merchant account.
#
# DELETE /accounts/{accountId}/returncarrier/{carrierAccountId}
# operationId: content.accounts.returncarrier.delete
export def "content-accounts-returncarrier-delete" [
  account_id: string
  carrier_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> any {
  http-request {
    method: delete
    path: "/accounts/{accountId}/returncarrier/{carrierAccountId}"
    path_params: [{name: accountId, var: account_id}, {name: carrierAccountId, var: carrier_account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, carrier_account_id: $carrier_account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a return carrier in the merchant account.
#
# PATCH /accounts/{accountId}/returncarrier/{carrierAccountId}
# Returns: record<carrierAccountId: string, carrierAccountName: string, carrierAccountNumber: string, carrierCode: string>
# operationId: content.accounts.returncarrier.patch
export def "content-accounts-returncarrier-patch" [
  account_id: string
  carrier_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --carrier-account-name: string # Name of the carrier account.
  --carrier-account-number: string # Number of the carrier account.
  --carrier-code: string@carrier-code-completer # The carrier code enum. Accepts the values FEDEX or UPS.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/accounts/{accountId}/returncarrier/{carrierAccountId}"
    path_params: [{name: accountId, var: account_id}, {name: carrierAccountId, var: carrier_account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: carrierAccountName, var: carrier_account_name}, {name: carrierAccountNumber, var: carrier_account_number}, {name: carrierCode, var: carrier_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, carrier_account_id: $carrier_account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, carrier_account_name: $carrier_account_name, carrier_account_number: $carrier_account_number, carrier_code: $carrier_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves multiple Merchant Center account statuses in a single request.
#
# POST /accountstatuses/batch
# Returns: record<entries: table<accountStatus: record, batchId: int, errors: record>, kind: string>
# operationId: content.accountstatuses.custombatch
export def "content-accountstatuses-custombatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --entries: list # The request entries to be processed in the batch. — item shape: {accountId?: string, batchId?: int, destinations?: list<string>, merchantId?: string, method?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accountstatuses/batch"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: entries, var: entries}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, entries: $entries
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves and updates tax settings of multiple accounts in a single request.
#
# POST /accounttax/batch
# Returns: record<entries: table<accountTax: record, batchId: int, errors: record, kind: string>, kind: string>
# operationId: content.accounttax.custombatch
export def "content-accounttax-custombatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --entries: list # The request entries to be processed in the batch. — item shape: {accountId?: string, accountTax?: record, batchId?: int, merchantId?: string, method?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounttax/batch"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: entries, var: entries}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, entries: $entries
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes, fetches, gets, inserts and updates multiple datafeeds in a single request.
#
# POST /datafeeds/batch
# Returns: record<entries: table<batchId: int, datafeed: record, errors: record>, kind: string>
# operationId: content.datafeeds.custombatch
export def "content-datafeeds-custombatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --entries: list # The request entries to be processed in the batch. — item shape: {batchId?: int, datafeed?: record, datafeedId?: string, merchantId?: string, method?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/datafeeds/batch"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: entries, var: entries}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, entries: $entries
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets multiple Merchant Center datafeed statuses in a single request.
#
# POST /datafeedstatuses/batch
# Returns: record<entries: table<batchId: int, datafeedStatus: record, errors: record>, kind: string>
# operationId: content.datafeedstatuses.custombatch
export def "content-datafeedstatuses-custombatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --entries: list # The request entries to be processed in the batch. — item shape: {batchId?: int, country?: string, datafeedId?: string, feedLabel?: string, language?: string, merchantId?: string, method?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/datafeedstatuses/batch"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: entries, var: entries}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, entries: $entries
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves and/or updates the LIA settings of multiple accounts in a single request.
#
# POST /liasettings/batch
# Returns: record<entries: table<batchId: int, errors: record, gmbAccounts: record, kind: string, liaSettings: record, posDataProviders: list>, kind: string>
# operationId: content.liasettings.custombatch
export def "content-liasettings-custombatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --entries: list # The request entries to be processed in the batch. — item shape: {accountId?: string, batchId?: int, contactEmail?: string, contactName?: string, country?: string, gmbEmail?: string, liaSettings?: record, merchantId?: string, method?: string, posDataProviderId?: string, posExternalAccountId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/liasettings/batch"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: entries, var: entries}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, entries: $entries
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the list of POS data providers that have active settings for the all eiligible countries.
#
# GET /liasettings/posdataproviders
# Returns: record<kind: string, posDataProviders: table<country: string, posDataProviders: list>>
# operationId: content.liasettings.listposdataproviders
export def "content-liasettings-listposdataproviders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/liasettings/posdataproviders"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates local inventory for multiple products or stores in a single request.
#
# POST /localinventory/batch
# Returns: record<entries: table<batchId: int, errors: record, kind: string>, kind: string>
# operationId: content.localinventory.custombatch
export def "content-localinventory-custombatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --entries: list # The request entries to be processed in the batch. — item shape: {batchId?: int, localInventory?: record, merchantId?: string, method?: string, productId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/localinventory/batch"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: entries, var: entries}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, entries: $entries
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Batches multiple POS-related calls in a single request.
#
# POST /pos/batch
# Returns: record<entries: table<batchId: int, errors: record, inventory: record, kind: string, sale: record, store: record>, kind: string>
# operationId: content.pos.custombatch
export def "content-pos-custombatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --entries: list # The request entries to be processed in the batch. — item shape: {batchId?: int, inventory?: record, merchantId?: string, method?: string, sale?: record, store?: record, storeCode?: string, targetMerchantId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/pos/batch"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: entries, var: entries}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, entries: $entries
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves, inserts, and deletes multiple products in a single request.
#
# POST /products/batch
# Returns: record<entries: table<batchId: int, errors: record, kind: string, product: record>, kind: string>
# operationId: content.products.custombatch
export def "content-products-custombatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --entries: list # The request entries to be processed in the batch. — item shape: {batchId?: int, feedId?: string, merchantId?: string, method?: string, product?: record, productId?: string, updateMask?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/products/batch"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: entries, var: entries}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, entries: $entries
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the statuses of multiple products in a single request.
#
# POST /productstatuses/batch
# Returns: record<entries: table<batchId: int, errors: record, kind: string, productStatus: record>, kind: string>
# operationId: content.productstatuses.custombatch
export def "content-productstatuses-custombatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --entries: list # The request entries to be processed in the batch. — item shape: {batchId?: int, destinations?: list<string>, includeAttributes?: bool, merchantId?: string, method?: string, productId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/productstatuses/batch"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: entries, var: entries}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, entries: $entries
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates regional inventory for multiple products or regions in a single request.
#
# POST /regionalinventory/batch
# Returns: record<entries: table<batchId: int, errors: record, kind: string, regionalInventory: record>, kind: string>
# operationId: content.regionalinventory.custombatch
export def "content-regionalinventory-custombatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --entries: list # The request entries to be processed in the batch. — item shape: {batchId?: int, merchantId?: string, method?: string, productId?: string, regionalInventory?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/regionalinventory/batch"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: entries, var: entries}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, entries: $entries
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Batches multiple return address related calls in a single request.
#
# POST /returnaddress/batch
# Returns: record<entries: table<batchId: int, errors: record, kind: string, returnAddress: record>, kind: string>
# operationId: content.returnaddress.custombatch
export def "content-returnaddress-custombatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --entries: list # The request entries to be processed in the batch. — item shape: {batchId?: int, merchantId?: string, method?: string, returnAddress?: record, returnAddressId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/returnaddress/batch"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: entries, var: entries}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, entries: $entries
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Batches multiple return policy related calls in a single request.
#
# POST /returnpolicy/batch
# Returns: record<entries: table<batchId: int, errors: record, kind: string, returnPolicy: record>, kind: string>
# operationId: content.returnpolicy.custombatch
export def "content-returnpolicy-custombatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --entries: list # The request entries to be processed in the batch. — item shape: {batchId?: int, merchantId?: string, method?: string, returnPolicy?: record, returnPolicyId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/returnpolicy/batch"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: entries, var: entries}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, entries: $entries
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves and updates the shipping settings of multiple accounts in a single request.
#
# POST /shippingsettings/batch
# Returns: record<entries: table<batchId: int, errors: record, kind: string, shippingSettings: record>, kind: string>
# operationId: content.shippingsettings.custombatch
export def "content-shippingsettings-custombatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --entries: list # The request entries to be processed in the batch. — item shape: {accountId?: string, batchId?: int, merchantId?: string, method?: string, shippingSettings?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/shippingsettings/batch"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: entries, var: entries}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, entries: $entries
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists CSS domains affiliated with a CSS group.
#
# GET /{cssGroupId}/csses
# Returns: record<csses: table<cssDomainId: string, cssGroupId: string, displayName: string, fullName: string, homepageUri: string, labelIds: list>, nextPageToken: string>
# operationId: content.csses.list
export def "content-csses-list" [
  css_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # The maximum number of CSS domains to return. The service may return fewer than this value. If unspecified, at most 50 CSS domains will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # A page token, received from a previous `ListCsses` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `ListCsses` must match the call that provided the page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{cssGroupId}/csses"
    path_params: [{name: cssGroupId, var: css_group_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    css_group_id: $css_group_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a single CSS domain by ID.
#
# GET /{cssGroupId}/csses/{cssDomainId}
# Returns: record<cssDomainId: string, cssGroupId: string, displayName: string, fullName: string, homepageUri: string, labelIds: list<string>>
# operationId: content.csses.get
export def "content-csses-get" [
  css_group_id: string
  css_domain_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{cssGroupId}/csses/{cssDomainId}"
    path_params: [{name: cssGroupId, var: css_group_id}, {name: cssDomainId, var: css_domain_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    css_group_id: $css_group_id, css_domain_id: $css_domain_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates labels that are assigned to a CSS domain by its CSS group.
#
# POST /{cssGroupId}/csses/{cssDomainId}/updatelabels
# Returns: record<cssDomainId: string, cssGroupId: string, displayName: string, fullName: string, homepageUri: string, labelIds: list<string>>
# operationId: content.csses.updatelabels
export def "content-csses-updatelabels" [
  css_group_id: string
  css_domain_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --label-ids: list<string> # The list of label IDs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{cssGroupId}/csses/{cssDomainId}/updatelabels"
    path_params: [{name: cssGroupId, var: css_group_id}, {name: cssDomainId, var: css_domain_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: labelIds, var: label_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    css_group_id: $css_group_id, css_domain_id: $css_domain_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, label_ids: $label_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the sub-accounts in your Merchant Center account.
#
# GET /{merchantId}/accounts
# Returns: record<kind: string, nextPageToken: string, resources: table<accountManagement: string, adsLinks: list, adultContent: bool, automaticImprovements: record, automaticLabelIds: list, businessInformation: record, conversionSettings: record, cssId: string, googleMyBusinessLink: record, id: string, kind: string, labelIds: list, name: string, sellerId: string, users: list, websiteUrl: string, youtubeChannelLinks: list>>
# operationId: content.accounts.list
export def "content-accounts-list" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --label: string # If view is set to "css", only return accounts that are assigned label with given ID.
  --max-results: int # The maximum number of accounts to return in the response, used for paging.
  --name: string # If set, only the accounts with the given name (case sensitive) will be returned.
  --page-token: string # The token returned by the previous request.
  --view: string@view-completer # Controls which fields will be populated. Acceptable values are: "merchant" and "css". The default value is "merchant".
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/accounts"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: label, var: label}, {name: maxResults, var: max_results}, {name: name, var: name}, {name: pageToken, var: page_token}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, label: $label, max_results: $max_results, name: $name, page_token: $page_token, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Merchant Center sub-account.
#
# POST /{merchantId}/accounts
# Returns: record<accountManagement: string, adsLinks: table<adsId: string, status: string>, adultContent: bool, automaticImprovements: record<imageImprovements: record<accountImageImprovementsSettings: record, effectiveAllowAutomaticImageImprovements: bool>, itemUpdates: record<accountItemUpdatesSettings: record, effectiveAllowAvailabilityUpdates: bool, effectiveAllowConditionUpdates: bool, effectiveAllowPriceUpdates: bool, effectiveAllowStrictAvailabilityUpdates: bool>, shippingImprovements: record<allowShippingImprovements: bool>>, automaticLabelIds: list<string>, businessInformation: record<address: record<country: string, locality: string, postalCode: string, region: string, streetAddress: string>, customerService: record<email: string, phoneNumber: string, url: string>, koreanBusinessRegistrationNumber: string, phoneNumber: string, phoneVerificationStatus: string>, conversionSettings: record<freeListingsAutoTaggingEnabled: bool>, cssId: string, googleMyBusinessLink: record<gmbAccountId: string, gmbEmail: string, status: string>, id: string, kind: string, labelIds: list<string>, name: string, sellerId: string, users: table<admin: bool, emailAddress: string, orderManager: bool, paymentsAnalyst: bool, paymentsManager: bool, reportingManager: bool>, websiteUrl: string, youtubeChannelLinks: table<channelId: string, status: string>>
# operationId: content.accounts.insert
export def "content-accounts-insert" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --ads-links: list # Linked Ads accounts that are active or pending approval. To create a new link request, add a new link with status `active` to the list. It will remain in a `pending` state until approved or rejected either in the Ads interface or through the Google Ads API. To delete an active link, or to cancel a link request, remove it from the list. — item shape: {adsId?: string, status?: string}
  --adult-content: oneof<nothing, bool> # Indicates whether the merchant sells adult content.
  --automatic-improvements: record # The automatic improvements of the account can be used to automatically update items, improve images and shipping. — shape: {imageImprovements?: record, itemUpdates?: record, shippingImprovements?: record}
  --automatic-label-ids: list<string> # Automatically created label IDs that are assigned to the account by CSS Center.
  --business-information: record # shape: {address?: record, customerService?: record, koreanBusinessRegistrationNumber?: string, phoneNumber?: string, phoneVerificationStatus?: string}
  --conversion-settings: record # Settings for conversion tracking. — shape: {freeListingsAutoTaggingEnabled?: bool}
  --css-id: string # ID of CSS the account belongs to. (format: uint64)
  --google-my-business-link: record # shape: {gmbAccountId?: string, gmbEmail?: string, status?: string}
  --id: string # Required. 64-bit Merchant Center account ID. (format: uint64)
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "`content#account`".
  --label-ids: list<string> # Manually created label IDs that are assigned to the account by CSS.
  --name: string # Required. Display name for the account.
  --seller-id: string # Client-specific, locally-unique, internal ID for the child account.
  --users: list # Users with access to the account. Every account (except for subaccounts) must have at least one admin user. — item shape: {admin?: bool, emailAddress?: string, orderManager?: bool, paymentsAnalyst?: bool, paymentsManager?: bool, reportingManager?: bool}
  --website-url: string # The merchant's website.
  --youtube-channel-links: list # Linked YouTube channels that are active or pending approval. To create a new link request, add a new link with status `active` to the list. It will remain in a `pending` state until approved or rejected in the YT Creator Studio interface. To delete an active link, or to cancel a link request, remove it from the list. — item shape: {channelId?: string, status?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/accounts"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: adsLinks, var: ads_links}, {name: adultContent, var: adult_content}, {name: automaticImprovements, var: automatic_improvements}, {name: automaticLabelIds, var: automatic_label_ids}, {name: businessInformation, var: business_information}, {name: conversionSettings, var: conversion_settings}, {name: cssId, var: css_id}, {name: googleMyBusinessLink, var: google_my_business_link}, {name: id, var: id}, {name: kind, var: kind}, {name: labelIds, var: label_ids}, {name: name, var: name}, {name: sellerId, var: seller_id}, {name: users, var: users}, {name: websiteUrl, var: website_url}, {name: youtubeChannelLinks, var: youtube_channel_links}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, ads_links: $ads_links, adult_content: $adult_content, automatic_improvements: $automatic_improvements, automatic_label_ids: $automatic_label_ids, business_information: $business_information, conversion_settings: $conversion_settings, css_id: $css_id, google_my_business_link: $google_my_business_link, id: $id, kind: $kind, label_ids: $label_ids, name: $name, seller_id: $seller_id, users: $users, website_url: $website_url, youtube_channel_links: $youtube_channel_links
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Merchant Center sub-account.
#
# DELETE /{merchantId}/accounts/{accountId}
# operationId: content.accounts.delete
export def "content-accounts-delete" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --force: oneof<nothing, bool> # Option to delete sub-accounts with products. The default value is false.
]: nothing -> any {
  http-request {
    method: delete
    path: "/{merchantId}/accounts/{accountId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: accountId, var: account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: force, var: force}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, account_id: $account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, force: $force
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a Merchant Center account.
#
# GET /{merchantId}/accounts/{accountId}
# Returns: record<accountManagement: string, adsLinks: table<adsId: string, status: string>, adultContent: bool, automaticImprovements: record<imageImprovements: record<accountImageImprovementsSettings: record, effectiveAllowAutomaticImageImprovements: bool>, itemUpdates: record<accountItemUpdatesSettings: record, effectiveAllowAvailabilityUpdates: bool, effectiveAllowConditionUpdates: bool, effectiveAllowPriceUpdates: bool, effectiveAllowStrictAvailabilityUpdates: bool>, shippingImprovements: record<allowShippingImprovements: bool>>, automaticLabelIds: list<string>, businessInformation: record<address: record<country: string, locality: string, postalCode: string, region: string, streetAddress: string>, customerService: record<email: string, phoneNumber: string, url: string>, koreanBusinessRegistrationNumber: string, phoneNumber: string, phoneVerificationStatus: string>, conversionSettings: record<freeListingsAutoTaggingEnabled: bool>, cssId: string, googleMyBusinessLink: record<gmbAccountId: string, gmbEmail: string, status: string>, id: string, kind: string, labelIds: list<string>, name: string, sellerId: string, users: table<admin: bool, emailAddress: string, orderManager: bool, paymentsAnalyst: bool, paymentsManager: bool, reportingManager: bool>, websiteUrl: string, youtubeChannelLinks: table<channelId: string, status: string>>
# operationId: content.accounts.get
export def "content-accounts-get" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --view: string@view-completer # Controls which fields will be populated. Acceptable values are: "merchant" and "css". The default value is "merchant".
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/accounts/{accountId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: accountId, var: account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, account_id: $account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a Merchant Center account. Any fields that are not provided are deleted from the resource.
#
# PUT /{merchantId}/accounts/{accountId}
# Returns: record<accountManagement: string, adsLinks: table<adsId: string, status: string>, adultContent: bool, automaticImprovements: record<imageImprovements: record<accountImageImprovementsSettings: record, effectiveAllowAutomaticImageImprovements: bool>, itemUpdates: record<accountItemUpdatesSettings: record, effectiveAllowAvailabilityUpdates: bool, effectiveAllowConditionUpdates: bool, effectiveAllowPriceUpdates: bool, effectiveAllowStrictAvailabilityUpdates: bool>, shippingImprovements: record<allowShippingImprovements: bool>>, automaticLabelIds: list<string>, businessInformation: record<address: record<country: string, locality: string, postalCode: string, region: string, streetAddress: string>, customerService: record<email: string, phoneNumber: string, url: string>, koreanBusinessRegistrationNumber: string, phoneNumber: string, phoneVerificationStatus: string>, conversionSettings: record<freeListingsAutoTaggingEnabled: bool>, cssId: string, googleMyBusinessLink: record<gmbAccountId: string, gmbEmail: string, status: string>, id: string, kind: string, labelIds: list<string>, name: string, sellerId: string, users: table<admin: bool, emailAddress: string, orderManager: bool, paymentsAnalyst: bool, paymentsManager: bool, reportingManager: bool>, websiteUrl: string, youtubeChannelLinks: table<channelId: string, status: string>>
# operationId: content.accounts.update
export def "content-accounts-update" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --ads-links: list # Linked Ads accounts that are active or pending approval. To create a new link request, add a new link with status `active` to the list. It will remain in a `pending` state until approved or rejected either in the Ads interface or through the Google Ads API. To delete an active link, or to cancel a link request, remove it from the list. — item shape: {adsId?: string, status?: string}
  --adult-content: oneof<nothing, bool> # Indicates whether the merchant sells adult content.
  --automatic-improvements: record # The automatic improvements of the account can be used to automatically update items, improve images and shipping. — shape: {imageImprovements?: record, itemUpdates?: record, shippingImprovements?: record}
  --automatic-label-ids: list<string> # Automatically created label IDs that are assigned to the account by CSS Center.
  --business-information: record # shape: {address?: record, customerService?: record, koreanBusinessRegistrationNumber?: string, phoneNumber?: string, phoneVerificationStatus?: string}
  --conversion-settings: record # Settings for conversion tracking. — shape: {freeListingsAutoTaggingEnabled?: bool}
  --css-id: string # ID of CSS the account belongs to. (format: uint64)
  --google-my-business-link: record # shape: {gmbAccountId?: string, gmbEmail?: string, status?: string}
  --id: string # Required. 64-bit Merchant Center account ID. (format: uint64)
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "`content#account`".
  --label-ids: list<string> # Manually created label IDs that are assigned to the account by CSS.
  --name: string # Required. Display name for the account.
  --seller-id: string # Client-specific, locally-unique, internal ID for the child account.
  --users: list # Users with access to the account. Every account (except for subaccounts) must have at least one admin user. — item shape: {admin?: bool, emailAddress?: string, orderManager?: bool, paymentsAnalyst?: bool, paymentsManager?: bool, reportingManager?: bool}
  --website-url: string # The merchant's website.
  --youtube-channel-links: list # Linked YouTube channels that are active or pending approval. To create a new link request, add a new link with status `active` to the list. It will remain in a `pending` state until approved or rejected in the YT Creator Studio interface. To delete an active link, or to cancel a link request, remove it from the list. — item shape: {channelId?: string, status?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{merchantId}/accounts/{accountId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: accountId, var: account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: adsLinks, var: ads_links}, {name: adultContent, var: adult_content}, {name: automaticImprovements, var: automatic_improvements}, {name: automaticLabelIds, var: automatic_label_ids}, {name: businessInformation, var: business_information}, {name: conversionSettings, var: conversion_settings}, {name: cssId, var: css_id}, {name: googleMyBusinessLink, var: google_my_business_link}, {name: id, var: id}, {name: kind, var: kind}, {name: labelIds, var: label_ids}, {name: name, var: name}, {name: sellerId, var: seller_id}, {name: users, var: users}, {name: websiteUrl, var: website_url}, {name: youtubeChannelLinks, var: youtube_channel_links}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, account_id: $account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, ads_links: $ads_links, adult_content: $adult_content, automatic_improvements: $automatic_improvements, automatic_label_ids: $automatic_label_ids, business_information: $business_information, conversion_settings: $conversion_settings, css_id: $css_id, google_my_business_link: $google_my_business_link, id: $id, kind: $kind, label_ids: $label_ids, name: $name, seller_id: $seller_id, users: $users, website_url: $website_url, youtube_channel_links: $youtube_channel_links
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Claims the website of a Merchant Center sub-account. Merchant accounts with approved third-party CSSs aren't required to claim a website.
#
# POST /{merchantId}/accounts/{accountId}/claimwebsite
# Returns: record<kind: string>
# operationId: content.accounts.claimwebsite
export def "content-accounts-claimwebsite" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --overwrite: oneof<nothing, bool> # Only available to selected merchants, for example multi-client accounts (MCAs) and their sub-accounts. When set to `True`, this option removes any existing claim on the requested website and replaces it with a claim from the account that makes the request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/{merchantId}/accounts/{accountId}/claimwebsite"
    path_params: [{name: merchantId, var: merchant_id}, {name: accountId, var: account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: overwrite, var: overwrite}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, account_id: $account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, overwrite: $overwrite
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Performs an action on a link between two Merchant Center accounts, namely accountId and linkedAccountId.
#
# POST /{merchantId}/accounts/{accountId}/link
# Returns: record<kind: string>
# operationId: content.accounts.link
export def "content-accounts-link" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --action: string # Action to perform for this link. The `"request"` action is only available to select merchants. Acceptable values are: - "`approve`" - "`remove`" - "`request`"
  --e-commerce-platform-link-info: record # Additional information required for E_COMMERCE_PLATFORM link type. — shape: {externalAccountId?: string}
  --link-type: string # Type of the link between the two accounts. Acceptable values are: - "`channelPartner`" - "`eCommercePlatform`" - "`paymentServiceProvider`"
  --linked-account-id: string # The ID of the linked account.
  --payment-service-provider-link-info: record # Additional information required for PAYMENT_SERVICE_PROVIDER link type. — shape: {externalAccountBusinessCountry?: string, externalAccountId?: string}
  --services: list<string> # Acceptable values are: - "`shoppingAdsProductManagement`" - "`shoppingActionsProductManagement`" - "`shoppingActionsOrderManagement`" - "`paymentProcessing`"
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/accounts/{accountId}/link"
    path_params: [{name: merchantId, var: merchant_id}, {name: accountId, var: account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: eCommercePlatformLinkInfo, var: e_commerce_platform_link_info}, {name: linkType, var: link_type}, {name: linkedAccountId, var: linked_account_id}, {name: paymentServiceProviderLinkInfo, var: payment_service_provider_link_info}, {name: services, var: services}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, account_id: $account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, action: $action, e_commerce_platform_link_info: $e_commerce_platform_link_info, link_type: $link_type, linked_account_id: $linked_account_id, payment_service_provider_link_info: $payment_service_provider_link_info, services: $services
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of accounts linked to your Merchant Center account.
#
# GET /{merchantId}/accounts/{accountId}/listlinks
# Returns: record<kind: string, links: table<linkedAccountId: string, services: list>, nextPageToken: string>
# operationId: content.accounts.listlinks
export def "content-accounts-listlinks" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --max-results: int # The maximum number of links to return in the response, used for pagination. The minimum allowed value is 5 results per page. If provided value is lower than 5, it will be automatically increased to 5.
  --page-token: string # The token returned by the previous request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/accounts/{accountId}/listlinks"
    path_params: [{name: merchantId, var: merchant_id}, {name: accountId, var: account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, account_id: $account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, max_results: $max_results, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request verification code to start phone verification.
#
# POST /{merchantId}/accounts/{accountId}/requestphoneverification
# Returns: record<verificationId: string>
# operationId: content.accounts.requestphoneverification
export def "content-accounts-requestphoneverification" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --language-code: string # Language code [IETF BCP 47 syntax](https://tools.ietf.org/html/bcp47) (for example, en-US). Language code is used to provide localized `SMS` and `PHONE_CALL`. Default language used is en-US if not provided.
  --phone-number: string # Phone number to be verified.
  --phone-region-code: string # Required. Two letter country code for the phone number, for example `CA` for Canadian numbers. See the [ISO 3166-1 alpha-2](https://wikipedia.org/wiki/ISO_3166-1_alpha-2#Officially_assigned_code_elements) officially assigned codes.
  --phone-verification-method: string@phone-verification-method-completer # Verification method to receive verification code.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/accounts/{accountId}/requestphoneverification"
    path_params: [{name: merchantId, var: merchant_id}, {name: accountId, var: account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: languageCode, var: language_code}, {name: phoneNumber, var: phone_number}, {name: phoneRegionCode, var: phone_region_code}, {name: phoneVerificationMethod, var: phone_verification_method}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, account_id: $account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, language_code: $language_code, phone_number: $phone_number, phone_region_code: $phone_region_code, phone_verification_method: $phone_verification_method
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates labels that are assigned to the Merchant Center account by CSS user.
#
# POST /{merchantId}/accounts/{accountId}/updatelabels
# Returns: record<kind: string>
# operationId: content.accounts.updatelabels
export def "content-accounts-updatelabels" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --label-ids: list<string> # The IDs of labels that should be assigned to the account.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/accounts/{accountId}/updatelabels"
    path_params: [{name: merchantId, var: merchant_id}, {name: accountId, var: account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: labelIds, var: label_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, account_id: $account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, label_ids: $label_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validates verification code to verify phone number for the account. If successful this will overwrite the value of `accounts.businessinformation.phoneNumber`. Only verified phone number will replace an existing verified phone number.
#
# POST /{merchantId}/accounts/{accountId}/verifyphonenumber
# Returns: record<verifiedPhoneNumber: string>
# operationId: content.accounts.verifyphonenumber
export def "content-accounts-verifyphonenumber" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --phone-verification-method: string@phone-verification-method-completer # Verification method used to receive verification code.
  --verification-code: string # The verification code that was sent to the phone number for validation.
  --verification-id: string # The verification ID returned by `requestphoneverification`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/accounts/{accountId}/verifyphonenumber"
    path_params: [{name: merchantId, var: merchant_id}, {name: accountId, var: account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: phoneVerificationMethod, var: phone_verification_method}, {name: verificationCode, var: verification_code}, {name: verificationId, var: verification_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, account_id: $account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, phone_verification_method: $phone_verification_method, verification_code: $verification_code, verification_id: $verification_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the statuses of the sub-accounts in your Merchant Center account.
#
# GET /{merchantId}/accountstatuses
# Returns: record<kind: string, nextPageToken: string, resources: table<accountId: string, accountLevelIssues: list, accountManagement: string, kind: string, products: list, websiteClaimed: bool>>
# operationId: content.accountstatuses.list
export def "content-accountstatuses-list" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --destinations: list<string> # If set, only issues for the specified destinations are returned, otherwise only issues for the Shopping destination.
  --max-results: int # The maximum number of account statuses to return in the response, used for paging.
  --name: string # If set, only the accounts with the given name (case sensitive) will be returned.
  --page-token: string # The token returned by the previous request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/accountstatuses"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: destinations, var: destinations, style: multi}, {name: maxResults, var: max_results}, {name: name, var: name}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, destinations: $destinations, max_results: $max_results, name: $name, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the status of a Merchant Center account. No itemLevelIssues are returned for multi-client accounts.
#
# GET /{merchantId}/accountstatuses/{accountId}
# Returns: record<accountId: string, accountLevelIssues: table<country: string, destination: string, detail: string, documentation: string, id: string, severity: string, title: string>, accountManagement: string, kind: string, products: table<channel: string, country: string, destination: string, itemLevelIssues: list, statistics: record>, websiteClaimed: bool>
# operationId: content.accountstatuses.get
export def "content-accountstatuses-get" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --destinations: list<string> # If set, only issues for the specified destinations are returned, otherwise only issues for the Shopping destination.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/accountstatuses/{accountId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: accountId, var: account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: destinations, var: destinations, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, account_id: $account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, destinations: $destinations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the tax settings of the sub-accounts in your Merchant Center account.
#
# GET /{merchantId}/accounttax
# Returns: record<kind: string, nextPageToken: string, resources: table<accountId: string, kind: string, rules: list>>
# operationId: content.accounttax.list
export def "content-accounttax-list" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --max-results: int # The maximum number of tax settings to return in the response, used for paging.
  --page-token: string # The token returned by the previous request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/accounttax"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, max_results: $max_results, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the tax settings of the account.
#
# GET /{merchantId}/accounttax/{accountId}
# Returns: record<accountId: string, kind: string, rules: table<country: string, locationId: string, ratePercent: string, shippingTaxed: bool, useGlobalRate: bool>>
# operationId: content.accounttax.get
export def "content-accounttax-get" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/accounttax/{accountId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: accountId, var: account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, account_id: $account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the tax settings of the account. Any fields that are not provided are deleted from the resource.
#
# PUT /{merchantId}/accounttax/{accountId}
# Returns: record<accountId: string, kind: string, rules: table<country: string, locationId: string, ratePercent: string, shippingTaxed: bool, useGlobalRate: bool>>
# operationId: content.accounttax.update
export def "content-accounttax-update" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-account-id: string # Required. The ID of the account to which these account tax settings belong. (format: uint64) (spec name: accountId)
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "`content#accountTax`".
  --rules: list # Tax rules. Updating the tax rules will enable "US" taxes (not reversible). Defining no rules is equivalent to not charging tax at all. — item shape: {country?: string, locationId?: string, ratePercent?: string, shippingTaxed?: bool, useGlobalRate?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{merchantId}/accounttax/{accountId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: accountId, var: account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: kind, var: kind}, {name: rules, var: rules}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, account_id: $account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body_account_id: $body_account_id, kind: $kind, rules: $rules
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a status of the BoG program for your Merchant Center account.
#
# GET /{merchantId}/buyongoogleprograms/{regionCode}
# Returns: record<businessModel: list<string>, customerServicePendingEmail: string, customerServicePendingPhoneNumber: string, customerServicePendingPhoneRegionCode: string, customerServiceVerifiedEmail: string, customerServiceVerifiedPhoneNumber: string, customerServiceVerifiedPhoneRegionCode: string, onlineSalesChannel: string, participationStage: string>
# operationId: content.buyongoogleprograms.get
export def "content-buyongoogleprograms-get" [
  merchant_id: string
  region_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/buyongoogleprograms/{regionCode}"
    path_params: [{name: merchantId, var: merchant_id}, {name: regionCode, var: region_code}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, region_code: $region_code, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the status of the BoG program for your Merchant Center account.
#
# PATCH /{merchantId}/buyongoogleprograms/{regionCode}
# Returns: record<businessModel: list<string>, customerServicePendingEmail: string, customerServicePendingPhoneNumber: string, customerServicePendingPhoneRegionCode: string, customerServiceVerifiedEmail: string, customerServiceVerifiedPhoneNumber: string, customerServiceVerifiedPhoneRegionCode: string, onlineSalesChannel: string, participationStage: string>
# operationId: content.buyongoogleprograms.patch
export def "content-buyongoogleprograms-patch" [
  merchant_id: string
  region_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --update-mask: string # The list of fields to update. If the update mask is not provided, then all the fields set in buyOnGoogleProgramStatus will be updated. Clearing fields is only possible if update mask is provided.
  --business-model: list<string> # The business models in which merchant participates.
  --customer-service-pending-email: string # The customer service pending email. After verification this field becomes empty.
  --customer-service-pending-phone-number: string # The pending phone number specified for BuyOnGoogle program. It might be different than account level phone number. In order to update this field the customer_service_pending_phone_region_code must also be set. After verification this field becomes empty.
  --customer-service-pending-phone-region-code: string # Two letter country code for the pending phone number, for example `CA` for Canadian numbers. See the [ISO 3166-1 alpha-2](https://wikipedia.org/wiki/ISO_3166-1_alpha-2#Officially_assigned_code_elements) officially assigned codes. In order to update this field the customer_service_pending_phone_number must also be set. After verification this field becomes empty.
  --online-sales-channel: string@online-sales-channel-completer # The channels through which the merchant is selling.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/{merchantId}/buyongoogleprograms/{regionCode}"
    path_params: [{name: merchantId, var: merchant_id}, {name: regionCode, var: region_code}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: businessModel, var: business_model}, {name: customerServicePendingEmail, var: customer_service_pending_email}, {name: customerServicePendingPhoneNumber, var: customer_service_pending_phone_number}, {name: customerServicePendingPhoneRegionCode, var: customer_service_pending_phone_region_code}, {name: onlineSalesChannel, var: online_sales_channel}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, region_code: $region_code, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, update_mask: $update_mask, business_model: $business_model, customer_service_pending_email: $customer_service_pending_email, customer_service_pending_phone_number: $customer_service_pending_phone_number, customer_service_pending_phone_region_code: $customer_service_pending_phone_region_code, online_sales_channel: $online_sales_channel
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reactivates the BoG program in your Merchant Center account. Moves the program to the active state when allowed, for example, when paused. This method is only available to selected merchants.
#
# POST /{merchantId}/buyongoogleprograms/{regionCode}/activate
# operationId: content.buyongoogleprograms.activate
export def "content-buyongoogleprograms-activate" [
  merchant_id: string
  region_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/{merchantId}/buyongoogleprograms/{regionCode}/activate"
    path_params: [{name: merchantId, var: merchant_id}, {name: regionCode, var: region_code}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, region_code: $region_code, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Onboards the BoG program in your Merchant Center account. By using this method, you agree to the [Terms of Service](https://merchants.google.com/mc/termsofservice/transactions/US/latest). Calling this method is only possible if the authenticated account is the same as the merchant id in the request. Calling this method multiple times will only accept Terms of Service if the latest version is not currently signed.
#
# POST /{merchantId}/buyongoogleprograms/{regionCode}/onboard
# operationId: content.buyongoogleprograms.onboard
export def "content-buyongoogleprograms-onboard" [
  merchant_id: string
  region_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --customer-service-email: string # The customer service email.
]: any -> any {
  $in | http-request {
    method: post
    path: "/{merchantId}/buyongoogleprograms/{regionCode}/onboard"
    path_params: [{name: merchantId, var: merchant_id}, {name: regionCode, var: region_code}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: customerServiceEmail, var: customer_service_email}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, region_code: $region_code, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, customer_service_email: $customer_service_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Pauses the BoG program in your Merchant Center account. This method is only available to selected merchants.
#
# POST /{merchantId}/buyongoogleprograms/{regionCode}/pause
# operationId: content.buyongoogleprograms.pause
export def "content-buyongoogleprograms-pause" [
  merchant_id: string
  region_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/{merchantId}/buyongoogleprograms/{regionCode}/pause"
    path_params: [{name: merchantId, var: merchant_id}, {name: regionCode, var: region_code}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, region_code: $region_code, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Requests review and then activates the BoG program in your Merchant Center account for the first time. Moves the program to the REVIEW_PENDING state. This method is only available to selected merchants.
#
# POST /{merchantId}/buyongoogleprograms/{regionCode}/requestreview
# operationId: content.buyongoogleprograms.requestreview
export def "content-buyongoogleprograms-requestreview" [
  merchant_id: string
  region_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/{merchantId}/buyongoogleprograms/{regionCode}/requestreview"
    path_params: [{name: merchantId, var: merchant_id}, {name: regionCode, var: region_code}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, region_code: $region_code, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the collections in your Merchant Center account. The response might contain fewer items than specified by page_size. Rely on next_page_token to determine if there are more items to be requested.
#
# GET /{merchantId}/collections
# Returns: record<nextPageToken: string, resources: table<customLabel0: string, customLabel1: string, customLabel2: string, customLabel3: string, customLabel4: string, featuredProduct: list, headline: list, id: string, imageLink: list, language: string, link: string, mobileLink: string, productCountry: string>>
# operationId: content.collections.list
export def "content-collections-list" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # The maximum number of collections to return in the response, used for paging. Defaults to 50; values above 1000 will be coerced to 1000.
  --page-token: string # Token (if provided) to retrieve the subsequent page. All other parameters must match the original call that provided the page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/collections"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uploads a collection to your Merchant Center account. If a collection with the same collectionId already exists, this method updates that entry. In each update, the collection is completely replaced by the fields in the body of the update request.
#
# POST /{merchantId}/collections
# Returns: record<customLabel0: string, customLabel1: string, customLabel2: string, customLabel3: string, customLabel4: string, featuredProduct: table<offerId: string, x: float, y: float>, headline: list<string>, id: string, imageLink: list<string>, language: string, link: string, mobileLink: string, productCountry: string>
# operationId: content.collections.create
export def "content-collections-create" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --custom-label0: string # Label that you assign to a collection to help organize bidding and reporting in Shopping campaigns. [Custom label](https://support.google.com/merchants/answer/9674217)
  --custom-label1: string # Label that you assign to a collection to help organize bidding and reporting in Shopping campaigns.
  --custom-label2: string # Label that you assign to a collection to help organize bidding and reporting in Shopping campaigns.
  --custom-label3: string # Label that you assign to a collection to help organize bidding and reporting in Shopping campaigns.
  --custom-label4: string # Label that you assign to a collection to help organize bidding and reporting in Shopping campaigns.
  --featured-product: list # This identifies one or more products associated with the collection. Used as a lookup to the corresponding product ID in your product feeds. Provide a maximum of 100 featuredProduct (for collections). Provide up to 10 featuredProduct (for Shoppable Images only) with ID and X and Y coordinates. [featured_product attribute](https://support.google.com/merchants/answer/9703736) — item shape: {offerId?: string, x?: float, y?: float}
  --headline: list<string> # Your collection's name. [headline attribute](https://support.google.com/merchants/answer/9673580)
  --id: string # Required. The REST ID of the collection. Content API methods that operate on collections take this as their collectionId parameter. The REST ID for a collection is of the form collectionId. [id attribute](https://support.google.com/merchants/answer/9649290)
  --image-link: list<string> # The URL of a collection’s image. [image_link attribute](https://support.google.com/merchants/answer/9703236)
  --language: string # The language of a collection and the language of any featured products linked to the collection. [language attribute](https://support.google.com/merchants/answer/9673781)
  --link: string # A collection’s landing page. URL directly linking to your collection's page on your website. [link attribute](https://support.google.com/merchants/answer/9673983)
  --mobile-link: string # A collection’s mobile-optimized landing page when you have a different URL for mobile and desktop traffic. [mobile_link attribute](https://support.google.com/merchants/answer/9646123)
  --product-country: string # [product_country attribute](https://support.google.com/merchants/answer/9674155)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/collections"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: customLabel0, var: custom_label0}, {name: customLabel1, var: custom_label1}, {name: customLabel2, var: custom_label2}, {name: customLabel3, var: custom_label3}, {name: customLabel4, var: custom_label4}, {name: featuredProduct, var: featured_product}, {name: headline, var: headline}, {name: id, var: id}, {name: imageLink, var: image_link}, {name: language, var: language}, {name: link, var: link}, {name: mobileLink, var: mobile_link}, {name: productCountry, var: product_country}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, custom_label0: $custom_label0, custom_label1: $custom_label1, custom_label2: $custom_label2, custom_label3: $custom_label3, custom_label4: $custom_label4, featured_product: $featured_product, headline: $headline, id: $id, image_link: $image_link, language: $language, link: $link, mobile_link: $mobile_link, product_country: $product_country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a collection from your Merchant Center account.
#
# DELETE /{merchantId}/collections/{collectionId}
# operationId: content.collections.delete
export def "content-collections-delete" [
  merchant_id: string
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> any {
  http-request {
    method: delete
    path: "/{merchantId}/collections/{collectionId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: collectionId, var: collection_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, collection_id: $collection_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a collection from your Merchant Center account.
#
# GET /{merchantId}/collections/{collectionId}
# Returns: record<customLabel0: string, customLabel1: string, customLabel2: string, customLabel3: string, customLabel4: string, featuredProduct: table<offerId: string, x: float, y: float>, headline: list<string>, id: string, imageLink: list<string>, language: string, link: string, mobileLink: string, productCountry: string>
# operationId: content.collections.get
export def "content-collections-get" [
  merchant_id: string
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/collections/{collectionId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: collectionId, var: collection_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, collection_id: $collection_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the statuses of the collections in your Merchant Center account.
#
# GET /{merchantId}/collectionstatuses
# Returns: record<nextPageToken: string, resources: table<collectionLevelIssuses: list, creationDate: string, destinationStatuses: list, id: string, lastUpdateDate: string>>
# operationId: content.collectionstatuses.list
export def "content-collectionstatuses-list" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # The maximum number of collection statuses to return in the response, used for paging. Defaults to 50; values above 1000 will be coerced to 1000.
  --page-token: string # Token (if provided) to retrieve the subsequent page. All other parameters must match the original call that provided the page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/collectionstatuses"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the status of a collection from your Merchant Center account.
#
# GET /{merchantId}/collectionstatuses/{collectionId}
# Returns: record<collectionLevelIssuses: table<applicableCountries: list, attributeName: string, code: string, description: string, destination: string, detail: string, documentation: string, resolution: string, servability: string>, creationDate: string, destinationStatuses: table<approvedCountries: list, destination: string, disapprovedCountries: list, pendingCountries: list, status: string>, id: string, lastUpdateDate: string>
# operationId: content.collectionstatuses.get
export def "content-collectionstatuses-get" [
  merchant_id: string
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/collectionstatuses/{collectionId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: collectionId, var: collection_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, collection_id: $collection_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the list of conversion sources the caller has access to.
#
# GET /{merchantId}/conversionsources
# Returns: record<conversionSources: table<conversionSourceId: string, expireTime: string, googleAnalyticsLink: record, merchantCenterDestination: record, state: string>, nextPageToken: string>
# operationId: content.conversionsources.list
export def "content-conversionsources-list" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # The maximum number of conversion sources to return in a page. If no `page_size` is specified, `100` is used as the default value. The maximum value is `200`. Values above `200` will be coerced to `200`. Regardless of pagination, at most `200` conversion sources are returned in total.
  --page-token: string # Page token.
  --show-deleted: oneof<nothing, bool> # If true, also returns archived conversion sources.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/conversionsources"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: showDeleted, var: show_deleted}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token, show_deleted: $show_deleted
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new conversion source.
#
# POST /{merchantId}/conversionsources
# Returns: record<conversionSourceId: string, expireTime: string, googleAnalyticsLink: record<attributionSettings: record<attributionLookbackWindowInDays: int, attributionModel: string, conversionType: list>, propertyId: string, propertyName: string>, merchantCenterDestination: record<attributionSettings: record<attributionLookbackWindowInDays: int, attributionModel: string, conversionType: list>, currencyCode: string, destinationId: string, displayName: string>, state: string>
# operationId: content.conversionsources.create
export def "content-conversionsources-create" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --google-analytics-link: record # "Google Analytics Link" sources can be used to get conversion data from an existing Google Analytics property into the linked Merchant Center account. — shape: {attributionSettings?: record, propertyId?: string}
  --merchant-center-destination: record # "Merchant Center Destination" sources can be used to send conversion events from a website using a Google tag directly to a Merchant Center account where the source is created. — shape: {attributionSettings?: record, currencyCode?: string, displayName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/conversionsources"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: googleAnalyticsLink, var: google_analytics_link}, {name: merchantCenterDestination, var: merchant_center_destination}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, google_analytics_link: $google_analytics_link, merchant_center_destination: $merchant_center_destination
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Archives an existing conversion source. It will be recoverable for 30 days. This archiving behavior is not typical in the Content API and unique to this service.
#
# DELETE /{merchantId}/conversionsources/{conversionSourceId}
# operationId: content.conversionsources.delete
export def "content-conversionsources-delete" [
  merchant_id: string
  conversion_source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> any {
  http-request {
    method: delete
    path: "/{merchantId}/conversionsources/{conversionSourceId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: conversionSourceId, var: conversion_source_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, conversion_source_id: $conversion_source_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches a conversion source.
#
# GET /{merchantId}/conversionsources/{conversionSourceId}
# Returns: record<conversionSourceId: string, expireTime: string, googleAnalyticsLink: record<attributionSettings: record<attributionLookbackWindowInDays: int, attributionModel: string, conversionType: list>, propertyId: string, propertyName: string>, merchantCenterDestination: record<attributionSettings: record<attributionLookbackWindowInDays: int, attributionModel: string, conversionType: list>, currencyCode: string, destinationId: string, displayName: string>, state: string>
# operationId: content.conversionsources.get
export def "content-conversionsources-get" [
  merchant_id: string
  conversion_source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/conversionsources/{conversionSourceId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: conversionSourceId, var: conversion_source_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, conversion_source_id: $conversion_source_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates information of an existing conversion source.
#
# PATCH /{merchantId}/conversionsources/{conversionSourceId}
# Returns: record<conversionSourceId: string, expireTime: string, googleAnalyticsLink: record<attributionSettings: record<attributionLookbackWindowInDays: int, attributionModel: string, conversionType: list>, propertyId: string, propertyName: string>, merchantCenterDestination: record<attributionSettings: record<attributionLookbackWindowInDays: int, attributionModel: string, conversionType: list>, currencyCode: string, destinationId: string, displayName: string>, state: string>
# operationId: content.conversionsources.patch
export def "content-conversionsources-patch" [
  merchant_id: string
  conversion_source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --update-mask: string # Required. List of fields being updated.
  --google-analytics-link: record # "Google Analytics Link" sources can be used to get conversion data from an existing Google Analytics property into the linked Merchant Center account. — shape: {attributionSettings?: record, propertyId?: string}
  --merchant-center-destination: record # "Merchant Center Destination" sources can be used to send conversion events from a website using a Google tag directly to a Merchant Center account where the source is created. — shape: {attributionSettings?: record, currencyCode?: string, displayName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/{merchantId}/conversionsources/{conversionSourceId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: conversionSourceId, var: conversion_source_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: googleAnalyticsLink, var: google_analytics_link}, {name: merchantCenterDestination, var: merchant_center_destination}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, conversion_source_id: $conversion_source_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, update_mask: $update_mask, google_analytics_link: $google_analytics_link, merchant_center_destination: $merchant_center_destination
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Re-enables an archived conversion source.
#
# POST /{merchantId}/conversionsources/{conversionSourceId}:undelete
# operationId: content.conversionsources.undelete
export def "content-conversionsources-undelete" [
  merchant_id: string
  conversion_source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/{merchantId}/conversionsources/{conversionSourceId}:undelete"
    path_params: [{name: merchantId, var: merchant_id}, {name: conversionSourceId, var: conversion_source_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, conversion_source_id: $conversion_source_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the configurations for datafeeds in your Merchant Center account.
#
# GET /{merchantId}/datafeeds
# Returns: record<kind: string, nextPageToken: string, resources: table<attributeLanguage: string, contentType: string, fetchSchedule: record, fileName: string, format: record, id: string, kind: string, name: string, targets: list>>
# operationId: content.datafeeds.list
export def "content-datafeeds-list" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --max-results: int # The maximum number of products to return in the response, used for paging.
  --page-token: string # The token returned by the previous request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/datafeeds"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, max_results: $max_results, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Registers a datafeed configuration with your Merchant Center account.
#
# POST /{merchantId}/datafeeds
# Returns: record<attributeLanguage: string, contentType: string, fetchSchedule: record<dayOfMonth: int, fetchUrl: string, hour: int, minuteOfHour: int, password: string, paused: bool, timeZone: string, username: string, weekday: string>, fileName: string, format: record<columnDelimiter: string, fileEncoding: string, quotingMode: string>, id: string, kind: string, name: string, targets: table<country: string, excludedDestinations: list, feedLabel: string, includedDestinations: list, language: string, targetCountries: list>>
# operationId: content.datafeeds.insert
export def "content-datafeeds-insert" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --attribute-language: string # The two-letter ISO 639-1 language in which the attributes are defined in the data feed.
  --content-type: string # Required. The type of data feed. For product inventory feeds, only feeds for local stores, not online stores, are supported. Acceptable values are: - "`local products`" - "`product inventory`" - "`products`"
  --fetch-schedule: record # The required fields vary based on the frequency of fetching. For a monthly fetch schedule, day_of_month and hour are required. For a weekly fetch schedule, weekday and hour are required. For a daily fetch schedule, only hour is required. — shape: {dayOfMonth?: int, fetchUrl?: string, hour?: int, minuteOfHour?: int, password?: string, paused?: bool, timeZone?: string, username?: string, weekday?: string}
  --file-name: string # Required. The filename of the feed. All feeds must have a unique file name.
  --format: record # shape: {columnDelimiter?: string, fileEncoding?: string, quotingMode?: string}
  --id: string # Required for update. The ID of the data feed. (format: int64)
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "`content#datafeed`"
  --name: string # Required for insert. A descriptive name of the data feed.
  --targets: list # The targets this feed should apply to (country, language, destinations). — item shape: {country?: string, excludedDestinations?: list<string>, feedLabel?: string, includedDestinations?: list<string>, language?: string, targetCountries?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/datafeeds"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributeLanguage, var: attribute_language}, {name: contentType, var: content_type}, {name: fetchSchedule, var: fetch_schedule}, {name: fileName, var: file_name}, {name: format, var: format}, {name: id, var: id}, {name: kind, var: kind}, {name: name, var: name}, {name: targets, var: targets}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, attribute_language: $attribute_language, content_type: $content_type, fetch_schedule: $fetch_schedule, file_name: $file_name, format: $format, id: $id, kind: $kind, name: $name, targets: $targets
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a datafeed configuration from your Merchant Center account.
#
# DELETE /{merchantId}/datafeeds/{datafeedId}
# operationId: content.datafeeds.delete
export def "content-datafeeds-delete" [
  merchant_id: string
  datafeed_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> any {
  http-request {
    method: delete
    path: "/{merchantId}/datafeeds/{datafeedId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: datafeedId, var: datafeed_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, datafeed_id: $datafeed_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a datafeed configuration from your Merchant Center account.
#
# GET /{merchantId}/datafeeds/{datafeedId}
# Returns: record<attributeLanguage: string, contentType: string, fetchSchedule: record<dayOfMonth: int, fetchUrl: string, hour: int, minuteOfHour: int, password: string, paused: bool, timeZone: string, username: string, weekday: string>, fileName: string, format: record<columnDelimiter: string, fileEncoding: string, quotingMode: string>, id: string, kind: string, name: string, targets: table<country: string, excludedDestinations: list, feedLabel: string, includedDestinations: list, language: string, targetCountries: list>>
# operationId: content.datafeeds.get
export def "content-datafeeds-get" [
  merchant_id: string
  datafeed_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/datafeeds/{datafeedId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: datafeedId, var: datafeed_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, datafeed_id: $datafeed_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a datafeed configuration of your Merchant Center account. Any fields that are not provided are deleted from the resource.
#
# PUT /{merchantId}/datafeeds/{datafeedId}
# Returns: record<attributeLanguage: string, contentType: string, fetchSchedule: record<dayOfMonth: int, fetchUrl: string, hour: int, minuteOfHour: int, password: string, paused: bool, timeZone: string, username: string, weekday: string>, fileName: string, format: record<columnDelimiter: string, fileEncoding: string, quotingMode: string>, id: string, kind: string, name: string, targets: table<country: string, excludedDestinations: list, feedLabel: string, includedDestinations: list, language: string, targetCountries: list>>
# operationId: content.datafeeds.update
export def "content-datafeeds-update" [
  merchant_id: string
  datafeed_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --attribute-language: string # The two-letter ISO 639-1 language in which the attributes are defined in the data feed.
  --content-type: string # Required. The type of data feed. For product inventory feeds, only feeds for local stores, not online stores, are supported. Acceptable values are: - "`local products`" - "`product inventory`" - "`products`"
  --fetch-schedule: record # The required fields vary based on the frequency of fetching. For a monthly fetch schedule, day_of_month and hour are required. For a weekly fetch schedule, weekday and hour are required. For a daily fetch schedule, only hour is required. — shape: {dayOfMonth?: int, fetchUrl?: string, hour?: int, minuteOfHour?: int, password?: string, paused?: bool, timeZone?: string, username?: string, weekday?: string}
  --file-name: string # Required. The filename of the feed. All feeds must have a unique file name.
  --format: record # shape: {columnDelimiter?: string, fileEncoding?: string, quotingMode?: string}
  --id: string # Required for update. The ID of the data feed. (format: int64)
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "`content#datafeed`"
  --name: string # Required for insert. A descriptive name of the data feed.
  --targets: list # The targets this feed should apply to (country, language, destinations). — item shape: {country?: string, excludedDestinations?: list<string>, feedLabel?: string, includedDestinations?: list<string>, language?: string, targetCountries?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{merchantId}/datafeeds/{datafeedId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: datafeedId, var: datafeed_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributeLanguage, var: attribute_language}, {name: contentType, var: content_type}, {name: fetchSchedule, var: fetch_schedule}, {name: fileName, var: file_name}, {name: format, var: format}, {name: id, var: id}, {name: kind, var: kind}, {name: name, var: name}, {name: targets, var: targets}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, datafeed_id: $datafeed_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, attribute_language: $attribute_language, content_type: $content_type, fetch_schedule: $fetch_schedule, file_name: $file_name, format: $format, id: $id, kind: $kind, name: $name, targets: $targets
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invokes a fetch for the datafeed in your Merchant Center account. If you need to call this method more than once per day, we recommend you use the [Products service](https://developers.google.com/shopping-content/reference/rest/v2.1/products) to update your product data.
#
# POST /{merchantId}/datafeeds/{datafeedId}/fetchNow
# Returns: record<kind: string>
# operationId: content.datafeeds.fetchnow
export def "content-datafeeds-fetchnow" [
  merchant_id: string
  datafeed_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/{merchantId}/datafeeds/{datafeedId}/fetchNow"
    path_params: [{name: merchantId, var: merchant_id}, {name: datafeedId, var: datafeed_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, datafeed_id: $datafeed_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the statuses of the datafeeds in your Merchant Center account.
#
# GET /{merchantId}/datafeedstatuses
# Returns: record<kind: string, nextPageToken: string, resources: table<country: string, datafeedId: string, errors: list, feedLabel: string, itemsTotal: string, itemsValid: string, kind: string, language: string, lastUploadDate: string, processingStatus: string, warnings: list>>
# operationId: content.datafeedstatuses.list
export def "content-datafeedstatuses-list" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --max-results: int # The maximum number of products to return in the response, used for paging.
  --page-token: string # The token returned by the previous request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/datafeedstatuses"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, max_results: $max_results, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the status of a datafeed from your Merchant Center account.
#
# GET /{merchantId}/datafeedstatuses/{datafeedId}
# Returns: record<country: string, datafeedId: string, errors: table<code: string, count: string, examples: list, message: string>, feedLabel: string, itemsTotal: string, itemsValid: string, kind: string, language: string, lastUploadDate: string, processingStatus: string, warnings: table<code: string, count: string, examples: list, message: string>>
# operationId: content.datafeedstatuses.get
export def "content-datafeedstatuses-get" [
  merchant_id: string
  datafeed_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --country: string # Deprecated. Use `feedLabel` instead. The country to get the datafeed status for. If this parameter is provided then `language` must also be provided. Note that this parameter is required for feeds targeting multiple countries and languages, since a feed may have a different status for each target.
  --feed-label: string # The feed label to get the datafeed status for. If this parameter is provided then `language` must also be provided. Note that this parameter is required for feeds targeting multiple countries and languages, since a feed may have a different status for each target.
  --language: string # The language to get the datafeed status for. If this parameter is provided then `country` must also be provided. Note that this parameter is required for feeds targeting multiple countries and languages, since a feed may have a different status for each target.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/datafeedstatuses/{datafeedId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: datafeedId, var: datafeed_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: country, var: country}, {name: feedLabel, var: feed_label}, {name: language, var: language}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, datafeed_id: $datafeed_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, country: $country, feed_label: $feed_label, language: $language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the status and review eligibility for the free listing program. Returns errors and warnings if they require action to resolve, will become disapprovals, or impact impressions. Use `accountstatuses` to view all issues for an account.
#
# GET /{merchantId}/freelistingsprogram
# Returns: record<globalState: string, regionStatuses: table<disapprovalDate: string, eligibilityStatus: string, onboardingIssues: list, regionCodes: list, reviewEligibilityStatus: string, reviewIneligibilityReason: string, reviewIneligibilityReasonDescription: string, reviewIneligibilityReasonDetails: record, reviewIssues: list>>
# operationId: content.freelistingsprogram.get
export def "content-freelistingsprogram-get" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/freelistingsprogram"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Requests a review of free listings in a specific region. This method is only available to selected merchants.
#
# POST /{merchantId}/freelistingsprogram/requestreview
# operationId: content.freelistingsprogram.requestreview
export def "content-freelistingsprogram-requestreview" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --region-code: string # The code [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) of the country for which review is to be requested.
]: any -> any {
  $in | http-request {
    method: post
    path: "/{merchantId}/freelistingsprogram/requestreview"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: regionCode, var: region_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, region_code: $region_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the LIA settings of the sub-accounts in your Merchant Center account.
#
# GET /{merchantId}/liasettings
# Returns: record<kind: string, nextPageToken: string, resources: table<accountId: string, countrySettings: list, kind: string>>
# operationId: content.liasettings.list
export def "content-liasettings-list" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --max-results: int # The maximum number of LIA settings to return in the response, used for paging.
  --page-token: string # The token returned by the previous request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/liasettings"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, max_results: $max_results, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the LIA settings of the account.
#
# GET /{merchantId}/liasettings/{accountId}
# Returns: record<accountId: string, countrySettings: table<about: record, country: string, hostedLocalStorefrontActive: bool, inventory: record, onDisplayToOrder: record, posDataProvider: record, storePickupActive: bool>, kind: string>
# operationId: content.liasettings.get
export def "content-liasettings-get" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/liasettings/{accountId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: accountId, var: account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, account_id: $account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the LIA settings of the account. Any fields that are not provided are deleted from the resource.
#
# PUT /{merchantId}/liasettings/{accountId}
# Returns: record<accountId: string, countrySettings: table<about: record, country: string, hostedLocalStorefrontActive: bool, inventory: record, onDisplayToOrder: record, posDataProvider: record, storePickupActive: bool>, kind: string>
# operationId: content.liasettings.update
export def "content-liasettings-update" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-account-id: string # The ID of the account to which these LIA settings belong. Ignored upon update, always present in get request responses. (format: uint64) (spec name: accountId)
  --country-settings: list # The LIA settings for each country. — item shape: {about?: record, country?: string, hostedLocalStorefrontActive?: bool, inventory?: record, onDisplayToOrder?: record, posDataProvider?: record, storePickupActive?: bool}
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "`content#liaSettings`"
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{merchantId}/liasettings/{accountId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: accountId, var: account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: countrySettings, var: country_settings}, {name: kind, var: kind}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, account_id: $account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body_account_id: $body_account_id, country_settings: $country_settings, kind: $kind
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the list of accessible Business Profiles.
#
# GET /{merchantId}/liasettings/{accountId}/accessiblegmbaccounts
# Returns: record<accountId: string, gmbAccounts: table<email: string, listingCount: string, name: string, type: string>, kind: string>
# operationId: content.liasettings.getaccessiblegmbaccounts
export def "content-liasettings-getaccessiblegmbaccounts" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/liasettings/{accountId}/accessiblegmbaccounts"
    path_params: [{name: merchantId, var: merchant_id}, {name: accountId, var: account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, account_id: $account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Requests access to a specified Business Profile.
#
# POST /{merchantId}/liasettings/{accountId}/requestgmbaccess
# Returns: record<kind: string>
# operationId: content.liasettings.requestgmbaccess
export def "content-liasettings-requestgmbaccess" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --gmb-email: string # The email of the Business Profile. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/{merchantId}/liasettings/{accountId}/requestgmbaccess"
    path_params: [{name: merchantId, var: merchant_id}, {name: accountId, var: account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: gmbEmail, var: gmb_email, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, account_id: $account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, gmb_email: $gmb_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Requests inventory validation for the specified country.
#
# POST /{merchantId}/liasettings/{accountId}/requestinventoryverification/{country}
# Returns: record<kind: string>
# operationId: content.liasettings.requestinventoryverification
export def "content-liasettings-requestinventoryverification" [
  merchant_id: string
  account_id: string
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/{merchantId}/liasettings/{accountId}/requestinventoryverification/{country}"
    path_params: [{name: merchantId, var: merchant_id}, {name: accountId, var: account_id}, {name: country, var: country}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, account_id: $account_id, country: $country, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the inventory verification contract for the specified country.
#
# POST /{merchantId}/liasettings/{accountId}/setinventoryverificationcontact
# Returns: record<kind: string>
# operationId: content.liasettings.setinventoryverificationcontact
export def "content-liasettings-setinventoryverificationcontact" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --country: string # The country for which inventory verification is requested. (required)
  --language: string # The language for which inventory verification is requested. (required)
  --contact-name: string # The name of the inventory verification contact. (required)
  --contact-email: string # The email of the inventory verification contact. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/{merchantId}/liasettings/{accountId}/setinventoryverificationcontact"
    path_params: [{name: merchantId, var: merchant_id}, {name: accountId, var: account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: country, var: country, required: true}, {name: language, var: language, required: true}, {name: contactName, var: contact_name, required: true}, {name: contactEmail, var: contact_email, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, account_id: $account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, country: $country, language: $language, contact_name: $contact_name, contact_email: $contact_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the POS data provider for the specified country.
#
# POST /{merchantId}/liasettings/{accountId}/setposdataprovider
# Returns: record<kind: string>
# operationId: content.liasettings.setposdataprovider
export def "content-liasettings-setposdataprovider" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --country: string # The country for which the POS data provider is selected. (required)
  --pos-data-provider-id: string # The ID of POS data provider.
  --pos-external-account-id: string # The account ID by which this merchant is known to the POS data provider.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/{merchantId}/liasettings/{accountId}/setposdataprovider"
    path_params: [{name: merchantId, var: merchant_id}, {name: accountId, var: account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: country, var: country, required: true}, {name: posDataProviderId, var: pos_data_provider_id}, {name: posExternalAccountId, var: pos_external_account_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, account_id: $account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, country: $country, pos_data_provider_id: $pos_data_provider_id, pos_external_account_id: $pos_external_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a charge invoice for a shipment group, and triggers a charge capture for orderinvoice enabled orders.
#
# POST /{merchantId}/orderinvoices/{orderId}/createChargeInvoice
# Returns: record<executionStatus: string, kind: string>
# operationId: content.orderinvoices.createchargeinvoice
export def "content-orderinvoices-createchargeinvoice" [
  merchant_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --invoice-id: string # [required] The ID of the invoice.
  --invoice-summary: record # shape: {additionalChargeSummaries?: list, productTotal?: record}
  --line-item-invoices: list # [required] Invoice details per line item. — item shape: {lineItemId?: string, productId?: string, shipmentUnitIds?: list<string>, unitInvoice?: record}
  --operation-id: string # [required] The ID of the operation, unique across all operations for a given order.
  --shipment-group-id: string # [required] ID of the shipment group. It is assigned by the merchant in the `shipLineItems` method and is used to group multiple line items that have the same kind of shipping charges.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/orderinvoices/{orderId}/createChargeInvoice"
    path_params: [{name: merchantId, var: merchant_id}, {name: orderId, var: order_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: invoiceId, var: invoice_id}, {name: invoiceSummary, var: invoice_summary}, {name: lineItemInvoices, var: line_item_invoices}, {name: operationId, var: operation_id}, {name: shipmentGroupId, var: shipment_group_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, order_id: $order_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, invoice_id: $invoice_id, invoice_summary: $invoice_summary, line_item_invoices: $line_item_invoices, operation_id: $operation_id, shipment_group_id: $shipment_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a refund invoice for one or more shipment groups, and triggers a refund for orderinvoice enabled orders. This can only be used for line items that have previously been charged using `createChargeInvoice`. All amounts (except for the summary) are incremental with respect to the previous invoice.
#
# POST /{merchantId}/orderinvoices/{orderId}/createRefundInvoice
# Returns: record<executionStatus: string, kind: string>
# operationId: content.orderinvoices.createrefundinvoice
export def "content-orderinvoices-createrefundinvoice" [
  merchant_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --invoice-id: string # [required] The ID of the invoice.
  --operation-id: string # [required] The ID of the operation, unique across all operations for a given order.
  --refund-only-option: record # shape: {description?: string, reason?: string}
  --return-option: record # shape: {description?: string, reason?: string}
  --shipment-invoices: list # Invoice details for different shipment groups. — item shape: {invoiceSummary?: record, lineItemInvoices?: list, shipmentGroupId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/orderinvoices/{orderId}/createRefundInvoice"
    path_params: [{name: merchantId, var: merchant_id}, {name: orderId, var: order_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: invoiceId, var: invoice_id}, {name: operationId, var: operation_id}, {name: refundOnlyOption, var: refund_only_option}, {name: returnOption, var: return_option}, {name: shipmentInvoices, var: shipment_invoices}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, order_id: $order_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, invoice_id: $invoice_id, operation_id: $operation_id, refund_only_option: $refund_only_option, return_option: $return_option, shipment_invoices: $shipment_invoices
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a report for disbursements from your Merchant Center account.
#
# GET /{merchantId}/orderreports/disbursements
# Returns: record<disbursements: table<disbursementAmount: record, disbursementCreationDate: string, disbursementDate: string, disbursementId: string, merchantId: string>, kind: string, nextPageToken: string>
# operationId: content.orderreports.listdisbursements
export def "content-orderreports-listdisbursements" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --disbursement-end-date: string # The last date which disbursements occurred. In ISO 8601 format. Default: current date.
  --disbursement-start-date: string # The first date which disbursements occurred. In ISO 8601 format.
  --max-results: int # The maximum number of disbursements to return in the response, used for paging.
  --page-token: string # The token returned by the previous request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/orderreports/disbursements"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: disbursementEndDate, var: disbursement_end_date}, {name: disbursementStartDate, var: disbursement_start_date}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, disbursement_end_date: $disbursement_end_date, disbursement_start_date: $disbursement_start_date, max_results: $max_results, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of transactions for a disbursement from your Merchant Center account.
#
# GET /{merchantId}/orderreports/disbursements/{disbursementId}/transactions
# Returns: record<kind: string, nextPageToken: string, transactions: table<disbursementAmount: record, disbursementCreationDate: string, disbursementDate: string, disbursementId: string, merchantId: string, merchantOrderId: string, orderId: string, productAmount: record, transactionDate: string>>
# operationId: content.orderreports.listtransactions
export def "content-orderreports-listtransactions" [
  merchant_id: string
  disbursement_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --max-results: int # The maximum number of disbursements to return in the response, used for paging.
  --page-token: string # The token returned by the previous request.
  --transaction-end-date: string # The last date in which transaction occurred. In ISO 8601 format. Default: current date.
  --transaction-start-date: string # The first date in which transaction occurred. In ISO 8601 format.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/orderreports/disbursements/{disbursementId}/transactions"
    path_params: [{name: merchantId, var: merchant_id}, {name: disbursementId, var: disbursement_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}, {name: transactionEndDate, var: transaction_end_date}, {name: transactionStartDate, var: transaction_start_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, disbursement_id: $disbursement_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, max_results: $max_results, page_token: $page_token, transaction_end_date: $transaction_end_date, transaction_start_date: $transaction_start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists order returns in your Merchant Center account.
#
# GET /{merchantId}/orderreturns
# Returns: record<kind: string, nextPageToken: string, resources: table<creationDate: string, merchantOrderId: string, orderId: string, orderReturnId: string, returnItems: list, returnPricingInfo: record, returnShipments: list>>
# operationId: content.orderreturns.list
export def "content-orderreturns-list" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --acknowledged: oneof<nothing, bool> # Obtains order returns that match the acknowledgement status. When set to true, obtains order returns that have been acknowledged. When false, obtains order returns that have not been acknowledged. When not provided, obtains order returns regardless of their acknowledgement status. We recommend using this filter set to `false`, in conjunction with the `acknowledge` call, such that only un-acknowledged order returns are returned.
  --created-end-date: string # Obtains order returns created before this date (inclusively), in ISO 8601 format.
  --created-start-date: string # Obtains order returns created after this date (inclusively), in ISO 8601 format.
  --google-order-ids: list<string> # Obtains order returns with the specified order ids. If this parameter is provided, createdStartDate, createdEndDate, shipmentType, shipmentStatus, shipmentState and acknowledged parameters must be not set. Note: if googleOrderId and shipmentTrackingNumber parameters are provided, the obtained results will include all order returns that either match the specified order id or the specified tracking number.
  --max-results: int # The maximum number of order returns to return in the response, used for paging. The default value is 25 returns per page, and the maximum allowed value is 250 returns per page.
  --order-by: string@order-by-completer # Return the results in the specified order.
  --page-token: string # The token returned by the previous request.
  --shipment-states: list<string> # Obtains order returns that match any shipment state provided in this parameter. When this parameter is not provided, order returns are obtained regardless of their shipment states.
  --shipment-status: list<string> # Obtains order returns that match any shipment status provided in this parameter. When this parameter is not provided, order returns are obtained regardless of their shipment statuses.
  --shipment-tracking-numbers: list<string> # Obtains order returns with the specified tracking numbers. If this parameter is provided, createdStartDate, createdEndDate, shipmentType, shipmentStatus, shipmentState and acknowledged parameters must be not set. Note: if googleOrderId and shipmentTrackingNumber parameters are provided, the obtained results will include all order returns that either match the specified order id or the specified tracking number.
  --shipment-types: list<string> # Obtains order returns that match any shipment type provided in this parameter. When this parameter is not provided, order returns are obtained regardless of their shipment types.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/orderreturns"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: acknowledged, var: acknowledged}, {name: createdEndDate, var: created_end_date}, {name: createdStartDate, var: created_start_date}, {name: googleOrderIds, var: google_order_ids, style: multi}, {name: maxResults, var: max_results}, {name: orderBy, var: order_by}, {name: pageToken, var: page_token}, {name: shipmentStates, var: shipment_states, style: multi}, {name: shipmentStatus, var: shipment_status, style: multi}, {name: shipmentTrackingNumbers, var: shipment_tracking_numbers, style: multi}, {name: shipmentTypes, var: shipment_types, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, acknowledged: $acknowledged, created_end_date: $created_end_date, created_start_date: $created_start_date, google_order_ids: $google_order_ids, max_results: $max_results, order_by: $order_by, page_token: $page_token, shipment_states: $shipment_states, shipment_status: $shipment_status, shipment_tracking_numbers: $shipment_tracking_numbers, shipment_types: $shipment_types
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create return in your Merchant Center account.
#
# POST /{merchantId}/orderreturns/createOrderReturn
# Returns: record<executionStatus: string, kind: string, orderReturn: record<creationDate: string, merchantOrderId: string, orderId: string, orderReturnId: string, returnItems: list<record>, returnPricingInfo: record<chargeReturnShippingFee: bool, maxReturnShippingFee: record, refundableItemsTotalAmount: record, refundableShippingAmount: record, totalRefundedAmount: record>, returnShipments: list<record>>>
# operationId: content.orderreturns.createorderreturn
export def "content-orderreturns-createorderreturn" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --line-items: list # The list of line items to return. — item shape: {lineItemId?: string, productId?: string, quantity?: int}
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
  --order-id: string # The ID of the order.
  --return-method-type: string # The way of the package being returned.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/orderreturns/createOrderReturn"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: lineItems, var: line_items}, {name: operationId, var: operation_id}, {name: orderId, var: order_id}, {name: returnMethodType, var: return_method_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, line_items: $line_items, operation_id: $operation_id, order_id: $order_id, return_method_type: $return_method_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves an order return from your Merchant Center account.
#
# GET /{merchantId}/orderreturns/{returnId}
# Returns: record<creationDate: string, merchantOrderId: string, orderId: string, orderReturnId: string, returnItems: table<customerReturnReason: record, itemId: string, merchantRejectionReason: record, merchantReturnReason: record, product: record, refundableAmount: record, returnItemId: string, returnShipmentIds: list, shipmentGroupId: string, shipmentUnitId: string, state: string>, returnPricingInfo: record<chargeReturnShippingFee: bool, maxReturnShippingFee: record<priceAmount: record, taxAmount: record>, refundableItemsTotalAmount: record<priceAmount: record, taxAmount: record>, refundableShippingAmount: record<priceAmount: record, taxAmount: record>, totalRefundedAmount: record<priceAmount: record, taxAmount: record>>, returnShipments: table<creationDate: string, deliveryDate: string, returnMethodType: string, shipmentId: string, shipmentTrackingInfos: list, shippingDate: string, state: string>>
# operationId: content.orderreturns.get
export def "content-orderreturns-get" [
  merchant_id: string
  return_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/orderreturns/{returnId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: returnId, var: return_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, return_id: $return_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Acks an order return in your Merchant Center account.
#
# POST /{merchantId}/orderreturns/{returnId}/acknowledge
# Returns: record<executionStatus: string, kind: string>
# operationId: content.orderreturns.acknowledge
export def "content-orderreturns-acknowledge" [
  merchant_id: string
  return_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --operation-id: string # [required] The ID of the operation, unique across all operations for a given order return.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/orderreturns/{returnId}/acknowledge"
    path_params: [{name: merchantId, var: merchant_id}, {name: returnId, var: return_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: operationId, var: operation_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, return_id: $return_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, operation_id: $operation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Links a return shipping label to a return id. You can only create one return label per return id. Since the label is sent to the buyer, the linked return label cannot be updated or deleted. If you try to create multiple return shipping labels for a single return id, every create request except the first will fail.
#
# POST /{merchantId}/orderreturns/{returnId}/labels
# Returns: record<carrier: string, labelUri: string, trackingId: string>
# operationId: content.orderreturns.labels.create
export def "content-orderreturns-labels-create" [
  merchant_id: string
  return_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --carrier: string # Name of the carrier.
  --label-uri: string # The URL for the return shipping label in PDF format
  --tracking-id: string # The tracking id of this return label.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/orderreturns/{returnId}/labels"
    path_params: [{name: merchantId, var: merchant_id}, {name: returnId, var: return_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: carrier, var: carrier}, {name: labelUri, var: label_uri}, {name: trackingId, var: tracking_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, return_id: $return_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, carrier: $carrier, label_uri: $label_uri, tracking_id: $tracking_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Processes return in your Merchant Center account.
#
# POST /{merchantId}/orderreturns/{returnId}/process
# Returns: record<executionStatus: string, kind: string>
# operationId: content.orderreturns.process
export def "content-orderreturns-process" [
  merchant_id: string
  return_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --full-charge-return-shipping-cost: oneof<nothing, bool> # Option to charge the customer return shipping cost.
  --operation-id: string # [required] The ID of the operation, unique across all operations for a given order return.
  --refund-shipping-fee: record # shape: {fullRefund?: bool, partialRefund?: record, paymentType?: string, reasonText?: string, returnRefundReason?: string}
  --return-items: list # The list of items to return. — item shape: {refund?: record, reject?: record, returnItemId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/orderreturns/{returnId}/process"
    path_params: [{name: merchantId, var: merchant_id}, {name: returnId, var: return_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: fullChargeReturnShippingCost, var: full_charge_return_shipping_cost}, {name: operationId, var: operation_id}, {name: refundShippingFee, var: refund_shipping_fee}, {name: returnItems, var: return_items}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, return_id: $return_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, full_charge_return_shipping_cost: $full_charge_return_shipping_cost, operation_id: $operation_id, refund_shipping_fee: $refund_shipping_fee, return_items: $return_items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the orders in your Merchant Center account.
#
# GET /{merchantId}/orders
# Returns: record<kind: string, nextPageToken: string, resources: table<acknowledged: bool, annotations: list, billingAddress: record, customer: record, deliveryDetails: record, id: string, kind: string, lineItems: list, merchantId: string, merchantOrderId: string, netPriceAmount: record, netTaxAmount: record, paymentStatus: string, pickupDetails: record, placedDate: string, promotions: list, refunds: list, shipments: list, shippingCost: record, shippingCostTax: record, status: string, taxCollector: string>>
# operationId: content.orders.list
export def "content-orders-list" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --acknowledged: oneof<nothing, bool> # Obtains orders that match the acknowledgement status. When set to true, obtains orders that have been acknowledged. When false, obtains orders that have not been acknowledged. We recommend using this filter set to `false`, in conjunction with the `acknowledge` call, such that only un-acknowledged orders are returned.
  --max-results: int # The maximum number of orders to return in the response, used for paging. The default value is 25 orders per page, and the maximum allowed value is 250 orders per page.
  --order-by: string # Order results by placement date in descending or ascending order. Acceptable values are: - placedDateAsc - placedDateDesc
  --page-token: string # The token returned by the previous request.
  --placed-date-end: string # Obtains orders placed before this date (exclusively), in ISO 8601 format.
  --placed-date-start: string # Obtains orders placed after this date (inclusively), in ISO 8601 format.
  --statuses: list<string> # Obtains orders that match any of the specified statuses. Note that `active` is a shortcut for `pendingShipment` and `partiallyShipped`, and `completed` is a shortcut for `shipped`, `partiallyDelivered`, `delivered`, `partiallyReturned`, `returned`, and `canceled`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/orders"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: acknowledged, var: acknowledged}, {name: maxResults, var: max_results}, {name: orderBy, var: order_by}, {name: pageToken, var: page_token}, {name: placedDateEnd, var: placed_date_end}, {name: placedDateStart, var: placed_date_start}, {name: statuses, var: statuses, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, acknowledged: $acknowledged, max_results: $max_results, order_by: $order_by, page_token: $page_token, placed_date_end: $placed_date_end, placed_date_start: $placed_date_start, statuses: $statuses
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves an order from your Merchant Center account.
#
# GET /{merchantId}/orders/{orderId}
# Returns: record<acknowledged: bool, annotations: table<key: string, value: string>, billingAddress: record<country: string, fullAddress: list<string>, isPostOfficeBox: bool, locality: string, postalCode: string, recipientName: string, region: string, streetAddress: list<string>>, customer: record<fullName: string, invoiceReceivingEmail: string, loyaltyInfo: record<loyaltyNumber: string, name: string>, marketingRightsInfo: record<explicitMarketingPreference: string, lastUpdatedTimestamp: string, marketingEmailAddress: string>>, deliveryDetails: record<address: record<country: string, fullAddress: list, isPostOfficeBox: bool, locality: string, postalCode: string, recipientName: string, region: string, streetAddress: list>, phoneNumber: string>, id: string, kind: string, lineItems: table<adjustments: list, annotations: list, cancellations: list, id: string, price: record, product: record, quantityCanceled: int, quantityDelivered: int, quantityOrdered: int, quantityPending: int, quantityReadyForPickup: int, quantityReturned: int, quantityShipped: int, quantityUndeliverable: int, returnInfo: record, returns: list, shippingDetails: record, tax: record>, merchantId: string, merchantOrderId: string, netPriceAmount: record<currency: string, value: string>, netTaxAmount: record<currency: string, value: string>, paymentStatus: string, pickupDetails: record<address: record<country: string, fullAddress: list, isPostOfficeBox: bool, locality: string, postalCode: string, recipientName: string, region: string, streetAddress: list>, collectors: list<record>, locationId: string, pickupType: string>, placedDate: string, promotions: table<applicableItems: list, appliedItems: list, endTime: string, funder: string, merchantPromotionId: string, priceValue: record, shortTitle: string, startTime: string, subtype: string, taxValue: record, title: string, type: string>, refunds: table<actor: string, amount: record, creationDate: string, reason: string, reasonText: string>, shipments: table<carrier: string, creationDate: string, deliveryDate: string, id: string, lineItems: list, scheduledDeliveryDetails: record, shipmentGroupId: string, status: string, trackingId: string>, shippingCost: record<currency: string, value: string>, shippingCostTax: record<currency: string, value: string>, status: string, taxCollector: string>
# operationId: content.orders.get
export def "content-orders-get" [
  merchant_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/orders/{orderId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: orderId, var: order_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, order_id: $order_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Marks an order as acknowledged.
#
# POST /{merchantId}/orders/{orderId}/acknowledge
# Returns: record<executionStatus: string, kind: string>
# operationId: content.orders.acknowledge
export def "content-orders-acknowledge" [
  merchant_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/orders/{orderId}/acknowledge"
    path_params: [{name: merchantId, var: merchant_id}, {name: orderId, var: order_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: operationId, var: operation_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, order_id: $order_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, operation_id: $operation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels all line items in an order, making a full refund.
#
# POST /{merchantId}/orders/{orderId}/cancel
# Returns: record<executionStatus: string, kind: string>
# operationId: content.orders.cancel
export def "content-orders-cancel" [
  merchant_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
  --reason: string # The reason for the cancellation. Acceptable values are: - "`customerInitiatedCancel`" - "`invalidCoupon`" - "`malformedShippingAddress`" - "`noInventory`" - "`other`" - "`priceError`" - "`shippingPriceError`" - "`taxError`" - "`undeliverableShippingAddress`" - "`unsupportedPoBoxAddress`" - "`failedToCaptureFunds`"
  --reason-text: string # The explanation of the reason.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/orders/{orderId}/cancel"
    path_params: [{name: merchantId, var: merchant_id}, {name: orderId, var: order_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: operationId, var: operation_id}, {name: reason, var: reason}, {name: reasonText, var: reason_text}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, order_id: $order_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, operation_id: $operation_id, reason: $reason, reason_text: $reason_text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels a line item, making a full refund.
#
# POST /{merchantId}/orders/{orderId}/cancelLineItem
# Returns: record<executionStatus: string, kind: string>
# operationId: content.orders.cancellineitem
export def "content-orders-cancellineitem" [
  merchant_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --line-item-id: string # The ID of the line item to cancel. Either lineItemId or productId is required.
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
  --product-id: string # The ID of the product to cancel. This is the REST ID used in the products service. Either lineItemId or productId is required.
  --quantity: int # The quantity to cancel. (format: uint32)
  --reason: string # The reason for the cancellation. Acceptable values are: - "`customerInitiatedCancel`" - "`invalidCoupon`" - "`malformedShippingAddress`" - "`noInventory`" - "`other`" - "`priceError`" - "`shippingPriceError`" - "`taxError`" - "`undeliverableShippingAddress`" - "`unsupportedPoBoxAddress`" - "`failedToCaptureFunds`"
  --reason-text: string # The explanation of the reason.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/orders/{orderId}/cancelLineItem"
    path_params: [{name: merchantId, var: merchant_id}, {name: orderId, var: order_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: lineItemId, var: line_item_id}, {name: operationId, var: operation_id}, {name: productId, var: product_id}, {name: quantity, var: quantity}, {name: reason, var: reason}, {name: reasonText, var: reason_text}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, order_id: $order_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, line_item_id: $line_item_id, operation_id: $operation_id, product_id: $product_id, quantity: $quantity, reason: $reason, reason_text: $reason_text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Capture funds from the customer for the current order total. This method should be called after the merchant verifies that they are able and ready to start shipping the order. This method blocks until a response is received from the payment processsor. If this method succeeds, the merchant is guaranteed to receive funds for the order after shipment. If the request fails, it can be retried or the order may be cancelled. This method cannot be called after the entire order is already shipped. A rejected error code is returned when the payment service provider has declined the charge. This indicates a problem between the PSP and either the merchant's or customer's account. Sometimes this error will be resolved by the customer. We recommend retrying these errors once per day or cancelling the order with reason `failedToCaptureFunds` if the items cannot be held.
#
# POST /{merchantId}/orders/{orderId}/captureOrder
# Returns: record<executionStatus: string>
# operationId: content.orders.captureOrder
export def "content-orders-capture-order" [
  merchant_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/orders/{orderId}/captureOrder"
    path_params: [{name: merchantId, var: merchant_id}, {name: orderId, var: order_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, order_id: $order_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deprecated. Notifies that item return and refund was handled directly by merchant outside of Google payments processing (for example, cash refund done in store). Note: We recommend calling the returnrefundlineitem method to refund in-store returns. We will issue the refund directly to the customer. This helps to prevent possible differences arising between merchant and Google transaction records. We also recommend having the point of sale system communicate with Google to ensure that customers do not receive a double refund by first refunding through Google then through an in-store return.
#
# POST /{merchantId}/orders/{orderId}/inStoreRefundLineItem
# Returns: record<executionStatus: string, kind: string>
# operationId: content.orders.instorerefundlineitem
export def "content-orders-instorerefundlineitem" [
  merchant_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --line-item-id: string # The ID of the line item to return. Either lineItemId or productId is required.
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
  --price-amount: record # shape: {currency?: string, value?: string}
  --product-id: string # The ID of the product to return. This is the REST ID used in the products service. Either lineItemId or productId is required.
  --quantity: int # The quantity to return and refund. (format: uint32)
  --reason: string # The reason for the return. Acceptable values are: - "`customerDiscretionaryReturn`" - "`customerInitiatedMerchantCancel`" - "`deliveredTooLate`" - "`expiredItem`" - "`invalidCoupon`" - "`malformedShippingAddress`" - "`other`" - "`productArrivedDamaged`" - "`productNotAsDescribed`" - "`qualityNotAsExpected`" - "`undeliverableShippingAddress`" - "`unsupportedPoBoxAddress`" - "`wrongProductShipped`"
  --reason-text: string # The explanation of the reason.
  --tax-amount: record # shape: {currency?: string, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/orders/{orderId}/inStoreRefundLineItem"
    path_params: [{name: merchantId, var: merchant_id}, {name: orderId, var: order_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: lineItemId, var: line_item_id}, {name: operationId, var: operation_id}, {name: priceAmount, var: price_amount}, {name: productId, var: product_id}, {name: quantity, var: quantity}, {name: reason, var: reason}, {name: reasonText, var: reason_text}, {name: taxAmount, var: tax_amount}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, order_id: $order_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, line_item_id: $line_item_id, operation_id: $operation_id, price_amount: $price_amount, product_id: $product_id, quantity: $quantity, reason: $reason, reason_text: $reason_text, tax_amount: $tax_amount
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Issues a partial or total refund for items and shipment.
#
# POST /{merchantId}/orders/{orderId}/refunditem
# Returns: record<executionStatus: string, kind: string>
# operationId: content.orders.refunditem
export def "content-orders-refunditem" [
  merchant_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --items: list # The items that are refunded. Either Item or Shipping must be provided in the request. — item shape: {amount?: record, fullRefund?: bool, lineItemId?: string, productId?: string, quantity?: int}
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
  --reason: string # The reason for the refund. Acceptable values are: - "`shippingCostAdjustment`" - "`priceAdjustment`" - "`taxAdjustment`" - "`feeAdjustment`" - "`courtesyAdjustment`" - "`adjustment`" - "`customerCancelled`" - "`noInventory`" - "`productNotAsDescribed`" - "`undeliverableShippingAddress`" - "`wrongProductShipped`" - "`lateShipmentCredit`" - "`deliveredLateByCarrier`" - "`productArrivedDamaged`"
  --reason-text: string # The explanation of the reason.
  --shipping: record # shape: {amount?: record, fullRefund?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/orders/{orderId}/refunditem"
    path_params: [{name: merchantId, var: merchant_id}, {name: orderId, var: order_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: items, var: items}, {name: operationId, var: operation_id}, {name: reason, var: reason}, {name: reasonText, var: reason_text}, {name: shipping, var: shipping}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, order_id: $order_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, items: $items, operation_id: $operation_id, reason: $reason, reason_text: $reason_text, shipping: $shipping
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Issues a partial or total refund for an order.
#
# POST /{merchantId}/orders/{orderId}/refundorder
# Returns: record<executionStatus: string, kind: string>
# operationId: content.orders.refundorder
export def "content-orders-refundorder" [
  merchant_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --amount: record # shape: {priceAmount?: record, taxAmount?: record}
  --full-refund: oneof<nothing, bool> # If true, the full order will be refunded, including shipping. If this is true, amount shouldn't be provided and will be ignored.
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
  --reason: string # The reason for the refund. Acceptable values are: - "`courtesyAdjustment`" - "`other`"
  --reason-text: string # The explanation of the reason.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/orders/{orderId}/refundorder"
    path_params: [{name: merchantId, var: merchant_id}, {name: orderId, var: order_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: fullRefund, var: full_refund}, {name: operationId, var: operation_id}, {name: reason, var: reason}, {name: reasonText, var: reason_text}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, order_id: $order_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, amount: $amount, full_refund: $full_refund, operation_id: $operation_id, reason: $reason, reason_text: $reason_text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rejects return on an line item.
#
# POST /{merchantId}/orders/{orderId}/rejectReturnLineItem
# Returns: record<executionStatus: string, kind: string>
# operationId: content.orders.rejectreturnlineitem
export def "content-orders-rejectreturnlineitem" [
  merchant_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --line-item-id: string # The ID of the line item to return. Either lineItemId or productId is required.
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
  --product-id: string # The ID of the product to return. This is the REST ID used in the products service. Either lineItemId or productId is required.
  --quantity: int # The quantity to return and refund. (format: uint32)
  --reason: string # The reason for the return. Acceptable values are: - "`damagedOrUsed`" - "`missingComponent`" - "`notEligible`" - "`other`" - "`outOfReturnWindow`"
  --reason-text: string # The explanation of the reason.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/orders/{orderId}/rejectReturnLineItem"
    path_params: [{name: merchantId, var: merchant_id}, {name: orderId, var: order_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: lineItemId, var: line_item_id}, {name: operationId, var: operation_id}, {name: productId, var: product_id}, {name: quantity, var: quantity}, {name: reason, var: reason}, {name: reasonText, var: reason_text}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, order_id: $order_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, line_item_id: $line_item_id, operation_id: $operation_id, product_id: $product_id, quantity: $quantity, reason: $reason, reason_text: $reason_text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns and refunds a line item. Note that this method can only be called on fully shipped orders. The Orderreturns API is the preferred way to handle returns after you receive a return from a customer. You can use Orderreturns.list or Orderreturns.get to search for the return, and then use Orderreturns.processreturn to issue the refund. If the return cannot be found, then we recommend using this API to issue a refund.
#
# POST /{merchantId}/orders/{orderId}/returnRefundLineItem
# Returns: record<executionStatus: string, kind: string>
# operationId: content.orders.returnrefundlineitem
export def "content-orders-returnrefundlineitem" [
  merchant_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --line-item-id: string # The ID of the line item to return. Either lineItemId or productId is required.
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
  --price-amount: record # shape: {currency?: string, value?: string}
  --product-id: string # The ID of the product to return. This is the REST ID used in the products service. Either lineItemId or productId is required.
  --quantity: int # The quantity to return and refund. Quantity is required. (format: uint32)
  --reason: string # The reason for the return. Acceptable values are: - "`customerDiscretionaryReturn`" - "`customerInitiatedMerchantCancel`" - "`deliveredTooLate`" - "`expiredItem`" - "`invalidCoupon`" - "`malformedShippingAddress`" - "`other`" - "`productArrivedDamaged`" - "`productNotAsDescribed`" - "`qualityNotAsExpected`" - "`undeliverableShippingAddress`" - "`unsupportedPoBoxAddress`" - "`wrongProductShipped`"
  --reason-text: string # The explanation of the reason.
  --tax-amount: record # shape: {currency?: string, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/orders/{orderId}/returnRefundLineItem"
    path_params: [{name: merchantId, var: merchant_id}, {name: orderId, var: order_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: lineItemId, var: line_item_id}, {name: operationId, var: operation_id}, {name: priceAmount, var: price_amount}, {name: productId, var: product_id}, {name: quantity, var: quantity}, {name: reason, var: reason}, {name: reasonText, var: reason_text}, {name: taxAmount, var: tax_amount}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, order_id: $order_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, line_item_id: $line_item_id, operation_id: $operation_id, price_amount: $price_amount, product_id: $product_id, quantity: $quantity, reason: $reason, reason_text: $reason_text, tax_amount: $tax_amount
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets (or overrides if it already exists) merchant provided annotations in the form of key-value pairs. A common use case would be to supply us with additional structured information about a line item that cannot be provided through other methods. Submitted key-value pairs can be retrieved as part of the orders resource.
#
# POST /{merchantId}/orders/{orderId}/setLineItemMetadata
# Returns: record<executionStatus: string, kind: string>
# operationId: content.orders.setlineitemmetadata
export def "content-orders-setlineitemmetadata" [
  merchant_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --annotations: list # item shape: {key?: string, value?: string}
  --line-item-id: string # The ID of the line item to set metadata. Either lineItemId or productId is required.
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
  --product-id: string # The ID of the product to set metadata. This is the REST ID used in the products service. Either lineItemId or productId is required.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/orders/{orderId}/setLineItemMetadata"
    path_params: [{name: merchantId, var: merchant_id}, {name: orderId, var: order_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: annotations, var: annotations}, {name: lineItemId, var: line_item_id}, {name: operationId, var: operation_id}, {name: productId, var: product_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, order_id: $order_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, annotations: $annotations, line_item_id: $line_item_id, operation_id: $operation_id, product_id: $product_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Marks line item(s) as shipped.
#
# POST /{merchantId}/orders/{orderId}/shipLineItems
# Returns: record<executionStatus: string, kind: string>
# operationId: content.orders.shiplineitems
export def "content-orders-shiplineitems" [
  merchant_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --line-items: list # Line items to ship. — item shape: {lineItemId?: string, productId?: string, quantity?: int}
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
  --shipment-group-id: string # ID of the shipment group. Required for orders that use the orderinvoices service.
  --shipment-infos: list # Shipment information. This field is repeated because a single line item can be shipped in several packages (and have several tracking IDs). — item shape: {carrier?: string, shipmentId?: string, trackingId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/orders/{orderId}/shipLineItems"
    path_params: [{name: merchantId, var: merchant_id}, {name: orderId, var: order_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: lineItems, var: line_items}, {name: operationId, var: operation_id}, {name: shipmentGroupId, var: shipment_group_id}, {name: shipmentInfos, var: shipment_infos}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, order_id: $order_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, line_items: $line_items, operation_id: $operation_id, shipment_group_id: $shipment_group_id, shipment_infos: $shipment_infos
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sandbox only. Creates a test return.
#
# POST /{merchantId}/orders/{orderId}/testreturn
# Returns: record<kind: string, returnId: string>
# operationId: content.orders.createtestreturn
export def "content-orders-createtestreturn" [
  merchant_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --items: list # Returned items. — item shape: {lineItemId?: string, quantity?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/orders/{orderId}/testreturn"
    path_params: [{name: merchantId, var: merchant_id}, {name: orderId, var: order_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: items, var: items}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, order_id: $order_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, items: $items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates ship by and delivery by dates for a line item.
#
# POST /{merchantId}/orders/{orderId}/updateLineItemShippingDetails
# Returns: record<executionStatus: string, kind: string>
# operationId: content.orders.updatelineitemshippingdetails
export def "content-orders-updatelineitemshippingdetails" [
  merchant_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --deliver-by-date: string # Updated delivery by date, in ISO 8601 format. If not specified only ship by date is updated. Provided date should be within 1 year timeframe and can't be a date in the past.
  --line-item-id: string # The ID of the line item to set metadata. Either lineItemId or productId is required.
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
  --product-id: string # The ID of the product to set metadata. This is the REST ID used in the products service. Either lineItemId or productId is required.
  --ship-by-date: string # Updated ship by date, in ISO 8601 format. If not specified only deliver by date is updated. Provided date should be within 1 year timeframe and can't be a date in the past.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/orders/{orderId}/updateLineItemShippingDetails"
    path_params: [{name: merchantId, var: merchant_id}, {name: orderId, var: order_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: deliverByDate, var: deliver_by_date}, {name: lineItemId, var: line_item_id}, {name: operationId, var: operation_id}, {name: productId, var: product_id}, {name: shipByDate, var: ship_by_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, order_id: $order_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, deliver_by_date: $deliver_by_date, line_item_id: $line_item_id, operation_id: $operation_id, product_id: $product_id, ship_by_date: $ship_by_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the merchant order ID for a given order.
#
# POST /{merchantId}/orders/{orderId}/updateMerchantOrderId
# Returns: record<executionStatus: string, kind: string>
# operationId: content.orders.updatemerchantorderid
export def "content-orders-updatemerchantorderid" [
  merchant_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --merchant-order-id: string # The merchant order id to be assigned to the order. Must be unique per merchant.
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/orders/{orderId}/updateMerchantOrderId"
    path_params: [{name: merchantId, var: merchant_id}, {name: orderId, var: order_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: merchantOrderId, var: merchant_order_id}, {name: operationId, var: operation_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, order_id: $order_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, merchant_order_id: $merchant_order_id, operation_id: $operation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a shipment's status, carrier, and/or tracking ID.
#
# POST /{merchantId}/orders/{orderId}/updateShipment
# Returns: record<executionStatus: string, kind: string>
# operationId: content.orders.updateshipment
export def "content-orders-updateshipment" [
  merchant_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --carrier: string # The carrier handling the shipment. Not updated if missing. See `shipments[].carrier` in the Orders resource representation for a list of acceptable values.
  --delivery-date: string # Date on which the shipment has been delivered, in ISO 8601 format. Optional and can be provided only if `status` is `delivered`.
  --last-pickup-date: string # Date after which the pickup will expire, in ISO 8601 format. Required only when order is buy-online-pickup-in-store(BOPIS) and `status` is `ready for pickup`.
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
  --ready-pickup-date: string # Date on which the shipment has been ready for pickup, in ISO 8601 format. Optional and can be provided only if `status` is `ready for pickup`.
  --scheduled-delivery-details: record # ScheduledDeliveryDetails used to update the scheduled delivery order. — shape: {carrierPhoneNumber?: string, scheduledDate?: string}
  --shipment-id: string # The ID of the shipment.
  --status: string # New status for the shipment. Not updated if missing. Acceptable values are: - "`delivered`" - "`undeliverable`" - "`readyForPickup`"
  --tracking-id: string # The tracking ID for the shipment. Not updated if missing.
  --undelivered-date: string # Date on which the shipment has been undeliverable, in ISO 8601 format. Optional and can be provided only if `status` is `undeliverable`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/orders/{orderId}/updateShipment"
    path_params: [{name: merchantId, var: merchant_id}, {name: orderId, var: order_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: carrier, var: carrier}, {name: deliveryDate, var: delivery_date}, {name: lastPickupDate, var: last_pickup_date}, {name: operationId, var: operation_id}, {name: readyPickupDate, var: ready_pickup_date}, {name: scheduledDeliveryDetails, var: scheduled_delivery_details}, {name: shipmentId, var: shipment_id}, {name: status, var: status}, {name: trackingId, var: tracking_id}, {name: undeliveredDate, var: undelivered_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, order_id: $order_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, carrier: $carrier, delivery_date: $delivery_date, last_pickup_date: $last_pickup_date, operation_id: $operation_id, ready_pickup_date: $ready_pickup_date, scheduled_delivery_details: $scheduled_delivery_details, shipment_id: $shipment_id, status: $status, tracking_id: $tracking_id, undelivered_date: $undelivered_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves an order using merchant order ID.
#
# GET /{merchantId}/ordersbymerchantid/{merchantOrderId}
# Returns: record<kind: string, order: record<acknowledged: bool, annotations: list<record>, billingAddress: record<country: string, fullAddress: list, isPostOfficeBox: bool, locality: string, postalCode: string, recipientName: string, region: string, streetAddress: list>, customer: record<fullName: string, invoiceReceivingEmail: string, loyaltyInfo: record, marketingRightsInfo: record>, deliveryDetails: record<address: record, phoneNumber: string>, id: string, kind: string, lineItems: list<record>, merchantId: string, merchantOrderId: string, netPriceAmount: record<currency: string, value: string>, netTaxAmount: record<currency: string, value: string>, paymentStatus: string, pickupDetails: record<address: record, collectors: list, locationId: string, pickupType: string>, placedDate: string, promotions: list<record>, refunds: list<record>, shipments: list<record>, shippingCost: record<currency: string, value: string>, shippingCostTax: record<currency: string, value: string>, status: string, taxCollector: string>>
# operationId: content.orders.getbymerchantorderid
export def "content-orders-getbymerchantorderid" [
  merchant_id: string
  merchant_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/ordersbymerchantid/{merchantOrderId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: merchantOrderId, var: merchant_order_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, merchant_order_id: $merchant_order_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates new order tracking signal.
#
# POST /{merchantId}/ordertrackingsignals
# Returns: record<customerShippingFee: record<currency: string, value: string>, deliveryPostalCode: string, deliveryRegionCode: string, lineItems: table<brand: string, gtin: string, lineItemId: string, mpn: string, productDescription: string, productId: string, productTitle: string, quantity: string, sku: string, upc: string>, merchantId: string, orderCreatedTime: record<day: int, hours: int, minutes: int, month: int, nanos: int, seconds: int, timeZone: record<id: string, version: string>, utcOffset: string, year: int>, orderId: string, orderTrackingSignalId: string, shipmentLineItemMapping: table<lineItemId: string, quantity: string, shipmentId: string>, shippingInfo: table<actualDeliveryTime: record, carrierName: string, carrierServiceName: string, earliestDeliveryPromiseTime: record, latestDeliveryPromiseTime: record, originPostalCode: string, originRegionCode: string, shipmentId: string, shippedTime: record, shippingStatus: string, trackingId: string>>
# operationId: content.ordertrackingsignals.create
export def "content-ordertrackingsignals-create" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --customer-shipping-fee: record # The price represented as a number and currency. — shape: {currency?: string, value?: string}
  --delivery-postal-code: string # Required. The delivery postal code, as a continuous string without spaces or dashes, e.g. "95016". This field will be anonymized in returned OrderTrackingSignal creation response.
  --delivery-region-code: string # Required. The [CLDR territory code] (http://www.unicode.org/repos/cldr/tags/latest/common/main/en.xml) for the shipping destination.
  --line-items: list # Information about line items in the order. — item shape: {brand?: string, gtin?: string, lineItemId?: string, mpn?: string, productDescription?: string, productId?: string, productTitle?: string, quantity?: string, sku?: string, upc?: string}
  --body-merchant-id: string # The Google merchant ID of this order tracking signal. This value is optional. If left unset, the caller's merchant ID is used. You must request access in order to provide data on behalf of another merchant. For more information, see [Submitting Order Tracking Signals](/shopping-content/guides/order-tracking-signals). (format: int64) (spec name: merchantId)
  --order-created-time: record # Represents civil time (or occasionally physical time). This type can represent a civil time in one of a few possible ways: * When utc_offset is set and time_zone is unset: a civil time on a calendar day with a particular offset from UTC. * When time_zone is set and utc_offset is unset: a civil time on a calendar day in a particular time zone. * When neither time_zone nor utc_offset is set: a civil time on a calendar day in local time. The date is relative to the Proleptic Gregorian Calendar. If year, month, or day are 0, the DateTime is considered not to have a specific year, month, or day respectively. This type may also be used to represent a physical time if all the date and time fields are set and either case of the `time_offset` oneof is set. Consider using `Timestamp` message for physical time instead. If your use case also would like to store the user's timezone, that can be done in another field. This type is more flexible than some applications may want. Make sure to document and validate your application's limitations. — shape: {day?: int, hours?: int, minutes?: int, month?: int, nanos?: int, seconds?: int, timeZone?: record, utcOffset?: string, year?: int}
  --order-id: string # Required. The ID of the order on the merchant side. This field will be hashed in returned OrderTrackingSignal creation response.
  --shipment-line-item-mapping: list # The mapping of the line items to the shipment information. — item shape: {lineItemId?: string, quantity?: string, shipmentId?: string}
  --shipping-info: list # The shipping information for the order. — item shape: {actualDeliveryTime?: record, carrierName?: string, carrierServiceName?: string, earliestDeliveryPromiseTime?: record, latestDeliveryPromiseTime?: record, originPostalCode?: string, originRegionCode?: string, shipmentId?: string, shippedTime?: record, shippingStatus?: "SHIPPING_STATE_UNSPECIFIED"|"SHIPPED"|"DELIVERED", trackingId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/ordertrackingsignals"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: customerShippingFee, var: customer_shipping_fee}, {name: deliveryPostalCode, var: delivery_postal_code}, {name: deliveryRegionCode, var: delivery_region_code}, {name: lineItems, var: line_items}, {name: merchantId, var: body_merchant_id}, {name: orderCreatedTime, var: order_created_time}, {name: orderId, var: order_id}, {name: shipmentLineItemMapping, var: shipment_line_item_mapping}, {name: shippingInfo, var: shipping_info}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, customer_shipping_fee: $customer_shipping_fee, delivery_postal_code: $delivery_postal_code, delivery_region_code: $delivery_region_code, line_items: $line_items, body_merchant_id: $body_merchant_id, order_created_time: $order_created_time, order_id: $order_id, shipment_line_item_mapping: $shipment_line_item_mapping, shipping_info: $shipping_info
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit inventory for the given merchant.
#
# POST /{merchantId}/pos/{targetMerchantId}/inventory
# Returns: record<contentLanguage: string, gtin: string, itemId: string, kind: string, price: record<currency: string, value: string>, quantity: string, storeCode: string, targetCountry: string, timestamp: string>
# operationId: content.pos.inventory
export def "content-pos-inventory" [
  merchant_id: string
  target_merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --content-language: string # Required. The two-letter ISO 639-1 language code for the item.
  --gtin: string # Global Trade Item Number.
  --item-id: string # Required. A unique identifier for the item.
  --price: record # shape: {currency?: string, value?: string}
  --quantity: string # Required. The available quantity of the item. (format: int64)
  --store-code: string # Required. The identifier of the merchant's store. Either a `storeCode` inserted through the API or the code of the store in a Business Profile.
  --target-country: string # Required. The CLDR territory code for the item.
  --timestamp: string # Required. The inventory timestamp, in ISO 8601 format.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/pos/{targetMerchantId}/inventory"
    path_params: [{name: merchantId, var: merchant_id}, {name: targetMerchantId, var: target_merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: contentLanguage, var: content_language}, {name: gtin, var: gtin}, {name: itemId, var: item_id}, {name: price, var: price}, {name: quantity, var: quantity}, {name: storeCode, var: store_code}, {name: targetCountry, var: target_country}, {name: timestamp, var: timestamp}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, target_merchant_id: $target_merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, content_language: $content_language, gtin: $gtin, item_id: $item_id, price: $price, quantity: $quantity, store_code: $store_code, target_country: $target_country, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit a sale event for the given merchant.
#
# POST /{merchantId}/pos/{targetMerchantId}/sale
# Returns: record<contentLanguage: string, gtin: string, itemId: string, kind: string, price: record<currency: string, value: string>, quantity: string, saleId: string, storeCode: string, targetCountry: string, timestamp: string>
# operationId: content.pos.sale
export def "content-pos-sale" [
  merchant_id: string
  target_merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --content-language: string # Required. The two-letter ISO 639-1 language code for the item.
  --gtin: string # Global Trade Item Number.
  --item-id: string # Required. A unique identifier for the item.
  --price: record # shape: {currency?: string, value?: string}
  --quantity: string # Required. The relative change of the available quantity. Negative for items returned. (format: int64)
  --sale-id: string # A unique ID to group items from the same sale event.
  --store-code: string # Required. The identifier of the merchant's store. Either a `storeCode` inserted through the API or the code of the store in a Business Profile.
  --target-country: string # Required. The CLDR territory code for the item.
  --timestamp: string # Required. The inventory timestamp, in ISO 8601 format.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/pos/{targetMerchantId}/sale"
    path_params: [{name: merchantId, var: merchant_id}, {name: targetMerchantId, var: target_merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: contentLanguage, var: content_language}, {name: gtin, var: gtin}, {name: itemId, var: item_id}, {name: price, var: price}, {name: quantity, var: quantity}, {name: saleId, var: sale_id}, {name: storeCode, var: store_code}, {name: targetCountry, var: target_country}, {name: timestamp, var: timestamp}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, target_merchant_id: $target_merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, content_language: $content_language, gtin: $gtin, item_id: $item_id, price: $price, quantity: $quantity, sale_id: $sale_id, store_code: $store_code, target_country: $target_country, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the stores of the target merchant.
#
# GET /{merchantId}/pos/{targetMerchantId}/store
# Returns: record<kind: string, resources: table<gcidCategory: list, kind: string, phoneNumber: string, placeId: string, storeAddress: string, storeCode: string, storeName: string, websiteUrl: string>>
# operationId: content.pos.list
export def "content-pos-list" [
  merchant_id: string
  target_merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/pos/{targetMerchantId}/store"
    path_params: [{name: merchantId, var: merchant_id}, {name: targetMerchantId, var: target_merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, target_merchant_id: $target_merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a store for the given merchant.
#
# POST /{merchantId}/pos/{targetMerchantId}/store
# Returns: record<gcidCategory: list<string>, kind: string, phoneNumber: string, placeId: string, storeAddress: string, storeCode: string, storeName: string, websiteUrl: string>
# operationId: content.pos.insert
export def "content-pos-insert" [
  merchant_id: string
  target_merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --gcid-category: list<string> # The business type of the store.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "`content#posStore`"
  --phone-number: string # The store phone number.
  --place-id: string # The Google Place Id of the store location.
  --store-address: string # Required. The street address of the store.
  --store-code: string # Required. A store identifier that is unique for the given merchant.
  --store-name: string # The merchant or store name.
  --website-url: string # The website url for the store or merchant.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/pos/{targetMerchantId}/store"
    path_params: [{name: merchantId, var: merchant_id}, {name: targetMerchantId, var: target_merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: gcidCategory, var: gcid_category}, {name: kind, var: kind}, {name: phoneNumber, var: phone_number}, {name: placeId, var: place_id}, {name: storeAddress, var: store_address}, {name: storeCode, var: store_code}, {name: storeName, var: store_name}, {name: websiteUrl, var: website_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, target_merchant_id: $target_merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, gcid_category: $gcid_category, kind: $kind, phone_number: $phone_number, place_id: $place_id, store_address: $store_address, store_code: $store_code, store_name: $store_name, website_url: $website_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a store for the given merchant.
#
# DELETE /{merchantId}/pos/{targetMerchantId}/store/{storeCode}
# operationId: content.pos.delete
export def "content-pos-delete" [
  merchant_id: string
  target_merchant_id: string
  store_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> any {
  http-request {
    method: delete
    path: "/{merchantId}/pos/{targetMerchantId}/store/{storeCode}"
    path_params: [{name: merchantId, var: merchant_id}, {name: targetMerchantId, var: target_merchant_id}, {name: storeCode, var: store_code}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, target_merchant_id: $target_merchant_id, store_code: $store_code, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the given store.
#
# GET /{merchantId}/pos/{targetMerchantId}/store/{storeCode}
# Returns: record<gcidCategory: list<string>, kind: string, phoneNumber: string, placeId: string, storeAddress: string, storeCode: string, storeName: string, websiteUrl: string>
# operationId: content.pos.get
export def "content-pos-get" [
  merchant_id: string
  target_merchant_id: string
  store_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/pos/{targetMerchantId}/store/{storeCode}"
    path_params: [{name: merchantId, var: merchant_id}, {name: targetMerchantId, var: target_merchant_id}, {name: storeCode, var: store_code}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, target_merchant_id: $target_merchant_id, store_code: $store_code, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates the delivery time of a product.
#
# POST /{merchantId}/productdeliverytime
# Returns: record<areaDeliveryTimes: table<deliveryArea: record, deliveryTime: record>, productId: record<productId: string>>
# operationId: content.productdeliverytime.create
export def "content-productdeliverytime-create" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --area-delivery-times: list # Required. A set of associations between `DeliveryArea` and `DeliveryTime` entries. The total number of `areaDeliveryTimes` can be at most 100. — item shape: {deliveryArea?: record, deliveryTime?: record}
  --product-id: record # The Content API ID of the product. — shape: {productId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/productdeliverytime"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: areaDeliveryTimes, var: area_delivery_times}, {name: productId, var: product_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, area_delivery_times: $area_delivery_times, product_id: $product_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the delivery time of a product.
#
# DELETE /{merchantId}/productdeliverytime/{productId}
# operationId: content.productdeliverytime.delete
export def "content-productdeliverytime-delete" [
  merchant_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> any {
  http-request {
    method: delete
    path: "/{merchantId}/productdeliverytime/{productId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: productId, var: product_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, product_id: $product_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets `productDeliveryTime` by `productId`.
#
# GET /{merchantId}/productdeliverytime/{productId}
# Returns: record<areaDeliveryTimes: table<deliveryArea: record, deliveryTime: record>, productId: record<productId: string>>
# operationId: content.productdeliverytime.get
export def "content-productdeliverytime-get" [
  merchant_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/productdeliverytime/{productId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: productId, var: product_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, product_id: $product_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the products in your Merchant Center account. The response might contain fewer items than specified by maxResults. Rely on nextPageToken to determine if there are more items to be requested.
#
# GET /{merchantId}/products
# Returns: record<kind: string, nextPageToken: string, resources: table<additionalImageLinks: list, additionalSizeType: string, adsGrouping: string, adsLabels: list, adsRedirect: string, adult: bool, ageGroup: string, availability: string, availabilityDate: string, brand: string, canonicalLink: string, channel: string, color: string, condition: string, contentLanguage: string, costOfGoodsSold: record, customAttributes: list, customLabel0: string, customLabel1: string, customLabel2: string, customLabel3: string, customLabel4: string, description: string, displayAdsId: string, displayAdsLink: string, displayAdsSimilarIds: list, displayAdsTitle: string, displayAdsValue: float, energyEfficiencyClass: string, excludedDestinations: list, expirationDate: string, externalSellerId: string, feedLabel: string, gender: string, googleProductCategory: string, gtin: string, id: string, identifierExists: bool, imageLink: string, includedDestinations: list, installment: record, isBundle: bool, itemGroupId: string, kind: string, lifestyleImageLinks: list, link: string, linkTemplate: string, loyaltyPoints: record, material: string, maxEnergyEfficiencyClass: string, maxHandlingTime: string, minEnergyEfficiencyClass: string, minHandlingTime: string, mobileLink: string, mobileLinkTemplate: string, mpn: string, multipack: string, offerId: string, pattern: string, pause: string, pickupMethod: string, pickupSla: string, price: record, productDetails: list, productHeight: record, productHighlights: list, productLength: record, productTypes: list, productWeight: record, productWidth: record, promotionIds: list, salePrice: record, salePriceEffectiveDate: string, sellOnGoogleQuantity: string, shipping: list, shippingHeight: record, shippingLabel: string, shippingLength: record, shippingWeight: record, shippingWidth: record, shoppingAdsExcludedCountries: list, sizeSystem: string, sizeType: string, sizes: list, source: string, subscriptionCost: record, targetCountry: string, taxCategory: string, taxes: list, title: string, transitTimeLabel: string, unitPricingBaseMeasure: record, unitPricingMeasure: record>>
# operationId: content.products.list
export def "content-products-list" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --max-results: int # The maximum number of products to return in the response, used for paging.
  --page-token: string # The token returned by the previous request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/products"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, max_results: $max_results, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uploads a product to your Merchant Center account. If an item with the same channel, contentLanguage, offerId, and targetCountry already exists, this method updates that entry.
#
# POST /{merchantId}/products
# Returns: record<additionalImageLinks: list<string>, additionalSizeType: string, adsGrouping: string, adsLabels: list<string>, adsRedirect: string, adult: bool, ageGroup: string, availability: string, availabilityDate: string, brand: string, canonicalLink: string, channel: string, color: string, condition: string, contentLanguage: string, costOfGoodsSold: record<currency: string, value: string>, customAttributes: table<groupValues: list, name: string, value: string>, customLabel0: string, customLabel1: string, customLabel2: string, customLabel3: string, customLabel4: string, description: string, displayAdsId: string, displayAdsLink: string, displayAdsSimilarIds: list<string>, displayAdsTitle: string, displayAdsValue: float, energyEfficiencyClass: string, excludedDestinations: list<string>, expirationDate: string, externalSellerId: string, feedLabel: string, gender: string, googleProductCategory: string, gtin: string, id: string, identifierExists: bool, imageLink: string, includedDestinations: list<string>, installment: record<amount: record<currency: string, value: string>, months: string>, isBundle: bool, itemGroupId: string, kind: string, lifestyleImageLinks: list<string>, link: string, linkTemplate: string, loyaltyPoints: record<name: string, pointsValue: string, ratio: float>, material: string, maxEnergyEfficiencyClass: string, maxHandlingTime: string, minEnergyEfficiencyClass: string, minHandlingTime: string, mobileLink: string, mobileLinkTemplate: string, mpn: string, multipack: string, offerId: string, pattern: string, pause: string, pickupMethod: string, pickupSla: string, price: record<currency: string, value: string>, productDetails: table<attributeName: string, attributeValue: string, sectionName: string>, productHeight: record<unit: string, value: float>, productHighlights: list<string>, productLength: record<unit: string, value: float>, productTypes: list<string>, productWeight: record<unit: string, value: float>, productWidth: record<unit: string, value: float>, promotionIds: list<string>, salePrice: record<currency: string, value: string>, salePriceEffectiveDate: string, sellOnGoogleQuantity: string, shipping: table<country: string, locationGroupName: string, locationId: string, maxHandlingTime: string, maxTransitTime: string, minHandlingTime: string, minTransitTime: string, postalCode: string, price: record, region: string, service: string>, shippingHeight: record<unit: string, value: float>, shippingLabel: string, shippingLength: record<unit: string, value: float>, shippingWeight: record<unit: string, value: float>, shippingWidth: record<unit: string, value: float>, shoppingAdsExcludedCountries: list<string>, sizeSystem: string, sizeType: string, sizes: list<string>, source: string, subscriptionCost: record<amount: record<currency: string, value: string>, period: string, periodLength: string>, targetCountry: string, taxCategory: string, taxes: table<country: string, locationId: string, postalCode: string, rate: float, region: string, taxShip: bool>, title: string, transitTimeLabel: string, unitPricingBaseMeasure: record<unit: string, value: string>, unitPricingMeasure: record<unit: string, value: float>>
# operationId: content.products.insert
export def "content-products-insert" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --feed-id: string # The Content API Supplemental Feed ID. If present then product insertion applies to the data in a supplemental feed.
  --additional-image-links: list<string> # Additional URLs of images of the item.
  --additional-size-type: string # Additional cut of the item. Used together with size_type to represent combined size types for apparel items.
  --ads-grouping: string # Used to group items in an arbitrary way. Only for CPA%, discouraged otherwise.
  --ads-labels: list<string> # Similar to ads_grouping, but only works on CPC.
  --ads-redirect: string # Allows advertisers to override the item URL when the product is shown within the context of Product Ads.
  --adult: oneof<nothing, bool> # Should be set to true if the item is targeted towards adults.
  --age-group: string # Target age group of the item.
  --availability: string # Availability status of the item.
  --availability-date: string # The day a pre-ordered product becomes available for delivery, in ISO 8601 format.
  --brand: string # Brand of the item.
  --canonical-link: string # URL for the canonical version of your item's landing page.
  --channel: string # Required. The item's channel (online or local). Acceptable values are: - "`local`" - "`online`"
  --color: string # Color of the item.
  --condition: string # Condition or state of the item.
  --content-language: string # Required. The two-letter ISO 639-1 language code for the item.
  --cost-of-goods-sold: record # shape: {currency?: string, value?: string}
  --custom-attributes: list # A list of custom (merchant-provided) attributes. It can also be used for submitting any attribute of the feed specification in its generic form (for example, `{ "name": "size type", "value": "regular" }`). This is useful for submitting attributes not explicitly exposed by the API, such as additional attributes used for Buy on Google (formerly known as Shopping Actions). — item shape: {groupValues?: list, name?: string, value?: string}
  --custom-label0: string # Custom label 0 for custom grouping of items in a Shopping campaign.
  --custom-label1: string # Custom label 1 for custom grouping of items in a Shopping campaign.
  --custom-label2: string # Custom label 2 for custom grouping of items in a Shopping campaign.
  --custom-label3: string # Custom label 3 for custom grouping of items in a Shopping campaign.
  --custom-label4: string # Custom label 4 for custom grouping of items in a Shopping campaign.
  --description: string # Description of the item.
  --display-ads-id: string # An identifier for an item for dynamic remarketing campaigns.
  --display-ads-link: string # URL directly to your item's landing page for dynamic remarketing campaigns.
  --display-ads-similar-ids: list<string> # Advertiser-specified recommendations.
  --display-ads-title: string # Title of an item for dynamic remarketing campaigns.
  --display-ads-value: float # Offer margin for dynamic remarketing campaigns. (format: double)
  --energy-efficiency-class: string # The energy efficiency class as defined in EU directive 2010/30/EU.
  --excluded-destinations: list<string> # The list of destinations to exclude for this target (corresponds to cleared check boxes in Merchant Center). Products that are excluded from all destinations for more than 7 days are automatically deleted.
  --expiration-date: string # Date on which the item should expire, as specified upon insertion, in ISO 8601 format. The actual expiration date in Google Shopping is exposed in `productstatuses` as `googleExpirationDate` and might be earlier if `expirationDate` is too far in the future.
  --external-seller-id: string # Required for multi-seller accounts. Use this attribute if you're a marketplace uploading products for various sellers to your multi-seller account.
  --feed-label: string # Feed label for the item. Either `targetCountry` or `feedLabel` is required. Must be less than or equal to 20 uppercase letters (A-Z), numbers (0-9), and dashes (-).
  --gender: string # Target gender of the item.
  --google-product-category: string # Google's category of the item (see [Google product taxonomy](https://support.google.com/merchants/answer/1705911)). When querying products, this field will contain the user provided value. There is currently no way to get back the auto assigned google product categories through the API.
  --gtin: string # Global Trade Item Number (GTIN) of the item.
  --id: string # The REST ID of the product. Content API methods that operate on products take this as their `productId` parameter. The REST ID for a product has one of the 2 forms channel:contentLanguage: targetCountry: offerId or channel:contentLanguage:feedLabel: offerId.
  --identifier-exists: oneof<nothing, bool> # False when the item does not have unique product identifiers appropriate to its category, such as GTIN, MPN, and brand. Required according to the Unique Product Identifier Rules for all target countries except for Canada.
  --image-link: string # URL of an image of the item.
  --included-destinations: list<string> # The list of destinations to include for this target (corresponds to checked check boxes in Merchant Center). Default destinations are always included unless provided in `excludedDestinations`.
  --installment: record # shape: {amount?: record, months?: string}
  --is-bundle: oneof<nothing, bool> # Whether the item is a merchant-defined bundle. A bundle is a custom grouping of different products sold by a merchant for a single price.
  --item-group-id: string # Shared identifier for all variants of the same product.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "`content#product`"
  --lifestyle-image-links: list<string> # Additional URLs of lifestyle images of the item. Used to explicitly identify images that showcase your item in a real-world context. See the Help Center article for more information.
  --link: string # URL directly linking to your item's page on your website.
  --link-template: string # URL template for merchant hosted local storefront.
  --loyalty-points: record # shape: {name?: string, pointsValue?: string, ratio?: float}
  --material: string # The material of which the item is made.
  --max-energy-efficiency-class: string # The energy efficiency class as defined in EU directive 2010/30/EU.
  --max-handling-time: string # Maximal product handling time (in business days). (format: int64)
  --min-energy-efficiency-class: string # The energy efficiency class as defined in EU directive 2010/30/EU.
  --min-handling-time: string # Minimal product handling time (in business days). (format: int64)
  --mobile-link: string # URL for the mobile-optimized version of your item's landing page.
  --mobile-link-template: string # URL template for merchant hosted local storefront optimized for mobile devices.
  --mpn: string # Manufacturer Part Number (MPN) of the item.
  --multipack: string # The number of identical products in a merchant-defined multipack. (format: int64)
  --offer-id: string # Required. A unique identifier for the item. Leading and trailing whitespaces are stripped and multiple whitespaces are replaced by a single whitespace upon submission. Only valid unicode characters are accepted. See the products feed specification for details. *Note:* Content API methods that operate on products take the REST ID of the product, *not* this identifier.
  --pattern: string # The item's pattern (for example, polka dots).
  --pause: string # Publication of this item should be temporarily paused. Acceptable values are: - "`ads`"
  --pickup-method: string # The pick up option for the item. Acceptable values are: - "`buy`" - "`reserve`" - "`ship to store`" - "`not supported`"
  --pickup-sla: string # Item store pickup timeline. Acceptable values are: - "`same day`" - "`next day`" - "`2-day`" - "`3-day`" - "`4-day`" - "`5-day`" - "`6-day`" - "`7-day`" - "`multi-week`"
  --price: record # shape: {currency?: string, value?: string}
  --product-details: list # Technical specification or additional product details. — item shape: {attributeName?: string, attributeValue?: string, sectionName?: string}
  --product-height: record # shape: {unit?: string, value?: float}
  --product-highlights: list<string> # Bullet points describing the most relevant highlights of a product.
  --product-length: record # shape: {unit?: string, value?: float}
  --product-types: list<string> # Categories of the item (formatted as in product data specification).
  --product-weight: record # shape: {unit?: string, value?: float}
  --product-width: record # shape: {unit?: string, value?: float}
  --promotion-ids: list<string> # The unique ID of a promotion.
  --sale-price: record # shape: {currency?: string, value?: string}
  --sale-price-effective-date: string # Date range during which the item is on sale (see product data specification ).
  --sell-on-google-quantity: string # The quantity of the product that is available for selling on Google. Supported only for online products. (format: int64)
  --shipping: list # Shipping rules. — item shape: {country?: string, locationGroupName?: string, locationId?: string, maxHandlingTime?: string, maxTransitTime?: string, minHandlingTime?: string, minTransitTime?: string, postalCode?: string, price?: record, region?: string, service?: string}
  --shipping-height: record # shape: {unit?: string, value?: float}
  --shipping-label: string # The shipping label of the product, used to group product in account-level shipping rules.
  --shipping-length: record # shape: {unit?: string, value?: float}
  --shipping-weight: record # shape: {unit?: string, value?: float}
  --shipping-width: record # shape: {unit?: string, value?: float}
  --shopping-ads-excluded-countries: list<string> # List of country codes (ISO 3166-1 alpha-2) to exclude the offer from Shopping Ads destination. Countries from this list are removed from countries configured in MC feed settings.
  --size-system: string # System in which the size is specified. Recommended for apparel items.
  --size-type: string # The cut of the item. Recommended for apparel items.
  --sizes: list<string> # Size of the item. Only one value is allowed. For variants with different sizes, insert a separate product for each size with the same `itemGroupId` value (see size definition).
  --source: string # The source of the offer, that is, how the offer was created. Acceptable values are: - "`api`" - "`crawl`" - "`feed`"
  --subscription-cost: record # shape: {amount?: record, period?: string, periodLength?: string}
  --target-country: string # Required. The CLDR territory code for the item's country of sale.
  --tax-category: string # The tax category of the product, used to configure detailed tax nexus in account-level tax settings.
  --taxes: list # Tax information. — item shape: {country?: string, locationId?: string, postalCode?: string, rate?: float, region?: string, taxShip?: bool}
  --title: string # Title of the item.
  --transit-time-label: string # The transit time label of the product, used to group product in account-level transit time tables.
  --unit-pricing-base-measure: record # shape: {unit?: string, value?: string}
  --unit-pricing-measure: record # shape: {unit?: string, value?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/products"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: feedId, var: feed_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: additionalImageLinks, var: additional_image_links}, {name: additionalSizeType, var: additional_size_type}, {name: adsGrouping, var: ads_grouping}, {name: adsLabels, var: ads_labels}, {name: adsRedirect, var: ads_redirect}, {name: adult, var: adult}, {name: ageGroup, var: age_group}, {name: availability, var: availability}, {name: availabilityDate, var: availability_date}, {name: brand, var: brand}, {name: canonicalLink, var: canonical_link}, {name: channel, var: channel}, {name: color, var: color}, {name: condition, var: condition}, {name: contentLanguage, var: content_language}, {name: costOfGoodsSold, var: cost_of_goods_sold}, {name: customAttributes, var: custom_attributes}, {name: customLabel0, var: custom_label0}, {name: customLabel1, var: custom_label1}, {name: customLabel2, var: custom_label2}, {name: customLabel3, var: custom_label3}, {name: customLabel4, var: custom_label4}, {name: description, var: description}, {name: displayAdsId, var: display_ads_id}, {name: displayAdsLink, var: display_ads_link}, {name: displayAdsSimilarIds, var: display_ads_similar_ids}, {name: displayAdsTitle, var: display_ads_title}, {name: displayAdsValue, var: display_ads_value}, {name: energyEfficiencyClass, var: energy_efficiency_class}, {name: excludedDestinations, var: excluded_destinations}, {name: expirationDate, var: expiration_date}, {name: externalSellerId, var: external_seller_id}, {name: feedLabel, var: feed_label}, {name: gender, var: gender}, {name: googleProductCategory, var: google_product_category}, {name: gtin, var: gtin}, {name: id, var: id}, {name: identifierExists, var: identifier_exists}, {name: imageLink, var: image_link}, {name: includedDestinations, var: included_destinations}, {name: installment, var: installment}, {name: isBundle, var: is_bundle}, {name: itemGroupId, var: item_group_id}, {name: kind, var: kind}, {name: lifestyleImageLinks, var: lifestyle_image_links}, {name: link, var: link}, {name: linkTemplate, var: link_template}, {name: loyaltyPoints, var: loyalty_points}, {name: material, var: material}, {name: maxEnergyEfficiencyClass, var: max_energy_efficiency_class}, {name: maxHandlingTime, var: max_handling_time}, {name: minEnergyEfficiencyClass, var: min_energy_efficiency_class}, {name: minHandlingTime, var: min_handling_time}, {name: mobileLink, var: mobile_link}, {name: mobileLinkTemplate, var: mobile_link_template}, {name: mpn, var: mpn}, {name: multipack, var: multipack}, {name: offerId, var: offer_id}, {name: pattern, var: pattern}, {name: pause, var: pause}, {name: pickupMethod, var: pickup_method}, {name: pickupSla, var: pickup_sla}, {name: price, var: price}, {name: productDetails, var: product_details}, {name: productHeight, var: product_height}, {name: productHighlights, var: product_highlights}, {name: productLength, var: product_length}, {name: productTypes, var: product_types}, {name: productWeight, var: product_weight}, {name: productWidth, var: product_width}, {name: promotionIds, var: promotion_ids}, {name: salePrice, var: sale_price}, {name: salePriceEffectiveDate, var: sale_price_effective_date}, {name: sellOnGoogleQuantity, var: sell_on_google_quantity}, {name: shipping, var: shipping}, {name: shippingHeight, var: shipping_height}, {name: shippingLabel, var: shipping_label}, {name: shippingLength, var: shipping_length}, {name: shippingWeight, var: shipping_weight}, {name: shippingWidth, var: shipping_width}, {name: shoppingAdsExcludedCountries, var: shopping_ads_excluded_countries}, {name: sizeSystem, var: size_system}, {name: sizeType, var: size_type}, {name: sizes, var: sizes}, {name: source, var: source}, {name: subscriptionCost, var: subscription_cost}, {name: targetCountry, var: target_country}, {name: taxCategory, var: tax_category}, {name: taxes, var: taxes}, {name: title, var: title}, {name: transitTimeLabel, var: transit_time_label}, {name: unitPricingBaseMeasure, var: unit_pricing_base_measure}, {name: unitPricingMeasure, var: unit_pricing_measure}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, feed_id: $feed_id, additional_image_links: $additional_image_links, additional_size_type: $additional_size_type, ads_grouping: $ads_grouping, ads_labels: $ads_labels, ads_redirect: $ads_redirect, adult: $adult, age_group: $age_group, availability: $availability, availability_date: $availability_date, brand: $brand, canonical_link: $canonical_link, channel: $channel, color: $color, condition: $condition, content_language: $content_language, cost_of_goods_sold: $cost_of_goods_sold, custom_attributes: $custom_attributes, custom_label0: $custom_label0, custom_label1: $custom_label1, custom_label2: $custom_label2, custom_label3: $custom_label3, custom_label4: $custom_label4, description: $description, display_ads_id: $display_ads_id, display_ads_link: $display_ads_link, display_ads_similar_ids: $display_ads_similar_ids, display_ads_title: $display_ads_title, display_ads_value: $display_ads_value, energy_efficiency_class: $energy_efficiency_class, excluded_destinations: $excluded_destinations, expiration_date: $expiration_date, external_seller_id: $external_seller_id, feed_label: $feed_label, gender: $gender, google_product_category: $google_product_category, gtin: $gtin, id: $id, identifier_exists: $identifier_exists, image_link: $image_link, included_destinations: $included_destinations, installment: $installment, is_bundle: $is_bundle, item_group_id: $item_group_id, kind: $kind, lifestyle_image_links: $lifestyle_image_links, link: $link, link_template: $link_template, loyalty_points: $loyalty_points, material: $material, max_energy_efficiency_class: $max_energy_efficiency_class, max_handling_time: $max_handling_time, min_energy_efficiency_class: $min_energy_efficiency_class, min_handling_time: $min_handling_time, mobile_link: $mobile_link, mobile_link_template: $mobile_link_template, mpn: $mpn, multipack: $multipack, offer_id: $offer_id, pattern: $pattern, pause: $pause, pickup_method: $pickup_method, pickup_sla: $pickup_sla, price: $price, product_details: $product_details, product_height: $product_height, product_highlights: $product_highlights, product_length: $product_length, product_types: $product_types, product_weight: $product_weight, product_width: $product_width, promotion_ids: $promotion_ids, sale_price: $sale_price, sale_price_effective_date: $sale_price_effective_date, sell_on_google_quantity: $sell_on_google_quantity, shipping: $shipping, shipping_height: $shipping_height, shipping_label: $shipping_label, shipping_length: $shipping_length, shipping_weight: $shipping_weight, shipping_width: $shipping_width, shopping_ads_excluded_countries: $shopping_ads_excluded_countries, size_system: $size_system, size_type: $size_type, sizes: $sizes, source: $source, subscription_cost: $subscription_cost, target_country: $target_country, tax_category: $tax_category, taxes: $taxes, title: $title, transit_time_label: $transit_time_label, unit_pricing_base_measure: $unit_pricing_base_measure, unit_pricing_measure: $unit_pricing_measure
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a product from your Merchant Center account.
#
# DELETE /{merchantId}/products/{productId}
# operationId: content.products.delete
export def "content-products-delete" [
  merchant_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --feed-id: string # The Content API Supplemental Feed ID. If present then product deletion applies to the data in a supplemental feed. If absent, entire product will be deleted.
]: nothing -> any {
  http-request {
    method: delete
    path: "/{merchantId}/products/{productId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: productId, var: product_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: feedId, var: feed_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, product_id: $product_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, feed_id: $feed_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a product from your Merchant Center account.
#
# GET /{merchantId}/products/{productId}
# Returns: record<additionalImageLinks: list<string>, additionalSizeType: string, adsGrouping: string, adsLabels: list<string>, adsRedirect: string, adult: bool, ageGroup: string, availability: string, availabilityDate: string, brand: string, canonicalLink: string, channel: string, color: string, condition: string, contentLanguage: string, costOfGoodsSold: record<currency: string, value: string>, customAttributes: table<groupValues: list, name: string, value: string>, customLabel0: string, customLabel1: string, customLabel2: string, customLabel3: string, customLabel4: string, description: string, displayAdsId: string, displayAdsLink: string, displayAdsSimilarIds: list<string>, displayAdsTitle: string, displayAdsValue: float, energyEfficiencyClass: string, excludedDestinations: list<string>, expirationDate: string, externalSellerId: string, feedLabel: string, gender: string, googleProductCategory: string, gtin: string, id: string, identifierExists: bool, imageLink: string, includedDestinations: list<string>, installment: record<amount: record<currency: string, value: string>, months: string>, isBundle: bool, itemGroupId: string, kind: string, lifestyleImageLinks: list<string>, link: string, linkTemplate: string, loyaltyPoints: record<name: string, pointsValue: string, ratio: float>, material: string, maxEnergyEfficiencyClass: string, maxHandlingTime: string, minEnergyEfficiencyClass: string, minHandlingTime: string, mobileLink: string, mobileLinkTemplate: string, mpn: string, multipack: string, offerId: string, pattern: string, pause: string, pickupMethod: string, pickupSla: string, price: record<currency: string, value: string>, productDetails: table<attributeName: string, attributeValue: string, sectionName: string>, productHeight: record<unit: string, value: float>, productHighlights: list<string>, productLength: record<unit: string, value: float>, productTypes: list<string>, productWeight: record<unit: string, value: float>, productWidth: record<unit: string, value: float>, promotionIds: list<string>, salePrice: record<currency: string, value: string>, salePriceEffectiveDate: string, sellOnGoogleQuantity: string, shipping: table<country: string, locationGroupName: string, locationId: string, maxHandlingTime: string, maxTransitTime: string, minHandlingTime: string, minTransitTime: string, postalCode: string, price: record, region: string, service: string>, shippingHeight: record<unit: string, value: float>, shippingLabel: string, shippingLength: record<unit: string, value: float>, shippingWeight: record<unit: string, value: float>, shippingWidth: record<unit: string, value: float>, shoppingAdsExcludedCountries: list<string>, sizeSystem: string, sizeType: string, sizes: list<string>, source: string, subscriptionCost: record<amount: record<currency: string, value: string>, period: string, periodLength: string>, targetCountry: string, taxCategory: string, taxes: table<country: string, locationId: string, postalCode: string, rate: float, region: string, taxShip: bool>, title: string, transitTimeLabel: string, unitPricingBaseMeasure: record<unit: string, value: string>, unitPricingMeasure: record<unit: string, value: float>>
# operationId: content.products.get
export def "content-products-get" [
  merchant_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/products/{productId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: productId, var: product_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, product_id: $product_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing product in your Merchant Center account. Only updates attributes provided in the request.
#
# PATCH /{merchantId}/products/{productId}
# Returns: record<additionalImageLinks: list<string>, additionalSizeType: string, adsGrouping: string, adsLabels: list<string>, adsRedirect: string, adult: bool, ageGroup: string, availability: string, availabilityDate: string, brand: string, canonicalLink: string, channel: string, color: string, condition: string, contentLanguage: string, costOfGoodsSold: record<currency: string, value: string>, customAttributes: table<groupValues: list, name: string, value: string>, customLabel0: string, customLabel1: string, customLabel2: string, customLabel3: string, customLabel4: string, description: string, displayAdsId: string, displayAdsLink: string, displayAdsSimilarIds: list<string>, displayAdsTitle: string, displayAdsValue: float, energyEfficiencyClass: string, excludedDestinations: list<string>, expirationDate: string, externalSellerId: string, feedLabel: string, gender: string, googleProductCategory: string, gtin: string, id: string, identifierExists: bool, imageLink: string, includedDestinations: list<string>, installment: record<amount: record<currency: string, value: string>, months: string>, isBundle: bool, itemGroupId: string, kind: string, lifestyleImageLinks: list<string>, link: string, linkTemplate: string, loyaltyPoints: record<name: string, pointsValue: string, ratio: float>, material: string, maxEnergyEfficiencyClass: string, maxHandlingTime: string, minEnergyEfficiencyClass: string, minHandlingTime: string, mobileLink: string, mobileLinkTemplate: string, mpn: string, multipack: string, offerId: string, pattern: string, pause: string, pickupMethod: string, pickupSla: string, price: record<currency: string, value: string>, productDetails: table<attributeName: string, attributeValue: string, sectionName: string>, productHeight: record<unit: string, value: float>, productHighlights: list<string>, productLength: record<unit: string, value: float>, productTypes: list<string>, productWeight: record<unit: string, value: float>, productWidth: record<unit: string, value: float>, promotionIds: list<string>, salePrice: record<currency: string, value: string>, salePriceEffectiveDate: string, sellOnGoogleQuantity: string, shipping: table<country: string, locationGroupName: string, locationId: string, maxHandlingTime: string, maxTransitTime: string, minHandlingTime: string, minTransitTime: string, postalCode: string, price: record, region: string, service: string>, shippingHeight: record<unit: string, value: float>, shippingLabel: string, shippingLength: record<unit: string, value: float>, shippingWeight: record<unit: string, value: float>, shippingWidth: record<unit: string, value: float>, shoppingAdsExcludedCountries: list<string>, sizeSystem: string, sizeType: string, sizes: list<string>, source: string, subscriptionCost: record<amount: record<currency: string, value: string>, period: string, periodLength: string>, targetCountry: string, taxCategory: string, taxes: table<country: string, locationId: string, postalCode: string, rate: float, region: string, taxShip: bool>, title: string, transitTimeLabel: string, unitPricingBaseMeasure: record<unit: string, value: string>, unitPricingMeasure: record<unit: string, value: float>>
# operationId: content.products.update
export def "content-products-update" [
  merchant_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --update-mask: string # The comma-separated list of product attributes to be updated. Example: `"title,salePrice"`. Attributes specified in the update mask without a value specified in the body will be deleted from the product. *You must specify the update mask to delete attributes.* Only top-level product attributes can be updated. If not defined, product attributes with set values will be updated and other attributes will stay unchanged.
  --additional-image-links: list<string> # Additional URLs of images of the item.
  --additional-size-type: string # Additional cut of the item. Used together with size_type to represent combined size types for apparel items.
  --ads-grouping: string # Used to group items in an arbitrary way. Only for CPA%, discouraged otherwise.
  --ads-labels: list<string> # Similar to ads_grouping, but only works on CPC.
  --ads-redirect: string # Allows advertisers to override the item URL when the product is shown within the context of Product Ads.
  --adult: oneof<nothing, bool> # Should be set to true if the item is targeted towards adults.
  --age-group: string # Target age group of the item.
  --availability: string # Availability status of the item.
  --availability-date: string # The day a pre-ordered product becomes available for delivery, in ISO 8601 format.
  --brand: string # Brand of the item.
  --canonical-link: string # URL for the canonical version of your item's landing page.
  --channel: string # Required. The item's channel (online or local). Acceptable values are: - "`local`" - "`online`"
  --color: string # Color of the item.
  --condition: string # Condition or state of the item.
  --content-language: string # Required. The two-letter ISO 639-1 language code for the item.
  --cost-of-goods-sold: record # shape: {currency?: string, value?: string}
  --custom-attributes: list # A list of custom (merchant-provided) attributes. It can also be used for submitting any attribute of the feed specification in its generic form (for example, `{ "name": "size type", "value": "regular" }`). This is useful for submitting attributes not explicitly exposed by the API, such as additional attributes used for Buy on Google (formerly known as Shopping Actions). — item shape: {groupValues?: list, name?: string, value?: string}
  --custom-label0: string # Custom label 0 for custom grouping of items in a Shopping campaign.
  --custom-label1: string # Custom label 1 for custom grouping of items in a Shopping campaign.
  --custom-label2: string # Custom label 2 for custom grouping of items in a Shopping campaign.
  --custom-label3: string # Custom label 3 for custom grouping of items in a Shopping campaign.
  --custom-label4: string # Custom label 4 for custom grouping of items in a Shopping campaign.
  --description: string # Description of the item.
  --display-ads-id: string # An identifier for an item for dynamic remarketing campaigns.
  --display-ads-link: string # URL directly to your item's landing page for dynamic remarketing campaigns.
  --display-ads-similar-ids: list<string> # Advertiser-specified recommendations.
  --display-ads-title: string # Title of an item for dynamic remarketing campaigns.
  --display-ads-value: float # Offer margin for dynamic remarketing campaigns. (format: double)
  --energy-efficiency-class: string # The energy efficiency class as defined in EU directive 2010/30/EU.
  --excluded-destinations: list<string> # The list of destinations to exclude for this target (corresponds to cleared check boxes in Merchant Center). Products that are excluded from all destinations for more than 7 days are automatically deleted.
  --expiration-date: string # Date on which the item should expire, as specified upon insertion, in ISO 8601 format. The actual expiration date in Google Shopping is exposed in `productstatuses` as `googleExpirationDate` and might be earlier if `expirationDate` is too far in the future.
  --external-seller-id: string # Required for multi-seller accounts. Use this attribute if you're a marketplace uploading products for various sellers to your multi-seller account.
  --feed-label: string # Feed label for the item. Either `targetCountry` or `feedLabel` is required. Must be less than or equal to 20 uppercase letters (A-Z), numbers (0-9), and dashes (-).
  --gender: string # Target gender of the item.
  --google-product-category: string # Google's category of the item (see [Google product taxonomy](https://support.google.com/merchants/answer/1705911)). When querying products, this field will contain the user provided value. There is currently no way to get back the auto assigned google product categories through the API.
  --gtin: string # Global Trade Item Number (GTIN) of the item.
  --id: string # The REST ID of the product. Content API methods that operate on products take this as their `productId` parameter. The REST ID for a product has one of the 2 forms channel:contentLanguage: targetCountry: offerId or channel:contentLanguage:feedLabel: offerId.
  --identifier-exists: oneof<nothing, bool> # False when the item does not have unique product identifiers appropriate to its category, such as GTIN, MPN, and brand. Required according to the Unique Product Identifier Rules for all target countries except for Canada.
  --image-link: string # URL of an image of the item.
  --included-destinations: list<string> # The list of destinations to include for this target (corresponds to checked check boxes in Merchant Center). Default destinations are always included unless provided in `excludedDestinations`.
  --installment: record # shape: {amount?: record, months?: string}
  --is-bundle: oneof<nothing, bool> # Whether the item is a merchant-defined bundle. A bundle is a custom grouping of different products sold by a merchant for a single price.
  --item-group-id: string # Shared identifier for all variants of the same product.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "`content#product`"
  --lifestyle-image-links: list<string> # Additional URLs of lifestyle images of the item. Used to explicitly identify images that showcase your item in a real-world context. See the Help Center article for more information.
  --link: string # URL directly linking to your item's page on your website.
  --link-template: string # URL template for merchant hosted local storefront.
  --loyalty-points: record # shape: {name?: string, pointsValue?: string, ratio?: float}
  --material: string # The material of which the item is made.
  --max-energy-efficiency-class: string # The energy efficiency class as defined in EU directive 2010/30/EU.
  --max-handling-time: string # Maximal product handling time (in business days). (format: int64)
  --min-energy-efficiency-class: string # The energy efficiency class as defined in EU directive 2010/30/EU.
  --min-handling-time: string # Minimal product handling time (in business days). (format: int64)
  --mobile-link: string # URL for the mobile-optimized version of your item's landing page.
  --mobile-link-template: string # URL template for merchant hosted local storefront optimized for mobile devices.
  --mpn: string # Manufacturer Part Number (MPN) of the item.
  --multipack: string # The number of identical products in a merchant-defined multipack. (format: int64)
  --offer-id: string # Required. A unique identifier for the item. Leading and trailing whitespaces are stripped and multiple whitespaces are replaced by a single whitespace upon submission. Only valid unicode characters are accepted. See the products feed specification for details. *Note:* Content API methods that operate on products take the REST ID of the product, *not* this identifier.
  --pattern: string # The item's pattern (for example, polka dots).
  --pause: string # Publication of this item should be temporarily paused. Acceptable values are: - "`ads`"
  --pickup-method: string # The pick up option for the item. Acceptable values are: - "`buy`" - "`reserve`" - "`ship to store`" - "`not supported`"
  --pickup-sla: string # Item store pickup timeline. Acceptable values are: - "`same day`" - "`next day`" - "`2-day`" - "`3-day`" - "`4-day`" - "`5-day`" - "`6-day`" - "`7-day`" - "`multi-week`"
  --price: record # shape: {currency?: string, value?: string}
  --product-details: list # Technical specification or additional product details. — item shape: {attributeName?: string, attributeValue?: string, sectionName?: string}
  --product-height: record # shape: {unit?: string, value?: float}
  --product-highlights: list<string> # Bullet points describing the most relevant highlights of a product.
  --product-length: record # shape: {unit?: string, value?: float}
  --product-types: list<string> # Categories of the item (formatted as in product data specification).
  --product-weight: record # shape: {unit?: string, value?: float}
  --product-width: record # shape: {unit?: string, value?: float}
  --promotion-ids: list<string> # The unique ID of a promotion.
  --sale-price: record # shape: {currency?: string, value?: string}
  --sale-price-effective-date: string # Date range during which the item is on sale (see product data specification ).
  --sell-on-google-quantity: string # The quantity of the product that is available for selling on Google. Supported only for online products. (format: int64)
  --shipping: list # Shipping rules. — item shape: {country?: string, locationGroupName?: string, locationId?: string, maxHandlingTime?: string, maxTransitTime?: string, minHandlingTime?: string, minTransitTime?: string, postalCode?: string, price?: record, region?: string, service?: string}
  --shipping-height: record # shape: {unit?: string, value?: float}
  --shipping-label: string # The shipping label of the product, used to group product in account-level shipping rules.
  --shipping-length: record # shape: {unit?: string, value?: float}
  --shipping-weight: record # shape: {unit?: string, value?: float}
  --shipping-width: record # shape: {unit?: string, value?: float}
  --shopping-ads-excluded-countries: list<string> # List of country codes (ISO 3166-1 alpha-2) to exclude the offer from Shopping Ads destination. Countries from this list are removed from countries configured in MC feed settings.
  --size-system: string # System in which the size is specified. Recommended for apparel items.
  --size-type: string # The cut of the item. Recommended for apparel items.
  --sizes: list<string> # Size of the item. Only one value is allowed. For variants with different sizes, insert a separate product for each size with the same `itemGroupId` value (see size definition).
  --source: string # The source of the offer, that is, how the offer was created. Acceptable values are: - "`api`" - "`crawl`" - "`feed`"
  --subscription-cost: record # shape: {amount?: record, period?: string, periodLength?: string}
  --target-country: string # Required. The CLDR territory code for the item's country of sale.
  --tax-category: string # The tax category of the product, used to configure detailed tax nexus in account-level tax settings.
  --taxes: list # Tax information. — item shape: {country?: string, locationId?: string, postalCode?: string, rate?: float, region?: string, taxShip?: bool}
  --title: string # Title of the item.
  --transit-time-label: string # The transit time label of the product, used to group product in account-level transit time tables.
  --unit-pricing-base-measure: record # shape: {unit?: string, value?: string}
  --unit-pricing-measure: record # shape: {unit?: string, value?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/{merchantId}/products/{productId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: productId, var: product_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: additionalImageLinks, var: additional_image_links}, {name: additionalSizeType, var: additional_size_type}, {name: adsGrouping, var: ads_grouping}, {name: adsLabels, var: ads_labels}, {name: adsRedirect, var: ads_redirect}, {name: adult, var: adult}, {name: ageGroup, var: age_group}, {name: availability, var: availability}, {name: availabilityDate, var: availability_date}, {name: brand, var: brand}, {name: canonicalLink, var: canonical_link}, {name: channel, var: channel}, {name: color, var: color}, {name: condition, var: condition}, {name: contentLanguage, var: content_language}, {name: costOfGoodsSold, var: cost_of_goods_sold}, {name: customAttributes, var: custom_attributes}, {name: customLabel0, var: custom_label0}, {name: customLabel1, var: custom_label1}, {name: customLabel2, var: custom_label2}, {name: customLabel3, var: custom_label3}, {name: customLabel4, var: custom_label4}, {name: description, var: description}, {name: displayAdsId, var: display_ads_id}, {name: displayAdsLink, var: display_ads_link}, {name: displayAdsSimilarIds, var: display_ads_similar_ids}, {name: displayAdsTitle, var: display_ads_title}, {name: displayAdsValue, var: display_ads_value}, {name: energyEfficiencyClass, var: energy_efficiency_class}, {name: excludedDestinations, var: excluded_destinations}, {name: expirationDate, var: expiration_date}, {name: externalSellerId, var: external_seller_id}, {name: feedLabel, var: feed_label}, {name: gender, var: gender}, {name: googleProductCategory, var: google_product_category}, {name: gtin, var: gtin}, {name: id, var: id}, {name: identifierExists, var: identifier_exists}, {name: imageLink, var: image_link}, {name: includedDestinations, var: included_destinations}, {name: installment, var: installment}, {name: isBundle, var: is_bundle}, {name: itemGroupId, var: item_group_id}, {name: kind, var: kind}, {name: lifestyleImageLinks, var: lifestyle_image_links}, {name: link, var: link}, {name: linkTemplate, var: link_template}, {name: loyaltyPoints, var: loyalty_points}, {name: material, var: material}, {name: maxEnergyEfficiencyClass, var: max_energy_efficiency_class}, {name: maxHandlingTime, var: max_handling_time}, {name: minEnergyEfficiencyClass, var: min_energy_efficiency_class}, {name: minHandlingTime, var: min_handling_time}, {name: mobileLink, var: mobile_link}, {name: mobileLinkTemplate, var: mobile_link_template}, {name: mpn, var: mpn}, {name: multipack, var: multipack}, {name: offerId, var: offer_id}, {name: pattern, var: pattern}, {name: pause, var: pause}, {name: pickupMethod, var: pickup_method}, {name: pickupSla, var: pickup_sla}, {name: price, var: price}, {name: productDetails, var: product_details}, {name: productHeight, var: product_height}, {name: productHighlights, var: product_highlights}, {name: productLength, var: product_length}, {name: productTypes, var: product_types}, {name: productWeight, var: product_weight}, {name: productWidth, var: product_width}, {name: promotionIds, var: promotion_ids}, {name: salePrice, var: sale_price}, {name: salePriceEffectiveDate, var: sale_price_effective_date}, {name: sellOnGoogleQuantity, var: sell_on_google_quantity}, {name: shipping, var: shipping}, {name: shippingHeight, var: shipping_height}, {name: shippingLabel, var: shipping_label}, {name: shippingLength, var: shipping_length}, {name: shippingWeight, var: shipping_weight}, {name: shippingWidth, var: shipping_width}, {name: shoppingAdsExcludedCountries, var: shopping_ads_excluded_countries}, {name: sizeSystem, var: size_system}, {name: sizeType, var: size_type}, {name: sizes, var: sizes}, {name: source, var: source}, {name: subscriptionCost, var: subscription_cost}, {name: targetCountry, var: target_country}, {name: taxCategory, var: tax_category}, {name: taxes, var: taxes}, {name: title, var: title}, {name: transitTimeLabel, var: transit_time_label}, {name: unitPricingBaseMeasure, var: unit_pricing_base_measure}, {name: unitPricingMeasure, var: unit_pricing_measure}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, product_id: $product_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, update_mask: $update_mask, additional_image_links: $additional_image_links, additional_size_type: $additional_size_type, ads_grouping: $ads_grouping, ads_labels: $ads_labels, ads_redirect: $ads_redirect, adult: $adult, age_group: $age_group, availability: $availability, availability_date: $availability_date, brand: $brand, canonical_link: $canonical_link, channel: $channel, color: $color, condition: $condition, content_language: $content_language, cost_of_goods_sold: $cost_of_goods_sold, custom_attributes: $custom_attributes, custom_label0: $custom_label0, custom_label1: $custom_label1, custom_label2: $custom_label2, custom_label3: $custom_label3, custom_label4: $custom_label4, description: $description, display_ads_id: $display_ads_id, display_ads_link: $display_ads_link, display_ads_similar_ids: $display_ads_similar_ids, display_ads_title: $display_ads_title, display_ads_value: $display_ads_value, energy_efficiency_class: $energy_efficiency_class, excluded_destinations: $excluded_destinations, expiration_date: $expiration_date, external_seller_id: $external_seller_id, feed_label: $feed_label, gender: $gender, google_product_category: $google_product_category, gtin: $gtin, id: $id, identifier_exists: $identifier_exists, image_link: $image_link, included_destinations: $included_destinations, installment: $installment, is_bundle: $is_bundle, item_group_id: $item_group_id, kind: $kind, lifestyle_image_links: $lifestyle_image_links, link: $link, link_template: $link_template, loyalty_points: $loyalty_points, material: $material, max_energy_efficiency_class: $max_energy_efficiency_class, max_handling_time: $max_handling_time, min_energy_efficiency_class: $min_energy_efficiency_class, min_handling_time: $min_handling_time, mobile_link: $mobile_link, mobile_link_template: $mobile_link_template, mpn: $mpn, multipack: $multipack, offer_id: $offer_id, pattern: $pattern, pause: $pause, pickup_method: $pickup_method, pickup_sla: $pickup_sla, price: $price, product_details: $product_details, product_height: $product_height, product_highlights: $product_highlights, product_length: $product_length, product_types: $product_types, product_weight: $product_weight, product_width: $product_width, promotion_ids: $promotion_ids, sale_price: $sale_price, sale_price_effective_date: $sale_price_effective_date, sell_on_google_quantity: $sell_on_google_quantity, shipping: $shipping, shipping_height: $shipping_height, shipping_label: $shipping_label, shipping_length: $shipping_length, shipping_weight: $shipping_weight, shipping_width: $shipping_width, shopping_ads_excluded_countries: $shopping_ads_excluded_countries, size_system: $size_system, size_type: $size_type, sizes: $sizes, source: $source, subscription_cost: $subscription_cost, target_country: $target_country, tax_category: $tax_category, taxes: $taxes, title: $title, transit_time_label: $transit_time_label, unit_pricing_base_measure: $unit_pricing_base_measure, unit_pricing_measure: $unit_pricing_measure
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the local inventory of a product in your Merchant Center account.
#
# POST /{merchantId}/products/{productId}/localinventory
# Returns: record<availability: string, customAttributes: table<groupValues: list, name: string, value: string>, instoreProductLocation: string, kind: string, pickupMethod: string, pickupSla: string, price: record<currency: string, value: string>, quantity: int, salePrice: record<currency: string, value: string>, salePriceEffectiveDate: string, storeCode: string>
# operationId: content.localinventory.insert
export def "content-localinventory-insert" [
  merchant_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --availability: string # Availability of the product. For accepted attribute values, see the local product inventory feed specification.
  --custom-attributes: list # A list of custom (merchant-provided) attributes. Can also be used to submit any attribute of the feed specification in its generic form, for example, `{ "name": "size type", "value": "regular" }`. — item shape: {groupValues?: list, name?: string, value?: string}
  --instore-product-location: string # In-store product location.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "`content#localInventory`"
  --pickup-method: string # Supported pickup method for this offer. Unless the value is "not supported", this field must be submitted together with `pickupSla`. For accepted attribute values, see the local product inventory feed specification.
  --pickup-sla: string # Expected date that an order will be ready for pickup relative to the order date. Must be submitted together with `pickupMethod`. For accepted attribute values, see the local product inventory feed specification.
  --price: record # shape: {currency?: string, value?: string}
  --quantity: int # Quantity of the product. Must be nonnegative. (format: uint32)
  --sale-price: record # shape: {currency?: string, value?: string}
  --sale-price-effective-date: string # A date range represented by a pair of ISO 8601 dates separated by a space, comma, or slash. Both dates may be specified as 'null' if undecided.
  --store-code: string # Required. Store code of this local inventory resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/products/{productId}/localinventory"
    path_params: [{name: merchantId, var: merchant_id}, {name: productId, var: product_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: availability, var: availability}, {name: customAttributes, var: custom_attributes}, {name: instoreProductLocation, var: instore_product_location}, {name: kind, var: kind}, {name: pickupMethod, var: pickup_method}, {name: pickupSla, var: pickup_sla}, {name: price, var: price}, {name: quantity, var: quantity}, {name: salePrice, var: sale_price}, {name: salePriceEffectiveDate, var: sale_price_effective_date}, {name: storeCode, var: store_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, product_id: $product_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, availability: $availability, custom_attributes: $custom_attributes, instore_product_location: $instore_product_location, kind: $kind, pickup_method: $pickup_method, pickup_sla: $pickup_sla, price: $price, quantity: $quantity, sale_price: $sale_price, sale_price_effective_date: $sale_price_effective_date, store_code: $store_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the regional inventory of a product in your Merchant Center account. If a regional inventory with the same region ID already exists, this method updates that entry.
#
# POST /{merchantId}/products/{productId}/regionalinventory
# Returns: record<availability: string, customAttributes: table<groupValues: list, name: string, value: string>, kind: string, price: record<currency: string, value: string>, regionId: string, salePrice: record<currency: string, value: string>, salePriceEffectiveDate: string>
# operationId: content.regionalinventory.insert
export def "content-regionalinventory-insert" [
  merchant_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --availability: string # The availability of the product.
  --custom-attributes: list # A list of custom (merchant-provided) attributes. It can also be used for submitting any attribute of the feed specification in its generic form. — item shape: {groupValues?: list, name?: string, value?: string}
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "`content#regionalInventory`".
  --price: record # shape: {currency?: string, value?: string}
  --region-id: string # The ID uniquely identifying each region.
  --sale-price: record # shape: {currency?: string, value?: string}
  --sale-price-effective-date: string # A date range represented by a pair of ISO 8601 dates separated by a space, comma, or slash. Both dates might be specified as 'null' if undecided.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/products/{productId}/regionalinventory"
    path_params: [{name: merchantId, var: merchant_id}, {name: productId, var: product_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: availability, var: availability}, {name: customAttributes, var: custom_attributes}, {name: kind, var: kind}, {name: price, var: price}, {name: regionId, var: region_id}, {name: salePrice, var: sale_price}, {name: salePriceEffectiveDate, var: sale_price_effective_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, product_id: $product_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, availability: $availability, custom_attributes: $custom_attributes, kind: $kind, price: $price, region_id: $region_id, sale_price: $sale_price, sale_price_effective_date: $sale_price_effective_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the statuses of the products in your Merchant Center account.
#
# GET /{merchantId}/productstatuses
# Returns: record<kind: string, nextPageToken: string, resources: table<creationDate: string, destinationStatuses: list, googleExpirationDate: string, itemLevelIssues: list, kind: string, lastUpdateDate: string, link: string, productId: string, title: string>>
# operationId: content.productstatuses.list
export def "content-productstatuses-list" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --destinations: list<string> # If set, only issues for the specified destinations are returned, otherwise only issues for the Shopping destination.
  --max-results: int # The maximum number of product statuses to return in the response, used for paging.
  --page-token: string # The token returned by the previous request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/productstatuses"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: destinations, var: destinations, style: multi}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, destinations: $destinations, max_results: $max_results, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the status of a product from your Merchant Center account.
#
# GET /{merchantId}/productstatuses/{productId}
# Returns: record<creationDate: string, destinationStatuses: table<approvedCountries: list, destination: string, disapprovedCountries: list, pendingCountries: list, status: string>, googleExpirationDate: string, itemLevelIssues: table<applicableCountries: list, attributeName: string, code: string, description: string, destination: string, detail: string, documentation: string, resolution: string, servability: string>, kind: string, lastUpdateDate: string, link: string, productId: string, title: string>
# operationId: content.productstatuses.get
export def "content-productstatuses-get" [
  merchant_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --destinations: list<string> # If set, only issues for the specified destinations are returned, otherwise only issues for the Shopping destination.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/productstatuses/{productId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: productId, var: product_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: destinations, var: destinations, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, product_id: $product_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, destinations: $destinations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the metrics report for a given Repricing product.
#
# GET /{merchantId}/productstatuses/{productId}/repricingreports
# Returns: record<nextPageToken: string, repricingProductReports: table<applicationCount: string, buyboxWinningProductStats: record, date: record, highWatermark: record, inapplicabilityDetails: list, lowWatermark: record, orderItemCount: int, ruleIds: list, totalGmv: record, type: string>>
# operationId: content.productstatuses.repricingreports.list
export def "content-productstatuses-repricingreports-list" [
  merchant_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --end-date: string # Gets Repricing reports on and before this date in the merchant's timezone. You can only retrieve data up to 7 days ago (default) or earlier. Format is YYYY-MM-DD.
  --page-size: int # Maximum number of days of reports to return. There can be more than one rule report returned per day. For example, if 3 rule types got applied to the same product within a 24-hour period, then a page_size of 1 will return 3 rule reports. The page size defaults to 50 and values above 1000 are coerced to 1000. This service may return fewer days of reports than this value, for example, if the time between your start and end date is less than the page size.
  --page-token: string # Token (if provided) to retrieve the subsequent page. All other parameters must match the original call that provided the page token.
  --rule-id: string # Id of the Repricing rule. If specified, only gets this rule's reports.
  --start-date: string # Gets Repricing reports on and after this date in the merchant's timezone, up to one year ago. Do not use a start date later than 7 days ago (default). Format is YYYY-MM-DD.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/productstatuses/{productId}/repricingreports"
    path_params: [{name: merchantId, var: merchant_id}, {name: productId, var: product_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: endDate, var: end_date}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: ruleId, var: rule_id}, {name: startDate, var: start_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, product_id: $product_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, end_date: $end_date, page_size: $page_size, page_token: $page_token, rule_id: $rule_id, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inserts a promotion for your Merchant Center account. If the promotion already exists, then it updates the promotion instead. To [end or delete] (https://developers.google.com/shopping-content/guides/promotions#end_a_promotion) a promotion update the time period of the promotion to a time that has already passed.
#
# POST /{merchantId}/promotions
# Returns: record<brand: list<string>, brandExclusion: list<string>, contentLanguage: string, couponValueType: string, freeGiftDescription: string, freeGiftItemId: string, freeGiftValue: record<currency: string, value: string>, genericRedemptionCode: string, getThisQuantityDiscounted: int, id: string, itemGroupId: list<string>, itemGroupIdExclusion: list<string>, itemId: list<string>, itemIdExclusion: list<string>, limitQuantity: int, limitValue: record<currency: string, value: string>, longTitle: string, minimumPurchaseAmount: record<currency: string, value: string>, minimumPurchaseQuantity: int, moneyBudget: record<currency: string, value: string>, moneyOffAmount: record<currency: string, value: string>, offerType: string, orderLimit: int, percentOff: int, productApplicability: string, productType: list<string>, productTypeExclusion: list<string>, promotionDestinationIds: list<string>, promotionDisplayDates: string, promotionDisplayTimePeriod: record<endTime: string, startTime: string>, promotionEffectiveDates: string, promotionEffectiveTimePeriod: record<endTime: string, startTime: string>, promotionId: string, promotionStatus: record<creationDate: string, destinationStatuses: list<record>, lastUpdateDate: string, promotionIssue: list<record>>, promotionUrl: string, redemptionChannel: list<string>, shippingServiceNames: list<string>, storeApplicability: string, storeCode: list<string>, storeCodeExclusion: list<string>, targetCountry: string>
# operationId: content.promotions.create
export def "content-promotions-create" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --brand: list<string> # Product filter by brand for the promotion.
  --brand-exclusion: list<string> # Product filter by brand exclusion for the promotion.
  --content-language: string # Required. The content language used as part of the unique identifier. `en` content language is available for all target countries. `fr` content language is available for `CA` and `FR` target countries. `de` content language is available for `DE` target country. `nl` content language is available for `NL` target country. `it` content language is available for `IT` target country. `pt` content language is available for `BR` target country. `ja` content language is available for `JP` target country. `ko` content language is available for `KR` target country.
  --coupon-value-type: string@coupon-value-type-completer # Required. Coupon value type for the promotion.
  --free-gift-description: string # Free gift description for the promotion.
  --free-gift-item-id: string # Free gift item ID for the promotion.
  --free-gift-value: record # The price represented as a number and currency. — shape: {currency?: string, value?: string}
  --generic-redemption-code: string # Generic redemption code for the promotion. To be used with the `offerType` field.
  --get-this-quantity-discounted: int # The number of items discounted in the promotion. (format: int32)
  --item-group-id: list<string> # Product filter by item group ID for the promotion.
  --item-group-id-exclusion: list<string> # Product filter by item group ID exclusion for the promotion.
  --item-id: list<string> # Product filter by item ID for the promotion.
  --item-id-exclusion: list<string> # Product filter by item ID exclusion for the promotion.
  --limit-quantity: int # Maximum purchase quantity for the promotion. (format: int32)
  --limit-value: record # The price represented as a number and currency. — shape: {currency?: string, value?: string}
  --long-title: string # Required. Long title for the promotion.
  --minimum-purchase-amount: record # The price represented as a number and currency. — shape: {currency?: string, value?: string}
  --minimum-purchase-quantity: int # Minimum purchase quantity for the promotion. (format: int32)
  --money-budget: record # The price represented as a number and currency. — shape: {currency?: string, value?: string}
  --money-off-amount: record # The price represented as a number and currency. — shape: {currency?: string, value?: string}
  --offer-type: string@offer-type-completer # Required. Type of the promotion.
  --order-limit: int # Order limit for the promotion. (format: int32)
  --percent-off: int # The percentage discount offered in the promotion. (format: int32)
  --product-applicability: string@product-applicability-completer # Required. Applicability of the promotion to either all products or only specific products.
  --product-type: list<string> # Product filter by product type for the promotion.
  --product-type-exclusion: list<string> # Product filter by product type exclusion for the promotion.
  --promotion-destination-ids: list<string> # Destination ID for the promotion.
  --promotion-display-dates: string # String representation of the promotion display dates. Deprecated. Use `promotion_display_time_period` instead.
  --promotion-display-time-period: record # A message that represents a time period. — shape: {endTime?: string, startTime?: string}
  --promotion-effective-dates: string # String representation of the promotion effective dates. Deprecated. Use `promotion_effective_time_period` instead.
  --promotion-effective-time-period: record # A message that represents a time period. — shape: {endTime?: string, startTime?: string}
  --promotion-id: string # Required. The user provided promotion ID to uniquely identify the promotion.
  --promotion-status: record # The status of the promotion. — shape: {creationDate?: string, destinationStatuses?: list, lastUpdateDate?: string, promotionIssue?: list}
  --promotion-url: string # URL to the page on the merchant's site where the promotion shows. Local Inventory ads promotions throw an error if no promo url is included. URL is used to confirm that the promotion is valid and can be redeemed.
  --redemption-channel: list<string> # Required. Redemption channel for the promotion. At least one channel is required.
  --shipping-service-names: list<string> # Shipping service names for the promotion.
  --store-applicability: string@store-applicability-completer # Whether the promotion applies to all stores, or only specified stores. Local Inventory ads promotions throw an error if no store applicability is included. An INVALID_ARGUMENT error is thrown if store_applicability is set to ALL_STORES and store_code or score_code_exclusion is set to a value.
  --store-code: list<string> # Store codes to include for the promotion.
  --store-code-exclusion: list<string> # Store codes to exclude for the promotion.
  --target-country: string # Required. The target country used as part of the unique identifier. Can be `AU`, `CA`, `DE`, `FR`, `GB`, `IN`, `US`, `BR`, `ES`, `NL`, `JP`, `IT` or `KR`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/promotions"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: brand, var: brand}, {name: brandExclusion, var: brand_exclusion}, {name: contentLanguage, var: content_language}, {name: couponValueType, var: coupon_value_type}, {name: freeGiftDescription, var: free_gift_description}, {name: freeGiftItemId, var: free_gift_item_id}, {name: freeGiftValue, var: free_gift_value}, {name: genericRedemptionCode, var: generic_redemption_code}, {name: getThisQuantityDiscounted, var: get_this_quantity_discounted}, {name: itemGroupId, var: item_group_id}, {name: itemGroupIdExclusion, var: item_group_id_exclusion}, {name: itemId, var: item_id}, {name: itemIdExclusion, var: item_id_exclusion}, {name: limitQuantity, var: limit_quantity}, {name: limitValue, var: limit_value}, {name: longTitle, var: long_title}, {name: minimumPurchaseAmount, var: minimum_purchase_amount}, {name: minimumPurchaseQuantity, var: minimum_purchase_quantity}, {name: moneyBudget, var: money_budget}, {name: moneyOffAmount, var: money_off_amount}, {name: offerType, var: offer_type}, {name: orderLimit, var: order_limit}, {name: percentOff, var: percent_off}, {name: productApplicability, var: product_applicability}, {name: productType, var: product_type}, {name: productTypeExclusion, var: product_type_exclusion}, {name: promotionDestinationIds, var: promotion_destination_ids}, {name: promotionDisplayDates, var: promotion_display_dates}, {name: promotionDisplayTimePeriod, var: promotion_display_time_period}, {name: promotionEffectiveDates, var: promotion_effective_dates}, {name: promotionEffectiveTimePeriod, var: promotion_effective_time_period}, {name: promotionId, var: promotion_id}, {name: promotionStatus, var: promotion_status}, {name: promotionUrl, var: promotion_url}, {name: redemptionChannel, var: redemption_channel}, {name: shippingServiceNames, var: shipping_service_names}, {name: storeApplicability, var: store_applicability}, {name: storeCode, var: store_code}, {name: storeCodeExclusion, var: store_code_exclusion}, {name: targetCountry, var: target_country}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, brand: $brand, brand_exclusion: $brand_exclusion, content_language: $content_language, coupon_value_type: $coupon_value_type, free_gift_description: $free_gift_description, free_gift_item_id: $free_gift_item_id, free_gift_value: $free_gift_value, generic_redemption_code: $generic_redemption_code, get_this_quantity_discounted: $get_this_quantity_discounted, item_group_id: $item_group_id, item_group_id_exclusion: $item_group_id_exclusion, item_id: $item_id, item_id_exclusion: $item_id_exclusion, limit_quantity: $limit_quantity, limit_value: $limit_value, long_title: $long_title, minimum_purchase_amount: $minimum_purchase_amount, minimum_purchase_quantity: $minimum_purchase_quantity, money_budget: $money_budget, money_off_amount: $money_off_amount, offer_type: $offer_type, order_limit: $order_limit, percent_off: $percent_off, product_applicability: $product_applicability, product_type: $product_type, product_type_exclusion: $product_type_exclusion, promotion_destination_ids: $promotion_destination_ids, promotion_display_dates: $promotion_display_dates, promotion_display_time_period: $promotion_display_time_period, promotion_effective_dates: $promotion_effective_dates, promotion_effective_time_period: $promotion_effective_time_period, promotion_id: $promotion_id, promotion_status: $promotion_status, promotion_url: $promotion_url, redemption_channel: $redemption_channel, shipping_service_names: $shipping_service_names, store_applicability: $store_applicability, store_code: $store_code, store_code_exclusion: $store_code_exclusion, target_country: $target_country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a promotion from your Merchant Center account.
#
# GET /{merchantId}/promotions/{id}
# Returns: record<brand: list<string>, brandExclusion: list<string>, contentLanguage: string, couponValueType: string, freeGiftDescription: string, freeGiftItemId: string, freeGiftValue: record<currency: string, value: string>, genericRedemptionCode: string, getThisQuantityDiscounted: int, id: string, itemGroupId: list<string>, itemGroupIdExclusion: list<string>, itemId: list<string>, itemIdExclusion: list<string>, limitQuantity: int, limitValue: record<currency: string, value: string>, longTitle: string, minimumPurchaseAmount: record<currency: string, value: string>, minimumPurchaseQuantity: int, moneyBudget: record<currency: string, value: string>, moneyOffAmount: record<currency: string, value: string>, offerType: string, orderLimit: int, percentOff: int, productApplicability: string, productType: list<string>, productTypeExclusion: list<string>, promotionDestinationIds: list<string>, promotionDisplayDates: string, promotionDisplayTimePeriod: record<endTime: string, startTime: string>, promotionEffectiveDates: string, promotionEffectiveTimePeriod: record<endTime: string, startTime: string>, promotionId: string, promotionStatus: record<creationDate: string, destinationStatuses: list<record>, lastUpdateDate: string, promotionIssue: list<record>>, promotionUrl: string, redemptionChannel: list<string>, shippingServiceNames: list<string>, storeApplicability: string, storeCode: list<string>, storeCodeExclusion: list<string>, targetCountry: string>
# operationId: content.promotions.get
export def "content-promotions-get" [
  merchant_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/promotions/{id}"
    path_params: [{name: merchantId, var: merchant_id}, {name: id, var: id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, id: $id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a Merchant Center account's pubsub notification settings.
#
# GET /{merchantId}/pubsubnotificationsettings
# Returns: record<cloudTopicName: string, kind: string, registeredEvents: list<string>>
# operationId: content.pubsubnotificationsettings.get
export def "content-pubsubnotificationsettings-get" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/pubsubnotificationsettings"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Register a Merchant Center account for pubsub notifications. Note that cloud topic name shouldn't be provided as part of the request.
#
# PUT /{merchantId}/pubsubnotificationsettings
# Returns: record<cloudTopicName: string, kind: string, registeredEvents: list<string>>
# operationId: content.pubsubnotificationsettings.update
export def "content-pubsubnotificationsettings-update" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cloud-topic-name: string # Cloud pub/sub topic to which notifications are sent (read-only).
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "`content#pubsubNotificationSettings`"
  --registered-events: list<string> # List of event types. Acceptable values are: - "`orderPendingShipment`"
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{merchantId}/pubsubnotificationsettings"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: cloudTopicName, var: cloud_topic_name}, {name: kind, var: kind}, {name: registeredEvents, var: registered_events}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cloud_topic_name: $cloud_topic_name, kind: $kind, registered_events: $registered_events
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the daily call quota and usage per method for your Merchant Center account.
#
# GET /{merchantId}/quotas
# Returns: record<methodQuotas: table<method: string, quotaLimit: string, quotaUsage: string>, nextPageToken: string>
# operationId: content.quotas.list
export def "content-quotas-list" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # The maximum number of quotas to return in the response, used for paging. Defaults to 500; values above 1000 will be coerced to 1000.
  --page-token: string # Token (if provided) to retrieve the subsequent page. All other parameters must match the original call that provided the page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/quotas"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates recommendations for a merchant.
#
# GET /{merchantId}/recommendations/generate
# Returns: record<recommendations: table<additionalCallToAction: list, additionalDescriptions: list, creative: list, defaultCallToAction: record, defaultDescription: string, numericalImpact: int, paid: bool, recommendationName: string, subType: string, title: string, type: string>, responseToken: string>
# operationId: content.recommendations.generate
export def "content-recommendations-generate" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --allowed-tag: list<string> # Optional. List of allowed tags. Tags are a set of predefined strings that describe the category that individual recommendation types. User can specify zero or more tags in this field to indicate what group of recommendations they want to receive. Current list of supported tags: - TREND
  --language-code: string # Optional. Language code of the client. If not set, the result will be in default language (English). This language code affects all fields prefixed with "localized". This should be set to ISO 639-1 country code. List of currently verified supported language code: en, fr, cs, da, de, es, it, nl, no, pl, pt, pt, fi, sv, vi, tr, th, ko, zh-CN, zh-TW, ja, id, hi
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/recommendations/generate"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: allowedTag, var: allowed_tag, style: multi}, {name: languageCode, var: language_code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, allowed_tag: $allowed_tag, language_code: $language_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reports an interaction on a recommendation for a merchant.
#
# POST /{merchantId}/recommendations/reportInteraction
# operationId: content.recommendations.reportInteraction
export def "content-recommendations-report-interaction" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --interaction-type: string@interaction-type-completer # Required. Type of the interaction that is reported, for example INTERACTION_CLICK.
  --response-token: string # Required. Token of the response when recommendation was returned.
  --subtype: string # Optional. Subtype of the recommendations this interaction happened on. This field must be set only to the value that is returned by {@link `RecommendationsService.GenerateRecommendations`} call.
  --type: string # Required. Type of the recommendations on which this interaction happened. This field must be set only to the value that is returned by {@link `GenerateRecommendationsResponse`} call.
]: any -> any {
  $in | http-request {
    method: post
    path: "/{merchantId}/recommendations/reportInteraction"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: interactionType, var: interaction_type}, {name: responseToken, var: response_token}, {name: subtype, var: subtype}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, interaction_type: $interaction_type, response_token: $response_token, subtype: $subtype, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the regions in your Merchant Center account.
#
# GET /{merchantId}/regions
# Returns: record<nextPageToken: string, regions: table<displayName: string, geotargetArea: record, merchantId: string, postalCodeArea: record, regionId: string, regionalInventoryEligible: bool, shippingEligible: bool>>
# operationId: content.regions.list
export def "content-regions-list" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # The maximum number of regions to return. The service may return fewer than this value. If unspecified, at most 50 rules will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # A page token, received from a previous `ListRegions` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `ListRegions` must match the call that provided the page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/regions"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a region definition in your Merchant Center account.
#
# POST /{merchantId}/regions
# Returns: record<displayName: string, geotargetArea: record<geotargetCriteriaIds: list<string>>, merchantId: string, postalCodeArea: record<postalCodes: list<record>, regionCode: string>, regionId: string, regionalInventoryEligible: bool, shippingEligible: bool>
# operationId: content.regions.create
export def "content-regions-create" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --region-id: string # Required. The id of the region to create.
  --display-name: string # The display name of the region.
  --geotarget-area: record # A list of geotargets that defines the region area. — shape: {geotargetCriteriaIds?: list<string>}
  --postal-code-area: record # A list of postal codes that defines the region area. Note: All regions defined using postal codes are accessible via the account's `ShippingSettings.postalCodeGroups` resource. — shape: {postalCodes?: list, regionCode?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/regions"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: regionId, var: region_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: displayName, var: display_name}, {name: geotargetArea, var: geotarget_area}, {name: postalCodeArea, var: postal_code_area}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, region_id: $region_id, display_name: $display_name, geotarget_area: $geotarget_area, postal_code_area: $postal_code_area
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a region definition from your Merchant Center account.
#
# DELETE /{merchantId}/regions/{regionId}
# operationId: content.regions.delete
export def "content-regions-delete" [
  merchant_id: string
  region_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> any {
  http-request {
    method: delete
    path: "/{merchantId}/regions/{regionId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: regionId, var: region_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, region_id: $region_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a region defined in your Merchant Center account.
#
# GET /{merchantId}/regions/{regionId}
# Returns: record<displayName: string, geotargetArea: record<geotargetCriteriaIds: list<string>>, merchantId: string, postalCodeArea: record<postalCodes: list<record>, regionCode: string>, regionId: string, regionalInventoryEligible: bool, shippingEligible: bool>
# operationId: content.regions.get
export def "content-regions-get" [
  merchant_id: string
  region_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/regions/{regionId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: regionId, var: region_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, region_id: $region_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a region definition in your Merchant Center account.
#
# PATCH /{merchantId}/regions/{regionId}
# Returns: record<displayName: string, geotargetArea: record<geotargetCriteriaIds: list<string>>, merchantId: string, postalCodeArea: record<postalCodes: list<record>, regionCode: string>, regionId: string, regionalInventoryEligible: bool, shippingEligible: bool>
# operationId: content.regions.patch
export def "content-regions-patch" [
  merchant_id: string
  region_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --update-mask: string # Optional. The comma-separated field mask indicating the fields to update. Example: `"displayName,postalCodeArea.regionCode"`.
  --display-name: string # The display name of the region.
  --geotarget-area: record # A list of geotargets that defines the region area. — shape: {geotargetCriteriaIds?: list<string>}
  --postal-code-area: record # A list of postal codes that defines the region area. Note: All regions defined using postal codes are accessible via the account's `ShippingSettings.postalCodeGroups` resource. — shape: {postalCodes?: list, regionCode?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/{merchantId}/regions/{regionId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: regionId, var: region_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: displayName, var: display_name}, {name: geotargetArea, var: geotarget_area}, {name: postalCodeArea, var: postal_code_area}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, region_id: $region_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, update_mask: $update_mask, display_name: $display_name, geotarget_area: $geotarget_area, postal_code_area: $postal_code_area
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves merchant performance mertrics matching the search query and optionally segmented by selected dimensions.
#
# POST /{merchantId}/reports/search
# Returns: record<nextPageToken: string, results: table<bestSellers: record, brand: record, metrics: record, priceCompetitiveness: record, priceInsights: record, productCluster: record, productView: record, segments: record>>
# operationId: content.reports.search
export def "content-reports-search" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # Number of ReportRows to retrieve in a single page. Defaults to the maximum of 1000. Values above 1000 are coerced to 1000. (format: int32)
  --page-token: string # Token of the page to retrieve. If not specified, the first page of results is returned. In order to request the next page of results, the value obtained from `next_page_token` in the previous response should be used.
  --query: string # Required. Query that defines performance metrics to retrieve and dimensions according to which the metrics are to be segmented. For details on how to construct your query, see the [Query Language guide](https://developers.google.com/shopping-content/guides/reports/query-language/overview).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/reports/search"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: query, var: query}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the repricing rules in your Merchant Center account.
#
# GET /{merchantId}/repricingrules
# Returns: record<nextPageToken: string, repricingRules: table<cogsBasedRule: record, countryCode: string, effectiveTimePeriod: record, eligibleOfferMatcher: record, languageCode: string, merchantId: string, paused: bool, restriction: record, ruleId: string, statsBasedRule: record, title: string, type: string>>
# operationId: content.repricingrules.list
export def "content-repricingrules-list" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --country-code: string # [CLDR country code](http://www.unicode.org/repos/cldr/tags/latest/common/main/en.xml) (e.g. "US"), used as a filter on repricing rules.
  --language-code: string # The two-letter ISO 639-1 language code associated with the repricing rule, used as a filter.
  --page-size: int # The maximum number of repricing rules to return. The service may return fewer than this value. If unspecified, at most 50 rules will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # A page token, received from a previous `ListRepricingRules` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `ListRepricingRules` must match the call that provided the page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/repricingrules"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: countryCode, var: country_code}, {name: languageCode, var: language_code}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, country_code: $country_code, language_code: $language_code, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a repricing rule for your Merchant Center account.
#
# POST /{merchantId}/repricingrules
# Returns: record<cogsBasedRule: record<percentageDelta: int, priceDelta: string>, countryCode: string, effectiveTimePeriod: record<fixedTimePeriods: list<record>>, eligibleOfferMatcher: record<brandMatcher: record<strAttributes: list>, itemGroupIdMatcher: record<strAttributes: list>, matcherOption: string, offerIdMatcher: record<strAttributes: list>, skipWhenOnPromotion: bool>, languageCode: string, merchantId: string, paused: bool, restriction: record<floor: record<percentageDelta: int, priceDelta: string>, useAutoPricingMinPrice: bool>, ruleId: string, statsBasedRule: record<percentageDelta: int, priceDelta: string>, title: string, type: string>
# operationId: content.repricingrules.create
export def "content-repricingrules-create" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --rule-id: string # Required. The id of the rule to create.
  --cogs-based-rule: record # A repricing rule that changes the sale price based on cost of goods sale. — shape: {percentageDelta?: int, priceDelta?: string}
  --country-code: string # Required. Immutable. [CLDR country code](http://www.unicode.org/repos/cldr/tags/latest/common/main/en.xml) (e.g. "US").
  --effective-time-period: record # shape: {fixedTimePeriods?: list}
  --eligible-offer-matcher: record # Matcher that specifies eligible offers. When the USE_FEED_ATTRIBUTE option is selected, only the repricing_rule_id attribute on the product feed is used to specify offer-rule mapping. When the CUSTOM_FILTER option is selected, only the *_matcher fields are used to filter the offers for offer-rule mapping. If the CUSTOM_FILTER option is selected, an offer needs to satisfy each custom filter matcher to be eligible for a rule. Size limit: the sum of the number of entries in all the matchers should not exceed 20. For example, there can be 15 product ids and 5 brands, but not 10 product ids and 11 brands. — shape: {brandMatcher?: record, itemGroupIdMatcher?: record, matcherOption?: "MATCHER_OPTION_UNSPECIFIED"|"MATCHER_OPTION_CUSTOM_FILTER"|"MATCHER_OPTION_USE_FEED_ATTRIBUTE"|"MATCHER_OPTION_ALL_PRODUCTS", offerIdMatcher?: record, skipWhenOnPromotion?: bool}
  --language-code: string # Required. Immutable. The two-letter ISO 639-1 language code associated with the repricing rule.
  --paused: oneof<nothing, bool> # Represents whether a rule is paused. A paused rule will behave like a non-paused rule within CRUD operations, with the major difference that a paused rule will not be evaluated and will have no effect on offers.
  --restriction: record # Definition of a rule restriction. At least one of the following needs to be true: (1) use_auto_pricing_min_price is true (2) floor.price_delta exists (3) floor.percentage_delta exists If floor.price_delta and floor.percentage_delta are both set on a rule, the highest value will be chosen by the Repricer. In other words, for a product with a price of $50, if the `floor.percentage_delta` is "-10" and the floor.price_delta is "-12", the offer price will only be lowered $5 (10% lower than the original offer price). — shape: {floor?: record, useAutoPricingMinPrice?: bool}
  --stats-based-rule: record # Definition of stats based rule. — shape: {percentageDelta?: int, priceDelta?: string}
  --title: string # The title for the rule.
  --type: string@type-completer # Required. Immutable. The type of the rule.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/repricingrules"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: ruleId, var: rule_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: cogsBasedRule, var: cogs_based_rule}, {name: countryCode, var: country_code}, {name: effectiveTimePeriod, var: effective_time_period}, {name: eligibleOfferMatcher, var: eligible_offer_matcher}, {name: languageCode, var: language_code}, {name: paused, var: paused}, {name: restriction, var: restriction}, {name: statsBasedRule, var: stats_based_rule}, {name: title, var: title}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, rule_id: $rule_id, cogs_based_rule: $cogs_based_rule, country_code: $country_code, effective_time_period: $effective_time_period, eligible_offer_matcher: $eligible_offer_matcher, language_code: $language_code, paused: $paused, restriction: $restriction, stats_based_rule: $stats_based_rule, title: $title, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a repricing rule in your Merchant Center account.
#
# DELETE /{merchantId}/repricingrules/{ruleId}
# operationId: content.repricingrules.delete
export def "content-repricingrules-delete" [
  merchant_id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> any {
  http-request {
    method: delete
    path: "/{merchantId}/repricingrules/{ruleId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: ruleId, var: rule_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, rule_id: $rule_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a repricing rule from your Merchant Center account.
#
# GET /{merchantId}/repricingrules/{ruleId}
# Returns: record<cogsBasedRule: record<percentageDelta: int, priceDelta: string>, countryCode: string, effectiveTimePeriod: record<fixedTimePeriods: list<record>>, eligibleOfferMatcher: record<brandMatcher: record<strAttributes: list>, itemGroupIdMatcher: record<strAttributes: list>, matcherOption: string, offerIdMatcher: record<strAttributes: list>, skipWhenOnPromotion: bool>, languageCode: string, merchantId: string, paused: bool, restriction: record<floor: record<percentageDelta: int, priceDelta: string>, useAutoPricingMinPrice: bool>, ruleId: string, statsBasedRule: record<percentageDelta: int, priceDelta: string>, title: string, type: string>
# operationId: content.repricingrules.get
export def "content-repricingrules-get" [
  merchant_id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/repricingrules/{ruleId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: ruleId, var: rule_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, rule_id: $rule_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a repricing rule in your Merchant Center account. All mutable fields will be overwritten in each update request. In each update, you must provide all required mutable fields, or an error will be thrown. If you do not provide an optional field in the update request, if that field currently exists, it will be deleted from the rule.
#
# PATCH /{merchantId}/repricingrules/{ruleId}
# Returns: record<cogsBasedRule: record<percentageDelta: int, priceDelta: string>, countryCode: string, effectiveTimePeriod: record<fixedTimePeriods: list<record>>, eligibleOfferMatcher: record<brandMatcher: record<strAttributes: list>, itemGroupIdMatcher: record<strAttributes: list>, matcherOption: string, offerIdMatcher: record<strAttributes: list>, skipWhenOnPromotion: bool>, languageCode: string, merchantId: string, paused: bool, restriction: record<floor: record<percentageDelta: int, priceDelta: string>, useAutoPricingMinPrice: bool>, ruleId: string, statsBasedRule: record<percentageDelta: int, priceDelta: string>, title: string, type: string>
# operationId: content.repricingrules.patch
export def "content-repricingrules-patch" [
  merchant_id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cogs-based-rule: record # A repricing rule that changes the sale price based on cost of goods sale. — shape: {percentageDelta?: int, priceDelta?: string}
  --country-code: string # Required. Immutable. [CLDR country code](http://www.unicode.org/repos/cldr/tags/latest/common/main/en.xml) (e.g. "US").
  --effective-time-period: record # shape: {fixedTimePeriods?: list}
  --eligible-offer-matcher: record # Matcher that specifies eligible offers. When the USE_FEED_ATTRIBUTE option is selected, only the repricing_rule_id attribute on the product feed is used to specify offer-rule mapping. When the CUSTOM_FILTER option is selected, only the *_matcher fields are used to filter the offers for offer-rule mapping. If the CUSTOM_FILTER option is selected, an offer needs to satisfy each custom filter matcher to be eligible for a rule. Size limit: the sum of the number of entries in all the matchers should not exceed 20. For example, there can be 15 product ids and 5 brands, but not 10 product ids and 11 brands. — shape: {brandMatcher?: record, itemGroupIdMatcher?: record, matcherOption?: "MATCHER_OPTION_UNSPECIFIED"|"MATCHER_OPTION_CUSTOM_FILTER"|"MATCHER_OPTION_USE_FEED_ATTRIBUTE"|"MATCHER_OPTION_ALL_PRODUCTS", offerIdMatcher?: record, skipWhenOnPromotion?: bool}
  --language-code: string # Required. Immutable. The two-letter ISO 639-1 language code associated with the repricing rule.
  --paused: oneof<nothing, bool> # Represents whether a rule is paused. A paused rule will behave like a non-paused rule within CRUD operations, with the major difference that a paused rule will not be evaluated and will have no effect on offers.
  --restriction: record # Definition of a rule restriction. At least one of the following needs to be true: (1) use_auto_pricing_min_price is true (2) floor.price_delta exists (3) floor.percentage_delta exists If floor.price_delta and floor.percentage_delta are both set on a rule, the highest value will be chosen by the Repricer. In other words, for a product with a price of $50, if the `floor.percentage_delta` is "-10" and the floor.price_delta is "-12", the offer price will only be lowered $5 (10% lower than the original offer price). — shape: {floor?: record, useAutoPricingMinPrice?: bool}
  --stats-based-rule: record # Definition of stats based rule. — shape: {percentageDelta?: int, priceDelta?: string}
  --title: string # The title for the rule.
  --type: string@type-completer # Required. Immutable. The type of the rule.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/{merchantId}/repricingrules/{ruleId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: ruleId, var: rule_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: cogsBasedRule, var: cogs_based_rule}, {name: countryCode, var: country_code}, {name: effectiveTimePeriod, var: effective_time_period}, {name: eligibleOfferMatcher, var: eligible_offer_matcher}, {name: languageCode, var: language_code}, {name: paused, var: paused}, {name: restriction, var: restriction}, {name: statsBasedRule, var: stats_based_rule}, {name: title, var: title}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, rule_id: $rule_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cogs_based_rule: $cogs_based_rule, country_code: $country_code, effective_time_period: $effective_time_period, eligible_offer_matcher: $eligible_offer_matcher, language_code: $language_code, paused: $paused, restriction: $restriction, stats_based_rule: $stats_based_rule, title: $title, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the metrics report for a given Repricing rule.
#
# GET /{merchantId}/repricingrules/{ruleId}/repricingreports
# Returns: record<nextPageToken: string, repricingRuleReports: table<buyboxWinningRuleStats: record, date: record, impactedProducts: list, inapplicabilityDetails: list, inapplicableProducts: list, orderItemCount: int, ruleId: string, totalGmv: record, type: string>>
# operationId: content.repricingrules.repricingreports.list
export def "content-repricingrules-repricingreports-list" [
  merchant_id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --end-date: string # Gets Repricing reports on and before this date in the merchant's timezone. You can only retrieve data up to 7 days ago (default) or earlier. Format: YYYY-MM-DD.
  --page-size: int # Maximum number of daily reports to return. Each report includes data from a single 24-hour period. The page size defaults to 50 and values above 1000 are coerced to 1000. This service may return fewer days than this value, for example, if the time between your start and end date is less than page size.
  --page-token: string # Token (if provided) to retrieve the subsequent page. All other parameters must match the original call that provided the page token.
  --start-date: string # Gets Repricing reports on and after this date in the merchant's timezone, up to one year ago. Do not use a start date later than 7 days ago (default). Format: YYYY-MM-DD.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/repricingrules/{ruleId}/repricingreports"
    path_params: [{name: merchantId, var: merchant_id}, {name: ruleId, var: rule_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: endDate, var: end_date}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: startDate, var: start_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, rule_id: $rule_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, end_date: $end_date, page_size: $page_size, page_token: $page_token, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the return addresses of the Merchant Center account.
#
# GET /{merchantId}/returnaddress
# Returns: record<kind: string, nextPageToken: string, resources: table<address: record, country: string, kind: string, label: string, phoneNumber: string, returnAddressId: string>>
# operationId: content.returnaddress.list
export def "content-returnaddress-list" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --country: string # List only return addresses applicable to the given country of sale. When omitted, all return addresses are listed.
  --max-results: int # The maximum number of addresses in the response, used for paging.
  --page-token: string # The token returned by the previous request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/returnaddress"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: country, var: country}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, country: $country, max_results: $max_results, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inserts a return address for the Merchant Center account.
#
# POST /{merchantId}/returnaddress
# Returns: record<address: record<country: string, locality: string, postalCode: string, recipientName: string, region: string, streetAddress: list<string>>, country: string, kind: string, label: string, phoneNumber: string, returnAddressId: string>
# operationId: content.returnaddress.insert
export def "content-returnaddress-insert" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --address: record # shape: {country?: string, locality?: string, postalCode?: string, recipientName?: string, region?: string, streetAddress?: list<string>}
  --country: string # Required. The country of sale where the return address is applicable.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "`content#returnAddress`"
  --label: string # Required. The user-defined label of the return address. For the default address, use the label "default".
  --phone-number: string # Required. The merchant's contact phone number regarding the return.
  --return-address-id: string # Return address ID generated by Google.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/returnaddress"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: country, var: country}, {name: kind, var: kind}, {name: label, var: label}, {name: phoneNumber, var: phone_number}, {name: returnAddressId, var: return_address_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, address: $address, country: $country, kind: $kind, label: $label, phone_number: $phone_number, return_address_id: $return_address_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a return address for the given Merchant Center account.
#
# DELETE /{merchantId}/returnaddress/{returnAddressId}
# operationId: content.returnaddress.delete
export def "content-returnaddress-delete" [
  merchant_id: string
  return_address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> any {
  http-request {
    method: delete
    path: "/{merchantId}/returnaddress/{returnAddressId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: returnAddressId, var: return_address_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, return_address_id: $return_address_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a return address of the Merchant Center account.
#
# GET /{merchantId}/returnaddress/{returnAddressId}
# Returns: record<address: record<country: string, locality: string, postalCode: string, recipientName: string, region: string, streetAddress: list<string>>, country: string, kind: string, label: string, phoneNumber: string, returnAddressId: string>
# operationId: content.returnaddress.get
export def "content-returnaddress-get" [
  merchant_id: string
  return_address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/returnaddress/{returnAddressId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: returnAddressId, var: return_address_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, return_address_id: $return_address_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the return policies of the Merchant Center account.
#
# GET /{merchantId}/returnpolicy
# Returns: record<kind: string, resources: table<country: string, kind: string, label: string, name: string, nonFreeReturnReasons: list, policy: record, returnPolicyId: string, returnShippingFee: record, seasonalOverrides: list>>
# operationId: content.returnpolicy.list
export def "content-returnpolicy-list" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/returnpolicy"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inserts a return policy for the Merchant Center account.
#
# POST /{merchantId}/returnpolicy
# Returns: record<country: string, kind: string, label: string, name: string, nonFreeReturnReasons: list<string>, policy: record<lastReturnDate: string, numberOfDays: string, type: string>, returnPolicyId: string, returnShippingFee: record<currency: string, value: string>, seasonalOverrides: table<endDate: string, name: string, policy: record, startDate: string>>
# operationId: content.returnpolicy.insert
export def "content-returnpolicy-insert" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --country: string # Required. The country of sale where the return policy is applicable.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "`content#returnPolicy`"
  --label: string # Required. The user-defined label of the return policy. For the default policy, use the label "default".
  --name: string # Required. The name of the policy as shown in Merchant Center.
  --non-free-return-reasons: list<string> # Return reasons that will incur return fees.
  --policy: record # shape: {lastReturnDate?: string, numberOfDays?: string, type?: string}
  --return-policy-id: string # Return policy ID generated by Google.
  --return-shipping-fee: record # shape: {currency?: string, value?: string}
  --seasonal-overrides: list # An optional list of seasonal overrides. — item shape: {endDate?: string, name?: string, policy?: record, startDate?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/returnpolicy"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: country, var: country}, {name: kind, var: kind}, {name: label, var: label}, {name: name, var: name}, {name: nonFreeReturnReasons, var: non_free_return_reasons}, {name: policy, var: policy}, {name: returnPolicyId, var: return_policy_id}, {name: returnShippingFee, var: return_shipping_fee}, {name: seasonalOverrides, var: seasonal_overrides}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, country: $country, kind: $kind, label: $label, name: $name, non_free_return_reasons: $non_free_return_reasons, policy: $policy, return_policy_id: $return_policy_id, return_shipping_fee: $return_shipping_fee, seasonal_overrides: $seasonal_overrides
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a return policy for the given Merchant Center account.
#
# DELETE /{merchantId}/returnpolicy/{returnPolicyId}
# operationId: content.returnpolicy.delete
export def "content-returnpolicy-delete" [
  merchant_id: string
  return_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> any {
  http-request {
    method: delete
    path: "/{merchantId}/returnpolicy/{returnPolicyId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: returnPolicyId, var: return_policy_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, return_policy_id: $return_policy_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a return policy of the Merchant Center account.
#
# GET /{merchantId}/returnpolicy/{returnPolicyId}
# Returns: record<country: string, kind: string, label: string, name: string, nonFreeReturnReasons: list<string>, policy: record<lastReturnDate: string, numberOfDays: string, type: string>, returnPolicyId: string, returnShippingFee: record<currency: string, value: string>, seasonalOverrides: table<endDate: string, name: string, policy: record, startDate: string>>
# operationId: content.returnpolicy.get
export def "content-returnpolicy-get" [
  merchant_id: string
  return_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/returnpolicy/{returnPolicyId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: returnPolicyId, var: return_policy_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, return_policy_id: $return_policy_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all existing return policies.
#
# GET /{merchantId}/returnpolicyonline
# Returns: record<returnPolicies: table<countries: list, itemConditions: list, label: string, name: string, policy: record, restockingFee: record, returnMethods: list, returnPolicyId: string, returnPolicyUri: string, returnReasonCategoryInfo: list>>
# operationId: content.returnpolicyonline.list
export def "content-returnpolicyonline-list" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/returnpolicyonline"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new return policy.
#
# POST /{merchantId}/returnpolicyonline
# Returns: record<countries: list<string>, itemConditions: list<string>, label: string, name: string, policy: record<days: string, type: string>, restockingFee: record<fixedFee: record<currency: string, value: string>, microPercent: int>, returnMethods: list<string>, returnPolicyId: string, returnPolicyUri: string, returnReasonCategoryInfo: table<returnLabelSource: string, returnReasonCategory: string, returnShippingFee: record>>
# operationId: content.returnpolicyonline.create
export def "content-returnpolicyonline-create" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --countries: list<string> # The countries of sale where the return policy is applicable. The values must be a valid 2 letter ISO 3166 code, e.g. "US".
  --item-conditions: list<string> # The item conditions that are accepted for returns. This is required to not be empty unless the type of return policy is noReturns.
  --label: string # The unique user-defined label of the return policy. The same label cannot be used in different return policies for the same country. Policies with the label 'default' will apply to all products, unless a product specifies a return_policy_label attribute.
  --name: string # The name of the policy as shown in Merchant Center.
  --policy: record # The available policies. — shape: {days?: string, type?: "TYPE_UNSPECIFIED"|"NUMBER_OF_DAYS_AFTER_DELIVERY"|"NO_RETURNS"|"LIFETIME_RETURNS"}
  --restocking-fee: record # The restocking fee. This can either be a fixed fee or a micro percent. — shape: {fixedFee?: record, microPercent?: int}
  --return-methods: list<string> # The return methods of how customers can return an item. This value is required to not be empty unless the type of return policy is noReturns.
  --return-policy-uri: string # The return policy uri. This can used by Google to do a sanity check for the policy.
  --return-reason-category-info: list # The return reason category information. This required to not be empty unless the type of return policy is noReturns. — item shape: {returnLabelSource?: "RETURN_LABEL_SOURCE_UNSPECIFIED"|"DOWNLOAD_AND_PRINT"|"IN_THE_BOX"|"CUSTOMER_RESPONSIBILITY", returnReasonCategory?: "RETURN_REASON_CATEGORY_UNSPECIFIED"|"BUYER_REMORSE"|"ITEM_DEFECT", returnShippingFee?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/returnpolicyonline"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: countries, var: countries}, {name: itemConditions, var: item_conditions}, {name: label, var: label}, {name: name, var: name}, {name: policy, var: policy}, {name: restockingFee, var: restocking_fee}, {name: returnMethods, var: return_methods}, {name: returnPolicyUri, var: return_policy_uri}, {name: returnReasonCategoryInfo, var: return_reason_category_info}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, countries: $countries, item_conditions: $item_conditions, label: $label, name: $name, policy: $policy, restocking_fee: $restocking_fee, return_methods: $return_methods, return_policy_uri: $return_policy_uri, return_reason_category_info: $return_reason_category_info
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing return policy.
#
# DELETE /{merchantId}/returnpolicyonline/{returnPolicyId}
# operationId: content.returnpolicyonline.delete
export def "content-returnpolicyonline-delete" [
  merchant_id: string
  return_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> any {
  http-request {
    method: delete
    path: "/{merchantId}/returnpolicyonline/{returnPolicyId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: returnPolicyId, var: return_policy_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, return_policy_id: $return_policy_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an existing return policy.
#
# GET /{merchantId}/returnpolicyonline/{returnPolicyId}
# Returns: record<countries: list<string>, itemConditions: list<string>, label: string, name: string, policy: record<days: string, type: string>, restockingFee: record<fixedFee: record<currency: string, value: string>, microPercent: int>, returnMethods: list<string>, returnPolicyId: string, returnPolicyUri: string, returnReasonCategoryInfo: table<returnLabelSource: string, returnReasonCategory: string, returnShippingFee: record>>
# operationId: content.returnpolicyonline.get
export def "content-returnpolicyonline-get" [
  merchant_id: string
  return_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/returnpolicyonline/{returnPolicyId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: returnPolicyId, var: return_policy_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, return_policy_id: $return_policy_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing return policy.
#
# PATCH /{merchantId}/returnpolicyonline/{returnPolicyId}
# Returns: record<countries: list<string>, itemConditions: list<string>, label: string, name: string, policy: record<days: string, type: string>, restockingFee: record<fixedFee: record<currency: string, value: string>, microPercent: int>, returnMethods: list<string>, returnPolicyId: string, returnPolicyUri: string, returnReasonCategoryInfo: table<returnLabelSource: string, returnReasonCategory: string, returnShippingFee: record>>
# operationId: content.returnpolicyonline.patch
export def "content-returnpolicyonline-patch" [
  merchant_id: string
  return_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --countries: list<string> # The countries of sale where the return policy is applicable. The values must be a valid 2 letter ISO 3166 code, e.g. "US".
  --item-conditions: list<string> # The item conditions that are accepted for returns. This is required to not be empty unless the type of return policy is noReturns.
  --label: string # The unique user-defined label of the return policy. The same label cannot be used in different return policies for the same country. Policies with the label 'default' will apply to all products, unless a product specifies a return_policy_label attribute.
  --name: string # The name of the policy as shown in Merchant Center.
  --policy: record # The available policies. — shape: {days?: string, type?: "TYPE_UNSPECIFIED"|"NUMBER_OF_DAYS_AFTER_DELIVERY"|"NO_RETURNS"|"LIFETIME_RETURNS"}
  --restocking-fee: record # The restocking fee. This can either be a fixed fee or a micro percent. — shape: {fixedFee?: record, microPercent?: int}
  --return-methods: list<string> # The return methods of how customers can return an item. This value is required to not be empty unless the type of return policy is noReturns.
  --return-policy-uri: string # The return policy uri. This can used by Google to do a sanity check for the policy.
  --return-reason-category-info: list # The return reason category information. This required to not be empty unless the type of return policy is noReturns. — item shape: {returnLabelSource?: "RETURN_LABEL_SOURCE_UNSPECIFIED"|"DOWNLOAD_AND_PRINT"|"IN_THE_BOX"|"CUSTOMER_RESPONSIBILITY", returnReasonCategory?: "RETURN_REASON_CATEGORY_UNSPECIFIED"|"BUYER_REMORSE"|"ITEM_DEFECT", returnShippingFee?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/{merchantId}/returnpolicyonline/{returnPolicyId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: returnPolicyId, var: return_policy_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: countries, var: countries}, {name: itemConditions, var: item_conditions}, {name: label, var: label}, {name: name, var: name}, {name: policy, var: policy}, {name: restockingFee, var: restocking_fee}, {name: returnMethods, var: return_methods}, {name: returnPolicyUri, var: return_policy_uri}, {name: returnReasonCategoryInfo, var: return_reason_category_info}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, return_policy_id: $return_policy_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, countries: $countries, item_conditions: $item_conditions, label: $label, name: $name, policy: $policy, restocking_fee: $restocking_fee, return_methods: $return_methods, return_policy_uri: $return_policy_uri, return_reason_category_info: $return_reason_category_info
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of settlement reports from your Merchant Center account.
#
# GET /{merchantId}/settlementreports
# Returns: record<kind: string, nextPageToken: string, resources: table<endDate: string, kind: string, previousBalance: record, settlementId: string, startDate: string, transferAmount: record, transferDate: string, transferIds: list>>
# operationId: content.settlementreports.list
export def "content-settlementreports-list" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --max-results: int # The maximum number of settlements to return in the response, used for paging. The default value is 200 returns per page, and the maximum allowed value is 5000 returns per page.
  --page-token: string # The token returned by the previous request.
  --transfer-end-date: string # Obtains settlements which have transactions before this date (inclusively), in ISO 8601 format.
  --transfer-start-date: string # Obtains settlements which have transactions after this date (inclusively), in ISO 8601 format.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/settlementreports"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}, {name: transferEndDate, var: transfer_end_date}, {name: transferStartDate, var: transfer_start_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, max_results: $max_results, page_token: $page_token, transfer_end_date: $transfer_end_date, transfer_start_date: $transfer_start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a settlement report from your Merchant Center account.
#
# GET /{merchantId}/settlementreports/{settlementId}
# Returns: record<endDate: string, kind: string, previousBalance: record<currency: string, value: string>, settlementId: string, startDate: string, transferAmount: record<currency: string, value: string>, transferDate: string, transferIds: list<string>>
# operationId: content.settlementreports.get
export def "content-settlementreports-get" [
  merchant_id: string
  settlement_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/settlementreports/{settlementId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: settlementId, var: settlement_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, settlement_id: $settlement_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of transactions for the settlement.
#
# GET /{merchantId}/settlementreports/{settlementId}/transactions
# Returns: record<kind: string, nextPageToken: string, resources: table<amount: record, identifiers: record, kind: string, transaction: record>>
# operationId: content.settlementtransactions.list
export def "content-settlementtransactions-list" [
  merchant_id: string
  settlement_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --max-results: int # The maximum number of transactions to return in the response, used for paging. The default value is 200 transactions per page, and the maximum allowed value is 5000 transactions per page.
  --page-token: string # The token returned by the previous request.
  --transaction-ids: list<string> # The list of transactions to return. If not set, all transactions will be returned.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/settlementreports/{settlementId}/transactions"
    path_params: [{name: merchantId, var: merchant_id}, {name: settlementId, var: settlement_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}, {name: transactionIds, var: transaction_ids, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, settlement_id: $settlement_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, max_results: $max_results, page_token: $page_token, transaction_ids: $transaction_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the shipping settings of the sub-accounts in your Merchant Center account.
#
# GET /{merchantId}/shippingsettings
# Returns: record<kind: string, nextPageToken: string, resources: table<accountId: string, postalCodeGroups: list, services: list, warehouses: list>>
# operationId: content.shippingsettings.list
export def "content-shippingsettings-list" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --max-results: int # The maximum number of shipping settings to return in the response, used for paging.
  --page-token: string # The token returned by the previous request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/shippingsettings"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, max_results: $max_results, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the shipping settings of the account.
#
# GET /{merchantId}/shippingsettings/{accountId}
# Returns: record<accountId: string, postalCodeGroups: table<country: string, name: string, postalCodeRanges: list>, services: table<active: bool, currency: string, deliveryCountry: string, deliveryTime: record, eligibility: string, minimumOrderValue: record, minimumOrderValueTable: record, name: string, pickupService: record, rateGroups: list, shipmentType: string>, warehouses: table<businessDayConfig: record, cutoffTime: record, handlingDays: string, name: string, shippingAddress: record>>
# operationId: content.shippingsettings.get
export def "content-shippingsettings-get" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/shippingsettings/{accountId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: accountId, var: account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, account_id: $account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the shipping settings of the account. Any fields that are not provided are deleted from the resource.
#
# PUT /{merchantId}/shippingsettings/{accountId}
# Returns: record<accountId: string, postalCodeGroups: table<country: string, name: string, postalCodeRanges: list>, services: table<active: bool, currency: string, deliveryCountry: string, deliveryTime: record, eligibility: string, minimumOrderValue: record, minimumOrderValueTable: record, name: string, pickupService: record, rateGroups: list, shipmentType: string>, warehouses: table<businessDayConfig: record, cutoffTime: record, handlingDays: string, name: string, shippingAddress: record>>
# operationId: content.shippingsettings.update
export def "content-shippingsettings-update" [
  merchant_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-account-id: string # The ID of the account to which these account shipping settings belong. Ignored upon update, always present in get request responses. (format: uint64) (spec name: accountId)
  --postal-code-groups: list # A list of postal code groups that can be referred to in `services`. Optional. — item shape: {country?: string, name?: string, postalCodeRanges?: list}
  --services: list # The target account's list of services. Optional. — item shape: {active?: bool, currency?: string, deliveryCountry?: string, deliveryTime?: record, eligibility?: string, minimumOrderValue?: record, minimumOrderValueTable?: record, name?: string, pickupService?: record, rateGroups?: list, shipmentType?: string}
  --warehouses: list # Optional. A list of warehouses which can be referred to in `services`. — item shape: {businessDayConfig?: record, cutoffTime?: record, handlingDays?: string, name?: string, shippingAddress?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{merchantId}/shippingsettings/{accountId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: accountId, var: account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: postalCodeGroups, var: postal_code_groups}, {name: services, var: services}, {name: warehouses, var: warehouses}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, account_id: $account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body_account_id: $body_account_id, postal_code_groups: $postal_code_groups, services: $services, warehouses: $warehouses
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the status and review eligibility for the Shopping Ads program. Returns errors and warnings if they require action to resolve, will become disapprovals, or impact impressions. Use `accountstatuses` to view all issues for an account.
#
# GET /{merchantId}/shoppingadsprogram
# Returns: record<globalState: string, regionStatuses: table<disapprovalDate: string, eligibilityStatus: string, onboardingIssues: list, regionCodes: list, reviewEligibilityStatus: string, reviewIneligibilityReason: string, reviewIneligibilityReasonDescription: string, reviewIneligibilityReasonDetails: record, reviewIssues: list>>
# operationId: content.shoppingadsprogram.get
export def "content-shoppingadsprogram-get" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/shoppingadsprogram"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Requests a review of Shopping ads in a specific region. This method is only available to selected merchants.
#
# POST /{merchantId}/shoppingadsprogram/requestreview
# operationId: content.shoppingadsprogram.requestreview
export def "content-shoppingadsprogram-requestreview" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --region-code: string # The code [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) of the country for which review is to be requested.
]: any -> any {
  $in | http-request {
    method: post
    path: "/{merchantId}/shoppingadsprogram/requestreview"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: regionCode, var: region_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, region_code: $region_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves supported carriers and carrier services for an account.
#
# GET /{merchantId}/supportedCarriers
# Returns: record<carriers: table<country: string, eddServices: list, name: string, services: list>, kind: string>
# operationId: content.shippingsettings.getsupportedcarriers
export def "content-shippingsettings-getsupportedcarriers" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/supportedCarriers"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves supported holidays for an account.
#
# GET /{merchantId}/supportedHolidays
# Returns: record<holidays: table<countryCode: string, date: string, deliveryGuaranteeDate: string, deliveryGuaranteeHour: string, id: string, type: string>, kind: string>
# operationId: content.shippingsettings.getsupportedholidays
export def "content-shippingsettings-getsupportedholidays" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/supportedHolidays"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves supported pickup services for an account.
#
# GET /{merchantId}/supportedPickupServices
# Returns: record<kind: string, pickupServices: table<carrierName: string, country: string, serviceName: string>>
# operationId: content.shippingsettings.getsupportedpickupservices
export def "content-shippingsettings-getsupportedpickupservices" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/supportedPickupServices"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sandbox only. Creates a test order.
#
# POST /{merchantId}/testorders
# Returns: record<kind: string, orderId: string>
# operationId: content.orders.createtestorder
export def "content-orders-createtestorder" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --country: string # The CLDR territory code of the country of the test order to create. Affects the currency and addresses of orders created through `template_name`, or the addresses of orders created through `test_order`. Acceptable values are: - "`US`" - "`FR`" Defaults to "`US`".
  --template-name: string # The test order template to use. Specify as an alternative to `testOrder` as a shortcut for retrieving a template and then creating an order using that template. Acceptable values are: - "`template1`" - "`template1a`" - "`template1b`" - "`template2`" - "`template3`"
  --test-order: record # shape: {deliveryDetails?: record, enableOrderinvoices?: bool, kind?: string, lineItems?: list, notificationMode?: string, pickupDetails?: record, predefinedBillingAddress?: string, predefinedDeliveryAddress?: string, predefinedEmail?: string, predefinedPickupDetails?: string, promotions?: list, shippingCost?: record, shippingOption?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/testorders"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: country, var: country}, {name: templateName, var: template_name}, {name: testOrder, var: test_order}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, country: $country, template_name: $template_name, test_order: $test_order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sandbox only. Moves a test order from state "`inProgress`" to state "`pendingShipment`".
#
# POST /{merchantId}/testorders/{orderId}/advance
# Returns: record<kind: string>
# operationId: content.orders.advancetestorder
export def "content-orders-advancetestorder" [
  merchant_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/{merchantId}/testorders/{orderId}/advance"
    path_params: [{name: merchantId, var: merchant_id}, {name: orderId, var: order_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, order_id: $order_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sandbox only. Cancels a test order for customer-initiated cancellation.
#
# POST /{merchantId}/testorders/{orderId}/cancelByCustomer
# Returns: record<kind: string>
# operationId: content.orders.canceltestorderbycustomer
export def "content-orders-canceltestorderbycustomer" [
  merchant_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --reason: string # The reason for the cancellation. Acceptable values are: - "`changedMind`" - "`orderedWrongItem`" - "`other`"
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/testorders/{orderId}/cancelByCustomer"
    path_params: [{name: merchantId, var: merchant_id}, {name: orderId, var: order_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: reason, var: reason}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, order_id: $order_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, reason: $reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sandbox only. Retrieves an order template that can be used to quickly create a new order in sandbox.
#
# GET /{merchantId}/testordertemplates/{templateName}
# Returns: record<kind: string, template: record<deliveryDetails: record<address: record, isScheduledDelivery: bool, phoneNumber: string>, enableOrderinvoices: bool, kind: string, lineItems: list<record>, notificationMode: string, pickupDetails: record<locationCode: string, pickupLocationAddress: record, pickupLocationType: string, pickupPersons: list>, predefinedBillingAddress: string, predefinedDeliveryAddress: string, predefinedEmail: string, predefinedPickupDetails: string, promotions: list<record>, shippingCost: record<currency: string, value: string>, shippingOption: string>>
# operationId: content.orders.gettestordertemplate
export def "content-orders-gettestordertemplate" [
  merchant_id: string
  template_name: string@template-name-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --country: string # The country of the template to retrieve. Defaults to "`US`".
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/testordertemplates/{templateName}"
    path_params: [{name: merchantId, var: merchant_id}, {name: templateName, var: template_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: country, var: country}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, template_name: $template_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, country: $country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
