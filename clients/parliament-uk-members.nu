# Auto-generated client for Members API v1
# Source: https://api.apis.guru/v2/specs/parliament.uk/members/v1/openapi.json
# Auth: --token flag or $env.MEMBERS_API_TOKEN

const CLIENT = {
  base_url: "https://api.apis.guru"
  token_env_var: "MEMBERS_API_TOKEN"
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

def base-url-completer [] { ["https://api.apis.guru"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def location-type-completer [] { ["0" "1" "2" "3"] }
def accept-completer [] { ["application/json" "text/json" "text/plain"] }
def house-completer [] { ["1" "2"] }
def membership-in-date-range-was-member-of-house-completer [] { ["1" "2"] }
def crop-type-completer [] { ["0" "1" "2" "3"] }
def type-completer [] { ["0" "1" "2"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-api-location-browse-location-type-location-name: "record<links: table<href: string, method: string, rel: string>, value: record<childContexts: list<record>, context: record<id: int, name: string, type: int, typeName: string>, parentContext: record<id: int, name: string, type: int, typeName: string>, stateOfTheParties: list<record>>>"
    get-api-location-constituency-search: "record<items: table<links: list, value: record>, links: table<href: string, method: string, rel: string>, resultContext: string, skip: int, take: int, totalResults: int>"
    get-api-location-constituency-id: "record<links: table<href: string, method: string, rel: string>, value: record<currentRepresentation: record<member: record, representation: record>, endDate: string, id: int, name: string, startDate: string>>"
    get-api-location-constituency-id-election-result-latest: "record<links: table<href: string, method: string, rel: string>, value: record<candidates: list<record>, constituencyName: string, electionDate: string, electionId: int, electionTitle: string, electorate: int, isGeneralElection: bool, isNotional: bool, majority: int, result: string, turnout: int, winningParty: record<abbreviation: string, backgroundColour: string, foregroundColour: string, governmentType: int, id: int, isIndependentParty: bool, isLordsMainParty: bool, isLordsSpiritualParty: bool, name: string>>>"
    get-api-location-constituency-id-election-result-election-id: "record<links: table<href: string, method: string, rel: string>, value: record<candidates: list<record>, constituencyName: string, electionDate: string, electionId: int, electionTitle: string, electorate: int, isGeneralElection: bool, isNotional: bool, majority: int, result: string, turnout: int, winningParty: record<abbreviation: string, backgroundColour: string, foregroundColour: string, governmentType: int, id: int, isIndependentParty: bool, isLordsMainParty: bool, isLordsSpiritualParty: bool, name: string>>>"
    get-api-location-constituency-id-election-results: "record<links: table<href: string, method: string, rel: string>, value: table<candidates: list, constituencyName: string, electionDate: string, electionId: int, electionTitle: string, electorate: int, isGeneralElection: bool, isNotional: bool, majority: int, result: string, turnout: int, winningParty: record>>"
    get-api-location-constituency-id-geometry: "record<links: table<href: string, method: string, rel: string>, value: string>"
    get-api-location-constituency-id-representations: "record<links: table<href: string, method: string, rel: string>, value: table<member: record, representation: record>>"
    get-api-location-constituency-id-synopsis: "record<links: table<href: string, method: string, rel: string>, value: string>"
    get-api-lords-interests-register: "record<items: table<links: list, value: record>, links: table<href: string, method: string, rel: string>, resultContext: string, skip: int, take: int, totalResults: int>"
    get-api-lords-interests-staff: "record<items: table<links: list, value: record>, links: table<href: string, method: string, rel: string>, resultContext: string, skip: int, take: int, totalResults: int>"
    get-api-members-history: "table<links: list<record>, value: record<houseMembershipHistory: list, id: int, nameHistory: list, partyHistory: list, thumbnailUrl: string>>"
    get-api-members-search: "record<items: table<links: list, value: record>, links: table<href: string, method: string, rel: string>, resultContext: string, skip: int, take: int, totalResults: int>"
    get-api-members-search-historical: "record<items: table<links: list, value: record>, links: table<href: string, method: string, rel: string>, resultContext: string, skip: int, take: int, totalResults: int>"
    get-api-members-id: "record<links: table<href: string, method: string, rel: string>, value: record<gender: string, id: int, latestHouseMembership: record<house: int, membershipEndDate: string, membershipEndReason: string, membershipEndReasonId: int, membershipEndReasonNotes: string, membershipFrom: string, membershipFromId: int, membershipStartDate: string, membershipStatus: record>, latestParty: record<abbreviation: string, backgroundColour: string, foregroundColour: string, governmentType: int, id: int, isIndependentParty: bool, isLordsMainParty: bool, isLordsSpiritualParty: bool, name: string>, nameAddressAs: string, nameDisplayAs: string, nameFullTitle: string, nameListAs: string, thumbnailUrl: string>>"
    get-api-members-id-biography: "record<links: table<href: string, method: string, rel: string>, value: record<committeeMemberships: list<record>, electionsContested: list<record>, governmentPosts: list<record>, houseMemberships: list<record>, oppositionPosts: list<record>, otherPosts: list<record>, partyAffiliations: list<record>, representations: list<record>>>"
    get-api-members-id-contact: "record<links: table<href: string, method: string, rel: string>, value: table<email: string, fax: string, isPreferred: bool, isWebAddress: bool, line1: string, line2: string, line3: string, line4: string, line5: string, notes: string, phone: string, postcode: string, type: string, typeDescription: string, typeId: int>>"
    get-api-members-id-contribution-summary: "record<items: table<links: list, value: record>, links: table<href: string, method: string, rel: string>, resultContext: string, skip: int, take: int, totalResults: int>"
    get-api-members-id-edms: "record<items: table<links: list, value: record>, links: table<href: string, method: string, rel: string>, resultContext: string, skip: int, take: int, totalResults: int>"
    get-api-members-id-experience: "record<links: table<href: string, method: string, rel: string>, value: table<endMonth: int, endYear: int, id: int, organisation: string, startMonth: int, startYear: int, title: string, type: string, typeId: int>>"
    get-api-members-id-focus: "record<links: table<href: string, method: string, rel: string>, value: table<category: string, focus: list>>"
    get-api-members-id-latest-election-result: "record<links: table<href: string, method: string, rel: string>, value: record<candidates: list<record>, constituencyName: string, electionDate: string, electionId: int, electionTitle: string, electorate: int, isGeneralElection: bool, isNotional: bool, majority: int, result: string, turnout: int, winningParty: record<abbreviation: string, backgroundColour: string, foregroundColour: string, governmentType: int, id: int, isIndependentParty: bool, isLordsMainParty: bool, isLordsSpiritualParty: bool, name: string>>>"
    get-api-members-id-portrait-url: "record<links: table<href: string, method: string, rel: string>, value: string>"
    get-api-members-id-registered-interests: "record<links: table<href: string, method: string, rel: string>, value: table<id: int, interests: list, name: string, sortOrder: int>>"
    get-api-members-id-staff: "record<links: table<href: string, method: string, rel: string>, value: table<details: string, forename: string, surname: string, title: string>>"
    get-api-members-id-synopsis: "record<links: table<href: string, method: string, rel: string>, value: string>"
    get-api-members-id-thumbnail-url: "record<links: table<href: string, method: string, rel: string>, value: string>"
    get-api-members-id-voting: "record<items: table<links: list, value: record>, links: table<href: string, method: string, rel: string>, resultContext: string, skip: int, take: int, totalResults: int>"
    get-api-members-id-written-questions: "record<items: table<links: list, value: record>, links: table<href: string, method: string, rel: string>, resultContext: string, skip: int, take: int, totalResults: int>"
    get-api-parties-get-active-house: "record<items: table<links: list, value: record>, links: table<href: string, method: string, rel: string>, resultContext: string, skip: int, take: int, totalResults: int>"
    get-api-parties-lords-by-type-for-date: "record<items: table<links: list, value: record>, links: table<href: string, method: string, rel: string>, resultContext: string, skip: int, take: int, totalResults: int>"
    get-api-parties-state-of-the-parties-house-for-date: "record<items: table<links: list, value: record>, links: table<href: string, method: string, rel: string>, resultContext: string, skip: int, take: int, totalResults: int>"
    get-api-posts-departments-type: "table<id: int, imageUrl: string, name: string, url: string>"
    get-api-posts-government-posts: "table<links: list<record>, value: record<createdWhen: string, governmentDepartments: list, hansardName: string, id: int, name: string, order: int, postHolders: list, type: int>>"
    get-api-posts-opposition-posts: "table<links: list<record>, value: record<createdWhen: string, governmentDepartments: list, hansardName: string, id: int, name: string, order: int, postHolders: list, type: int>>"
    get-api-posts-speaker-and-deputies-for-date: "table<links: list<record>, value: record<gender: string, id: int, latestHouseMembership: record, latestParty: record, nameAddressAs: string, nameDisplayAs: string, nameFullTitle: string, nameListAs: string, thumbnailUrl: string>>"
    get-api-posts-spokespersons: "table<links: list<record>, value: record<createdWhen: string, governmentDepartments: list, hansardName: string, id: int, name: string, order: int, postHolders: list, type: int>>"
    get-api-reference-answering-bodies: "table<department: record<id: int, imageUrl: string, name: string, url: string>, id: int, name: string, shortName: string, target: string>"
    get-api-reference-departments: "table<id: int, imageUrl: string, name: string, url: string>"
    get-api-reference-policy-interests: "table<description: string, id: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-api-location-browse-location-type-location-name" "get-api-location-constituency-search" "get-api-location-constituency-id" "get-api-location-constituency-id-election-result-latest" "get-api-location-constituency-id-election-result-election-id" "get-api-location-constituency-id-election-results" "get-api-location-constituency-id-geometry" "get-api-location-constituency-id-representations" "get-api-location-constituency-id-synopsis" "get-api-lords-interests-register" "get-api-lords-interests-staff" "get-api-members-history" "get-api-members-search" "get-api-members-search-historical" "get-api-members-id" "get-api-members-id-biography" "get-api-members-id-contact" "get-api-members-id-contribution-summary" "get-api-members-id-edms" "get-api-members-id-experience" "get-api-members-id-focus" "get-api-members-id-latest-election-result" "get-api-members-id-portrait" "get-api-members-id-portrait-url" "get-api-members-id-registered-interests" "get-api-members-id-staff" "get-api-members-id-synopsis" "get-api-members-id-thumbnail" "get-api-members-id-thumbnail-url" "get-api-members-id-voting" "get-api-members-id-written-questions" "get-api-parties-get-active-house" "get-api-parties-lords-by-type-for-date" "get-api-parties-state-of-the-parties-house-for-date" "get-api-posts-departments-type" "get-api-posts-government-posts" "get-api-posts-opposition-posts" "get-api-posts-speaker-and-deputies-for-date" "get-api-posts-spokespersons" "get-api-reference-answering-bodies" "get-api-reference-departments" "get-api-reference-departments-id-logo" "get-api-reference-policy-interests" "commands"] | sort) } | get name | first)
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

# Returns a list of locations, both parent and child
#
# GET /api/Location/Browse/{locationType}/{locationName}
# Returns: record<links: table<href: string, method: string, rel: string>, value: record<childContexts: list<record>, context: record<id: int, name: string, type: int, typeName: string>, parentContext: record<id: int, name: string, type: int, typeName: string>, stateOfTheParties: list<record>>>
export def "get-api-location-browse-location-type-location-name" [
  location_type: int@location-type-completer
  location_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Location/Browse/{locationType}/{locationName}"
    path_params: [{name: locationType, var: location_type}, {name: locationName, var: location_name}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    location_type: $location_type, location_name: $location_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list of constituencies
#
# GET /api/Location/Constituency/Search
# Returns: record<items: table<links: list, value: record>, links: table<href: string, method: string, rel: string>, resultContext: string, skip: int, take: int, totalResults: int>
export def "get-api-location-constituency-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-text: string # Constituencies containing serach term in their name
  --skip: int # The number of records to skip from the first, default is 0 (format: int32, default: 0)
  --take: int # The number of records to return, default is 20. Maximum is 20 (format: int32, default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Location/Constituency/Search"
    query: [{name: searchText, var: search_text}, {name: skip, var: skip}, {name: take, var: take}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    search_text: $search_text, skip: $skip, take: $take
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a constituency by ID
#
# GET /api/Location/Constituency/{id}
# Returns: record<links: table<href: string, method: string, rel: string>, value: record<currentRepresentation: record<member: record, representation: record>, endDate: string, id: int, name: string, startDate: string>>
export def "get-api-location-constituency-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Location/Constituency/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns latest election result by constituency id
#
# GET /api/Location/Constituency/{id}/ElectionResult/Latest
# Returns: record<links: table<href: string, method: string, rel: string>, value: record<candidates: list<record>, constituencyName: string, electionDate: string, electionId: int, electionTitle: string, electorate: int, isGeneralElection: bool, isNotional: bool, majority: int, result: string, turnout: int, winningParty: record<abbreviation: string, backgroundColour: string, foregroundColour: string, governmentType: int, id: int, isIndependentParty: bool, isLordsMainParty: bool, isLordsSpiritualParty: bool, name: string>>>
export def "get-api-location-constituency-id-election-result-latest" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Location/Constituency/{id}/ElectionResult/Latest"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns an election result by constituency and election id
#
# GET /api/Location/Constituency/{id}/ElectionResult/{electionId}
# Returns: record<links: table<href: string, method: string, rel: string>, value: record<candidates: list<record>, constituencyName: string, electionDate: string, electionId: int, electionTitle: string, electorate: int, isGeneralElection: bool, isNotional: bool, majority: int, result: string, turnout: int, winningParty: record<abbreviation: string, backgroundColour: string, foregroundColour: string, governmentType: int, id: int, isIndependentParty: bool, isLordsMainParty: bool, isLordsSpiritualParty: bool, name: string>>>
export def "get-api-location-constituency-id-election-result-election-id" [
  id: int
  election_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Location/Constituency/{id}/ElectionResult/{electionId}"
    path_params: [{name: id, var: id}, {name: electionId, var: election_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, election_id: $election_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list of election results by constituency ID
#
# GET /api/Location/Constituency/{id}/ElectionResults
# Returns: record<links: table<href: string, method: string, rel: string>, value: table<candidates: list, constituencyName: string, electionDate: string, electionId: int, electionTitle: string, electorate: int, isGeneralElection: bool, isNotional: bool, majority: int, result: string, turnout: int, winningParty: record>>
export def "get-api-location-constituency-id-election-results" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Location/Constituency/{id}/ElectionResults"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns geometry by constituency ID
#
# GET /api/Location/Constituency/{id}/Geometry
# Returns: record<links: table<href: string, method: string, rel: string>, value: string>
export def "get-api-location-constituency-id-geometry" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Location/Constituency/{id}/Geometry"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list of representations by constituency ID
#
# GET /api/Location/Constituency/{id}/Representations
# Returns: record<links: table<href: string, method: string, rel: string>, value: table<member: record, representation: record>>
export def "get-api-location-constituency-id-representations" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Location/Constituency/{id}/Representations"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a synopsis by constituency ID
#
# GET /api/Location/Constituency/{id}/Synopsis
# Returns: record<links: table<href: string, method: string, rel: string>, value: string>
export def "get-api-location-constituency-id-synopsis" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Location/Constituency/{id}/Synopsis"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list of registered interests
#
# GET /api/LordsInterests/Register
# Returns: record<items: table<links: list, value: record>, links: table<href: string, method: string, rel: string>, resultContext: string, skip: int, take: int, totalResults: int>
export def "get-api-lords-interests-register" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-term: string # Registered interests containing search term
  --page: int # Page of results to return, default 0. Results per page 20. (format: int32)
  --include-deleted: oneof<nothing, bool> # Registered interests that have been deleted (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/LordsInterests/Register"
    query: [{name: searchTerm, var: search_term}, {name: page, var: page}, {name: includeDeleted, var: include_deleted}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    search_term: $search_term, page: $page, include_deleted: $include_deleted
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list of staff
#
# GET /api/LordsInterests/Staff
# Returns: record<items: table<links: list, value: record>, links: table<href: string, method: string, rel: string>, resultContext: string, skip: int, take: int, totalResults: int>
export def "get-api-lords-interests-staff" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-term: string # Staff containing search term
  --page: int # Page of results to return, default 0. Results per page 20. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/LordsInterests/Staff"
    query: [{name: searchTerm, var: search_term}, {name: page, var: page}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    search_term: $search_term, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return members by ID with list of their historical names, parties and memberships
#
# GET /api/Members/History
# Returns: table<links: list<record>, value: record<houseMembershipHistory: list, id: int, nameHistory: list, partyHistory: list, thumbnailUrl: string>>
export def "get-api-members-history" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ids: list<int> # List of MemberIds to find
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/Members/History"
    query: [{name: ids, var: ids, style: multi}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list of current members of the Commons or Lords
#
# GET /api/Members/Search
# Returns: record<items: table<links: list, value: record>, links: table<href: string, method: string, rel: string>, resultContext: string, skip: int, take: int, totalResults: int>
export def "get-api-members-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # Members where name contains term specified
  --location: string # Members where postcode or geographical location matches the term specified
  --post-title: string # Members which have held the post specified
  --party-id: int # Members which are currently affiliated with party with party ID (format: int32)
  --house: int@house-completer # Members where their most recent house is the house specified (format: int32)
  --constituency-id: int # Members which currently hold the constituency with constituency id (format: int32)
  --name-starts-with: string # Members with surname begining with letter(s) specified
  --gender: string # Members with the gender specified
  --membership-started-since: string # Members who started on or after the date given (format: date-time)
  --membership-ended-membership-ended-since: string # Members who left the House on or after the date given (format: date-time)
  --membership-ended-membership-end-reason-ids: list<int>
  --membership-in-date-range-was-member-on-or-after: string # Members who were active on or after the date specified (format: date-time)
  --membership-in-date-range-was-member-on-or-before: string # Members who were active on or before the date specified (format: date-time)
  --membership-in-date-range-was-member-of-house: int@membership-in-date-range-was-member-of-house-completer # Members who were active in the house specifid (format: int32)
  --is-eligible: oneof<nothing, bool> # Members currently Eligible to sit in their House
  --is-current-member: oneof<nothing, bool> # Members who are current or former members
  --policy-interest-id: int # Members with specified policy interest (format: int32)
  --experience: string # Members with specified experience
  --skip: int # The number of records to skip from the first, default is 0 (format: int32, default: 0)
  --take: int # The number of records to return, default is 20. Maximum is 20 (format: int32, default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Members/Search"
    query: [{name: Name, var: name}, {name: Location, var: location}, {name: PostTitle, var: post_title}, {name: PartyId, var: party_id}, {name: House, var: house}, {name: ConstituencyId, var: constituency_id}, {name: NameStartsWith, var: name_starts_with}, {name: Gender, var: gender}, {name: MembershipStartedSince, var: membership_started_since}, {name: "MembershipEnded.MembershipEndedSince", var: membership_ended_membership_ended_since}, {name: "MembershipEnded.MembershipEndReasonIds", var: membership_ended_membership_end_reason_ids, style: multi}, {name: "MembershipInDateRange.WasMemberOnOrAfter", var: membership_in_date_range_was_member_on_or_after}, {name: "MembershipInDateRange.WasMemberOnOrBefore", var: membership_in_date_range_was_member_on_or_before}, {name: "MembershipInDateRange.WasMemberOfHouse", var: membership_in_date_range_was_member_of_house}, {name: IsEligible, var: is_eligible}, {name: IsCurrentMember, var: is_current_member}, {name: PolicyInterestId, var: policy_interest_id}, {name: Experience, var: experience}, {name: skip, var: skip}, {name: take, var: take}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    name: $name, location: $location, post_title: $post_title, party_id: $party_id, house: $house, constituency_id: $constituency_id, name_starts_with: $name_starts_with, gender: $gender, membership_started_since: $membership_started_since, membership_ended_membership_ended_since: $membership_ended_membership_ended_since, membership_ended_membership_end_reason_ids: $membership_ended_membership_end_reason_ids, membership_in_date_range_was_member_on_or_after: $membership_in_date_range_was_member_on_or_after, membership_in_date_range_was_member_on_or_before: $membership_in_date_range_was_member_on_or_before, membership_in_date_range_was_member_of_house: $membership_in_date_range_was_member_of_house, is_eligible: $is_eligible, is_current_member: $is_current_member, policy_interest_id: $policy_interest_id, experience: $experience, skip: $skip, take: $take
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list of members of the Commons or Lords
#
# GET /api/Members/SearchHistorical
# Returns: record<items: table<links: list, value: record>, links: table<href: string, method: string, rel: string>, resultContext: string, skip: int, take: int, totalResults: int>
export def "get-api-members-search-historical" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # Members with names containing the term specified
  --date-to-search-for: string # Members that were an active member of the Commons or Lords on the date specified (format: date-time)
  --skip: int # The number of records to skip from the first, default is 0 (format: int32, default: 0)
  --take: int # The number of records to return, default is 20. Maximum is 20 (format: int32, default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Members/SearchHistorical"
    query: [{name: name, var: name}, {name: dateToSearchFor, var: date_to_search_for}, {name: skip, var: skip}, {name: take, var: take}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    name: $name, date_to_search_for: $date_to_search_for, skip: $skip, take: $take
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return member by ID
#
# GET /api/Members/{id}
# Returns: record<links: table<href: string, method: string, rel: string>, value: record<gender: string, id: int, latestHouseMembership: record<house: int, membershipEndDate: string, membershipEndReason: string, membershipEndReasonId: int, membershipEndReasonNotes: string, membershipFrom: string, membershipFromId: int, membershipStartDate: string, membershipStatus: record>, latestParty: record<abbreviation: string, backgroundColour: string, foregroundColour: string, governmentType: int, id: int, isIndependentParty: bool, isLordsMainParty: bool, isLordsSpiritualParty: bool, name: string>, nameAddressAs: string, nameDisplayAs: string, nameFullTitle: string, nameListAs: string, thumbnailUrl: string>>
export def "get-api-members-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --details-for-date: string # Member object will be populated with details from the date specified (format: date-time)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Members/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: detailsForDate, var: details_for_date}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, details_for_date: $details_for_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return biography of member by ID
#
# GET /api/Members/{id}/Biography
# Returns: record<links: table<href: string, method: string, rel: string>, value: record<committeeMemberships: list<record>, electionsContested: list<record>, governmentPosts: list<record>, houseMemberships: list<record>, oppositionPosts: list<record>, otherPosts: list<record>, partyAffiliations: list<record>, representations: list<record>>>
export def "get-api-members-id-biography" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Members/{id}/Biography"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return list of contact details of member by ID
#
# GET /api/Members/{id}/Contact
# Returns: record<links: table<href: string, method: string, rel: string>, value: table<email: string, fax: string, isPreferred: bool, isWebAddress: bool, line1: string, line2: string, line3: string, line4: string, line5: string, notes: string, phone: string, postcode: string, type: string, typeDescription: string, typeId: int>>
export def "get-api-members-id-contact" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Members/{id}/Contact"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return contribution summary of member by ID
#
# GET /api/Members/{id}/ContributionSummary
# Returns: record<items: table<links: list, value: record>, links: table<href: string, method: string, rel: string>, resultContext: string, skip: int, take: int, totalResults: int>
export def "get-api-members-id-contribution-summary" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # format: int32
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Members/{id}/ContributionSummary"
    path_params: [{name: id, var: id}]
    query: [{name: page, var: page}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return list of early day motions of member by ID
#
# GET /api/Members/{id}/Edms
# Returns: record<items: table<links: list, value: record>, links: table<href: string, method: string, rel: string>, resultContext: string, skip: int, take: int, totalResults: int>
export def "get-api-members-id-edms" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # format: int32
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Members/{id}/Edms"
    path_params: [{name: id, var: id}]
    query: [{name: page, var: page}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return experience of member by ID
#
# GET /api/Members/{id}/Experience
# Returns: record<links: table<href: string, method: string, rel: string>, value: table<endMonth: int, endYear: int, id: int, organisation: string, startMonth: int, startYear: int, title: string, type: string, typeId: int>>
export def "get-api-members-id-experience" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Members/{id}/Experience"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return list of areas of focus of member by ID
#
# GET /api/Members/{id}/Focus
# Returns: record<links: table<href: string, method: string, rel: string>, value: table<category: string, focus: list>>
export def "get-api-members-id-focus" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Members/{id}/Focus"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return latest election result of member by ID
#
# GET /api/Members/{id}/LatestElectionResult
# Returns: record<links: table<href: string, method: string, rel: string>, value: record<candidates: list<record>, constituencyName: string, electionDate: string, electionId: int, electionTitle: string, electorate: int, isGeneralElection: bool, isNotional: bool, majority: int, result: string, turnout: int, winningParty: record<abbreviation: string, backgroundColour: string, foregroundColour: string, governmentType: int, id: int, isIndependentParty: bool, isLordsMainParty: bool, isLordsSpiritualParty: bool, name: string>>>
export def "get-api-members-id-latest-election-result" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Members/{id}/LatestElectionResult"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return portrait of member by ID
#
# GET /api/Members/{id}/Portrait
export def "get-api-members-id-portrait" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --crop-type: int@crop-type-completer # format: int32
  --web-version: oneof<nothing, bool> # default: true
]: nothing -> any {
  http-request {
    method: get
    path: "/api/Members/{id}/Portrait"
    path_params: [{name: id, var: id}]
    query: [{name: cropType, var: crop_type}, {name: webVersion, var: web_version}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    id: $id, crop_type: $crop_type, web_version: $web_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return portrait url of member by ID
#
# GET /api/Members/{id}/PortraitUrl
# Returns: record<links: table<href: string, method: string, rel: string>, value: string>
export def "get-api-members-id-portrait-url" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Members/{id}/PortraitUrl"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return list of registered interests of member by ID
#
# GET /api/Members/{id}/RegisteredInterests
# Returns: record<links: table<href: string, method: string, rel: string>, value: table<id: int, interests: list, name: string, sortOrder: int>>
export def "get-api-members-id-registered-interests" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --house: int@house-completer # Registered interests of Member by House specified (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Members/{id}/RegisteredInterests"
    path_params: [{name: id, var: id}]
    query: [{name: house, var: house}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, house: $house
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return list of staff of member by ID
#
# GET /api/Members/{id}/Staff
# Returns: record<links: table<href: string, method: string, rel: string>, value: table<details: string, forename: string, surname: string, title: string>>
export def "get-api-members-id-staff" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Members/{id}/Staff"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return synopsis of member by ID
#
# GET /api/Members/{id}/Synopsis
# Returns: record<links: table<href: string, method: string, rel: string>, value: string>
export def "get-api-members-id-synopsis" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Members/{id}/Synopsis"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return thumbnail of member by ID
#
# GET /api/Members/{id}/Thumbnail
export def "get-api-members-id-thumbnail" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/api/Members/{id}/Thumbnail"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return thumbnail url of member by ID
#
# GET /api/Members/{id}/ThumbnailUrl
# Returns: record<links: table<href: string, method: string, rel: string>, value: string>
export def "get-api-members-id-thumbnail-url" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Members/{id}/ThumbnailUrl"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return list of votes by member by ID
#
# GET /api/Members/{id}/Voting
# Returns: record<items: table<links: list, value: record>, links: table<href: string, method: string, rel: string>, resultContext: string, skip: int, take: int, totalResults: int>
export def "get-api-members-id-voting" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --house: int@house-completer # required, format: int32
  --page: int # format: int32
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Members/{id}/Voting"
    path_params: [{name: id, var: id}]
    query: [{name: house, var: house, required: true}, {name: page, var: page}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, house: $house, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return list of written questions by member by ID
#
# GET /api/Members/{id}/WrittenQuestions
# Returns: record<items: table<links: list, value: record>, links: table<href: string, method: string, rel: string>, resultContext: string, skip: int, take: int, totalResults: int>
export def "get-api-members-id-written-questions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # format: int32
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Members/{id}/WrittenQuestions"
    path_params: [{name: id, var: id}]
    query: [{name: page, var: page}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list of current parties with at least one active member.
#
# GET /api/Parties/GetActive/{house}
# Returns: record<items: table<links: list, value: record>, links: table<href: string, method: string, rel: string>, resultContext: string, skip: int, take: int, totalResults: int>
export def "get-api-parties-get-active-house" [
  house: int@house-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Parties/GetActive/{house}"
    path_params: [{name: house, var: house}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    house: $house
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns the composition of the House of Lords by peerage type.
#
# GET /api/Parties/LordsByType/{forDate}
# Returns: record<items: table<links: list, value: record>, links: table<href: string, method: string, rel: string>, resultContext: string, skip: int, take: int, totalResults: int>
export def "get-api-parties-lords-by-type-for-date" [
  for_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Parties/LordsByType/{forDate}"
    path_params: [{name: forDate, var: for_date}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    for_date: $for_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns current state of parties
#
# GET /api/Parties/StateOfTheParties/{house}/{forDate}
# Returns: record<items: table<links: list, value: record>, links: table<href: string, method: string, rel: string>, resultContext: string, skip: int, take: int, totalResults: int>
export def "get-api-parties-state-of-the-parties-house-for-date" [
  house: int@house-completer
  for_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Parties/StateOfTheParties/{house}/{forDate}"
    path_params: [{name: house, var: house}, {name: forDate, var: for_date}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    house: $house, for_date: $for_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list of departments.
#
# GET /api/Posts/Departments/{type}
# Returns: table<id: int, imageUrl: string, name: string, url: string>
export def "get-api-posts-departments-type" [
  type: int@type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/Posts/Departments/{type}"
    path_params: [{name: type, var: type}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list of government posts.
#
# GET /api/Posts/GovernmentPosts
# Returns: table<links: list<record>, value: record<createdWhen: string, governmentDepartments: list, hansardName: string, id: int, name: string, order: int, postHolders: list, type: int>>
export def "get-api-posts-government-posts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --department-id: int # Government posts by department ID (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/Posts/GovernmentPosts"
    query: [{name: departmentId, var: department_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    department_id: $department_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list of opposition posts.
#
# GET /api/Posts/OppositionPosts
# Returns: table<links: list<record>, value: record<createdWhen: string, governmentDepartments: list, hansardName: string, id: int, name: string, order: int, postHolders: list, type: int>>
export def "get-api-posts-opposition-posts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --department-id: int # Opposition posts by department ID (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/Posts/OppositionPosts"
    query: [{name: departmentId, var: department_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    department_id: $department_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list containing the speaker and deputy speakers.
#
# GET /api/Posts/SpeakerAndDeputies/{forDate}
# Returns: table<links: list<record>, value: record<gender: string, id: int, latestHouseMembership: record, latestParty: record, nameAddressAs: string, nameDisplayAs: string, nameFullTitle: string, nameListAs: string, thumbnailUrl: string>>
export def "get-api-posts-speaker-and-deputies-for-date" [
  for_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/Posts/SpeakerAndDeputies/{forDate}"
    path_params: [{name: forDate, var: for_date}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    for_date: $for_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list of spokespersons.
#
# GET /api/Posts/Spokespersons
# Returns: table<links: list<record>, value: record<createdWhen: string, governmentDepartments: list, hansardName: string, id: int, name: string, order: int, postHolders: list, type: int>>
export def "get-api-posts-spokespersons" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --party-id: int # Spokespersons by party ID (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/Posts/Spokespersons"
    query: [{name: partyId, var: party_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list of answering bodies.
#
# GET /api/Reference/AnsweringBodies
# Returns: table<department: record<id: int, imageUrl: string, name: string, url: string>, id: int, name: string, shortName: string, target: string>
export def "get-api-reference-answering-bodies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --name-contains: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/Reference/AnsweringBodies"
    query: [{name: id, var: id}, {name: nameContains, var: name_contains}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name_contains: $name_contains
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list of departments.
#
# GET /api/Reference/Departments
# Returns: table<id: int, imageUrl: string, name: string, url: string>
export def "get-api-reference-departments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --name-contains: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/Reference/Departments"
    query: [{name: id, var: id}, {name: nameContains, var: name_contains}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name_contains: $name_contains
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns department logo.
#
# GET /api/Reference/Departments/{id}/Logo
export def "get-api-reference-departments-id-logo" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/api/Reference/Departments/{id}/Logo"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of policy interest.
#
# GET /api/Reference/PolicyInterests
# Returns: table<description: string, id: int>
export def "get-api-reference-policy-interests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/Reference/PolicyInterests"
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
