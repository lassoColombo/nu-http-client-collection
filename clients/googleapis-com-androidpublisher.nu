# Auto-generated client for Google Play Android Developer API v3
# Source: https://api.apis.guru/v2/specs/googleapis.com/androidpublisher/v3/openapi.json
# Auth: --token flag or $env.GOOGLE_PLAY_ANDROID_DEVELOPER_API_TOKEN

const CLIENT = {
  base_url: "https://androidpublisher.googleapis.com"
  token_env_var: "GOOGLE_PLAY_ANDROID_DEVELOPER_API_TOKEN"
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

def base-url-completer [] { ["https://androidpublisher.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def deobfuscation-file-type-completer [] { ["deobfuscationFileTypeUnspecified" "nativeCode" "proguard"] }
def expansion-file-type-completer [] { ["expansionFileTypeUnspecified" "main" "patch"] }
def image-type-completer [] { ["appImageTypeUnspecified" "featureGraphic" "icon" "phoneScreenshots" "sevenInchScreenshots" "tenInchScreenshots" "tvBanner" "tvScreenshots" "wearScreenshots"] }
def purchase-type-completer [] { ["managedUser" "purchaseTypeUnspecified" "subscription"] }
def status-completer [] { ["active" "inactive" "statusUnspecified"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    androidpublisher-internalappsharingartifacts-uploadapk: "record<certificateFingerprint: string, downloadUrl: string, sha256: string>"
    androidpublisher-internalappsharingartifacts-uploadbundle: "record<certificateFingerprint: string, downloadUrl: string, sha256: string>"
    androidpublisher-applications-device-tier-configs-list: "record<deviceTierConfigs: table<deviceGroups: list, deviceTierConfigId: string, deviceTierSet: record, userCountrySets: list>, nextPageToken: string>"
    androidpublisher-applications-device-tier-configs-create: "record<deviceGroups: table<deviceSelectors: list, name: string>, deviceTierConfigId: string, deviceTierSet: record<deviceTiers: list<record>>, userCountrySets: table<countryCodes: list, name: string>>"
    androidpublisher-applications-device-tier-configs-get: "record<deviceGroups: table<deviceSelectors: list, name: string>, deviceTierConfigId: string, deviceTierSet: record<deviceTiers: list<record>>, userCountrySets: table<countryCodes: list, name: string>>"
    androidpublisher-edits-insert: "record<expiryTimeSeconds: string, id: string>"
    androidpublisher-edits-get: "record<expiryTimeSeconds: string, id: string>"
    androidpublisher-edits-apks-list: "record<apks: table<binary: record, versionCode: int>, kind: string>"
    androidpublisher-edits-apks-upload: "record<binary: record<sha1: string, sha256: string>, versionCode: int>"
    androidpublisher-edits-apks-addexternallyhosted: "record<externallyHostedApk: record<applicationLabel: string, certificateBase64s: list<string>, externallyHostedUrl: string, fileSha1Base64: string, fileSha256Base64: string, fileSize: string, iconBase64: string, maximumSdk: int, minimumSdk: int, nativeCodes: list<string>, packageName: string, usesFeatures: list<string>, usesPermissions: list<record>, versionCode: int, versionName: string>>"
    androidpublisher-edits-deobfuscationfiles-upload: "record<deobfuscationFile: record<symbolType: string>>"
    androidpublisher-edits-expansionfiles-get: "record<fileSize: string, referencesVersion: int>"
    androidpublisher-edits-expansionfiles-patch: "record<fileSize: string, referencesVersion: int>"
    androidpublisher-edits-expansionfiles-upload: "record<expansionFile: record<fileSize: string, referencesVersion: int>>"
    androidpublisher-edits-expansionfiles-update: "record<fileSize: string, referencesVersion: int>"
    androidpublisher-edits-bundles-list: "record<bundles: table<sha1: string, sha256: string, versionCode: int>, kind: string>"
    androidpublisher-edits-bundles-upload: "record<sha1: string, sha256: string, versionCode: int>"
    androidpublisher-edits-countryavailability-get: "record<countries: table<countryCode: string>, restOfWorld: bool, syncWithProduction: bool>"
    androidpublisher-edits-details-get: "record<contactEmail: string, contactPhone: string, contactWebsite: string, defaultLanguage: string>"
    androidpublisher-edits-details-patch: "record<contactEmail: string, contactPhone: string, contactWebsite: string, defaultLanguage: string>"
    androidpublisher-edits-details-update: "record<contactEmail: string, contactPhone: string, contactWebsite: string, defaultLanguage: string>"
    androidpublisher-edits-listings-list: "record<kind: string, listings: table<fullDescription: string, language: string, shortDescription: string, title: string, video: string>>"
    androidpublisher-edits-listings-get: "record<fullDescription: string, language: string, shortDescription: string, title: string, video: string>"
    androidpublisher-edits-listings-patch: "record<fullDescription: string, language: string, shortDescription: string, title: string, video: string>"
    androidpublisher-edits-listings-update: "record<fullDescription: string, language: string, shortDescription: string, title: string, video: string>"
    androidpublisher-edits-images-deleteall: "record<deleted: table<id: string, sha1: string, sha256: string, url: string>>"
    androidpublisher-edits-images-list: "record<images: table<id: string, sha1: string, sha256: string, url: string>>"
    androidpublisher-edits-images-upload: "record<image: record<id: string, sha1: string, sha256: string, url: string>>"
    androidpublisher-edits-testers-get: "record<googleGroups: list<string>>"
    androidpublisher-edits-testers-patch: "record<googleGroups: list<string>>"
    androidpublisher-edits-testers-update: "record<googleGroups: list<string>>"
    androidpublisher-edits-tracks-list: "record<kind: string, tracks: table<releases: list, track: string>>"
    androidpublisher-edits-tracks-get: "record<releases: table<countryTargeting: record, inAppUpdatePriority: int, name: string, releaseNotes: list, status: string, userFraction: float, versionCodes: list>, track: string>"
    androidpublisher-edits-tracks-patch: "record<releases: table<countryTargeting: record, inAppUpdatePriority: int, name: string, releaseNotes: list, status: string, userFraction: float, versionCodes: list>, track: string>"
    androidpublisher-edits-tracks-update: "record<releases: table<countryTargeting: record, inAppUpdatePriority: int, name: string, releaseNotes: list, status: string, userFraction: float, versionCodes: list>, track: string>"
    androidpublisher-edits-commit: "record<expiryTimeSeconds: string, id: string>"
    androidpublisher-edits-validate: "record<expiryTimeSeconds: string, id: string>"
    androidpublisher-generatedapks-list: "record<generatedApks: table<certificateSha256Hash: string, generatedAssetPackSlices: list, generatedSplitApks: list, generatedStandaloneApks: list, generatedUniversalApk: record>>"
    androidpublisher-inappproducts-list: "record<inappproduct: table<defaultLanguage: string, defaultPrice: record, gracePeriod: string, listings: record, managedProductTaxesAndComplianceSettings: record, packageName: string, prices: record, purchaseType: string, sku: string, status: string, subscriptionPeriod: string, subscriptionTaxesAndComplianceSettings: record, trialPeriod: string>, kind: string, pageInfo: record<resultPerPage: int, startIndex: int, totalResults: int>, tokenPagination: record<nextPageToken: string, previousPageToken: string>>"
    androidpublisher-inappproducts-insert: "record<defaultLanguage: string, defaultPrice: record<currency: string, priceMicros: string>, gracePeriod: string, listings: record, managedProductTaxesAndComplianceSettings: record<eeaWithdrawalRightType: string, taxRateInfoByRegionCode: record>, packageName: string, prices: record, purchaseType: string, sku: string, status: string, subscriptionPeriod: string, subscriptionTaxesAndComplianceSettings: record<eeaWithdrawalRightType: string, taxRateInfoByRegionCode: record>, trialPeriod: string>"
    androidpublisher-inappproducts-get: "record<defaultLanguage: string, defaultPrice: record<currency: string, priceMicros: string>, gracePeriod: string, listings: record, managedProductTaxesAndComplianceSettings: record<eeaWithdrawalRightType: string, taxRateInfoByRegionCode: record>, packageName: string, prices: record, purchaseType: string, sku: string, status: string, subscriptionPeriod: string, subscriptionTaxesAndComplianceSettings: record<eeaWithdrawalRightType: string, taxRateInfoByRegionCode: record>, trialPeriod: string>"
    androidpublisher-inappproducts-patch: "record<defaultLanguage: string, defaultPrice: record<currency: string, priceMicros: string>, gracePeriod: string, listings: record, managedProductTaxesAndComplianceSettings: record<eeaWithdrawalRightType: string, taxRateInfoByRegionCode: record>, packageName: string, prices: record, purchaseType: string, sku: string, status: string, subscriptionPeriod: string, subscriptionTaxesAndComplianceSettings: record<eeaWithdrawalRightType: string, taxRateInfoByRegionCode: record>, trialPeriod: string>"
    androidpublisher-inappproducts-update: "record<defaultLanguage: string, defaultPrice: record<currency: string, priceMicros: string>, gracePeriod: string, listings: record, managedProductTaxesAndComplianceSettings: record<eeaWithdrawalRightType: string, taxRateInfoByRegionCode: record>, packageName: string, prices: record, purchaseType: string, sku: string, status: string, subscriptionPeriod: string, subscriptionTaxesAndComplianceSettings: record<eeaWithdrawalRightType: string, taxRateInfoByRegionCode: record>, trialPeriod: string>"
    androidpublisher-monetization-convert-region-prices: "record<convertedOtherRegionsPrice: record<eurPrice: record<currencyCode: string, nanos: int, units: string>, usdPrice: record<currencyCode: string, nanos: int, units: string>>, convertedRegionPrices: record>"
    androidpublisher-purchases-products-get: "record<acknowledgementState: int, consumptionState: int, developerPayload: string, kind: string, obfuscatedExternalAccountId: string, obfuscatedExternalProfileId: string, orderId: string, productId: string, purchaseState: int, purchaseTimeMillis: string, purchaseToken: string, purchaseType: int, quantity: int, regionCode: string>"
    androidpublisher-purchases-subscriptions-get: "record<acknowledgementState: int, autoRenewing: bool, autoResumeTimeMillis: string, cancelReason: int, cancelSurveyResult: record<cancelSurveyReason: int, userInputCancelReason: string>, countryCode: string, developerPayload: string, emailAddress: string, expiryTimeMillis: string, externalAccountId: string, familyName: string, givenName: string, introductoryPriceInfo: record<introductoryPriceAmountMicros: string, introductoryPriceCurrencyCode: string, introductoryPriceCycles: int, introductoryPricePeriod: string>, kind: string, linkedPurchaseToken: string, obfuscatedExternalAccountId: string, obfuscatedExternalProfileId: string, orderId: string, paymentState: int, priceAmountMicros: string, priceChange: record<newPrice: record<currency: string, priceMicros: string>, state: int>, priceCurrencyCode: string, profileId: string, profileName: string, promotionCode: string, promotionType: int, purchaseType: int, startTimeMillis: string, userCancellationTimeMillis: string>"
    androidpublisher-purchases-subscriptions-defer: "record<newExpiryTimeMillis: string>"
    androidpublisher-purchases-subscriptionsv2-get: "record<acknowledgementState: string, canceledStateContext: record<developerInitiatedCancellation: record, replacementCancellation: record, systemInitiatedCancellation: record, userInitiatedCancellation: record<cancelSurveyResult: record, cancelTime: string>>, externalAccountIdentifiers: record<externalAccountId: string, obfuscatedExternalAccountId: string, obfuscatedExternalProfileId: string>, kind: string, latestOrderId: string, lineItems: table<autoRenewingPlan: record, expiryTime: string, offerDetails: record, prepaidPlan: record, productId: string>, linkedPurchaseToken: string, pausedStateContext: record<autoResumeTime: string>, regionCode: string, startTime: string, subscribeWithGoogleInfo: record<emailAddress: string, familyName: string, givenName: string, profileId: string, profileName: string>, subscriptionState: string, testPurchase: record>"
    androidpublisher-purchases-voidedpurchases-list: "record<pageInfo: record<resultPerPage: int, startIndex: int, totalResults: int>, tokenPagination: record<nextPageToken: string, previousPageToken: string>, voidedPurchases: table<kind: string, orderId: string, purchaseTimeMillis: string, purchaseToken: string, voidedReason: int, voidedSource: int, voidedTimeMillis: string>>"
    androidpublisher-reviews-list: "record<pageInfo: record<resultPerPage: int, startIndex: int, totalResults: int>, reviews: table<authorName: string, comments: list, reviewId: string>, tokenPagination: record<nextPageToken: string, previousPageToken: string>>"
    androidpublisher-reviews-get: "record<authorName: string, comments: table<developerComment: record, userComment: record>, reviewId: string>"
    androidpublisher-reviews-reply: "record<result: record<lastEdited: record<nanos: int, seconds: string>, replyText: string>>"
    androidpublisher-monetization-subscriptions-list: "record<nextPageToken: string, subscriptions: table<archived: bool, basePlans: list, listings: list, packageName: string, productId: string, taxAndComplianceSettings: record>>"
    androidpublisher-monetization-subscriptions-create: "record<archived: bool, basePlans: table<autoRenewingBasePlanType: record, basePlanId: string, offerTags: list, otherRegionsConfig: record, prepaidBasePlanType: record, regionalConfigs: list, state: string>, listings: table<benefits: list, description: string, languageCode: string, title: string>, packageName: string, productId: string, taxAndComplianceSettings: record<eeaWithdrawalRightType: string, taxRateInfoByRegionCode: record>>"
    androidpublisher-monetization-subscriptions-get: "record<archived: bool, basePlans: table<autoRenewingBasePlanType: record, basePlanId: string, offerTags: list, otherRegionsConfig: record, prepaidBasePlanType: record, regionalConfigs: list, state: string>, listings: table<benefits: list, description: string, languageCode: string, title: string>, packageName: string, productId: string, taxAndComplianceSettings: record<eeaWithdrawalRightType: string, taxRateInfoByRegionCode: record>>"
    androidpublisher-monetization-subscriptions-patch: "record<archived: bool, basePlans: table<autoRenewingBasePlanType: record, basePlanId: string, offerTags: list, otherRegionsConfig: record, prepaidBasePlanType: record, regionalConfigs: list, state: string>, listings: table<benefits: list, description: string, languageCode: string, title: string>, packageName: string, productId: string, taxAndComplianceSettings: record<eeaWithdrawalRightType: string, taxRateInfoByRegionCode: record>>"
    androidpublisher-monetization-subscriptions-base-plans-offers-list: "record<nextPageToken: string, subscriptionOffers: table<basePlanId: string, offerId: string, offerTags: list, otherRegionsConfig: record, packageName: string, phases: list, productId: string, regionalConfigs: list, state: string, targeting: record>>"
    androidpublisher-monetization-subscriptions-base-plans-offers-create: "record<basePlanId: string, offerId: string, offerTags: table<tag: string>, otherRegionsConfig: record<otherRegionsNewSubscriberAvailability: bool>, packageName: string, phases: table<duration: string, otherRegionsConfig: record, recurrenceCount: int, regionalConfigs: list>, productId: string, regionalConfigs: table<newSubscriberAvailability: bool, regionCode: string>, state: string, targeting: record<acquisitionRule: record<scope: record>, upgradeRule: record<billingPeriodDuration: string, oncePerUser: bool, scope: record>>>"
    androidpublisher-monetization-subscriptions-base-plans-offers-get: "record<basePlanId: string, offerId: string, offerTags: table<tag: string>, otherRegionsConfig: record<otherRegionsNewSubscriberAvailability: bool>, packageName: string, phases: table<duration: string, otherRegionsConfig: record, recurrenceCount: int, regionalConfigs: list>, productId: string, regionalConfigs: table<newSubscriberAvailability: bool, regionCode: string>, state: string, targeting: record<acquisitionRule: record<scope: record>, upgradeRule: record<billingPeriodDuration: string, oncePerUser: bool, scope: record>>>"
    androidpublisher-monetization-subscriptions-base-plans-offers-patch: "record<basePlanId: string, offerId: string, offerTags: table<tag: string>, otherRegionsConfig: record<otherRegionsNewSubscriberAvailability: bool>, packageName: string, phases: table<duration: string, otherRegionsConfig: record, recurrenceCount: int, regionalConfigs: list>, productId: string, regionalConfigs: table<newSubscriberAvailability: bool, regionCode: string>, state: string, targeting: record<acquisitionRule: record<scope: record>, upgradeRule: record<billingPeriodDuration: string, oncePerUser: bool, scope: record>>>"
    androidpublisher-monetization-subscriptions-base-plans-offers-activate: "record<basePlanId: string, offerId: string, offerTags: table<tag: string>, otherRegionsConfig: record<otherRegionsNewSubscriberAvailability: bool>, packageName: string, phases: table<duration: string, otherRegionsConfig: record, recurrenceCount: int, regionalConfigs: list>, productId: string, regionalConfigs: table<newSubscriberAvailability: bool, regionCode: string>, state: string, targeting: record<acquisitionRule: record<scope: record>, upgradeRule: record<billingPeriodDuration: string, oncePerUser: bool, scope: record>>>"
    androidpublisher-monetization-subscriptions-base-plans-offers-deactivate: "record<basePlanId: string, offerId: string, offerTags: table<tag: string>, otherRegionsConfig: record<otherRegionsNewSubscriberAvailability: bool>, packageName: string, phases: table<duration: string, otherRegionsConfig: record, recurrenceCount: int, regionalConfigs: list>, productId: string, regionalConfigs: table<newSubscriberAvailability: bool, regionCode: string>, state: string, targeting: record<acquisitionRule: record<scope: record>, upgradeRule: record<billingPeriodDuration: string, oncePerUser: bool, scope: record>>>"
    androidpublisher-monetization-subscriptions-base-plans-activate: "record<archived: bool, basePlans: table<autoRenewingBasePlanType: record, basePlanId: string, offerTags: list, otherRegionsConfig: record, prepaidBasePlanType: record, regionalConfigs: list, state: string>, listings: table<benefits: list, description: string, languageCode: string, title: string>, packageName: string, productId: string, taxAndComplianceSettings: record<eeaWithdrawalRightType: string, taxRateInfoByRegionCode: record>>"
    androidpublisher-monetization-subscriptions-base-plans-deactivate: "record<archived: bool, basePlans: table<autoRenewingBasePlanType: record, basePlanId: string, offerTags: list, otherRegionsConfig: record, prepaidBasePlanType: record, regionalConfigs: list, state: string>, listings: table<benefits: list, description: string, languageCode: string, title: string>, packageName: string, productId: string, taxAndComplianceSettings: record<eeaWithdrawalRightType: string, taxRateInfoByRegionCode: record>>"
    androidpublisher-monetization-subscriptions-base-plans-migrate-prices: "record"
    androidpublisher-monetization-subscriptions-archive: "record<archived: bool, basePlans: table<autoRenewingBasePlanType: record, basePlanId: string, offerTags: list, otherRegionsConfig: record, prepaidBasePlanType: record, regionalConfigs: list, state: string>, listings: table<benefits: list, description: string, languageCode: string, title: string>, packageName: string, productId: string, taxAndComplianceSettings: record<eeaWithdrawalRightType: string, taxRateInfoByRegionCode: record>>"
    androidpublisher-systemapks-variants-list: "record<variants: table<deviceSpec: record, variantId: int>>"
    androidpublisher-systemapks-variants-create: "record<deviceSpec: record<screenDensity: int, supportedAbis: list<string>, supportedLocales: list<string>>, variantId: int>"
    androidpublisher-systemapks-variants-get: "record<deviceSpec: record<screenDensity: int, supportedAbis: list<string>, supportedLocales: list<string>>, variantId: int>"
    androidpublisher-externaltransactions-getexternaltransaction: "record<createTime: string, currentPreTaxAmount: record<currency: string, priceMicros: string>, currentTaxAmount: record<currency: string, priceMicros: string>, externalTransactionId: string, oneTimeTransaction: record<externalTransactionToken: string>, originalPreTaxAmount: record<currency: string, priceMicros: string>, originalTaxAmount: record<currency: string, priceMicros: string>, packageName: string, recurringTransaction: record<externalSubscription: record<subscriptionType: string>, externalTransactionToken: string, initialExternalTransactionId: string>, testPurchase: record, transactionState: string, transactionTime: string, userTaxAddress: record<regionCode: string>>"
    androidpublisher-users-patch: "record<accessState: string, developerAccountPermissions: list<string>, email: string, expirationTime: string, grants: table<appLevelPermissions: list, name: string, packageName: string>, name: string, partial: bool>"
    androidpublisher-externaltransactions-refundexternaltransaction: "record<createTime: string, currentPreTaxAmount: record<currency: string, priceMicros: string>, currentTaxAmount: record<currency: string, priceMicros: string>, externalTransactionId: string, oneTimeTransaction: record<externalTransactionToken: string>, originalPreTaxAmount: record<currency: string, priceMicros: string>, originalTaxAmount: record<currency: string, priceMicros: string>, packageName: string, recurringTransaction: record<externalSubscription: record<subscriptionType: string>, externalTransactionToken: string, initialExternalTransactionId: string>, testPurchase: record, transactionState: string, transactionTime: string, userTaxAddress: record<regionCode: string>>"
    androidpublisher-externaltransactions-createexternaltransaction: "record<createTime: string, currentPreTaxAmount: record<currency: string, priceMicros: string>, currentTaxAmount: record<currency: string, priceMicros: string>, externalTransactionId: string, oneTimeTransaction: record<externalTransactionToken: string>, originalPreTaxAmount: record<currency: string, priceMicros: string>, originalTaxAmount: record<currency: string, priceMicros: string>, packageName: string, recurringTransaction: record<externalSubscription: record<subscriptionType: string>, externalTransactionToken: string, initialExternalTransactionId: string>, testPurchase: record, transactionState: string, transactionTime: string, userTaxAddress: record<regionCode: string>>"
    androidpublisher-grants-create: "record<appLevelPermissions: list<string>, name: string, packageName: string>"
    androidpublisher-users-list: "record<nextPageToken: string, users: table<accessState: string, developerAccountPermissions: list, email: string, expirationTime: string, grants: list, name: string, partial: bool>>"
    androidpublisher-users-create: "record<accessState: string, developerAccountPermissions: list<string>, email: string, expirationTime: string, grants: table<appLevelPermissions: list, name: string, packageName: string>, name: string, partial: bool>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["androidpublisher-internalappsharingartifacts-uploadapk" "androidpublisher-internalappsharingartifacts-uploadbundle" "androidpublisher-applications-device-tier-configs-list" "androidpublisher-applications-device-tier-configs-create" "androidpublisher-applications-device-tier-configs-get" "androidpublisher-edits-insert" "androidpublisher-edits-delete" "androidpublisher-edits-get" "androidpublisher-edits-apks-list" "androidpublisher-edits-apks-upload" "androidpublisher-edits-apks-addexternallyhosted" "androidpublisher-edits-deobfuscationfiles-upload" "androidpublisher-edits-expansionfiles-get" "androidpublisher-edits-expansionfiles-patch" "androidpublisher-edits-expansionfiles-upload" "androidpublisher-edits-expansionfiles-update" "androidpublisher-edits-bundles-list" "androidpublisher-edits-bundles-upload" "androidpublisher-edits-countryavailability-get" "androidpublisher-edits-details-get" "androidpublisher-edits-details-patch" "androidpublisher-edits-details-update" "androidpublisher-edits-listings-deleteall" "androidpublisher-edits-listings-list" "androidpublisher-edits-listings-delete" "androidpublisher-edits-listings-get" "androidpublisher-edits-listings-patch" "androidpublisher-edits-listings-update" "androidpublisher-edits-images-deleteall" "androidpublisher-edits-images-list" "androidpublisher-edits-images-upload" "androidpublisher-edits-images-delete" "androidpublisher-edits-testers-get" "androidpublisher-edits-testers-patch" "androidpublisher-edits-testers-update" "androidpublisher-edits-tracks-list" "androidpublisher-edits-tracks-get" "androidpublisher-edits-tracks-patch" "androidpublisher-edits-tracks-update" "androidpublisher-edits-commit" "androidpublisher-edits-validate" "androidpublisher-generatedapks-list" "androidpublisher-generatedapks-download" "androidpublisher-inappproducts-list" "androidpublisher-inappproducts-insert" "androidpublisher-inappproducts-delete" "androidpublisher-inappproducts-get" "androidpublisher-inappproducts-patch" "androidpublisher-inappproducts-update" "androidpublisher-orders-refund" "androidpublisher-monetization-convert-region-prices" "androidpublisher-purchases-products-get" "androidpublisher-purchases-products-acknowledge" "androidpublisher-purchases-products-consume" "androidpublisher-purchases-subscriptions-get" "androidpublisher-purchases-subscriptions-acknowledge" "androidpublisher-purchases-subscriptions-cancel" "androidpublisher-purchases-subscriptions-defer" "androidpublisher-purchases-subscriptions-refund" "androidpublisher-purchases-subscriptions-revoke" "androidpublisher-purchases-subscriptionsv2-get" "androidpublisher-purchases-voidedpurchases-list" "androidpublisher-reviews-list" "androidpublisher-reviews-get" "androidpublisher-reviews-reply" "androidpublisher-monetization-subscriptions-list" "androidpublisher-monetization-subscriptions-create" "androidpublisher-monetization-subscriptions-delete" "androidpublisher-monetization-subscriptions-get" "androidpublisher-monetization-subscriptions-patch" "androidpublisher-monetization-subscriptions-base-plans-delete" "androidpublisher-monetization-subscriptions-base-plans-offers-list" "androidpublisher-monetization-subscriptions-base-plans-offers-create" "androidpublisher-monetization-subscriptions-base-plans-offers-delete" "androidpublisher-monetization-subscriptions-base-plans-offers-get" "androidpublisher-monetization-subscriptions-base-plans-offers-patch" "androidpublisher-monetization-subscriptions-base-plans-offers-activate" "androidpublisher-monetization-subscriptions-base-plans-offers-deactivate" "androidpublisher-monetization-subscriptions-base-plans-activate" "androidpublisher-monetization-subscriptions-base-plans-deactivate" "androidpublisher-monetization-subscriptions-base-plans-migrate-prices" "androidpublisher-monetization-subscriptions-archive" "androidpublisher-systemapks-variants-list" "androidpublisher-systemapks-variants-create" "androidpublisher-systemapks-variants-get" "androidpublisher-systemapks-variants-download" "androidpublisher-users-delete" "androidpublisher-externaltransactions-getexternaltransaction" "androidpublisher-users-patch" "androidpublisher-externaltransactions-refundexternaltransaction" "androidpublisher-externaltransactions-createexternaltransaction" "androidpublisher-grants-create" "androidpublisher-users-list" "androidpublisher-users-create" "commands"] | sort) } | get name | first)
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

# Uploads an APK to internal app sharing. If you are using the Google API client libraries, please increase the timeout of the http request before calling this endpoint (a timeout of 2 minutes is recommended). See [Timeouts and Errors](https://developers.google.com/api-client-library/java/google-api-java-client/errors) for an example in java.
#
# POST /androidpublisher/v3/applications/internalappsharing/{packageName}/artifacts/apk
# Returns: record<certificateFingerprint: string, downloadUrl: string, sha256: string>
# operationId: androidpublisher.internalappsharingartifacts.uploadapk
export def "androidpublisher-internalappsharingartifacts-uploadapk" [
  package_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/internalappsharing/{packageName}/artifacts/apk"
    path_params: [{name: packageName, var: package_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uploads an app bundle to internal app sharing. If you are using the Google API client libraries, please increase the timeout of the http request before calling this endpoint (a timeout of 2 minutes is recommended). See [Timeouts and Errors](https://developers.google.com/api-client-library/java/google-api-java-client/errors) for an example in java.
#
# POST /androidpublisher/v3/applications/internalappsharing/{packageName}/artifacts/bundle
# Returns: record<certificateFingerprint: string, downloadUrl: string, sha256: string>
# operationId: androidpublisher.internalappsharingartifacts.uploadbundle
export def "androidpublisher-internalappsharingartifacts-uploadbundle" [
  package_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/internalappsharing/{packageName}/artifacts/bundle"
    path_params: [{name: packageName, var: package_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns created device tier configs, ordered by descending creation time.
#
# GET /androidpublisher/v3/applications/{packageName}/deviceTierConfigs
# Returns: record<deviceTierConfigs: table<deviceGroups: list, deviceTierConfigId: string, deviceTierSet: record, userCountrySets: list>, nextPageToken: string>
# operationId: androidpublisher.applications.deviceTierConfigs.list
export def "androidpublisher-applications-device-tier-configs-list" [
  package_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # The maximum number of device tier configs to return. The service may return fewer than this value. If unspecified, at most 10 device tier configs will be returned. The maximum value for this field is 100; values above 100 will be coerced to 100. Device tier configs will be ordered by descending creation time.
  --page-token: string # A page token, received from a previous `ListDeviceTierConfigs` call. Provide this to retrieve the subsequent page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/androidpublisher/v3/applications/{packageName}/deviceTierConfigs"
    path_params: [{name: packageName, var: package_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new device tier config for an app.
#
# POST /androidpublisher/v3/applications/{packageName}/deviceTierConfigs
# Returns: record<deviceGroups: table<deviceSelectors: list, name: string>, deviceTierConfigId: string, deviceTierSet: record<deviceTiers: list<record>>, userCountrySets: table<countryCodes: list, name: string>>
# operationId: androidpublisher.applications.deviceTierConfigs.create
export def "androidpublisher-applications-device-tier-configs-create" [
  package_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --allow-unknown-devices: oneof<nothing, bool> # Whether the service should accept device IDs that are unknown to Play's device catalog.
  --device-groups: list # Definition of device groups for the app. — item shape: {deviceSelectors?: list, name?: string}
  --device-tier-set: record # A set of device tiers. A tier set determines what variation of app content gets served to a specific device, for device-targeted content. You should assign a priority level to each tier, which determines the ordering by which they are evaluated by Play. See the documentation of DeviceTier.level for more details. — shape: {deviceTiers?: list}
  --user-country-sets: list # Definition of user country sets for the app. — item shape: {countryCodes?: list<string>, name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/androidpublisher/v3/applications/{packageName}/deviceTierConfigs"
    path_params: [{name: packageName, var: package_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: allowUnknownDevices, var: allow_unknown_devices}]
    body: {content_type: "application/json", kind: json, fields: [{name: deviceGroups, var: device_groups}, {name: deviceTierSet, var: device_tier_set}, {name: userCountrySets, var: user_country_sets}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, allow_unknown_devices: $allow_unknown_devices, device_groups: $device_groups, device_tier_set: $device_tier_set, user_country_sets: $user_country_sets
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a particular device tier config.
#
# GET /androidpublisher/v3/applications/{packageName}/deviceTierConfigs/{deviceTierConfigId}
# Returns: record<deviceGroups: table<deviceSelectors: list, name: string>, deviceTierConfigId: string, deviceTierSet: record<deviceTiers: list<record>>, userCountrySets: table<countryCodes: list, name: string>>
# operationId: androidpublisher.applications.deviceTierConfigs.get
export def "androidpublisher-applications-device-tier-configs-get" [
  package_name: string
  device_tier_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/deviceTierConfigs/{deviceTierConfigId}"
    path_params: [{name: packageName, var: package_name}, {name: deviceTierConfigId, var: device_tier_config_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, device_tier_config_id: $device_tier_config_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new edit for an app.
#
# POST /androidpublisher/v3/applications/{packageName}/edits
# Returns: record<expiryTimeSeconds: string, id: string>
# operationId: androidpublisher.edits.insert
export def "androidpublisher-edits-insert" [
  package_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/edits"
    path_params: [{name: packageName, var: package_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an app edit.
#
# DELETE /androidpublisher/v3/applications/{packageName}/edits/{editId}
# operationId: androidpublisher.edits.delete
export def "androidpublisher-edits-delete" [
  package_name: string
  edit_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an app edit.
#
# GET /androidpublisher/v3/applications/{packageName}/edits/{editId}
# Returns: record<expiryTimeSeconds: string, id: string>
# operationId: androidpublisher.edits.get
export def "androidpublisher-edits-get" [
  package_name: string
  edit_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all current APKs of the app and edit.
#
# GET /androidpublisher/v3/applications/{packageName}/edits/{editId}/apks
# Returns: record<apks: table<binary: record, versionCode: int>, kind: string>
# operationId: androidpublisher.edits.apks.list
export def "androidpublisher-edits-apks-list" [
  package_name: string
  edit_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}/apks"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uploads an APK and adds to the current edit.
#
# POST /androidpublisher/v3/applications/{packageName}/edits/{editId}/apks
# Returns: record<binary: record<sha1: string, sha256: string>, versionCode: int>
# operationId: androidpublisher.edits.apks.upload
export def "androidpublisher-edits-apks-upload" [
  package_name: string
  edit_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}/apks"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new APK without uploading the APK itself to Google Play, instead hosting the APK at a specified URL. This function is only available to organizations using Managed Play whose application is configured to restrict distribution to the organizations.
#
# POST /androidpublisher/v3/applications/{packageName}/edits/{editId}/apks/externallyHosted
# Returns: record<externallyHostedApk: record<applicationLabel: string, certificateBase64s: list<string>, externallyHostedUrl: string, fileSha1Base64: string, fileSha256Base64: string, fileSize: string, iconBase64: string, maximumSdk: int, minimumSdk: int, nativeCodes: list<string>, packageName: string, usesFeatures: list<string>, usesPermissions: list<record>, versionCode: int, versionName: string>>
# operationId: androidpublisher.edits.apks.addexternallyhosted
export def "androidpublisher-edits-apks-addexternallyhosted" [
  package_name: string
  edit_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --externally-hosted-apk: record # Defines an APK available for this application that is hosted externally and not uploaded to Google Play. This function is only available to organizations using Managed Play whose application is configured to restrict distribution to the organizations. — shape: {applicationLabel?: string, certificateBase64s?: list<string>, externallyHostedUrl?: string, fileSha1Base64?: string, fileSha256Base64?: string, fileSize?: string, iconBase64?: string, maximumSdk?: int, minimumSdk?: int, nativeCodes?: list<string>, packageName?: string, usesFeatures?: list<string>, usesPermissions?: list, versionCode?: int, versionName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}/apks/externallyHosted"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: externallyHostedApk, var: externally_hosted_apk}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, externally_hosted_apk: $externally_hosted_apk
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uploads a new deobfuscation file and attaches to the specified APK.
#
# POST /androidpublisher/v3/applications/{packageName}/edits/{editId}/apks/{apkVersionCode}/deobfuscationFiles/{deobfuscationFileType}
# Returns: record<deobfuscationFile: record<symbolType: string>>
# operationId: androidpublisher.edits.deobfuscationfiles.upload
export def "androidpublisher-edits-deobfuscationfiles-upload" [
  package_name: string
  edit_id: string
  apk_version_code: int
  deobfuscation_file_type: string@deobfuscation-file-type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}/apks/{apkVersionCode}/deobfuscationFiles/{deobfuscationFileType}"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}, {name: apkVersionCode, var: apk_version_code}, {name: deobfuscationFileType, var: deobfuscation_file_type}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, apk_version_code: $apk_version_code, deobfuscation_file_type: $deobfuscation_file_type, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches the expansion file configuration for the specified APK.
#
# GET /androidpublisher/v3/applications/{packageName}/edits/{editId}/apks/{apkVersionCode}/expansionFiles/{expansionFileType}
# Returns: record<fileSize: string, referencesVersion: int>
# operationId: androidpublisher.edits.expansionfiles.get
export def "androidpublisher-edits-expansionfiles-get" [
  package_name: string
  edit_id: string
  apk_version_code: int
  expansion_file_type: string@expansion-file-type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}/apks/{apkVersionCode}/expansionFiles/{expansionFileType}"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}, {name: apkVersionCode, var: apk_version_code}, {name: expansionFileType, var: expansion_file_type}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, apk_version_code: $apk_version_code, expansion_file_type: $expansion_file_type, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patches the APK's expansion file configuration to reference another APK's expansion file. To add a new expansion file use the Upload method.
#
# PATCH /androidpublisher/v3/applications/{packageName}/edits/{editId}/apks/{apkVersionCode}/expansionFiles/{expansionFileType}
# Returns: record<fileSize: string, referencesVersion: int>
# operationId: androidpublisher.edits.expansionfiles.patch
export def "androidpublisher-edits-expansionfiles-patch" [
  package_name: string
  edit_id: string
  apk_version_code: int
  expansion_file_type: string@expansion-file-type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --file-size: string # If set, this field indicates that this APK has an expansion file uploaded to it: this APK does not reference another APK's expansion file. The field's value is the size of the uploaded expansion file in bytes. (format: int64)
  --references-version: int # If set, this APK's expansion file references another APK's expansion file. The file_size field will not be set. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}/apks/{apkVersionCode}/expansionFiles/{expansionFileType}"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}, {name: apkVersionCode, var: apk_version_code}, {name: expansionFileType, var: expansion_file_type}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: fileSize, var: file_size}, {name: referencesVersion, var: references_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, apk_version_code: $apk_version_code, expansion_file_type: $expansion_file_type, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, file_size: $file_size, references_version: $references_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uploads a new expansion file and attaches to the specified APK.
#
# POST /androidpublisher/v3/applications/{packageName}/edits/{editId}/apks/{apkVersionCode}/expansionFiles/{expansionFileType}
# Returns: record<expansionFile: record<fileSize: string, referencesVersion: int>>
# operationId: androidpublisher.edits.expansionfiles.upload
export def "androidpublisher-edits-expansionfiles-upload" [
  package_name: string
  edit_id: string
  apk_version_code: int
  expansion_file_type: string@expansion-file-type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}/apks/{apkVersionCode}/expansionFiles/{expansionFileType}"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}, {name: apkVersionCode, var: apk_version_code}, {name: expansionFileType, var: expansion_file_type}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, apk_version_code: $apk_version_code, expansion_file_type: $expansion_file_type, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the APK's expansion file configuration to reference another APK's expansion file. To add a new expansion file use the Upload method.
#
# PUT /androidpublisher/v3/applications/{packageName}/edits/{editId}/apks/{apkVersionCode}/expansionFiles/{expansionFileType}
# Returns: record<fileSize: string, referencesVersion: int>
# operationId: androidpublisher.edits.expansionfiles.update
export def "androidpublisher-edits-expansionfiles-update" [
  package_name: string
  edit_id: string
  apk_version_code: int
  expansion_file_type: string@expansion-file-type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --file-size: string # If set, this field indicates that this APK has an expansion file uploaded to it: this APK does not reference another APK's expansion file. The field's value is the size of the uploaded expansion file in bytes. (format: int64)
  --references-version: int # If set, this APK's expansion file references another APK's expansion file. The file_size field will not be set. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}/apks/{apkVersionCode}/expansionFiles/{expansionFileType}"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}, {name: apkVersionCode, var: apk_version_code}, {name: expansionFileType, var: expansion_file_type}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: fileSize, var: file_size}, {name: referencesVersion, var: references_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, apk_version_code: $apk_version_code, expansion_file_type: $expansion_file_type, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, file_size: $file_size, references_version: $references_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all current Android App Bundles of the app and edit.
#
# GET /androidpublisher/v3/applications/{packageName}/edits/{editId}/bundles
# Returns: record<bundles: table<sha1: string, sha256: string, versionCode: int>, kind: string>
# operationId: androidpublisher.edits.bundles.list
export def "androidpublisher-edits-bundles-list" [
  package_name: string
  edit_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}/bundles"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uploads a new Android App Bundle to this edit. If you are using the Google API client libraries, please increase the timeout of the http request before calling this endpoint (a timeout of 2 minutes is recommended). See [Timeouts and Errors](https://developers.google.com/api-client-library/java/google-api-java-client/errors) for an example in java.
#
# POST /androidpublisher/v3/applications/{packageName}/edits/{editId}/bundles
# Returns: record<sha1: string, sha256: string, versionCode: int>
# operationId: androidpublisher.edits.bundles.upload
export def "androidpublisher-edits-bundles-upload" [
  package_name: string
  edit_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --ack-bundle-installation-warning: oneof<nothing, bool> # Must be set to true if the app bundle installation may trigger a warning on user devices (for example, if installation size may be over a threshold, typically 100 MB).
  --device-tier-config-id: string # Device tier config (DTC) to be used for generating deliverables (APKs). Contains id of the DTC or "LATEST" for last uploaded DTC.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}/bundles"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: ackBundleInstallationWarning, var: ack_bundle_installation_warning}, {name: deviceTierConfigId, var: device_tier_config_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, ack_bundle_installation_warning: $ack_bundle_installation_warning, device_tier_config_id: $device_tier_config_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets country availability.
#
# GET /androidpublisher/v3/applications/{packageName}/edits/{editId}/countryAvailability/{track}
# Returns: record<countries: table<countryCode: string>, restOfWorld: bool, syncWithProduction: bool>
# operationId: androidpublisher.edits.countryavailability.get
export def "androidpublisher-edits-countryavailability-get" [
  package_name: string
  edit_id: string
  track: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}/countryAvailability/{track}"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}, {name: track, var: track}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, track: $track, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets details of an app.
#
# GET /androidpublisher/v3/applications/{packageName}/edits/{editId}/details
# Returns: record<contactEmail: string, contactPhone: string, contactWebsite: string, defaultLanguage: string>
# operationId: androidpublisher.edits.details.get
export def "androidpublisher-edits-details-get" [
  package_name: string
  edit_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}/details"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patches details of an app.
#
# PATCH /androidpublisher/v3/applications/{packageName}/edits/{editId}/details
# Returns: record<contactEmail: string, contactPhone: string, contactWebsite: string, defaultLanguage: string>
# operationId: androidpublisher.edits.details.patch
export def "androidpublisher-edits-details-patch" [
  package_name: string
  edit_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --contact-email: string # The user-visible support email for this app.
  --contact-phone: string # The user-visible support telephone number for this app.
  --contact-website: string # The user-visible website for this app.
  --default-language: string # Default language code, in BCP 47 format (eg "en-US").
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}/details"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: contactEmail, var: contact_email}, {name: contactPhone, var: contact_phone}, {name: contactWebsite, var: contact_website}, {name: defaultLanguage, var: default_language}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, contact_email: $contact_email, contact_phone: $contact_phone, contact_website: $contact_website, default_language: $default_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates details of an app.
#
# PUT /androidpublisher/v3/applications/{packageName}/edits/{editId}/details
# Returns: record<contactEmail: string, contactPhone: string, contactWebsite: string, defaultLanguage: string>
# operationId: androidpublisher.edits.details.update
export def "androidpublisher-edits-details-update" [
  package_name: string
  edit_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --contact-email: string # The user-visible support email for this app.
  --contact-phone: string # The user-visible support telephone number for this app.
  --contact-website: string # The user-visible website for this app.
  --default-language: string # Default language code, in BCP 47 format (eg "en-US").
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}/details"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: contactEmail, var: contact_email}, {name: contactPhone, var: contact_phone}, {name: contactWebsite, var: contact_website}, {name: defaultLanguage, var: default_language}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, contact_email: $contact_email, contact_phone: $contact_phone, contact_website: $contact_website, default_language: $default_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes all store listings.
#
# DELETE /androidpublisher/v3/applications/{packageName}/edits/{editId}/listings
# operationId: androidpublisher.edits.listings.deleteall
export def "androidpublisher-edits-listings-deleteall" [
  package_name: string
  edit_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}/listings"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all localized store listings.
#
# GET /androidpublisher/v3/applications/{packageName}/edits/{editId}/listings
# Returns: record<kind: string, listings: table<fullDescription: string, language: string, shortDescription: string, title: string, video: string>>
# operationId: androidpublisher.edits.listings.list
export def "androidpublisher-edits-listings-list" [
  package_name: string
  edit_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}/listings"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a localized store listing.
#
# DELETE /androidpublisher/v3/applications/{packageName}/edits/{editId}/listings/{language}
# operationId: androidpublisher.edits.listings.delete
export def "androidpublisher-edits-listings-delete" [
  package_name: string
  edit_id: string
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}/listings/{language}"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}, {name: language, var: language}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, language: $language, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a localized store listing.
#
# GET /androidpublisher/v3/applications/{packageName}/edits/{editId}/listings/{language}
# Returns: record<fullDescription: string, language: string, shortDescription: string, title: string, video: string>
# operationId: androidpublisher.edits.listings.get
export def "androidpublisher-edits-listings-get" [
  package_name: string
  edit_id: string
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}/listings/{language}"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}, {name: language, var: language}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, language: $language, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patches a localized store listing.
#
# PATCH /androidpublisher/v3/applications/{packageName}/edits/{editId}/listings/{language}
# Returns: record<fullDescription: string, language: string, shortDescription: string, title: string, video: string>
# operationId: androidpublisher.edits.listings.patch
export def "androidpublisher-edits-listings-patch" [
  package_name: string
  edit_id: string
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --full-description: string # Full description of the app.
  --body-language: string # Language localization code (a BCP-47 language tag; for example, "de-AT" for Austrian German). (spec name: language)
  --short-description: string # Short description of the app.
  --title: string # Localized title of the app.
  --video: string # URL of a promotional YouTube video for the app.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}/listings/{language}"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}, {name: language, var: language}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: fullDescription, var: full_description}, {name: language, var: body_language}, {name: shortDescription, var: short_description}, {name: title, var: title}, {name: video, var: video}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, language: $language, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, full_description: $full_description, body_language: $body_language, short_description: $short_description, title: $title, video: $video
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates a localized store listing.
#
# PUT /androidpublisher/v3/applications/{packageName}/edits/{editId}/listings/{language}
# Returns: record<fullDescription: string, language: string, shortDescription: string, title: string, video: string>
# operationId: androidpublisher.edits.listings.update
export def "androidpublisher-edits-listings-update" [
  package_name: string
  edit_id: string
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --full-description: string # Full description of the app.
  --body-language: string # Language localization code (a BCP-47 language tag; for example, "de-AT" for Austrian German). (spec name: language)
  --short-description: string # Short description of the app.
  --title: string # Localized title of the app.
  --video: string # URL of a promotional YouTube video for the app.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}/listings/{language}"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}, {name: language, var: language}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: fullDescription, var: full_description}, {name: language, var: body_language}, {name: shortDescription, var: short_description}, {name: title, var: title}, {name: video, var: video}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, language: $language, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, full_description: $full_description, body_language: $body_language, short_description: $short_description, title: $title, video: $video
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes all images for the specified language and image type. Returns an empty response if no images are found.
#
# DELETE /androidpublisher/v3/applications/{packageName}/edits/{editId}/listings/{language}/{imageType}
# Returns: record<deleted: table<id: string, sha1: string, sha256: string, url: string>>
# operationId: androidpublisher.edits.images.deleteall
export def "androidpublisher-edits-images-deleteall" [
  package_name: string
  edit_id: string
  language: string
  image_type: string@image-type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    method: delete
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}/listings/{language}/{imageType}"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}, {name: language, var: language}, {name: imageType, var: image_type}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, language: $language, image_type: $image_type, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all images. The response may be empty.
#
# GET /androidpublisher/v3/applications/{packageName}/edits/{editId}/listings/{language}/{imageType}
# Returns: record<images: table<id: string, sha1: string, sha256: string, url: string>>
# operationId: androidpublisher.edits.images.list
export def "androidpublisher-edits-images-list" [
  package_name: string
  edit_id: string
  language: string
  image_type: string@image-type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}/listings/{language}/{imageType}"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}, {name: language, var: language}, {name: imageType, var: image_type}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, language: $language, image_type: $image_type, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uploads an image of the specified language and image type, and adds to the edit.
#
# POST /androidpublisher/v3/applications/{packageName}/edits/{editId}/listings/{language}/{imageType}
# Returns: record<image: record<id: string, sha1: string, sha256: string, url: string>>
# operationId: androidpublisher.edits.images.upload
export def "androidpublisher-edits-images-upload" [
  package_name: string
  edit_id: string
  language: string
  image_type: string@image-type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}/listings/{language}/{imageType}"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}, {name: language, var: language}, {name: imageType, var: image_type}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, language: $language, image_type: $image_type, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the image (specified by id) from the edit.
#
# DELETE /androidpublisher/v3/applications/{packageName}/edits/{editId}/listings/{language}/{imageType}/{imageId}
# operationId: androidpublisher.edits.images.delete
export def "androidpublisher-edits-images-delete" [
  package_name: string
  edit_id: string
  language: string
  image_type: string@image-type-completer
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}/listings/{language}/{imageType}/{imageId}"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}, {name: language, var: language}, {name: imageType, var: image_type}, {name: imageId, var: image_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, language: $language, image_type: $image_type, image_id: $image_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets testers. Note: Testers resource does not support email lists.
#
# GET /androidpublisher/v3/applications/{packageName}/edits/{editId}/testers/{track}
# Returns: record<googleGroups: list<string>>
# operationId: androidpublisher.edits.testers.get
export def "androidpublisher-edits-testers-get" [
  package_name: string
  edit_id: string
  track: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}/testers/{track}"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}, {name: track, var: track}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, track: $track, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patches testers. Note: Testers resource does not support email lists.
#
# PATCH /androidpublisher/v3/applications/{packageName}/edits/{editId}/testers/{track}
# Returns: record<googleGroups: list<string>>
# operationId: androidpublisher.edits.testers.patch
export def "androidpublisher-edits-testers-patch" [
  package_name: string
  edit_id: string
  track: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --google-groups: list<string> # All testing Google Groups, as email addresses.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}/testers/{track}"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}, {name: track, var: track}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: googleGroups, var: google_groups}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, track: $track, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, google_groups: $google_groups
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates testers. Note: Testers resource does not support email lists.
#
# PUT /androidpublisher/v3/applications/{packageName}/edits/{editId}/testers/{track}
# Returns: record<googleGroups: list<string>>
# operationId: androidpublisher.edits.testers.update
export def "androidpublisher-edits-testers-update" [
  package_name: string
  edit_id: string
  track: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --google-groups: list<string> # All testing Google Groups, as email addresses.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}/testers/{track}"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}, {name: track, var: track}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: googleGroups, var: google_groups}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, track: $track, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, google_groups: $google_groups
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all tracks.
#
# GET /androidpublisher/v3/applications/{packageName}/edits/{editId}/tracks
# Returns: record<kind: string, tracks: table<releases: list, track: string>>
# operationId: androidpublisher.edits.tracks.list
export def "androidpublisher-edits-tracks-list" [
  package_name: string
  edit_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}/tracks"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a track.
#
# GET /androidpublisher/v3/applications/{packageName}/edits/{editId}/tracks/{track}
# Returns: record<releases: table<countryTargeting: record, inAppUpdatePriority: int, name: string, releaseNotes: list, status: string, userFraction: float, versionCodes: list>, track: string>
# operationId: androidpublisher.edits.tracks.get
export def "androidpublisher-edits-tracks-get" [
  package_name: string
  edit_id: string
  track: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}/tracks/{track}"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}, {name: track, var: track}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, track: $track, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patches a track.
#
# PATCH /androidpublisher/v3/applications/{packageName}/edits/{editId}/tracks/{track}
# Returns: record<releases: table<countryTargeting: record, inAppUpdatePriority: int, name: string, releaseNotes: list, status: string, userFraction: float, versionCodes: list>, track: string>
# operationId: androidpublisher.edits.tracks.patch
export def "androidpublisher-edits-tracks-patch" [
  package_name: string
  edit_id: string
  track: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --releases: list # In a read request, represents all active releases in the track. In an update request, represents desired changes. — item shape: {countryTargeting?: record, inAppUpdatePriority?: int, name?: string, releaseNotes?: list, status?: "statusUnspecified"|"draft"|"inProgress"|"halted"|"completed", userFraction?: float, versionCodes?: list<string>}
  --body-track: string # Identifier of the track. Form factor tracks have a special prefix as an identifier, for example `wear:production`, `automotive:production`. [More on track name](https://developers.google.com/android-publisher/tracks#ff-track-name) (spec name: track)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}/tracks/{track}"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}, {name: track, var: track}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: releases, var: releases}, {name: track, var: body_track}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, track: $track, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, releases: $releases, body_track: $body_track
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a track.
#
# PUT /androidpublisher/v3/applications/{packageName}/edits/{editId}/tracks/{track}
# Returns: record<releases: table<countryTargeting: record, inAppUpdatePriority: int, name: string, releaseNotes: list, status: string, userFraction: float, versionCodes: list>, track: string>
# operationId: androidpublisher.edits.tracks.update
export def "androidpublisher-edits-tracks-update" [
  package_name: string
  edit_id: string
  track: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --releases: list # In a read request, represents all active releases in the track. In an update request, represents desired changes. — item shape: {countryTargeting?: record, inAppUpdatePriority?: int, name?: string, releaseNotes?: list, status?: "statusUnspecified"|"draft"|"inProgress"|"halted"|"completed", userFraction?: float, versionCodes?: list<string>}
  --body-track: string # Identifier of the track. Form factor tracks have a special prefix as an identifier, for example `wear:production`, `automotive:production`. [More on track name](https://developers.google.com/android-publisher/tracks#ff-track-name) (spec name: track)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}/tracks/{track}"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}, {name: track, var: track}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: releases, var: releases}, {name: track, var: body_track}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, track: $track, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, releases: $releases, body_track: $body_track
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Commits an app edit.
#
# POST /androidpublisher/v3/applications/{packageName}/edits/{editId}:commit
# Returns: record<expiryTimeSeconds: string, id: string>
# operationId: androidpublisher.edits.commit
export def "androidpublisher-edits-commit" [
  package_name: string
  edit_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --changes-not-sent-for-review: oneof<nothing, bool> # Indicates that the changes in this edit will not be reviewed until they are explicitly sent for review from the Google Play Console UI. These changes will be added to any other changes that are not yet sent for review.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}:commit"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: changesNotSentForReview, var: changes_not_sent_for_review}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, changes_not_sent_for_review: $changes_not_sent_for_review
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validates an app edit.
#
# POST /androidpublisher/v3/applications/{packageName}/edits/{editId}:validate
# Returns: record<expiryTimeSeconds: string, id: string>
# operationId: androidpublisher.edits.validate
export def "androidpublisher-edits-validate" [
  package_name: string
  edit_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/edits/{editId}:validate"
    path_params: [{name: packageName, var: package_name}, {name: editId, var: edit_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, edit_id: $edit_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns download metadata for all APKs that were generated from a given app bundle.
#
# GET /androidpublisher/v3/applications/{packageName}/generatedApks/{versionCode}
# Returns: record<generatedApks: table<certificateSha256Hash: string, generatedAssetPackSlices: list, generatedSplitApks: list, generatedStandaloneApks: list, generatedUniversalApk: record>>
# operationId: androidpublisher.generatedapks.list
export def "androidpublisher-generatedapks-list" [
  package_name: string
  version_code: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/generatedApks/{versionCode}"
    path_params: [{name: packageName, var: package_name}, {name: versionCode, var: version_code}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, version_code: $version_code, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Downloads a single signed APK generated from an app bundle.
#
# GET /androidpublisher/v3/applications/{packageName}/generatedApks/{versionCode}/downloads/{downloadId}:download
# operationId: androidpublisher.generatedapks.download
export def "androidpublisher-generatedapks-download" [
  package_name: string
  version_code: int
  download_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    method: get
    path: "/androidpublisher/v3/applications/{packageName}/generatedApks/{versionCode}/downloads/{downloadId}:download"
    path_params: [{name: packageName, var: package_name}, {name: versionCode, var: version_code}, {name: downloadId, var: download_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, version_code: $version_code, download_id: $download_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all in-app products - both managed products and subscriptions. If an app has a large number of in-app products, the response may be paginated. In this case the response field `tokenPagination.nextPageToken` will be set and the caller should provide its value as a `token` request parameter to retrieve the next page.
#
# GET /androidpublisher/v3/applications/{packageName}/inappproducts
# Returns: record<inappproduct: table<defaultLanguage: string, defaultPrice: record, gracePeriod: string, listings: record, managedProductTaxesAndComplianceSettings: record, packageName: string, prices: record, purchaseType: string, sku: string, status: string, subscriptionPeriod: string, subscriptionTaxesAndComplianceSettings: record, trialPeriod: string>, kind: string, pageInfo: record<resultPerPage: int, startIndex: int, totalResults: int>, tokenPagination: record<nextPageToken: string, previousPageToken: string>>
# operationId: androidpublisher.inappproducts.list
export def "androidpublisher-inappproducts-list" [
  package_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --max-results: int # Deprecated and ignored. The page size is determined by the server.
  --start-index: int # Deprecated and ignored. Set the `token` parameter to retrieve the next page.
  --qp-token: string # Pagination token. If empty, list starts at the first product. (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/androidpublisher/v3/applications/{packageName}/inappproducts"
    path_params: [{name: packageName, var: package_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: maxResults, var: max_results}, {name: startIndex, var: start_index}, {name: token, var: qp_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, max_results: $max_results, start_index: $start_index, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an in-app product (i.e. a managed product or a subscription).
#
# POST /androidpublisher/v3/applications/{packageName}/inappproducts
# Returns: record<defaultLanguage: string, defaultPrice: record<currency: string, priceMicros: string>, gracePeriod: string, listings: record, managedProductTaxesAndComplianceSettings: record<eeaWithdrawalRightType: string, taxRateInfoByRegionCode: record>, packageName: string, prices: record, purchaseType: string, sku: string, status: string, subscriptionPeriod: string, subscriptionTaxesAndComplianceSettings: record<eeaWithdrawalRightType: string, taxRateInfoByRegionCode: record>, trialPeriod: string>
# operationId: androidpublisher.inappproducts.insert
export def "androidpublisher-inappproducts-insert" [
  package_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --auto-convert-missing-prices: oneof<nothing, bool> # If true the prices for all regions targeted by the parent app that don't have a price specified for this in-app product will be auto converted to the target currency based on the default price. Defaults to false.
  --default-language: string # Default language of the localized data, as defined by BCP-47. e.g. "en-US".
  --default-price: record # Definition of a price, i.e. currency and units. — shape: {currency?: string, priceMicros?: string}
  --grace-period: string # Grace period of the subscription, specified in ISO 8601 format. Allows developers to give their subscribers a grace period when the payment for the new recurrence period is declined. Acceptable values are P0D (zero days), P3D (three days), P7D (seven days), P14D (14 days), and P30D (30 days).
  --listings: record # List of localized title and description data. Map key is the language of the localized data, as defined by BCP-47, e.g. "en-US".
  --managed-product-taxes-and-compliance-settings: record # Details about taxation and legal compliance for managed products. — shape: {eeaWithdrawalRightType?: "WITHDRAWAL_RIGHT_TYPE_UNSPECIFIED"|"WITHDRAWAL_RIGHT_DIGITAL_CONTENT"|"WITHDRAWAL_RIGHT_SERVICE", taxRateInfoByRegionCode?: record}
  --body-package-name: string # Package name of the parent app. (spec name: packageName)
  --prices: record # Prices per buyer region. None of these can be zero, as in-app products are never free. Map key is region code, as defined by ISO 3166-2.
  --purchase-type: string@purchase-type-completer # The type of the product, e.g. a recurring subscription.
  --sku: string # Stock-keeping-unit (SKU) of the product, unique within an app.
  --status: string@status-completer # The status of the product, e.g. whether it's active.
  --subscription-period: string # Subscription period, specified in ISO 8601 format. Acceptable values are P1W (one week), P1M (one month), P3M (three months), P6M (six months), and P1Y (one year).
  --subscription-taxes-and-compliance-settings: record # Details about taxation, Google Play policy and legal compliance for subscription products. — shape: {eeaWithdrawalRightType?: "WITHDRAWAL_RIGHT_TYPE_UNSPECIFIED"|"WITHDRAWAL_RIGHT_DIGITAL_CONTENT"|"WITHDRAWAL_RIGHT_SERVICE", taxRateInfoByRegionCode?: record}
  --trial-period: string # Trial period, specified in ISO 8601 format. Acceptable values are anything between P7D (seven days) and P999D (999 days).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/androidpublisher/v3/applications/{packageName}/inappproducts"
    path_params: [{name: packageName, var: package_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: autoConvertMissingPrices, var: auto_convert_missing_prices}]
    body: {content_type: "application/json", kind: json, fields: [{name: defaultLanguage, var: default_language}, {name: defaultPrice, var: default_price}, {name: gracePeriod, var: grace_period}, {name: listings, var: listings}, {name: managedProductTaxesAndComplianceSettings, var: managed_product_taxes_and_compliance_settings}, {name: packageName, var: body_package_name}, {name: prices, var: prices}, {name: purchaseType, var: purchase_type}, {name: sku, var: sku}, {name: status, var: status}, {name: subscriptionPeriod, var: subscription_period}, {name: subscriptionTaxesAndComplianceSettings, var: subscription_taxes_and_compliance_settings}, {name: trialPeriod, var: trial_period}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, auto_convert_missing_prices: $auto_convert_missing_prices, default_language: $default_language, default_price: $default_price, grace_period: $grace_period, listings: $listings, managed_product_taxes_and_compliance_settings: $managed_product_taxes_and_compliance_settings, body_package_name: $body_package_name, prices: $prices, purchase_type: $purchase_type, sku: $sku, status: $status, subscription_period: $subscription_period, subscription_taxes_and_compliance_settings: $subscription_taxes_and_compliance_settings, trial_period: $trial_period
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an in-app product (i.e. a managed product or a subscription).
#
# DELETE /androidpublisher/v3/applications/{packageName}/inappproducts/{sku}
# operationId: androidpublisher.inappproducts.delete
export def "androidpublisher-inappproducts-delete" [
  package_name: string
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/inappproducts/{sku}"
    path_params: [{name: packageName, var: package_name}, {name: sku, var: sku}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, sku: $sku, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an in-app product, which can be a managed product or a subscription.
#
# GET /androidpublisher/v3/applications/{packageName}/inappproducts/{sku}
# Returns: record<defaultLanguage: string, defaultPrice: record<currency: string, priceMicros: string>, gracePeriod: string, listings: record, managedProductTaxesAndComplianceSettings: record<eeaWithdrawalRightType: string, taxRateInfoByRegionCode: record>, packageName: string, prices: record, purchaseType: string, sku: string, status: string, subscriptionPeriod: string, subscriptionTaxesAndComplianceSettings: record<eeaWithdrawalRightType: string, taxRateInfoByRegionCode: record>, trialPeriod: string>
# operationId: androidpublisher.inappproducts.get
export def "androidpublisher-inappproducts-get" [
  package_name: string
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/inappproducts/{sku}"
    path_params: [{name: packageName, var: package_name}, {name: sku, var: sku}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, sku: $sku, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patches an in-app product (i.e. a managed product or a subscription).
#
# PATCH /androidpublisher/v3/applications/{packageName}/inappproducts/{sku}
# Returns: record<defaultLanguage: string, defaultPrice: record<currency: string, priceMicros: string>, gracePeriod: string, listings: record, managedProductTaxesAndComplianceSettings: record<eeaWithdrawalRightType: string, taxRateInfoByRegionCode: record>, packageName: string, prices: record, purchaseType: string, sku: string, status: string, subscriptionPeriod: string, subscriptionTaxesAndComplianceSettings: record<eeaWithdrawalRightType: string, taxRateInfoByRegionCode: record>, trialPeriod: string>
# operationId: androidpublisher.inappproducts.patch
export def "androidpublisher-inappproducts-patch" [
  package_name: string
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --auto-convert-missing-prices: oneof<nothing, bool> # If true the prices for all regions targeted by the parent app that don't have a price specified for this in-app product will be auto converted to the target currency based on the default price. Defaults to false.
  --default-language: string # Default language of the localized data, as defined by BCP-47. e.g. "en-US".
  --default-price: record # Definition of a price, i.e. currency and units. — shape: {currency?: string, priceMicros?: string}
  --grace-period: string # Grace period of the subscription, specified in ISO 8601 format. Allows developers to give their subscribers a grace period when the payment for the new recurrence period is declined. Acceptable values are P0D (zero days), P3D (three days), P7D (seven days), P14D (14 days), and P30D (30 days).
  --listings: record # List of localized title and description data. Map key is the language of the localized data, as defined by BCP-47, e.g. "en-US".
  --managed-product-taxes-and-compliance-settings: record # Details about taxation and legal compliance for managed products. — shape: {eeaWithdrawalRightType?: "WITHDRAWAL_RIGHT_TYPE_UNSPECIFIED"|"WITHDRAWAL_RIGHT_DIGITAL_CONTENT"|"WITHDRAWAL_RIGHT_SERVICE", taxRateInfoByRegionCode?: record}
  --body-package-name: string # Package name of the parent app. (spec name: packageName)
  --prices: record # Prices per buyer region. None of these can be zero, as in-app products are never free. Map key is region code, as defined by ISO 3166-2.
  --purchase-type: string@purchase-type-completer # The type of the product, e.g. a recurring subscription.
  --body-sku: string # Stock-keeping-unit (SKU) of the product, unique within an app. (spec name: sku)
  --status: string@status-completer # The status of the product, e.g. whether it's active.
  --subscription-period: string # Subscription period, specified in ISO 8601 format. Acceptable values are P1W (one week), P1M (one month), P3M (three months), P6M (six months), and P1Y (one year).
  --subscription-taxes-and-compliance-settings: record # Details about taxation, Google Play policy and legal compliance for subscription products. — shape: {eeaWithdrawalRightType?: "WITHDRAWAL_RIGHT_TYPE_UNSPECIFIED"|"WITHDRAWAL_RIGHT_DIGITAL_CONTENT"|"WITHDRAWAL_RIGHT_SERVICE", taxRateInfoByRegionCode?: record}
  --trial-period: string # Trial period, specified in ISO 8601 format. Acceptable values are anything between P7D (seven days) and P999D (999 days).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/androidpublisher/v3/applications/{packageName}/inappproducts/{sku}"
    path_params: [{name: packageName, var: package_name}, {name: sku, var: sku}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: autoConvertMissingPrices, var: auto_convert_missing_prices}]
    body: {content_type: "application/json", kind: json, fields: [{name: defaultLanguage, var: default_language}, {name: defaultPrice, var: default_price}, {name: gracePeriod, var: grace_period}, {name: listings, var: listings}, {name: managedProductTaxesAndComplianceSettings, var: managed_product_taxes_and_compliance_settings}, {name: packageName, var: body_package_name}, {name: prices, var: prices}, {name: purchaseType, var: purchase_type}, {name: sku, var: body_sku}, {name: status, var: status}, {name: subscriptionPeriod, var: subscription_period}, {name: subscriptionTaxesAndComplianceSettings, var: subscription_taxes_and_compliance_settings}, {name: trialPeriod, var: trial_period}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, sku: $sku, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, auto_convert_missing_prices: $auto_convert_missing_prices, default_language: $default_language, default_price: $default_price, grace_period: $grace_period, listings: $listings, managed_product_taxes_and_compliance_settings: $managed_product_taxes_and_compliance_settings, body_package_name: $body_package_name, prices: $prices, purchase_type: $purchase_type, body_sku: $body_sku, status: $status, subscription_period: $subscription_period, subscription_taxes_and_compliance_settings: $subscription_taxes_and_compliance_settings, trial_period: $trial_period
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an in-app product (i.e. a managed product or a subscription).
#
# PUT /androidpublisher/v3/applications/{packageName}/inappproducts/{sku}
# Returns: record<defaultLanguage: string, defaultPrice: record<currency: string, priceMicros: string>, gracePeriod: string, listings: record, managedProductTaxesAndComplianceSettings: record<eeaWithdrawalRightType: string, taxRateInfoByRegionCode: record>, packageName: string, prices: record, purchaseType: string, sku: string, status: string, subscriptionPeriod: string, subscriptionTaxesAndComplianceSettings: record<eeaWithdrawalRightType: string, taxRateInfoByRegionCode: record>, trialPeriod: string>
# operationId: androidpublisher.inappproducts.update
export def "androidpublisher-inappproducts-update" [
  package_name: string
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --allow-missing: oneof<nothing, bool> # If set to true, and the in-app product with the given package_name and sku doesn't exist, the in-app product will be created.
  --auto-convert-missing-prices: oneof<nothing, bool> # If true the prices for all regions targeted by the parent app that don't have a price specified for this in-app product will be auto converted to the target currency based on the default price. Defaults to false.
  --default-language: string # Default language of the localized data, as defined by BCP-47. e.g. "en-US".
  --default-price: record # Definition of a price, i.e. currency and units. — shape: {currency?: string, priceMicros?: string}
  --grace-period: string # Grace period of the subscription, specified in ISO 8601 format. Allows developers to give their subscribers a grace period when the payment for the new recurrence period is declined. Acceptable values are P0D (zero days), P3D (three days), P7D (seven days), P14D (14 days), and P30D (30 days).
  --listings: record # List of localized title and description data. Map key is the language of the localized data, as defined by BCP-47, e.g. "en-US".
  --managed-product-taxes-and-compliance-settings: record # Details about taxation and legal compliance for managed products. — shape: {eeaWithdrawalRightType?: "WITHDRAWAL_RIGHT_TYPE_UNSPECIFIED"|"WITHDRAWAL_RIGHT_DIGITAL_CONTENT"|"WITHDRAWAL_RIGHT_SERVICE", taxRateInfoByRegionCode?: record}
  --body-package-name: string # Package name of the parent app. (spec name: packageName)
  --prices: record # Prices per buyer region. None of these can be zero, as in-app products are never free. Map key is region code, as defined by ISO 3166-2.
  --purchase-type: string@purchase-type-completer # The type of the product, e.g. a recurring subscription.
  --body-sku: string # Stock-keeping-unit (SKU) of the product, unique within an app. (spec name: sku)
  --status: string@status-completer # The status of the product, e.g. whether it's active.
  --subscription-period: string # Subscription period, specified in ISO 8601 format. Acceptable values are P1W (one week), P1M (one month), P3M (three months), P6M (six months), and P1Y (one year).
  --subscription-taxes-and-compliance-settings: record # Details about taxation, Google Play policy and legal compliance for subscription products. — shape: {eeaWithdrawalRightType?: "WITHDRAWAL_RIGHT_TYPE_UNSPECIFIED"|"WITHDRAWAL_RIGHT_DIGITAL_CONTENT"|"WITHDRAWAL_RIGHT_SERVICE", taxRateInfoByRegionCode?: record}
  --trial-period: string # Trial period, specified in ISO 8601 format. Acceptable values are anything between P7D (seven days) and P999D (999 days).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/androidpublisher/v3/applications/{packageName}/inappproducts/{sku}"
    path_params: [{name: packageName, var: package_name}, {name: sku, var: sku}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: allowMissing, var: allow_missing}, {name: autoConvertMissingPrices, var: auto_convert_missing_prices}]
    body: {content_type: "application/json", kind: json, fields: [{name: defaultLanguage, var: default_language}, {name: defaultPrice, var: default_price}, {name: gracePeriod, var: grace_period}, {name: listings, var: listings}, {name: managedProductTaxesAndComplianceSettings, var: managed_product_taxes_and_compliance_settings}, {name: packageName, var: body_package_name}, {name: prices, var: prices}, {name: purchaseType, var: purchase_type}, {name: sku, var: body_sku}, {name: status, var: status}, {name: subscriptionPeriod, var: subscription_period}, {name: subscriptionTaxesAndComplianceSettings, var: subscription_taxes_and_compliance_settings}, {name: trialPeriod, var: trial_period}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, sku: $sku, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, allow_missing: $allow_missing, auto_convert_missing_prices: $auto_convert_missing_prices, default_language: $default_language, default_price: $default_price, grace_period: $grace_period, listings: $listings, managed_product_taxes_and_compliance_settings: $managed_product_taxes_and_compliance_settings, body_package_name: $body_package_name, prices: $prices, purchase_type: $purchase_type, body_sku: $body_sku, status: $status, subscription_period: $subscription_period, subscription_taxes_and_compliance_settings: $subscription_taxes_and_compliance_settings, trial_period: $trial_period
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Refunds a user's subscription or in-app purchase order. Orders older than 1 year cannot be refunded.
#
# POST /androidpublisher/v3/applications/{packageName}/orders/{orderId}:refund
# operationId: androidpublisher.orders.refund
export def "androidpublisher-orders-refund" [
  package_name: string
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
  --revoke: oneof<nothing, bool> # Whether to revoke the purchased item. If set to true, access to the subscription or in-app item will be terminated immediately. If the item is a recurring subscription, all future payments will also be terminated. Consumed in-app items need to be handled by developer's app. (optional).
]: nothing -> any {
  http-request {
    method: post
    path: "/androidpublisher/v3/applications/{packageName}/orders/{orderId}:refund"
    path_params: [{name: packageName, var: package_name}, {name: orderId, var: order_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: revoke, var: revoke}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, order_id: $order_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, revoke: $revoke
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Calculates the region prices, using today's exchange rate and country-specific pricing patterns, based on the price in the request for a set of regions.
#
# POST /androidpublisher/v3/applications/{packageName}/pricing:convertRegionPrices
# Returns: record<convertedOtherRegionsPrice: record<eurPrice: record<currencyCode: string, nanos: int, units: string>, usdPrice: record<currencyCode: string, nanos: int, units: string>>, convertedRegionPrices: record>
# operationId: androidpublisher.monetization.convertRegionPrices
export def "androidpublisher-monetization-convert-region-prices" [
  package_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --price: record # Represents an amount of money with its currency type. — shape: {currencyCode?: string, nanos?: int, units?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/androidpublisher/v3/applications/{packageName}/pricing:convertRegionPrices"
    path_params: [{name: packageName, var: package_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: price, var: price}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, price: $price
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks the purchase and consumption status of an inapp item.
#
# GET /androidpublisher/v3/applications/{packageName}/purchases/products/{productId}/tokens/{token}
# Returns: record<acknowledgementState: int, consumptionState: int, developerPayload: string, kind: string, obfuscatedExternalAccountId: string, obfuscatedExternalProfileId: string, orderId: string, productId: string, purchaseState: int, purchaseTimeMillis: string, purchaseToken: string, purchaseType: int, quantity: int, regionCode: string>
# operationId: androidpublisher.purchases.products.get
export def "androidpublisher-purchases-products-get" [
  package_name: string
  product_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/purchases/products/{productId}/tokens/{token}"
    path_params: [{name: packageName, var: package_name}, {name: productId, var: product_id}, {name: token, var: token_arg}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, product_id: $product_id, token_arg: $token_arg, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Acknowledges a purchase of an inapp item.
#
# POST /androidpublisher/v3/applications/{packageName}/purchases/products/{productId}/tokens/{token}:acknowledge
# operationId: androidpublisher.purchases.products.acknowledge
export def "androidpublisher-purchases-products-acknowledge" [
  package_name: string
  product_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --developer-payload: string # Payload to attach to the purchase.
]: any -> any {
  $in | http-request {
    method: post
    path: "/androidpublisher/v3/applications/{packageName}/purchases/products/{productId}/tokens/{token}:acknowledge"
    path_params: [{name: packageName, var: package_name}, {name: productId, var: product_id}, {name: token, var: token_arg}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: developerPayload, var: developer_payload}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, product_id: $product_id, token_arg: $token_arg, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, developer_payload: $developer_payload
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Consumes a purchase for an inapp item.
#
# POST /androidpublisher/v3/applications/{packageName}/purchases/products/{productId}/tokens/{token}:consume
# operationId: androidpublisher.purchases.products.consume
export def "androidpublisher-purchases-products-consume" [
  package_name: string
  product_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    method: post
    path: "/androidpublisher/v3/applications/{packageName}/purchases/products/{productId}/tokens/{token}:consume"
    path_params: [{name: packageName, var: package_name}, {name: productId, var: product_id}, {name: token, var: token_arg}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, product_id: $product_id, token_arg: $token_arg, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks whether a user's subscription purchase is valid and returns its expiry time.
#
# GET /androidpublisher/v3/applications/{packageName}/purchases/subscriptions/{subscriptionId}/tokens/{token}
# Returns: record<acknowledgementState: int, autoRenewing: bool, autoResumeTimeMillis: string, cancelReason: int, cancelSurveyResult: record<cancelSurveyReason: int, userInputCancelReason: string>, countryCode: string, developerPayload: string, emailAddress: string, expiryTimeMillis: string, externalAccountId: string, familyName: string, givenName: string, introductoryPriceInfo: record<introductoryPriceAmountMicros: string, introductoryPriceCurrencyCode: string, introductoryPriceCycles: int, introductoryPricePeriod: string>, kind: string, linkedPurchaseToken: string, obfuscatedExternalAccountId: string, obfuscatedExternalProfileId: string, orderId: string, paymentState: int, priceAmountMicros: string, priceChange: record<newPrice: record<currency: string, priceMicros: string>, state: int>, priceCurrencyCode: string, profileId: string, profileName: string, promotionCode: string, promotionType: int, purchaseType: int, startTimeMillis: string, userCancellationTimeMillis: string>
# operationId: androidpublisher.purchases.subscriptions.get
export def "androidpublisher-purchases-subscriptions-get" [
  package_name: string
  subscription_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/purchases/subscriptions/{subscriptionId}/tokens/{token}"
    path_params: [{name: packageName, var: package_name}, {name: subscriptionId, var: subscription_id}, {name: token, var: token_arg}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, subscription_id: $subscription_id, token_arg: $token_arg, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Acknowledges a subscription purchase.
#
# POST /androidpublisher/v3/applications/{packageName}/purchases/subscriptions/{subscriptionId}/tokens/{token}:acknowledge
# operationId: androidpublisher.purchases.subscriptions.acknowledge
export def "androidpublisher-purchases-subscriptions-acknowledge" [
  package_name: string
  subscription_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --developer-payload: string # Payload to attach to the purchase.
]: any -> any {
  $in | http-request {
    method: post
    path: "/androidpublisher/v3/applications/{packageName}/purchases/subscriptions/{subscriptionId}/tokens/{token}:acknowledge"
    path_params: [{name: packageName, var: package_name}, {name: subscriptionId, var: subscription_id}, {name: token, var: token_arg}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: developerPayload, var: developer_payload}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, subscription_id: $subscription_id, token_arg: $token_arg, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, developer_payload: $developer_payload
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels a user's subscription purchase. The subscription remains valid until its expiration time.
#
# POST /androidpublisher/v3/applications/{packageName}/purchases/subscriptions/{subscriptionId}/tokens/{token}:cancel
# operationId: androidpublisher.purchases.subscriptions.cancel
export def "androidpublisher-purchases-subscriptions-cancel" [
  package_name: string
  subscription_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    method: post
    path: "/androidpublisher/v3/applications/{packageName}/purchases/subscriptions/{subscriptionId}/tokens/{token}:cancel"
    path_params: [{name: packageName, var: package_name}, {name: subscriptionId, var: subscription_id}, {name: token, var: token_arg}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, subscription_id: $subscription_id, token_arg: $token_arg, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Defers a user's subscription purchase until a specified future expiration time.
#
# POST /androidpublisher/v3/applications/{packageName}/purchases/subscriptions/{subscriptionId}/tokens/{token}:defer
# Returns: record<newExpiryTimeMillis: string>
# operationId: androidpublisher.purchases.subscriptions.defer
export def "androidpublisher-purchases-subscriptions-defer" [
  package_name: string
  subscription_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --deferral-info: record # A SubscriptionDeferralInfo contains the data needed to defer a subscription purchase to a future expiry time. — shape: {desiredExpiryTimeMillis?: string, expectedExpiryTimeMillis?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/androidpublisher/v3/applications/{packageName}/purchases/subscriptions/{subscriptionId}/tokens/{token}:defer"
    path_params: [{name: packageName, var: package_name}, {name: subscriptionId, var: subscription_id}, {name: token, var: token_arg}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: deferralInfo, var: deferral_info}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, subscription_id: $subscription_id, token_arg: $token_arg, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, deferral_info: $deferral_info
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Refunds a user's subscription purchase, but the subscription remains valid until its expiration time and it will continue to recur.
#
# POST /androidpublisher/v3/applications/{packageName}/purchases/subscriptions/{subscriptionId}/tokens/{token}:refund
# operationId: androidpublisher.purchases.subscriptions.refund
export def "androidpublisher-purchases-subscriptions-refund" [
  package_name: string
  subscription_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    method: post
    path: "/androidpublisher/v3/applications/{packageName}/purchases/subscriptions/{subscriptionId}/tokens/{token}:refund"
    path_params: [{name: packageName, var: package_name}, {name: subscriptionId, var: subscription_id}, {name: token, var: token_arg}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, subscription_id: $subscription_id, token_arg: $token_arg, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Refunds and immediately revokes a user's subscription purchase. Access to the subscription will be terminated immediately and it will stop recurring.
#
# POST /androidpublisher/v3/applications/{packageName}/purchases/subscriptions/{subscriptionId}/tokens/{token}:revoke
# operationId: androidpublisher.purchases.subscriptions.revoke
export def "androidpublisher-purchases-subscriptions-revoke" [
  package_name: string
  subscription_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    method: post
    path: "/androidpublisher/v3/applications/{packageName}/purchases/subscriptions/{subscriptionId}/tokens/{token}:revoke"
    path_params: [{name: packageName, var: package_name}, {name: subscriptionId, var: subscription_id}, {name: token, var: token_arg}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, subscription_id: $subscription_id, token_arg: $token_arg, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get metadata about a subscription
#
# GET /androidpublisher/v3/applications/{packageName}/purchases/subscriptionsv2/tokens/{token}
# Returns: record<acknowledgementState: string, canceledStateContext: record<developerInitiatedCancellation: record, replacementCancellation: record, systemInitiatedCancellation: record, userInitiatedCancellation: record<cancelSurveyResult: record, cancelTime: string>>, externalAccountIdentifiers: record<externalAccountId: string, obfuscatedExternalAccountId: string, obfuscatedExternalProfileId: string>, kind: string, latestOrderId: string, lineItems: table<autoRenewingPlan: record, expiryTime: string, offerDetails: record, prepaidPlan: record, productId: string>, linkedPurchaseToken: string, pausedStateContext: record<autoResumeTime: string>, regionCode: string, startTime: string, subscribeWithGoogleInfo: record<emailAddress: string, familyName: string, givenName: string, profileId: string, profileName: string>, subscriptionState: string, testPurchase: record>
# operationId: androidpublisher.purchases.subscriptionsv2.get
export def "androidpublisher-purchases-subscriptionsv2-get" [
  package_name: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/purchases/subscriptionsv2/tokens/{token}"
    path_params: [{name: packageName, var: package_name}, {name: token, var: token_arg}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, token_arg: $token_arg, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the purchases that were canceled, refunded or charged-back.
#
# GET /androidpublisher/v3/applications/{packageName}/purchases/voidedpurchases
# Returns: record<pageInfo: record<resultPerPage: int, startIndex: int, totalResults: int>, tokenPagination: record<nextPageToken: string, previousPageToken: string>, voidedPurchases: table<kind: string, orderId: string, purchaseTimeMillis: string, purchaseToken: string, voidedReason: int, voidedSource: int, voidedTimeMillis: string>>
# operationId: androidpublisher.purchases.voidedpurchases.list
export def "androidpublisher-purchases-voidedpurchases-list" [
  package_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --end-time: string # The time, in milliseconds since the Epoch, of the newest voided purchase that you want to see in the response. The value of this parameter cannot be greater than the current time and is ignored if a pagination token is set. Default value is current time. Note: This filter is applied on the time at which the record is seen as voided by our systems and not the actual voided time returned in the response.
  --max-results: int # Defines how many results the list operation should return. The default number depends on the resource collection.
  --start-index: int # Defines the index of the first element to return. This can only be used if indexed paging is enabled.
  --start-time: string # The time, in milliseconds since the Epoch, of the oldest voided purchase that you want to see in the response. The value of this parameter cannot be older than 30 days and is ignored if a pagination token is set. Default value is current time minus 30 days. Note: This filter is applied on the time at which the record is seen as voided by our systems and not the actual voided time returned in the response.
  --qp-token: string # Defines the token of the page to return, usually taken from TokenPagination. This can only be used if token paging is enabled. (spec name: token)
  --type: int # The type of voided purchases that you want to see in the response. Possible values are: 0. Only voided in-app product purchases will be returned in the response. This is the default value. 1. Both voided in-app purchases and voided subscription purchases will be returned in the response. Note: Before requesting to receive voided subscription purchases, you must switch to use orderId in the response which uniquely identifies one-time purchases and subscriptions. Otherwise, you will receive multiple subscription orders with the same PurchaseToken, because subscription renewal orders share the same PurchaseToken.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/androidpublisher/v3/applications/{packageName}/purchases/voidedpurchases"
    path_params: [{name: packageName, var: package_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: endTime, var: end_time}, {name: maxResults, var: max_results}, {name: startIndex, var: start_index}, {name: startTime, var: start_time}, {name: token, var: qp_token}, {name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, end_time: $end_time, max_results: $max_results, start_index: $start_index, start_time: $start_time, qp_token: $qp_token, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all reviews.
#
# GET /androidpublisher/v3/applications/{packageName}/reviews
# Returns: record<pageInfo: record<resultPerPage: int, startIndex: int, totalResults: int>, reviews: table<authorName: string, comments: list, reviewId: string>, tokenPagination: record<nextPageToken: string, previousPageToken: string>>
# operationId: androidpublisher.reviews.list
export def "androidpublisher-reviews-list" [
  package_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --max-results: int # How many results the list operation should return.
  --start-index: int # The index of the first element to return.
  --qp-token: string # Pagination token. If empty, list starts at the first review. (spec name: token)
  --translation-language: string # Language localization code.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/androidpublisher/v3/applications/{packageName}/reviews"
    path_params: [{name: packageName, var: package_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: maxResults, var: max_results}, {name: startIndex, var: start_index}, {name: token, var: qp_token}, {name: translationLanguage, var: translation_language}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, max_results: $max_results, start_index: $start_index, qp_token: $qp_token, translation_language: $translation_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a single review.
#
# GET /androidpublisher/v3/applications/{packageName}/reviews/{reviewId}
# Returns: record<authorName: string, comments: table<developerComment: record, userComment: record>, reviewId: string>
# operationId: androidpublisher.reviews.get
export def "androidpublisher-reviews-get" [
  package_name: string
  review_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --translation-language: string # Language localization code.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/androidpublisher/v3/applications/{packageName}/reviews/{reviewId}"
    path_params: [{name: packageName, var: package_name}, {name: reviewId, var: review_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: translationLanguage, var: translation_language}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, review_id: $review_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, translation_language: $translation_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replies to a single review, or updates an existing reply.
#
# POST /androidpublisher/v3/applications/{packageName}/reviews/{reviewId}:reply
# Returns: record<result: record<lastEdited: record<nanos: int, seconds: string>, replyText: string>>
# operationId: androidpublisher.reviews.reply
export def "androidpublisher-reviews-reply" [
  package_name: string
  review_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --reply-text: string # The text to set as the reply. Replies of more than approximately 350 characters will be rejected. HTML tags will be stripped.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/androidpublisher/v3/applications/{packageName}/reviews/{reviewId}:reply"
    path_params: [{name: packageName, var: package_name}, {name: reviewId, var: review_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: replyText, var: reply_text}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, review_id: $review_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, reply_text: $reply_text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all subscriptions under a given app.
#
# GET /androidpublisher/v3/applications/{packageName}/subscriptions
# Returns: record<nextPageToken: string, subscriptions: table<archived: bool, basePlans: list, listings: list, packageName: string, productId: string, taxAndComplianceSettings: record>>
# operationId: androidpublisher.monetization.subscriptions.list
export def "androidpublisher-monetization-subscriptions-list" [
  package_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # The maximum number of subscriptions to return. The service may return fewer than this value. If unspecified, at most 50 subscriptions will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # A page token, received from a previous `ListSubscriptions` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `ListSubscriptions` must match the call that provided the page token.
  --show-archived: oneof<nothing, bool> # Whether archived subscriptions should be included in the response. Defaults to false.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/androidpublisher/v3/applications/{packageName}/subscriptions"
    path_params: [{name: packageName, var: package_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: showArchived, var: show_archived}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token, show_archived: $show_archived
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new subscription. Newly added base plans will remain in draft state until activated.
#
# POST /androidpublisher/v3/applications/{packageName}/subscriptions
# Returns: record<archived: bool, basePlans: table<autoRenewingBasePlanType: record, basePlanId: string, offerTags: list, otherRegionsConfig: record, prepaidBasePlanType: record, regionalConfigs: list, state: string>, listings: table<benefits: list, description: string, languageCode: string, title: string>, packageName: string, productId: string, taxAndComplianceSettings: record<eeaWithdrawalRightType: string, taxRateInfoByRegionCode: record>>
# operationId: androidpublisher.monetization.subscriptions.create
export def "androidpublisher-monetization-subscriptions-create" [
  package_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --product-id: string # Required. The ID to use for the subscription. For the requirements on this format, see the documentation of the product_id field on the Subscription resource.
  --regions-version-version: string # Required. A string representing version of the available regions being used for the specified resource. The current version is 2022/02.
  --base-plans: list # The set of base plans for this subscription. Represents the prices and duration of the subscription if no other offers apply. — item shape: {autoRenewingBasePlanType?: record, basePlanId?: string, offerTags?: list, otherRegionsConfig?: record, prepaidBasePlanType?: record, regionalConfigs?: list}
  --listings: list # Required. List of localized listings for this subscription. Must contain at least an entry for the default language of the parent app. — item shape: {benefits?: list<string>, description?: string, languageCode?: string, title?: string}
  --body-package-name: string # Immutable. Package name of the parent app. (spec name: packageName)
  --body-product-id: string # Immutable. Unique product ID of the product. Unique within the parent app. Product IDs must be composed of lower-case letters (a-z), numbers (0-9), underscores (_) and dots (.). It must start with a lower-case letter or number, and be between 1 and 40 (inclusive) characters in length. (spec name: productId)
  --tax-and-compliance-settings: record # Details about taxation, Google Play policy and legal compliance for subscription products. — shape: {eeaWithdrawalRightType?: "WITHDRAWAL_RIGHT_TYPE_UNSPECIFIED"|"WITHDRAWAL_RIGHT_DIGITAL_CONTENT"|"WITHDRAWAL_RIGHT_SERVICE", taxRateInfoByRegionCode?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/androidpublisher/v3/applications/{packageName}/subscriptions"
    path_params: [{name: packageName, var: package_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: productId, var: product_id}, {name: "regionsVersion.version", var: regions_version_version}]
    body: {content_type: "application/json", kind: json, fields: [{name: basePlans, var: base_plans}, {name: listings, var: listings}, {name: packageName, var: body_package_name}, {name: productId, var: body_product_id}, {name: taxAndComplianceSettings, var: tax_and_compliance_settings}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, product_id: $product_id, regions_version_version: $regions_version_version, base_plans: $base_plans, listings: $listings, body_package_name: $body_package_name, body_product_id: $body_product_id, tax_and_compliance_settings: $tax_and_compliance_settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a subscription. A subscription can only be deleted if it has never had a base plan published.
#
# DELETE /androidpublisher/v3/applications/{packageName}/subscriptions/{productId}
# operationId: androidpublisher.monetization.subscriptions.delete
export def "androidpublisher-monetization-subscriptions-delete" [
  package_name: string
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
    path: "/androidpublisher/v3/applications/{packageName}/subscriptions/{productId}"
    path_params: [{name: packageName, var: package_name}, {name: productId, var: product_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, product_id: $product_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reads a single subscription.
#
# GET /androidpublisher/v3/applications/{packageName}/subscriptions/{productId}
# Returns: record<archived: bool, basePlans: table<autoRenewingBasePlanType: record, basePlanId: string, offerTags: list, otherRegionsConfig: record, prepaidBasePlanType: record, regionalConfigs: list, state: string>, listings: table<benefits: list, description: string, languageCode: string, title: string>, packageName: string, productId: string, taxAndComplianceSettings: record<eeaWithdrawalRightType: string, taxRateInfoByRegionCode: record>>
# operationId: androidpublisher.monetization.subscriptions.get
export def "androidpublisher-monetization-subscriptions-get" [
  package_name: string
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
    path: "/androidpublisher/v3/applications/{packageName}/subscriptions/{productId}"
    path_params: [{name: packageName, var: package_name}, {name: productId, var: product_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, product_id: $product_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing subscription.
#
# PATCH /androidpublisher/v3/applications/{packageName}/subscriptions/{productId}
# Returns: record<archived: bool, basePlans: table<autoRenewingBasePlanType: record, basePlanId: string, offerTags: list, otherRegionsConfig: record, prepaidBasePlanType: record, regionalConfigs: list, state: string>, listings: table<benefits: list, description: string, languageCode: string, title: string>, packageName: string, productId: string, taxAndComplianceSettings: record<eeaWithdrawalRightType: string, taxRateInfoByRegionCode: record>>
# operationId: androidpublisher.monetization.subscriptions.patch
export def "androidpublisher-monetization-subscriptions-patch" [
  package_name: string
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
  --regions-version-version: string # Required. A string representing version of the available regions being used for the specified resource. The current version is 2022/02.
  --update-mask: string # Required. The list of fields to be updated.
  --base-plans: list # The set of base plans for this subscription. Represents the prices and duration of the subscription if no other offers apply. — item shape: {autoRenewingBasePlanType?: record, basePlanId?: string, offerTags?: list, otherRegionsConfig?: record, prepaidBasePlanType?: record, regionalConfigs?: list}
  --listings: list # Required. List of localized listings for this subscription. Must contain at least an entry for the default language of the parent app. — item shape: {benefits?: list<string>, description?: string, languageCode?: string, title?: string}
  --body-package-name: string # Immutable. Package name of the parent app. (spec name: packageName)
  --body-product-id: string # Immutable. Unique product ID of the product. Unique within the parent app. Product IDs must be composed of lower-case letters (a-z), numbers (0-9), underscores (_) and dots (.). It must start with a lower-case letter or number, and be between 1 and 40 (inclusive) characters in length. (spec name: productId)
  --tax-and-compliance-settings: record # Details about taxation, Google Play policy and legal compliance for subscription products. — shape: {eeaWithdrawalRightType?: "WITHDRAWAL_RIGHT_TYPE_UNSPECIFIED"|"WITHDRAWAL_RIGHT_DIGITAL_CONTENT"|"WITHDRAWAL_RIGHT_SERVICE", taxRateInfoByRegionCode?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/androidpublisher/v3/applications/{packageName}/subscriptions/{productId}"
    path_params: [{name: packageName, var: package_name}, {name: productId, var: product_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: "regionsVersion.version", var: regions_version_version}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: basePlans, var: base_plans}, {name: listings, var: listings}, {name: packageName, var: body_package_name}, {name: productId, var: body_product_id}, {name: taxAndComplianceSettings, var: tax_and_compliance_settings}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, product_id: $product_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, regions_version_version: $regions_version_version, update_mask: $update_mask, base_plans: $base_plans, listings: $listings, body_package_name: $body_package_name, body_product_id: $body_product_id, tax_and_compliance_settings: $tax_and_compliance_settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a base plan. Can only be done for draft base plans. This action is irreversible.
#
# DELETE /androidpublisher/v3/applications/{packageName}/subscriptions/{productId}/basePlans/{basePlanId}
# operationId: androidpublisher.monetization.subscriptions.basePlans.delete
export def "androidpublisher-monetization-subscriptions-base-plans-delete" [
  package_name: string
  product_id: string
  base_plan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/subscriptions/{productId}/basePlans/{basePlanId}"
    path_params: [{name: packageName, var: package_name}, {name: productId, var: product_id}, {name: basePlanId, var: base_plan_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, product_id: $product_id, base_plan_id: $base_plan_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all offers under a given subscription.
#
# GET /androidpublisher/v3/applications/{packageName}/subscriptions/{productId}/basePlans/{basePlanId}/offers
# Returns: record<nextPageToken: string, subscriptionOffers: table<basePlanId: string, offerId: string, offerTags: list, otherRegionsConfig: record, packageName: string, phases: list, productId: string, regionalConfigs: list, state: string, targeting: record>>
# operationId: androidpublisher.monetization.subscriptions.basePlans.offers.list
export def "androidpublisher-monetization-subscriptions-base-plans-offers-list" [
  package_name: string
  product_id: string
  base_plan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # The maximum number of subscriptions to return. The service may return fewer than this value. If unspecified, at most 50 subscriptions will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # A page token, received from a previous `ListSubscriptionsOffers` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `ListSubscriptionOffers` must match the call that provided the page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/androidpublisher/v3/applications/{packageName}/subscriptions/{productId}/basePlans/{basePlanId}/offers"
    path_params: [{name: packageName, var: package_name}, {name: productId, var: product_id}, {name: basePlanId, var: base_plan_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, product_id: $product_id, base_plan_id: $base_plan_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new subscription offer. Only auto-renewing base plans can have subscription offers. The offer state will be DRAFT until it is activated.
#
# POST /androidpublisher/v3/applications/{packageName}/subscriptions/{productId}/basePlans/{basePlanId}/offers
# Returns: record<basePlanId: string, offerId: string, offerTags: table<tag: string>, otherRegionsConfig: record<otherRegionsNewSubscriberAvailability: bool>, packageName: string, phases: table<duration: string, otherRegionsConfig: record, recurrenceCount: int, regionalConfigs: list>, productId: string, regionalConfigs: table<newSubscriberAvailability: bool, regionCode: string>, state: string, targeting: record<acquisitionRule: record<scope: record>, upgradeRule: record<billingPeriodDuration: string, oncePerUser: bool, scope: record>>>
# operationId: androidpublisher.monetization.subscriptions.basePlans.offers.create
export def "androidpublisher-monetization-subscriptions-base-plans-offers-create" [
  package_name: string
  product_id: string
  base_plan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --offer-id: string # Required. The ID to use for the offer. For the requirements on this format, see the documentation of the offer_id field on the SubscriptionOffer resource.
  --regions-version-version: string # Required. A string representing version of the available regions being used for the specified resource. The current version is 2022/02.
  --body-base-plan-id: string # Required. Immutable. The ID of the base plan to which this offer is an extension. (spec name: basePlanId)
  --body-offer-id: string # Required. Immutable. Unique ID of this subscription offer. Must be unique within the base plan. (spec name: offerId)
  --offer-tags: list # List of up to 20 custom tags specified for this offer, and returned to the app through the billing library. — item shape: {tag?: string}
  --other-regions-config: record # Configuration for any new locations Play may launch in specified on a subscription offer. — shape: {otherRegionsNewSubscriberAvailability?: bool}
  --body-package-name: string # Required. Immutable. The package name of the app the parent subscription belongs to. (spec name: packageName)
  --phases: list # Required. The phases of this subscription offer. Must contain at least one entry, and may contain at most five. Users will always receive all these phases in the specified order. Phases may not be added, removed, or reordered after initial creation. — item shape: {duration?: string, otherRegionsConfig?: record, recurrenceCount?: int, regionalConfigs?: list}
  --body-product-id: string # Required. Immutable. The ID of the parent subscription this offer belongs to. (spec name: productId)
  --regional-configs: list # Required. The region-specific configuration of this offer. Must contain at least one entry. — item shape: {newSubscriberAvailability?: bool, regionCode?: string}
  --targeting: record # Defines the rule a user needs to satisfy to receive this offer. — shape: {acquisitionRule?: record, upgradeRule?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/androidpublisher/v3/applications/{packageName}/subscriptions/{productId}/basePlans/{basePlanId}/offers"
    path_params: [{name: packageName, var: package_name}, {name: productId, var: product_id}, {name: basePlanId, var: base_plan_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: offerId, var: offer_id}, {name: "regionsVersion.version", var: regions_version_version}]
    body: {content_type: "application/json", kind: json, fields: [{name: basePlanId, var: body_base_plan_id}, {name: offerId, var: body_offer_id}, {name: offerTags, var: offer_tags}, {name: otherRegionsConfig, var: other_regions_config}, {name: packageName, var: body_package_name}, {name: phases, var: phases}, {name: productId, var: body_product_id}, {name: regionalConfigs, var: regional_configs}, {name: targeting, var: targeting}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, product_id: $product_id, base_plan_id: $base_plan_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, offer_id: $offer_id, regions_version_version: $regions_version_version, body_base_plan_id: $body_base_plan_id, body_offer_id: $body_offer_id, offer_tags: $offer_tags, other_regions_config: $other_regions_config, body_package_name: $body_package_name, phases: $phases, body_product_id: $body_product_id, regional_configs: $regional_configs, targeting: $targeting
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a subscription offer. Can only be done for draft offers. This action is irreversible.
#
# DELETE /androidpublisher/v3/applications/{packageName}/subscriptions/{productId}/basePlans/{basePlanId}/offers/{offerId}
# operationId: androidpublisher.monetization.subscriptions.basePlans.offers.delete
export def "androidpublisher-monetization-subscriptions-base-plans-offers-delete" [
  package_name: string
  product_id: string
  base_plan_id: string
  offer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/subscriptions/{productId}/basePlans/{basePlanId}/offers/{offerId}"
    path_params: [{name: packageName, var: package_name}, {name: productId, var: product_id}, {name: basePlanId, var: base_plan_id}, {name: offerId, var: offer_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, product_id: $product_id, base_plan_id: $base_plan_id, offer_id: $offer_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reads a single offer
#
# GET /androidpublisher/v3/applications/{packageName}/subscriptions/{productId}/basePlans/{basePlanId}/offers/{offerId}
# Returns: record<basePlanId: string, offerId: string, offerTags: table<tag: string>, otherRegionsConfig: record<otherRegionsNewSubscriberAvailability: bool>, packageName: string, phases: table<duration: string, otherRegionsConfig: record, recurrenceCount: int, regionalConfigs: list>, productId: string, regionalConfigs: table<newSubscriberAvailability: bool, regionCode: string>, state: string, targeting: record<acquisitionRule: record<scope: record>, upgradeRule: record<billingPeriodDuration: string, oncePerUser: bool, scope: record>>>
# operationId: androidpublisher.monetization.subscriptions.basePlans.offers.get
export def "androidpublisher-monetization-subscriptions-base-plans-offers-get" [
  package_name: string
  product_id: string
  base_plan_id: string
  offer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/subscriptions/{productId}/basePlans/{basePlanId}/offers/{offerId}"
    path_params: [{name: packageName, var: package_name}, {name: productId, var: product_id}, {name: basePlanId, var: base_plan_id}, {name: offerId, var: offer_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, product_id: $product_id, base_plan_id: $base_plan_id, offer_id: $offer_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing subscription offer.
#
# PATCH /androidpublisher/v3/applications/{packageName}/subscriptions/{productId}/basePlans/{basePlanId}/offers/{offerId}
# Returns: record<basePlanId: string, offerId: string, offerTags: table<tag: string>, otherRegionsConfig: record<otherRegionsNewSubscriberAvailability: bool>, packageName: string, phases: table<duration: string, otherRegionsConfig: record, recurrenceCount: int, regionalConfigs: list>, productId: string, regionalConfigs: table<newSubscriberAvailability: bool, regionCode: string>, state: string, targeting: record<acquisitionRule: record<scope: record>, upgradeRule: record<billingPeriodDuration: string, oncePerUser: bool, scope: record>>>
# operationId: androidpublisher.monetization.subscriptions.basePlans.offers.patch
export def "androidpublisher-monetization-subscriptions-base-plans-offers-patch" [
  package_name: string
  product_id: string
  base_plan_id: string
  offer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --regions-version-version: string # Required. A string representing version of the available regions being used for the specified resource. The current version is 2022/02.
  --update-mask: string # Required. The list of fields to be updated.
  --body-base-plan-id: string # Required. Immutable. The ID of the base plan to which this offer is an extension. (spec name: basePlanId)
  --body-offer-id: string # Required. Immutable. Unique ID of this subscription offer. Must be unique within the base plan. (spec name: offerId)
  --offer-tags: list # List of up to 20 custom tags specified for this offer, and returned to the app through the billing library. — item shape: {tag?: string}
  --other-regions-config: record # Configuration for any new locations Play may launch in specified on a subscription offer. — shape: {otherRegionsNewSubscriberAvailability?: bool}
  --body-package-name: string # Required. Immutable. The package name of the app the parent subscription belongs to. (spec name: packageName)
  --phases: list # Required. The phases of this subscription offer. Must contain at least one entry, and may contain at most five. Users will always receive all these phases in the specified order. Phases may not be added, removed, or reordered after initial creation. — item shape: {duration?: string, otherRegionsConfig?: record, recurrenceCount?: int, regionalConfigs?: list}
  --body-product-id: string # Required. Immutable. The ID of the parent subscription this offer belongs to. (spec name: productId)
  --regional-configs: list # Required. The region-specific configuration of this offer. Must contain at least one entry. — item shape: {newSubscriberAvailability?: bool, regionCode?: string}
  --targeting: record # Defines the rule a user needs to satisfy to receive this offer. — shape: {acquisitionRule?: record, upgradeRule?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/androidpublisher/v3/applications/{packageName}/subscriptions/{productId}/basePlans/{basePlanId}/offers/{offerId}"
    path_params: [{name: packageName, var: package_name}, {name: productId, var: product_id}, {name: basePlanId, var: base_plan_id}, {name: offerId, var: offer_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: "regionsVersion.version", var: regions_version_version}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: basePlanId, var: body_base_plan_id}, {name: offerId, var: body_offer_id}, {name: offerTags, var: offer_tags}, {name: otherRegionsConfig, var: other_regions_config}, {name: packageName, var: body_package_name}, {name: phases, var: phases}, {name: productId, var: body_product_id}, {name: regionalConfigs, var: regional_configs}, {name: targeting, var: targeting}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, product_id: $product_id, base_plan_id: $base_plan_id, offer_id: $offer_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, regions_version_version: $regions_version_version, update_mask: $update_mask, body_base_plan_id: $body_base_plan_id, body_offer_id: $body_offer_id, offer_tags: $offer_tags, other_regions_config: $other_regions_config, body_package_name: $body_package_name, phases: $phases, body_product_id: $body_product_id, regional_configs: $regional_configs, targeting: $targeting
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Activates a subscription offer. Once activated, subscription offers will be available to new subscribers.
#
# POST /androidpublisher/v3/applications/{packageName}/subscriptions/{productId}/basePlans/{basePlanId}/offers/{offerId}:activate
# Returns: record<basePlanId: string, offerId: string, offerTags: table<tag: string>, otherRegionsConfig: record<otherRegionsNewSubscriberAvailability: bool>, packageName: string, phases: table<duration: string, otherRegionsConfig: record, recurrenceCount: int, regionalConfigs: list>, productId: string, regionalConfigs: table<newSubscriberAvailability: bool, regionCode: string>, state: string, targeting: record<acquisitionRule: record<scope: record>, upgradeRule: record<billingPeriodDuration: string, oncePerUser: bool, scope: record>>>
# operationId: androidpublisher.monetization.subscriptions.basePlans.offers.activate
export def "androidpublisher-monetization-subscriptions-base-plans-offers-activate" [
  package_name: string
  product_id: string
  base_plan_id: string
  offer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/subscriptions/{productId}/basePlans/{basePlanId}/offers/{offerId}:activate"
    path_params: [{name: packageName, var: package_name}, {name: productId, var: product_id}, {name: basePlanId, var: base_plan_id}, {name: offerId, var: offer_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, product_id: $product_id, base_plan_id: $base_plan_id, offer_id: $offer_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deactivates a subscription offer. Once deactivated, existing subscribers will maintain their subscription, but the offer will become unavailable to new subscribers.
#
# POST /androidpublisher/v3/applications/{packageName}/subscriptions/{productId}/basePlans/{basePlanId}/offers/{offerId}:deactivate
# Returns: record<basePlanId: string, offerId: string, offerTags: table<tag: string>, otherRegionsConfig: record<otherRegionsNewSubscriberAvailability: bool>, packageName: string, phases: table<duration: string, otherRegionsConfig: record, recurrenceCount: int, regionalConfigs: list>, productId: string, regionalConfigs: table<newSubscriberAvailability: bool, regionCode: string>, state: string, targeting: record<acquisitionRule: record<scope: record>, upgradeRule: record<billingPeriodDuration: string, oncePerUser: bool, scope: record>>>
# operationId: androidpublisher.monetization.subscriptions.basePlans.offers.deactivate
export def "androidpublisher-monetization-subscriptions-base-plans-offers-deactivate" [
  package_name: string
  product_id: string
  base_plan_id: string
  offer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/subscriptions/{productId}/basePlans/{basePlanId}/offers/{offerId}:deactivate"
    path_params: [{name: packageName, var: package_name}, {name: productId, var: product_id}, {name: basePlanId, var: base_plan_id}, {name: offerId, var: offer_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, product_id: $product_id, base_plan_id: $base_plan_id, offer_id: $offer_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Activates a base plan. Once activated, base plans will be available to new subscribers.
#
# POST /androidpublisher/v3/applications/{packageName}/subscriptions/{productId}/basePlans/{basePlanId}:activate
# Returns: record<archived: bool, basePlans: table<autoRenewingBasePlanType: record, basePlanId: string, offerTags: list, otherRegionsConfig: record, prepaidBasePlanType: record, regionalConfigs: list, state: string>, listings: table<benefits: list, description: string, languageCode: string, title: string>, packageName: string, productId: string, taxAndComplianceSettings: record<eeaWithdrawalRightType: string, taxRateInfoByRegionCode: record>>
# operationId: androidpublisher.monetization.subscriptions.basePlans.activate
export def "androidpublisher-monetization-subscriptions-base-plans-activate" [
  package_name: string
  product_id: string
  base_plan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/subscriptions/{productId}/basePlans/{basePlanId}:activate"
    path_params: [{name: packageName, var: package_name}, {name: productId, var: product_id}, {name: basePlanId, var: base_plan_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, product_id: $product_id, base_plan_id: $base_plan_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deactivates a base plan. Once deactivated, the base plan will become unavailable to new subscribers, but existing subscribers will maintain their subscription
#
# POST /androidpublisher/v3/applications/{packageName}/subscriptions/{productId}/basePlans/{basePlanId}:deactivate
# Returns: record<archived: bool, basePlans: table<autoRenewingBasePlanType: record, basePlanId: string, offerTags: list, otherRegionsConfig: record, prepaidBasePlanType: record, regionalConfigs: list, state: string>, listings: table<benefits: list, description: string, languageCode: string, title: string>, packageName: string, productId: string, taxAndComplianceSettings: record<eeaWithdrawalRightType: string, taxRateInfoByRegionCode: record>>
# operationId: androidpublisher.monetization.subscriptions.basePlans.deactivate
export def "androidpublisher-monetization-subscriptions-base-plans-deactivate" [
  package_name: string
  product_id: string
  base_plan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/subscriptions/{productId}/basePlans/{basePlanId}:deactivate"
    path_params: [{name: packageName, var: package_name}, {name: productId, var: product_id}, {name: basePlanId, var: base_plan_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, product_id: $product_id, base_plan_id: $base_plan_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Migrates subscribers who are receiving an historical subscription price to the currently-offered price for the specified region. Requests will cause price change notifications to be sent to users who are currently receiving an historical price older than the supplied timestamp. Subscribers who do not agree to the new price will have their subscription ended at the next renewal.
#
# POST /androidpublisher/v3/applications/{packageName}/subscriptions/{productId}/basePlans/{basePlanId}:migratePrices
# Returns: record
# operationId: androidpublisher.monetization.subscriptions.basePlans.migratePrices
export def "androidpublisher-monetization-subscriptions-base-plans-migrate-prices" [
  package_name: string
  product_id: string
  base_plan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --regional-price-migrations: list # Required. The regional prices to update. — item shape: {oldestAllowedPriceVersionTime?: string, regionCode?: string}
  --regions-version: record # The version of the available regions being used for the specified resource. — shape: {version?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/androidpublisher/v3/applications/{packageName}/subscriptions/{productId}/basePlans/{basePlanId}:migratePrices"
    path_params: [{name: packageName, var: package_name}, {name: productId, var: product_id}, {name: basePlanId, var: base_plan_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: regionalPriceMigrations, var: regional_price_migrations}, {name: regionsVersion, var: regions_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, product_id: $product_id, base_plan_id: $base_plan_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, regional_price_migrations: $regional_price_migrations, regions_version: $regions_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Archives a subscription. Can only be done if at least one base plan was active in the past, and no base plan is available for new or existing subscribers currently. This action is irreversible, and the subscription ID will remain reserved.
#
# POST /androidpublisher/v3/applications/{packageName}/subscriptions/{productId}:archive
# Returns: record<archived: bool, basePlans: table<autoRenewingBasePlanType: record, basePlanId: string, offerTags: list, otherRegionsConfig: record, prepaidBasePlanType: record, regionalConfigs: list, state: string>, listings: table<benefits: list, description: string, languageCode: string, title: string>, packageName: string, productId: string, taxAndComplianceSettings: record<eeaWithdrawalRightType: string, taxRateInfoByRegionCode: record>>
# operationId: androidpublisher.monetization.subscriptions.archive
export def "androidpublisher-monetization-subscriptions-archive" [
  package_name: string
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/androidpublisher/v3/applications/{packageName}/subscriptions/{productId}:archive"
    path_params: [{name: packageName, var: package_name}, {name: productId, var: product_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, product_id: $product_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of previously created system APK variants.
#
# GET /androidpublisher/v3/applications/{packageName}/systemApks/{versionCode}/variants
# Returns: record<variants: table<deviceSpec: record, variantId: int>>
# operationId: androidpublisher.systemapks.variants.list
export def "androidpublisher-systemapks-variants-list" [
  package_name: string
  version_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/systemApks/{versionCode}/variants"
    path_params: [{name: packageName, var: package_name}, {name: versionCode, var: version_code}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, version_code: $version_code, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an APK which is suitable for inclusion in a system image from an already uploaded Android App Bundle.
#
# POST /androidpublisher/v3/applications/{packageName}/systemApks/{versionCode}/variants
# Returns: record<deviceSpec: record<screenDensity: int, supportedAbis: list<string>, supportedLocales: list<string>>, variantId: int>
# operationId: androidpublisher.systemapks.variants.create
export def "androidpublisher-systemapks-variants-create" [
  package_name: string
  version_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --device-spec: record # The device spec used to generate a system APK. — shape: {screenDensity?: int, supportedAbis?: list<string>, supportedLocales?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/androidpublisher/v3/applications/{packageName}/systemApks/{versionCode}/variants"
    path_params: [{name: packageName, var: package_name}, {name: versionCode, var: version_code}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: deviceSpec, var: device_spec}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, version_code: $version_code, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, device_spec: $device_spec
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a previously created system APK variant.
#
# GET /androidpublisher/v3/applications/{packageName}/systemApks/{versionCode}/variants/{variantId}
# Returns: record<deviceSpec: record<screenDensity: int, supportedAbis: list<string>, supportedLocales: list<string>>, variantId: int>
# operationId: androidpublisher.systemapks.variants.get
export def "androidpublisher-systemapks-variants-get" [
  package_name: string
  version_code: string
  variant_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/applications/{packageName}/systemApks/{versionCode}/variants/{variantId}"
    path_params: [{name: packageName, var: package_name}, {name: versionCode, var: version_code}, {name: variantId, var: variant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, version_code: $version_code, variant_id: $variant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Downloads a previously created system APK which is suitable for inclusion in a system image.
#
# GET /androidpublisher/v3/applications/{packageName}/systemApks/{versionCode}/variants/{variantId}:download
# operationId: androidpublisher.systemapks.variants.download
export def "androidpublisher-systemapks-variants-download" [
  package_name: string
  version_code: string
  variant_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    method: get
    path: "/androidpublisher/v3/applications/{packageName}/systemApks/{versionCode}/variants/{variantId}:download"
    path_params: [{name: packageName, var: package_name}, {name: versionCode, var: version_code}, {name: variantId, var: variant_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, version_code: $version_code, variant_id: $variant_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes all access for the user to the given developer account.
#
# DELETE /androidpublisher/v3/{name}
# operationId: androidpublisher.users.delete
export def "androidpublisher-users-delete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an existing external transaction.
#
# GET /androidpublisher/v3/{name}
# Returns: record<createTime: string, currentPreTaxAmount: record<currency: string, priceMicros: string>, currentTaxAmount: record<currency: string, priceMicros: string>, externalTransactionId: string, oneTimeTransaction: record<externalTransactionToken: string>, originalPreTaxAmount: record<currency: string, priceMicros: string>, originalTaxAmount: record<currency: string, priceMicros: string>, packageName: string, recurringTransaction: record<externalSubscription: record<subscriptionType: string>, externalTransactionToken: string, initialExternalTransactionId: string>, testPurchase: record, transactionState: string, transactionTime: string, userTaxAddress: record<regionCode: string>>
# operationId: androidpublisher.externaltransactions.getexternaltransaction
export def "androidpublisher-externaltransactions-getexternaltransaction" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/androidpublisher/v3/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates access for the user to the developer account.
#
# PATCH /androidpublisher/v3/{name}
# Returns: record<accessState: string, developerAccountPermissions: list<string>, email: string, expirationTime: string, grants: table<appLevelPermissions: list, name: string, packageName: string>, name: string, partial: bool>
# operationId: androidpublisher.users.patch
export def "androidpublisher-users-patch" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --update-mask: string # Optional. The list of fields to be updated.
  --developer-account-permissions: list<string> # Permissions for the user which apply across the developer account.
  --email: string # Immutable. The user's email address.
  --expiration-time: string # The time at which the user's access expires, if set. When setting this value, it must always be in the future. (format: google-datetime)
  --body-name: string # Required. Resource name for this user, following the pattern "developers/{developer}/users/{email}". (spec name: name)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/androidpublisher/v3/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: developerAccountPermissions, var: developer_account_permissions}, {name: email, var: email}, {name: expirationTime, var: expiration_time}, {name: name, var: body_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, update_mask: $update_mask, developer_account_permissions: $developer_account_permissions, email: $email, expiration_time: $expiration_time, body_name: $body_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Refunds or partially refunds an existing external transaction.
#
# POST /androidpublisher/v3/{name}:refund
# Returns: record<createTime: string, currentPreTaxAmount: record<currency: string, priceMicros: string>, currentTaxAmount: record<currency: string, priceMicros: string>, externalTransactionId: string, oneTimeTransaction: record<externalTransactionToken: string>, originalPreTaxAmount: record<currency: string, priceMicros: string>, originalTaxAmount: record<currency: string, priceMicros: string>, packageName: string, recurringTransaction: record<externalSubscription: record<subscriptionType: string>, externalTransactionToken: string, initialExternalTransactionId: string>, testPurchase: record, transactionState: string, transactionTime: string, userTaxAddress: record<regionCode: string>>
# operationId: androidpublisher.externaltransactions.refundexternaltransaction
export def "androidpublisher-externaltransactions-refundexternaltransaction" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --full-refund: record # A full refund of the remaining amount of a transaction.
  --partial-refund: record # A partial refund of a transaction. — shape: {refundId?: string, refundPreTaxAmount?: record}
  --refund-time: string # Required. The time that the transaction was refunded. (format: google-datetime)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/androidpublisher/v3/{name}:refund"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: fullRefund, var: full_refund}, {name: partialRefund, var: partial_refund}, {name: refundTime, var: refund_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, full_refund: $full_refund, partial_refund: $partial_refund, refund_time: $refund_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new external transaction.
#
# POST /androidpublisher/v3/{parent}/externalTransactions
# Returns: record<createTime: string, currentPreTaxAmount: record<currency: string, priceMicros: string>, currentTaxAmount: record<currency: string, priceMicros: string>, externalTransactionId: string, oneTimeTransaction: record<externalTransactionToken: string>, originalPreTaxAmount: record<currency: string, priceMicros: string>, originalTaxAmount: record<currency: string, priceMicros: string>, packageName: string, recurringTransaction: record<externalSubscription: record<subscriptionType: string>, externalTransactionToken: string, initialExternalTransactionId: string>, testPurchase: record, transactionState: string, transactionTime: string, userTaxAddress: record<regionCode: string>>
# operationId: androidpublisher.externaltransactions.createexternaltransaction
export def "androidpublisher-externaltransactions-createexternaltransaction" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --external-transaction-id: string # Required. The id to use for the external transaction. Must be unique across all other transactions for the app. This value should be 1-63 characters and valid characters are /a-z0-9_-/.
  --current-pre-tax-amount: record # Definition of a price, i.e. currency and units. — shape: {currency?: string, priceMicros?: string}
  --current-tax-amount: record # Definition of a price, i.e. currency and units. — shape: {currency?: string, priceMicros?: string}
  --one-time-transaction: record # Represents a one-time transaction. — shape: {externalTransactionToken?: string}
  --original-pre-tax-amount: record # Definition of a price, i.e. currency and units. — shape: {currency?: string, priceMicros?: string}
  --original-tax-amount: record # Definition of a price, i.e. currency and units. — shape: {currency?: string, priceMicros?: string}
  --recurring-transaction: record # Represents a transaction that is part of a recurring series of payments. This can be a subscription or a one-time product with multiple payments (such as preorder). — shape: {externalSubscription?: record, externalTransactionToken?: string, initialExternalTransactionId?: string}
  --test-purchase: record # Represents a transaction performed using a test account. These transactions will not be charged by Google.
  --transaction-time: string # Required. The time when the transaction was completed. (format: google-datetime)
  --user-tax-address: record # User's address for the external transaction. — shape: {regionCode?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/androidpublisher/v3/{parent}/externalTransactions"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: externalTransactionId, var: external_transaction_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: currentPreTaxAmount, var: current_pre_tax_amount}, {name: currentTaxAmount, var: current_tax_amount}, {name: oneTimeTransaction, var: one_time_transaction}, {name: originalPreTaxAmount, var: original_pre_tax_amount}, {name: originalTaxAmount, var: original_tax_amount}, {name: recurringTransaction, var: recurring_transaction}, {name: testPurchase, var: test_purchase}, {name: transactionTime, var: transaction_time}, {name: userTaxAddress, var: user_tax_address}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, external_transaction_id: $external_transaction_id, current_pre_tax_amount: $current_pre_tax_amount, current_tax_amount: $current_tax_amount, one_time_transaction: $one_time_transaction, original_pre_tax_amount: $original_pre_tax_amount, original_tax_amount: $original_tax_amount, recurring_transaction: $recurring_transaction, test_purchase: $test_purchase, transaction_time: $transaction_time, user_tax_address: $user_tax_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Grant access for a user to the given package.
#
# POST /androidpublisher/v3/{parent}/grants
# Returns: record<appLevelPermissions: list<string>, name: string, packageName: string>
# operationId: androidpublisher.grants.create
export def "androidpublisher-grants-create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --app-level-permissions: list<string> # The permissions granted to the user for this app.
  --name: string # Required. Resource name for this grant, following the pattern "developers/{developer}/users/{email}/grants/{package_name}". If this grant is for a draft app, the app ID will be used in this resource name instead of the package name.
  --package-name: string # Immutable. The package name of the app. This will be empty for draft apps.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/androidpublisher/v3/{parent}/grants"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: appLevelPermissions, var: app_level_permissions}, {name: name, var: name}, {name: packageName, var: package_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, app_level_permissions: $app_level_permissions, name: $name, package_name: $package_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all users with access to a developer account.
#
# GET /androidpublisher/v3/{parent}/users
# Returns: record<nextPageToken: string, users: table<accessState: string, developerAccountPermissions: list, email: string, expirationTime: string, grants: list, name: string, partial: bool>>
# operationId: androidpublisher.users.list
export def "androidpublisher-users-list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # The maximum number of results to return. This must be set to -1 to disable pagination.
  --page-token: string # A token received from a previous call to this method, in order to retrieve further results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/androidpublisher/v3/{parent}/users"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Grant access for a user to the given developer account.
#
# POST /androidpublisher/v3/{parent}/users
# Returns: record<accessState: string, developerAccountPermissions: list<string>, email: string, expirationTime: string, grants: table<appLevelPermissions: list, name: string, packageName: string>, name: string, partial: bool>
# operationId: androidpublisher.users.create
export def "androidpublisher-users-create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --developer-account-permissions: list<string> # Permissions for the user which apply across the developer account.
  --email: string # Immutable. The user's email address.
  --expiration-time: string # The time at which the user's access expires, if set. When setting this value, it must always be in the future. (format: google-datetime)
  --name: string # Required. Resource name for this user, following the pattern "developers/{developer}/users/{email}".
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/androidpublisher/v3/{parent}/users"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: developerAccountPermissions, var: developer_account_permissions}, {name: email, var: email}, {name: expirationTime, var: expiration_time}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, developer_account_permissions: $developer_account_permissions, email: $email, expiration_time: $expiration_time, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
