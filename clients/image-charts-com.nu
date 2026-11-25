# Auto-generated client for Image-Charts v6.1.19
# Source: https://api.apis.guru/v2/specs/image-charts.com/6.1.19/swagger.json
# Auth: --token flag or $env.IMAGE_CHARTS_TOKEN

const CLIENT = {
  base_url: "https://image-charts.com"
  token_env_var: "IMAGE_CHARTS_TOKEN"
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

def base-url-completer [] { ["https://image-charts.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def cht-completer [] { ["bb" "bhg" "bhs" "bvg" "bvo" "bvs" "gv" "gv:circo" "gv:dot" "gv:fdp" "gv:neato" "gv:osage" "gv:twopi" "lc" "lc:nda" "ls" "ls:nda" "lxy" "lxy:nda" "p" "p3" "pa" "pc" "pd" "qr" "r"] }
def choe-completer [] { ["UTF-8"] }
def icff-completer [] { ["ABeeZee" "Abel" "Abhaya Libre" "Abril Fatface" "Aclonica" "Acme" "Actor" "Adamina" "Advent Pro" "Aguafina Script" "Akronim" "Aladin" "Aldrich" "Alef" "Alegreya" "Alegreya SC" "Alegreya Sans" "Alegreya Sans SC" "Aleo" "Alex Brush" "Alfa Slab One" "Alice" "Alike" "Alike Angular" "Allan" "Allerta" "Allerta Stencil" "Allura" "Almarai" "Almendra" "Almendra Display" "Almendra SC" "Amarante" "Amaranth" "Amatic SC" "Amethysta" "Amiko" "Amiri" "Amita" "Anaheim" "Andada" "Andika" "Angkor" "Annie Use Your Telescope" "Anonymous Pro" "Antic" "Antic Didone" "Antic Slab" "Anton" "Arapey" "Arbutus" "Arbutus Slab" "Architects Daughter" "Archivo" "Archivo Black" "Archivo Narrow" "Aref Ruqaa" "Arima Madurai" "Arimo" "Arizonia" "Armata" "Arsenal" "Artifika" "Arvo" "Arya" "Asap" "Asap Condensed" "Asar" "Asset" "Assistant" "Astloch" "Asul" "Athiti" "Atma" "Atomic Age" "Aubrey" "Audiowide" "Autour One" "Average" "Average Sans" "Averia Gruesa Libre" "Averia Libre" "Averia Sans Libre" "Averia Serif Libre" "B612" "B612 Mono" "Bad Script" "Bahiana" "Bahianita" "Bai Jamjuree" "Baloo" "Baloo Bhai" "Baloo Bhaijaan" "Baloo Bhaina" "Baloo Chettan" "Baloo Da" "Baloo Paaji" "Baloo Tamma" "Baloo Tammudu" "Baloo Thambi" "Balthazar" "Bangers" "Barlow" "Barlow Condensed" "Barlow Semi Condensed" "Barriecito" "Barrio" "Basic" "Battambang" "Baumans" "Bayon" "Be Vietnam" "Belgrano" "Bellefair" "Belleza" "BenchNine" "Bentham" "Berkshire Swash" "Beth Ellen" "Bevan" "Big Shoulders Display" "Big Shoulders Text" "Bigelow Rules" "Bigshot One" "Bilbo" "Bilbo Swash Caps" "BioRhyme" "BioRhyme Expanded" "Biryani" "Bitter" "Black And White Picture" "Black Han Sans" "Black Ops One" "Blinker" "Bokor" "Bonbon" "Boogaloo" "Bowlby One" "Bowlby One SC" "Brawler" "Bree Serif" "Bubblegum Sans" "Bubbler One" "Buda" "Buenard" "Bungee" "Bungee Hairline" "Bungee Inline" "Bungee Outline" "Bungee Shade" "Butcherman" "Butterfly Kids" "Cabin" "Cabin Condensed" "Cabin Sketch" "Caesar Dressing" "Cagliostro" "Cairo" "Calligraffitti" "Cambay" "Cambo" "Candal" "Cantarell" "Cantata One" "Cantora One" "Capriola" "Cardo" "Carme" "Carrois Gothic" "Carrois Gothic SC" "Carter One" "Catamaran" "Caudex" "Caveat" "Caveat Brush" "Cedarville Cursive" "Ceviche One" "Chakra Petch" "Changa" "Changa One" "Chango" "Charm" "Charmonman" "Chathura" "Chau Philomene One" "Chela One" "Chelsea Market" "Chenla" "Cherry Cream Soda" "Cherry Swash" "Chewy" "Chicle" "Chilanka" "Chivo" "Chonburi" "Cinzel" "Cinzel Decorative" "Clicker Script" "Coda" "Coda Caption" "Codystar" "Coiny" "Combo" "Comfortaa" "Coming Soon" "Concert One" "Condiment" "Content" "Contrail One" "Convergence" "Cookie" "Copse" "Corben" "Cormorant" "Cormorant Garamond" "Cormorant Infant" "Cormorant SC" "Cormorant Unicase" "Cormorant Upright" "Courgette" "Cousine" "Coustard" "Covered By Your Grace" "Crafty Girls" "Creepster" "Crete Round" "Crimson Pro" "Crimson Text" "Croissant One" "Crushed" "Cuprum" "Cute Font" "Cutive" "Cutive Mono" "DM Sans" "DM Serif Display" "DM Serif Text" "Damion" "Dancing Script" "Dangrek" "Darker Grotesque" "David Libre" "Dawning of a New Day" "Days One" "Dekko" "Delius" "Delius Swash Caps" "Delius Unicase" "Della Respira" "Denk One" "Devonshire" "Dhurjati" "Didact Gothic" "Diplomata" "Diplomata SC" "Do Hyeon" "Dokdo" "Domine" "Donegal One" "Doppio One" "Dorsa" "Dosis" "Dr Sugiyama" "Duru Sans" "Dynalight" "EB Garamond" "Eagle Lake" "East Sea Dokdo" "Eater" "Economica" "Eczar" "El Messiri" "Electrolize" "Elsie" "Elsie Swash Caps" "Emblema One" "Emilys Candy" "Encode Sans" "Encode Sans Condensed" "Encode Sans Expanded" "Encode Sans Semi Condensed" "Encode Sans Semi Expanded" "Engagement" "Englebert" "Enriqueta" "Erica One" "Esteban" "Euphoria Script" "Ewert" "Exo" "Exo 2" "Expletus Sans" "Fahkwang" "Fanwood Text" "Farro" "Farsan" "Fascinate" "Fascinate Inline" "Faster One" "Fasthand" "Fauna One" "Faustina" "Federant" "Federo" "Felipa" "Fenix" "Finger Paint" "Fira Code" "Fira Mono" "Fira Sans" "Fira Sans Condensed" "Fira Sans Extra Condensed" "Fjalla One" "Fjord One" "Flamenco" "Flavors" "Fondamento" "Fontdiner Swanky" "Forum" "Francois One" "Frank Ruhl Libre" "Freckle Face" "Fredericka the Great" "Fredoka One" "Freehand" "Fresca" "Frijole" "Fruktur" "Fugaz One" "GFS Didot" "GFS Neohellenic" "Gabriela" "Gaegu" "Gafata" "Galada" "Galdeano" "Galindo" "Gamja Flower" "Gayathri" "Gentium Basic" "Gentium Book Basic" "Geo" "Geostar" "Geostar Fill" "Germania One" "Gidugu" "Gilda Display" "Give You Glory" "Glass Antiqua" "Glegoo" "Gloria Hallelujah" "Goblin One" "Gochi Hand" "Gorditas" "Gothic A1" "Goudy Bookletter 1911" "Graduate" "Grand Hotel" "Gravitas One" "Great Vibes" "Grenze" "Griffy" "Gruppo" "Gudea" "Gugi" "Gurajada" "Habibi" "Halant" "Hammersmith One" "Hanalei" "Hanalei Fill" "Handlee" "Hanuman" "Happy Monkey" "Harmattan" "Headland One" "Heebo" "Henny Penny" "Hepta Slab" "Herr Von Muellerhoff" "Hi Melody" "Hind" "Hind Guntur" "Hind Madurai" "Hind Siliguri" "Hind Vadodara" "Holtwood One SC" "Homemade Apple" "Homenaje" "IBM Plex Mono" "IBM Plex Sans" "IBM Plex Sans Condensed" "IBM Plex Serif" "IM Fell DW Pica" "IM Fell DW Pica SC" "IM Fell Double Pica" "IM Fell Double Pica SC" "IM Fell English" "IM Fell English SC" "IM Fell French Canon" "IM Fell French Canon SC" "IM Fell Great Primer" "IM Fell Great Primer SC" "Iceberg" "Iceland" "Imprima" "Inconsolata" "Inder" "Indie Flower" "Inika" "Inknut Antiqua" "Irish Grover" "Istok Web" "Italiana" "Italianno" "Itim" "Jacques Francois" "Jacques Francois Shadow" "Jaldi" "Jim Nightshade" "Jockey One" "Jolly Lodger" "Jomhuria" "Jomolhari" "Josefin Sans" "Josefin Slab" "Joti One" "Jua" "Judson" "Julee" "Julius Sans One" "Junge" "Jura" "Just Another Hand" "Just Me Again Down Here" "K2D" "Kadwa" "Kalam" "Kameron" "Kanit" "Kantumruy" "Karla" "Karma" "Katibeh" "Kaushan Script" "Kavivanar" "Kavoon" "Kdam Thmor" "Keania One" "Kelly Slab" "Kenia" "Khand" "Khmer" "Khula" "Kirang Haerang" "Kite One" "Knewave" "KoHo" "Kodchasan" "Kosugi" "Kosugi Maru" "Kotta One" "Koulen" "Kranky" "Kreon" "Kristi" "Krona One" "Krub" "Kumar One" "Kumar One Outline" "Kurale" "La Belle Aurore" "Lacquer" "Laila" "Lakki Reddy" "Lalezar" "Lancelot" "Lateef" "Lato" "League Script" "Leckerli One" "Ledger" "Lekton" "Lemon" "Lemonada" "Lexend Deca" "Lexend Exa" "Lexend Giga" "Lexend Mega" "Lexend Peta" "Lexend Tera" "Lexend Zetta" "Libre Barcode 128" "Libre Barcode 128 Text" "Libre Barcode 39" "Libre Barcode 39 Extended" "Libre Barcode 39 Extended Text" "Libre Barcode 39 Text" "Libre Baskerville" "Libre Caslon Display" "Libre Caslon Text" "Libre Franklin" "Life Savers" "Lilita One" "Lily Script One" "Limelight" "Linden Hill" "Literata" "Liu Jian Mao Cao" "Livvic" "Lobster" "Lobster Two" "Londrina Outline" "Londrina Shadow" "Londrina Sketch" "Londrina Solid" "Long Cang" "Lora" "Love Ya Like A Sister" "Loved by the King" "Lovers Quarrel" "Luckiest Guy" "Lusitana" "Lustria" "M PLUS 1p" "M PLUS Rounded 1c" "Ma Shan Zheng" "Macondo" "Macondo Swash Caps" "Mada" "Magra" "Maiden Orange" "Maitree" "Major Mono Display" "Mako" "Mali" "Mallanna" "Mandali" "Manjari" "Mansalva" "Manuale" "Marcellus" "Marcellus SC" "Marck Script" "Margarine" "Markazi Text" "Marko One" "Marmelad" "Martel" "Martel Sans" "Marvel" "Mate" "Mate SC" "Maven Pro" "McLaren" "Meddon" "MedievalSharp" "Medula One" "Meera Inimai" "Megrim" "Meie Script" "Merienda" "Merienda One" "Merriweather" "Merriweather Sans" "Metal" "Metal Mania" "Metamorphous" "Metrophobic" "Michroma" "Milonga" "Miltonian" "Miltonian Tattoo" "Mina" "Miniver" "Miriam Libre" "Mirza" "Miss Fajardose" "Mitr" "Modak" "Modern Antiqua" "Mogra" "Molengo" "Molle" "Monda" "Monofett" "Monoton" "Monsieur La Doulaise" "Montaga" "Montez" "Montserrat" "Montserrat Alternates" "Montserrat Subrayada" "Moul" "Moulpali" "Mountains of Christmas" "Mouse Memoirs" "Mr Bedfort" "Mr Dafoe" "Mr De Haviland" "Mrs Saint Delafield" "Mrs Sheppards" "Mukta" "Mukta Mahee" "Mukta Malar" "Mukta Vaani" "Muli" "Mystery Quest" "NTR" "Nanum Brush Script" "Nanum Gothic" "Nanum Gothic Coding" "Nanum Myeongjo" "Nanum Pen Script" "Neucha" "Neuton" "New Rocker" "News Cycle" "Niconne" "Niramit" "Nixie One" "Nobile" "Nokora" "Norican" "Nosifer" "Notable" "Nothing You Could Do" "Noticia Text" "Noto Sans" "Noto Sans HK" "Noto Sans JP" "Noto Sans KR" "Noto Sans SC" "Noto Sans TC" "Noto Serif" "Noto Serif JP" "Noto Serif KR" "Noto Serif SC" "Noto Serif TC" "Nova Cut" "Nova Flat" "Nova Mono" "Nova Oval" "Nova Round" "Nova Script" "Nova Slim" "Nova Square" "Numans" "Nunito" "Nunito Sans" "Odor Mean Chey" "Offside" "Old Standard TT" "Oldenburg" "Oleo Script" "Oleo Script Swash Caps" "Open Sans" "Open Sans Condensed" "Oranienbaum" "Orbitron" "Oregano" "Orienta" "Original Surfer" "Oswald" "Over the Rainbow" "Overlock" "Overlock SC" "Overpass" "Overpass Mono" "Ovo" "Oxygen" "Oxygen Mono" "PT Mono" "PT Sans" "PT Sans Caption" "PT Sans Narrow" "PT Serif" "PT Serif Caption" "Pacifico" "Padauk" "Palanquin" "Palanquin Dark" "Pangolin" "Paprika" "Parisienne" "Passero One" "Passion One" "Pathway Gothic One" "Patrick Hand" "Patrick Hand SC" "Pattaya" "Patua One" "Pavanam" "Paytone One" "Peddana" "Peralta" "Permanent Marker" "Petit Formal Script" "Petrona" "Philosopher" "Piedra" "Pinyon Script" "Pirata One" "Plaster" "Play" "Playball" "Playfair Display" "Playfair Display SC" "Podkova" "Poiret One" "Poller One" "Poly" "Pompiere" "Pontano Sans" "Poor Story" "Poppins" "Port Lligat Sans" "Port Lligat Slab" "Pragati Narrow" "Prata" "Preahvihear" "Press Start 2P" "Pridi" "Princess Sofia" "Prociono" "Prompt" "Prosto One" "Proza Libre" "Puritan" "Purple Purse" "Quando" "Quantico" "Quattrocento" "Quattrocento Sans" "Questrial" "Quicksand" "Quintessential" "Qwigley" "Racing Sans One" "Radley" "Rajdhani" "Rakkas" "Raleway" "Raleway Dots" "Ramabhadra" "Ramaraja" "Rambla" "Rammetto One" "Ranchers" "Rancho" "Ranga" "Rasa" "Rationale" "Ravi Prakash" "Red Hat Display" "Red Hat Text" "Redressed" "Reem Kufi" "Reenie Beanie" "Revalia" "Rhodium Libre" "Ribeye" "Ribeye Marrow" "Righteous" "Risque" "Roboto" "Roboto Condensed" "Roboto Mono" "Roboto Slab" "Rochester" "Rock Salt" "Rokkitt" "Romanesco" "Ropa Sans" "Rosario" "Rosarivo" "Rouge Script" "Rozha One" "Rubik" "Rubik Mono One" "Ruda" "Rufina" "Ruge Boogie" "Ruluko" "Rum Raisin" "Ruslan Display" "Russo One" "Ruthie" "Rye" "Sacramento" "Sahitya" "Sail" "Saira" "Saira Condensed" "Saira Extra Condensed" "Saira Semi Condensed" "Saira Stencil One" "Salsa" "Sanchez" "Sancreek" "Sansita" "Sarabun" "Sarala" "Sarina" "Sarpanch" "Satisfy" "Sawarabi Gothic" "Sawarabi Mincho" "Scada" "Scheherazade" "Schoolbell" "Scope One" "Seaweed Script" "Secular One" "Sedgwick Ave" "Sedgwick Ave Display" "Sevillana" "Seymour One" "Shadows Into Light" "Shadows Into Light Two" "Shanti" "Share" "Share Tech" "Share Tech Mono" "Shojumaru" "Short Stack" "Shrikhand" "Siemreap" "Sigmar One" "Signika" "Signika Negative" "Simonetta" "Single Day" "Sintony" "Sirin Stencil" "Six Caps" "Skranji" "Slabo 13px" "Slabo 27px" "Slackey" "Smokum" "Smythe" "Sniglet" "Snippet" "Snowburst One" "Sofadi One" "Sofia" "Song Myung" "Sonsie One" "Sorts Mill Goudy" "Source Code Pro" "Source Sans Pro" "Source Serif Pro" "Space Mono" "Special Elite" "Spectral" "Spectral SC" "Spicy Rice" "Spinnaker" "Spirax" "Squada One" "Sree Krushnadevaraya" "Sriracha" "Srisakdi" "Staatliches" "Stalemate" "Stalinist One" "Stardos Stencil" "Stint Ultra Condensed" "Stint Ultra Expanded" "Stoke" "Strait" "Stylish" "Sue Ellen Francisco" "Suez One" "Sumana" "Sunflower" "Sunshiney" "Supermercado One" "Sura" "Suranna" "Suravaram" "Suwannaphum" "Swanky and Moo Moo" "Syncopate" "Tajawal" "Tangerine" "Taprom" "Tauri" "Taviraj" "Teko" "Telex" "Tenali Ramakrishna" "Tenor Sans" "Text Me One" "Thasadith" "The Girl Next Door" "Tienne" "Tillana" "Timmana" "Tinos" "Titan One" "Titillium Web" "Trade Winds" "Trirong" "Trocchi" "Trochut" "Trykker" "Tulpen One" "Turret Road" "Ubuntu" "Ubuntu Condensed" "Ubuntu Mono" "Ultra" "Uncial Antiqua" "Underdog" "Unica One" "UnifrakturCook" "UnifrakturMaguntia" "Unkempt" "Unlock" "Unna" "VT323" "Vampiro One" "Varela" "Varela Round" "Vast Shadow" "Vesper Libre" "Vibes" "Vibur" "Vidaloka" "Viga" "Voces" "Volkhov" "Vollkorn" "Vollkorn SC" "Voltaire" "Waiting for the Sunrise" "Wallpoet" "Walter Turncoat" "Warnes" "Wellfleet" "Wendy One" "Wire One" "Work Sans" "Yanone Kaffeesatz" "Yantramanav" "Yatra One" "Yellowtail" "Yeon Sung" "Yeseva One" "Yesteryear" "Yrsa" "ZCOOL KuaiLe" "ZCOOL QingKe HuangYou" "ZCOOL XiaoWei" "Zeyada" "Zhi Mang Xing" "Zilla Slab" "Zilla Slab Highlight"] }
def icfs-completer [] { ["italic" "normal"] }
def iclocale-completer [] { ["de" "en" "fr"] }
def icwt-completer [] { ["0" "1" "false" "true"] }
def icretina-completer [] { ["0" "1"] }
def accept-completer [] { ["application/gif" "application/png" "image/svg+xml"] }
def encoding-completer [] { ["base64" "url"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-chart: "string"
    get-chartjs280: "string"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-chart" "get-chartjs280" "commands"] | sort) } | get name | first)
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

# Image-Charts API
#
# GET /chart
# Returns: string
# operationId: getChart
export def "get-chart" [
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
  --cht: string@cht-completer # Chart type (required)
  --chd: string # chart data
  --chds: string # data format with custom scaling
  --choe: string@choe-completer # QRCode data encoding
  --chld: string # QRCode error correction level and optional margin (default: L|4)
  --chxr: string # Axis data-range
  --chxp: string # axis label positions
  --chof: string # Image output format (default: .png)
  --chs: string # Chart size (x)
  --chdl: string # Text for each series, to display in the legend (default: "")
  --chdls: string # Chart legend text and style (default: 000000)
  --chg: string # Solid or dotted grid lines
  --chco: string # series colors (default: F56991,FF9F80,FFC48C,D1F2A5,EFFAB4)
  --chtt: string # chart title (default: "")
  --chts: string # chart title colors and font size (default: "")
  --chxt: string # Display values on your axis lines or change which axes are shown (default: "")
  --chxl: string # Custom string axis labels on any axis (default: "")
  --chxs: string # Font size, color for axis labels, both custom labels and default label values
  --chm: string # compound charts and line fills (default: "")
  --chls: string # line thickness and solid/dashed style (default: "")
  --chl: string # bar, pie slice, doughnut slice and polar slice chart labels (required, default: "")
  --chlps: string # Position and style of labels on data (default: "")
  --chma: string # chart margins
  --chdlp: string # Position of the legend and order of the legend entries (default: r)
  --chf: string # Background Fills (default: bg,s,FFFFFF)
  --chbh: string # Bar Width and Spacing. (not supported) You can optionally specify custom values for bar widths and spacing between bars and groups. You can only specify one set of width values for all bars. If you don't specify chbh, all bars will be 23 pixels wide, which means that the end bars can be clipped if the total bar + space width is wider than the chart width. (default: 10)
  --chbr: string # Bar corner radius. Display bars with rounded corner. (default: 0)
  --chan: string # gif configuration
  --chli: string # doughnut chart inside label
  --icac: string # image-charts enterprise `account_id`
  --ichm: string # HMAC-SHA256 signature required to activate paid features
  --icff: string@icff-completer # Default font family for all text from Google Fonts. Use same syntax as Google Font CSS API
  --icfs: string@icfs-completer # Default font style for all text
  --iclocale: string@iclocale-completer # localization (ISO 639-1)
  --icwt: oneof<nothing, bool> # (Private) Force to display the watermark EVEN IF the chart was signed with an enterprise account (default: false)
  --icretina: string@icretina-completer # retina mode
  --icqrb: string # Background color for QR Codes (default: FFFFFF)
  --icqrf: string # Foreground color for QR Codes (default: 000000)
]: nothing -> any {
  http-request {
    method: get
    path: "/chart"
    query: [{name: cht, var: cht, required: true}, {name: chd, var: chd}, {name: chds, var: chds}, {name: choe, var: choe}, {name: chld, var: chld}, {name: chxr, var: chxr}, {name: chxp, var: chxp}, {name: chof, var: chof}, {name: chs, var: chs}, {name: chdl, var: chdl}, {name: chdls, var: chdls}, {name: chg, var: chg}, {name: chco, var: chco}, {name: chtt, var: chtt}, {name: chts, var: chts}, {name: chxt, var: chxt}, {name: chxl, var: chxl}, {name: chxs, var: chxs}, {name: chm, var: chm}, {name: chls, var: chls}, {name: chl, var: chl, required: true, default: ""}, {name: chlps, var: chlps}, {name: chma, var: chma}, {name: chdlp, var: chdlp}, {name: chf, var: chf}, {name: chbh, var: chbh}, {name: chbr, var: chbr}, {name: chan, var: chan}, {name: chli, var: chli}, {name: icac, var: icac}, {name: ichm, var: ichm}, {name: icff, var: icff}, {name: icfs, var: icfs}, {name: iclocale, var: iclocale}, {name: icwt, var: icwt}, {name: icretina, var: icretina}, {name: icqrb, var: icqrb}, {name: icqrf, var: icqrf}]
    accept: ["application/png", "application/gif", "image/svg+xml"]
    ok: []
    auth: bearer
  } {
    cht: $cht, chd: $chd, chds: $chds, choe: $choe, chld: $chld, chxr: $chxr, chxp: $chxp, chof: $chof, chs: $chs, chdl: $chdl, chdls: $chdls, chg: $chg, chco: $chco, chtt: $chtt, chts: $chts, chxt: $chxt, chxl: $chxl, chxs: $chxs, chm: $chm, chls: $chls, chl: $chl, chlps: $chlps, chma: $chma, chdlp: $chdlp, chf: $chf, chbh: $chbh, chbr: $chbr, chan: $chan, chli: $chli, icac: $icac, ichm: $ichm, icff: $icff, icfs: $icfs, iclocale: $iclocale, icwt: $icwt, icretina: $icretina, icqrb: $icqrb, icqrf: $icqrf
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Chart.js as image API
#
# GET /chart.js/2.8.0
# Returns: string
# operationId: getChartjs280
export def "get-chartjs280" [
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
  --c: string # Javascript/JSON definition of the chart. Use a Chart.js configuration object.
  --chart: string # Javascript/JSON definition of the chart. Use a Chart.js configuration object.
  --width: int # Width of the chart (default: 500)
  --height: int # Height of the chart (default: 300)
  --background-color: string # Background of the chart canvas. Accepts rgb (rgb(255,255,120)), colors (red), and url-encoded hex values (%23ff00ff). Abbreviated as "bkg"
  --bkg: string # Background of the chart canvas. Accepts rgb (rgb(255,255,120)), colors (red), and url-encoded hex values (%23ff00ff). Abbreviated as "bkg"
  --encoding: string@encoding-completer # Encoding of your "chart" parameter. Accepted values are url and base64. (default: url)
  --icac: string # image-charts enterprise `account_id`
  --ichm: string # HMAC-SHA256 signature required to activate paid features
  --icretina: string@icretina-completer # retina mode
]: nothing -> any {
  http-request {
    method: get
    path: "/chart.js/2.8.0"
    query: [{name: c, var: c}, {name: chart, var: chart}, {name: width, var: width}, {name: height, var: height}, {name: backgroundColor, var: background_color}, {name: bkg, var: bkg}, {name: encoding, var: encoding}, {name: icac, var: icac}, {name: ichm, var: ichm}, {name: icretina, var: icretina}]
    accept: ["application/png", "application/gif", "image/svg+xml"]
    ok: []
    auth: bearer
  } {
    c: $c, chart: $chart, width: $width, height: $height, background_color: $background_color, bkg: $bkg, encoding: $encoding, icac: $icac, ichm: $ichm, icretina: $icretina
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
