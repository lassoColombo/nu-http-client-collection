# Auto-generated client for Drive Labels API v2beta
# Source: https://api.apis.guru/v2/specs/googleapis.com/drivelabels/v2beta/openapi.json
# Auth: --token flag or $env.DRIVE_LABELS_API_TOKEN

const CLIENT = {
  base_url: "https://drivelabels.googleapis.com"
  token_env_var: "DRIVE_LABELS_API_TOKEN"
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

def base-url-completer [] { ["https://drivelabels.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def minimum-role-completer [] { ["APPLIER" "EDITOR" "LABEL_ROLE_UNSPECIFIED" "ORGANIZER" "READER"] }
def view-completer [] { ["LABEL_VIEW_BASIC" "LABEL_VIEW_FULL"] }
def label-type-completer [] { ["ADMIN" "LABEL_TYPE_UNSPECIFIED" "SHARED"] }
def copy-mode-completer [] { ["ALWAYS_COPY" "COPY_APPLIABLE" "COPY_MODE_UNSPECIFIED" "DO_NOT_COPY"] }
def role-completer [] { ["APPLIER" "EDITOR" "LABEL_ROLE_UNSPECIFIED" "ORGANIZER" "READER"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    drivelabels-labels-list: "record<labels: table<appliedCapabilities: record, appliedLabelPolicy: record, createTime: string, creator: record, customer: string, disableTime: string, disabler: record, displayHints: record, fields: list, id: string, labelType: string, learnMoreUri: string, lifecycle: record, lockStatus: record, name: string, properties: record, publishTime: string, publisher: record, revisionCreateTime: string, revisionCreator: record, revisionId: string, schemaCapabilities: record>, nextPageToken: string>"
    drivelabels-labels-create: "record<appliedCapabilities: record<canApply: bool, canRead: bool, canRemove: bool>, appliedLabelPolicy: record<copyMode: string>, createTime: string, creator: record<person: string>, customer: string, disableTime: string, disabler: record<person: string>, displayHints: record<disabled: bool, hiddenInSearch: bool, priority: string, shownInApply: bool>, fields: table<appliedCapabilities: record, createTime: string, creator: record, dateOptions: record, disableTime: string, disabler: record, displayHints: record, id: string, integerOptions: record, lifecycle: record, lockStatus: record, properties: record, publisher: record, queryKey: string, schemaCapabilities: record, selectionOptions: record, textOptions: record, updateTime: string, updater: record, userOptions: record>, id: string, labelType: string, learnMoreUri: string, lifecycle: record<disabledPolicy: record<hideInSearch: bool, showInApply: bool>, hasUnpublishedChanges: bool, state: string>, lockStatus: record<locked: bool>, name: string, properties: record<description: string, title: string>, publishTime: string, publisher: record<person: string>, revisionCreateTime: string, revisionCreator: record<person: string>, revisionId: string, schemaCapabilities: record<canDelete: bool, canDisable: bool, canEnable: bool, canUpdate: bool>>"
    drivelabels-limits-get-label: "record<fieldLimits: record<dateLimits: record<maxValue: record, minValue: record>, integerLimits: record<maxValue: string, minValue: string>, longTextLimits: record<maxLength: int, minLength: int>, maxDescriptionLength: int, maxDisplayNameLength: int, maxIdLength: int, selectionLimits: record<listLimits: record, maxChoices: int, maxDeletedChoices: int, maxDisplayNameLength: int, maxIdLength: int>, textLimits: record<maxLength: int, minLength: int>, userLimits: record<listLimits: record>>, maxDeletedFields: int, maxDescriptionLength: int, maxDraftRevisions: int, maxFields: int, maxTitleLength: int, name: string>"
    drivelabels-labels-revisions-permissions-delete: "record"
    drivelabels-users-get-capabilities: "record<canAccessLabelManager: bool, canAdministrateLabels: bool, canCreateAdminLabels: bool, canCreateSharedLabels: bool, name: string>"
    drivelabels-labels-delta: "record<responses: table<createField: record, createSelectionChoice: record, deleteField: record, deleteSelectionChoice: record, disableField: record, disableSelectionChoice: record, enableField: record, enableSelectionChoice: record, updateField: record, updateFieldType: record, updateLabel: record, updateSelectionChoiceProperties: record>, updatedLabel: record<appliedCapabilities: record<canApply: bool, canRead: bool, canRemove: bool>, appliedLabelPolicy: record<copyMode: string>, createTime: string, creator: record<person: string>, customer: string, disableTime: string, disabler: record<person: string>, displayHints: record<disabled: bool, hiddenInSearch: bool, priority: string, shownInApply: bool>, fields: list<record>, id: string, labelType: string, learnMoreUri: string, lifecycle: record<disabledPolicy: record, hasUnpublishedChanges: bool, state: string>, lockStatus: record<locked: bool>, name: string, properties: record<description: string, title: string>, publishTime: string, publisher: record<person: string>, revisionCreateTime: string, revisionCreator: record<person: string>, revisionId: string, schemaCapabilities: record<canDelete: bool, canDisable: bool, canEnable: bool, canUpdate: bool>>>"
    drivelabels-labels-disable: "record<appliedCapabilities: record<canApply: bool, canRead: bool, canRemove: bool>, appliedLabelPolicy: record<copyMode: string>, createTime: string, creator: record<person: string>, customer: string, disableTime: string, disabler: record<person: string>, displayHints: record<disabled: bool, hiddenInSearch: bool, priority: string, shownInApply: bool>, fields: table<appliedCapabilities: record, createTime: string, creator: record, dateOptions: record, disableTime: string, disabler: record, displayHints: record, id: string, integerOptions: record, lifecycle: record, lockStatus: record, properties: record, publisher: record, queryKey: string, schemaCapabilities: record, selectionOptions: record, textOptions: record, updateTime: string, updater: record, userOptions: record>, id: string, labelType: string, learnMoreUri: string, lifecycle: record<disabledPolicy: record<hideInSearch: bool, showInApply: bool>, hasUnpublishedChanges: bool, state: string>, lockStatus: record<locked: bool>, name: string, properties: record<description: string, title: string>, publishTime: string, publisher: record<person: string>, revisionCreateTime: string, revisionCreator: record<person: string>, revisionId: string, schemaCapabilities: record<canDelete: bool, canDisable: bool, canEnable: bool, canUpdate: bool>>"
    drivelabels-labels-enable: "record<appliedCapabilities: record<canApply: bool, canRead: bool, canRemove: bool>, appliedLabelPolicy: record<copyMode: string>, createTime: string, creator: record<person: string>, customer: string, disableTime: string, disabler: record<person: string>, displayHints: record<disabled: bool, hiddenInSearch: bool, priority: string, shownInApply: bool>, fields: table<appliedCapabilities: record, createTime: string, creator: record, dateOptions: record, disableTime: string, disabler: record, displayHints: record, id: string, integerOptions: record, lifecycle: record, lockStatus: record, properties: record, publisher: record, queryKey: string, schemaCapabilities: record, selectionOptions: record, textOptions: record, updateTime: string, updater: record, userOptions: record>, id: string, labelType: string, learnMoreUri: string, lifecycle: record<disabledPolicy: record<hideInSearch: bool, showInApply: bool>, hasUnpublishedChanges: bool, state: string>, lockStatus: record<locked: bool>, name: string, properties: record<description: string, title: string>, publishTime: string, publisher: record<person: string>, revisionCreateTime: string, revisionCreator: record<person: string>, revisionId: string, schemaCapabilities: record<canDelete: bool, canDisable: bool, canEnable: bool, canUpdate: bool>>"
    drivelabels-labels-publish: "record<appliedCapabilities: record<canApply: bool, canRead: bool, canRemove: bool>, appliedLabelPolicy: record<copyMode: string>, createTime: string, creator: record<person: string>, customer: string, disableTime: string, disabler: record<person: string>, displayHints: record<disabled: bool, hiddenInSearch: bool, priority: string, shownInApply: bool>, fields: table<appliedCapabilities: record, createTime: string, creator: record, dateOptions: record, disableTime: string, disabler: record, displayHints: record, id: string, integerOptions: record, lifecycle: record, lockStatus: record, properties: record, publisher: record, queryKey: string, schemaCapabilities: record, selectionOptions: record, textOptions: record, updateTime: string, updater: record, userOptions: record>, id: string, labelType: string, learnMoreUri: string, lifecycle: record<disabledPolicy: record<hideInSearch: bool, showInApply: bool>, hasUnpublishedChanges: bool, state: string>, lockStatus: record<locked: bool>, name: string, properties: record<description: string, title: string>, publishTime: string, publisher: record<person: string>, revisionCreateTime: string, revisionCreator: record<person: string>, revisionId: string, schemaCapabilities: record<canDelete: bool, canDisable: bool, canEnable: bool, canUpdate: bool>>"
    drivelabels-labels-update-label-copy-mode: "record<appliedCapabilities: record<canApply: bool, canRead: bool, canRemove: bool>, appliedLabelPolicy: record<copyMode: string>, createTime: string, creator: record<person: string>, customer: string, disableTime: string, disabler: record<person: string>, displayHints: record<disabled: bool, hiddenInSearch: bool, priority: string, shownInApply: bool>, fields: table<appliedCapabilities: record, createTime: string, creator: record, dateOptions: record, disableTime: string, disabler: record, displayHints: record, id: string, integerOptions: record, lifecycle: record, lockStatus: record, properties: record, publisher: record, queryKey: string, schemaCapabilities: record, selectionOptions: record, textOptions: record, updateTime: string, updater: record, userOptions: record>, id: string, labelType: string, learnMoreUri: string, lifecycle: record<disabledPolicy: record<hideInSearch: bool, showInApply: bool>, hasUnpublishedChanges: bool, state: string>, lockStatus: record<locked: bool>, name: string, properties: record<description: string, title: string>, publishTime: string, publisher: record<person: string>, revisionCreateTime: string, revisionCreator: record<person: string>, revisionId: string, schemaCapabilities: record<canDelete: bool, canDisable: bool, canEnable: bool, canUpdate: bool>>"
    drivelabels-labels-revisions-locks-list: "record<labelLocks: table<capabilities: record, choiceId: string, createTime: string, creator: record, deleteTime: string, fieldId: string, name: string, state: string>, nextPageToken: string>"
    drivelabels-labels-revisions-permissions-list: "record<labelPermissions: table<audience: string, email: string, group: string, name: string, person: string, role: string>, nextPageToken: string>"
    drivelabels-labels-revisions-update-permissions: "record<audience: string, email: string, group: string, name: string, person: string, role: string>"
    drivelabels-labels-revisions-permissions-create: "record<audience: string, email: string, group: string, name: string, person: string, role: string>"
    drivelabels-labels-revisions-permissions-batch-delete: "record"
    drivelabels-labels-revisions-permissions-batch-update: "record<permissions: table<audience: string, email: string, group: string, name: string, person: string, role: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["drivelabels-labels-list" "drivelabels-labels-create" "drivelabels-limits-get-label" "drivelabels-labels-revisions-permissions-delete" "drivelabels-users-get-capabilities" "drivelabels-labels-delta" "drivelabels-labels-disable" "drivelabels-labels-enable" "drivelabels-labels-publish" "drivelabels-labels-update-label-copy-mode" "drivelabels-labels-revisions-locks-list" "drivelabels-labels-revisions-permissions-list" "drivelabels-labels-revisions-update-permissions" "drivelabels-labels-revisions-permissions-create" "drivelabels-labels-revisions-permissions-batch-delete" "drivelabels-labels-revisions-permissions-batch-update" "commands"] | sort) } | get name | first)
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

# List labels.
#
# GET /v2beta/labels
# Returns: record<labels: table<appliedCapabilities: record, appliedLabelPolicy: record, createTime: string, creator: record, customer: string, disableTime: string, disabler: record, displayHints: record, fields: list, id: string, labelType: string, learnMoreUri: string, lifecycle: record, lockStatus: record, name: string, properties: record, publishTime: string, publisher: record, revisionCreateTime: string, revisionCreator: record, revisionId: string, schemaCapabilities: record>, nextPageToken: string>
# operationId: drivelabels.labels.list
export def "drivelabels-labels-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --customer: string # The customer to scope this list request to. For example: "customers/abcd1234". If unset, will return all labels within the current customer.
  --language-code: string # The BCP-47 language code to use for evaluating localized field labels. When not specified, values in the default configured language are used.
  --minimum-role: string@minimum-role-completer # Specifies the level of access the user must have on the returned Labels. The minimum role a user must have on a label. Defaults to `READER`.
  --page-size: int # Maximum number of labels to return per page. Default: 50. Max: 200.
  --page-token: string # The token of the page to return.
  --published-only: oneof<nothing, bool> # Whether to include only published labels in the results. * When `true`, only the current published label revisions are returned. Disabled labels are included. Returned label resource names reference the published revision (`labels/{id}/{revision_id}`). * When `false`, the current label revisions are returned, which might not be published. Returned label resource names don't reference a specific revision (`labels/{id}`).
  --use-admin-access: oneof<nothing, bool> # Set to `true` in order to use the user's admin credentials. This will return all Labels within the customer.
  --view: string@view-completer # When specified, only certain fields belonging to the indicated view are returned.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2beta/labels"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: customer, var: customer}, {name: languageCode, var: language_code}, {name: minimumRole, var: minimum_role}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: publishedOnly, var: published_only}, {name: useAdminAccess, var: use_admin_access}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, customer: $customer, language_code: $language_code, minimum_role: $minimum_role, page_size: $page_size, page_token: $page_token, published_only: $published_only, use_admin_access: $use_admin_access, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Label.
#
# POST /v2beta/labels
# Returns: record<appliedCapabilities: record<canApply: bool, canRead: bool, canRemove: bool>, appliedLabelPolicy: record<copyMode: string>, createTime: string, creator: record<person: string>, customer: string, disableTime: string, disabler: record<person: string>, displayHints: record<disabled: bool, hiddenInSearch: bool, priority: string, shownInApply: bool>, fields: table<appliedCapabilities: record, createTime: string, creator: record, dateOptions: record, disableTime: string, disabler: record, displayHints: record, id: string, integerOptions: record, lifecycle: record, lockStatus: record, properties: record, publisher: record, queryKey: string, schemaCapabilities: record, selectionOptions: record, textOptions: record, updateTime: string, updater: record, userOptions: record>, id: string, labelType: string, learnMoreUri: string, lifecycle: record<disabledPolicy: record<hideInSearch: bool, showInApply: bool>, hasUnpublishedChanges: bool, state: string>, lockStatus: record<locked: bool>, name: string, properties: record<description: string, title: string>, publishTime: string, publisher: record<person: string>, revisionCreateTime: string, revisionCreator: record<person: string>, revisionId: string, schemaCapabilities: record<canDelete: bool, canDisable: bool, canEnable: bool, canUpdate: bool>>
# operationId: drivelabels.labels.create
export def "drivelabels-labels-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --language-code: string # The BCP-47 language code to use for evaluating localized Field labels in response. When not specified, values in the default configured language will be used.
  --use-admin-access: oneof<nothing, bool> # Set to `true` in order to use the user's admin privileges. The server will verify the user is an admin before allowing access.
  --applied-capabilities: record # The capabilities a user has on this label's applied metadata. — shape: {canApply?: bool, canRead?: bool, canRemove?: bool}
  --applied-label-policy: record # Behavior of this label when it's applied to Drive items. — shape: {copyMode?: "COPY_MODE_UNSPECIFIED"|"DO_NOT_COPY"|"ALWAYS_COPY"|"COPY_APPLIABLE"}
  --creator: record # Information about a user. — shape: {person?: string}
  --disabler: record # Information about a user. — shape: {person?: string}
  --display-hints: record # UI display hints for rendering the label. — shape: {disabled?: bool, hiddenInSearch?: bool, priority?: string, shownInApply?: bool}
  --body-fields: list # List of fields in descending priority order. — item shape: {appliedCapabilities?: record, creator?: record, dateOptions?: record, disabler?: record, displayHints?: record, integerOptions?: record, lifecycle?: record, lockStatus?: record, properties?: record, publisher?: record, schemaCapabilities?: record, selectionOptions?: record, textOptions?: record, updater?: record, userOptions?: record} (spec name: fields)
  --label-type: string@label-type-completer # Required. The type of label.
  --learn-more-uri: string # Custom URL to present to users to allow them to learn more about this label and how it should be used.
  --lifecycle: record # The lifecycle state of an object, such as label, field, or choice. The lifecycle enforces the following transitions: * `UNPUBLISHED_DRAFT` (starting state) * `UNPUBLISHED_DRAFT` -> `PUBLISHED` * `UNPUBLISHED_DRAFT` -> (Deleted) * `PUBLISHED` -> `DISABLED` * `DISABLED` -> `PUBLISHED` * `DISABLED` -> (Deleted) The published and disabled states have some distinct characteristics: * Published—Some kinds of changes might be made to an object in this state, in which case `has_unpublished_changes` will be true. Also, some kinds of changes are not permitted. Generally, any change that would invalidate or cause new restrictions on existing metadata related to the label are rejected. * Disabled—When disabled, the configured `DisabledPolicy` takes effect. — shape: {disabledPolicy?: record}
  --lock-status: record # Contains information about whether a label component should be considered locked.
  --properties: record # Basic properties of the label. — shape: {description?: string, title?: string}
  --publisher: record # Information about a user. — shape: {person?: string}
  --revision-creator: record # Information about a user. — shape: {person?: string}
  --schema-capabilities: record # The capabilities related to this label when editing the label. — shape: {canDelete?: bool, canDisable?: bool, canEnable?: bool, canUpdate?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2beta/labels"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: languageCode, var: language_code}, {name: useAdminAccess, var: use_admin_access}]
    body: {content_type: "application/json", kind: json, fields: [{name: appliedCapabilities, var: applied_capabilities}, {name: appliedLabelPolicy, var: applied_label_policy}, {name: creator, var: creator}, {name: disabler, var: disabler}, {name: displayHints, var: display_hints}, {name: fields, var: body_fields}, {name: labelType, var: label_type}, {name: learnMoreUri, var: learn_more_uri}, {name: lifecycle, var: lifecycle}, {name: lockStatus, var: lock_status}, {name: properties, var: properties}, {name: publisher, var: publisher}, {name: revisionCreator, var: revision_creator}, {name: schemaCapabilities, var: schema_capabilities}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, language_code: $language_code, use_admin_access: $use_admin_access, applied_capabilities: $applied_capabilities, applied_label_policy: $applied_label_policy, creator: $creator, disabler: $disabler, display_hints: $display_hints, body_fields: $body_fields, label_type: $label_type, learn_more_uri: $learn_more_uri, lifecycle: $lifecycle, lock_status: $lock_status, properties: $properties, publisher: $publisher, revision_creator: $revision_creator, schema_capabilities: $schema_capabilities
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the constraints on the structure of a Label; such as, the maximum number of Fields allowed and maximum length of the label title.
#
# GET /v2beta/limits/label
# Returns: record<fieldLimits: record<dateLimits: record<maxValue: record, minValue: record>, integerLimits: record<maxValue: string, minValue: string>, longTextLimits: record<maxLength: int, minLength: int>, maxDescriptionLength: int, maxDisplayNameLength: int, maxIdLength: int, selectionLimits: record<listLimits: record, maxChoices: int, maxDeletedChoices: int, maxDisplayNameLength: int, maxIdLength: int>, textLimits: record<maxLength: int, minLength: int>, userLimits: record<listLimits: record>>, maxDeletedFields: int, maxDescriptionLength: int, maxDraftRevisions: int, maxFields: int, maxTitleLength: int, name: string>
# operationId: drivelabels.limits.getLabel
export def "drivelabels-limits-get-label" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --name: string # Required. Label revision resource name Must be: "limits/label"
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2beta/limits/label"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Label's permission. Permissions affect the Label resource as a whole, are not revisioned, and do not require publishing.
#
# DELETE /v2beta/{name}
# Returns: record
# operationId: drivelabels.labels.revisions.permissions.delete
export def "drivelabels-labels-revisions-permissions-delete" [
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
  --use-admin-access: oneof<nothing, bool> # Set to `true` in order to use the user's admin credentials. The server will verify the user is an admin for the Label before allowing access.
  --write-control-required-revision-id: string # The revision_id of the label that the write request will be applied to. If this is not the latest revision of the label, the request will not be processed and will return a 400 Bad Request error.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v2beta/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: useAdminAccess, var: use_admin_access}, {name: "writeControl.requiredRevisionId", var: write_control_required_revision_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, use_admin_access: $use_admin_access, write_control_required_revision_id: $write_control_required_revision_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the user capabilities.
#
# GET /v2beta/{name}
# Returns: record<canAccessLabelManager: bool, canAdministrateLabels: bool, canCreateAdminLabels: bool, canCreateSharedLabels: bool, name: string>
# operationId: drivelabels.users.getCapabilities
export def "drivelabels-users-get-capabilities" [
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
  --customer: string # The customer to scope this request to. For example: "customers/abcd1234". If unset, will return settings within the current customer.
  --use-admin-access: oneof<nothing, bool> # Set to `true` in order to use the user's admin credentials. The server verifies that the user is an admin for the label before allowing access.
  --view: string@view-completer # When specified, only certain fields belonging to the indicated view are returned.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2beta/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: customer, var: customer}, {name: useAdminAccess, var: use_admin_access}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, customer: $customer, use_admin_access: $use_admin_access, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a single Label by applying a set of update requests resulting in a new draft revision. The batch update is all-or-nothing: If any of the update requests are invalid, no changes are applied. The resulting draft revision must be published before the changes may be used with Drive Items.
#
# POST /v2beta/{name}:delta
# Returns: record<responses: table<createField: record, createSelectionChoice: record, deleteField: record, deleteSelectionChoice: record, disableField: record, disableSelectionChoice: record, enableField: record, enableSelectionChoice: record, updateField: record, updateFieldType: record, updateLabel: record, updateSelectionChoiceProperties: record>, updatedLabel: record<appliedCapabilities: record<canApply: bool, canRead: bool, canRemove: bool>, appliedLabelPolicy: record<copyMode: string>, createTime: string, creator: record<person: string>, customer: string, disableTime: string, disabler: record<person: string>, displayHints: record<disabled: bool, hiddenInSearch: bool, priority: string, shownInApply: bool>, fields: list<record>, id: string, labelType: string, learnMoreUri: string, lifecycle: record<disabledPolicy: record, hasUnpublishedChanges: bool, state: string>, lockStatus: record<locked: bool>, name: string, properties: record<description: string, title: string>, publishTime: string, publisher: record<person: string>, revisionCreateTime: string, revisionCreator: record<person: string>, revisionId: string, schemaCapabilities: record<canDelete: bool, canDisable: bool, canEnable: bool, canUpdate: bool>>>
# operationId: drivelabels.labels.delta
export def "drivelabels-labels-delta" [
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
  --language-code: string # The BCP-47 language code to use for evaluating localized Field labels when `include_label_in_response` is `true`.
  --requests: list # A list of updates to apply to the Label. Requests will be applied in the order they are specified. — item shape: {createField?: record, createSelectionChoice?: record, deleteField?: record, deleteSelectionChoice?: record, disableField?: record, disableSelectionChoice?: record, enableField?: record, enableSelectionChoice?: record, updateField?: record, updateFieldType?: record, updateLabel?: record, updateSelectionChoiceProperties?: record}
  --use-admin-access: oneof<nothing, bool> # Set to `true` in order to use the user's admin credentials. The server will verify the user is an admin for the Label before allowing access.
  --view: string@view-completer # When specified, only certain fields belonging to the indicated view will be returned.
  --write-control: record # Provides control over how write requests are executed. When not specified, the last write wins. — shape: {requiredRevisionId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2beta/{name}:delta"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: languageCode, var: language_code}, {name: requests, var: requests}, {name: useAdminAccess, var: use_admin_access}, {name: view, var: view}, {name: writeControl, var: write_control}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, language_code: $language_code, requests: $requests, use_admin_access: $use_admin_access, view: $view, write_control: $write_control
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable a published Label. Disabling a Label will result in a new disabled published revision based on the current published revision. If there is a draft revision, a new disabled draft revision will be created based on the latest draft revision. Older draft revisions will be deleted. Once disabled, a label may be deleted with `DeleteLabel`.
#
# POST /v2beta/{name}:disable
# Returns: record<appliedCapabilities: record<canApply: bool, canRead: bool, canRemove: bool>, appliedLabelPolicy: record<copyMode: string>, createTime: string, creator: record<person: string>, customer: string, disableTime: string, disabler: record<person: string>, displayHints: record<disabled: bool, hiddenInSearch: bool, priority: string, shownInApply: bool>, fields: table<appliedCapabilities: record, createTime: string, creator: record, dateOptions: record, disableTime: string, disabler: record, displayHints: record, id: string, integerOptions: record, lifecycle: record, lockStatus: record, properties: record, publisher: record, queryKey: string, schemaCapabilities: record, selectionOptions: record, textOptions: record, updateTime: string, updater: record, userOptions: record>, id: string, labelType: string, learnMoreUri: string, lifecycle: record<disabledPolicy: record<hideInSearch: bool, showInApply: bool>, hasUnpublishedChanges: bool, state: string>, lockStatus: record<locked: bool>, name: string, properties: record<description: string, title: string>, publishTime: string, publisher: record<person: string>, revisionCreateTime: string, revisionCreator: record<person: string>, revisionId: string, schemaCapabilities: record<canDelete: bool, canDisable: bool, canEnable: bool, canUpdate: bool>>
# operationId: drivelabels.labels.disable
export def "drivelabels-labels-disable" [
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
  --disabled-policy: record # The policy that governs how to treat a disabled label, field, or selection choice in different contexts. — shape: {hideInSearch?: bool, showInApply?: bool}
  --language-code: string # The BCP-47 language code to use for evaluating localized field labels. When not specified, values in the default configured language will be used.
  --update-mask: string # The fields that should be updated. At least one field must be specified. The root `disabled_policy` is implied and should not be specified. A single `*` can be used as short-hand for updating every field. (format: google-fieldmask)
  --use-admin-access: oneof<nothing, bool> # Set to `true` in order to use the user's admin credentials. The server will verify the user is an admin for the Label before allowing access.
  --write-control: record # Provides control over how write requests are executed. When not specified, the last write wins. — shape: {requiredRevisionId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2beta/{name}:disable"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: disabledPolicy, var: disabled_policy}, {name: languageCode, var: language_code}, {name: updateMask, var: update_mask}, {name: useAdminAccess, var: use_admin_access}, {name: writeControl, var: write_control}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, disabled_policy: $disabled_policy, language_code: $language_code, update_mask: $update_mask, use_admin_access: $use_admin_access, write_control: $write_control
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable a disabled Label and restore it to its published state. This will result in a new published revision based on the current disabled published revision. If there is an existing disabled draft revision, a new revision will be created based on that draft and will be enabled.
#
# POST /v2beta/{name}:enable
# Returns: record<appliedCapabilities: record<canApply: bool, canRead: bool, canRemove: bool>, appliedLabelPolicy: record<copyMode: string>, createTime: string, creator: record<person: string>, customer: string, disableTime: string, disabler: record<person: string>, displayHints: record<disabled: bool, hiddenInSearch: bool, priority: string, shownInApply: bool>, fields: table<appliedCapabilities: record, createTime: string, creator: record, dateOptions: record, disableTime: string, disabler: record, displayHints: record, id: string, integerOptions: record, lifecycle: record, lockStatus: record, properties: record, publisher: record, queryKey: string, schemaCapabilities: record, selectionOptions: record, textOptions: record, updateTime: string, updater: record, userOptions: record>, id: string, labelType: string, learnMoreUri: string, lifecycle: record<disabledPolicy: record<hideInSearch: bool, showInApply: bool>, hasUnpublishedChanges: bool, state: string>, lockStatus: record<locked: bool>, name: string, properties: record<description: string, title: string>, publishTime: string, publisher: record<person: string>, revisionCreateTime: string, revisionCreator: record<person: string>, revisionId: string, schemaCapabilities: record<canDelete: bool, canDisable: bool, canEnable: bool, canUpdate: bool>>
# operationId: drivelabels.labels.enable
export def "drivelabels-labels-enable" [
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
  --language-code: string # The BCP-47 language code to use for evaluating localized field labels. When not specified, values in the default configured language will be used.
  --use-admin-access: oneof<nothing, bool> # Set to `true` in order to use the user's admin credentials. The server will verify the user is an admin for the Label before allowing access.
  --write-control: record # Provides control over how write requests are executed. When not specified, the last write wins. — shape: {requiredRevisionId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2beta/{name}:enable"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: languageCode, var: language_code}, {name: useAdminAccess, var: use_admin_access}, {name: writeControl, var: write_control}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, language_code: $language_code, use_admin_access: $use_admin_access, write_control: $write_control
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Publish all draft changes to the Label. Once published, the Label may not return to its draft state. See `google.apps.drive.labels.v2.Lifecycle` for more information. Publishing a Label will result in a new published revision. All previous draft revisions will be deleted. Previous published revisions will be kept but are subject to automated deletion as needed. Once published, some changes are no longer permitted. Generally, any change that would invalidate or cause new restrictions on existing metadata related to the Label will be rejected. For example, the following changes to a Label will be rejected after the Label is published: * The label cannot be directly deleted. It must be disabled first, then deleted. * Field.FieldType cannot be changed. * Changes to Field validation options cannot reject something that was previously accepted. * Reducing the max entries.
#
# POST /v2beta/{name}:publish
# Returns: record<appliedCapabilities: record<canApply: bool, canRead: bool, canRemove: bool>, appliedLabelPolicy: record<copyMode: string>, createTime: string, creator: record<person: string>, customer: string, disableTime: string, disabler: record<person: string>, displayHints: record<disabled: bool, hiddenInSearch: bool, priority: string, shownInApply: bool>, fields: table<appliedCapabilities: record, createTime: string, creator: record, dateOptions: record, disableTime: string, disabler: record, displayHints: record, id: string, integerOptions: record, lifecycle: record, lockStatus: record, properties: record, publisher: record, queryKey: string, schemaCapabilities: record, selectionOptions: record, textOptions: record, updateTime: string, updater: record, userOptions: record>, id: string, labelType: string, learnMoreUri: string, lifecycle: record<disabledPolicy: record<hideInSearch: bool, showInApply: bool>, hasUnpublishedChanges: bool, state: string>, lockStatus: record<locked: bool>, name: string, properties: record<description: string, title: string>, publishTime: string, publisher: record<person: string>, revisionCreateTime: string, revisionCreator: record<person: string>, revisionId: string, schemaCapabilities: record<canDelete: bool, canDisable: bool, canEnable: bool, canUpdate: bool>>
# operationId: drivelabels.labels.publish
export def "drivelabels-labels-publish" [
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
  --language-code: string # The BCP-47 language code to use for evaluating localized field labels. When not specified, values in the default configured language will be used.
  --use-admin-access: oneof<nothing, bool> # Set to `true` in order to use the user's admin credentials. The server will verify the user is an admin for the Label before allowing access.
  --write-control: record # Provides control over how write requests are executed. When not specified, the last write wins. — shape: {requiredRevisionId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2beta/{name}:publish"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: languageCode, var: language_code}, {name: useAdminAccess, var: use_admin_access}, {name: writeControl, var: write_control}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, language_code: $language_code, use_admin_access: $use_admin_access, write_control: $write_control
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a Label's `CopyMode`. Changes to this policy are not revisioned, do not require publishing, and take effect immediately.
#
# POST /v2beta/{name}:updateLabelCopyMode
# Returns: record<appliedCapabilities: record<canApply: bool, canRead: bool, canRemove: bool>, appliedLabelPolicy: record<copyMode: string>, createTime: string, creator: record<person: string>, customer: string, disableTime: string, disabler: record<person: string>, displayHints: record<disabled: bool, hiddenInSearch: bool, priority: string, shownInApply: bool>, fields: table<appliedCapabilities: record, createTime: string, creator: record, dateOptions: record, disableTime: string, disabler: record, displayHints: record, id: string, integerOptions: record, lifecycle: record, lockStatus: record, properties: record, publisher: record, queryKey: string, schemaCapabilities: record, selectionOptions: record, textOptions: record, updateTime: string, updater: record, userOptions: record>, id: string, labelType: string, learnMoreUri: string, lifecycle: record<disabledPolicy: record<hideInSearch: bool, showInApply: bool>, hasUnpublishedChanges: bool, state: string>, lockStatus: record<locked: bool>, name: string, properties: record<description: string, title: string>, publishTime: string, publisher: record<person: string>, revisionCreateTime: string, revisionCreator: record<person: string>, revisionId: string, schemaCapabilities: record<canDelete: bool, canDisable: bool, canEnable: bool, canUpdate: bool>>
# operationId: drivelabels.labels.updateLabelCopyMode
export def "drivelabels-labels-update-label-copy-mode" [
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
  --copy-mode: string@copy-mode-completer # Required. Indicates how the applied Label, and Field values should be copied when a Drive item is copied.
  --language-code: string # The BCP-47 language code to use for evaluating localized field labels. When not specified, values in the default configured language will be used.
  --use-admin-access: oneof<nothing, bool> # Set to `true` in order to use the user's admin credentials. The server will verify the user is an admin for the Label before allowing access.
  --view: string@view-completer # When specified, only certain fields belonging to the indicated view will be returned.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2beta/{name}:updateLabelCopyMode"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: copyMode, var: copy_mode}, {name: languageCode, var: language_code}, {name: useAdminAccess, var: use_admin_access}, {name: view, var: view}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, copy_mode: $copy_mode, language_code: $language_code, use_admin_access: $use_admin_access, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the LabelLocks on a Label.
#
# GET /v2beta/{parent}/locks
# Returns: record<labelLocks: table<capabilities: record, choiceId: string, createTime: string, creator: record, deleteTime: string, fieldId: string, name: string, state: string>, nextPageToken: string>
# operationId: drivelabels.labels.revisions.locks.list
export def "drivelabels-labels-revisions-locks-list" [
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
  --page-size: int # Maximum number of Locks to return per page. Default: 100. Max: 200.
  --page-token: string # The token of the page to return.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2beta/{parent}/locks"
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

# Lists a Label's permissions.
#
# GET /v2beta/{parent}/permissions
# Returns: record<labelPermissions: table<audience: string, email: string, group: string, name: string, person: string, role: string>, nextPageToken: string>
# operationId: drivelabels.labels.revisions.permissions.list
export def "drivelabels-labels-revisions-permissions-list" [
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
  --page-size: int # Maximum number of permissions to return per page. Default: 50. Max: 200.
  --page-token: string # The token of the page to return.
  --use-admin-access: oneof<nothing, bool> # Set to `true` in order to use the user's admin credentials. The server will verify the user is an admin for the Label before allowing access.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2beta/{parent}/permissions"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: useAdminAccess, var: use_admin_access}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token, use_admin_access: $use_admin_access
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a Label's permissions. If a permission for the indicated principal doesn't exist, a new Label Permission is created, otherwise the existing permission is updated. Permissions affect the Label resource as a whole, are not revisioned, and do not require publishing.
#
# PATCH /v2beta/{parent}/permissions
# Returns: record<audience: string, email: string, group: string, name: string, person: string, role: string>
# operationId: drivelabels.labels.revisions.updatePermissions
export def "drivelabels-labels-revisions-update-permissions" [
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
  --use-admin-access: oneof<nothing, bool> # Set to `true` in order to use the user's admin credentials. The server will verify the user is an admin for the Label before allowing access.
  --audience: string # Audience to grant a role to. The magic value of `audiences/default` may be used to apply the role to the default audience in the context of the organization that owns the Label.
  --email: string # Specifies the email address for a user or group pricinpal. Not populated for audience principals. User and Group permissions may only be inserted using email address. On update requests, if email address is specified, no principal should be specified.
  --group: string # Group resource name.
  --name: string # Resource name of this permission.
  --person: string # Person resource name.
  --role: string@role-completer # The role the principal should have.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v2beta/{parent}/permissions"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: useAdminAccess, var: use_admin_access}]
    body: {content_type: "application/json", kind: json, fields: [{name: audience, var: audience}, {name: email, var: email}, {name: group, var: group}, {name: name, var: name}, {name: person, var: person}, {name: role, var: role}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, use_admin_access: $use_admin_access, audience: $audience, email: $email, group: $group, name: $name, person: $person, role: $role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a Label's permissions. If a permission for the indicated principal doesn't exist, a new Label Permission is created, otherwise the existing permission is updated. Permissions affect the Label resource as a whole, are not revisioned, and do not require publishing.
#
# POST /v2beta/{parent}/permissions
# Returns: record<audience: string, email: string, group: string, name: string, person: string, role: string>
# operationId: drivelabels.labels.revisions.permissions.create
export def "drivelabels-labels-revisions-permissions-create" [
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
  --use-admin-access: oneof<nothing, bool> # Set to `true` in order to use the user's admin credentials. The server will verify the user is an admin for the Label before allowing access.
  --audience: string # Audience to grant a role to. The magic value of `audiences/default` may be used to apply the role to the default audience in the context of the organization that owns the Label.
  --email: string # Specifies the email address for a user or group pricinpal. Not populated for audience principals. User and Group permissions may only be inserted using email address. On update requests, if email address is specified, no principal should be specified.
  --group: string # Group resource name.
  --name: string # Resource name of this permission.
  --person: string # Person resource name.
  --role: string@role-completer # The role the principal should have.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2beta/{parent}/permissions"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: useAdminAccess, var: use_admin_access}]
    body: {content_type: "application/json", kind: json, fields: [{name: audience, var: audience}, {name: email, var: email}, {name: group, var: group}, {name: name, var: name}, {name: person, var: person}, {name: role, var: role}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, use_admin_access: $use_admin_access, audience: $audience, email: $email, group: $group, name: $name, person: $person, role: $role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes Label permissions. Permissions affect the Label resource as a whole, are not revisioned, and do not require publishing.
#
# POST /v2beta/{parent}/permissions:batchDelete
# Returns: record
# operationId: drivelabels.labels.revisions.permissions.batchDelete
export def "drivelabels-labels-revisions-permissions-batch-delete" [
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
  --requests: list # Required. The request message specifying the resources to update. — item shape: {name?: string, useAdminAccess?: bool}
  --use-admin-access: oneof<nothing, bool> # Set to `true` in order to use the user's admin credentials. The server will verify the user is an admin for the Label before allowing access. If this is set, the use_admin_access field in the DeleteLabelPermissionRequest messages must either be empty or match this field.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2beta/{parent}/permissions:batchDelete"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: requests, var: requests}, {name: useAdminAccess, var: use_admin_access}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, requests: $requests, use_admin_access: $use_admin_access
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates Label permissions. If a permission for the indicated principal doesn't exist, a new Label Permission is created, otherwise the existing permission is updated. Permissions affect the Label resource as a whole, are not revisioned, and do not require publishing.
#
# POST /v2beta/{parent}/permissions:batchUpdate
# Returns: record<permissions: table<audience: string, email: string, group: string, name: string, person: string, role: string>>
# operationId: drivelabels.labels.revisions.permissions.batchUpdate
export def "drivelabels-labels-revisions-permissions-batch-update" [
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
  --requests: list # Required. The request message specifying the resources to update. — item shape: {labelPermission?: record, parent?: string, useAdminAccess?: bool}
  --use-admin-access: oneof<nothing, bool> # Set to `true` in order to use the user's admin credentials. The server will verify the user is an admin for the Label before allowing access. If this is set, the use_admin_access field in the UpdateLabelPermissionRequest messages must either be empty or match this field.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2beta/{parent}/permissions:batchUpdate"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: requests, var: requests}, {name: useAdminAccess, var: use_admin_access}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, requests: $requests, use_admin_access: $use_admin_access
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
