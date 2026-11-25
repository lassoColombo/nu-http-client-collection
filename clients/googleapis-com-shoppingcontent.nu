# Auto-generated client for Content API for Shopping v2
# Source: https://api.apis.guru/v2/specs/googleapis.com/shoppingcontent/v2/openapi.json
# Auth: --token flag or $env.CONTENT_API_FOR_SHOPPING_TOKEN

const CLIENT = {
  base_url: "https://shoppingcontent.googleapis.com/content/v2"
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

def base-url-completer [] { ["https://shoppingcontent.googleapis.com/content/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def order-by-completer [] { ["RETURN_CREATION_TIME_ASC" "RETURN_CREATION_TIME_DESC"] }
def template-name-completer [] { ["TEMPLATE1" "TEMPLATE1A" "TEMPLATE1B" "TEMPLATE2" "TEMPLATE3"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    content-accounts-authinfo: "record<accountIdentifiers: table<aggregatorId: string, merchantId: string>, kind: string>"
    content-accounts-custombatch: "record<entries: table<account: record, batchId: int, errors: record, kind: string, linkStatus: string>, kind: string>"
    content-accountstatuses-custombatch: "record<entries: table<accountStatus: record, batchId: int, errors: record>, kind: string>"
    content-accounttax-custombatch: "record<entries: table<accountTax: record, batchId: int, errors: record, kind: string>, kind: string>"
    content-datafeeds-custombatch: "record<entries: table<batchId: int, datafeed: record, errors: record>, kind: string>"
    content-datafeedstatuses-custombatch: "record<entries: table<batchId: int, datafeedStatus: record, errors: record>, kind: string>"
    content-liasettings-custombatch: "record<entries: table<batchId: int, errors: record, gmbAccounts: record, kind: string, liaSettings: record, posDataProviders: list>, kind: string>"
    content-liasettings-listposdataproviders: "record<kind: string, posDataProviders: table<country: string, posDataProviders: list>>"
    content-orders-custombatch: "record<entries: table<batchId: int, errors: record, executionStatus: string, kind: string, order: record>, kind: string>"
    content-pos-custombatch: "record<entries: table<batchId: int, errors: record, inventory: record, kind: string, sale: record, store: record>, kind: string>"
    content-products-custombatch: "record<entries: table<batchId: int, errors: record, kind: string, product: record>, kind: string>"
    content-productstatuses-custombatch: "record<entries: table<batchId: int, errors: record, kind: string, productStatus: record>, kind: string>"
    content-shippingsettings-custombatch: "record<entries: table<batchId: int, errors: record, kind: string, shippingSettings: record>, kind: string>"
    content-accounts-list: "record<kind: string, nextPageToken: string, resources: table<adultContent: bool, adwordsLinks: list, businessInformation: record, googleMyBusinessLink: record, id: string, kind: string, name: string, reviewsUrl: string, sellerId: string, users: list, websiteUrl: string, youtubeChannelLinks: list>>"
    content-accounts-insert: "record<adultContent: bool, adwordsLinks: table<adwordsId: string, status: string>, businessInformation: record<address: record<country: string, locality: string, postalCode: string, region: string, streetAddress: string>, customerService: record<email: string, phoneNumber: string, url: string>, koreanBusinessRegistrationNumber: string, phoneNumber: string>, googleMyBusinessLink: record<gmbEmail: string, status: string>, id: string, kind: string, name: string, reviewsUrl: string, sellerId: string, users: table<admin: bool, emailAddress: string, orderManager: bool, paymentsAnalyst: bool, paymentsManager: bool>, websiteUrl: string, youtubeChannelLinks: table<channelId: string, status: string>>"
    content-accounts-get: "record<adultContent: bool, adwordsLinks: table<adwordsId: string, status: string>, businessInformation: record<address: record<country: string, locality: string, postalCode: string, region: string, streetAddress: string>, customerService: record<email: string, phoneNumber: string, url: string>, koreanBusinessRegistrationNumber: string, phoneNumber: string>, googleMyBusinessLink: record<gmbEmail: string, status: string>, id: string, kind: string, name: string, reviewsUrl: string, sellerId: string, users: table<admin: bool, emailAddress: string, orderManager: bool, paymentsAnalyst: bool, paymentsManager: bool>, websiteUrl: string, youtubeChannelLinks: table<channelId: string, status: string>>"
    content-accounts-update: "record<adultContent: bool, adwordsLinks: table<adwordsId: string, status: string>, businessInformation: record<address: record<country: string, locality: string, postalCode: string, region: string, streetAddress: string>, customerService: record<email: string, phoneNumber: string, url: string>, koreanBusinessRegistrationNumber: string, phoneNumber: string>, googleMyBusinessLink: record<gmbEmail: string, status: string>, id: string, kind: string, name: string, reviewsUrl: string, sellerId: string, users: table<admin: bool, emailAddress: string, orderManager: bool, paymentsAnalyst: bool, paymentsManager: bool>, websiteUrl: string, youtubeChannelLinks: table<channelId: string, status: string>>"
    content-accounts-claimwebsite: "record<kind: string>"
    content-accounts-link: "record<kind: string>"
    content-accountstatuses-list: "record<kind: string, nextPageToken: string, resources: table<accountId: string, accountLevelIssues: list, dataQualityIssues: list, kind: string, products: list, websiteClaimed: bool>>"
    content-accountstatuses-get: "record<accountId: string, accountLevelIssues: table<country: string, destination: string, detail: string, documentation: string, id: string, severity: string, title: string>, dataQualityIssues: table<country: string, destination: string, detail: string, displayedValue: string, exampleItems: list, id: string, lastChecked: string, location: string, numItems: int, severity: string, submittedValue: string>, kind: string, products: table<channel: string, country: string, destination: string, itemLevelIssues: list, statistics: record>, websiteClaimed: bool>"
    content-accounttax-list: "record<kind: string, nextPageToken: string, resources: table<accountId: string, kind: string, rules: list>>"
    content-accounttax-get: "record<accountId: string, kind: string, rules: table<country: string, locationId: string, ratePercent: string, shippingTaxed: bool, useGlobalRate: bool>>"
    content-accounttax-update: "record<accountId: string, kind: string, rules: table<country: string, locationId: string, ratePercent: string, shippingTaxed: bool, useGlobalRate: bool>>"
    content-datafeeds-list: "record<kind: string, nextPageToken: string, resources: table<attributeLanguage: string, contentLanguage: string, contentType: string, fetchSchedule: record, fileName: string, format: record, id: string, intendedDestinations: list, kind: string, name: string, targetCountry: string, targets: list>>"
    content-datafeeds-insert: "record<attributeLanguage: string, contentLanguage: string, contentType: string, fetchSchedule: record<dayOfMonth: int, fetchUrl: string, hour: int, minuteOfHour: int, password: string, paused: bool, timeZone: string, username: string, weekday: string>, fileName: string, format: record<columnDelimiter: string, fileEncoding: string, quotingMode: string>, id: string, intendedDestinations: list<string>, kind: string, name: string, targetCountry: string, targets: table<country: string, excludedDestinations: list, includedDestinations: list, language: string>>"
    content-datafeeds-get: "record<attributeLanguage: string, contentLanguage: string, contentType: string, fetchSchedule: record<dayOfMonth: int, fetchUrl: string, hour: int, minuteOfHour: int, password: string, paused: bool, timeZone: string, username: string, weekday: string>, fileName: string, format: record<columnDelimiter: string, fileEncoding: string, quotingMode: string>, id: string, intendedDestinations: list<string>, kind: string, name: string, targetCountry: string, targets: table<country: string, excludedDestinations: list, includedDestinations: list, language: string>>"
    content-datafeeds-update: "record<attributeLanguage: string, contentLanguage: string, contentType: string, fetchSchedule: record<dayOfMonth: int, fetchUrl: string, hour: int, minuteOfHour: int, password: string, paused: bool, timeZone: string, username: string, weekday: string>, fileName: string, format: record<columnDelimiter: string, fileEncoding: string, quotingMode: string>, id: string, intendedDestinations: list<string>, kind: string, name: string, targetCountry: string, targets: table<country: string, excludedDestinations: list, includedDestinations: list, language: string>>"
    content-datafeeds-fetchnow: "record<kind: string>"
    content-datafeedstatuses-list: "record<kind: string, nextPageToken: string, resources: table<country: string, datafeedId: string, errors: list, itemsTotal: string, itemsValid: string, kind: string, language: string, lastUploadDate: string, processingStatus: string, warnings: list>>"
    content-datafeedstatuses-get: "record<country: string, datafeedId: string, errors: table<code: string, count: string, examples: list, message: string>, itemsTotal: string, itemsValid: string, kind: string, language: string, lastUploadDate: string, processingStatus: string, warnings: table<code: string, count: string, examples: list, message: string>>"
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
    content-orderreports-listtransactions: "record<kind: string, nextPageToken: string, transactions: table<disbursementAmount: record, disbursementCreationDate: string, disbursementDate: string, disbursementId: string, merchantId: string, merchantOrderId: string, orderId: string, productAmount: record, productAmountWithRemittedTax: record, transactionDate: string>>"
    content-orderreturns-list: "record<kind: string, nextPageToken: string, resources: table<creationDate: string, merchantOrderId: string, orderId: string, orderReturnId: string, returnItems: list, returnShipments: list>>"
    content-orderreturns-get: "record<creationDate: string, merchantOrderId: string, orderId: string, orderReturnId: string, returnItems: table<customerReturnReason: record, itemId: string, merchantReturnReason: record, product: record, returnShipmentIds: list, state: string>, returnShipments: table<creationDate: string, deliveryDate: string, returnMethodType: string, shipmentId: string, shipmentTrackingInfos: list, shippingDate: string, state: string>>"
    content-orders-list: "record<kind: string, nextPageToken: string, resources: table<acknowledged: bool, channelType: string, customer: record, deliveryDetails: record, id: string, kind: string, lineItems: list, merchantId: string, merchantOrderId: string, netAmount: record, paymentMethod: record, paymentStatus: string, pickupDetails: record, placedDate: string, promotions: list, refunds: list, shipments: list, shippingCost: record, shippingCostTax: record, shippingOption: string, status: string, taxCollector: string>>"
    content-orders-get: "record<acknowledged: bool, channelType: string, customer: record<email: string, explicitMarketingPreference: bool, fullName: string, invoiceReceivingEmail: string, marketingRightsInfo: record<explicitMarketingPreference: string, lastUpdatedTimestamp: string, marketingEmailAddress: string>>, deliveryDetails: record<address: record<country: string, fullAddress: list, isPostOfficeBox: bool, locality: string, postalCode: string, recipientName: string, region: string, streetAddress: list>, phoneNumber: string>, id: string, kind: string, lineItems: table<annotations: list, cancellations: list, id: string, price: record, product: record, quantityCanceled: int, quantityDelivered: int, quantityOrdered: int, quantityPending: int, quantityReadyForPickup: int, quantityReturned: int, quantityShipped: int, returnInfo: record, returns: list, shippingDetails: record, tax: record>, merchantId: string, merchantOrderId: string, netAmount: record<currency: string, value: string>, paymentMethod: record<billingAddress: record<country: string, fullAddress: list, isPostOfficeBox: bool, locality: string, postalCode: string, recipientName: string, region: string, streetAddress: list>, expirationMonth: int, expirationYear: int, lastFourDigits: string, phoneNumber: string, type: string>, paymentStatus: string, pickupDetails: record<address: record<country: string, fullAddress: list, isPostOfficeBox: bool, locality: string, postalCode: string, recipientName: string, region: string, streetAddress: list>, collectors: list<record>, locationId: string>, placedDate: string, promotions: table<benefits: list, effectiveDates: string, genericRedemptionCode: string, id: string, longTitle: string, productApplicability: string, redemptionChannel: string>, refunds: table<actor: string, amount: record, creationDate: string, reason: string, reasonText: string>, shipments: table<carrier: string, creationDate: string, deliveryDate: string, id: string, lineItems: list, scheduledDeliveryDetails: record, status: string, trackingId: string>, shippingCost: record<currency: string, value: string>, shippingCostTax: record<currency: string, value: string>, shippingOption: string, status: string, taxCollector: string>"
    content-orders-acknowledge: "record<executionStatus: string, kind: string>"
    content-orders-cancel: "record<executionStatus: string, kind: string>"
    content-orders-cancellineitem: "record<executionStatus: string, kind: string>"
    content-orders-instorerefundlineitem: "record<executionStatus: string, kind: string>"
    content-orders-refund: "record<executionStatus: string, kind: string>"
    content-orders-rejectreturnlineitem: "record<executionStatus: string, kind: string>"
    content-orders-returnlineitem: "record<executionStatus: string, kind: string>"
    content-orders-returnrefundlineitem: "record<executionStatus: string, kind: string>"
    content-orders-setlineitemmetadata: "record<executionStatus: string, kind: string>"
    content-orders-shiplineitems: "record<executionStatus: string, kind: string>"
    content-orders-createtestreturn: "record<kind: string, returnId: string>"
    content-orders-updatelineitemshippingdetails: "record<executionStatus: string, kind: string>"
    content-orders-updatemerchantorderid: "record<executionStatus: string, kind: string>"
    content-orders-updateshipment: "record<executionStatus: string, kind: string>"
    content-orders-getbymerchantorderid: "record<kind: string, order: record<acknowledged: bool, channelType: string, customer: record<email: string, explicitMarketingPreference: bool, fullName: string, invoiceReceivingEmail: string, marketingRightsInfo: record>, deliveryDetails: record<address: record, phoneNumber: string>, id: string, kind: string, lineItems: list<record>, merchantId: string, merchantOrderId: string, netAmount: record<currency: string, value: string>, paymentMethod: record<billingAddress: record, expirationMonth: int, expirationYear: int, lastFourDigits: string, phoneNumber: string, type: string>, paymentStatus: string, pickupDetails: record<address: record, collectors: list, locationId: string>, placedDate: string, promotions: list<record>, refunds: list<record>, shipments: list<record>, shippingCost: record<currency: string, value: string>, shippingCostTax: record<currency: string, value: string>, shippingOption: string, status: string, taxCollector: string>>"
    content-pos-inventory: "record<contentLanguage: string, gtin: string, itemId: string, kind: string, price: record<currency: string, value: string>, quantity: string, storeCode: string, targetCountry: string, timestamp: string>"
    content-pos-sale: "record<contentLanguage: string, gtin: string, itemId: string, kind: string, price: record<currency: string, value: string>, quantity: string, saleId: string, storeCode: string, targetCountry: string, timestamp: string>"
    content-pos-list: "record<kind: string, resources: table<gcidCategory: list, kind: string, phoneNumber: string, placeId: string, storeAddress: string, storeCode: string, storeName: string, websiteUrl: string>>"
    content-pos-insert: "record<gcidCategory: list<string>, kind: string, phoneNumber: string, placeId: string, storeAddress: string, storeCode: string, storeName: string, websiteUrl: string>"
    content-pos-get: "record<gcidCategory: list<string>, kind: string, phoneNumber: string, placeId: string, storeAddress: string, storeCode: string, storeName: string, websiteUrl: string>"
    content-products-list: "record<kind: string, nextPageToken: string, resources: table<additionalImageLinks: list, additionalProductTypes: list, adult: bool, adwordsGrouping: string, adwordsLabels: list, adwordsRedirect: string, ageGroup: string, aspects: list, availability: string, availabilityDate: string, brand: string, canonicalLink: string, channel: string, color: string, condition: string, contentLanguage: string, costOfGoodsSold: record, customAttributes: list, customGroups: list, customLabel0: string, customLabel1: string, customLabel2: string, customLabel3: string, customLabel4: string, description: string, destinations: list, displayAdsId: string, displayAdsLink: string, displayAdsSimilarIds: list, displayAdsTitle: string, displayAdsValue: float, energyEfficiencyClass: string, expirationDate: string, gender: string, googleProductCategory: string, gtin: string, id: string, identifierExists: bool, imageLink: string, installment: record, isBundle: bool, itemGroupId: string, kind: string, link: string, loyaltyPoints: record, material: string, maxEnergyEfficiencyClass: string, maxHandlingTime: string, minEnergyEfficiencyClass: string, minHandlingTime: string, mobileLink: string, mpn: string, multipack: string, offerId: string, onlineOnly: bool, pattern: string, price: record, productType: string, promotionIds: list, salePrice: record, salePriceEffectiveDate: string, sellOnGoogleQuantity: string, shipping: list, shippingHeight: record, shippingLabel: string, shippingLength: record, shippingWeight: record, shippingWidth: record, sizeSystem: string, sizeType: string, sizes: list, source: string, targetCountry: string, taxes: list, title: string, unitPricingBaseMeasure: record, unitPricingMeasure: record, validatedDestinations: list, warnings: list>>"
    content-products-insert: "record<additionalImageLinks: list<string>, additionalProductTypes: list<string>, adult: bool, adwordsGrouping: string, adwordsLabels: list<string>, adwordsRedirect: string, ageGroup: string, aspects: table<aspectName: string, destinationName: string, intention: string>, availability: string, availabilityDate: string, brand: string, canonicalLink: string, channel: string, color: string, condition: string, contentLanguage: string, costOfGoodsSold: record<currency: string, value: string>, customAttributes: table<name: string, type: string, unit: string, value: string>, customGroups: table<attributes: list, name: string>, customLabel0: string, customLabel1: string, customLabel2: string, customLabel3: string, customLabel4: string, description: string, destinations: table<destinationName: string, intention: string>, displayAdsId: string, displayAdsLink: string, displayAdsSimilarIds: list<string>, displayAdsTitle: string, displayAdsValue: float, energyEfficiencyClass: string, expirationDate: string, gender: string, googleProductCategory: string, gtin: string, id: string, identifierExists: bool, imageLink: string, installment: record<amount: record<currency: string, value: string>, months: string>, isBundle: bool, itemGroupId: string, kind: string, link: string, loyaltyPoints: record<name: string, pointsValue: string, ratio: float>, material: string, maxEnergyEfficiencyClass: string, maxHandlingTime: string, minEnergyEfficiencyClass: string, minHandlingTime: string, mobileLink: string, mpn: string, multipack: string, offerId: string, onlineOnly: bool, pattern: string, price: record<currency: string, value: string>, productType: string, promotionIds: list<string>, salePrice: record<currency: string, value: string>, salePriceEffectiveDate: string, sellOnGoogleQuantity: string, shipping: table<country: string, locationGroupName: string, locationId: string, postalCode: string, price: record, region: string, service: string>, shippingHeight: record<unit: string, value: float>, shippingLabel: string, shippingLength: record<unit: string, value: float>, shippingWeight: record<unit: string, value: float>, shippingWidth: record<unit: string, value: float>, sizeSystem: string, sizeType: string, sizes: list<string>, source: string, targetCountry: string, taxes: table<country: string, locationId: string, postalCode: string, rate: float, region: string, taxShip: bool>, title: string, unitPricingBaseMeasure: record<unit: string, value: string>, unitPricingMeasure: record<unit: string, value: float>, validatedDestinations: list<string>, warnings: table<domain: string, message: string, reason: string>>"
    content-products-get: "record<additionalImageLinks: list<string>, additionalProductTypes: list<string>, adult: bool, adwordsGrouping: string, adwordsLabels: list<string>, adwordsRedirect: string, ageGroup: string, aspects: table<aspectName: string, destinationName: string, intention: string>, availability: string, availabilityDate: string, brand: string, canonicalLink: string, channel: string, color: string, condition: string, contentLanguage: string, costOfGoodsSold: record<currency: string, value: string>, customAttributes: table<name: string, type: string, unit: string, value: string>, customGroups: table<attributes: list, name: string>, customLabel0: string, customLabel1: string, customLabel2: string, customLabel3: string, customLabel4: string, description: string, destinations: table<destinationName: string, intention: string>, displayAdsId: string, displayAdsLink: string, displayAdsSimilarIds: list<string>, displayAdsTitle: string, displayAdsValue: float, energyEfficiencyClass: string, expirationDate: string, gender: string, googleProductCategory: string, gtin: string, id: string, identifierExists: bool, imageLink: string, installment: record<amount: record<currency: string, value: string>, months: string>, isBundle: bool, itemGroupId: string, kind: string, link: string, loyaltyPoints: record<name: string, pointsValue: string, ratio: float>, material: string, maxEnergyEfficiencyClass: string, maxHandlingTime: string, minEnergyEfficiencyClass: string, minHandlingTime: string, mobileLink: string, mpn: string, multipack: string, offerId: string, onlineOnly: bool, pattern: string, price: record<currency: string, value: string>, productType: string, promotionIds: list<string>, salePrice: record<currency: string, value: string>, salePriceEffectiveDate: string, sellOnGoogleQuantity: string, shipping: table<country: string, locationGroupName: string, locationId: string, postalCode: string, price: record, region: string, service: string>, shippingHeight: record<unit: string, value: float>, shippingLabel: string, shippingLength: record<unit: string, value: float>, shippingWeight: record<unit: string, value: float>, shippingWidth: record<unit: string, value: float>, sizeSystem: string, sizeType: string, sizes: list<string>, source: string, targetCountry: string, taxes: table<country: string, locationId: string, postalCode: string, rate: float, region: string, taxShip: bool>, title: string, unitPricingBaseMeasure: record<unit: string, value: string>, unitPricingMeasure: record<unit: string, value: float>, validatedDestinations: list<string>, warnings: table<domain: string, message: string, reason: string>>"
    content-productstatuses-list: "record<kind: string, nextPageToken: string, resources: table<creationDate: string, dataQualityIssues: list, destinationStatuses: list, googleExpirationDate: string, itemLevelIssues: list, kind: string, lastUpdateDate: string, link: string, product: record, productId: string, title: string>>"
    content-productstatuses-get: "record<creationDate: string, dataQualityIssues: table<destination: string, detail: string, fetchStatus: string, id: string, location: string, severity: string, timestamp: string, valueOnLandingPage: string, valueProvided: string>, destinationStatuses: table<approvalPending: bool, approvalStatus: string, destination: string, intention: string>, googleExpirationDate: string, itemLevelIssues: table<attributeName: string, code: string, description: string, destination: string, detail: string, documentation: string, resolution: string, servability: string>, kind: string, lastUpdateDate: string, link: string, product: record<additionalImageLinks: list<string>, additionalProductTypes: list<string>, adult: bool, adwordsGrouping: string, adwordsLabels: list<string>, adwordsRedirect: string, ageGroup: string, aspects: list<record>, availability: string, availabilityDate: string, brand: string, canonicalLink: string, channel: string, color: string, condition: string, contentLanguage: string, costOfGoodsSold: record<currency: string, value: string>, customAttributes: list<record>, customGroups: list<record>, customLabel0: string, customLabel1: string, customLabel2: string, customLabel3: string, customLabel4: string, description: string, destinations: list<record>, displayAdsId: string, displayAdsLink: string, displayAdsSimilarIds: list<string>, displayAdsTitle: string, displayAdsValue: float, energyEfficiencyClass: string, expirationDate: string, gender: string, googleProductCategory: string, gtin: string, id: string, identifierExists: bool, imageLink: string, installment: record<amount: record, months: string>, isBundle: bool, itemGroupId: string, kind: string, link: string, loyaltyPoints: record<name: string, pointsValue: string, ratio: float>, material: string, maxEnergyEfficiencyClass: string, maxHandlingTime: string, minEnergyEfficiencyClass: string, minHandlingTime: string, mobileLink: string, mpn: string, multipack: string, offerId: string, onlineOnly: bool, pattern: string, price: record<currency: string, value: string>, productType: string, promotionIds: list<string>, salePrice: record<currency: string, value: string>, salePriceEffectiveDate: string, sellOnGoogleQuantity: string, shipping: list<record>, shippingHeight: record<unit: string, value: float>, shippingLabel: string, shippingLength: record<unit: string, value: float>, shippingWeight: record<unit: string, value: float>, shippingWidth: record<unit: string, value: float>, sizeSystem: string, sizeType: string, sizes: list<string>, source: string, targetCountry: string, taxes: list<record>, title: string, unitPricingBaseMeasure: record<unit: string, value: string>, unitPricingMeasure: record<unit: string, value: float>, validatedDestinations: list<string>, warnings: list<record>>, productId: string, title: string>"
    content-shippingsettings-list: "record<kind: string, nextPageToken: string, resources: table<accountId: string, postalCodeGroups: list, services: list, warehouses: list>>"
    content-shippingsettings-get: "record<accountId: string, postalCodeGroups: table<country: string, name: string, postalCodeRanges: list>, services: table<active: bool, currency: string, deliveryCountry: string, deliveryTime: record, eligibility: string, minimumOrderValue: record, minimumOrderValueTable: record, name: string, pickupService: record, rateGroups: list, shipmentType: string>, warehouses: table<businessDayConfig: record, cutoffTime: record, handlingDays: string, name: string, shippingAddress: record>>"
    content-shippingsettings-update: "record<accountId: string, postalCodeGroups: table<country: string, name: string, postalCodeRanges: list>, services: table<active: bool, currency: string, deliveryCountry: string, deliveryTime: record, eligibility: string, minimumOrderValue: record, minimumOrderValueTable: record, name: string, pickupService: record, rateGroups: list, shipmentType: string>, warehouses: table<businessDayConfig: record, cutoffTime: record, handlingDays: string, name: string, shippingAddress: record>>"
    content-shippingsettings-getsupportedcarriers: "record<carriers: table<country: string, eddServices: list, name: string, services: list>, kind: string>"
    content-shippingsettings-getsupportedholidays: "record<holidays: table<countryCode: string, date: string, deliveryGuaranteeDate: string, deliveryGuaranteeHour: string, id: string, type: string>, kind: string>"
    content-shippingsettings-getsupportedpickupservices: "record<kind: string, pickupServices: table<carrierName: string, country: string, serviceName: string>>"
    content-orders-createtestorder: "record<kind: string, orderId: string>"
    content-orders-advancetestorder: "record<kind: string>"
    content-orders-canceltestorderbycustomer: "record<kind: string>"
    content-orders-gettestordertemplate: "record<kind: string, template: record<customer: record<email: string, explicitMarketingPreference: bool, fullName: string, marketingRightsInfo: record>, enableOrderinvoices: bool, kind: string, lineItems: list<record>, notificationMode: string, paymentMethod: record<expirationMonth: int, expirationYear: int, lastFourDigits: string, predefinedBillingAddress: string, type: string>, predefinedDeliveryAddress: string, predefinedPickupDetails: string, promotions: list<record>, shippingCost: record<currency: string, value: string>, shippingCostTax: record<currency: string, value: string>, shippingOption: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["content-accounts-authinfo" "content-accounts-custombatch" "content-accountstatuses-custombatch" "content-accounttax-custombatch" "content-datafeeds-custombatch" "content-datafeedstatuses-custombatch" "content-liasettings-custombatch" "content-liasettings-listposdataproviders" "content-orders-custombatch" "content-pos-custombatch" "content-products-custombatch" "content-productstatuses-custombatch" "content-shippingsettings-custombatch" "content-accounts-list" "content-accounts-insert" "content-accounts-delete" "content-accounts-get" "content-accounts-update" "content-accounts-claimwebsite" "content-accounts-link" "content-accountstatuses-list" "content-accountstatuses-get" "content-accounttax-list" "content-accounttax-get" "content-accounttax-update" "content-datafeeds-list" "content-datafeeds-insert" "content-datafeeds-delete" "content-datafeeds-get" "content-datafeeds-update" "content-datafeeds-fetchnow" "content-datafeedstatuses-list" "content-datafeedstatuses-get" "content-liasettings-list" "content-liasettings-get" "content-liasettings-update" "content-liasettings-getaccessiblegmbaccounts" "content-liasettings-requestgmbaccess" "content-liasettings-requestinventoryverification" "content-liasettings-setinventoryverificationcontact" "content-liasettings-setposdataprovider" "content-orderinvoices-createchargeinvoice" "content-orderinvoices-createrefundinvoice" "content-orderreports-listdisbursements" "content-orderreports-listtransactions" "content-orderreturns-list" "content-orderreturns-get" "content-orders-list" "content-orders-get" "content-orders-acknowledge" "content-orders-cancel" "content-orders-cancellineitem" "content-orders-instorerefundlineitem" "content-orders-refund" "content-orders-rejectreturnlineitem" "content-orders-returnlineitem" "content-orders-returnrefundlineitem" "content-orders-setlineitemmetadata" "content-orders-shiplineitems" "content-orders-createtestreturn" "content-orders-updatelineitemshippingdetails" "content-orders-updatemerchantorderid" "content-orders-updateshipment" "content-orders-getbymerchantorderid" "content-pos-inventory" "content-pos-sale" "content-pos-list" "content-pos-insert" "content-pos-delete" "content-pos-get" "content-products-list" "content-products-insert" "content-products-delete" "content-products-get" "content-productstatuses-list" "content-productstatuses-get" "content-shippingsettings-list" "content-shippingsettings-get" "content-shippingsettings-update" "content-shippingsettings-getsupportedcarriers" "content-shippingsettings-getsupportedholidays" "content-shippingsettings-getsupportedpickupservices" "content-orders-createtestorder" "content-orders-advancetestorder" "content-orders-canceltestorderbycustomer" "content-orders-gettestordertemplate" "commands"] | sort) } | get name | first)
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
# Returns: record<entries: table<account: record, batchId: int, errors: record, kind: string, linkStatus: string>, kind: string>
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any). (spec name: dryRun)
  --entries: list # The request entries to be processed in the batch. — item shape: {account?: record, accountId?: string, batchId?: int, force?: bool, labelIds?: list<string>, linkRequest?: record, merchantId?: string, method?: string, overwrite?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/batch"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dryRun, var: qp_dry_run}]
    body: {content_type: "application/json", kind: json, fields: [{name: entries, var: entries}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, qp_dry_run: $qp_dry_run, entries: $entries
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any). (spec name: dryRun)
  --entries: list # The request entries to be processed in the batch. — item shape: {accountId?: string, accountTax?: record, batchId?: int, merchantId?: string, method?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounttax/batch"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dryRun, var: qp_dry_run}]
    body: {content_type: "application/json", kind: json, fields: [{name: entries, var: entries}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, qp_dry_run: $qp_dry_run, entries: $entries
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any). (spec name: dryRun)
  --entries: list # The request entries to be processed in the batch. — item shape: {batchId?: int, datafeed?: record, datafeedId?: string, merchantId?: string, method?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/datafeeds/batch"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dryRun, var: qp_dry_run}]
    body: {content_type: "application/json", kind: json, fields: [{name: entries, var: entries}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, qp_dry_run: $qp_dry_run, entries: $entries
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
  --entries: list # The request entries to be processed in the batch. — item shape: {batchId?: int, country?: string, datafeedId?: string, language?: string, merchantId?: string, method?: string}
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any). (spec name: dryRun)
  --entries: list # The request entries to be processed in the batch. — item shape: {accountId?: string, batchId?: int, contactEmail?: string, contactName?: string, country?: string, gmbEmail?: string, liaSettings?: record, merchantId?: string, method?: string, posDataProviderId?: string, posExternalAccountId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/liasettings/batch"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dryRun, var: qp_dry_run}]
    body: {content_type: "application/json", kind: json, fields: [{name: entries, var: entries}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, qp_dry_run: $qp_dry_run, entries: $entries
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

# Retrieves or modifies multiple orders in a single request.
#
# POST /orders/batch
# Returns: record<entries: table<batchId: int, errors: record, executionStatus: string, kind: string, order: record>, kind: string>
# operationId: content.orders.custombatch
export def "content-orders-custombatch" [
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
  --entries: list # The request entries to be processed in the batch. — item shape: {batchId?: int, cancel?: record, cancelLineItem?: record, inStoreRefundLineItem?: record, merchantId?: string, merchantOrderId?: string, method?: string, operationId?: string, orderId?: string, refund?: record, rejectReturnLineItem?: record, returnLineItem?: record, returnRefundLineItem?: record, setLineItemMetadata?: record, shipLineItems?: record, updateLineItemShippingDetails?: record, updateShipment?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/orders/batch"
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any). (spec name: dryRun)
  --entries: list # The request entries to be processed in the batch. — item shape: {batchId?: int, inventory?: record, merchantId?: string, method?: string, sale?: record, store?: record, storeCode?: string, targetMerchantId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/pos/batch"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dryRun, var: qp_dry_run}]
    body: {content_type: "application/json", kind: json, fields: [{name: entries, var: entries}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, qp_dry_run: $qp_dry_run, entries: $entries
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any). (spec name: dryRun)
  --entries: list # The request entries to be processed in the batch. — item shape: {batchId?: int, merchantId?: string, method?: string, product?: record, productId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/products/batch"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dryRun, var: qp_dry_run}]
    body: {content_type: "application/json", kind: json, fields: [{name: entries, var: entries}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, qp_dry_run: $qp_dry_run, entries: $entries
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
  --include-attributes: oneof<nothing, bool> # Flag to include full product data in the results of this request. The default value is false.
  --entries: list # The request entries to be processed in the batch. — item shape: {batchId?: int, destinations?: list<string>, includeAttributes?: bool, merchantId?: string, method?: string, productId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/productstatuses/batch"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: includeAttributes, var: include_attributes}]
    body: {content_type: "application/json", kind: json, fields: [{name: entries, var: entries}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, include_attributes: $include_attributes, entries: $entries
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any). (spec name: dryRun)
  --entries: list # The request entries to be processed in the batch. — item shape: {accountId?: string, batchId?: int, merchantId?: string, method?: string, shippingSettings?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/shippingsettings/batch"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dryRun, var: qp_dry_run}]
    body: {content_type: "application/json", kind: json, fields: [{name: entries, var: entries}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, qp_dry_run: $qp_dry_run, entries: $entries
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the sub-accounts in your Merchant Center account.
#
# GET /{merchantId}/accounts
# Returns: record<kind: string, nextPageToken: string, resources: table<adultContent: bool, adwordsLinks: list, businessInformation: record, googleMyBusinessLink: record, id: string, kind: string, name: string, reviewsUrl: string, sellerId: string, users: list, websiteUrl: string, youtubeChannelLinks: list>>
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
  --max-results: int # The maximum number of accounts to return in the response, used for paging.
  --page-token: string # The token returned by the previous request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/accounts"
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

# Creates a Merchant Center sub-account.
#
# POST /{merchantId}/accounts
# Returns: record<adultContent: bool, adwordsLinks: table<adwordsId: string, status: string>, businessInformation: record<address: record<country: string, locality: string, postalCode: string, region: string, streetAddress: string>, customerService: record<email: string, phoneNumber: string, url: string>, koreanBusinessRegistrationNumber: string, phoneNumber: string>, googleMyBusinessLink: record<gmbEmail: string, status: string>, id: string, kind: string, name: string, reviewsUrl: string, sellerId: string, users: table<admin: bool, emailAddress: string, orderManager: bool, paymentsAnalyst: bool, paymentsManager: bool>, websiteUrl: string, youtubeChannelLinks: table<channelId: string, status: string>>
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any). (spec name: dryRun)
  --adult-content: oneof<nothing, bool> # Indicates whether the merchant sells adult content.
  --adwords-links: list # List of linked AdWords accounts that are active or pending approval. To create a new link request, add a new link with status `active` to the list. It will remain in a `pending` state until approved or rejected either in the AdWords interface or through the AdWords API. To delete an active link, or to cancel a link request, remove it from the list. — item shape: {adwordsId?: string, status?: string}
  --business-information: record # shape: {address?: record, customerService?: record, koreanBusinessRegistrationNumber?: string, phoneNumber?: string}
  --google-my-business-link: record # shape: {gmbEmail?: string, status?: string}
  --id: string # Required for update. Merchant Center account ID. (format: uint64)
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "`content#account`"
  --name: string # Required. Display name for the account.
  --reviews-url: string # [DEPRECATED] This field is never returned and will be ignored if provided.
  --seller-id: string # Client-specific, locally-unique, internal ID for the child account.
  --users: list # Users with access to the account. Every account (except for subaccounts) must have at least one admin user. — item shape: {admin?: bool, emailAddress?: string, orderManager?: bool, paymentsAnalyst?: bool, paymentsManager?: bool}
  --website-url: string # The merchant's website.
  --youtube-channel-links: list # List of linked YouTube channels that are active or pending approval. To create a new link request, add a new link with status `active` to the list. It will remain in a `pending` state until approved or rejected in the YT Creator Studio interface. To delete an active link, or to cancel a link request, remove it from the list. — item shape: {channelId?: string, status?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/accounts"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dryRun, var: qp_dry_run}]
    body: {content_type: "application/json", kind: json, fields: [{name: adultContent, var: adult_content}, {name: adwordsLinks, var: adwords_links}, {name: businessInformation, var: business_information}, {name: googleMyBusinessLink, var: google_my_business_link}, {name: id, var: id}, {name: kind, var: kind}, {name: name, var: name}, {name: reviewsUrl, var: reviews_url}, {name: sellerId, var: seller_id}, {name: users, var: users}, {name: websiteUrl, var: website_url}, {name: youtubeChannelLinks, var: youtube_channel_links}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, qp_dry_run: $qp_dry_run, adult_content: $adult_content, adwords_links: $adwords_links, business_information: $business_information, google_my_business_link: $google_my_business_link, id: $id, kind: $kind, name: $name, reviews_url: $reviews_url, seller_id: $seller_id, users: $users, website_url: $website_url, youtube_channel_links: $youtube_channel_links
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any). (spec name: dryRun)
  --force: oneof<nothing, bool> # Flag to delete sub-accounts with products. The default value is false.
]: nothing -> any {
  http-request {
    method: delete
    path: "/{merchantId}/accounts/{accountId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: accountId, var: account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dryRun, var: qp_dry_run}, {name: force, var: force}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, account_id: $account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, qp_dry_run: $qp_dry_run, force: $force
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a Merchant Center account.
#
# GET /{merchantId}/accounts/{accountId}
# Returns: record<adultContent: bool, adwordsLinks: table<adwordsId: string, status: string>, businessInformation: record<address: record<country: string, locality: string, postalCode: string, region: string, streetAddress: string>, customerService: record<email: string, phoneNumber: string, url: string>, koreanBusinessRegistrationNumber: string, phoneNumber: string>, googleMyBusinessLink: record<gmbEmail: string, status: string>, id: string, kind: string, name: string, reviewsUrl: string, sellerId: string, users: table<admin: bool, emailAddress: string, orderManager: bool, paymentsAnalyst: bool, paymentsManager: bool>, websiteUrl: string, youtubeChannelLinks: table<channelId: string, status: string>>
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/accounts/{accountId}"
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

# Updates a Merchant Center account. Any fields that are not provided are deleted from the resource.
#
# PUT /{merchantId}/accounts/{accountId}
# Returns: record<adultContent: bool, adwordsLinks: table<adwordsId: string, status: string>, businessInformation: record<address: record<country: string, locality: string, postalCode: string, region: string, streetAddress: string>, customerService: record<email: string, phoneNumber: string, url: string>, koreanBusinessRegistrationNumber: string, phoneNumber: string>, googleMyBusinessLink: record<gmbEmail: string, status: string>, id: string, kind: string, name: string, reviewsUrl: string, sellerId: string, users: table<admin: bool, emailAddress: string, orderManager: bool, paymentsAnalyst: bool, paymentsManager: bool>, websiteUrl: string, youtubeChannelLinks: table<channelId: string, status: string>>
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any). (spec name: dryRun)
  --adult-content: oneof<nothing, bool> # Indicates whether the merchant sells adult content.
  --adwords-links: list # List of linked AdWords accounts that are active or pending approval. To create a new link request, add a new link with status `active` to the list. It will remain in a `pending` state until approved or rejected either in the AdWords interface or through the AdWords API. To delete an active link, or to cancel a link request, remove it from the list. — item shape: {adwordsId?: string, status?: string}
  --business-information: record # shape: {address?: record, customerService?: record, koreanBusinessRegistrationNumber?: string, phoneNumber?: string}
  --google-my-business-link: record # shape: {gmbEmail?: string, status?: string}
  --id: string # Required for update. Merchant Center account ID. (format: uint64)
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "`content#account`"
  --name: string # Required. Display name for the account.
  --reviews-url: string # [DEPRECATED] This field is never returned and will be ignored if provided.
  --seller-id: string # Client-specific, locally-unique, internal ID for the child account.
  --users: list # Users with access to the account. Every account (except for subaccounts) must have at least one admin user. — item shape: {admin?: bool, emailAddress?: string, orderManager?: bool, paymentsAnalyst?: bool, paymentsManager?: bool}
  --website-url: string # The merchant's website.
  --youtube-channel-links: list # List of linked YouTube channels that are active or pending approval. To create a new link request, add a new link with status `active` to the list. It will remain in a `pending` state until approved or rejected in the YT Creator Studio interface. To delete an active link, or to cancel a link request, remove it from the list. — item shape: {channelId?: string, status?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{merchantId}/accounts/{accountId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: accountId, var: account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dryRun, var: qp_dry_run}]
    body: {content_type: "application/json", kind: json, fields: [{name: adultContent, var: adult_content}, {name: adwordsLinks, var: adwords_links}, {name: businessInformation, var: business_information}, {name: googleMyBusinessLink, var: google_my_business_link}, {name: id, var: id}, {name: kind, var: kind}, {name: name, var: name}, {name: reviewsUrl, var: reviews_url}, {name: sellerId, var: seller_id}, {name: users, var: users}, {name: websiteUrl, var: website_url}, {name: youtubeChannelLinks, var: youtube_channel_links}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, account_id: $account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, qp_dry_run: $qp_dry_run, adult_content: $adult_content, adwords_links: $adwords_links, business_information: $business_information, google_my_business_link: $google_my_business_link, id: $id, kind: $kind, name: $name, reviews_url: $reviews_url, seller_id: $seller_id, users: $users, website_url: $website_url, youtube_channel_links: $youtube_channel_links
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Claims the website of a Merchant Center sub-account.
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
  --overwrite: oneof<nothing, bool> # Only available to selected merchants. When set to `True`, this flag removes any existing claim on the requested website by another account and replaces it with a claim from this account.
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
  --link-type: string # Type of the link between the two accounts. Acceptable values are: - "`channelPartner`" - "`eCommercePlatform`"
  --linked-account-id: string # The ID of the linked account.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/accounts/{accountId}/link"
    path_params: [{name: merchantId, var: merchant_id}, {name: accountId, var: account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: linkType, var: link_type}, {name: linkedAccountId, var: linked_account_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, account_id: $account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, action: $action, link_type: $link_type, linked_account_id: $linked_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the statuses of the sub-accounts in your Merchant Center account.
#
# GET /{merchantId}/accountstatuses
# Returns: record<kind: string, nextPageToken: string, resources: table<accountId: string, accountLevelIssues: list, dataQualityIssues: list, kind: string, products: list, websiteClaimed: bool>>
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
  --page-token: string # The token returned by the previous request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/accountstatuses"
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

# Retrieves the status of a Merchant Center account. No itemLevelIssues are returned for multi-client accounts.
#
# GET /{merchantId}/accountstatuses/{accountId}
# Returns: record<accountId: string, accountLevelIssues: table<country: string, destination: string, detail: string, documentation: string, id: string, severity: string, title: string>, dataQualityIssues: table<country: string, destination: string, detail: string, displayedValue: string, exampleItems: list, id: string, lastChecked: string, location: string, numItems: int, severity: string, submittedValue: string>, kind: string, products: table<channel: string, country: string, destination: string, itemLevelIssues: list, statistics: record>, websiteClaimed: bool>
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any). (spec name: dryRun)
  --body-account-id: string # Required. The ID of the account to which these account tax settings belong. (format: uint64) (spec name: accountId)
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "content#accountTax".
  --rules: list # Tax rules. Updating the tax rules will enable US taxes (not reversible). Defining no rules is equivalent to not charging tax at all. — item shape: {country?: string, locationId?: string, ratePercent?: string, shippingTaxed?: bool, useGlobalRate?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{merchantId}/accounttax/{accountId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: accountId, var: account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dryRun, var: qp_dry_run}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: kind, var: kind}, {name: rules, var: rules}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, account_id: $account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, qp_dry_run: $qp_dry_run, body_account_id: $body_account_id, kind: $kind, rules: $rules
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the configurations for datafeeds in your Merchant Center account.
#
# GET /{merchantId}/datafeeds
# Returns: record<kind: string, nextPageToken: string, resources: table<attributeLanguage: string, contentLanguage: string, contentType: string, fetchSchedule: record, fileName: string, format: record, id: string, intendedDestinations: list, kind: string, name: string, targetCountry: string, targets: list>>
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
# Returns: record<attributeLanguage: string, contentLanguage: string, contentType: string, fetchSchedule: record<dayOfMonth: int, fetchUrl: string, hour: int, minuteOfHour: int, password: string, paused: bool, timeZone: string, username: string, weekday: string>, fileName: string, format: record<columnDelimiter: string, fileEncoding: string, quotingMode: string>, id: string, intendedDestinations: list<string>, kind: string, name: string, targetCountry: string, targets: table<country: string, excludedDestinations: list, includedDestinations: list, language: string>>
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any). (spec name: dryRun)
  --attribute-language: string # The two-letter ISO 639-1 language in which the attributes are defined in the data feed.
  --content-language: string # [DEPRECATED] Please use targets[].language instead. The two-letter ISO 639-1 language of the items in the feed. Must be a valid language for `targetCountry`.
  --content-type: string # Required. The type of data feed. For product inventory feeds, only feeds for local stores, not online stores, are supported. Acceptable values are: - "`local products`" - "`product inventory`" - "`products`"
  --fetch-schedule: record # The required fields vary based on the frequency of fetching. For a monthly fetch schedule, day_of_month and hour are required. For a weekly fetch schedule, weekday and hour are required. For a daily fetch schedule, only hour is required. — shape: {dayOfMonth?: int, fetchUrl?: string, hour?: int, minuteOfHour?: int, password?: string, paused?: bool, timeZone?: string, username?: string, weekday?: string}
  --file-name: string # Required. The filename of the feed. All feeds must have a unique file name.
  --format: record # shape: {columnDelimiter?: string, fileEncoding?: string, quotingMode?: string}
  --id: string # Required for update. The ID of the data feed. (format: int64)
  --intended-destinations: list<string> # [DEPRECATED] Please use targets[].includedDestinations instead. The list of intended destinations (corresponds to checked check boxes in Merchant Center).
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "`content#datafeed`"
  --name: string # Required for insert. A descriptive name of the data feed.
  --target-country: string # [DEPRECATED] Please use targets[].country instead. The country where the items in the feed will be included in the search index, represented as a CLDR territory code.
  --targets: list # The targets this feed should apply to (country, language, destinations). — item shape: {country?: string, excludedDestinations?: list<string>, includedDestinations?: list<string>, language?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/datafeeds"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dryRun, var: qp_dry_run}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributeLanguage, var: attribute_language}, {name: contentLanguage, var: content_language}, {name: contentType, var: content_type}, {name: fetchSchedule, var: fetch_schedule}, {name: fileName, var: file_name}, {name: format, var: format}, {name: id, var: id}, {name: intendedDestinations, var: intended_destinations}, {name: kind, var: kind}, {name: name, var: name}, {name: targetCountry, var: target_country}, {name: targets, var: targets}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, qp_dry_run: $qp_dry_run, attribute_language: $attribute_language, content_language: $content_language, content_type: $content_type, fetch_schedule: $fetch_schedule, file_name: $file_name, format: $format, id: $id, intended_destinations: $intended_destinations, kind: $kind, name: $name, target_country: $target_country, targets: $targets
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any). (spec name: dryRun)
]: nothing -> any {
  http-request {
    method: delete
    path: "/{merchantId}/datafeeds/{datafeedId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: datafeedId, var: datafeed_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dryRun, var: qp_dry_run}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, datafeed_id: $datafeed_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, qp_dry_run: $qp_dry_run
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a datafeed configuration from your Merchant Center account.
#
# GET /{merchantId}/datafeeds/{datafeedId}
# Returns: record<attributeLanguage: string, contentLanguage: string, contentType: string, fetchSchedule: record<dayOfMonth: int, fetchUrl: string, hour: int, minuteOfHour: int, password: string, paused: bool, timeZone: string, username: string, weekday: string>, fileName: string, format: record<columnDelimiter: string, fileEncoding: string, quotingMode: string>, id: string, intendedDestinations: list<string>, kind: string, name: string, targetCountry: string, targets: table<country: string, excludedDestinations: list, includedDestinations: list, language: string>>
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
# Returns: record<attributeLanguage: string, contentLanguage: string, contentType: string, fetchSchedule: record<dayOfMonth: int, fetchUrl: string, hour: int, minuteOfHour: int, password: string, paused: bool, timeZone: string, username: string, weekday: string>, fileName: string, format: record<columnDelimiter: string, fileEncoding: string, quotingMode: string>, id: string, intendedDestinations: list<string>, kind: string, name: string, targetCountry: string, targets: table<country: string, excludedDestinations: list, includedDestinations: list, language: string>>
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any). (spec name: dryRun)
  --attribute-language: string # The two-letter ISO 639-1 language in which the attributes are defined in the data feed.
  --content-language: string # [DEPRECATED] Please use targets[].language instead. The two-letter ISO 639-1 language of the items in the feed. Must be a valid language for `targetCountry`.
  --content-type: string # Required. The type of data feed. For product inventory feeds, only feeds for local stores, not online stores, are supported. Acceptable values are: - "`local products`" - "`product inventory`" - "`products`"
  --fetch-schedule: record # The required fields vary based on the frequency of fetching. For a monthly fetch schedule, day_of_month and hour are required. For a weekly fetch schedule, weekday and hour are required. For a daily fetch schedule, only hour is required. — shape: {dayOfMonth?: int, fetchUrl?: string, hour?: int, minuteOfHour?: int, password?: string, paused?: bool, timeZone?: string, username?: string, weekday?: string}
  --file-name: string # Required. The filename of the feed. All feeds must have a unique file name.
  --format: record # shape: {columnDelimiter?: string, fileEncoding?: string, quotingMode?: string}
  --id: string # Required for update. The ID of the data feed. (format: int64)
  --intended-destinations: list<string> # [DEPRECATED] Please use targets[].includedDestinations instead. The list of intended destinations (corresponds to checked check boxes in Merchant Center).
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "`content#datafeed`"
  --name: string # Required for insert. A descriptive name of the data feed.
  --target-country: string # [DEPRECATED] Please use targets[].country instead. The country where the items in the feed will be included in the search index, represented as a CLDR territory code.
  --targets: list # The targets this feed should apply to (country, language, destinations). — item shape: {country?: string, excludedDestinations?: list<string>, includedDestinations?: list<string>, language?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{merchantId}/datafeeds/{datafeedId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: datafeedId, var: datafeed_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dryRun, var: qp_dry_run}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributeLanguage, var: attribute_language}, {name: contentLanguage, var: content_language}, {name: contentType, var: content_type}, {name: fetchSchedule, var: fetch_schedule}, {name: fileName, var: file_name}, {name: format, var: format}, {name: id, var: id}, {name: intendedDestinations, var: intended_destinations}, {name: kind, var: kind}, {name: name, var: name}, {name: targetCountry, var: target_country}, {name: targets, var: targets}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, datafeed_id: $datafeed_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, qp_dry_run: $qp_dry_run, attribute_language: $attribute_language, content_language: $content_language, content_type: $content_type, fetch_schedule: $fetch_schedule, file_name: $file_name, format: $format, id: $id, intended_destinations: $intended_destinations, kind: $kind, name: $name, target_country: $target_country, targets: $targets
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invokes a fetch for the datafeed in your Merchant Center account. If you need to call this method more than once per day, we recommend you use the Products service to update your product data.
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any). (spec name: dryRun)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/{merchantId}/datafeeds/{datafeedId}/fetchNow"
    path_params: [{name: merchantId, var: merchant_id}, {name: datafeedId, var: datafeed_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dryRun, var: qp_dry_run}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, datafeed_id: $datafeed_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, qp_dry_run: $qp_dry_run
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the statuses of the datafeeds in your Merchant Center account.
#
# GET /{merchantId}/datafeedstatuses
# Returns: record<kind: string, nextPageToken: string, resources: table<country: string, datafeedId: string, errors: list, itemsTotal: string, itemsValid: string, kind: string, language: string, lastUploadDate: string, processingStatus: string, warnings: list>>
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
# Returns: record<country: string, datafeedId: string, errors: table<code: string, count: string, examples: list, message: string>, itemsTotal: string, itemsValid: string, kind: string, language: string, lastUploadDate: string, processingStatus: string, warnings: table<code: string, count: string, examples: list, message: string>>
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
  --country: string # The country for which to get the datafeed status. If this parameter is provided then language must also be provided. Note that this parameter is required for feeds targeting multiple countries and languages, since a feed may have a different status for each target.
  --language: string # The language for which to get the datafeed status. If this parameter is provided then country must also be provided. Note that this parameter is required for feeds targeting multiple countries and languages, since a feed may have a different status for each target.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/datafeedstatuses/{datafeedId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: datafeedId, var: datafeed_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: country, var: country}, {name: language, var: language}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, datafeed_id: $datafeed_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, country: $country, language: $language
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any). (spec name: dryRun)
  --body-account-id: string # The ID of the account to which these LIA settings belong. Ignored upon update, always present in get request responses. (format: uint64) (spec name: accountId)
  --country-settings: list # The LIA settings for each country. — item shape: {about?: record, country?: string, hostedLocalStorefrontActive?: bool, inventory?: record, onDisplayToOrder?: record, posDataProvider?: record, storePickupActive?: bool}
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "`content#liaSettings`"
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{merchantId}/liasettings/{accountId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: accountId, var: account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dryRun, var: qp_dry_run}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: countrySettings, var: country_settings}, {name: kind, var: kind}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, account_id: $account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, qp_dry_run: $qp_dry_run, body_account_id: $body_account_id, country_settings: $country_settings, kind: $kind
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the list of accessible Google My Business accounts.
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

# Requests access to a specified Google My Business account.
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
  --gmb-email: string # The email of the Google My Business account. (required)
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
  --invoice-summary: record # shape: {additionalChargeSummaries?: list, customerBalance?: record, googleBalance?: record, merchantBalance?: record, productTotal?: record, promotionSummaries?: list}
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
# Returns: record<kind: string, nextPageToken: string, transactions: table<disbursementAmount: record, disbursementCreationDate: string, disbursementDate: string, disbursementId: string, merchantId: string, merchantOrderId: string, orderId: string, productAmount: record, productAmountWithRemittedTax: record, transactionDate: string>>
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
# Returns: record<kind: string, nextPageToken: string, resources: table<creationDate: string, merchantOrderId: string, orderId: string, orderReturnId: string, returnItems: list, returnShipments: list>>
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
  --created-end-date: string # Obtains order returns created before this date (inclusively), in ISO 8601 format.
  --created-start-date: string # Obtains order returns created after this date (inclusively), in ISO 8601 format.
  --max-results: int # The maximum number of order returns to return in the response, used for paging. The default value is 25 returns per page, and the maximum allowed value is 250 returns per page.
  --order-by: string@order-by-completer # Return the results in the specified order.
  --page-token: string # The token returned by the previous request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/orderreturns"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: createdEndDate, var: created_end_date}, {name: createdStartDate, var: created_start_date}, {name: maxResults, var: max_results}, {name: orderBy, var: order_by}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, created_end_date: $created_end_date, created_start_date: $created_start_date, max_results: $max_results, order_by: $order_by, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves an order return from your Merchant Center account.
#
# GET /{merchantId}/orderreturns/{returnId}
# Returns: record<creationDate: string, merchantOrderId: string, orderId: string, orderReturnId: string, returnItems: table<customerReturnReason: record, itemId: string, merchantReturnReason: record, product: record, returnShipmentIds: list, state: string>, returnShipments: table<creationDate: string, deliveryDate: string, returnMethodType: string, shipmentId: string, shipmentTrackingInfos: list, shippingDate: string, state: string>>
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

# Lists the orders in your Merchant Center account.
#
# GET /{merchantId}/orders
# Returns: record<kind: string, nextPageToken: string, resources: table<acknowledged: bool, channelType: string, customer: record, deliveryDetails: record, id: string, kind: string, lineItems: list, merchantId: string, merchantOrderId: string, netAmount: record, paymentMethod: record, paymentStatus: string, pickupDetails: record, placedDate: string, promotions: list, refunds: list, shipments: list, shippingCost: record, shippingCostTax: record, shippingOption: string, status: string, taxCollector: string>>
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
  --statuses: list<string> # Obtains orders that match any of the specified statuses. Please note that `active` is a shortcut for `pendingShipment` and `partiallyShipped`, and `completed` is a shortcut for `shipped`, `partiallyDelivered`, `delivered`, `partiallyReturned`, `returned`, and `canceled`.
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
# Returns: record<acknowledged: bool, channelType: string, customer: record<email: string, explicitMarketingPreference: bool, fullName: string, invoiceReceivingEmail: string, marketingRightsInfo: record<explicitMarketingPreference: string, lastUpdatedTimestamp: string, marketingEmailAddress: string>>, deliveryDetails: record<address: record<country: string, fullAddress: list, isPostOfficeBox: bool, locality: string, postalCode: string, recipientName: string, region: string, streetAddress: list>, phoneNumber: string>, id: string, kind: string, lineItems: table<annotations: list, cancellations: list, id: string, price: record, product: record, quantityCanceled: int, quantityDelivered: int, quantityOrdered: int, quantityPending: int, quantityReadyForPickup: int, quantityReturned: int, quantityShipped: int, returnInfo: record, returns: list, shippingDetails: record, tax: record>, merchantId: string, merchantOrderId: string, netAmount: record<currency: string, value: string>, paymentMethod: record<billingAddress: record<country: string, fullAddress: list, isPostOfficeBox: bool, locality: string, postalCode: string, recipientName: string, region: string, streetAddress: list>, expirationMonth: int, expirationYear: int, lastFourDigits: string, phoneNumber: string, type: string>, paymentStatus: string, pickupDetails: record<address: record<country: string, fullAddress: list, isPostOfficeBox: bool, locality: string, postalCode: string, recipientName: string, region: string, streetAddress: list>, collectors: list<record>, locationId: string>, placedDate: string, promotions: table<benefits: list, effectiveDates: string, genericRedemptionCode: string, id: string, longTitle: string, productApplicability: string, redemptionChannel: string>, refunds: table<actor: string, amount: record, creationDate: string, reason: string, reasonText: string>, shipments: table<carrier: string, creationDate: string, deliveryDate: string, id: string, lineItems: list, scheduledDeliveryDetails: record, status: string, trackingId: string>, shippingCost: record<currency: string, value: string>, shippingCostTax: record<currency: string, value: string>, shippingOption: string, status: string, taxCollector: string>
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
  --reason: string # The reason for the cancellation. Acceptable values are: - "`customerInitiatedCancel`" - "`invalidCoupon`" - "`malformedShippingAddress`" - "`noInventory`" - "`other`" - "`priceError`" - "`shippingPriceError`" - "`taxError`" - "`undeliverableShippingAddress`" - "`unsupportedPoBoxAddress`"
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
  --amount: record # shape: {currency?: string, value?: string}
  --amount-pretax: record # shape: {currency?: string, value?: string}
  --amount-tax: record # shape: {currency?: string, value?: string}
  --line-item-id: string # The ID of the line item to cancel. Either lineItemId or productId is required.
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
  --product-id: string # The ID of the product to cancel. This is the REST ID used in the products service. Either lineItemId or productId is required.
  --quantity: int # The quantity to cancel. (format: uint32)
  --reason: string # The reason for the cancellation. Acceptable values are: - "`customerInitiatedCancel`" - "`invalidCoupon`" - "`malformedShippingAddress`" - "`noInventory`" - "`other`" - "`priceError`" - "`shippingPriceError`" - "`taxError`" - "`undeliverableShippingAddress`" - "`unsupportedPoBoxAddress`"
  --reason-text: string # The explanation of the reason.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/orders/{orderId}/cancelLineItem"
    path_params: [{name: merchantId, var: merchant_id}, {name: orderId, var: order_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: amountPretax, var: amount_pretax}, {name: amountTax, var: amount_tax}, {name: lineItemId, var: line_item_id}, {name: operationId, var: operation_id}, {name: productId, var: product_id}, {name: quantity, var: quantity}, {name: reason, var: reason}, {name: reasonText, var: reason_text}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, order_id: $order_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, amount: $amount, amount_pretax: $amount_pretax, amount_tax: $amount_tax, line_item_id: $line_item_id, operation_id: $operation_id, product_id: $product_id, quantity: $quantity, reason: $reason, reason_text: $reason_text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deprecated. Notifies that item return and refund was handled directly by merchant outside of Google payments processing (e.g. cash refund done in store). Note: We recommend calling the returnrefundlineitem method to refund in-store returns. We will issue the refund directly to the customer. This helps to prevent possible differences arising between merchant and Google transaction records. We also recommend having the point of sale system communicate with Google to ensure that customers do not receive a double refund by first refunding via Google then via an in-store return.
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
  --amount-pretax: record # shape: {currency?: string, value?: string}
  --amount-tax: record # shape: {currency?: string, value?: string}
  --line-item-id: string # The ID of the line item to return. Either lineItemId or productId is required.
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
  --product-id: string # The ID of the product to return. This is the REST ID used in the products service. Either lineItemId or productId is required.
  --quantity: int # The quantity to return and refund. (format: uint32)
  --reason: string # The reason for the return. Acceptable values are: - "`customerDiscretionaryReturn`" - "`customerInitiatedMerchantCancel`" - "`deliveredTooLate`" - "`expiredItem`" - "`invalidCoupon`" - "`malformedShippingAddress`" - "`other`" - "`productArrivedDamaged`" - "`productNotAsDescribed`" - "`qualityNotAsExpected`" - "`undeliverableShippingAddress`" - "`unsupportedPoBoxAddress`" - "`wrongProductShipped`"
  --reason-text: string # The explanation of the reason.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/orders/{orderId}/inStoreRefundLineItem"
    path_params: [{name: merchantId, var: merchant_id}, {name: orderId, var: order_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: amountPretax, var: amount_pretax}, {name: amountTax, var: amount_tax}, {name: lineItemId, var: line_item_id}, {name: operationId, var: operation_id}, {name: productId, var: product_id}, {name: quantity, var: quantity}, {name: reason, var: reason}, {name: reasonText, var: reason_text}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, order_id: $order_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, amount_pretax: $amount_pretax, amount_tax: $amount_tax, line_item_id: $line_item_id, operation_id: $operation_id, product_id: $product_id, quantity: $quantity, reason: $reason, reason_text: $reason_text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deprecated, please use returnRefundLineItem instead.
#
# POST /{merchantId}/orders/{orderId}/refund
# Returns: record<executionStatus: string, kind: string>
# operationId: content.orders.refund
export def "content-orders-refund" [
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
  --amount: record # shape: {currency?: string, value?: string}
  --amount-pretax: record # shape: {currency?: string, value?: string}
  --amount-tax: record # shape: {currency?: string, value?: string}
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
  --reason: string # The reason for the refund. Acceptable values are: - "`adjustment`" - "`courtesyAdjustment`" - "`customerCanceled`" - "`customerDiscretionaryReturn`" - "`deliveredLateByCarrier`" - "`feeAdjustment`" - "`lateShipmentCredit`" - "`noInventory`" - "`other`" - "`priceError`" - "`productArrivedDamaged`" - "`productNotAsDescribed`" - "`shippingCostAdjustment`" - "`taxAdjustment`" - "`undeliverableShippingAddress`" - "`wrongProductShipped`"
  --reason-text: string # The explanation of the reason.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/orders/{orderId}/refund"
    path_params: [{name: merchantId, var: merchant_id}, {name: orderId, var: order_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: amountPretax, var: amount_pretax}, {name: amountTax, var: amount_tax}, {name: operationId, var: operation_id}, {name: reason, var: reason}, {name: reasonText, var: reason_text}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, order_id: $order_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, amount: $amount, amount_pretax: $amount_pretax, amount_tax: $amount_tax, operation_id: $operation_id, reason: $reason, reason_text: $reason_text
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

# Returns a line item.
#
# POST /{merchantId}/orders/{orderId}/returnLineItem
# Returns: record<executionStatus: string, kind: string>
# operationId: content.orders.returnlineitem
export def "content-orders-returnlineitem" [
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
  --quantity: int # The quantity to return. (format: uint32)
  --reason: string # The reason for the return. Acceptable values are: - "`customerDiscretionaryReturn`" - "`customerInitiatedMerchantCancel`" - "`deliveredTooLate`" - "`expiredItem`" - "`invalidCoupon`" - "`malformedShippingAddress`" - "`other`" - "`productArrivedDamaged`" - "`productNotAsDescribed`" - "`qualityNotAsExpected`" - "`undeliverableShippingAddress`" - "`unsupportedPoBoxAddress`" - "`wrongProductShipped`"
  --reason-text: string # The explanation of the reason.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/orders/{orderId}/returnLineItem"
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

# Returns and refunds a line item. Note that this method can only be called on fully shipped orders. Please also note that the Orderreturns API is the preferred way to handle returns after you receive a return from a customer. You can use Orderreturns.list or Orderreturns.get to search for the return, and then use Orderreturns.processreturn to issue the refund. If the return cannot be found, then we recommend using this API to issue a refund.
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
  --amount-pretax: record # shape: {currency?: string, value?: string}
  --amount-tax: record # shape: {currency?: string, value?: string}
  --line-item-id: string # The ID of the line item to return. Either lineItemId or productId is required.
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
  --product-id: string # The ID of the product to return. This is the REST ID used in the products service. Either lineItemId or productId is required.
  --quantity: int # The quantity to return and refund. Quantity is required. (format: uint32)
  --reason: string # The reason for the return. Acceptable values are: - "`customerDiscretionaryReturn`" - "`customerInitiatedMerchantCancel`" - "`deliveredTooLate`" - "`expiredItem`" - "`invalidCoupon`" - "`malformedShippingAddress`" - "`other`" - "`productArrivedDamaged`" - "`productNotAsDescribed`" - "`qualityNotAsExpected`" - "`undeliverableShippingAddress`" - "`unsupportedPoBoxAddress`" - "`wrongProductShipped`"
  --reason-text: string # The explanation of the reason.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/orders/{orderId}/returnRefundLineItem"
    path_params: [{name: merchantId, var: merchant_id}, {name: orderId, var: order_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: amountPretax, var: amount_pretax}, {name: amountTax, var: amount_tax}, {name: lineItemId, var: line_item_id}, {name: operationId, var: operation_id}, {name: productId, var: product_id}, {name: quantity, var: quantity}, {name: reason, var: reason}, {name: reasonText, var: reason_text}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, order_id: $order_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, amount_pretax: $amount_pretax, amount_tax: $amount_tax, line_item_id: $line_item_id, operation_id: $operation_id, product_id: $product_id, quantity: $quantity, reason: $reason, reason_text: $reason_text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets (or overrides if it already exists) merchant provided annotations in the form of key-value pairs. A common use case would be to supply us with additional structured information about a line item that cannot be provided via other methods. Submitted key-value pairs can be retrieved as part of the orders resource.
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
  --carrier: string # Deprecated. Please use shipmentInfo instead. The carrier handling the shipment. See `shipments[].carrier` in the Orders resource representation for a list of acceptable values.
  --line-items: list # Line items to ship. — item shape: {lineItemId?: string, productId?: string, quantity?: int}
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
  --shipment-group-id: string # ID of the shipment group. Required for orders that use the orderinvoices service.
  --shipment-id: string # Deprecated. Please use shipmentInfo instead. The ID of the shipment.
  --shipment-infos: list # Shipment information. This field is repeated because a single line item can be shipped in several packages (and have several tracking IDs). — item shape: {carrier?: string, shipmentId?: string, trackingId?: string}
  --tracking-id: string # Deprecated. Please use shipmentInfo instead. The tracking ID for the shipment.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/orders/{orderId}/shipLineItems"
    path_params: [{name: merchantId, var: merchant_id}, {name: orderId, var: order_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: carrier, var: carrier}, {name: lineItems, var: line_items}, {name: operationId, var: operation_id}, {name: shipmentGroupId, var: shipment_group_id}, {name: shipmentId, var: shipment_id}, {name: shipmentInfos, var: shipment_infos}, {name: trackingId, var: tracking_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, order_id: $order_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, carrier: $carrier, line_items: $line_items, operation_id: $operation_id, shipment_group_id: $shipment_group_id, shipment_id: $shipment_id, shipment_infos: $shipment_infos, tracking_id: $tracking_id
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
  --deliver-by-date: string # Updated delivery by date, in ISO 8601 format. If not specified only ship by date is updated. Provided date should be within 1 year timeframe and can not be a date in the past.
  --line-item-id: string # The ID of the line item to set metadata. Either lineItemId or productId is required.
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
  --product-id: string # The ID of the product to set metadata. This is the REST ID used in the products service. Either lineItemId or productId is required.
  --ship-by-date: string # Updated ship by date, in ISO 8601 format. If not specified only deliver by date is updated. Provided date should be within 1 year timeframe and can not be a date in the past.
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
  --operation-id: string # The ID of the operation. Unique across all operations for a given order.
  --shipment-id: string # The ID of the shipment.
  --status: string # New status for the shipment. Not updated if missing. Acceptable values are: - "`delivered`" - "`undeliverable`" - "`readyForPickup`"
  --tracking-id: string # The tracking ID for the shipment. Not updated if missing.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/orders/{orderId}/updateShipment"
    path_params: [{name: merchantId, var: merchant_id}, {name: orderId, var: order_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: carrier, var: carrier}, {name: deliveryDate, var: delivery_date}, {name: operationId, var: operation_id}, {name: shipmentId, var: shipment_id}, {name: status, var: status}, {name: trackingId, var: tracking_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, order_id: $order_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, carrier: $carrier, delivery_date: $delivery_date, operation_id: $operation_id, shipment_id: $shipment_id, status: $status, tracking_id: $tracking_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves an order using merchant order ID.
#
# GET /{merchantId}/ordersbymerchantid/{merchantOrderId}
# Returns: record<kind: string, order: record<acknowledged: bool, channelType: string, customer: record<email: string, explicitMarketingPreference: bool, fullName: string, invoiceReceivingEmail: string, marketingRightsInfo: record>, deliveryDetails: record<address: record, phoneNumber: string>, id: string, kind: string, lineItems: list<record>, merchantId: string, merchantOrderId: string, netAmount: record<currency: string, value: string>, paymentMethod: record<billingAddress: record, expirationMonth: int, expirationYear: int, lastFourDigits: string, phoneNumber: string, type: string>, paymentStatus: string, pickupDetails: record<address: record, collectors: list, locationId: string>, placedDate: string, promotions: list<record>, refunds: list<record>, shipments: list<record>, shippingCost: record<currency: string, value: string>, shippingCostTax: record<currency: string, value: string>, shippingOption: string, status: string, taxCollector: string>>
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any). (spec name: dryRun)
  --content-language: string # Required. The two-letter ISO 639-1 language code for the item.
  --gtin: string # Global Trade Item Number.
  --item-id: string # Required. A unique identifier for the item.
  --price: record # shape: {currency?: string, value?: string}
  --quantity: string # Required. The available quantity of the item. (format: int64)
  --store-code: string # Required. The identifier of the merchant's store. Either a `storeCode` inserted via the API or the code of the store in Google My Business.
  --target-country: string # Required. The CLDR territory code for the item.
  --timestamp: string # Required. The inventory timestamp, in ISO 8601 format.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/pos/{targetMerchantId}/inventory"
    path_params: [{name: merchantId, var: merchant_id}, {name: targetMerchantId, var: target_merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dryRun, var: qp_dry_run}]
    body: {content_type: "application/json", kind: json, fields: [{name: contentLanguage, var: content_language}, {name: gtin, var: gtin}, {name: itemId, var: item_id}, {name: price, var: price}, {name: quantity, var: quantity}, {name: storeCode, var: store_code}, {name: targetCountry, var: target_country}, {name: timestamp, var: timestamp}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, target_merchant_id: $target_merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, qp_dry_run: $qp_dry_run, content_language: $content_language, gtin: $gtin, item_id: $item_id, price: $price, quantity: $quantity, store_code: $store_code, target_country: $target_country, timestamp: $timestamp
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any). (spec name: dryRun)
  --content-language: string # Required. The two-letter ISO 639-1 language code for the item.
  --gtin: string # Global Trade Item Number.
  --item-id: string # Required. A unique identifier for the item.
  --price: record # shape: {currency?: string, value?: string}
  --quantity: string # Required. The relative change of the available quantity. Negative for items returned. (format: int64)
  --sale-id: string # A unique ID to group items from the same sale event.
  --store-code: string # Required. The identifier of the merchant's store. Either a `storeCode` inserted via the API or the code of the store in Google My Business.
  --target-country: string # Required. The CLDR territory code for the item.
  --timestamp: string # Required. The inventory timestamp, in ISO 8601 format.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/pos/{targetMerchantId}/sale"
    path_params: [{name: merchantId, var: merchant_id}, {name: targetMerchantId, var: target_merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dryRun, var: qp_dry_run}]
    body: {content_type: "application/json", kind: json, fields: [{name: contentLanguage, var: content_language}, {name: gtin, var: gtin}, {name: itemId, var: item_id}, {name: price, var: price}, {name: quantity, var: quantity}, {name: saleId, var: sale_id}, {name: storeCode, var: store_code}, {name: targetCountry, var: target_country}, {name: timestamp, var: timestamp}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, target_merchant_id: $target_merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, qp_dry_run: $qp_dry_run, content_language: $content_language, gtin: $gtin, item_id: $item_id, price: $price, quantity: $quantity, sale_id: $sale_id, store_code: $store_code, target_country: $target_country, timestamp: $timestamp
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any). (spec name: dryRun)
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
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dryRun, var: qp_dry_run}]
    body: {content_type: "application/json", kind: json, fields: [{name: gcidCategory, var: gcid_category}, {name: kind, var: kind}, {name: phoneNumber, var: phone_number}, {name: placeId, var: place_id}, {name: storeAddress, var: store_address}, {name: storeCode, var: store_code}, {name: storeName, var: store_name}, {name: websiteUrl, var: website_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, target_merchant_id: $target_merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, qp_dry_run: $qp_dry_run, gcid_category: $gcid_category, kind: $kind, phone_number: $phone_number, place_id: $place_id, store_address: $store_address, store_code: $store_code, store_name: $store_name, website_url: $website_url
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any). (spec name: dryRun)
]: nothing -> any {
  http-request {
    method: delete
    path: "/{merchantId}/pos/{targetMerchantId}/store/{storeCode}"
    path_params: [{name: merchantId, var: merchant_id}, {name: targetMerchantId, var: target_merchant_id}, {name: storeCode, var: store_code}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dryRun, var: qp_dry_run}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, target_merchant_id: $target_merchant_id, store_code: $store_code, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, qp_dry_run: $qp_dry_run
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

# Lists the products in your Merchant Center account. The response might contain fewer items than specified by maxResults. Rely on nextPageToken to determine if there are more items to be requested.
#
# GET /{merchantId}/products
# Returns: record<kind: string, nextPageToken: string, resources: table<additionalImageLinks: list, additionalProductTypes: list, adult: bool, adwordsGrouping: string, adwordsLabels: list, adwordsRedirect: string, ageGroup: string, aspects: list, availability: string, availabilityDate: string, brand: string, canonicalLink: string, channel: string, color: string, condition: string, contentLanguage: string, costOfGoodsSold: record, customAttributes: list, customGroups: list, customLabel0: string, customLabel1: string, customLabel2: string, customLabel3: string, customLabel4: string, description: string, destinations: list, displayAdsId: string, displayAdsLink: string, displayAdsSimilarIds: list, displayAdsTitle: string, displayAdsValue: float, energyEfficiencyClass: string, expirationDate: string, gender: string, googleProductCategory: string, gtin: string, id: string, identifierExists: bool, imageLink: string, installment: record, isBundle: bool, itemGroupId: string, kind: string, link: string, loyaltyPoints: record, material: string, maxEnergyEfficiencyClass: string, maxHandlingTime: string, minEnergyEfficiencyClass: string, minHandlingTime: string, mobileLink: string, mpn: string, multipack: string, offerId: string, onlineOnly: bool, pattern: string, price: record, productType: string, promotionIds: list, salePrice: record, salePriceEffectiveDate: string, sellOnGoogleQuantity: string, shipping: list, shippingHeight: record, shippingLabel: string, shippingLength: record, shippingWeight: record, shippingWidth: record, sizeSystem: string, sizeType: string, sizes: list, source: string, targetCountry: string, taxes: list, title: string, unitPricingBaseMeasure: record, unitPricingMeasure: record, validatedDestinations: list, warnings: list>>
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
  --include-invalid-inserted-items: oneof<nothing, bool> # Flag to include the invalid inserted items in the result of the list request. By default the invalid items are not shown (the default value is false).
  --max-results: int # The maximum number of products to return in the response, used for paging.
  --page-token: string # The token returned by the previous request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/products"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: includeInvalidInsertedItems, var: include_invalid_inserted_items}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, include_invalid_inserted_items: $include_invalid_inserted_items, max_results: $max_results, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uploads a product to your Merchant Center account. If an item with the same channel, contentLanguage, offerId, and targetCountry already exists, this method updates that entry.
#
# POST /{merchantId}/products
# Returns: record<additionalImageLinks: list<string>, additionalProductTypes: list<string>, adult: bool, adwordsGrouping: string, adwordsLabels: list<string>, adwordsRedirect: string, ageGroup: string, aspects: table<aspectName: string, destinationName: string, intention: string>, availability: string, availabilityDate: string, brand: string, canonicalLink: string, channel: string, color: string, condition: string, contentLanguage: string, costOfGoodsSold: record<currency: string, value: string>, customAttributes: table<name: string, type: string, unit: string, value: string>, customGroups: table<attributes: list, name: string>, customLabel0: string, customLabel1: string, customLabel2: string, customLabel3: string, customLabel4: string, description: string, destinations: table<destinationName: string, intention: string>, displayAdsId: string, displayAdsLink: string, displayAdsSimilarIds: list<string>, displayAdsTitle: string, displayAdsValue: float, energyEfficiencyClass: string, expirationDate: string, gender: string, googleProductCategory: string, gtin: string, id: string, identifierExists: bool, imageLink: string, installment: record<amount: record<currency: string, value: string>, months: string>, isBundle: bool, itemGroupId: string, kind: string, link: string, loyaltyPoints: record<name: string, pointsValue: string, ratio: float>, material: string, maxEnergyEfficiencyClass: string, maxHandlingTime: string, minEnergyEfficiencyClass: string, minHandlingTime: string, mobileLink: string, mpn: string, multipack: string, offerId: string, onlineOnly: bool, pattern: string, price: record<currency: string, value: string>, productType: string, promotionIds: list<string>, salePrice: record<currency: string, value: string>, salePriceEffectiveDate: string, sellOnGoogleQuantity: string, shipping: table<country: string, locationGroupName: string, locationId: string, postalCode: string, price: record, region: string, service: string>, shippingHeight: record<unit: string, value: float>, shippingLabel: string, shippingLength: record<unit: string, value: float>, shippingWeight: record<unit: string, value: float>, shippingWidth: record<unit: string, value: float>, sizeSystem: string, sizeType: string, sizes: list<string>, source: string, targetCountry: string, taxes: table<country: string, locationId: string, postalCode: string, rate: float, region: string, taxShip: bool>, title: string, unitPricingBaseMeasure: record<unit: string, value: string>, unitPricingMeasure: record<unit: string, value: float>, validatedDestinations: list<string>, warnings: table<domain: string, message: string, reason: string>>
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any). (spec name: dryRun)
  --additional-image-links: list<string> # Additional URLs of images of the item.
  --additional-product-types: list<string> # Additional categories of the item (formatted as in products data specification).
  --adult: oneof<nothing, bool> # Should be set to true if the item is targeted towards adults.
  --adwords-grouping: string # Used to group items in an arbitrary way. Only for CPA%, discouraged otherwise.
  --adwords-labels: list<string> # Similar to adwords_grouping, but only works on CPC.
  --adwords-redirect: string # Allows advertisers to override the item URL when the product is shown within the context of Product Ads.
  --age-group: string # Target age group of the item. Acceptable values are: - "`adult`" - "`infant`" - "`kids`" - "`newborn`" - "`toddler`" - "`youngAdult`"
  --aspects: list # Deprecated. Do not use. — item shape: {aspectName?: string, destinationName?: string, intention?: string}
  --availability: string # Availability status of the item. Acceptable values are: - "`in stock`" - "`out of stock`" - "`preorder`"
  --availability-date: string # The day a pre-ordered product becomes available for delivery, in ISO 8601 format.
  --brand: string # Brand of the item.
  --canonical-link: string # URL for the canonical version of your item's landing page.
  --channel: string # Required. The item's channel (online or local). Acceptable values are: - "`local`" - "`online`"
  --color: string # Color of the item.
  --condition: string # Condition or state of the item. Acceptable values are: - "`new`" - "`refurbished`" - "`used`"
  --content-language: string # Required. The two-letter ISO 639-1 language code for the item.
  --cost-of-goods-sold: record # shape: {currency?: string, value?: string}
  --custom-attributes: list # A list of custom (merchant-provided) attributes. It can also be used for submitting any attribute of the feed specification in its generic form (e.g., `{ "name": "size type", "value": "regular" }`). This is useful for submitting attributes not explicitly exposed by the API, such as additional attributes used for Buy on Google (formerly known as Shopping Actions). — item shape: {name?: string, type?: string, unit?: string, value?: string}
  --custom-groups: list # A list of custom (merchant-provided) custom attribute groups. — item shape: {attributes?: list, name?: string}
  --custom-label0: string # Custom label 0 for custom grouping of items in a Shopping campaign.
  --custom-label1: string # Custom label 1 for custom grouping of items in a Shopping campaign.
  --custom-label2: string # Custom label 2 for custom grouping of items in a Shopping campaign.
  --custom-label3: string # Custom label 3 for custom grouping of items in a Shopping campaign.
  --custom-label4: string # Custom label 4 for custom grouping of items in a Shopping campaign.
  --description: string # Description of the item.
  --destinations: list # Specifies the intended destinations for the product. — item shape: {destinationName?: string, intention?: string}
  --display-ads-id: string # An identifier for an item for dynamic remarketing campaigns.
  --display-ads-link: string # URL directly to your item's landing page for dynamic remarketing campaigns.
  --display-ads-similar-ids: list<string> # Advertiser-specified recommendations.
  --display-ads-title: string # Title of an item for dynamic remarketing campaigns.
  --display-ads-value: float # Offer margin for dynamic remarketing campaigns. (format: double)
  --energy-efficiency-class: string # The energy efficiency class as defined in EU directive 2010/30/EU. Acceptable values are: - "`A`" - "`A+`" - "`A++`" - "`A+++`" - "`B`" - "`C`" - "`D`" - "`E`" - "`F`" - "`G`"
  --expiration-date: string # Date on which the item should expire, as specified upon insertion, in ISO 8601 format. The actual expiration date in Google Shopping is exposed in `productstatuses` as `googleExpirationDate` and might be earlier if `expirationDate` is too far in the future.
  --gender: string # Target gender of the item. Acceptable values are: - "`female`" - "`male`" - "`unisex`"
  --google-product-category: string # Google's category of the item (see [Google product taxonomy](https://support.google.com/merchants/answer/1705911)). When querying products, this field will contain the user provided value. There is currently no way to get back the auto assigned google product categories through the API.
  --gtin: string # Global Trade Item Number (GTIN) of the item.
  --id: string # The REST ID of the product. Content API methods that operate on products take this as their `productId` parameter. The REST ID for a product is of the form channel:contentLanguage: targetCountry: offerId.
  --identifier-exists: oneof<nothing, bool> # False when the item does not have unique product identifiers appropriate to its category, such as GTIN, MPN, and brand. Required according to the Unique Product Identifier Rules for all target countries except for Canada.
  --image-link: string # URL of an image of the item.
  --installment: record # shape: {amount?: record, months?: string}
  --is-bundle: oneof<nothing, bool> # Whether the item is a merchant-defined bundle. A bundle is a custom grouping of different products sold by a merchant for a single price.
  --item-group-id: string # Shared identifier for all variants of the same product.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "`content#product`"
  --link: string # URL directly linking to your item's page on your website.
  --loyalty-points: record # shape: {name?: string, pointsValue?: string, ratio?: float}
  --material: string # The material of which the item is made.
  --max-energy-efficiency-class: string # The energy efficiency class as defined in EU directive 2010/30/EU. Acceptable values are: - "`A`" - "`A+`" - "`A++`" - "`A+++`" - "`B`" - "`C`" - "`D`" - "`E`" - "`F`" - "`G`"
  --max-handling-time: string # Maximal product handling time (in business days). (format: int64)
  --min-energy-efficiency-class: string # The energy efficiency class as defined in EU directive 2010/30/EU. Acceptable values are: - "`A`" - "`A+`" - "`A++`" - "`A+++`" - "`B`" - "`C`" - "`D`" - "`E`" - "`F`" - "`G`"
  --min-handling-time: string # Minimal product handling time (in business days). (format: int64)
  --mobile-link: string # URL for the mobile-optimized version of your item's landing page.
  --mpn: string # Manufacturer Part Number (MPN) of the item.
  --multipack: string # The number of identical products in a merchant-defined multipack. (format: int64)
  --offer-id: string # Required. A unique identifier for the item. Leading and trailing whitespaces are stripped and multiple whitespaces are replaced by a single whitespace upon submission. Only valid unicode characters are accepted. See the products feed specification for details. *Note:* Content API methods that operate on products take the REST ID of the product, *not* this identifier.
  --online-only: oneof<nothing, bool> # Deprecated.
  --pattern: string # The item's pattern (e.g. polka dots).
  --price: record # shape: {currency?: string, value?: string}
  --product-type: string # Your category of the item (formatted as in products data specification).
  --promotion-ids: list<string> # The unique ID of a promotion.
  --sale-price: record # shape: {currency?: string, value?: string}
  --sale-price-effective-date: string # Date range during which the item is on sale (see products data specification ).
  --sell-on-google-quantity: string # The quantity of the product that is available for selling on Google. Supported only for online products. (format: int64)
  --shipping: list # Shipping rules. — item shape: {country?: string, locationGroupName?: string, locationId?: string, postalCode?: string, price?: record, region?: string, service?: string}
  --shipping-height: record # shape: {unit?: string, value?: float}
  --shipping-label: string # The shipping label of the product, used to group product in account-level shipping rules.
  --shipping-length: record # shape: {unit?: string, value?: float}
  --shipping-weight: record # shape: {unit?: string, value?: float}
  --shipping-width: record # shape: {unit?: string, value?: float}
  --size-system: string # System in which the size is specified. Recommended for apparel items. Acceptable values are: - "`AU`" - "`BR`" - "`CN`" - "`DE`" - "`EU`" - "`FR`" - "`IT`" - "`JP`" - "`MEX`" - "`UK`" - "`US`"
  --size-type: string # The cut of the item. Recommended for apparel items. Acceptable values are: - "`big and tall`" - "`maternity`" - "`oversize`" - "`petite`" - "`plus`" - "`regular`"
  --sizes: list<string> # Size of the item. Only one value is allowed. For variants with different sizes, insert a separate product for each size with the same `itemGroupId` value (see size definition).
  --source: string # The source of the offer, i.e., how the offer was created. Acceptable values are: - "`api`" - "`crawl`" - "`feed`"
  --target-country: string # Required. The CLDR territory code for the item.
  --taxes: list # Tax information. — item shape: {country?: string, locationId?: string, postalCode?: string, rate?: float, region?: string, taxShip?: bool}
  --title: string # Title of the item.
  --unit-pricing-base-measure: record # shape: {unit?: string, value?: string}
  --unit-pricing-measure: record # shape: {unit?: string, value?: float}
  --validated-destinations: list<string> # Deprecated. The read-only list of intended destinations which passed validation.
  --warnings: list # Read-only warnings. — item shape: {domain?: string, message?: string, reason?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{merchantId}/products"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dryRun, var: qp_dry_run}]
    body: {content_type: "application/json", kind: json, fields: [{name: additionalImageLinks, var: additional_image_links}, {name: additionalProductTypes, var: additional_product_types}, {name: adult, var: adult}, {name: adwordsGrouping, var: adwords_grouping}, {name: adwordsLabels, var: adwords_labels}, {name: adwordsRedirect, var: adwords_redirect}, {name: ageGroup, var: age_group}, {name: aspects, var: aspects}, {name: availability, var: availability}, {name: availabilityDate, var: availability_date}, {name: brand, var: brand}, {name: canonicalLink, var: canonical_link}, {name: channel, var: channel}, {name: color, var: color}, {name: condition, var: condition}, {name: contentLanguage, var: content_language}, {name: costOfGoodsSold, var: cost_of_goods_sold}, {name: customAttributes, var: custom_attributes}, {name: customGroups, var: custom_groups}, {name: customLabel0, var: custom_label0}, {name: customLabel1, var: custom_label1}, {name: customLabel2, var: custom_label2}, {name: customLabel3, var: custom_label3}, {name: customLabel4, var: custom_label4}, {name: description, var: description}, {name: destinations, var: destinations}, {name: displayAdsId, var: display_ads_id}, {name: displayAdsLink, var: display_ads_link}, {name: displayAdsSimilarIds, var: display_ads_similar_ids}, {name: displayAdsTitle, var: display_ads_title}, {name: displayAdsValue, var: display_ads_value}, {name: energyEfficiencyClass, var: energy_efficiency_class}, {name: expirationDate, var: expiration_date}, {name: gender, var: gender}, {name: googleProductCategory, var: google_product_category}, {name: gtin, var: gtin}, {name: id, var: id}, {name: identifierExists, var: identifier_exists}, {name: imageLink, var: image_link}, {name: installment, var: installment}, {name: isBundle, var: is_bundle}, {name: itemGroupId, var: item_group_id}, {name: kind, var: kind}, {name: link, var: link}, {name: loyaltyPoints, var: loyalty_points}, {name: material, var: material}, {name: maxEnergyEfficiencyClass, var: max_energy_efficiency_class}, {name: maxHandlingTime, var: max_handling_time}, {name: minEnergyEfficiencyClass, var: min_energy_efficiency_class}, {name: minHandlingTime, var: min_handling_time}, {name: mobileLink, var: mobile_link}, {name: mpn, var: mpn}, {name: multipack, var: multipack}, {name: offerId, var: offer_id}, {name: onlineOnly, var: online_only}, {name: pattern, var: pattern}, {name: price, var: price}, {name: productType, var: product_type}, {name: promotionIds, var: promotion_ids}, {name: salePrice, var: sale_price}, {name: salePriceEffectiveDate, var: sale_price_effective_date}, {name: sellOnGoogleQuantity, var: sell_on_google_quantity}, {name: shipping, var: shipping}, {name: shippingHeight, var: shipping_height}, {name: shippingLabel, var: shipping_label}, {name: shippingLength, var: shipping_length}, {name: shippingWeight, var: shipping_weight}, {name: shippingWidth, var: shipping_width}, {name: sizeSystem, var: size_system}, {name: sizeType, var: size_type}, {name: sizes, var: sizes}, {name: source, var: source}, {name: targetCountry, var: target_country}, {name: taxes, var: taxes}, {name: title, var: title}, {name: unitPricingBaseMeasure, var: unit_pricing_base_measure}, {name: unitPricingMeasure, var: unit_pricing_measure}, {name: validatedDestinations, var: validated_destinations}, {name: warnings, var: warnings}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, qp_dry_run: $qp_dry_run, additional_image_links: $additional_image_links, additional_product_types: $additional_product_types, adult: $adult, adwords_grouping: $adwords_grouping, adwords_labels: $adwords_labels, adwords_redirect: $adwords_redirect, age_group: $age_group, aspects: $aspects, availability: $availability, availability_date: $availability_date, brand: $brand, canonical_link: $canonical_link, channel: $channel, color: $color, condition: $condition, content_language: $content_language, cost_of_goods_sold: $cost_of_goods_sold, custom_attributes: $custom_attributes, custom_groups: $custom_groups, custom_label0: $custom_label0, custom_label1: $custom_label1, custom_label2: $custom_label2, custom_label3: $custom_label3, custom_label4: $custom_label4, description: $description, destinations: $destinations, display_ads_id: $display_ads_id, display_ads_link: $display_ads_link, display_ads_similar_ids: $display_ads_similar_ids, display_ads_title: $display_ads_title, display_ads_value: $display_ads_value, energy_efficiency_class: $energy_efficiency_class, expiration_date: $expiration_date, gender: $gender, google_product_category: $google_product_category, gtin: $gtin, id: $id, identifier_exists: $identifier_exists, image_link: $image_link, installment: $installment, is_bundle: $is_bundle, item_group_id: $item_group_id, kind: $kind, link: $link, loyalty_points: $loyalty_points, material: $material, max_energy_efficiency_class: $max_energy_efficiency_class, max_handling_time: $max_handling_time, min_energy_efficiency_class: $min_energy_efficiency_class, min_handling_time: $min_handling_time, mobile_link: $mobile_link, mpn: $mpn, multipack: $multipack, offer_id: $offer_id, online_only: $online_only, pattern: $pattern, price: $price, product_type: $product_type, promotion_ids: $promotion_ids, sale_price: $sale_price, sale_price_effective_date: $sale_price_effective_date, sell_on_google_quantity: $sell_on_google_quantity, shipping: $shipping, shipping_height: $shipping_height, shipping_label: $shipping_label, shipping_length: $shipping_length, shipping_weight: $shipping_weight, shipping_width: $shipping_width, size_system: $size_system, size_type: $size_type, sizes: $sizes, source: $source, target_country: $target_country, taxes: $taxes, title: $title, unit_pricing_base_measure: $unit_pricing_base_measure, unit_pricing_measure: $unit_pricing_measure, validated_destinations: $validated_destinations, warnings: $warnings
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any). (spec name: dryRun)
]: nothing -> any {
  http-request {
    method: delete
    path: "/{merchantId}/products/{productId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: productId, var: product_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dryRun, var: qp_dry_run}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, product_id: $product_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, qp_dry_run: $qp_dry_run
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a product from your Merchant Center account.
#
# GET /{merchantId}/products/{productId}
# Returns: record<additionalImageLinks: list<string>, additionalProductTypes: list<string>, adult: bool, adwordsGrouping: string, adwordsLabels: list<string>, adwordsRedirect: string, ageGroup: string, aspects: table<aspectName: string, destinationName: string, intention: string>, availability: string, availabilityDate: string, brand: string, canonicalLink: string, channel: string, color: string, condition: string, contentLanguage: string, costOfGoodsSold: record<currency: string, value: string>, customAttributes: table<name: string, type: string, unit: string, value: string>, customGroups: table<attributes: list, name: string>, customLabel0: string, customLabel1: string, customLabel2: string, customLabel3: string, customLabel4: string, description: string, destinations: table<destinationName: string, intention: string>, displayAdsId: string, displayAdsLink: string, displayAdsSimilarIds: list<string>, displayAdsTitle: string, displayAdsValue: float, energyEfficiencyClass: string, expirationDate: string, gender: string, googleProductCategory: string, gtin: string, id: string, identifierExists: bool, imageLink: string, installment: record<amount: record<currency: string, value: string>, months: string>, isBundle: bool, itemGroupId: string, kind: string, link: string, loyaltyPoints: record<name: string, pointsValue: string, ratio: float>, material: string, maxEnergyEfficiencyClass: string, maxHandlingTime: string, minEnergyEfficiencyClass: string, minHandlingTime: string, mobileLink: string, mpn: string, multipack: string, offerId: string, onlineOnly: bool, pattern: string, price: record<currency: string, value: string>, productType: string, promotionIds: list<string>, salePrice: record<currency: string, value: string>, salePriceEffectiveDate: string, sellOnGoogleQuantity: string, shipping: table<country: string, locationGroupName: string, locationId: string, postalCode: string, price: record, region: string, service: string>, shippingHeight: record<unit: string, value: float>, shippingLabel: string, shippingLength: record<unit: string, value: float>, shippingWeight: record<unit: string, value: float>, shippingWidth: record<unit: string, value: float>, sizeSystem: string, sizeType: string, sizes: list<string>, source: string, targetCountry: string, taxes: table<country: string, locationId: string, postalCode: string, rate: float, region: string, taxShip: bool>, title: string, unitPricingBaseMeasure: record<unit: string, value: string>, unitPricingMeasure: record<unit: string, value: float>, validatedDestinations: list<string>, warnings: table<domain: string, message: string, reason: string>>
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

# Lists the statuses of the products in your Merchant Center account.
#
# GET /{merchantId}/productstatuses
# Returns: record<kind: string, nextPageToken: string, resources: table<creationDate: string, dataQualityIssues: list, destinationStatuses: list, googleExpirationDate: string, itemLevelIssues: list, kind: string, lastUpdateDate: string, link: string, product: record, productId: string, title: string>>
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
  --include-attributes: oneof<nothing, bool> # Flag to include full product data in the results of the list request. The default value is false.
  --include-invalid-inserted-items: oneof<nothing, bool> # Flag to include the invalid inserted items in the result of the list request. By default the invalid items are not shown (the default value is false).
  --max-results: int # The maximum number of product statuses to return in the response, used for paging.
  --page-token: string # The token returned by the previous request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/productstatuses"
    path_params: [{name: merchantId, var: merchant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: destinations, var: destinations, style: multi}, {name: includeAttributes, var: include_attributes}, {name: includeInvalidInsertedItems, var: include_invalid_inserted_items}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, destinations: $destinations, include_attributes: $include_attributes, include_invalid_inserted_items: $include_invalid_inserted_items, max_results: $max_results, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the status of a product from your Merchant Center account.
#
# GET /{merchantId}/productstatuses/{productId}
# Returns: record<creationDate: string, dataQualityIssues: table<destination: string, detail: string, fetchStatus: string, id: string, location: string, severity: string, timestamp: string, valueOnLandingPage: string, valueProvided: string>, destinationStatuses: table<approvalPending: bool, approvalStatus: string, destination: string, intention: string>, googleExpirationDate: string, itemLevelIssues: table<attributeName: string, code: string, description: string, destination: string, detail: string, documentation: string, resolution: string, servability: string>, kind: string, lastUpdateDate: string, link: string, product: record<additionalImageLinks: list<string>, additionalProductTypes: list<string>, adult: bool, adwordsGrouping: string, adwordsLabels: list<string>, adwordsRedirect: string, ageGroup: string, aspects: list<record>, availability: string, availabilityDate: string, brand: string, canonicalLink: string, channel: string, color: string, condition: string, contentLanguage: string, costOfGoodsSold: record<currency: string, value: string>, customAttributes: list<record>, customGroups: list<record>, customLabel0: string, customLabel1: string, customLabel2: string, customLabel3: string, customLabel4: string, description: string, destinations: list<record>, displayAdsId: string, displayAdsLink: string, displayAdsSimilarIds: list<string>, displayAdsTitle: string, displayAdsValue: float, energyEfficiencyClass: string, expirationDate: string, gender: string, googleProductCategory: string, gtin: string, id: string, identifierExists: bool, imageLink: string, installment: record<amount: record, months: string>, isBundle: bool, itemGroupId: string, kind: string, link: string, loyaltyPoints: record<name: string, pointsValue: string, ratio: float>, material: string, maxEnergyEfficiencyClass: string, maxHandlingTime: string, minEnergyEfficiencyClass: string, minHandlingTime: string, mobileLink: string, mpn: string, multipack: string, offerId: string, onlineOnly: bool, pattern: string, price: record<currency: string, value: string>, productType: string, promotionIds: list<string>, salePrice: record<currency: string, value: string>, salePriceEffectiveDate: string, sellOnGoogleQuantity: string, shipping: list<record>, shippingHeight: record<unit: string, value: float>, shippingLabel: string, shippingLength: record<unit: string, value: float>, shippingWeight: record<unit: string, value: float>, shippingWidth: record<unit: string, value: float>, sizeSystem: string, sizeType: string, sizes: list<string>, source: string, targetCountry: string, taxes: list<record>, title: string, unitPricingBaseMeasure: record<unit: string, value: string>, unitPricingMeasure: record<unit: string, value: float>, validatedDestinations: list<string>, warnings: list<record>>, productId: string, title: string>
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
  --include-attributes: oneof<nothing, bool> # Flag to include full product data in the result of this get request. The default value is false.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{merchantId}/productstatuses/{productId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: productId, var: product_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: destinations, var: destinations, style: multi}, {name: includeAttributes, var: include_attributes}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, product_id: $product_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, destinations: $destinations, include_attributes: $include_attributes
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
  --qp-dry-run: oneof<nothing, bool> # Flag to simulate a request like in a live environment. If set to true, dry-run mode checks the validity of the request and returns errors (if any). (spec name: dryRun)
  --body-account-id: string # The ID of the account to which these account shipping settings belong. Ignored upon update, always present in get request responses. (format: uint64) (spec name: accountId)
  --postal-code-groups: list # A list of postal code groups that can be referred to in `services`. Optional. — item shape: {country?: string, name?: string, postalCodeRanges?: list}
  --services: list # The target account's list of services. Optional. — item shape: {active?: bool, currency?: string, deliveryCountry?: string, deliveryTime?: record, eligibility?: string, minimumOrderValue?: record, minimumOrderValueTable?: record, name?: string, pickupService?: record, rateGroups?: list, shipmentType?: string}
  --warehouses: list # Optional. A list of warehouses which can be referred to in `services`. — item shape: {businessDayConfig?: record, cutoffTime?: record, handlingDays?: string, name?: string, shippingAddress?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{merchantId}/shippingsettings/{accountId}"
    path_params: [{name: merchantId, var: merchant_id}, {name: accountId, var: account_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dryRun, var: qp_dry_run}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: postalCodeGroups, var: postal_code_groups}, {name: services, var: services}, {name: warehouses, var: warehouses}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    merchant_id: $merchant_id, account_id: $account_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, qp_dry_run: $qp_dry_run, body_account_id: $body_account_id, postal_code_groups: $postal_code_groups, services: $services, warehouses: $warehouses
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
  --country: string # The CLDR territory code of the country of the test order to create. Affects the currency and addresses of orders created via `template_name`, or the addresses of orders created via `test_order`. Acceptable values are: - "`US`" - "`FR`" Defaults to `US`.
  --template-name: string # The test order template to use. Specify as an alternative to `testOrder` as a shortcut for retrieving a template and then creating an order using that template. Acceptable values are: - "`template1`" - "`template1a`" - "`template1b`" - "`template2`" - "`template3`"
  --test-order: record # shape: {customer?: record, enableOrderinvoices?: bool, kind?: string, lineItems?: list, notificationMode?: string, paymentMethod?: record, predefinedDeliveryAddress?: string, predefinedPickupDetails?: string, promotions?: list, shippingCost?: record, shippingCostTax?: record, shippingOption?: string}
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
# Returns: record<kind: string, template: record<customer: record<email: string, explicitMarketingPreference: bool, fullName: string, marketingRightsInfo: record>, enableOrderinvoices: bool, kind: string, lineItems: list<record>, notificationMode: string, paymentMethod: record<expirationMonth: int, expirationYear: int, lastFourDigits: string, predefinedBillingAddress: string, type: string>, predefinedDeliveryAddress: string, predefinedPickupDetails: string, promotions: list<record>, shippingCost: record<currency: string, value: string>, shippingCostTax: record<currency: string, value: string>, shippingOption: string>>
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
  --country: string # The country of the template to retrieve. Defaults to `US`.
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
