# Auto-generated client for ExaVault v2.0
# Source: https://api.apis.guru/v2/specs/exavault.com/2.0/openapi.json
# Auth: --token flag or $env.EXAVAULT_TOKEN

const CLIENT = {
  base_url: "https://accountname.exavault.com/api/v2"
  token_env_var: "EXAVAULT_TOKEN"
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

def base-url-completer [] { ["https://accountname.exavault.com/api/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def include-completer [] { ["share"] }
def type-completer [] { ["file" "file_drop" "folder" "send_receipt" "share_receipt" "shared_folder"] }
def include-completer-1 [] { ["resource" "share" "user"] }
def action-completer [] { ["all" "connect" "delete" "download" "upload"] }
def action-completer-1 [] { ["all" "delete" "download" "upload"] }
def type-completer-1 [] { ["file" "folder"] }
def accept-completer [] { ["application/octet-stream" "application/zip"] }
def size-completer [] { ["large" "medium" "small"] }
def scope-completer [] { ["active" "all" "currentUser"] }
def sort-completer [] { ["-created" "created"] }
def type-completer-2 [] { ["receive" "send" "shared_folder"] }
def role-completer [] { ["admin" "user"] }
def response-version-completer [] { ["v1" "v2"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-account: "record<data: record<attributes: record<accountName: string, accountOnboarding: bool, allowedIp: list, branding: bool, brandingSettings: record, clientId: int, complexPasswords: bool, created: string, customDomain: bool, customSignature: string, externalDomains: list, maxUsers: int, modified: string, planDetails: record, quota: record, secureOnly: bool, showReferralLinks: bool, status: int, userCount: int, welcomeEmailContent: string, welcomeEmailSubject: string>, id: int, relationships: record<masterUser: record>, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int>"
    update-account: "record<data: record<attributes: record<accountName: string, accountOnboarding: bool, allowedIp: list, branding: bool, brandingSettings: record, clientId: int, complexPasswords: bool, created: string, customDomain: bool, customSignature: string, externalDomains: list, maxUsers: int, modified: string, planDetails: record, quota: record, secureOnly: bool, showReferralLinks: bool, status: int, userCount: int, welcomeEmailContent: string, welcomeEmailSubject: string>, id: int, relationships: record<masterUser: record>, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int>"
    get-session-logs: "record<data: table<attributes: record, id: int, type: string>, responseStatus: int, returnedResults: int, totalResults: int>"
    get-webhook-logs: "record<data: table<attributes: any, id: int, type: string>, responseStatus: int, returnedResults: int, totalResults: int>"
    get-email-lists: "record<data: table<attributes: record, id: int, relationships: record, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int, returnedResults: int, totalResults: int>"
    add-email-list: "record<data: record<attributes: record<created: string, emails: list, modified: string, name: string>, id: int, relationships: record<ownerUser: record>, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int>"
    delete-email-list-by-id: "record<data: list<string>, responseStatus: int>"
    get-email-list-by-id: "record<data: record<attributes: record<created: string, emails: list, modified: string, name: string>, id: int, relationships: record<ownerUser: record>, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int>"
    update-email-list-by-id: "record<data: record<attributes: record<created: string, emails: list, modified: string, name: string>, id: int, relationships: record<ownerUser: record>, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int>"
    send-referral-email: "record<data: list<string>, responseStatus: int>"
    send-welcome-email: "record<data: list<string>, responseStatus: int>"
    get-form-by-share-hash: "record<data: record<attributes: record<cssStyles: string, elements: list, formDescription: string, submitButtonText: string, successMessage: string>, id: int, relationships: record<share: record>, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int>"
    delete-form-message-by-id: "record<data: list<string>, responseStatus: int>"
    get-form-entries: "record<data: table<attributes: record, id: int, type: string>, responseStatus: int, returnedResults: int, totalResults: int>"
    get-form-by-id: "record<data: record<attributes: record<cssStyles: string, elements: list, formDescription: string, submitButtonText: string, successMessage: string>, id: int, relationships: record<share: record>, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int>"
    update-form-by-id: "record<data: record<attributes: record<cssStyles: string, elements: list, formDescription: string, submitButtonText: string, successMessage: string>, id: int, relationships: record<share: record>, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int>"
    list-notifications: "record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int, returnedResults: int, totalResults: int>"
    add-notification: "record<data: record<attributes: record<action: string, created: string, message: string, modified: string, name: string, path: string, readableDescription: string, readableDescriptionWithoutPath: string, recipients: list, sendEmail: bool, shareId: string, type: string, userId: string, usernames: list>, id: int, relationships: record<ownerUser: record, resource: record, share: record>, type: string>, included: list<any>, responseStatus: int>"
    delete-notification-by-id: "record<data: list<string>, responseStatus: int>"
    get-notification-by-id: "record<data: record<attributes: record<action: string, created: string, message: string, modified: string, name: string, path: string, readableDescription: string, readableDescriptionWithoutPath: string, recipients: list, sendEmail: bool, shareId: string, type: string, userId: string, usernames: list>, id: int, relationships: record<ownerUser: record, resource: record, share: record>, type: string>, included: list<any>, responseStatus: int>"
    update-notification-by-id: "record<data: record<attributes: record<action: string, created: string, message: string, modified: string, name: string, path: string, readableDescription: string, readableDescriptionWithoutPath: string, recipients: list, sendEmail: bool, shareId: string, type: string, userId: string, usernames: list>, id: int, relationships: record<ownerUser: record, resource: record, share: record>, type: string>, included: list<any>, responseStatus: int>"
    resend-invitations-for-share: "record<data: list<string>, responseStatus: int>"
    delete-resources: "record<data: list<string>, responseStatus: int>"
    get-resource-info: "record<data: record<attributes: record<accessedAt: string, accessedTime: int, createdAt: string, createdBy: string, createdTime: int, extension: string, fileCount: int, hash: string, name: string, path: string, previewable: bool, size: int, type: string, updatedAt: string, updatedTime: int, uploadDate: string>, id: int, relationships: record<directFile: record, notifications: list, parentResource: record, share: record>, type: string>, included: list<any>, responseStatus: int>"
    add-folder: "record<data: record<attributes: record<accessedAt: string, accessedTime: int, createdAt: string, createdBy: string, createdTime: int, extension: string, fileCount: int, hash: string, name: string, path: string, previewable: bool, size: int, type: string, updatedAt: string, updatedTime: int, uploadDate: string>, id: int, relationships: record<directFile: record, notifications: list, parentResource: record, share: record>, type: string>, included: list<any>, responseStatus: int>"
    compress-files: "record<data: record<attributes: record<accessedAt: string, accessedTime: int, createdAt: string, createdBy: string, createdTime: int, extension: string, fileCount: int, hash: string, name: string, path: string, previewable: bool, size: int, type: string, updatedAt: string, updatedTime: int, uploadDate: string>, id: int, relationships: record<directFile: record, notifications: list, parentResource: record, share: record>, type: string>, included: list<any>, responseStatus: int>"
    copy-resources: "record<data: record<attributes: record<accessedAt: string, accessedTime: int, createdAt: string, createdBy: string, createdTime: int, extension: string, fileCount: int, hash: string, name: string, path: string, previewable: bool, size: int, type: string, updatedAt: string, updatedTime: int, uploadDate: string>, id: int, relationships: record<directFile: record, notifications: list, parentResource: record, share: record>, type: string>, meta: record>"
    download: "binary"
    extract-files: "record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int, returnedResults: int, totalResults: int>"
    list-resources: "record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int, returnedResults: int, totalResults: int>"
    list-resource-contents: "record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int, returnedResults: int, totalResults: int>"
    move-resources: "record<data: record<attributes: record<accessedAt: string, accessedTime: int, createdAt: string, createdBy: string, createdTime: int, extension: string, fileCount: int, hash: string, name: string, path: string, previewable: bool, size: int, type: string, updatedAt: string, updatedTime: int, uploadDate: string>, id: int, relationships: record<directFile: record, notifications: list, parentResource: record, share: record>, type: string>, meta: record>"
    get-preview-image: "record<data: record<attributes: record<image: string, imageHash: string, pageCount: int, size: int>, id: int, type: string>, responseStatus: int>"
    upload-file: "record<data: record<attributes: record<accessedAt: string, accessedTime: int, createdAt: string, createdBy: string, createdTime: int, extension: string, fileCount: int, hash: string, name: string, path: string, previewable: bool, size: int, type: string, updatedAt: string, updatedTime: int, uploadDate: string>, id: int, relationships: record<directFile: record, notifications: list, parentResource: record, share: record>, type: string>, included: list<any>, responseStatus: int>"
    delete-resource-by-id: "record<data: list<string>, responseStatus: int>"
    get-resource-info-by-id: "record<data: record<attributes: record<accessedAt: string, accessedTime: int, createdAt: string, createdBy: string, createdTime: int, extension: string, fileCount: int, hash: string, name: string, path: string, previewable: bool, size: int, type: string, updatedAt: string, updatedTime: int, uploadDate: string>, id: int, relationships: record<directFile: record, notifications: list, parentResource: record, share: record>, type: string>, included: list<any>, responseStatus: int>"
    update-resource-by-id: "record<data: record<attributes: record<accessedAt: string, accessedTime: int, createdAt: string, createdBy: string, createdTime: int, extension: string, fileCount: int, hash: string, name: string, path: string, previewable: bool, size: int, type: string, updatedAt: string, updatedTime: int, uploadDate: string>, id: int, relationships: record<directFile: record, notifications: list, parentResource: record, share: record>, type: string>, included: list<any>, responseStatus: int>"
    list-shares: "record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int, returnedResults: int, totalResults: int>"
    add-share: "record<data: record<attributes: record<accessDescription: string, accessMode: record, created: string, embed: bool, expiration: string, expired: bool, fileDropCreateFolders: bool, formId: int, hasNotification: bool, hasPassword: bool, hash: string, inherited: bool, messages: list, modified: string, name: string, ownerHash: string, paths: list, public: bool, recipients: list, requireEmail: bool, resent: string, status: int, trackingStatus: string, type: string>, id: int, relationships: record<messages: list, notifications: list, owner: record, resources: list>, type: string>, included: list<any>, responseStatus: int>"
    complete-direct-send: "record<data: record<attributes: record<accessDescription: string, accessMode: record, created: string, embed: bool, expiration: string, expired: bool, fileDropCreateFolders: bool, formId: int, hasNotification: bool, hasPassword: bool, hash: string, inherited: bool, messages: list, modified: string, name: string, ownerHash: string, paths: list, public: bool, recipients: list, requireEmail: bool, resent: string, status: int, trackingStatus: string, type: string>, id: int, relationships: record<messages: list, notifications: list, owner: record, resources: list>, type: string>, included: list<any>, responseStatus: int>"
    delete-share-by-id: "record<data: list<string>, responseStatus: int>"
    get-share-by-id: "record<data: record<attributes: record<accessDescription: string, accessMode: record, created: string, embed: bool, expiration: string, expired: bool, fileDropCreateFolders: bool, formId: int, hasNotification: bool, hasPassword: bool, hash: string, inherited: bool, messages: list, modified: string, name: string, ownerHash: string, paths: list, public: bool, recipients: list, requireEmail: bool, resent: string, status: int, trackingStatus: string, type: string>, id: int, relationships: record<messages: list, notifications: list, owner: record, resources: list>, type: string>, included: list<any>, responseStatus: int>"
    update-share-by-id: "record<data: record<attributes: record<accessDescription: string, accessMode: record, created: string, embed: bool, expiration: string, expired: bool, fileDropCreateFolders: bool, formId: int, hasNotification: bool, hasPassword: bool, hash: string, inherited: bool, messages: list, modified: string, name: string, ownerHash: string, paths: list, public: bool, recipients: list, requireEmail: bool, resent: string, status: int, trackingStatus: string, type: string>, id: int, relationships: record<messages: list, notifications: list, owner: record, resources: list>, type: string>, included: list<any>, responseStatus: int>"
    get-ssh-keys-list: "record<data: table<attributes: record, id: int, relationships: record, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int, returnedResults: int, totalResults: int>"
    add-ssh-key: "record<data: record<attributes: record<created: string, fingerprint: string, lastLogin: string>, id: int, relationships: record<ownerUser: record>, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int>"
    get-ssh-key: "record<data: record<attributes: record<created: string, fingerprint: string, lastLogin: string>, id: int, relationships: record<ownerUser: record>, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int>"
    list-users: "record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int, returnedResults: int, totalResults: int>"
    add-user: "record<data: record<attributes: record<accessTimestamp: string, accountName: string, created: string, email: string, expiration: string, firstLogin: bool, homePath: string, locked: bool, modified: string, nickname: string, onboarding: bool, permissions: record, role: string, status: int, timeZone: string, username: string>, id: int, relationships: record<homeResource: record, ownerAccount: record>, type: string>, included: list<any>, responseStatus: int>"
    delete-user: "record<data: list<string>, responseStatus: int>"
    get-user-by-id: "record<data: record<attributes: record<accessTimestamp: string, accountName: string, created: string, email: string, expiration: string, firstLogin: bool, homePath: string, locked: bool, modified: string, nickname: string, onboarding: bool, permissions: record, role: string, status: int, timeZone: string, username: string>, id: int, relationships: record<homeResource: record, ownerAccount: record>, type: string>, included: list<any>, responseStatus: int>"
    update-user: "record<data: record<attributes: record<accessTimestamp: string, accountName: string, created: string, email: string, expiration: string, firstLogin: bool, homePath: string, locked: bool, modified: string, nickname: string, onboarding: bool, permissions: record, role: string, status: int, timeZone: string, username: string>, id: int, relationships: record<homeResource: record, ownerAccount: record>, type: string>, included: list<any>, responseStatus: int>"
    get-wehooks-list: "record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int, returnedResults: int, totalResults: int>"
    add-webhook: "record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int>"
    regenerate-webhook-token: "record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int>"
    resend-webhook-activity-entry: "record<data: list<string>, responseStatus: int>"
    delete-webhook: "record<data: list<string>, responseStatus: int>"
    get-webhook-by-id: "record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int>"
    update-webhook: "record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-account" "update-account" "get-session-logs" "get-webhook-logs" "get-email-lists" "add-email-list" "delete-email-list-by-id" "get-email-list-by-id" "update-email-list-by-id" "send-referral-email" "send-welcome-email" "get-form-by-share-hash" "delete-form-message-by-id" "get-form-entries" "get-form-by-id" "update-form-by-id" "list-notifications" "add-notification" "delete-notification-by-id" "get-notification-by-id" "update-notification-by-id" "resend-invitations-for-share" "delete-resources" "get-resource-info" "add-folder" "compress-files" "copy-resources" "download" "extract-files" "list-resources" "list-resource-contents" "move-resources" "get-preview-image" "upload-file" "delete-resource-by-id" "get-resource-info-by-id" "update-resource-by-id" "list-shares" "add-share" "complete-direct-send" "delete-share-by-id" "get-share-by-id" "update-share-by-id" "get-ssh-keys-list" "add-ssh-key" "delete-ssh-key" "get-ssh-key" "list-users" "add-user" "delete-user" "get-user-by-id" "update-user" "get-wehooks-list" "add-webhook" "regenerate-webhook-token" "resend-webhook-activity-entry" "delete-webhook" "get-webhook-by-id" "update-webhook" "commands"] | sort) } | get name | first)
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

# Get account settings
#
# GET /account
# Returns: record<data: record<attributes: record<accountName: string, accountOnboarding: bool, allowedIp: list, branding: bool, brandingSettings: record, clientId: int, complexPasswords: bool, created: string, customDomain: bool, customSignature: string, externalDomains: list, maxUsers: int, modified: string, planDetails: record, quota: record, secureOnly: bool, showReferralLinks: bool, status: int, userCount: int, welcomeEmailContent: string, welcomeEmailSubject: string>, id: int, relationships: record<masterUser: record>, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int>
# operationId: getAccount
export def "get-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string # Related records to include in the response. Valid option is **masterUser** (e.g. masterUser)
  --ev-api-key: string # API Key required for the request (required, e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access Token for the request (required, e.g. 19853ef63a0bc348024a9e4cfd4a92520d2dfd04e88d8679fb1ed6bc551593d1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account"
    query: [{name: include, var: include}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    include: $include, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update account settings
#
# PATCH /account
# Returns: record<data: record<attributes: record<accountName: string, accountOnboarding: bool, allowedIp: list, branding: bool, brandingSettings: record, clientId: int, complexPasswords: bool, created: string, customDomain: bool, customSignature: string, externalDomains: list, maxUsers: int, modified: string, planDetails: record, quota: record, secureOnly: bool, showReferralLinks: bool, status: int, userCount: int, welcomeEmailContent: string, welcomeEmailSubject: string>, id: int, relationships: record<masterUser: record>, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int>
# operationId: updateAccount
export def "update-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make the API call. (required, e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 19853ef63a0bc348024a9e4cfd4a92520d2dfd04e88d8679fb1ed6bc551593d1)
  --account-onboarding: oneof<nothing, bool> # Whether extra help popups can be enabled for users in the web file manager. (e.g. true)
  --allowed-ip-ranges: list # IP Address Ranges for restricting account access — item shape: {ipEnd?: string, ipStart?: string}
  --branding-settings: record # shape: {companyName?: string, customEmail?: string, theme?: string}
  --complex-passwords: oneof<nothing, bool> # Whether to require complex passwords for all passwords. (e.g. false)
  --custom-signature: string # Signature to be automatically added to the bottom of emails generated by the account.
  --email-content: string # Content of welcome email template. (e.g. Great news, your new account is ready! For your records, we've listed information you'll use to log in below: FTP Server: [[ftpserver]] Username (Web and FTP access): [[username]] [[setpassword]])
  --email-subject: string # Subject line for welcome emails (e.g. ExaVault File Sharing Account)
  --external-domain: string # Custom address used for web file manager. Not available for all account types.
  --quota: record # shape: {noticeEnabled?: bool, noticeThreshold?: int, transactionsNoticeEnabled?: bool, transactionsNoticeThreshold?: int}
  --secure-only: oneof<nothing, bool> # Whether unencrypted FTP connections should be denied for the account. (e.g. false)
  --show-referral-links: oneof<nothing, bool> # Whether to display links for others to sign up on share views and invitation emails (e.g. false)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/account"
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountOnboarding, var: account_onboarding}, {name: allowedIpRanges, var: allowed_ip_ranges}, {name: brandingSettings, var: branding_settings}, {name: complexPasswords, var: complex_passwords}, {name: customSignature, var: custom_signature}, {name: emailContent, var: email_content}, {name: emailSubject, var: email_subject}, {name: externalDomain, var: external_domain}, {name: quota, var: quota}, {name: secureOnly, var: secure_only}, {name: showReferralLinks, var: show_referral_links}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ev_api_key: $ev_api_key, ev_access_token: $ev_access_token, account_onboarding: $account_onboarding, allowed_ip_ranges: $allowed_ip_ranges, branding_settings: $branding_settings, complex_passwords: $complex_passwords, custom_signature: $custom_signature, email_content: $email_content, email_subject: $email_subject, external_domain: $external_domain, quota: $quota, secure_only: $secure_only, show_referral_links: $show_referral_links
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get activity logs
#
# GET /activity/session
# Returns: record<data: table<attributes: record, id: int, type: string>, responseStatus: int, returnedResults: int, totalResults: int>
# operationId: getSessionLogs
export def "get-session-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start date of the filter data range (format: date-time, e.g. 2019-10-18T06:48:40Z)
  --end-date: string # End date of the filter data range (format: date-time, e.g. 2019-10-18T06:48:40Z)
  --ip-address: string # Used to filter session logs by ip address. (e.g. 127.0.0.1)
  --username: string # Username used for filtering a list (e.g. jdoe)
  --path: string # Path used to filter records (e.g. /folder*)
  --type: string # Filter session logs for operation type (see table above for acceptable values) (e.g. EDIT_SHARE)
  --offset: int # Offset of the records list (e.g. 100)
  --limit: int # Limit of the records list (e.g. 10)
  --sort: string # Comma separated list sort params (e.g. -date)
  --ev-api-key: string # API Key (required, e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access Token (required, e.g. 19853ef63a0bc348024a9e4cfd4a92520d2dfd04e88d8679fb1ed6bc551593d1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/activity/session"
    query: [{name: startDate, var: start_date}, {name: endDate, var: end_date}, {name: ipAddress, var: ip_address}, {name: username, var: username}, {name: path, var: path}, {name: type, var: type}, {name: offset, var: offset}, {name: limit, var: limit}, {name: sort, var: sort}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, end_date: $end_date, ip_address: $ip_address, username: $username, path: $path, type: $type, offset: $offset, limit: $limit, sort: $sort, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get webhook logs
#
# GET /activity/webhooks
# Returns: record<data: table<attributes: any, id: int, type: string>, responseStatus: int, returnedResults: int, totalResults: int>
# operationId: getWebhookLogs
export def "get-webhook-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Earliest date of entries to include in list (format: date-time)
  --end-date: string # Latest date of entries to include in list (format: date-time)
  --endpoint-url: string # Webhook listener endpoint (format: uri)
  --event: string # Type of activity that triggered the webhook attempt (e.g. resources.upload)
  --status-code: int # Response code from the webhook endpoint (e.g. 200)
  --resource-path: string # Path of the resource that triggered the webhook attempt (e.g. /Production)
  --username: string # Filter by triggering username. (e.g. exampleuser)
  --offset: int # Records to skip before returning results. (e.g. 100)
  --limit: int # Limit of the records list (e.g. 100)
  --sort: string # Comma separated list sort params (e.g. -date,event)
  --ev-api-key: string # API Key (required, e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access Token (required, e.g. 19853ef63a0bc348024a9e4cfd4a92520d2dfd04e88d8679fb1ed6bc551593d1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/activity/webhooks"
    query: [{name: startDate, var: start_date}, {name: endDate, var: end_date}, {name: endpointUrl, var: endpoint_url}, {name: event, var: event}, {name: statusCode, var: status_code}, {name: resourcePath, var: resource_path}, {name: username, var: username}, {name: offset, var: offset}, {name: limit, var: limit}, {name: sort, var: sort}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, end_date: $end_date, endpoint_url: $endpoint_url, event: $event, status_code: $status_code, resource_path: $resource_path, username: $username, offset: $offset, limit: $limit, sort: $sort, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all email groups
#
# GET /email-lists
# Returns: record<data: table<attributes: record, id: int, relationships: record, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int, returnedResults: int, totalResults: int>
# operationId: getEmailLists
export def "get-email-lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string # Related record types to include in the response. Valid option is `ownerUser`
  --ev-api-key: string # API Key required to make the API call. (required, e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/email-lists"
    query: [{name: include, var: include}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    include: $include, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new email list
#
# POST /email-lists
# Returns: record<data: record<attributes: record<created: string, emails: list, modified: string, name: string>, id: int, relationships: record<ownerUser: record>, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int>
# operationId: addEmailList
export def "add-email-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make the API call. (required, e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  emails: list<string> # Array of email addresses to include in the email list. (e.g. [johns@example.com, jdoe@example.com])
  name: string # Name of the email list. (e.g. My friends list)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/email-lists"
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: emails, var: emails}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    ev_api_key: $ev_api_key, ev_access_token: $ev_access_token, emails: $emails, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an email group with given id
#
# DELETE /email-lists/{id}
# Returns: record<data: list<string>, responseStatus: int>
# operationId: deleteEmailListById
export def "delete-email-list-by-id" [
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
  --ev-api-key: string # API Key required to make the API call. (required, e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/email-lists/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get individual email group
#
# GET /email-lists/{id}
# Returns: record<data: record<attributes: record<created: string, emails: list, modified: string, name: string>, id: int, relationships: record<ownerUser: record>, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int>
# operationId: getEmailListById
export def "get-email-list-by-id" [
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
  --include: string # Related record types to include in the response. Valid option is `ownerUser`
  --ev-api-key: string # API Key required to make the API call. (required, e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/email-lists/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: include, var: include}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include: $include, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an email group
#
# PATCH /email-lists/{id}
# Returns: record<data: record<attributes: record<created: string, emails: list, modified: string, name: string>, id: int, relationships: record<ownerUser: record>, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int>
# operationId: updateEmailListById
export def "update-email-list-by-id" [
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
  --ev-api-key: string # API Key required to make the API call. (required, e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  --emails: list<string> # Email addresses that replace existing list. (e.g. [yuk@example.com, jdoe@example.com])
  --name: string # Name of the email list. (e.g. My friends list)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/email-lists/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: emails, var: emails}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token, emails: $emails, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send referral email to a given address
#
# POST /email/referral
# Returns: record<data: list<string>, responseStatus: int>
# operationId: sendReferralEmail
export def "send-referral-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  emails: list<string>
  message: string # e.g. I use ExaVault for secure file sending, and so should you. Follow my link to sign up for a trial.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/email/referral"
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: emails, var: emails}, {name: message, var: message}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    ev_api_key: $ev_api_key, ev_access_token: $ev_access_token, emails: $emails, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resend welcome email to specific user
#
# POST /email/welcome/{username}
# Returns: record<data: list<string>, responseStatus: int>
# operationId: sendWelcomeEmail
export def "send-welcome-email" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make the API call. (required, e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/email/welcome/{username}"
    path_params: [{name: username, var: username}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    username: $username, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get receive folder form settings
#
# GET /forms
# Returns: record<data: record<attributes: record<cssStyles: string, elements: list, formDescription: string, submitButtonText: string, successMessage: string>, id: int, relationships: record<share: record>, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int>
# operationId: getFormByShareHash
export def "get-form-by-share-hash" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --share-hash: string # Share hash to retrieve the form for. (required)
  --include: string@include-completer # Related record types to include in the response. Valid option is **share**
  --ev-api-key: string # API key required to make the API call. (required)
  --ev-access-token: string # Access Token required to make the API call. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/forms"
    query: [{name: shareHash, var: share_hash, required: true}, {name: include, var: include}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    share_hash: $share_hash, include: $include, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a receive form submission
#
# DELETE /forms/entries/{id}
# Returns: record<data: list<string>, responseStatus: int>
# operationId: deleteFormMessageById
export def "delete-form-message-by-id" [
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
  --ev-api-key: string # API Key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/forms/entries/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get form data entries for a receive
#
# GET /forms/entries/{id}
# Returns: record<data: table<attributes: record, id: int, type: string>, responseStatus: int, returnedResults: int, totalResults: int>
# operationId: getFormEntries
export def "get-form-entries" [
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
  --limit: int # Limit of records to be returned (for pagination) (e.g. 10)
  --offset: int # Current offset of records (for pagination) (e.g. 100)
  --ev-api-key: string # API Key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/forms/entries/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, limit: $limit, offset: $offset, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get receive folder form by Id
#
# GET /forms/{id}
# Returns: record<data: record<attributes: record<cssStyles: string, elements: list, formDescription: string, submitButtonText: string, successMessage: string>, id: int, relationships: record<share: record>, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int>
# operationId: getFormById
export def "get-form-by-id" [
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
  --include: string # Enter "**share**" to get information about associated receive folder. (e.g. share)
  --ev-api-key: string # API key required to make the API call. (required)
  --ev-access-token: string # Access Token required to make the API call. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/forms/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: include, var: include}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include: $include, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a form with given parameters
#
# PATCH /forms/{id}
# Returns: record<data: record<attributes: record<cssStyles: string, elements: list, formDescription: string, submitButtonText: string, successMessage: string>, id: int, relationships: record<share: record>, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int>
# operationId: updateFormById
export def "update-form-by-id" [
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
  --ev-api-key: string # API Key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  --css-styles: string # e.g. #ev-widget-form {   /*Change this to change the font. Remove to use your website font*/   font-family: Helvetica Neue, sans-serif;   /*Makes the form the same width as your website */   margin: 0 -2%; } #ev-widget-form label{   width: 100%; } #ev-widget-form input, #ev-widget-form textarea {   /*Changes color and thickness of borders on form elements */   border: 2px solid #ccc;   /*Changes spacing inside the form elements (top/bottom and left/right */   padding: 5px 5px;   /* Changes how far away the inputs are from their label */   margin-top: 2px; }  #ev-widget-form input:focus, #ev-widget-form textarea:focus {   /*Changes the color of the form elements when they are clicked in to */   border: 2px solid #b2cf88;   /*Removes glow effect from form elements that are clicked in to */   outline: none; }  #ev-widget-form label {   font-size: 14px;   font-weight: bold;   /*Changes color of labels */   color: #232323 }  #ev-widget-form .ev-form-element-description {   /*Changes size of descriptions */   font-size: 12px;   /*Changes color of descriptions */   color: #777;   /* Changes how far away the descriptions are from their input */   margin-top: 2px; }  #ev-widget-form textarea {   /* Makes textareas (multiline inputs) a taller. */   min-height: 90px; }     
  --elements: list # item shape: {id?: int, name?: string, order?: int, settings?: record, type?: "name"|"email"|"text"|"textarea"|"upload_area"}
  --form-description: string # Set a description for the form that will be visible to recipients. (e.g. Send your files)
  --submit-button-text: string # Text to be displayed on the submission button. (e.g. Send Files)
  --success-message: string # Text to be displayed when a recipient has submitted the form. (e.g. Your files were uploaded)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/forms/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: cssStyles, var: css_styles}, {name: elements, var: elements}, {name: formDescription, var: form_description}, {name: submitButtonText, var: submit_button_text}, {name: successMessage, var: success_message}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token, css_styles: $css_styles, elements: $elements, form_description: $form_description, submit_button_text: $submit_button_text, success_message: $success_message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of notifications
#
# GET /notifications
# Returns: record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int, returnedResults: int, totalResults: int>
# operationId: listNotifications
export def "list-notifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer # Type of notification include in the list. Valid options are **file**, **folder**, **send_receipt**, **share_receipt**, **file_drop** If this parameter is not used, only **file** and **folder** type notifications are included in the list. (e.g. file)
  --offset: int # Starting notification record in the result set. Can be used for pagination. (format: int32, default: 0, e.g. 50)
  --sort: string # What order the list of matches should be in. Valid sort fields are **resourcename**, **date**, **action** and **type**. The sort order for each sort field is ascending unless it is prefixed with a minus (“-“), in which case it will be descending. You can chose multiple options for the sort by separating them with commmas, such as "type,-date" to sort by type, then most recent. (e.g. date)
  --limit: int # Number of notification records to return. Can be used for pagination. (format: int32, default: 25, e.g. 100)
  --include: string@include-completer-1 # Related records to include in the response. Valid options are **ownerUser**, **resource**, **share** (e.g. resource,share,user)
  --action: string@action-completer # The kind of action which triggers the notification. Valid choices are **connect** (only for delivery receipts), **download**, **upload**, **delete**, or **all** **Note** The **all** action matches notifications set to "all", not all notifications. For example, notifications set to trigger only on delete are not included if you filter for action=all (e.g. all)
  --ev-api-key: string # API Key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/notifications"
    query: [{name: type, var: type}, {name: offset, var: offset}, {name: sort, var: sort}, {name: limit, var: limit}, {name: include, var: include}, {name: action, var: action}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, offset: $offset, sort: $sort, limit: $limit, include: $include, action: $action, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new notification
#
# POST /notifications
# Returns: record<data: record<attributes: record<action: string, created: string, message: string, modified: string, name: string, path: string, readableDescription: string, readableDescriptionWithoutPath: string, recipients: list, sendEmail: bool, shareId: string, type: string, userId: string, usernames: list>, id: int, relationships: record<ownerUser: record, resource: record, share: record>, type: string>, included: list<any>, responseStatus: int>
# operationId: addNotification
export def "add-notification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  action: string@action-completer-1 # Type of action be notified about. Notifications will only be fired for the given type of action. Valid choices are **upload**, **download**, **delete** or **all** (upload/download/delete) (e.g. upload)
  --message: string # Custom message to include in notification emails.
  --recipients: list<string> # Email addresses to send notification emails to. If not specified, sends to the current user's email address. (e.g. [myemail@example.com])
  resource: string # Resources for this notification. See details on [how to specify resources](#section/Identifying-Resources) above.
  --send-email: oneof<nothing, bool> # Set to true if the user should be notified by email when the notification is triggered. (e.g. true)
  type: string@type-completer-1 # What kind of notification you're making. Valid choices are: - **file** to monitor activity for a file resource - **folder** to monitor activity for a folder resource (e.g. file)
  usernames: list<string> # Determines which users' actions should trigger the notification. Rather than listing individual users, you can also use 3 special options: - **notice\_user\_all** for activity by any user or share recipient - **notice\_user\_all\_users** for activity only by user accounts - **notice\_user\_all\_recipient** for activity only by share recipients
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/notifications"
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: message, var: message}, {name: recipients, var: recipients}, {name: resource, var: resource}, {name: sendEmail, var: send_email, required: true}, {name: type, var: type}, {name: usernames, var: usernames}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    ev_api_key: $ev_api_key, ev_access_token: $ev_access_token, action: $action, message: $message, recipients: $recipients, resource: $resource, send_email: $send_email, type: $type, usernames: $usernames
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a notification
#
# DELETE /notifications/{id}
# Returns: record<data: list<string>, responseStatus: int>
# operationId: deleteNotificationById
export def "delete-notification-by-id" [
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
  --ev-api-key: string # API Key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/notifications/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get notification details
#
# GET /notifications/{id}
# Returns: record<data: record<attributes: record<action: string, created: string, message: string, modified: string, name: string, path: string, readableDescription: string, readableDescriptionWithoutPath: string, recipients: list, sendEmail: bool, shareId: string, type: string, userId: string, usernames: list>, id: int, relationships: record<ownerUser: record, resource: record, share: record>, type: string>, included: list<any>, responseStatus: int>
# operationId: getNotificationById
export def "get-notification-by-id" [
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
  --include: string # Related record types to include in the response. You can include multiple types by separating them with commas. Valid options are **ownerUser**, **resource**, and **share**. (e.g. resource,share)
  --ev-api-key: string # API Key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/notifications/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: include, var: include}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include: $include, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a notification
#
# PATCH /notifications/{id}
# Returns: record<data: record<attributes: record<action: string, created: string, message: string, modified: string, name: string, path: string, readableDescription: string, readableDescriptionWithoutPath: string, recipients: list, sendEmail: bool, shareId: string, type: string, userId: string, usernames: list>, id: int, relationships: record<ownerUser: record, resource: record, share: record>, type: string>, included: list<any>, responseStatus: int>
# operationId: updateNotificationById
export def "update-notification-by-id" [
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
  --ev-api-key: string # API Key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  --action: string@action-completer-1 # Type of action be notified about. Notifications will only be sent for the given type of action. Valid choices are **upload**, **download**, **delete** or **all** (upload/download/delete) (e.g. all)
  --message: string # Custom message to insert into the notification emails, along with the matching activity.
  --recipients: list<string> # Email addresses to send notification emails to. If empty, sends to the current user's email address. (e.g. [myemail@example.com])
  --send-email: oneof<nothing, bool> # Whether an email should be sent to the recipients when matching activity happens. (e.g. true)
  --usernames: list<string> # Determines which users' actions should trigger the notification. Rather than listing individual users, you can also use 3 special options: - **notice\_user\_all** for activity by any user or share recipient - **notice\_user\_all\_users** for activity only by user accounts - **notice\_user\_all\_recipients** for activity only by share recipients (e.g. [notice_user_all])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/notifications/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: message, var: message}, {name: recipients, var: recipients}, {name: sendEmail, var: send_email}, {name: usernames, var: usernames}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token, action: $action, message: $message, recipients: $recipients, send_email: $send_email, usernames: $usernames
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resend invitations to share recipients
#
# POST /recipients/shares/invites/{shareId}
# Returns: record<data: list<string>, responseStatus: int>
# operationId: resendInvitationsForShare
export def "resend-invitations-for-share" [
  share_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  --recipient-id: int # ID number of recipient to send a new invitation to. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/recipients/shares/invites/{shareId}"
    path_params: [{name: shareId, var: share_id}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: recipientId, var: recipient_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    share_id: $share_id, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token, recipient_id: $recipient_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Resources
#
# DELETE /resources
# Returns: record<data: list<string>, responseStatus: int>
# operationId: deleteResources
export def "delete-resources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key (required, e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access Token (required, e.g. 19853ef63a0bc348024a9e4cfd4a92520d2dfd04e88d8679fb1ed6bc551593d1)
  resources: list<string> # Resource identifiers of items to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/resources"
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: resources, var: resources}]}
    accept: ["application/json"]
    ok: [200, 207]
    auth: bearer
  } {
    ev_api_key: $ev_api_key, ev_access_token: $ev_access_token, resources: $resources
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Resource Properties
#
# GET /resources
# Returns: record<data: record<attributes: record<accessedAt: string, accessedTime: int, createdAt: string, createdBy: string, createdTime: int, extension: string, fileCount: int, hash: string, name: string, path: string, previewable: bool, size: int, type: string, updatedAt: string, updatedTime: int, uploadDate: string>, id: int, relationships: record<directFile: record, notifications: list, parentResource: record, share: record>, type: string>, included: list<any>, responseStatus: int>
# operationId: getResourceInfo
export def "get-resource-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource: string # Resource identifier of the file or folder to get metadata for. (required)
  --include: string # Comma separated list of relationships to include in response. Possible values are **share**, **notifications**, **directFile**, **parentResource**, **ownerUser**, **ownerUser**.
  --ev-api-key: string # API Key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/resources"
    query: [{name: resource, var: resource, required: true}, {name: include, var: include}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource: $resource, include: $include, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a folder
#
# POST /resources
# Returns: record<data: record<attributes: record<accessedAt: string, accessedTime: int, createdAt: string, createdBy: string, createdTime: int, extension: string, fileCount: int, hash: string, name: string, path: string, previewable: bool, size: int, type: string, updatedAt: string, updatedTime: int, uploadDate: string>, id: int, relationships: record<directFile: record, notifications: list, parentResource: record, share: record>, type: string>, included: list<any>, responseStatus: int>
# operationId: addFolder
export def "add-folder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  --name: string # Name of the folder to create. Required if **path** is not used
  --parent-resource: string # Resource identifier where to create a folder. Required if **path** is not used
  --path: string # Fully-qualified path to the new folder including folder's name
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/resources"
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: parentResource, var: parent_resource}, {name: path, var: path}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    ev_api_key: $ev_api_key, ev_access_token: $ev_access_token, name: $name, parent_resource: $parent_resource, path: $path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Compress resources
#
# POST /resources/compress
# Returns: record<data: record<attributes: record<accessedAt: string, accessedTime: int, createdAt: string, createdBy: string, createdTime: int, extension: string, fileCount: int, hash: string, name: string, path: string, previewable: bool, size: int, type: string, updatedAt: string, updatedTime: int, uploadDate: string>, id: int, relationships: record<directFile: record, notifications: list, parentResource: record, share: record>, type: string>, included: list<any>, responseStatus: int>
# operationId: compressFiles
export def "compress-files" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  --archive-name: string # Name of the zip archive to create. If left blank, current date will be used.
  --parent-resource: string # Resource identifier of the folder where zip archive should be created.
  resources: list<string> # Resource identifiers for file(s)/folder(s) to include in new zip file
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/resources/compress"
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: archiveName, var: archive_name}, {name: parentResource, var: parent_resource}, {name: resources, var: resources}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    ev_api_key: $ev_api_key, ev_access_token: $ev_access_token, archive_name: $archive_name, parent_resource: $parent_resource, resources: $resources
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Copy resources
#
# POST /resources/copy
# Returns: record<data: record<attributes: record<accessedAt: string, accessedTime: int, createdAt: string, createdBy: string, createdTime: int, extension: string, fileCount: int, hash: string, name: string, path: string, previewable: bool, size: int, type: string, updatedAt: string, updatedTime: int, uploadDate: string>, id: int, relationships: record<directFile: record, notifications: list, parentResource: record, share: record>, type: string>, meta: record>
# operationId: copyResources
export def "copy-resources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  parent_resource: string # Resource identifier for folder where items will be copied to.
  resources: list<string> # Resource identifier(s) of items to be copied to a new location
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/resources/copy"
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: parentResource, var: parent_resource}, {name: resources, var: resources}]}
    accept: ["application/json"]
    ok: [200, 207]
    auth: bearer
  } {
    ev_api_key: $ev_api_key, ev_access_token: $ev_access_token, parent_resource: $parent_resource, resources: $resources
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download a file
#
# GET /resources/download
# Returns: binary
# operationId: download
export def "download" [
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
  --resources: list<string> # Path of file or folder to be downloaded, starting from the root. Can also be an array of paths. (required)
  --download-archive-name: string # When downloading multiple files, this will be used as the name of the zip file that is created.
  --ev-api-key: string # API Key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> any {
  http-request {
    method: get
    path: "/resources/download"
    query: [{name: "resources[]", var: resources, style: multi, required: true}, {name: downloadArchiveName, var: download_archive_name}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/octet-stream", "application/zip"]
    ok: [200]
    auth: bearer
  } {
    resources: $resources, download_archive_name: $download_archive_name, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Extract resources
#
# POST /resources/extract
# Returns: record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int, returnedResults: int, totalResults: int>
# operationId: extractFiles
export def "extract-files" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  parent_resource: string # Resource identifier for folder files should be extracted to.
  resource: string # Resource identifier of zip archive to be extracted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/resources/extract"
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: parentResource, var: parent_resource}, {name: resource, var: resource}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    ev_api_key: $ev_api_key, ev_access_token: $ev_access_token, parent_resource: $parent_resource, resource: $resource
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of all resources
#
# GET /resources/list
# Returns: record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int, returnedResults: int, totalResults: int>
# operationId: listResources
export def "list-resources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource: string # Resource identifier to get resources for. Can be path/id/name. (required)
  --sort: string # Endpoint support multiple sort fields by allowing array of sort params. Sort fields should be applied in the order specified. The sort order for each sort field is ascending unless it is prefixed with a minus (“-“), in which case it will be descending. (e.g. name)
  --offset: int # Determines which item to start on for pagination. Use zero (0) to start at the beginning of the list. e.g, setting `offset=200` would trigger the server to skip the first 200 matching entries when returning the results. (format: int32, default: 0)
  --limit: int # The number of files to limit the result. If you have more files in your directory than this limit, make multiple calls, incrementing the `offset` parameter, above. (format: int32)
  --type: string # Limit types of resources returned to "file" or "dir" only. This is ignored if you are using the `name` parameter to trigger a search.
  --name: string # Text to match resource names. This allows you to filter the results returned. For example, to locate only zip archive files, you can enter `*zip` and only resources ending in "zip" will be included in the list of results.
  --include: string # Comma separated list of relationships to include in response. Possible values are **share**, **notifications**, **directFile**, **parentResource**, **ownerUser**, **ownerAccount**.
  --ev-api-key: string # API Key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/resources/list"
    query: [{name: resource, var: resource, required: true}, {name: sort, var: sort}, {name: offset, var: offset}, {name: limit, var: limit}, {name: type, var: type}, {name: name, var: name}, {name: include, var: include}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource: $resource, sort: $sort, offset: $offset, limit: $limit, type: $type, name: $name, include: $include, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List contents of folder
#
# GET /resources/list/{id}
# Returns: record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int, returnedResults: int, totalResults: int>
# operationId: listResourceContents
export def "list-resource-contents" [
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
  --sort: string # Endpoint support multiple sort fields by allowing array of sort params. Sort fields should be applied in the order specified. The sort order for each sort field is ascending unless it is prefixed with a minus (“-“), in which case it will be descending. (e.g. name)
  --offset: int # Determines which item to start on for pagination. Use zero (0) to start at the beginning of the list. (format: int32, default: 0)
  --limit: int # The number of files to limit the result. Cannot be set higher than 100. If you have more than one hundred files in your directory, make multiple calls, incrementing the `offset parameter, above. (format: int32)
  --type: string # Limit types of resources returned to "file" or "dir" only.
  --include: string # Comma separated list of relationships to include in response. Possible values are **share**, **notifications**, **directFile**, **parentResource**, **ownerUser**, **ownerUser**.
  --ev-api-key: string # API Key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/resources/list/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: sort, var: sort}, {name: offset, var: offset}, {name: limit, var: limit}, {name: type, var: type}, {name: include, var: include}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, sort: $sort, offset: $offset, limit: $limit, type: $type, include: $include, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Move resources
#
# POST /resources/move
# Returns: record<data: record<attributes: record<accessedAt: string, accessedTime: int, createdAt: string, createdBy: string, createdTime: int, extension: string, fileCount: int, hash: string, name: string, path: string, previewable: bool, size: int, type: string, updatedAt: string, updatedTime: int, uploadDate: string>, id: int, relationships: record<directFile: record, notifications: list, parentResource: record, share: record>, type: string>, meta: record>
# operationId: moveResources
export def "move-resources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  parent_resource: string # Resource identifier of folder to move files/folders to. (e.g. /copyhere)
  resources: list<string> # Array containing file/folder paths to move. (e.g. [/testone.jpg, /folder])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/resources/move"
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: parentResource, var: parent_resource}, {name: resources, var: resources}]}
    accept: ["application/json"]
    ok: [200, 207]
    auth: bearer
  } {
    ev_api_key: $ev_api_key, ev_access_token: $ev_access_token, parent_resource: $parent_resource, resources: $resources
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Preview a file
#
# GET /resources/preview
# Returns: record<data: record<attributes: record<image: string, imageHash: string, pageCount: int, size: int>, id: int, type: string>, responseStatus: int>
# operationId: getPreviewImage
export def "get-preview-image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource: string # Resource identifier for the image file. (required)
  --size: string@size-completer # The size of the image. (required)
  --width: int # Overrides sizes. Sets to a specific width. (format: int32)
  --height: int # Overrides sizes. Sets to a specific height. (format: int32)
  --page: int # Page number to extract from a multi-page document (0 is the first page). Vaild for **.pdf** or **.doc** files. (format: int32, default: 0)
  --ev-api-key: string # API Key (required, e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access Token (required, e.g. 19853ef63a0bc348024a9e4cfd4a92520d2dfd04e88d8679fb1ed6bc551593d1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/resources/preview"
    query: [{name: resource, var: resource, required: true}, {name: size, var: size, required: true}, {name: width, var: width}, {name: height, var: height}, {name: page, var: page}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource: $resource, size: $size, width: $width, height: $height, page: $page, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload a file
#
# POST /resources/upload
# Returns: record<data: record<attributes: record<accessedAt: string, accessedTime: int, createdAt: string, createdBy: string, createdTime: int, extension: string, fileCount: int, hash: string, name: string, path: string, previewable: bool, size: int, type: string, updatedAt: string, updatedTime: int, uploadDate: string>, id: int, relationships: record<directFile: record, notifications: list, parentResource: record, share: record>, type: string>, included: list<any>, responseStatus: int>
# operationId: uploadFile
export def "upload-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # Destination path for the file being uploaded, including the file name. (required)
  --file-size: int # File size, in bits, of the file being uploaded. (required, e.g. 2935)
  --resume: oneof<nothing, bool> # True if upload resume is supported, false if it isn't. (default: true, e.g. true)
  --allow-overwrite: oneof<nothing, bool> # True if a file with the same name is found in the designated path, should be overwritten. False if different file names should be generated. (default: false, e.g. true)
  --ev-api-key: string # API Key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  --offset-bytes: int # Allows a file upload to resume at a certain number of bytes. (e.g. 4852)
  --file: string # format: binary
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/resources/upload"
    query: [{name: path, var: path, required: true}, {name: fileSize, var: file_size, required: true}, {name: resume, var: resume}, {name: allowOverwrite, var: allow_overwrite}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}, {name: offsetBytes, var: offset_bytes}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}], files: [file]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    path: $path, file_size: $file_size, resume: $resume, allow_overwrite: $allow_overwrite, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token, offset_bytes: $offset_bytes, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Resource
#
# DELETE /resources/{id}
# Returns: record<data: list<string>, responseStatus: int>
# operationId: deleteResourceById
export def "delete-resource-by-id" [
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
  --ev-api-key: string # API Key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/resources/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get resource metadata
#
# GET /resources/{id}
# Returns: record<data: record<attributes: record<accessedAt: string, accessedTime: int, createdAt: string, createdBy: string, createdTime: int, extension: string, fileCount: int, hash: string, name: string, path: string, previewable: bool, size: int, type: string, updatedAt: string, updatedTime: int, uploadDate: string>, id: int, relationships: record<directFile: record, notifications: list, parentResource: record, share: record>, type: string>, included: list<any>, responseStatus: int>
# operationId: getResourceInfoById
export def "get-resource-info-by-id" [
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
  --include: string # Comma separated list of relationships to include in response. Possible values are **share**, **notifications**, **directFile**, **parentResource**, **ownerUser**, **ownerAccount**.
  --ev-api-key: string # API Key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/resources/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: include, var: include}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include: $include, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rename a resource.
#
# PATCH /resources/{id}
# Returns: record<data: record<attributes: record<accessedAt: string, accessedTime: int, createdAt: string, createdBy: string, createdTime: int, extension: string, fileCount: int, hash: string, name: string, path: string, previewable: bool, size: int, type: string, updatedAt: string, updatedTime: int, uploadDate: string>, id: int, relationships: record<directFile: record, notifications: list, parentResource: record, share: record>, type: string>, included: list<any>, responseStatus: int>
# operationId: updateResourceById
export def "update-resource-by-id" [
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
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  --ev-api-key: string # API key required to make the API call. (required)
  --name: string # The new name for the resource (file or folder). (e.g. my-renamed-file.txt)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/resources/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: ev-access-token, var: ev_access_token, required: true}, {name: ev-api-key, var: ev_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ev_access_token: $ev_access_token, ev_api_key: $ev_api_key, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of shares
#
# GET /shares
# Returns: record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int, returnedResults: int, totalResults: int>
# operationId: listShares
export def "list-shares" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Current offset of records (for pagination) (e.g. 100)
  --limit: int # Limit of records to be returned (for pagination) (default: 100, e.g. 10)
  --scope: string@scope-completer # Set of shares to return. (**all**=all of them, **active**=shares that are currently active, **curentUser**=shares created by you) (e.g. active)
  --sort: string@sort-completer # What order the list of matches should be in. (e.g. created)
  --type: string@type-completer-2 # Limit the list of matches to only certain types of shares. (e.g. receive)
  --include: string # Comma separated list of relationships to include in response. Possible values are **owner**, **resources**, **notifications**, **activity**. (e.g. owner,notifications)
  --name: string # When provided, only shares whose names include this value will be in the list. Supports wildcards, such as **send\*** to return everything starting with "send". Use this parameter if you are searching for shares or receives for a specific folder name. For example **/Clients/ACME/To Be Processed**. (e.g. Customer*)
  --recipient: string # Filter the results to include only shares that invited a certain email address. Supports wildcard matching so that **\*@example.com** will give back entries shared with addresses ending in "@example.com". (e.g. test@example.com)
  --message: string # When provided, only shares with a message that contains the text will be included in the list of matches. Both the subject and the body of all messages will be checked for matches. This will always be a wildcard match, so that searching for **taxes** will return any shares with a message that contains the word "taxes". (e.g. submitted)
  --username: string # When provided, only shares created by the user with that `username` will be included in the list. Does not support wildcard searching. (e.g. example)
  --search: string # Searches the share name, username, recipients, share messages fields for the provided value. Supports wildcard searches.
  --ev-api-key: string # API Key required to make the API call. (required, e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/shares"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: scope, var: scope}, {name: sort, var: sort}, {name: type, var: type}, {name: include, var: include}, {name: name, var: name}, {name: recipient, var: recipient}, {name: message, var: message}, {name: username, var: username}, {name: search, var: search}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, scope: $scope, sort: $sort, type: $type, include: $include, name: $name, recipient: $recipient, message: $message, username: $username, search: $search, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a share
#
# POST /shares
# Returns: record<data: record<attributes: record<accessDescription: string, accessMode: record, created: string, embed: bool, expiration: string, expired: bool, fileDropCreateFolders: bool, formId: int, hasNotification: bool, hasPassword: bool, hash: string, inherited: bool, messages: list, modified: string, name: string, ownerHash: string, paths: list, public: bool, recipients: list, requireEmail: bool, resent: string, status: int, trackingStatus: string, type: string>, id: int, relationships: record<messages: list, notifications: list, owner: record, resources: list>, type: string>, included: list<any>, responseStatus: int>
# operationId: addShare
export def "add-share" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make the API call. (required, e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  --access-mode: record # An object defining what a not-logged-in visitor can do with the share contents — shape: {delete?: bool, download?: bool, modify?: bool, upload?: bool}
  --embed: oneof<nothing, bool> # Whether this share can be embedded within a web page. (e.g. false)
  --expiration: string # Expiration date for the share. If someone attempts to use the share after this date, they will receive an error that the share is not available. (format: date-time, e.g. 2017-09-25T14:12:10Z)
  --file-drop-create-folders: oneof<nothing, bool> # Only used for **receive** shares. If true, uploads will be automatically placed into sub-folders of the folder, named after the chosen field on your form. (e.g. false)
  --has-notification: oneof<nothing, bool> # Whether delivery receipts should be sent. (e.g. false)
  --is-public: oneof<nothing, bool> # Whether someone can visit the share without following a personalized recipient link. (e.g. true)
  --message-body: string # The message to be included in email invitations for your recipients. Ignored if you have not also provided `recipients` and `messageSubject`
  --message-subject: string # Subject to use on emails inviting recipients to the share. Ignored if you have not also provided `recipients` and a `messageBody` (e.g. Invitation to a shared folder)
  name: string # A name for the share. This will be visible on the page that recipients visit. (e.g. Shared Folder)
  --notification-emails: list<string> # Emails that will receive delivery receipts for this share. `hasNotification` must be **true** for delivery receipts will be sent. (e.g. [notify@example.com, notify2@example.com])
  --password: string # Set a password for recipients to access the share. All recipients will use the same password.
  --recipients: list # People you want to invite to the share. **Note**: unless you also set the `messageSubject` and `messageBody` for the new share, invitation emails will not be sent to these recipients. — item shape: {email?: string, type?: string}
  --require-email: oneof<nothing, bool> # True if recipients must provide their email to view the share. (e.g. false)
  --resources: list<string> # Array of resources for this share. See details on [how to specify resources](#section/Identifying-Resources) above. **shared_folder** and **receive** shares must have only one `resource`, which is a directory that does not have a current share attached. **send** shares may have multiple `resource` parameters. You can also leave this parameter null if you are planning to upload files to the send. If you are planning to upload files to the send that are not yet in your account, you will also need to call the [POST /shares/complete-send/{id}](#operation/completeDirectSend) endpoint to finish the send operation. (e.g. [/testfolder])
  --sending-local-files: oneof<nothing, bool> # Use this only for **send** shares. Flag to indicate that you are going to upload additional files from your computer to the share. If this is **true**, you will also need to use the [POST /shares/complete-send/{id}](#operation/completeDirectSend) call to finish setting up your share after the files are uploaded.
  type: string@type-completer-2 # The type of share to create. See above for a description of each. (e.g. shared_folder)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/shares"
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: accessMode, var: access_mode}, {name: embed, var: embed}, {name: expiration, var: expiration}, {name: fileDropCreateFolders, var: file_drop_create_folders}, {name: hasNotification, var: has_notification}, {name: isPublic, var: is_public}, {name: messageBody, var: message_body}, {name: messageSubject, var: message_subject}, {name: name, var: name}, {name: notificationEmails, var: notification_emails}, {name: password, var: password}, {name: recipients, var: recipients}, {name: requireEmail, var: require_email}, {name: resources, var: resources}, {name: sendingLocalFiles, var: sending_local_files}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    ev_api_key: $ev_api_key, ev_access_token: $ev_access_token, access_mode: $access_mode, embed: $embed, expiration: $expiration, file_drop_create_folders: $file_drop_create_folders, has_notification: $has_notification, is_public: $is_public, message_body: $message_body, message_subject: $message_subject, name: $name, notification_emails: $notification_emails, password: $password, recipients: $recipients, require_email: $require_email, resources: $resources, sending_local_files: $sending_local_files, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Complete send files
#
# POST /shares/complete-send/{id}
# Returns: record<data: record<attributes: record<accessDescription: string, accessMode: record, created: string, embed: bool, expiration: string, expired: bool, fileDropCreateFolders: bool, formId: int, hasNotification: bool, hasPassword: bool, hash: string, inherited: bool, messages: list, modified: string, name: string, ownerHash: string, paths: list, public: bool, recipients: list, requireEmail: bool, resent: string, status: int, trackingStatus: string, type: string>, id: int, relationships: record<messages: list, notifications: list, owner: record, resources: list>, type: string>, included: list<any>, responseStatus: int>
# operationId: completeDirectSend
export def "complete-direct-send" [
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
  --ev-api-key: string # API Key (required, e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access Token (required, e.g. 19853ef63a0bc348024a9e4cfd4a92520d2dfd04e88d8679fb1ed6bc551593d1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/shares/complete-send/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deactivate a share
#
# DELETE /shares/{id}
# Returns: record<data: list<string>, responseStatus: int>
# operationId: deleteShareById
export def "delete-share-by-id" [
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
  --ev-api-key: string # API Key required to make the API call. (required, e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/shares/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a share
#
# GET /shares/{id}
# Returns: record<data: record<attributes: record<accessDescription: string, accessMode: record, created: string, embed: bool, expiration: string, expired: bool, fileDropCreateFolders: bool, formId: int, hasNotification: bool, hasPassword: bool, hash: string, inherited: bool, messages: list, modified: string, name: string, ownerHash: string, paths: list, public: bool, recipients: list, requireEmail: bool, resent: string, status: int, trackingStatus: string, type: string>, id: int, relationships: record<messages: list, notifications: list, owner: record, resources: list>, type: string>, included: list<any>, responseStatus: int>
# operationId: getShareById
export def "get-share-by-id" [
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
  --include: string # Comma separated list of relationships to include in response. Possible values are **owner**, **resources**, **notifications**, **activity**. (e.g. owner,notifications)
  --ev-api-key: string # API Key (required, e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access Token (required, e.g. 19853ef63a0bc348024a9e4cfd4a92520d2dfd04e88d8679fb1ed6bc551593d1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/shares/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: include, var: include}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include: $include, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a share
#
# PATCH /shares/{id}
# Returns: record<data: record<attributes: record<accessDescription: string, accessMode: record, created: string, embed: bool, expiration: string, expired: bool, fileDropCreateFolders: bool, formId: int, hasNotification: bool, hasPassword: bool, hash: string, inherited: bool, messages: list, modified: string, name: string, ownerHash: string, paths: list, public: bool, recipients: list, requireEmail: bool, resent: string, status: int, trackingStatus: string, type: string>, id: int, relationships: record<messages: list, notifications: list, owner: record, resources: list>, type: string>, included: list<any>, responseStatus: int>
# operationId: updateShareById
export def "update-share-by-id" [
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
  --ev-api-key: string # API Key (required, e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access Token (required, e.g. 19853ef63a0bc348024a9e4cfd4a92520d2dfd04e88d8679fb1ed6bc551593d1)
  --access-mode: record # An object defining what a not-logged-in visitor can do with the share contents — shape: {delete?: bool, download?: bool, modify?: bool, upload?: bool}
  --embed: oneof<nothing, bool> # Whether the share can be embedded in another web page. (e.g. false)
  --expiration: string # New expiration date and time for the share (format: date-time, e.g. 2017-09-25T14:12:10Z)
  --file-drop-create-folders: oneof<nothing, bool> # Whether uploads to a receive folder should be automatically placed into subfolders. See our [receive folder documentation](/docs/account/05-file-sharing/05-form-builder#advanced-form-settings) (e.g. false)
  --has-notification: oneof<nothing, bool> # Whether delivery receipts should be sent for this share. (e.g. false)
  --is-public: oneof<nothing, bool> # Whether people can visit the share without following a link from an invitation email (e.g. true)
  --message-body: string # Message content to use for emails inviting recipients to the share. Ignored if you have not also provided `recipients` and a `subject`
  --message-subject: string # Subject to use on emails inviting recipients to the share. Ignored if you have not also provided `recipients` and a `message` (e.g. Invitation to a shared folder)
  --name: string # Name of the share. (e.g. Shared Folder)
  --notification-emails: list<string> # List of email addresses to send delivery receipts to. Ignored if `hasNotification` is false. (e.g. [notify@example.com, notify2@example.com])
  --password: string # New password for the share. To leave the password unchanged, do not send this parameter.
  --recipients: list # People you want to invite to the share. **Note**: unless you also set the `subject` and `message` for the new share, invitation emails will not be sent to these recipients. **Note**: Recipients in this list will **REPLACE** the recipients already assigned to this share. — item shape: {email?: string, type?: string}
  --require-email: oneof<nothing, bool> # Whether visitors to the share will be required to enter their email in order to access the share. (e.g. false)
  --resources: list<string> # Array of resources for this share. See details on [how to specify resources](#section/Identifying-Resources) above. **shared_folder** and **receive** shares must have only one `resource`, which is a directory that does not have a current share attached. **send** shares may have multiple `resource` parameters. **NOTE**: Sending this parameter will **REPLACE** the existing resources with the resources included in this request. (e.g. [/testfolder])
  --status: int # New status for the share. You can set an active share to inactive by setting the status to **0**
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/shares/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: accessMode, var: access_mode}, {name: embed, var: embed}, {name: expiration, var: expiration}, {name: fileDropCreateFolders, var: file_drop_create_folders}, {name: hasNotification, var: has_notification}, {name: isPublic, var: is_public}, {name: messageBody, var: message_body}, {name: messageSubject, var: message_subject}, {name: name, var: name}, {name: notificationEmails, var: notification_emails}, {name: password, var: password}, {name: recipients, var: recipients}, {name: requireEmail, var: require_email}, {name: resources, var: resources}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token, access_mode: $access_mode, embed: $embed, expiration: $expiration, file_drop_create_folders: $file_drop_create_folders, has_notification: $has_notification, is_public: $is_public, message_body: $message_body, message_subject: $message_subject, name: $name, notification_emails: $notification_emails, password: $password, recipients: $recipients, require_email: $require_email, resources: $resources, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get metadata for a list of SSH Keys
#
# GET /ssh-keys
# Returns: record<data: table<attributes: record, id: int, relationships: record, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int, returnedResults: int, totalResults: int>
# operationId: getSSHKeysList
export def "get-ssh-keys-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # Only return results for the given user ID. This is not the username, but the numeric ID of the user.
  --limit: int # Limits the results by the given number. Cannot be set higher than 100.
  --offset: int # Determines which item to start on for pagination. Use zero (0) to start at the beginning of the list.
  --ev-api-key: string # API key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ssh-keys"
    query: [{name: userId, var: user_id}, {name: limit, var: limit}, {name: offset, var: offset}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, limit: $limit, offset: $offset, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new SSH Key
#
# POST /ssh-keys
# Returns: record<data: record<attributes: record<created: string, fingerprint: string, lastLogin: string>, id: int, relationships: record<ownerUser: record>, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int>
# operationId: addSSHKey
export def "add-ssh-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  public_key: string # Public Key to provide ExaVault. You can provide the Public Key as formatted from the ssh-keygen command or a standard rfc-4716 format.
  user_id: int # ID of the user to assign the new key to.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ssh-keys"
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: publicKey, var: public_key}, {name: userId, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ev_api_key: $ev_api_key, ev_access_token: $ev_access_token, public_key: $public_key, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an SSH Key
#
# DELETE /ssh-keys/{id}
# operationId: deleteSSHKey
export def "delete-ssh-key" [
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
  --ev-api-key: string # API key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> any {
  http-request {
    method: delete
    path: "/ssh-keys/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get metadata for an SSH Key
#
# GET /ssh-keys/{id}
# Returns: record<data: record<attributes: record<created: string, fingerprint: string, lastLogin: string>, id: int, relationships: record<ownerUser: record>, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int>
# operationId: getSSHKey
export def "get-ssh-key" [
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
  --ev-api-key: string # API key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ssh-keys/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of users
#
# GET /users
# Returns: record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int, returnedResults: int, totalResults: int>
# operationId: listUsers
export def "list-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # The username of the user you are looking for. Only entries with the same username as this will be in the list of results. Does not support wildcard searches. (e.g. testuser)
  --home-resource: string # Resource identifier for user's home directory. Does not support wildcard searches.
  --nickname: string # Nickname to search for. Ignored if `username` is provided. Supports wildcard searches.
  --email: string # Email to search for. Ignored if `username` is provided. Supports wildcard searches (e.g. *@example.co)
  --role: string # Types of users to include the list. Ignored if `username` is provided. Valid options are **admin**, **master** and **user** (e.g. use)
  --status: int # Whether a user is locked. Ignored if `username` is provided. **0** means user is locked, **1** means user is not locked.
  --search: string # Searches the nickname, email, role and homeDir fields for the provided value. Ignored if `username` is provided. Supports wildcard searches.
  --offset: int # Starting user record in the result set. Can be used for pagination. (format: int32, e.g. 50)
  --sort: string # Sort order or matching users. You can sort by multiple columns by separating sort options with a comma; the sort will be applied in the order specified. The sort order for each sort field is ascending unless it is prefixed with a minus (“-“), in which case it will be descending. Valid sort fields are: **nickname**, **username**, **email**, **homeDir** and **modified** (e.g. homeDir,-modified)
  --limit: int # Number of users to return. Can be used for pagination. (format: int32, e.g. 100)
  --include: string # Comma separated list of relationships to include in response. Valid options are **homeResource** and **ownerAccount**. (e.g. homeResource,ownerAccount)
  --ev-api-key: string # API key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users"
    query: [{name: username, var: username}, {name: homeResource, var: home_resource}, {name: nickname, var: nickname}, {name: email, var: email}, {name: role, var: role}, {name: status, var: status}, {name: search, var: search}, {name: offset, var: offset}, {name: sort, var: sort}, {name: limit, var: limit}, {name: include, var: include}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, home_resource: $home_resource, nickname: $nickname, email: $email, role: $role, status: $status, search: $search, offset: $offset, sort: $sort, limit: $limit, include: $include, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a user
#
# POST /users
# Returns: record<data: record<attributes: record<accessTimestamp: string, accountName: string, created: string, email: string, expiration: string, firstLogin: bool, homePath: string, locked: bool, modified: string, nickname: string, onboarding: bool, permissions: record, role: string, status: int, timeZone: string, username: string>, id: int, relationships: record<homeResource: record, ownerAccount: record>, type: string>, included: list<any>, responseStatus: int>
# operationId: addUser
export def "add-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API key required to make the API call (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  email: string # Email address for the user (format: email, e.g. testuser@example.com)
  --expiration: string # Optional timestamp when the user should expire, formatted in date-time. (e.g. 2011-03-21 00:18:56)
  home_resource: string # Resource identifier for the user's home folder. See details on [how to specify resources](#section/Identifying-Resources) above. The user will be locked to this directory and unable to move 'up' in the account. If the folder does not exist in the account, it will be created when the user is created. Users with the `role` **admin** should have their homeResource set to '/' (e.g. /)
  --locked: oneof<nothing, bool> # If true, the user will not be able to log in (e.g. true)
  --nickname: string # An optional nickname (e.g. 'David from Sales'). (e.g. testnickname)
  --onboarding: oneof<nothing, bool> # Set this to **true** to enable extra help popups in the web file manager for this user. (e.g. true)
  password: string # Password for the user
  permissions: record # An object containing name/value pairs for each permission. Any permission that is not passed will be set to `false` by default. Note that users will be unable to see any files in the account unless you include `list` permission. When creating a user with the `role` **admin**, you should set all of the permissions to `true` — shape: {changePassword?: bool, delete?: bool, deleteFormData?: bool, download?: bool, list?: bool, modify?: bool, notification?: bool, share?: bool, upload?: bool, viewFormData?: bool}
  role: string@role-completer # The type of user to create, either **user** or **admin**. (e.g. user)
  time_zone: string # Time zone, used for accurate time display within the application. See this page for allowed values. (e.g. America/Los_Angeles)
  username: string # Username of the user to create. This should follow standard username conventions - spaces are not allowed, etc. We do allow email addresses as usernames. **Note** Usernames must be unique across all ExaVault accounts. (e.g. testuser)
  --welcome-email: oneof<nothing, bool> # If **true**, send this new user a welcome email upon creation. The content of the welcome email can be configured with the [PATCH /accounts](#operation/updateAccount) method. (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users"
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: expiration, var: expiration}, {name: homeResource, var: home_resource}, {name: locked, var: locked}, {name: nickname, var: nickname}, {name: onboarding, var: onboarding}, {name: password, var: password}, {name: permissions, var: permissions}, {name: role, var: role}, {name: timeZone, var: time_zone}, {name: username, var: username}, {name: welcomeEmail, var: welcome_email}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    ev_api_key: $ev_api_key, ev_access_token: $ev_access_token, email: $email, expiration: $expiration, home_resource: $home_resource, locked: $locked, nickname: $nickname, onboarding: $onboarding, password: $password, permissions: $permissions, role: $role, time_zone: $time_zone, username: $username, welcome_email: $welcome_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a user
#
# DELETE /users/{id}
# Returns: record<data: list<string>, responseStatus: int>
# operationId: deleteUser
export def "delete-user" [
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
  --ev-api-key: string # API Key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 19853ef63a0bc348024a9e4cfd4a92520d2dfd04e88d8679fb1ed6bc551593d1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/users/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get info for a user
#
# GET /users/{id}
# Returns: record<data: record<attributes: record<accessTimestamp: string, accountName: string, created: string, email: string, expiration: string, firstLogin: bool, homePath: string, locked: bool, modified: string, nickname: string, onboarding: bool, permissions: record, role: string, status: int, timeZone: string, username: string>, id: int, relationships: record<homeResource: record, ownerAccount: record>, type: string>, included: list<any>, responseStatus: int>
# operationId: getUserById
export def "get-user-by-id" [
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
  --include: string # Comma-separated list of relationships to include in response. Possible values include **homeResource** and **ownerAccount**. (e.g. homeResource,ownerAccount)
  --ev-api-key: string # API Key (required, e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 19853ef63a0bc348024a9e4cfd4a92520d2dfd04e88d8679fb1ed6bc551593d1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: include, var: include}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include: $include, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a user
#
# PATCH /users/{id}
# Returns: record<data: record<attributes: record<accessTimestamp: string, accountName: string, created: string, email: string, expiration: string, firstLogin: bool, homePath: string, locked: bool, modified: string, nickname: string, onboarding: bool, permissions: record, role: string, status: int, timeZone: string, username: string>, id: int, relationships: record<homeResource: record, ownerAccount: record>, type: string>, included: list<any>, responseStatus: int>
# operationId: updateUser
export def "update-user" [
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
  --ev-api-key: string # API key required to make the API call. (required, e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 19853ef63a0bc348024a9e4cfd4a92520d2dfd04e88d8679fb1ed6bc551593d1)
  --email: string # Email address for the user (format: email, e.g. testuser@example.com)
  --expiration: string # Optional timestamp when the user should expire. (e.g. 2011-03-21 00:18:56)
  --home-resource: string # Resource identifier for the user's home folder. See details on [how to specify resources](#section/Identifying-Resources) above. The user will be locked to this directory and unable to move 'up' in the account. If the folder does not exist in the account, it will be created when the user logs in. This setting is ignored for users with the `role` **admin**. (e.g. /)
  --locked: oneof<nothing, bool> # If true, the user will be prevented from logging in (e.g. true)
  --nickname: string # An optional nickname (e.g. 'David from Sales'). (e.g. testnickname)
  --onboarding: oneof<nothing, bool> # Set this to **true** to enable extra help popups in the web file manager for this user. (e.g. true)
  --password: string # New password for the user
  --permissions: record # shape: {changePassword: bool, delete: bool, deleteFormData: bool, download: bool, list: bool, modify: bool, notification: bool, share: bool, upload: bool, viewFormData: bool}
  --role: string@role-completer # The type of user (**admin** or **user**). Note that admin users cannot have a `homeResource` other than '/', and will have full permissions, but you must provide at least "download,upload,list,delete" in the `permissions` parameter. (e.g. user)
  --time-zone: string # Time zone, used for accurate time display within the application. See this page for allowed values. (e.g. America/Los_Angeles)
  --username: string # New username for the user. This should follow standard username conventions - spaces are not allowed, etc. We do allow email addresses as usernames. **Note** Usernames must be unique across all ExaVault accounts. (e.g. testuser)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/users/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: expiration, var: expiration}, {name: homeResource, var: home_resource}, {name: locked, var: locked}, {name: nickname, var: nickname}, {name: onboarding, var: onboarding}, {name: password, var: password}, {name: permissions, var: permissions}, {name: role, var: role}, {name: timeZone, var: time_zone}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token, email: $email, expiration: $expiration, home_resource: $home_resource, locked: $locked, nickname: $nickname, onboarding: $onboarding, password: $password, permissions: $permissions, role: $role, time_zone: $time_zone, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Webhooks List
#
# GET /webhooks
# Returns: record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int, returnedResults: int, totalResults: int>
# operationId: getWehooksList
export def "get-wehooks-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string # List of related record types to include. Valid options are `owningAccount` and `resource`
  --offset: int # Records to skip before returning results. (e.g. 100)
  --limit: int # Limit of the records list (e.g. 100)
  --ev-api-key: string # API key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/webhooks"
    query: [{name: include, var: include}, {name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    include: $include, offset: $offset, limit: $limit, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add A New Webhook
#
# POST /webhooks
# Returns: record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int>
# operationId: addWebhook
export def "add-webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  endpoint_url: string # The endpoint is where the webhook request will be sent. (format: uri, e.g. https://example.com/webhook)
  --resource: string # Resource identifier for the top folder this webhook is associated with (e.g. /uploads-folder)
  --response-version: string@response-version-completer # What version of webhook request should be sent to the endpoint URL when messages are sent (e.g. v2)
  --triggers: record # shape: {resources?: record, shares?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/webhooks"
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: endpointUrl, var: endpoint_url}, {name: resource, var: resource}, {name: responseVersion, var: response_version}, {name: triggers, var: triggers}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    ev_api_key: $ev_api_key, ev_access_token: $ev_access_token, endpoint_url: $endpoint_url, resource: $resource, response_version: $response_version, triggers: $triggers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Regenerate security token
#
# POST /webhooks/regenerate-token/{id}
# Returns: record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int>
# operationId: regenerateWebhookToken
export def "regenerate-webhook-token" [
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
  --ev-api-key: string # API key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/webhooks/regenerate-token/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resend a webhook message
#
# POST /webhooks/resend/{activityId}
# Returns: record<data: list<string>, responseStatus: int>
# operationId: resendWebhookActivityEntry
export def "resend-webhook-activity-entry" [
  activity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/webhooks/resend/{activityId}"
    path_params: [{name: activityId, var: activity_id}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    activity_id: $activity_id, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a webhook
#
# DELETE /webhooks/{id}
# Returns: record<data: list<string>, responseStatus: int>
# operationId: deleteWebhook
export def "delete-webhook" [
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
  --ev-api-key: string # API key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/webhooks/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get info for a webhook
#
# GET /webhooks/{id}
# Returns: record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int>
# operationId: getWebhookById
export def "get-webhook-by-id" [
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
  --include: string # Include metadata for related items; `ownerAccount` and/or `resource`
  --ev-api-key: string # API key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/webhooks/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: include, var: include}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include: $include, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a webhook
#
# PATCH /webhooks/{id}
# Returns: record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int>
# operationId: updateWebhook
export def "update-webhook" [
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
  --ev-api-key: string # API key required to make the API call. (required)
  --ev-access-token: string # Access token required to make the API call. (required, e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  --endpoint-url: string # New endpoint URL to use for the webhook configuration (format: uri, e.g. https://example.com/new-endpoint)
  --resource: string # Resource identifier of the top folder watched by this webhook. (e.g. /newfolder)
  --response-version: string@response-version-completer # Version of the webhooks message to send to the endpoint (e.g. v1)
  --triggers: record # shape: {resources?: record, shares?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/webhooks/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: ev-api-key, var: ev_api_key, required: true}, {name: ev-access-token, var: ev_access_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: endpointUrl, var: endpoint_url}, {name: resource, var: resource}, {name: responseVersion, var: response_version}, {name: triggers, var: triggers}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ev_api_key: $ev_api_key, ev_access_token: $ev_access_token, endpoint_url: $endpoint_url, resource: $resource, response_version: $response_version, triggers: $triggers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
