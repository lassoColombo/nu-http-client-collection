# Auto-generated client for Google My Business API v4
# Source: https://api.apis.guru/v2/specs/googleapis.com/my-business/v4/openapi.json
# Auth: --token flag or $env.GOOGLE_MY_BUSINESS_API_TOKEN

const CLIENT = {
  base_url: "https://mybusiness.googleapis.com"
  token_env_var: "GOOGLE_MY_BUSINESS_API_TOKEN"
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

def base-url-completer [] { ["https://mybusiness.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def permission-level-completer [] { ["MEMBER_LEVEL" "OWNER_LEVEL" "PERMISSION_LEVEL_UNSPECIFIED"] }
def role-completer [] { ["ACCOUNT_ROLE_UNSPECIFIED" "COMMUNITY_MANAGER" "CO_OWNER" "MANAGER" "OWNER"] }
def type-completer [] { ["ACCOUNT_TYPE_UNSPECIFIED" "LOCATION_GROUP" "ORGANIZATION" "PERSONAL" "USER_GROUP"] }
def view-completer [] { ["BASIC" "CATEGORY_VIEW_UNSPECIFIED" "FULL"] }
def report-reason-bad-location-completer [] { ["BAD_LOCATION_REASON_UNSPECIFIED" "DOES_NOT_EXIST" "DUPLICATE" "MOVED" "NOT_A_BUSINESS" "NOT_A_LOCATION" "PERMANENTLY_CLOSED" "SPAM"] }
def report-reason-bad-recommendation-completer [] { ["BAD_RECOMMENDATION_REASON_UNSPECIFIED" "IRRELEVANT" "NOT_A_STORE_FRONT" "NOT_PART_OF_SUGGESTED_CHAIN"] }
def method-completer [] { ["ADDRESS" "AUTO" "EMAIL" "PHONE_CALL" "SMS" "VERIFICATION_METHOD_UNSPECIFIED"] }
def role-completer-1 [] { ["ADMIN_ROLE_UNSPECIFIED" "COMMUNITY_MANAGER" "CO_OWNER" "MANAGER" "OWNER"] }
def target-type-completer [] { ["ACCOUNTS_ONLY" "ALL" "LOCATIONS_ONLY"] }
def alert-type-completer [] { ["ALERT_TYPE_UNSPECIFIED" "COVID_19"] }
def state-completer [] { ["LIVE" "LOCAL_POST_STATE_UNSPECIFIED" "PROCESSING" "REJECTED"] }
def topic-type-completer [] { ["ALERT" "EVENT" "LOCAL_POST_TOPIC_TYPE_UNSPECIFIED" "OFFER" "STANDARD"] }
def media-format-completer [] { ["MEDIA_FORMAT_UNSPECIFIED" "PHOTO" "VIDEO"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    mybusiness-accounts-list: "record<accounts: table<accountName: string, accountNumber: string, name: string, organizationInfo: record, permissionLevel: string, role: string, state: record, type: string>, nextPageToken: string>"
    mybusiness-accounts-create: "record<accountName: string, accountNumber: string, name: string, organizationInfo: record<phoneNumber: string, postalAddress: record<addressLines: list, administrativeArea: string, languageCode: string, locality: string, organization: string, postalCode: string, recipients: list, regionCode: string, revision: int, sortingCode: string, sublocality: string>, registeredDomain: string>, permissionLevel: string, role: string, state: record<status: string>, type: string>"
    mybusiness-attributes-list: "record<attributes: table<attributeId: string, displayName: string, groupDisplayName: string, isDeprecated: bool, isRepeatable: bool, valueMetadata: list, valueType: string>, nextPageToken: string>"
    mybusiness-categories-list: "record<categories: table<categoryId: string, displayName: string, moreHoursTypes: list, serviceTypes: list>, nextPageToken: string, totalCategoryCount: int>"
    mybusiness-categories-batch-get: "record<categories: table<categoryId: string, displayName: string, moreHoursTypes: list, serviceTypes: list>>"
    mybusiness-chains-search: "record<chains: table<chainNames: list, locationCount: int, name: string, websites: list>>"
    mybusiness-google-locations-search: "record<googleLocations: table<location: record, name: string, requestAdminRightsUrl: string>>"
    mybusiness-accounts-locations-questions-delete: "record"
    mybusiness-chains-get: "record<chainNames: table<displayName: string, languageCode: string>, locationCount: int, name: string, websites: table<url: string>>"
    mybusiness-accounts-locations-questions-patch: "record<author: record<displayName: string, profilePhotoUrl: string, type: string>, createTime: string, name: string, text: string, topAnswers: table<author: record, createTime: string, name: string, text: string, updateTime: string, upvoteCount: int>, totalAnswerCount: int, updateTime: string, upvoteCount: int>"
    mybusiness-accounts-update-notifications: "record<name: string, notificationTypes: list<string>, topicName: string>"
    mybusiness-accounts-locations-local-posts-report-insights: "record<localPostMetrics: table<localPostName: string, metricValues: list>, name: string, timeZone: string>"
    mybusiness-accounts-locations-batch-get: "record<locations: table<adWordsLocationExtensions: record, additionalCategories: list, additionalPhones: list, address: record, attributes: list, labels: list, languageCode: string, latlng: record, locationKey: record, locationName: string, locationState: record, metadata: record, moreHours: list, name: string, openInfo: record, priceLists: list, primaryCategory: record, primaryPhone: string, profile: record, regularHours: record, relationshipData: record, serviceArea: record, specialHours: record, storeCode: string, websiteUrl: string>>"
    mybusiness-accounts-locations-batch-get-reviews: "record<locationReviews: table<name: string, review: record>, nextPageToken: string>"
    mybusiness-accounts-locations-report-insights: "record<locationDrivingDirectionMetrics: table<locationName: string, timeZone: string, topDirectionSources: list>, locationMetrics: table<locationName: string, metricValues: list, timeZone: string>>"
    mybusiness-accounts-locations-reviews-delete-reply: "record"
    mybusiness-accounts-locations-reviews-update-reply: "record<comment: string, updateTime: string>"
    mybusiness-accounts-invitations-accept: "record"
    mybusiness-accounts-locations-associate: "record"
    mybusiness-accounts-locations-clear-association: "record"
    mybusiness-accounts-locations-verifications-complete: "record<verification: record<createTime: string, method: string, name: string, state: string>>"
    mybusiness-accounts-invitations-decline: "record"
    mybusiness-accounts-locations-fetch-verification-options: "record<options: table<addressData: record, emailData: record, phoneData: record, verificationMethod: string>>"
    mybusiness-accounts-locations-find-matches: "record<matchTime: string, matchedLocations: table<isExactMatch: bool, location: record>>"
    mybusiness-accounts-generate-account-number: "record<accountName: string, accountNumber: string, name: string, organizationInfo: record<phoneNumber: string, postalAddress: record<addressLines: list, administrativeArea: string, languageCode: string, locality: string, organization: string, postalCode: string, recipients: list, regionCode: string, revision: int, sortingCode: string, sublocality: string>, registeredDomain: string>, permissionLevel: string, role: string, state: record<status: string>, type: string>"
    mybusiness-accounts-locations-lodging-get-google-updated: "record<diffMask: string, lodging: record<accessibility: record<mobilityAccessible: bool, mobilityAccessibleElevator: bool, mobilityAccessibleElevatorException: string, mobilityAccessibleException: string, mobilityAccessibleParking: bool, mobilityAccessibleParkingException: string, mobilityAccessiblePool: bool, mobilityAccessiblePoolException: string>, activities: record<beachAccess: bool, beachAccessException: string, beachFront: bool, beachFrontException: string, bicycleRental: bool, bicycleRentalException: string, boutiqueStores: bool, boutiqueStoresException: string, casino: bool, casinoException: string, freeBicycleRental: bool, freeBicycleRentalException: string, freeWatercraftRental: bool, freeWatercraftRentalException: string, gameRoom: bool, gameRoomException: string, golf: bool, golfException: string, horsebackRiding: bool, horsebackRidingException: string, nightclub: bool, nightclubException: string, privateBeach: bool, privateBeachException: string, scuba: bool, scubaException: string, snorkeling: bool, snorkelingException: string, tennis: bool, tennisException: string, waterSkiing: bool, waterSkiingException: string, watercraftRental: bool, watercraftRentalException: string>, allUnits: record<bungalowOrVilla: bool, bungalowOrVillaException: string, connectingUnitAvailable: bool, connectingUnitAvailableException: string, executiveFloor: bool, executiveFloorException: string, maxAdultOccupantsCount: int, maxAdultOccupantsCountException: string, maxChildOccupantsCount: int, maxChildOccupantsCountException: string, maxOccupantsCount: int, maxOccupantsCountException: string, privateHome: bool, privateHomeException: string, suite: bool, suiteException: string, tier: string, tierException: string, totalLivingAreas: record, views: record>, business: record<businessCenter: bool, businessCenterException: string, meetingRooms: bool, meetingRoomsCount: int, meetingRoomsCountException: string, meetingRoomsException: string>, commonLivingArea: record<accessibility: record, eating: record, features: record, layout: record, sleeping: record>, connectivity: record<freeWifi: bool, freeWifiException: string, publicAreaWifiAvailable: bool, publicAreaWifiAvailableException: string, publicInternetTerminal: bool, publicInternetTerminalException: string, wifiAvailable: bool, wifiAvailableException: string>, families: record<babysitting: bool, babysittingException: string, kidsActivities: bool, kidsActivitiesException: string, kidsClub: bool, kidsClubException: string>, foodAndDrink: record<bar: bool, barException: string, breakfastAvailable: bool, breakfastAvailableException: string, breakfastBuffet: bool, breakfastBuffetException: string, buffet: bool, buffetException: string, dinnerBuffet: bool, dinnerBuffetException: string, freeBreakfast: bool, freeBreakfastException: string, restaurant: bool, restaurantException: string, restaurantsCount: int, restaurantsCountException: string, roomService: bool, roomServiceException: string, tableService: bool, tableServiceException: string, twentyFourHourRoomService: bool, twentyFourHourRoomServiceException: string, vendingMachine: bool, vendingMachineException: string>, guestUnits: list<record>, healthAndSafety: record<enhancedCleaning: record, increasedFoodSafety: record, minimizedContact: record, personalProtection: record, physicalDistancing: record>, housekeeping: record<dailyHousekeeping: bool, dailyHousekeepingException: string, housekeepingAvailable: bool, housekeepingAvailableException: string, turndownService: bool, turndownServiceException: string>, metadata: record<updateTime: string>, name: string, parking: record<electricCarChargingStations: bool, electricCarChargingStationsException: string, freeParking: bool, freeParkingException: string, freeSelfParking: bool, freeSelfParkingException: string, freeValetParking: bool, freeValetParkingException: string, parkingAvailable: bool, parkingAvailableException: string, selfParkingAvailable: bool, selfParkingAvailableException: string, valetParkingAvailable: bool, valetParkingAvailableException: string>, pets: record<catsAllowed: bool, catsAllowedException: string, dogsAllowed: bool, dogsAllowedException: string, petsAllowed: bool, petsAllowedException: string, petsAllowedFree: bool, petsAllowedFreeException: string>, policies: record<allInclusiveAvailable: bool, allInclusiveAvailableException: string, allInclusiveOnly: bool, allInclusiveOnlyException: string, checkinTime: record, checkinTimeException: string, checkoutTime: record, checkoutTimeException: string, kidsStayFree: bool, kidsStayFreeException: string, maxChildAge: int, maxChildAgeException: string, maxKidsStayFreeCount: int, maxKidsStayFreeCountException: string, paymentOptions: record, smokeFreeProperty: bool, smokeFreePropertyException: string>, pools: record<adultPool: bool, adultPoolException: string, hotTub: bool, hotTubException: string, indoorPool: bool, indoorPoolException: string, indoorPoolsCount: int, indoorPoolsCountException: string, lazyRiver: bool, lazyRiverException: string, lifeguard: bool, lifeguardException: string, outdoorPool: bool, outdoorPoolException: string, outdoorPoolsCount: int, outdoorPoolsCountException: string, pool: bool, poolException: string, poolsCount: int, poolsCountException: string, wadingPool: bool, wadingPoolException: string, waterPark: bool, waterParkException: string, waterslide: bool, waterslideException: string, wavePool: bool, wavePoolException: string>, property: record<builtYear: int, builtYearException: string, floorsCount: int, floorsCountException: string, lastRenovatedYear: int, lastRenovatedYearException: string, roomsCount: int, roomsCountException: string>, services: record<baggageStorage: bool, baggageStorageException: string, concierge: bool, conciergeException: string, convenienceStore: bool, convenienceStoreException: string, currencyExchange: bool, currencyExchangeException: string, elevator: bool, elevatorException: string, frontDesk: bool, frontDeskException: string, fullServiceLaundry: bool, fullServiceLaundryException: string, giftShop: bool, giftShopException: string, languagesSpoken: record, selfServiceLaundry: bool, selfServiceLaundryException: string, socialHour: bool, socialHourException: string, twentyFourHourFrontDesk: bool, twentyFourHourFrontDeskException: string, wakeUpCalls: bool, wakeUpCallsException: string>, someUnits: record<bungalowOrVilla: bool, bungalowOrVillaException: string, connectingUnitAvailable: bool, connectingUnitAvailableException: string, executiveFloor: bool, executiveFloorException: string, maxAdultOccupantsCount: int, maxAdultOccupantsCountException: string, maxChildOccupantsCount: int, maxChildOccupantsCountException: string, maxOccupantsCount: int, maxOccupantsCountException: string, privateHome: bool, privateHomeException: string, suite: bool, suiteException: string, tier: string, tierException: string, totalLivingAreas: record, views: record>, transportation: record<airportShuttle: bool, airportShuttleException: string, carRentalOnProperty: bool, carRentalOnPropertyException: string, freeAirportShuttle: bool, freeAirportShuttleException: string, freePrivateCarService: bool, freePrivateCarServiceException: string, localShuttle: bool, localShuttleException: string, privateCarService: bool, privateCarServiceException: string, transfer: bool, transferException: string>, wellness: record<doctorOnCall: bool, doctorOnCallException: string, ellipticalMachine: bool, ellipticalMachineException: string, fitnessCenter: bool, fitnessCenterException: string, freeFitnessCenter: bool, freeFitnessCenterException: string, freeWeights: bool, freeWeightsException: string, massage: bool, massageException: string, salon: bool, salonException: string, sauna: bool, saunaException: string, spa: bool, spaException: string, treadmill: bool, treadmillException: string, weightMachine: bool, weightMachineException: string>>>"
    mybusiness-accounts-locations-get-google-updated: "record<diffMask: string, location: record<adWordsLocationExtensions: record<adPhone: string>, additionalCategories: list<record>, additionalPhones: list<string>, address: record<addressLines: list, administrativeArea: string, languageCode: string, locality: string, organization: string, postalCode: string, recipients: list, regionCode: string, revision: int, sortingCode: string, sublocality: string>, attributes: list<record>, labels: list<string>, languageCode: string, latlng: record<latitude: float, longitude: float>, locationKey: record<explicitNoPlaceId: bool, placeId: string, plusPageId: string, requestId: string>, locationName: string, locationState: record<canDelete: bool, canHaveFoodMenus: bool, canModifyServiceList: bool, canOperateHealthData: bool, canOperateLodgingData: bool, canUpdate: bool, hasPendingEdits: bool, hasPendingVerification: bool, isDisabled: bool, isDisconnected: bool, isDuplicate: bool, isGoogleUpdated: bool, isLocalPostApiDisabled: bool, isPendingReview: bool, isPublished: bool, isSuspended: bool, isVerified: bool, needsReverification: bool>, metadata: record<duplicate: record, mapsUrl: string, newReviewUrl: string>, moreHours: list<record>, name: string, openInfo: record<canReopen: bool, openingDate: record, status: string>, priceLists: list<record>, primaryCategory: record<categoryId: string, displayName: string, moreHoursTypes: list, serviceTypes: list>, primaryPhone: string, profile: record<description: string>, regularHours: record<periods: list>, relationshipData: record<parentChain: string>, serviceArea: record<businessType: string, places: record, radius: record>, specialHours: record<specialHourPeriods: list>, storeCode: string, websiteUrl: string>>"
    mybusiness-accounts-list-recommend-google-locations: "record<googleLocations: table<location: record, name: string, requestAdminRightsUrl: string>, nextPageToken: string, totalSize: int>"
    mybusiness-google-locations-report: "record"
    mybusiness-accounts-locations-transfer: "record<adWordsLocationExtensions: record<adPhone: string>, additionalCategories: table<categoryId: string, displayName: string, moreHoursTypes: list, serviceTypes: list>, additionalPhones: list<string>, address: record<addressLines: list<string>, administrativeArea: string, languageCode: string, locality: string, organization: string, postalCode: string, recipients: list<string>, regionCode: string, revision: int, sortingCode: string, sublocality: string>, attributes: table<attributeId: string, repeatedEnumValue: record, urlValues: list, valueType: string, values: list>, labels: list<string>, languageCode: string, latlng: record<latitude: float, longitude: float>, locationKey: record<explicitNoPlaceId: bool, placeId: string, plusPageId: string, requestId: string>, locationName: string, locationState: record<canDelete: bool, canHaveFoodMenus: bool, canModifyServiceList: bool, canOperateHealthData: bool, canOperateLodgingData: bool, canUpdate: bool, hasPendingEdits: bool, hasPendingVerification: bool, isDisabled: bool, isDisconnected: bool, isDuplicate: bool, isGoogleUpdated: bool, isLocalPostApiDisabled: bool, isPendingReview: bool, isPublished: bool, isSuspended: bool, isVerified: bool, needsReverification: bool>, metadata: record<duplicate: record<access: string, locationName: string, placeId: string>, mapsUrl: string, newReviewUrl: string>, moreHours: table<hoursTypeId: string, periods: list>, name: string, openInfo: record<canReopen: bool, openingDate: record<day: int, month: int, year: int>, status: string>, priceLists: table<labels: list, priceListId: string, sections: list, sourceUrl: string>, primaryCategory: record<categoryId: string, displayName: string, moreHoursTypes: list<record>, serviceTypes: list<record>>, primaryPhone: string, profile: record<description: string>, regularHours: record<periods: list<record>>, relationshipData: record<parentChain: string>, serviceArea: record<businessType: string, places: record<placeInfos: list>, radius: record<latlng: record, radiusKm: float>>, specialHours: record<specialHourPeriods: list<record>>, storeCode: string, websiteUrl: string>"
    mybusiness-accounts-locations-verify: "record<verification: record<createTime: string, method: string, name: string, state: string>>"
    mybusiness-accounts-locations-admins-list: "record<admins: table<adminName: string, name: string, pendingInvitation: bool, role: string>>"
    mybusiness-accounts-locations-admins-create: "record<adminName: string, name: string, pendingInvitation: bool, role: string>"
    mybusiness-accounts-locations-questions-answers-list: "record<answers: table<author: record, createTime: string, name: string, text: string, updateTime: string, upvoteCount: int>, nextPageToken: string, totalSize: int>"
    mybusiness-accounts-locations-questions-answers-delete: "record"
    mybusiness-accounts-locations-questions-answers-upsert: "record<author: record<displayName: string, profilePhotoUrl: string, type: string>, createTime: string, name: string, text: string, updateTime: string, upvoteCount: int>"
    mybusiness-accounts-locations-insurance-networks-list: "record<networks: table<networkId: string, networkNames: record, payerNames: record, state: string>, nextPageToken: string>"
    mybusiness-accounts-invitations-list: "record<invitations: table<name: string, role: string, targetAccount: record, targetLocation: record>>"
    mybusiness-accounts-locations-local-posts-list: "record<localPosts: table<alertType: string, callToAction: record, createTime: string, event: record, languageCode: string, media: list, name: string, offer: record, searchUrl: string, state: string, summary: string, topicType: string, updateTime: string>, nextPageToken: string>"
    mybusiness-accounts-locations-local-posts-create: "record<alertType: string, callToAction: record<actionType: string, url: string>, createTime: string, event: record<schedule: record<endDate: record, endTime: record, startDate: record, startTime: record>, title: string>, languageCode: string, media: table<attribution: record, createTime: string, dataRef: record, description: string, dimensions: record, googleUrl: string, insights: record, locationAssociation: record, mediaFormat: string, name: string, sourceUrl: string, thumbnailUrl: string>, name: string, offer: record<couponCode: string, redeemOnlineUrl: string, termsConditions: string>, searchUrl: string, state: string, summary: string, topicType: string, updateTime: string>"
    mybusiness-accounts-locations-list: "record<locations: table<adWordsLocationExtensions: record, additionalCategories: list, additionalPhones: list, address: record, attributes: list, labels: list, languageCode: string, latlng: record, locationKey: record, locationName: string, locationState: record, metadata: record, moreHours: list, name: string, openInfo: record, priceLists: list, primaryCategory: record, primaryPhone: string, profile: record, regularHours: record, relationshipData: record, serviceArea: record, specialHours: record, storeCode: string, websiteUrl: string>, nextPageToken: string, totalSize: int>"
    mybusiness-accounts-locations-create: "record<adWordsLocationExtensions: record<adPhone: string>, additionalCategories: table<categoryId: string, displayName: string, moreHoursTypes: list, serviceTypes: list>, additionalPhones: list<string>, address: record<addressLines: list<string>, administrativeArea: string, languageCode: string, locality: string, organization: string, postalCode: string, recipients: list<string>, regionCode: string, revision: int, sortingCode: string, sublocality: string>, attributes: table<attributeId: string, repeatedEnumValue: record, urlValues: list, valueType: string, values: list>, labels: list<string>, languageCode: string, latlng: record<latitude: float, longitude: float>, locationKey: record<explicitNoPlaceId: bool, placeId: string, plusPageId: string, requestId: string>, locationName: string, locationState: record<canDelete: bool, canHaveFoodMenus: bool, canModifyServiceList: bool, canOperateHealthData: bool, canOperateLodgingData: bool, canUpdate: bool, hasPendingEdits: bool, hasPendingVerification: bool, isDisabled: bool, isDisconnected: bool, isDuplicate: bool, isGoogleUpdated: bool, isLocalPostApiDisabled: bool, isPendingReview: bool, isPublished: bool, isSuspended: bool, isVerified: bool, needsReverification: bool>, metadata: record<duplicate: record<access: string, locationName: string, placeId: string>, mapsUrl: string, newReviewUrl: string>, moreHours: table<hoursTypeId: string, periods: list>, name: string, openInfo: record<canReopen: bool, openingDate: record<day: int, month: int, year: int>, status: string>, priceLists: table<labels: list, priceListId: string, sections: list, sourceUrl: string>, primaryCategory: record<categoryId: string, displayName: string, moreHoursTypes: list<record>, serviceTypes: list<record>>, primaryPhone: string, profile: record<description: string>, regularHours: record<periods: list<record>>, relationshipData: record<parentChain: string>, serviceArea: record<businessType: string, places: record<placeInfos: list>, radius: record<latlng: record, radiusKm: float>>, specialHours: record<specialHourPeriods: list<record>>, storeCode: string, websiteUrl: string>"
    mybusiness-accounts-locations-media-list: "record<mediaItems: table<attribution: record, createTime: string, dataRef: record, description: string, dimensions: record, googleUrl: string, insights: record, locationAssociation: record, mediaFormat: string, name: string, sourceUrl: string, thumbnailUrl: string>, nextPageToken: string, totalMediaItemCount: int>"
    mybusiness-accounts-locations-media-create: "record<attribution: record<profileName: string, profilePhotoUrl: string, profileUrl: string, takedownUrl: string>, createTime: string, dataRef: record<resourceName: string>, description: string, dimensions: record<heightPixels: int, widthPixels: int>, googleUrl: string, insights: record<viewCount: string>, locationAssociation: record<category: string, priceListItemId: string>, mediaFormat: string, name: string, sourceUrl: string, thumbnailUrl: string>"
    mybusiness-accounts-locations-media-customers-list: "record<mediaItems: table<attribution: record, createTime: string, dataRef: record, description: string, dimensions: record, googleUrl: string, insights: record, locationAssociation: record, mediaFormat: string, name: string, sourceUrl: string, thumbnailUrl: string>, nextPageToken: string, totalMediaItemCount: int>"
    mybusiness-accounts-locations-media-start-upload: "record<resourceName: string>"
    mybusiness-accounts-locations-questions-list: "record<nextPageToken: string, questions: table<author: record, createTime: string, name: string, text: string, topAnswers: list, totalAnswerCount: int, updateTime: string, upvoteCount: int>, totalSize: int>"
    mybusiness-accounts-locations-questions-create: "record<author: record<displayName: string, profilePhotoUrl: string, type: string>, createTime: string, name: string, text: string, topAnswers: table<author: record, createTime: string, name: string, text: string, updateTime: string, upvoteCount: int>, totalAnswerCount: int, updateTime: string, upvoteCount: int>"
    mybusiness-accounts-locations-reviews-list: "record<averageRating: float, nextPageToken: string, reviews: table<comment: string, createTime: string, name: string, reviewId: string, reviewReply: record, reviewer: record, starRating: string, updateTime: string>, totalReviewCount: int>"
    mybusiness-accounts-locations-verifications-list: "record<nextPageToken: string, verifications: table<createTime: string, method: string, name: string, state: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["mybusiness-accounts-list" "mybusiness-accounts-create" "mybusiness-attributes-list" "mybusiness-categories-list" "mybusiness-categories-batch-get" "mybusiness-chains-search" "mybusiness-google-locations-search" "mybusiness-accounts-locations-questions-delete" "mybusiness-chains-get" "mybusiness-accounts-locations-questions-patch" "mybusiness-accounts-update-notifications" "mybusiness-accounts-locations-local-posts-report-insights" "mybusiness-accounts-locations-batch-get" "mybusiness-accounts-locations-batch-get-reviews" "mybusiness-accounts-locations-report-insights" "mybusiness-accounts-locations-reviews-delete-reply" "mybusiness-accounts-locations-reviews-update-reply" "mybusiness-accounts-invitations-accept" "mybusiness-accounts-locations-associate" "mybusiness-accounts-locations-clear-association" "mybusiness-accounts-locations-verifications-complete" "mybusiness-accounts-invitations-decline" "mybusiness-accounts-locations-fetch-verification-options" "mybusiness-accounts-locations-find-matches" "mybusiness-accounts-generate-account-number" "mybusiness-accounts-locations-lodging-get-google-updated" "mybusiness-accounts-locations-get-google-updated" "mybusiness-accounts-list-recommend-google-locations" "mybusiness-google-locations-report" "mybusiness-accounts-locations-transfer" "mybusiness-accounts-locations-verify" "mybusiness-accounts-locations-admins-list" "mybusiness-accounts-locations-admins-create" "mybusiness-accounts-locations-questions-answers-list" "mybusiness-accounts-locations-questions-answers-delete" "mybusiness-accounts-locations-questions-answers-upsert" "mybusiness-accounts-locations-insurance-networks-list" "mybusiness-accounts-invitations-list" "mybusiness-accounts-locations-local-posts-list" "mybusiness-accounts-locations-local-posts-create" "mybusiness-accounts-locations-list" "mybusiness-accounts-locations-create" "mybusiness-accounts-locations-media-list" "mybusiness-accounts-locations-media-create" "mybusiness-accounts-locations-media-customers-list" "mybusiness-accounts-locations-media-start-upload" "mybusiness-accounts-locations-questions-list" "mybusiness-accounts-locations-questions-create" "mybusiness-accounts-locations-reviews-list" "mybusiness-accounts-locations-verifications-list" "commands"] | sort) } | get name | first)
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

# Lists all of the accounts for the authenticated user. This includes all accounts that the user owns, as well as any accounts for which the user has management rights.
#
# GET /v4/accounts
# Returns: record<accounts: table<accountName: string, accountNumber: string, name: string, organizationInfo: record, permissionLevel: string, role: string, state: record, type: string>, nextPageToken: string>
# operationId: mybusiness.accounts.list
export def "mybusiness-accounts-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # A filter constraining the accounts to return. The response includes only entries that match the filter. If `filter` is empty, then no constraints are applied and all accounts (paginated) are retrieved for the requested account. For example, a request with the filter `type=USER_GROUP` will only return user groups.
  --name: string # The resource name of the account for which the list of directly accessible accounts is to be retrieved. This only makes sense for Organizations and User Groups. If empty, will return `ListAccounts` for the authenticated user.
  --page-size: int # How many accounts to fetch per page. Default is 20, minimum is 2, and maximum page size is 20.
  --page-token: string # If specified, the next page of accounts is retrieved. The `pageToken` is returned when a call to `accounts.list` returns more results than can fit into the requested page size.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/accounts"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: name, var: name}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, name: $name, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an account with the specified name and type under the given parent. - Personal accounts and Organizations cannot be created. - User Groups cannot be created with a Personal account as primary owner. - Location Groups cannot be created with a primary owner of a Personal account if the Personal account is in an Organization. - Location Groups cannot own Location Groups.
#
# POST /v4/accounts
# Returns: record<accountName: string, accountNumber: string, name: string, organizationInfo: record<phoneNumber: string, postalAddress: record<addressLines: list, administrativeArea: string, languageCode: string, locality: string, organization: string, postalCode: string, recipients: list, regionCode: string, revision: int, sortingCode: string, sublocality: string>, registeredDomain: string>, permissionLevel: string, role: string, state: record<status: string>, type: string>
# operationId: mybusiness.accounts.create
export def "mybusiness-accounts-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --primary-owner: string # The resource name of the account which will be the primary owner of the account being created. It should be of the form `accounts/{account_id}/`.
  --account-name: string # The name of the account. *Note:* For an account with AccountType `PERSONAL`, this is the first and last name of the user account.
  --account-number: string # Account reference number if provisioned.
  --name: string # The resource name, in the format `accounts/{account_id}`.
  --organization-info: record # Additional Info stored for an organization. — shape: {phoneNumber?: string, postalAddress?: record, registeredDomain?: string}
  --permission-level: string@permission-level-completer # Output only. Specifies the PermissionLevel the caller has for this account.
  --role: string@role-completer # Output only. Specifies the AccountRole the caller has for this account.
  --state: record # Indicates status of the account, such as whether the account has been verified by Google. — shape: {status?: "ACCOUNT_STATUS_UNSPECIFIED"|"VERIFIED"|"UNVERIFIED"|"VERIFICATION_REQUESTED"}
  --type: string@type-completer # Output only. Specifies the AccountType of this account.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/accounts"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: primaryOwner, var: primary_owner}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountName, var: account_name}, {name: accountNumber, var: account_number}, {name: name, var: name}, {name: organizationInfo, var: organization_info}, {name: permissionLevel, var: permission_level}, {name: role, var: role}, {name: state, var: state}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, primary_owner: $primary_owner, account_name: $account_name, account_number: $account_number, name: $name, organization_info: $organization_info, permission_level: $permission_level, role: $role, state: $state, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of available attributes that would be available for a location with the given primary category and country.
#
# GET /v4/attributes
# Returns: record<attributes: table<attributeId: string, displayName: string, groupDisplayName: string, isDeprecated: bool, isRepeatable: bool, valueMetadata: list, valueType: string>, nextPageToken: string>
# operationId: mybusiness.attributes.list
export def "mybusiness-attributes-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --category-id: string # The primary category stable ID to find available attributes.
  --country: string # The ISO 3166-1 alpha-2 country code to find available attributes.
  --language-code: string # The BCP 47 code of language to get attribute display names in. If this language is not available, they will be provided in English.
  --name: string # Resource name of the location to look up available attributes.
  --page-size: int # How many attributes to include per page. Default is 200, minimum is 1.
  --page-token: string # If specified, the next page of attribute metadata is retrieved. The `pageToken` is returned when a call to `attributes.list` returns more results than can fit into the requested page size.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/attributes"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: categoryId, var: category_id}, {name: country, var: country}, {name: languageCode, var: language_code}, {name: name, var: name}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, category_id: $category_id, country: $country, language_code: $language_code, name: $name, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of business categories. Search will match the category name but not the category ID. *Note:* Search only matches the front of a category name (that is, 'food' may return 'Food Court' but not 'Fast Food Restaurant').
#
# GET /v4/categories
# Returns: record<categories: table<categoryId: string, displayName: string, moreHoursTypes: list, serviceTypes: list>, nextPageToken: string, totalCategoryCount: int>
# operationId: mybusiness.categories.list
export def "mybusiness-categories-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --language-code: string # The BCP 47 code of language. If the language is not available, it will default to English.
  --page-size: int # How many categories to fetch per page. Default is 100, minimum is 1, and maximum page size is 100.
  --page-token: string # If specified, the next page of categories will be fetched.
  --region-code: string # The ISO 3166-1 alpha-2 country code.
  --search-term: string # Optional filter string from user.
  --view: string@view-completer # Optional. Specifies which parts to the Category resource should be returned in the response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/categories"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: languageCode, var: language_code}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: regionCode, var: region_code}, {name: searchTerm, var: search_term}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, language_code: $language_code, page_size: $page_size, page_token: $page_token, region_code: $region_code, search_term: $search_term, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of business categories for the provided language and GConcept ids.
#
# GET /v4/categories:batchGet
# Returns: record<categories: table<categoryId: string, displayName: string, moreHoursTypes: list, serviceTypes: list>>
# operationId: mybusiness.categories.batchGet
export def "mybusiness-categories-batch-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --category-ids: list<string> # Required. At least one name must be set. The GConcept ids the localized category names should be returned for.
  --language-code: string # Required. The BCP 47 code of language that the category names should be returned in.
  --region-code: string # Optional. The ISO 3166-1 alpha-2 country code used to infer non-standard language.
  --view: string@view-completer # Required. Specifies which parts to the Category resource should be returned in the response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/categories:batchGet"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: categoryIds, var: category_ids, style: multi}, {name: languageCode, var: language_code}, {name: regionCode, var: region_code}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, category_ids: $category_ids, language_code: $language_code, region_code: $region_code, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Searches the chain based on chain name.
#
# GET /v4/chains:search
# Returns: record<chains: table<chainNames: list, locationCount: int, name: string, websites: list>>
# operationId: mybusiness.chains.search
export def "mybusiness-chains-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --chain-display-name: string # Search for a chain by its name. Exact/partial/fuzzy/related queries are supported. Examples: "walmart", "wal-mart", "walmmmart", "沃尔玛"
  --result-count: int # The maximum number of matched chains to return from this query. The default is 10. The maximum possible value is 500.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/chains:search"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: chainDisplayName, var: chain_display_name}, {name: resultCount, var: result_count}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, chain_display_name: $chain_display_name, result_count: $result_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search all of the possible locations that are a match to the specified request.
#
# POST /v4/googleLocations:search
# Returns: record<googleLocations: table<location: record, name: string, requestAdminRightsUrl: string>>
# operationId: mybusiness.googleLocations.search
export def "mybusiness-google-locations-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --location: record # A location. See the [help center article] (https://support.google.com/business/answer/3038177) for a detailed description of these fields, or the [category endpoint](/my-business/reference/rest/v4/categories) for a list of valid business categories. — shape: {adWordsLocationExtensions?: record, additionalCategories?: list, additionalPhones?: list<string>, address?: record, attributes?: list, labels?: list<string>, languageCode?: string, latlng?: record, locationKey?: record, locationName?: string, locationState?: record, metadata?: record, moreHours?: list, name?: string, openInfo?: record, priceLists?: list, primaryCategory?: record, primaryPhone?: string, profile?: record, regularHours?: record, relationshipData?: record, serviceArea?: record, ... (3 more fields)}
  --query: string # Text query to search for. The search results from a query string will be less accurate than if providing an exact location, but can provide more inexact matches.
  --result-count: int # The number of matches to return. The default value is 3, with a maximum of 10. Note that latency may increase if more are requested. There is no pagination. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/googleLocations:search"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: location, var: location}, {name: query, var: query}, {name: resultCount, var: result_count}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, location: $location, query: $query, result_count: $result_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a specific question written by the current user.
#
# DELETE /v4/{name}
# Returns: record
# operationId: mybusiness.accounts.locations.questions.delete
export def "mybusiness-accounts-locations-questions-delete" [
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
    method: delete
    path: "/v4/{name}"
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

# Gets the specified chain. Returns `NOT_FOUND` if the chain does not exist.
#
# GET /v4/{name}
# Returns: record<chainNames: table<displayName: string, languageCode: string>, locationCount: int, name: string, websites: table<url: string>>
# operationId: mybusiness.chains.get
export def "mybusiness-chains-get" [
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
    path: "/v4/{name}"
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

# Updates a specific question written by the current user.
#
# PATCH /v4/{name}
# Returns: record<author: record<displayName: string, profilePhotoUrl: string, type: string>, createTime: string, name: string, text: string, topAnswers: table<author: record, createTime: string, name: string, text: string, updateTime: string, upvoteCount: int>, totalAnswerCount: int, updateTime: string, upvoteCount: int>
# operationId: mybusiness.accounts.locations.questions.patch
export def "mybusiness-accounts-locations-questions-patch" [
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
  --update-mask: string # The specific fields to update. If no mask is specified, then this is treated as a full update and all editable fields are set to the values passed in.
  --author: record # Represents the author of a question or answer — shape: {displayName?: string, profilePhotoUrl?: string, type?: "AUTHOR_TYPE_UNSPECIFIED"|"REGULAR_USER"|"LOCAL_GUIDE"|"MERCHANT"}
  --create-time: string # Output only. The timestamp for when the question was written. (format: google-datetime)
  --body-name: string # Output only. The unique name for the question. accounts/*/locations/*/questions/* (spec name: name)
  --text: string # The text of the question. It should contain at least three words and the total length should be greater than or equal to 10 characters. The maximum length is 4096 characters.
  --top-answers: list # Output only. A list of answers to the question, sorted by upvotes. This may not be a complete list of answers depending on the request parameters (answers_per_question) — item shape: {author?: record, createTime?: string, name?: string, text?: string, updateTime?: string, upvoteCount?: int}
  --total-answer-count: int # Output only. The total number of answers posted for this question. (format: int32)
  --update-time: string # Output only. The timestamp for when the question was last modified. (format: google-datetime)
  --upvote-count: int # Output only. The number of upvotes for the question. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v4/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: author, var: author}, {name: createTime, var: create_time}, {name: name, var: body_name}, {name: text, var: text}, {name: topAnswers, var: top_answers}, {name: totalAnswerCount, var: total_answer_count}, {name: updateTime, var: update_time}, {name: upvoteCount, var: upvote_count}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, update_mask: $update_mask, author: $author, create_time: $create_time, body_name: $body_name, text: $text, top_answers: $top_answers, total_answer_count: $total_answer_count, update_time: $update_time, upvote_count: $upvote_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the pubsub notification settings for the account informing Business Profile which topic to send pubsub notifications for: - New reviews for locations administered by the account. - Updated reviews for locations administered by the account. - New `GoogleUpdates` for locations administered by the account. An account will only have one notification settings resource, and only one pubsub topic can be set.
#
# PUT /v4/{name}
# Returns: record<name: string, notificationTypes: list<string>, topicName: string>
# operationId: mybusiness.accounts.updateNotifications
export def "mybusiness-accounts-update-notifications" [
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
  --body-name: string # Output only. The notifications resource name. (spec name: name)
  --notification-types: list<string> # The types of notifications that will be sent to the Cloud Pub/Sub topic. At least one must be specified. To stop receiving notifications entirely, use DeleteNotifications.
  --topic-name: string # The Google Cloud Pub/Sub topic that will receive notifications when locations managed by this account are updated. If unset, no notifications will be posted. The account mybusiness-api-pubsub@system.gserviceaccount.com must have at least Publish permissions on the Cloud Pub/Sub topic.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: body_name}, {name: notificationTypes, var: notification_types}, {name: topicName, var: topic_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body_name: $body_name, notification_types: $notification_types, topic_name: $topic_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns insights for a set of local posts associated with a single listing. Which metrics and how they are reported are options specified in the request proto. *Note:* Insight reports are limited to 100 `local_post_names` per call.
#
# POST /v4/{name}/localPosts:reportInsights
# Returns: record<localPostMetrics: table<localPostName: string, metricValues: list>, name: string, timeZone: string>
# operationId: mybusiness.accounts.locations.localPosts.reportInsights
export def "mybusiness-accounts-locations-local-posts-report-insights" [
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
  --basic-request: record # A request for basic metric insights. — shape: {metricRequests?: list, timeRange?: record}
  --local-post-names: list<string> # Required. The list of posts for which to fetch insights data. All posts have to belong to the location whose name is specified in the `name` field.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/{name}/localPosts:reportInsights"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: basicRequest, var: basic_request}, {name: localPostNames, var: local_post_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, basic_request: $basic_request, local_post_names: $local_post_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all of the specified locations in the given account.
#
# POST /v4/{name}/locations:batchGet
# Returns: record<locations: table<adWordsLocationExtensions: record, additionalCategories: list, additionalPhones: list, address: record, attributes: list, labels: list, languageCode: string, latlng: record, locationKey: record, locationName: string, locationState: record, metadata: record, moreHours: list, name: string, openInfo: record, priceLists: list, primaryCategory: record, primaryPhone: string, profile: record, regularHours: record, relationshipData: record, serviceArea: record, specialHours: record, storeCode: string, websiteUrl: string>>
# operationId: mybusiness.accounts.locations.batchGet
export def "mybusiness-accounts-locations-batch-get" [
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
  --location-names: list<string> # A collection of locations to fetch, specified by their names.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/{name}/locations:batchGet"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: locationNames, var: location_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, location_names: $location_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the paginated list of reviews for all specified locations. This operation is only valid if the specified locations are verified. *Note:* Reviews are limited to a batch size of 200 `location_names` per call.
#
# POST /v4/{name}/locations:batchGetReviews
# Returns: record<locationReviews: table<name: string, review: record>, nextPageToken: string>
# operationId: mybusiness.accounts.locations.batchGetReviews
export def "mybusiness-accounts-locations-batch-get-reviews" [
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
  --ignore-rating-only-reviews: oneof<nothing, bool> # Whether to ignore rating-only reviews.
  --location-names: list<string> # A collection of locations to fetch reviews for, specified by their names.
  --order-by: string # Optional. Specifies the field to sort reviews by. If unspecified, the order of reviews returned will default to `update_time desc`. Valid orders to sort by are `rating`, `rating desc` and `update_time desc`. `rating` will return reviews in ascending order. `update_time`(i.e. ascending order) is not supported.
  --page-size: int # How many reviews to fetch per page. The default value is 200. (format: int32)
  --page-token: string # If specified, it fetches the next page of reviews.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/{name}/locations:batchGetReviews"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: ignoreRatingOnlyReviews, var: ignore_rating_only_reviews}, {name: locationNames, var: location_names}, {name: orderBy, var: order_by}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, ignore_rating_only_reviews: $ignore_rating_only_reviews, location_names: $location_names, order_by: $order_by, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a report containing insights on one or more metrics by location. *Note:* Insight reports are limited to a batch size of 10 `location_names` per call.
#
# POST /v4/{name}/locations:reportInsights
# Returns: record<locationDrivingDirectionMetrics: table<locationName: string, timeZone: string, topDirectionSources: list>, locationMetrics: table<locationName: string, metricValues: list, timeZone: string>>
# operationId: mybusiness.accounts.locations.reportInsights
export def "mybusiness-accounts-locations-report-insights" [
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
  --basic-request: record # A request for basic metric insights. — shape: {metricRequests?: list, timeRange?: record}
  --driving-directions-request: record # A request for driving direction insights. — shape: {languageCode?: string, numDays?: "SEVEN"|"THIRTY"|"NINETY"}
  --location-names: list<string> # A collection of locations to fetch insights for, specified by their names.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/{name}/locations:reportInsights"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: basicRequest, var: basic_request}, {name: drivingDirectionsRequest, var: driving_directions_request}, {name: locationNames, var: location_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, basic_request: $basic_request, driving_directions_request: $driving_directions_request, location_names: $location_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the response to the specified review. This operation is only valid if the specified location is verified.
#
# DELETE /v4/{name}/reply
# Returns: record
# operationId: mybusiness.accounts.locations.reviews.deleteReply
export def "mybusiness-accounts-locations-reviews-delete-reply" [
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
    method: delete
    path: "/v4/{name}/reply"
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

# Updates the reply to the specified review. A reply is created if one does not exist. This operation is only valid if the specified location is verified.
#
# PUT /v4/{name}/reply
# Returns: record<comment: string, updateTime: string>
# operationId: mybusiness.accounts.locations.reviews.updateReply
export def "mybusiness-accounts-locations-reviews-update-reply" [
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
  --comment: string # The body of the reply as plain text with markups. The maximum length is 4096 bytes.
  --update-time: string # Output only. The timestamp for when the reply was last modified. (format: google-datetime)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/{name}/reply"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: comment, var: comment}, {name: updateTime, var: update_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, comment: $comment, update_time: $update_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accepts the specified invitation.
#
# POST /v4/{name}:accept
# Returns: record
# operationId: mybusiness.accounts.invitations.accept
export def "mybusiness-accounts-invitations-accept" [
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/{name}:accept"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates a location to a place ID. Any previous association is overwritten. This operation is only valid if the location is unverified. The association must be valid, that is, it appears in the list of `FindMatchingLocations`.
#
# POST /v4/{name}:associate
# Returns: record
# operationId: mybusiness.accounts.locations.associate
export def "mybusiness-accounts-locations-associate" [
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
  --place-id: string # The association to establish. If not set, it indicates no match.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/{name}:associate"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: placeId, var: place_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, place_id: $place_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clears an association between a location and its place ID. This operation is only valid if the location is unverified.
#
# POST /v4/{name}:clearAssociation
# Returns: record
# operationId: mybusiness.accounts.locations.clearAssociation
export def "mybusiness-accounts-locations-clear-association" [
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/{name}:clearAssociation"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Completes a `PENDING` verification. It is only necessary for non `AUTO` verification methods. `AUTO` verification request is instantly `VERIFIED` upon creation.
#
# POST /v4/{name}:complete
# Returns: record<verification: record<createTime: string, method: string, name: string, state: string>>
# operationId: mybusiness.accounts.locations.verifications.complete
export def "mybusiness-accounts-locations-verifications-complete" [
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
  --pin: string # PIN code received by the merchant to complete the verification.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/{name}:complete"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: pin, var: pin}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, pin: $pin
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Declines the specified invitation.
#
# POST /v4/{name}:decline
# Returns: record
# operationId: mybusiness.accounts.invitations.decline
export def "mybusiness-accounts-invitations-decline" [
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/{name}:decline"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reports all eligible verification options for a location in a specific language.
#
# POST /v4/{name}:fetchVerificationOptions
# Returns: record<options: table<addressData: record, emailData: record, phoneData: record, verificationMethod: string>>
# operationId: mybusiness.accounts.locations.fetchVerificationOptions
export def "mybusiness-accounts-locations-fetch-verification-options" [
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
  --context: record # Additional data for service business verification. — shape: {address?: record}
  --language-code: string # The BCP 47 language code representing the language that is to be used for the verification process. Available options vary by language.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/{name}:fetchVerificationOptions"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: context, var: context}, {name: languageCode, var: language_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, context: $context, language_code: $language_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Finds all of the possible locations that are a match to the specified location. This operation is only valid if the location is unverified.
#
# POST /v4/{name}:findMatches
# Returns: record<matchTime: string, matchedLocations: table<isExactMatch: bool, location: record>>
# operationId: mybusiness.accounts.locations.findMatches
export def "mybusiness-accounts-locations-find-matches" [
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
  --language-code: string # The preferred language for the matching location (in BCP-47 format).
  --max-cache-duration: string # Deprecated. This field is ignored for all requests. (format: google-duration)
  --num-results: int # The number of matches to return. The default value is 3, with a maximum of 10. Note that latency may increase if more are requested. There is no pagination. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/{name}:findMatches"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: languageCode, var: language_code}, {name: maxCacheDuration, var: max_cache_duration}, {name: numResults, var: num_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, language_code: $language_code, max_cache_duration: $max_cache_duration, num_results: $num_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates an account number for this account. The account number is not provisioned when an account is created. Use this request to create an account number when it is required.
#
# POST /v4/{name}:generateAccountNumber
# Returns: record<accountName: string, accountNumber: string, name: string, organizationInfo: record<phoneNumber: string, postalAddress: record<addressLines: list, administrativeArea: string, languageCode: string, locality: string, organization: string, postalCode: string, recipients: list, regionCode: string, revision: int, sortingCode: string, sublocality: string>, registeredDomain: string>, permissionLevel: string, role: string, state: record<status: string>, type: string>
# operationId: mybusiness.accounts.generateAccountNumber
export def "mybusiness-accounts-generate-account-number" [
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/{name}:generateAccountNumber"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the Google updated Lodging of a specific location.
#
# GET /v4/{name}:getGoogleUpdated
# Returns: record<diffMask: string, lodging: record<accessibility: record<mobilityAccessible: bool, mobilityAccessibleElevator: bool, mobilityAccessibleElevatorException: string, mobilityAccessibleException: string, mobilityAccessibleParking: bool, mobilityAccessibleParkingException: string, mobilityAccessiblePool: bool, mobilityAccessiblePoolException: string>, activities: record<beachAccess: bool, beachAccessException: string, beachFront: bool, beachFrontException: string, bicycleRental: bool, bicycleRentalException: string, boutiqueStores: bool, boutiqueStoresException: string, casino: bool, casinoException: string, freeBicycleRental: bool, freeBicycleRentalException: string, freeWatercraftRental: bool, freeWatercraftRentalException: string, gameRoom: bool, gameRoomException: string, golf: bool, golfException: string, horsebackRiding: bool, horsebackRidingException: string, nightclub: bool, nightclubException: string, privateBeach: bool, privateBeachException: string, scuba: bool, scubaException: string, snorkeling: bool, snorkelingException: string, tennis: bool, tennisException: string, waterSkiing: bool, waterSkiingException: string, watercraftRental: bool, watercraftRentalException: string>, allUnits: record<bungalowOrVilla: bool, bungalowOrVillaException: string, connectingUnitAvailable: bool, connectingUnitAvailableException: string, executiveFloor: bool, executiveFloorException: string, maxAdultOccupantsCount: int, maxAdultOccupantsCountException: string, maxChildOccupantsCount: int, maxChildOccupantsCountException: string, maxOccupantsCount: int, maxOccupantsCountException: string, privateHome: bool, privateHomeException: string, suite: bool, suiteException: string, tier: string, tierException: string, totalLivingAreas: record, views: record>, business: record<businessCenter: bool, businessCenterException: string, meetingRooms: bool, meetingRoomsCount: int, meetingRoomsCountException: string, meetingRoomsException: string>, commonLivingArea: record<accessibility: record, eating: record, features: record, layout: record, sleeping: record>, connectivity: record<freeWifi: bool, freeWifiException: string, publicAreaWifiAvailable: bool, publicAreaWifiAvailableException: string, publicInternetTerminal: bool, publicInternetTerminalException: string, wifiAvailable: bool, wifiAvailableException: string>, families: record<babysitting: bool, babysittingException: string, kidsActivities: bool, kidsActivitiesException: string, kidsClub: bool, kidsClubException: string>, foodAndDrink: record<bar: bool, barException: string, breakfastAvailable: bool, breakfastAvailableException: string, breakfastBuffet: bool, breakfastBuffetException: string, buffet: bool, buffetException: string, dinnerBuffet: bool, dinnerBuffetException: string, freeBreakfast: bool, freeBreakfastException: string, restaurant: bool, restaurantException: string, restaurantsCount: int, restaurantsCountException: string, roomService: bool, roomServiceException: string, tableService: bool, tableServiceException: string, twentyFourHourRoomService: bool, twentyFourHourRoomServiceException: string, vendingMachine: bool, vendingMachineException: string>, guestUnits: list<record>, healthAndSafety: record<enhancedCleaning: record, increasedFoodSafety: record, minimizedContact: record, personalProtection: record, physicalDistancing: record>, housekeeping: record<dailyHousekeeping: bool, dailyHousekeepingException: string, housekeepingAvailable: bool, housekeepingAvailableException: string, turndownService: bool, turndownServiceException: string>, metadata: record<updateTime: string>, name: string, parking: record<electricCarChargingStations: bool, electricCarChargingStationsException: string, freeParking: bool, freeParkingException: string, freeSelfParking: bool, freeSelfParkingException: string, freeValetParking: bool, freeValetParkingException: string, parkingAvailable: bool, parkingAvailableException: string, selfParkingAvailable: bool, selfParkingAvailableException: string, valetParkingAvailable: bool, valetParkingAvailableException: string>, pets: record<catsAllowed: bool, catsAllowedException: string, dogsAllowed: bool, dogsAllowedException: string, petsAllowed: bool, petsAllowedException: string, petsAllowedFree: bool, petsAllowedFreeException: string>, policies: record<allInclusiveAvailable: bool, allInclusiveAvailableException: string, allInclusiveOnly: bool, allInclusiveOnlyException: string, checkinTime: record, checkinTimeException: string, checkoutTime: record, checkoutTimeException: string, kidsStayFree: bool, kidsStayFreeException: string, maxChildAge: int, maxChildAgeException: string, maxKidsStayFreeCount: int, maxKidsStayFreeCountException: string, paymentOptions: record, smokeFreeProperty: bool, smokeFreePropertyException: string>, pools: record<adultPool: bool, adultPoolException: string, hotTub: bool, hotTubException: string, indoorPool: bool, indoorPoolException: string, indoorPoolsCount: int, indoorPoolsCountException: string, lazyRiver: bool, lazyRiverException: string, lifeguard: bool, lifeguardException: string, outdoorPool: bool, outdoorPoolException: string, outdoorPoolsCount: int, outdoorPoolsCountException: string, pool: bool, poolException: string, poolsCount: int, poolsCountException: string, wadingPool: bool, wadingPoolException: string, waterPark: bool, waterParkException: string, waterslide: bool, waterslideException: string, wavePool: bool, wavePoolException: string>, property: record<builtYear: int, builtYearException: string, floorsCount: int, floorsCountException: string, lastRenovatedYear: int, lastRenovatedYearException: string, roomsCount: int, roomsCountException: string>, services: record<baggageStorage: bool, baggageStorageException: string, concierge: bool, conciergeException: string, convenienceStore: bool, convenienceStoreException: string, currencyExchange: bool, currencyExchangeException: string, elevator: bool, elevatorException: string, frontDesk: bool, frontDeskException: string, fullServiceLaundry: bool, fullServiceLaundryException: string, giftShop: bool, giftShopException: string, languagesSpoken: record, selfServiceLaundry: bool, selfServiceLaundryException: string, socialHour: bool, socialHourException: string, twentyFourHourFrontDesk: bool, twentyFourHourFrontDeskException: string, wakeUpCalls: bool, wakeUpCallsException: string>, someUnits: record<bungalowOrVilla: bool, bungalowOrVillaException: string, connectingUnitAvailable: bool, connectingUnitAvailableException: string, executiveFloor: bool, executiveFloorException: string, maxAdultOccupantsCount: int, maxAdultOccupantsCountException: string, maxChildOccupantsCount: int, maxChildOccupantsCountException: string, maxOccupantsCount: int, maxOccupantsCountException: string, privateHome: bool, privateHomeException: string, suite: bool, suiteException: string, tier: string, tierException: string, totalLivingAreas: record, views: record>, transportation: record<airportShuttle: bool, airportShuttleException: string, carRentalOnProperty: bool, carRentalOnPropertyException: string, freeAirportShuttle: bool, freeAirportShuttleException: string, freePrivateCarService: bool, freePrivateCarServiceException: string, localShuttle: bool, localShuttleException: string, privateCarService: bool, privateCarServiceException: string, transfer: bool, transferException: string>, wellness: record<doctorOnCall: bool, doctorOnCallException: string, ellipticalMachine: bool, ellipticalMachineException: string, fitnessCenter: bool, fitnessCenterException: string, freeFitnessCenter: bool, freeFitnessCenterException: string, freeWeights: bool, freeWeightsException: string, massage: bool, massageException: string, salon: bool, salonException: string, sauna: bool, saunaException: string, spa: bool, spaException: string, treadmill: bool, treadmillException: string, weightMachine: bool, weightMachineException: string>>>
# operationId: mybusiness.accounts.locations.lodging.getGoogleUpdated
export def "mybusiness-accounts-locations-lodging-get-google-updated" [
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
  --read-mask: string # Optional. The specific fields to return. If no mask is specified, then it returns the full Lodging (same as "*"). Repeated field items cannot be individually specified.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/{name}:getGoogleUpdated"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: readMask, var: read_mask}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, read_mask: $read_mask
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the Google-updated version of the specified location. Returns `NOT_FOUND` if the location does not exist.
#
# GET /v4/{name}:googleUpdated
# Returns: record<diffMask: string, location: record<adWordsLocationExtensions: record<adPhone: string>, additionalCategories: list<record>, additionalPhones: list<string>, address: record<addressLines: list, administrativeArea: string, languageCode: string, locality: string, organization: string, postalCode: string, recipients: list, regionCode: string, revision: int, sortingCode: string, sublocality: string>, attributes: list<record>, labels: list<string>, languageCode: string, latlng: record<latitude: float, longitude: float>, locationKey: record<explicitNoPlaceId: bool, placeId: string, plusPageId: string, requestId: string>, locationName: string, locationState: record<canDelete: bool, canHaveFoodMenus: bool, canModifyServiceList: bool, canOperateHealthData: bool, canOperateLodgingData: bool, canUpdate: bool, hasPendingEdits: bool, hasPendingVerification: bool, isDisabled: bool, isDisconnected: bool, isDuplicate: bool, isGoogleUpdated: bool, isLocalPostApiDisabled: bool, isPendingReview: bool, isPublished: bool, isSuspended: bool, isVerified: bool, needsReverification: bool>, metadata: record<duplicate: record, mapsUrl: string, newReviewUrl: string>, moreHours: list<record>, name: string, openInfo: record<canReopen: bool, openingDate: record, status: string>, priceLists: list<record>, primaryCategory: record<categoryId: string, displayName: string, moreHoursTypes: list, serviceTypes: list>, primaryPhone: string, profile: record<description: string>, regularHours: record<periods: list>, relationshipData: record<parentChain: string>, serviceArea: record<businessType: string, places: record, radius: record>, specialHours: record<specialHourPeriods: list>, storeCode: string, websiteUrl: string>>
# operationId: mybusiness.accounts.locations.getGoogleUpdated
export def "mybusiness-accounts-locations-get-google-updated" [
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
    path: "/v4/{name}:googleUpdated"
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

# List all the GoogleLocations that have been recommended to the specified Business Profile account. Recommendations are provided for personal accounts and location groups only, requests for all other account types will result in an error. The recommendations for location groups are based on the locations in that group. The recommendations for personal accounts are based on all of the locations that the user has access to on Business Profile (which includes locations they can access through location groups), and is a superset of all recommendations generated for the user.
#
# GET /v4/{name}:recommendGoogleLocations
# Returns: record<googleLocations: table<location: record, name: string, requestAdminRightsUrl: string>, nextPageToken: string, totalSize: int>
# operationId: mybusiness.accounts.listRecommendGoogleLocations
export def "mybusiness-accounts-list-recommend-google-locations" [
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
  --page-size: int # How many locations to fetch per page. Default is 25, minimum is 1, and maximum page size is 100.
  --page-token: string # If specified, the next page of locations is retrieved.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/{name}:recommendGoogleLocations"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Report a GoogleLocation.
#
# POST /v4/{name}:report
# Returns: record
# operationId: mybusiness.googleLocations.report
export def "mybusiness-google-locations-report" [
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
  --location-group-name: string # Optional. The resource name of the location group that this Google Location is being reported for, in the format `accounts/{account_id}`.
  --report-reason-bad-location: string@report-reason-bad-location-completer # The reason for which the user is reporting this location when the issue is with the location itself.
  --report-reason-bad-recommendation: string@report-reason-bad-recommendation-completer # The reason for which the user is reporting this location when the issue is with the recommendation. This report is useful if the location has been recommended to the Business Profile account.
  --report-reason-elaboration: string # Optional. A text entry for elaborating on the reason for which the user is reporting this location. The maximum length is 512 characters.
  --report-reason-language-code: string # Optional. The BCP 47 code of language used in `report_reason_elaboration`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/{name}:report"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: locationGroupName, var: location_group_name}, {name: reportReasonBadLocation, var: report_reason_bad_location}, {name: reportReasonBadRecommendation, var: report_reason_bad_recommendation}, {name: reportReasonElaboration, var: report_reason_elaboration}, {name: reportReasonLanguageCode, var: report_reason_language_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, location_group_name: $location_group_name, report_reason_bad_location: $report_reason_bad_location, report_reason_bad_recommendation: $report_reason_bad_recommendation, report_reason_elaboration: $report_reason_elaboration, report_reason_language_code: $report_reason_language_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Moves a location from an account that the user owns to another account that the same user administers. The user must be an owner of the account the location is currently associated with and must also be at least a manager of the destination account. Returns the Location with its new resource name.
#
# POST /v4/{name}:transfer
# Returns: record<adWordsLocationExtensions: record<adPhone: string>, additionalCategories: table<categoryId: string, displayName: string, moreHoursTypes: list, serviceTypes: list>, additionalPhones: list<string>, address: record<addressLines: list<string>, administrativeArea: string, languageCode: string, locality: string, organization: string, postalCode: string, recipients: list<string>, regionCode: string, revision: int, sortingCode: string, sublocality: string>, attributes: table<attributeId: string, repeatedEnumValue: record, urlValues: list, valueType: string, values: list>, labels: list<string>, languageCode: string, latlng: record<latitude: float, longitude: float>, locationKey: record<explicitNoPlaceId: bool, placeId: string, plusPageId: string, requestId: string>, locationName: string, locationState: record<canDelete: bool, canHaveFoodMenus: bool, canModifyServiceList: bool, canOperateHealthData: bool, canOperateLodgingData: bool, canUpdate: bool, hasPendingEdits: bool, hasPendingVerification: bool, isDisabled: bool, isDisconnected: bool, isDuplicate: bool, isGoogleUpdated: bool, isLocalPostApiDisabled: bool, isPendingReview: bool, isPublished: bool, isSuspended: bool, isVerified: bool, needsReverification: bool>, metadata: record<duplicate: record<access: string, locationName: string, placeId: string>, mapsUrl: string, newReviewUrl: string>, moreHours: table<hoursTypeId: string, periods: list>, name: string, openInfo: record<canReopen: bool, openingDate: record<day: int, month: int, year: int>, status: string>, priceLists: table<labels: list, priceListId: string, sections: list, sourceUrl: string>, primaryCategory: record<categoryId: string, displayName: string, moreHoursTypes: list<record>, serviceTypes: list<record>>, primaryPhone: string, profile: record<description: string>, regularHours: record<periods: list<record>>, relationshipData: record<parentChain: string>, serviceArea: record<businessType: string, places: record<placeInfos: list>, radius: record<latlng: record, radiusKm: float>>, specialHours: record<specialHourPeriods: list<record>>, storeCode: string, websiteUrl: string>
# operationId: mybusiness.accounts.locations.transfer
export def "mybusiness-accounts-locations-transfer" [
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
  --to-account: string # Name of the account resource to transfer the location to (for example, "accounts/8675309").
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/{name}:transfer"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: toAccount, var: to_account}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, to_account: $to_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts the verification process for a location.
#
# POST /v4/{name}:verify
# Returns: record<verification: record<createTime: string, method: string, name: string, state: string>>
# operationId: mybusiness.accounts.locations.verify
export def "mybusiness-accounts-locations-verify" [
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
  --address-input: record # Input for ADDRESS verification. — shape: {mailerContactName?: string}
  --context: record # Additional data for service business verification. — shape: {address?: record}
  --email-input: record # Input for EMAIL verification. — shape: {emailAddress?: string}
  --language-code: string # The BCP 47 language code representing the language that is to be used for the verification process.
  --method: string@method-completer # Verification method.
  --phone-input: record # Input for PHONE_CALL/SMS verification. — shape: {phoneNumber?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/{name}:verify"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: addressInput, var: address_input}, {name: context, var: context}, {name: emailInput, var: email_input}, {name: languageCode, var: language_code}, {name: method, var: method}, {name: phoneInput, var: phone_input}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, address_input: $address_input, context: $context, email_input: $email_input, language_code: $language_code, method: $method, phone_input: $phone_input
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the admins for the specified location.
#
# GET /v4/{parent}/admins
# Returns: record<admins: table<adminName: string, name: string, pendingInvitation: bool, role: string>>
# operationId: mybusiness.accounts.locations.admins.list
export def "mybusiness-accounts-locations-admins-list" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/{parent}/admins"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invites the specified user to become an administrator for the specified location. The invitee must accept the invitation in order to be granted access to the location. See AcceptInvitation to programmatically accept an invitation.
#
# POST /v4/{parent}/admins
# Returns: record<adminName: string, name: string, pendingInvitation: bool, role: string>
# operationId: mybusiness.accounts.locations.admins.create
export def "mybusiness-accounts-locations-admins-create" [
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
  --admin-name: string # The name of the admin. When making the initial invitation, this is the invitee's email address. On `GET` calls, the user's email address is returned if the invitation is still pending. Otherwise, it contains the user's first and last names.
  --name: string # The resource name. For account admins, this is in the form: `accounts/{account_id}/admins/{admin_id}` For location admins, this is in the form: `accounts/{account_id}/locations/{location_id}/admins/{admin_id}`
  --pending-invitation: oneof<nothing, bool> # Output only. Indicates whether this admin has a pending invitation for the specified resource.
  --role: string@role-completer-1 # Specifies the AdminRole that this admin uses with the specified Account or Location resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/{parent}/admins"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: adminName, var: admin_name}, {name: name, var: name}, {name: pendingInvitation, var: pending_invitation}, {name: role, var: role}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, admin_name: $admin_name, name: $name, pending_invitation: $pending_invitation, role: $role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the paginated list of answers for a specified question.
#
# GET /v4/{parent}/answers
# Returns: record<answers: table<author: record, createTime: string, name: string, text: string, updateTime: string, upvoteCount: int>, nextPageToken: string, totalSize: int>
# operationId: mybusiness.accounts.locations.questions.answers.list
export def "mybusiness-accounts-locations-questions-answers-list" [
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
  --order-by: string # The order to return the answers. Valid options include 'update_time desc' and 'upvote_count desc', which will return the answers sorted descendingly by the requested field. The default sort order is 'update_time desc'.
  --page-size: int # How many answers to fetch per page. The default and maximum `page_size` values are 10.
  --page-token: string # If specified, the next page of answers is retrieved.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/{parent}/answers"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: orderBy, var: order_by}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, order_by: $order_by, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the answer written by the current user to a question.
#
# DELETE /v4/{parent}/answers:delete
# Returns: record
# operationId: mybusiness.accounts.locations.questions.answers.delete
export def "mybusiness-accounts-locations-questions-answers-delete" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v4/{parent}/answers:delete"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an answer or updates the existing answer written by the user for the specified question. A user can only create one answer per question.
#
# POST /v4/{parent}/answers:upsert
# Returns: record<author: record<displayName: string, profilePhotoUrl: string, type: string>, createTime: string, name: string, text: string, updateTime: string, upvoteCount: int>
# operationId: mybusiness.accounts.locations.questions.answers.upsert
export def "mybusiness-accounts-locations-questions-answers-upsert" [
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
  --answer: record # Represents an answer to a question — shape: {author?: record, createTime?: string, name?: string, text?: string, updateTime?: string, upvoteCount?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/{parent}/answers:upsert"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: answer, var: answer}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, answer: $answer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of all insurance networks supported by Google.
#
# GET /v4/{parent}/insuranceNetworks
# Returns: record<networks: table<networkId: string, networkNames: record, payerNames: record, state: string>, nextPageToken: string>
# operationId: mybusiness.accounts.locations.insuranceNetworks.list
export def "mybusiness-accounts-locations-insurance-networks-list" [
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
  --language-code: string # Optional. The BCP 47 code for the language. If a language code is not provided, it defaults to English. Right now only 'en' is supported.
  --page-size: int # How many insurance networks to return per page. The default value is 5000. Maximum page size is 10000.
  --page-token: string # If specified, returns the next page of insurance networks.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/{parent}/insuranceNetworks"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: languageCode, var: language_code}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, language_code: $language_code, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists pending invitations for the specified account.
#
# GET /v4/{parent}/invitations
# Returns: record<invitations: table<name: string, role: string, targetAccount: record, targetLocation: record>>
# operationId: mybusiness.accounts.invitations.list
export def "mybusiness-accounts-invitations-list" [
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
  --target-type: string@target-type-completer # Specifies which target types should appear in the response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/{parent}/invitations"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: targetType, var: target_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, target_type: $target_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of local posts associated with a location.
#
# GET /v4/{parent}/localPosts
# Returns: record<localPosts: table<alertType: string, callToAction: record, createTime: string, event: record, languageCode: string, media: list, name: string, offer: record, searchUrl: string, state: string, summary: string, topicType: string, updateTime: string>, nextPageToken: string>
# operationId: mybusiness.accounts.locations.localPosts.list
export def "mybusiness-accounts-locations-local-posts-list" [
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
  --page-size: int # How many local posts to return per page. Default of 20. The minimum is 1, and maximum page size is 100.
  --page-token: string # If specified, returns the next page of local posts.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/{parent}/localPosts"
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

# Creates a new local post associated with the specified location, and returns it.
#
# POST /v4/{parent}/localPosts
# Returns: record<alertType: string, callToAction: record<actionType: string, url: string>, createTime: string, event: record<schedule: record<endDate: record, endTime: record, startDate: record, startTime: record>, title: string>, languageCode: string, media: table<attribution: record, createTime: string, dataRef: record, description: string, dimensions: record, googleUrl: string, insights: record, locationAssociation: record, mediaFormat: string, name: string, sourceUrl: string, thumbnailUrl: string>, name: string, offer: record<couponCode: string, redeemOnlineUrl: string, termsConditions: string>, searchUrl: string, state: string, summary: string, topicType: string, updateTime: string>
# operationId: mybusiness.accounts.locations.localPosts.create
export def "mybusiness-accounts-locations-local-posts-create" [
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
  --alert-type: string@alert-type-completer # The type of alert the post is created for. This field is only applicable for posts of topic_type Alert, and behaves as a sub-type of Alerts.
  --call-to-action: record # An action that is performed when the user clicks through the post — shape: {actionType?: "ACTION_TYPE_UNSPECIFIED"|"BOOK"|"ORDER"|"SHOP"|"LEARN_MORE"|"SIGN_UP"|"GET_OFFER"|"CALL", url?: string}
  --create-time: string # Output only. Time of the creation of the post. (format: google-datetime)
  --event: record # All the information pertaining to an event featured in a local post. — shape: {schedule?: record, title?: string}
  --language-code: string # The language of the local post.
  --media: list # The media associated with the post. source_url is the only supported data field for a LocalPost MediaItem. — item shape: {attribution?: record, createTime?: string, dataRef?: record, description?: string, dimensions?: record, googleUrl?: string, insights?: record, locationAssociation?: record, mediaFormat?: "MEDIA_FORMAT_UNSPECIFIED"|"PHOTO"|"VIDEO", name?: string, sourceUrl?: string, thumbnailUrl?: string}
  --name: string # Output only. Google identifier for this local post in the form: `accounts/{account_id}/locations/{location_id}/localPosts/{local_post_id}`
  --offer: record # Specific fields for offer posts. — shape: {couponCode?: string, redeemOnlineUrl?: string, termsConditions?: string}
  --search-url: string # Output only. The link to the local post in Google search. This link can be used to share the post via social media, email, text, etc.
  --state: string@state-completer # Output only. The state of the post, indicating what part of its lifecycle it is in.
  --summary: string # Description/body of the local post.
  --topic-type: string@topic-type-completer # Required. The topic type of the post: standard, event, offer, or alert.
  --update-time: string # Output only. Time of the last modification of the post made by the user. (format: google-datetime)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/{parent}/localPosts"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: alertType, var: alert_type}, {name: callToAction, var: call_to_action}, {name: createTime, var: create_time}, {name: event, var: event}, {name: languageCode, var: language_code}, {name: media, var: media}, {name: name, var: name}, {name: offer, var: offer}, {name: searchUrl, var: search_url}, {name: state, var: state}, {name: summary, var: summary}, {name: topicType, var: topic_type}, {name: updateTime, var: update_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, alert_type: $alert_type, call_to_action: $call_to_action, create_time: $create_time, event: $event, language_code: $language_code, media: $media, name: $name, offer: $offer, search_url: $search_url, state: $state, summary: $summary, topic_type: $topic_type, update_time: $update_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the locations for the specified account.
#
# GET /v4/{parent}/locations
# Returns: record<locations: table<adWordsLocationExtensions: record, additionalCategories: list, additionalPhones: list, address: record, attributes: list, labels: list, languageCode: string, latlng: record, locationKey: record, locationName: string, locationState: record, metadata: record, moreHours: list, name: string, openInfo: record, priceLists: list, primaryCategory: record, primaryPhone: string, profile: record, regularHours: record, relationshipData: record, serviceArea: record, specialHours: record, storeCode: string, websiteUrl: string>, nextPageToken: string, totalSize: int>
# operationId: mybusiness.accounts.locations.list
export def "mybusiness-accounts-locations-list" [
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
  --filter: string # A filter constraining the locations to return. The response includes only entries that match the filter. If `filter` is empty, then constraints are applied and all locations (paginated) are retrieved for the requested account. For more information about valid fields and example usage, see [Work with Location Data Guide](https://developers.google.com/my-business/content/location-data#filter_results_when_you_list_locations).
  --language-code: string # The BCP 47 code of language to get display location properties in. If this language is not available, they will be provided in the language of the location. If neither is available, they will be provided in English. Deprecated. After August 15th, 2020, this field will no longer be applied. Instead, the language of the location will always be used.
  --order-by: string # Sorting order for the request. Multiple fields should be comma-separated, following SQL syntax. The default sorting order is ascending. To specify descending order, a suffix " desc" should be added. Valid fields to order_by are location_name and store_code. For example: "location_name, store_code desc" or "location_name" or "store_code desc"
  --page-size: int # How many locations to fetch per page. Default is 100, minimum is 1, and maximum page size is 100.
  --page-token: string # If specified, it fetches the next `page` of locations. The page token is returned by previous calls to `ListLocations` when there were more locations than could fit in the requested page size.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/{parent}/locations"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: languageCode, var: language_code}, {name: orderBy, var: order_by}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, language_code: $language_code, order_by: $order_by, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new location owned by the specified account, and returns it.
#
# POST /v4/{parent}/locations
# Returns: record<adWordsLocationExtensions: record<adPhone: string>, additionalCategories: table<categoryId: string, displayName: string, moreHoursTypes: list, serviceTypes: list>, additionalPhones: list<string>, address: record<addressLines: list<string>, administrativeArea: string, languageCode: string, locality: string, organization: string, postalCode: string, recipients: list<string>, regionCode: string, revision: int, sortingCode: string, sublocality: string>, attributes: table<attributeId: string, repeatedEnumValue: record, urlValues: list, valueType: string, values: list>, labels: list<string>, languageCode: string, latlng: record<latitude: float, longitude: float>, locationKey: record<explicitNoPlaceId: bool, placeId: string, plusPageId: string, requestId: string>, locationName: string, locationState: record<canDelete: bool, canHaveFoodMenus: bool, canModifyServiceList: bool, canOperateHealthData: bool, canOperateLodgingData: bool, canUpdate: bool, hasPendingEdits: bool, hasPendingVerification: bool, isDisabled: bool, isDisconnected: bool, isDuplicate: bool, isGoogleUpdated: bool, isLocalPostApiDisabled: bool, isPendingReview: bool, isPublished: bool, isSuspended: bool, isVerified: bool, needsReverification: bool>, metadata: record<duplicate: record<access: string, locationName: string, placeId: string>, mapsUrl: string, newReviewUrl: string>, moreHours: table<hoursTypeId: string, periods: list>, name: string, openInfo: record<canReopen: bool, openingDate: record<day: int, month: int, year: int>, status: string>, priceLists: table<labels: list, priceListId: string, sections: list, sourceUrl: string>, primaryCategory: record<categoryId: string, displayName: string, moreHoursTypes: list<record>, serviceTypes: list<record>>, primaryPhone: string, profile: record<description: string>, regularHours: record<periods: list<record>>, relationshipData: record<parentChain: string>, serviceArea: record<businessType: string, places: record<placeInfos: list>, radius: record<latlng: record, radiusKm: float>>, specialHours: record<specialHourPeriods: list<record>>, storeCode: string, websiteUrl: string>
# operationId: mybusiness.accounts.locations.create
export def "mybusiness-accounts-locations-create" [
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
  --request-id: string # A unique request ID for the server to detect duplicated requests. We recommend using UUIDs. Max length is 50 characters.
  --validate-only: oneof<nothing, bool> # If true, the request is validated without actually creating the location.
  --ad-words-location-extensions: record # Additional information that is surfaced in AdWords. — shape: {adPhone?: string}
  --additional-categories: list # Additional categories to describe your business. Categories help your customers find accurate, specific results for services they're interested in. To keep your business information accurate and live, make sure that you use as few categories as possible to describe your overall core business. Choose categories that are as specific as possible, but representative of your main business. — item shape: {categoryId?: string, displayName?: string, serviceTypes?: list}
  --additional-phones: list<string> # Up to two phone numbers (mobile or landline, no fax) at which your business can be called, in addition to your primary phone number.
  --address: record # Represents a postal address, e.g. for postal delivery or payments addresses. Given a postal address, a postal service can deliver items to a premise, P.O. Box or similar. It is not intended to model geographical locations (roads, towns, mountains). In typical usage an address would be created via user input or from importing existing data, depending on the type of process. Advice on address input / editing: - Use an i18n-ready address widget such as https://github.com/google/libaddressinput) - Users should not be presented with UI elements for input or editing of fields outside countries where that field is used. For more guidance on how to use this schema, please see: https://support.google.com/business/answer/6397478 — shape: {addressLines?: list<string>, administrativeArea?: string, languageCode?: string, locality?: string, organization?: string, postalCode?: string, recipients?: list<string>, regionCode?: string, revision?: int, sortingCode?: string, sublocality?: string}
  --attributes: list # Attributes for this location. — item shape: {attributeId?: string, repeatedEnumValue?: record, urlValues?: list, valueType?: "ATTRIBUTE_VALUE_TYPE_UNSPECIFIED"|"BOOL"|"ENUM"|"URL"|"REPEATED_ENUM", values?: list}
  --labels: list<string> # A collection of free-form strings to allow you to tag your business. These labels are NOT user facing; only you can see them. Limited to 255 characters (per label).
  --language-code: string # The language of the location. Set during creation and not updateable.
  --latlng: record # An object that represents a latitude/longitude pair. This is expressed as a pair of doubles to represent degrees latitude and degrees longitude. Unless specified otherwise, this must conform to the WGS84 standard. Values must be within normalized ranges. — shape: {latitude?: float, longitude?: float}
  --location-key: record # Alternate/surrogate key references for a location. — shape: {explicitNoPlaceId?: bool, placeId?: string, plusPageId?: string, requestId?: string}
  --location-name: string # Location name should reflect your business's real-world name, as used consistently on your storefront, website, and stationery, and as known to customers. Any additional information, when relevant, can be included in other fields of the resource (for example, `Address`, `Categories`). Don't add unnecessary information to your name (for example, prefer "Google" over "Google Inc. - Mountain View Corporate Headquarters"). Don't include marketing taglines, store codes, special characters, hours or closed/open status, phone numbers, website URLs, service/product information, location/address or directions, or containment information (for example, "Chase ATM in Duane Reade").
  --location-state: record # Contains a set of booleans that reflect the [state of a Location.](https://support.google.com/business/answer/3480862) — shape: {canDelete?: bool, canUpdate?: bool, hasPendingEdits?: bool, hasPendingVerification?: bool, isDisabled?: bool, isDisconnected?: bool, isDuplicate?: bool, isGoogleUpdated?: bool, isLocalPostApiDisabled?: bool, isPendingReview?: bool, isPublished?: bool, isSuspended?: bool, isVerified?: bool, needsReverification?: bool}
  --metadata: record # Additional non-user-editable information about the location. — shape: {duplicate?: record, mapsUrl?: string, newReviewUrl?: string}
  --more-hours: list # More hours for a business's different departments or specific customers. — item shape: {hoursTypeId?: string, periods?: list}
  --name: string # Google identifier for this location in the form: `accounts/{account_id}/locations/{location_id}` In the context of matches, this field will not be populated.
  --open-info: record # Information related to the opening state of the business. — shape: {canReopen?: bool, openingDate?: record, status?: "OPEN_FOR_BUSINESS_UNSPECIFIED"|"OPEN"|"CLOSED_PERMANENTLY"|"CLOSED_TEMPORARILY"}
  --price-lists: list # Price list information for this location. — item shape: {labels?: list, priceListId?: string, sections?: list, sourceUrl?: string}
  --primary-category: record # A category describing what this business is (not what it does). For a list of valid category IDs, and the mappings to their human-readable names, see [categories.list](https://developers.google.com/my-business/reference/rest/v4/categories/list). — shape: {categoryId?: string, displayName?: string, serviceTypes?: list}
  --primary-phone: string # A phone number that connects to your individual business location as directly as possible. Use a local phone number instead of a central, call center helpline number whenever possible.
  --profile: record # All information pertaining to the location's profile. — shape: {description?: string}
  --regular-hours: record # Represents the time periods that this location is open for business. Holds a collection of TimePeriod instances. — shape: {periods?: list}
  --relationship-data: record # Information of all parent and children locations related to this one. — shape: {parentChain?: string}
  --service-area: record # Service area businesses provide their service at the customer's location (for example, a locksmith or plumber). — shape: {businessType?: "BUSINESS_TYPE_UNSPECIFIED"|"CUSTOMER_LOCATION_ONLY"|"CUSTOMER_AND_BUSINESS_LOCATION", places?: record, radius?: record}
  --special-hours: record # Represents a set of time periods when a location's operational hours differ from its normal business hours. — shape: {specialHourPeriods?: list}
  --store-code: string # External identifier for this location, which must be unique inside a given account. This is a means of associating the location with your own records.
  --website-url: string # A URL for this business. If possible, use a URL that represents this individual business location instead of a generic website/URL that represents all locations, or the brand.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/{parent}/locations"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: requestId, var: request_id}, {name: validateOnly, var: validate_only}]
    body: {content_type: "application/json", kind: json, fields: [{name: adWordsLocationExtensions, var: ad_words_location_extensions}, {name: additionalCategories, var: additional_categories}, {name: additionalPhones, var: additional_phones}, {name: address, var: address}, {name: attributes, var: attributes}, {name: labels, var: labels}, {name: languageCode, var: language_code}, {name: latlng, var: latlng}, {name: locationKey, var: location_key}, {name: locationName, var: location_name}, {name: locationState, var: location_state}, {name: metadata, var: metadata}, {name: moreHours, var: more_hours}, {name: name, var: name}, {name: openInfo, var: open_info}, {name: priceLists, var: price_lists}, {name: primaryCategory, var: primary_category}, {name: primaryPhone, var: primary_phone}, {name: profile, var: profile}, {name: regularHours, var: regular_hours}, {name: relationshipData, var: relationship_data}, {name: serviceArea, var: service_area}, {name: specialHours, var: special_hours}, {name: storeCode, var: store_code}, {name: websiteUrl, var: website_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, request_id: $request_id, validate_only: $validate_only, ad_words_location_extensions: $ad_words_location_extensions, additional_categories: $additional_categories, additional_phones: $additional_phones, address: $address, attributes: $attributes, labels: $labels, language_code: $language_code, latlng: $latlng, location_key: $location_key, location_name: $location_name, location_state: $location_state, metadata: $metadata, more_hours: $more_hours, name: $name, open_info: $open_info, price_lists: $price_lists, primary_category: $primary_category, primary_phone: $primary_phone, profile: $profile, regular_hours: $regular_hours, relationship_data: $relationship_data, service_area: $service_area, special_hours: $special_hours, store_code: $store_code, website_url: $website_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of media items associated with a location.
#
# GET /v4/{parent}/media
# Returns: record<mediaItems: table<attribution: record, createTime: string, dataRef: record, description: string, dimensions: record, googleUrl: string, insights: record, locationAssociation: record, mediaFormat: string, name: string, sourceUrl: string, thumbnailUrl: string>, nextPageToken: string, totalMediaItemCount: int>
# operationId: mybusiness.accounts.locations.media.list
export def "mybusiness-accounts-locations-media-list" [
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
  --page-size: int # How many media items to return per page. The default value is 100, which is also the maximum supported number of media items able to be added to a location with the Google My Business API. Maximum page size is 2500.
  --page-token: string # If specified, returns the next page of media items.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/{parent}/media"
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

# Creates a new media item for the location.
#
# POST /v4/{parent}/media
# Returns: record<attribution: record<profileName: string, profilePhotoUrl: string, profileUrl: string, takedownUrl: string>, createTime: string, dataRef: record<resourceName: string>, description: string, dimensions: record<heightPixels: int, widthPixels: int>, googleUrl: string, insights: record<viewCount: string>, locationAssociation: record<category: string, priceListItemId: string>, mediaFormat: string, name: string, sourceUrl: string, thumbnailUrl: string>
# operationId: mybusiness.accounts.locations.media.create
export def "mybusiness-accounts-locations-media-create" [
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
  --attribution: record # Attribution information for customer media items, such as the contributor's name and profile picture. — shape: {profileName?: string, profilePhotoUrl?: string, profileUrl?: string, takedownUrl?: string}
  --create-time: string # Output only. Creation time of this media item. (format: google-datetime)
  --data-ref: record # Reference to the photo binary data of a `MediaItem` uploaded through the Google My Business API. Create a data ref using StartUploadMediaItemData, and use this ref when uploading bytes to [UpdateMedia] and subsequently calling CreateMediaItem. — shape: {resourceName?: string}
  --description: string # Description for this media item. Descriptions cannot be modified through the Google My Business API, but can be set when creating a new media item that is not a cover photo.
  --dimensions: record # Dimensions of the media item. — shape: {heightPixels?: int, widthPixels?: int}
  --google-url: string # Output only. Google-hosted URL for this media item. This URL is not static since it may change over time. For video this will be a preview image with an overlaid play icon.
  --insights: record # Insights and statistics for the media item. — shape: {viewCount?: string}
  --location-association: record # How the media item is associated with its location. — shape: {category?: "CATEGORY_UNSPECIFIED"|"COVER"|"PROFILE"|"LOGO"|"EXTERIOR"|"INTERIOR"|"PRODUCT"|"AT_WORK"|"FOOD_AND_DRINK"|"MENU"|"COMMON_AREA"|"ROOMS"|"TEAMS"|"ADDITIONAL", priceListItemId?: string}
  --media-format: string@media-format-completer # The format of this media item. Must be set when the media item is created, and is read-only on all other requests. Cannot be updated.
  --name: string # The resource name for this media item. `accounts/{account_id}/locations/{location_id}/media/{media_key}`
  --source-url: string # A publicly accessible URL where the media item can be retrieved from. When creating one of this or data_ref must be set to specify the source of the media item. If `source_url` was used when creating a media item, it will be populated with that source URL when the media item is retrieved. This field cannot be updated.
  --thumbnail-url: string # Output only. Where provided, the URL of a thumbnail image for this media item.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/{parent}/media"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: attribution, var: attribution}, {name: createTime, var: create_time}, {name: dataRef, var: data_ref}, {name: description, var: description}, {name: dimensions, var: dimensions}, {name: googleUrl, var: google_url}, {name: insights, var: insights}, {name: locationAssociation, var: location_association}, {name: mediaFormat, var: media_format}, {name: name, var: name}, {name: sourceUrl, var: source_url}, {name: thumbnailUrl, var: thumbnail_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, attribution: $attribution, create_time: $create_time, data_ref: $data_ref, description: $description, dimensions: $dimensions, google_url: $google_url, insights: $insights, location_association: $location_association, media_format: $media_format, name: $name, source_url: $source_url, thumbnail_url: $thumbnail_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of media items associated with a location that have been contributed by customers.
#
# GET /v4/{parent}/media/customers
# Returns: record<mediaItems: table<attribution: record, createTime: string, dataRef: record, description: string, dimensions: record, googleUrl: string, insights: record, locationAssociation: record, mediaFormat: string, name: string, sourceUrl: string, thumbnailUrl: string>, nextPageToken: string, totalMediaItemCount: int>
# operationId: mybusiness.accounts.locations.media.customers.list
export def "mybusiness-accounts-locations-media-customers-list" [
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
  --page-size: int # How many media items to return per page. The default value is 100, the maximum supported page size is 200.
  --page-token: string # If specified, returns the next page of media items.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/{parent}/media/customers"
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

# Generates a `MediaItemDataRef` for media item uploading.
#
# POST /v4/{parent}/media:startUpload
# Returns: record<resourceName: string>
# operationId: mybusiness.accounts.locations.media.startUpload
export def "mybusiness-accounts-locations-media-start-upload" [
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/{parent}/media:startUpload"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the paginated list of questions and some of its answers for a specified location.
#
# GET /v4/{parent}/questions
# Returns: record<nextPageToken: string, questions: table<author: record, createTime: string, name: string, text: string, topAnswers: list, totalAnswerCount: int, updateTime: string, upvoteCount: int>, totalSize: int>
# operationId: mybusiness.accounts.locations.questions.list
export def "mybusiness-accounts-locations-questions-list" [
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
  --answers-per-question: int # How many answers to fetch per question. The default and maximum `answers_per_question` values are 10.
  --filter: string # A filter constraining the questions to return. The only filter currently supported is "ignore_answered=true"
  --order-by: string # The order to return the questions. Valid options include 'update_time desc' and 'upvote_count desc', which will return the questions sorted descendingly by the requested field. The default sort order is 'update_time desc'.
  --page-size: int # How many questions to fetch per page. The default and maximum `page_size` values are 10.
  --page-token: string # If specified, the next page of questions is retrieved.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/{parent}/questions"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: answersPerQuestion, var: answers_per_question}, {name: filter, var: filter}, {name: orderBy, var: order_by}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, answers_per_question: $answers_per_question, filter: $filter, order_by: $order_by, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a question for the specified location.
#
# POST /v4/{parent}/questions
# Returns: record<author: record<displayName: string, profilePhotoUrl: string, type: string>, createTime: string, name: string, text: string, topAnswers: table<author: record, createTime: string, name: string, text: string, updateTime: string, upvoteCount: int>, totalAnswerCount: int, updateTime: string, upvoteCount: int>
# operationId: mybusiness.accounts.locations.questions.create
export def "mybusiness-accounts-locations-questions-create" [
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
  --author: record # Represents the author of a question or answer — shape: {displayName?: string, profilePhotoUrl?: string, type?: "AUTHOR_TYPE_UNSPECIFIED"|"REGULAR_USER"|"LOCAL_GUIDE"|"MERCHANT"}
  --create-time: string # Output only. The timestamp for when the question was written. (format: google-datetime)
  --name: string # Output only. The unique name for the question. accounts/*/locations/*/questions/*
  --text: string # The text of the question. It should contain at least three words and the total length should be greater than or equal to 10 characters. The maximum length is 4096 characters.
  --top-answers: list # Output only. A list of answers to the question, sorted by upvotes. This may not be a complete list of answers depending on the request parameters (answers_per_question) — item shape: {author?: record, createTime?: string, name?: string, text?: string, updateTime?: string, upvoteCount?: int}
  --total-answer-count: int # Output only. The total number of answers posted for this question. (format: int32)
  --update-time: string # Output only. The timestamp for when the question was last modified. (format: google-datetime)
  --upvote-count: int # Output only. The number of upvotes for the question. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/{parent}/questions"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: author, var: author}, {name: createTime, var: create_time}, {name: name, var: name}, {name: text, var: text}, {name: topAnswers, var: top_answers}, {name: totalAnswerCount, var: total_answer_count}, {name: updateTime, var: update_time}, {name: upvoteCount, var: upvote_count}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, author: $author, create_time: $create_time, name: $name, text: $text, top_answers: $top_answers, total_answer_count: $total_answer_count, update_time: $update_time, upvote_count: $upvote_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the paginated list of reviews for the specified location. This operation is only valid if the specified location is verified.
#
# GET /v4/{parent}/reviews
# Returns: record<averageRating: float, nextPageToken: string, reviews: table<comment: string, createTime: string, name: string, reviewId: string, reviewReply: record, reviewer: record, starRating: string, updateTime: string>, totalReviewCount: int>
# operationId: mybusiness.accounts.locations.reviews.list
export def "mybusiness-accounts-locations-reviews-list" [
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
  --order-by: string # Specifies the field to sort reviews by. If unspecified, the order of reviews returned will default to `update_time desc`. Valid orders to sort by are `rating`, `rating desc` and `update_time desc`.
  --page-size: int # How many reviews to fetch per page. The maximum `page_size` is 50.
  --page-token: string # If specified, it fetches the next page of reviews.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/{parent}/reviews"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: orderBy, var: order_by}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, order_by: $order_by, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List verifications of a location, ordered by create time.
#
# GET /v4/{parent}/verifications
# Returns: record<nextPageToken: string, verifications: table<createTime: string, method: string, name: string, state: string>>
# operationId: mybusiness.accounts.locations.verifications.list
export def "mybusiness-accounts-locations-verifications-list" [
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
  --page-size: int # How many verification to include per page. If not set, return all.
  --page-token: string # If specified, returns the next page of verifications.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/{parent}/verifications"
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
