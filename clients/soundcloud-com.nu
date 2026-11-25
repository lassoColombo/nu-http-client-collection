# Auto-generated client for SoundCloud Public API Specification v1.0.0
# Source: https://api.apis.guru/v2/specs/soundcloud.com/1.0.0/openapi.json
# Auth: --token flag or $env.SOUNDCLOUD_PUBLIC_API_SPECIFICATION_TOKEN
# Auth (AuthHeader): --token-authheader flag or $env.SOUNDCLOUD_PUBLIC_API_SPECIFICATION_AUTHHEADER_TOKEN
# Auth (ClientId): --token-clientid flag or $env.SOUNDCLOUD_PUBLIC_API_SPECIFICATION_CLIENTID_TOKEN

const CLIENT = {
  base_url: "https://api.soundcloud.com"
  token_env_var: "SOUNDCLOUD_PUBLIC_API_SPECIFICATION_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: bearer, in: header, header_name: Authorization, prefix: Bearer}
    {name: query-client_id, in: query, header_name: client_id, prefix: ""}
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

def base-url-completer [] { ["https://api.soundcloud.com"] }
def auth-scheme-completer [] { ["bearer" "query-client_id"] }

# Completers for enum parameters
def response-type-completer [] { ["code" "code_and_token" "token"] }
def grant-type-completer [] { ["authorization_code" "client_credentials"] }
def track-embeddable-by-completer [] { ["all" "me" "none"] }
def track-license-completer [] { ["all-rights-reserved" "cc-by" "cc-by-nc" "cc-by-nc-nd" "cc-by-nc-sa" "cc-by-nd" "cc-by-sa" "no-rights-reserved"] }
def track-sharing-completer [] { ["private" "public"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help" "token-authheader" "token-clientid"]
  let return_types = {
    get-me: "record<avatar_url: string, city: string, country: string, description: string, discogs_name: string, first_name: string, followers_count: int, followings_count: int, full_name: string, id: int, kind: string, last_modified: string, last_name: string, locale: string, myspace_name: string, permalink: string, permalink_url: string, plan: string, playlist_count: int, primary_email_confirmed: bool, private_playlists_count: int, private_tracks_count: int, public_favorites_count: int, quota: record<unlimited_upload_quota: bool, upload_seconds_used: int>, reposts_count: int, subscriptions: list<list<any>>, track_count: int, uri: string, username: string, website: string, website_title: string>"
    get-me-activities: "record<collection: table<created_at: string, origin: record, type: string>, future_href: string, next_href: string>"
    get-me-activities-all-own: "record<collection: table<created_at: string, origin: record, type: string>, future_href: string, next_href: string>"
    get-me-activities-tracks: "record<collection: table<created_at: string, origin: record, type: string>, future_href: string, next_href: string>"
    get-me-connections: "table<created_at: string, display_name: string, id: int, kind: string, post_favorite: bool, post_publish: bool, service: string, type: string, uri: string>"
    get-me-connections-connection-id: "record<created_at: string, display_name: string, id: int, kind: string, post_favorite: bool, post_publish: bool, service: string, type: string, uri: string>"
    get-me-followers-follower-id: "record<avatar_url: string, city: string, country: string, created_at: string, description: string, discogs_name: string, first_name: string, followers_count: int, followings_count: int, full_name: string, id: int, kind: string, last_modified: string, last_name: string, myspace_name: string, permalink: string, permalink_url: string, plan: string, playlist_count: int, public_favorites_count: int, reposts_count: int, subscriptions: list<list<any>>, track_count: int, uri: string, username: string, website: string, website_title: string>"
    get-me-followings-tracks: "table<access: string, artwork_url: string, available_country_codes: string, bpm: int, comment_count: int, commentable: bool, created_at: string, description: string, download_count: int, download_url: string, downloadable: string, duration: int, embeddable_by: string, favoritings_count: int, genre: string, id: int, isrc: string, key_signature: string, kind: string, label_name: string, license: string, permalink_url: string, playback_count: int, purchase_title: string, purchase_url: string, release: string, release_day: int, release_month: int, release_year: int, reposts_count: int, secret_uri: string, sharing: string, stream_url: string, streamable: bool, tag_list: string, title: string, uri: string, user: record<avatar_url: string, created_at: string, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, uri: string, username: string>, user_favorite: bool, user_playback_count: int, waveform_url: string>"
    get-me-followings-user-id: "record<avatar_url: string, city: string, country: string, created_at: string, description: string, discogs_name: string, first_name: string, followers_count: int, followings_count: int, full_name: string, id: int, kind: string, last_modified: string, last_name: string, myspace_name: string, permalink: string, permalink_url: string, plan: string, playlist_count: int, public_favorites_count: int, reposts_count: int, subscriptions: list<list<any>>, track_count: int, uri: string, username: string, website: string, website_title: string>"
    put-me-followings-user-id: "record<avatar_url: string, city: string, country: string, created_at: string, description: string, discogs_name: string, first_name: string, followers_count: int, followings_count: int, full_name: string, id: int, kind: string, last_modified: string, last_name: string, myspace_name: string, permalink: string, permalink_url: string, plan: string, playlist_count: int, public_favorites_count: int, reposts_count: int, subscriptions: list<list<any>>, track_count: int, uri: string, username: string, website: string, website_title: string>"
    get-me-playlists: "table<artwork_url: string, created_at: string, description: string, downloadable: bool, duration: int, ean: string, embeddable_by: string, genre: string, id: int, kind: string, label: record<avatar_url: string, created_at: string, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, uri: string, username: string>, label_id: int, label_name: string, last_modified: string, license: string, likes_count: int, permalink: string, permalink_url: string, playlist_type: string, purchase_title: string, purchase_url: string, release: string, release_day: int, release_month: int, release_year: int, sharing: string, streamable: bool, tag_list: string, tags: string, title: string, track_count: int, tracks: list<record>, tracks_uri: string, type: string, uri: string, user: record<avatar_url: string, created_at: string, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, uri: string, username: string>, user_id: int>"
    get-me-playlists-playlist-id: "record<artwork_url: string, created_at: string, description: string, downloadable: bool, duration: int, ean: string, embeddable_by: string, genre: string, id: int, kind: string, label: record<avatar_url: string, created_at: string, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, uri: string, username: string>, label_id: int, label_name: string, last_modified: string, license: string, likes_count: int, permalink: string, permalink_url: string, playlist_type: string, purchase_title: string, purchase_url: string, release: string, release_day: int, release_month: int, release_year: int, sharing: string, streamable: bool, tag_list: string, tags: string, title: string, track_count: int, tracks: table<access: string, artwork_url: string, available_country_codes: string, bpm: int, comment_count: int, commentable: bool, created_at: string, description: string, download_count: int, download_url: string, downloadable: string, duration: int, embeddable_by: string, favoritings_count: int, genre: string, id: int, isrc: string, key_signature: string, kind: string, label_name: string, license: string, permalink_url: string, playback_count: int, purchase_title: string, purchase_url: string, release: string, release_day: int, release_month: int, release_year: int, reposts_count: int, secret_uri: string, sharing: string, stream_url: string, streamable: bool, tag_list: string, title: string, uri: string, user: record, user_favorite: bool, user_playback_count: int, waveform_url: string>, tracks_uri: string, type: string, uri: string, user: record<avatar_url: string, created_at: string, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, uri: string, username: string>, user_id: int>"
    get-me-tracks-track-id: "record<access: string, artwork_url: string, available_country_codes: string, bpm: int, comment_count: int, commentable: bool, created_at: string, description: string, download_count: int, download_url: string, downloadable: string, duration: int, embeddable_by: string, favoritings_count: int, genre: string, id: int, isrc: string, key_signature: string, kind: string, label_name: string, license: string, permalink_url: string, playback_count: int, purchase_title: string, purchase_url: string, release: string, release_day: int, release_month: int, release_year: int, reposts_count: int, secret_uri: string, sharing: string, stream_url: string, streamable: bool, tag_list: string, title: string, uri: string, user: record<avatar_url: string, created_at: string, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, uri: string, username: string>, user_favorite: bool, user_playback_count: int, waveform_url: string>"
    post-playlists: "record<artwork_url: string, created_at: string, description: string, downloadable: bool, duration: int, ean: string, embeddable_by: string, genre: string, id: int, kind: string, label_id: int, label_name: string, last_modified: string, license: string, permalink: string, permalink_url: string, playlist_type: string, purchase_title: string, purchase_url: string, release: string, release_day: int, release_month: int, release_year: int, sharing: string, streamable: bool, tag_list: string, title: string, track_count: int, tracks: table<artwork_url: string, bpm: int, comment_count: int, commentable: bool, created_at: string, description: string, download_count: int, downloadable: string, duration: int, embeddable_by: string, favoritings_count: int, genre: string, id: int, isrc: string, key_signature: string, kind: string, label_name: string, license: string, permalink_url: string, playback_count: int, purchase_title: string, purchase_url: string, release: string, release_day: int, release_month: int, release_year: int, sharing: string, stream_url: string, streamable: bool, tag_list: string, title: string, uri: string, user: record, user_favorite: bool, user_playback_count: int, waveform_url: string>, type: string, uri: string, user: record<avatar_url: string, created_at: string, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, uri: string, username: string>, user_id: int>"
    get-playlists-playlist-id: "record<artwork_url: string, created_at: string, description: string, downloadable: bool, duration: int, ean: string, embeddable_by: string, genre: string, id: int, kind: string, label: record<avatar_url: string, created_at: string, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, uri: string, username: string>, label_id: int, label_name: string, last_modified: string, license: string, likes_count: int, permalink: string, permalink_url: string, playlist_type: string, purchase_title: string, purchase_url: string, release: string, release_day: int, release_month: int, release_year: int, sharing: string, streamable: bool, tag_list: string, tags: string, title: string, track_count: int, tracks: table<access: string, artwork_url: string, available_country_codes: string, bpm: int, comment_count: int, commentable: bool, created_at: string, description: string, download_count: int, download_url: string, downloadable: string, duration: int, embeddable_by: string, favoritings_count: int, genre: string, id: int, isrc: string, key_signature: string, kind: string, label_name: string, license: string, permalink_url: string, playback_count: int, purchase_title: string, purchase_url: string, release: string, release_day: int, release_month: int, release_year: int, reposts_count: int, secret_uri: string, sharing: string, stream_url: string, streamable: bool, tag_list: string, title: string, uri: string, user: record, user_favorite: bool, user_playback_count: int, waveform_url: string>, tracks_uri: string, type: string, uri: string, user: record<avatar_url: string, created_at: string, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, uri: string, username: string>, user_id: int>"
    put-playlists-playlist-id: "record<artwork_url: string, created_at: string, description: string, downloadable: bool, duration: int, ean: string, embeddable_by: string, genre: string, id: int, kind: string, label_id: int, label_name: string, last_modified: string, license: string, permalink: string, permalink_url: string, playlist_type: string, purchase_title: string, purchase_url: string, release: string, release_day: int, release_month: int, release_year: int, sharing: string, streamable: bool, tag_list: string, title: string, track_count: int, tracks: table<artwork_url: string, bpm: int, comment_count: int, commentable: bool, created_at: string, description: string, download_count: int, downloadable: string, duration: int, embeddable_by: string, favoritings_count: int, genre: string, id: int, isrc: string, key_signature: string, kind: string, label_name: string, license: string, permalink_url: string, playback_count: int, purchase_title: string, purchase_url: string, release: string, release_day: int, release_month: int, release_year: int, sharing: string, stream_url: string, streamable: bool, tag_list: string, title: string, uri: string, user: record, user_favorite: bool, user_playback_count: int, waveform_url: string>, type: string, uri: string, user: record<avatar_url: string, created_at: string, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, uri: string, username: string>, user_id: int>"
    get-playlists-playlist-id-reposters: "record<collection: table<avatar_url: string, created_at: string, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, uri: string, username: string>, next_href: string>"
    post-tracks: "record<access: string, artwork_url: string, available_country_codes: string, bpm: int, comment_count: int, commentable: bool, created_at: string, description: string, download_count: int, download_url: string, downloadable: string, duration: int, embeddable_by: string, favoritings_count: int, genre: string, id: int, isrc: string, key_signature: string, kind: string, label_name: string, license: string, permalink_url: string, playback_count: int, purchase_title: string, purchase_url: string, release: string, release_day: int, release_month: int, release_year: int, reposts_count: int, secret_uri: string, sharing: string, stream_url: string, streamable: bool, tag_list: string, title: string, uri: string, user: record<avatar_url: string, created_at: string, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, uri: string, username: string>, user_favorite: bool, user_playback_count: int, waveform_url: string>"
    get-tracks-track-id: "record<access: string, artwork_url: string, available_country_codes: string, bpm: int, comment_count: int, commentable: bool, created_at: string, description: string, download_count: int, download_url: string, downloadable: string, duration: int, embeddable_by: string, favoritings_count: int, genre: string, id: int, isrc: string, key_signature: string, kind: string, label_name: string, license: string, permalink_url: string, playback_count: int, purchase_title: string, purchase_url: string, release: string, release_day: int, release_month: int, release_year: int, reposts_count: int, secret_uri: string, sharing: string, stream_url: string, streamable: bool, tag_list: string, title: string, uri: string, user: record<avatar_url: string, created_at: string, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, uri: string, username: string>, user_favorite: bool, user_playback_count: int, waveform_url: string>"
    put-tracks-track-id: "record<access: string, artwork_url: string, available_country_codes: string, bpm: int, comment_count: int, commentable: bool, created_at: string, description: string, download_count: int, download_url: string, downloadable: string, duration: int, embeddable_by: string, favoritings_count: int, genre: string, id: int, isrc: string, key_signature: string, kind: string, label_name: string, license: string, permalink_url: string, playback_count: int, purchase_title: string, purchase_url: string, release: string, release_day: int, release_month: int, release_year: int, reposts_count: int, secret_uri: string, sharing: string, stream_url: string, streamable: bool, tag_list: string, title: string, uri: string, user: record<avatar_url: string, created_at: string, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, uri: string, username: string>, user_favorite: bool, user_playback_count: int, waveform_url: string>"
    post-tracks-track-id-comments: "record<body: string, created_at: string, id: int, kind: string, timestamp: string, track_id: int, uri: string, user: record<avatar_url: string, followers_count: int, followings_count: int, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, reposts_count: int, uri: string, username: string>, user_id: int>"
    get-tracks-track-id-favoriters: "table<avatar_url: string, city: string, country: string, description: string, discogs_name: string, first_name: string, followers_count: int, followings_count: int, full_name: string, id: int, kind: string, last_modified: string, last_name: string, myspace_name: string, permalink: string, permalink_url: string, plan: string, playlist_count: int, public_favorites_count: int, reposts_count: int, subscriptions: list<list>, track_count: int, uri: string, username: string, website: string, website_title: string>"
    get-tracks-track-id-reposters: "record<collection: table<avatar_url: string, created_at: string, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, uri: string, username: string>, next_href: string>"
    get-tracks-track-id-streams: "record<hls_mp3_128_url: string, hls_opus_64_url: string, http_mp3_128_url: string, preview_mp3_128_url: string>"
    get-users-user-id: "record<avatar_url: string, city: string, country: string, description: string, discogs_name: string, first_name: string, followers_count: int, followings_count: int, full_name: string, id: int, kind: string, last_modified: string, last_name: string, locale: string, myspace_name: string, permalink: string, permalink_url: string, plan: string, playlist_count: int, primary_email_confirmed: bool, private_playlists_count: int, private_tracks_count: int, public_favorites_count: int, quota: record<unlimited_upload_quota: bool, upload_seconds_used: int>, reposts_count: int, subscriptions: list<list<any>>, track_count: int, uri: string, username: string, website: string, website_title: string>"
    get-users-user-id-comments: "table<body: string, created_at: string, id: int, kind: string, timestamp: string, track_id: int, uri: string, user: record<avatar_url: string, followers_count: int, followings_count: int, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, reposts_count: int, uri: string, username: string>, user_id: int>"
    get-users-user-id-followings-following-id: "record<avatar_url: string, city: string, country: string, description: string, discogs_name: string, first_name: string, followers_count: int, followings_count: int, full_name: string, id: int, kind: string, last_modified: string, last_name: string, locale: string, myspace_name: string, permalink: string, permalink_url: string, plan: string, playlist_count: int, primary_email_confirmed: bool, private_playlists_count: int, private_tracks_count: int, public_favorites_count: int, quota: record<unlimited_upload_quota: bool, upload_seconds_used: int>, reposts_count: int, subscriptions: list<list<any>>, track_count: int, uri: string, username: string, website: string, website_title: string>"
    get-users-user-id-web-profiles: "table<created_at: string, id: int, kind: string, service: string, title: string, url: string, username: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-connect" "delete-likes-playlists-playlist-id" "post-likes-playlists-playlist-id" "delete-likes-tracks-track-id" "post-likes-tracks-track-id" "get-me" "get-me-activities" "get-me-activities-all-own" "get-me-activities-tracks" "get-me-connections" "get-me-connections-connection-id" "get-me-favorites-ids" "get-me-followers" "get-me-followers-follower-id" "get-me-followings" "get-me-followings-tracks" "delete-me-followings-user-id" "get-me-followings-user-id" "put-me-followings-user-id" "get-me-likes-tracks" "get-me-playlists" "get-me-playlists-playlist-id" "get-me-tracks" "get-me-tracks-track-id" "post-oauth2-token" "get-playlists" "post-playlists" "delete-playlists-playlist-id" "get-playlists-playlist-id" "put-playlists-playlist-id" "get-playlists-playlist-id-reposters" "get-playlists-playlist-id-tracks" "delete-reposts-playlists-playlist-id" "post-reposts-playlists-playlist-id" "delete-reposts-tracks-track-id" "post-reposts-tracks-track-id" "get-resolve" "get-tracks" "post-tracks" "delete-tracks-track-id" "get-tracks-track-id" "put-tracks-track-id" "get-tracks-track-id-comments" "post-tracks-track-id-comments" "get-tracks-track-id-favoriters" "get-tracks-track-id-related" "get-tracks-track-id-reposters" "get-tracks-track-id-streams" "get-users" "get-users-user-id" "get-users-user-id-comments" "get-users-user-id-favorites" "get-users-user-id-followers" "get-users-user-id-followings" "get-users-user-id-followings-following-id" "get-users-user-id-likes-tracks" "get-users-user-id-playlists" "get-users-user-id-tracks" "get-users-user-id-web-profiles" "commands"] | sort) } | get name | first)
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

# The OAuth2 authorization endpoint. Your app redirects a user to this endpoint, allowing them to delegate access to their account.
#
# GET /connect
export def "get-connect" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-authheader: string # Auth token for AuthHeader (Authorization)
  --token-clientid: string # Auth token for ClientId (client_id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # The client id belonging to your application (required, e.g. some client)
  --redirect-uri: string # The redirect uri you have configured for your application (required, e.g. https://soundcloud.com)
  --response-type: string@response-type-completer # It's recommended to use "code" here (required, e.g. code)
  --scope: string # Scope (required, e.g. default)
  --state: string # Any value included here will be appended to the redirect URI. Use this for CSRF protection. (e.g. encrypted_session_info)
]: nothing -> any {
  http-request {
    method: get
    path: "/connect"
    query: [{name: client_id, var: client_id, required: true}, {name: redirect_uri, var: redirect_uri, required: true}, {name: response_type, var: response_type, required: true}, {name: scope, var: scope, required: true}, {name: state, var: state}]
    accept: ["application/json"]
    ok: [302]
    auth_all: [{scheme: bearer, var: token_authheader, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_AUTHHEADER_TOKEN}, {scheme: query-client_id, var: token_clientid, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_CLIENTID_TOKEN}]
  } {
    client_id: $client_id, redirect_uri: $redirect_uri, response_type: $response_type, scope: $scope, state: $state
    base_url: $base_url, token_authheader: $token_authheader, token_clientid: $token_clientid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unlikes a playlist.
#
# DELETE /likes/playlists/{playlist_id}
export def "delete-likes-playlists-playlist-id" [
  playlist_id: int
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
    method: delete
    path: "/likes/playlists/{playlist_id}"
    path_params: [{name: playlist_id, var: playlist_id}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    playlist_id: $playlist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Likes a playlist.
#
# POST /likes/playlists/{playlist_id}
export def "post-likes-playlists-playlist-id" [
  playlist_id: int
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
    method: post
    path: "/likes/playlists/{playlist_id}"
    path_params: [{name: playlist_id, var: playlist_id}]
    accept: ["application/json; charset=utf-8"]
    ok: [200, 201]
    auth: bearer
  } {
    playlist_id: $playlist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unlikes a track.
#
# DELETE /likes/tracks/{track_id}
export def "delete-likes-tracks-track-id" [
  track_id: int
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
    method: delete
    path: "/likes/tracks/{track_id}"
    path_params: [{name: track_id, var: track_id}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    track_id: $track_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Likes a track.
#
# POST /likes/tracks/{track_id}
export def "post-likes-tracks-track-id" [
  track_id: int
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
    method: post
    path: "/likes/tracks/{track_id}"
    path_params: [{name: track_id, var: track_id}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    track_id: $track_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the authenticated user’s information.
#
# GET /me
# Returns: record<avatar_url: string, city: string, country: string, description: string, discogs_name: string, first_name: string, followers_count: int, followings_count: int, full_name: string, id: int, kind: string, last_modified: string, last_name: string, locale: string, myspace_name: string, permalink: string, permalink_url: string, plan: string, playlist_count: int, primary_email_confirmed: bool, private_playlists_count: int, private_tracks_count: int, public_favorites_count: int, quota: record<unlimited_upload_quota: bool, upload_seconds_used: int>, reposts_count: int, subscriptions: list<list<any>>, track_count: int, uri: string, username: string, website: string, website_title: string>
export def "get-me" [
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
    path: "/me"
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the authenticated user's activities.
#
# GET /me/activities
# Returns: record<collection: table<created_at: string, origin: record, type: string>, future_href: string, next_href: string>
export def "get-me-activities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access: list<string> # Filters content by level of access the user (logged in or anonymous) has to the track. The result list will include only tracks with the specified access. Include all options if you'd like to see all possible tracks. See `Track#access` schema for more details. (default: playable,preview)
  --limit: int # Number of results to return in the collection. (default: 50, e.g. 2)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/me/activities"
    query: [{name: access, var: access, style: csv}, {name: limit, var: limit}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    access: $access, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recent the authenticated user's activities.
#
# GET /me/activities/all/own
# Returns: record<collection: table<created_at: string, origin: record, type: string>, future_href: string, next_href: string>
export def "get-me-activities-all-own" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access: list<string> # Filters content by level of access the user (logged in or anonymous) has to the track. The result list will include only tracks with the specified access. Include all options if you'd like to see all possible tracks. See `Track#access` schema for more details. (default: playable,preview)
  --limit: int # Number of results to return in the collection. (default: 50, e.g. 2)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/me/activities/all/own"
    query: [{name: access, var: access, style: csv}, {name: limit, var: limit}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    access: $access, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the authenticated user's recent track related activities.
#
# GET /me/activities/tracks
# Returns: record<collection: table<created_at: string, origin: record, type: string>, future_href: string, next_href: string>
export def "get-me-activities-tracks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access: list<string> # Filters content by level of access the user (logged in or anonymous) has to the track. The result list will include only tracks with the specified access. Include all options if you'd like to see all possible tracks. See `Track#access` schema for more details. (default: playable,preview)
  --limit: int # Number of results to return in the collection. (default: 50, e.g. 2)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/me/activities/tracks"
    query: [{name: access, var: access, style: csv}, {name: limit, var: limit}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    access: $access, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of the authenticated user's connected social accounts.
#
# GET /me/connections
# Returns: table<created_at: string, display_name: string, id: int, kind: string, post_favorite: bool, post_publish: bool, service: string, type: string, uri: string>
@deprecated --flag offset
export def "get-me-connections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return in the collection. (default: 50, e.g. 2)
  --offset: int # Offset of first result. Deprecated, use `linked_partitioning` instead. (DEPRECATED, default: 0, e.g. 0)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/me/connections"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the authenticated user's connected social account.
#
# GET /me/connections/{connection_id}
# Returns: record<created_at: string, display_name: string, id: int, kind: string, post_favorite: bool, post_publish: bool, service: string, type: string, uri: string>
export def "get-me-connections-connection-id" [
  connection_id: int
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
    path: "/me/connections/{connection_id}"
    path_params: [{name: connection_id, var: connection_id}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns user’s favorites ids. (use /me/likes/tracks instead to fetch the authenticated user's likes)
#
# GET /me/favorites/ids
# DEPRECATED
@deprecated
export def "get-me-favorites-ids" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return in the collection. (default: 50, e.g. 2)
]: nothing -> any {
  http-request {
    method: get
    path: "/me/favorites/ids"
    query: [{name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of users who are following the authenticated user.
#
# GET /me/followers
export def "get-me-followers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return in the collection. (default: 50, e.g. 2)
]: nothing -> any {
  http-request {
    method: get
    path: "/me/followers"
    query: [{name: limit, var: limit}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a user who is following the authenticated user. (use /users/{user_id} instead, to fetch the user details)
#
# GET /me/followers/{follower_id}
# DEPRECATED
# Returns: record<avatar_url: string, city: string, country: string, created_at: string, description: string, discogs_name: string, first_name: string, followers_count: int, followings_count: int, full_name: string, id: int, kind: string, last_modified: string, last_name: string, myspace_name: string, permalink: string, permalink_url: string, plan: string, playlist_count: int, public_favorites_count: int, reposts_count: int, subscriptions: list<list<any>>, track_count: int, uri: string, username: string, website: string, website_title: string>
@deprecated
export def "get-me-followers-follower-id" [
  follower_id: int
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
    path: "/me/followers/{follower_id}"
    path_params: [{name: follower_id, var: follower_id}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    follower_id: $follower_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of users who are followed by the authenticated user.
#
# GET /me/followings
@deprecated --flag offset
export def "get-me-followings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return in the collection. (default: 50, e.g. 2)
  --offset: int # Offset of first result. Deprecated, use `linked_partitioning` instead. (DEPRECATED, default: 0, e.g. 0)
]: nothing -> any {
  http-request {
    method: get
    path: "/me/followings"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of recent tracks from users followed by the authenticated user.
#
# GET /me/followings/tracks
# Returns: table<access: string, artwork_url: string, available_country_codes: string, bpm: int, comment_count: int, commentable: bool, created_at: string, description: string, download_count: int, download_url: string, downloadable: string, duration: int, embeddable_by: string, favoritings_count: int, genre: string, id: int, isrc: string, key_signature: string, kind: string, label_name: string, license: string, permalink_url: string, playback_count: int, purchase_title: string, purchase_url: string, release: string, release_day: int, release_month: int, release_year: int, reposts_count: int, secret_uri: string, sharing: string, stream_url: string, streamable: bool, tag_list: string, title: string, uri: string, user: record<avatar_url: string, created_at: string, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, uri: string, username: string>, user_favorite: bool, user_playback_count: int, waveform_url: string>
@deprecated --flag offset
export def "get-me-followings-tracks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access: list<string> # Filters content by level of access the user (logged in or anonymous) has to the track. The result list will include only tracks with the specified access. Include all options if you'd like to see all possible tracks. See `Track#access` schema for more details. (default: playable,preview)
  --limit: int # Number of results to return in the collection. (default: 50, e.g. 2)
  --offset: int # Offset of first result. Deprecated, use `linked_partitioning` instead. (DEPRECATED, default: 0, e.g. 0)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/me/followings/tracks"
    query: [{name: access, var: access, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    access: $access, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a user who is followed by the authenticated user.
#
# DELETE /me/followings/{user_id}
export def "delete-me-followings-user-id" [
  user_id: int
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
    method: delete
    path: "/me/followings/{user_id}"
    path_params: [{name: user_id, var: user_id}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a user who is followed by the authenticated user. (use /users/{user_id} instead, to fetch the user details)
#
# GET /me/followings/{user_id}
# DEPRECATED
# Returns: record<avatar_url: string, city: string, country: string, created_at: string, description: string, discogs_name: string, first_name: string, followers_count: int, followings_count: int, full_name: string, id: int, kind: string, last_modified: string, last_name: string, myspace_name: string, permalink: string, permalink_url: string, plan: string, playlist_count: int, public_favorites_count: int, reposts_count: int, subscriptions: list<list<any>>, track_count: int, uri: string, username: string, website: string, website_title: string>
@deprecated
export def "get-me-followings-user-id" [
  user_id: int
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
    path: "/me/followings/{user_id}"
    path_params: [{name: user_id, var: user_id}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Follows a user.
#
# PUT /me/followings/{user_id}
# Returns: record<avatar_url: string, city: string, country: string, created_at: string, description: string, discogs_name: string, first_name: string, followers_count: int, followings_count: int, full_name: string, id: int, kind: string, last_modified: string, last_name: string, myspace_name: string, permalink: string, permalink_url: string, plan: string, playlist_count: int, public_favorites_count: int, reposts_count: int, subscriptions: list<list<any>>, track_count: int, uri: string, username: string, website: string, website_title: string>
export def "put-me-followings-user-id" [
  user_id: int
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
    method: put
    path: "/me/followings/{user_id}"
    path_params: [{name: user_id, var: user_id}]
    accept: ["application/json; charset=utf-8"]
    ok: [200, 201]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of favorited or liked tracks of the authenticated user.
#
# GET /me/likes/tracks
export def "get-me-likes-tracks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return in the collection. (default: 50, e.g. 2)
  --linked-partitioning: oneof<nothing, bool> # Returns paginated collection of items (recommended, returning a list without pagination is deprecated and should not be used) (e.g. true)
]: nothing -> any {
  http-request {
    method: get
    path: "/me/likes/tracks"
    query: [{name: limit, var: limit}, {name: linked_partitioning, var: linked_partitioning}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, linked_partitioning: $linked_partitioning
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns user’s playlists (sets).
#
# GET /me/playlists
# Returns: table<artwork_url: string, created_at: string, description: string, downloadable: bool, duration: int, ean: string, embeddable_by: string, genre: string, id: int, kind: string, label: record<avatar_url: string, created_at: string, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, uri: string, username: string>, label_id: int, label_name: string, last_modified: string, license: string, likes_count: int, permalink: string, permalink_url: string, playlist_type: string, purchase_title: string, purchase_url: string, release: string, release_day: int, release_month: int, release_year: int, sharing: string, streamable: bool, tag_list: string, tags: string, title: string, track_count: int, tracks: list<record>, tracks_uri: string, type: string, uri: string, user: record<avatar_url: string, created_at: string, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, uri: string, username: string>, user_id: int>
export def "get-me-playlists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return in the collection. (default: 50, e.g. 2)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/me/playlists"
    query: [{name: limit, var: limit}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns playlist. (use /playlists/{playlist_id} instead, to fetch the playlist details)
#
# GET /me/playlists/{playlist_id}
# DEPRECATED
# Returns: record<artwork_url: string, created_at: string, description: string, downloadable: bool, duration: int, ean: string, embeddable_by: string, genre: string, id: int, kind: string, label: record<avatar_url: string, created_at: string, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, uri: string, username: string>, label_id: int, label_name: string, last_modified: string, license: string, likes_count: int, permalink: string, permalink_url: string, playlist_type: string, purchase_title: string, purchase_url: string, release: string, release_day: int, release_month: int, release_year: int, sharing: string, streamable: bool, tag_list: string, tags: string, title: string, track_count: int, tracks: table<access: string, artwork_url: string, available_country_codes: string, bpm: int, comment_count: int, commentable: bool, created_at: string, description: string, download_count: int, download_url: string, downloadable: string, duration: int, embeddable_by: string, favoritings_count: int, genre: string, id: int, isrc: string, key_signature: string, kind: string, label_name: string, license: string, permalink_url: string, playback_count: int, purchase_title: string, purchase_url: string, release: string, release_day: int, release_month: int, release_year: int, reposts_count: int, secret_uri: string, sharing: string, stream_url: string, streamable: bool, tag_list: string, title: string, uri: string, user: record, user_favorite: bool, user_playback_count: int, waveform_url: string>, tracks_uri: string, type: string, uri: string, user: record<avatar_url: string, created_at: string, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, uri: string, username: string>, user_id: int>
@deprecated
export def "get-me-playlists-playlist-id" [
  playlist_id: int
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
    path: "/me/playlists/{playlist_id}"
    path_params: [{name: playlist_id, var: playlist_id}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    playlist_id: $playlist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of user's tracks.
#
# GET /me/tracks
export def "get-me-tracks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return in the collection. (default: 50, e.g. 2)
  --linked-partitioning: oneof<nothing, bool> # Returns paginated collection of items (recommended, returning a list without pagination is deprecated and should not be used) (e.g. true)
]: nothing -> any {
  http-request {
    method: get
    path: "/me/tracks"
    query: [{name: limit, var: limit}, {name: linked_partitioning, var: linked_partitioning}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, linked_partitioning: $linked_partitioning
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a specified track. (use /tracks/{track_id} instead, to fetch the track details)
#
# GET /me/tracks/{track_id}
# DEPRECATED
# Returns: record<access: string, artwork_url: string, available_country_codes: string, bpm: int, comment_count: int, commentable: bool, created_at: string, description: string, download_count: int, download_url: string, downloadable: string, duration: int, embeddable_by: string, favoritings_count: int, genre: string, id: int, isrc: string, key_signature: string, kind: string, label_name: string, license: string, permalink_url: string, playback_count: int, purchase_title: string, purchase_url: string, release: string, release_day: int, release_month: int, release_year: int, reposts_count: int, secret_uri: string, sharing: string, stream_url: string, streamable: bool, tag_list: string, title: string, uri: string, user: record<avatar_url: string, created_at: string, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, uri: string, username: string>, user_favorite: bool, user_playback_count: int, waveform_url: string>
@deprecated
export def "get-me-tracks-track-id" [
  track_id: int
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
    path: "/me/tracks/{track_id}"
    path_params: [{name: track_id, var: track_id}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    track_id: $track_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This endpoint accepts POST requests and is used to provision access tokens once a user has authorized your application.
#
# POST /oauth2/token
export def "post-oauth2-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization-code: string # Authorization code
  --client-id: string # Client ID
  --client-secret: string # Client secret
  --grant-type: string@grant-type-completer
  --redirect-uri: string # Redirect URI
  --refresh-token: string # Refresh token
  --password: string # User password
  --user-name: string # User name
]: any -> any {
  $in | http-request {
    method: post
    path: "/oauth2/token"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: authorization_code, var: authorization_code}, {name: client_id, var: client_id}, {name: client_secret, var: client_secret}, {name: grant_type, var: grant_type}, {name: redirect_uri, var: redirect_uri}, {name: refresh_token, var: refresh_token}, {name: password, var: password}, {name: user_name, var: user_name}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: query-client_id
  } {
    authorization_code: $authorization_code, client_id: $client_id, client_secret: $client_secret, grant_type: $grant_type, redirect_uri: $redirect_uri, refresh_token: $refresh_token, password: $password, user_name: $user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Performs a playlist search based on a query
#
# GET /playlists
@deprecated --flag offset
export def "get-playlists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-authheader: string # Auth token for AuthHeader (Authorization)
  --token-clientid: string # Auth token for ClientId (client_id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # search (required, e.g. hello)
  --access: list<string> # Filters content by level of access the user (logged in or anonymous) has to the track. The result list will include only tracks with the specified access. Include all options if you'd like to see all possible tracks. See `Track#access` schema for more details. (default: playable,preview)
  --limit: int # Number of results to return in the collection. (default: 50, e.g. 2)
  --offset: int # Offset of first result. Deprecated, use `linked_partitioning` instead. (DEPRECATED, default: 0, e.g. 0)
  --linked-partitioning: oneof<nothing, bool> # Returns paginated collection of items (recommended, returning a list without pagination is deprecated and should not be used) (e.g. true)
]: nothing -> any {
  http-request {
    method: get
    path: "/playlists"
    query: [{name: q, var: q, required: true}, {name: access, var: access, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}, {name: linked_partitioning, var: linked_partitioning}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: bearer, var: token_authheader, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_AUTHHEADER_TOKEN}, {scheme: query-client_id, var: token_clientid, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_CLIENTID_TOKEN}]
  } {
    q: $q, access: $access, limit: $limit, offset: $offset, linked_partitioning: $linked_partitioning
    base_url: $base_url, token_authheader: $token_authheader, token_clientid: $token_clientid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a playlist.
#
# POST /playlists
# Returns: record<artwork_url: string, created_at: string, description: string, downloadable: bool, duration: int, ean: string, embeddable_by: string, genre: string, id: int, kind: string, label_id: int, label_name: string, last_modified: string, license: string, permalink: string, permalink_url: string, playlist_type: string, purchase_title: string, purchase_url: string, release: string, release_day: int, release_month: int, release_year: int, sharing: string, streamable: bool, tag_list: string, title: string, track_count: int, tracks: table<artwork_url: string, bpm: int, comment_count: int, commentable: bool, created_at: string, description: string, download_count: int, downloadable: string, duration: int, embeddable_by: string, favoritings_count: int, genre: string, id: int, isrc: string, key_signature: string, kind: string, label_name: string, license: string, permalink_url: string, playback_count: int, purchase_title: string, purchase_url: string, release: string, release_day: int, release_month: int, release_year: int, sharing: string, stream_url: string, streamable: bool, tag_list: string, title: string, uri: string, user: record, user_favorite: bool, user_playback_count: int, waveform_url: string>, type: string, uri: string, user: record<avatar_url: string, created_at: string, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, uri: string, username: string>, user_id: int>
export def "post-playlists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --playlist: record # shape: {description?: string, sharing?: "public"|"private", title?: string, tracks?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/playlists"
    body: {content_type: "application/json", kind: json, fields: [{name: playlist, var: playlist}]}
    accept: ["application/json; charset=utf-8"]
    ok: [201]
    auth: bearer
  } {
    playlist: $playlist
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a playlist.
#
# DELETE /playlists/{playlist_id}
export def "delete-playlists-playlist-id" [
  playlist_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-authheader: string # Auth token for AuthHeader (Authorization)
  --token-clientid: string # Auth token for ClientId (client_id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/playlists/{playlist_id}"
    path_params: [{name: playlist_id, var: playlist_id}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: bearer, var: token_authheader, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_AUTHHEADER_TOKEN}, {scheme: query-client_id, var: token_clientid, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_CLIENTID_TOKEN}]
  } {
    playlist_id: $playlist_id
    base_url: $base_url, token_authheader: $token_authheader, token_clientid: $token_clientid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a playlist.
#
# GET /playlists/{playlist_id}
# Returns: record<artwork_url: string, created_at: string, description: string, downloadable: bool, duration: int, ean: string, embeddable_by: string, genre: string, id: int, kind: string, label: record<avatar_url: string, created_at: string, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, uri: string, username: string>, label_id: int, label_name: string, last_modified: string, license: string, likes_count: int, permalink: string, permalink_url: string, playlist_type: string, purchase_title: string, purchase_url: string, release: string, release_day: int, release_month: int, release_year: int, sharing: string, streamable: bool, tag_list: string, tags: string, title: string, track_count: int, tracks: table<access: string, artwork_url: string, available_country_codes: string, bpm: int, comment_count: int, commentable: bool, created_at: string, description: string, download_count: int, download_url: string, downloadable: string, duration: int, embeddable_by: string, favoritings_count: int, genre: string, id: int, isrc: string, key_signature: string, kind: string, label_name: string, license: string, permalink_url: string, playback_count: int, purchase_title: string, purchase_url: string, release: string, release_day: int, release_month: int, release_year: int, reposts_count: int, secret_uri: string, sharing: string, stream_url: string, streamable: bool, tag_list: string, title: string, uri: string, user: record, user_favorite: bool, user_playback_count: int, waveform_url: string>, tracks_uri: string, type: string, uri: string, user: record<avatar_url: string, created_at: string, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, uri: string, username: string>, user_id: int>
export def "get-playlists-playlist-id" [
  playlist_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-authheader: string # Auth token for AuthHeader (Authorization)
  --token-clientid: string # Auth token for ClientId (client_id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --secret-token: string # A secret token to fetch private playlists/tracks
  --access: list<string> # Filters content by level of access the user (logged in or anonymous) has to the track. The result list will include only tracks with the specified access. Include all options if you'd like to see all possible tracks. See `Track#access` schema for more details. (default: playable,preview)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/playlists/{playlist_id}"
    path_params: [{name: playlist_id, var: playlist_id}]
    query: [{name: secret_token, var: secret_token}, {name: access, var: access, style: csv}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: bearer, var: token_authheader, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_AUTHHEADER_TOKEN}, {scheme: query-client_id, var: token_clientid, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_CLIENTID_TOKEN}]
  } {
    playlist_id: $playlist_id, secret_token: $secret_token, access: $access
    base_url: $base_url, token_authheader: $token_authheader, token_clientid: $token_clientid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a playlist.
#
# PUT /playlists/{playlist_id}
# Returns: record<artwork_url: string, created_at: string, description: string, downloadable: bool, duration: int, ean: string, embeddable_by: string, genre: string, id: int, kind: string, label_id: int, label_name: string, last_modified: string, license: string, permalink: string, permalink_url: string, playlist_type: string, purchase_title: string, purchase_url: string, release: string, release_day: int, release_month: int, release_year: int, sharing: string, streamable: bool, tag_list: string, title: string, track_count: int, tracks: table<artwork_url: string, bpm: int, comment_count: int, commentable: bool, created_at: string, description: string, download_count: int, downloadable: string, duration: int, embeddable_by: string, favoritings_count: int, genre: string, id: int, isrc: string, key_signature: string, kind: string, label_name: string, license: string, permalink_url: string, playback_count: int, purchase_title: string, purchase_url: string, release: string, release_day: int, release_month: int, release_year: int, sharing: string, stream_url: string, streamable: bool, tag_list: string, title: string, uri: string, user: record, user_favorite: bool, user_playback_count: int, waveform_url: string>, type: string, uri: string, user: record<avatar_url: string, created_at: string, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, uri: string, username: string>, user_id: int>
export def "put-playlists-playlist-id" [
  playlist_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --playlist: record # shape: {description?: string, sharing?: "public"|"private", title?: string, tracks?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/playlists/{playlist_id}"
    path_params: [{name: playlist_id, var: playlist_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: playlist, var: playlist}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    playlist_id: $playlist_id, playlist: $playlist
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a collection of playlist's reposters.
#
# GET /playlists/{playlist_id}/reposters
# Returns: record<collection: table<avatar_url: string, created_at: string, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, uri: string, username: string>, next_href: string>
export def "get-playlists-playlist-id-reposters" [
  playlist_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return in the collection. (default: 50, e.g. 2)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/playlists/{playlist_id}/reposters"
    path_params: [{name: playlist_id, var: playlist_id}]
    query: [{name: limit, var: limit}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: query-client_id
  } {
    playlist_id: $playlist_id, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns tracks under a playlist.
#
# GET /playlists/{playlist_id}/tracks
export def "get-playlists-playlist-id-tracks" [
  playlist_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-authheader: string # Auth token for AuthHeader (Authorization)
  --token-clientid: string # Auth token for ClientId (client_id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --secret-token: string # A secret token to fetch private playlists/tracks
  --access: list<string> # Filters content by level of access the user (logged in or anonymous) has to the track. The result list will include only tracks with the specified access. Include all options if you'd like to see all possible tracks. See `Track#access` schema for more details. (default: playable,preview)
  --linked-partitioning: oneof<nothing, bool> # Returns paginated collection of items (recommended, returning a list without pagination is deprecated and should not be used) (e.g. true)
]: nothing -> any {
  http-request {
    method: get
    path: "/playlists/{playlist_id}/tracks"
    path_params: [{name: playlist_id, var: playlist_id}]
    query: [{name: secret_token, var: secret_token}, {name: access, var: access, style: csv}, {name: linked_partitioning, var: linked_partitioning}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: bearer, var: token_authheader, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_AUTHHEADER_TOKEN}, {scheme: query-client_id, var: token_clientid, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_CLIENTID_TOKEN}]
  } {
    playlist_id: $playlist_id, secret_token: $secret_token, access: $access, linked_partitioning: $linked_partitioning
    base_url: $base_url, token_authheader: $token_authheader, token_clientid: $token_clientid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a repost on a playlist as the authenticated user
#
# DELETE /reposts/playlists/{playlist_id}
export def "delete-reposts-playlists-playlist-id" [
  playlist_id: int
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
    method: delete
    path: "/reposts/playlists/{playlist_id}"
    path_params: [{name: playlist_id, var: playlist_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    playlist_id: $playlist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reposts a playlist as the authenticated user
#
# POST /reposts/playlists/{playlist_id}
export def "post-reposts-playlists-playlist-id" [
  playlist_id: int
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
    method: post
    path: "/reposts/playlists/{playlist_id}"
    path_params: [{name: playlist_id, var: playlist_id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    playlist_id: $playlist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a repost on a track as the authenticated user
#
# DELETE /reposts/tracks/{track_id}
export def "delete-reposts-tracks-track-id" [
  track_id: int
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
    method: delete
    path: "/reposts/tracks/{track_id}"
    path_params: [{name: track_id, var: track_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    track_id: $track_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reposts a track as the authenticated user
#
# POST /reposts/tracks/{track_id}
export def "post-reposts-tracks-track-id" [
  track_id: int
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
    method: post
    path: "/reposts/tracks/{track_id}"
    path_params: [{name: track_id, var: track_id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    track_id: $track_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resolves soundcloud.com URLs to Resource URLs to use with the API.
#
# GET /resolve
export def "get-resolve" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-authheader: string # Auth token for AuthHeader (Authorization)
  --token-clientid: string # Auth token for ClientId (client_id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --url: string # SoundCloud URL (required, e.g. https://soundcloud.com/user-434241656)
]: nothing -> any {
  http-request {
    method: get
    path: "/resolve"
    query: [{name: url, var: url, required: true}]
    accept: ["application/json"]
    ok: [302]
    auth_all: [{scheme: bearer, var: token_authheader, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_AUTHHEADER_TOKEN}, {scheme: query-client_id, var: token_clientid, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_CLIENTID_TOKEN}]
  } {
    url: $url
    base_url: $base_url, token_authheader: $token_authheader, token_clientid: $token_clientid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Performs a track search based on a query
#
# GET /tracks
@deprecated --flag offset
export def "get-tracks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-authheader: string # Auth token for AuthHeader (Authorization)
  --token-clientid: string # Auth token for ClientId (client_id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # search (required, e.g. hello)
  --ids: string # A comma separated list of track ids to filter on (e.g. 1,2,3)
  --genres: string # A comma separated list of genres (e.g. Pop,House)
  --tags: string # A comma separated list of tags (e.g. test)
  --bpm: record # Return tracks with a specified bpm[from], bpm[to]
  --duration: record # Return tracks within a specified duration range
  --created-at: record # (yyyy-mm-dd hh:mm:ss) return tracks created within the specified dates
  --access: list<string> # Filters content by level of access the user (logged in or anonymous) has to the track. The result list will include only tracks with the specified access. Include all options if you'd like to see all possible tracks. See `Track#access` schema for more details. (default: playable,preview)
  --limit: int # Number of results to return in the collection. (default: 50, e.g. 2)
  --offset: int # Offset of first result. Deprecated, use `linked_partitioning` instead. (DEPRECATED, default: 0, e.g. 0)
  --linked-partitioning: oneof<nothing, bool> # Returns paginated collection of items (recommended, returning a list without pagination is deprecated and should not be used) (e.g. true)
]: nothing -> any {
  http-request {
    method: get
    path: "/tracks"
    query: [{name: q, var: q, required: true}, {name: ids, var: ids}, {name: genres, var: genres}, {name: tags, var: tags}, {name: bpm, var: bpm, style: deepObject}, {name: duration, var: duration, style: deepObject}, {name: created_at, var: created_at, style: deepObject}, {name: access, var: access, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}, {name: linked_partitioning, var: linked_partitioning}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: bearer, var: token_authheader, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_AUTHHEADER_TOKEN}, {scheme: query-client_id, var: token_clientid, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_CLIENTID_TOKEN}]
  } {
    q: $q, ids: $ids, genres: $genres, tags: $tags, bpm: $bpm, duration: $duration, created_at: $created_at, access: $access, limit: $limit, offset: $offset, linked_partitioning: $linked_partitioning
    base_url: $base_url, token_authheader: $token_authheader, token_clientid: $token_clientid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uploads a new track.
#
# POST /tracks
# Returns: record<access: string, artwork_url: string, available_country_codes: string, bpm: int, comment_count: int, commentable: bool, created_at: string, description: string, download_count: int, download_url: string, downloadable: string, duration: int, embeddable_by: string, favoritings_count: int, genre: string, id: int, isrc: string, key_signature: string, kind: string, label_name: string, license: string, permalink_url: string, playback_count: int, purchase_title: string, purchase_url: string, release: string, release_day: int, release_month: int, release_year: int, reposts_count: int, secret_uri: string, sharing: string, stream_url: string, streamable: bool, tag_list: string, title: string, uri: string, user: record<avatar_url: string, created_at: string, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, uri: string, username: string>, user_favorite: bool, user_playback_count: int, waveform_url: string>
export def "post-tracks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-authheader: string # Auth token for AuthHeader (Authorization)
  --token-clientid: string # Auth token for ClientId (client_id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --track-artwork-data: string # format: binary
  --track-asset-data: string # format: binary
  --track-commentable: oneof<nothing, bool> # default: true
  --track-description: string
  --track-downloadable: oneof<nothing, bool> # default: true
  --track-embeddable-by: string@track-embeddable-by-completer # who can embed this track "all", "me", or "none"
  --track-genre: string
  --track-isrc: string
  --track-label-name: string
  --track-license: string@track-license-completer # Possible values: no-rights-reserved, all-rights-reserved, cc-by, cc-by-nc, cc-by-nd, cc-by-sa, cc-by-nc-nd, cc-by-nc-sa
  --track-permalink: string
  --track-purchase-url: string
  --track-release: string
  --track-release-date: string # string, formatted as yyyy-mm-dd, representing release date
  --track-sharing: string@track-sharing-completer # default: public
  --track-streamable: oneof<nothing, bool> # default: true
  --track-tag-list: string # The tag_list property contains a list of tags separated by spaces. Multiword tags are quoted in double quotes. We also support machine tags that follow the pattern NAMESPACE:KEY=VALUE. For example: geo:lat=43.555 camel:size=medium “machine:tag=with space” Machine tags are not revealed to the user on the track pages.
  --track-title: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tracks"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: "track[artwork_data]", var: track_artwork_data}, {name: "track[asset_data]", var: track_asset_data}, {name: "track[commentable]", var: track_commentable}, {name: "track[description]", var: track_description}, {name: "track[downloadable]", var: track_downloadable}, {name: "track[embeddable_by]", var: track_embeddable_by}, {name: "track[genre]", var: track_genre}, {name: "track[isrc]", var: track_isrc}, {name: "track[label_name]", var: track_label_name}, {name: "track[license]", var: track_license}, {name: "track[permalink]", var: track_permalink}, {name: "track[purchase_url]", var: track_purchase_url}, {name: "track[release]", var: track_release}, {name: "track[release_date]", var: track_release_date}, {name: "track[sharing]", var: track_sharing}, {name: "track[streamable]", var: track_streamable}, {name: "track[tag_list]", var: track_tag_list}, {name: "track[title]", var: track_title}], files: ["track[artwork_data]", "track[asset_data]"]}
    accept: ["application/json; charset=utf-8"]
    ok: [201]
    auth_all: [{scheme: bearer, var: token_authheader, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_AUTHHEADER_TOKEN}, {scheme: query-client_id, var: token_clientid, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_CLIENTID_TOKEN}]
  } {
    track_artwork_data: $track_artwork_data, track_asset_data: $track_asset_data, track_commentable: $track_commentable, track_description: $track_description, track_downloadable: $track_downloadable, track_embeddable_by: $track_embeddable_by, track_genre: $track_genre, track_isrc: $track_isrc, track_label_name: $track_label_name, track_license: $track_license, track_permalink: $track_permalink, track_purchase_url: $track_purchase_url, track_release: $track_release, track_release_date: $track_release_date, track_sharing: $track_sharing, track_streamable: $track_streamable, track_tag_list: $track_tag_list, track_title: $track_title
    base_url: $base_url, token_authheader: $token_authheader, token_clientid: $token_clientid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a track.
#
# DELETE /tracks/{track_id}
export def "delete-tracks-track-id" [
  track_id: int
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
    method: delete
    path: "/tracks/{track_id}"
    path_params: [{name: track_id, var: track_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    track_id: $track_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a track.
#
# GET /tracks/{track_id}
# Returns: record<access: string, artwork_url: string, available_country_codes: string, bpm: int, comment_count: int, commentable: bool, created_at: string, description: string, download_count: int, download_url: string, downloadable: string, duration: int, embeddable_by: string, favoritings_count: int, genre: string, id: int, isrc: string, key_signature: string, kind: string, label_name: string, license: string, permalink_url: string, playback_count: int, purchase_title: string, purchase_url: string, release: string, release_day: int, release_month: int, release_year: int, reposts_count: int, secret_uri: string, sharing: string, stream_url: string, streamable: bool, tag_list: string, title: string, uri: string, user: record<avatar_url: string, created_at: string, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, uri: string, username: string>, user_favorite: bool, user_playback_count: int, waveform_url: string>
export def "get-tracks-track-id" [
  track_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --secret-token: string # A secret token to fetch private playlists/tracks
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tracks/{track_id}"
    path_params: [{name: track_id, var: track_id}]
    query: [{name: secret_token, var: secret_token}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: query-client_id
  } {
    track_id: $track_id, secret_token: $secret_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a track's information.
#
# PUT /tracks/{track_id}
# Returns: record<access: string, artwork_url: string, available_country_codes: string, bpm: int, comment_count: int, commentable: bool, created_at: string, description: string, download_count: int, download_url: string, downloadable: string, duration: int, embeddable_by: string, favoritings_count: int, genre: string, id: int, isrc: string, key_signature: string, kind: string, label_name: string, license: string, permalink_url: string, playback_count: int, purchase_title: string, purchase_url: string, release: string, release_day: int, release_month: int, release_year: int, reposts_count: int, secret_uri: string, sharing: string, stream_url: string, streamable: bool, tag_list: string, title: string, uri: string, user: record<avatar_url: string, created_at: string, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, uri: string, username: string>, user_favorite: bool, user_playback_count: int, waveform_url: string>
export def "put-tracks-track-id" [
  track_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --track: record # shape: {commentable?: bool, description?: string, downloadable?: bool, embeddable_by?: "all"|"me"|"none", genre?: string, isrc?: string, label_name?: string, license?: "no-rights-reserved"|"all-rights-reserved"|"cc-by"|"cc-by-nc"|"cc-by-nd"|"cc-by-sa"|"cc-by-nc-nd"|"cc-by-nc-sa", permalink?: string, purchase_url?: string, release?: string, release_date?: string, sharing?: "public"|"private", streamable?: bool, tag_list?: string, title?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/tracks/{track_id}"
    path_params: [{name: track_id, var: track_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: track, var: track}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    track_id: $track_id, track: $track
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the comments posted on the track(track_id).
#
# GET /tracks/{track_id}/comments
@deprecated --flag offset
export def "get-tracks-track-id-comments" [
  track_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return in the collection. (default: 50, e.g. 2)
  --offset: int # Offset of first result. Deprecated, use `linked_partitioning` instead. (DEPRECATED, default: 0, e.g. 0)
  --linked-partitioning: oneof<nothing, bool> # Returns paginated collection of items (recommended, returning a list without pagination is deprecated and should not be used) (e.g. true)
]: nothing -> any {
  http-request {
    method: get
    path: "/tracks/{track_id}/comments"
    path_params: [{name: track_id, var: track_id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: linked_partitioning, var: linked_partitioning}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: query-client_id
  } {
    track_id: $track_id, limit: $limit, offset: $offset, linked_partitioning: $linked_partitioning
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the newly created comment on success
#
# POST /tracks/{track_id}/comments
# Returns: record<body: string, created_at: string, id: int, kind: string, timestamp: string, track_id: int, uri: string, user: record<avatar_url: string, followers_count: int, followings_count: int, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, reposts_count: int, uri: string, username: string>, user_id: int>
export def "post-tracks-track-id-comments" [
  track_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-authheader: string # Auth token for AuthHeader (Authorization)
  --token-clientid: string # Auth token for ClientId (client_id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: record # shape: {body: string, timestamp?: any}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tracks/{track_id}/comments"
    path_params: [{name: track_id, var: track_id}]
    body: {content_type: "application/json; charset=utf-8", kind: json, fields: [{name: comment, var: comment}]}
    accept: ["application/json; charset=utf-8"]
    ok: [201]
    auth_all: [{scheme: bearer, var: token_authheader, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_AUTHHEADER_TOKEN}, {scheme: query-client_id, var: token_clientid, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_CLIENTID_TOKEN}]
  } {
    track_id: $track_id, comment: $comment
    base_url: $base_url, token_authheader: $token_authheader, token_clientid: $token_clientid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of users who have favorited or liked the track.
#
# GET /tracks/{track_id}/favoriters
# Returns: table<avatar_url: string, city: string, country: string, description: string, discogs_name: string, first_name: string, followers_count: int, followings_count: int, full_name: string, id: int, kind: string, last_modified: string, last_name: string, myspace_name: string, permalink: string, permalink_url: string, plan: string, playlist_count: int, public_favorites_count: int, reposts_count: int, subscriptions: list<list>, track_count: int, uri: string, username: string, website: string, website_title: string>
@deprecated --flag offset
export def "get-tracks-track-id-favoriters" [
  track_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return in the collection. (default: 50, e.g. 2)
  --offset: int # Offset of first result. Deprecated, use `linked_partitioning` instead. (DEPRECATED, default: 0, e.g. 0)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/tracks/{track_id}/favoriters"
    path_params: [{name: track_id, var: track_id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: query-client_id
  } {
    track_id: $track_id, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all related tracks of track on SoundCloud.
#
# GET /tracks/{track_id}/related
@deprecated --flag offset
export def "get-tracks-track-id-related" [
  track_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access: list<string> # Filters content by level of access the user (logged in or anonymous) has to the track. The result list will include only tracks with the specified access. Include all options if you'd like to see all possible tracks. See `Track#access` schema for more details. (default: playable,preview)
  --limit: int # Number of results to return in the collection. (default: 50, e.g. 2)
  --offset: int # Offset of first result. Deprecated, use `linked_partitioning` instead. (DEPRECATED, default: 0, e.g. 0)
  --linked-partitioning: oneof<nothing, bool> # Returns paginated collection of items (recommended, returning a list without pagination is deprecated and should not be used) (e.g. true)
]: nothing -> any {
  http-request {
    method: get
    path: "/tracks/{track_id}/related"
    path_params: [{name: track_id, var: track_id}]
    query: [{name: access, var: access, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}, {name: linked_partitioning, var: linked_partitioning}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: query-client_id
  } {
    track_id: $track_id, access: $access, limit: $limit, offset: $offset, linked_partitioning: $linked_partitioning
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a collection of track's reposters.
#
# GET /tracks/{track_id}/reposters
# Returns: record<collection: table<avatar_url: string, created_at: string, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, uri: string, username: string>, next_href: string>
export def "get-tracks-track-id-reposters" [
  track_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return in the collection. (default: 50, e.g. 2)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tracks/{track_id}/reposters"
    path_params: [{name: track_id, var: track_id}]
    query: [{name: limit, var: limit}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: query-client_id
  } {
    track_id: $track_id, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a track's streamable URLs
#
# GET /tracks/{track_id}/streams
# Returns: record<hls_mp3_128_url: string, hls_opus_64_url: string, http_mp3_128_url: string, preview_mp3_128_url: string>
export def "get-tracks-track-id-streams" [
  track_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --secret-token: string # A secret token to fetch private playlists/tracks
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tracks/{track_id}/streams"
    path_params: [{name: track_id, var: track_id}]
    query: [{name: secret_token, var: secret_token}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: query-client_id
  } {
    track_id: $track_id, secret_token: $secret_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Performs a user search based on a query
#
# GET /users
@deprecated --flag offset
export def "get-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-authheader: string # Auth token for AuthHeader (Authorization)
  --token-clientid: string # Auth token for ClientId (client_id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # search (required, e.g. hello)
  --ids: string # A comma separated list of track ids to filter on (e.g. 1,2,3)
  --limit: int # Number of results to return in the collection. (default: 50, e.g. 2)
  --offset: int # Offset of first result. Deprecated, use `linked_partitioning` instead. (DEPRECATED, default: 0, e.g. 0)
  --linked-partitioning: oneof<nothing, bool> # Returns paginated collection of items (recommended, returning a list without pagination is deprecated and should not be used) (e.g. true)
]: nothing -> any {
  http-request {
    method: get
    path: "/users"
    query: [{name: q, var: q, required: true}, {name: ids, var: ids}, {name: limit, var: limit}, {name: offset, var: offset}, {name: linked_partitioning, var: linked_partitioning}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: bearer, var: token_authheader, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_AUTHHEADER_TOKEN}, {scheme: query-client_id, var: token_clientid, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_CLIENTID_TOKEN}]
  } {
    q: $q, ids: $ids, limit: $limit, offset: $offset, linked_partitioning: $linked_partitioning
    base_url: $base_url, token_authheader: $token_authheader, token_clientid: $token_clientid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a user.
#
# GET /users/{user_id}
# Returns: record<avatar_url: string, city: string, country: string, description: string, discogs_name: string, first_name: string, followers_count: int, followings_count: int, full_name: string, id: int, kind: string, last_modified: string, last_name: string, locale: string, myspace_name: string, permalink: string, permalink_url: string, plan: string, playlist_count: int, primary_email_confirmed: bool, private_playlists_count: int, private_tracks_count: int, public_favorites_count: int, quota: record<unlimited_upload_quota: bool, upload_seconds_used: int>, reposts_count: int, subscriptions: list<list<any>>, track_count: int, uri: string, username: string, website: string, website_title: string>
export def "get-users-user-id" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-authheader: string # Auth token for AuthHeader (Authorization)
  --token-clientid: string # Auth token for ClientId (client_id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}"
    path_params: [{name: user_id, var: user_id}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: bearer, var: token_authheader, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_AUTHHEADER_TOKEN}, {scheme: query-client_id, var: token_clientid, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_CLIENTID_TOKEN}]
  } {
    user_id: $user_id
    base_url: $base_url, token_authheader: $token_authheader, token_clientid: $token_clientid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of user's comments.
#
# GET /users/{user_id}/comments
# Returns: table<body: string, created_at: string, id: int, kind: string, timestamp: string, track_id: int, uri: string, user: record<avatar_url: string, followers_count: int, followings_count: int, id: int, kind: string, last_modified: string, permalink: string, permalink_url: string, reposts_count: int, uri: string, username: string>, user_id: int>
@deprecated --flag offset
export def "get-users-user-id-comments" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-authheader: string # Auth token for AuthHeader (Authorization)
  --token-clientid: string # Auth token for ClientId (client_id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return in the collection. (default: 50, e.g. 2)
  --offset: int # Offset of first result. Deprecated, use `linked_partitioning` instead. (DEPRECATED, default: 0, e.g. 0)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/comments"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: bearer, var: token_authheader, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_AUTHHEADER_TOKEN}, {scheme: query-client_id, var: token_clientid, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_CLIENTID_TOKEN}]
  } {
    user_id: $user_id, limit: $limit, offset: $offset
    base_url: $base_url, token_authheader: $token_authheader, token_clientid: $token_clientid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of user's favorited or liked tracks. (use /users/:userId/likes/tracks instead, to fetch a user's likes)
#
# GET /users/{user_id}/favorites
# DEPRECATED
@deprecated
export def "get-users-user-id-favorites" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-authheader: string # Auth token for AuthHeader (Authorization)
  --token-clientid: string # Auth token for ClientId (client_id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return in the collection. (default: 50, e.g. 2)
  --linked-partitioning: oneof<nothing, bool> # Returns paginated collection of items (recommended, returning a list without pagination is deprecated and should not be used) (e.g. true)
]: nothing -> any {
  http-request {
    method: get
    path: "/users/{user_id}/favorites"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: limit, var: limit}, {name: linked_partitioning, var: linked_partitioning}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: bearer, var: token_authheader, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_AUTHHEADER_TOKEN}, {scheme: query-client_id, var: token_clientid, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_CLIENTID_TOKEN}]
  } {
    user_id: $user_id, limit: $limit, linked_partitioning: $linked_partitioning
    base_url: $base_url, token_authheader: $token_authheader, token_clientid: $token_clientid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of user’s followers.
#
# GET /users/{user_id}/followers
export def "get-users-user-id-followers" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-authheader: string # Auth token for AuthHeader (Authorization)
  --token-clientid: string # Auth token for ClientId (client_id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return in the collection. (default: 50, e.g. 2)
]: nothing -> any {
  http-request {
    method: get
    path: "/users/{user_id}/followers"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: limit, var: limit}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: bearer, var: token_authheader, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_AUTHHEADER_TOKEN}, {scheme: query-client_id, var: token_clientid, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_CLIENTID_TOKEN}]
  } {
    user_id: $user_id, limit: $limit
    base_url: $base_url, token_authheader: $token_authheader, token_clientid: $token_clientid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of user’s followings.
#
# GET /users/{user_id}/followings
export def "get-users-user-id-followings" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-authheader: string # Auth token for AuthHeader (Authorization)
  --token-clientid: string # Auth token for ClientId (client_id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return in the collection. (default: 50, e.g. 2)
]: nothing -> any {
  http-request {
    method: get
    path: "/users/{user_id}/followings"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: limit, var: limit}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: bearer, var: token_authheader, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_AUTHHEADER_TOKEN}, {scheme: query-client_id, var: token_clientid, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_CLIENTID_TOKEN}]
  } {
    user_id: $user_id, limit: $limit
    base_url: $base_url, token_authheader: $token_authheader, token_clientid: $token_clientid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a user's following. (use /users/{user_id} instead, to fetch the user details)
#
# GET /users/{user_id}/followings/{following_id}
# DEPRECATED
# Returns: record<avatar_url: string, city: string, country: string, description: string, discogs_name: string, first_name: string, followers_count: int, followings_count: int, full_name: string, id: int, kind: string, last_modified: string, last_name: string, locale: string, myspace_name: string, permalink: string, permalink_url: string, plan: string, playlist_count: int, primary_email_confirmed: bool, private_playlists_count: int, private_tracks_count: int, public_favorites_count: int, quota: record<unlimited_upload_quota: bool, upload_seconds_used: int>, reposts_count: int, subscriptions: list<list<any>>, track_count: int, uri: string, username: string, website: string, website_title: string>
@deprecated
export def "get-users-user-id-followings-following-id" [
  user_id: int
  following_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-authheader: string # Auth token for AuthHeader (Authorization)
  --token-clientid: string # Auth token for ClientId (client_id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/followings/{following_id}"
    path_params: [{name: user_id, var: user_id}, {name: following_id, var: following_id}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: bearer, var: token_authheader, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_AUTHHEADER_TOKEN}, {scheme: query-client_id, var: token_clientid, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_CLIENTID_TOKEN}]
  } {
    user_id: $user_id, following_id: $following_id
    base_url: $base_url, token_authheader: $token_authheader, token_clientid: $token_clientid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of user's liked tracks.
#
# GET /users/{user_id}/likes/tracks
export def "get-users-user-id-likes-tracks" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-authheader: string # Auth token for AuthHeader (Authorization)
  --token-clientid: string # Auth token for ClientId (client_id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access: list<string> # Filters content by level of access the user (logged in or anonymous) has to the track. The result list will include only tracks with the specified access. Include all options if you'd like to see all possible tracks. See `Track#access` schema for more details. (default: playable,preview)
  --limit: int # Number of results to return in the collection. (default: 50, e.g. 2)
  --linked-partitioning: oneof<nothing, bool> # Returns paginated collection of items (recommended, returning a list without pagination is deprecated and should not be used) (e.g. true)
]: nothing -> any {
  http-request {
    method: get
    path: "/users/{user_id}/likes/tracks"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: access, var: access, style: csv}, {name: limit, var: limit}, {name: linked_partitioning, var: linked_partitioning}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: bearer, var: token_authheader, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_AUTHHEADER_TOKEN}, {scheme: query-client_id, var: token_clientid, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_CLIENTID_TOKEN}]
  } {
    user_id: $user_id, access: $access, limit: $limit, linked_partitioning: $linked_partitioning
    base_url: $base_url, token_authheader: $token_authheader, token_clientid: $token_clientid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of user's playlists.
#
# GET /users/{user_id}/playlists
export def "get-users-user-id-playlists" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-authheader: string # Auth token for AuthHeader (Authorization)
  --token-clientid: string # Auth token for ClientId (client_id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access: list<string> # Filters content by level of access the user (logged in or anonymous) has to the track. The result list will include only tracks with the specified access. Include all options if you'd like to see all possible tracks. See `Track#access` schema for more details. (default: playable,preview)
  --limit: int # Number of results to return in the collection. (default: 50, e.g. 2)
  --linked-partitioning: oneof<nothing, bool> # Returns paginated collection of items (recommended, returning a list without pagination is deprecated and should not be used) (e.g. true)
]: nothing -> any {
  http-request {
    method: get
    path: "/users/{user_id}/playlists"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: access, var: access, style: csv}, {name: limit, var: limit}, {name: linked_partitioning, var: linked_partitioning}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: bearer, var: token_authheader, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_AUTHHEADER_TOKEN}, {scheme: query-client_id, var: token_clientid, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_CLIENTID_TOKEN}]
  } {
    user_id: $user_id, access: $access, limit: $limit, linked_partitioning: $linked_partitioning
    base_url: $base_url, token_authheader: $token_authheader, token_clientid: $token_clientid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of user's tracks.
#
# GET /users/{user_id}/tracks
export def "get-users-user-id-tracks" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-authheader: string # Auth token for AuthHeader (Authorization)
  --token-clientid: string # Auth token for ClientId (client_id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access: list<string> # Filters content by level of access the user (logged in or anonymous) has to the track. The result list will include only tracks with the specified access. Include all options if you'd like to see all possible tracks. See `Track#access` schema for more details. (default: playable,preview)
  --limit: int # Number of results to return in the collection. (default: 50, e.g. 2)
  --linked-partitioning: oneof<nothing, bool> # Returns paginated collection of items (recommended, returning a list without pagination is deprecated and should not be used) (e.g. true)
]: nothing -> any {
  http-request {
    method: get
    path: "/users/{user_id}/tracks"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: access, var: access, style: csv}, {name: limit, var: limit}, {name: linked_partitioning, var: linked_partitioning}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: bearer, var: token_authheader, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_AUTHHEADER_TOKEN}, {scheme: query-client_id, var: token_clientid, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_CLIENTID_TOKEN}]
  } {
    user_id: $user_id, access: $access, limit: $limit, linked_partitioning: $linked_partitioning
    base_url: $base_url, token_authheader: $token_authheader, token_clientid: $token_clientid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of user's links added to their profile (website, facebook, instagram).
#
# GET /users/{user_id}/web-profiles
# Returns: table<created_at: string, id: int, kind: string, service: string, title: string, url: string, username: string>
export def "get-users-user-id-web-profiles" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-authheader: string # Auth token for AuthHeader (Authorization)
  --token-clientid: string # Auth token for ClientId (client_id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return in the collection. (default: 50, e.g. 2)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/web-profiles"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: limit, var: limit}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth_all: [{scheme: bearer, var: token_authheader, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_AUTHHEADER_TOKEN}, {scheme: query-client_id, var: token_clientid, env: SOUNDCLOUD_PUBLIC_API_SPECIFICATION_CLIENTID_TOKEN}]
  } {
    user_id: $user_id, limit: $limit
    base_url: $base_url, token_authheader: $token_authheader, token_clientid: $token_clientid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
