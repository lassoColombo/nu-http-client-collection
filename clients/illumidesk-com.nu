# Auto-generated client for IllumiDesk v1.0
# Source: https://api.apis.guru/v2/specs/illumidesk.com/1.0/swagger.json
# Auth: --token flag or $env.ILLUMIDESK_TOKEN

const CLIENT = {
  base_url: "https://api.illumidesk.com"
  token_env_var: "ILLUMIDESK_TOKEN"
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

def base-url-completer [] { ["https://api.illumidesk.com"] }
def auth-scheme-completer [] { ["bearer" "none"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/html"] }
def provider-completer [] { ["github" "google" "slack"] }
def entity-completer [] { ["billing"] }
def authorization-grant-type-completer [] { ["authorization-code" "client-credentials" "implicit" "password"] }
def client-type-completer [] { ["confidential" "public"] }
def permissions-completer [] { ["read_project" "write_project"] }
def framework-completer [] { ["tensorflow"] }
def runtime-completer [] { ["python2.7"] }
def operation-completer [] { ["start" "stop" "terminate"] }
def type-completer [] { ["projects" "servers" "users"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    auth-jwt-token-auth: "record<token: string>"
    auth-jwt-token-refresh: "record<token: string>"
    auth-jwt-token-verify: "record<token: string>"
    auth-register: "record<email: string, first_name: string, id: string, last_name: string, profile: record<avatar: string, bio: string, company: string, location: string, timezone: string, url: string>, username: string>"
    me: "record<email: string, first_name: string, id: string, last_name: string, profile: record<avatar: string, bio: string, company: string, location: string, timezone: string, url: string>, username: string>"
    servers-options-sizes-list: "table<active: bool, cpu: int, id: string, memory: int, name: string>"
    servers-options-server-size-create: "record<active: bool, cpu: int, id: string, memory: int, name: string>"
    servers-options-resources-read: "record<active: bool, cpu: int, id: string, memory: int, name: string>"
    servers-options-server-size-update: "record<active: bool, cpu: int, id: string, memory: int, name: string>"
    servers-options-server-size-replace: "record<active: bool, cpu: int, id: string, memory: int, name: string>"
    teams-list: "table<avatar: string, avatar_url: string, created_by: string, description: string, id: string, location: string, name: string, website: string>"
    teams-create: "record<avatar: string, avatar_url: string, created_by: string, description: string, id: string, location: string, name: string, website: string>"
    teams-read: "record<avatar: string, avatar_url: string, created_by: string, description: string, id: string, location: string, name: string, website: string>"
    teams-update: "record<avatar: string, avatar_url: string, created_by: string, description: string, id: string, location: string, name: string, website: string>"
    teams-replace: "record<avatar: string, avatar_url: string, created_by: string, description: string, id: string, location: string, name: string, website: string>"
    teams-billing-invoices-list: "table<amount_due: int, application_fee: int, attempt_count: int, attempted: bool, closed: bool, created: string, currency: string, customer: string, description: string, id: string, invoice_date: string, livemode: bool, metadata: record, next_payment_attempt: string, paid: bool, period_end: string, period_start: string, reciept_number: string, starting_balance: int, statement_descriptor: string, stripe_id: string, subscription: string, subtotal: int, tax: int, total: int>"
    teams-billing-invoices-read: "record<amount_due: int, application_fee: int, attempt_count: int, attempted: bool, closed: bool, created: string, currency: string, customer: string, description: string, id: string, invoice_date: string, livemode: bool, metadata: record, next_payment_attempt: string, paid: bool, period_end: string, period_start: string, reciept_number: string, starting_balance: int, statement_descriptor: string, stripe_id: string, subscription: string, subtotal: int, tax: int, total: int>"
    teams-billing-invoice-items-list: "table<amount: int, created: string, currency: string, description: string, id: string, invoice: string, invoice_date: string, livemode: bool, metadata: record, proration: bool, quantity: int, stripe_id: string>"
    teams-billing-invoice-items-read: "record<amount: int, created: string, currency: string, description: string, id: string, invoice: string, invoice_date: string, livemode: bool, metadata: record, proration: bool, quantity: int, stripe_id: string>"
    teams-billing-subscriptions-list: "table<application_fee_percent: float, cancel_at_period_end: bool, canceled_at: string, created: string, current_period_end: string, current_period_start: string, ended_at: string, id: string, livemode: bool, plan: string, quantity: int, start: string, status: string, stripe_id: string, trial_end: string, trial_start: string>"
    teams-billing-subscriptions-create: "record<application_fee_percent: float, cancel_at_period_end: bool, canceled_at: string, created: string, current_period_end: string, current_period_start: string, ended_at: string, id: string, livemode: bool, plan: string, quantity: int, start: string, status: string, stripe_id: string, trial_end: string, trial_start: string>"
    teams-billing-subscriptions-read: "record<application_fee_percent: float, cancel_at_period_end: bool, canceled_at: string, created: string, current_period_end: string, current_period_start: string, ended_at: string, id: string, livemode: bool, plan: string, quantity: int, start: string, status: string, stripe_id: string, trial_end: string, trial_start: string>"
    teams-groups-list: "table<created_by: string, description: string, id: string, members: list<string>, name: string, parent: string, permissions: list<string>, private: bool>"
    teams-groups-read: "record<created_by: string, description: string, id: string, members: list<string>, name: string, parent: string, permissions: list<string>, private: bool>"
    teams-groups-update: "record<created_by: string, description: string, id: string, members: list<string>, name: string, parent: string, permissions: list<string>, private: bool>"
    teams-groups-replace: "record<created_by: string, description: string, id: string, members: list<string>, name: string, parent: string, permissions: list<string>, private: bool>"
    teams-groups-add-to-group: "record<user: string>"
    users-list: "table<email: string, first_name: string, id: string, last_name: string, profile: record<avatar: string, bio: string, company: string, location: string, timezone: string, url: string>, username: string>"
    users-create: "record<email: string, first_name: string, id: string, last_name: string, profile: record<avatar: string, bio: string, company: string, location: string, timezone: string, url: string>, username: string>"
    users-read: "record<email: string, first_name: string, id: string, last_name: string, profile: record<avatar: string, bio: string, company: string, location: string, timezone: string, url: string>, username: string>"
    users-update: "record<email: string, first_name: string, id: string, last_name: string, profile: record<avatar: string, bio: string, company: string, location: string, timezone: string, url: string>, username: string>"
    user-avatar-update: "record<email: string, first_name: string, id: string, last_name: string, profile: record<avatar: string, bio: string, company: string, location: string, timezone: string, url: string>, username: string>"
    user-avatar-set: "record<email: string, first_name: string, id: string, last_name: string, profile: record<avatar: string, bio: string, company: string, location: string, timezone: string, url: string>, username: string>"
    users-emails-list: "table<address: string, id: string, public: bool, unsubscribed: bool, user: string>"
    users-emails-create: "record<address: string, id: string, public: bool, unsubscribed: bool, user: string>"
    users-emails-read: "record<address: string, id: string, public: bool, unsubscribed: bool, user: string>"
    users-emails-update: "record<address: string, id: string, public: bool, unsubscribed: bool, user: string>"
    users-emails-replace: "record<address: string, id: string, public: bool, unsubscribed: bool, user: string>"
    billing-cards-list: "table<address_city: string, address_country: string, address_line1: string, address_line1_check: string, address_line2: string, address_state: string, address_zip: string, address_zip_check: string, brand: string, created: string, customer: string, cvc_check: string, exp_month: int, exp_year: int, fingerprint: string, funding: string, id: string, last4: string, name: string, stripe_id: string, token: string>"
    billing-cards-create: "record<address_city: string, address_country: string, address_line1: string, address_line1_check: string, address_line2: string, address_state: string, address_zip: string, address_zip_check: string, brand: string, created: string, customer: string, cvc_check: string, exp_month: int, exp_year: int, fingerprint: string, funding: string, id: string, last4: string, name: string, stripe_id: string, token: string>"
    billing-cards-read: "record<address_city: string, address_country: string, address_line1: string, address_line1_check: string, address_line2: string, address_state: string, address_zip: string, address_zip_check: string, brand: string, created: string, customer: string, cvc_check: string, exp_month: int, exp_year: int, fingerprint: string, funding: string, id: string, last4: string, name: string, stripe_id: string, token: string>"
    billing-cards-update: "record<address_city: string, address_country: string, address_line1: string, address_line1_check: string, address_line2: string, address_state: string, address_zip: string, address_zip_check: string, brand: string, created: string, customer: string, cvc_check: string, exp_month: int, exp_year: int, fingerprint: string, funding: string, id: string, last4: string, name: string, stripe_id: string, token: string>"
    billing-cards-replace: "record<address_city: string, address_country: string, address_line1: string, address_line1_check: string, address_line2: string, address_state: string, address_zip: string, address_zip_check: string, brand: string, created: string, customer: string, cvc_check: string, exp_month: int, exp_year: int, fingerprint: string, funding: string, id: string, last4: string, name: string, stripe_id: string, token: string>"
    billing-invoices-list: "table<amount_due: int, application_fee: int, attempt_count: int, attempted: bool, closed: bool, created: string, currency: string, customer: string, description: string, id: string, invoice_date: string, livemode: bool, metadata: record, next_payment_attempt: string, paid: bool, period_end: string, period_start: string, reciept_number: string, starting_balance: int, statement_descriptor: string, stripe_id: string, subscription: string, subtotal: int, tax: int, total: int>"
    billing-invoices-read: "record<amount_due: int, application_fee: int, attempt_count: int, attempted: bool, closed: bool, created: string, currency: string, customer: string, description: string, id: string, invoice_date: string, livemode: bool, metadata: record, next_payment_attempt: string, paid: bool, period_end: string, period_start: string, reciept_number: string, starting_balance: int, statement_descriptor: string, stripe_id: string, subscription: string, subtotal: int, tax: int, total: int>"
    billing-invoice-items-list: "table<amount: int, created: string, currency: string, description: string, id: string, invoice: string, invoice_date: string, livemode: bool, metadata: record, proration: bool, quantity: int, stripe_id: string>"
    billing-invoice-items-read: "record<amount: int, created: string, currency: string, description: string, id: string, invoice: string, invoice_date: string, livemode: bool, metadata: record, proration: bool, quantity: int, stripe_id: string>"
    billing-plans-list: "table<amount: int, created: string, currency: string, id: string, interval: string, interval_count: int, livemode: bool, metadata: record, name: string, statement_descriptor: string, stripe_id: string, trial_period_days: int>"
    billing-plans-read: "record<amount: int, created: string, currency: string, id: string, interval: string, interval_count: int, livemode: bool, metadata: record, name: string, statement_descriptor: string, stripe_id: string, trial_period_days: int>"
    billing-subscriptions-list: "table<application_fee_percent: float, cancel_at_period_end: bool, canceled_at: string, created: string, current_period_end: string, current_period_start: string, ended_at: string, id: string, livemode: bool, plan: string, quantity: int, start: string, status: string, stripe_id: string, trial_end: string, trial_start: string>"
    billing-subscriptions-create: "record<application_fee_percent: float, cancel_at_period_end: bool, canceled_at: string, created: string, current_period_end: string, current_period_start: string, ended_at: string, id: string, livemode: bool, plan: string, quantity: int, start: string, status: string, stripe_id: string, trial_end: string, trial_start: string>"
    billing-subscriptions-read: "record<application_fee_percent: float, cancel_at_period_end: bool, canceled_at: string, created: string, current_period_end: string, current_period_start: string, ended_at: string, id: string, livemode: bool, plan: string, quantity: int, start: string, status: string, stripe_id: string, trial_end: string, trial_start: string>"
    notifications-list: "table<actor: string, id: string, read: bool, target: string, timestamp: string, type: string, user: string>"
    notifications-update-list: "record<actor: string, id: string, read: bool, target: string, timestamp: string, type: string, user: string>"
    notifications-list-entity: "table<actor: string, id: string, read: bool, target: string, timestamp: string, type: string, user: string>"
    notifications-update-entity-list: "record<actor: string, id: string, read: bool, target: string, timestamp: string, type: string, user: string>"
    notification-settings-read: "table<email_address: string, emails_enabled: bool, enabled: bool, entity: string, id: string, user: string>"
    notification-settings-update: "record<email_address: string, emails_enabled: bool, enabled: bool, entity: string, id: string, user: string>"
    notification-settings-create: "record<email_address: string, emails_enabled: bool, enabled: bool, entity: string, id: string, user: string>"
    notification-settings-entity-read: "table<email_address: string, emails_enabled: bool, enabled: bool, entity: string, id: string, user: string>"
    notification-settings-entity-update: "record<email_address: string, emails_enabled: bool, enabled: bool, entity: string, id: string, user: string>"
    notification-settings-entity-create: "record<email_address: string, emails_enabled: bool, enabled: bool, entity: string, id: string, user: string>"
    notification-read: "record<actor: string, id: string, read: bool, target: string, timestamp: string, type: string, user: string>"
    notification-update: "record<actor: string, id: string, read: bool, target: string, timestamp: string, type: string, user: string>"
    oauth-applications-list: "table<authorization_grant_type: string, client_id: string, client_secret: string, client_type: string, id: string, name: string, redirect_uris: string>"
    oauth-application-create: "record<authorization_grant_type: string, client_id: string, client_secret: string, client_type: string, id: string, name: string, redirect_uris: string>"
    oauth-application-read: "record<authorization_grant_type: string, client_id: string, client_secret: string, client_type: string, id: string, name: string, redirect_uris: string>"
    oauth-application-update: "record<authorization_grant_type: string, client_id: string, client_secret: string, client_type: string, id: string, name: string, redirect_uris: string>"
    oauth-application-replace: "record<authorization_grant_type: string, client_id: string, client_secret: string, client_type: string, id: string, name: string, redirect_uris: string>"
    projects-list: "table<collaborators: list<string>, description: string, id: string, last_updated: string, name: string, owner: string, private: bool, team: string>"
    projects-create: "record<collaborators: list<string>, description: string, id: string, last_updated: string, name: string, owner: string, private: bool, team: string>"
    project-copy-check: "record"
    project-copy: "record<collaborators: list<string>, description: string, id: string, last_updated: string, name: string, owner: string, private: bool, team: string>"
    projects-read: "record<collaborators: list<string>, description: string, id: string, last_updated: string, name: string, owner: string, private: bool, team: string>"
    projects-update: "record<collaborators: list<string>, description: string, id: string, last_updated: string, name: string, owner: string, private: bool, team: string>"
    projects-replace: "record<collaborators: list<string>, description: string, id: string, last_updated: string, name: string, owner: string, private: bool, team: string>"
    projects-collaborators-list: "table<email: string, first_name: string, id: string, joined: string, last_name: string, owner: bool, permissions: list<string>, project: string, user: string, username: string>"
    projects-collaborators-create: "record<email: string, first_name: string, id: string, joined: string, last_name: string, owner: bool, permissions: list<string>, project: string, user: string, username: string>"
    projects-collaborators-read: "record<email: string, first_name: string, id: string, joined: string, last_name: string, owner: bool, permissions: list<string>, project: string, user: string, username: string>"
    projects-collaborators-update: "record<email: string, first_name: string, id: string, joined: string, last_name: string, owner: bool, permissions: list<string>, project: string, user: string, username: string>"
    projects-deployments-list: "table<config: record<files: list, handler: string>, created_at: string, created_by: string, framework: string, id: string, name: string, project: string, runtime: string>"
    projects-deployments-create: "record<config: record<files: list<string>, handler: string>, created_at: string, created_by: string, framework: string, id: string, name: string, project: string, runtime: string>"
    projects-deployments-read: "record<config: record<files: list<string>, handler: string>, created_at: string, created_by: string, framework: string, id: string, name: string, project: string, runtime: string>"
    projects-deployments-update: "record<config: record<files: list<string>, handler: string>, created_at: string, created_by: string, framework: string, id: string, name: string, project: string, runtime: string>"
    projects-deployments-replace: "record<config: record<files: list<string>, handler: string>, created_at: string, created_by: string, framework: string, id: string, name: string, project: string, runtime: string>"
    projects-project-files-list: "table<content: string, id: string, name: string, path: string, project: string>"
    projects-project-files-create: "record<content: string, id: string, name: string, path: string, project: string>"
    projects-project-files-read: "record<content: string, id: string, name: string, path: string, project: string>"
    projects-project-files-update: "record<content: string, id: string, name: string, path: string, project: string>"
    projects-project-files-replace: "record<content: string, id: string, name: string, path: string, project: string>"
    projects-servers-list: "table<config: record, connected: list<string>, created_at: string, created_by: string, endpoint: string, host: string, id: string, image_name: string, logs_url: string, name: string, project: string, server_size: string, startup_script: string, status: string, status_url: string>"
    projects-servers-create: "record<config: record, connected: list<string>, created_at: string, created_by: string, endpoint: string, host: string, id: string, image_name: string, logs_url: string, name: string, project: string, server_size: string, startup_script: string, status: string, status_url: string>"
    projects-servers-statuses: "table<id: string, status: string>"
    projects-servers-read: "record<config: record, connected: list<string>, created_at: string, created_by: string, endpoint: string, host: string, id: string, image_name: string, logs_url: string, name: string, project: string, server_size: string, startup_script: string, status: string, status_url: string>"
    projects-servers-update: "record<config: record, connected: list<string>, created_at: string, created_by: string, endpoint: string, host: string, id: string, image_name: string, logs_url: string, name: string, project: string, server_size: string, startup_script: string, status: string, status_url: string>"
    projects-servers-replace: "record<config: record, connected: list<string>, created_at: string, created_by: string, endpoint: string, host: string, id: string, image_name: string, logs_url: string, name: string, project: string, server_size: string, startup_script: string, status: string, status_url: string>"
    projects-servers-api-key: "record<token: string>"
    projects-servers-run-stats-create: "record<exit_code: int, id: string, server: string, size: int, stacktrace: string, start: string, stop: string>"
    projects-servers-run-stats-read: "record<exit_code: int, id: string, server: string, size: int, stacktrace: string, start: string, stop: string>"
    projects-servers-run-stats-update: "record<exit_code: int, id: string, server: string, size: int, stacktrace: string, start: string, stop: string>"
    projects-servers-run-stats-replace: "record<exit_code: int, id: string, server: string, size: int, stacktrace: string, start: string, stop: string>"
    projects-servers-ssh-tunnels-list: "table<endpoint: string, host: string, id: string, local_port: int, name: string, remote_port: int, server: string, username: string>"
    projects-servers-ssh-tunnels-create: "record<endpoint: string, host: string, id: string, local_port: int, name: string, remote_port: int, server: string, username: string>"
    projects-servers-ssh-tunnels-read: "record<endpoint: string, host: string, id: string, local_port: int, name: string, remote_port: int, server: string, username: string>"
    projects-servers-ssh-tunnels-update: "record<endpoint: string, host: string, id: string, local_port: int, name: string, remote_port: int, server: string, username: string>"
    projects-servers-ssh-tunnels-replace: "record<endpoint: string, host: string, id: string, local_port: int, name: string, remote_port: int, server: string, username: string>"
    projects-servers-stats-read: "record<id: string, server: string, size: int, start: string, stop: string>"
    projects-servers-stats-update: "record<id: string, server: string, size: int, start: string, stop: string>"
    projects-servers-stats-replace: "record<id: string, server: string, size: int, start: string, stop: string>"
    service-trigger-list: "table<id: string, name: string, operation: string, webhook: record<payload: record, url: string>>"
    service-trigger-create: "record<id: string, name: string, operation: string, webhook: record<payload: record, url: string>>"
    service-trigger-read: "record<id: string, name: string, operation: string, webhook: record<payload: record, url: string>>"
    service-trigger-update: "record<id: string, name: string, operation: string, webhook: record<payload: record, url: string>>"
    service-trigger-replace: "record<id: string, name: string, operation: string, webhook: record<payload: record, url: string>>"
    search: "list<record>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["auth-jwt-token-auth" "auth-jwt-token-refresh" "auth-jwt-token-verify" "oauth-login" "auth-register" "me" "servers-options-sizes-list" "servers-options-server-size-create" "servers-options-server-size-delete" "servers-options-resources-read" "servers-options-server-size-update" "servers-options-server-size-replace" "teams-list" "teams-create" "teams-delete" "teams-read" "teams-update" "teams-replace" "teams-billing-invoices-list" "teams-billing-invoices-read" "teams-billing-invoice-items-list" "teams-billing-invoice-items-read" "teams-billing-subscriptions-list" "teams-billing-subscriptions-create" "teams-billing-subscriptions-delete" "teams-billing-subscriptions-read" "teams-groups-list" "teams-groups-delete" "teams-groups-read" "teams-groups-update" "teams-groups-replace" "teams-groups-add-to-group" "teams-groups-remove-from-group" "users-list" "users-create" "users-delete" "users-read" "users-update" "users-api-key-list" "user-avatar-delete" "user-avatar-get" "user-avatar-update" "user-avatar-set" "users-emails-list" "users-emails-create" "users-emails-delete" "users-emails-read" "users-emails-update" "users-emails-replace" "users-ssh-key-list" "users-ssh-key-reset" "billing-cards-list" "billing-cards-create" "billing-cards-delete" "billing-cards-read" "billing-cards-update" "billing-cards-replace" "billing-invoices-list" "billing-invoices-read" "billing-invoice-items-list" "billing-invoice-items-read" "billing-plans-list" "billing-plans-read" "billing-subscriptions-list" "billing-subscriptions-create" "billing-subscriptions-delete" "billing-subscriptions-read" "notifications-list" "notifications-update-list" "notifications-list-entity" "notifications-update-entity-list" "notification-settings-read" "notification-settings-update" "notification-settings-create" "notification-settings-entity-read" "notification-settings-entity-update" "notification-settings-entity-create" "notification-read" "notification-update" "oauth-applications-list" "oauth-application-create" "oauth-application-delete" "oauth-application-read" "oauth-application-update" "oauth-application-replace" "projects-list" "projects-create" "project-copy-check" "project-copy" "projects-delete" "projects-read" "projects-update" "projects-replace" "projects-collaborators-list" "projects-collaborators-create" "projects-collaborators-delete" "projects-collaborators-read" "projects-collaborators-update" "projects-deployments-list" "projects-deployments-create" "projects-deployment-delete" "projects-deployments-read" "projects-deployments-update" "projects-deployments-replace" "projects-deployments-deploy" "projects-project-files-list" "projects-project-files-create" "projects-project-files-delete" "projects-project-files-read" "projects-project-files-update" "projects-project-files-replace" "projects-servers-list" "projects-servers-create" "projects-servers-statuses" "projects-servers-delete" "projects-servers-read" "projects-servers-update" "projects-servers-replace" "projects-servers-api-key" "projects-servers-auth" "projects-servers-run-stats-create" "projects-servers-run-stats-delete" "projects-servers-run-stats-read" "projects-servers-run-stats-update" "projects-servers-run-stats-replace" "projects-servers-ssh-tunnels-list" "projects-servers-ssh-tunnels-create" "projects-servers-ssh-tunnels-delete" "projects-servers-ssh-tunnels-read" "projects-servers-ssh-tunnels-update" "projects-servers-ssh-tunnels-replace" "projects-servers-start" "projects-servers-stats-delete" "projects-servers-stats-read" "projects-servers-stats-update" "projects-servers-stats-replace" "projects-servers-stop" "service-trigger-list" "service-trigger-create" "service-trigger-delete" "service-trigger-read" "service-trigger-update" "service-trigger-replace" "search" "commands"] | sort) } | get name | first)
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

# Create JSON Web Token (JWT)
#
# POST /auth/jwt-token-auth/
# Returns: record<token: string>
# operationId: auth_jwt-token-auth
export def "auth-jwt-token-auth" [
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
  password: string # User password.
  username: string # User name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth/jwt-token-auth/"
    body: {content_type: "application/json", kind: json, fields: [{name: password, var: password}, {name: username, var: username}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: none
  } {
    password: $password, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Refresh a JSON Web Token (JWT)
#
# POST /auth/jwt-token-refresh/
# Returns: record<token: string>
# operationId: auth_jwt-token-refresh
export def "auth-jwt-token-refresh" [
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
  --body-token: string # Refreshed token. (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth/jwt-token-refresh/"
    body: {content_type: "application/json", kind: json, fields: [{name: token, var: body_token, required: true}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: none
  } {
    body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Validate JSON Web Token (JWT)
#
# POST /auth/jwt-token-verify/
# Returns: record<token: string>
# operationId: auth_jwt-token-verify
export def "auth-jwt-token-verify" [
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
  --body-token: string # JSON Web Token (JWT). (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth/jwt-token-verify/"
    body: {content_type: "application/json", kind: json, fields: [{name: token, var: body_token, required: true}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: none
  } {
    body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /auth/login/{provider}/
#
# operationId: oauth_login
export def "oauth-login" [
  provider: string@provider-completer
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
]: nothing -> any {
  http-request {
    method: get
    path: "/auth/login/{provider}/"
    path_params: [{name: provider, var: provider}]
    accept: ["application/json", "text/html"]
    ok: [302]
    auth: bearer
  } {
    provider: $provider
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Register a user
#
# POST /auth/register/
# Returns: record<email: string, first_name: string, id: string, last_name: string, profile: record<avatar: string, bio: string, company: string, location: string, timezone: string, url: string>, username: string>
# operationId: auth_register
export def "auth-register" [
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
  --email: string # User email.
  --first-name: string # User first name.
  --last-name: string # User last name.
  password: string # User password.
  profile: record # shape: {avatar?: string, bio?: string, company?: string, location?: string, timezone?: string, url?: string}
  username: string # Required. 150 characters or fewer. Letters, digits and @/./+/-/_ only.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth/register/"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: password, var: password}, {name: profile, var: profile}, {name: username, var: username}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: none
  } {
    email: $email, first_name: $first_name, last_name: $last_name, password: $password, profile: $profile, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# A convenience endpoint that is equivalent to GET /v1/users/profiles//
#
# GET /v1/me
# Returns: record<email: string, first_name: string, id: string, last_name: string, profile: record<avatar: string, bio: string, company: string, location: string, timezone: string, url: string>, username: string>
# operationId: me
export def "me" [
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
    path: "/v1/me"
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve available server sizes
#
# GET /v1/servers/options/server-size/
# Returns: table<active: bool, cpu: int, id: string, memory: int, name: string>
# operationId: servers_options_sizes_list
export def "servers-options-sizes-list" [
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
  --limit: string # Set limit when retrieving items.
  --offset: string # Offset when retrieving items.
  --ordering: string # Set order when retrieving items.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/servers/options/server-size/"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: ordering, var: ordering}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, ordering: $ordering
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new server size item
#
# POST /v1/servers/options/server-size/
# Returns: record<active: bool, cpu: int, id: string, memory: int, name: string>
# operationId: servers_options_server_size_create
export def "servers-options-server-size-create" [
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
  --active: oneof<nothing, bool> # Active or not active.
  cpu: int # CPU set for server size.
  memory: int # Memory set for server size.
  name: string # Server size name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/servers/options/server-size/"
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active, required: true}, {name: cpu, var: cpu}, {name: memory, var: memory}, {name: name, var: name}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: bearer
  } {
    active: $active, cpu: $cpu, memory: $memory, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a server size by id
#
# DELETE /v1/servers/options/server-size/{size}/
# operationId: servers_options_server_size_delete
export def "servers-options-server-size-delete" [
  size: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/servers/options/server-size/{size}/"
    path_params: [{name: size, var: size}]
    accept: ["application/json", "text/html"]
    ok: [204]
    auth: bearer
  } {
    size: $size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a server size by id
#
# GET /v1/servers/options/server-size/{size}/
# Returns: record<active: bool, cpu: int, id: string, memory: int, name: string>
# operationId: servers_options_resources_read
export def "servers-options-resources-read" [
  size: string
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
    path: "/v1/servers/options/server-size/{size}/"
    path_params: [{name: size, var: size}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    size: $size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a server size by id
#
# PATCH /v1/servers/options/server-size/{size}/
# Returns: record<active: bool, cpu: int, id: string, memory: int, name: string>
# operationId: servers_options_server_size_update
export def "servers-options-server-size-update" [
  size: string
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
  --active: oneof<nothing, bool> # Active or not active.
  cpu: int # CPU set for server size.
  memory: int # Memory set for server size.
  name: string # Server size name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/servers/options/server-size/{size}/"
    path_params: [{name: size, var: size}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active, required: true}, {name: cpu, var: cpu}, {name: memory, var: memory}, {name: name, var: name}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    size: $size, active: $active, cpu: $cpu, memory: $memory, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replace a server size by id
#
# PUT /v1/servers/options/server-size/{size}/
# Returns: record<active: bool, cpu: int, id: string, memory: int, name: string>
# operationId: servers_options_server_size_replace
export def "servers-options-server-size-replace" [
  size: string
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
  --active: oneof<nothing, bool> # Active or not active.
  cpu: int # CPU set for server size.
  memory: int # Memory set for server size.
  name: string # Server size name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/servers/options/server-size/{size}/"
    path_params: [{name: size, var: size}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active, required: true}, {name: cpu, var: cpu}, {name: memory, var: memory}, {name: name, var: name}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    size: $size, active: $active, cpu: $cpu, memory: $memory, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get teams
#
# GET /v1/teams/
# Returns: table<avatar: string, avatar_url: string, created_by: string, description: string, id: string, location: string, name: string, website: string>
# operationId: teams_list
export def "teams-list" [
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
  --limit: string # Limit when getting data.
  --offset: string # Offset when getting data.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/teams/"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new team
#
# POST /v1/teams/
# Returns: record<avatar: string, avatar_url: string, created_by: string, description: string, id: string, location: string, name: string, website: string>
# operationId: teams_create
export def "teams-create" [
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
  --avatar: string # Team avatar image. (format: byte)
  --avatar-url: string # Team avatar url.
  --description: string # Team description
  --location: string # Team location.
  name: string # Team name
  --website: string # Teams website.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/teams/"
    body: {content_type: "application/json", kind: json, fields: [{name: avatar, var: avatar}, {name: avatar_url, var: avatar_url}, {name: description, var: description}, {name: location, var: location}, {name: name, var: name}, {name: website, var: website}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: bearer
  } {
    avatar: $avatar, avatar_url: $avatar_url, description: $description, location: $location, name: $name, website: $website
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a team
#
# DELETE /v1/teams/{team}/
# operationId: teams_delete
export def "teams-delete" [
  team: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/teams/{team}/"
    path_params: [{name: team, var: team}]
    accept: ["application/json", "text/html"]
    ok: [204]
    auth: bearer
  } {
    team: $team
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a team
#
# GET /v1/teams/{team}/
# Returns: record<avatar: string, avatar_url: string, created_by: string, description: string, id: string, location: string, name: string, website: string>
# operationId: teams_read
export def "teams-read" [
  team: string
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
    path: "/v1/teams/{team}/"
    path_params: [{name: team, var: team}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    team: $team
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a team
#
# PATCH /v1/teams/{team}/
# Returns: record<avatar: string, avatar_url: string, created_by: string, description: string, id: string, location: string, name: string, website: string>
# operationId: teams_update
export def "teams-update" [
  team: string
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
  --avatar: string # Team avatar image. (format: byte)
  --avatar-url: string # Team avatar url.
  --description: string # Team description
  --location: string # Team location.
  name: string # Team name
  --website: string # Teams website.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/teams/{team}/"
    path_params: [{name: team, var: team}]
    body: {content_type: "application/json", kind: json, fields: [{name: avatar, var: avatar}, {name: avatar_url, var: avatar_url}, {name: description, var: description}, {name: location, var: location}, {name: name, var: name}, {name: website, var: website}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    team: $team, avatar: $avatar, avatar_url: $avatar_url, description: $description, location: $location, name: $name, website: $website
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replace a team
#
# PUT /v1/teams/{team}/
# Returns: record<avatar: string, avatar_url: string, created_by: string, description: string, id: string, location: string, name: string, website: string>
# operationId: teams_replace
export def "teams-replace" [
  team: string
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
  --avatar: string # Team avatar image. (format: byte)
  --avatar-url: string # Team avatar url.
  --description: string # Team description
  --location: string # Team location.
  name: string # Team name
  --website: string # Teams website.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/teams/{team}/"
    path_params: [{name: team, var: team}]
    body: {content_type: "application/json", kind: json, fields: [{name: avatar, var: avatar}, {name: avatar_url, var: avatar_url}, {name: description, var: description}, {name: location, var: location}, {name: name, var: name}, {name: website, var: website}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    team: $team, avatar: $avatar, avatar_url: $avatar_url, description: $description, location: $location, name: $name, website: $website
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get team invoices
#
# GET /v1/teams/{team}/billing/invoices/
# Returns: table<amount_due: int, application_fee: int, attempt_count: int, attempted: bool, closed: bool, created: string, currency: string, customer: string, description: string, id: string, invoice_date: string, livemode: bool, metadata: record, next_payment_attempt: string, paid: bool, period_end: string, period_start: string, reciept_number: string, starting_balance: int, statement_descriptor: string, stripe_id: string, subscription: string, subtotal: int, tax: int, total: int>
# operationId: teams_billing_invoices_list
export def "teams-billing-invoices-list" [
  team: string
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
  --limit: string # Limit when getting items.
  --offset: string # Offset when getting items.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/teams/{team}/billing/invoices/"
    path_params: [{name: team, var: team}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    team: $team, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get an invoice
#
# GET /v1/teams/{team}/billing/invoices/{id}/
# Returns: record<amount_due: int, application_fee: int, attempt_count: int, attempted: bool, closed: bool, created: string, currency: string, customer: string, description: string, id: string, invoice_date: string, livemode: bool, metadata: record, next_payment_attempt: string, paid: bool, period_end: string, period_start: string, reciept_number: string, starting_balance: int, statement_descriptor: string, stripe_id: string, subscription: string, subtotal: int, tax: int, total: int>
# operationId: teams_billing_invoices_read
export def "teams-billing-invoices-read" [
  team: string
  id: string
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
    path: "/v1/teams/{team}/billing/invoices/{id}/"
    path_params: [{name: team, var: team}, {name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    team: $team, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get team invoice items for a given invoice.
#
# GET /v1/teams/{team}/billing/invoices/{invoice_id}/invoice-items/
# Returns: table<amount: int, created: string, currency: string, description: string, id: string, invoice: string, invoice_date: string, livemode: bool, metadata: record, proration: bool, quantity: int, stripe_id: string>
# operationId: teams_billing_invoice_items_list
export def "teams-billing-invoice-items-list" [
  team: string
  invoice_id: string
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
  --limit: string # Limit when getting items.
  --offset: string # Offset when getting items.
  --ordering: string # Ordering when getting items.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/teams/{team}/billing/invoices/{invoice_id}/invoice-items/"
    path_params: [{name: team, var: team}, {name: invoice_id, var: invoice_id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: ordering, var: ordering}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    team: $team, invoice_id: $invoice_id, limit: $limit, offset: $offset, ordering: $ordering
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a specific team InvoiceItem.
#
# GET /v1/teams/{team}/billing/invoices/{invoice_id}/invoice-items/{id}
# Returns: record<amount: int, created: string, currency: string, description: string, id: string, invoice: string, invoice_date: string, livemode: bool, metadata: record, proration: bool, quantity: int, stripe_id: string>
# operationId: teams_billing_invoice_items_read
export def "teams-billing-invoice-items-read" [
  team: string
  invoice_id: string
  id: string
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
    path: "/v1/teams/{team}/billing/invoices/{invoice_id}/invoice-items/{id}"
    path_params: [{name: team, var: team}, {name: invoice_id, var: invoice_id}, {name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    team: $team, invoice_id: $invoice_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get active team subscriptons
#
# GET /v1/teams/{team}/billing/subscriptions/
# Returns: table<application_fee_percent: float, cancel_at_period_end: bool, canceled_at: string, created: string, current_period_end: string, current_period_start: string, ended_at: string, id: string, livemode: bool, plan: string, quantity: int, start: string, status: string, stripe_id: string, trial_end: string, trial_start: string>
# operationId: teams_billing_subscriptions_list
export def "teams-billing-subscriptions-list" [
  team: string
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
  --limit: string # Limit when getting items.
  --offset: string # Offset when getting items.
  --ordering: string # Ordering when getting items.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/teams/{team}/billing/subscriptions/"
    path_params: [{name: team, var: team}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: ordering, var: ordering}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    team: $team, limit: $limit, offset: $offset, ordering: $ordering
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new team subscription
#
# POST /v1/teams/{team}/billing/subscriptions/
# Returns: record<application_fee_percent: float, cancel_at_period_end: bool, canceled_at: string, created: string, current_period_end: string, current_period_start: string, ended_at: string, id: string, livemode: bool, plan: string, quantity: int, start: string, status: string, stripe_id: string, trial_end: string, trial_start: string>
# operationId: teams_billing_subscriptions_create
export def "teams-billing-subscriptions-create" [
  team: string
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
  plan: string # Plan unique identifier.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/teams/{team}/billing/subscriptions/"
    path_params: [{name: team, var: team}]
    body: {content_type: "application/json", kind: json, fields: [{name: plan, var: plan}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: bearer
  } {
    team: $team, plan: $plan
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a subscription
#
# DELETE /v1/teams/{team}/billing/subscriptions/{id}/
# operationId: teams_billing_subscriptions_delete
export def "teams-billing-subscriptions-delete" [
  team: string
  id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/teams/{team}/billing/subscriptions/{id}/"
    path_params: [{name: team, var: team}, {name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [204]
    auth: bearer
  } {
    team: $team, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get team subscriptions
#
# GET /v1/teams/{team}/billing/subscriptions/{id}/
# Returns: record<application_fee_percent: float, cancel_at_period_end: bool, canceled_at: string, created: string, current_period_end: string, current_period_start: string, ended_at: string, id: string, livemode: bool, plan: string, quantity: int, start: string, status: string, stripe_id: string, trial_end: string, trial_start: string>
# operationId: teams_billing_subscriptions_read
export def "teams-billing-subscriptions-read" [
  team: string
  id: string
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
    path: "/v1/teams/{team}/billing/subscriptions/{id}/"
    path_params: [{name: team, var: team}, {name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    team: $team, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get team groups
#
# GET /v1/teams/{team}/groups/
# Returns: table<created_by: string, description: string, id: string, members: list<string>, name: string, parent: string, permissions: list<string>, private: bool>
# operationId: teams_groups_list
export def "teams-groups-list" [
  team: string
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
  --limit: string # Limit when getting data.
  --offset: string # Offset when getting data.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/teams/{team}/groups/"
    path_params: [{name: team, var: team}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    team: $team, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete team group
#
# DELETE /v1/teams/{team}/groups/{group}/
# operationId: teams_groups_delete
export def "teams-groups-delete" [
  team: string
  group: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/teams/{team}/groups/{group}/"
    path_params: [{name: team, var: team}, {name: group, var: group}]
    accept: ["application/json", "text/html"]
    ok: [204]
    auth: bearer
  } {
    team: $team, group: $group
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get team group
#
# GET /v1/teams/{team}/groups/{group}/
# Returns: record<created_by: string, description: string, id: string, members: list<string>, name: string, parent: string, permissions: list<string>, private: bool>
# operationId: teams_groups_read
export def "teams-groups-read" [
  team: string
  group: string
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
    path: "/v1/teams/{team}/groups/{group}/"
    path_params: [{name: team, var: team}, {name: group, var: group}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    team: $team, group: $group
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Patch team group
#
# PATCH /v1/teams/{team}/groups/{group}/
# Returns: record<created_by: string, description: string, id: string, members: list<string>, name: string, parent: string, permissions: list<string>, private: bool>
# operationId: teams_groups_update
export def "teams-groups-update" [
  team: string
  group: string
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
  --description: string # Group description
  name: string # Group name
  --parent: string # Parent group
  --private: oneof<nothing, bool> # States whether group is visible to all users.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/teams/{team}/groups/{group}/"
    path_params: [{name: team, var: team}, {name: group, var: group}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: parent, var: parent}, {name: private, var: private}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    team: $team, group: $group, description: $description, name: $name, parent: $parent, private: $private
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Patch team group
#
# PUT /v1/teams/{team}/groups/{group}/
# Returns: record<created_by: string, description: string, id: string, members: list<string>, name: string, parent: string, permissions: list<string>, private: bool>
# operationId: teams_groups_replace
export def "teams-groups-replace" [
  team: string
  group: string
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
  --description: string # Group description
  name: string # Group name
  --parent: string # Parent group
  --private: oneof<nothing, bool> # States whether group is visible to all users.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/teams/{team}/groups/{group}/"
    path_params: [{name: team, var: team}, {name: group, var: group}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: parent, var: parent}, {name: private, var: private}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    team: $team, group: $group, description: $description, name: $name, parent: $parent, private: $private
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add user to group
#
# POST /v1/teams/{team}/groups/{group}/add/
# Returns: record<user: string>
# operationId: teams_groups_add_to_group
export def "teams-groups-add-to-group" [
  team: string
  group: string
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
    method: post
    path: "/v1/teams/{team}/groups/{group}/add/"
    path_params: [{name: team, var: team}, {name: group, var: group}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    team: $team, group: $group
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# User removed from group
#
# POST /v1/teams/{team}/groups/{group}/remove/
# operationId: teams_groups_remove_from_group
export def "teams-groups-remove-from-group" [
  team: string
  group: string
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
]: nothing -> any {
  http-request {
    method: post
    path: "/v1/teams/{team}/groups/{group}/remove/"
    path_params: [{name: team, var: team}, {name: group, var: group}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    team: $team, group: $group
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get user list
#
# GET /v1/users/profiles/
# Returns: table<email: string, first_name: string, id: string, last_name: string, profile: record<avatar: string, bio: string, company: string, location: string, timezone: string, url: string>, username: string>
# operationId: users_list
export def "users-list" [
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
  --limit: string # Limit user list.
  --offset: string # Offset when getting users.
  --username: string # User username.
  --email: string # User email.
  --ordering: string # Ordering when getting users.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/users/profiles/"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: username, var: username}, {name: email, var: email}, {name: ordering, var: ordering}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, username: $username, email: $email, ordering: $ordering
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create new user
#
# POST /v1/users/profiles/
# Returns: record<email: string, first_name: string, id: string, last_name: string, profile: record<avatar: string, bio: string, company: string, location: string, timezone: string, url: string>, username: string>
# operationId: users_create
export def "users-create" [
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
  --email: string # User email.
  --first-name: string # User first name.
  --last-name: string # User last name.
  password: string # User password.
  profile: record # shape: {avatar?: string, bio?: string, company?: string, location?: string, timezone?: string, url?: string}
  username: string # Required. 150 characters or fewer. Letters, digits and @/./+/-/_ only.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/users/profiles/"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: password, var: password}, {name: profile, var: profile}, {name: username, var: username}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: bearer
  } {
    email: $email, first_name: $first_name, last_name: $last_name, password: $password, profile: $profile, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a user
#
# DELETE /v1/users/profiles/{user}/
# operationId: users_delete
export def "users-delete" [
  user: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/users/profiles/{user}/"
    path_params: [{name: user, var: user}]
    accept: ["application/json", "text/html"]
    ok: [204]
    auth: bearer
  } {
    user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a user
#
# GET /v1/users/profiles/{user}/
# Returns: record<email: string, first_name: string, id: string, last_name: string, profile: record<avatar: string, bio: string, company: string, location: string, timezone: string, url: string>, username: string>
# operationId: users_read
export def "users-read" [
  user: string
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
    path: "/v1/users/profiles/{user}/"
    path_params: [{name: user, var: user}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a user
#
# PATCH /v1/users/profiles/{user}/
# Returns: record<email: string, first_name: string, id: string, last_name: string, profile: record<avatar: string, bio: string, company: string, location: string, timezone: string, url: string>, username: string>
# operationId: users_update
export def "users-update" [
  user: string
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
  --email: string # User email.
  --first-name: string # User first name.
  --last-name: string # User last name.
  password: string # User password.
  profile: record # shape: {avatar?: string, bio?: string, company?: string, location?: string, timezone?: string, url?: string}
  username: string # Required. 150 characters or fewer. Letters, digits and @/./+/-/_ only.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/users/profiles/{user}/"
    path_params: [{name: user, var: user}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: password, var: password}, {name: profile, var: profile}, {name: username, var: username}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    user: $user, email: $email, first_name: $first_name, last_name: $last_name, password: $password, profile: $profile, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve account's API key
#
# GET /v1/users/{user}/api-key/
# operationId: users_api-key_list
export def "users-api-key-list" [
  user: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/users/{user}/api-key/"
    path_params: [{name: user, var: user}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete avatar
#
# DELETE /v1/users/{user}/avatar/
# operationId: user_avatar_delete
export def "user-avatar-delete" [
  user: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/users/{user}/avatar/"
    path_params: [{name: user, var: user}]
    accept: ["application/json", "text/html"]
    ok: [204]
    auth: bearer
  } {
    user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve user's avatar
#
# GET /v1/users/{user}/avatar/
# operationId: user_avatar_get
export def "user-avatar-get" [
  user: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/users/{user}/avatar/"
    path_params: [{name: user, var: user}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a project file
#
# PATCH /v1/users/{user}/avatar/
# Returns: record<email: string, first_name: string, id: string, last_name: string, profile: record<avatar: string, bio: string, company: string, location: string, timezone: string, url: string>, username: string>
# operationId: user_avatar_update
export def "user-avatar-update" [
  user: string
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
    method: patch
    path: "/v1/users/{user}/avatar/"
    path_params: [{name: user, var: user}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add user avatar
#
# POST /v1/users/{user}/avatar/
# Returns: record<email: string, first_name: string, id: string, last_name: string, profile: record<avatar: string, bio: string, company: string, location: string, timezone: string, url: string>, username: string>
# operationId: user_avatar_set
export def "user-avatar-set" [
  user: string
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
    method: post
    path: "/v1/users/{user}/avatar/"
    path_params: [{name: user, var: user}]
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: bearer
  } {
    user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve account email addresses
#
# GET /v1/users/{user}/emails/
# Returns: table<address: string, id: string, public: bool, unsubscribed: bool, user: string>
# operationId: users_emails_list
export def "users-emails-list" [
  user: string
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
  --limit: string # Limite when getting email list.
  --offset: string # Offset when getting email list.
  --ordering: string # Ordering when getting email list.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/users/{user}/emails/"
    path_params: [{name: user, var: user}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: ordering, var: ordering}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    user: $user, limit: $limit, offset: $offset, ordering: $ordering
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create an email address
#
# POST /v1/users/{user}/emails/
# Returns: record<address: string, id: string, public: bool, unsubscribed: bool, user: string>
# operationId: users_emails_create
export def "users-emails-create" [
  user: string
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
  address: string # Email address.
  --public: oneof<nothing, bool> # Public or private email address.
  --unsubscribed: oneof<nothing, bool> # Unsubscribed or suscribed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/users/{user}/emails/"
    path_params: [{name: user, var: user}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: public, var: public}, {name: unsubscribed, var: unsubscribed}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: bearer
  } {
    user: $user, address: $address, public: $public, unsubscribed: $unsubscribed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an email address
#
# DELETE /v1/users/{user}/emails/{email_id}/
# operationId: users_emails_delete
export def "users-emails-delete" [
  user: string
  email_id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/users/{user}/emails/{email_id}/"
    path_params: [{name: user, var: user}, {name: email_id, var: email_id}]
    accept: ["application/json", "text/html"]
    ok: [204]
    auth: bearer
  } {
    user: $user, email_id: $email_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a user's email addresses
#
# GET /v1/users/{user}/emails/{email_id}/
# Returns: record<address: string, id: string, public: bool, unsubscribed: bool, user: string>
# operationId: users_emails_read
export def "users-emails-read" [
  user: string
  email_id: string
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
    path: "/v1/users/{user}/emails/{email_id}/"
    path_params: [{name: user, var: user}, {name: email_id, var: email_id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    user: $user, email_id: $email_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update an email address
#
# PATCH /v1/users/{user}/emails/{email_id}/
# Returns: record<address: string, id: string, public: bool, unsubscribed: bool, user: string>
# operationId: users_emails_update
export def "users-emails-update" [
  user: string
  email_id: string
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
  address: string # Email address.
  --public: oneof<nothing, bool> # Public or private email address.
  --unsubscribed: oneof<nothing, bool> # Unsubscribed or suscribed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/users/{user}/emails/{email_id}/"
    path_params: [{name: user, var: user}, {name: email_id, var: email_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: public, var: public}, {name: unsubscribed, var: unsubscribed}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    user: $user, email_id: $email_id, address: $address, public: $public, unsubscribed: $unsubscribed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replace an email address
#
# PUT /v1/users/{user}/emails/{email_id}/
# Returns: record<address: string, id: string, public: bool, unsubscribed: bool, user: string>
# operationId: users_emails_replace
export def "users-emails-replace" [
  user: string
  email_id: string
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
  address: string # Email address.
  --public: oneof<nothing, bool> # Public or private email address.
  --unsubscribed: oneof<nothing, bool> # Unsubscribed or suscribed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/users/{user}/emails/{email_id}/"
    path_params: [{name: user, var: user}, {name: email_id, var: email_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: public, var: public}, {name: unsubscribed, var: unsubscribed}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    user: $user, email_id: $email_id, address: $address, public: $public, unsubscribed: $unsubscribed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve an SSH key
#
# GET /v1/users/{user}/ssh-key/
# operationId: users_ssh-key_list
export def "users-ssh-key-list" [
  user: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/users/{user}/ssh-key/"
    path_params: [{name: user, var: user}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Recreate an SSH key
#
# POST /v1/users/{user}/ssh-key/reset/
# operationId: users_ssh-key_reset
export def "users-ssh-key-reset" [
  user: string
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
]: nothing -> any {
  http-request {
    method: post
    path: "/v1/users/{user}/ssh-key/reset/"
    path_params: [{name: user, var: user}]
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: bearer
  } {
    user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get credit cards
#
# GET /v1/{namespace}/billing/cards/
# Returns: table<address_city: string, address_country: string, address_line1: string, address_line1_check: string, address_line2: string, address_state: string, address_zip: string, address_zip_check: string, brand: string, created: string, customer: string, cvc_check: string, exp_month: int, exp_year: int, fingerprint: string, funding: string, id: string, last4: string, name: string, stripe_id: string, token: string>
# operationId: billing_cards_list
export def "billing-cards-list" [
  namespace: string
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
  --limit: string # Set limit when retrieving credit or debit cards.
  --offset: string # Set offset when retriving cards.
  --ordering: string # Order when retrieving cards.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{namespace}/billing/cards/"
    path_params: [{name: namespace, var: namespace}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: ordering, var: ordering}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, limit: $limit, offset: $offset, ordering: $ordering
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create new credit card
#
# POST /v1/{namespace}/billing/cards/
# Returns: record<address_city: string, address_country: string, address_line1: string, address_line1_check: string, address_line2: string, address_state: string, address_zip: string, address_zip_check: string, brand: string, created: string, customer: string, cvc_check: string, exp_month: int, exp_year: int, fingerprint: string, funding: string, id: string, last4: string, name: string, stripe_id: string, token: string>
# operationId: billing_cards_create
export def "billing-cards-create" [
  namespace: string
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
  --address-city: string # Address city.
  --address-country: string # Address country.
  --address-line1: string # Address line 1.
  --address-line2: string # Address line 2.
  --address-state: string # Address state.
  --address-zip: string # Address zip code.
  --exp-month: int # Card expiration month.
  --exp-year: int # Card expiration year.
  --name: string # Card name.
  --body-token: string # Card unique token. (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{namespace}/billing/cards/"
    path_params: [{name: namespace, var: namespace}]
    body: {content_type: "application/json", kind: json, fields: [{name: address_city, var: address_city}, {name: address_country, var: address_country}, {name: address_line1, var: address_line1}, {name: address_line2, var: address_line2}, {name: address_state, var: address_state}, {name: address_zip, var: address_zip}, {name: exp_month, var: exp_month}, {name: exp_year, var: exp_year}, {name: name, var: name}, {name: token, var: body_token}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: bearer
  } {
    namespace: $namespace, address_city: $address_city, address_country: $address_country, address_line1: $address_line1, address_line2: $address_line2, address_state: $address_state, address_zip: $address_zip, exp_month: $exp_month, exp_year: $exp_year, name: $name, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a credit card
#
# DELETE /v1/{namespace}/billing/cards/{id}/
# operationId: billing_cards_delete
export def "billing-cards-delete" [
  namespace: string
  id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/{namespace}/billing/cards/{id}/"
    path_params: [{name: namespace, var: namespace}, {name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [204]
    auth: bearer
  } {
    namespace: $namespace, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get credit card by id
#
# GET /v1/{namespace}/billing/cards/{id}/
# Returns: record<address_city: string, address_country: string, address_line1: string, address_line1_check: string, address_line2: string, address_state: string, address_zip: string, address_zip_check: string, brand: string, created: string, customer: string, cvc_check: string, exp_month: int, exp_year: int, fingerprint: string, funding: string, id: string, last4: string, name: string, stripe_id: string, token: string>
# operationId: billing_cards_read
export def "billing-cards-read" [
  namespace: string
  id: string
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
    path: "/v1/{namespace}/billing/cards/{id}/"
    path_params: [{name: namespace, var: namespace}, {name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a credit card
#
# PATCH /v1/{namespace}/billing/cards/{id}/
# Returns: record<address_city: string, address_country: string, address_line1: string, address_line1_check: string, address_line2: string, address_state: string, address_zip: string, address_zip_check: string, brand: string, created: string, customer: string, cvc_check: string, exp_month: int, exp_year: int, fingerprint: string, funding: string, id: string, last4: string, name: string, stripe_id: string, token: string>
# operationId: billing_cards_update
export def "billing-cards-update" [
  namespace: string
  id: string
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
  --address-city: string # Address city.
  --address-country: string # Address country.
  --address-line1: string # Address line 1.
  --address-line2: string # Address line 2.
  --address-state: string # Address state.
  --address-zip: string # Address zip code.
  --exp-month: int # Card expiration month.
  --exp-year: int # Card expiration year.
  --name: string # Card name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/{namespace}/billing/cards/{id}/"
    path_params: [{name: namespace, var: namespace}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address_city, var: address_city}, {name: address_country, var: address_country}, {name: address_line1, var: address_line1}, {name: address_line2, var: address_line2}, {name: address_state, var: address_state}, {name: address_zip, var: address_zip}, {name: exp_month, var: exp_month}, {name: exp_year, var: exp_year}, {name: name, var: name}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, id: $id, address_city: $address_city, address_country: $address_country, address_line1: $address_line1, address_line2: $address_line2, address_state: $address_state, address_zip: $address_zip, exp_month: $exp_month, exp_year: $exp_year, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replace a credit card
#
# PUT /v1/{namespace}/billing/cards/{id}/
# Returns: record<address_city: string, address_country: string, address_line1: string, address_line1_check: string, address_line2: string, address_state: string, address_zip: string, address_zip_check: string, brand: string, created: string, customer: string, cvc_check: string, exp_month: int, exp_year: int, fingerprint: string, funding: string, id: string, last4: string, name: string, stripe_id: string, token: string>
# operationId: billing_cards_replace
export def "billing-cards-replace" [
  namespace: string
  id: string
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
  --address-city: string # Address city.
  --address-country: string # Address country.
  --address-line1: string # Address line 1.
  --address-line2: string # Address line 2.
  --address-state: string # Address state.
  --address-zip: string # Address zip code.
  --exp-month: int # Card expiration month.
  --exp-year: int # Card expiration year.
  --name: string # Card name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/{namespace}/billing/cards/{id}/"
    path_params: [{name: namespace, var: namespace}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address_city, var: address_city}, {name: address_country, var: address_country}, {name: address_line1, var: address_line1}, {name: address_line2, var: address_line2}, {name: address_state, var: address_state}, {name: address_zip, var: address_zip}, {name: exp_month, var: exp_month}, {name: exp_year, var: exp_year}, {name: name, var: name}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, id: $id, address_city: $address_city, address_country: $address_country, address_line1: $address_line1, address_line2: $address_line2, address_state: $address_state, address_zip: $address_zip, exp_month: $exp_month, exp_year: $exp_year, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get invoices
#
# GET /v1/{namespace}/billing/invoices/
# Returns: table<amount_due: int, application_fee: int, attempt_count: int, attempted: bool, closed: bool, created: string, currency: string, customer: string, description: string, id: string, invoice_date: string, livemode: bool, metadata: record, next_payment_attempt: string, paid: bool, period_end: string, period_start: string, reciept_number: string, starting_balance: int, statement_descriptor: string, stripe_id: string, subscription: string, subtotal: int, tax: int, total: int>
# operationId: billing_invoices_list
export def "billing-invoices-list" [
  namespace: string
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
  --limit: string # Limit when getting items.
  --offset: string # Offset when getting items.
  --ordering: string # Ordering when getting items.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{namespace}/billing/invoices/"
    path_params: [{name: namespace, var: namespace}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: ordering, var: ordering}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, limit: $limit, offset: $offset, ordering: $ordering
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get an invoice
#
# GET /v1/{namespace}/billing/invoices/{id}/
# Returns: record<amount_due: int, application_fee: int, attempt_count: int, attempted: bool, closed: bool, created: string, currency: string, customer: string, description: string, id: string, invoice_date: string, livemode: bool, metadata: record, next_payment_attempt: string, paid: bool, period_end: string, period_start: string, reciept_number: string, starting_balance: int, statement_descriptor: string, stripe_id: string, subscription: string, subtotal: int, tax: int, total: int>
# operationId: billing_invoices_read
export def "billing-invoices-read" [
  namespace: string
  id: string
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
    path: "/v1/{namespace}/billing/invoices/{id}/"
    path_params: [{name: namespace, var: namespace}, {name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get invoice items for a given invoice.
#
# GET /v1/{namespace}/billing/invoices/{invoice_id}/invoice-items/
# Returns: table<amount: int, created: string, currency: string, description: string, id: string, invoice: string, invoice_date: string, livemode: bool, metadata: record, proration: bool, quantity: int, stripe_id: string>
# operationId: billing_invoice_items_list
export def "billing-invoice-items-list" [
  namespace: string
  invoice_id: string
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
  --limit: string # Limit when getting items.
  --offset: string # Offset when getting items.
  --ordering: string # Ordering when getting items.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{namespace}/billing/invoices/{invoice_id}/invoice-items/"
    path_params: [{name: namespace, var: namespace}, {name: invoice_id, var: invoice_id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: ordering, var: ordering}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, invoice_id: $invoice_id, limit: $limit, offset: $offset, ordering: $ordering
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a specific InvoiceItem.
#
# GET /v1/{namespace}/billing/invoices/{invoice_id}/invoice-items/{id}
# Returns: record<amount: int, created: string, currency: string, description: string, id: string, invoice: string, invoice_date: string, livemode: bool, metadata: record, proration: bool, quantity: int, stripe_id: string>
# operationId: billing_invoice_items_read
export def "billing-invoice-items-read" [
  namespace: string
  invoice_id: string
  id: string
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
    path: "/v1/{namespace}/billing/invoices/{invoice_id}/invoice-items/{id}"
    path_params: [{name: namespace, var: namespace}, {name: invoice_id, var: invoice_id}, {name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, invoice_id: $invoice_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get billing plans
#
# GET /v1/{namespace}/billing/plans/
# Returns: table<amount: int, created: string, currency: string, id: string, interval: string, interval_count: int, livemode: bool, metadata: record, name: string, statement_descriptor: string, stripe_id: string, trial_period_days: int>
# operationId: billing_plans_list
export def "billing-plans-list" [
  namespace: string
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
  --limit: string # Limit when getting items.
  --offset: string # Offset when getting items.
  --ordering: string # Ordering when getting items.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{namespace}/billing/plans/"
    path_params: [{name: namespace, var: namespace}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: ordering, var: ordering}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, limit: $limit, offset: $offset, ordering: $ordering
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a billing plan
#
# GET /v1/{namespace}/billing/plans/{id}/
# Returns: record<amount: int, created: string, currency: string, id: string, interval: string, interval_count: int, livemode: bool, metadata: record, name: string, statement_descriptor: string, stripe_id: string, trial_period_days: int>
# operationId: billing_plans_read
export def "billing-plans-read" [
  namespace: string
  id: string
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
    path: "/v1/{namespace}/billing/plans/{id}/"
    path_params: [{name: namespace, var: namespace}, {name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get active subscriptons
#
# GET /v1/{namespace}/billing/subscriptions/
# Returns: table<application_fee_percent: float, cancel_at_period_end: bool, canceled_at: string, created: string, current_period_end: string, current_period_start: string, ended_at: string, id: string, livemode: bool, plan: string, quantity: int, start: string, status: string, stripe_id: string, trial_end: string, trial_start: string>
# operationId: billing_subscriptions_list
export def "billing-subscriptions-list" [
  namespace: string
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
  --limit: string # Limit when getting items.
  --offset: string # Offset when getting items.
  --ordering: string # Ordering when getting items.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{namespace}/billing/subscriptions/"
    path_params: [{name: namespace, var: namespace}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: ordering, var: ordering}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, limit: $limit, offset: $offset, ordering: $ordering
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new subscription
#
# POST /v1/{namespace}/billing/subscriptions/
# Returns: record<application_fee_percent: float, cancel_at_period_end: bool, canceled_at: string, created: string, current_period_end: string, current_period_start: string, ended_at: string, id: string, livemode: bool, plan: string, quantity: int, start: string, status: string, stripe_id: string, trial_end: string, trial_start: string>
# operationId: billing_subscriptions_create
export def "billing-subscriptions-create" [
  namespace: string
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
  plan: string # Plan unique identifier.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{namespace}/billing/subscriptions/"
    path_params: [{name: namespace, var: namespace}]
    body: {content_type: "application/json", kind: json, fields: [{name: plan, var: plan}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: bearer
  } {
    namespace: $namespace, plan: $plan
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a subscription
#
# DELETE /v1/{namespace}/billing/subscriptions/{id}/
# operationId: billing_subscriptions_delete
export def "billing-subscriptions-delete" [
  namespace: string
  id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/{namespace}/billing/subscriptions/{id}/"
    path_params: [{name: namespace, var: namespace}, {name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [204]
    auth: bearer
  } {
    namespace: $namespace, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a subscriptions
#
# GET /v1/{namespace}/billing/subscriptions/{id}/
# Returns: record<application_fee_percent: float, cancel_at_period_end: bool, canceled_at: string, created: string, current_period_end: string, current_period_start: string, ended_at: string, id: string, livemode: bool, plan: string, quantity: int, start: string, status: string, stripe_id: string, trial_end: string, trial_start: string>
# operationId: billing_subscriptions_read
export def "billing-subscriptions-read" [
  namespace: string
  id: string
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
    path: "/v1/{namespace}/billing/subscriptions/{id}/"
    path_params: [{name: namespace, var: namespace}, {name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get notifications of all types and entities for the authenticated user.
#
# GET /v1/{namespace}/notifications/
# Returns: table<actor: string, id: string, read: bool, target: string, timestamp: string, type: string, user: string>
# operationId: notifications_list
export def "notifications-list" [
  namespace: string
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
  --limit: string # Limit when getting items.
  --offset: string # Offset when getting items.
  --ordering: string # Ordering when getting items.
  --read: oneof<nothing, bool> # When true, get only read notifications. When false, get only unread notifications. Default behavior is to return both read and unread.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{namespace}/notifications/"
    path_params: [{name: namespace, var: namespace}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: ordering, var: ordering}, {name: read, var: read}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, limit: $limit, offset: $offset, ordering: $ordering, read: $read
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Mark a list of notifications as either read or unread.
#
# PATCH /v1/{namespace}/notifications/
# Returns: record<actor: string, id: string, read: bool, target: string, timestamp: string, type: string, user: string>
# operationId: notifications_update_list
export def "notifications-update-list" [
  namespace: string
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
  notifications: list<string> # An array of notification IDs to update.
  --read: oneof<nothing, bool> # Mark the notification as either read or unread
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/{namespace}/notifications/"
    path_params: [{name: namespace, var: namespace}]
    body: {content_type: "application/json", kind: json, fields: [{name: notifications, var: notifications}, {name: read, var: read, required: true}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, notifications: $notifications, read: $read
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get notifications of all types and entities for the authenticated user.
#
# GET /v1/{namespace}/notifications/entity/{entity}
# Returns: table<actor: string, id: string, read: bool, target: string, timestamp: string, type: string, user: string>
# operationId: notifications_list_entity
export def "notifications-list-entity" [
  namespace: string
  entity: string@entity-completer
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
  --limit: string # Limit when getting items.
  --offset: string # Offset when getting items.
  --ordering: string # Ordering when getting items.
  --read: oneof<nothing, bool> # When true, get only read notifications. When false, get only unread notifications. Default behavior is to return both read and unread.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{namespace}/notifications/entity/{entity}"
    path_params: [{name: namespace, var: namespace}, {name: entity, var: entity}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: ordering, var: ordering}, {name: read, var: read}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, entity: $entity, limit: $limit, offset: $offset, ordering: $ordering, read: $read
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Mark a list of notifications as either read or unread.
#
# PATCH /v1/{namespace}/notifications/entity/{entity}
# Returns: record<actor: string, id: string, read: bool, target: string, timestamp: string, type: string, user: string>
# operationId: notifications_update_entity_list
export def "notifications-update-entity-list" [
  namespace: string
  entity: string@entity-completer
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
  notifications: list<string> # An array of notification IDs to update.
  --read: oneof<nothing, bool> # Mark the notification as either read or unread
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/{namespace}/notifications/entity/{entity}"
    path_params: [{name: namespace, var: namespace}, {name: entity, var: entity}]
    body: {content_type: "application/json", kind: json, fields: [{name: notifications, var: notifications}, {name: read, var: read, required: true}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, entity: $entity, notifications: $notifications, read: $read
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve global notification settings for the authenticated user
#
# GET /v1/{namespace}/notifications/settings/
# Returns: table<email_address: string, emails_enabled: bool, enabled: bool, entity: string, id: string, user: string>
# operationId: notification_settings_read
export def "notification-settings-read" [
  namespace: string
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
    path: "/v1/{namespace}/notifications/settings/"
    path_params: [{name: namespace, var: namespace}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Modify global notification settings.
#
# PATCH /v1/{namespace}/notifications/settings/
# Returns: record<email_address: string, emails_enabled: bool, enabled: bool, entity: string, id: string, user: string>
# operationId: notification_settings_update
export def "notification-settings-update" [
  namespace: string
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
  --emails-enabled: oneof<nothing, bool> # Turn emails on or off.
  --enabled: oneof<nothing, bool> # Turn notifications on or off entirely.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/{namespace}/notifications/settings/"
    path_params: [{name: namespace, var: namespace}]
    body: {content_type: "application/json", kind: json, fields: [{name: emails_enabled, var: emails_enabled, required: true}, {name: enabled, var: enabled, required: true}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, emails_enabled: $emails_enabled, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create global notification settings
#
# POST /v1/{namespace}/notifications/settings/
# Returns: record<email_address: string, emails_enabled: bool, enabled: bool, entity: string, id: string, user: string>
# operationId: notification_settings_create
export def "notification-settings-create" [
  namespace: string
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
  --emails-enabled: oneof<nothing, bool> # Turn emails on or off.
  --enabled: oneof<nothing, bool> # Turn notifications on or off entirely.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{namespace}/notifications/settings/"
    path_params: [{name: namespace, var: namespace}]
    body: {content_type: "application/json", kind: json, fields: [{name: emails_enabled, var: emails_enabled, required: true}, {name: enabled, var: enabled, required: true}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: bearer
  } {
    namespace: $namespace, emails_enabled: $emails_enabled, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve global notification settings for the authenticated user
#
# GET /v1/{namespace}/notifications/settings/entity/{entity}
# Returns: table<email_address: string, emails_enabled: bool, enabled: bool, entity: string, id: string, user: string>
# operationId: notification_settings_entity_read
export def "notification-settings-entity-read" [
  namespace: string
  entity: string@entity-completer
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
    path: "/v1/{namespace}/notifications/settings/entity/{entity}"
    path_params: [{name: namespace, var: namespace}, {name: entity, var: entity}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, entity: $entity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Modify global notification settings.
#
# PATCH /v1/{namespace}/notifications/settings/entity/{entity}
# Returns: record<email_address: string, emails_enabled: bool, enabled: bool, entity: string, id: string, user: string>
# operationId: notification_settings_entity_update
export def "notification-settings-entity-update" [
  namespace: string
  entity: string@entity-completer
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
  --emails-enabled: oneof<nothing, bool> # Turn emails on or off.
  --enabled: oneof<nothing, bool> # Turn notifications on or off entirely.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/{namespace}/notifications/settings/entity/{entity}"
    path_params: [{name: namespace, var: namespace}, {name: entity, var: entity}]
    body: {content_type: "application/json", kind: json, fields: [{name: emails_enabled, var: emails_enabled, required: true}, {name: enabled, var: enabled, required: true}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, entity: $entity, emails_enabled: $emails_enabled, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create global notification settings
#
# POST /v1/{namespace}/notifications/settings/entity/{entity}
# Returns: record<email_address: string, emails_enabled: bool, enabled: bool, entity: string, id: string, user: string>
# operationId: notification_settings_entity_create
export def "notification-settings-entity-create" [
  namespace: string
  entity: string@entity-completer
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
  --emails-enabled: oneof<nothing, bool> # Turn emails on or off.
  --enabled: oneof<nothing, bool> # Turn notifications on or off entirely.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{namespace}/notifications/settings/entity/{entity}"
    path_params: [{name: namespace, var: namespace}, {name: entity, var: entity}]
    body: {content_type: "application/json", kind: json, fields: [{name: emails_enabled, var: emails_enabled, required: true}, {name: enabled, var: enabled, required: true}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: bearer
  } {
    namespace: $namespace, entity: $entity, emails_enabled: $emails_enabled, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a specific notification.
#
# GET /v1/{namespace}/notifications/{notification_id}
# Returns: record<actor: string, id: string, read: bool, target: string, timestamp: string, type: string, user: string>
# operationId: notification_read
export def "notification-read" [
  namespace: string
  notification_id: string
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
    path: "/v1/{namespace}/notifications/{notification_id}"
    path_params: [{name: namespace, var: namespace}, {name: notification_id, var: notification_id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, notification_id: $notification_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Mark a specific notification as either read or unread.
#
# PATCH /v1/{namespace}/notifications/{notification_id}
# Returns: record<actor: string, id: string, read: bool, target: string, timestamp: string, type: string, user: string>
# operationId: notification_update
export def "notification-update" [
  namespace: string
  notification_id: string
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
  --read: oneof<nothing, bool> # Mark the notification as either read or unread
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/{namespace}/notifications/{notification_id}"
    path_params: [{name: namespace, var: namespace}, {name: notification_id, var: notification_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: read, var: read, required: true}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, notification_id: $notification_id, read: $read
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve oauth applications
#
# GET /v1/{namespace}/oauth/applications/
# Returns: table<authorization_grant_type: string, client_id: string, client_secret: string, client_type: string, id: string, name: string, redirect_uris: string>
# operationId: oauth_applications_list
export def "oauth-applications-list" [
  namespace: string
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
  --limit: string # Set limit when retrieving items.
  --offset: string # Offset when retrieving items.
  --ordering: string # Set order when retrieving items.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{namespace}/oauth/applications/"
    path_params: [{name: namespace, var: namespace}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: ordering, var: ordering}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, limit: $limit, offset: $offset, ordering: $ordering
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new OAuth2 application
#
# POST /v1/{namespace}/oauth/applications/
# Returns: record<authorization_grant_type: string, client_id: string, client_secret: string, client_type: string, id: string, name: string, redirect_uris: string>
# operationId: oauth_application_create
export def "oauth-application-create" [
  namespace: string
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
  authorization_grant_type: string@authorization-grant-type-completer # OAuth2 authorization grant type
  client_type: string@client-type-completer # OAuth2 client type
  name: string # Application name
  --redirect-uris: string # Uris to redirect auth request
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{namespace}/oauth/applications/"
    path_params: [{name: namespace, var: namespace}]
    body: {content_type: "application/json", kind: json, fields: [{name: authorization_grant_type, var: authorization_grant_type}, {name: client_type, var: client_type}, {name: name, var: name}, {name: redirect_uris, var: redirect_uris}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: bearer
  } {
    namespace: $namespace, authorization_grant_type: $authorization_grant_type, client_type: $client_type, name: $name, redirect_uris: $redirect_uris
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an application by id
#
# DELETE /v1/{namespace}/oauth/applications/{application}/
# operationId: oauth_application_delete
export def "oauth-application-delete" [
  namespace: string
  application: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/{namespace}/oauth/applications/{application}/"
    path_params: [{name: namespace, var: namespace}, {name: application, var: application}]
    accept: ["application/json", "text/html"]
    ok: [204]
    auth: bearer
  } {
    namespace: $namespace, application: $application
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get an application by id
#
# GET /v1/{namespace}/oauth/applications/{application}/
# Returns: record<authorization_grant_type: string, client_id: string, client_secret: string, client_type: string, id: string, name: string, redirect_uris: string>
# operationId: oauth_application_read
export def "oauth-application-read" [
  namespace: string
  application: string
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
    path: "/v1/{namespace}/oauth/applications/{application}/"
    path_params: [{name: namespace, var: namespace}, {name: application, var: application}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, application: $application
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update an application by id
#
# PATCH /v1/{namespace}/oauth/applications/{application}/
# Returns: record<authorization_grant_type: string, client_id: string, client_secret: string, client_type: string, id: string, name: string, redirect_uris: string>
# operationId: oauth_application_update
export def "oauth-application-update" [
  namespace: string
  application: string
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
  authorization_grant_type: string@authorization-grant-type-completer # OAuth2 authorization grant type
  client_type: string@client-type-completer # OAuth2 client type
  name: string # Application name
  --redirect-uris: string # Uris to redirect auth request
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/{namespace}/oauth/applications/{application}/"
    path_params: [{name: namespace, var: namespace}, {name: application, var: application}]
    body: {content_type: "application/json", kind: json, fields: [{name: authorization_grant_type, var: authorization_grant_type}, {name: client_type, var: client_type}, {name: name, var: name}, {name: redirect_uris, var: redirect_uris}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, application: $application, authorization_grant_type: $authorization_grant_type, client_type: $client_type, name: $name, redirect_uris: $redirect_uris
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replace an application by id
#
# PUT /v1/{namespace}/oauth/applications/{application}/
# Returns: record<authorization_grant_type: string, client_id: string, client_secret: string, client_type: string, id: string, name: string, redirect_uris: string>
# operationId: oauth_application_replace
export def "oauth-application-replace" [
  namespace: string
  application: string
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
  authorization_grant_type: string@authorization-grant-type-completer # OAuth2 authorization grant type
  client_type: string@client-type-completer # OAuth2 client type
  name: string # Application name
  --redirect-uris: string # Uris to redirect auth request
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/{namespace}/oauth/applications/{application}/"
    path_params: [{name: namespace, var: namespace}, {name: application, var: application}]
    body: {content_type: "application/json", kind: json, fields: [{name: authorization_grant_type, var: authorization_grant_type}, {name: client_type, var: client_type}, {name: name, var: name}, {name: redirect_uris, var: redirect_uris}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, application: $application, authorization_grant_type: $authorization_grant_type, client_type: $client_type, name: $name, redirect_uris: $redirect_uris
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get available projects
#
# GET /v1/{namespace}/projects/
# Returns: table<collaborators: list<string>, description: string, id: string, last_updated: string, name: string, owner: string, private: bool, team: string>
# operationId: projects_list
export def "projects-list" [
  namespace: string
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
  --limit: string # Limit when getting data.
  --offset: string # Offset when getting data.
  --private: string # Private project or public project.
  --name: string # Project name.
  --ordering: string # Ordering when getting projects.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{namespace}/projects/"
    path_params: [{name: namespace, var: namespace}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: private, var: private}, {name: name, var: name}, {name: ordering, var: ordering}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, limit: $limit, offset: $offset, private: $private, name: $name, ordering: $ordering
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new project
#
# POST /v1/{namespace}/projects/
# Returns: record<collaborators: list<string>, description: string, id: string, last_updated: string, name: string, owner: string, private: bool, team: string>
# operationId: projects_create
export def "projects-create" [
  namespace: string
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
  --description: string # Project description.
  name: string # Project name.
  --private: oneof<nothing, bool> # Private project true, otherwise public.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{namespace}/projects/"
    path_params: [{name: namespace, var: namespace}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: private, var: private}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: bearer
  } {
    namespace: $namespace, description: $description, name: $name, private: $private
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Check if you are able to copy a project to your account.
#
# HEAD /v1/{namespace}/projects/project-copy-check/
# Returns: record
# operationId: project_copy_check
export def "project-copy-check" [
  namespace: string
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
    method: head
    path: "/v1/{namespace}/projects/project-copy-check/"
    path_params: [{name: namespace, var: namespace}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Copy a project to your own account.
#
# POST /v1/{namespace}/projects/project-copy/
# Returns: record<collaborators: list<string>, description: string, id: string, last_updated: string, name: string, owner: string, private: bool, team: string>
# operationId: project_copy
export def "project-copy" [
  namespace: string
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
  --name: string # Name for the newly copied project
  project: string # UUID of the project the user wishes to copy.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{namespace}/projects/project-copy/"
    path_params: [{name: namespace, var: namespace}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: project, var: project}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: bearer
  } {
    namespace: $namespace, name: $name, project: $project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a project
#
# DELETE /v1/{namespace}/projects/{project}/
# operationId: projects_delete
export def "projects-delete" [
  namespace: string
  project: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/{namespace}/projects/{project}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}]
    accept: ["application/json", "text/html"]
    ok: [204]
    auth: bearer
  } {
    namespace: $namespace, project: $project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a project
#
# GET /v1/{namespace}/projects/{project}/
# Returns: record<collaborators: list<string>, description: string, id: string, last_updated: string, name: string, owner: string, private: bool, team: string>
# operationId: projects_read
export def "projects-read" [
  namespace: string
  project: string
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
    path: "/v1/{namespace}/projects/{project}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a project
#
# PATCH /v1/{namespace}/projects/{project}/
# Returns: record<collaborators: list<string>, description: string, id: string, last_updated: string, name: string, owner: string, private: bool, team: string>
# operationId: projects_update
export def "projects-update" [
  namespace: string
  project: string
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
  --description: string # Project description.
  name: string # Project name.
  --private: oneof<nothing, bool> # Private project true, otherwise public.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/{namespace}/projects/{project}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: private, var: private}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, description: $description, name: $name, private: $private
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replace a project
#
# PUT /v1/{namespace}/projects/{project}/
# Returns: record<collaborators: list<string>, description: string, id: string, last_updated: string, name: string, owner: string, private: bool, team: string>
# operationId: projects_replace
export def "projects-replace" [
  namespace: string
  project: string
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
  --description: string # Project description.
  name: string # Project name.
  --private: oneof<nothing, bool> # Private project true, otherwise public.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/{namespace}/projects/{project}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: private, var: private}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, description: $description, name: $name, private: $private
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get project collaborators
#
# GET /v1/{namespace}/projects/{project}/collaborators/
# Returns: table<email: string, first_name: string, id: string, joined: string, last_name: string, owner: bool, permissions: list<string>, project: string, user: string, username: string>
# operationId: projects_collaborators_list
export def "projects-collaborators-list" [
  namespace: string
  project: string
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
  --limit: string # Limit when retrieving items.
  --offset: string # Offset when retrieving items.
  --ordering: string # Ordering when retrieving items.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{namespace}/projects/{project}/collaborators/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: ordering, var: ordering}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, limit: $limit, offset: $offset, ordering: $ordering
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create project collaborators
#
# POST /v1/{namespace}/projects/{project}/collaborators/
# Returns: record<email: string, first_name: string, id: string, joined: string, last_name: string, owner: bool, permissions: list<string>, project: string, user: string, username: string>
# operationId: projects_collaborators_create
export def "projects-collaborators-create" [
  namespace: string
  project: string
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
  member: string # Project member username.
  --owner: oneof<nothing, bool> # Project owner. Defaults to false.
  permissions: string@permissions-completer # Permissions assigned to collaborator.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{namespace}/projects/{project}/collaborators/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}]
    body: {content_type: "application/json", kind: json, fields: [{name: member, var: member}, {name: owner, var: owner}, {name: permissions, var: permissions}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: bearer
  } {
    namespace: $namespace, project: $project, member: $member, owner: $owner, permissions: $permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a project collaborator
#
# DELETE /v1/{namespace}/projects/{project}/collaborators/{collaborator}/
# operationId: projects_collaborators_delete
export def "projects-collaborators-delete" [
  namespace: string
  project: string
  collaborator: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/{namespace}/projects/{project}/collaborators/{collaborator}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: collaborator, var: collaborator}]
    accept: ["application/json", "text/html"]
    ok: [204]
    auth: bearer
  } {
    namespace: $namespace, project: $project, collaborator: $collaborator
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a project collaborator
#
# GET /v1/{namespace}/projects/{project}/collaborators/{collaborator}/
# Returns: record<email: string, first_name: string, id: string, joined: string, last_name: string, owner: bool, permissions: list<string>, project: string, user: string, username: string>
# operationId: projects_collaborators_read
export def "projects-collaborators-read" [
  namespace: string
  project: string
  collaborator: string
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
    path: "/v1/{namespace}/projects/{project}/collaborators/{collaborator}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: collaborator, var: collaborator}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, collaborator: $collaborator
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update project collaborator
#
# PATCH /v1/{namespace}/projects/{project}/collaborators/{collaborator}/
# Returns: record<email: string, first_name: string, id: string, joined: string, last_name: string, owner: bool, permissions: list<string>, project: string, user: string, username: string>
# operationId: projects_collaborators_update
export def "projects-collaborators-update" [
  namespace: string
  project: string
  collaborator: string
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
  member: string # Project member username.
  --owner: oneof<nothing, bool> # Project owner. Defaults to false.
  permissions: string@permissions-completer # Permissions assigned to collaborator.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/{namespace}/projects/{project}/collaborators/{collaborator}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: collaborator, var: collaborator}]
    body: {content_type: "application/json", kind: json, fields: [{name: member, var: member}, {name: owner, var: owner}, {name: permissions, var: permissions}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, collaborator: $collaborator, member: $member, owner: $owner, permissions: $permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve deployments
#
# GET /v1/{namespace}/projects/{project}/deployments/
# Returns: table<config: record<files: list, handler: string>, created_at: string, created_by: string, framework: string, id: string, name: string, project: string, runtime: string>
# operationId: projects_deployments_list
export def "projects-deployments-list" [
  namespace: string
  project: string
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
  --limit: string # Limit results when getting deployment list.
  --offset: string # Offset results when getting deployment list.
  --name: string # Server name.
  --ordering: string # Ordering option when getting deployment list.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{namespace}/projects/{project}/deployments/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: name, var: name}, {name: ordering, var: ordering}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, limit: $limit, offset: $offset, name: $name, ordering: $ordering
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new deployment
#
# POST /v1/{namespace}/projects/{project}/deployments/
# Returns: record<config: record<files: list<string>, handler: string>, created_at: string, created_by: string, framework: string, id: string, name: string, project: string, runtime: string>
# operationId: projects_deployments_create
export def "projects-deployments-create" [
  namespace: string
  project: string
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
  config: record # shape: {files?: list<string>, handler?: string}
  framework: string@framework-completer # Framework that the deployment will have access to.
  name: string # Deployment name.
  runtime: string@runtime-completer # Language runtime the deployment will use.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{namespace}/projects/{project}/deployments/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}]
    body: {content_type: "application/json", kind: json, fields: [{name: config, var: config}, {name: framework, var: framework}, {name: name, var: name}, {name: runtime, var: runtime}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: bearer
  } {
    namespace: $namespace, project: $project, config: $config, framework: $framework, name: $name, runtime: $runtime
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a deployment
#
# DELETE /v1/{namespace}/projects/{project}/deployments/{deployment}/
# operationId: projects_deployment_delete
export def "projects-deployment-delete" [
  namespace: string
  project: string
  deployment: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/{namespace}/projects/{project}/deployments/{deployment}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: deployment, var: deployment}]
    accept: ["application/json", "text/html"]
    ok: [204]
    auth: bearer
  } {
    namespace: $namespace, project: $project, deployment: $deployment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a deployment
#
# GET /v1/{namespace}/projects/{project}/deployments/{deployment}/
# Returns: record<config: record<files: list<string>, handler: string>, created_at: string, created_by: string, framework: string, id: string, name: string, project: string, runtime: string>
# operationId: projects_deployments_read
export def "projects-deployments-read" [
  namespace: string
  project: string
  deployment: string
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
    path: "/v1/{namespace}/projects/{project}/deployments/{deployment}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: deployment, var: deployment}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, deployment: $deployment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a deployment
#
# PATCH /v1/{namespace}/projects/{project}/deployments/{deployment}/
# Returns: record<config: record<files: list<string>, handler: string>, created_at: string, created_by: string, framework: string, id: string, name: string, project: string, runtime: string>
# operationId: projects_deployments_update
export def "projects-deployments-update" [
  namespace: string
  project: string
  deployment: string
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
  config: record # shape: {files?: list<string>, handler?: string}
  framework: string@framework-completer # Framework that the deployment will have access to.
  name: string # Deployment name.
  runtime: string@runtime-completer # Language runtime the deployment will use.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/{namespace}/projects/{project}/deployments/{deployment}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: deployment, var: deployment}]
    body: {content_type: "application/json", kind: json, fields: [{name: config, var: config}, {name: framework, var: framework}, {name: name, var: name}, {name: runtime, var: runtime}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, deployment: $deployment, config: $config, framework: $framework, name: $name, runtime: $runtime
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replace a deployment
#
# PUT /v1/{namespace}/projects/{project}/deployments/{deployment}/
# Returns: record<config: record<files: list<string>, handler: string>, created_at: string, created_by: string, framework: string, id: string, name: string, project: string, runtime: string>
# operationId: projects_deployments_replace
export def "projects-deployments-replace" [
  namespace: string
  project: string
  deployment: string
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
  config: record # shape: {files?: list<string>, handler?: string}
  framework: string@framework-completer # Framework that the deployment will have access to.
  name: string # Deployment name.
  runtime: string@runtime-completer # Language runtime the deployment will use.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/{namespace}/projects/{project}/deployments/{deployment}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: deployment, var: deployment}]
    body: {content_type: "application/json", kind: json, fields: [{name: config, var: config}, {name: framework, var: framework}, {name: name, var: name}, {name: runtime, var: runtime}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, deployment: $deployment, config: $config, framework: $framework, name: $name, runtime: $runtime
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Deploy an existing model
#
# POST /v1/{namespace}/projects/{project}/deployments/{deployment}/deploy/
# operationId: projects_deployments_deploy
export def "projects-deployments-deploy" [
  namespace: string
  project: string
  deployment: string
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
]: nothing -> any {
  http-request {
    method: post
    path: "/v1/{namespace}/projects/{project}/deployments/{deployment}/deploy/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: deployment, var: deployment}]
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: bearer
  } {
    namespace: $namespace, project: $project, deployment: $deployment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get project files
#
# GET /v1/{namespace}/projects/{project}/project_files/
# Returns: table<content: string, id: string, name: string, path: string, project: string>
# operationId: projects_project_files_list
export def "projects-project-files-list" [
  namespace: string
  project: string
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
  --limit: string # Limit when getting project file list.
  --offset: string # Offset when getting project file list.
  --ordering: string # Ordering of list values when getting project file list.
  --filename: string # Exact file name, relative to the project root. If no such file is found, an empty list will be returned.
  --content: string # Determines whether or not content is returned as base64. Defaults to false.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{namespace}/projects/{project}/project_files/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: ordering, var: ordering}, {name: filename, var: filename}, {name: content, var: content}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, limit: $limit, offset: $offset, ordering: $ordering, filename: $filename, content: $content
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create project files
#
# POST /v1/{namespace}/projects/{project}/project_files/
# Returns: record<content: string, id: string, name: string, path: string, project: string>
# operationId: projects_project_files_create
export def "projects-project-files-create" [
  namespace: string
  project: string
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
  --file: path # File to send, to create new file. This parameter is only used with form data and may include multiple files.
  --base64-data: string # Fila data, represented as base64.
  --name: string # File name. May include path when creating file with base64 field.
  --path: string # File path. Defaults to (/).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{namespace}/projects/{project}/project_files/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}, {name: base64_data, var: base64_data}, {name: name, var: name}, {name: path, var: path}], files: [file]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: bearer
  } {
    namespace: $namespace, project: $project, file: $file, base64_data: $base64_data, name: $name, path: $path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a project file
#
# DELETE /v1/{namespace}/projects/{project}/project_files/{id}/
# operationId: projects_project_files_delete
export def "projects-project-files-delete" [
  namespace: string
  project: string
  id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/{namespace}/projects/{project}/project_files/{id}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [204]
    auth: bearer
  } {
    namespace: $namespace, project: $project, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a project file
#
# GET /v1/{namespace}/projects/{project}/project_files/{id}/
# Returns: record<content: string, id: string, name: string, path: string, project: string>
# operationId: projects_project_files_read
export def "projects-project-files-read" [
  namespace: string
  project: string
  id: string
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
  --content: string # Determines whether or not content is returned as base64. Defaults to false.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{namespace}/projects/{project}/project_files/{id}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: id, var: id}]
    query: [{name: content, var: content}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, id: $id, content: $content
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a project file
#
# PATCH /v1/{namespace}/projects/{project}/project_files/{id}/
# Returns: record<content: string, id: string, name: string, path: string, project: string>
# operationId: projects_project_files_update
export def "projects-project-files-update" [
  namespace: string
  project: string
  id: string
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
  --file: path # File to send, to create new file. This parameter is only used with form data and may include multiple files.
  --base64-data: string # Fila data, represented as base64.
  --name: string # File name. May include path when creating file with base64 field.
  --path: string # File path. Defaults to (/).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/{namespace}/projects/{project}/project_files/{id}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: id, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}, {name: base64_data, var: base64_data}, {name: name, var: name}, {name: path, var: path}], files: [file]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, id: $id, file: $file, base64_data: $base64_data, name: $name, path: $path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replace a project file
#
# PUT /v1/{namespace}/projects/{project}/project_files/{id}/
# Returns: record<content: string, id: string, name: string, path: string, project: string>
# operationId: projects_project_files_replace
export def "projects-project-files-replace" [
  namespace: string
  project: string
  id: string
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
  --file: path # File to send, to create new file. This parameter is only used with form data and may include multiple files.
  --base64-data: string # Fila data, represented as base64.
  --name: string # File name. May include path when creating file with base64 field.
  --path: string # File path. Defaults to (/).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/{namespace}/projects/{project}/project_files/{id}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: id, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}, {name: base64_data, var: base64_data}, {name: name, var: name}, {name: path, var: path}], files: [file]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, id: $id, file: $file, base64_data: $base64_data, name: $name, path: $path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve servers
#
# GET /v1/{namespace}/projects/{project}/servers/
# Returns: table<config: record, connected: list<string>, created_at: string, created_by: string, endpoint: string, host: string, id: string, image_name: string, logs_url: string, name: string, project: string, server_size: string, startup_script: string, status: string, status_url: string>
# operationId: projects_servers_list
export def "projects-servers-list" [
  namespace: string
  project: string
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
  --limit: string # Limit results when getting server list.
  --offset: string # Offset results when getting server list.
  --name: string # Server name.
  --ordering: string # Ordering option when getting server list.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{namespace}/projects/{project}/servers/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: name, var: name}, {name: ordering, var: ordering}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, limit: $limit, offset: $offset, name: $name, ordering: $ordering
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new server
#
# POST /v1/{namespace}/projects/{project}/servers/
# Returns: record<config: record, connected: list<string>, created_at: string, created_by: string, endpoint: string, host: string, id: string, image_name: string, logs_url: string, name: string, project: string, server_size: string, startup_script: string, status: string, status_url: string>
# operationId: projects_servers_create
export def "projects-servers-create" [
  namespace: string
  project: string
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
  --config: record # shape: {command?: string, function?: string, script?: string, type?: "jupyter"|"restful"|"cron"}
  --connected: list<string> # Array of other servers the server is connected to.
  --host: string # External host IPv4 address or hostname.
  --image-name: string # Image name.
  name: string # Server name.
  --server-size: string # Server size unique identifier.
  --startup-script: string # Startup script to run when launching server.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{namespace}/projects/{project}/servers/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}]
    body: {content_type: "application/json", kind: json, fields: [{name: config, var: config}, {name: connected, var: connected}, {name: host, var: host}, {name: image_name, var: image_name}, {name: name, var: name}, {name: server_size, var: server_size}, {name: startup_script, var: startup_script}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: bearer
  } {
    namespace: $namespace, project: $project, config: $config, connected: $connected, host: $host, image_name: $image_name, name: $name, server_size: $server_size, startup_script: $startup_script
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve server statuses
#
# GET /v1/{namespace}/projects/{project}/servers/statuses/
# Returns: table<id: string, status: string>
# operationId: projects_servers_statuses
export def "projects-servers-statuses" [
  namespace: string
  project: string
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
    path: "/v1/{namespace}/projects/{project}/servers/statuses/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a server
#
# DELETE /v1/{namespace}/projects/{project}/servers/{server}/
# operationId: projects_servers_delete
export def "projects-servers-delete" [
  namespace: string
  project: string
  server: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/{namespace}/projects/{project}/servers/{server}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: server, var: server}]
    accept: ["application/json", "text/html"]
    ok: [204]
    auth: bearer
  } {
    namespace: $namespace, project: $project, server: $server
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a server
#
# GET /v1/{namespace}/projects/{project}/servers/{server}/
# Returns: record<config: record, connected: list<string>, created_at: string, created_by: string, endpoint: string, host: string, id: string, image_name: string, logs_url: string, name: string, project: string, server_size: string, startup_script: string, status: string, status_url: string>
# operationId: projects_servers_read
export def "projects-servers-read" [
  namespace: string
  project: string
  server: string
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
    path: "/v1/{namespace}/projects/{project}/servers/{server}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: server, var: server}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, server: $server
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a server
#
# PATCH /v1/{namespace}/projects/{project}/servers/{server}/
# Returns: record<config: record, connected: list<string>, created_at: string, created_by: string, endpoint: string, host: string, id: string, image_name: string, logs_url: string, name: string, project: string, server_size: string, startup_script: string, status: string, status_url: string>
# operationId: projects_servers_update
export def "projects-servers-update" [
  namespace: string
  project: string
  server: string
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
  --config: record # shape: {command?: string, function?: string, script?: string, type?: "jupyter"|"restful"|"cron"}
  --connected: list<string> # Array of other servers the server is connected to.
  --host: string # External host IPv4 address or hostname.
  --image-name: string # Image name.
  name: string # Server name.
  --server-size: string # Server size unique identifier.
  --startup-script: string # Startup script to run when launching server.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/{namespace}/projects/{project}/servers/{server}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: server, var: server}]
    body: {content_type: "application/json", kind: json, fields: [{name: config, var: config}, {name: connected, var: connected}, {name: host, var: host}, {name: image_name, var: image_name}, {name: name, var: name}, {name: server_size, var: server_size}, {name: startup_script, var: startup_script}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, server: $server, config: $config, connected: $connected, host: $host, image_name: $image_name, name: $name, server_size: $server_size, startup_script: $startup_script
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replace a server
#
# PUT /v1/{namespace}/projects/{project}/servers/{server}/
# Returns: record<config: record, connected: list<string>, created_at: string, created_by: string, endpoint: string, host: string, id: string, image_name: string, logs_url: string, name: string, project: string, server_size: string, startup_script: string, status: string, status_url: string>
# operationId: projects_servers_replace
export def "projects-servers-replace" [
  namespace: string
  project: string
  server: string
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
  --config: record # shape: {command?: string, function?: string, script?: string, type?: "jupyter"|"restful"|"cron"}
  --connected: list<string> # Array of other servers the server is connected to.
  --host: string # External host IPv4 address or hostname.
  --image-name: string # Image name.
  name: string # Server name.
  --server-size: string # Server size unique identifier.
  --startup-script: string # Startup script to run when launching server.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/{namespace}/projects/{project}/servers/{server}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: server, var: server}]
    body: {content_type: "application/json", kind: json, fields: [{name: config, var: config}, {name: connected, var: connected}, {name: host, var: host}, {name: image_name, var: image_name}, {name: name, var: name}, {name: server_size, var: server_size}, {name: startup_script, var: startup_script}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, server: $server, config: $config, connected: $connected, host: $host, image_name: $image_name, name: $name, server_size: $server_size, startup_script: $startup_script
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get server API key
#
# GET /v1/{namespace}/projects/{project}/servers/{server}/api-key/
# Returns: record<token: string>
# operationId: projects_servers_api-key
export def "projects-servers-api-key" [
  namespace: string
  project: string
  server: string
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
    path: "/v1/{namespace}/projects/{project}/servers/{server}/api-key/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: server, var: server}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, server: $server
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Server api key validation
#
# POST /v1/{namespace}/projects/{project}/servers/{server}/auth/
# operationId: projects_servers_auth
export def "projects-servers-auth" [
  namespace: string
  project: string
  server: string
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
]: nothing -> any {
  http-request {
    method: post
    path: "/v1/{namespace}/projects/{project}/servers/{server}/auth/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: server, var: server}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, server: $server
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new server's run statistics
#
# POST /v1/{namespace}/projects/{project}/servers/{server}/run-stats/
# Returns: record<exit_code: int, id: string, server: string, size: int, stacktrace: string, start: string, stop: string>
# operationId: projects_servers_run-stats_create
export def "projects-servers-run-stats-create" [
  namespace: string
  project: string
  server: string
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
  --exit-code: int # Server exit code.
  --size: int # Server size.
  --stacktrace: string # Server stacktrace.
  --start: string # Server start.
  --stop: string # Server stop.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{namespace}/projects/{project}/servers/{server}/run-stats/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: server, var: server}]
    body: {content_type: "application/json", kind: json, fields: [{name: exit_code, var: exit_code}, {name: size, var: size}, {name: stacktrace, var: stacktrace}, {name: start, var: start}, {name: stop, var: stop}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: bearer
  } {
    namespace: $namespace, project: $project, server: $server, exit_code: $exit_code, size: $size, stacktrace: $stacktrace, start: $start, stop: $stop
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a server's statistics
#
# DELETE /v1/{namespace}/projects/{project}/servers/{server}/run-stats/{id}/
# operationId: projects_servers_run-stats_delete
export def "projects-servers-run-stats-delete" [
  namespace: string
  project: string
  server: string
  id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/{namespace}/projects/{project}/servers/{server}/run-stats/{id}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: server, var: server}, {name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [204]
    auth: bearer
  } {
    namespace: $namespace, project: $project, server: $server, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve statistics for a server
#
# GET /v1/{namespace}/projects/{project}/servers/{server}/run-stats/{id}/
# Returns: record<exit_code: int, id: string, server: string, size: int, stacktrace: string, start: string, stop: string>
# operationId: projects_servers_run-stats_read
export def "projects-servers-run-stats-read" [
  namespace: string
  project: string
  server: string
  id: string
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
    path: "/v1/{namespace}/projects/{project}/servers/{server}/run-stats/{id}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: server, var: server}, {name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, server: $server, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a server's statistics
#
# PATCH /v1/{namespace}/projects/{project}/servers/{server}/run-stats/{id}/
# Returns: record<exit_code: int, id: string, server: string, size: int, stacktrace: string, start: string, stop: string>
# operationId: projects_servers_run-stats_update
export def "projects-servers-run-stats-update" [
  namespace: string
  project: string
  server: string
  id: string
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
  --exit-code: int # Server exit code.
  --size: int # Server size.
  --stacktrace: string # Server stacktrace.
  --start: string # Server start.
  --stop: string # Server stop.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/{namespace}/projects/{project}/servers/{server}/run-stats/{id}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: server, var: server}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: exit_code, var: exit_code}, {name: size, var: size}, {name: stacktrace, var: stacktrace}, {name: start, var: start}, {name: stop, var: stop}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, server: $server, id: $id, exit_code: $exit_code, size: $size, stacktrace: $stacktrace, start: $start, stop: $stop
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replace a server's statistics
#
# PUT /v1/{namespace}/projects/{project}/servers/{server}/run-stats/{id}/
# Returns: record<exit_code: int, id: string, server: string, size: int, stacktrace: string, start: string, stop: string>
# operationId: projects_servers_run-stats_replace
export def "projects-servers-run-stats-replace" [
  namespace: string
  project: string
  server: string
  id: string
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
  --exit-code: int # Server exit code.
  --size: int # Server size.
  --stacktrace: string # Server stacktrace.
  --start: string # Server start.
  --stop: string # Server stop.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/{namespace}/projects/{project}/servers/{server}/run-stats/{id}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: server, var: server}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: exit_code, var: exit_code}, {name: size, var: size}, {name: stacktrace, var: stacktrace}, {name: start, var: start}, {name: stop, var: stop}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, server: $server, id: $id, exit_code: $exit_code, size: $size, stacktrace: $stacktrace, start: $start, stop: $stop
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get SSH Tunnels associated to a server
#
# GET /v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/
# Returns: table<endpoint: string, host: string, id: string, local_port: int, name: string, remote_port: int, server: string, username: string>
# operationId: projects_servers_ssh-tunnels_list
export def "projects-servers-ssh-tunnels-list" [
  namespace: string
  project: string
  server: string
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
  --limit: string # Limit retrieved items.
  --offset: string # Offset retrieved items.
  --ordering: string # Order retrieved items.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: server, var: server}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: ordering, var: ordering}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, server: $server, limit: $limit, offset: $offset, ordering: $ordering
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create SSH Tunnel associated to a server
#
# POST /v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/
# Returns: record<endpoint: string, host: string, id: string, local_port: int, name: string, remote_port: int, server: string, username: string>
# operationId: projects_servers_ssh-tunnels_create
export def "projects-servers-ssh-tunnels-create" [
  namespace: string
  project: string
  server: string
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
  endpoint: string # SSH tunnel endpoint.
  host: string # SSH tunnel host.
  local_port: int # SSH tunnel local port.
  name: string # SSH tunnel name.
  remote_port: int # SSH tunnel remote port.
  username: string # User name to establish SSH tunnel.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: server, var: server}]
    body: {content_type: "application/json", kind: json, fields: [{name: endpoint, var: endpoint}, {name: host, var: host}, {name: local_port, var: local_port}, {name: name, var: name}, {name: remote_port, var: remote_port}, {name: username, var: username}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: bearer
  } {
    namespace: $namespace, project: $project, server: $server, endpoint: $endpoint, host: $host, local_port: $local_port, name: $name, remote_port: $remote_port, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an SSH Tunnel associated to a server
#
# DELETE /v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/{tunnel}/
# operationId: projects_servers_ssh-tunnels_delete
export def "projects-servers-ssh-tunnels-delete" [
  namespace: string
  project: string
  server: string
  tunnel: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/{tunnel}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: server, var: server}, {name: tunnel, var: tunnel}]
    accept: ["application/json", "text/html"]
    ok: [204]
    auth: bearer
  } {
    namespace: $namespace, project: $project, server: $server, tunnel: $tunnel
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get an SSH Tunnel associated to a server
#
# GET /v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/{tunnel}/
# Returns: record<endpoint: string, host: string, id: string, local_port: int, name: string, remote_port: int, server: string, username: string>
# operationId: projects_servers_ssh-tunnels_read
export def "projects-servers-ssh-tunnels-read" [
  namespace: string
  project: string
  server: string
  tunnel: string
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
    path: "/v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/{tunnel}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: server, var: server}, {name: tunnel, var: tunnel}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, server: $server, tunnel: $tunnel
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update an SSH Tunnel associated to a server
#
# PATCH /v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/{tunnel}/
# Returns: record<endpoint: string, host: string, id: string, local_port: int, name: string, remote_port: int, server: string, username: string>
# operationId: projects_servers_ssh-tunnels_update
export def "projects-servers-ssh-tunnels-update" [
  namespace: string
  project: string
  server: string
  tunnel: string
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
  endpoint: string # SSH tunnel endpoint.
  host: string # SSH tunnel host.
  local_port: int # SSH tunnel local port.
  name: string # SSH tunnel name.
  remote_port: int # SSH tunnel remote port.
  username: string # User name to establish SSH tunnel.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/{tunnel}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: server, var: server}, {name: tunnel, var: tunnel}]
    body: {content_type: "application/json", kind: json, fields: [{name: endpoint, var: endpoint}, {name: host, var: host}, {name: local_port, var: local_port}, {name: name, var: name}, {name: remote_port, var: remote_port}, {name: username, var: username}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, server: $server, tunnel: $tunnel, endpoint: $endpoint, host: $host, local_port: $local_port, name: $name, remote_port: $remote_port, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replace SSH Tunnel associated to a server
#
# PUT /v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/{tunnel}/
# Returns: record<endpoint: string, host: string, id: string, local_port: int, name: string, remote_port: int, server: string, username: string>
# operationId: projects_servers_ssh-tunnels_replace
export def "projects-servers-ssh-tunnels-replace" [
  namespace: string
  project: string
  server: string
  tunnel: string
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
  endpoint: string # SSH tunnel endpoint.
  host: string # SSH tunnel host.
  local_port: int # SSH tunnel local port.
  name: string # SSH tunnel name.
  remote_port: int # SSH tunnel remote port.
  username: string # User name to establish SSH tunnel.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/{tunnel}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: server, var: server}, {name: tunnel, var: tunnel}]
    body: {content_type: "application/json", kind: json, fields: [{name: endpoint, var: endpoint}, {name: host, var: host}, {name: local_port, var: local_port}, {name: name, var: name}, {name: remote_port, var: remote_port}, {name: username, var: username}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, server: $server, tunnel: $tunnel, endpoint: $endpoint, host: $host, local_port: $local_port, name: $name, remote_port: $remote_port, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Start a server
#
# POST /v1/{namespace}/projects/{project}/servers/{server}/start/
# operationId: projects_servers_start
export def "projects-servers-start" [
  namespace: string
  project: string
  server: string
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
]: nothing -> any {
  http-request {
    method: post
    path: "/v1/{namespace}/projects/{project}/servers/{server}/start/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: server, var: server}]
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: bearer
  } {
    namespace: $namespace, project: $project, server: $server
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a server's statistics
#
# DELETE /v1/{namespace}/projects/{project}/servers/{server}/stats/{id}/
# operationId: projects_servers_stats_delete
export def "projects-servers-stats-delete" [
  namespace: string
  project: string
  server: string
  id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/{namespace}/projects/{project}/servers/{server}/stats/{id}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: server, var: server}, {name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [204]
    auth: bearer
  } {
    namespace: $namespace, project: $project, server: $server, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a server's statistics
#
# GET /v1/{namespace}/projects/{project}/servers/{server}/stats/{id}/
# Returns: record<id: string, server: string, size: int, start: string, stop: string>
# operationId: projects_servers_stats_read
export def "projects-servers-stats-read" [
  namespace: string
  project: string
  server: string
  id: string
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
    path: "/v1/{namespace}/projects/{project}/servers/{server}/stats/{id}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: server, var: server}, {name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, server: $server, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a server's statistics
#
# PATCH /v1/{namespace}/projects/{project}/servers/{server}/stats/{id}/
# Returns: record<id: string, server: string, size: int, start: string, stop: string>
# operationId: projects_servers_stats_update
export def "projects-servers-stats-update" [
  namespace: string
  project: string
  server: string
  id: string
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
  --body-id: list<string> # id field errors. (spec name: id)
  --non-field-errors: list<string> # Errors not connected to any field.
  --size: list<string> # size field errors.
  --start: list<string> # start field errors.
  --stop: list<string> # stop field errors.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/{namespace}/projects/{project}/servers/{server}/stats/{id}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: server, var: server}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: body_id}, {name: non_field_errors, var: non_field_errors}, {name: size, var: size}, {name: start, var: start}, {name: stop, var: stop}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, server: $server, id: $id, body_id: $body_id, non_field_errors: $non_field_errors, size: $size, start: $start, stop: $stop
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replace a server's statistics
#
# PUT /v1/{namespace}/projects/{project}/servers/{server}/stats/{id}/
# Returns: record<id: string, server: string, size: int, start: string, stop: string>
# operationId: projects_servers_stats_replace
export def "projects-servers-stats-replace" [
  namespace: string
  project: string
  server: string
  id: string
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
  --body-id: list<string> # id field errors. (spec name: id)
  --non-field-errors: list<string> # Errors not connected to any field.
  --size: list<string> # size field errors.
  --start: list<string> # start field errors.
  --stop: list<string> # stop field errors.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/{namespace}/projects/{project}/servers/{server}/stats/{id}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: server, var: server}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: body_id}, {name: non_field_errors, var: non_field_errors}, {name: size, var: size}, {name: start, var: start}, {name: stop, var: stop}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, server: $server, id: $id, body_id: $body_id, non_field_errors: $non_field_errors, size: $size, start: $start, stop: $stop
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Stop a server
#
# POST /v1/{namespace}/projects/{project}/servers/{server}/stop/
# operationId: projects_servers_stop
export def "projects-servers-stop" [
  namespace: string
  project: string
  server: string
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
]: nothing -> any {
  http-request {
    method: post
    path: "/v1/{namespace}/projects/{project}/servers/{server}/stop/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: server, var: server}]
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: bearer
  } {
    namespace: $namespace, project: $project, server: $server
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve server triggers
#
# GET /v1/{namespace}/projects/{project}/servers/{server}/triggers/
# Returns: table<id: string, name: string, operation: string, webhook: record<payload: record, url: string>>
# operationId: service_trigger_list
export def "service-trigger-list" [
  namespace: string
  project: string
  server: string
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
  --name: string # Trigger name.
  --limit: string # Limit when getting triggers.
  --offset: string # Offset when getting triggers.
  --ordering: string # Ordering when getting triggers.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{namespace}/projects/{project}/servers/{server}/triggers/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: server, var: server}]
    query: [{name: name, var: name}, {name: limit, var: limit}, {name: offset, var: offset}, {name: ordering, var: ordering}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, server: $server, name: $name, limit: $limit, offset: $offset, ordering: $ordering
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new server trigger
#
# POST /v1/{namespace}/projects/{project}/servers/{server}/triggers/
# Returns: record<id: string, name: string, operation: string, webhook: record<payload: record, url: string>>
# operationId: service_trigger_create
export def "service-trigger-create" [
  namespace: string
  project: string
  server: string
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
  --name: string # Name of server action.
  --operation: string@operation-completer # Manage server state. Starting a server changes state from Pending to Running. Terminating a server changes state from Running to Terminated. Stopping a server changes state from Running to Stopped. If the action results in Error, status will change to Error.
  --webhook: record # shape: {payload?: record, url: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{namespace}/projects/{project}/servers/{server}/triggers/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: server, var: server}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: operation, var: operation}, {name: webhook, var: webhook}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: bearer
  } {
    namespace: $namespace, project: $project, server: $server, name: $name, operation: $operation, webhook: $webhook
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a server trigger
#
# DELETE /v1/{namespace}/projects/{project}/servers/{server}/triggers/{trigger}/
# operationId: service_trigger_delete
export def "service-trigger-delete" [
  namespace: string
  project: string
  server: string
  trigger: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/{namespace}/projects/{project}/servers/{server}/triggers/{trigger}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: server, var: server}, {name: trigger, var: trigger}]
    accept: ["application/json", "text/html"]
    ok: [204]
    auth: bearer
  } {
    namespace: $namespace, project: $project, server: $server, trigger: $trigger
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a server trigger
#
# GET /v1/{namespace}/projects/{project}/servers/{server}/triggers/{trigger}/
# Returns: record<id: string, name: string, operation: string, webhook: record<payload: record, url: string>>
# operationId: service_trigger_read
export def "service-trigger-read" [
  namespace: string
  project: string
  server: string
  trigger: string
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
    path: "/v1/{namespace}/projects/{project}/servers/{server}/triggers/{trigger}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: server, var: server}, {name: trigger, var: trigger}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, server: $server, trigger: $trigger
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a server trigger
#
# PATCH /v1/{namespace}/projects/{project}/servers/{server}/triggers/{trigger}/
# Returns: record<id: string, name: string, operation: string, webhook: record<payload: record, url: string>>
# operationId: service_trigger_update
export def "service-trigger-update" [
  namespace: string
  project: string
  server: string
  trigger: string
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
  --name: string # Name of server action.
  --operation: string@operation-completer # Manage server state. Starting a server changes state from Pending to Running. Terminating a server changes state from Running to Terminated. Stopping a server changes state from Running to Stopped. If the action results in Error, status will change to Error.
  --webhook: record # shape: {payload?: record, url: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/{namespace}/projects/{project}/servers/{server}/triggers/{trigger}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: server, var: server}, {name: trigger, var: trigger}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: operation, var: operation}, {name: webhook, var: webhook}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, server: $server, trigger: $trigger, name: $name, operation: $operation, webhook: $webhook
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replace a server trigger
#
# PUT /v1/{namespace}/projects/{project}/servers/{server}/triggers/{trigger}/
# Returns: record<id: string, name: string, operation: string, webhook: record<payload: record, url: string>>
# operationId: service_trigger_replace
export def "service-trigger-replace" [
  namespace: string
  project: string
  server: string
  trigger: string
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
  --name: string # Name of server action.
  --operation: string@operation-completer # Manage server state. Starting a server changes state from Pending to Running. Terminating a server changes state from Running to Terminated. Stopping a server changes state from Running to Stopped. If the action results in Error, status will change to Error.
  --webhook: record # shape: {payload?: record, url: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/{namespace}/projects/{project}/servers/{server}/triggers/{trigger}/"
    path_params: [{name: namespace, var: namespace}, {name: project, var: project}, {name: server, var: server}, {name: trigger, var: trigger}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: operation, var: operation}, {name: webhook, var: webhook}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, project: $project, server: $server, trigger: $trigger, name: $name, operation: $operation, webhook: $webhook
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a search results
#
# GET /v1/{namespace}/search/
# Returns: list<record>
# operationId: search
export def "search" [
  namespace: string
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
  --q: string # Search string. (required)
  --type: string@type-completer # Limit results to specific types.
  --limit: string # Limit data when getting items.
  --offset: string # Offset data when getting items.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{namespace}/search/"
    path_params: [{name: namespace, var: namespace}]
    query: [{name: q, var: q, required: true}, {name: type, var: type}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, q: $q, type: $type, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
