# Auto-generated client for Postmark API v1.0.0
# Source: https://api.apis.guru/v2/specs/postmarkapp.com/server/1.0.0/swagger.json
# Auth: --token flag or $env.POSTMARK_API_TOKEN

const CLIENT = {
  base_url: "https://api.postmarkapp.com"
  token_env_var: "POSTMARK_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: []
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

def base-url-completer [] { ["https://api.postmarkapp.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["AddressChange" "AutoResponder" "BadEmailAddress" "Blocked" "DMARCPolicy" "DnsError" "HardBounce" "InboundError" "MailFrontier Matador." "ManuallyDeactivated" "OpenRelayTest" "SMTPApiError" "SoftBounce" "SpamComplaint" "SpamNotification" "Subscribe" "TemplateRenderingFailed" "Transient" "Unconfirmed" "Unknown" "Unsubscribe" "VirusNotification"] }
def track-links-completer [] { ["HtmlAndText" "HtmlOnly" "None" "TextOnly"] }
def status-completer [] { ["blocked" "failed" "processed" "queued" "scheduled"] }
def status-completer-1 [] { ["queued" "sent"] }
def color-completer [] { ["blue" "green" "grey" "purple" "red" "turqoise" "yellow"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-bounces: "record<Bounces: table<BouncedAt: string, CanActivate: bool, Content: string, Description: string, Details: string, DumpAvailable: bool, Email: string, ID: string, Inactive: bool, MessageID: string, Name: string, Subject: string, Tag: string, Type: string, TypeCode: int>, TotalCount: int>"
    get-single-bounce: "record<BouncedAt: string, CanActivate: bool, Content: string, Description: string, Details: string, DumpAvailable: bool, Email: string, ID: string, Inactive: bool, MessageID: string, Name: string, Subject: string, Tag: string, Type: string, TypeCode: int>"
    activate-bounce: "record<Bounce: record<BouncedAt: string, CanActivate: bool, Content: string, Description: string, Details: string, DumpAvailable: bool, Email: string, ID: string, Inactive: bool, MessageID: string, Name: string, Subject: string, Tag: string, Type: string, TypeCode: int>, Message: string>"
    get-bounces-bounceid-dump: "record<Body: string>"
    get-delivery-stats: "record<Bounces: table<Count: int, Name: string, Type: string>, InactiveMails: int>"
    send-email: "record<ErrorCode: int, Message: string, MessageID: string, SubmittedAt: string, To: string>"
    send-email-batch: "table<ErrorCode: int, Message: string, MessageID: string, SubmittedAt: string, To: string>"
    send-email-batch-with-templates: "table<ErrorCode: int, Message: string, MessageID: string, SubmittedAt: string, To: string>"
    send-email-with-template: "record<ErrorCode: int, Message: string, MessageID: string, SubmittedAt: string, To: string>"
    search-inbound-messages: "record<InboundMessages: table<Attachments: list, Cc: string, CcFull: list, Date: string, From: string, FromFull: record, FromName: string, MailboxHash: string, MessageID: string, OriginalRecipient: string, ReplyTo: string, Status: string, Subject: string, Tag: string, To: string, ToFull: list>, TotalCount: int>"
    bypass-rules-for-inbound-message: "record<ErrorCode: int, Message: string>"
    get-inbound-message-details: "record<Attachments: table<Content: string, ContentID: string, ContentType: string, Name: string>, BlockedReason: string, Cc: string, CcFull: table<Email: string, Name: string>, Date: string, From: string, FromFull: record<Email: string, Name: string>, FromName: string, Headers: table<Name: string, Value: string>, HtmlBody: string, MailboxHash: string, MessageID: string, OriginalRecipient: string, ReplyTo: string, Status: string, Subject: string, Tag: string, TextBody: string, To: string, ToFull: table<Email: string, Name: string>>"
    retry-inbound-message-processing: "record<ErrorCode: int, Message: string>"
    search-outbound-messages: "record<Messages: table<Attachments: list, Bcc: list, Cc: list, From: string, MessageID: string, ReceivedAt: string, Recipients: list, Status: string, Subject: string, Tag: string, To: list, TrackLinks: string, TrackOpens: bool>, TotalCount: int>"
    search-clicks-for-outbound-messages: "record<Clicks: table<ClickLocation: string, Client: record, Geo: record, MessageID: string, OS: record, OriginalLink: string, Platform: string, ReceivedAt: string, Recipient: string, Tag: string, UserAgent: string>, TotalCount: int>"
    get-clicks-for-single-outbound-message: "record<Clicks: table<ClickLocation: string, Client: record, Geo: record, MessageID: string, OS: record, OriginalLink: string, Platform: string, ReceivedAt: string, Recipient: string, Tag: string, UserAgent: string>, TotalCount: int>"
    search-opens-for-outbound-messages: "record<Opens: table<Client: record, FirstOpen: bool, Geo: record, MessageID: string, OS: record, Platform: string, ReceivedAt: string, Recipient: string, Tag: string, UserAgent: string>, TotalCount: int>"
    get-opens-for-single-outbound-message: "record<Opens: table<Client: record, FirstOpen: bool, Geo: record, MessageID: string, OS: record, Platform: string, ReceivedAt: string, Recipient: string, Tag: string, UserAgent: string>, TotalCount: int>"
    get-outbound-message-details: "record<Attachments: table<Content: string, ContentID: string, ContentType: string, Name: string>, Bcc: table<Email: string, Name: string>, Body: string, Cc: table<Email: string, Name: string>, From: string, HtmlBody: string, MessageEvents: table<Details: record, ReceivedAt: string, Recipient: string, Type: string>, MessageID: string, ReceivedAt: string, Recipients: list<string>, Status: string, Subject: string, Tag: string, TextBody: string, To: table<Email: string, Name: string>, TrackLinks: string, TrackOpens: bool>"
    get-outbound-message-dump: "record<Body: string>"
    get-current-server-configuration: "record<ApiTokens: list<string>, BounceHookUrl: string, ClickHookUrl: string, Color: string, DeliveryHookUrl: string, ID: int, InboundAddress: string, InboundDomain: string, InboundHash: string, InboundHookUrl: string, InboundSpamThreshold: int, Name: string, OpenHookUrl: string, PostFirstOpenOnly: bool, RawEmailEnabled: bool, ServerLink: string, SmtpApiActivated: bool, TrackLinks: string, TrackOpens: bool>"
    edit-current-server-configuration: "record<ApiTokens: list<string>, BounceHookUrl: string, ClickHookUrl: string, Color: string, DeliveryHookUrl: string, ID: int, InboundAddress: string, InboundDomain: string, InboundHash: string, InboundHookUrl: string, InboundSpamThreshold: int, Name: string, OpenHookUrl: string, PostFirstOpenOnly: bool, RawEmailEnabled: bool, ServerLink: string, SmtpApiActivated: bool, TrackLinks: string, TrackOpens: bool>"
    get-outbound-overview-statistics: "record<BounceRate: int, Bounced: int, Opens: int, SMTPAPIErrors: int, Sent: int, SpamComplaints: int, SpamComplaintsRate: int, TotalClicks: int, TotalTrackedLinksSent: int, Tracked: int, UniqueLinksClicked: int, UniqueOpens: int, WithClientRecorded: int, WithLinkTracking: int, WithOpenTracking: int, WithPlatformRecorded: int>"
    get-bounce-counts: "record<Days: table<Date: string, HardBounce: int, SMTPApiError: int, SoftBounce: int, Transient: int>, HardBounce: int, SMTPApiError: int, SoftBounce: int, Transient: int>"
    get-outbound-click-counts-by-browser-family: "record"
    get-outbound-open-counts: "record<Days: table<Date: string, Opens: int, Unique: int>, Opens: int, Unique: int>"
    get-outbound-open-counts-by-email-client: "record<Days: list<any>, Desktop: int, Mobile: int, Unknown: int, WebMail: int>"
    get-outbound-open-counts-by-platform: "record<Days: table<Date: string, Desktop: int, Mobile: int, Unknown: int, WebMail: int>, Desktop: int, Mobile: int, Unknown: int, WebMail: int>"
    get-sent-counts: "record<Days: table<Date: string, Sent: int>, Sent: int>"
    get-spam-complaints: "record<Days: table<Date: string, SpamComplaint: int>, SpamComplaint: int>"
    get-tracked-email-counts: "record<Days: table<Date: string, Tracked: int>, Tracked: int>"
    list-templates: "record<\"Templates API\": table<Active: bool, Alias: string, Name: string, TemplateId: float>, TotalCount: float>"
    post-templates: "record<Active: bool, Alias: string, Name: string, TemplateId: float>"
    test-template-content: "record<AllContentIsValid: bool, HtmlBody: record<ContentIsValid: bool, RenderedContent: string, ValidationErrors: list<record>>, Subject: record<ContentIsValid: bool, RenderedContent: string, ValidationErrors: list<record>>, SuggestedTemplateModel: record, TextBody: record<ContentIsValid: bool, RenderedContent: string, ValidationErrors: list<record>>>"
    delete-template: "record<Active: bool, Alias: string, AssociatedServerId: int, HtmlBody: string, Name: string, Subject: string, TemplateID: int, TextBody: string>"
    get-single-template: "record<Active: bool, Alias: string, AssociatedServerId: int, HtmlBody: string, Name: string, Subject: string, TemplateID: int, TextBody: string>"
    update-template: "record<Active: bool, Alias: string, Name: string, TemplateId: float>"
    list-inbound-rules: "record<InboundRules: table<ID: int, Rule: string>, TotalCount: int>"
    create-inbound-rule: "record<ID: int, Rule: string>"
    delete-inbound-rule: "record<ErrorCode: int, Message: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-bounces" "get-single-bounce" "activate-bounce" "get-bounces-bounceid-dump" "get-delivery-stats" "send-email" "send-email-batch" "send-email-batch-with-templates" "send-email-with-template" "search-inbound-messages" "bypass-rules-for-inbound-message" "get-inbound-message-details" "retry-inbound-message-processing" "search-outbound-messages" "search-clicks-for-outbound-messages" "get-clicks-for-single-outbound-message" "search-opens-for-outbound-messages" "get-opens-for-single-outbound-message" "get-outbound-message-details" "get-outbound-message-dump" "get-current-server-configuration" "edit-current-server-configuration" "get-outbound-overview-statistics" "get-bounce-counts" "get-outbound-click-counts" "get-outbound-click-counts-by-browser-family" "get-outbound-click-counts-by-location" "get-outbound-click-counts-by-platform" "get-outbound-open-counts" "get-outbound-open-counts-by-email-client" "get-outbound-open-counts-by-platform" "get-sent-counts" "get-spam-complaints" "get-tracked-email-counts" "list-templates" "post-templates" "test-template-content" "delete-template" "get-single-template" "update-template" "list-inbound-rules" "create-inbound-rule" "delete-inbound-rule" "commands"] | sort) } | get name | first)
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

# Get bounces
#
# GET /bounces
# Returns: record<Bounces: table<BouncedAt: string, CanActivate: bool, Content: string, Description: string, Details: string, DumpAvailable: bool, Email: string, ID: string, Inactive: bool, MessageID: string, Name: string, Subject: string, Tag: string, Type: string, TypeCode: int>, TotalCount: int>
# operationId: getBounces
export def "get-bounces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Number of bounces to return per request. Max 500. (required)
  --offset: int # Number of bounces to skip. (required)
  --type: string@type-completer # Filter by type of bounce
  --inactive: oneof<nothing, bool> # Filter by emails that were deactivated by Postmark due to the bounce. Set to true or false. If this isn't specified it will return both active and inactive.
  --email-filter: string # Filter by email address (format: email)
  --message-id: string # Filter by messageID
  --tag: string # Filter by tag
  --todate: string # Filter messages up to the date specified. e.g. `2014-02-01` (format: date)
  --fromdate: string # Filter messages starting from the date specified. e.g. `2014-02-01` (format: date)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bounces"
    query: [{name: count, var: count, required: true}, {name: offset, var: offset, required: true}, {name: type, var: type}, {name: inactive, var: inactive}, {name: emailFilter, var: email_filter}, {name: messageID, var: message_id}, {name: tag, var: tag}, {name: todate, var: todate}, {name: fromdate, var: fromdate}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    count: $count, offset: $offset, type: $type, inactive: $inactive, email_filter: $email_filter, message_id: $message_id, tag: $tag, todate: $todate, fromdate: $fromdate, x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single bounce
#
# GET /bounces/{bounceid}
# Returns: record<BouncedAt: string, CanActivate: bool, Content: string, Description: string, Details: string, DumpAvailable: bool, Email: string, ID: string, Inactive: bool, MessageID: string, Name: string, Subject: string, Tag: string, Type: string, TypeCode: int>
# operationId: getSingleBounce
export def "get-single-bounce" [
  bounceid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bounces/{bounceid}"
    path_params: [{name: bounceid, var: bounceid}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bounceid: $bounceid, x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Activate a bounce
#
# PUT /bounces/{bounceid}/activate
# Returns: record<Bounce: record<BouncedAt: string, CanActivate: bool, Content: string, Description: string, Details: string, DumpAvailable: bool, Email: string, ID: string, Inactive: bool, MessageID: string, Name: string, Subject: string, Tag: string, Type: string, TypeCode: int>, Message: string>
# operationId: activateBounce
export def "activate-bounce" [
  bounceid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/bounces/{bounceid}/activate"
    path_params: [{name: bounceid, var: bounceid}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bounceid: $bounceid, x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get bounce dump
#
# GET /bounces/{bounceid}/dump
# Returns: record<Body: string>
export def "get-bounces-bounceid-dump" [
  bounceid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bounces/{bounceid}/dump"
    path_params: [{name: bounceid, var: bounceid}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bounceid: $bounceid, x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get delivery stats
#
# GET /deliverystats
# Returns: record<Bounces: table<Count: int, Name: string, Type: string>, InactiveMails: int>
# operationId: getDeliveryStats
export def "get-delivery-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/deliverystats"
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send a single email
#
# POST /email
# Returns: record<ErrorCode: int, Message: string, MessageID: string, SubmittedAt: string, To: string>
# operationId: sendEmail
export def "send-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
  --attachments: list # item shape: {Content?: string, ContentID?: string, ContentType?: string, Name?: string}
  --bcc: string # Bcc recipient email address. Multiple addresses are comma seperated. Max 50.
  --cc: string # Recipient email address. Multiple addresses are comma seperated. Max 50.
  --from: string # The sender email address. Must have a registered and confirmed Sender Signature.
  --headers: list # item shape: {Name?: string, Value?: string}
  --html-body: string # If no TextBody specified HTML email message
  --reply-to: string # Reply To override email address. Defaults to the Reply To set in the sender signature.
  --subject: string # Email Subject
  --tag: string # Email tag that allows you to categorize outgoing emails and get detailed statistics.
  --text-body: string # If no HtmlBody specified Plain text email message
  --to: string # Recipient email address. Multiple addresses are comma seperated. Max 50.
  --track-links: string@track-links-completer # Replace links in content to enable "click tracking" stats. Default is 'null', which uses the server's LinkTracking setting'.
  --track-opens: oneof<nothing, bool> # Activate open tracking for this email.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/email"
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Attachments, var: attachments}, {name: Bcc, var: bcc}, {name: Cc, var: cc}, {name: From, var: from}, {name: Headers, var: headers}, {name: HtmlBody, var: html_body}, {name: ReplyTo, var: reply_to}, {name: Subject, var: subject}, {name: Tag, var: tag}, {name: TextBody, var: text_body}, {name: To, var: to}, {name: TrackLinks, var: track_links}, {name: TrackOpens, var: track_opens}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_postmark_server_token: $x_postmark_server_token, attachments: $attachments, bcc: $bcc, cc: $cc, from: $from, headers: $headers, html_body: $html_body, reply_to: $reply_to, subject: $subject, tag: $tag, text_body: $text_body, to: $to, track_links: $track_links, track_opens: $track_opens
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send a batch of emails
#
# POST /email/batch
# Returns: table<ErrorCode: int, Message: string, MessageID: string, SubmittedAt: string, To: string>
# operationId: sendEmailBatch
export def "send-email-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/email/batch"
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_postmark_server_token: $x_postmark_server_token, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send a batch of email using templates.
#
# POST /email/batchWithTemplates
# Returns: table<ErrorCode: int, Message: string, MessageID: string, SubmittedAt: string, To: string>
# operationId: sendEmailBatchWithTemplates
export def "send-email-batch-with-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
  --messages: list # item shape: {Attachments?: list, Bcc?: string, Cc?: string, From: string, Headers?: list, InlineCss?: bool, ReplyTo?: string, Tag?: string, TemplateAlias: string, TemplateId: int, TemplateModel: record, To: string, TrackLinks?: "None"|"HtmlAndText"|"HtmlOnly"|"TextOnly", TrackOpens?: bool}
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/email/batchWithTemplates"
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Messages, var: messages}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_postmark_server_token: $x_postmark_server_token, messages: $messages
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send an email using a Template
#
# POST /email/withTemplate
# Returns: record<ErrorCode: int, Message: string, MessageID: string, SubmittedAt: string, To: string>
# operationId: sendEmailWithTemplate
export def "send-email-with-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
  --attachments: list # item shape: {Content?: string, ContentID?: string, ContentType?: string, Name?: string}
  --bcc: string # format: email
  --cc: string # format: email
  from: string # format: email
  --headers: list # item shape: {Name?: string, Value?: string}
  --inline-css: oneof<nothing, bool> # default: true
  --reply-to: string
  --tag: string
  template_alias: string # Required if 'TemplateId' is not specified.
  template_id: int # Required if 'TemplateAlias' is not specified.
  template_model: record
  to: string # format: email
  --track-links: string@track-links-completer # Replace links in content to enable "click tracking" stats. Default is 'null', which uses the server's LinkTracking setting'.
  --track-opens: oneof<nothing, bool> # Activate open tracking for this email.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/email/withTemplate"
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Attachments, var: attachments}, {name: Bcc, var: bcc}, {name: Cc, var: cc}, {name: From, var: from}, {name: Headers, var: headers}, {name: InlineCss, var: inline_css}, {name: ReplyTo, var: reply_to}, {name: Tag, var: tag}, {name: TemplateAlias, var: template_alias}, {name: TemplateId, var: template_id}, {name: TemplateModel, var: template_model}, {name: To, var: to}, {name: TrackLinks, var: track_links}, {name: TrackOpens, var: track_opens}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_postmark_server_token: $x_postmark_server_token, attachments: $attachments, bcc: $bcc, cc: $cc, from: $from, headers: $headers, inline_css: $inline_css, reply_to: $reply_to, tag: $tag, template_alias: $template_alias, template_id: $template_id, template_model: $template_model, to: $to, track_links: $track_links, track_opens: $track_opens
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inbound message search
#
# GET /messages/inbound
# Returns: record<InboundMessages: table<Attachments: list, Cc: string, CcFull: list, Date: string, From: string, FromFull: record, FromName: string, MailboxHash: string, MessageID: string, OriginalRecipient: string, ReplyTo: string, Status: string, Subject: string, Tag: string, To: string, ToFull: list>, TotalCount: int>
# operationId: searchInboundMessages
export def "search-inbound-messages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Number of messages to return per request. Max 500. (required)
  --offset: int # Number of messages to skip (required)
  --recipient: string # Filter by the user who was receiving the email (format: email)
  --fromemail: string # Filter by the sender email address (format: email)
  --subject: string # Filter by email subject
  --mailboxhash: string # Filter by mailboxhash
  --tag: string # Filter by tag
  --status: string@status-completer # Filter by status (`blocked`, `processed`, `queued`, `failed`, `scheduled`)
  --todate: string # Filter messages up to the date specified. e.g. `2014-02-01` (format: date)
  --fromdate: string # Filter messages starting from the date specified. e.g. `2014-02-01` (format: date)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/messages/inbound"
    query: [{name: count, var: count, required: true}, {name: offset, var: offset, required: true}, {name: recipient, var: recipient}, {name: fromemail, var: fromemail}, {name: subject, var: subject}, {name: mailboxhash, var: mailboxhash}, {name: tag, var: tag}, {name: status, var: status}, {name: todate, var: todate}, {name: fromdate, var: fromdate}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    count: $count, offset: $offset, recipient: $recipient, fromemail: $fromemail, subject: $subject, mailboxhash: $mailboxhash, tag: $tag, status: $status, todate: $todate, fromdate: $fromdate, x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bypass rules for a blocked inbound message
#
# PUT /messages/inbound/{messageid}/bypass
# Returns: record<ErrorCode: int, Message: string>
# operationId: bypassRulesForInboundMessage
export def "bypass-rules-for-inbound-message" [
  messageid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/messages/inbound/{messageid}/bypass"
    path_params: [{name: messageid, var: messageid}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    messageid: $messageid, x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inbound message details
#
# GET /messages/inbound/{messageid}/details
# Returns: record<Attachments: table<Content: string, ContentID: string, ContentType: string, Name: string>, BlockedReason: string, Cc: string, CcFull: table<Email: string, Name: string>, Date: string, From: string, FromFull: record<Email: string, Name: string>, FromName: string, Headers: table<Name: string, Value: string>, HtmlBody: string, MailboxHash: string, MessageID: string, OriginalRecipient: string, ReplyTo: string, Status: string, Subject: string, Tag: string, TextBody: string, To: string, ToFull: table<Email: string, Name: string>>
# operationId: getInboundMessageDetails
export def "get-inbound-message-details" [
  messageid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/messages/inbound/{messageid}/details"
    path_params: [{name: messageid, var: messageid}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    messageid: $messageid, x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retry a failed inbound message for processing
#
# PUT /messages/inbound/{messageid}/retry
# Returns: record<ErrorCode: int, Message: string>
# operationId: retryInboundMessageProcessing
export def "retry-inbound-message-processing" [
  messageid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/messages/inbound/{messageid}/retry"
    path_params: [{name: messageid, var: messageid}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    messageid: $messageid, x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Outbound message search
#
# GET /messages/outbound
# Returns: record<Messages: table<Attachments: list, Bcc: list, Cc: list, From: string, MessageID: string, ReceivedAt: string, Recipients: list, Status: string, Subject: string, Tag: string, To: list, TrackLinks: string, TrackOpens: bool>, TotalCount: int>
# operationId: searchOutboundMessages
export def "search-outbound-messages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Number of messages to return per request. Max 500. (required)
  --offset: int # Number of messages to skip (required)
  --recipient: string # Filter by the user who was receiving the email (format: email)
  --fromemail: string # Filter by the sender email address (format: email)
  --tag: string # Filter by tag
  --status: string@status-completer-1 # Filter by status (`queued` or `sent`)
  --todate: string # Filter messages up to the date specified. e.g. `2014-02-01` (format: date)
  --fromdate: string # Filter messages starting from the date specified. e.g. `2014-02-01` (format: date)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/messages/outbound"
    query: [{name: count, var: count, required: true}, {name: offset, var: offset, required: true}, {name: recipient, var: recipient}, {name: fromemail, var: fromemail}, {name: tag, var: tag}, {name: status, var: status}, {name: todate, var: todate}, {name: fromdate, var: fromdate}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    count: $count, offset: $offset, recipient: $recipient, fromemail: $fromemail, tag: $tag, status: $status, todate: $todate, fromdate: $fromdate, x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clicks for a all messages
#
# GET /messages/outbound/clicks
# Returns: record<Clicks: table<ClickLocation: string, Client: record, Geo: record, MessageID: string, OS: record, OriginalLink: string, Platform: string, ReceivedAt: string, Recipient: string, Tag: string, UserAgent: string>, TotalCount: int>
# operationId: searchClicksForOutboundMessages
export def "search-clicks-for-outbound-messages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Number of message clicks to return per request. Max 500. (required)
  --offset: int # Number of messages to skip (required)
  --recipient: string # Filter by To, Cc, Bcc
  --tag: string # Filter by tag
  --client-name: string # Filter by client name, i.e. Outlook, Gmail
  --client-company: string # Filter by company, i.e. Microsoft, Apple, Google
  --client-family: string # Filter by client family, i.e. OS X, Chrome
  --os-name: string # Filter by full OS name and specific version, i.e. OS X 10.9 Mavericks, Windows 7
  --os-family: string # Filter by kind of OS used without specific version, i.e. OS X, Windows
  --os-company: string # Filter by company which produced the OS, i.e. Apple Computer, Inc., Microsoft Corporation
  --platform: string # Filter by platform, i.e. webmail, desktop, mobile
  --country: string # Filter by country messages were opened in, i.e. Denmark, Russia
  --region: string # Filter by full name of region messages were opened in, i.e. Moscow, New York
  --city: string # Filter by full name of region messages were opened in, i.e. Moscow, New York
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/messages/outbound/clicks"
    query: [{name: count, var: count, required: true}, {name: offset, var: offset, required: true}, {name: recipient, var: recipient}, {name: tag, var: tag}, {name: client_name, var: client_name}, {name: client_company, var: client_company}, {name: client_family, var: client_family}, {name: os_name, var: os_name}, {name: os_family, var: os_family}, {name: os_company, var: os_company}, {name: platform, var: platform}, {name: country, var: country}, {name: region, var: region}, {name: city, var: city}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    count: $count, offset: $offset, recipient: $recipient, tag: $tag, client_name: $client_name, client_company: $client_company, client_family: $client_family, os_name: $os_name, os_family: $os_family, os_company: $os_company, platform: $platform, country: $country, region: $region, city: $city, x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Message Clicks
#
# GET /messages/outbound/clicks/{messageid}
# Returns: record<Clicks: table<ClickLocation: string, Client: record, Geo: record, MessageID: string, OS: record, OriginalLink: string, Platform: string, ReceivedAt: string, Recipient: string, Tag: string, UserAgent: string>, TotalCount: int>
# operationId: getClicksForSingleOutboundMessage
export def "get-clicks-for-single-outbound-message" [
  messageid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Number of message clicks to return per request. Max 500. (required, default: 1)
  --offset: int # Number of messages to skip. (required, default: 0)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/messages/outbound/clicks/{messageid}"
    path_params: [{name: messageid, var: messageid}]
    query: [{name: count, var: count, required: true, default: 1}, {name: offset, var: offset, required: true, default: 0}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    messageid: $messageid, count: $count, offset: $offset, x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Opens for all messages
#
# GET /messages/outbound/opens
# Returns: record<Opens: table<Client: record, FirstOpen: bool, Geo: record, MessageID: string, OS: record, Platform: string, ReceivedAt: string, Recipient: string, Tag: string, UserAgent: string>, TotalCount: int>
# operationId: searchOpensForOutboundMessages
export def "search-opens-for-outbound-messages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Number of message opens to return per request. Max 500. (required)
  --offset: int # Number of messages to skip (required)
  --recipient: string # Filter by To, Cc, Bcc
  --tag: string # Filter by tag
  --client-name: string # Filter by client name, i.e. Outlook, Gmail
  --client-company: string # Filter by company, i.e. Microsoft, Apple, Google
  --client-family: string # Filter by client family, i.e. OS X, Chrome
  --os-name: string # Filter by full OS name and specific version, i.e. OS X 10.9 Mavericks, Windows 7
  --os-family: string # Filter by kind of OS used without specific version, i.e. OS X, Windows
  --os-company: string # Filter by company which produced the OS, i.e. Apple Computer, Inc., Microsoft Corporation
  --platform: string # Filter by platform, i.e. webmail, desktop, mobile
  --country: string # Filter by country messages were opened in, i.e. Denmark, Russia
  --region: string # Filter by full name of region messages were opened in, i.e. Moscow, New York
  --city: string # Filter by full name of region messages were opened in, i.e. Moscow, New York
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/messages/outbound/opens"
    query: [{name: count, var: count, required: true}, {name: offset, var: offset, required: true}, {name: recipient, var: recipient}, {name: tag, var: tag}, {name: client_name, var: client_name}, {name: client_company, var: client_company}, {name: client_family, var: client_family}, {name: os_name, var: os_name}, {name: os_family, var: os_family}, {name: os_company, var: os_company}, {name: platform, var: platform}, {name: country, var: country}, {name: region, var: region}, {name: city, var: city}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    count: $count, offset: $offset, recipient: $recipient, tag: $tag, client_name: $client_name, client_company: $client_company, client_family: $client_family, os_name: $os_name, os_family: $os_family, os_company: $os_company, platform: $platform, country: $country, region: $region, city: $city, x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Message Opens
#
# GET /messages/outbound/opens/{messageid}
# Returns: record<Opens: table<Client: record, FirstOpen: bool, Geo: record, MessageID: string, OS: record, Platform: string, ReceivedAt: string, Recipient: string, Tag: string, UserAgent: string>, TotalCount: int>
# operationId: getOpensForSingleOutboundMessage
export def "get-opens-for-single-outbound-message" [
  messageid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Number of message opens to return per request. Max 500. (required, default: 1)
  --offset: int # Number of messages to skip. (required, default: 0)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/messages/outbound/opens/{messageid}"
    path_params: [{name: messageid, var: messageid}]
    query: [{name: count, var: count, required: true, default: 1}, {name: offset, var: offset, required: true, default: 0}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    messageid: $messageid, count: $count, offset: $offset, x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Outbound message details
#
# GET /messages/outbound/{messageid}/details
# Returns: record<Attachments: table<Content: string, ContentID: string, ContentType: string, Name: string>, Bcc: table<Email: string, Name: string>, Body: string, Cc: table<Email: string, Name: string>, From: string, HtmlBody: string, MessageEvents: table<Details: record, ReceivedAt: string, Recipient: string, Type: string>, MessageID: string, ReceivedAt: string, Recipients: list<string>, Status: string, Subject: string, Tag: string, TextBody: string, To: table<Email: string, Name: string>, TrackLinks: string, TrackOpens: bool>
# operationId: getOutboundMessageDetails
export def "get-outbound-message-details" [
  messageid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/messages/outbound/{messageid}/details"
    path_params: [{name: messageid, var: messageid}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    messageid: $messageid, x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Outbound message dump
#
# GET /messages/outbound/{messageid}/dump
# Returns: record<Body: string>
# operationId: getOutboundMessageDump
export def "get-outbound-message-dump" [
  messageid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/messages/outbound/{messageid}/dump"
    path_params: [{name: messageid, var: messageid}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    messageid: $messageid, x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Server Configuration
#
# GET /server
# Returns: record<ApiTokens: list<string>, BounceHookUrl: string, ClickHookUrl: string, Color: string, DeliveryHookUrl: string, ID: int, InboundAddress: string, InboundDomain: string, InboundHash: string, InboundHookUrl: string, InboundSpamThreshold: int, Name: string, OpenHookUrl: string, PostFirstOpenOnly: bool, RawEmailEnabled: bool, ServerLink: string, SmtpApiActivated: bool, TrackLinks: string, TrackOpens: bool>
# operationId: getCurrentServerConfiguration
export def "get-current-server-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/server"
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit Server Configuration
#
# PUT /server
# Returns: record<ApiTokens: list<string>, BounceHookUrl: string, ClickHookUrl: string, Color: string, DeliveryHookUrl: string, ID: int, InboundAddress: string, InboundDomain: string, InboundHash: string, InboundHookUrl: string, InboundSpamThreshold: int, Name: string, OpenHookUrl: string, PostFirstOpenOnly: bool, RawEmailEnabled: bool, ServerLink: string, SmtpApiActivated: bool, TrackLinks: string, TrackOpens: bool>
# operationId: editCurrentServerConfiguration
export def "edit-current-server-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
  --bounce-hook-url: string
  --click-hook-url: string # Webhook url allowing real-time notification when tracked links are clicked.
  --color: string@color-completer
  --delivery-hook-url: string
  --inbound-domain: string
  --inbound-hook-url: string
  --inbound-spam-threshold: int
  --name: string
  --open-hook-url: string
  --post-first-open-only: oneof<nothing, bool>
  --raw-email-enabled: oneof<nothing, bool>
  --smtp-api-activated: oneof<nothing, bool>
  --track-links: string@track-links-completer
  --track-opens: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/server"
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: BounceHookUrl, var: bounce_hook_url}, {name: ClickHookUrl, var: click_hook_url}, {name: Color, var: color}, {name: DeliveryHookUrl, var: delivery_hook_url}, {name: InboundDomain, var: inbound_domain}, {name: InboundHookUrl, var: inbound_hook_url}, {name: InboundSpamThreshold, var: inbound_spam_threshold}, {name: Name, var: name}, {name: OpenHookUrl, var: open_hook_url}, {name: PostFirstOpenOnly, var: post_first_open_only}, {name: RawEmailEnabled, var: raw_email_enabled}, {name: SmtpApiActivated, var: smtp_api_activated}, {name: TrackLinks, var: track_links}, {name: TrackOpens, var: track_opens}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_postmark_server_token: $x_postmark_server_token, bounce_hook_url: $bounce_hook_url, click_hook_url: $click_hook_url, color: $color, delivery_hook_url: $delivery_hook_url, inbound_domain: $inbound_domain, inbound_hook_url: $inbound_hook_url, inbound_spam_threshold: $inbound_spam_threshold, name: $name, open_hook_url: $open_hook_url, post_first_open_only: $post_first_open_only, raw_email_enabled: $raw_email_enabled, smtp_api_activated: $smtp_api_activated, track_links: $track_links, track_opens: $track_opens
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get outbound overview
#
# GET /stats/outbound
# Returns: record<BounceRate: int, Bounced: int, Opens: int, SMTPAPIErrors: int, Sent: int, SpamComplaints: int, SpamComplaintsRate: int, TotalClicks: int, TotalTrackedLinksSent: int, Tracked: int, UniqueLinksClicked: int, UniqueOpens: int, WithClientRecorded: int, WithLinkTracking: int, WithOpenTracking: int, WithPlatformRecorded: int>
# operationId: getOutboundOverviewStatistics
export def "get-outbound-overview-statistics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/stats/outbound"
    query: [{name: tag, var: tag}, {name: fromdate, var: fromdate}, {name: todate, var: todate}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tag: $tag, fromdate: $fromdate, todate: $todate, x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get bounce counts
#
# GET /stats/outbound/bounces
# Returns: record<Days: table<Date: string, HardBounce: int, SMTPApiError: int, SoftBounce: int, Transient: int>, HardBounce: int, SMTPApiError: int, SoftBounce: int, Transient: int>
# operationId: getBounceCounts
export def "get-bounce-counts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/stats/outbound/bounces"
    query: [{name: tag, var: tag}, {name: fromdate, var: fromdate}, {name: todate, var: todate}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tag: $tag, fromdate: $fromdate, todate: $todate, x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get click counts
#
# GET /stats/outbound/clicks
# operationId: getOutboundClickCounts
export def "get-outbound-click-counts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/stats/outbound/clicks"
    query: [{name: tag, var: tag}, {name: fromdate, var: fromdate}, {name: todate, var: todate}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tag: $tag, fromdate: $fromdate, todate: $todate, x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get browser usage by family
#
# GET /stats/outbound/clicks/browserfamilies
# Returns: record
# operationId: getOutboundClickCountsByBrowserFamily
export def "get-outbound-click-counts-by-browser-family" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/stats/outbound/clicks/browserfamilies"
    query: [{name: tag, var: tag}, {name: fromdate, var: fromdate}, {name: todate, var: todate}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tag: $tag, fromdate: $fromdate, todate: $todate, x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get clicks by body location
#
# GET /stats/outbound/clicks/location
# operationId: getOutboundClickCountsByLocation
export def "get-outbound-click-counts-by-location" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/stats/outbound/clicks/location"
    query: [{name: tag, var: tag}, {name: fromdate, var: fromdate}, {name: todate, var: todate}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tag: $tag, fromdate: $fromdate, todate: $todate, x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get browser plaform usage
#
# GET /stats/outbound/clicks/platforms
# operationId: getOutboundClickCountsByPlatform
export def "get-outbound-click-counts-by-platform" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/stats/outbound/clicks/platforms"
    query: [{name: tag, var: tag}, {name: fromdate, var: fromdate}, {name: todate, var: todate}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tag: $tag, fromdate: $fromdate, todate: $todate, x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get email open counts
#
# GET /stats/outbound/opens
# Returns: record<Days: table<Date: string, Opens: int, Unique: int>, Opens: int, Unique: int>
# operationId: getOutboundOpenCounts
export def "get-outbound-open-counts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/stats/outbound/opens"
    query: [{name: tag, var: tag}, {name: fromdate, var: fromdate}, {name: todate, var: todate}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tag: $tag, fromdate: $fromdate, todate: $todate, x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get email client usage
#
# GET /stats/outbound/opens/emailclients
# Returns: record<Days: list<any>, Desktop: int, Mobile: int, Unknown: int, WebMail: int>
# operationId: getOutboundOpenCountsByEmailClient
export def "get-outbound-open-counts-by-email-client" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/stats/outbound/opens/emailclients"
    query: [{name: tag, var: tag}, {name: fromdate, var: fromdate}, {name: todate, var: todate}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tag: $tag, fromdate: $fromdate, todate: $todate, x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get email platform usage
#
# GET /stats/outbound/opens/platforms
# Returns: record<Days: table<Date: string, Desktop: int, Mobile: int, Unknown: int, WebMail: int>, Desktop: int, Mobile: int, Unknown: int, WebMail: int>
# operationId: getOutboundOpenCountsByPlatform
export def "get-outbound-open-counts-by-platform" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/stats/outbound/opens/platforms"
    query: [{name: tag, var: tag}, {name: fromdate, var: fromdate}, {name: todate, var: todate}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tag: $tag, fromdate: $fromdate, todate: $todate, x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get sent counts
#
# GET /stats/outbound/sends
# Returns: record<Days: table<Date: string, Sent: int>, Sent: int>
# operationId: getSentCounts
export def "get-sent-counts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/stats/outbound/sends"
    query: [{name: tag, var: tag}, {name: fromdate, var: fromdate}, {name: todate, var: todate}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tag: $tag, fromdate: $fromdate, todate: $todate, x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get spam complaints
#
# GET /stats/outbound/spam
# Returns: record<Days: table<Date: string, SpamComplaint: int>, SpamComplaint: int>
# operationId: getSpamComplaints
export def "get-spam-complaints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats up to the date specified. e.g. `2014-02-01` (format: date)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/stats/outbound/spam"
    query: [{name: tag, var: tag}, {name: fromdate, var: fromdate}, {name: todate, var: todate}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tag: $tag, fromdate: $fromdate, todate: $todate, x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get tracked email counts
#
# GET /stats/outbound/tracked
# Returns: record<Days: table<Date: string, Tracked: int>, Tracked: int>
# operationId: getTrackedEmailCounts
export def "get-tracked-email-counts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Filter by tag
  --fromdate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --todate: string # Filter stats starting from the date specified. e.g. `2014-01-01` (format: date)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/stats/outbound/tracked"
    query: [{name: tag, var: tag}, {name: fromdate, var: fromdate}, {name: todate, var: todate}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tag: $tag, fromdate: $fromdate, todate: $todate, x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the Templates associated with this Server
#
# GET /templates
# Returns: record<"Templates API": table<Active: bool, Alias: string, Name: string, TemplateId: float>, TotalCount: float>
# operationId: listTemplates
export def "list-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: float # The number of Templates to return (required, format: int)
  --offset: float # The number of Templates to "skip" before returning results. (required, format: int)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/templates"
    query: [{name: Count, var: count, required: true}, {name: Offset, var: offset, required: true}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    count: $count, offset: $offset, x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Template
#
# POST /templates
# Returns: record<Active: bool, Alias: string, Name: string, TemplateId: float>
export def "post-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
  --alias: string # The optional string identifier for referring to this Template (numbers, letters, and '.', '-', '_' characters, starts with a letter).
  --html-body: string # The HTML template definition for this Template.
  name: string # The friendly display name for the template.
  subject: string # The Subject template definition for this Template.
  --text-body: string # The Text template definition for this Template.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/templates"
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Alias, var: alias}, {name: HtmlBody, var: html_body}, {name: Name, var: name}, {name: Subject, var: subject}, {name: TextBody, var: text_body}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_postmark_server_token: $x_postmark_server_token, alias: $alias, html_body: $html_body, name: $name, subject: $subject, text_body: $text_body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test Template Content
#
# POST /templates/validate
# Returns: record<AllContentIsValid: bool, HtmlBody: record<ContentIsValid: bool, RenderedContent: string, ValidationErrors: list<record>>, Subject: record<ContentIsValid: bool, RenderedContent: string, ValidationErrors: list<record>>, SuggestedTemplateModel: record, TextBody: record<ContentIsValid: bool, RenderedContent: string, ValidationErrors: list<record>>>
# operationId: testTemplateContent
export def "test-template-content" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
  --html-body: string # The html body content to validate. Must be specified if Subject or TextBody are not. See our template language documentation for more information on the syntax for this field.
  --inline-css-for-html-test-render: oneof<nothing, bool> # When HtmlBody is specified, the test render will have style blocks inlined as style attributes on matching html elements. You may disable the css inlining behavior by passing false for this parameter. (default: true)
  --subject: string # The subject content to validate. Must be specified if HtmlBody or TextBody are not. See our template language documentation for more information on the syntax for this field.
  --test-render-model: record # The model to be used when rendering test content.
  --text-body: string # The text body content to validate. Must be specified if HtmlBody or Subject are not. See our template language documentation for more information on the syntax for this field.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/templates/validate"
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: HtmlBody, var: html_body}, {name: InlineCssForHtmlTestRender, var: inline_css_for_html_test_render}, {name: Subject, var: subject}, {name: TestRenderModel, var: test_render_model}, {name: TextBody, var: text_body}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_postmark_server_token: $x_postmark_server_token, html_body: $html_body, inline_css_for_html_test_render: $inline_css_for_html_test_render, subject: $subject, test_render_model: $test_render_model, text_body: $text_body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Template
#
# DELETE /templates/{templateIdOrAlias}
# Returns: record<Active: bool, Alias: string, AssociatedServerId: int, HtmlBody: string, Name: string, Subject: string, TemplateID: int, TextBody: string>
# operationId: deleteTemplate
export def "delete-template" [
  template_id_or_alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/templates/{templateIdOrAlias}"
    path_params: [{name: templateIdOrAlias, var: template_id_or_alias}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    template_id_or_alias: $template_id_or_alias, x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Template
#
# GET /templates/{templateIdOrAlias}
# Returns: record<Active: bool, Alias: string, AssociatedServerId: int, HtmlBody: string, Name: string, Subject: string, TemplateID: int, TextBody: string>
# operationId: getSingleTemplate
export def "get-single-template" [
  template_id_or_alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/templates/{templateIdOrAlias}"
    path_params: [{name: templateIdOrAlias, var: template_id_or_alias}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    template_id_or_alias: $template_id_or_alias, x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Template
#
# PUT /templates/{templateIdOrAlias}
# Returns: record<Active: bool, Alias: string, Name: string, TemplateId: float>
# operationId: updateTemplate
export def "update-template" [
  template_id_or_alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
  --alias: string # The optional string identifier for referring to this Template (numbers, letters, and '.', '-', '_' characters, starts with a letter).
  --html-body: string # The HTML template definition for this Template.
  --name: string # The friendly display name for the template.
  --subject: string # The Subject template definition for this Template.
  --text-body: string # The Text template definition for this Template.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/templates/{templateIdOrAlias}"
    path_params: [{name: templateIdOrAlias, var: template_id_or_alias}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Alias, var: alias}, {name: HtmlBody, var: html_body}, {name: Name, var: name}, {name: Subject, var: subject}, {name: TextBody, var: text_body}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    template_id_or_alias: $template_id_or_alias, x_postmark_server_token: $x_postmark_server_token, alias: $alias, html_body: $html_body, name: $name, subject: $subject, text_body: $text_body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List inbound rule triggers
#
# GET /triggers/inboundrules
# Returns: record<InboundRules: table<ID: int, Rule: string>, TotalCount: int>
# operationId: listInboundRules
export def "list-inbound-rules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Number of records to return per request. (required)
  --offset: int # Number of records to skip. (required)
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/triggers/inboundrules"
    query: [{name: count, var: count, required: true}, {name: offset, var: offset, required: true}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    count: $count, offset: $offset, x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an inbound rule trigger
#
# POST /triggers/inboundrules
# Returns: record<ID: int, Rule: string>
# operationId: createInboundRule
export def "create-inbound-rule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
  --rule: string # format: email
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/triggers/inboundrules"
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Rule, var: rule}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_postmark_server_token: $x_postmark_server_token, rule: $rule
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a single trigger
#
# DELETE /triggers/inboundrules/{triggerid}
# Returns: record<ErrorCode: int, Message: string>
# operationId: deleteInboundRule
export def "delete-inbound-rule" [
  triggerid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-postmark-server-token: string # The token associated with the Server on which this request will operate. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/triggers/inboundrules/{triggerid}"
    path_params: [{name: triggerid, var: triggerid}]
    header: [{name: X-Postmark-Server-Token, var: x_postmark_server_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    triggerid: $triggerid, x_postmark_server_token: $x_postmark_server_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
