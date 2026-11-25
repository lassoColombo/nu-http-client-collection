# Auto-generated client for The Water Linked Underwater GPS API v1.0.0
# Source: https://api.apis.guru/v2/specs/waterlinked.com/1.0.0/swagger.json
# Auth: --token flag or $env.THE_WATER_LINKED_UNDERWATER_GPS_API_TOKEN

const CLIENT = {
  base_url: "http://demo.waterlinked.com"
  token_env_var: "THE_WATER_LINKED_UNDERWATER_GPS_API_TOKEN"
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

def base-url-completer [] { ["http://demo.waterlinked.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/vnd.waterlinked.configuration+json" "application/vnd.waterlinked.operation_response+json"] }
def compass-completer [] { ["external" "onboard" "static"] }
def environment-completer [] { ["openwater" "reflective"] }
def gps-completer [] { ["external" "onboard" "static"] }
def locator-type-completer [] { ["a1" "d1" "p2" "s2" "u1"] }
def mode-completer [] { ["ap" "client"] }
def accept-completer-1 [] { ["application/vnd.waterlinked.operation_response+json" "application/vnd.wl.external.locator.orientation+json"] }
def action-completer [] { ["abort" "start"] }
def accept-completer-2 [] { ["application/vnd.waterlinked.operation_response+json" "application/vnd.wl.warning+json; type=collection"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    about-api-version: "record<versions: list<string>>"
    about-get: "record<chipid: string, hardware_revision: int, product_id: int, product_name: string, variant: string, version: string, version_short: string>"
    about-factory-reset: "record<error: string, success: bool>"
    about-status: "record<battery: int, gps: int, imu: int>"
    about-temperature: "record<board: float, water: float>"
    config-get-antenna-config: "record<antenna_rotation: int, depth: float, x: float, y: float>"
    config-modify-antenna-config: "record<error: string, success: bool>"
    config-get: "record<antenna_enabled: bool, channel: int, compass: string, environment: string, external_pps_enabled: bool, gps: string, imu_vehicle_enabled: bool, locator_type: string, range_max_x: float, range_max_y: float, range_max_z: float, range_min_x: float, range_min_y: float, search_direction: float, search_radius: float, search_sector: float, speed_of_sound: int, static_lat: float, static_lon: float, static_orientation: float>"
    config-modify: "record<error: string, success: bool>"
    config-get-ip: "record<address: string, dhcp: bool, dns: string, gateway: string, prefix: int>"
    config-modify-ip: "record<error: string, success: bool>"
    config-list-receiver: "table<id: int, x: float, y: float, z: float>"
    config-show-receiver: "record<id: int, x: float, y: float, z: float>"
    config-get-wifi: "record<mode: string, password: string, ssid: string>"
    config-modify-wifi: "record<error: string, success: bool>"
    external-set-depth: "record<error: string, success: bool>"
    external-get-vehicle-imu: "record<pitch: float, roll: float, x: float, y: float, yaw: float, z: float>"
    external-set-vehicle-imu: "record<error: string, success: bool>"
    external-set-master: "record<error: string, success: bool>"
    external-get-orientation: "record<orientation: float>"
    external-set-orientation: "record<error: string, success: bool>"
    imu-get: "record<pitch: float, progress: int, roll: float, state: int, yaw: float>"
    poi-list: "table<depth: float, icon: string, id: int, lat: float, lng: float, name: string, visible: bool>"
    poi-show: "record<depth: float, icon: string, id: int, lat: float, lng: float, name: string, visible: bool>"
    position-acoustic-filtered: "record<position_valid: bool, receiver_distance: list<float>, receiver_nsd: list<float>, receiver_rssi: list<float>, receiver_valid: list<float>, std: float, x: float, y: float, z: float>"
    position-acoustic-raw: "record<position_valid: bool, receiver_distance: list<float>, receiver_nsd: list<float>, receiver_rssi: list<float>, receiver_valid: list<float>, std: float, x: float, y: float, z: float>"
    position-get: "record<cog: float, fix_quality: float, hdop: float, lat: float, lon: float, numsats: float, orientation: float, sog: float>"
    position-get-master: "record<cog: float, fix_quality: float, hdop: float, lat: float, lon: float, numsats: float, orientation: float, sog: float>"
    status-report-get: "table<error_ids: list<string>, message: string, status: string, status_group: string, status_group_id: string>"
    warnings-get: "table<id: string, message: string, severity: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["about-api-version" "about-get" "about-factory-reset" "about-led" "about-status" "about-temperature" "config-get-antenna-config" "config-modify-antenna-config" "config-get" "config-modify" "config-get-ip" "config-modify-ip" "config-list-receiver" "config-show-receiver" "config-modify-receiver" "config-get-wifi" "config-modify-wifi" "external-set-depth" "external-get-vehicle-imu" "external-set-vehicle-imu" "external-set-master" "external-get-orientation" "external-set-orientation" "imu-get" "imu-calibrate" "imu-reset-gyro" "imu-set-north" "poi-list" "poi-create" "poi-delete" "poi-show" "poi-update" "position-acoustic-filtered" "position-acoustic-raw" "position-get" "position-get-master" "status-report-get" "warnings-get" "commands"] | sort) } | get name | first)
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

# ApiVersion about
#
# GET /api/
# Returns: record<versions: list<string>>
# operationId: about#ApiVersion
export def "about-api-version" [
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
    path: "/api/"
    accept: ["application/vnd.wupdater.apiversion"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get about
#
# GET /api/v1/about
# Returns: record<chipid: string, hardware_revision: int, product_id: int, product_name: string, variant: string, version: string, version_short: string>
# operationId: about#Get
export def "about-get" [
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
    path: "/api/v1/about"
    accept: ["application/vnd.waterlinked.about+json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# FactoryReset about
#
# POST /api/v1/about/factoryreset
# Returns: record<error: string, success: bool>
# operationId: about#FactoryReset
export def "about-factory-reset" [
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
    method: post
    path: "/api/v1/about/factoryreset"
    accept: ["application/vnd.waterlinked.operation_response+json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# LED about
#
# GET /api/v1/about/led
# operationId: about#LED
export def "about-led" [
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
    path: "/api/v1/about/led"
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Status about
#
# GET /api/v1/about/status
# Returns: record<battery: int, gps: int, imu: int>
# operationId: about#Status
export def "about-status" [
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
    path: "/api/v1/about/status"
    accept: ["application/vnd.waterlinked.status+json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Temperature about
#
# GET /api/v1/about/temperature
# Returns: record<board: float, water: float>
# operationId: about#Temperature
export def "about-temperature" [
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
    path: "/api/v1/about/temperature"
    accept: ["application/vnd.waterlinked.temperature+json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GetAntennaConfig config
#
# GET /api/v1/config/antenna
# Returns: record<antenna_rotation: int, depth: float, x: float, y: float>
# operationId: config#GetAntennaConfig
export def "config-get-antenna-config" [
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
    path: "/api/v1/config/antenna"
    accept: ["application/vnd.waterlinked.antenna_config+json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ModifyAntennaConfig config
#
# PUT /api/v1/config/antenna
# Returns: record<error: string, success: bool>
# operationId: config#ModifyAntennaConfig
export def "config-modify-antenna-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  antenna_rotation: int # Configured rotation of antenna relative to forward arrow on topside housing. Clockwise is positive direction (degrees) (e.g. 90)
  depth: float # Configured depth relative to surface (meter) (e.g. 2)
  x: float # Configured f position relative to master electronics (meter) (e.g. -2)
  y: float # Configured Y position relative to master electronics (meter) (e.g. 2)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/config/antenna"
    body: {content_type: "application/json", kind: json, fields: [{name: antenna_rotation, var: antenna_rotation}, {name: depth, var: depth}, {name: x, var: x}, {name: y, var: y}]}
    accept: ["application/vnd.waterlinked.operation_response+json"]
    ok: [200]
    auth: bearer
  } {
    antenna_rotation: $antenna_rotation, depth: $depth, x: $x, y: $y
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get config
#
# GET /api/v1/config/generic
# Returns: record<antenna_enabled: bool, channel: int, compass: string, environment: string, external_pps_enabled: bool, gps: string, imu_vehicle_enabled: bool, locator_type: string, range_max_x: float, range_max_y: float, range_max_z: float, range_min_x: float, range_min_y: float, search_direction: float, search_radius: float, search_sector: float, speed_of_sound: int, static_lat: float, static_lon: float, static_orientation: float>
# operationId: config#Get
export def "config-get" [
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
    path: "/api/v1/config/generic"
    accept: ["application/vnd.waterlinked.configuration+json", "application/vnd.waterlinked.operation_response+json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Modify config
#
# PUT /api/v1/config/generic
# Returns: record<error: string, success: bool>
# operationId: config#Modify
export def "config-modify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --antenna-enabled: oneof<nothing, bool> # Enable use of antenna (e.g. true)
  channel: int # Channel to use (e.g. 13)
  compass: string@compass-completer # Compass provider setting (e.g. external)
  --environment: string@environment-completer # [Deprecated] Environment setting (e.g. openwater)
  --external-pps-enabled: oneof<nothing, bool> # Enable external PPS input to master (e.g. false)
  gps: string@gps-completer # GPS provider setting (e.g. external)
  --imu-vehicle-enabled: oneof<nothing, bool> # [Deprecated] Enable IMU input from vehicle (e.g. true)
  locator_type: string@locator-type-completer # Locator type in use (e.g. a1)
  --range-max-x: float # [Deprecated] Max range (meters) (e.g. 50)
  --range-max-y: float # [Deprecated] Max range (meters) (e.g. 50)
  --range-max-z: float # [Deprecated] Max range (meters) (e.g. 50)
  --range-min-x: float # [Deprecated] Max range (meters) (e.g. -50)
  --range-min-y: float # [Deprecated] Max range (meters) (e.g. -50)
  --search-direction: float # Direction of circular search area section (e.g. 30)
  --search-radius: float # Radius of circular search area (e.g. 150)
  --search-sector: float # Sector angle of circular search area (e.g. 90)
  --speed-of-sound: int # Speed of sound use by the system (e.g. 1475)
  static_lat: float # Latitude to use in static mode (e.g. 63.422)
  static_lon: float # Longitude to use in static mode (e.g. 10.424)
  static_orientation: float # Orientation/compass reading to use in static mode (degrees) (e.g. 42)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/config/generic"
    body: {content_type: "application/json", kind: json, fields: [{name: antenna_enabled, var: antenna_enabled}, {name: channel, var: channel}, {name: compass, var: compass}, {name: environment, var: environment}, {name: external_pps_enabled, var: external_pps_enabled}, {name: gps, var: gps}, {name: imu_vehicle_enabled, var: imu_vehicle_enabled}, {name: locator_type, var: locator_type}, {name: range_max_x, var: range_max_x}, {name: range_max_y, var: range_max_y}, {name: range_max_z, var: range_max_z}, {name: range_min_x, var: range_min_x}, {name: range_min_y, var: range_min_y}, {name: search_direction, var: search_direction}, {name: search_radius, var: search_radius}, {name: search_sector, var: search_sector}, {name: speed_of_sound, var: speed_of_sound}, {name: static_lat, var: static_lat}, {name: static_lon, var: static_lon}, {name: static_orientation, var: static_orientation}]}
    accept: ["application/vnd.waterlinked.operation_response+json"]
    ok: [200]
    auth: bearer
  } {
    antenna_enabled: $antenna_enabled, channel: $channel, compass: $compass, environment: $environment, external_pps_enabled: $external_pps_enabled, gps: $gps, imu_vehicle_enabled: $imu_vehicle_enabled, locator_type: $locator_type, range_max_x: $range_max_x, range_max_y: $range_max_y, range_max_z: $range_max_z, range_min_x: $range_min_x, range_min_y: $range_min_y, search_direction: $search_direction, search_radius: $search_radius, search_sector: $search_sector, speed_of_sound: $speed_of_sound, static_lat: $static_lat, static_lon: $static_lon, static_orientation: $static_orientation
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GetIP config
#
# GET /api/v1/config/ip
# Returns: record<address: string, dhcp: bool, dns: string, gateway: string, prefix: int>
# operationId: config#GetIP
export def "config-get-ip" [
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
    path: "/api/v1/config/ip"
    accept: ["application/vnd.waterlinked.ip_config+json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ModifyIP config
#
# PUT /api/v1/config/ip
# Returns: record<error: string, success: bool>
# operationId: config#ModifyIP
export def "config-modify-ip" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  address: string # IP address to use (e.g. 10.11.12.94)
  --dhcp: oneof<nothing, bool> # DHCP to use (e.g. true)
  dns: string # DNS to use (e.g. 10.11.12.1)
  gateway: string # Gateway to use (e.g. 10.11.12.1)
  prefix: int # Prefix to use (e.g. 24)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/config/ip"
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: dhcp, var: dhcp, required: true}, {name: dns, var: dns}, {name: gateway, var: gateway}, {name: prefix, var: prefix}]}
    accept: ["application/vnd.waterlinked.operation_response+json"]
    ok: [200]
    auth: bearer
  } {
    address: $address, dhcp: $dhcp, dns: $dns, gateway: $gateway, prefix: $prefix
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListReceiver config
#
# GET /api/v1/config/receivers/
# Returns: table<id: int, x: float, y: float, z: float>
# operationId: config#ListReceiver
export def "config-list-receiver" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/config/receivers/"
    accept: ["application/vnd.waterlinked.receiver+json; type=collection"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ShowReceiver config
#
# GET /api/v1/config/receivers/{ID}
# Returns: record<id: int, x: float, y: float, z: float>
# operationId: config#ShowReceiver
export def "config-show-receiver" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/config/receivers/{ID}"
    path_params: [{name: ID, var: id}]
    accept: ["application/vnd.waterlinked.receiver+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ModifyReceiver config
#
# PUT /api/v1/config/receivers/{ID}
# operationId: config#ModifyReceiver
export def "config-modify-receiver" [
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
  --body-id: int # Unique receiver identifier (format: int64, e.g. 2339264502380679700) (spec name: id)
  x: float # Configured X position relative to master electronics (meter) (format: double, e.g. 0.0158212572962501)
  y: float # Configured Y position relative to master electronics (meter) (format: double, e.g. 0.08142596921667565)
  z: float # Configured Z position relative to master electronics (meter) (format: double, e.g. 0.34617068793186784)
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v1/config/receivers/{ID}"
    path_params: [{name: ID, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: body_id, required: true}, {name: x, var: x}, {name: y, var: y}, {name: z, var: z}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, body_id: $body_id, x: $x, y: $y, z: $z
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GetWIFI config
#
# GET /api/v1/config/wifi
# Returns: record<mode: string, password: string, ssid: string>
# operationId: config#GetWIFI
export def "config-get-wifi" [
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
    path: "/api/v1/config/wifi"
    accept: ["application/vnd.waterlinked.wifi_config+json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ModifyWIFI config
#
# PUT /api/v1/config/wifi
# Returns: record<error: string, success: bool>
# operationId: config#ModifyWIFI
export def "config-modify-wifi" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  mode: string@mode-completer # Which mode should the WiFi be in? (e.g. ap)
  password: string # Password to use for WiFi in Client mode (e.g. 10.11.12.1)
  ssid: string # WIFI SSID to use for WiFi in Client mode (e.g. 10.11.12.94)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/config/wifi"
    body: {content_type: "application/json", kind: json, fields: [{name: mode, var: mode}, {name: password, var: password}, {name: ssid, var: ssid}]}
    accept: ["application/vnd.waterlinked.operation_response+json"]
    ok: [200]
    auth: bearer
  } {
    mode: $mode, password: $password, ssid: $ssid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SetDepth external
#
# PUT /api/v1/external/depth
# Returns: record<error: string, success: bool>
# operationId: external#SetDepth
export def "external-set-depth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  depth: float # Curent depth (meter) (e.g. 3.2)
  temp: float # Current water temperature (C) (e.g. 11.2)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/external/depth"
    body: {content_type: "application/json", kind: json, fields: [{name: depth, var: depth}, {name: temp, var: temp}]}
    accept: ["application/vnd.waterlinked.operation_response+json"]
    ok: [200]
    auth: bearer
  } {
    depth: $depth, temp: $temp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GetVehicleIMU external
#
# GET /api/v1/external/imu
# Returns: record<pitch: float, roll: float, x: float, y: float, yaw: float, z: float>
# operationId: external#GetVehicleIMU
export def "external-get-vehicle-imu" [
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
    path: "/api/v1/external/imu"
    accept: ["application/vnd.wl.external.vehicle.imu+json"]
    ok: [200, 204]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SetVehicleIMU external
#
# PUT /api/v1/external/imu
# Returns: record<error: string, success: bool>
# operationId: external#SetVehicleIMU
export def "external-set-vehicle-imu" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  pitch: float # Current pitch of vehicle(degrees). (e.g. 30)
  roll: float # Current roll of vehicle(degrees). (e.g. -30)
  x: float # Current acceleration in x-axis of vehicle. (e.g. 10)
  y: float # Current acceleration in y-axis of vehicle. (e.g. -10)
  yaw: float # Current yaw of vehicle(degrees). (e.g. 30)
  z: float # Current acceleration in z-axis of vehicle. (e.g. 5)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/external/imu"
    body: {content_type: "application/json", kind: json, fields: [{name: pitch, var: pitch}, {name: roll, var: roll}, {name: x, var: x}, {name: y, var: y}, {name: yaw, var: yaw}, {name: z, var: z}]}
    accept: ["application/vnd.waterlinked.operation_response+json"]
    ok: [200]
    auth: bearer
  } {
    pitch: $pitch, roll: $roll, x: $x, y: $y, yaw: $yaw, z: $z
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SetMaster external
#
# PUT /api/v1/external/master
# Returns: record<error: string, success: bool>
# operationId: external#SetMaster
export def "external-set-master" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cog: float # Course over ground (degrees). -1 means no data. (e.g. 42)
  --fix-quality: float # Fix quality. 0 if no data. (e.g. 1)
  --hdop: float # Horizontal dilution of precision. -1 means no data. (e.g. 1.9)
  lat: float # Current Latitude (e.g. 63.422)
  lon: float # Current Longitude (e.g. 10.424)
  --numsats: float # Number of satellites. -1 means no data. (e.g. 11)
  orientation: float # Current orientation/compass heading (degrees) (e.g. 42)
  --sog: float # Speed over ground (km/h). -1 means no data. (e.g. 0.5)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/external/master"
    body: {content_type: "application/json", kind: json, fields: [{name: cog, var: cog}, {name: fix_quality, var: fix_quality}, {name: hdop, var: hdop}, {name: lat, var: lat}, {name: lon, var: lon}, {name: numsats, var: numsats}, {name: orientation, var: orientation}, {name: sog, var: sog}]}
    accept: ["application/vnd.waterlinked.operation_response+json"]
    ok: [200]
    auth: bearer
  } {
    cog: $cog, fix_quality: $fix_quality, hdop: $hdop, lat: $lat, lon: $lon, numsats: $numsats, orientation: $orientation, sog: $sog
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GetOrientation external
#
# GET /api/v1/external/orientation
# Returns: record<orientation: float>
# operationId: external#GetOrientation
export def "external-get-orientation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/external/orientation"
    accept: ["application/vnd.waterlinked.operation_response+json", "application/vnd.wl.external.locator.orientation+json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# SetOrientation external
#
# PUT /api/v1/external/orientation
# Returns: record<error: string, success: bool>
# operationId: external#SetOrientation
export def "external-set-orientation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  orientation: float # Current orientation/compass heading (degrees). -1 means no orientation set (e.g. 42)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/external/orientation"
    body: {content_type: "application/json", kind: json, fields: [{name: orientation, var: orientation}]}
    accept: ["application/vnd.waterlinked.operation_response+json"]
    ok: [200]
    auth: bearer
  } {
    orientation: $orientation
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get imu
#
# GET /api/v1/imu/calibrate
# Returns: record<pitch: float, progress: int, roll: float, state: int, yaw: float>
# operationId: imu#Get
export def "imu-get" [
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
    path: "/api/v1/imu/calibrate"
    accept: ["application/vnd.waterlinked.imu+json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Calibrate imu
#
# POST /api/v1/imu/calibrate
# operationId: imu#Calibrate
export def "imu-calibrate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  action: string@action-completer # IMU Calibration Action to use (e.g. start)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/imu/calibrate"
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}]}
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    action: $action
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ResetGyro imu
#
# POST /api/v1/imu/resetgyros
# operationId: imu#ResetGyro
export def "imu-reset-gyro" [
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
    path: "/api/v1/imu/resetgyros"
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SetNorth imu
#
# POST /api/v1/imu/setnorth
# operationId: imu#SetNorth
export def "imu-set-north" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  heading: float # Current heading (e.g. 50)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/imu/setnorth"
    body: {content_type: "application/json", kind: json, fields: [{name: heading, var: heading}]}
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    heading: $heading
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List poi
#
# GET /api/v1/poi/
# Returns: table<depth: float, icon: string, id: int, lat: float, lng: float, name: string, visible: bool>
# operationId: poi#List
export def "poi-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/poi/"
    accept: ["application/vnd.waterlinked.poi+json; type=collection"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create poi
#
# POST /api/v1/poi/
# operationId: poi#Create
export def "poi-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  depth: float # Depth of POI (format: double, e.g. 0.9848439086783396)
  icon: string # Icon of POI (e.g. Ut molestias laboriosam.)
  --id: int # Unique POI id (format: int64, e.g. 3408207428662661600)
  lat: float # Latitude of POI (format: double, e.g. 0.8147274904139097)
  lng: float # Longitude of POI (format: double, e.g. 0.06472337355304676)
  name: string # Name of POI (e.g. Reprehenderit non architecto quia.)
  --visible: oneof<nothing, bool> # Visibility of POI (e.g. false)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/poi/"
    body: {content_type: "application/json", kind: json, fields: [{name: depth, var: depth}, {name: icon, var: icon}, {name: id, var: id}, {name: lat, var: lat}, {name: lng, var: lng}, {name: name, var: name}, {name: visible, var: visible, required: true}]}
    accept: ["application/vnd.goa.error"]
    ok: [201]
    auth: bearer
  } {
    depth: $depth, icon: $icon, id: $id, lat: $lat, lng: $lng, name: $name, visible: $visible
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete poi
#
# DELETE /api/v1/poi/{ID}
# operationId: poi#Delete
export def "poi-delete" [
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
    method: delete
    path: "/api/v1/poi/{ID}"
    path_params: [{name: ID, var: id}]
    accept: ["application/vnd.goa.error"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show poi
#
# GET /api/v1/poi/{ID}
# Returns: record<depth: float, icon: string, id: int, lat: float, lng: float, name: string, visible: bool>
# operationId: poi#Show
export def "poi-show" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/poi/{ID}"
    path_params: [{name: ID, var: id}]
    accept: ["application/vnd.waterlinked.poi+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update poi
#
# PATCH /api/v1/poi/{ID}
# operationId: poi#Update
export def "poi-update" [
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
  depth: float # Depth of POI (format: double, e.g. 0.9848439086783396)
  icon: string # Icon of POI (e.g. Ut molestias laboriosam.)
  --body-id: int # Unique POI id (format: int64, e.g. 3408207428662661600) (spec name: id)
  lat: float # Latitude of POI (format: double, e.g. 0.8147274904139097)
  lng: float # Longitude of POI (format: double, e.g. 0.06472337355304676)
  name: string # Name of POI (e.g. Reprehenderit non architecto quia.)
  --visible: oneof<nothing, bool> # Visibility of POI (e.g. false)
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/v1/poi/{ID}"
    path_params: [{name: ID, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: depth, var: depth}, {name: icon, var: icon}, {name: id, var: body_id}, {name: lat, var: lat}, {name: lng, var: lng}, {name: name, var: name}, {name: visible, var: visible, required: true}]}
    accept: ["application/vnd.goa.error"]
    ok: [204]
    auth: bearer
  } {
    id: $id, depth: $depth, icon: $icon, body_id: $body_id, lat: $lat, lng: $lng, name: $name, visible: $visible
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# AcousticFiltered position
#
# GET /api/v1/position/acoustic/filtered
# Returns: record<position_valid: bool, receiver_distance: list<float>, receiver_nsd: list<float>, receiver_rssi: list<float>, receiver_valid: list<float>, std: float, x: float, y: float, z: float>
# operationId: position#AcousticFiltered
export def "position-acoustic-filtered" [
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
    path: "/api/v1/position/acoustic/filtered"
    accept: ["application/vnd.waterlinked.accoustic.position+json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# AcousticRaw position
#
# GET /api/v1/position/acoustic/raw
# Returns: record<position_valid: bool, receiver_distance: list<float>, receiver_nsd: list<float>, receiver_rssi: list<float>, receiver_valid: list<float>, std: float, x: float, y: float, z: float>
# operationId: position#AcousticRaw
export def "position-acoustic-raw" [
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
    path: "/api/v1/position/acoustic/raw"
    accept: ["application/vnd.waterlinked.accoustic.position+json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get position
#
# GET /api/v1/position/global
# Returns: record<cog: float, fix_quality: float, hdop: float, lat: float, lon: float, numsats: float, orientation: float, sog: float>
# operationId: position#Get
export def "position-get" [
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
    path: "/api/v1/position/global"
    accept: ["application/vnd.wl.satellite.position+json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GetMaster position
#
# GET /api/v1/position/master
# Returns: record<cog: float, fix_quality: float, hdop: float, lat: float, lon: float, numsats: float, orientation: float, sog: float>
# operationId: position#GetMaster
export def "position-get-master" [
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
    path: "/api/v1/position/master"
    accept: ["application/vnd.wl.satellite.position+json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get status_report
#
# GET /api/v1/status_report/
# Returns: table<error_ids: list<string>, message: string, status: string, status_group: string, status_group_id: string>
# operationId: status_report#Get
export def "status-report-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/status_report/"
    accept: ["application/vnd.wl.status.group+json; type=collection"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get warnings
#
# GET /api/v1/warnings/
# Returns: table<id: string, message: string, severity: string>
# operationId: warnings#Get
export def "warnings-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/warnings/"
    accept: ["application/vnd.waterlinked.operation_response+json", "application/vnd.wl.warning+json; type=collection"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
