# Auto-generated client for Telegram Bot API v5.0.0
# Source: https://api.apis.guru/v2/specs/telegram.org/5.0.0/openapi.json
# Auth: --token flag or $env.TELEGRAM_BOT_API_TOKEN

const CLIENT = {
  base_url: "https://api.telegram.org/bot123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"
  token_env_var: "TELEGRAM_BOT_API_TOKEN"
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

def base-url-completer [] { ["https://api.telegram.org/bot123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def emoji-completer [] { ["⚽" "🎯" "🎰" "🎲" "🏀"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    post-add-sticker-to-set: "record<ok: bool, result: bool>"
    post-answer-callback-query: "record<ok: bool, result: bool>"
    post-answer-inline-query: "record<ok: bool, result: bool>"
    post-answer-pre-checkout-query: "record<ok: bool, result: bool>"
    post-answer-shipping-query: "record<ok: bool, result: bool>"
    post-close: "record<ok: bool, result: bool>"
    post-copy-message: "record<ok: bool, result: record<message_id: int>>"
    post-create-new-sticker-set: "record<ok: bool, result: bool>"
    post-delete-chat-photo: "record<ok: bool, result: bool>"
    post-delete-chat-sticker-set: "record<ok: bool, result: bool>"
    post-delete-message: "record<ok: bool, result: bool>"
    post-delete-sticker-from-set: "record<ok: bool, result: bool>"
    post-delete-webhook: "record<ok: bool, result: bool>"
    post-edit-message-caption: "record<ok: bool, result: any>"
    post-edit-message-live-location: "record<ok: bool, result: any>"
    post-edit-message-media: "record<ok: bool, result: any>"
    post-edit-message-reply-markup: "record<ok: bool, result: any>"
    post-edit-message-text: "record<ok: bool, result: any>"
    post-export-chat-invite-link: "record<ok: bool, result: string>"
    post-forward-message: "record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>"
    post-get-chat: "record<ok: bool, result: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record<address: string, location: record>, permissions: record<can_add_web_page_previews: bool, can_change_info: bool, can_invite_users: bool, can_pin_messages: bool, can_send_media_messages: bool, can_send_messages: bool, can_send_other_messages: bool, can_send_polls: bool>, photo: record<big_file_id: string, big_file_unique_id: string, small_file_id: string, small_file_unique_id: string>, pinned_message: record<animation: record, audio: record, author_signature: string, caption: string, caption_entities: list, channel_chat_created: bool, chat: any, connected_website: string, contact: record, date: int, delete_chat_photo: bool, dice: record, document: record, edit_date: int, entities: list, forward_date: int, forward_from: record, forward_from_chat: any, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record, game: record, group_chat_created: bool, invoice: record, left_chat_member: record, location: record, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list, new_chat_photo: list, new_chat_title: string, passport_data: record, photo: list, pinned_message: any, poll: record, proximity_alert_triggered: record, reply_markup: record, reply_to_message: any, sender_chat: any, sticker: record, successful_payment: record, supergroup_chat_created: bool, text: string, venue: record, via_bot: record, video: record, video_note: record, voice: record>, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>>"
    post-get-chat-administrators: "record<ok: bool, result: table<can_add_web_page_previews: bool, can_be_edited: bool, can_change_info: bool, can_delete_messages: bool, can_edit_messages: bool, can_invite_users: bool, can_pin_messages: bool, can_post_messages: bool, can_promote_members: bool, can_restrict_members: bool, can_send_media_messages: bool, can_send_messages: bool, can_send_other_messages: bool, can_send_polls: bool, custom_title: string, is_anonymous: bool, is_member: bool, status: string, until_date: int, user: record>>"
    post-get-chat-member: "record<ok: bool, result: record<can_add_web_page_previews: bool, can_be_edited: bool, can_change_info: bool, can_delete_messages: bool, can_edit_messages: bool, can_invite_users: bool, can_pin_messages: bool, can_post_messages: bool, can_promote_members: bool, can_restrict_members: bool, can_send_media_messages: bool, can_send_messages: bool, can_send_other_messages: bool, can_send_polls: bool, custom_title: string, is_anonymous: bool, is_member: bool, status: string, until_date: int, user: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>>>"
    post-get-chat-members-count: "record<ok: bool, result: int>"
    post-get-file: "record<ok: bool, result: record<file_id: string, file_path: string, file_size: int, file_unique_id: string>>"
    post-get-game-high-scores: "record<ok: bool, result: table<position: int, score: int, user: record>>"
    post-get-me: "record<ok: bool, result: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>>"
    post-get-my-commands: "record<ok: bool, result: table<command: string, description: string>>"
    post-get-sticker-set: "record<ok: bool, result: record<contains_masks: bool, is_animated: bool, name: string, stickers: list<record>, thumb: record<file_id: string, file_size: int, file_unique_id: string, height: int, width: int>, title: string>>"
    post-get-updates: "record<ok: bool, result: table<callback_query: record, channel_post: record, chosen_inline_result: record, edited_channel_post: record, edited_message: record, inline_query: record, message: record, poll: record, poll_answer: record, pre_checkout_query: record, shipping_query: record, update_id: int>>"
    post-get-user-profile-photos: "record<ok: bool, result: record<photos: list<list>, total_count: int>>"
    post-get-webhook-info: "record<ok: bool, result: record<allowed_updates: list<string>, has_custom_certificate: bool, ip_address: string, last_error_date: int, last_error_message: string, max_connections: int, pending_update_count: int, url: string>>"
    post-kick-chat-member: "record<ok: bool, result: bool>"
    post-leave-chat: "record<ok: bool, result: bool>"
    post-log-out: "record<ok: bool, result: bool>"
    post-pin-chat-message: "record<ok: bool, result: bool>"
    post-promote-chat-member: "record<ok: bool, result: bool>"
    post-restrict-chat-member: "record<ok: bool, result: bool>"
    post-send-animation: "record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>"
    post-send-audio: "record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>"
    post-send-chat-action: "record<ok: bool, result: bool>"
    post-send-contact: "record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>"
    post-send-dice: "record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>"
    post-send-document: "record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>"
    post-send-game: "record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>"
    post-send-invoice: "record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>"
    post-send-location: "record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>"
    post-send-media-group: "record<ok: bool, result: table<animation: record, audio: record, author_signature: string, caption: string, caption_entities: list, channel_chat_created: bool, chat: record, connected_website: string, contact: record, date: int, delete_chat_photo: bool, dice: record, document: record, edit_date: int, entities: list, forward_date: int, forward_from: record, forward_from_chat: record, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record, game: record, group_chat_created: bool, invoice: record, left_chat_member: record, location: record, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list, new_chat_photo: list, new_chat_title: string, passport_data: record, photo: list, pinned_message: any, poll: record, proximity_alert_triggered: record, reply_markup: record, reply_to_message: any, sender_chat: record, sticker: record, successful_payment: record, supergroup_chat_created: bool, text: string, venue: record, via_bot: record, video: record, video_note: record, voice: record>>"
    post-send-message: "record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>"
    post-send-photo: "record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>"
    post-send-poll: "record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>"
    post-send-sticker: "record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>"
    post-send-venue: "record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>"
    post-send-video: "record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>"
    post-send-video-note: "record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>"
    post-send-voice: "record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>"
    post-set-chat-administrator-custom-title: "record<ok: bool, result: bool>"
    post-set-chat-description: "record<ok: bool, result: bool>"
    post-set-chat-permissions: "record<ok: bool, result: bool>"
    post-set-chat-photo: "record<ok: bool, result: bool>"
    post-set-chat-sticker-set: "record<ok: bool, result: bool>"
    post-set-chat-title: "record<ok: bool, result: bool>"
    post-set-game-score: "record<ok: bool, result: any>"
    post-set-my-commands: "record<ok: bool, result: bool>"
    post-set-passport-data-errors: "record<ok: bool, result: bool>"
    post-set-sticker-position-in-set: "record<ok: bool, result: bool>"
    post-set-sticker-set-thumb: "record<ok: bool, result: bool>"
    post-set-webhook: "record<ok: bool, result: bool>"
    post-stop-message-live-location: "record<ok: bool, result: any>"
    post-stop-poll: "record<ok: bool, result: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list<record>, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list<record>, question: string, total_voter_count: int, type: string>>"
    post-unban-chat-member: "record<ok: bool, result: bool>"
    post-unpin-all-chat-messages: "record<ok: bool, result: bool>"
    post-unpin-chat-message: "record<ok: bool, result: bool>"
    post-upload-sticker-file: "record<ok: bool, result: record<file_id: string, file_path: string, file_size: int, file_unique_id: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["post-add-sticker-to-set" "post-answer-callback-query" "post-answer-inline-query" "post-answer-pre-checkout-query" "post-answer-shipping-query" "post-close" "post-copy-message" "post-create-new-sticker-set" "post-delete-chat-photo" "post-delete-chat-sticker-set" "post-delete-message" "post-delete-sticker-from-set" "post-delete-webhook" "post-edit-message-caption" "post-edit-message-live-location" "post-edit-message-media" "post-edit-message-reply-markup" "post-edit-message-text" "post-export-chat-invite-link" "post-forward-message" "post-get-chat" "post-get-chat-administrators" "post-get-chat-member" "post-get-chat-members-count" "post-get-file" "post-get-game-high-scores" "post-get-me" "post-get-my-commands" "post-get-sticker-set" "post-get-updates" "post-get-user-profile-photos" "post-get-webhook-info" "post-kick-chat-member" "post-leave-chat" "post-log-out" "post-pin-chat-message" "post-promote-chat-member" "post-restrict-chat-member" "post-send-animation" "post-send-audio" "post-send-chat-action" "post-send-contact" "post-send-dice" "post-send-document" "post-send-game" "post-send-invoice" "post-send-location" "post-send-media-group" "post-send-message" "post-send-photo" "post-send-poll" "post-send-sticker" "post-send-venue" "post-send-video" "post-send-video-note" "post-send-voice" "post-set-chat-administrator-custom-title" "post-set-chat-description" "post-set-chat-permissions" "post-set-chat-photo" "post-set-chat-sticker-set" "post-set-chat-title" "post-set-game-score" "post-set-my-commands" "post-set-passport-data-errors" "post-set-sticker-position-in-set" "post-set-sticker-set-thumb" "post-set-webhook" "post-stop-message-live-location" "post-stop-poll" "post-unban-chat-member" "post-unpin-all-chat-messages" "post-unpin-chat-message" "post-upload-sticker-file" "commands"] | sort) } | get name | first)
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

# Use this method to add a new sticker to a set created by the bot. You **must** use exactly one of the fields *png\_sticker* or *tgs\_sticker*. Animated stickers can be added to animated sticker sets and only to them. Animated sticker sets can have up to 50 stickers. Static sticker sets can have up to 120 stickers. Returns *True* on success.
#
# POST /addStickerToSet
# Docs: https://core.telegram.org/bots/api/#addstickertoset
# Returns: record<ok: bool, result: bool>
export def "post-add-sticker-to-set" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  emojis: string # One or more emoji corresponding to the sticker
  --mask-position: record # This object describes the position on faces where a mask should be placed by default. — shape: {point: "forehead"|"eyes"|"mouth"|"chin", scale: float, x_shift: float, y_shift: float}
  name: string # Sticker set name
  --png-sticker: any # **PNG** image with the sticker, must be up to 512 kilobytes in size, dimensions must not exceed 512px, and either width or height must be exactly 512px. Pass a *file\_id* as a String to send a file that already exists on the Telegram servers, pass an HTTP URL as a String for Telegram to get a file from the Internet, or upload a new one using multipart/form-data. [More info on Sending Files »](https://core.telegram.org/bots/api/#sending-files)
  --tgs-sticker: any # This object represents the contents of a file to be uploaded. Must be posted using multipart/form-data in the usual way that files are uploaded via the browser.
  user_id: int # User identifier of sticker set owner
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/addStickerToSet"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: emojis, var: emojis}, {name: mask_position, var: mask_position}, {name: name, var: name}, {name: png_sticker, var: png_sticker}, {name: tgs_sticker, var: tgs_sticker}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    emojis: $emojis, mask_position: $mask_position, name: $name, png_sticker: $png_sticker, tgs_sticker: $tgs_sticker, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to send answers to callback queries sent from [inline keyboards](/bots#inline-keyboards-and-on-the-fly-updating). The answer will be displayed to the user as a notification at the top of the chat screen or as an alert. On success, *True* is returned. Alternatively, the user can be redirected to the specified Game URL. For this option to work, you must first create a game for your bot via [@Botfather](https://t.me/botfather) and accept the terms. Otherwise, you may use links like `t.me/your_bot?start=XXXX` that open your bot with a parameter.
#
# POST /answerCallbackQuery
# Docs: https://core.telegram.org/bots/api/#answercallbackquery
# Returns: record<ok: bool, result: bool>
export def "post-answer-callback-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-time: int # The maximum amount of time in seconds that the result of the callback query may be cached client-side. Telegram apps will support caching starting in version 3.14. Defaults to 0. (default: 0)
  callback_query_id: string # Unique identifier for the query to be answered
  --show-alert: oneof<nothing, bool> # If *true*, an alert will be shown by the client instead of a notification at the top of the chat screen. Defaults to *false*. (default: false)
  --text: string # Text of the notification. If not specified, nothing will be shown to the user, 0-200 characters
  --url: string # URL that will be opened by the user's client. If you have created a [Game](https://core.telegram.org/bots/api/#game) and accepted the conditions via [@Botfather](https://t.me/botfather), specify the URL that opens your game — note that this will only work if the query comes from a [*callback\_game*](https://core.telegram.org/bots/api/#inlinekeyboardbutton) button. Otherwise, you may use links like `t.me/your_bot?start=XXXX` that open your bot with a parameter.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/answerCallbackQuery"
    body: {content_type: "application/json", kind: json, fields: [{name: cache_time, var: cache_time}, {name: callback_query_id, var: callback_query_id}, {name: show_alert, var: show_alert}, {name: text, var: text}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cache_time: $cache_time, callback_query_id: $callback_query_id, show_alert: $show_alert, text: $text, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to send answers to an inline query. On success, *True* is returned. No more than **50** results per query are allowed.
#
# POST /answerInlineQuery
# Docs: https://core.telegram.org/bots/api/#answerinlinequery
# Returns: record<ok: bool, result: bool>
export def "post-answer-inline-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-time: int # The maximum amount of time in seconds that the result of the inline query may be cached on the server. Defaults to 300. (default: 300)
  inline_query_id: string # Unique identifier for the answered query
  --is-personal: oneof<nothing, bool> # Pass *True*, if results may be cached on the server side only for the user that sent the query. By default, results may be returned to any user who sends the same query
  --next-offset: string # Pass the offset that a client should send in the next query with the same text to receive more results. Pass an empty string if there are no more results or if you don't support pagination. Offset length can't exceed 64 bytes.
  results: list # A JSON-serialized array of results for the inline query
  --switch-pm-parameter: string # [Deep-linking](/bots#deep-linking) parameter for the /start message sent to the bot when user presses the switch button. 1-64 characters, only `A-Z`, `a-z`, `0-9`, `_` and `-` are allowed. *Example:* An inline bot that sends YouTube videos can ask the user to connect the bot to their YouTube account to adapt search results accordingly. To do this, it displays a 'Connect your YouTube account' button above the results, or even before showing any. The user presses the button, switches to a private chat with the bot and, in doing so, passes a start parameter that instructs the bot to return an oauth link. Once done, the bot can offer a [*switch\_inline*](https://core.telegram.org/bots/api/#inlinekeyboardmarkup) button so that the user can easily return to the chat where they wanted to use the bot's inline capabilities.
  --switch-pm-text: string # If passed, clients will display a button with specified text that switches the user to a private chat with the bot and sends the bot a start message with the parameter *switch\_pm\_parameter*
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/answerInlineQuery"
    body: {content_type: "application/json", kind: json, fields: [{name: cache_time, var: cache_time}, {name: inline_query_id, var: inline_query_id}, {name: is_personal, var: is_personal}, {name: next_offset, var: next_offset}, {name: results, var: results}, {name: switch_pm_parameter, var: switch_pm_parameter}, {name: switch_pm_text, var: switch_pm_text}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cache_time: $cache_time, inline_query_id: $inline_query_id, is_personal: $is_personal, next_offset: $next_offset, results: $results, switch_pm_parameter: $switch_pm_parameter, switch_pm_text: $switch_pm_text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Once the user has confirmed their payment and shipping details, the Bot API sends the final confirmation in the form of an [Update](https://core.telegram.org/bots/api/#update) with the field *pre\_checkout\_query*. Use this method to respond to such pre-checkout queries. On success, True is returned. **Note:** The Bot API must receive an answer within 10 seconds after the pre-checkout query was sent.
#
# POST /answerPreCheckoutQuery
# Docs: https://core.telegram.org/bots/api/#answerprecheckoutquery
# Returns: record<ok: bool, result: bool>
export def "post-answer-pre-checkout-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --error-message: string # Required if *ok* is *False*. Error message in human readable form that explains the reason for failure to proceed with the checkout (e.g. "Sorry, somebody just bought the last of our amazing black T-shirts while you were busy filling out your payment details. Please choose a different color or garment!"). Telegram will display this message to the user.
  --ok: oneof<nothing, bool> # Specify *True* if everything is alright (goods are available, etc.) and the bot is ready to proceed with the order. Use *False* if there are any problems.
  pre_checkout_query_id: string # Unique identifier for the query to be answered
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/answerPreCheckoutQuery"
    body: {content_type: "application/json", kind: json, fields: [{name: error_message, var: error_message}, {name: ok, var: ok, required: true}, {name: pre_checkout_query_id, var: pre_checkout_query_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    error_message: $error_message, ok: $ok, pre_checkout_query_id: $pre_checkout_query_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# If you sent an invoice requesting a shipping address and the parameter *is\_flexible* was specified, the Bot API will send an [Update](https://core.telegram.org/bots/api/#update) with a *shipping\_query* field to the bot. Use this method to reply to shipping queries. On success, True is returned.
#
# POST /answerShippingQuery
# Docs: https://core.telegram.org/bots/api/#answershippingquery
# Returns: record<ok: bool, result: bool>
export def "post-answer-shipping-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --error-message: string # Required if *ok* is False. Error message in human readable form that explains why it is impossible to complete the order (e.g. "Sorry, delivery to your desired address is unavailable'). Telegram will display this message to the user.
  --ok: oneof<nothing, bool> # Specify True if delivery to the specified address is possible and False if there are any problems (for example, if delivery to the specified address is not possible)
  --shipping-options: list # Required if *ok* is True. A JSON-serialized array of available shipping options. — item shape: {id: string, prices: list, title: string}
  shipping_query_id: string # Unique identifier for the query to be answered
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/answerShippingQuery"
    body: {content_type: "application/json", kind: json, fields: [{name: error_message, var: error_message}, {name: ok, var: ok, required: true}, {name: shipping_options, var: shipping_options}, {name: shipping_query_id, var: shipping_query_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    error_message: $error_message, ok: $ok, shipping_options: $shipping_options, shipping_query_id: $shipping_query_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to close the bot instance before moving it from one local server to another. You need to delete the webhook before calling this method to ensure that the bot isn't launched again after server restart. The method will return error 429 in the first 10 minutes after the bot is launched. Returns *True* on success. Requires no parameters.
#
# POST /close
# Docs: https://core.telegram.org/bots/api/#close
# Returns: record<ok: bool, result: bool>
export def "post-close" [
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
    path: "/close"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to copy messages of any kind. The method is analogous to the method [forwardMessages](https://core.telegram.org/bots/api/#forwardmessages), but the copied message doesn't have a link to the original message. Returns the [MessageId](https://core.telegram.org/bots/api/#messageid) of the sent message on success.
#
# POST /copyMessage
# Docs: https://core.telegram.org/bots/api/#copymessage
# Returns: record<ok: bool, result: record<message_id: int>>
export def "post-copy-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  --caption: string # New caption for media, 0-1024 characters after entities parsing. If not specified, the original caption is kept
  --caption-entities: list # List of special entities that appear in the new caption, which can be specified instead of *parse\_mode* — item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  from_chat_id: any # Unique identifier for the chat where the original message was sent (or channel username in the format `@channelusername`)
  message_id: int # Message identifier in the chat specified in *from\_chat\_id*
  --parse-mode: string # Mode for parsing entities in the new caption. See [formatting options](https://core.telegram.org/bots/api/#formatting-options) for more details.
  --reply-markup: any # Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating), [custom reply keyboard](https://core.telegram.org/bots#keyboards), instructions to remove reply keyboard or to force a reply from the user.
  --reply-to-message-id: int # If the message is a reply, ID of the original message
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/copyMessage"
    body: {content_type: "application/json", kind: json, fields: [{name: allow_sending_without_reply, var: allow_sending_without_reply}, {name: caption, var: caption}, {name: caption_entities, var: caption_entities}, {name: chat_id, var: chat_id}, {name: disable_notification, var: disable_notification}, {name: from_chat_id, var: from_chat_id}, {name: message_id, var: message_id}, {name: parse_mode, var: parse_mode}, {name: reply_markup, var: reply_markup}, {name: reply_to_message_id, var: reply_to_message_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allow_sending_without_reply: $allow_sending_without_reply, caption: $caption, caption_entities: $caption_entities, chat_id: $chat_id, disable_notification: $disable_notification, from_chat_id: $from_chat_id, message_id: $message_id, parse_mode: $parse_mode, reply_markup: $reply_markup, reply_to_message_id: $reply_to_message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to create a new sticker set owned by a user. The bot will be able to edit the sticker set thus created. You **must** use exactly one of the fields *png\_sticker* or *tgs\_sticker*. Returns *True* on success.
#
# POST /createNewStickerSet
# Docs: https://core.telegram.org/bots/api/#createnewstickerset
# Returns: record<ok: bool, result: bool>
export def "post-create-new-sticker-set" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contains-masks: oneof<nothing, bool> # Pass *True*, if a set of mask stickers should be created
  emojis: string # One or more emoji corresponding to the sticker
  --mask-position: record # This object describes the position on faces where a mask should be placed by default. — shape: {point: "forehead"|"eyes"|"mouth"|"chin", scale: float, x_shift: float, y_shift: float}
  name: string # Short name of sticker set, to be used in `t.me/addstickers/` URLs (e.g., *animals*). Can contain only english letters, digits and underscores. Must begin with a letter, can't contain consecutive underscores and must end in *“\_by\_”*. *<bot\_username>* is case insensitive. 1-64 characters.
  --png-sticker: any # **PNG** image with the sticker, must be up to 512 kilobytes in size, dimensions must not exceed 512px, and either width or height must be exactly 512px. Pass a *file\_id* as a String to send a file that already exists on the Telegram servers, pass an HTTP URL as a String for Telegram to get a file from the Internet, or upload a new one using multipart/form-data. [More info on Sending Files »](https://core.telegram.org/bots/api/#sending-files)
  --tgs-sticker: any # This object represents the contents of a file to be uploaded. Must be posted using multipart/form-data in the usual way that files are uploaded via the browser.
  title: string # Sticker set title, 1-64 characters
  user_id: int # User identifier of created sticker set owner
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/createNewStickerSet"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: contains_masks, var: contains_masks}, {name: emojis, var: emojis}, {name: mask_position, var: mask_position}, {name: name, var: name}, {name: png_sticker, var: png_sticker}, {name: tgs_sticker, var: tgs_sticker}, {name: title, var: title}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    contains_masks: $contains_masks, emojis: $emojis, mask_position: $mask_position, name: $name, png_sticker: $png_sticker, tgs_sticker: $tgs_sticker, title: $title, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to delete a chat photo. Photos can't be changed for private chats. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns *True* on success.
#
# POST /deleteChatPhoto
# Docs: https://core.telegram.org/bots/api/#deletechatphoto
# Returns: record<ok: bool, result: bool>
export def "post-delete-chat-photo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/deleteChatPhoto"
    body: {content_type: "application/json", kind: json, fields: [{name: chat_id, var: chat_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    chat_id: $chat_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to delete a group sticker set from a supergroup. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Use the field *can\_set\_sticker\_set* optionally returned in [getChat](https://core.telegram.org/bots/api/#getchat) requests to check if the bot can use this method. Returns *True* on success.
#
# POST /deleteChatStickerSet
# Docs: https://core.telegram.org/bots/api/#deletechatstickerset
# Returns: record<ok: bool, result: bool>
export def "post-delete-chat-sticker-set" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target supergroup (in the format `@supergroupusername`)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/deleteChatStickerSet"
    body: {content_type: "application/json", kind: json, fields: [{name: chat_id, var: chat_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    chat_id: $chat_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to delete a message, including service messages, with the following limitations: \- A message can only be deleted if it was sent less than 48 hours ago. \- A dice message in a private chat can only be deleted if it was sent more than 24 hours ago. \- Bots can delete outgoing messages in private chats, groups, and supergroups. \- Bots can delete incoming messages in private chats. \- Bots granted *can\_post\_messages* permissions can delete outgoing messages in channels. \- If the bot is an administrator of a group, it can delete any message there. \- If the bot has *can\_delete\_messages* permission in a supergroup or a channel, it can delete any message there. Returns *True* on success.
#
# POST /deleteMessage
# Docs: https://core.telegram.org/bots/api/#deletemessage
# Returns: record<ok: bool, result: bool>
export def "post-delete-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  message_id: int # Identifier of the message to delete
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/deleteMessage"
    body: {content_type: "application/json", kind: json, fields: [{name: chat_id, var: chat_id}, {name: message_id, var: message_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    chat_id: $chat_id, message_id: $message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to delete a sticker from a set created by the bot. Returns *True* on success.
#
# POST /deleteStickerFromSet
# Docs: https://core.telegram.org/bots/api/#deletestickerfromset
# Returns: record<ok: bool, result: bool>
export def "post-delete-sticker-from-set" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  sticker: string # File identifier of the sticker
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/deleteStickerFromSet"
    body: {content_type: "application/json", kind: json, fields: [{name: sticker, var: sticker}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sticker: $sticker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to remove webhook integration if you decide to switch back to [getUpdates](https://core.telegram.org/bots/api/#getupdates). Returns *True* on success.
#
# POST /deleteWebhook
# Docs: https://core.telegram.org/bots/api/#deletewebhook
# Returns: record<ok: bool, result: bool>
export def "post-delete-webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --drop-pending-updates: oneof<nothing, bool> # Pass *True* to drop all pending updates
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/deleteWebhook"
    body: {content_type: "application/json", kind: json, fields: [{name: drop_pending_updates, var: drop_pending_updates}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    drop_pending_updates: $drop_pending_updates
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to edit captions of messages. On success, if the edited message is not an inline message, the edited [Message](https://core.telegram.org/bots/api/#message) is returned, otherwise *True* is returned.
#
# POST /editMessageCaption
# Docs: https://core.telegram.org/bots/api/#editmessagecaption
# Returns: record<ok: bool, result: any>
export def "post-edit-message-caption" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --caption: string # New caption of the message, 0-1024 characters after entities parsing
  --caption-entities: list # List of special entities that appear in the caption, which can be specified instead of *parse\_mode* — item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
  --chat-id: any # Required if *inline\_message\_id* is not specified. Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --inline-message-id: string # Required if *chat\_id* and *message\_id* are not specified. Identifier of the inline message
  --message-id: int # Required if *inline\_message\_id* is not specified. Identifier of the message to edit
  --parse-mode: string # Mode for parsing entities in the message caption. See [formatting options](https://core.telegram.org/bots/api/#formatting-options) for more details.
  --reply-markup: record # This object represents an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating) that appears right next to the message it belongs to. — shape: {inline_keyboard: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/editMessageCaption"
    body: {content_type: "application/json", kind: json, fields: [{name: caption, var: caption}, {name: caption_entities, var: caption_entities}, {name: chat_id, var: chat_id}, {name: inline_message_id, var: inline_message_id}, {name: message_id, var: message_id}, {name: parse_mode, var: parse_mode}, {name: reply_markup, var: reply_markup}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    caption: $caption, caption_entities: $caption_entities, chat_id: $chat_id, inline_message_id: $inline_message_id, message_id: $message_id, parse_mode: $parse_mode, reply_markup: $reply_markup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to edit live location messages. A location can be edited until its *live\_period* expires or editing is explicitly disabled by a call to [stopMessageLiveLocation](https://core.telegram.org/bots/api/#stopmessagelivelocation). On success, if the edited message is not an inline message, the edited [Message](https://core.telegram.org/bots/api/#message) is returned, otherwise *True* is returned.
#
# POST /editMessageLiveLocation
# Docs: https://core.telegram.org/bots/api/#editmessagelivelocation
# Returns: record<ok: bool, result: any>
export def "post-edit-message-live-location" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --chat-id: any # Required if *inline\_message\_id* is not specified. Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --heading: int # Direction in which the user is moving, in degrees. Must be between 1 and 360 if specified.
  --horizontal-accuracy: float # The radius of uncertainty for the location, measured in meters; 0-1500
  --inline-message-id: string # Required if *chat\_id* and *message\_id* are not specified. Identifier of the inline message
  latitude: float # Latitude of new location
  longitude: float # Longitude of new location
  --message-id: int # Required if *inline\_message\_id* is not specified. Identifier of the message to edit
  --proximity-alert-radius: int # Maximum distance for proximity alerts about approaching another chat member, in meters. Must be between 1 and 100000 if specified.
  --reply-markup: record # This object represents an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating) that appears right next to the message it belongs to. — shape: {inline_keyboard: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/editMessageLiveLocation"
    body: {content_type: "application/json", kind: json, fields: [{name: chat_id, var: chat_id}, {name: heading, var: heading}, {name: horizontal_accuracy, var: horizontal_accuracy}, {name: inline_message_id, var: inline_message_id}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: message_id, var: message_id}, {name: proximity_alert_radius, var: proximity_alert_radius}, {name: reply_markup, var: reply_markup}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    chat_id: $chat_id, heading: $heading, horizontal_accuracy: $horizontal_accuracy, inline_message_id: $inline_message_id, latitude: $latitude, longitude: $longitude, message_id: $message_id, proximity_alert_radius: $proximity_alert_radius, reply_markup: $reply_markup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to edit animation, audio, document, photo, or video messages. If a message is part of a message album, then it can be edited only to an audio for audio albums, only to a document for document albums and to a photo or a video otherwise. When an inline message is edited, a new file can't be uploaded. Use a previously uploaded file via its file\_id or specify a URL. On success, if the edited message was sent by the bot, the edited [Message](https://core.telegram.org/bots/api/#message) is returned, otherwise *True* is returned.
#
# POST /editMessageMedia
# Docs: https://core.telegram.org/bots/api/#editmessagemedia
# Returns: record<ok: bool, result: any>
export def "post-edit-message-media" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --chat-id: any # Required if *inline\_message\_id* is not specified. Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --inline-message-id: string # Required if *chat\_id* and *message\_id* are not specified. Identifier of the inline message
  media: any # This object represents the content of a media message to be sent. It should be one of
  --message-id: int # Required if *inline\_message\_id* is not specified. Identifier of the message to edit
  --reply-markup: record # This object represents an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating) that appears right next to the message it belongs to. — shape: {inline_keyboard: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/editMessageMedia"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: chat_id, var: chat_id}, {name: inline_message_id, var: inline_message_id}, {name: media, var: media}, {name: message_id, var: message_id}, {name: reply_markup, var: reply_markup}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    chat_id: $chat_id, inline_message_id: $inline_message_id, media: $media, message_id: $message_id, reply_markup: $reply_markup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to edit only the reply markup of messages. On success, if the edited message is not an inline message, the edited [Message](https://core.telegram.org/bots/api/#message) is returned, otherwise *True* is returned.
#
# POST /editMessageReplyMarkup
# Docs: https://core.telegram.org/bots/api/#editmessagereplymarkup
# Returns: record<ok: bool, result: any>
export def "post-edit-message-reply-markup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --chat-id: any # Required if *inline\_message\_id* is not specified. Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --inline-message-id: string # Required if *chat\_id* and *message\_id* are not specified. Identifier of the inline message
  --message-id: int # Required if *inline\_message\_id* is not specified. Identifier of the message to edit
  --reply-markup: record # This object represents an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating) that appears right next to the message it belongs to. — shape: {inline_keyboard: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/editMessageReplyMarkup"
    body: {content_type: "application/json", kind: json, fields: [{name: chat_id, var: chat_id}, {name: inline_message_id, var: inline_message_id}, {name: message_id, var: message_id}, {name: reply_markup, var: reply_markup}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    chat_id: $chat_id, inline_message_id: $inline_message_id, message_id: $message_id, reply_markup: $reply_markup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to edit text and [game](https://core.telegram.org/bots/api/#games) messages. On success, if the edited message is not an inline message, the edited [Message](https://core.telegram.org/bots/api/#message) is returned, otherwise *True* is returned.
#
# POST /editMessageText
# Docs: https://core.telegram.org/bots/api/#editmessagetext
# Returns: record<ok: bool, result: any>
export def "post-edit-message-text" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --chat-id: any # Required if *inline\_message\_id* is not specified. Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-web-page-preview: oneof<nothing, bool> # Disables link previews for links in this message
  --entities: list # List of special entities that appear in message text, which can be specified instead of *parse\_mode* — item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
  --inline-message-id: string # Required if *chat\_id* and *message\_id* are not specified. Identifier of the inline message
  --message-id: int # Required if *inline\_message\_id* is not specified. Identifier of the message to edit
  --parse-mode: string # Mode for parsing entities in the message text. See [formatting options](https://core.telegram.org/bots/api/#formatting-options) for more details.
  --reply-markup: record # This object represents an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating) that appears right next to the message it belongs to. — shape: {inline_keyboard: list}
  text: string # New text of the message, 1-4096 characters after entities parsing
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/editMessageText"
    body: {content_type: "application/json", kind: json, fields: [{name: chat_id, var: chat_id}, {name: disable_web_page_preview, var: disable_web_page_preview}, {name: entities, var: entities}, {name: inline_message_id, var: inline_message_id}, {name: message_id, var: message_id}, {name: parse_mode, var: parse_mode}, {name: reply_markup, var: reply_markup}, {name: text, var: text}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    chat_id: $chat_id, disable_web_page_preview: $disable_web_page_preview, entities: $entities, inline_message_id: $inline_message_id, message_id: $message_id, parse_mode: $parse_mode, reply_markup: $reply_markup, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to generate a new invite link for a chat; any previously generated link is revoked. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns the new invite link as *String* on success.
#
# POST /exportChatInviteLink
# Docs: https://core.telegram.org/bots/api/#exportchatinvitelink
# Returns: record<ok: bool, result: string>
export def "post-export-chat-invite-link" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/exportChatInviteLink"
    body: {content_type: "application/json", kind: json, fields: [{name: chat_id, var: chat_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    chat_id: $chat_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to forward messages of any kind. On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned.
#
# POST /forwardMessage
# Docs: https://core.telegram.org/bots/api/#forwardmessage
# Returns: record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>
export def "post-forward-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  from_chat_id: any # Unique identifier for the chat where the original message was sent (or channel username in the format `@channelusername`)
  message_id: int # Message identifier in the chat specified in *from\_chat\_id*
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/forwardMessage"
    body: {content_type: "application/json", kind: json, fields: [{name: chat_id, var: chat_id}, {name: disable_notification, var: disable_notification}, {name: from_chat_id, var: from_chat_id}, {name: message_id, var: message_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    chat_id: $chat_id, disable_notification: $disable_notification, from_chat_id: $from_chat_id, message_id: $message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to get up to date information about the chat (current name of the user for one-on-one conversations, current username of a user, group or channel, etc.). Returns a [Chat](https://core.telegram.org/bots/api/#chat) object on success.
#
# POST /getChat
# Docs: https://core.telegram.org/bots/api/#getchat
# Returns: record<ok: bool, result: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record<address: string, location: record>, permissions: record<can_add_web_page_previews: bool, can_change_info: bool, can_invite_users: bool, can_pin_messages: bool, can_send_media_messages: bool, can_send_messages: bool, can_send_other_messages: bool, can_send_polls: bool>, photo: record<big_file_id: string, big_file_unique_id: string, small_file_id: string, small_file_unique_id: string>, pinned_message: record<animation: record, audio: record, author_signature: string, caption: string, caption_entities: list, channel_chat_created: bool, chat: any, connected_website: string, contact: record, date: int, delete_chat_photo: bool, dice: record, document: record, edit_date: int, entities: list, forward_date: int, forward_from: record, forward_from_chat: any, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record, game: record, group_chat_created: bool, invoice: record, left_chat_member: record, location: record, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list, new_chat_photo: list, new_chat_title: string, passport_data: record, photo: list, pinned_message: any, poll: record, proximity_alert_triggered: record, reply_markup: record, reply_to_message: any, sender_chat: any, sticker: record, successful_payment: record, supergroup_chat_created: bool, text: string, venue: record, via_bot: record, video: record, video_note: record, voice: record>, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>>
export def "post-get-chat" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target supergroup or channel (in the format `@channelusername`)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/getChat"
    body: {content_type: "application/json", kind: json, fields: [{name: chat_id, var: chat_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    chat_id: $chat_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to get a list of administrators in a chat. On success, returns an Array of [ChatMember](https://core.telegram.org/bots/api/#chatmember) objects that contains information about all chat administrators except other bots. If the chat is a group or a supergroup and no administrators were appointed, only the creator will be returned.
#
# POST /getChatAdministrators
# Docs: https://core.telegram.org/bots/api/#getchatadministrators
# Returns: record<ok: bool, result: table<can_add_web_page_previews: bool, can_be_edited: bool, can_change_info: bool, can_delete_messages: bool, can_edit_messages: bool, can_invite_users: bool, can_pin_messages: bool, can_post_messages: bool, can_promote_members: bool, can_restrict_members: bool, can_send_media_messages: bool, can_send_messages: bool, can_send_other_messages: bool, can_send_polls: bool, custom_title: string, is_anonymous: bool, is_member: bool, status: string, until_date: int, user: record>>
export def "post-get-chat-administrators" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target supergroup or channel (in the format `@channelusername`)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/getChatAdministrators"
    body: {content_type: "application/json", kind: json, fields: [{name: chat_id, var: chat_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    chat_id: $chat_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to get information about a member of a chat. Returns a [ChatMember](https://core.telegram.org/bots/api/#chatmember) object on success.
#
# POST /getChatMember
# Docs: https://core.telegram.org/bots/api/#getchatmember
# Returns: record<ok: bool, result: record<can_add_web_page_previews: bool, can_be_edited: bool, can_change_info: bool, can_delete_messages: bool, can_edit_messages: bool, can_invite_users: bool, can_pin_messages: bool, can_post_messages: bool, can_promote_members: bool, can_restrict_members: bool, can_send_media_messages: bool, can_send_messages: bool, can_send_other_messages: bool, can_send_polls: bool, custom_title: string, is_anonymous: bool, is_member: bool, status: string, until_date: int, user: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>>>
export def "post-get-chat-member" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target supergroup or channel (in the format `@channelusername`)
  user_id: int # Unique identifier of the target user
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/getChatMember"
    body: {content_type: "application/json", kind: json, fields: [{name: chat_id, var: chat_id}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    chat_id: $chat_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to get the number of members in a chat. Returns *Int* on success.
#
# POST /getChatMembersCount
# Docs: https://core.telegram.org/bots/api/#getchatmemberscount
# Returns: record<ok: bool, result: int>
export def "post-get-chat-members-count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target supergroup or channel (in the format `@channelusername`)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/getChatMembersCount"
    body: {content_type: "application/json", kind: json, fields: [{name: chat_id, var: chat_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    chat_id: $chat_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to get basic info about a file and prepare it for downloading. For the moment, bots can download files of up to 20MB in size. On success, a [File](https://core.telegram.org/bots/api/#file) object is returned. The file can then be downloaded via the link `https://api.telegram.org/file/bot/<file_path>`, where `<file_path>` is taken from the response. It is guaranteed that the link will be valid for at least 1 hour. When the link expires, a new one can be requested by calling [getFile](https://core.telegram.org/bots/api/#getfile) again.
#
# POST /getFile
# Docs: https://core.telegram.org/bots/api/#getfile
# Returns: record<ok: bool, result: record<file_id: string, file_path: string, file_size: int, file_unique_id: string>>
export def "post-get-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file_id: string # File identifier to get info about
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/getFile"
    body: {content_type: "application/json", kind: json, fields: [{name: file_id, var: file_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to get data for high score tables. Will return the score of the specified user and several of their neighbors in a game. On success, returns an *Array* of [GameHighScore](https://core.telegram.org/bots/api/#gamehighscore) objects. This method will currently return scores for the target user, plus two of their closest neighbors on each side. Will also return the top three users if the user and his neighbors are not among them. Please note that this behavior is subject to change.
#
# POST /getGameHighScores
# Docs: https://core.telegram.org/bots/api/#getgamehighscores
# Returns: record<ok: bool, result: table<position: int, score: int, user: record>>
export def "post-get-game-high-scores" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --chat-id: int # Required if *inline\_message\_id* is not specified. Unique identifier for the target chat
  --inline-message-id: string # Required if *chat\_id* and *message\_id* are not specified. Identifier of the inline message
  --message-id: int # Required if *inline\_message\_id* is not specified. Identifier of the sent message
  user_id: int # Target user id
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/getGameHighScores"
    body: {content_type: "application/json", kind: json, fields: [{name: chat_id, var: chat_id}, {name: inline_message_id, var: inline_message_id}, {name: message_id, var: message_id}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    chat_id: $chat_id, inline_message_id: $inline_message_id, message_id: $message_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# A simple method for testing your bot's auth token. Requires no parameters. Returns basic information about the bot in form of a [User](https://core.telegram.org/bots/api/#user) object.
#
# POST /getMe
# Docs: https://core.telegram.org/bots/api/#getme
# Returns: record<ok: bool, result: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>>
export def "post-get-me" [
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
    path: "/getMe"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to get the current list of the bot's commands. Requires no parameters. Returns Array of [BotCommand](https://core.telegram.org/bots/api/#botcommand) on success.
#
# POST /getMyCommands
# Docs: https://core.telegram.org/bots/api/#getmycommands
# Returns: record<ok: bool, result: table<command: string, description: string>>
export def "post-get-my-commands" [
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
    path: "/getMyCommands"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to get a sticker set. On success, a [StickerSet](https://core.telegram.org/bots/api/#stickerset) object is returned.
#
# POST /getStickerSet
# Docs: https://core.telegram.org/bots/api/#getstickerset
# Returns: record<ok: bool, result: record<contains_masks: bool, is_animated: bool, name: string, stickers: list<record>, thumb: record<file_id: string, file_size: int, file_unique_id: string, height: int, width: int>, title: string>>
export def "post-get-sticker-set" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of the sticker set
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/getStickerSet"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to receive incoming updates using long polling ([wiki](https://en.wikipedia.org/wiki/Push_technology#Long_polling)). An Array of [Update](https://core.telegram.org/bots/api/#update) objects is returned.
#
# POST /getUpdates
# Docs: https://core.telegram.org/bots/api/#getupdates
# Returns: record<ok: bool, result: table<callback_query: record, channel_post: record, chosen_inline_result: record, edited_channel_post: record, edited_message: record, inline_query: record, message: record, poll: record, poll_answer: record, pre_checkout_query: record, shipping_query: record, update_id: int>>
export def "post-get-updates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowed-updates: list<string> # A JSON-serialized list of the update types you want your bot to receive. For example, specify [“message”, “edited\_channel\_post”, “callback\_query”] to only receive updates of these types. See [Update](https://core.telegram.org/bots/api/#update) for a complete list of available update types. Specify an empty list to receive all updates regardless of type (default). If not specified, the previous setting will be used. Please note that this parameter doesn't affect updates created before the call to the getUpdates, so unwanted updates may be received for a short period of time.
  --limit: int # Limits the number of updates to be retrieved. Values between 1-100 are accepted. Defaults to 100. (default: 100)
  --offset: int # Identifier of the first update to be returned. Must be greater by one than the highest among the identifiers of previously received updates. By default, updates starting with the earliest unconfirmed update are returned. An update is considered confirmed as soon as [getUpdates](https://core.telegram.org/bots/api/#getupdates) is called with an *offset* higher than its *update\_id*. The negative offset can be specified to retrieve updates starting from *-offset* update from the end of the updates queue. All previous updates will forgotten.
  --timeout: int # Timeout in seconds for long polling. Defaults to 0, i.e. usual short polling. Should be positive, short polling should be used for testing purposes only. (default: 0)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/getUpdates"
    body: {content_type: "application/json", kind: json, fields: [{name: allowed_updates, var: allowed_updates}, {name: limit, var: limit}, {name: offset, var: offset}, {name: timeout, var: timeout}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allowed_updates: $allowed_updates, limit: $limit, offset: $offset, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to get a list of profile pictures for a user. Returns a [UserProfilePhotos](https://core.telegram.org/bots/api/#userprofilephotos) object.
#
# POST /getUserProfilePhotos
# Docs: https://core.telegram.org/bots/api/#getuserprofilephotos
# Returns: record<ok: bool, result: record<photos: list<list>, total_count: int>>
export def "post-get-user-profile-photos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Limits the number of photos to be retrieved. Values between 1-100 are accepted. Defaults to 100. (default: 100)
  --offset: int # Sequential number of the first photo to be returned. By default, all photos are returned.
  user_id: int # Unique identifier of the target user
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/getUserProfilePhotos"
    body: {content_type: "application/json", kind: json, fields: [{name: limit, var: limit}, {name: offset, var: offset}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to get current webhook status. Requires no parameters. On success, returns a [WebhookInfo](https://core.telegram.org/bots/api/#webhookinfo) object. If the bot is using [getUpdates](https://core.telegram.org/bots/api/#getupdates), will return an object with the *url* field empty.
#
# POST /getWebhookInfo
# Docs: https://core.telegram.org/bots/api/#getwebhookinfo
# Returns: record<ok: bool, result: record<allowed_updates: list<string>, has_custom_certificate: bool, ip_address: string, last_error_date: int, last_error_message: string, max_connections: int, pending_update_count: int, url: string>>
export def "post-get-webhook-info" [
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
    path: "/getWebhookInfo"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to kick a user from a group, a supergroup or a channel. In the case of supergroups and channels, the user will not be able to return to the group on their own using invite links, etc., unless [unbanned](https://core.telegram.org/bots/api/#unbanchatmember) first. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns *True* on success.
#
# POST /kickChatMember
# Docs: https://core.telegram.org/bots/api/#kickchatmember
# Returns: record<ok: bool, result: bool>
export def "post-kick-chat-member" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target group or username of the target supergroup or channel (in the format `@channelusername`)
  --until-date: int # Date when the user will be unbanned, unix time. If user is banned for more than 366 days or less than 30 seconds from the current time they are considered to be banned forever
  user_id: int # Unique identifier of the target user
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/kickChatMember"
    body: {content_type: "application/json", kind: json, fields: [{name: chat_id, var: chat_id}, {name: until_date, var: until_date}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    chat_id: $chat_id, until_date: $until_date, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method for your bot to leave a group, supergroup or channel. Returns *True* on success.
#
# POST /leaveChat
# Docs: https://core.telegram.org/bots/api/#leavechat
# Returns: record<ok: bool, result: bool>
export def "post-leave-chat" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target supergroup or channel (in the format `@channelusername`)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/leaveChat"
    body: {content_type: "application/json", kind: json, fields: [{name: chat_id, var: chat_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    chat_id: $chat_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to log out from the cloud Bot API server before launching the bot locally. You **must** log out the bot before running it locally, otherwise there is no guarantee that the bot will receive updates. After a successful call, you can immediately log in on a local server, but will not be able to log in back to the cloud Bot API server for 10 minutes. Returns *True* on success. Requires no parameters.
#
# POST /logOut
# Docs: https://core.telegram.org/bots/api/#logout
# Returns: record<ok: bool, result: bool>
export def "post-log-out" [
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
    path: "/logOut"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to add a message to the list of pinned messages in a chat. If the chat is not a private chat, the bot must be an administrator in the chat for this to work and must have the 'can\_pin\_messages' admin right in a supergroup or 'can\_edit\_messages' admin right in a channel. Returns *True* on success.
#
# POST /pinChatMessage
# Docs: https://core.telegram.org/bots/api/#pinchatmessage
# Returns: record<ok: bool, result: bool>
export def "post-pin-chat-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-notification: oneof<nothing, bool> # Pass *True*, if it is not necessary to send a notification to all chat members about the new pinned message. Notifications are always disabled in channels and private chats.
  message_id: int # Identifier of a message to pin
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/pinChatMessage"
    body: {content_type: "application/json", kind: json, fields: [{name: chat_id, var: chat_id}, {name: disable_notification, var: disable_notification}, {name: message_id, var: message_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    chat_id: $chat_id, disable_notification: $disable_notification, message_id: $message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to promote or demote a user in a supergroup or a channel. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Pass *False* for all boolean parameters to demote a user. Returns *True* on success.
#
# POST /promoteChatMember
# Docs: https://core.telegram.org/bots/api/#promotechatmember
# Returns: record<ok: bool, result: bool>
export def "post-promote-chat-member" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --can-change-info: oneof<nothing, bool> # Pass True, if the administrator can change chat title, photo and other settings
  --can-delete-messages: oneof<nothing, bool> # Pass True, if the administrator can delete messages of other users
  --can-edit-messages: oneof<nothing, bool> # Pass True, if the administrator can edit messages of other users and can pin messages, channels only
  --can-invite-users: oneof<nothing, bool> # Pass True, if the administrator can invite new users to the chat
  --can-pin-messages: oneof<nothing, bool> # Pass True, if the administrator can pin messages, supergroups only
  --can-post-messages: oneof<nothing, bool> # Pass True, if the administrator can create channel posts, channels only
  --can-promote-members: oneof<nothing, bool> # Pass True, if the administrator can add new administrators with a subset of their own privileges or demote administrators that he has promoted, directly or indirectly (promoted by administrators that were appointed by him)
  --can-restrict-members: oneof<nothing, bool> # Pass True, if the administrator can restrict, ban or unban chat members
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --is-anonymous: oneof<nothing, bool> # Pass *True*, if the administrator's presence in the chat is hidden
  user_id: int # Unique identifier of the target user
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/promoteChatMember"
    body: {content_type: "application/json", kind: json, fields: [{name: can_change_info, var: can_change_info}, {name: can_delete_messages, var: can_delete_messages}, {name: can_edit_messages, var: can_edit_messages}, {name: can_invite_users, var: can_invite_users}, {name: can_pin_messages, var: can_pin_messages}, {name: can_post_messages, var: can_post_messages}, {name: can_promote_members, var: can_promote_members}, {name: can_restrict_members, var: can_restrict_members}, {name: chat_id, var: chat_id}, {name: is_anonymous, var: is_anonymous}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    can_change_info: $can_change_info, can_delete_messages: $can_delete_messages, can_edit_messages: $can_edit_messages, can_invite_users: $can_invite_users, can_pin_messages: $can_pin_messages, can_post_messages: $can_post_messages, can_promote_members: $can_promote_members, can_restrict_members: $can_restrict_members, chat_id: $chat_id, is_anonymous: $is_anonymous, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to restrict a user in a supergroup. The bot must be an administrator in the supergroup for this to work and must have the appropriate admin rights. Pass *True* for all permissions to lift restrictions from a user. Returns *True* on success.
#
# POST /restrictChatMember
# Docs: https://core.telegram.org/bots/api/#restrictchatmember
# Returns: record<ok: bool, result: bool>
export def "post-restrict-chat-member" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target supergroup (in the format `@supergroupusername`)
  permissions: record # Describes actions that a non-administrator user is allowed to take in a chat. — shape: {can_add_web_page_previews?: bool, can_change_info?: bool, can_invite_users?: bool, can_pin_messages?: bool, can_send_media_messages?: bool, can_send_messages?: bool, can_send_other_messages?: bool, can_send_polls?: bool}
  --until-date: int # Date when restrictions will be lifted for the user, unix time. If user is restricted for more than 366 days or less than 30 seconds from the current time, they are considered to be restricted forever
  user_id: int # Unique identifier of the target user
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/restrictChatMember"
    body: {content_type: "application/json", kind: json, fields: [{name: chat_id, var: chat_id}, {name: permissions, var: permissions}, {name: until_date, var: until_date}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    chat_id: $chat_id, permissions: $permissions, until_date: $until_date, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to send animation files (GIF or H.264/MPEG-4 AVC video without sound). On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned. Bots can currently send animation files of up to 50 MB in size, this limit may be changed in the future.
#
# POST /sendAnimation
# Docs: https://core.telegram.org/bots/api/#sendanimation
# Returns: record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>
export def "post-send-animation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  animation: any # Animation to send. Pass a file\_id as String to send an animation that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get an animation from the Internet, or upload a new animation using multipart/form-data. [More info on Sending Files »](https://core.telegram.org/bots/api/#sending-files)
  --caption: string # Animation caption (may also be used when resending animation by *file\_id*), 0-1024 characters after entities parsing
  --caption-entities: list # List of special entities that appear in the caption, which can be specified instead of *parse\_mode* — item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  --duration: int # Duration of sent animation in seconds
  --height: int # Animation height
  --parse-mode: string # Mode for parsing entities in the animation caption. See [formatting options](https://core.telegram.org/bots/api/#formatting-options) for more details.
  --reply-markup: any # Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating), [custom reply keyboard](https://core.telegram.org/bots#keyboards), instructions to remove reply keyboard or to force a reply from the user.
  --reply-to-message-id: int # If the message is a reply, ID of the original message
  --thumb: any # Thumbnail of the file sent; can be ignored if thumbnail generation for the file is supported server-side. The thumbnail should be in JPEG format and less than 200 kB in size. A thumbnail's width and height should not exceed 320. Ignored if the file is not uploaded using multipart/form-data. Thumbnails can't be reused and can be only uploaded as a new file, so you can pass “attach://<file\_attach\_name>” if the thumbnail was uploaded using multipart/form-data under <file\_attach\_name>. [More info on Sending Files »](https://core.telegram.org/bots/api/#sending-files)
  --width: int # Animation width
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sendAnimation"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: allow_sending_without_reply, var: allow_sending_without_reply}, {name: animation, var: animation}, {name: caption, var: caption}, {name: caption_entities, var: caption_entities}, {name: chat_id, var: chat_id}, {name: disable_notification, var: disable_notification}, {name: duration, var: duration}, {name: height, var: height}, {name: parse_mode, var: parse_mode}, {name: reply_markup, var: reply_markup}, {name: reply_to_message_id, var: reply_to_message_id}, {name: thumb, var: thumb}, {name: width, var: width}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allow_sending_without_reply: $allow_sending_without_reply, animation: $animation, caption: $caption, caption_entities: $caption_entities, chat_id: $chat_id, disable_notification: $disable_notification, duration: $duration, height: $height, parse_mode: $parse_mode, reply_markup: $reply_markup, reply_to_message_id: $reply_to_message_id, thumb: $thumb, width: $width
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to send audio files, if you want Telegram clients to display them in the music player. Your audio must be in the .MP3 or .M4A format. On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned. Bots can currently send audio files of up to 50 MB in size, this limit may be changed in the future. For sending voice messages, use the [sendVoice](https://core.telegram.org/bots/api/#sendvoice) method instead.
#
# POST /sendAudio
# Docs: https://core.telegram.org/bots/api/#sendaudio
# Returns: record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>
export def "post-send-audio" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  audio: any # Audio file to send. Pass a file\_id as String to send an audio file that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get an audio file from the Internet, or upload a new one using multipart/form-data. [More info on Sending Files »](https://core.telegram.org/bots/api/#sending-files)
  --caption: string # Audio caption, 0-1024 characters after entities parsing
  --caption-entities: list # List of special entities that appear in the caption, which can be specified instead of *parse\_mode* — item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  --duration: int # Duration of the audio in seconds
  --parse-mode: string # Mode for parsing entities in the audio caption. See [formatting options](https://core.telegram.org/bots/api/#formatting-options) for more details.
  --performer: string # Performer
  --reply-markup: any # Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating), [custom reply keyboard](https://core.telegram.org/bots#keyboards), instructions to remove reply keyboard or to force a reply from the user.
  --reply-to-message-id: int # If the message is a reply, ID of the original message
  --thumb: any # Thumbnail of the file sent; can be ignored if thumbnail generation for the file is supported server-side. The thumbnail should be in JPEG format and less than 200 kB in size. A thumbnail's width and height should not exceed 320. Ignored if the file is not uploaded using multipart/form-data. Thumbnails can't be reused and can be only uploaded as a new file, so you can pass “attach://<file\_attach\_name>” if the thumbnail was uploaded using multipart/form-data under <file\_attach\_name>. [More info on Sending Files »](https://core.telegram.org/bots/api/#sending-files)
  --title: string # Track name
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sendAudio"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: allow_sending_without_reply, var: allow_sending_without_reply}, {name: audio, var: audio}, {name: caption, var: caption}, {name: caption_entities, var: caption_entities}, {name: chat_id, var: chat_id}, {name: disable_notification, var: disable_notification}, {name: duration, var: duration}, {name: parse_mode, var: parse_mode}, {name: performer, var: performer}, {name: reply_markup, var: reply_markup}, {name: reply_to_message_id, var: reply_to_message_id}, {name: thumb, var: thumb}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allow_sending_without_reply: $allow_sending_without_reply, audio: $audio, caption: $caption, caption_entities: $caption_entities, chat_id: $chat_id, disable_notification: $disable_notification, duration: $duration, parse_mode: $parse_mode, performer: $performer, reply_markup: $reply_markup, reply_to_message_id: $reply_to_message_id, thumb: $thumb, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method when you need to tell the user that something is happening on the bot's side. The status is set for 5 seconds or less (when a message arrives from your bot, Telegram clients clear its typing status). Returns *True* on success. Example: The [ImageBot](https://t.me/imagebot) needs some time to process a request and upload the image. Instead of sending a text message along the lines of “Retrieving image, please wait…”, the bot may use [sendChatAction](https://core.telegram.org/bots/api/#sendchataction) with *action* = *upload\_photo*. The user will see a “sending photo” status for the bot. We only recommend using this method when a response from the bot will take a **noticeable** amount of time to arrive.
#
# POST /sendChatAction
# Docs: https://core.telegram.org/bots/api/#sendchataction
# Returns: record<ok: bool, result: bool>
export def "post-send-chat-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  action: string # Type of action to broadcast. Choose one, depending on what the user is about to receive: *typing* for [text messages](https://core.telegram.org/bots/api/#sendmessage), *upload\_photo* for [photos](https://core.telegram.org/bots/api/#sendphoto), *record\_video* or *upload\_video* for [videos](https://core.telegram.org/bots/api/#sendvideo), *record\_voice* or *upload\_voice* for [voice notes](https://core.telegram.org/bots/api/#sendvoice), *upload\_document* for [general files](https://core.telegram.org/bots/api/#senddocument), *find\_location* for [location data](https://core.telegram.org/bots/api/#sendlocation), *record\_video\_note* or *upload\_video\_note* for [video notes](https://core.telegram.org/bots/api/#sendvideonote).
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sendChatAction"
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: chat_id, var: chat_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action: $action, chat_id: $chat_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to send phone contacts. On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned.
#
# POST /sendContact
# Docs: https://core.telegram.org/bots/api/#sendcontact
# Returns: record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>
export def "post-send-contact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  first_name: string # Contact's first name
  --last-name: string # Contact's last name
  phone_number: string # Contact's phone number
  --reply-markup: any # Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating), [custom reply keyboard](https://core.telegram.org/bots#keyboards), instructions to remove keyboard or to force a reply from the user.
  --reply-to-message-id: int # If the message is a reply, ID of the original message
  --vcard: string # Additional data about the contact in the form of a [vCard](https://en.wikipedia.org/wiki/VCard), 0-2048 bytes
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sendContact"
    body: {content_type: "application/json", kind: json, fields: [{name: allow_sending_without_reply, var: allow_sending_without_reply}, {name: chat_id, var: chat_id}, {name: disable_notification, var: disable_notification}, {name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: phone_number, var: phone_number}, {name: reply_markup, var: reply_markup}, {name: reply_to_message_id, var: reply_to_message_id}, {name: vcard, var: vcard}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allow_sending_without_reply: $allow_sending_without_reply, chat_id: $chat_id, disable_notification: $disable_notification, first_name: $first_name, last_name: $last_name, phone_number: $phone_number, reply_markup: $reply_markup, reply_to_message_id: $reply_to_message_id, vcard: $vcard
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to send an animated emoji that will display a random value. On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned.
#
# POST /sendDice
# Docs: https://core.telegram.org/bots/api/#senddice
# Returns: record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>
export def "post-send-dice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  --emoji: string@emoji-completer # Emoji on which the dice throw animation is based. Currently, must be one of “”, “”, “”, “”, or “”. Dice can have values 1-6 for “” and “”, values 1-5 for “” and “”, and values 1-64 for “”. Defaults to “” (default: 🎲)
  --reply-markup: any # Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating), [custom reply keyboard](https://core.telegram.org/bots#keyboards), instructions to remove reply keyboard or to force a reply from the user.
  --reply-to-message-id: int # If the message is a reply, ID of the original message
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sendDice"
    body: {content_type: "application/json", kind: json, fields: [{name: allow_sending_without_reply, var: allow_sending_without_reply}, {name: chat_id, var: chat_id}, {name: disable_notification, var: disable_notification}, {name: emoji, var: emoji}, {name: reply_markup, var: reply_markup}, {name: reply_to_message_id, var: reply_to_message_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allow_sending_without_reply: $allow_sending_without_reply, chat_id: $chat_id, disable_notification: $disable_notification, emoji: $emoji, reply_markup: $reply_markup, reply_to_message_id: $reply_to_message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to send general files. On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned. Bots can currently send files of any type of up to 50 MB in size, this limit may be changed in the future.
#
# POST /sendDocument
# Docs: https://core.telegram.org/bots/api/#senddocument
# Returns: record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>
export def "post-send-document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  --caption: string # Document caption (may also be used when resending documents by *file\_id*), 0-1024 characters after entities parsing
  --caption-entities: list # List of special entities that appear in the caption, which can be specified instead of *parse\_mode* — item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-content-type-detection: oneof<nothing, bool> # Disables automatic server-side content type detection for files uploaded using multipart/form-data
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  document: any # File to send. Pass a file\_id as String to send a file that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get a file from the Internet, or upload a new one using multipart/form-data. [More info on Sending Files »](https://core.telegram.org/bots/api/#sending-files)
  --parse-mode: string # Mode for parsing entities in the document caption. See [formatting options](https://core.telegram.org/bots/api/#formatting-options) for more details.
  --reply-markup: any # Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating), [custom reply keyboard](https://core.telegram.org/bots#keyboards), instructions to remove reply keyboard or to force a reply from the user.
  --reply-to-message-id: int # If the message is a reply, ID of the original message
  --thumb: any # Thumbnail of the file sent; can be ignored if thumbnail generation for the file is supported server-side. The thumbnail should be in JPEG format and less than 200 kB in size. A thumbnail's width and height should not exceed 320. Ignored if the file is not uploaded using multipart/form-data. Thumbnails can't be reused and can be only uploaded as a new file, so you can pass “attach://<file\_attach\_name>” if the thumbnail was uploaded using multipart/form-data under <file\_attach\_name>. [More info on Sending Files »](https://core.telegram.org/bots/api/#sending-files)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sendDocument"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: allow_sending_without_reply, var: allow_sending_without_reply}, {name: caption, var: caption}, {name: caption_entities, var: caption_entities}, {name: chat_id, var: chat_id}, {name: disable_content_type_detection, var: disable_content_type_detection}, {name: disable_notification, var: disable_notification}, {name: document, var: document}, {name: parse_mode, var: parse_mode}, {name: reply_markup, var: reply_markup}, {name: reply_to_message_id, var: reply_to_message_id}, {name: thumb, var: thumb}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allow_sending_without_reply: $allow_sending_without_reply, caption: $caption, caption_entities: $caption_entities, chat_id: $chat_id, disable_content_type_detection: $disable_content_type_detection, disable_notification: $disable_notification, document: $document, parse_mode: $parse_mode, reply_markup: $reply_markup, reply_to_message_id: $reply_to_message_id, thumb: $thumb
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to send a game. On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned.
#
# POST /sendGame
# Docs: https://core.telegram.org/bots/api/#sendgame
# Returns: record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>
export def "post-send-game" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  chat_id: int # Unique identifier for the target chat
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  game_short_name: string # Short name of the game, serves as the unique identifier for the game. Set up your games via [Botfather](https://t.me/botfather).
  --reply-markup: record # This object represents an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating) that appears right next to the message it belongs to. — shape: {inline_keyboard: list}
  --reply-to-message-id: int # If the message is a reply, ID of the original message
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sendGame"
    body: {content_type: "application/json", kind: json, fields: [{name: allow_sending_without_reply, var: allow_sending_without_reply}, {name: chat_id, var: chat_id}, {name: disable_notification, var: disable_notification}, {name: game_short_name, var: game_short_name}, {name: reply_markup, var: reply_markup}, {name: reply_to_message_id, var: reply_to_message_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allow_sending_without_reply: $allow_sending_without_reply, chat_id: $chat_id, disable_notification: $disable_notification, game_short_name: $game_short_name, reply_markup: $reply_markup, reply_to_message_id: $reply_to_message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to send invoices. On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned.
#
# POST /sendInvoice
# Docs: https://core.telegram.org/bots/api/#sendinvoice
# Returns: record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>
export def "post-send-invoice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  chat_id: int # Unique identifier for the target private chat
  currency: string # Three-letter ISO 4217 currency code, see [more on currencies](/bots/payments#supported-currencies)
  description: string # Product description, 1-255 characters
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  --is-flexible: oneof<nothing, bool> # Pass *True*, if the final price depends on the shipping method
  --need-email: oneof<nothing, bool> # Pass *True*, if you require the user's email address to complete the order
  --need-name: oneof<nothing, bool> # Pass *True*, if you require the user's full name to complete the order
  --need-phone-number: oneof<nothing, bool> # Pass *True*, if you require the user's phone number to complete the order
  --need-shipping-address: oneof<nothing, bool> # Pass *True*, if you require the user's shipping address to complete the order
  payload: string # Bot-defined invoice payload, 1-128 bytes. This will not be displayed to the user, use for your internal processes.
  --photo-height: int # Photo height
  --photo-size: int # Photo size
  --photo-url: string # URL of the product photo for the invoice. Can be a photo of the goods or a marketing image for a service. People like it better when they see what they are paying for.
  --photo-width: int # Photo width
  prices: list # Price breakdown, a JSON-serialized list of components (e.g. product price, tax, discount, delivery cost, delivery tax, bonus, etc.) — item shape: {amount: int, label: string}
  --provider-data: string # A JSON-serialized data about the invoice, which will be shared with the payment provider. A detailed description of required fields should be provided by the payment provider.
  provider_token: string # Payments provider token, obtained via [Botfather](https://t.me/botfather)
  --reply-markup: record # This object represents an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating) that appears right next to the message it belongs to. — shape: {inline_keyboard: list}
  --reply-to-message-id: int # If the message is a reply, ID of the original message
  --send-email-to-provider: oneof<nothing, bool> # Pass *True*, if user's email address should be sent to provider
  --send-phone-number-to-provider: oneof<nothing, bool> # Pass *True*, if user's phone number should be sent to provider
  start_parameter: string # Unique deep-linking parameter that can be used to generate this invoice when used as a start parameter
  title: string # Product name, 1-32 characters
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sendInvoice"
    body: {content_type: "application/json", kind: json, fields: [{name: allow_sending_without_reply, var: allow_sending_without_reply}, {name: chat_id, var: chat_id}, {name: currency, var: currency}, {name: description, var: description}, {name: disable_notification, var: disable_notification}, {name: is_flexible, var: is_flexible}, {name: need_email, var: need_email}, {name: need_name, var: need_name}, {name: need_phone_number, var: need_phone_number}, {name: need_shipping_address, var: need_shipping_address}, {name: payload, var: payload}, {name: photo_height, var: photo_height}, {name: photo_size, var: photo_size}, {name: photo_url, var: photo_url}, {name: photo_width, var: photo_width}, {name: prices, var: prices}, {name: provider_data, var: provider_data}, {name: provider_token, var: provider_token}, {name: reply_markup, var: reply_markup}, {name: reply_to_message_id, var: reply_to_message_id}, {name: send_email_to_provider, var: send_email_to_provider}, {name: send_phone_number_to_provider, var: send_phone_number_to_provider}, {name: start_parameter, var: start_parameter}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allow_sending_without_reply: $allow_sending_without_reply, chat_id: $chat_id, currency: $currency, description: $description, disable_notification: $disable_notification, is_flexible: $is_flexible, need_email: $need_email, need_name: $need_name, need_phone_number: $need_phone_number, need_shipping_address: $need_shipping_address, payload: $payload, photo_height: $photo_height, photo_size: $photo_size, photo_url: $photo_url, photo_width: $photo_width, prices: $prices, provider_data: $provider_data, provider_token: $provider_token, reply_markup: $reply_markup, reply_to_message_id: $reply_to_message_id, send_email_to_provider: $send_email_to_provider, send_phone_number_to_provider: $send_phone_number_to_provider, start_parameter: $start_parameter, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to send point on the map. On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned.
#
# POST /sendLocation
# Docs: https://core.telegram.org/bots/api/#sendlocation
# Returns: record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>
export def "post-send-location" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  --heading: int # For live locations, a direction in which the user is moving, in degrees. Must be between 1 and 360 if specified.
  --horizontal-accuracy: float # The radius of uncertainty for the location, measured in meters; 0-1500
  latitude: float # Latitude of the location
  --live-period: int # Period in seconds for which the location will be updated (see [Live Locations](https://telegram.org/blog/live-locations), should be between 60 and 86400.
  longitude: float # Longitude of the location
  --proximity-alert-radius: int # For live locations, a maximum distance for proximity alerts about approaching another chat member, in meters. Must be between 1 and 100000 if specified.
  --reply-markup: any # Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating), [custom reply keyboard](https://core.telegram.org/bots#keyboards), instructions to remove reply keyboard or to force a reply from the user.
  --reply-to-message-id: int # If the message is a reply, ID of the original message
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sendLocation"
    body: {content_type: "application/json", kind: json, fields: [{name: allow_sending_without_reply, var: allow_sending_without_reply}, {name: chat_id, var: chat_id}, {name: disable_notification, var: disable_notification}, {name: heading, var: heading}, {name: horizontal_accuracy, var: horizontal_accuracy}, {name: latitude, var: latitude}, {name: live_period, var: live_period}, {name: longitude, var: longitude}, {name: proximity_alert_radius, var: proximity_alert_radius}, {name: reply_markup, var: reply_markup}, {name: reply_to_message_id, var: reply_to_message_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allow_sending_without_reply: $allow_sending_without_reply, chat_id: $chat_id, disable_notification: $disable_notification, heading: $heading, horizontal_accuracy: $horizontal_accuracy, latitude: $latitude, live_period: $live_period, longitude: $longitude, proximity_alert_radius: $proximity_alert_radius, reply_markup: $reply_markup, reply_to_message_id: $reply_to_message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to send a group of photos, videos, documents or audios as an album. Documents and audio files can be only grouped in an album with messages of the same type. On success, an array of [Messages](https://core.telegram.org/bots/api/#message) that were sent is returned.
#
# POST /sendMediaGroup
# Docs: https://core.telegram.org/bots/api/#sendmediagroup
# Returns: record<ok: bool, result: table<animation: record, audio: record, author_signature: string, caption: string, caption_entities: list, channel_chat_created: bool, chat: record, connected_website: string, contact: record, date: int, delete_chat_photo: bool, dice: record, document: record, edit_date: int, entities: list, forward_date: int, forward_from: record, forward_from_chat: record, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record, game: record, group_chat_created: bool, invoice: record, left_chat_member: record, location: record, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list, new_chat_photo: list, new_chat_title: string, passport_data: record, photo: list, pinned_message: any, poll: record, proximity_alert_triggered: record, reply_markup: record, reply_to_message: any, sender_chat: record, sticker: record, successful_payment: record, supergroup_chat_created: bool, text: string, venue: record, via_bot: record, video: record, video_note: record, voice: record>>
export def "post-send-media-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-notification: oneof<nothing, bool> # Sends messages [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  media: list # A JSON-serialized array describing messages to be sent, must include 2-10 items
  --reply-to-message-id: int # If the messages are a reply, ID of the original message
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sendMediaGroup"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: allow_sending_without_reply, var: allow_sending_without_reply}, {name: chat_id, var: chat_id}, {name: disable_notification, var: disable_notification}, {name: media, var: media}, {name: reply_to_message_id, var: reply_to_message_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allow_sending_without_reply: $allow_sending_without_reply, chat_id: $chat_id, disable_notification: $disable_notification, media: $media, reply_to_message_id: $reply_to_message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to send text messages. On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned.
#
# POST /sendMessage
# Docs: https://core.telegram.org/bots/api/#sendmessage
# Returns: record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>
export def "post-send-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  --disable-web-page-preview: oneof<nothing, bool> # Disables link previews for links in this message
  --entities: list # List of special entities that appear in message text, which can be specified instead of *parse\_mode* — item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
  --parse-mode: string # Mode for parsing entities in the message text. See [formatting options](https://core.telegram.org/bots/api/#formatting-options) for more details.
  --reply-markup: any # Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating), [custom reply keyboard](https://core.telegram.org/bots#keyboards), instructions to remove reply keyboard or to force a reply from the user.
  --reply-to-message-id: int # If the message is a reply, ID of the original message
  text: string # Text of the message to be sent, 1-4096 characters after entities parsing
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sendMessage"
    body: {content_type: "application/json", kind: json, fields: [{name: allow_sending_without_reply, var: allow_sending_without_reply}, {name: chat_id, var: chat_id}, {name: disable_notification, var: disable_notification}, {name: disable_web_page_preview, var: disable_web_page_preview}, {name: entities, var: entities}, {name: parse_mode, var: parse_mode}, {name: reply_markup, var: reply_markup}, {name: reply_to_message_id, var: reply_to_message_id}, {name: text, var: text}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allow_sending_without_reply: $allow_sending_without_reply, chat_id: $chat_id, disable_notification: $disable_notification, disable_web_page_preview: $disable_web_page_preview, entities: $entities, parse_mode: $parse_mode, reply_markup: $reply_markup, reply_to_message_id: $reply_to_message_id, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to send photos. On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned.
#
# POST /sendPhoto
# Docs: https://core.telegram.org/bots/api/#sendphoto
# Returns: record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>
export def "post-send-photo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  --caption: string # Photo caption (may also be used when resending photos by *file\_id*), 0-1024 characters after entities parsing
  --caption-entities: list # List of special entities that appear in the caption, which can be specified instead of *parse\_mode* — item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  --parse-mode: string # Mode for parsing entities in the photo caption. See [formatting options](https://core.telegram.org/bots/api/#formatting-options) for more details.
  photo: any # Photo to send. Pass a file\_id as String to send a photo that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get a photo from the Internet, or upload a new photo using multipart/form-data. The photo must be at most 10 MB in size. The photo's width and height must not exceed 10000 in total. Width and height ratio must be at most 20. [More info on Sending Files »](https://core.telegram.org/bots/api/#sending-files)
  --reply-markup: any # Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating), [custom reply keyboard](https://core.telegram.org/bots#keyboards), instructions to remove reply keyboard or to force a reply from the user.
  --reply-to-message-id: int # If the message is a reply, ID of the original message
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sendPhoto"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: allow_sending_without_reply, var: allow_sending_without_reply}, {name: caption, var: caption}, {name: caption_entities, var: caption_entities}, {name: chat_id, var: chat_id}, {name: disable_notification, var: disable_notification}, {name: parse_mode, var: parse_mode}, {name: photo, var: photo}, {name: reply_markup, var: reply_markup}, {name: reply_to_message_id, var: reply_to_message_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allow_sending_without_reply: $allow_sending_without_reply, caption: $caption, caption_entities: $caption_entities, chat_id: $chat_id, disable_notification: $disable_notification, parse_mode: $parse_mode, photo: $photo, reply_markup: $reply_markup, reply_to_message_id: $reply_to_message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to send a native poll. On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned.
#
# POST /sendPoll
# Docs: https://core.telegram.org/bots/api/#sendpoll
# Returns: record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>
export def "post-send-poll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  --allows-multiple-answers: oneof<nothing, bool> # True, if the poll allows multiple answers, ignored for polls in quiz mode, defaults to *False*
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --close-date: int # Point in time (Unix timestamp) when the poll will be automatically closed. Must be at least 5 and no more than 600 seconds in the future. Can't be used together with *open\_period*.
  --correct-option-id: int # 0-based identifier of the correct answer option, required for polls in quiz mode
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  --explanation: string # Text that is shown when a user chooses an incorrect answer or taps on the lamp icon in a quiz-style poll, 0-200 characters with at most 2 line feeds after entities parsing
  --explanation-entities: list # List of special entities that appear in the poll explanation, which can be specified instead of *parse\_mode* — item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
  --explanation-parse-mode: string # Mode for parsing entities in the explanation. See [formatting options](https://core.telegram.org/bots/api/#formatting-options) for more details.
  --is-anonymous: oneof<nothing, bool> # True, if the poll needs to be anonymous, defaults to *True*
  --is-closed: oneof<nothing, bool> # Pass *True*, if the poll needs to be immediately closed. This can be useful for poll preview.
  --open-period: int # Amount of time in seconds the poll will be active after creation, 5-600. Can't be used together with *close\_date*.
  options: list<string> # A JSON-serialized list of answer options, 2-10 strings 1-100 characters each
  question: string # Poll question, 1-300 characters
  --reply-markup: any # Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating), [custom reply keyboard](https://core.telegram.org/bots#keyboards), instructions to remove reply keyboard or to force a reply from the user.
  --reply-to-message-id: int # If the message is a reply, ID of the original message
  --type: string # Poll type, “quiz” or “regular”, defaults to “regular”
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sendPoll"
    body: {content_type: "application/json", kind: json, fields: [{name: allow_sending_without_reply, var: allow_sending_without_reply}, {name: allows_multiple_answers, var: allows_multiple_answers}, {name: chat_id, var: chat_id}, {name: close_date, var: close_date}, {name: correct_option_id, var: correct_option_id}, {name: disable_notification, var: disable_notification}, {name: explanation, var: explanation}, {name: explanation_entities, var: explanation_entities}, {name: explanation_parse_mode, var: explanation_parse_mode}, {name: is_anonymous, var: is_anonymous}, {name: is_closed, var: is_closed}, {name: open_period, var: open_period}, {name: options, var: options}, {name: question, var: question}, {name: reply_markup, var: reply_markup}, {name: reply_to_message_id, var: reply_to_message_id}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allow_sending_without_reply: $allow_sending_without_reply, allows_multiple_answers: $allows_multiple_answers, chat_id: $chat_id, close_date: $close_date, correct_option_id: $correct_option_id, disable_notification: $disable_notification, explanation: $explanation, explanation_entities: $explanation_entities, explanation_parse_mode: $explanation_parse_mode, is_anonymous: $is_anonymous, is_closed: $is_closed, open_period: $open_period, options: $options, question: $question, reply_markup: $reply_markup, reply_to_message_id: $reply_to_message_id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to send static .WEBP or [animated](https://telegram.org/blog/animated-stickers) .TGS stickers. On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned.
#
# POST /sendSticker
# Docs: https://core.telegram.org/bots/api/#sendsticker
# Returns: record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>
export def "post-send-sticker" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  --reply-markup: any # Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating), [custom reply keyboard](https://core.telegram.org/bots#keyboards), instructions to remove reply keyboard or to force a reply from the user.
  --reply-to-message-id: int # If the message is a reply, ID of the original message
  sticker: any # Sticker to send. Pass a file\_id as String to send a file that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get a .WEBP file from the Internet, or upload a new one using multipart/form-data. [More info on Sending Files »](https://core.telegram.org/bots/api/#sending-files)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sendSticker"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: allow_sending_without_reply, var: allow_sending_without_reply}, {name: chat_id, var: chat_id}, {name: disable_notification, var: disable_notification}, {name: reply_markup, var: reply_markup}, {name: reply_to_message_id, var: reply_to_message_id}, {name: sticker, var: sticker}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allow_sending_without_reply: $allow_sending_without_reply, chat_id: $chat_id, disable_notification: $disable_notification, reply_markup: $reply_markup, reply_to_message_id: $reply_to_message_id, sticker: $sticker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to send information about a venue. On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned.
#
# POST /sendVenue
# Docs: https://core.telegram.org/bots/api/#sendvenue
# Returns: record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>
export def "post-send-venue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  address: string # Address of the venue
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  --foursquare-id: string # Foursquare identifier of the venue
  --foursquare-type: string # Foursquare type of the venue, if known. (For example, “arts\_entertainment/default”, “arts\_entertainment/aquarium” or “food/icecream”.)
  --google-place-id: string # Google Places identifier of the venue
  --google-place-type: string # Google Places type of the venue. (See [supported types](https://developers.google.com/places/web-service/supported_types).)
  latitude: float # Latitude of the venue
  longitude: float # Longitude of the venue
  --reply-markup: any # Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating), [custom reply keyboard](https://core.telegram.org/bots#keyboards), instructions to remove reply keyboard or to force a reply from the user.
  --reply-to-message-id: int # If the message is a reply, ID of the original message
  title: string # Name of the venue
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sendVenue"
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: allow_sending_without_reply, var: allow_sending_without_reply}, {name: chat_id, var: chat_id}, {name: disable_notification, var: disable_notification}, {name: foursquare_id, var: foursquare_id}, {name: foursquare_type, var: foursquare_type}, {name: google_place_id, var: google_place_id}, {name: google_place_type, var: google_place_type}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: reply_markup, var: reply_markup}, {name: reply_to_message_id, var: reply_to_message_id}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    address: $address, allow_sending_without_reply: $allow_sending_without_reply, chat_id: $chat_id, disable_notification: $disable_notification, foursquare_id: $foursquare_id, foursquare_type: $foursquare_type, google_place_id: $google_place_id, google_place_type: $google_place_type, latitude: $latitude, longitude: $longitude, reply_markup: $reply_markup, reply_to_message_id: $reply_to_message_id, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to send video files, Telegram clients support mp4 videos (other formats may be sent as [Document](https://core.telegram.org/bots/api/#document)). On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned. Bots can currently send video files of up to 50 MB in size, this limit may be changed in the future.
#
# POST /sendVideo
# Docs: https://core.telegram.org/bots/api/#sendvideo
# Returns: record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>
export def "post-send-video" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  --caption: string # Video caption (may also be used when resending videos by *file\_id*), 0-1024 characters after entities parsing
  --caption-entities: list # List of special entities that appear in the caption, which can be specified instead of *parse\_mode* — item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  --duration: int # Duration of sent video in seconds
  --height: int # Video height
  --parse-mode: string # Mode for parsing entities in the video caption. See [formatting options](https://core.telegram.org/bots/api/#formatting-options) for more details.
  --reply-markup: any # Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating), [custom reply keyboard](https://core.telegram.org/bots#keyboards), instructions to remove reply keyboard or to force a reply from the user.
  --reply-to-message-id: int # If the message is a reply, ID of the original message
  --supports-streaming: oneof<nothing, bool> # Pass *True*, if the uploaded video is suitable for streaming
  --thumb: any # Thumbnail of the file sent; can be ignored if thumbnail generation for the file is supported server-side. The thumbnail should be in JPEG format and less than 200 kB in size. A thumbnail's width and height should not exceed 320. Ignored if the file is not uploaded using multipart/form-data. Thumbnails can't be reused and can be only uploaded as a new file, so you can pass “attach://<file\_attach\_name>” if the thumbnail was uploaded using multipart/form-data under <file\_attach\_name>. [More info on Sending Files »](https://core.telegram.org/bots/api/#sending-files)
  video: any # Video to send. Pass a file\_id as String to send a video that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get a video from the Internet, or upload a new video using multipart/form-data. [More info on Sending Files »](https://core.telegram.org/bots/api/#sending-files)
  --width: int # Video width
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sendVideo"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: allow_sending_without_reply, var: allow_sending_without_reply}, {name: caption, var: caption}, {name: caption_entities, var: caption_entities}, {name: chat_id, var: chat_id}, {name: disable_notification, var: disable_notification}, {name: duration, var: duration}, {name: height, var: height}, {name: parse_mode, var: parse_mode}, {name: reply_markup, var: reply_markup}, {name: reply_to_message_id, var: reply_to_message_id}, {name: supports_streaming, var: supports_streaming}, {name: thumb, var: thumb}, {name: video, var: video}, {name: width, var: width}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allow_sending_without_reply: $allow_sending_without_reply, caption: $caption, caption_entities: $caption_entities, chat_id: $chat_id, disable_notification: $disable_notification, duration: $duration, height: $height, parse_mode: $parse_mode, reply_markup: $reply_markup, reply_to_message_id: $reply_to_message_id, supports_streaming: $supports_streaming, thumb: $thumb, video: $video, width: $width
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# As of [v.4.0](https://telegram.org/blog/video-messages-and-telescope), Telegram clients support rounded square mp4 videos of up to 1 minute long. Use this method to send video messages. On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned.
#
# POST /sendVideoNote
# Docs: https://core.telegram.org/bots/api/#sendvideonote
# Returns: record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>
export def "post-send-video-note" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  --duration: int # Duration of sent video in seconds
  --length: int # Video width and height, i.e. diameter of the video message
  --reply-markup: any # Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating), [custom reply keyboard](https://core.telegram.org/bots#keyboards), instructions to remove reply keyboard or to force a reply from the user.
  --reply-to-message-id: int # If the message is a reply, ID of the original message
  --thumb: any # Thumbnail of the file sent; can be ignored if thumbnail generation for the file is supported server-side. The thumbnail should be in JPEG format and less than 200 kB in size. A thumbnail's width and height should not exceed 320. Ignored if the file is not uploaded using multipart/form-data. Thumbnails can't be reused and can be only uploaded as a new file, so you can pass “attach://<file\_attach\_name>” if the thumbnail was uploaded using multipart/form-data under <file\_attach\_name>. [More info on Sending Files »](https://core.telegram.org/bots/api/#sending-files)
  video_note: any # Video note to send. Pass a file\_id as String to send a video note that exists on the Telegram servers (recommended) or upload a new video using multipart/form-data. [More info on Sending Files »](https://core.telegram.org/bots/api/#sending-files). Sending video notes by a URL is currently unsupported
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sendVideoNote"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: allow_sending_without_reply, var: allow_sending_without_reply}, {name: chat_id, var: chat_id}, {name: disable_notification, var: disable_notification}, {name: duration, var: duration}, {name: length, var: length}, {name: reply_markup, var: reply_markup}, {name: reply_to_message_id, var: reply_to_message_id}, {name: thumb, var: thumb}, {name: video_note, var: video_note}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allow_sending_without_reply: $allow_sending_without_reply, chat_id: $chat_id, disable_notification: $disable_notification, duration: $duration, length: $length, reply_markup: $reply_markup, reply_to_message_id: $reply_to_message_id, thumb: $thumb, video_note: $video_note
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to send audio files, if you want Telegram clients to display the file as a playable voice message. For this to work, your audio must be in an .OGG file encoded with OPUS (other formats may be sent as [Audio](https://core.telegram.org/bots/api/#audio) or [Document](https://core.telegram.org/bots/api/#document)). On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned. Bots can currently send voice messages of up to 50 MB in size, this limit may be changed in the future.
#
# POST /sendVoice
# Docs: https://core.telegram.org/bots/api/#sendvoice
# Returns: record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>>
export def "post-send-voice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  --caption: string # Voice message caption, 0-1024 characters after entities parsing
  --caption-entities: list # List of special entities that appear in the caption, which can be specified instead of *parse\_mode* — item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  --duration: int # Duration of the voice message in seconds
  --parse-mode: string # Mode for parsing entities in the voice message caption. See [formatting options](https://core.telegram.org/bots/api/#formatting-options) for more details.
  --reply-markup: any # Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating), [custom reply keyboard](https://core.telegram.org/bots#keyboards), instructions to remove reply keyboard or to force a reply from the user.
  --reply-to-message-id: int # If the message is a reply, ID of the original message
  voice: any # Audio file to send. Pass a file\_id as String to send a file that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get a file from the Internet, or upload a new one using multipart/form-data. [More info on Sending Files »](https://core.telegram.org/bots/api/#sending-files)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sendVoice"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: allow_sending_without_reply, var: allow_sending_without_reply}, {name: caption, var: caption}, {name: caption_entities, var: caption_entities}, {name: chat_id, var: chat_id}, {name: disable_notification, var: disable_notification}, {name: duration, var: duration}, {name: parse_mode, var: parse_mode}, {name: reply_markup, var: reply_markup}, {name: reply_to_message_id, var: reply_to_message_id}, {name: voice, var: voice}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allow_sending_without_reply: $allow_sending_without_reply, caption: $caption, caption_entities: $caption_entities, chat_id: $chat_id, disable_notification: $disable_notification, duration: $duration, parse_mode: $parse_mode, reply_markup: $reply_markup, reply_to_message_id: $reply_to_message_id, voice: $voice
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to set a custom title for an administrator in a supergroup promoted by the bot. Returns *True* on success.
#
# POST /setChatAdministratorCustomTitle
# Docs: https://core.telegram.org/bots/api/#setchatadministratorcustomtitle
# Returns: record<ok: bool, result: bool>
export def "post-set-chat-administrator-custom-title" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target supergroup (in the format `@supergroupusername`)
  custom_title: string # New custom title for the administrator; 0-16 characters, emoji are not allowed
  user_id: int # Unique identifier of the target user
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setChatAdministratorCustomTitle"
    body: {content_type: "application/json", kind: json, fields: [{name: chat_id, var: chat_id}, {name: custom_title, var: custom_title}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    chat_id: $chat_id, custom_title: $custom_title, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to change the description of a group, a supergroup or a channel. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns *True* on success.
#
# POST /setChatDescription
# Docs: https://core.telegram.org/bots/api/#setchatdescription
# Returns: record<ok: bool, result: bool>
export def "post-set-chat-description" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --description: string # New chat description, 0-255 characters
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setChatDescription"
    body: {content_type: "application/json", kind: json, fields: [{name: chat_id, var: chat_id}, {name: description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    chat_id: $chat_id, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to set default chat permissions for all members. The bot must be an administrator in the group or a supergroup for this to work and must have the *can\_restrict\_members* admin rights. Returns *True* on success.
#
# POST /setChatPermissions
# Docs: https://core.telegram.org/bots/api/#setchatpermissions
# Returns: record<ok: bool, result: bool>
export def "post-set-chat-permissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target supergroup (in the format `@supergroupusername`)
  permissions: record # Describes actions that a non-administrator user is allowed to take in a chat. — shape: {can_add_web_page_previews?: bool, can_change_info?: bool, can_invite_users?: bool, can_pin_messages?: bool, can_send_media_messages?: bool, can_send_messages?: bool, can_send_other_messages?: bool, can_send_polls?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setChatPermissions"
    body: {content_type: "application/json", kind: json, fields: [{name: chat_id, var: chat_id}, {name: permissions, var: permissions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    chat_id: $chat_id, permissions: $permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to set a new profile photo for the chat. Photos can't be changed for private chats. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns *True* on success.
#
# POST /setChatPhoto
# Docs: https://core.telegram.org/bots/api/#setchatphoto
# Returns: record<ok: bool, result: bool>
export def "post-set-chat-photo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  photo: any # This object represents the contents of a file to be uploaded. Must be posted using multipart/form-data in the usual way that files are uploaded via the browser.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setChatPhoto"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: chat_id, var: chat_id}, {name: photo, var: photo}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    chat_id: $chat_id, photo: $photo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to set a new group sticker set for a supergroup. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Use the field *can\_set\_sticker\_set* optionally returned in [getChat](https://core.telegram.org/bots/api/#getchat) requests to check if the bot can use this method. Returns *True* on success.
#
# POST /setChatStickerSet
# Docs: https://core.telegram.org/bots/api/#setchatstickerset
# Returns: record<ok: bool, result: bool>
export def "post-set-chat-sticker-set" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target supergroup (in the format `@supergroupusername`)
  sticker_set_name: string # Name of the sticker set to be set as the group sticker set
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setChatStickerSet"
    body: {content_type: "application/json", kind: json, fields: [{name: chat_id, var: chat_id}, {name: sticker_set_name, var: sticker_set_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    chat_id: $chat_id, sticker_set_name: $sticker_set_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to change the title of a chat. Titles can't be changed for private chats. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns *True* on success.
#
# POST /setChatTitle
# Docs: https://core.telegram.org/bots/api/#setchattitle
# Returns: record<ok: bool, result: bool>
export def "post-set-chat-title" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  title: string # New chat title, 1-255 characters
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setChatTitle"
    body: {content_type: "application/json", kind: json, fields: [{name: chat_id, var: chat_id}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    chat_id: $chat_id, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to set the score of the specified user in a game. On success, if the message was sent by the bot, returns the edited [Message](https://core.telegram.org/bots/api/#message), otherwise returns *True*. Returns an error, if the new score is not greater than the user's current score in the chat and *force* is *False*.
#
# POST /setGameScore
# Docs: https://core.telegram.org/bots/api/#setgamescore
# Returns: record<ok: bool, result: any>
export def "post-set-game-score" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --chat-id: int # Required if *inline\_message\_id* is not specified. Unique identifier for the target chat
  --disable-edit-message: oneof<nothing, bool> # Pass True, if the game message should not be automatically edited to include the current scoreboard
  --force: oneof<nothing, bool> # Pass True, if the high score is allowed to decrease. This can be useful when fixing mistakes or banning cheaters
  --inline-message-id: string # Required if *chat\_id* and *message\_id* are not specified. Identifier of the inline message
  --message-id: int # Required if *inline\_message\_id* is not specified. Identifier of the sent message
  score: int # New score, must be non-negative
  user_id: int # User identifier
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setGameScore"
    body: {content_type: "application/json", kind: json, fields: [{name: chat_id, var: chat_id}, {name: disable_edit_message, var: disable_edit_message}, {name: force, var: force}, {name: inline_message_id, var: inline_message_id}, {name: message_id, var: message_id}, {name: score, var: score}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    chat_id: $chat_id, disable_edit_message: $disable_edit_message, force: $force, inline_message_id: $inline_message_id, message_id: $message_id, score: $score, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to change the list of the bot's commands. Returns *True* on success.
#
# POST /setMyCommands
# Docs: https://core.telegram.org/bots/api/#setmycommands
# Returns: record<ok: bool, result: bool>
export def "post-set-my-commands" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  commands: list # A JSON-serialized list of bot commands to be set as the list of the bot's commands. At most 100 commands can be specified. — item shape: {command: string, description: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setMyCommands"
    body: {content_type: "application/json", kind: json, fields: [{name: commands, var: commands}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    commands: $commands
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Informs a user that some of the Telegram Passport elements they provided contains errors. The user will not be able to re-submit their Passport to you until the errors are fixed (the contents of the field for which you returned the error must change). Returns *True* on success. Use this if the data submitted by the user doesn't satisfy the standards your service requires for any reason. For example, if a birthday date seems invalid, a submitted document is blurry, a scan shows evidence of tampering, etc. Supply some details in the error message to make sure the user knows how to correct the issues.
#
# POST /setPassportDataErrors
# Docs: https://core.telegram.org/bots/api/#setpassportdataerrors
# Returns: record<ok: bool, result: bool>
export def "post-set-passport-data-errors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  errors: list # A JSON-serialized array describing the errors
  user_id: int # User identifier
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setPassportDataErrors"
    body: {content_type: "application/json", kind: json, fields: [{name: errors, var: errors}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    errors: $errors, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to move a sticker in a set created by the bot to a specific position. Returns *True* on success.
#
# POST /setStickerPositionInSet
# Docs: https://core.telegram.org/bots/api/#setstickerpositioninset
# Returns: record<ok: bool, result: bool>
export def "post-set-sticker-position-in-set" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  position: int # New sticker position in the set, zero-based
  sticker: string # File identifier of the sticker
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setStickerPositionInSet"
    body: {content_type: "application/json", kind: json, fields: [{name: position, var: position}, {name: sticker, var: sticker}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    position: $position, sticker: $sticker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to set the thumbnail of a sticker set. Animated thumbnails can be set for animated sticker sets only. Returns *True* on success.
#
# POST /setStickerSetThumb
# Docs: https://core.telegram.org/bots/api/#setstickersetthumb
# Returns: record<ok: bool, result: bool>
export def "post-set-sticker-set-thumb" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Sticker set name
  --thumb: any # A **PNG** image with the thumbnail, must be up to 128 kilobytes in size and have width and height exactly 100px, or a **TGS** animation with the thumbnail up to 32 kilobytes in size; see [](https://core.telegram.org/animated_stickers#technical-requirements)[https://core.telegram.org/animated\_stickers#technical-requirements](https://core.telegram.org/animated_stickers#technical-requirements) for animated sticker technical requirements. Pass a *file\_id* as a String to send a file that already exists on the Telegram servers, pass an HTTP URL as a String for Telegram to get a file from the Internet, or upload a new one using multipart/form-data. [More info on Sending Files »](https://core.telegram.org/bots/api/#sending-files). Animated sticker set thumbnail can't be uploaded via HTTP URL.
  user_id: int # User identifier of the sticker set owner
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setStickerSetThumb"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: name, var: name}, {name: thumb, var: thumb}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, thumb: $thumb, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to specify a url and receive incoming updates via an outgoing webhook. Whenever there is an update for the bot, we will send an HTTPS POST request to the specified url, containing a JSON-serialized [Update](https://core.telegram.org/bots/api/#update). In case of an unsuccessful request, we will give up after a reasonable amount of attempts. Returns *True* on success. If you'd like to make sure that the Webhook request comes from Telegram, we recommend using a secret path in the URL, e.g. `https://www.example.com/`. Since nobody else knows your bot's token, you can be pretty sure it's us.
#
# POST /setWebhook
# Docs: https://core.telegram.org/bots/api/#setwebhook
# Returns: record<ok: bool, result: bool>
export def "post-set-webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowed-updates: list<string> # A JSON-serialized list of the update types you want your bot to receive. For example, specify [“message”, “edited\_channel\_post”, “callback\_query”] to only receive updates of these types. See [Update](https://core.telegram.org/bots/api/#update) for a complete list of available update types. Specify an empty list to receive all updates regardless of type (default). If not specified, the previous setting will be used. Please note that this parameter doesn't affect updates created before the call to the setWebhook, so unwanted updates may be received for a short period of time.
  --certificate: any # This object represents the contents of a file to be uploaded. Must be posted using multipart/form-data in the usual way that files are uploaded via the browser.
  --drop-pending-updates: oneof<nothing, bool> # Pass *True* to drop all pending updates
  --ip-address: string # The fixed IP address which will be used to send webhook requests instead of the IP address resolved through DNS
  --max-connections: int # Maximum allowed number of simultaneous HTTPS connections to the webhook for update delivery, 1-100. Defaults to *40*. Use lower values to limit the load on your bot's server, and higher values to increase your bot's throughput. (default: 40)
  url: string # HTTPS url to send updates to. Use an empty string to remove webhook integration
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setWebhook"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: allowed_updates, var: allowed_updates}, {name: certificate, var: certificate}, {name: drop_pending_updates, var: drop_pending_updates}, {name: ip_address, var: ip_address}, {name: max_connections, var: max_connections}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allowed_updates: $allowed_updates, certificate: $certificate, drop_pending_updates: $drop_pending_updates, ip_address: $ip_address, max_connections: $max_connections, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to stop updating a live location message before *live\_period* expires. On success, if the message was sent by the bot, the sent [Message](https://core.telegram.org/bots/api/#message) is returned, otherwise *True* is returned.
#
# POST /stopMessageLiveLocation
# Docs: https://core.telegram.org/bots/api/#stopmessagelivelocation
# Returns: record<ok: bool, result: any>
export def "post-stop-message-live-location" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --chat-id: any # Required if *inline\_message\_id* is not specified. Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --inline-message-id: string # Required if *chat\_id* and *message\_id* are not specified. Identifier of the inline message
  --message-id: int # Required if *inline\_message\_id* is not specified. Identifier of the message with live location to stop
  --reply-markup: record # This object represents an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating) that appears right next to the message it belongs to. — shape: {inline_keyboard: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/stopMessageLiveLocation"
    body: {content_type: "application/json", kind: json, fields: [{name: chat_id, var: chat_id}, {name: inline_message_id, var: inline_message_id}, {name: message_id, var: message_id}, {name: reply_markup, var: reply_markup}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    chat_id: $chat_id, inline_message_id: $inline_message_id, message_id: $message_id, reply_markup: $reply_markup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to stop a poll which was sent by the bot. On success, the stopped [Poll](https://core.telegram.org/bots/api/#poll) with the final results is returned.
#
# POST /stopPoll
# Docs: https://core.telegram.org/bots/api/#stoppoll
# Returns: record<ok: bool, result: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list<record>, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list<record>, question: string, total_voter_count: int, type: string>>
export def "post-stop-poll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  message_id: int # Identifier of the original message with the poll
  --reply-markup: record # This object represents an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating) that appears right next to the message it belongs to. — shape: {inline_keyboard: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/stopPoll"
    body: {content_type: "application/json", kind: json, fields: [{name: chat_id, var: chat_id}, {name: message_id, var: message_id}, {name: reply_markup, var: reply_markup}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    chat_id: $chat_id, message_id: $message_id, reply_markup: $reply_markup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to unban a previously kicked user in a supergroup or channel. The user will **not** return to the group or channel automatically, but will be able to join via link, etc. The bot must be an administrator for this to work. By default, this method guarantees that after the call the user is not a member of the chat, but will be able to join it. So if the user is a member of the chat they will also be **removed** from the chat. If you don't want this, use the parameter *only\_if\_banned*. Returns *True* on success.
#
# POST /unbanChatMember
# Docs: https://core.telegram.org/bots/api/#unbanchatmember
# Returns: record<ok: bool, result: bool>
export def "post-unban-chat-member" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target group or username of the target supergroup or channel (in the format `@username`)
  --only-if-banned: oneof<nothing, bool> # Do nothing if the user is not banned
  user_id: int # Unique identifier of the target user
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/unbanChatMember"
    body: {content_type: "application/json", kind: json, fields: [{name: chat_id, var: chat_id}, {name: only_if_banned, var: only_if_banned}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    chat_id: $chat_id, only_if_banned: $only_if_banned, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to clear the list of pinned messages in a chat. If the chat is not a private chat, the bot must be an administrator in the chat for this to work and must have the 'can\_pin\_messages' admin right in a supergroup or 'can\_edit\_messages' admin right in a channel. Returns *True* on success.
#
# POST /unpinAllChatMessages
# Docs: https://core.telegram.org/bots/api/#unpinallchatmessages
# Returns: record<ok: bool, result: bool>
export def "post-unpin-all-chat-messages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/unpinAllChatMessages"
    body: {content_type: "application/json", kind: json, fields: [{name: chat_id, var: chat_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    chat_id: $chat_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to remove a message from the list of pinned messages in a chat. If the chat is not a private chat, the bot must be an administrator in the chat for this to work and must have the 'can\_pin\_messages' admin right in a supergroup or 'can\_edit\_messages' admin right in a channel. Returns *True* on success.
#
# POST /unpinChatMessage
# Docs: https://core.telegram.org/bots/api/#unpinchatmessage
# Returns: record<ok: bool, result: bool>
export def "post-unpin-chat-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --message-id: int # Identifier of a message to unpin. If not specified, the most recent pinned message (by sending date) will be unpinned.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/unpinChatMessage"
    body: {content_type: "application/json", kind: json, fields: [{name: chat_id, var: chat_id}, {name: message_id, var: message_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    chat_id: $chat_id, message_id: $message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to upload a .PNG file with a sticker for later use in *createNewStickerSet* and *addStickerToSet* methods (can be used multiple times). Returns the uploaded [File](https://core.telegram.org/bots/api/#file) on success.
#
# POST /uploadStickerFile
# Docs: https://core.telegram.org/bots/api/#uploadstickerfile
# Returns: record<ok: bool, result: record<file_id: string, file_path: string, file_size: int, file_unique_id: string>>
export def "post-upload-sticker-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  png_sticker: any # This object represents the contents of a file to be uploaded. Must be posted using multipart/form-data in the usual way that files are uploaded via the browser.
  user_id: int # User identifier of sticker file owner
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/uploadStickerFile"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: png_sticker, var: png_sticker}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    png_sticker: $png_sticker, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
