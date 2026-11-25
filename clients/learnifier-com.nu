# Auto-generated client for Learnifier v1.1.0
# Source: https://api.apis.guru/v2/specs/learnifier.com/1.1.0/swagger.json
# Auth: --token flag or $env.LEARNIFIER_TOKEN

const CLIENT = {
  base_url: "http://learnifier.com"
  token_env_var: "LEARNIFIER_TOKEN"
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

def base-url-completer [] { ["http://learnifier.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["ACTIVATED" "DISABLED" "NEW"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-coursedesigns: "table<created: string, createdBy: string, description: string, enabled: bool, locale: string, locked: string, lockedBy: string, lockedDesign: bool, name: string, softid: string, sticky: bool, tags: list<string>>"
    get-extorgunit: "record<externalId: string, id: int, name: string, parentId: int, type: string>"
    get-extparticipation: "record<accessLink: string, activated: bool, activitiesCompleted: float, activitiesTotal: float, errorMessage: string, expiration: string, externalId: string, firstAccess: string, firstActivation: string, firstMail: string, id: int, inError: bool, lastAccess: string, lastActivation: string, lastMail: string, projectId: int, userId: string>"
    get-extproject: "record<adminUrl: string, country: string, created: string, createdBy: string, designId: int, externalId: string, id: int, locale: string, name: string, note: string, orgId: int, status: string, timezone: string, userDescription: string, userTitle: string>"
    get-extuser: "record<authorizationPossible: bool, displayName: string, externalId: string, firstLogin: string, firstName: string, hardLock: bool, homeOrg: int, id: string, lastLogin: string, lastName: string, locked: bool, prefs: record<locale: string>, primaryEmail: string>"
    get-globalusergroups: "table<created: string, createdBy: string, id: int, name: string, parent: int, softiId: string, updated: string, updatedBy: string>"
    get-globalusergroups-groupid-members: "table<authorizationPossible: bool, displayName: string, externalId: string, firstLogin: string, firstName: string, hardLock: bool, homeOrg: int, id: string, lastLogin: string, lastName: string, locked: bool, prefs: record<locale: string>, primaryEmail: string>"
    get-orgunits: "record<orgUnits: table<externalId: string, id: int, name: string, parentId: int, type: string>>"
    post-orgunits: "record<ouId: float>"
    get-orgunits-orgid: "record<externalId: string, id: int, name: string, parentId: int, type: string>"
    get-orgunits-orgid-projects: "table<adminUrl: string, country: string, created: string, createdBy: string, designId: int, externalId: string, id: int, locale: string, name: string, note: string, orgId: int, status: string, timezone: string, userDescription: string, userTitle: string>"
    post-orgunits-orgid-projects: "record<adminUrl: string, country: string, created: string, createdBy: string, designId: int, externalId: string, id: int, locale: string, name: string, note: string, orgId: int, status: string, timezone: string, userDescription: string, userTitle: string>"
    get-orgunits-orgid-projects-projectid: "record<adminUrl: string, country: string, created: string, createdBy: string, designId: int, externalId: string, id: int, locale: string, name: string, note: string, orgId: int, status: string, timezone: string, userDescription: string, userTitle: string>"
    patch-orgunits-orgid-projects-projectid: "record<adminUrl: string, country: string, created: string, createdBy: string, designId: int, externalId: string, id: int, locale: string, name: string, note: string, orgId: int, status: string, timezone: string, userDescription: string, userTitle: string>"
    get-orgunits-orgid-projects-projectid-participants: "table<accessLink: string, activated: bool, activitiesCompleted: float, activitiesTotal: float, errorMessage: string, expiration: string, externalId: string, firstAccess: string, firstActivation: string, firstMail: string, id: int, inError: bool, lastAccess: string, lastActivation: string, lastMail: string, projectId: int, userId: string>"
    post-orgunits-orgid-projects-projectid-participants-participant-id-loginlink: "record<link: string>"
    get-orgunits-orgid-projects-projectid-teammembers: "table<roles: record<name: string, roleid: string>, userid: string>"
    get-orgunits-orgid-usergroups: "table<children: list<any>, globalId: int, groupId: int, name: string, parent: int, userGroup: int>"
    post-orgunits-orgid-usergroups: "table<groupId: int>"
    get-orgunits-orgid-usergroups-groupid: "record<children: list<any>, globalId: int, groupId: int, name: string, parent: int, userGroup: int>"
    get-orgunits-orgid-usergroups-groupid-members: "table<authorizationPossible: bool, displayName: string, externalId: string, firstLogin: string, firstName: string, hardLock: bool, homeOrg: int, id: string, lastLogin: string, lastName: string, locked: bool, prefs: record<locale: string>, primaryEmail: string>"
    post-orgunits-orgid-usergroups-groupid-members: "record<uuid: string>"
    get-users: "table<authorizationPossible: bool, displayName: string, externalId: string, firstLogin: string, firstName: string, hardLock: bool, homeOrg: int, id: string, lastLogin: string, lastName: string, locked: bool, prefs: record<locale: string>, primaryEmail: string, backOfficeRoles: list<record>, clientRoles: list<record>>"
    post-users: "record<userId: string>"
    get-users-userid: "record<authorizationPossible: bool, displayName: string, externalId: string, firstLogin: string, firstName: string, hardLock: bool, homeOrg: int, id: string, lastLogin: string, lastName: string, locked: bool, prefs: record<locale: string>, primaryEmail: string>"
    get-users-userid-project-participations: "record<accessLink: string, activated: bool, activitiesCompleted: float, activitiesTotal: float, errorMessage: string, expiration: string, externalId: string, firstAccess: string, firstActivation: string, firstMail: string, id: int, inError: bool, lastAccess: string, lastActivation: string, lastMail: string, projectId: int, projectName: string, projectOrgId: int, projectStatus: string, projectThumbnail: string, projectUserTitle: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-coursedesigns" "get-extorgunit" "get-extparticipation" "get-extproject" "get-extuser" "get-globalusergroups" "get-globalusergroups-groupid-members" "get-orgunits" "post-orgunits" "get-orgunits-orgid" "patch-orgunits-orgid" "get-orgunits-orgid-projects" "post-orgunits-orgid-projects" "delete-orgunits-orgid-projects-projectid" "get-orgunits-orgid-projects-projectid" "patch-orgunits-orgid-projects-projectid" "get-orgunits-orgid-projects-projectid-participants" "post-orgunits-orgid-projects-projectid-participants" "delete-orgunits-orgid-projects-projectid-participants-participant-id" "post-orgunits-orgid-projects-projectid-participants-participant-id-activate" "post-orgunits-orgid-projects-projectid-participants-participant-id-loginlink" "get-orgunits-orgid-projects-projectid-teammembers" "get-orgunits-orgid-usergroups" "post-orgunits-orgid-usergroups" "get-orgunits-orgid-usergroups-groupid" "get-orgunits-orgid-usergroups-groupid-members" "post-orgunits-orgid-usergroups-groupid-members" "delete-orgunits-orgid-usergroups-groupid-members-uuid" "get-users" "post-users" "get-users-userid" "patch-users-userid" "get-users-userid-pic-key-apikey" "get-users-userid-project-participations" "commands"] | sort) } | get name | first)
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

# Lists all global course design templates
#
# GET /coursedesigns
# Returns: table<created: string, createdBy: string, description: string, enabled: bool, locale: string, locked: string, lockedBy: string, lockedDesign: bool, name: string, softid: string, sticky: bool, tags: list<string>>
export def "get-coursedesigns" [
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
    path: "/coursedesigns"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Organization Unit with External Id
#
# GET /extorgunit
# Returns: record<externalId: string, id: int, name: string, parentId: int, type: string>
export def "get-extorgunit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --extid: string # The external id of the organization unit (required, format: extid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/extorgunit"
    query: [{name: extid, var: extid, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    extid: $extid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a participation by external id
#
# GET /extparticipation
# Returns: record<accessLink: string, activated: bool, activitiesCompleted: float, activitiesTotal: float, errorMessage: string, expiration: string, externalId: string, firstAccess: string, firstActivation: string, firstMail: string, id: int, inError: bool, lastAccess: string, lastActivation: string, lastMail: string, projectId: int, userId: string>
export def "get-extparticipation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --extid: string # The external id of the participation (required, format: extid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/extparticipation"
    query: [{name: extid, var: extid, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    extid: $extid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets Organization Unit by external id
#
# GET /extproject
# Returns: record<adminUrl: string, country: string, created: string, createdBy: string, designId: int, externalId: string, id: int, locale: string, name: string, note: string, orgId: int, status: string, timezone: string, userDescription: string, userTitle: string>
export def "get-extproject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --extid: string # The external id of the organization unit (required, format: extid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/extproject"
    query: [{name: extid, var: extid, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    extid: $extid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a user by external id
#
# GET /extuser
# Returns: record<authorizationPossible: bool, displayName: string, externalId: string, firstLogin: string, firstName: string, hardLock: bool, homeOrg: int, id: string, lastLogin: string, lastName: string, locked: bool, prefs: record<locale: string>, primaryEmail: string>
export def "get-extuser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --extid: string # The external id of the user (required, format: extid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/extuser"
    query: [{name: extid, var: extid, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    extid: $extid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Global User Groups.
#
# GET /globalusergroups
# Returns: table<created: string, createdBy: string, id: int, name: string, parent: int, softiId: string, updated: string, updatedBy: string>
export def "get-globalusergroups" [
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
    path: "/globalusergroups"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of all users in group.
#
# GET /globalusergroups/{groupid}/members
# Returns: table<authorizationPossible: bool, displayName: string, externalId: string, firstLogin: string, firstName: string, hardLock: bool, homeOrg: int, id: string, lastLogin: string, lastName: string, locked: bool, prefs: record<locale: string>, primaryEmail: string>
export def "get-globalusergroups-groupid-members" [
  groupid: int
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
    path: "/globalusergroups/{groupid}/members"
    path_params: [{name: groupid, var: groupid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    groupid: $groupid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Organization Units
#
# GET /orgunits
# Returns: record<orgUnits: table<externalId: string, id: int, name: string, parentId: int, type: string>>
export def "get-orgunits" [
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
    path: "/orgunits"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds an Organization Unit
#
# POST /orgunits
# Returns: record<ouId: float>
export def "post-orgunits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --caller: string # The id of the user that initiated this operation (format: uuid, e.g. 81590981-1e05-4fd5-aa15-15bc4b06cf7f)
  --client-number: string # A client number. Sometimes used when communicating with external system. Must be unique if specified. (e.g. X-1234)
  --country: string # The country code that best matches the organization unit. If unspecified the platform default will be set. (format: locale, e.g. se)
  display_name: string # The name shown for the organization unit (e.g. Sample Corp)
  --external-id: string # The external id (foreign key). Must not exceed 255 characters.
  --parent: float # A Organization Unit id of the parent Organization Unit (optional). (format: id64, e.g. 1234)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/orgunits"
    body: {content_type: "application/json", kind: json, fields: [{name: caller, var: caller}, {name: clientNumber, var: client_number}, {name: country, var: country}, {name: displayName, var: display_name}, {name: externalId, var: external_id}, {name: parent, var: parent}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    caller: $caller, client_number: $client_number, country: $country, display_name: $display_name, external_id: $external_id, parent: $parent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Organization Unit
#
# GET /orgunits/{orgid}
# Returns: record<externalId: string, id: int, name: string, parentId: int, type: string>
export def "get-orgunits-orgid" [
  orgid: int
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
    path: "/orgunits/{orgid}"
    path_params: [{name: orgid, var: orgid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    orgid: $orgid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an Organization Unit
#
# PATCH /orgunits/{orgid}
export def "patch-orgunits-orgid" [
  orgid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --caller: string # The id of the user that initiated this operation (format: uuid, e.g. 81590981-1e05-4fd5-aa15-15bc4b06cf7f)
  --client-number: string # A client number. Sometimes used when communicating with external system. Must be unique if specified. (e.g. X-1234)
  --country: string # The country code that best matches the organization unit. If unspecified the platform default will be set. (format: locale, e.g. se)
  --display-name: string # The name shown for the organization unit (e.g. Sample Corp)
  --external-id: string # The external id (foreign key). Must not exceed 255 characters.
  --parent: float # A Organization Unit id of the parent Organization Unit (optional). (format: id64, e.g. 1234)
]: any -> any {
  $in | http-request {
    method: patch
    path: "/orgunits/{orgid}"
    path_params: [{name: orgid, var: orgid}]
    body: {content_type: "application/json", kind: json, fields: [{name: caller, var: caller}, {name: clientNumber, var: client_number}, {name: country, var: country}, {name: displayName, var: display_name}, {name: externalId, var: external_id}, {name: parent, var: parent}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    orgid: $orgid, caller: $caller, client_number: $client_number, country: $country, display_name: $display_name, external_id: $external_id, parent: $parent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Organization Unit Projects
#
# GET /orgunits/{orgid}/projects
# Returns: table<adminUrl: string, country: string, created: string, createdBy: string, designId: int, externalId: string, id: int, locale: string, name: string, note: string, orgId: int, status: string, timezone: string, userDescription: string, userTitle: string>
export def "get-orgunits-orgid-projects" [
  orgid: float
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
    path: "/orgunits/{orgid}/projects"
    path_params: [{name: orgid, var: orgid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    orgid: $orgid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create project
#
# POST /orgunits/{orgid}/projects
# Returns: record<adminUrl: string, country: string, created: string, createdBy: string, designId: int, externalId: string, id: int, locale: string, name: string, note: string, orgId: int, status: string, timezone: string, userDescription: string, userTitle: string>
export def "post-orgunits-orgid-projects" [
  orgid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # The country code. Default value will be used if not specified (format: countrycode, e.g. SE)
  --created-by: string # The id of the user that created the project. If the creator is not known this value can be *null* or not specified (format: uuid, e.g. 8c102c8e-fabd-4c8a-b245-4d2d2f77fc4b)
  design_id: int # The id of the design this project should be based on (format: int64)
  --locale: string # The primary locale for this project. Default value will be used if not specified (format: locale, e.g. en-US)
  name: string # The internal name of the project
  --note: string # The internal note field
  --timezone: string # The main timezone for the project. Do not specify for default timezone (format: timezone, e.g. Europe/Stockholm)
  --user-description: string # The description presented to participants. Do not specify for default value from design
  --user-title: string # The title presented to participants. Do not specify for default value from design
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/orgunits/{orgid}/projects"
    path_params: [{name: orgid, var: orgid}]
    body: {content_type: "application/json", kind: json, fields: [{name: country, var: country}, {name: createdBy, var: created_by}, {name: designId, var: design_id}, {name: locale, var: locale}, {name: name, var: name}, {name: note, var: note}, {name: timezone, var: timezone}, {name: userDescription, var: user_description}, {name: userTitle, var: user_title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    orgid: $orgid, country: $country, created_by: $created_by, design_id: $design_id, locale: $locale, name: $name, note: $note, timezone: $timezone, user_description: $user_description, user_title: $user_title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the project
#
# DELETE /orgunits/{orgid}/projects/{projectid}
export def "delete-orgunits-orgid-projects-projectid" [
  orgid: int
  projectid: int
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
    path: "/orgunits/{orgid}/projects/{projectid}"
    path_params: [{name: orgid, var: orgid}, {name: projectid, var: projectid}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    orgid: $orgid, projectid: $projectid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Project information
#
# GET /orgunits/{orgid}/projects/{projectid}
# Returns: record<adminUrl: string, country: string, created: string, createdBy: string, designId: int, externalId: string, id: int, locale: string, name: string, note: string, orgId: int, status: string, timezone: string, userDescription: string, userTitle: string>
export def "get-orgunits-orgid-projects-projectid" [
  orgid: int
  projectid: int
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
    path: "/orgunits/{orgid}/projects/{projectid}"
    path_params: [{name: orgid, var: orgid}, {name: projectid, var: projectid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    orgid: $orgid, projectid: $projectid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update project information
#
# PATCH /orgunits/{orgid}/projects/{projectid}
# Returns: record<adminUrl: string, country: string, created: string, createdBy: string, designId: int, externalId: string, id: int, locale: string, name: string, note: string, orgId: int, status: string, timezone: string, userDescription: string, userTitle: string>
export def "patch-orgunits-orgid-projects-projectid" [
  orgid: int
  projectid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # The country code (format: countrycode, e.g. SE)
  --locale: string # The primary locale for this project (format: locale, e.g. en-US)
  --name: string # The internal name of the project
  --note: string # The internal note field
  --status: string@status-completer # Project status. Can be either ACTIVATED, NEW or DISABLED (e.g. ACTIVATED)
  --timezone: string # The main timezone for the project (format: timezone, e.g. Europe/Stockholm)
  --user-description: string # The description presented to participants. This value can be *null*.
  --user-title: string # The title presented to participants
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/orgunits/{orgid}/projects/{projectid}"
    path_params: [{name: orgid, var: orgid}, {name: projectid, var: projectid}]
    body: {content_type: "application/json", kind: json, fields: [{name: country, var: country}, {name: locale, var: locale}, {name: name, var: name}, {name: note, var: note}, {name: status, var: status}, {name: timezone, var: timezone}, {name: userDescription, var: user_description}, {name: userTitle, var: user_title}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    orgid: $orgid, projectid: $projectid, country: $country, locale: $locale, name: $name, note: $note, status: $status, timezone: $timezone, user_description: $user_description, user_title: $user_title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Project participants
#
# GET /orgunits/{orgid}/projects/{projectid}/participants
# Returns: table<accessLink: string, activated: bool, activitiesCompleted: float, activitiesTotal: float, errorMessage: string, expiration: string, externalId: string, firstAccess: string, firstActivation: string, firstMail: string, id: int, inError: bool, lastAccess: string, lastActivation: string, lastMail: string, projectId: int, userId: string>
export def "get-orgunits-orgid-projects-projectid-participants" [
  orgid: int
  projectid: int
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
    path: "/orgunits/{orgid}/projects/{projectid}/participants"
    path_params: [{name: orgid, var: orgid}, {name: projectid, var: projectid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    orgid: $orgid, projectid: $projectid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add participant
#
# POST /orgunits/{orgid}/projects/{projectid}/participants
export def "post-orgunits-orgid-projects-projectid-participants" [
  orgid: int
  projectid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email of the user. If no user exists with the specified email a user will be created with default values and the specified email. (format: email, e.g. user@example.com)
  --extid: string # An optional external id for the participation
  --userid: string # format: uuid, e.g. 81590981-1e05-4fd5-aa15-15bc4b06cf7f
]: any -> any {
  $in | http-request {
    method: post
    path: "/orgunits/{orgid}/projects/{projectid}/participants"
    path_params: [{name: orgid, var: orgid}, {name: projectid, var: projectid}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: extid, var: extid}, {name: userid, var: userid}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    orgid: $orgid, projectid: $projectid, email: $email, extid: $extid, userid: $userid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a participant
#
# DELETE /orgunits/{orgid}/projects/{projectid}/participants/${participantId}
export def "delete-orgunits-orgid-projects-projectid-participants-participant-id" [
  orgid: int
  projectid: int
  participant_id: int
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
    path: "/orgunits/{orgid}/projects/{projectid}/participants/${participantId}"
    path_params: [{name: orgid, var: orgid}, {name: projectid, var: projectid}, {name: participantId, var: participant_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    orgid: $orgid, projectid: $projectid, participant_id: $participant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Activate participant
#
# POST /orgunits/{orgid}/projects/{projectid}/participants/${participantId}/activate
export def "post-orgunits-orgid-projects-projectid-participants-participant-id-activate" [
  orgid: int
  projectid: int
  participant_id: int
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
    path: "/orgunits/{orgid}/projects/{projectid}/participants/${participantId}/activate"
    path_params: [{name: orgid, var: orgid}, {name: projectid, var: projectid}, {name: participantId, var: participant_id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    orgid: $orgid, projectid: $projectid, participant_id: $participant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Participant login link
#
# POST /orgunits/{orgid}/projects/{projectid}/participants/${participantId}/loginlink
# Returns: record<link: string>
export def "post-orgunits-orgid-projects-projectid-participants-participant-id-loginlink" [
  orgid: int
  projectid: int
  participant_id: int
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
    path: "/orgunits/{orgid}/projects/{projectid}/participants/${participantId}/loginlink"
    path_params: [{name: orgid, var: orgid}, {name: projectid, var: projectid}, {name: participantId, var: participant_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    orgid: $orgid, projectid: $projectid, participant_id: $participant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Project team members
#
# GET /orgunits/{orgid}/projects/{projectid}/teammembers
# Returns: table<roles: record<name: string, roleid: string>, userid: string>
export def "get-orgunits-orgid-projects-projectid-teammembers" [
  orgid: int
  projectid: int
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
    path: "/orgunits/{orgid}/projects/{projectid}/teammembers"
    path_params: [{name: orgid, var: orgid}, {name: projectid, var: projectid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    orgid: $orgid, projectid: $projectid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List User Groups.
#
# GET /orgunits/{orgid}/usergroups
# Returns: table<children: list<any>, globalId: int, groupId: int, name: string, parent: int, userGroup: int>
export def "get-orgunits-orgid-usergroups" [
  orgid: int
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
    path: "/orgunits/{orgid}/usergroups"
    path_params: [{name: orgid, var: orgid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    orgid: $orgid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a User Group.
#
# POST /orgunits/{orgid}/usergroups
# Returns: table<groupId: int>
export def "post-orgunits-orgid-usergroups" [
  orgid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of group. (e.g. Foo)
  --parent: int # Optional ID of parent group. (format: int64, e.g. 1010)
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/orgunits/{orgid}/usergroups"
    path_params: [{name: orgid, var: orgid}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: parent, var: parent}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    orgid: $orgid, name: $name, parent: $parent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get user group
#
# GET /orgunits/{orgid}/usergroups/{groupid}
# Returns: record<children: list<any>, globalId: int, groupId: int, name: string, parent: int, userGroup: int>
export def "get-orgunits-orgid-usergroups-groupid" [
  orgid: int
  groupid: int
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
    path: "/orgunits/{orgid}/usergroups/{groupid}"
    path_params: [{name: orgid, var: orgid}, {name: groupid, var: groupid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    orgid: $orgid, groupid: $groupid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of all users in group.
#
# GET /orgunits/{orgid}/usergroups/{groupid}/members
# Returns: table<authorizationPossible: bool, displayName: string, externalId: string, firstLogin: string, firstName: string, hardLock: bool, homeOrg: int, id: string, lastLogin: string, lastName: string, locked: bool, prefs: record<locale: string>, primaryEmail: string>
export def "get-orgunits-orgid-usergroups-groupid-members" [
  orgid: int
  groupid: int
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
    path: "/orgunits/{orgid}/usergroups/{groupid}/members"
    path_params: [{name: orgid, var: orgid}, {name: groupid, var: groupid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    orgid: $orgid, groupid: $groupid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add user group member.
#
# POST /orgunits/{orgid}/usergroups/{groupid}/members
# Returns: record<uuid: string>
export def "post-orgunits-orgid-usergroups-groupid-members" [
  orgid: int
  groupid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  uuid: string # UUID of user to add to this group. (format: uuid)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/orgunits/{orgid}/usergroups/{groupid}/members"
    path_params: [{name: orgid, var: orgid}, {name: groupid, var: groupid}]
    body: {content_type: "application/json", kind: json, fields: [{name: uuid, var: uuid}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    orgid: $orgid, groupid: $groupid, uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove user group member.
#
# DELETE /orgunits/{orgid}/usergroups/{groupid}/members/{uuid}
export def "delete-orgunits-orgid-usergroups-groupid-members-uuid" [
  orgid: int
  groupid: int
  uuid: string
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
    path: "/orgunits/{orgid}/usergroups/{groupid}/members/{uuid}"
    path_params: [{name: orgid, var: orgid}, {name: groupid, var: groupid}, {name: uuid, var: uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    orgid: $orgid, groupid: $groupid, uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all users
#
# GET /users
# Returns: table<authorizationPossible: bool, displayName: string, externalId: string, firstLogin: string, firstName: string, hardLock: bool, homeOrg: int, id: string, lastLogin: string, lastName: string, locked: bool, prefs: record<locale: string>, primaryEmail: string, backOfficeRoles: list<record>, clientRoles: list<record>>
export def "get-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of users to return (format: integer, default: 5000)
  --offset: int # The offset to start listing users from (format: integer, default: 0)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a user
#
# POST /users
# Returns: record<userId: string>
export def "post-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-name: string # The name shown when the user is listed (e.g. Jane Doe)
  --external-id: string # The external id (foreign key). Must not exceed 255 characters.
  --first-name: string # The first (given) name of the user (e.g. Jane)
  --hard-lock: oneof<nothing, bool> # True if the user should be locked from the system
  --home-org: int # The primary organization for the user. Must match the id of an Organization Unit. (format: int64, e.g. 1234)
  --last-name: any # The last name (surname) of the user (format: string, e.g. Doe)
  --locale: string # The user's preferred language/locale setting. Affects date and number formatting. (format: locale, e.g. en-US)
  --primary-email: string # The primary email for the user. Used for communication from the platform. (e.g. jane.doe@example.com)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users"
    body: {content_type: "application/json", kind: json, fields: [{name: displayName, var: display_name}, {name: externalId, var: external_id}, {name: firstName, var: first_name}, {name: hardLock, var: hard_lock}, {name: homeOrg, var: home_org}, {name: lastName, var: last_name}, {name: locale, var: locale}, {name: primaryEmail, var: primary_email}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    display_name: $display_name, external_id: $external_id, first_name: $first_name, hard_lock: $hard_lock, home_org: $home_org, last_name: $last_name, locale: $locale, primary_email: $primary_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# User information
#
# GET /users/{userid}
# Returns: record<authorizationPossible: bool, displayName: string, externalId: string, firstLogin: string, firstName: string, hardLock: bool, homeOrg: int, id: string, lastLogin: string, lastName: string, locked: bool, prefs: record<locale: string>, primaryEmail: string>
export def "get-users-userid" [
  userid: string
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
    path: "/users/{userid}"
    path_params: [{name: userid, var: userid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    userid: $userid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates user information
#
# PATCH /users/{userid}
export def "patch-users-userid" [
  userid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-name: string # The name shown when the user is listed (e.g. Jane Doe)
  --external-id: string # The external id (foreign key). Must not exceed 255 characters.
  --first-name: string # The first (given) name of the user (e.g. Jane)
  --hard-lock: oneof<nothing, bool> # True if the user should be locked from the system
  --home-org: int # The primary organization for the user. Must match the id of an Organization Unit. (format: int64, e.g. 1234)
  --last-name: any # The last name (surname) of the user (format: string, e.g. Doe)
  --locale: string # The user's preferred language/locale setting. Affects date and number formatting. (format: locale, e.g. en-US)
  --primary-email: string # The primary email for the user. Used for communication from the platform. (e.g. jane.doe@example.com)
]: any -> any {
  $in | http-request {
    method: patch
    path: "/users/{userid}"
    path_params: [{name: userid, var: userid}]
    body: {content_type: "application/json", kind: json, fields: [{name: displayName, var: display_name}, {name: externalId, var: external_id}, {name: firstName, var: first_name}, {name: hardLock, var: hard_lock}, {name: homeOrg, var: home_org}, {name: lastName, var: last_name}, {name: locale, var: locale}, {name: primaryEmail, var: primary_email}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    userid: $userid, display_name: $display_name, external_id: $external_id, first_name: $first_name, hard_lock: $hard_lock, home_org: $home_org, last_name: $last_name, locale: $locale, primary_email: $primary_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# User profile picture
#
# GET /users/{userid}/pic?key={APIKEY}
export def "get-users-userid-pic-key-apikey" [
  userid: string
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
    path: "/users/{userid}/pic"
    fixed_query: "key={APIKEY}"
    path_params: [{name: userid, var: userid}]
    accept: ["application/json"]
    ok: [200, 302]
    auth: bearer
  } {
    userid: $userid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the projects the user is a participant in.
#
# GET /users/{userid}/projectParticipations
# Returns: record<accessLink: string, activated: bool, activitiesCompleted: float, activitiesTotal: float, errorMessage: string, expiration: string, externalId: string, firstAccess: string, firstActivation: string, firstMail: string, id: int, inError: bool, lastAccess: string, lastActivation: string, lastMail: string, projectId: int, projectName: string, projectOrgId: int, projectStatus: string, projectThumbnail: string, projectUserTitle: string>
export def "get-users-userid-project-participations" [
  userid: string
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
    path: "/users/{userid}/projectParticipations"
    path_params: [{name: userid, var: userid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    userid: $userid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
