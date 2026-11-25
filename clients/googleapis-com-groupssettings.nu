# Auto-generated client for Groups Settings API v1
# Source: https://api.apis.guru/v2/specs/googleapis.com/groupssettings/v1/openapi.json
# Auth: --token flag or $env.GROUPS_SETTINGS_API_TOKEN

const CLIENT = {
  base_url: "https://www.googleapis.com/groups/v1/groups"
  token_env_var: "GROUPS_SETTINGS_API_TOKEN"
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

def base-url-completer [] { ["https://www.googleapis.com/groups/v1/groups"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def alt-completer [] { ["atom" "json"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    groups-settings-groups-get: "record<allowExternalMembers: string, allowGoogleCommunication: string, allowWebPosting: string, archiveOnly: string, customFooterText: string, customReplyTo: string, customRolesEnabledForSettingsToBeMerged: string, defaultMessageDenyNotificationText: string, default_sender: string, description: string, email: string, enableCollaborativeInbox: string, favoriteRepliesOnTop: string, includeCustomFooter: string, includeInGlobalAddressList: string, isArchived: string, kind: string, maxMessageBytes: int, membersCanPostAsTheGroup: string, messageDisplayFont: string, messageModerationLevel: string, name: string, primaryLanguage: string, replyTo: string, sendMessageDenyNotification: string, showInGroupDirectory: string, spamModerationLevel: string, whoCanAdd: string, whoCanAddReferences: string, whoCanApproveMembers: string, whoCanApproveMessages: string, whoCanAssignTopics: string, whoCanAssistContent: string, whoCanBanUsers: string, whoCanContactOwner: string, whoCanDeleteAnyPost: string, whoCanDeleteTopics: string, whoCanDiscoverGroup: string, whoCanEnterFreeFormTags: string, whoCanHideAbuse: string, whoCanInvite: string, whoCanJoin: string, whoCanLeaveGroup: string, whoCanLockTopics: string, whoCanMakeTopicsSticky: string, whoCanMarkDuplicate: string, whoCanMarkFavoriteReplyOnAnyTopic: string, whoCanMarkFavoriteReplyOnOwnTopic: string, whoCanMarkNoResponseNeeded: string, whoCanModerateContent: string, whoCanModerateMembers: string, whoCanModifyMembers: string, whoCanModifyTagsAndCategories: string, whoCanMoveTopicsIn: string, whoCanMoveTopicsOut: string, whoCanPostAnnouncements: string, whoCanPostMessage: string, whoCanTakeTopics: string, whoCanUnassignTopic: string, whoCanUnmarkFavoriteReplyOnAnyTopic: string, whoCanViewGroup: string, whoCanViewMembership: string>"
    groups-settings-groups-patch: "record<allowExternalMembers: string, allowGoogleCommunication: string, allowWebPosting: string, archiveOnly: string, customFooterText: string, customReplyTo: string, customRolesEnabledForSettingsToBeMerged: string, defaultMessageDenyNotificationText: string, default_sender: string, description: string, email: string, enableCollaborativeInbox: string, favoriteRepliesOnTop: string, includeCustomFooter: string, includeInGlobalAddressList: string, isArchived: string, kind: string, maxMessageBytes: int, membersCanPostAsTheGroup: string, messageDisplayFont: string, messageModerationLevel: string, name: string, primaryLanguage: string, replyTo: string, sendMessageDenyNotification: string, showInGroupDirectory: string, spamModerationLevel: string, whoCanAdd: string, whoCanAddReferences: string, whoCanApproveMembers: string, whoCanApproveMessages: string, whoCanAssignTopics: string, whoCanAssistContent: string, whoCanBanUsers: string, whoCanContactOwner: string, whoCanDeleteAnyPost: string, whoCanDeleteTopics: string, whoCanDiscoverGroup: string, whoCanEnterFreeFormTags: string, whoCanHideAbuse: string, whoCanInvite: string, whoCanJoin: string, whoCanLeaveGroup: string, whoCanLockTopics: string, whoCanMakeTopicsSticky: string, whoCanMarkDuplicate: string, whoCanMarkFavoriteReplyOnAnyTopic: string, whoCanMarkFavoriteReplyOnOwnTopic: string, whoCanMarkNoResponseNeeded: string, whoCanModerateContent: string, whoCanModerateMembers: string, whoCanModifyMembers: string, whoCanModifyTagsAndCategories: string, whoCanMoveTopicsIn: string, whoCanMoveTopicsOut: string, whoCanPostAnnouncements: string, whoCanPostMessage: string, whoCanTakeTopics: string, whoCanUnassignTopic: string, whoCanUnmarkFavoriteReplyOnAnyTopic: string, whoCanViewGroup: string, whoCanViewMembership: string>"
    groups-settings-groups-update: "record<allowExternalMembers: string, allowGoogleCommunication: string, allowWebPosting: string, archiveOnly: string, customFooterText: string, customReplyTo: string, customRolesEnabledForSettingsToBeMerged: string, defaultMessageDenyNotificationText: string, default_sender: string, description: string, email: string, enableCollaborativeInbox: string, favoriteRepliesOnTop: string, includeCustomFooter: string, includeInGlobalAddressList: string, isArchived: string, kind: string, maxMessageBytes: int, membersCanPostAsTheGroup: string, messageDisplayFont: string, messageModerationLevel: string, name: string, primaryLanguage: string, replyTo: string, sendMessageDenyNotification: string, showInGroupDirectory: string, spamModerationLevel: string, whoCanAdd: string, whoCanAddReferences: string, whoCanApproveMembers: string, whoCanApproveMessages: string, whoCanAssignTopics: string, whoCanAssistContent: string, whoCanBanUsers: string, whoCanContactOwner: string, whoCanDeleteAnyPost: string, whoCanDeleteTopics: string, whoCanDiscoverGroup: string, whoCanEnterFreeFormTags: string, whoCanHideAbuse: string, whoCanInvite: string, whoCanJoin: string, whoCanLeaveGroup: string, whoCanLockTopics: string, whoCanMakeTopicsSticky: string, whoCanMarkDuplicate: string, whoCanMarkFavoriteReplyOnAnyTopic: string, whoCanMarkFavoriteReplyOnOwnTopic: string, whoCanMarkNoResponseNeeded: string, whoCanModerateContent: string, whoCanModerateMembers: string, whoCanModifyMembers: string, whoCanModifyTagsAndCategories: string, whoCanMoveTopicsIn: string, whoCanMoveTopicsOut: string, whoCanPostAnnouncements: string, whoCanPostMessage: string, whoCanTakeTopics: string, whoCanUnassignTopic: string, whoCanUnmarkFavoriteReplyOnAnyTopic: string, whoCanViewGroup: string, whoCanViewMembership: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["groups-settings-groups-get" "groups-settings-groups-patch" "groups-settings-groups-update" "commands"] | sort) } | get name | first)
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

# Gets one resource by id.
#
# GET /{groupUniqueId}
# Returns: record<allowExternalMembers: string, allowGoogleCommunication: string, allowWebPosting: string, archiveOnly: string, customFooterText: string, customReplyTo: string, customRolesEnabledForSettingsToBeMerged: string, defaultMessageDenyNotificationText: string, default_sender: string, description: string, email: string, enableCollaborativeInbox: string, favoriteRepliesOnTop: string, includeCustomFooter: string, includeInGlobalAddressList: string, isArchived: string, kind: string, maxMessageBytes: int, membersCanPostAsTheGroup: string, messageDisplayFont: string, messageModerationLevel: string, name: string, primaryLanguage: string, replyTo: string, sendMessageDenyNotification: string, showInGroupDirectory: string, spamModerationLevel: string, whoCanAdd: string, whoCanAddReferences: string, whoCanApproveMembers: string, whoCanApproveMessages: string, whoCanAssignTopics: string, whoCanAssistContent: string, whoCanBanUsers: string, whoCanContactOwner: string, whoCanDeleteAnyPost: string, whoCanDeleteTopics: string, whoCanDiscoverGroup: string, whoCanEnterFreeFormTags: string, whoCanHideAbuse: string, whoCanInvite: string, whoCanJoin: string, whoCanLeaveGroup: string, whoCanLockTopics: string, whoCanMakeTopicsSticky: string, whoCanMarkDuplicate: string, whoCanMarkFavoriteReplyOnAnyTopic: string, whoCanMarkFavoriteReplyOnOwnTopic: string, whoCanMarkNoResponseNeeded: string, whoCanModerateContent: string, whoCanModerateMembers: string, whoCanModifyMembers: string, whoCanModifyTagsAndCategories: string, whoCanMoveTopicsIn: string, whoCanMoveTopicsOut: string, whoCanPostAnnouncements: string, whoCanPostMessage: string, whoCanTakeTopics: string, whoCanUnassignTopic: string, whoCanUnmarkFavoriteReplyOnAnyTopic: string, whoCanViewGroup: string, whoCanViewMembership: string>
# operationId: groupsSettings.groups.get
export def "groups-settings-groups-get" [
  group_unique_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{groupUniqueId}"
    path_params: [{name: groupUniqueId, var: group_unique_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_unique_id: $group_unique_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing resource. This method supports patch semantics.
#
# PATCH /{groupUniqueId}
# Returns: record<allowExternalMembers: string, allowGoogleCommunication: string, allowWebPosting: string, archiveOnly: string, customFooterText: string, customReplyTo: string, customRolesEnabledForSettingsToBeMerged: string, defaultMessageDenyNotificationText: string, default_sender: string, description: string, email: string, enableCollaborativeInbox: string, favoriteRepliesOnTop: string, includeCustomFooter: string, includeInGlobalAddressList: string, isArchived: string, kind: string, maxMessageBytes: int, membersCanPostAsTheGroup: string, messageDisplayFont: string, messageModerationLevel: string, name: string, primaryLanguage: string, replyTo: string, sendMessageDenyNotification: string, showInGroupDirectory: string, spamModerationLevel: string, whoCanAdd: string, whoCanAddReferences: string, whoCanApproveMembers: string, whoCanApproveMessages: string, whoCanAssignTopics: string, whoCanAssistContent: string, whoCanBanUsers: string, whoCanContactOwner: string, whoCanDeleteAnyPost: string, whoCanDeleteTopics: string, whoCanDiscoverGroup: string, whoCanEnterFreeFormTags: string, whoCanHideAbuse: string, whoCanInvite: string, whoCanJoin: string, whoCanLeaveGroup: string, whoCanLockTopics: string, whoCanMakeTopicsSticky: string, whoCanMarkDuplicate: string, whoCanMarkFavoriteReplyOnAnyTopic: string, whoCanMarkFavoriteReplyOnOwnTopic: string, whoCanMarkNoResponseNeeded: string, whoCanModerateContent: string, whoCanModerateMembers: string, whoCanModifyMembers: string, whoCanModifyTagsAndCategories: string, whoCanMoveTopicsIn: string, whoCanMoveTopicsOut: string, whoCanPostAnnouncements: string, whoCanPostMessage: string, whoCanTakeTopics: string, whoCanUnassignTopic: string, whoCanUnmarkFavoriteReplyOnAnyTopic: string, whoCanViewGroup: string, whoCanViewMembership: string>
# operationId: groupsSettings.groups.patch
export def "groups-settings-groups-patch" [
  group_unique_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --allow-external-members: string # Identifies whether members external to your organization can join the group. Possible values are: - true: G Suite users external to your organization can become members of this group. - false: Users not belonging to the organization are not allowed to become members of this group.
  --allow-google-communication: string # Deprecated. Allows Google to contact administrator of the group. - true: Allow Google to contact managers of this group. Occasionally Google may send updates on the latest features, ask for input on new features, or ask for permission to highlight your group. - false: Google can not contact managers of this group.
  --allow-web-posting: string # Allows posting from web. Possible values are: - true: Allows any member to post to the group forum. - false: Members only use Gmail to communicate with the group.
  --archive-only: string # Allows the group to be archived only. Possible values are: - true: Group is archived and the group is inactive. New messages to this group are rejected. The older archived messages are browseable and searchable. - If true, the whoCanPostMessage property is set to NONE_CAN_POST. - If reverted from true to false, whoCanPostMessages is set to ALL_MANAGERS_CAN_POST. - false: The group is active and can receive messages. - When false, updating whoCanPostMessage to NONE_CAN_POST, results in an error.
  --custom-footer-text: string # Set the content of custom footer text. The maximum number of characters is 1,000.
  --custom-reply-to: string # An email address used when replying to a message if the replyTo property is set to REPLY_TO_CUSTOM. This address is defined by an account administrator. - When the group's ReplyTo property is set to REPLY_TO_CUSTOM, the customReplyTo property holds a custom email address used when replying to a message. - If the group's ReplyTo property is set to REPLY_TO_CUSTOM, the customReplyTo property must have a text value or an error is returned.
  --custom-roles-enabled-for-settings-to-be-merged: string # Specifies whether the group has a custom role that's included in one of the settings being merged. This field is read-only and update/patch requests to it are ignored. Possible values are: - true - false
  --default-message-deny-notification-text: string # When a message is rejected, this is text for the rejection notification sent to the message's author. By default, this property is empty and has no value in the API's response body. The maximum notification text size is 10,000 characters. Note: Requires sendMessageDenyNotification property to be true.
  --default-sender: string # Default sender for members who can post messages as the group. Possible values are: - `DEFAULT_SELF`: By default messages will be sent from the user - `GROUP`: By default messages will be sent from the group
  --description: string # Description of the group. This property value may be an empty string if no group description has been entered. If entered, the maximum group description is no more than 300 characters.
  --email: string # The group's email address. This property can be updated using the Directory API. Note: Only a group owner can change a group's email address. A group manager can't do this. When you change your group's address using the Directory API or the control panel, you are changing the address your subscribers use to send email and the web address people use to access your group. People can't reach your group by visiting the old address.
  --enable-collaborative-inbox: string # Specifies whether a collaborative inbox will remain turned on for the group. Possible values are: - true - false
  --favorite-replies-on-top: string # Indicates if favorite replies should be displayed above other replies. - true: Favorite replies will be displayed above other replies. - false: Favorite replies will not be displayed above other replies.
  --include-custom-footer: string # Whether to include custom footer. Possible values are: - true - false
  --include-in-global-address-list: string # Enables the group to be included in the Global Address List. For more information, see the help center. Possible values are: - true: Group is included in the Global Address List. - false: Group is not included in the Global Address List.
  --is-archived: string # Allows the Group contents to be archived. Possible values are: - true: Archive messages sent to the group. - false: Do not keep an archive of messages sent to this group. If false, previously archived messages remain in the archive.
  --kind: string # The type of the resource. It is always groupsSettings#groups. (default: groupsSettings#groups)
  --max-message-bytes: int # Deprecated. The maximum size of a message is 25Mb. (format: int32)
  --members-can-post-as-the-group: string # Enables members to post messages as the group. Possible values are: - true: Group member can post messages using the group's email address instead of their own email address. Message appear to originate from the group itself. Note: When true, any message moderation settings on individual users or new members do not apply to posts made on behalf of the group. - false: Members can not post in behalf of the group's email address.
  --message-display-font: string # Deprecated. The default message display font always has a value of "DEFAULT_FONT".
  --message-moderation-level: string # Moderation level of incoming messages. Possible values are: - MODERATE_ALL_MESSAGES: All messages are sent to the group owner's email address for approval. If approved, the message is sent to the group. - MODERATE_NON_MEMBERS: All messages from non group members are sent to the group owner's email address for approval. If approved, the message is sent to the group. - MODERATE_NEW_MEMBERS: All messages from new members are sent to the group owner's email address for approval. If approved, the message is sent to the group. - MODERATE_NONE: No moderator approval is required. Messages are delivered directly to the group. Note: When the whoCanPostMessage is set to ANYONE_CAN_POST, we recommend the messageModerationLevel be set to MODERATE_NON_MEMBERS to protect the group from possible spam. When memberCanPostAsTheGroup is true, any message moderation settings on individual users or new members will not apply to posts made on behalf of the group.
  --name: string # Name of the group, which has a maximum size of 75 characters.
  --primary-language: string # The primary language for group. For a group's primary language use the language tags from the G Suite languages found at G Suite Email Settings API Email Language Tags.
  --reply-to: string # Specifies who receives the default reply. Possible values are: - REPLY_TO_CUSTOM: For replies to messages, use the group's custom email address. When the group's ReplyTo property is set to REPLY_TO_CUSTOM, the customReplyTo property holds the custom email address used when replying to a message. If the group's ReplyTo property is set to REPLY_TO_CUSTOM, the customReplyTo property must have a value. Otherwise an error is returned. - REPLY_TO_SENDER: The reply sent to author of message. - REPLY_TO_LIST: This reply message is sent to the group. - REPLY_TO_OWNER: The reply is sent to the owner(s) of the group. This does not include the group's managers. - REPLY_TO_IGNORE: Group users individually decide where the message reply is sent. - REPLY_TO_MANAGERS: This reply message is sent to the group's managers, which includes all managers and the group owner.
  --send-message-deny-notification: string # Allows a member to be notified if the member's message to the group is denied by the group owner. Possible values are: - true: When a message is rejected, send the deny message notification to the message author. The defaultMessageDenyNotificationText property is dependent on the sendMessageDenyNotification property being true. - false: When a message is rejected, no notification is sent.
  --show-in-group-directory: string # Deprecated. This is merged into the new whoCanDiscoverGroup setting. Allows the group to be visible in the Groups Directory. Possible values are: - true: All groups in the account are listed in the Groups directory. - false: All groups in the account are not listed in the directory.
  --spam-moderation-level: string # Specifies moderation levels for messages detected as spam. Possible values are: - ALLOW: Post the message to the group. - MODERATE: Send the message to the moderation queue. This is the default. - SILENTLY_MODERATE: Send the message to the moderation queue, but do not send notification to moderators. - REJECT: Immediately reject the message.
  --who-can-add: string # Deprecated. This is merged into the new whoCanModerateMembers setting. Permissions to add members. Possible values are: - ALL_MEMBERS_CAN_ADD: Managers and members can directly add new members. - ALL_MANAGERS_CAN_ADD: Only managers can directly add new members. this includes the group's owner. - ALL_OWNERS_CAN_ADD: Only owners can directly add new members. - NONE_CAN_ADD: No one can directly add new members.
  --who-can-add-references: string # Deprecated. This functionality is no longer supported in the Google Groups UI. The value is always "NONE".
  --who-can-approve-members: string # Specifies who can approve members who ask to join groups. This permission will be deprecated once it is merged into the new whoCanModerateMembers setting. Possible values are: - ALL_MEMBERS_CAN_APPROVE - ALL_MANAGERS_CAN_APPROVE - ALL_OWNERS_CAN_APPROVE - NONE_CAN_APPROVE
  --who-can-approve-messages: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can approve pending messages in the moderation queue. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - OWNERS_ONLY - NONE
  --who-can-assign-topics: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to assign topics in a forum to another user. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - MANAGERS_ONLY - OWNERS_ONLY - NONE
  --who-can-assist-content: string # Specifies who can moderate metadata. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - MANAGERS_ONLY - OWNERS_ONLY - NONE
  --who-can-ban-users: string # Specifies who can deny membership to users. This permission will be deprecated once it is merged into the new whoCanModerateMembers setting. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - OWNERS_ONLY - NONE
  --who-can-contact-owner: string # Permission to contact owner of the group via web UI. Possible values are: - ALL_IN_DOMAIN_CAN_CONTACT - ALL_MANAGERS_CAN_CONTACT - ALL_MEMBERS_CAN_CONTACT - ANYONE_CAN_CONTACT - ALL_OWNERS_CAN_CONTACT
  --who-can-delete-any-post: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can delete replies to topics. (Authors can always delete their own posts). Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - OWNERS_ONLY - NONE
  --who-can-delete-topics: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can delete topics. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - OWNERS_ONLY - NONE
  --who-can-discover-group: string # Specifies the set of users for whom this group is discoverable. Possible values are: - ANYONE_CAN_DISCOVER - ALL_IN_DOMAIN_CAN_DISCOVER - ALL_MEMBERS_CAN_DISCOVER
  --who-can-enter-free-form-tags: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to enter free form tags for topics in a forum. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - MANAGERS_ONLY - OWNERS_ONLY - NONE
  --who-can-hide-abuse: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can hide posts by reporting them as abuse. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - OWNERS_ONLY - NONE
  --who-can-invite: string # Deprecated. This is merged into the new whoCanModerateMembers setting. Permissions to invite new members. Possible values are: - ALL_MEMBERS_CAN_INVITE: Managers and members can invite a new member candidate. - ALL_MANAGERS_CAN_INVITE: Only managers can invite a new member. This includes the group's owner. - ALL_OWNERS_CAN_INVITE: Only owners can invite a new member. - NONE_CAN_INVITE: No one can invite a new member candidate.
  --who-can-join: string # Permission to join group. Possible values are: - ANYONE_CAN_JOIN: Anyone in the account domain can join. This includes accounts with multiple domains. - ALL_IN_DOMAIN_CAN_JOIN: Any Internet user who is outside your domain can access your Google Groups service and view the list of groups in your Groups directory. Warning: Group owners can add external addresses, outside of the domain to their groups. They can also allow people outside your domain to join their groups. If you later disable this option, any external addresses already added to users' groups remain in those groups. - INVITED_CAN_JOIN: Candidates for membership can be invited to join. - CAN_REQUEST_TO_JOIN: Non members can request an invitation to join.
  --who-can-leave-group: string # Permission to leave the group. Possible values are: - ALL_MANAGERS_CAN_LEAVE - ALL_MEMBERS_CAN_LEAVE - NONE_CAN_LEAVE
  --who-can-lock-topics: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can prevent users from posting replies to topics. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - OWNERS_ONLY - NONE
  --who-can-make-topics-sticky: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can make topics appear at the top of the topic list. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - OWNERS_ONLY - NONE
  --who-can-mark-duplicate: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to mark a topic as a duplicate of another topic. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - MANAGERS_ONLY - OWNERS_ONLY - NONE
  --who-can-mark-favorite-reply-on-any-topic: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to mark any other user's post as a favorite reply. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - MANAGERS_ONLY - OWNERS_ONLY - NONE
  --who-can-mark-favorite-reply-on-own-topic: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to mark a post for a topic they started as a favorite reply. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - MANAGERS_ONLY - OWNERS_ONLY - NONE
  --who-can-mark-no-response-needed: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to mark a topic as not needing a response. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - MANAGERS_ONLY - OWNERS_ONLY - NONE
  --who-can-moderate-content: string # Specifies who can moderate content. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - OWNERS_ONLY - NONE
  --who-can-moderate-members: string # Specifies who can manage members. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - OWNERS_ONLY - NONE
  --who-can-modify-members: string # Deprecated. This is merged into the new whoCanModerateMembers setting. Specifies who can change group members' roles. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - OWNERS_ONLY - NONE
  --who-can-modify-tags-and-categories: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to change tags and categories. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - MANAGERS_ONLY - OWNERS_ONLY - NONE
  --who-can-move-topics-in: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can move topics into the group or forum. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - OWNERS_ONLY - NONE
  --who-can-move-topics-out: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can move topics out of the group or forum. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - OWNERS_ONLY - NONE
  --who-can-post-announcements: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can post announcements, a special topic type. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - OWNERS_ONLY - NONE
  --who-can-post-message: string # Permissions to post messages. Possible values are: - NONE_CAN_POST: The group is disabled and archived. No one can post a message to this group. - When archiveOnly is false, updating whoCanPostMessage to NONE_CAN_POST, results in an error. - If archiveOnly is reverted from true to false, whoCanPostMessages is set to ALL_MANAGERS_CAN_POST. - ALL_MANAGERS_CAN_POST: Managers, including group owners, can post messages. - ALL_MEMBERS_CAN_POST: Any group member can post a message. - ALL_OWNERS_CAN_POST: Only group owners can post a message. - ALL_IN_DOMAIN_CAN_POST: Anyone in the account can post a message. - ANYONE_CAN_POST: Any Internet user who outside your account can access your Google Groups service and post a message. Note: When whoCanPostMessage is set to ANYONE_CAN_POST, we recommend the messageModerationLevel be set to MODERATE_NON_MEMBERS to protect the group from possible spam.
  --who-can-take-topics: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to take topics in a forum. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - MANAGERS_ONLY - OWNERS_ONLY - NONE
  --who-can-unassign-topic: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to unassign any topic in a forum. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - MANAGERS_ONLY - OWNERS_ONLY - NONE
  --who-can-unmark-favorite-reply-on-any-topic: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to unmark any post from a favorite reply. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - MANAGERS_ONLY - OWNERS_ONLY - NONE
  --who-can-view-group: string # Permissions to view group messages. Possible values are: - ANYONE_CAN_VIEW: Any Internet user can view the group's messages. - ALL_IN_DOMAIN_CAN_VIEW: Anyone in your account can view this group's messages. - ALL_MEMBERS_CAN_VIEW: All group members can view the group's messages. - ALL_MANAGERS_CAN_VIEW: Any group manager can view this group's messages.
  --who-can-view-membership: string # Permissions to view membership. Possible values are: - ALL_IN_DOMAIN_CAN_VIEW: Anyone in the account can view the group members list. If a group already has external members, those members can still send email to this group. - ALL_MEMBERS_CAN_VIEW: The group members can view the group members list. - ALL_MANAGERS_CAN_VIEW: The group managers can view group members list.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/{groupUniqueId}"
    path_params: [{name: groupUniqueId, var: group_unique_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: allowExternalMembers, var: allow_external_members}, {name: allowGoogleCommunication, var: allow_google_communication}, {name: allowWebPosting, var: allow_web_posting}, {name: archiveOnly, var: archive_only}, {name: customFooterText, var: custom_footer_text}, {name: customReplyTo, var: custom_reply_to}, {name: customRolesEnabledForSettingsToBeMerged, var: custom_roles_enabled_for_settings_to_be_merged}, {name: defaultMessageDenyNotificationText, var: default_message_deny_notification_text}, {name: default_sender, var: default_sender}, {name: description, var: description}, {name: email, var: email}, {name: enableCollaborativeInbox, var: enable_collaborative_inbox}, {name: favoriteRepliesOnTop, var: favorite_replies_on_top}, {name: includeCustomFooter, var: include_custom_footer}, {name: includeInGlobalAddressList, var: include_in_global_address_list}, {name: isArchived, var: is_archived}, {name: kind, var: kind}, {name: maxMessageBytes, var: max_message_bytes}, {name: membersCanPostAsTheGroup, var: members_can_post_as_the_group}, {name: messageDisplayFont, var: message_display_font}, {name: messageModerationLevel, var: message_moderation_level}, {name: name, var: name}, {name: primaryLanguage, var: primary_language}, {name: replyTo, var: reply_to}, {name: sendMessageDenyNotification, var: send_message_deny_notification}, {name: showInGroupDirectory, var: show_in_group_directory}, {name: spamModerationLevel, var: spam_moderation_level}, {name: whoCanAdd, var: who_can_add}, {name: whoCanAddReferences, var: who_can_add_references}, {name: whoCanApproveMembers, var: who_can_approve_members}, {name: whoCanApproveMessages, var: who_can_approve_messages}, {name: whoCanAssignTopics, var: who_can_assign_topics}, {name: whoCanAssistContent, var: who_can_assist_content}, {name: whoCanBanUsers, var: who_can_ban_users}, {name: whoCanContactOwner, var: who_can_contact_owner}, {name: whoCanDeleteAnyPost, var: who_can_delete_any_post}, {name: whoCanDeleteTopics, var: who_can_delete_topics}, {name: whoCanDiscoverGroup, var: who_can_discover_group}, {name: whoCanEnterFreeFormTags, var: who_can_enter_free_form_tags}, {name: whoCanHideAbuse, var: who_can_hide_abuse}, {name: whoCanInvite, var: who_can_invite}, {name: whoCanJoin, var: who_can_join}, {name: whoCanLeaveGroup, var: who_can_leave_group}, {name: whoCanLockTopics, var: who_can_lock_topics}, {name: whoCanMakeTopicsSticky, var: who_can_make_topics_sticky}, {name: whoCanMarkDuplicate, var: who_can_mark_duplicate}, {name: whoCanMarkFavoriteReplyOnAnyTopic, var: who_can_mark_favorite_reply_on_any_topic}, {name: whoCanMarkFavoriteReplyOnOwnTopic, var: who_can_mark_favorite_reply_on_own_topic}, {name: whoCanMarkNoResponseNeeded, var: who_can_mark_no_response_needed}, {name: whoCanModerateContent, var: who_can_moderate_content}, {name: whoCanModerateMembers, var: who_can_moderate_members}, {name: whoCanModifyMembers, var: who_can_modify_members}, {name: whoCanModifyTagsAndCategories, var: who_can_modify_tags_and_categories}, {name: whoCanMoveTopicsIn, var: who_can_move_topics_in}, {name: whoCanMoveTopicsOut, var: who_can_move_topics_out}, {name: whoCanPostAnnouncements, var: who_can_post_announcements}, {name: whoCanPostMessage, var: who_can_post_message}, {name: whoCanTakeTopics, var: who_can_take_topics}, {name: whoCanUnassignTopic, var: who_can_unassign_topic}, {name: whoCanUnmarkFavoriteReplyOnAnyTopic, var: who_can_unmark_favorite_reply_on_any_topic}, {name: whoCanViewGroup, var: who_can_view_group}, {name: whoCanViewMembership, var: who_can_view_membership}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_unique_id: $group_unique_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, allow_external_members: $allow_external_members, allow_google_communication: $allow_google_communication, allow_web_posting: $allow_web_posting, archive_only: $archive_only, custom_footer_text: $custom_footer_text, custom_reply_to: $custom_reply_to, custom_roles_enabled_for_settings_to_be_merged: $custom_roles_enabled_for_settings_to_be_merged, default_message_deny_notification_text: $default_message_deny_notification_text, default_sender: $default_sender, description: $description, email: $email, enable_collaborative_inbox: $enable_collaborative_inbox, favorite_replies_on_top: $favorite_replies_on_top, include_custom_footer: $include_custom_footer, include_in_global_address_list: $include_in_global_address_list, is_archived: $is_archived, kind: $kind, max_message_bytes: $max_message_bytes, members_can_post_as_the_group: $members_can_post_as_the_group, message_display_font: $message_display_font, message_moderation_level: $message_moderation_level, name: $name, primary_language: $primary_language, reply_to: $reply_to, send_message_deny_notification: $send_message_deny_notification, show_in_group_directory: $show_in_group_directory, spam_moderation_level: $spam_moderation_level, who_can_add: $who_can_add, who_can_add_references: $who_can_add_references, who_can_approve_members: $who_can_approve_members, who_can_approve_messages: $who_can_approve_messages, who_can_assign_topics: $who_can_assign_topics, who_can_assist_content: $who_can_assist_content, who_can_ban_users: $who_can_ban_users, who_can_contact_owner: $who_can_contact_owner, who_can_delete_any_post: $who_can_delete_any_post, who_can_delete_topics: $who_can_delete_topics, who_can_discover_group: $who_can_discover_group, who_can_enter_free_form_tags: $who_can_enter_free_form_tags, who_can_hide_abuse: $who_can_hide_abuse, who_can_invite: $who_can_invite, who_can_join: $who_can_join, who_can_leave_group: $who_can_leave_group, who_can_lock_topics: $who_can_lock_topics, who_can_make_topics_sticky: $who_can_make_topics_sticky, who_can_mark_duplicate: $who_can_mark_duplicate, who_can_mark_favorite_reply_on_any_topic: $who_can_mark_favorite_reply_on_any_topic, who_can_mark_favorite_reply_on_own_topic: $who_can_mark_favorite_reply_on_own_topic, who_can_mark_no_response_needed: $who_can_mark_no_response_needed, who_can_moderate_content: $who_can_moderate_content, who_can_moderate_members: $who_can_moderate_members, who_can_modify_members: $who_can_modify_members, who_can_modify_tags_and_categories: $who_can_modify_tags_and_categories, who_can_move_topics_in: $who_can_move_topics_in, who_can_move_topics_out: $who_can_move_topics_out, who_can_post_announcements: $who_can_post_announcements, who_can_post_message: $who_can_post_message, who_can_take_topics: $who_can_take_topics, who_can_unassign_topic: $who_can_unassign_topic, who_can_unmark_favorite_reply_on_any_topic: $who_can_unmark_favorite_reply_on_any_topic, who_can_view_group: $who_can_view_group, who_can_view_membership: $who_can_view_membership
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing resource.
#
# PUT /{groupUniqueId}
# Returns: record<allowExternalMembers: string, allowGoogleCommunication: string, allowWebPosting: string, archiveOnly: string, customFooterText: string, customReplyTo: string, customRolesEnabledForSettingsToBeMerged: string, defaultMessageDenyNotificationText: string, default_sender: string, description: string, email: string, enableCollaborativeInbox: string, favoriteRepliesOnTop: string, includeCustomFooter: string, includeInGlobalAddressList: string, isArchived: string, kind: string, maxMessageBytes: int, membersCanPostAsTheGroup: string, messageDisplayFont: string, messageModerationLevel: string, name: string, primaryLanguage: string, replyTo: string, sendMessageDenyNotification: string, showInGroupDirectory: string, spamModerationLevel: string, whoCanAdd: string, whoCanAddReferences: string, whoCanApproveMembers: string, whoCanApproveMessages: string, whoCanAssignTopics: string, whoCanAssistContent: string, whoCanBanUsers: string, whoCanContactOwner: string, whoCanDeleteAnyPost: string, whoCanDeleteTopics: string, whoCanDiscoverGroup: string, whoCanEnterFreeFormTags: string, whoCanHideAbuse: string, whoCanInvite: string, whoCanJoin: string, whoCanLeaveGroup: string, whoCanLockTopics: string, whoCanMakeTopicsSticky: string, whoCanMarkDuplicate: string, whoCanMarkFavoriteReplyOnAnyTopic: string, whoCanMarkFavoriteReplyOnOwnTopic: string, whoCanMarkNoResponseNeeded: string, whoCanModerateContent: string, whoCanModerateMembers: string, whoCanModifyMembers: string, whoCanModifyTagsAndCategories: string, whoCanMoveTopicsIn: string, whoCanMoveTopicsOut: string, whoCanPostAnnouncements: string, whoCanPostMessage: string, whoCanTakeTopics: string, whoCanUnassignTopic: string, whoCanUnmarkFavoriteReplyOnAnyTopic: string, whoCanViewGroup: string, whoCanViewMembership: string>
# operationId: groupsSettings.groups.update
export def "groups-settings-groups-update" [
  group_unique_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --allow-external-members: string # Identifies whether members external to your organization can join the group. Possible values are: - true: G Suite users external to your organization can become members of this group. - false: Users not belonging to the organization are not allowed to become members of this group.
  --allow-google-communication: string # Deprecated. Allows Google to contact administrator of the group. - true: Allow Google to contact managers of this group. Occasionally Google may send updates on the latest features, ask for input on new features, or ask for permission to highlight your group. - false: Google can not contact managers of this group.
  --allow-web-posting: string # Allows posting from web. Possible values are: - true: Allows any member to post to the group forum. - false: Members only use Gmail to communicate with the group.
  --archive-only: string # Allows the group to be archived only. Possible values are: - true: Group is archived and the group is inactive. New messages to this group are rejected. The older archived messages are browseable and searchable. - If true, the whoCanPostMessage property is set to NONE_CAN_POST. - If reverted from true to false, whoCanPostMessages is set to ALL_MANAGERS_CAN_POST. - false: The group is active and can receive messages. - When false, updating whoCanPostMessage to NONE_CAN_POST, results in an error.
  --custom-footer-text: string # Set the content of custom footer text. The maximum number of characters is 1,000.
  --custom-reply-to: string # An email address used when replying to a message if the replyTo property is set to REPLY_TO_CUSTOM. This address is defined by an account administrator. - When the group's ReplyTo property is set to REPLY_TO_CUSTOM, the customReplyTo property holds a custom email address used when replying to a message. - If the group's ReplyTo property is set to REPLY_TO_CUSTOM, the customReplyTo property must have a text value or an error is returned.
  --custom-roles-enabled-for-settings-to-be-merged: string # Specifies whether the group has a custom role that's included in one of the settings being merged. This field is read-only and update/patch requests to it are ignored. Possible values are: - true - false
  --default-message-deny-notification-text: string # When a message is rejected, this is text for the rejection notification sent to the message's author. By default, this property is empty and has no value in the API's response body. The maximum notification text size is 10,000 characters. Note: Requires sendMessageDenyNotification property to be true.
  --default-sender: string # Default sender for members who can post messages as the group. Possible values are: - `DEFAULT_SELF`: By default messages will be sent from the user - `GROUP`: By default messages will be sent from the group
  --description: string # Description of the group. This property value may be an empty string if no group description has been entered. If entered, the maximum group description is no more than 300 characters.
  --email: string # The group's email address. This property can be updated using the Directory API. Note: Only a group owner can change a group's email address. A group manager can't do this. When you change your group's address using the Directory API or the control panel, you are changing the address your subscribers use to send email and the web address people use to access your group. People can't reach your group by visiting the old address.
  --enable-collaborative-inbox: string # Specifies whether a collaborative inbox will remain turned on for the group. Possible values are: - true - false
  --favorite-replies-on-top: string # Indicates if favorite replies should be displayed above other replies. - true: Favorite replies will be displayed above other replies. - false: Favorite replies will not be displayed above other replies.
  --include-custom-footer: string # Whether to include custom footer. Possible values are: - true - false
  --include-in-global-address-list: string # Enables the group to be included in the Global Address List. For more information, see the help center. Possible values are: - true: Group is included in the Global Address List. - false: Group is not included in the Global Address List.
  --is-archived: string # Allows the Group contents to be archived. Possible values are: - true: Archive messages sent to the group. - false: Do not keep an archive of messages sent to this group. If false, previously archived messages remain in the archive.
  --kind: string # The type of the resource. It is always groupsSettings#groups. (default: groupsSettings#groups)
  --max-message-bytes: int # Deprecated. The maximum size of a message is 25Mb. (format: int32)
  --members-can-post-as-the-group: string # Enables members to post messages as the group. Possible values are: - true: Group member can post messages using the group's email address instead of their own email address. Message appear to originate from the group itself. Note: When true, any message moderation settings on individual users or new members do not apply to posts made on behalf of the group. - false: Members can not post in behalf of the group's email address.
  --message-display-font: string # Deprecated. The default message display font always has a value of "DEFAULT_FONT".
  --message-moderation-level: string # Moderation level of incoming messages. Possible values are: - MODERATE_ALL_MESSAGES: All messages are sent to the group owner's email address for approval. If approved, the message is sent to the group. - MODERATE_NON_MEMBERS: All messages from non group members are sent to the group owner's email address for approval. If approved, the message is sent to the group. - MODERATE_NEW_MEMBERS: All messages from new members are sent to the group owner's email address for approval. If approved, the message is sent to the group. - MODERATE_NONE: No moderator approval is required. Messages are delivered directly to the group. Note: When the whoCanPostMessage is set to ANYONE_CAN_POST, we recommend the messageModerationLevel be set to MODERATE_NON_MEMBERS to protect the group from possible spam. When memberCanPostAsTheGroup is true, any message moderation settings on individual users or new members will not apply to posts made on behalf of the group.
  --name: string # Name of the group, which has a maximum size of 75 characters.
  --primary-language: string # The primary language for group. For a group's primary language use the language tags from the G Suite languages found at G Suite Email Settings API Email Language Tags.
  --reply-to: string # Specifies who receives the default reply. Possible values are: - REPLY_TO_CUSTOM: For replies to messages, use the group's custom email address. When the group's ReplyTo property is set to REPLY_TO_CUSTOM, the customReplyTo property holds the custom email address used when replying to a message. If the group's ReplyTo property is set to REPLY_TO_CUSTOM, the customReplyTo property must have a value. Otherwise an error is returned. - REPLY_TO_SENDER: The reply sent to author of message. - REPLY_TO_LIST: This reply message is sent to the group. - REPLY_TO_OWNER: The reply is sent to the owner(s) of the group. This does not include the group's managers. - REPLY_TO_IGNORE: Group users individually decide where the message reply is sent. - REPLY_TO_MANAGERS: This reply message is sent to the group's managers, which includes all managers and the group owner.
  --send-message-deny-notification: string # Allows a member to be notified if the member's message to the group is denied by the group owner. Possible values are: - true: When a message is rejected, send the deny message notification to the message author. The defaultMessageDenyNotificationText property is dependent on the sendMessageDenyNotification property being true. - false: When a message is rejected, no notification is sent.
  --show-in-group-directory: string # Deprecated. This is merged into the new whoCanDiscoverGroup setting. Allows the group to be visible in the Groups Directory. Possible values are: - true: All groups in the account are listed in the Groups directory. - false: All groups in the account are not listed in the directory.
  --spam-moderation-level: string # Specifies moderation levels for messages detected as spam. Possible values are: - ALLOW: Post the message to the group. - MODERATE: Send the message to the moderation queue. This is the default. - SILENTLY_MODERATE: Send the message to the moderation queue, but do not send notification to moderators. - REJECT: Immediately reject the message.
  --who-can-add: string # Deprecated. This is merged into the new whoCanModerateMembers setting. Permissions to add members. Possible values are: - ALL_MEMBERS_CAN_ADD: Managers and members can directly add new members. - ALL_MANAGERS_CAN_ADD: Only managers can directly add new members. this includes the group's owner. - ALL_OWNERS_CAN_ADD: Only owners can directly add new members. - NONE_CAN_ADD: No one can directly add new members.
  --who-can-add-references: string # Deprecated. This functionality is no longer supported in the Google Groups UI. The value is always "NONE".
  --who-can-approve-members: string # Specifies who can approve members who ask to join groups. This permission will be deprecated once it is merged into the new whoCanModerateMembers setting. Possible values are: - ALL_MEMBERS_CAN_APPROVE - ALL_MANAGERS_CAN_APPROVE - ALL_OWNERS_CAN_APPROVE - NONE_CAN_APPROVE
  --who-can-approve-messages: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can approve pending messages in the moderation queue. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - OWNERS_ONLY - NONE
  --who-can-assign-topics: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to assign topics in a forum to another user. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - MANAGERS_ONLY - OWNERS_ONLY - NONE
  --who-can-assist-content: string # Specifies who can moderate metadata. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - MANAGERS_ONLY - OWNERS_ONLY - NONE
  --who-can-ban-users: string # Specifies who can deny membership to users. This permission will be deprecated once it is merged into the new whoCanModerateMembers setting. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - OWNERS_ONLY - NONE
  --who-can-contact-owner: string # Permission to contact owner of the group via web UI. Possible values are: - ALL_IN_DOMAIN_CAN_CONTACT - ALL_MANAGERS_CAN_CONTACT - ALL_MEMBERS_CAN_CONTACT - ANYONE_CAN_CONTACT - ALL_OWNERS_CAN_CONTACT
  --who-can-delete-any-post: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can delete replies to topics. (Authors can always delete their own posts). Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - OWNERS_ONLY - NONE
  --who-can-delete-topics: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can delete topics. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - OWNERS_ONLY - NONE
  --who-can-discover-group: string # Specifies the set of users for whom this group is discoverable. Possible values are: - ANYONE_CAN_DISCOVER - ALL_IN_DOMAIN_CAN_DISCOVER - ALL_MEMBERS_CAN_DISCOVER
  --who-can-enter-free-form-tags: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to enter free form tags for topics in a forum. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - MANAGERS_ONLY - OWNERS_ONLY - NONE
  --who-can-hide-abuse: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can hide posts by reporting them as abuse. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - OWNERS_ONLY - NONE
  --who-can-invite: string # Deprecated. This is merged into the new whoCanModerateMembers setting. Permissions to invite new members. Possible values are: - ALL_MEMBERS_CAN_INVITE: Managers and members can invite a new member candidate. - ALL_MANAGERS_CAN_INVITE: Only managers can invite a new member. This includes the group's owner. - ALL_OWNERS_CAN_INVITE: Only owners can invite a new member. - NONE_CAN_INVITE: No one can invite a new member candidate.
  --who-can-join: string # Permission to join group. Possible values are: - ANYONE_CAN_JOIN: Anyone in the account domain can join. This includes accounts with multiple domains. - ALL_IN_DOMAIN_CAN_JOIN: Any Internet user who is outside your domain can access your Google Groups service and view the list of groups in your Groups directory. Warning: Group owners can add external addresses, outside of the domain to their groups. They can also allow people outside your domain to join their groups. If you later disable this option, any external addresses already added to users' groups remain in those groups. - INVITED_CAN_JOIN: Candidates for membership can be invited to join. - CAN_REQUEST_TO_JOIN: Non members can request an invitation to join.
  --who-can-leave-group: string # Permission to leave the group. Possible values are: - ALL_MANAGERS_CAN_LEAVE - ALL_MEMBERS_CAN_LEAVE - NONE_CAN_LEAVE
  --who-can-lock-topics: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can prevent users from posting replies to topics. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - OWNERS_ONLY - NONE
  --who-can-make-topics-sticky: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can make topics appear at the top of the topic list. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - OWNERS_ONLY - NONE
  --who-can-mark-duplicate: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to mark a topic as a duplicate of another topic. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - MANAGERS_ONLY - OWNERS_ONLY - NONE
  --who-can-mark-favorite-reply-on-any-topic: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to mark any other user's post as a favorite reply. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - MANAGERS_ONLY - OWNERS_ONLY - NONE
  --who-can-mark-favorite-reply-on-own-topic: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to mark a post for a topic they started as a favorite reply. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - MANAGERS_ONLY - OWNERS_ONLY - NONE
  --who-can-mark-no-response-needed: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to mark a topic as not needing a response. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - MANAGERS_ONLY - OWNERS_ONLY - NONE
  --who-can-moderate-content: string # Specifies who can moderate content. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - OWNERS_ONLY - NONE
  --who-can-moderate-members: string # Specifies who can manage members. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - OWNERS_ONLY - NONE
  --who-can-modify-members: string # Deprecated. This is merged into the new whoCanModerateMembers setting. Specifies who can change group members' roles. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - OWNERS_ONLY - NONE
  --who-can-modify-tags-and-categories: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to change tags and categories. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - MANAGERS_ONLY - OWNERS_ONLY - NONE
  --who-can-move-topics-in: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can move topics into the group or forum. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - OWNERS_ONLY - NONE
  --who-can-move-topics-out: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can move topics out of the group or forum. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - OWNERS_ONLY - NONE
  --who-can-post-announcements: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can post announcements, a special topic type. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - OWNERS_ONLY - NONE
  --who-can-post-message: string # Permissions to post messages. Possible values are: - NONE_CAN_POST: The group is disabled and archived. No one can post a message to this group. - When archiveOnly is false, updating whoCanPostMessage to NONE_CAN_POST, results in an error. - If archiveOnly is reverted from true to false, whoCanPostMessages is set to ALL_MANAGERS_CAN_POST. - ALL_MANAGERS_CAN_POST: Managers, including group owners, can post messages. - ALL_MEMBERS_CAN_POST: Any group member can post a message. - ALL_OWNERS_CAN_POST: Only group owners can post a message. - ALL_IN_DOMAIN_CAN_POST: Anyone in the account can post a message. - ANYONE_CAN_POST: Any Internet user who outside your account can access your Google Groups service and post a message. Note: When whoCanPostMessage is set to ANYONE_CAN_POST, we recommend the messageModerationLevel be set to MODERATE_NON_MEMBERS to protect the group from possible spam.
  --who-can-take-topics: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to take topics in a forum. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - MANAGERS_ONLY - OWNERS_ONLY - NONE
  --who-can-unassign-topic: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to unassign any topic in a forum. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - MANAGERS_ONLY - OWNERS_ONLY - NONE
  --who-can-unmark-favorite-reply-on-any-topic: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to unmark any post from a favorite reply. Possible values are: - ALL_MEMBERS - OWNERS_AND_MANAGERS - MANAGERS_ONLY - OWNERS_ONLY - NONE
  --who-can-view-group: string # Permissions to view group messages. Possible values are: - ANYONE_CAN_VIEW: Any Internet user can view the group's messages. - ALL_IN_DOMAIN_CAN_VIEW: Anyone in your account can view this group's messages. - ALL_MEMBERS_CAN_VIEW: All group members can view the group's messages. - ALL_MANAGERS_CAN_VIEW: Any group manager can view this group's messages.
  --who-can-view-membership: string # Permissions to view membership. Possible values are: - ALL_IN_DOMAIN_CAN_VIEW: Anyone in the account can view the group members list. If a group already has external members, those members can still send email to this group. - ALL_MEMBERS_CAN_VIEW: The group members can view the group members list. - ALL_MANAGERS_CAN_VIEW: The group managers can view group members list.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{groupUniqueId}"
    path_params: [{name: groupUniqueId, var: group_unique_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: allowExternalMembers, var: allow_external_members}, {name: allowGoogleCommunication, var: allow_google_communication}, {name: allowWebPosting, var: allow_web_posting}, {name: archiveOnly, var: archive_only}, {name: customFooterText, var: custom_footer_text}, {name: customReplyTo, var: custom_reply_to}, {name: customRolesEnabledForSettingsToBeMerged, var: custom_roles_enabled_for_settings_to_be_merged}, {name: defaultMessageDenyNotificationText, var: default_message_deny_notification_text}, {name: default_sender, var: default_sender}, {name: description, var: description}, {name: email, var: email}, {name: enableCollaborativeInbox, var: enable_collaborative_inbox}, {name: favoriteRepliesOnTop, var: favorite_replies_on_top}, {name: includeCustomFooter, var: include_custom_footer}, {name: includeInGlobalAddressList, var: include_in_global_address_list}, {name: isArchived, var: is_archived}, {name: kind, var: kind}, {name: maxMessageBytes, var: max_message_bytes}, {name: membersCanPostAsTheGroup, var: members_can_post_as_the_group}, {name: messageDisplayFont, var: message_display_font}, {name: messageModerationLevel, var: message_moderation_level}, {name: name, var: name}, {name: primaryLanguage, var: primary_language}, {name: replyTo, var: reply_to}, {name: sendMessageDenyNotification, var: send_message_deny_notification}, {name: showInGroupDirectory, var: show_in_group_directory}, {name: spamModerationLevel, var: spam_moderation_level}, {name: whoCanAdd, var: who_can_add}, {name: whoCanAddReferences, var: who_can_add_references}, {name: whoCanApproveMembers, var: who_can_approve_members}, {name: whoCanApproveMessages, var: who_can_approve_messages}, {name: whoCanAssignTopics, var: who_can_assign_topics}, {name: whoCanAssistContent, var: who_can_assist_content}, {name: whoCanBanUsers, var: who_can_ban_users}, {name: whoCanContactOwner, var: who_can_contact_owner}, {name: whoCanDeleteAnyPost, var: who_can_delete_any_post}, {name: whoCanDeleteTopics, var: who_can_delete_topics}, {name: whoCanDiscoverGroup, var: who_can_discover_group}, {name: whoCanEnterFreeFormTags, var: who_can_enter_free_form_tags}, {name: whoCanHideAbuse, var: who_can_hide_abuse}, {name: whoCanInvite, var: who_can_invite}, {name: whoCanJoin, var: who_can_join}, {name: whoCanLeaveGroup, var: who_can_leave_group}, {name: whoCanLockTopics, var: who_can_lock_topics}, {name: whoCanMakeTopicsSticky, var: who_can_make_topics_sticky}, {name: whoCanMarkDuplicate, var: who_can_mark_duplicate}, {name: whoCanMarkFavoriteReplyOnAnyTopic, var: who_can_mark_favorite_reply_on_any_topic}, {name: whoCanMarkFavoriteReplyOnOwnTopic, var: who_can_mark_favorite_reply_on_own_topic}, {name: whoCanMarkNoResponseNeeded, var: who_can_mark_no_response_needed}, {name: whoCanModerateContent, var: who_can_moderate_content}, {name: whoCanModerateMembers, var: who_can_moderate_members}, {name: whoCanModifyMembers, var: who_can_modify_members}, {name: whoCanModifyTagsAndCategories, var: who_can_modify_tags_and_categories}, {name: whoCanMoveTopicsIn, var: who_can_move_topics_in}, {name: whoCanMoveTopicsOut, var: who_can_move_topics_out}, {name: whoCanPostAnnouncements, var: who_can_post_announcements}, {name: whoCanPostMessage, var: who_can_post_message}, {name: whoCanTakeTopics, var: who_can_take_topics}, {name: whoCanUnassignTopic, var: who_can_unassign_topic}, {name: whoCanUnmarkFavoriteReplyOnAnyTopic, var: who_can_unmark_favorite_reply_on_any_topic}, {name: whoCanViewGroup, var: who_can_view_group}, {name: whoCanViewMembership, var: who_can_view_membership}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_unique_id: $group_unique_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, allow_external_members: $allow_external_members, allow_google_communication: $allow_google_communication, allow_web_posting: $allow_web_posting, archive_only: $archive_only, custom_footer_text: $custom_footer_text, custom_reply_to: $custom_reply_to, custom_roles_enabled_for_settings_to_be_merged: $custom_roles_enabled_for_settings_to_be_merged, default_message_deny_notification_text: $default_message_deny_notification_text, default_sender: $default_sender, description: $description, email: $email, enable_collaborative_inbox: $enable_collaborative_inbox, favorite_replies_on_top: $favorite_replies_on_top, include_custom_footer: $include_custom_footer, include_in_global_address_list: $include_in_global_address_list, is_archived: $is_archived, kind: $kind, max_message_bytes: $max_message_bytes, members_can_post_as_the_group: $members_can_post_as_the_group, message_display_font: $message_display_font, message_moderation_level: $message_moderation_level, name: $name, primary_language: $primary_language, reply_to: $reply_to, send_message_deny_notification: $send_message_deny_notification, show_in_group_directory: $show_in_group_directory, spam_moderation_level: $spam_moderation_level, who_can_add: $who_can_add, who_can_add_references: $who_can_add_references, who_can_approve_members: $who_can_approve_members, who_can_approve_messages: $who_can_approve_messages, who_can_assign_topics: $who_can_assign_topics, who_can_assist_content: $who_can_assist_content, who_can_ban_users: $who_can_ban_users, who_can_contact_owner: $who_can_contact_owner, who_can_delete_any_post: $who_can_delete_any_post, who_can_delete_topics: $who_can_delete_topics, who_can_discover_group: $who_can_discover_group, who_can_enter_free_form_tags: $who_can_enter_free_form_tags, who_can_hide_abuse: $who_can_hide_abuse, who_can_invite: $who_can_invite, who_can_join: $who_can_join, who_can_leave_group: $who_can_leave_group, who_can_lock_topics: $who_can_lock_topics, who_can_make_topics_sticky: $who_can_make_topics_sticky, who_can_mark_duplicate: $who_can_mark_duplicate, who_can_mark_favorite_reply_on_any_topic: $who_can_mark_favorite_reply_on_any_topic, who_can_mark_favorite_reply_on_own_topic: $who_can_mark_favorite_reply_on_own_topic, who_can_mark_no_response_needed: $who_can_mark_no_response_needed, who_can_moderate_content: $who_can_moderate_content, who_can_moderate_members: $who_can_moderate_members, who_can_modify_members: $who_can_modify_members, who_can_modify_tags_and_categories: $who_can_modify_tags_and_categories, who_can_move_topics_in: $who_can_move_topics_in, who_can_move_topics_out: $who_can_move_topics_out, who_can_post_announcements: $who_can_post_announcements, who_can_post_message: $who_can_post_message, who_can_take_topics: $who_can_take_topics, who_can_unassign_topic: $who_can_unassign_topic, who_can_unmark_favorite_reply_on_any_topic: $who_can_unmark_favorite_reply_on_any_topic, who_can_view_group: $who_can_view_group, who_can_view_membership: $who_can_view_membership
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
