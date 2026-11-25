# Auto-generated client for PTV Timetable API - Version 3 v3
# Source: https://api.apis.guru/v2/specs/ptv.vic.gov.au/v3/openapi.json
# Auth: --token flag or $env.PTV_TIMETABLE_API_VERSION_3_TOKEN

const CLIENT = {
  base_url: "http://timetableapi.ptv.vic.gov.au"
  token_env_var: "PTV_TIMETABLE_API_VERSION_3_TOKEN"
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

def base-url-completer [] { ["http://timetableapi.ptv.vic.gov.au" "https://timetableapi.ptv.vic.gov.au"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def route-type-completer [] { ["0" "1" "2" "3" "4"] }
def accept-completer [] { ["application/json" "text/html" "text/json"] }
def disruption-status-completer [] { ["current" "planned"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    departures-get-for-stop: "record<departures: table<at_platform: bool, departure_sequence: int, direction_id: int, disruption_ids: list, estimated_departure_utc: string, flags: string, platform_number: string, route_id: int, run_id: int, run_ref: string, scheduled_departure_utc: string, stop_id: int>, directions: record, disruptions: record, routes: record, runs: record, status: record<health: int, version: string>, stops: record>"
    departures-get-for-stop-and-route: "record<departures: table<at_platform: bool, departure_sequence: int, direction_id: int, disruption_ids: list, estimated_departure_utc: string, flags: string, platform_number: string, route_id: int, run_id: int, run_ref: string, scheduled_departure_utc: string, stop_id: int>, directions: record, disruptions: record, routes: record, runs: record, status: record<health: int, version: string>, stops: record>"
    directions-for-route: "record<directions: table<direction_id: int, direction_name: string, route_direction_description: string, route_id: int, route_type: int>, status: record<health: int, version: string>>"
    directions-for-direction: "record<directions: table<direction_id: int, direction_name: string, route_direction_description: string, route_id: int, route_type: int>, status: record<health: int, version: string>>"
    directions-for-direction-and-type: "record<directions: table<direction_id: int, direction_name: string, route_direction_description: string, route_id: int, route_type: int>, status: record<health: int, version: string>>"
    disruptions-get-all-disruptions: "record<disruptions: record<ferry: list<record>, general: list<record>, interstate_train: list<record>, metro_bus: list<record>, metro_train: list<record>, metro_tram: list<record>, night_bus: list<record>, regional_bus: list<record>, regional_coach: list<record>, regional_train: list<record>, school_bus: list<record>, skybus: list<record>, taxi: list<record>, telebus: list<record>>, status: record<health: int, version: string>>"
    disruptions-get-disruption-modes: "record<disruption_modes: table<disruption_mode: int, disruption_mode_name: string>, status: record<health: int, version: string>>"
    disruptions-get-disruptions-by-route: "record<disruptions: record<ferry: list<record>, general: list<record>, interstate_train: list<record>, metro_bus: list<record>, metro_train: list<record>, metro_tram: list<record>, night_bus: list<record>, regional_bus: list<record>, regional_coach: list<record>, regional_train: list<record>, school_bus: list<record>, skybus: list<record>, taxi: list<record>, telebus: list<record>>, status: record<health: int, version: string>>"
    disruptions-get-disruptions-by-route-and-stop: "record<disruptions: record<ferry: list<record>, general: list<record>, interstate_train: list<record>, metro_bus: list<record>, metro_train: list<record>, metro_tram: list<record>, night_bus: list<record>, regional_bus: list<record>, regional_coach: list<record>, regional_train: list<record>, school_bus: list<record>, skybus: list<record>, taxi: list<record>, telebus: list<record>>, status: record<health: int, version: string>>"
    disruptions-get-disruptions-by-stop: "record<disruptions: record<ferry: list<record>, general: list<record>, interstate_train: list<record>, metro_bus: list<record>, metro_train: list<record>, metro_tram: list<record>, night_bus: list<record>, regional_bus: list<record>, regional_coach: list<record>, regional_train: list<record>, school_bus: list<record>, skybus: list<record>, taxi: list<record>, telebus: list<record>>, status: record<health: int, version: string>>"
    disruptions-get-disruption-by-id: "record<disruption: record<colour: string, description: string, display_on_board: bool, display_status: bool, disruption_id: int, disruption_status: string, disruption_type: string, from_date: string, last_updated: string, published_on: string, routes: list<record>, stops: list<record>, title: string, to_date: string, url: string>, status: record<health: int, version: string>>"
    outlets-get-all-outlets: "record<outlets: table<outlet_business: string, outlet_business_hour_fri: string, outlet_business_hour_mon: string, outlet_business_hour_sat: string, outlet_business_hour_sun: string, outlet_business_hour_thur: string, outlet_business_hour_tue: string, outlet_business_hour_wed: string, outlet_latitude: float, outlet_longitude: float, outlet_name: string, outlet_notes: string, outlet_postcode: int, outlet_slid_spid: string, outlet_suburb: string>, status: record<health: int, version: string>>"
    outlets-get-outlets-by-geolocation: "record<outlets: table<outlet_business: string, outlet_business_hour_fri: string, outlet_business_hour_mon: string, outlet_business_hour_sat: string, outlet_business_hour_sun: string, outlet_business_hour_thur: string, outlet_business_hour_tue: string, outlet_business_hour_wed: string, outlet_distance: float, outlet_latitude: float, outlet_longitude: float, outlet_name: string, outlet_notes: string, outlet_postcode: int, outlet_slid_spid: string, outlet_suburb: string>, status: record<health: int, version: string>>"
    patterns-get-pattern-by-run: "record<departures: table<at_platform: bool, departure_sequence: int, direction_id: int, disruption_ids: list, estimated_departure_utc: string, flags: string, platform_number: string, route_id: int, run_id: int, run_ref: string, scheduled_departure_utc: string, skipped_stops: list, stop_id: int>, directions: record, disruptions: table<colour: string, description: string, display_on_board: bool, display_status: bool, disruption_id: int, disruption_status: string, disruption_type: string, from_date: string, last_updated: string, published_on: string, routes: list, stops: list, title: string, to_date: string, url: string>, routes: record, runs: record, status: record<health: int, version: string>, stops: record>"
    route-types-get-route-types: "record<route_types: table<route_type: int, route_type_name: string>, status: record<health: int, version: string>>"
    routes-one-or-more-routes: "record<route: record, status: record<health: int, version: string>>"
    routes-route-from-id: "record<route: record, status: record<health: int, version: string>>"
    runs-for-route: "record<runs: table<destination_name: string, direction_id: int, express_stop_count: int, final_stop_id: int, geopath: list, route_id: int, route_type: int, run_id: int, run_ref: string, run_sequence: int, status: string, vehicle_descriptor: record, vehicle_position: record>, status: record<health: int, version: string>>"
    runs-for-route-and-route-type: "record<runs: table<destination_name: string, direction_id: int, express_stop_count: int, final_stop_id: int, geopath: list, route_id: int, route_type: int, run_id: int, run_ref: string, run_sequence: int, status: string, vehicle_descriptor: record, vehicle_position: record>, status: record<health: int, version: string>>"
    runs-for-run: "record<runs: table<destination_name: string, direction_id: int, express_stop_count: int, final_stop_id: int, geopath: list, route_id: int, route_type: int, run_id: int, run_ref: string, run_sequence: int, status: string, vehicle_descriptor: record, vehicle_position: record>, status: record<health: int, version: string>>"
    runs-for-run-and-route-type: "record<run: record<destination_name: string, direction_id: int, express_stop_count: int, final_stop_id: int, geopath: list<record>, route_id: int, route_type: int, run_id: int, run_ref: string, run_sequence: int, status: string, vehicle_descriptor: record<air_conditioned: bool, description: string, id: string, length: string, low_floor: bool, operator: string, supplier: string>, vehicle_position: record<bearing: float, datetime_utc: string, direction: string, easting: float, expiry_time: string, latitude: float, longitude: float, northing: float, supplier: string>>, status: record<health: int, version: string>>"
    search-search: "record<outlets: table<outlet_business: string, outlet_business_hour_fri: string, outlet_business_hour_mon: string, outlet_business_hour_sat: string, outlet_business_hour_sun: string, outlet_business_hour_thur: string, outlet_business_hour_tue: string, outlet_business_hour_wed: string, outlet_distance: float, outlet_latitude: float, outlet_longitude: float, outlet_name: string, outlet_notes: string, outlet_postcode: int, outlet_slid_spid: string, outlet_suburb: string>, routes: table<route_gtfs_id: string, route_id: int, route_name: string, route_number: string, route_service_status: record, route_type: int>, status: record<health: int, version: string>, stops: table<route_type: int, routes: list, stop_distance: float, stop_id: int, stop_landmark: string, stop_latitude: float, stop_longitude: float, stop_name: string, stop_sequence: int, stop_suburb: string>>"
    stops-stops-by-geolocation: "record<disruptions: record, status: record<health: int, version: string>, stops: table<disruption_ids: list, route_type: int, routes: list, stop_distance: float, stop_id: int, stop_landmark: string, stop_latitude: float, stop_longitude: float, stop_name: string, stop_sequence: int, stop_suburb: string>>"
    stops-stops-for-route: "record<disruptions: record, geopath: list<record>, status: record<health: int, version: string>, stops: table<disruption_ids: list, route_type: int, stop_id: int, stop_landmark: string, stop_latitude: float, stop_longitude: float, stop_name: string, stop_sequence: int, stop_suburb: string, stop_ticket: record>>"
    stops-stop-details: "record<disruptions: record, status: record<health: int, version: string>, stop: record<disruption_ids: list<int>, route_type: int, routes: list<record>, station_description: string, station_type: string, stop_accessibility: record<audio_customer_information: bool, escalator: bool, hearing_loop: bool, lift: bool, lighting: bool, platform_number: int, stairs: bool, stop_accessible: bool, tactile_ground_surface_indicator: bool, waiting_room: bool, wheelchair: record>, stop_amenities: record<car_parking: string, cctv: bool, taxi_rank: bool, toilet: bool>, stop_id: int, stop_landmark: string, stop_location: record<gps: record>, stop_name: string, stop_staffing: record<fri_am_from: string, fri_am_to: string, fri_pm_from: string, fri_pm_to: string, mon_am_from: string, mon_am_to: string, mon_pm_from: string, mon_pm_to: string, ph_additional_text: string, ph_from: string, ph_to: string, sat_am_from: string, sat_am_to: string, sat_pm_from: string, sat_pm_to: string, sun_am_from: string, sun_am_to: string, sun_pm_from: string, sun_pm_to: string, thu_am_from: string, thu_am_to: string, thu_pm_from: string, thu_pm_to: string, tue_am_from: string, tue_am_to: string, tue_pm_from: string, tue_pm_to: string, wed_am_from: string, wed_am_to: string, wed_pm_To: string, wed_pm_from: string>>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["departures-get-for-stop" "departures-get-for-stop-and-route" "directions-for-route" "directions-for-direction" "directions-for-direction-and-type" "disruptions-get-all-disruptions" "disruptions-get-disruption-modes" "disruptions-get-disruptions-by-route" "disruptions-get-disruptions-by-route-and-stop" "disruptions-get-disruptions-by-stop" "disruptions-get-disruption-by-id" "fare-estimate-get-fare-estimate-by-zone" "outlets-get-all-outlets" "outlets-get-outlets-by-geolocation" "patterns-get-pattern-by-run" "route-types-get-route-types" "routes-one-or-more-routes" "routes-route-from-id" "runs-for-route" "runs-for-route-and-route-type" "runs-for-run" "runs-for-run-and-route-type" "search-search" "stops-stops-by-geolocation" "stops-stops-for-route" "stops-stop-details" "commands"] | sort) } | get name | first)
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

# View departures for all routes from a stop
#
# GET /v3/departures/route_type/{route_type}/stop/{stop_id}
# Returns: record<departures: table<at_platform: bool, departure_sequence: int, direction_id: int, disruption_ids: list, estimated_departure_utc: string, flags: string, platform_number: string, route_id: int, run_id: int, run_ref: string, scheduled_departure_utc: string, stop_id: int>, directions: record, disruptions: record, routes: record, runs: record, status: record<health: int, version: string>, stops: record>
# operationId: Departures_GetForStop
export def "departures-get-for-stop" [
  route_type: int@route-type-completer
  stop_id: int
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
  --platform-numbers: list<int> # Filter by platform number at stop
  --direction-id: int # Filter by identifier of direction of travel; values returned by Directions API - /v3/directions/route/{route_id} (format: int32)
  --gtfs: oneof<nothing, bool> # Indicates that stop_id parameter will accept "GTFS stop_id" data
  --date-utc: string # Filter by the date and time of the request (ISO 8601 UTC format) (default = current date and time) (format: date-time)
  --max-results: int # Maximum number of results returned (format: int32)
  --include-cancelled: oneof<nothing, bool> # Indicates if cancelled services (if they exist) are returned (default = false) - metropolitan train only
  --look-backwards: oneof<nothing, bool> # Indicates if filtering runs (and their departures) to those that arrive at destination before date_utc (default = false). Requires max_results > 0.
  --expand: list<string> # List of objects to be returned in full (i.e. expanded) - options include: All, Stop, Route, Run, Direction, Disruption, VehiclePosition, VehicleDescriptor or None. Run must be expanded to receive VehiclePosition and VehicleDescriptor information.
  --include-geopath: oneof<nothing, bool> # Indicates if the route geopath should be returned
  --qp-token: string # Please ignore (spec name: token)
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/departures/route_type/{route_type}/stop/{stop_id}"
    path_params: [{name: route_type, var: route_type}, {name: stop_id, var: stop_id}]
    query: [{name: platform_numbers, var: platform_numbers, style: multi}, {name: direction_id, var: direction_id}, {name: gtfs, var: gtfs}, {name: date_utc, var: date_utc}, {name: max_results, var: max_results}, {name: include_cancelled, var: include_cancelled}, {name: look_backwards, var: look_backwards}, {name: expand, var: expand, style: multi}, {name: include_geopath, var: include_geopath}, {name: token, var: qp_token}, {name: devid, var: devid}, {name: signature, var: signature}]
    accept: ["application/json", "text/html", "text/json"]
    ok: [200]
    auth: bearer
  } {
    route_type: $route_type, stop_id: $stop_id, platform_numbers: $platform_numbers, direction_id: $direction_id, gtfs: $gtfs, date_utc: $date_utc, max_results: $max_results, include_cancelled: $include_cancelled, look_backwards: $look_backwards, expand: $expand, include_geopath: $include_geopath, qp_token: $qp_token, devid: $devid, signature: $signature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# View departures for a specific route from a stop
#
# GET /v3/departures/route_type/{route_type}/stop/{stop_id}/route/{route_id}
# Returns: record<departures: table<at_platform: bool, departure_sequence: int, direction_id: int, disruption_ids: list, estimated_departure_utc: string, flags: string, platform_number: string, route_id: int, run_id: int, run_ref: string, scheduled_departure_utc: string, stop_id: int>, directions: record, disruptions: record, routes: record, runs: record, status: record<health: int, version: string>, stops: record>
# operationId: Departures_GetForStopAndRoute
export def "departures-get-for-stop-and-route" [
  route_type: int@route-type-completer
  stop_id: int
  route_id: string
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
  --direction-id: int # Filter by identifier of direction of travel; values returned by Directions API - /v3/directions/route/{route_id} (format: int32)
  --gtfs: oneof<nothing, bool> # Indicates that stop_id parameter will accept "GTFS stop_id" data
  --date-utc: string # Filter by the date and time of the request (ISO 8601 UTC format) (default = current date and time) (format: date-time)
  --max-results: int # Maximum number of results returned (format: int32)
  --include-cancelled: oneof<nothing, bool> # Indicates if cancelled services (if they exist) are returned (default = false) - metropolitan train only
  --look-backwards: oneof<nothing, bool> # Indicates if filtering runs (and their departures) to those that arrive at destination before date_utc (default = false). Requires max_results > 0.
  --expand: list<string> # List of objects to be returned in full (i.e. expanded) - options include: All, Stop, Route, Run, Direction, Disruption, VehiclePosition, VehicleDescriptor or None. Run must be expanded to receive VehiclePosition and VehicleDescriptor information.
  --include-geopath: oneof<nothing, bool> # Indicates if the route geopath should be returned
  --qp-token: string # Please ignore (spec name: token)
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/departures/route_type/{route_type}/stop/{stop_id}/route/{route_id}"
    path_params: [{name: route_type, var: route_type}, {name: stop_id, var: stop_id}, {name: route_id, var: route_id}]
    query: [{name: direction_id, var: direction_id}, {name: gtfs, var: gtfs}, {name: date_utc, var: date_utc}, {name: max_results, var: max_results}, {name: include_cancelled, var: include_cancelled}, {name: look_backwards, var: look_backwards}, {name: expand, var: expand, style: multi}, {name: include_geopath, var: include_geopath}, {name: token, var: qp_token}, {name: devid, var: devid}, {name: signature, var: signature}]
    accept: ["application/json", "text/html", "text/json"]
    ok: [200]
    auth: bearer
  } {
    route_type: $route_type, stop_id: $stop_id, route_id: $route_id, direction_id: $direction_id, gtfs: $gtfs, date_utc: $date_utc, max_results: $max_results, include_cancelled: $include_cancelled, look_backwards: $look_backwards, expand: $expand, include_geopath: $include_geopath, qp_token: $qp_token, devid: $devid, signature: $signature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# View directions that a route travels in
#
# GET /v3/directions/route/{route_id}
# Returns: record<directions: table<direction_id: int, direction_name: string, route_direction_description: string, route_id: int, route_type: int>, status: record<health: int, version: string>>
# operationId: Directions_ForRoute
export def "directions-for-route" [
  route_id: int
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
  --qp-token: string # Please ignore (spec name: token)
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/directions/route/{route_id}"
    path_params: [{name: route_id, var: route_id}]
    query: [{name: token, var: qp_token}, {name: devid, var: devid}, {name: signature, var: signature}]
    accept: ["application/json", "text/html", "text/json"]
    ok: [200]
    auth: bearer
  } {
    route_id: $route_id, qp_token: $qp_token, devid: $devid, signature: $signature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# View all routes for a direction of travel
#
# GET /v3/directions/{direction_id}
# Returns: record<directions: table<direction_id: int, direction_name: string, route_direction_description: string, route_id: int, route_type: int>, status: record<health: int, version: string>>
# operationId: Directions_ForDirection
export def "directions-for-direction" [
  direction_id: int
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
  --qp-token: string # Please ignore (spec name: token)
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/directions/{direction_id}"
    path_params: [{name: direction_id, var: direction_id}]
    query: [{name: token, var: qp_token}, {name: devid, var: devid}, {name: signature, var: signature}]
    accept: ["application/json", "text/html", "text/json"]
    ok: [200]
    auth: bearer
  } {
    direction_id: $direction_id, qp_token: $qp_token, devid: $devid, signature: $signature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# View all routes of a particular type for a direction of travel
#
# GET /v3/directions/{direction_id}/route_type/{route_type}
# Returns: record<directions: table<direction_id: int, direction_name: string, route_direction_description: string, route_id: int, route_type: int>, status: record<health: int, version: string>>
# operationId: Directions_ForDirectionAndType
export def "directions-for-direction-and-type" [
  direction_id: int
  route_type: int@route-type-completer
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
  --qp-token: string # Please ignore (spec name: token)
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/directions/{direction_id}/route_type/{route_type}"
    path_params: [{name: direction_id, var: direction_id}, {name: route_type, var: route_type}]
    query: [{name: token, var: qp_token}, {name: devid, var: devid}, {name: signature, var: signature}]
    accept: ["application/json", "text/html", "text/json"]
    ok: [200]
    auth: bearer
  } {
    direction_id: $direction_id, route_type: $route_type, qp_token: $qp_token, devid: $devid, signature: $signature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# View all disruptions for all route types
#
# GET /v3/disruptions
# Returns: record<disruptions: record<ferry: list<record>, general: list<record>, interstate_train: list<record>, metro_bus: list<record>, metro_train: list<record>, metro_tram: list<record>, night_bus: list<record>, regional_bus: list<record>, regional_coach: list<record>, regional_train: list<record>, school_bus: list<record>, skybus: list<record>, taxi: list<record>, telebus: list<record>>, status: record<health: int, version: string>>
# operationId: Disruptions_GetAllDisruptions
export def "disruptions-get-all-disruptions" [
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
  --route-types: list<int> # Filter by route_type; values returned via RouteTypes API
  --disruption-modes: list<int> # Filter by disruption_mode; values returned via v3/disruptions/modes API
  --disruption-status: string@disruption-status-completer # Filter by status of disruption
  --qp-token: string # Please ignore (spec name: token)
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/disruptions"
    query: [{name: route_types, var: route_types, style: multi}, {name: disruption_modes, var: disruption_modes, style: multi}, {name: disruption_status, var: disruption_status}, {name: token, var: qp_token}, {name: devid, var: devid}, {name: signature, var: signature}]
    accept: ["application/json", "text/html", "text/json"]
    ok: [200]
    auth: bearer
  } {
    route_types: $route_types, disruption_modes: $disruption_modes, disruption_status: $disruption_status, qp_token: $qp_token, devid: $devid, signature: $signature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get all disruption modes
#
# GET /v3/disruptions/modes
# Returns: record<disruption_modes: table<disruption_mode: int, disruption_mode_name: string>, status: record<health: int, version: string>>
# operationId: Disruptions_GetDisruptionModes
export def "disruptions-get-disruption-modes" [
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
  --qp-token: string # Please ignore (spec name: token)
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/disruptions/modes"
    query: [{name: token, var: qp_token}, {name: devid, var: devid}, {name: signature, var: signature}]
    accept: ["application/json", "text/html", "text/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, devid: $devid, signature: $signature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# View all disruptions for a particular route
#
# GET /v3/disruptions/route/{route_id}
# Returns: record<disruptions: record<ferry: list<record>, general: list<record>, interstate_train: list<record>, metro_bus: list<record>, metro_train: list<record>, metro_tram: list<record>, night_bus: list<record>, regional_bus: list<record>, regional_coach: list<record>, regional_train: list<record>, school_bus: list<record>, skybus: list<record>, taxi: list<record>, telebus: list<record>>, status: record<health: int, version: string>>
# operationId: Disruptions_GetDisruptionsByRoute
export def "disruptions-get-disruptions-by-route" [
  route_id: int
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
  --disruption-status: string@disruption-status-completer # Filter by status of disruption
  --qp-token: string # Please ignore (spec name: token)
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/disruptions/route/{route_id}"
    path_params: [{name: route_id, var: route_id}]
    query: [{name: disruption_status, var: disruption_status}, {name: token, var: qp_token}, {name: devid, var: devid}, {name: signature, var: signature}]
    accept: ["application/json", "text/html", "text/json"]
    ok: [200]
    auth: bearer
  } {
    route_id: $route_id, disruption_status: $disruption_status, qp_token: $qp_token, devid: $devid, signature: $signature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# View all disruptions for a particular route and stop
#
# GET /v3/disruptions/route/{route_id}/stop/{stop_id}
# Returns: record<disruptions: record<ferry: list<record>, general: list<record>, interstate_train: list<record>, metro_bus: list<record>, metro_train: list<record>, metro_tram: list<record>, night_bus: list<record>, regional_bus: list<record>, regional_coach: list<record>, regional_train: list<record>, school_bus: list<record>, skybus: list<record>, taxi: list<record>, telebus: list<record>>, status: record<health: int, version: string>>
# operationId: Disruptions_GetDisruptionsByRouteAndStop
export def "disruptions-get-disruptions-by-route-and-stop" [
  route_id: int
  stop_id: int
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
  --disruption-status: string@disruption-status-completer # Filter by status of disruption
  --qp-token: string # Please ignore (spec name: token)
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/disruptions/route/{route_id}/stop/{stop_id}"
    path_params: [{name: route_id, var: route_id}, {name: stop_id, var: stop_id}]
    query: [{name: disruption_status, var: disruption_status}, {name: token, var: qp_token}, {name: devid, var: devid}, {name: signature, var: signature}]
    accept: ["application/json", "text/html", "text/json"]
    ok: [200]
    auth: bearer
  } {
    route_id: $route_id, stop_id: $stop_id, disruption_status: $disruption_status, qp_token: $qp_token, devid: $devid, signature: $signature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# View all disruptions for a particular stop
#
# GET /v3/disruptions/stop/{stop_id}
# Returns: record<disruptions: record<ferry: list<record>, general: list<record>, interstate_train: list<record>, metro_bus: list<record>, metro_train: list<record>, metro_tram: list<record>, night_bus: list<record>, regional_bus: list<record>, regional_coach: list<record>, regional_train: list<record>, school_bus: list<record>, skybus: list<record>, taxi: list<record>, telebus: list<record>>, status: record<health: int, version: string>>
# operationId: Disruptions_GetDisruptionsByStop
export def "disruptions-get-disruptions-by-stop" [
  stop_id: int
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
  --disruption-status: string@disruption-status-completer # Filter by status of disruption
  --qp-token: string # Please ignore (spec name: token)
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/disruptions/stop/{stop_id}"
    path_params: [{name: stop_id, var: stop_id}]
    query: [{name: disruption_status, var: disruption_status}, {name: token, var: qp_token}, {name: devid, var: devid}, {name: signature, var: signature}]
    accept: ["application/json", "text/html", "text/json"]
    ok: [200]
    auth: bearer
  } {
    stop_id: $stop_id, disruption_status: $disruption_status, qp_token: $qp_token, devid: $devid, signature: $signature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# View a specific disruption
#
# GET /v3/disruptions/{disruption_id}
# Returns: record<disruption: record<colour: string, description: string, display_on_board: bool, display_status: bool, disruption_id: int, disruption_status: string, disruption_type: string, from_date: string, last_updated: string, published_on: string, routes: list<record>, stops: list<record>, title: string, to_date: string, url: string>, status: record<health: int, version: string>>
# operationId: Disruptions_GetDisruptionById
export def "disruptions-get-disruption-by-id" [
  disruption_id: int
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
  --qp-token: string # Please ignore (spec name: token)
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/disruptions/{disruption_id}"
    path_params: [{name: disruption_id, var: disruption_id}]
    query: [{name: token, var: qp_token}, {name: devid, var: devid}, {name: signature, var: signature}]
    accept: ["application/json", "text/html", "text/json"]
    ok: [200]
    auth: bearer
  } {
    disruption_id: $disruption_id, qp_token: $qp_token, devid: $devid, signature: $signature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Estimate a fare by zone
#
# GET /v3/fare_estimate/min_zone/{minZone}/max_zone/{maxZone}
# operationId: FareEstimate_GetFareEstimateByZone
export def "fare-estimate-get-fare-estimate-by-zone" [
  min_zone: int
  max_zone: int
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
  --journey-touch-on-utc: string # JourneyTouchOnUtc in format yyyy-M-d h:m (e.g 2016-5-31 16:53). (format: date-time)
  --journey-touch-off-utc: string # JourneyTouchOffUtc in format yyyy-M-d h:m (e.g 2016-5-31 16:53). (format: date-time)
  --is-journey-in-free-tram-zone: oneof<nothing, bool>
  --travelled-route-types: list<int>
  --qp-token: string # Please ignore (spec name: token)
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> any {
  http-request {
    method: get
    path: "/v3/fare_estimate/min_zone/{minZone}/max_zone/{maxZone}"
    path_params: [{name: minZone, var: min_zone}, {name: maxZone, var: max_zone}]
    query: [{name: journey_touch_on_utc, var: journey_touch_on_utc}, {name: journey_touch_off_utc, var: journey_touch_off_utc}, {name: is_journey_in_free_tram_zone, var: is_journey_in_free_tram_zone}, {name: travelled_route_types, var: travelled_route_types, style: multi}, {name: token, var: qp_token}, {name: devid, var: devid}, {name: signature, var: signature}]
    accept: ["application/json", "text/html", "text/json"]
    ok: [200]
    auth: bearer
  } {
    min_zone: $min_zone, max_zone: $max_zone, journey_touch_on_utc: $journey_touch_on_utc, journey_touch_off_utc: $journey_touch_off_utc, is_journey_in_free_tram_zone: $is_journey_in_free_tram_zone, travelled_route_types: $travelled_route_types, qp_token: $qp_token, devid: $devid, signature: $signature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all ticket outlets
#
# GET /v3/outlets
# Returns: record<outlets: table<outlet_business: string, outlet_business_hour_fri: string, outlet_business_hour_mon: string, outlet_business_hour_sat: string, outlet_business_hour_sun: string, outlet_business_hour_thur: string, outlet_business_hour_tue: string, outlet_business_hour_wed: string, outlet_latitude: float, outlet_longitude: float, outlet_name: string, outlet_notes: string, outlet_postcode: int, outlet_slid_spid: string, outlet_suburb: string>, status: record<health: int, version: string>>
# operationId: Outlets_GetAllOutlets
export def "outlets-get-all-outlets" [
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
  --max-results: int # Maximum number of results returned (default = 30) (format: int32)
  --qp-token: string # Please ignore (spec name: token)
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/outlets"
    query: [{name: max_results, var: max_results}, {name: token, var: qp_token}, {name: devid, var: devid}, {name: signature, var: signature}]
    accept: ["application/json", "text/html", "text/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, qp_token: $qp_token, devid: $devid, signature: $signature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List ticket outlets near a specific location
#
# GET /v3/outlets/location/{latitude},{longitude}
# Returns: record<outlets: table<outlet_business: string, outlet_business_hour_fri: string, outlet_business_hour_mon: string, outlet_business_hour_sat: string, outlet_business_hour_sun: string, outlet_business_hour_thur: string, outlet_business_hour_tue: string, outlet_business_hour_wed: string, outlet_distance: float, outlet_latitude: float, outlet_longitude: float, outlet_name: string, outlet_notes: string, outlet_postcode: int, outlet_slid_spid: string, outlet_suburb: string>, status: record<health: int, version: string>>
# operationId: Outlets_GetOutletsByGeolocation
export def "outlets-get-outlets-by-geolocation" [
  latitude: float
  longitude: float
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
  --max-distance: float # Filter by maximum distance (in metres) from location specified via latitude and longitude parameters (default = 300) (format: double)
  --max-results: int # Maximum number of results returned (default = 30) (format: int32)
  --qp-token: string # Please ignore (spec name: token)
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/outlets/location/{latitude},{longitude}"
    path_params: [{name: latitude, var: latitude}, {name: longitude, var: longitude}]
    query: [{name: max_distance, var: max_distance}, {name: max_results, var: max_results}, {name: token, var: qp_token}, {name: devid, var: devid}, {name: signature, var: signature}]
    accept: ["application/json", "text/html", "text/json"]
    ok: [200]
    auth: bearer
  } {
    latitude: $latitude, longitude: $longitude, max_distance: $max_distance, max_results: $max_results, qp_token: $qp_token, devid: $devid, signature: $signature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# View the stopping pattern for a specific trip/service run
#
# GET /v3/pattern/run/{run_ref}/route_type/{route_type}
# Returns: record<departures: table<at_platform: bool, departure_sequence: int, direction_id: int, disruption_ids: list, estimated_departure_utc: string, flags: string, platform_number: string, route_id: int, run_id: int, run_ref: string, scheduled_departure_utc: string, skipped_stops: list, stop_id: int>, directions: record, disruptions: table<colour: string, description: string, display_on_board: bool, display_status: bool, disruption_id: int, disruption_status: string, disruption_type: string, from_date: string, last_updated: string, published_on: string, routes: list, stops: list, title: string, to_date: string, url: string>, routes: record, runs: record, status: record<health: int, version: string>, stops: record>
# operationId: Patterns_GetPatternByRun
export def "patterns-get-pattern-by-run" [
  run_ref: string
  route_type: int@route-type-completer
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
  --expand: list<string> # List of objects to be returned in full (i.e. expanded) - options include: All, Stop, Route, Run, Direction, Disruption, VehiclePosition, VehicleDescriptor and None. Default is Disruption. Run must be expanded to receive VehiclePosition and VehicleDescriptor information. (required)
  --stop-id: int # Filter by stop_id; values returned by Stops API (format: int32)
  --date-utc: string # Filter by the date and time of the request (ISO 8601 UTC format) (format: date-time)
  --include-skipped-stops: oneof<nothing, bool> # Include any skipped stops in a stopping pattern. Defaults to false.
  --include-geopath: oneof<nothing, bool> # Indicates if geopath data will be returned (default = false)
  --qp-token: string # Please ignore (spec name: token)
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/pattern/run/{run_ref}/route_type/{route_type}"
    path_params: [{name: run_ref, var: run_ref}, {name: route_type, var: route_type}]
    query: [{name: expand, var: expand, style: multi, required: true}, {name: stop_id, var: stop_id}, {name: date_utc, var: date_utc}, {name: include_skipped_stops, var: include_skipped_stops}, {name: include_geopath, var: include_geopath}, {name: token, var: qp_token}, {name: devid, var: devid}, {name: signature, var: signature}]
    accept: ["application/json", "text/html", "text/json"]
    ok: [200]
    auth: bearer
  } {
    run_ref: $run_ref, route_type: $route_type, expand: $expand, stop_id: $stop_id, date_utc: $date_utc, include_skipped_stops: $include_skipped_stops, include_geopath: $include_geopath, qp_token: $qp_token, devid: $devid, signature: $signature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# View all route types and their names
#
# GET /v3/route_types
# Returns: record<route_types: table<route_type: int, route_type_name: string>, status: record<health: int, version: string>>
# operationId: RouteTypes_GetRouteTypes
export def "route-types-get-route-types" [
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
  --qp-token: string # Please ignore (spec name: token)
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/route_types"
    query: [{name: token, var: qp_token}, {name: devid, var: devid}, {name: signature, var: signature}]
    accept: ["application/json", "text/html", "text/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, devid: $devid, signature: $signature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# View route names and numbers for all routes
#
# GET /v3/routes
# Returns: record<route: record, status: record<health: int, version: string>>
# operationId: Routes_OneOrMoreRoutes
export def "routes-one-or-more-routes" [
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
  --route-types: list<int> # Filter by route_type; values returned via RouteTypes API
  --route-name: string # Filter by name of route (accepts partial route name matches)
  --qp-token: string # Please ignore (spec name: token)
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/routes"
    query: [{name: route_types, var: route_types, style: multi}, {name: route_name, var: route_name}, {name: token, var: qp_token}, {name: devid, var: devid}, {name: signature, var: signature}]
    accept: ["application/json", "text/html", "text/json"]
    ok: [200]
    auth: bearer
  } {
    route_types: $route_types, route_name: $route_name, qp_token: $qp_token, devid: $devid, signature: $signature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# View route name and number for specific route ID
#
# GET /v3/routes/{route_id}
# Returns: record<route: record, status: record<health: int, version: string>>
# operationId: Routes_RouteFromId
export def "routes-route-from-id" [
  route_id: int
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
  --include-geopath: oneof<nothing, bool> # Indicates kif geopath data will be returned (default = false)
  --geopath-utc: string # Filter geopaths by date (ISO 8601 UTC format) (default = current date) (format: date-time)
  --qp-token: string # Please ignore (spec name: token)
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/routes/{route_id}"
    path_params: [{name: route_id, var: route_id}]
    query: [{name: include_geopath, var: include_geopath}, {name: geopath_utc, var: geopath_utc}, {name: token, var: qp_token}, {name: devid, var: devid}, {name: signature, var: signature}]
    accept: ["application/json", "text/html", "text/json"]
    ok: [200]
    auth: bearer
  } {
    route_id: $route_id, include_geopath: $include_geopath, geopath_utc: $geopath_utc, qp_token: $qp_token, devid: $devid, signature: $signature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# View all trip/service runs for a specific route ID
#
# GET /v3/runs/route/{route_id}
# Returns: record<runs: table<destination_name: string, direction_id: int, express_stop_count: int, final_stop_id: int, geopath: list, route_id: int, route_type: int, run_id: int, run_ref: string, run_sequence: int, status: string, vehicle_descriptor: record, vehicle_position: record>, status: record<health: int, version: string>>
# operationId: Runs_ForRoute
export def "runs-for-route" [
  route_id: int
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
  --expand: list<string> # List of objects to be returned in full (i.e. expanded) - options include: All, VehiclePosition, VehicleDescriptor, or None. Default is None.
  --date-utc: string # Date of the request. (optional - defaults to now) (format: date-time)
  --qp-token: string # Please ignore (spec name: token)
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/runs/route/{route_id}"
    path_params: [{name: route_id, var: route_id}]
    query: [{name: expand, var: expand, style: multi}, {name: date_utc, var: date_utc}, {name: token, var: qp_token}, {name: devid, var: devid}, {name: signature, var: signature}]
    accept: ["application/json", "text/html", "text/json"]
    ok: [200]
    auth: bearer
  } {
    route_id: $route_id, expand: $expand, date_utc: $date_utc, qp_token: $qp_token, devid: $devid, signature: $signature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# View all trip/service runs for a specific route ID and route type
#
# GET /v3/runs/route/{route_id}/route_type/{route_type}
# Returns: record<runs: table<destination_name: string, direction_id: int, express_stop_count: int, final_stop_id: int, geopath: list, route_id: int, route_type: int, run_id: int, run_ref: string, run_sequence: int, status: string, vehicle_descriptor: record, vehicle_position: record>, status: record<health: int, version: string>>
# operationId: Runs_ForRouteAndRouteType
export def "runs-for-route-and-route-type" [
  route_id: int
  route_type: int@route-type-completer
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
  --expand: list<string> # List of objects to be returned in full (i.e. expanded) - options include: All, VehiclePosition, VehicleDescriptor, or None. Default is All. (required)
  --date-utc: string # Date of the request. (optional - defaults to now) (format: date-time)
  --qp-token: string # Please ignore (spec name: token)
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/runs/route/{route_id}/route_type/{route_type}"
    path_params: [{name: route_id, var: route_id}, {name: route_type, var: route_type}]
    query: [{name: expand, var: expand, style: multi, required: true}, {name: date_utc, var: date_utc}, {name: token, var: qp_token}, {name: devid, var: devid}, {name: signature, var: signature}]
    accept: ["application/json", "text/html", "text/json"]
    ok: [200]
    auth: bearer
  } {
    route_id: $route_id, route_type: $route_type, expand: $expand, date_utc: $date_utc, qp_token: $qp_token, devid: $devid, signature: $signature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# View all trip/service runs for a specific run_ref
#
# GET /v3/runs/{run_ref}
# Returns: record<runs: table<destination_name: string, direction_id: int, express_stop_count: int, final_stop_id: int, geopath: list, route_id: int, route_type: int, run_id: int, run_ref: string, run_sequence: int, status: string, vehicle_descriptor: record, vehicle_position: record>, status: record<health: int, version: string>>
# operationId: Runs_ForRun
export def "runs-for-run" [
  run_ref: string
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
  --expand: list<string> # List of objects to be returned in full (i.e. expanded) - options include: All, VehiclePosition, VehicleDescriptor, or None. Default is None. (required)
  --date-utc: string # Date of the request. (optional - defaults to now) (format: date-time)
  --include-geopath: oneof<nothing, bool> # Indicates if geopath data will be returned (default = false)
  --qp-token: string # Please ignore (spec name: token)
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/runs/{run_ref}"
    path_params: [{name: run_ref, var: run_ref}]
    query: [{name: expand, var: expand, style: multi, required: true}, {name: date_utc, var: date_utc}, {name: include_geopath, var: include_geopath}, {name: token, var: qp_token}, {name: devid, var: devid}, {name: signature, var: signature}]
    accept: ["application/json", "text/html", "text/json"]
    ok: [200]
    auth: bearer
  } {
    run_ref: $run_ref, expand: $expand, date_utc: $date_utc, include_geopath: $include_geopath, qp_token: $qp_token, devid: $devid, signature: $signature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# View the trip/service run for a specific run_ref and route type
#
# GET /v3/runs/{run_ref}/route_type/{route_type}
# Returns: record<run: record<destination_name: string, direction_id: int, express_stop_count: int, final_stop_id: int, geopath: list<record>, route_id: int, route_type: int, run_id: int, run_ref: string, run_sequence: int, status: string, vehicle_descriptor: record<air_conditioned: bool, description: string, id: string, length: string, low_floor: bool, operator: string, supplier: string>, vehicle_position: record<bearing: float, datetime_utc: string, direction: string, easting: float, expiry_time: string, latitude: float, longitude: float, northing: float, supplier: string>>, status: record<health: int, version: string>>
# operationId: Runs_ForRunAndRouteType
export def "runs-for-run-and-route-type" [
  run_ref: string
  route_type: int@route-type-completer
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
  --expand: list<string> # List of objects to be returned in full (i.e. expanded) - options include: All, VehiclePosition, VehicleDescriptor, or None. Default is None. (required)
  --date-utc: string # Date of the request. (optional - defaults to now) (format: date-time)
  --include-geopath: oneof<nothing, bool> # Indicates if geopath data will be returned (default = false)
  --qp-token: string # Please ignore (spec name: token)
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/runs/{run_ref}/route_type/{route_type}"
    path_params: [{name: run_ref, var: run_ref}, {name: route_type, var: route_type}]
    query: [{name: expand, var: expand, style: multi, required: true}, {name: date_utc, var: date_utc}, {name: include_geopath, var: include_geopath}, {name: token, var: qp_token}, {name: devid, var: devid}, {name: signature, var: signature}]
    accept: ["application/json", "text/html", "text/json"]
    ok: [200]
    auth: bearer
  } {
    run_ref: $run_ref, route_type: $route_type, expand: $expand, date_utc: $date_utc, include_geopath: $include_geopath, qp_token: $qp_token, devid: $devid, signature: $signature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# View stops, routes and myki ticket outlets that match the search term
#
# GET /v3/search/{search_term}
# Returns: record<outlets: table<outlet_business: string, outlet_business_hour_fri: string, outlet_business_hour_mon: string, outlet_business_hour_sat: string, outlet_business_hour_sun: string, outlet_business_hour_thur: string, outlet_business_hour_tue: string, outlet_business_hour_wed: string, outlet_distance: float, outlet_latitude: float, outlet_longitude: float, outlet_name: string, outlet_notes: string, outlet_postcode: int, outlet_slid_spid: string, outlet_suburb: string>, routes: table<route_gtfs_id: string, route_id: int, route_name: string, route_number: string, route_service_status: record, route_type: int>, status: record<health: int, version: string>, stops: table<route_type: int, routes: list, stop_distance: float, stop_id: int, stop_landmark: string, stop_latitude: float, stop_longitude: float, stop_name: string, stop_sequence: int, stop_suburb: string>>
# operationId: Search_Search
export def "search-search" [
  search_term: string
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
  --route-types: list<int> # Filter by route_type; values returned via RouteTypes API (note: stops and routes are ordered by route_types specified)
  --latitude: float # Filter by geographic coordinate of latitude (format: float)
  --longitude: float # Filter by geographic coordinate of longitude (format: float)
  --max-distance: float # Filter by maximum distance (in metres) from location specified via latitude and longitude parameters (format: float)
  --include-addresses: oneof<nothing, bool> # Placeholder for future development; currently unavailable
  --include-outlets: oneof<nothing, bool> # Indicates if outlets will be returned in response (default = true)
  --match-stop-by-suburb: oneof<nothing, bool> # Indicates whether to find stops by suburbs in the search term (default = true)
  --match-route-by-suburb: oneof<nothing, bool> # Indicates whether to find routes by suburbs in the search term (default = true)
  --match-stop-by-gtfs-stop-id: oneof<nothing, bool> # Indicates whether to search for stops according to a metlink stop ID (default = false)
  --qp-token: string # Please ignore (spec name: token)
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/search/{search_term}"
    path_params: [{name: search_term, var: search_term}]
    query: [{name: route_types, var: route_types, style: multi}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: max_distance, var: max_distance}, {name: include_addresses, var: include_addresses}, {name: include_outlets, var: include_outlets}, {name: match_stop_by_suburb, var: match_stop_by_suburb}, {name: match_route_by_suburb, var: match_route_by_suburb}, {name: match_stop_by_gtfs_stop_id, var: match_stop_by_gtfs_stop_id}, {name: token, var: qp_token}, {name: devid, var: devid}, {name: signature, var: signature}]
    accept: ["application/json", "text/html", "text/json"]
    ok: [200]
    auth: bearer
  } {
    search_term: $search_term, route_types: $route_types, latitude: $latitude, longitude: $longitude, max_distance: $max_distance, include_addresses: $include_addresses, include_outlets: $include_outlets, match_stop_by_suburb: $match_stop_by_suburb, match_route_by_suburb: $match_route_by_suburb, match_stop_by_gtfs_stop_id: $match_stop_by_gtfs_stop_id, qp_token: $qp_token, devid: $devid, signature: $signature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# View all stops near a specific location
#
# GET /v3/stops/location/{latitude},{longitude}
# Returns: record<disruptions: record, status: record<health: int, version: string>, stops: table<disruption_ids: list, route_type: int, routes: list, stop_distance: float, stop_id: int, stop_landmark: string, stop_latitude: float, stop_longitude: float, stop_name: string, stop_sequence: int, stop_suburb: string>>
# operationId: Stops_StopsByGeolocation
export def "stops-stops-by-geolocation" [
  latitude: float
  longitude: float
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
  --route-types: list<int> # Filter by route_type; values returned via RouteTypes API
  --max-results: int # Maximum number of results returned (default = 30) (format: int32)
  --max-distance: float # Filter by maximum distance (in metres) from location specified via latitude and longitude parameters (default = 300) (format: double)
  --stop-disruptions: oneof<nothing, bool> # Indicates if stop disruption information will be returned (default = false)
  --qp-token: string # Please ignore (spec name: token)
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/stops/location/{latitude},{longitude}"
    path_params: [{name: latitude, var: latitude}, {name: longitude, var: longitude}]
    query: [{name: route_types, var: route_types, style: multi}, {name: max_results, var: max_results}, {name: max_distance, var: max_distance}, {name: stop_disruptions, var: stop_disruptions}, {name: token, var: qp_token}, {name: devid, var: devid}, {name: signature, var: signature}]
    accept: ["application/json", "text/html", "text/json"]
    ok: [200]
    auth: bearer
  } {
    latitude: $latitude, longitude: $longitude, route_types: $route_types, max_results: $max_results, max_distance: $max_distance, stop_disruptions: $stop_disruptions, qp_token: $qp_token, devid: $devid, signature: $signature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# View all stops on a specific route
#
# GET /v3/stops/route/{route_id}/route_type/{route_type}
# Returns: record<disruptions: record, geopath: list<record>, status: record<health: int, version: string>, stops: table<disruption_ids: list, route_type: int, stop_id: int, stop_landmark: string, stop_latitude: float, stop_longitude: float, stop_name: string, stop_sequence: int, stop_suburb: string, stop_ticket: record>>
# operationId: Stops_StopsForRoute
export def "stops-stops-for-route" [
  route_id: int
  route_type: int@route-type-completer
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
  --direction-id: int # An optional direction; values returned by Directions API. When this is set, stop sequence information is returned in the response. (format: int32)
  --stop-disruptions: oneof<nothing, bool> # Indicates if stop disruption information will be returned (default = false)
  --include-geopath: oneof<nothing, bool> # Indicates if geopath data will be returned (default = false)
  --geopath-utc: string # Filter geopaths by date (ISO 8601 UTC format) (default = current date) (format: date-time)
  --qp-token: string # Please ignore (spec name: token)
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/stops/route/{route_id}/route_type/{route_type}"
    path_params: [{name: route_id, var: route_id}, {name: route_type, var: route_type}]
    query: [{name: direction_id, var: direction_id}, {name: stop_disruptions, var: stop_disruptions}, {name: include_geopath, var: include_geopath}, {name: geopath_utc, var: geopath_utc}, {name: token, var: qp_token}, {name: devid, var: devid}, {name: signature, var: signature}]
    accept: ["application/json", "text/html", "text/json"]
    ok: [200]
    auth: bearer
  } {
    route_id: $route_id, route_type: $route_type, direction_id: $direction_id, stop_disruptions: $stop_disruptions, include_geopath: $include_geopath, geopath_utc: $geopath_utc, qp_token: $qp_token, devid: $devid, signature: $signature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# View facilities at a specific stop (Metro and V/Line stations only)
#
# GET /v3/stops/{stop_id}/route_type/{route_type}
# Returns: record<disruptions: record, status: record<health: int, version: string>, stop: record<disruption_ids: list<int>, route_type: int, routes: list<record>, station_description: string, station_type: string, stop_accessibility: record<audio_customer_information: bool, escalator: bool, hearing_loop: bool, lift: bool, lighting: bool, platform_number: int, stairs: bool, stop_accessible: bool, tactile_ground_surface_indicator: bool, waiting_room: bool, wheelchair: record>, stop_amenities: record<car_parking: string, cctv: bool, taxi_rank: bool, toilet: bool>, stop_id: int, stop_landmark: string, stop_location: record<gps: record>, stop_name: string, stop_staffing: record<fri_am_from: string, fri_am_to: string, fri_pm_from: string, fri_pm_to: string, mon_am_from: string, mon_am_to: string, mon_pm_from: string, mon_pm_to: string, ph_additional_text: string, ph_from: string, ph_to: string, sat_am_from: string, sat_am_to: string, sat_pm_from: string, sat_pm_to: string, sun_am_from: string, sun_am_to: string, sun_pm_from: string, sun_pm_to: string, thu_am_from: string, thu_am_to: string, thu_pm_from: string, thu_pm_to: string, tue_am_from: string, tue_am_to: string, tue_pm_from: string, tue_pm_to: string, wed_am_from: string, wed_am_to: string, wed_pm_To: string, wed_pm_from: string>>>
# operationId: Stops_StopDetails
export def "stops-stop-details" [
  stop_id: int
  route_type: int@route-type-completer
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
  --stop-location: oneof<nothing, bool> # Indicates if stop location information will be returned (default = false)
  --stop-amenities: oneof<nothing, bool> # Indicates if stop amenity information will be returned (default = false)
  --stop-accessibility: oneof<nothing, bool> # Indicates if stop accessibility information will be returned (default = false)
  --stop-contact: oneof<nothing, bool> # Indicates if stop contact information will be returned (default = false)
  --stop-ticket: oneof<nothing, bool> # Indicates if stop ticket information will be returned (default = false)
  --gtfs: oneof<nothing, bool> # Incdicates whether the stop_id is a GTFS ID or not
  --stop-staffing: oneof<nothing, bool> # Indicates if stop staffing information will be returned (default = false)
  --stop-disruptions: oneof<nothing, bool> # Indicates if stop disruption information will be returned (default = false)
  --qp-token: string # Please ignore (spec name: token)
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/stops/{stop_id}/route_type/{route_type}"
    path_params: [{name: stop_id, var: stop_id}, {name: route_type, var: route_type}]
    query: [{name: stop_location, var: stop_location}, {name: stop_amenities, var: stop_amenities}, {name: stop_accessibility, var: stop_accessibility}, {name: stop_contact, var: stop_contact}, {name: stop_ticket, var: stop_ticket}, {name: gtfs, var: gtfs}, {name: stop_staffing, var: stop_staffing}, {name: stop_disruptions, var: stop_disruptions}, {name: token, var: qp_token}, {name: devid, var: devid}, {name: signature, var: signature}]
    accept: ["application/json", "text/html", "text/json"]
    ok: [200]
    auth: bearer
  } {
    stop_id: $stop_id, route_type: $route_type, stop_location: $stop_location, stop_amenities: $stop_amenities, stop_accessibility: $stop_accessibility, stop_contact: $stop_contact, stop_ticket: $stop_ticket, gtfs: $gtfs, stop_staffing: $stop_staffing, stop_disruptions: $stop_disruptions, qp_token: $qp_token, devid: $devid, signature: $signature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
