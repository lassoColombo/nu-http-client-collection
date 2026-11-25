# Auto-generated client for OpenAI API v1.2.0
# Source: https://api.apis.guru/v2/specs/openai.com/1.2.0/openapi.json
# Auth: --token flag or $env.OPENAI_API_TOKEN

const CLIENT = {
  base_url: "https://api.openai.com/v1"
  token_env_var: "OPENAI_API_TOKEN"
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

def base-url-completer [] { ["https://api.openai.com/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def response-format-completer [] { ["b64_json" "url"] }
def size-completer [] { ["1024x1024" "256x256" "512x512"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    create-answer: "record<answers: list<string>, completion: string, model: string, object: string, search_model: string, selected_documents: table<document: int, text: string>>"
    create-transcription: "record<text: string>"
    create-translation: "record<text: string>"
    create-chat-completion: "record<choices: table<finish_reason: string, index: int, message: record>, created: int, id: string, model: string, object: string, usage: record<completion_tokens: int, prompt_tokens: int, total_tokens: int>>"
    create-classification: "record<completion: string, label: string, model: string, object: string, search_model: string, selected_examples: table<document: int, label: string, text: string>>"
    create-completion: "record<choices: table<finish_reason: string, index: int, logprobs: record, text: string>, created: int, id: string, model: string, object: string, usage: record<completion_tokens: int, prompt_tokens: int, total_tokens: int>>"
    create-edit: "record<choices: table<finish_reason: string, index: int, logprobs: record, text: string>, created: int, object: string, usage: record<completion_tokens: int, prompt_tokens: int, total_tokens: int>>"
    create-embedding: "record<data: table<embedding: list, index: int, object: string>, model: string, object: string, usage: record<prompt_tokens: int, total_tokens: int>>"
    list-engines: "record<data: table<created: int, id: string, object: string, ready: bool>, object: string>"
    retrieve-engine: "record<created: int, id: string, object: string, ready: bool>"
    create-search: "record<data: table<document: int, object: string, score: float>, model: string, object: string>"
    list-files: "record<data: table<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>, object: string>"
    create-file: "record<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>"
    delete-file: "record<deleted: bool, id: string, object: string>"
    retrieve-file: "record<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>"
    download-file: "string"
    list-fine-tunes: "record<data: table<created_at: int, events: list, fine_tuned_model: string, hyperparams: record, id: string, model: string, object: string, organization_id: string, result_files: list, status: string, training_files: list, updated_at: int, validation_files: list>, object: string>"
    create-fine-tune: "record<created_at: int, events: table<created_at: int, level: string, message: string, object: string>, fine_tuned_model: string, hyperparams: record, id: string, model: string, object: string, organization_id: string, result_files: table<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>, status: string, training_files: table<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>, updated_at: int, validation_files: table<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>>"
    retrieve-fine-tune: "record<created_at: int, events: table<created_at: int, level: string, message: string, object: string>, fine_tuned_model: string, hyperparams: record, id: string, model: string, object: string, organization_id: string, result_files: table<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>, status: string, training_files: table<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>, updated_at: int, validation_files: table<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>>"
    cancel-fine-tune: "record<created_at: int, events: table<created_at: int, level: string, message: string, object: string>, fine_tuned_model: string, hyperparams: record, id: string, model: string, object: string, organization_id: string, result_files: table<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>, status: string, training_files: table<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>, updated_at: int, validation_files: table<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>>"
    list-fine-tune-events: "record<data: table<created_at: int, level: string, message: string, object: string>, object: string>"
    create-image-edit: "record<created: int, data: table<b64_json: string, url: string>>"
    create-image: "record<created: int, data: table<b64_json: string, url: string>>"
    create-image-variation: "record<created: int, data: table<b64_json: string, url: string>>"
    list-models: "record<data: table<created: int, id: string, object: string, owned_by: string>, object: string>"
    delete-model: "record<deleted: bool, id: string, object: string>"
    retrieve-model: "record<created: int, id: string, object: string, owned_by: string>"
    create-moderation: "record<id: string, model: string, results: table<categories: record, category_scores: record, flagged: bool>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["create-answer" "create-transcription" "create-translation" "create-chat-completion" "create-classification" "create-completion" "create-edit" "create-embedding" "list-engines" "retrieve-engine" "create-search" "list-files" "create-file" "delete-file" "retrieve-file" "download-file" "list-fine-tunes" "create-fine-tune" "retrieve-fine-tune" "cancel-fine-tune" "list-fine-tune-events" "create-image-edit" "create-image" "create-image-variation" "list-models" "delete-model" "retrieve-model" "create-moderation" "commands"] | sort) } | get name | first)
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

# Answers the specified question using the provided documents and examples. The endpoint first [searches](/docs/api-reference/searches) over provided documents or files to find relevant context. The relevant context is combined with the provided examples and question to create the prompt for [completion](/docs/api-reference/completions).
#
# POST /answers
# DEPRECATED
# Returns: record<answers: list<string>, completion: string, model: string, object: string, search_model: string, selected_documents: table<document: int, text: string>>
# operationId: createAnswer
@deprecated
export def "create-answer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --documents: list<string> # List of documents from which the answer for the input `question` should be derived. If this is an empty list, the question will be answered based on the question-answer examples. You should specify either `documents` or a `file`, but not both. (nullable, e.g. ['Japan is an island country in East Asia, located in the northwest Pacific Ocean.', 'Tokyo is the capital and most populous prefecture of Japan.'])
  examples: list # List of (question, answer) pairs that will help steer the model towards the tone and answer format you'd like. We recommend adding 2 to 3 examples. (e.g. [['What is the capital of Canada?', 'Ottawa'], ['Which province is Ottawa in?', 'Ontario']])
  examples_context: string # A text snippet containing the contextual information used to generate the answers for the `examples` you provide. (e.g. Ottawa, Canada's capital, is located in the east of southern Ontario, near the city of Montréal and the U.S. border.)
  --expand: list # If an object name is in the list, we provide the full information of the object; otherwise, we only provide the object ID. Currently we support `completion` and `file` objects for expansion. (nullable, default: [])
  --file: string # The ID of an uploaded file that contains documents to search over. See [upload file](/docs/api-reference/files/upload) for how to upload a file of the desired format and purpose. You should specify either `documents` or a `file`, but not both. (nullable)
  --logit-bias: record # Modify the likelihood of specified tokens appearing in the completion. Accepts a json object that maps tokens (specified by their token ID in the GPT tokenizer) to an associated bias value from -100 to 100. You can use this [tokenizer tool](/tokenizer?view=bpe) (which works for both GPT-2 and GPT-3) to convert text to token IDs. Mathematically, the bias is added to the logits generated by the model prior to sampling. The exact effect will vary per model, but values between -1 and 1 should decrease or increase likelihood of selection; values like -100 or 100 should result in a ban or exclusive selection of the relevant token. As an example, you can pass `{"50256": -100}` to prevent the <|endoftext|> token from being generated. (nullable)
  --logprobs: int # Include the log probabilities on the `logprobs` most likely tokens, as well the chosen tokens. For example, if `logprobs` is 5, the API will return a list of the 5 most likely tokens. The API will always return the `logprob` of the sampled token, so there may be up to `logprobs+1` elements in the response. The maximum value for `logprobs` is 5. If you need more than this, please contact us through our [Help center](https://help.openai.com) and describe your use case. When `logprobs` is set, `completion` will be automatically added into `expand` to get the logprobs. (nullable)
  --max-rerank: int # The maximum number of documents to be ranked by [Search](/docs/api-reference/searches/create) when using `file`. Setting it to a higher value leads to improved accuracy but with increased latency and cost. (nullable, default: 200)
  --max-tokens: int # The maximum number of tokens allowed for the generated answer (nullable, default: 16)
  model: string # ID of the model to use for completion. You can select one of `ada`, `babbage`, `curie`, or `davinci`.
  --n: int # How many answers to generate for each question. (nullable, default: 1)
  question: string # Question to get answered. (e.g. What is the capital of Japan?)
  --return-metadata: oneof<nothing, bool> # A special boolean flag for showing metadata. If set to `true`, each document entry in the returned JSON will contain a "metadata" field. This flag only takes effect when `file` is set. (nullable, default: false)
  --return-prompt: oneof<nothing, bool> # If set to `true`, the returned JSON will include a "prompt" field containing the final prompt that was used to request a completion. This is mainly useful for debugging purposes. (nullable, default: false)
  --search-model: string # ID of the model to use for [Search](/docs/api-reference/searches/create). You can select one of `ada`, `babbage`, `curie`, or `davinci`. (nullable, default: ada)
  --stop: any # Up to 4 sequences where the API will stop generating further tokens. The returned text will not contain the stop sequence. (nullable)
  --temperature: float # What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. (nullable, default: 0)
  --user: string # A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse. [Learn more](/docs/guides/safety-best-practices/end-user-ids). (e.g. user-1234)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/answers"
    body: {content_type: "application/json", kind: json, fields: [{name: documents, var: documents}, {name: examples, var: examples}, {name: examples_context, var: examples_context}, {name: expand, var: expand}, {name: file, var: file}, {name: logit_bias, var: logit_bias}, {name: logprobs, var: logprobs}, {name: max_rerank, var: max_rerank}, {name: max_tokens, var: max_tokens}, {name: model, var: model}, {name: n, var: n}, {name: question, var: question}, {name: return_metadata, var: return_metadata}, {name: return_prompt, var: return_prompt}, {name: search_model, var: search_model}, {name: stop, var: stop}, {name: temperature, var: temperature}, {name: user, var: user}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    documents: $documents, examples: $examples, examples_context: $examples_context, expand: $expand, file: $file, logit_bias: $logit_bias, logprobs: $logprobs, max_rerank: $max_rerank, max_tokens: $max_tokens, model: $model, n: $n, question: $question, return_metadata: $return_metadata, return_prompt: $return_prompt, search_model: $search_model, stop: $stop, temperature: $temperature, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transcribes audio into the input language.
#
# POST /audio/transcriptions
# Returns: record<text: string>
# operationId: createTranscription
export def "create-transcription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # The audio file to transcribe, in one of these formats: mp3, mp4, mpeg, mpga, m4a, wav, or webm. (format: binary)
  --language: string # The language of the input audio. Supplying the input language in [ISO-639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) format will improve accuracy and latency.
  model: string # ID of the model to use. Only `whisper-1` is currently available.
  --prompt: string # An optional text to guide the model's style or continue a previous audio segment. The [prompt](/docs/guides/speech-to-text/prompting) should match the audio language.
  --response-format: string # The format of the transcript output, in one of these options: json, text, srt, verbose_json, or vtt. (default: json)
  --temperature: float # The sampling temperature, between 0 and 1. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. If set to 0, the model will use [log probability](https://en.wikipedia.org/wiki/Log_probability) to automatically increase the temperature until certain thresholds are hit. (default: 0)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/audio/transcriptions"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}, {name: language, var: language}, {name: model, var: model}, {name: prompt, var: prompt}, {name: response_format, var: response_format}, {name: temperature, var: temperature}], files: [file]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file: $file, language: $language, model: $model, prompt: $prompt, response_format: $response_format, temperature: $temperature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Translates audio into into English.
#
# POST /audio/translations
# Returns: record<text: string>
# operationId: createTranslation
export def "create-translation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # The audio file to translate, in one of these formats: mp3, mp4, mpeg, mpga, m4a, wav, or webm. (format: binary)
  model: string # ID of the model to use. Only `whisper-1` is currently available.
  --prompt: string # An optional text to guide the model's style or continue a previous audio segment. The [prompt](/docs/guides/speech-to-text/prompting) should be in English.
  --response-format: string # The format of the transcript output, in one of these options: json, text, srt, verbose_json, or vtt. (default: json)
  --temperature: float # The sampling temperature, between 0 and 1. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. If set to 0, the model will use [log probability](https://en.wikipedia.org/wiki/Log_probability) to automatically increase the temperature until certain thresholds are hit. (default: 0)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/audio/translations"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}, {name: model, var: model}, {name: prompt, var: prompt}, {name: response_format, var: response_format}, {name: temperature, var: temperature}], files: [file]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file: $file, model: $model, prompt: $prompt, response_format: $response_format, temperature: $temperature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a completion for the chat message
#
# POST /chat/completions
# Returns: record<choices: table<finish_reason: string, index: int, message: record>, created: int, id: string, model: string, object: string, usage: record<completion_tokens: int, prompt_tokens: int, total_tokens: int>>
# operationId: createChatCompletion
export def "create-chat-completion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --frequency-penalty: float # Number between -2.0 and 2.0. Positive values penalize new tokens based on their existing frequency in the text so far, decreasing the model's likelihood to repeat the same line verbatim. [See more information about frequency and presence penalties.](/docs/api-reference/parameter-details) (nullable, default: 0)
  --logit-bias: record # Modify the likelihood of specified tokens appearing in the completion. Accepts a json object that maps tokens (specified by their token ID in the tokenizer) to an associated bias value from -100 to 100. Mathematically, the bias is added to the logits generated by the model prior to sampling. The exact effect will vary per model, but values between -1 and 1 should decrease or increase likelihood of selection; values like -100 or 100 should result in a ban or exclusive selection of the relevant token. (nullable)
  --max-tokens: int # The maximum number of tokens allowed for the generated answer. By default, the number of tokens the model can return will be (4096 - prompt tokens). (default: inf)
  messages: list # The messages to generate chat completions for, in the [chat format](/docs/guides/chat/introduction). — item shape: {content: string, name?: string, role: "system"|"user"|"assistant"}
  model: string # ID of the model to use. Currently, only `gpt-3.5-turbo` and `gpt-3.5-turbo-0301` are supported.
  --n: int # How many chat completion choices to generate for each input message. (nullable, default: 1, e.g. 1)
  --presence-penalty: float # Number between -2.0 and 2.0. Positive values penalize new tokens based on whether they appear in the text so far, increasing the model's likelihood to talk about new topics. [See more information about frequency and presence penalties.](/docs/api-reference/parameter-details) (nullable, default: 0)
  --stop: any # Up to 4 sequences where the API will stop generating further tokens.
  --stream: oneof<nothing, bool> # If set, partial message deltas will be sent, like in ChatGPT. Tokens will be sent as data-only [server-sent events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events#Event_stream_format) as they become available, with the stream terminated by a `data: [DONE]` message. (nullable, default: false)
  --temperature: float # What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. We generally recommend altering this or `top_p` but not both. (nullable, default: 1, e.g. 1)
  --top-p: float # An alternative to sampling with temperature, called nucleus sampling, where the model considers the results of the tokens with top_p probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered. We generally recommend altering this or `temperature` but not both. (nullable, default: 1, e.g. 1)
  --user: string # A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse. [Learn more](/docs/guides/safety-best-practices/end-user-ids). (e.g. user-1234)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/chat/completions"
    body: {content_type: "application/json", kind: json, fields: [{name: frequency_penalty, var: frequency_penalty}, {name: logit_bias, var: logit_bias}, {name: max_tokens, var: max_tokens}, {name: messages, var: messages}, {name: model, var: model}, {name: n, var: n}, {name: presence_penalty, var: presence_penalty}, {name: stop, var: stop}, {name: stream, var: stream}, {name: temperature, var: temperature}, {name: top_p, var: top_p}, {name: user, var: user}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    frequency_penalty: $frequency_penalty, logit_bias: $logit_bias, max_tokens: $max_tokens, messages: $messages, model: $model, n: $n, presence_penalty: $presence_penalty, stop: $stop, stream: $stream, temperature: $temperature, top_p: $top_p, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Classifies the specified `query` using provided examples. The endpoint first [searches](/docs/api-reference/searches) over the labeled examples to select the ones most relevant for the particular query. Then, the relevant examples are combined with the query to construct a prompt to produce the final label via the [completions](/docs/api-reference/completions) endpoint. Labeled examples can be provided via an uploaded `file`, or explicitly listed in the request using the `examples` parameter for quick tests and small scale use cases.
#
# POST /classifications
# DEPRECATED
# Returns: record<completion: string, label: string, model: string, object: string, search_model: string, selected_examples: table<document: int, label: string, text: string>>
# operationId: createClassification
@deprecated
export def "create-classification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --examples: list # A list of examples with labels, in the following format: `[["The movie is so interesting.", "Positive"], ["It is quite boring.", "Negative"], ...]` All the label strings will be normalized to be capitalized. You should specify either `examples` or `file`, but not both. (nullable, e.g. [['Do not see this film.', 'Negative'], ['Smart, provocative and blisteringly funny.', 'Positive']])
  --expand: list # If an object name is in the list, we provide the full information of the object; otherwise, we only provide the object ID. Currently we support `completion` and `file` objects for expansion. (nullable, default: [])
  --file: string # The ID of the uploaded file that contains training examples. See [upload file](/docs/api-reference/files/upload) for how to upload a file of the desired format and purpose. You should specify either `examples` or `file`, but not both. (nullable)
  --labels: list<string> # The set of categories being classified. If not specified, candidate labels will be automatically collected from the examples you provide. All the label strings will be normalized to be capitalized. (nullable, e.g. [Positive, Negative])
  --logit-bias: record # Modify the likelihood of specified tokens appearing in the completion. Accepts a json object that maps tokens (specified by their token ID in the GPT tokenizer) to an associated bias value from -100 to 100. You can use this [tokenizer tool](/tokenizer?view=bpe) (which works for both GPT-2 and GPT-3) to convert text to token IDs. Mathematically, the bias is added to the logits generated by the model prior to sampling. The exact effect will vary per model, but values between -1 and 1 should decrease or increase likelihood of selection; values like -100 or 100 should result in a ban or exclusive selection of the relevant token. As an example, you can pass `{"50256": -100}` to prevent the <|endoftext|> token from being generated. (nullable)
  --logprobs: int # Include the log probabilities on the `logprobs` most likely tokens, as well the chosen tokens. For example, if `logprobs` is 5, the API will return a list of the 5 most likely tokens. The API will always return the `logprob` of the sampled token, so there may be up to `logprobs+1` elements in the response. The maximum value for `logprobs` is 5. If you need more than this, please contact us through our [Help center](https://help.openai.com) and describe your use case. When `logprobs` is set, `completion` will be automatically added into `expand` to get the logprobs. (nullable)
  --max-examples: int # The maximum number of examples to be ranked by [Search](/docs/api-reference/searches/create) when using `file`. Setting it to a higher value leads to improved accuracy but with increased latency and cost. (nullable, default: 200)
  model: string # ID of the model to use. You can use the [List models](/docs/api-reference/models/list) API to see all of your available models, or see our [Model overview](/docs/models/overview) for descriptions of them.
  query: string # Query to be classified. (e.g. The plot is not very attractive.)
  --return-metadata: oneof<nothing, bool> # A special boolean flag for showing metadata. If set to `true`, each document entry in the returned JSON will contain a "metadata" field. This flag only takes effect when `file` is set. (nullable, default: false)
  --return-prompt: oneof<nothing, bool> # If set to `true`, the returned JSON will include a "prompt" field containing the final prompt that was used to request a completion. This is mainly useful for debugging purposes. (nullable, default: false)
  --search-model: string # ID of the model to use for [Search](/docs/api-reference/searches/create). You can select one of `ada`, `babbage`, `curie`, or `davinci`. (nullable, default: ada)
  --temperature: float # What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. (nullable, default: 0, e.g. 0)
  --user: string # A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse. [Learn more](/docs/guides/safety-best-practices/end-user-ids). (e.g. user-1234)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/classifications"
    body: {content_type: "application/json", kind: json, fields: [{name: examples, var: examples}, {name: expand, var: expand}, {name: file, var: file}, {name: labels, var: labels}, {name: logit_bias, var: logit_bias}, {name: logprobs, var: logprobs}, {name: max_examples, var: max_examples}, {name: model, var: model}, {name: query, var: query}, {name: return_metadata, var: return_metadata}, {name: return_prompt, var: return_prompt}, {name: search_model, var: search_model}, {name: temperature, var: temperature}, {name: user, var: user}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    examples: $examples, expand: $expand, file: $file, labels: $labels, logit_bias: $logit_bias, logprobs: $logprobs, max_examples: $max_examples, model: $model, query: $query, return_metadata: $return_metadata, return_prompt: $return_prompt, search_model: $search_model, temperature: $temperature, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a completion for the provided prompt and parameters
#
# POST /completions
# Returns: record<choices: table<finish_reason: string, index: int, logprobs: record, text: string>, created: int, id: string, model: string, object: string, usage: record<completion_tokens: int, prompt_tokens: int, total_tokens: int>>
# operationId: createCompletion
export def "create-completion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --best-of: int # Generates `best_of` completions server-side and returns the "best" (the one with the highest log probability per token). Results cannot be streamed. When used with `n`, `best_of` controls the number of candidate completions and `n` specifies how many to return – `best_of` must be greater than `n`. **Note:** Because this parameter generates many completions, it can quickly consume your token quota. Use carefully and ensure that you have reasonable settings for `max_tokens` and `stop`. (nullable, default: 1)
  --echo: oneof<nothing, bool> # Echo back the prompt in addition to the completion (nullable, default: false)
  --frequency-penalty: float # Number between -2.0 and 2.0. Positive values penalize new tokens based on their existing frequency in the text so far, decreasing the model's likelihood to repeat the same line verbatim. [See more information about frequency and presence penalties.](/docs/api-reference/parameter-details) (nullable, default: 0)
  --logit-bias: record # Modify the likelihood of specified tokens appearing in the completion. Accepts a json object that maps tokens (specified by their token ID in the GPT tokenizer) to an associated bias value from -100 to 100. You can use this [tokenizer tool](/tokenizer?view=bpe) (which works for both GPT-2 and GPT-3) to convert text to token IDs. Mathematically, the bias is added to the logits generated by the model prior to sampling. The exact effect will vary per model, but values between -1 and 1 should decrease or increase likelihood of selection; values like -100 or 100 should result in a ban or exclusive selection of the relevant token. As an example, you can pass `{"50256": -100}` to prevent the <|endoftext|> token from being generated. (nullable)
  --logprobs: int # Include the log probabilities on the `logprobs` most likely tokens, as well the chosen tokens. For example, if `logprobs` is 5, the API will return a list of the 5 most likely tokens. The API will always return the `logprob` of the sampled token, so there may be up to `logprobs+1` elements in the response. The maximum value for `logprobs` is 5. If you need more than this, please contact us through our [Help center](https://help.openai.com) and describe your use case. (nullable)
  --max-tokens: int # The maximum number of [tokens](/tokenizer) to generate in the completion. The token count of your prompt plus `max_tokens` cannot exceed the model's context length. Most models have a context length of 2048 tokens (except for the newest models, which support 4096). (nullable, default: 16, e.g. 16)
  model: string # ID of the model to use. You can use the [List models](/docs/api-reference/models/list) API to see all of your available models, or see our [Model overview](/docs/models/overview) for descriptions of them.
  --n: int # How many completions to generate for each prompt. **Note:** Because this parameter generates many completions, it can quickly consume your token quota. Use carefully and ensure that you have reasonable settings for `max_tokens` and `stop`. (nullable, default: 1, e.g. 1)
  --presence-penalty: float # Number between -2.0 and 2.0. Positive values penalize new tokens based on whether they appear in the text so far, increasing the model's likelihood to talk about new topics. [See more information about frequency and presence penalties.](/docs/api-reference/parameter-details) (nullable, default: 0)
  --prompt: any # The prompt(s) to generate completions for, encoded as a string, array of strings, array of tokens, or array of token arrays. Note that <|endoftext|> is the document separator that the model sees during training, so if a prompt is not specified the model will generate as if from the beginning of a new document. (nullable, default: <|endoftext|>)
  --stop: any # Up to 4 sequences where the API will stop generating further tokens. The returned text will not contain the stop sequence. (nullable)
  --stream: oneof<nothing, bool> # Whether to stream back partial progress. If set, tokens will be sent as data-only [server-sent events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events#Event_stream_format) as they become available, with the stream terminated by a `data: [DONE]` message. (nullable, default: false)
  --suffix: string # The suffix that comes after a completion of inserted text. (nullable, e.g. test.)
  --temperature: float # What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. We generally recommend altering this or `top_p` but not both. (nullable, default: 1, e.g. 1)
  --top-p: float # An alternative to sampling with temperature, called nucleus sampling, where the model considers the results of the tokens with top_p probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered. We generally recommend altering this or `temperature` but not both. (nullable, default: 1, e.g. 1)
  --user: string # A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse. [Learn more](/docs/guides/safety-best-practices/end-user-ids). (e.g. user-1234)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/completions"
    body: {content_type: "application/json", kind: json, fields: [{name: best_of, var: best_of}, {name: echo, var: echo}, {name: frequency_penalty, var: frequency_penalty}, {name: logit_bias, var: logit_bias}, {name: logprobs, var: logprobs}, {name: max_tokens, var: max_tokens}, {name: model, var: model}, {name: n, var: n}, {name: presence_penalty, var: presence_penalty}, {name: prompt, var: prompt}, {name: stop, var: stop}, {name: stream, var: stream}, {name: suffix, var: suffix}, {name: temperature, var: temperature}, {name: top_p, var: top_p}, {name: user, var: user}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    best_of: $best_of, echo: $echo, frequency_penalty: $frequency_penalty, logit_bias: $logit_bias, logprobs: $logprobs, max_tokens: $max_tokens, model: $model, n: $n, presence_penalty: $presence_penalty, prompt: $prompt, stop: $stop, stream: $stream, suffix: $suffix, temperature: $temperature, top_p: $top_p, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new edit for the provided input, instruction, and parameters.
#
# POST /edits
# Returns: record<choices: table<finish_reason: string, index: int, logprobs: record, text: string>, created: int, object: string, usage: record<completion_tokens: int, prompt_tokens: int, total_tokens: int>>
# operationId: createEdit
export def "create-edit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --input: string # The input text to use as a starting point for the edit. (nullable, default: "", e.g. What day of the wek is it?)
  instruction: string # The instruction that tells the model how to edit the prompt. (e.g. Fix the spelling mistakes.)
  model: string # ID of the model to use. You can use the `text-davinci-edit-001` or `code-davinci-edit-001` model with this endpoint.
  --n: int # How many edits to generate for the input and instruction. (nullable, default: 1, e.g. 1)
  --temperature: float # What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. We generally recommend altering this or `top_p` but not both. (nullable, default: 1, e.g. 1)
  --top-p: float # An alternative to sampling with temperature, called nucleus sampling, where the model considers the results of the tokens with top_p probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered. We generally recommend altering this or `temperature` but not both. (nullable, default: 1, e.g. 1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/edits"
    body: {content_type: "application/json", kind: json, fields: [{name: input, var: input}, {name: instruction, var: instruction}, {name: model, var: model}, {name: n, var: n}, {name: temperature, var: temperature}, {name: top_p, var: top_p}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    input: $input, instruction: $instruction, model: $model, n: $n, temperature: $temperature, top_p: $top_p
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an embedding vector representing the input text.
#
# POST /embeddings
# Returns: record<data: table<embedding: list, index: int, object: string>, model: string, object: string, usage: record<prompt_tokens: int, total_tokens: int>>
# operationId: createEmbedding
export def "create-embedding" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: any # Input text to get embeddings for, encoded as a string or array of tokens. To get embeddings for multiple inputs in a single request, pass an array of strings or array of token arrays. Each input must not exceed 8192 tokens in length. (e.g. The quick brown fox jumped over the lazy dog)
  model: string # ID of the model to use. You can use the [List models](/docs/api-reference/models/list) API to see all of your available models, or see our [Model overview](/docs/models/overview) for descriptions of them.
  --user: string # A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse. [Learn more](/docs/guides/safety-best-practices/end-user-ids). (e.g. user-1234)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/embeddings"
    body: {content_type: "application/json", kind: json, fields: [{name: input, var: input}, {name: model, var: model}, {name: user, var: user}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    input: $input, model: $model, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the currently available (non-finetuned) models, and provides basic information about each one such as the owner and availability.
#
# GET /engines
# DEPRECATED
# Returns: record<data: table<created: int, id: string, object: string, ready: bool>, object: string>
# operationId: listEngines
@deprecated
export def "list-engines" [
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
    path: "/engines"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a model instance, providing basic information about it such as the owner and availability.
#
# GET /engines/{engine_id}
# DEPRECATED
# Returns: record<created: int, id: string, object: string, ready: bool>
# operationId: retrieveEngine
@deprecated
export def "retrieve-engine" [
  engine_id: string
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
    path: "/engines/{engine_id}"
    path_params: [{name: engine_id, var: engine_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    engine_id: $engine_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The search endpoint computes similarity scores between provided query and documents. Documents can be passed directly to the API if there are no more than 200 of them. To go beyond the 200 document limit, documents can be processed offline and then used for efficient retrieval at query time. When `file` is set, the search endpoint searches over all the documents in the given file and returns up to the `max_rerank` number of documents. These documents will be returned along with their search scores. The similarity score is a positive score that usually ranges from 0 to 300 (but can sometimes go higher), where a score above 200 usually means the document is semantically similar to the query.
#
# POST /engines/{engine_id}/search
# DEPRECATED
# Returns: record<data: table<document: int, object: string, score: float>, model: string, object: string>
# operationId: createSearch
@deprecated
export def "create-search" [
  engine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --documents: list<string> # Up to 200 documents to search over, provided as a list of strings. The maximum document length (in tokens) is 2034 minus the number of tokens in the query. You should specify either `documents` or a `file`, but not both. (nullable, e.g. ['White House', 'hospital', 'school'])
  --file: string # The ID of an uploaded file that contains documents to search over. You should specify either `documents` or a `file`, but not both. (nullable)
  --max-rerank: int # The maximum number of documents to be re-ranked and returned by search. This flag only takes effect when `file` is set. (nullable, default: 200)
  query: string # Query to search against the documents. (e.g. the president)
  --return-metadata: oneof<nothing, bool> # A special boolean flag for showing metadata. If set to `true`, each document entry in the returned JSON will contain a "metadata" field. This flag only takes effect when `file` is set. (nullable, default: false)
  --user: string # A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse. [Learn more](/docs/guides/safety-best-practices/end-user-ids). (e.g. user-1234)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/engines/{engine_id}/search"
    path_params: [{name: engine_id, var: engine_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: documents, var: documents}, {name: file, var: file}, {name: max_rerank, var: max_rerank}, {name: query, var: query}, {name: return_metadata, var: return_metadata}, {name: user, var: user}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    engine_id: $engine_id, documents: $documents, file: $file, max_rerank: $max_rerank, query: $query, return_metadata: $return_metadata, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of files that belong to the user's organization.
#
# GET /files
# Returns: record<data: table<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>, object: string>
# operationId: listFiles
export def "list-files" [
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
    path: "/files"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload a file that contains document(s) to be used across various endpoints/features. Currently, the size of all the files uploaded by one organization can be up to 1 GB. Please contact us if you need to increase the storage limit.
#
# POST /files
# Returns: record<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>
# operationId: createFile
export def "create-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # Name of the [JSON Lines](https://jsonlines.readthedocs.io/en/latest/) file to be uploaded. If the `purpose` is set to "fine-tune", each line is a JSON record with "prompt" and "completion" fields representing your [training examples](/docs/guides/fine-tuning/prepare-training-data). (format: binary)
  purpose: string # The intended purpose of the uploaded documents. Use "fine-tune" for [Fine-tuning](/docs/api-reference/fine-tunes). This allows us to validate the format of the uploaded file.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}, {name: purpose, var: purpose}], files: [file]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file: $file, purpose: $purpose
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a file.
#
# DELETE /files/{file_id}
# Returns: record<deleted: bool, id: string, object: string>
# operationId: deleteFile
export def "delete-file" [
  file_id: string
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
    method: delete
    path: "/files/{file_id}"
    path_params: [{name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a specific file.
#
# GET /files/{file_id}
# Returns: record<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>
# operationId: retrieveFile
export def "retrieve-file" [
  file_id: string
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
    path: "/files/{file_id}"
    path_params: [{name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the contents of the specified file
#
# GET /files/{file_id}/content
# Returns: string
# operationId: downloadFile
export def "download-file" [
  file_id: string
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
    path: "/files/{file_id}/content"
    path_params: [{name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List your organization's fine-tuning jobs
#
# GET /fine-tunes
# Returns: record<data: table<created_at: int, events: list, fine_tuned_model: string, hyperparams: record, id: string, model: string, object: string, organization_id: string, result_files: list, status: string, training_files: list, updated_at: int, validation_files: list>, object: string>
# operationId: listFineTunes
export def "list-fine-tunes" [
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
    path: "/fine-tunes"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a job that fine-tunes a specified model from a given dataset. Response includes details of the enqueued job including job status and the name of the fine-tuned models once complete. [Learn more about Fine-tuning](/docs/guides/fine-tuning)
#
# POST /fine-tunes
# Returns: record<created_at: int, events: table<created_at: int, level: string, message: string, object: string>, fine_tuned_model: string, hyperparams: record, id: string, model: string, object: string, organization_id: string, result_files: table<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>, status: string, training_files: table<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>, updated_at: int, validation_files: table<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>>
# operationId: createFineTune
export def "create-fine-tune" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --batch-size: int # The batch size to use for training. The batch size is the number of training examples used to train a single forward and backward pass. By default, the batch size will be dynamically configured to be ~0.2% of the number of examples in the training set, capped at 256 - in general, we've found that larger batch sizes tend to work better for larger datasets. (nullable)
  --classification-betas: list<float> # If this is provided, we calculate F-beta scores at the specified beta values. The F-beta score is a generalization of F-1 score. This is only used for binary classification. With a beta of 1 (i.e. the F-1 score), precision and recall are given the same weight. A larger beta score puts more weight on recall and less on precision. A smaller beta score puts more weight on precision and less on recall. (nullable, e.g. [0.6, 1, 1.5, 2])
  --classification-n-classes: int # The number of classes in a classification task. This parameter is required for multiclass classification. (nullable)
  --classification-positive-class: string # The positive class in binary classification. This parameter is needed to generate precision, recall, and F1 metrics when doing binary classification. (nullable)
  --compute-classification-metrics: oneof<nothing, bool> # If set, we calculate classification-specific metrics such as accuracy and F-1 score using the validation set at the end of every epoch. These metrics can be viewed in the [results file](/docs/guides/fine-tuning/analyzing-your-fine-tuned-model). In order to compute classification metrics, you must provide a `validation_file`. Additionally, you must specify `classification_n_classes` for multiclass classification or `classification_positive_class` for binary classification. (nullable, default: false)
  --learning-rate-multiplier: float # The learning rate multiplier to use for training. The fine-tuning learning rate is the original learning rate used for pretraining multiplied by this value. By default, the learning rate multiplier is the 0.05, 0.1, or 0.2 depending on final `batch_size` (larger learning rates tend to perform better with larger batch sizes). We recommend experimenting with values in the range 0.02 to 0.2 to see what produces the best results. (nullable)
  --model: string # The name of the base model to fine-tune. You can select one of "ada", "babbage", "curie", "davinci", or a fine-tuned model created after 2022-04-21. To learn more about these models, see the [Models](https://platform.openai.com/docs/models) documentation. (nullable, default: curie)
  --n-epochs: int # The number of epochs to train the model for. An epoch refers to one full cycle through the training dataset. (nullable, default: 4)
  --prompt-loss-weight: float # The weight to use for loss on the prompt tokens. This controls how much the model tries to learn to generate the prompt (as compared to the completion which always has a weight of 1.0), and can add a stabilizing effect to training when completions are short. If prompts are extremely long (relative to completions), it may make sense to reduce this weight so as to avoid over-prioritizing learning the prompt. (nullable, default: 0.01)
  --suffix: string # A string of up to 40 characters that will be added to your fine-tuned model name. For example, a `suffix` of "custom-model-name" would produce a model name like `ada:ft-your-org:custom-model-name-2022-02-15-04-21-04`. (nullable)
  training_file: string # The ID of an uploaded file that contains training data. See [upload file](/docs/api-reference/files/upload) for how to upload a file. Your dataset must be formatted as a JSONL file, where each training example is a JSON object with the keys "prompt" and "completion". Additionally, you must upload your file with the purpose `fine-tune`. See the [fine-tuning guide](/docs/guides/fine-tuning/creating-training-data) for more details. (e.g. file-ajSREls59WBbvgSzJSVWxMCB)
  --validation-file: string # The ID of an uploaded file that contains validation data. If you provide this file, the data is used to generate validation metrics periodically during fine-tuning. These metrics can be viewed in the [fine-tuning results file](/docs/guides/fine-tuning/analyzing-your-fine-tuned-model). Your train and validation data should be mutually exclusive. Your dataset must be formatted as a JSONL file, where each validation example is a JSON object with the keys "prompt" and "completion". Additionally, you must upload your file with the purpose `fine-tune`. See the [fine-tuning guide](/docs/guides/fine-tuning/creating-training-data) for more details. (nullable, e.g. file-XjSREls59WBbvgSzJSVWxMCa)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/fine-tunes"
    body: {content_type: "application/json", kind: json, fields: [{name: batch_size, var: batch_size}, {name: classification_betas, var: classification_betas}, {name: classification_n_classes, var: classification_n_classes}, {name: classification_positive_class, var: classification_positive_class}, {name: compute_classification_metrics, var: compute_classification_metrics}, {name: learning_rate_multiplier, var: learning_rate_multiplier}, {name: model, var: model}, {name: n_epochs, var: n_epochs}, {name: prompt_loss_weight, var: prompt_loss_weight}, {name: suffix, var: suffix}, {name: training_file, var: training_file}, {name: validation_file, var: validation_file}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    batch_size: $batch_size, classification_betas: $classification_betas, classification_n_classes: $classification_n_classes, classification_positive_class: $classification_positive_class, compute_classification_metrics: $compute_classification_metrics, learning_rate_multiplier: $learning_rate_multiplier, model: $model, n_epochs: $n_epochs, prompt_loss_weight: $prompt_loss_weight, suffix: $suffix, training_file: $training_file, validation_file: $validation_file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets info about the fine-tune job. [Learn more about Fine-tuning](/docs/guides/fine-tuning)
#
# GET /fine-tunes/{fine_tune_id}
# Returns: record<created_at: int, events: table<created_at: int, level: string, message: string, object: string>, fine_tuned_model: string, hyperparams: record, id: string, model: string, object: string, organization_id: string, result_files: table<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>, status: string, training_files: table<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>, updated_at: int, validation_files: table<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>>
# operationId: retrieveFineTune
export def "retrieve-fine-tune" [
  fine_tune_id: string
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
    path: "/fine-tunes/{fine_tune_id}"
    path_params: [{name: fine_tune_id, var: fine_tune_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    fine_tune_id: $fine_tune_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Immediately cancel a fine-tune job.
#
# POST /fine-tunes/{fine_tune_id}/cancel
# Returns: record<created_at: int, events: table<created_at: int, level: string, message: string, object: string>, fine_tuned_model: string, hyperparams: record, id: string, model: string, object: string, organization_id: string, result_files: table<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>, status: string, training_files: table<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>, updated_at: int, validation_files: table<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>>
# operationId: cancelFineTune
export def "cancel-fine-tune" [
  fine_tune_id: string
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
    path: "/fine-tunes/{fine_tune_id}/cancel"
    path_params: [{name: fine_tune_id, var: fine_tune_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    fine_tune_id: $fine_tune_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get fine-grained status updates for a fine-tune job.
#
# GET /fine-tunes/{fine_tune_id}/events
# Returns: record<data: table<created_at: int, level: string, message: string, object: string>, object: string>
# operationId: listFineTuneEvents
export def "list-fine-tune-events" [
  fine_tune_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stream: oneof<nothing, bool> # Whether to stream events for the fine-tune job. If set to true, events will be sent as data-only [server-sent events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events#Event_stream_format) as they become available. The stream will terminate with a `data: [DONE]` message when the job is finished (succeeded, cancelled, or failed). If set to false, only events generated so far will be returned. (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/fine-tunes/{fine_tune_id}/events"
    path_params: [{name: fine_tune_id, var: fine_tune_id}]
    query: [{name: stream, var: stream}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    fine_tune_id: $fine_tune_id, stream: $stream
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an edited or extended image given an original image and a prompt.
#
# POST /images/edits
# Returns: record<created: int, data: table<b64_json: string, url: string>>
# operationId: createImageEdit
export def "create-image-edit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  image: string # The image to edit. Must be a valid PNG file, less than 4MB, and square. If mask is not provided, image must have transparency, which will be used as the mask. (format: binary)
  --mask: string # An additional image whose fully transparent areas (e.g. where alpha is zero) indicate where `image` should be edited. Must be a valid PNG file, less than 4MB, and have the same dimensions as `image`. (format: binary)
  --n: int # The number of images to generate. Must be between 1 and 10. (nullable, default: 1, e.g. 1)
  prompt: string # A text description of the desired image(s). The maximum length is 1000 characters. (e.g. A cute baby sea otter wearing a beret)
  --response-format: string@response-format-completer # The format in which the generated images are returned. Must be one of `url` or `b64_json`. (nullable, default: url, e.g. url)
  --size: string@size-completer # The size of the generated images. Must be one of `256x256`, `512x512`, or `1024x1024`. (nullable, default: 1024x1024, e.g. 1024x1024)
  --user: string # A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse. [Learn more](/docs/guides/safety-best-practices/end-user-ids). (e.g. user-1234)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/images/edits"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: image, var: image}, {name: mask, var: mask}, {name: n, var: n}, {name: prompt, var: prompt}, {name: response_format, var: response_format}, {name: size, var: size}, {name: user, var: user}], files: [image, mask]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image: $image, mask: $mask, n: $n, prompt: $prompt, response_format: $response_format, size: $size, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an image given a prompt.
#
# POST /images/generations
# Returns: record<created: int, data: table<b64_json: string, url: string>>
# operationId: createImage
export def "create-image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --n: int # The number of images to generate. Must be between 1 and 10. (nullable, default: 1, e.g. 1)
  prompt: string # A text description of the desired image(s). The maximum length is 1000 characters. (e.g. A cute baby sea otter)
  --response-format: string@response-format-completer # The format in which the generated images are returned. Must be one of `url` or `b64_json`. (nullable, default: url, e.g. url)
  --size: string@size-completer # The size of the generated images. Must be one of `256x256`, `512x512`, or `1024x1024`. (nullable, default: 1024x1024, e.g. 1024x1024)
  --user: string # A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse. [Learn more](/docs/guides/safety-best-practices/end-user-ids). (e.g. user-1234)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/images/generations"
    body: {content_type: "application/json", kind: json, fields: [{name: n, var: n}, {name: prompt, var: prompt}, {name: response_format, var: response_format}, {name: size, var: size}, {name: user, var: user}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    n: $n, prompt: $prompt, response_format: $response_format, size: $size, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a variation of a given image.
#
# POST /images/variations
# Returns: record<created: int, data: table<b64_json: string, url: string>>
# operationId: createImageVariation
export def "create-image-variation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  image: string # The image to use as the basis for the variation(s). Must be a valid PNG file, less than 4MB, and square. (format: binary)
  --n: int # The number of images to generate. Must be between 1 and 10. (nullable, default: 1, e.g. 1)
  --response-format: string@response-format-completer # The format in which the generated images are returned. Must be one of `url` or `b64_json`. (nullable, default: url, e.g. url)
  --size: string@size-completer # The size of the generated images. Must be one of `256x256`, `512x512`, or `1024x1024`. (nullable, default: 1024x1024, e.g. 1024x1024)
  --user: string # A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse. [Learn more](/docs/guides/safety-best-practices/end-user-ids). (e.g. user-1234)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/images/variations"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: image, var: image}, {name: n, var: n}, {name: response_format, var: response_format}, {name: size, var: size}, {name: user, var: user}], files: [image]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image: $image, n: $n, response_format: $response_format, size: $size, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the currently available models, and provides basic information about each one such as the owner and availability.
#
# GET /models
# Returns: record<data: table<created: int, id: string, object: string, owned_by: string>, object: string>
# operationId: listModels
export def "list-models" [
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
    path: "/models"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a fine-tuned model. You must have the Owner role in your organization.
#
# DELETE /models/{model}
# Returns: record<deleted: bool, id: string, object: string>
# operationId: deleteModel
export def "delete-model" [
  model: string
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
    method: delete
    path: "/models/{model}"
    path_params: [{name: model, var: model}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    model: $model
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a model instance, providing basic information about the model such as the owner and permissioning.
#
# GET /models/{model}
# Returns: record<created: int, id: string, object: string, owned_by: string>
# operationId: retrieveModel
export def "retrieve-model" [
  model: string
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
    path: "/models/{model}"
    path_params: [{name: model, var: model}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    model: $model
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Classifies if text violates OpenAI's Content Policy
#
# POST /moderations
# Returns: record<id: string, model: string, results: table<categories: record, category_scores: record, flagged: bool>>
# operationId: createModeration
export def "create-moderation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: any # The input text to classify
  --model: string # Two content moderations models are available: `text-moderation-stable` and `text-moderation-latest`. The default is `text-moderation-latest` which will be automatically upgraded over time. This ensures you are always using our most accurate model. If you use `text-moderation-stable`, we will provide advanced notice before updating the model. Accuracy of `text-moderation-stable` may be slightly lower than for `text-moderation-latest`. (default: text-moderation-latest, e.g. text-moderation-stable)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/moderations"
    body: {content_type: "application/json", kind: json, fields: [{name: input, var: input}, {name: model, var: model}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    input: $input, model: $model
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
