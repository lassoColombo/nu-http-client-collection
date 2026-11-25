# Auto-generated client for VocaDbWeb v1.0
# Source: https://api.apis.guru/v2/specs/vocadb.net/1.0/openapi.json
# Auth: --token flag or $env.VOCADBWEB_TOKEN

const CLIENT = {
  base_url: "https://api.apis.guru"
  token_env_var: "VOCADBWEB_TOKEN"
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

def base-url-completer [] { ["https://api.apis.guru"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def edit-event-completer [] { ["Created" "Deleted" "Restored" "Updated"] }
def entry-type-completer [] { ["Album" "Artist" "DiscussionTopic" "PV" "ReleaseEvent" "ReleaseEventSeries" "Song" "SongList" "Tag" "Undefined" "User" "Venue"] }
def fields-completer [] { ["ArchivedVersion" "Entry" "None"] }
def entry-fields-completer [] { ["AdditionalNames" "Description" "MainPicture" "Names" "None" "PVs" "Tags" "WebLinks"] }
def lang-completer [] { ["Default" "English" "Japanese" "Romaji"] }
def sort-rule-completer [] { ["CreateDate" "CreateDateDescending"] }
def accept-completer [] { ["application/json" "text/json" "text/plain"] }
def disc-types-completer [] { ["Album" "Artbook" "Compilation" "EP" "Fanmade" "Game" "Instrumental" "Other" "Single" "SplitAlbum" "Unknown" "Video"] }
def artist-participation-status-completer [] { ["Everything" "OnlyCollaborations" "OnlyMainAlbums"] }
def status-completer [] { ["Approved" "Draft" "Finished" "Locked"] }
def sort-completer [] { ["AdditionDate" "CollectionCount" "Name" "NameThenReleaseDate" "None" "RatingAverage" "RatingTotal" "ReleaseDate" "ReleaseDateWithNulls"] }
def name-match-mode-completer [] { ["Auto" "Exact" "Partial" "StartsWith" "Words"] }
def fields-completer-1 [] { ["AdditionalNames" "Artists" "Description" "Discs" "Identifiers" "MainPicture" "Names" "None" "PVs" "ReleaseEvent" "Tags" "Tracks" "WebLinks"] }
def language-preference-completer [] { ["Default" "English" "Japanese" "Romaji"] }
def song-fields-completer [] { ["AdditionalNames" "Albums" "Artists" "Bpm" "Lyrics" "MainPicture" "Names" "None" "PVs" "ReleaseEvent" "Tags" "ThumbUrl" "WebLinks"] }
def fields-completer-2 [] { ["AdditionalNames" "Albums" "Artists" "Bpm" "Lyrics" "MainPicture" "Names" "None" "PVs" "ReleaseEvent" "Tags" "ThumbUrl" "WebLinks"] }
def sort-completer-1 [] { ["AdditionDate" "AdditionDateAsc" "ArtistType" "FollowerCount" "Name" "None" "ReleaseDate" "SongCount" "SongRating"] }
def fields-completer-3 [] { ["AdditionalNames" "ArtistLinks" "ArtistLinksReverse" "BaseVoicebank" "Description" "MainPicture" "Names" "None" "Tags" "WebLinks"] }
def relations-completer [] { ["All" "LatestAlbums" "LatestEvents" "LatestSongs" "None" "PopularAlbums" "PopularSongs"] }
def fields-completer-4 [] { ["Entry" "None"] }
def fields-completer-5 [] { ["LastTopic" "None" "TopicCount"] }
def fields-completer-6 [] { ["All" "CommentCount" "Comments" "Content" "LastComment" "None"] }
def sort-completer-2 [] { ["DateCreated" "LastCommentDate" "Name" "None"] }
def entry-types-completer [] { ["Album" "Artist" "DiscussionTopic" "Nothing" "PV" "ReleaseEvent" "ReleaseEventSeries" "Song" "SongList" "Tag" "User" "Venue"] }
def sort-completer-3 [] { ["ActivityDate" "AdditionDate" "Name" "None"] }
def fields-completer-7 [] { ["AdditionalNames" "Description" "MainPicture" "Names" "None" "PVs" "Tags" "WebLinks"] }
def fields-completer-8 [] { ["AdditionalNames" "AliasedTo" "Description" "MainPicture" "Names" "None" "Parent" "RelatedTags" "TranslatedDescription" "WebLinks"] }
def service-completer [] { ["Bandcamp" "Bilibili" "Creofuga" "File" "LocalFile" "NicoNicoDouga" "Piapro" "SoundCloud" "Vimeo" "Youtube"] }
def fields-completer-9 [] { ["AdditionalNames" "Description" "Events" "MainPicture" "Names" "None" "WebLinks"] }
def category-completer [] { ["AlbumRelease" "Anniversary" "Club" "Concert" "Contest" "Convention" "Festival" "Other" "Unspecified"] }
def sort-completer-4 [] { ["AdditionDate" "Date" "Name" "None" "SeriesName" "VenueName"] }
def fields-completer-10 [] { ["AdditionalNames" "Artists" "Description" "MainPicture" "Names" "None" "PVs" "Series" "SongList" "Tags" "Venue" "WebLinks"] }
def sort-direction-completer [] { ["Ascending" "Descending"] }
def report-type-completer [] { ["Duplicate" "Inappropriate" "InvalidInfo" "Other"] }
def featured-category-completer [] { ["Concerts" "Nothing" "Other" "Pools" "VocaloidRanking"] }
def sort-completer-5 [] { ["CreateDate" "Date" "Name" "None"] }
def fields-completer-11 [] { ["Description" "Events" "MainPicture" "None" "Tags"] }
def pv-services-completer [] { ["Bandcamp" "Bilibili" "Creofuga" "File" "LocalFile" "NicoNicoDouga" "Nothing" "Piapro" "SoundCloud" "Vimeo" "Youtube"] }
def sort-completer-6 [] { ["AdditionDate" "FavoritedTimes" "Name" "None" "PublishDate" "RatingScore" "SongType" "TagUsageCount"] }
def pv-service-completer [] { ["Bandcamp" "Bilibili" "Creofuga" "File" "LocalFile" "NicoNicoDouga" "Piapro" "SoundCloud" "Vimeo" "Youtube"] }
def filter-by-completer [] { ["CreateDate" "Popularity" "PublishDate"] }
def vocalist-completer [] { ["Nothing" "Other" "UTAU" "Vocaloid"] }
def user-fields-completer [] { ["KnownLanguages" "MainPicture" "None" "OldUsernames"] }
def rating-completer [] { ["Dislike" "Favorite" "Like" "Nothing"] }
def sort-completer-7 [] { ["AdditionDate" "Name" "Nothing" "UsageCount"] }
def target-completer [] { ["Album" "AlbumArtist" "AlbumSong" "All" "Artist" "ArtistSong" "Event" "Nothing" "Song" "SongList"] }
def groups-completer [] { ["Admin" "Limited" "Moderator" "Nothing" "Regular" "Trusted"] }
def sort-completer-8 [] { ["Group" "Name" "RegisterDate"] }
def fields-completer-12 [] { ["KnownLanguages" "MainPicture" "None" "OldUsernames"] }
def collection-status-completer [] { ["Nothing" "Ordered" "Owned" "Wishlisted"] }
def media-type-completer [] { ["DigitalDownload" "Other" "PhysicalDisc"] }
def purchase-statuses-completer [] { ["All" "Nothing" "Ordered" "Owned" "Wishlisted"] }
def album-types-completer [] { ["Album" "Artbook" "Compilation" "EP" "Fanmade" "Game" "Instrumental" "Other" "Single" "SplitAlbum" "Unknown" "Video"] }
def relationship-type-completer [] { ["Attending" "Interested"] }
def artist-type-completer [] { ["Animator" "Band" "CeVIO" "Character" "Circle" "CoverArtist" "Illustrator" "Label" "Lyricist" "OtherGroup" "OtherIndividual" "OtherVocalist" "OtherVoiceSynthesizer" "Producer" "SynthesizerV" "UTAU" "Unknown" "Utaite" "Vocalist" "Vocaloid"] }
def inbox-completer [] { ["Nothing" "Notifications" "Received" "Sent"] }
def artist-grouping-completer [] { ["And" "Or"] }
def sort-completer-9 [] { ["AdditionDate" "FavoritedTimes" "Name" "None" "PublishDate" "RatingDate" "RatingScore"] }
def report-type-completer-1 [] { ["MaliciousIP" "Other" "RemovePermissions" "Spamming"] }
def fields-completer-13 [] { ["AdditionalNames" "Description" "Events" "Names" "None" "WebLinks"] }
def sort-rule-completer-1 [] { ["Distance" "Name" "None"] }
def distance-unit-completer [] { ["Kilometers" "Miles"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-api-activity-entries: "record<items: table<archivedVersion: record, author: record, createDate: string, editEvent: string, entry: record>, term: string, totalCount: int>"
    get-api-albums: "record<items: table<additionalNames: string, artistString: string, artists: list, barcode: string, catalogNumber: string, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, discType: string, discs: list, id: int, identifiers: list, mainPicture: record, mergedTo: int, name: string, names: list, pvs: list, ratingAverage: float, ratingCount: int, releaseDate: record, releaseEvent: record, status: string, tags: list, tracks: list, version: int, webLinks: list>, term: string, totalCount: int>"
    get-api-albums-names: "list<string>"
    get-api-albums-new: "table<additionalNames: string, artistString: string, artists: list<record>, barcode: string, catalogNumber: string, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, discType: string, discs: list<record>, id: int, identifiers: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: list<record>, pvs: list<record>, ratingAverage: float, ratingCount: int, releaseDate: record<day: int, formatted: string, isEmpty: bool, month: int, year: int>, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, status: string, tags: list<record>, tracks: list<record>, version: int, webLinks: list<record>>"
    get-api-albums-top: "table<additionalNames: string, artistString: string, artists: list<record>, barcode: string, catalogNumber: string, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, discType: string, discs: list<record>, id: int, identifiers: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: list<record>, pvs: list<record>, ratingAverage: float, ratingCount: int, releaseDate: record<day: int, formatted: string, isEmpty: bool, month: int, year: int>, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, status: string, tags: list<record>, tracks: list<record>, version: int, webLinks: list<record>>"
    get-api-albums-id: "record<additionalNames: string, artistString: string, artists: table<artist: record, categories: string, effectiveRoles: string, isSupport: bool, name: string, roles: string>, barcode: string, catalogNumber: string, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, discType: string, discs: table<discNumber: int, id: int, mediaType: string, name: string>, id: int, identifiers: table<value: string>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: table<language: string, value: string>, pvs: table<author: string, createdBy: int, disabled: bool, extendedMetadata: record, id: int, length: int, name: string, publishDate: string, pvId: string, pvType: string, service: string, thumbUrl: string, url: string>, ratingAverage: float, ratingCount: int, releaseDate: record<day: int, formatted: string, isEmpty: bool, month: int, year: int>, releaseEvent: record<additionalNames: string, artists: list<record>, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, series: record<additionalNames: string, category: string, deleted: bool, description: string, id: int, name: string, pictureMime: string, status: string, urlSlug: string, version: int, webLinks: list>, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record<featuredCategory: string, id: int, name: string>, status: string, tags: list<record>, urlSlug: string, venue: record<additionalNames: string, address: string, addressCountryCode: string, coordinates: record, deleted: bool, description: string, events: list, id: int, name: string, names: list, status: string, version: int, webLinks: list>, venueName: string, version: int, webLinks: list<record>>, status: string, tags: table<count: int, tag: record>, tracks: table<discNumber: int, id: int, name: string, rating: string, song: record, trackNumber: int>, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>>"
    get-api-albums-id-comments: "table<author: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record, name: string, names: list, pvs: list, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list, urlSlug: string, version: int, webLinks: list>, id: int, message: string>"
    post-api-albums-id-comments: "record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list<record>, urlSlug: string, version: int, webLinks: list<record>>, id: int, message: string>"
    get-api-albums-id-reviews: "table<albumId: int, date: string, id: int, languageCode: string, text: string, title: string, user: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>>"
    post-api-albums-id-reviews: "record<albumId: int, date: string, id: int, languageCode: string, text: string, title: string, user: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>>"
    get-api-albums-id-tracks: "table<discNumber: int, id: int, name: string, rating: string, song: record<additionalNames: string, albums: list, artistString: string, artists: list, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list, mainPicture: record, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list, originalVersionId: int, publishDate: string, pvServices: string, pvs: list, ratingScore: int, releaseEvent: record, songType: string, status: string, tags: list, thumbUrl: string, version: int, webLinks: list>, trackNumber: int>"
    get-api-albums-id-tracks-fields: "list<record>"
    get-api-albums-id-user-collections: "table<album: record<additionalNames: string, artistString: string, artists: list, barcode: string, catalogNumber: string, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, discType: string, discs: list, id: int, identifiers: list, mainPicture: record, mergedTo: int, name: string, names: list, pvs: list, ratingAverage: float, ratingCount: int, releaseDate: record, releaseEvent: record, status: string, tags: list, tracks: list, version: int, webLinks: list>, mediaType: string, purchaseStatus: string, rating: int, user: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>>"
    get-api-artists: "record<items: table<additionalNames: string, artistLinks: list, artistLinksReverse: list, artistType: string, baseVoicebank: record, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, id: int, mainPicture: record, mergedTo: int, name: string, names: list, pictureMime: string, relations: record, releaseDate: string, status: string, tags: list, version: int, webLinks: list>, term: string, totalCount: int>"
    get-api-artists-names: "list<string>"
    get-api-artists-id: "record<additionalNames: string, artistLinks: table<artist: record, linkType: string>, artistLinksReverse: table<artist: record, linkType: string>, artistType: string, baseVoicebank: record<additionalNames: string, artistType: string, deleted: bool, id: int, name: string, pictureMime: string, releaseDate: string, status: string, version: int>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: table<language: string, value: string>, pictureMime: string, relations: record<latestAlbums: list<record>, latestEvents: list<record>, latestSongs: list<record>, popularAlbums: list<record>, popularSongs: list<record>>, releaseDate: string, status: string, tags: table<count: int, tag: record>, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>>"
    get-api-artists-id-comments: "table<author: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record, name: string, names: list, pvs: list, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list, urlSlug: string, version: int, webLinks: list>, id: int, message: string>"
    post-api-artists-id-comments: "record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list<record>, urlSlug: string, version: int, webLinks: list<record>>, id: int, message: string>"
    get-api-comments: "record<items: table<author: record, authorName: string, created: string, entry: record, id: int, message: string>, term: string, totalCount: int>"
    get-api-comments-entry-type-comments: "record<items: table<author: record, authorName: string, created: string, entry: record, id: int, message: string>, term: string, totalCount: int>"
    post-api-comments-entry-type-comments: "record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list<record>, urlSlug: string, version: int, webLinks: list<record>>, id: int, message: string>"
    get-api-discussions-folders: "table<description: string, id: int, lastTopicAuthor: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>, lastTopicDate: string, name: string, topicCount: int>"
    post-api-discussions-folders: "record<description: string, id: int, lastTopicAuthor: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, lastTopicDate: string, name: string, topicCount: int>"
    get-api-discussions-folders-folder-id-topics: "table<author: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>, commentCount: int, comments: list<record>, content: string, created: string, folderId: int, id: int, lastComment: record<author: record, authorName: string, created: string, entry: record, id: int, message: string>, locked: bool, name: string>"
    post-api-discussions-folders-folder-id-topics: "record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, commentCount: int, comments: table<author: record, authorName: string, created: string, entry: record, id: int, message: string>, content: string, created: string, folderId: int, id: int, lastComment: record<author: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record, name: string, names: list, pvs: list, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list, urlSlug: string, version: int, webLinks: list>, id: int, message: string>, locked: bool, name: string>"
    get-api-discussions-topics: "record<items: table<author: record, commentCount: int, comments: list, content: string, created: string, folderId: int, id: int, lastComment: record, locked: bool, name: string>, term: string, totalCount: int>"
    get-api-discussions-topics-topic-id: "record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, commentCount: int, comments: table<author: record, authorName: string, created: string, entry: record, id: int, message: string>, content: string, created: string, folderId: int, id: int, lastComment: record<author: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record, name: string, names: list, pvs: list, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list, urlSlug: string, version: int, webLinks: list>, id: int, message: string>, locked: bool, name: string>"
    post-api-discussions-topics-topic-id-comments: "record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list<record>, urlSlug: string, version: int, webLinks: list<record>>, id: int, message: string>"
    get-api-entries: "record<items: table<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record, name: string, names: list, pvs: list, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list, urlSlug: string, version: int, webLinks: list>, term: string, totalCount: int>"
    get-api-entries-names: "list<string>"
    get-api-entry-types-entry-type-sub-type-tag: "record<additionalNames: string, aliasedTo: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, categoryName: string, createDate: string, defaultNameLanguage: string, description: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: table<id: int, language: string, value: string>, parent: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, relatedTags: table<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, status: string, targets: int, translatedDescription: record<english: string, original: string>, urlSlug: string, usageCount: int, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>>"
    get-api-pvs-for-songs: "record<items: table<author: string, createdBy: int, disabled: bool, extendedMetadata: record, id: int, length: int, name: string, publishDate: string, pvId: string, pvType: string, service: string, song: record, thumbUrl: string, url: string>, term: string, totalCount: int>"
    get-api-release-event-series: "record<items: table<additionalNames: string, category: string, description: string, events: list, id: int, mainPicture: record, name: string, names: list, status: string, urlSlug: string, version: int, webLinks: list>, term: string, totalCount: int>"
    get-api-release-event-series-id: "record<additionalNames: string, category: string, description: string, events: table<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: table<language: string, value: string>, status: string, urlSlug: string, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>>"
    get-api-release-event-series-id-for-edit: "record<category: string, defaultNameLanguage: string, deleted: bool, description: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: table<id: int, language: string, value: string>, status: string, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>>"
    get-api-release-events: "record<items: table<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, term: string, totalCount: int>"
    get-api-release-events-names: "list<string>"
    get-api-release-events-event-id-albums: "table<additionalNames: string, artistString: string, artists: list<record>, barcode: string, catalogNumber: string, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, discType: string, discs: list<record>, id: int, identifiers: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: list<record>, pvs: list<record>, ratingAverage: float, ratingCount: int, releaseDate: record<day: int, formatted: string, isEmpty: bool, month: int, year: int>, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, status: string, tags: list<record>, tracks: list<record>, version: int, webLinks: list<record>>"
    get-api-release-events-event-id-published-songs: "table<additionalNames: string, albums: list<record>, artistString: string, artists: list<record>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list<record>, originalVersionId: int, publishDate: string, pvServices: string, pvs: list<record>, ratingScore: int, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, songType: string, status: string, tags: list<record>, thumbUrl: string, version: int, webLinks: list<record>>"
    get-api-release-events-id: "record<additionalNames: string, artists: table<artist: record, effectiveRoles: string, id: int, name: string, roles: string>, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: table<language: string, value: string>, pvs: table<author: string, createdBy: int, disabled: bool, extendedMetadata: record, id: int, length: int, name: string, publishDate: string, pvId: string, pvType: string, service: string, thumbUrl: string, url: string>, series: record<additionalNames: string, category: string, deleted: bool, description: string, id: int, name: string, pictureMime: string, status: string, urlSlug: string, version: int, webLinks: list<record>>, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record<featuredCategory: string, id: int, name: string>, status: string, tags: table<count: int, tag: record>, urlSlug: string, venue: record<additionalNames: string, address: string, addressCountryCode: string, coordinates: record<formatted: string, hasValue: bool, latitude: float, longitude: float>, deleted: bool, description: string, events: list<record>, id: int, name: string, names: list<record>, status: string, version: int, webLinks: list<record>>, venueName: string, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>>"
    get-api-resources-culture-code: "record"
    post-api-song-lists: "int"
    get-api-song-lists-featured: "record<items: table<author: record, deleted: bool, description: string, eventDate: string, events: list, featuredCategory: string, id: int, latestComments: list, mainPicture: record, name: string, status: string, tags: list>, term: string, totalCount: int>"
    get-api-song-lists-featured-names: "list<string>"
    get-api-song-lists-list-id-comments: "record<items: table<author: record, authorName: string, created: string, entry: record, id: int, message: string>, term: string, totalCount: int>"
    post-api-song-lists-list-id-comments: "record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list<record>, urlSlug: string, version: int, webLinks: list<record>>, id: int, message: string>"
    get-api-song-lists-list-id-songs: "record<items: table<notes: string, order: int, song: record>, term: string, totalCount: int>"
    get-api-songs: "record<items: table<additionalNames: string, albums: list, artistString: string, artists: list, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list, mainPicture: record, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list, originalVersionId: int, publishDate: string, pvServices: string, pvs: list, ratingScore: int, releaseEvent: record, songType: string, status: string, tags: list, thumbUrl: string, version: int, webLinks: list>, term: string, totalCount: int>"
    get-api-songs-by-pv: "record<additionalNames: string, albums: table<additionalNames: string, artistString: string, coverPictureMime: string, createDate: string, deleted: bool, discType: string, id: int, name: string, ratingAverage: float, ratingCount: int, releaseDate: record, releaseEvent: record, status: string, version: int>, artistString: string, artists: table<artist: record, categories: string, effectiveRoles: string, id: int, isCustomName: bool, isSupport: bool, name: string, roles: string>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: table<cultureCode: string, id: int, source: string, translationType: string, url: string, value: string>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: table<language: string, value: string>, originalVersionId: int, publishDate: string, pvServices: string, pvs: table<author: string, createdBy: int, disabled: bool, extendedMetadata: record, id: int, length: int, name: string, publishDate: string, pvId: string, pvType: string, service: string, thumbUrl: string, url: string>, ratingScore: int, releaseEvent: record<additionalNames: string, artists: list<record>, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, series: record<additionalNames: string, category: string, deleted: bool, description: string, id: int, name: string, pictureMime: string, status: string, urlSlug: string, version: int, webLinks: list>, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record<featuredCategory: string, id: int, name: string>, status: string, tags: list<record>, urlSlug: string, venue: record<additionalNames: string, address: string, addressCountryCode: string, coordinates: record, deleted: bool, description: string, events: list, id: int, name: string, names: list, status: string, version: int, webLinks: list>, venueName: string, version: int, webLinks: list<record>>, songType: string, status: string, tags: table<count: int, tag: record>, thumbUrl: string, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>>"
    get-api-songs-highlighted: "table<additionalNames: string, albums: list<record>, artistString: string, artists: list<record>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list<record>, originalVersionId: int, publishDate: string, pvServices: string, pvs: list<record>, ratingScore: int, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, songType: string, status: string, tags: list<record>, thumbUrl: string, version: int, webLinks: list<record>>"
    get-api-songs-lyrics-lyrics-id: "record<cultureCode: string, id: int, source: string, translationType: string, url: string, value: string>"
    get-api-songs-names: "list<string>"
    get-api-songs-top-rated: "table<additionalNames: string, albums: list<record>, artistString: string, artists: list<record>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list<record>, originalVersionId: int, publishDate: string, pvServices: string, pvs: list<record>, ratingScore: int, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, songType: string, status: string, tags: list<record>, thumbUrl: string, version: int, webLinks: list<record>>"
    get-api-songs-id: "record<additionalNames: string, albums: table<additionalNames: string, artistString: string, coverPictureMime: string, createDate: string, deleted: bool, discType: string, id: int, name: string, ratingAverage: float, ratingCount: int, releaseDate: record, releaseEvent: record, status: string, version: int>, artistString: string, artists: table<artist: record, categories: string, effectiveRoles: string, id: int, isCustomName: bool, isSupport: bool, name: string, roles: string>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: table<cultureCode: string, id: int, source: string, translationType: string, url: string, value: string>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: table<language: string, value: string>, originalVersionId: int, publishDate: string, pvServices: string, pvs: table<author: string, createdBy: int, disabled: bool, extendedMetadata: record, id: int, length: int, name: string, publishDate: string, pvId: string, pvType: string, service: string, thumbUrl: string, url: string>, ratingScore: int, releaseEvent: record<additionalNames: string, artists: list<record>, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, series: record<additionalNames: string, category: string, deleted: bool, description: string, id: int, name: string, pictureMime: string, status: string, urlSlug: string, version: int, webLinks: list>, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record<featuredCategory: string, id: int, name: string>, status: string, tags: list<record>, urlSlug: string, venue: record<additionalNames: string, address: string, addressCountryCode: string, coordinates: record, deleted: bool, description: string, events: list, id: int, name: string, names: list, status: string, version: int, webLinks: list>, venueName: string, version: int, webLinks: list<record>>, songType: string, status: string, tags: table<count: int, tag: record>, thumbUrl: string, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>>"
    get-api-songs-id-comments: "table<author: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record, name: string, names: list, pvs: list, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list, urlSlug: string, version: int, webLinks: list>, id: int, message: string>"
    post-api-songs-id-comments: "record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list<record>, urlSlug: string, version: int, webLinks: list<record>>, id: int, message: string>"
    get-api-songs-id-derived: "table<additionalNames: string, albums: list<record>, artistString: string, artists: list<record>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list<record>, originalVersionId: int, publishDate: string, pvServices: string, pvs: list<record>, ratingScore: int, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, songType: string, status: string, tags: list<record>, thumbUrl: string, version: int, webLinks: list<record>>"
    get-api-songs-id-ratings: "table<date: string, rating: string, song: record<additionalNames: string, albums: list, artistString: string, artists: list, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list, mainPicture: record, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list, originalVersionId: int, publishDate: string, pvServices: string, pvs: list, ratingScore: int, releaseEvent: record, songType: string, status: string, tags: list, thumbUrl: string, version: int, webLinks: list>, user: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>>"
    get-api-songs-id-related: "record<artistMatches: table<additionalNames: string, albums: list, artistString: string, artists: list, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list, mainPicture: record, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list, originalVersionId: int, publishDate: string, pvServices: string, pvs: list, ratingScore: int, releaseEvent: record, songType: string, status: string, tags: list, thumbUrl: string, version: int, webLinks: list>, likeMatches: table<additionalNames: string, albums: list, artistString: string, artists: list, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list, mainPicture: record, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list, originalVersionId: int, publishDate: string, pvServices: string, pvs: list, ratingScore: int, releaseEvent: record, songType: string, status: string, tags: list, thumbUrl: string, version: int, webLinks: list>, tagMatches: table<additionalNames: string, albums: list, artistString: string, artists: list, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list, mainPicture: record, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list, originalVersionId: int, publishDate: string, pvServices: string, pvs: list, ratingScore: int, releaseEvent: record, songType: string, status: string, tags: list, thumbUrl: string, version: int, webLinks: list>>"
    get-api-tags: "record<items: table<additionalNames: string, aliasedTo: record, categoryName: string, createDate: string, defaultNameLanguage: string, description: string, id: int, mainPicture: record, name: string, names: list, parent: record, relatedTags: list, status: string, targets: int, translatedDescription: record, urlSlug: string, usageCount: int, version: int, webLinks: list>, term: string, totalCount: int>"
    post-api-tags: "record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>"
    get-api-tags-by-name-name: "record<additionalNames: string, aliasedTo: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, categoryName: string, createDate: string, defaultNameLanguage: string, description: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: table<id: int, language: string, value: string>, parent: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, relatedTags: table<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, status: string, targets: int, translatedDescription: record<english: string, original: string>, urlSlug: string, usageCount: int, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>>"
    get-api-tags-category-names: "list<string>"
    get-api-tags-names: "list<string>"
    get-api-tags-top: "table<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>"
    get-api-tags-id: "record<additionalNames: string, aliasedTo: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, categoryName: string, createDate: string, defaultNameLanguage: string, description: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: table<id: int, language: string, value: string>, parent: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, relatedTags: table<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, status: string, targets: int, translatedDescription: record<english: string, original: string>, urlSlug: string, usageCount: int, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>>"
    get-api-tags-tag-id-children: "table<additionalNames: string, aliasedTo: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, categoryName: string, createDate: string, defaultNameLanguage: string, description: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, parent: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, relatedTags: list<record>, status: string, targets: int, translatedDescription: record<english: string, original: string>, urlSlug: string, usageCount: int, version: int, webLinks: list<record>>"
    get-api-tags-tag-id-comments: "record<items: table<author: record, authorName: string, created: string, entry: record, id: int, message: string>, term: string, totalCount: int>"
    post-api-tags-tag-id-comments: "record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list<record>, urlSlug: string, version: int, webLinks: list<record>>, id: int, message: string>"
    get-api-users: "record<items: table<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>, term: string, totalCount: int>"
    get-api-users-current: "record<active: bool, groupId: string, id: int, knownLanguages: table<cultureCode: string, proficiency: string>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: table<date: string, oldName: string>, verifiedArtist: bool>"
    get-api-users-current-album-collection-statuses-album-id: "record<album: record<additionalNames: string, artistString: string, artists: list<record>, barcode: string, catalogNumber: string, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, discType: string, discs: list<record>, id: int, identifiers: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: list<record>, pvs: list<record>, ratingAverage: float, ratingCount: int, releaseDate: record<day: int, formatted: string, isEmpty: bool, month: int, year: int>, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, status: string, tags: list<record>, tracks: list<record>, version: int, webLinks: list<record>>, mediaType: string, purchaseStatus: string, rating: int, user: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>>"
    post-api-users-current-albums-album-id: "string"
    get-api-users-current-followed-artists-artist-id: "record<artist: record<additionalNames: string, artistLinks: list<record>, artistLinksReverse: list<record>, artistType: string, baseVoicebank: record<additionalNames: string, artistType: string, deleted: bool, id: int, name: string, pictureMime: string, releaseDate: string, status: string, version: int>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: list<record>, pictureMime: string, relations: record<latestAlbums: list, latestEvents: list, latestSongs: list, popularAlbums: list, popularSongs: list>, releaseDate: string, status: string, tags: list<record>, version: int, webLinks: list<record>>, id: int>"
    get-api-users-current-rated-songs-song-id: "string"
    post-api-users-current-refresh-entry-edit: "record<time: string, userId: int, userName: string>"
    get-api-users-messages-message-id: "record<body: string, createdFormatted: string, highPriority: bool, id: int, inbox: string, read: bool, receiver: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, sender: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, subject: string>"
    get-api-users-names: "list<string>"
    get-api-users-id: "record<active: bool, groupId: string, id: int, knownLanguages: table<cultureCode: string, proficiency: string>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: table<date: string, oldName: string>, verifiedArtist: bool>"
    get-api-users-id-album-collection-statuses-album-id: "record<album: record<additionalNames: string, artistString: string, artists: list<record>, barcode: string, catalogNumber: string, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, discType: string, discs: list<record>, id: int, identifiers: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: list<record>, pvs: list<record>, ratingAverage: float, ratingCount: int, releaseDate: record<day: int, formatted: string, isEmpty: bool, month: int, year: int>, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, status: string, tags: list<record>, tracks: list<record>, version: int, webLinks: list<record>>, mediaType: string, purchaseStatus: string, rating: int, user: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>>"
    get-api-users-id-albums: "record<items: table<album: record, mediaType: string, purchaseStatus: string, rating: int, user: record>, term: string, totalCount: int>"
    get-api-users-id-events: "table<additionalNames: string, artists: list<record>, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, series: record<additionalNames: string, category: string, deleted: bool, description: string, id: int, name: string, pictureMime: string, status: string, urlSlug: string, version: int, webLinks: list>, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record<featuredCategory: string, id: int, name: string>, status: string, tags: list<record>, urlSlug: string, venue: record<additionalNames: string, address: string, addressCountryCode: string, coordinates: record, deleted: bool, description: string, events: list, id: int, name: string, names: list, status: string, version: int, webLinks: list>, venueName: string, version: int, webLinks: list<record>>"
    get-api-users-id-followed-artists: "record<items: table<artist: record, id: int>, term: string, totalCount: int>"
    get-api-users-id-followed-artists-artist-id: "record<artist: record<additionalNames: string, artistLinks: list<record>, artistLinksReverse: list<record>, artistType: string, baseVoicebank: record<additionalNames: string, artistType: string, deleted: bool, id: int, name: string, pictureMime: string, releaseDate: string, status: string, version: int>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: list<record>, pictureMime: string, relations: record<latestAlbums: list, latestEvents: list, latestSongs: list, popularAlbums: list, popularSongs: list>, releaseDate: string, status: string, tags: list<record>, version: int, webLinks: list<record>>, id: int>"
    get-api-users-id-messages: "record<items: table<body: string, createdFormatted: string, highPriority: bool, id: int, inbox: string, read: bool, receiver: record, sender: record, subject: string>, term: string, totalCount: int>"
    post-api-users-id-messages: "record<body: string, createdFormatted: string, highPriority: bool, id: int, inbox: string, read: bool, receiver: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, sender: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, subject: string>"
    get-api-users-id-profile-comments: "record<items: table<author: record, authorName: string, created: string, entry: record, id: int, message: string>, term: string, totalCount: int>"
    post-api-users-id-profile-comments: "record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list<record>, urlSlug: string, version: int, webLinks: list<record>>, id: int, message: string>"
    get-api-users-id-rated-songs: "record<items: table<date: string, rating: string, song: record, user: record>, term: string, totalCount: int>"
    get-api-users-id-rated-songs-song-id: "string"
    post-api-users-id-reports: "bool"
    get-api-users-id-song-lists: "record<items: table<author: record, deleted: bool, description: string, eventDate: string, events: list, featuredCategory: string, id: int, latestComments: list, mainPicture: record, name: string, status: string, tags: list>, term: string, totalCount: int>"
    get-api-venues: "record<items: table<additionalNames: string, address: string, addressCountryCode: string, coordinates: record, deleted: bool, description: string, events: list, id: int, name: string, names: list, status: string, version: int, webLinks: list>, term: string, totalCount: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-api-activity-entries" "get-api-albums" "delete-api-albums-comments-comment-id" "post-api-albums-comments-comment-id" "get-api-albums-names" "get-api-albums-new" "get-api-albums-top" "delete-api-albums-id" "get-api-albums-id" "get-api-albums-id-comments" "post-api-albums-id-comments" "get-api-albums-id-reviews" "post-api-albums-id-reviews" "delete-api-albums-id-reviews-review-id" "get-api-albums-id-tracks" "get-api-albums-id-tracks-fields" "get-api-albums-id-user-collections" "get-api-artists" "delete-api-artists-comments-comment-id" "post-api-artists-comments-comment-id" "get-api-artists-names" "delete-api-artists-id" "get-api-artists-id" "get-api-artists-id-comments" "post-api-artists-id-comments" "get-api-comments" "get-api-comments-entry-type-comments" "post-api-comments-entry-type-comments" "delete-api-comments-entry-type-comments-comment-id" "post-api-comments-entry-type-comments-comment-id" "delete-api-discussions-comments-comment-id" "post-api-discussions-comments-comment-id" "get-api-discussions-folders" "post-api-discussions-folders" "get-api-discussions-folders-folder-id-topics" "post-api-discussions-folders-folder-id-topics" "get-api-discussions-topics" "delete-api-discussions-topics-topic-id" "get-api-discussions-topics-topic-id" "post-api-discussions-topics-topic-id" "post-api-discussions-topics-topic-id-comments" "get-api-entries" "get-api-entries-names" "get-api-entry-types-entry-type-sub-type-tag" "get-api-pvs-for-songs" "get-api-release-event-series" "delete-api-release-event-series-id" "get-api-release-event-series-id" "get-api-release-event-series-id-for-edit" "get-api-release-events" "get-api-release-events-names" "get-api-release-events-event-id-albums" "get-api-release-events-event-id-published-songs" "post-api-release-events-event-id-reports" "delete-api-release-events-id" "get-api-release-events-id" "get-api-resources-culture-code" "post-api-song-lists" "delete-api-song-lists-comments-comment-id" "post-api-song-lists-comments-comment-id" "get-api-song-lists-featured" "get-api-song-lists-featured-names" "delete-api-song-lists-id" "get-api-song-lists-list-id-comments" "post-api-song-lists-list-id-comments" "get-api-song-lists-list-id-songs" "get-api-songs" "get-api-songs-by-pv" "delete-api-songs-comments-comment-id" "post-api-songs-comments-comment-id" "get-api-songs-highlighted" "get-api-songs-lyrics-lyrics-id" "get-api-songs-names" "get-api-songs-top-rated" "delete-api-songs-id" "get-api-songs-id" "get-api-songs-id-comments" "post-api-songs-id-comments" "get-api-songs-id-derived" "get-api-songs-id-ratings" "post-api-songs-id-ratings" "get-api-songs-id-related" "get-api-tags" "post-api-tags" "get-api-tags-by-name-name" "get-api-tags-category-names" "delete-api-tags-comments-comment-id" "post-api-tags-comments-comment-id" "get-api-tags-names" "get-api-tags-top" "delete-api-tags-id" "get-api-tags-id" "get-api-tags-tag-id-children" "get-api-tags-tag-id-comments" "post-api-tags-tag-id-comments" "post-api-tags-tag-id-reports" "get-api-users" "get-api-users-current" "get-api-users-current-album-collection-statuses-album-id" "post-api-users-current-albums-album-id" "get-api-users-current-followed-artists-artist-id" "delete-api-users-current-followed-tags-tag-id" "post-api-users-current-followed-tags-tag-id" "get-api-users-current-rated-songs-song-id" "post-api-users-current-refresh-entry-edit" "post-api-users-current-song-tags-song-id" "get-api-users-messages-message-id" "get-api-users-names" "delete-api-users-profile-comments-comment-id" "post-api-users-profile-comments-comment-id" "get-api-users-id" "get-api-users-id-album-collection-statuses-album-id" "get-api-users-id-albums" "get-api-users-id-events" "get-api-users-id-followed-artists" "get-api-users-id-followed-artists-artist-id" "delete-api-users-id-messages" "get-api-users-id-messages" "post-api-users-id-messages" "get-api-users-id-profile-comments" "post-api-users-id-profile-comments" "get-api-users-id-rated-songs" "get-api-users-id-rated-songs-song-id" "post-api-users-id-reports" "post-api-users-id-settings-setting-name" "get-api-users-id-song-lists" "get-api-venues" "delete-api-venues-id" "post-api-venues-id-reports" "commands"] | sort) } | get name | first)
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

# GET /api/activityEntries
#
# Returns: record<items: table<archivedVersion: record, author: record, createDate: string, editEvent: string, entry: record>, term: string, totalCount: int>
export def "get-api-activity-entries" [
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
  --before: string # format: date-time
  --since: string # format: date-time
  --user-id: int # format: int32
  --edit-event: string@edit-event-completer
  --entry-type: string@entry-type-completer
  --max-results: int # format: int32, default: 50
  --get-total-count: oneof<nothing, bool> # default: false
  --fields: string@fields-completer
  --entry-fields: string@entry-fields-completer
  --lang: string@lang-completer
  --sort-rule: string@sort-rule-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/activityEntries"
    query: [{name: before, var: before}, {name: since, var: since}, {name: userId, var: user_id}, {name: editEvent, var: edit_event}, {name: entryType, var: entry_type}, {name: maxResults, var: max_results}, {name: getTotalCount, var: get_total_count}, {name: fields, var: fields}, {name: entryFields, var: entry_fields}, {name: lang, var: lang}, {name: sortRule, var: sort_rule}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    before: $before, since: $since, user_id: $user_id, edit_event: $edit_event, entry_type: $entry_type, max_results: $max_results, get_total_count: $get_total_count, fields: $fields, entry_fields: $entry_fields, lang: $lang, sort_rule: $sort_rule
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/albums
#
# Returns: record<items: table<additionalNames: string, artistString: string, artists: list, barcode: string, catalogNumber: string, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, discType: string, discs: list, id: int, identifiers: list, mainPicture: record, mergedTo: int, name: string, names: list, pvs: list, ratingAverage: float, ratingCount: int, releaseDate: record, releaseEvent: record, status: string, tags: list, tracks: list, version: int, webLinks: list>, term: string, totalCount: int>
export def "get-api-albums" [
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
  --query: string # default: ""
  --disc-types: string@disc-types-completer
  --tag-name: list<string>
  --tag-id: list<int>
  --child-tags: oneof<nothing, bool> # default: false
  --artist-id: list<int>
  --artist-participation-status: string@artist-participation-status-completer
  --child-voicebanks: oneof<nothing, bool> # default: false
  --include-members: oneof<nothing, bool> # default: false
  --barcode: string
  --status: string@status-completer
  --release-date-after: string # format: date-time
  --release-date-before: string # format: date-time
  --advanced-filters: list
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --sort: string@sort-completer
  --prefer-accurate-matches: oneof<nothing, bool> # default: false
  --deleted: oneof<nothing, bool> # default: false
  --name-match-mode: string@name-match-mode-completer
  --fields: string@fields-completer-1
  --lang: string@lang-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/albums"
    query: [{name: query, var: query}, {name: discTypes, var: disc_types}, {name: "tagName[]", var: tag_name, style: multi}, {name: "tagId[]", var: tag_id, style: multi}, {name: childTags, var: child_tags}, {name: "artistId[]", var: artist_id, style: multi}, {name: artistParticipationStatus, var: artist_participation_status}, {name: childVoicebanks, var: child_voicebanks}, {name: includeMembers, var: include_members}, {name: barcode, var: barcode}, {name: status, var: status}, {name: releaseDateAfter, var: release_date_after}, {name: releaseDateBefore, var: release_date_before}, {name: advancedFilters, var: advanced_filters, style: multi}, {name: start, var: start}, {name: maxResults, var: max_results}, {name: getTotalCount, var: get_total_count}, {name: sort, var: sort}, {name: preferAccurateMatches, var: prefer_accurate_matches}, {name: deleted, var: deleted}, {name: nameMatchMode, var: name_match_mode}, {name: fields, var: fields}, {name: lang, var: lang}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    query: $query, disc_types: $disc_types, tag_name: $tag_name, tag_id: $tag_id, child_tags: $child_tags, artist_id: $artist_id, artist_participation_status: $artist_participation_status, child_voicebanks: $child_voicebanks, include_members: $include_members, barcode: $barcode, status: $status, release_date_after: $release_date_after, release_date_before: $release_date_before, advanced_filters: $advanced_filters, start: $start, max_results: $max_results, get_total_count: $get_total_count, sort: $sort, prefer_accurate_matches: $prefer_accurate_matches, deleted: $deleted, name_match_mode: $name_match_mode, fields: $fields, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DELETE /api/albums/comments/{commentId}
export def "delete-api-albums-comments-comment-id" [
  comment_id: int
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
    path: "/api/albums/comments/{commentId}"
    path_params: [{name: commentId, var: comment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    comment_id: $comment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/albums/comments/{commentId}
export def "post-api-albums-comments-comment-id" [
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --author-name: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
  --id: int # format: int32
  --message: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/albums/comments/{commentId}"
    path_params: [{name: commentId, var: comment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: author, var: author}, {name: authorName, var: author_name}, {name: created, var: created}, {name: entry, var: entry}, {name: id, var: id}, {name: message, var: message}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    comment_id: $comment_id, author: $author, author_name: $author_name, created: $created, entry: $entry, id: $id, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/albums/names
#
# Returns: list<string>
export def "get-api-albums-names" [
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
  --query: string # default: ""
  --name-match-mode: string@name-match-mode-completer
  --max-results: int # format: int32, default: 15
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/albums/names"
    query: [{name: query, var: query}, {name: nameMatchMode, var: name_match_mode}, {name: maxResults, var: max_results}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    query: $query, name_match_mode: $name_match_mode, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/albums/new
#
# Returns: table<additionalNames: string, artistString: string, artists: list<record>, barcode: string, catalogNumber: string, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, discType: string, discs: list<record>, id: int, identifiers: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: list<record>, pvs: list<record>, ratingAverage: float, ratingCount: int, releaseDate: record<day: int, formatted: string, isEmpty: bool, month: int, year: int>, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, status: string, tags: list<record>, tracks: list<record>, version: int, webLinks: list<record>>
export def "get-api-albums-new" [
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
  --language-preference: string@language-preference-completer
  --fields: string@fields-completer-1
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/albums/new"
    query: [{name: languagePreference, var: language_preference}, {name: fields, var: fields}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    language_preference: $language_preference, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/albums/top
#
# Returns: table<additionalNames: string, artistString: string, artists: list<record>, barcode: string, catalogNumber: string, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, discType: string, discs: list<record>, id: int, identifiers: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: list<record>, pvs: list<record>, ratingAverage: float, ratingCount: int, releaseDate: record<day: int, formatted: string, isEmpty: bool, month: int, year: int>, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, status: string, tags: list<record>, tracks: list<record>, version: int, webLinks: list<record>>
export def "get-api-albums-top" [
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
  --ignore-ids: list<int>
  --language-preference: string@language-preference-completer
  --fields: string@fields-completer-1
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/albums/top"
    query: [{name: "ignoreIds[]", var: ignore_ids, style: multi}, {name: languagePreference, var: language_preference}, {name: fields, var: fields}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    ignore_ids: $ignore_ids, language_preference: $language_preference, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DELETE /api/albums/{id}
export def "delete-api-albums-id" [
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
  --notes: string # default: ""
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/albums/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: notes, var: notes}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, notes: $notes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/albums/{id}
#
# Returns: record<additionalNames: string, artistString: string, artists: table<artist: record, categories: string, effectiveRoles: string, isSupport: bool, name: string, roles: string>, barcode: string, catalogNumber: string, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, discType: string, discs: table<discNumber: int, id: int, mediaType: string, name: string>, id: int, identifiers: table<value: string>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: table<language: string, value: string>, pvs: table<author: string, createdBy: int, disabled: bool, extendedMetadata: record, id: int, length: int, name: string, publishDate: string, pvId: string, pvType: string, service: string, thumbUrl: string, url: string>, ratingAverage: float, ratingCount: int, releaseDate: record<day: int, formatted: string, isEmpty: bool, month: int, year: int>, releaseEvent: record<additionalNames: string, artists: list<record>, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, series: record<additionalNames: string, category: string, deleted: bool, description: string, id: int, name: string, pictureMime: string, status: string, urlSlug: string, version: int, webLinks: list>, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record<featuredCategory: string, id: int, name: string>, status: string, tags: list<record>, urlSlug: string, venue: record<additionalNames: string, address: string, addressCountryCode: string, coordinates: record, deleted: bool, description: string, events: list, id: int, name: string, names: list, status: string, version: int, webLinks: list>, venueName: string, version: int, webLinks: list<record>>, status: string, tags: table<count: int, tag: record>, tracks: table<discNumber: int, id: int, name: string, rating: string, song: record, trackNumber: int>, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>>
export def "get-api-albums-id" [
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
  --accept: string@accept-completer # Response content type
  --fields: string@fields-completer-1
  --song-fields: string@song-fields-completer
  --lang: string@lang-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/albums/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}, {name: songFields, var: song_fields}, {name: lang, var: lang}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields: $fields, song_fields: $song_fields, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/albums/{id}/comments
#
# Returns: table<author: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record, name: string, names: list, pvs: list, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list, urlSlug: string, version: int, webLinks: list>, id: int, message: string>
export def "get-api-albums-id-comments" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/albums/{id}/comments"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/albums/{id}/comments
#
# Returns: record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list<record>, urlSlug: string, version: int, webLinks: list<record>>, id: int, message: string>
export def "post-api-albums-id-comments" [
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
  --accept: string@accept-completer # Response content type
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --author-name: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
  --body-id: int # format: int32 (spec name: id)
  --message: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/albums/{id}/comments"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: author, var: author}, {name: authorName, var: author_name}, {name: created, var: created}, {name: entry, var: entry}, {name: id, var: body_id}, {name: message, var: message}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, author: $author, author_name: $author_name, created: $created, entry: $entry, body_id: $body_id, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/albums/{id}/reviews
#
# Returns: table<albumId: int, date: string, id: int, languageCode: string, text: string, title: string, user: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>>
export def "get-api-albums-id-reviews" [
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
  --accept: string@accept-completer # Response content type
  --language-code: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/albums/{id}/reviews"
    path_params: [{name: id, var: id}]
    query: [{name: languageCode, var: language_code}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, language_code: $language_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/albums/{id}/reviews
#
# Returns: record<albumId: int, date: string, id: int, languageCode: string, text: string, title: string, user: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>>
export def "post-api-albums-id-reviews" [
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
  --accept: string@accept-completer # Response content type
  --album-id: int # format: int32
  --date: string # format: date-time
  --body-id: int # format: int32 (spec name: id)
  --language-code: string # nullable
  --text: string # nullable
  --title: string # nullable
  --user: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/albums/{id}/reviews"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: albumId, var: album_id}, {name: date, var: date}, {name: id, var: body_id}, {name: languageCode, var: language_code}, {name: text, var: text}, {name: title, var: title}, {name: user, var: user}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, album_id: $album_id, date: $date, body_id: $body_id, language_code: $language_code, text: $text, title: $title, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DELETE /api/albums/{id}/reviews/{reviewId}
export def "delete-api-albums-id-reviews-review-id" [
  id: string
  review_id: int
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
    path: "/api/albums/{id}/reviews/{reviewId}"
    path_params: [{name: id, var: id}, {name: reviewId, var: review_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, review_id: $review_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/albums/{id}/tracks
#
# Returns: table<discNumber: int, id: int, name: string, rating: string, song: record<additionalNames: string, albums: list, artistString: string, artists: list, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list, mainPicture: record, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list, originalVersionId: int, publishDate: string, pvServices: string, pvs: list, ratingScore: int, releaseEvent: record, songType: string, status: string, tags: list, thumbUrl: string, version: int, webLinks: list>, trackNumber: int>
export def "get-api-albums-id-tracks" [
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
  --accept: string@accept-completer # Response content type
  --fields: string@fields-completer-2
  --lang: string@lang-completer
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/albums/{id}/tracks"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}, {name: lang, var: lang}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields: $fields, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/albums/{id}/tracks/fields
#
# Returns: list<record>
export def "get-api-albums-id-tracks-fields" [
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
  --accept: string@accept-completer # Response content type
  --field: list<string>
  --disc-number: int # format: int32
  --lang: string@lang-completer
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/albums/{id}/tracks/fields"
    path_params: [{name: id, var: id}]
    query: [{name: "field[]", var: field, style: multi}, {name: discNumber, var: disc_number}, {name: lang, var: lang}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, field: $field, disc_number: $disc_number, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/albums/{id}/user-collections
#
# Returns: table<album: record<additionalNames: string, artistString: string, artists: list, barcode: string, catalogNumber: string, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, discType: string, discs: list, id: int, identifiers: list, mainPicture: record, mergedTo: int, name: string, names: list, pvs: list, ratingAverage: float, ratingCount: int, releaseDate: record, releaseEvent: record, status: string, tags: list, tracks: list, version: int, webLinks: list>, mediaType: string, purchaseStatus: string, rating: int, user: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>>
export def "get-api-albums-id-user-collections" [
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
  --accept: string@accept-completer # Response content type
  --language-preference: string@language-preference-completer
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/albums/{id}/user-collections"
    path_params: [{name: id, var: id}]
    query: [{name: languagePreference, var: language_preference}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, language_preference: $language_preference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/artists
#
# Returns: record<items: table<additionalNames: string, artistLinks: list, artistLinksReverse: list, artistType: string, baseVoicebank: record, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, id: int, mainPicture: record, mergedTo: int, name: string, names: list, pictureMime: string, relations: record, releaseDate: string, status: string, tags: list, version: int, webLinks: list>, term: string, totalCount: int>
export def "get-api-artists" [
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
  --query: string # default: ""
  --artist-types: string
  --allow-base-voicebanks: oneof<nothing, bool> # default: true
  --tag-name: list<string>
  --tag-id: list<int>
  --child-tags: oneof<nothing, bool> # default: false
  --followed-by-user-id: int # format: int32
  --status: string@status-completer
  --advanced-filters: list
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --sort: string@sort-completer-1
  --prefer-accurate-matches: oneof<nothing, bool> # default: false
  --name-match-mode: string@name-match-mode-completer
  --fields: string@fields-completer-3
  --lang: string@lang-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/artists"
    query: [{name: query, var: query}, {name: artistTypes, var: artist_types}, {name: allowBaseVoicebanks, var: allow_base_voicebanks}, {name: "tagName[]", var: tag_name, style: multi}, {name: "tagId[]", var: tag_id, style: multi}, {name: childTags, var: child_tags}, {name: followedByUserId, var: followed_by_user_id}, {name: status, var: status}, {name: advancedFilters, var: advanced_filters, style: multi}, {name: start, var: start}, {name: maxResults, var: max_results}, {name: getTotalCount, var: get_total_count}, {name: sort, var: sort}, {name: preferAccurateMatches, var: prefer_accurate_matches}, {name: nameMatchMode, var: name_match_mode}, {name: fields, var: fields}, {name: lang, var: lang}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    query: $query, artist_types: $artist_types, allow_base_voicebanks: $allow_base_voicebanks, tag_name: $tag_name, tag_id: $tag_id, child_tags: $child_tags, followed_by_user_id: $followed_by_user_id, status: $status, advanced_filters: $advanced_filters, start: $start, max_results: $max_results, get_total_count: $get_total_count, sort: $sort, prefer_accurate_matches: $prefer_accurate_matches, name_match_mode: $name_match_mode, fields: $fields, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DELETE /api/artists/comments/{commentId}
export def "delete-api-artists-comments-comment-id" [
  comment_id: int
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
    path: "/api/artists/comments/{commentId}"
    path_params: [{name: commentId, var: comment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    comment_id: $comment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/artists/comments/{commentId}
export def "post-api-artists-comments-comment-id" [
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --author-name: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
  --id: int # format: int32
  --message: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/artists/comments/{commentId}"
    path_params: [{name: commentId, var: comment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: author, var: author}, {name: authorName, var: author_name}, {name: created, var: created}, {name: entry, var: entry}, {name: id, var: id}, {name: message, var: message}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    comment_id: $comment_id, author: $author, author_name: $author_name, created: $created, entry: $entry, id: $id, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/artists/names
#
# Returns: list<string>
export def "get-api-artists-names" [
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
  --query: string # default: ""
  --name-match-mode: string@name-match-mode-completer
  --max-results: int # format: int32, default: 15
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/artists/names"
    query: [{name: query, var: query}, {name: nameMatchMode, var: name_match_mode}, {name: maxResults, var: max_results}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    query: $query, name_match_mode: $name_match_mode, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DELETE /api/artists/{id}
export def "delete-api-artists-id" [
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
  --notes: string # default: ""
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/artists/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: notes, var: notes}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, notes: $notes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/artists/{id}
#
# Returns: record<additionalNames: string, artistLinks: table<artist: record, linkType: string>, artistLinksReverse: table<artist: record, linkType: string>, artistType: string, baseVoicebank: record<additionalNames: string, artistType: string, deleted: bool, id: int, name: string, pictureMime: string, releaseDate: string, status: string, version: int>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: table<language: string, value: string>, pictureMime: string, relations: record<latestAlbums: list<record>, latestEvents: list<record>, latestSongs: list<record>, popularAlbums: list<record>, popularSongs: list<record>>, releaseDate: string, status: string, tags: table<count: int, tag: record>, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>>
export def "get-api-artists-id" [
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
  --accept: string@accept-completer # Response content type
  --fields: string@fields-completer-3
  --relations: string@relations-completer
  --lang: string@lang-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/artists/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}, {name: relations, var: relations}, {name: lang, var: lang}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields: $fields, relations: $relations, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/artists/{id}/comments
#
# Returns: table<author: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record, name: string, names: list, pvs: list, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list, urlSlug: string, version: int, webLinks: list>, id: int, message: string>
export def "get-api-artists-id-comments" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/artists/{id}/comments"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/artists/{id}/comments
#
# Returns: record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list<record>, urlSlug: string, version: int, webLinks: list<record>>, id: int, message: string>
export def "post-api-artists-id-comments" [
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
  --accept: string@accept-completer # Response content type
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --author-name: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
  --body-id: int # format: int32 (spec name: id)
  --message: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/artists/{id}/comments"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: author, var: author}, {name: authorName, var: author_name}, {name: created, var: created}, {name: entry, var: entry}, {name: id, var: body_id}, {name: message, var: message}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, author: $author, author_name: $author_name, created: $created, entry: $entry, body_id: $body_id, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/comments
#
# Returns: record<items: table<author: record, authorName: string, created: string, entry: record, id: int, message: string>, term: string, totalCount: int>
export def "get-api-comments" [
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
  --before: string # format: date-time
  --since: string # format: date-time
  --user-id: int # format: int32
  --entry-type: string@entry-type-completer
  --max-results: int # format: int32, default: 50
  --get-total-count: oneof<nothing, bool> # default: false
  --fields: string@fields-completer-4
  --entry-fields: string@entry-fields-completer
  --lang: string@lang-completer
  --sort-rule: string@sort-rule-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/comments"
    query: [{name: before, var: before}, {name: since, var: since}, {name: userId, var: user_id}, {name: entryType, var: entry_type}, {name: maxResults, var: max_results}, {name: getTotalCount, var: get_total_count}, {name: fields, var: fields}, {name: entryFields, var: entry_fields}, {name: lang, var: lang}, {name: sortRule, var: sort_rule}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    before: $before, since: $since, user_id: $user_id, entry_type: $entry_type, max_results: $max_results, get_total_count: $get_total_count, fields: $fields, entry_fields: $entry_fields, lang: $lang, sort_rule: $sort_rule
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/comments/{entryType}-comments
#
# Returns: record<items: table<author: record, authorName: string, created: string, entry: record, id: int, message: string>, term: string, totalCount: int>
export def "get-api-comments-entry-type-comments" [
  entry_type: string@entry-type-completer
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
  --entry-id: int # format: int32
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/comments/{entryType}-comments"
    path_params: [{name: entryType, var: entry_type}]
    query: [{name: entryId, var: entry_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    entry_type: $entry_type, entry_id: $entry_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/comments/{entryType}-comments
#
# Returns: record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list<record>, urlSlug: string, version: int, webLinks: list<record>>, id: int, message: string>
export def "post-api-comments-entry-type-comments" [
  entry_type: string@entry-type-completer
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
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --author-name: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
  --id: int # format: int32
  --message: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/comments/{entryType}-comments"
    path_params: [{name: entryType, var: entry_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: author, var: author}, {name: authorName, var: author_name}, {name: created, var: created}, {name: entry, var: entry}, {name: id, var: id}, {name: message, var: message}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    entry_type: $entry_type, author: $author, author_name: $author_name, created: $created, entry: $entry, id: $id, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DELETE /api/comments/{entryType}-comments/{commentId}
export def "delete-api-comments-entry-type-comments-comment-id" [
  entry_type: string@entry-type-completer
  comment_id: int
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
    path: "/api/comments/{entryType}-comments/{commentId}"
    path_params: [{name: entryType, var: entry_type}, {name: commentId, var: comment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    entry_type: $entry_type, comment_id: $comment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/comments/{entryType}-comments/{commentId}
export def "post-api-comments-entry-type-comments-comment-id" [
  entry_type: string@entry-type-completer
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --author-name: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
  --id: int # format: int32
  --message: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/comments/{entryType}-comments/{commentId}"
    path_params: [{name: entryType, var: entry_type}, {name: commentId, var: comment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: author, var: author}, {name: authorName, var: author_name}, {name: created, var: created}, {name: entry, var: entry}, {name: id, var: id}, {name: message, var: message}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    entry_type: $entry_type, comment_id: $comment_id, author: $author, author_name: $author_name, created: $created, entry: $entry, id: $id, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /api/discussions/comments/{commentId}
export def "delete-api-discussions-comments-comment-id" [
  comment_id: int
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
    path: "/api/discussions/comments/{commentId}"
    path_params: [{name: commentId, var: comment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    comment_id: $comment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/discussions/comments/{commentId}
export def "post-api-discussions-comments-comment-id" [
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --author-name: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
  --id: int # format: int32
  --message: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/discussions/comments/{commentId}"
    path_params: [{name: commentId, var: comment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: author, var: author}, {name: authorName, var: author_name}, {name: created, var: created}, {name: entry, var: entry}, {name: id, var: id}, {name: message, var: message}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    comment_id: $comment_id, author: $author, author_name: $author_name, created: $created, entry: $entry, id: $id, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/discussions/folders
#
# Returns: table<description: string, id: int, lastTopicAuthor: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>, lastTopicDate: string, name: string, topicCount: int>
export def "get-api-discussions-folders" [
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
  --fields: string@fields-completer-5
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/discussions/folders"
    query: [{name: fields, var: fields}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/discussions/folders
#
# Returns: record<description: string, id: int, lastTopicAuthor: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, lastTopicDate: string, name: string, topicCount: int>
export def "post-api-discussions-folders" [
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
  --description: string # nullable
  --id: int # format: int32
  --last-topic-author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --last-topic-date: string # nullable, format: date-time
  --name: string # nullable
  --topic-count: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/discussions/folders"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: id, var: id}, {name: lastTopicAuthor, var: last_topic_author}, {name: lastTopicDate, var: last_topic_date}, {name: name, var: name}, {name: topicCount, var: topic_count}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    description: $description, id: $id, last_topic_author: $last_topic_author, last_topic_date: $last_topic_date, name: $name, topic_count: $topic_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/discussions/folders/{folderId}/topics
#
# DEPRECATED
# Returns: table<author: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>, commentCount: int, comments: list<record>, content: string, created: string, folderId: int, id: int, lastComment: record<author: record, authorName: string, created: string, entry: record, id: int, message: string>, locked: bool, name: string>
@deprecated
export def "get-api-discussions-folders-folder-id-topics" [
  folder_id: int
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
  --fields: string@fields-completer-6
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/discussions/folders/{folderId}/topics"
    path_params: [{name: folderId, var: folder_id}]
    query: [{name: fields, var: fields}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    folder_id: $folder_id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/discussions/folders/{folderId}/topics
#
# Returns: record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, commentCount: int, comments: table<author: record, authorName: string, created: string, entry: record, id: int, message: string>, content: string, created: string, folderId: int, id: int, lastComment: record<author: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record, name: string, names: list, pvs: list, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list, urlSlug: string, version: int, webLinks: list>, id: int, message: string>, locked: bool, name: string>
export def "post-api-discussions-folders-folder-id-topics" [
  folder_id: int
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
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --comment-count: int # format: int32
  --comments: list # nullable — item shape: {author?: record, authorName?: string, created?: string, entry?: record, id?: int, message?: string}
  --content: string # nullable
  --created: string # format: date-time
  --body-folder-id: int # format: int32 (spec name: folderId)
  --id: int # format: int32
  --last-comment: record # shape: {author?: record, authorName?: string, created?: string, entry?: record, id?: int, message?: string}
  --locked: oneof<nothing, bool>
  --name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/discussions/folders/{folderId}/topics"
    path_params: [{name: folderId, var: folder_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: author, var: author}, {name: commentCount, var: comment_count}, {name: comments, var: comments}, {name: content, var: content}, {name: created, var: created}, {name: folderId, var: body_folder_id}, {name: id, var: id}, {name: lastComment, var: last_comment}, {name: locked, var: locked}, {name: name, var: name}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    folder_id: $folder_id, author: $author, comment_count: $comment_count, comments: $comments, content: $content, created: $created, body_folder_id: $body_folder_id, id: $id, last_comment: $last_comment, locked: $locked, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/discussions/topics
#
# Returns: record<items: table<author: record, commentCount: int, comments: list, content: string, created: string, folderId: int, id: int, lastComment: record, locked: bool, name: string>, term: string, totalCount: int>
export def "get-api-discussions-topics" [
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
  --folder-id: int # format: int32
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --sort: string@sort-completer-2
  --fields: string@fields-completer-6
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/discussions/topics"
    query: [{name: folderId, var: folder_id}, {name: start, var: start}, {name: maxResults, var: max_results}, {name: getTotalCount, var: get_total_count}, {name: sort, var: sort}, {name: fields, var: fields}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    folder_id: $folder_id, start: $start, max_results: $max_results, get_total_count: $get_total_count, sort: $sort, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DELETE /api/discussions/topics/{topicId}
export def "delete-api-discussions-topics-topic-id" [
  topic_id: int
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
    path: "/api/discussions/topics/{topicId}"
    path_params: [{name: topicId, var: topic_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    topic_id: $topic_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/discussions/topics/{topicId}
#
# Returns: record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, commentCount: int, comments: table<author: record, authorName: string, created: string, entry: record, id: int, message: string>, content: string, created: string, folderId: int, id: int, lastComment: record<author: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record, name: string, names: list, pvs: list, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list, urlSlug: string, version: int, webLinks: list>, id: int, message: string>, locked: bool, name: string>
export def "get-api-discussions-topics-topic-id" [
  topic_id: int
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
  --fields: string@fields-completer-6
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/discussions/topics/{topicId}"
    path_params: [{name: topicId, var: topic_id}]
    query: [{name: fields, var: fields}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    topic_id: $topic_id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/discussions/topics/{topicId}
export def "post-api-discussions-topics-topic-id" [
  topic_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --comment-count: int # format: int32
  --comments: list # nullable — item shape: {author?: record, authorName?: string, created?: string, entry?: record, id?: int, message?: string}
  --content: string # nullable
  --created: string # format: date-time
  --folder-id: int # format: int32
  --id: int # format: int32
  --last-comment: record # shape: {author?: record, authorName?: string, created?: string, entry?: record, id?: int, message?: string}
  --locked: oneof<nothing, bool>
  --name: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/discussions/topics/{topicId}"
    path_params: [{name: topicId, var: topic_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: author, var: author}, {name: commentCount, var: comment_count}, {name: comments, var: comments}, {name: content, var: content}, {name: created, var: created}, {name: folderId, var: folder_id}, {name: id, var: id}, {name: lastComment, var: last_comment}, {name: locked, var: locked}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    topic_id: $topic_id, author: $author, comment_count: $comment_count, comments: $comments, content: $content, created: $created, folder_id: $folder_id, id: $id, last_comment: $last_comment, locked: $locked, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/discussions/topics/{topicId}/comments
#
# Returns: record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list<record>, urlSlug: string, version: int, webLinks: list<record>>, id: int, message: string>
export def "post-api-discussions-topics-topic-id-comments" [
  topic_id: int
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
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --author-name: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
  --id: int # format: int32
  --message: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/discussions/topics/{topicId}/comments"
    path_params: [{name: topicId, var: topic_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: author, var: author}, {name: authorName, var: author_name}, {name: created, var: created}, {name: entry, var: entry}, {name: id, var: id}, {name: message, var: message}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    topic_id: $topic_id, author: $author, author_name: $author_name, created: $created, entry: $entry, id: $id, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/entries
#
# Returns: record<items: table<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record, name: string, names: list, pvs: list, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list, urlSlug: string, version: int, webLinks: list>, term: string, totalCount: int>
export def "get-api-entries" [
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
  --query: string # default: ""
  --tag-name: list<string>
  --tag-id: list<int>
  --child-tags: oneof<nothing, bool> # default: false
  --entry-types: string@entry-types-completer
  --status: string@status-completer
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --sort: string@sort-completer-3
  --name-match-mode: string@name-match-mode-completer
  --fields: string@fields-completer-7
  --lang: string@lang-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/entries"
    query: [{name: query, var: query}, {name: "tagName[]", var: tag_name, style: multi}, {name: "tagId[]", var: tag_id, style: multi}, {name: childTags, var: child_tags}, {name: entryTypes, var: entry_types}, {name: status, var: status}, {name: start, var: start}, {name: maxResults, var: max_results}, {name: getTotalCount, var: get_total_count}, {name: sort, var: sort}, {name: nameMatchMode, var: name_match_mode}, {name: fields, var: fields}, {name: lang, var: lang}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    query: $query, tag_name: $tag_name, tag_id: $tag_id, child_tags: $child_tags, entry_types: $entry_types, status: $status, start: $start, max_results: $max_results, get_total_count: $get_total_count, sort: $sort, name_match_mode: $name_match_mode, fields: $fields, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/entries/names
#
# Returns: list<string>
export def "get-api-entries-names" [
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
  --query: string # default: ""
  --name-match-mode: string@name-match-mode-completer
  --max-results: int # format: int32, default: 10
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/entries/names"
    query: [{name: query, var: query}, {name: nameMatchMode, var: name_match_mode}, {name: maxResults, var: max_results}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    query: $query, name_match_mode: $name_match_mode, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/entry-types/{entryType}/{subType}/tag
#
# Returns: record<additionalNames: string, aliasedTo: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, categoryName: string, createDate: string, defaultNameLanguage: string, description: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: table<id: int, language: string, value: string>, parent: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, relatedTags: table<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, status: string, targets: int, translatedDescription: record<english: string, original: string>, urlSlug: string, usageCount: int, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>>
export def "get-api-entry-types-entry-type-sub-type-tag" [
  entry_type: string@entry-type-completer
  sub_type: string
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
  --fields: string@fields-completer-8
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/entry-types/{entryType}/{subType}/tag"
    path_params: [{name: entryType, var: entry_type}, {name: subType, var: sub_type}]
    query: [{name: fields, var: fields}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    entry_type: $entry_type, sub_type: $sub_type, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/pvs/for-songs
#
# Returns: record<items: table<author: string, createdBy: int, disabled: bool, extendedMetadata: record, id: int, length: int, name: string, publishDate: string, pvId: string, pvType: string, service: string, song: record, thumbUrl: string, url: string>, term: string, totalCount: int>
export def "get-api-pvs-for-songs" [
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
  --name: string
  --author: string
  --service: string@service-completer
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --lang: string@lang-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/pvs/for-songs"
    query: [{name: name, var: name}, {name: author, var: author}, {name: service, var: service}, {name: maxResults, var: max_results}, {name: getTotalCount, var: get_total_count}, {name: lang, var: lang}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    name: $name, author: $author, service: $service, max_results: $max_results, get_total_count: $get_total_count, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/releaseEventSeries
#
# Returns: record<items: table<additionalNames: string, category: string, description: string, events: list, id: int, mainPicture: record, name: string, names: list, status: string, urlSlug: string, version: int, webLinks: list>, term: string, totalCount: int>
export def "get-api-release-event-series" [
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
  --query: string # default: ""
  --fields: string@fields-completer-9
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --name-match-mode: string@name-match-mode-completer
  --lang: string@lang-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/releaseEventSeries"
    query: [{name: query, var: query}, {name: fields, var: fields}, {name: start, var: start}, {name: maxResults, var: max_results}, {name: getTotalCount, var: get_total_count}, {name: nameMatchMode, var: name_match_mode}, {name: lang, var: lang}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    query: $query, fields: $fields, start: $start, max_results: $max_results, get_total_count: $get_total_count, name_match_mode: $name_match_mode, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DELETE /api/releaseEventSeries/{id}
export def "delete-api-release-event-series-id" [
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
  --notes: string # default: ""
  --hard-delete: oneof<nothing, bool> # default: false
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/releaseEventSeries/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: notes, var: notes}, {name: hardDelete, var: hard_delete}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, notes: $notes, hard_delete: $hard_delete
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/releaseEventSeries/{id}
#
# Returns: record<additionalNames: string, category: string, description: string, events: table<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: table<language: string, value: string>, status: string, urlSlug: string, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>>
export def "get-api-release-event-series-id" [
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
  --accept: string@accept-completer # Response content type
  --fields: string@fields-completer-9
  --lang: string@lang-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/releaseEventSeries/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}, {name: lang, var: lang}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields: $fields, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/releaseEventSeries/{id}/for-edit
#
# Returns: record<category: string, defaultNameLanguage: string, deleted: bool, description: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: table<id: int, language: string, value: string>, status: string, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>>
export def "get-api-release-event-series-id-for-edit" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/releaseEventSeries/{id}/for-edit"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/releaseEvents
#
# Returns: record<items: table<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, term: string, totalCount: int>
export def "get-api-release-events" [
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
  --query: string # default: ""
  --name-match-mode: string@name-match-mode-completer
  --series-id: int # format: int32, default: 0
  --after-date: string # format: date-time
  --before-date: string # format: date-time
  --category: string@category-completer
  --user-collection-id: int # format: int32
  --tag-id: list<int>
  --child-tags: oneof<nothing, bool> # default: false
  --artist-id: list<int>
  --child-voicebanks: oneof<nothing, bool> # default: false
  --include-members: oneof<nothing, bool> # default: false
  --status: string@status-completer
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --sort: string@sort-completer-4
  --fields: string@fields-completer-10
  --lang: string@lang-completer
  --sort-direction: string@sort-direction-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/releaseEvents"
    query: [{name: query, var: query}, {name: nameMatchMode, var: name_match_mode}, {name: seriesId, var: series_id}, {name: afterDate, var: after_date}, {name: beforeDate, var: before_date}, {name: category, var: category}, {name: userCollectionId, var: user_collection_id}, {name: "tagId[]", var: tag_id, style: multi}, {name: childTags, var: child_tags}, {name: "artistId[]", var: artist_id, style: multi}, {name: childVoicebanks, var: child_voicebanks}, {name: includeMembers, var: include_members}, {name: status, var: status}, {name: start, var: start}, {name: maxResults, var: max_results}, {name: getTotalCount, var: get_total_count}, {name: sort, var: sort}, {name: fields, var: fields}, {name: lang, var: lang}, {name: sortDirection, var: sort_direction}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    query: $query, name_match_mode: $name_match_mode, series_id: $series_id, after_date: $after_date, before_date: $before_date, category: $category, user_collection_id: $user_collection_id, tag_id: $tag_id, child_tags: $child_tags, artist_id: $artist_id, child_voicebanks: $child_voicebanks, include_members: $include_members, status: $status, start: $start, max_results: $max_results, get_total_count: $get_total_count, sort: $sort, fields: $fields, lang: $lang, sort_direction: $sort_direction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/releaseEvents/names
#
# Returns: list<string>
export def "get-api-release-events-names" [
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
  --query: string # default: ""
  --max-results: int # format: int32, default: 10
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/releaseEvents/names"
    query: [{name: query, var: query}, {name: maxResults, var: max_results}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    query: $query, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/releaseEvents/{eventId}/albums
#
# Returns: table<additionalNames: string, artistString: string, artists: list<record>, barcode: string, catalogNumber: string, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, discType: string, discs: list<record>, id: int, identifiers: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: list<record>, pvs: list<record>, ratingAverage: float, ratingCount: int, releaseDate: record<day: int, formatted: string, isEmpty: bool, month: int, year: int>, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, status: string, tags: list<record>, tracks: list<record>, version: int, webLinks: list<record>>
export def "get-api-release-events-event-id-albums" [
  event_id: int
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
  --fields: string@fields-completer-1
  --lang: string@lang-completer
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/releaseEvents/{eventId}/albums"
    path_params: [{name: eventId, var: event_id}]
    query: [{name: fields, var: fields}, {name: lang, var: lang}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    event_id: $event_id, fields: $fields, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/releaseEvents/{eventId}/published-songs
#
# Returns: table<additionalNames: string, albums: list<record>, artistString: string, artists: list<record>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list<record>, originalVersionId: int, publishDate: string, pvServices: string, pvs: list<record>, ratingScore: int, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, songType: string, status: string, tags: list<record>, thumbUrl: string, version: int, webLinks: list<record>>
export def "get-api-release-events-event-id-published-songs" [
  event_id: int
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
  --fields: string@fields-completer-2
  --lang: string@lang-completer
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/releaseEvents/{eventId}/published-songs"
    path_params: [{name: eventId, var: event_id}]
    query: [{name: fields, var: fields}, {name: lang, var: lang}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    event_id: $event_id, fields: $fields, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/releaseEvents/{eventId}/reports
export def "post-api-release-events-event-id-reports" [
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-type: string@report-type-completer
  --notes: string
  --version-number: int # format: int32
]: nothing -> any {
  http-request {
    method: post
    path: "/api/releaseEvents/{eventId}/reports"
    path_params: [{name: eventId, var: event_id}]
    query: [{name: reportType, var: report_type}, {name: notes, var: notes}, {name: versionNumber, var: version_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    event_id: $event_id, report_type: $report_type, notes: $notes, version_number: $version_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /api/releaseEvents/{id}
export def "delete-api-release-events-id" [
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
  --notes: string # default: ""
  --hard-delete: oneof<nothing, bool> # default: false
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/releaseEvents/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: notes, var: notes}, {name: hardDelete, var: hard_delete}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, notes: $notes, hard_delete: $hard_delete
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/releaseEvents/{id}
#
# Returns: record<additionalNames: string, artists: table<artist: record, effectiveRoles: string, id: int, name: string, roles: string>, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: table<language: string, value: string>, pvs: table<author: string, createdBy: int, disabled: bool, extendedMetadata: record, id: int, length: int, name: string, publishDate: string, pvId: string, pvType: string, service: string, thumbUrl: string, url: string>, series: record<additionalNames: string, category: string, deleted: bool, description: string, id: int, name: string, pictureMime: string, status: string, urlSlug: string, version: int, webLinks: list<record>>, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record<featuredCategory: string, id: int, name: string>, status: string, tags: table<count: int, tag: record>, urlSlug: string, venue: record<additionalNames: string, address: string, addressCountryCode: string, coordinates: record<formatted: string, hasValue: bool, latitude: float, longitude: float>, deleted: bool, description: string, events: list<record>, id: int, name: string, names: list<record>, status: string, version: int, webLinks: list<record>>, venueName: string, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>>
export def "get-api-release-events-id" [
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
  --accept: string@accept-completer # Response content type
  --fields: string@fields-completer-10
  --lang: string@lang-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/releaseEvents/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}, {name: lang, var: lang}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields: $fields, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/resources/{cultureCode}
#
# Returns: record
export def "get-api-resources-culture-code" [
  culture_code: string
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
  --set-names: list<string>
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/resources/{cultureCode}"
    path_params: [{name: cultureCode, var: culture_code}]
    query: [{name: "setNames[]", var: set_names, style: multi}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    culture_code: $culture_code, set_names: $set_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/songLists
#
# Returns: int
export def "post-api-song-lists" [
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
  --deleted: oneof<nothing, bool>
  --description: string # nullable
  --event-date: string # nullable, format: date-time
  --featured-category: string@featured-category-completer
  --id: int # format: int32
  --main-picture: record # shape: {mime?: string, name?: string, urlOriginal?: string, urlSmallThumb?: string, urlThumb?: string, urlTinyThumb?: string}
  --name: string # nullable
  --song-links: list # nullable — item shape: {notes?: string, order?: int, song?: record, songInListId?: int}
  --status: string@status-completer
  --update-notes: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/songLists"
    body: {content_type: "application/json", kind: json, fields: [{name: deleted, var: deleted}, {name: description, var: description}, {name: eventDate, var: event_date}, {name: featuredCategory, var: featured_category}, {name: id, var: id}, {name: mainPicture, var: main_picture}, {name: name, var: name}, {name: songLinks, var: song_links}, {name: status, var: status}, {name: updateNotes, var: update_notes}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    deleted: $deleted, description: $description, event_date: $event_date, featured_category: $featured_category, id: $id, main_picture: $main_picture, name: $name, song_links: $song_links, status: $status, update_notes: $update_notes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DELETE /api/songLists/comments/{commentId}
export def "delete-api-song-lists-comments-comment-id" [
  comment_id: int
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
    path: "/api/songLists/comments/{commentId}"
    path_params: [{name: commentId, var: comment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    comment_id: $comment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/songLists/comments/{commentId}
export def "post-api-song-lists-comments-comment-id" [
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --author-name: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
  --id: int # format: int32
  --message: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/songLists/comments/{commentId}"
    path_params: [{name: commentId, var: comment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: author, var: author}, {name: authorName, var: author_name}, {name: created, var: created}, {name: entry, var: entry}, {name: id, var: id}, {name: message, var: message}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    comment_id: $comment_id, author: $author, author_name: $author_name, created: $created, entry: $entry, id: $id, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/songLists/featured
#
# Returns: record<items: table<author: record, deleted: bool, description: string, eventDate: string, events: list, featuredCategory: string, id: int, latestComments: list, mainPicture: record, name: string, status: string, tags: list>, term: string, totalCount: int>
export def "get-api-song-lists-featured" [
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
  --query: string # default: ""
  --tag-id: list<int>
  --child-tags: oneof<nothing, bool> # default: false
  --name-match-mode: string@name-match-mode-completer
  --featured-category: string@featured-category-completer
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --sort: string@sort-completer-5
  --fields: string@fields-completer-11
  --lang: string@lang-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/songLists/featured"
    query: [{name: query, var: query}, {name: "tagId[]", var: tag_id, style: multi}, {name: childTags, var: child_tags}, {name: nameMatchMode, var: name_match_mode}, {name: featuredCategory, var: featured_category}, {name: start, var: start}, {name: maxResults, var: max_results}, {name: getTotalCount, var: get_total_count}, {name: sort, var: sort}, {name: fields, var: fields}, {name: lang, var: lang}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    query: $query, tag_id: $tag_id, child_tags: $child_tags, name_match_mode: $name_match_mode, featured_category: $featured_category, start: $start, max_results: $max_results, get_total_count: $get_total_count, sort: $sort, fields: $fields, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/songLists/featured/names
#
# Returns: list<string>
export def "get-api-song-lists-featured-names" [
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
  --query: string # default: ""
  --name-match-mode: string@name-match-mode-completer
  --featured-category: string@featured-category-completer
  --max-results: int # format: int32, default: 10
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/songLists/featured/names"
    query: [{name: query, var: query}, {name: nameMatchMode, var: name_match_mode}, {name: featuredCategory, var: featured_category}, {name: maxResults, var: max_results}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    query: $query, name_match_mode: $name_match_mode, featured_category: $featured_category, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DELETE /api/songLists/{id}
export def "delete-api-song-lists-id" [
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
  --notes: string # default: ""
  --hard-delete: oneof<nothing, bool> # default: false
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/songLists/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: notes, var: notes}, {name: hardDelete, var: hard_delete}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, notes: $notes, hard_delete: $hard_delete
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/songLists/{listId}/comments
#
# Returns: record<items: table<author: record, authorName: string, created: string, entry: record, id: int, message: string>, term: string, totalCount: int>
export def "get-api-song-lists-list-id-comments" [
  list_id: int
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
    path: "/api/songLists/{listId}/comments"
    path_params: [{name: listId, var: list_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    list_id: $list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/songLists/{listId}/comments
#
# Returns: record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list<record>, urlSlug: string, version: int, webLinks: list<record>>, id: int, message: string>
export def "post-api-song-lists-list-id-comments" [
  list_id: int
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
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --author-name: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
  --id: int # format: int32
  --message: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/songLists/{listId}/comments"
    path_params: [{name: listId, var: list_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: author, var: author}, {name: authorName, var: author_name}, {name: created, var: created}, {name: entry, var: entry}, {name: id, var: id}, {name: message, var: message}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    list_id: $list_id, author: $author, author_name: $author_name, created: $created, entry: $entry, id: $id, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/songLists/{listId}/songs
#
# Returns: record<items: table<notes: string, order: int, song: record>, term: string, totalCount: int>
export def "get-api-song-lists-list-id-songs" [
  list_id: int
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
  --query: string # default: ""
  --song-types: string
  --pv-services: string@pv-services-completer
  --tag-id: list<int>
  --artist-id: list<int>
  --child-voicebanks: oneof<nothing, bool> # default: false
  --advanced-filters: list
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --sort: string@sort-completer-6
  --name-match-mode: string@name-match-mode-completer
  --fields: string@fields-completer-2
  --lang: string@lang-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/songLists/{listId}/songs"
    path_params: [{name: listId, var: list_id}]
    query: [{name: query, var: query}, {name: songTypes, var: song_types}, {name: pvServices, var: pv_services}, {name: "tagId[]", var: tag_id, style: multi}, {name: "artistId[]", var: artist_id, style: multi}, {name: childVoicebanks, var: child_voicebanks}, {name: advancedFilters, var: advanced_filters, style: multi}, {name: start, var: start}, {name: maxResults, var: max_results}, {name: getTotalCount, var: get_total_count}, {name: sort, var: sort}, {name: nameMatchMode, var: name_match_mode}, {name: fields, var: fields}, {name: lang, var: lang}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    list_id: $list_id, query: $query, song_types: $song_types, pv_services: $pv_services, tag_id: $tag_id, artist_id: $artist_id, child_voicebanks: $child_voicebanks, advanced_filters: $advanced_filters, start: $start, max_results: $max_results, get_total_count: $get_total_count, sort: $sort, name_match_mode: $name_match_mode, fields: $fields, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/songs
#
# Returns: record<items: table<additionalNames: string, albums: list, artistString: string, artists: list, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list, mainPicture: record, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list, originalVersionId: int, publishDate: string, pvServices: string, pvs: list, ratingScore: int, releaseEvent: record, songType: string, status: string, tags: list, thumbUrl: string, version: int, webLinks: list>, term: string, totalCount: int>
export def "get-api-songs" [
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
  --query: string # default: ""
  --song-types: string
  --after-date: string # format: date-time
  --before-date: string # format: date-time
  --tag-name: list<string>
  --tag-id: list<int>
  --child-tags: oneof<nothing, bool> # default: false
  --unify-types-and-tags: oneof<nothing, bool> # default: false
  --artist-id: list<int>
  --artist-participation-status: string@artist-participation-status-completer
  --child-voicebanks: oneof<nothing, bool> # default: false
  --include-members: oneof<nothing, bool> # default: false
  --only-with-pvs: oneof<nothing, bool> # default: false
  --pv-services: string@pv-services-completer
  --since: int # format: int32
  --min-score: int # format: int32
  --user-collection-id: int # format: int32
  --release-event-id: int # format: int32
  --parent-song-id: int # format: int32
  --status: string@status-completer
  --advanced-filters: list
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --sort: string@sort-completer-6
  --prefer-accurate-matches: oneof<nothing, bool> # default: false
  --name-match-mode: string@name-match-mode-completer
  --fields: string@fields-completer-2
  --lang: string@lang-completer
  --min-milli-bpm: int # format: int32
  --max-milli-bpm: int # format: int32
  --min-length: int # format: int32
  --max-length: int # format: int32
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/songs"
    query: [{name: query, var: query}, {name: songTypes, var: song_types}, {name: afterDate, var: after_date}, {name: beforeDate, var: before_date}, {name: "tagName[]", var: tag_name, style: multi}, {name: "tagId[]", var: tag_id, style: multi}, {name: childTags, var: child_tags}, {name: unifyTypesAndTags, var: unify_types_and_tags}, {name: "artistId[]", var: artist_id, style: multi}, {name: artistParticipationStatus, var: artist_participation_status}, {name: childVoicebanks, var: child_voicebanks}, {name: includeMembers, var: include_members}, {name: onlyWithPvs, var: only_with_pvs}, {name: pvServices, var: pv_services}, {name: since, var: since}, {name: minScore, var: min_score}, {name: userCollectionId, var: user_collection_id}, {name: releaseEventId, var: release_event_id}, {name: parentSongId, var: parent_song_id}, {name: status, var: status}, {name: advancedFilters, var: advanced_filters, style: multi}, {name: start, var: start}, {name: maxResults, var: max_results}, {name: getTotalCount, var: get_total_count}, {name: sort, var: sort}, {name: preferAccurateMatches, var: prefer_accurate_matches}, {name: nameMatchMode, var: name_match_mode}, {name: fields, var: fields}, {name: lang, var: lang}, {name: minMilliBpm, var: min_milli_bpm}, {name: maxMilliBpm, var: max_milli_bpm}, {name: minLength, var: min_length}, {name: maxLength, var: max_length}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    query: $query, song_types: $song_types, after_date: $after_date, before_date: $before_date, tag_name: $tag_name, tag_id: $tag_id, child_tags: $child_tags, unify_types_and_tags: $unify_types_and_tags, artist_id: $artist_id, artist_participation_status: $artist_participation_status, child_voicebanks: $child_voicebanks, include_members: $include_members, only_with_pvs: $only_with_pvs, pv_services: $pv_services, since: $since, min_score: $min_score, user_collection_id: $user_collection_id, release_event_id: $release_event_id, parent_song_id: $parent_song_id, status: $status, advanced_filters: $advanced_filters, start: $start, max_results: $max_results, get_total_count: $get_total_count, sort: $sort, prefer_accurate_matches: $prefer_accurate_matches, name_match_mode: $name_match_mode, fields: $fields, lang: $lang, min_milli_bpm: $min_milli_bpm, max_milli_bpm: $max_milli_bpm, min_length: $min_length, max_length: $max_length
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/songs/byPv
#
# Returns: record<additionalNames: string, albums: table<additionalNames: string, artistString: string, coverPictureMime: string, createDate: string, deleted: bool, discType: string, id: int, name: string, ratingAverage: float, ratingCount: int, releaseDate: record, releaseEvent: record, status: string, version: int>, artistString: string, artists: table<artist: record, categories: string, effectiveRoles: string, id: int, isCustomName: bool, isSupport: bool, name: string, roles: string>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: table<cultureCode: string, id: int, source: string, translationType: string, url: string, value: string>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: table<language: string, value: string>, originalVersionId: int, publishDate: string, pvServices: string, pvs: table<author: string, createdBy: int, disabled: bool, extendedMetadata: record, id: int, length: int, name: string, publishDate: string, pvId: string, pvType: string, service: string, thumbUrl: string, url: string>, ratingScore: int, releaseEvent: record<additionalNames: string, artists: list<record>, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, series: record<additionalNames: string, category: string, deleted: bool, description: string, id: int, name: string, pictureMime: string, status: string, urlSlug: string, version: int, webLinks: list>, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record<featuredCategory: string, id: int, name: string>, status: string, tags: list<record>, urlSlug: string, venue: record<additionalNames: string, address: string, addressCountryCode: string, coordinates: record, deleted: bool, description: string, events: list, id: int, name: string, names: list, status: string, version: int, webLinks: list>, venueName: string, version: int, webLinks: list<record>>, songType: string, status: string, tags: table<count: int, tag: record>, thumbUrl: string, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>>
export def "get-api-songs-by-pv" [
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
  --pv-service: string@pv-service-completer
  --pv-id: string
  --fields: string@fields-completer-2
  --lang: string@lang-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/songs/byPv"
    query: [{name: pvService, var: pv_service}, {name: pvId, var: pv_id}, {name: fields, var: fields}, {name: lang, var: lang}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    pv_service: $pv_service, pv_id: $pv_id, fields: $fields, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DELETE /api/songs/comments/{commentId}
export def "delete-api-songs-comments-comment-id" [
  comment_id: int
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
    path: "/api/songs/comments/{commentId}"
    path_params: [{name: commentId, var: comment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    comment_id: $comment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/songs/comments/{commentId}
export def "post-api-songs-comments-comment-id" [
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --author-name: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
  --id: int # format: int32
  --message: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/songs/comments/{commentId}"
    path_params: [{name: commentId, var: comment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: author, var: author}, {name: authorName, var: author_name}, {name: created, var: created}, {name: entry, var: entry}, {name: id, var: id}, {name: message, var: message}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    comment_id: $comment_id, author: $author, author_name: $author_name, created: $created, entry: $entry, id: $id, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/songs/highlighted
#
# Returns: table<additionalNames: string, albums: list<record>, artistString: string, artists: list<record>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list<record>, originalVersionId: int, publishDate: string, pvServices: string, pvs: list<record>, ratingScore: int, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, songType: string, status: string, tags: list<record>, thumbUrl: string, version: int, webLinks: list<record>>
export def "get-api-songs-highlighted" [
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
  --language-preference: string@language-preference-completer
  --fields: string@fields-completer-2
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/songs/highlighted"
    query: [{name: languagePreference, var: language_preference}, {name: fields, var: fields}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    language_preference: $language_preference, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/songs/lyrics/{lyricsId}
#
# Returns: record<cultureCode: string, id: int, source: string, translationType: string, url: string, value: string>
export def "get-api-songs-lyrics-lyrics-id" [
  lyrics_id: int
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
    path: "/api/songs/lyrics/{lyricsId}"
    path_params: [{name: lyricsId, var: lyrics_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    lyrics_id: $lyrics_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/songs/names
#
# Returns: list<string>
export def "get-api-songs-names" [
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
  --query: string # default: ""
  --name-match-mode: string@name-match-mode-completer
  --max-results: int # format: int32, default: 15
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/songs/names"
    query: [{name: query, var: query}, {name: nameMatchMode, var: name_match_mode}, {name: maxResults, var: max_results}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    query: $query, name_match_mode: $name_match_mode, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/songs/top-rated
#
# Returns: table<additionalNames: string, albums: list<record>, artistString: string, artists: list<record>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list<record>, originalVersionId: int, publishDate: string, pvServices: string, pvs: list<record>, ratingScore: int, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, songType: string, status: string, tags: list<record>, thumbUrl: string, version: int, webLinks: list<record>>
export def "get-api-songs-top-rated" [
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
  --duration-hours: int # format: int32
  --start-date: string # format: date-time
  --filter-by: string@filter-by-completer
  --vocalist: string@vocalist-completer
  --max-results: int # format: int32, default: 25
  --fields: string@fields-completer-2
  --language-preference: string@language-preference-completer
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/songs/top-rated"
    query: [{name: durationHours, var: duration_hours}, {name: startDate, var: start_date}, {name: filterBy, var: filter_by}, {name: vocalist, var: vocalist}, {name: maxResults, var: max_results}, {name: fields, var: fields}, {name: languagePreference, var: language_preference}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    duration_hours: $duration_hours, start_date: $start_date, filter_by: $filter_by, vocalist: $vocalist, max_results: $max_results, fields: $fields, language_preference: $language_preference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DELETE /api/songs/{id}
export def "delete-api-songs-id" [
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
  --notes: string # default: ""
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/songs/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: notes, var: notes}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, notes: $notes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/songs/{id}
#
# Returns: record<additionalNames: string, albums: table<additionalNames: string, artistString: string, coverPictureMime: string, createDate: string, deleted: bool, discType: string, id: int, name: string, ratingAverage: float, ratingCount: int, releaseDate: record, releaseEvent: record, status: string, version: int>, artistString: string, artists: table<artist: record, categories: string, effectiveRoles: string, id: int, isCustomName: bool, isSupport: bool, name: string, roles: string>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: table<cultureCode: string, id: int, source: string, translationType: string, url: string, value: string>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: table<language: string, value: string>, originalVersionId: int, publishDate: string, pvServices: string, pvs: table<author: string, createdBy: int, disabled: bool, extendedMetadata: record, id: int, length: int, name: string, publishDate: string, pvId: string, pvType: string, service: string, thumbUrl: string, url: string>, ratingScore: int, releaseEvent: record<additionalNames: string, artists: list<record>, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, series: record<additionalNames: string, category: string, deleted: bool, description: string, id: int, name: string, pictureMime: string, status: string, urlSlug: string, version: int, webLinks: list>, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record<featuredCategory: string, id: int, name: string>, status: string, tags: list<record>, urlSlug: string, venue: record<additionalNames: string, address: string, addressCountryCode: string, coordinates: record, deleted: bool, description: string, events: list, id: int, name: string, names: list, status: string, version: int, webLinks: list>, venueName: string, version: int, webLinks: list<record>>, songType: string, status: string, tags: table<count: int, tag: record>, thumbUrl: string, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>>
export def "get-api-songs-id" [
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
  --accept: string@accept-completer # Response content type
  --fields: string@fields-completer-2
  --lang: string@lang-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/songs/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}, {name: lang, var: lang}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields: $fields, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/songs/{id}/comments
#
# Returns: table<author: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record, name: string, names: list, pvs: list, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list, urlSlug: string, version: int, webLinks: list>, id: int, message: string>
export def "get-api-songs-id-comments" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/songs/{id}/comments"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/songs/{id}/comments
#
# Returns: record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list<record>, urlSlug: string, version: int, webLinks: list<record>>, id: int, message: string>
export def "post-api-songs-id-comments" [
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
  --accept: string@accept-completer # Response content type
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --author-name: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
  --body-id: int # format: int32 (spec name: id)
  --message: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/songs/{id}/comments"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: author, var: author}, {name: authorName, var: author_name}, {name: created, var: created}, {name: entry, var: entry}, {name: id, var: body_id}, {name: message, var: message}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, author: $author, author_name: $author_name, created: $created, entry: $entry, body_id: $body_id, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/songs/{id}/derived
#
# Returns: table<additionalNames: string, albums: list<record>, artistString: string, artists: list<record>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list<record>, originalVersionId: int, publishDate: string, pvServices: string, pvs: list<record>, ratingScore: int, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, songType: string, status: string, tags: list<record>, thumbUrl: string, version: int, webLinks: list<record>>
export def "get-api-songs-id-derived" [
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
  --accept: string@accept-completer # Response content type
  --fields: string@fields-completer-2
  --lang: string@lang-completer
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/songs/{id}/derived"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}, {name: lang, var: lang}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields: $fields, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/songs/{id}/ratings
#
# Returns: table<date: string, rating: string, song: record<additionalNames: string, albums: list, artistString: string, artists: list, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list, mainPicture: record, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list, originalVersionId: int, publishDate: string, pvServices: string, pvs: list, ratingScore: int, releaseEvent: record, songType: string, status: string, tags: list, thumbUrl: string, version: int, webLinks: list>, user: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>>
export def "get-api-songs-id-ratings" [
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
  --accept: string@accept-completer # Response content type
  --user-fields: string@user-fields-completer
  --lang: string@lang-completer
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/songs/{id}/ratings"
    path_params: [{name: id, var: id}]
    query: [{name: userFields, var: user_fields}, {name: lang, var: lang}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, user_fields: $user_fields, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/songs/{id}/ratings
export def "post-api-songs-id-ratings" [
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
  --rating: string@rating-completer
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/songs/{id}/ratings"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: rating, var: rating}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rating: $rating
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/songs/{id}/related
#
# Returns: record<artistMatches: table<additionalNames: string, albums: list, artistString: string, artists: list, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list, mainPicture: record, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list, originalVersionId: int, publishDate: string, pvServices: string, pvs: list, ratingScore: int, releaseEvent: record, songType: string, status: string, tags: list, thumbUrl: string, version: int, webLinks: list>, likeMatches: table<additionalNames: string, albums: list, artistString: string, artists: list, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list, mainPicture: record, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list, originalVersionId: int, publishDate: string, pvServices: string, pvs: list, ratingScore: int, releaseEvent: record, songType: string, status: string, tags: list, thumbUrl: string, version: int, webLinks: list>, tagMatches: table<additionalNames: string, albums: list, artistString: string, artists: list, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list, mainPicture: record, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list, originalVersionId: int, publishDate: string, pvServices: string, pvs: list, ratingScore: int, releaseEvent: record, songType: string, status: string, tags: list, thumbUrl: string, version: int, webLinks: list>>
export def "get-api-songs-id-related" [
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
  --accept: string@accept-completer # Response content type
  --fields: string@fields-completer-2
  --lang: string@lang-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/songs/{id}/related"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}, {name: lang, var: lang}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields: $fields, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/tags
#
# Returns: record<items: table<additionalNames: string, aliasedTo: record, categoryName: string, createDate: string, defaultNameLanguage: string, description: string, id: int, mainPicture: record, name: string, names: list, parent: record, relatedTags: list, status: string, targets: int, translatedDescription: record, urlSlug: string, usageCount: int, version: int, webLinks: list>, term: string, totalCount: int>
export def "get-api-tags" [
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
  --query: string # default: ""
  --allow-children: oneof<nothing, bool> # default: true
  --category-name: string # default: ""
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --name-match-mode: string@name-match-mode-completer
  --sort: string@sort-completer-7
  --prefer-accurate-matches: oneof<nothing, bool> # default: false
  --fields: string@fields-completer-8
  --lang: string@lang-completer
  --target: string@target-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/tags"
    query: [{name: query, var: query}, {name: allowChildren, var: allow_children}, {name: categoryName, var: category_name}, {name: start, var: start}, {name: maxResults, var: max_results}, {name: getTotalCount, var: get_total_count}, {name: nameMatchMode, var: name_match_mode}, {name: sort, var: sort}, {name: preferAccurateMatches, var: prefer_accurate_matches}, {name: fields, var: fields}, {name: lang, var: lang}, {name: target, var: target}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    query: $query, allow_children: $allow_children, category_name: $category_name, start: $start, max_results: $max_results, get_total_count: $get_total_count, name_match_mode: $name_match_mode, sort: $sort, prefer_accurate_matches: $prefer_accurate_matches, fields: $fields, lang: $lang, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/tags
#
# Returns: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>
export def "post-api-tags" [
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
  --name: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/tags"
    query: [{name: name, var: name}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/tags/byName/{name}
#
# DEPRECATED
# Returns: record<additionalNames: string, aliasedTo: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, categoryName: string, createDate: string, defaultNameLanguage: string, description: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: table<id: int, language: string, value: string>, parent: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, relatedTags: table<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, status: string, targets: int, translatedDescription: record<english: string, original: string>, urlSlug: string, usageCount: int, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>>
@deprecated
export def "get-api-tags-by-name-name" [
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
  --accept: string@accept-completer # Response content type
  --fields: string@fields-completer-8
  --lang: string@lang-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/tags/byName/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: fields, var: fields}, {name: lang, var: lang}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    name: $name, fields: $fields, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/tags/categoryNames
#
# Returns: list<string>
export def "get-api-tags-category-names" [
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
  --query: string # default: ""
  --name-match-mode: string@name-match-mode-completer
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/tags/categoryNames"
    query: [{name: query, var: query}, {name: nameMatchMode, var: name_match_mode}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    query: $query, name_match_mode: $name_match_mode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DELETE /api/tags/comments/{commentId}
export def "delete-api-tags-comments-comment-id" [
  comment_id: int
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
    path: "/api/tags/comments/{commentId}"
    path_params: [{name: commentId, var: comment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    comment_id: $comment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/tags/comments/{commentId}
export def "post-api-tags-comments-comment-id" [
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --author-name: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
  --id: int # format: int32
  --message: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/tags/comments/{commentId}"
    path_params: [{name: commentId, var: comment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: author, var: author}, {name: authorName, var: author_name}, {name: created, var: created}, {name: entry, var: entry}, {name: id, var: id}, {name: message, var: message}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    comment_id: $comment_id, author: $author, author_name: $author_name, created: $created, entry: $entry, id: $id, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/tags/names
#
# Returns: list<string>
export def "get-api-tags-names" [
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
  --query: string # default: ""
  --allow-aliases: oneof<nothing, bool> # default: true
  --max-results: int # format: int32, default: 10
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/tags/names"
    query: [{name: query, var: query}, {name: allowAliases, var: allow_aliases}, {name: maxResults, var: max_results}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    query: $query, allow_aliases: $allow_aliases, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/tags/top
#
# Returns: table<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>
export def "get-api-tags-top" [
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
  --category-name: string
  --entry-type: string@entry-type-completer
  --max-results: int # format: int32, default: 15
  --lang: string@lang-completer
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/tags/top"
    query: [{name: categoryName, var: category_name}, {name: entryType, var: entry_type}, {name: maxResults, var: max_results}, {name: lang, var: lang}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    category_name: $category_name, entry_type: $entry_type, max_results: $max_results, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DELETE /api/tags/{id}
export def "delete-api-tags-id" [
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
  --notes: string # default: ""
  --hard-delete: oneof<nothing, bool> # default: false
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/tags/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: notes, var: notes}, {name: hardDelete, var: hard_delete}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, notes: $notes, hard_delete: $hard_delete
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/tags/{id}
#
# Returns: record<additionalNames: string, aliasedTo: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, categoryName: string, createDate: string, defaultNameLanguage: string, description: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: table<id: int, language: string, value: string>, parent: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, relatedTags: table<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, status: string, targets: int, translatedDescription: record<english: string, original: string>, urlSlug: string, usageCount: int, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>>
export def "get-api-tags-id" [
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
  --accept: string@accept-completer # Response content type
  --fields: string@fields-completer-8
  --lang: string@lang-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/tags/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}, {name: lang, var: lang}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields: $fields, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/tags/{tagId}/children
#
# Returns: table<additionalNames: string, aliasedTo: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, categoryName: string, createDate: string, defaultNameLanguage: string, description: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, parent: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, relatedTags: list<record>, status: string, targets: int, translatedDescription: record<english: string, original: string>, urlSlug: string, usageCount: int, version: int, webLinks: list<record>>
export def "get-api-tags-tag-id-children" [
  tag_id: int
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
  --fields: string@fields-completer-8
  --lang: string@lang-completer
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/tags/{tagId}/children"
    path_params: [{name: tagId, var: tag_id}]
    query: [{name: fields, var: fields}, {name: lang, var: lang}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    tag_id: $tag_id, fields: $fields, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/tags/{tagId}/comments
#
# Returns: record<items: table<author: record, authorName: string, created: string, entry: record, id: int, message: string>, term: string, totalCount: int>
export def "get-api-tags-tag-id-comments" [
  tag_id: int
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
    path: "/api/tags/{tagId}/comments"
    path_params: [{name: tagId, var: tag_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    tag_id: $tag_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/tags/{tagId}/comments
#
# Returns: record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list<record>, urlSlug: string, version: int, webLinks: list<record>>, id: int, message: string>
export def "post-api-tags-tag-id-comments" [
  tag_id: int
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
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --author-name: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
  --id: int # format: int32
  --message: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/tags/{tagId}/comments"
    path_params: [{name: tagId, var: tag_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: author, var: author}, {name: authorName, var: author_name}, {name: created, var: created}, {name: entry, var: entry}, {name: id, var: id}, {name: message, var: message}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    tag_id: $tag_id, author: $author, author_name: $author_name, created: $created, entry: $entry, id: $id, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/tags/{tagId}/reports
export def "post-api-tags-tag-id-reports" [
  tag_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-type: string@report-type-completer
  --notes: string
  --version-number: int # format: int32
]: nothing -> any {
  http-request {
    method: post
    path: "/api/tags/{tagId}/reports"
    path_params: [{name: tagId, var: tag_id}]
    query: [{name: reportType, var: report_type}, {name: notes, var: notes}, {name: versionNumber, var: version_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tag_id: $tag_id, report_type: $report_type, notes: $notes, version_number: $version_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/users
#
# Returns: record<items: table<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>, term: string, totalCount: int>
export def "get-api-users" [
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
  --query: string # default: ""
  --groups: string@groups-completer
  --join-date-after: string # format: date-time
  --join-date-before: string # format: date-time
  --name-match-mode: string@name-match-mode-completer
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --sort: string@sort-completer-8
  --include-disabled: oneof<nothing, bool> # default: false
  --only-verified: oneof<nothing, bool> # default: false
  --knows-language: string
  --fields: string@fields-completer-12
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/users"
    query: [{name: query, var: query}, {name: groups, var: groups}, {name: joinDateAfter, var: join_date_after}, {name: joinDateBefore, var: join_date_before}, {name: nameMatchMode, var: name_match_mode}, {name: start, var: start}, {name: maxResults, var: max_results}, {name: getTotalCount, var: get_total_count}, {name: sort, var: sort}, {name: includeDisabled, var: include_disabled}, {name: onlyVerified, var: only_verified}, {name: knowsLanguage, var: knows_language}, {name: fields, var: fields}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    query: $query, groups: $groups, join_date_after: $join_date_after, join_date_before: $join_date_before, name_match_mode: $name_match_mode, start: $start, max_results: $max_results, get_total_count: $get_total_count, sort: $sort, include_disabled: $include_disabled, only_verified: $only_verified, knows_language: $knows_language, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/users/current
#
# Returns: record<active: bool, groupId: string, id: int, knownLanguages: table<cultureCode: string, proficiency: string>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: table<date: string, oldName: string>, verifiedArtist: bool>
export def "get-api-users-current" [
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
  --fields: string@fields-completer-12
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/users/current"
    query: [{name: fields, var: fields}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/users/current/album-collection-statuses/{albumId}
#
# Returns: record<album: record<additionalNames: string, artistString: string, artists: list<record>, barcode: string, catalogNumber: string, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, discType: string, discs: list<record>, id: int, identifiers: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: list<record>, pvs: list<record>, ratingAverage: float, ratingCount: int, releaseDate: record<day: int, formatted: string, isEmpty: bool, month: int, year: int>, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, status: string, tags: list<record>, tracks: list<record>, version: int, webLinks: list<record>>, mediaType: string, purchaseStatus: string, rating: int, user: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>>
export def "get-api-users-current-album-collection-statuses-album-id" [
  album_id: int
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
    path: "/api/users/current/album-collection-statuses/{albumId}"
    path_params: [{name: albumId, var: album_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    album_id: $album_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/users/current/albums/{albumId}
#
# Returns: string
export def "post-api-users-current-albums-album-id" [
  album_id: int
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
  --collection-status: string@collection-status-completer
  --media-type: string@media-type-completer
  --rating: int # format: int32
]: nothing -> any {
  http-request {
    method: post
    path: "/api/users/current/albums/{albumId}"
    path_params: [{name: albumId, var: album_id}]
    query: [{name: collectionStatus, var: collection_status}, {name: mediaType, var: media_type}, {name: rating, var: rating}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    album_id: $album_id, collection_status: $collection_status, media_type: $media_type, rating: $rating
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/users/current/followedArtists/{artistId}
#
# Returns: record<artist: record<additionalNames: string, artistLinks: list<record>, artistLinksReverse: list<record>, artistType: string, baseVoicebank: record<additionalNames: string, artistType: string, deleted: bool, id: int, name: string, pictureMime: string, releaseDate: string, status: string, version: int>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: list<record>, pictureMime: string, relations: record<latestAlbums: list, latestEvents: list, latestSongs: list, popularAlbums: list, popularSongs: list>, releaseDate: string, status: string, tags: list<record>, version: int, webLinks: list<record>>, id: int>
export def "get-api-users-current-followed-artists-artist-id" [
  artist_id: int
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
    path: "/api/users/current/followedArtists/{artistId}"
    path_params: [{name: artistId, var: artist_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    artist_id: $artist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DELETE /api/users/current/followedTags/{tagId}
export def "delete-api-users-current-followed-tags-tag-id" [
  tag_id: int
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
    path: "/api/users/current/followedTags/{tagId}"
    path_params: [{name: tagId, var: tag_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tag_id: $tag_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/users/current/followedTags/{tagId}
export def "post-api-users-current-followed-tags-tag-id" [
  tag_id: int
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
    path: "/api/users/current/followedTags/{tagId}"
    path_params: [{name: tagId, var: tag_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tag_id: $tag_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/users/current/ratedSongs/{songId}
#
# Returns: string
export def "get-api-users-current-rated-songs-song-id" [
  song_id: int
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
    path: "/api/users/current/ratedSongs/{songId}"
    path_params: [{name: songId, var: song_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    song_id: $song_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/users/current/refreshEntryEdit
#
# Returns: record<time: string, userId: int, userName: string>
export def "post-api-users-current-refresh-entry-edit" [
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
  --entry-type: string@entry-type-completer
  --entry-id: int # format: int32
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/users/current/refreshEntryEdit"
    query: [{name: entryType, var: entry_type}, {name: entryId, var: entry_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    entry_type: $entry_type, entry_id: $entry_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/users/current/songTags/{songId}
export def "post-api-users-current-song-tags-song-id" [
  song_id: int
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
    path: "/api/users/current/songTags/{songId}"
    path_params: [{name: songId, var: song_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    song_id: $song_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/users/messages/{messageId}
#
# Returns: record<body: string, createdFormatted: string, highPriority: bool, id: int, inbox: string, read: bool, receiver: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, sender: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, subject: string>
export def "get-api-users-messages-message-id" [
  message_id: int
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
    path: "/api/users/messages/{messageId}"
    path_params: [{name: messageId, var: message_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    message_id: $message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/users/names
#
# Returns: list<string>
export def "get-api-users-names" [
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
  --query: string # default: ""
  --name-match-mode: string@name-match-mode-completer
  --max-results: int # format: int32, default: 10
  --include-disabled: oneof<nothing, bool> # default: false
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/users/names"
    query: [{name: query, var: query}, {name: nameMatchMode, var: name_match_mode}, {name: maxResults, var: max_results}, {name: includeDisabled, var: include_disabled}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    query: $query, name_match_mode: $name_match_mode, max_results: $max_results, include_disabled: $include_disabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DELETE /api/users/profileComments/{commentId}
export def "delete-api-users-profile-comments-comment-id" [
  comment_id: int
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
    path: "/api/users/profileComments/{commentId}"
    path_params: [{name: commentId, var: comment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    comment_id: $comment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/users/profileComments/{commentId}
export def "post-api-users-profile-comments-comment-id" [
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --author-name: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
  --id: int # format: int32
  --message: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/users/profileComments/{commentId}"
    path_params: [{name: commentId, var: comment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: author, var: author}, {name: authorName, var: author_name}, {name: created, var: created}, {name: entry, var: entry}, {name: id, var: id}, {name: message, var: message}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    comment_id: $comment_id, author: $author, author_name: $author_name, created: $created, entry: $entry, id: $id, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/users/{id}
#
# Returns: record<active: bool, groupId: string, id: int, knownLanguages: table<cultureCode: string, proficiency: string>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: table<date: string, oldName: string>, verifiedArtist: bool>
export def "get-api-users-id" [
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
  --accept: string@accept-completer # Response content type
  --fields: string@fields-completer-12
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/users/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/users/{id}/album-collection-statuses/{albumId}
#
# Returns: record<album: record<additionalNames: string, artistString: string, artists: list<record>, barcode: string, catalogNumber: string, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, discType: string, discs: list<record>, id: int, identifiers: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: list<record>, pvs: list<record>, ratingAverage: float, ratingCount: int, releaseDate: record<day: int, formatted: string, isEmpty: bool, month: int, year: int>, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, status: string, tags: list<record>, tracks: list<record>, version: int, webLinks: list<record>>, mediaType: string, purchaseStatus: string, rating: int, user: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>>
export def "get-api-users-id-album-collection-statuses-album-id" [
  id: int
  album_id: int
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
    path: "/api/users/{id}/album-collection-statuses/{albumId}"
    path_params: [{name: id, var: id}, {name: albumId, var: album_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, album_id: $album_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/users/{id}/albums
#
# Returns: record<items: table<album: record, mediaType: string, purchaseStatus: string, rating: int, user: record>, term: string, totalCount: int>
export def "get-api-users-id-albums" [
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
  --accept: string@accept-completer # Response content type
  --query: string # default: ""
  --tag-id: int # format: int32
  --tag: string
  --artist-id: int # format: int32
  --purchase-statuses: string@purchase-statuses-completer
  --release-event-id: int # format: int32, default: 0
  --album-types: string@album-types-completer
  --advanced-filters: list
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --sort: string@sort-completer
  --name-match-mode: string@name-match-mode-completer
  --fields: string@fields-completer-1
  --lang: string@lang-completer
  --media-type: string@media-type-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/users/{id}/albums"
    path_params: [{name: id, var: id}]
    query: [{name: query, var: query}, {name: tagId, var: tag_id}, {name: tag, var: tag}, {name: artistId, var: artist_id}, {name: purchaseStatuses, var: purchase_statuses}, {name: releaseEventId, var: release_event_id}, {name: albumTypes, var: album_types}, {name: advancedFilters, var: advanced_filters, style: multi}, {name: start, var: start}, {name: maxResults, var: max_results}, {name: getTotalCount, var: get_total_count}, {name: sort, var: sort}, {name: nameMatchMode, var: name_match_mode}, {name: fields, var: fields}, {name: lang, var: lang}, {name: mediaType, var: media_type}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, query: $query, tag_id: $tag_id, tag: $tag, artist_id: $artist_id, purchase_statuses: $purchase_statuses, release_event_id: $release_event_id, album_types: $album_types, advanced_filters: $advanced_filters, start: $start, max_results: $max_results, get_total_count: $get_total_count, sort: $sort, name_match_mode: $name_match_mode, fields: $fields, lang: $lang, media_type: $media_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/users/{id}/events
#
# Returns: table<additionalNames: string, artists: list<record>, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, series: record<additionalNames: string, category: string, deleted: bool, description: string, id: int, name: string, pictureMime: string, status: string, urlSlug: string, version: int, webLinks: list>, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record<featuredCategory: string, id: int, name: string>, status: string, tags: list<record>, urlSlug: string, venue: record<additionalNames: string, address: string, addressCountryCode: string, coordinates: record, deleted: bool, description: string, events: list, id: int, name: string, names: list, status: string, version: int, webLinks: list>, venueName: string, version: int, webLinks: list<record>>
export def "get-api-users-id-events" [
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
  --accept: string@accept-completer # Response content type
  --relationship-type: string@relationship-type-completer
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/users/{id}/events"
    path_params: [{name: id, var: id}]
    query: [{name: relationshipType, var: relationship_type}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, relationship_type: $relationship_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/users/{id}/followedArtists
#
# Returns: record<items: table<artist: record, id: int>, term: string, totalCount: int>
export def "get-api-users-id-followed-artists" [
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
  --accept: string@accept-completer # Response content type
  --query: string # default: ""
  --tag-id: list<int>
  --artist-type: string@artist-type-completer
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --sort: string@sort-completer-1
  --name-match-mode: string@name-match-mode-completer
  --fields: string@fields-completer-3
  --lang: string@lang-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/users/{id}/followedArtists"
    path_params: [{name: id, var: id}]
    query: [{name: query, var: query}, {name: "tagId[]", var: tag_id, style: multi}, {name: artistType, var: artist_type}, {name: start, var: start}, {name: maxResults, var: max_results}, {name: getTotalCount, var: get_total_count}, {name: sort, var: sort}, {name: nameMatchMode, var: name_match_mode}, {name: fields, var: fields}, {name: lang, var: lang}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, query: $query, tag_id: $tag_id, artist_type: $artist_type, start: $start, max_results: $max_results, get_total_count: $get_total_count, sort: $sort, name_match_mode: $name_match_mode, fields: $fields, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/users/{id}/followedArtists/{artistId}
#
# Returns: record<artist: record<additionalNames: string, artistLinks: list<record>, artistLinksReverse: list<record>, artistType: string, baseVoicebank: record<additionalNames: string, artistType: string, deleted: bool, id: int, name: string, pictureMime: string, releaseDate: string, status: string, version: int>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: list<record>, pictureMime: string, relations: record<latestAlbums: list, latestEvents: list, latestSongs: list, popularAlbums: list, popularSongs: list>, releaseDate: string, status: string, tags: list<record>, version: int, webLinks: list<record>>, id: int>
export def "get-api-users-id-followed-artists-artist-id" [
  id: int
  artist_id: int
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
    path: "/api/users/{id}/followedArtists/{artistId}"
    path_params: [{name: id, var: id}, {name: artistId, var: artist_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, artist_id: $artist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DELETE /api/users/{id}/messages
export def "delete-api-users-id-messages" [
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
  --message-id: list<int>
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/users/{id}/messages"
    path_params: [{name: id, var: id}]
    query: [{name: messageId, var: message_id, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, message_id: $message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/users/{id}/messages
#
# Returns: record<items: table<body: string, createdFormatted: string, highPriority: bool, id: int, inbox: string, read: bool, receiver: record, sender: record, subject: string>, term: string, totalCount: int>
export def "get-api-users-id-messages" [
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
  --accept: string@accept-completer # Response content type
  --inbox: string@inbox-completer
  --unread: oneof<nothing, bool> # default: false
  --another-user-id: int # format: int32
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/users/{id}/messages"
    path_params: [{name: id, var: id}]
    query: [{name: inbox, var: inbox}, {name: unread, var: unread}, {name: anotherUserId, var: another_user_id}, {name: start, var: start}, {name: maxResults, var: max_results}, {name: getTotalCount, var: get_total_count}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, inbox: $inbox, unread: $unread, another_user_id: $another_user_id, start: $start, max_results: $max_results, get_total_count: $get_total_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/users/{id}/messages
#
# Returns: record<body: string, createdFormatted: string, highPriority: bool, id: int, inbox: string, read: bool, receiver: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, sender: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, subject: string>
export def "post-api-users-id-messages" [
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
  --accept: string@accept-completer # Response content type
  --body: string # nullable
  --created-formatted: string # nullable
  --high-priority: oneof<nothing, bool>
  --body-id: int # format: int32 (spec name: id)
  --inbox: string@inbox-completer
  --read: oneof<nothing, bool>
  --receiver: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --sender: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --subject: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/users/{id}/messages"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}, {name: createdFormatted, var: created_formatted}, {name: highPriority, var: high_priority}, {name: id, var: body_id}, {name: inbox, var: inbox}, {name: read, var: read}, {name: receiver, var: receiver}, {name: sender, var: sender}, {name: subject, var: subject}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body: $body, created_formatted: $created_formatted, high_priority: $high_priority, body_id: $body_id, inbox: $inbox, read: $read, receiver: $receiver, sender: $sender, subject: $subject
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/users/{id}/profileComments
#
# Returns: record<items: table<author: record, authorName: string, created: string, entry: record, id: int, message: string>, term: string, totalCount: int>
export def "get-api-users-id-profile-comments" [
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
  --accept: string@accept-completer # Response content type
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/users/{id}/profileComments"
    path_params: [{name: id, var: id}]
    query: [{name: start, var: start}, {name: maxResults, var: max_results}, {name: getTotalCount, var: get_total_count}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, start: $start, max_results: $max_results, get_total_count: $get_total_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/users/{id}/profileComments
#
# Returns: record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list<record>, urlSlug: string, version: int, webLinks: list<record>>, id: int, message: string>
export def "post-api-users-id-profile-comments" [
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
  --accept: string@accept-completer # Response content type
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --author-name: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
  --body-id: int # format: int32 (spec name: id)
  --message: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/users/{id}/profileComments"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: author, var: author}, {name: authorName, var: author_name}, {name: created, var: created}, {name: entry, var: entry}, {name: id, var: body_id}, {name: message, var: message}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, author: $author, author_name: $author_name, created: $created, entry: $entry, body_id: $body_id, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/users/{id}/ratedSongs
#
# Returns: record<items: table<date: string, rating: string, song: record, user: record>, term: string, totalCount: int>
export def "get-api-users-id-rated-songs" [
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
  --accept: string@accept-completer # Response content type
  --query: string # default: ""
  --tag-name: string
  --tag-id: list<int>
  --artist-id: list<int>
  --child-voicebanks: oneof<nothing, bool> # default: false
  --artist-grouping: string@artist-grouping-completer
  --rating: string@rating-completer
  --song-list-id: int # format: int32
  --group-by-rating: oneof<nothing, bool> # default: true
  --pv-services: string@pv-services-completer
  --advanced-filters: list
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --sort: string@sort-completer-9
  --name-match-mode: string@name-match-mode-completer
  --fields: string@fields-completer-2
  --lang: string@lang-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/users/{id}/ratedSongs"
    path_params: [{name: id, var: id}]
    query: [{name: query, var: query}, {name: tagName, var: tag_name}, {name: "tagId[]", var: tag_id, style: multi}, {name: "artistId[]", var: artist_id, style: multi}, {name: childVoicebanks, var: child_voicebanks}, {name: artistGrouping, var: artist_grouping}, {name: rating, var: rating}, {name: songListId, var: song_list_id}, {name: groupByRating, var: group_by_rating}, {name: pvServices, var: pv_services}, {name: advancedFilters, var: advanced_filters, style: multi}, {name: start, var: start}, {name: maxResults, var: max_results}, {name: getTotalCount, var: get_total_count}, {name: sort, var: sort}, {name: nameMatchMode, var: name_match_mode}, {name: fields, var: fields}, {name: lang, var: lang}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, query: $query, tag_name: $tag_name, tag_id: $tag_id, artist_id: $artist_id, child_voicebanks: $child_voicebanks, artist_grouping: $artist_grouping, rating: $rating, song_list_id: $song_list_id, group_by_rating: $group_by_rating, pv_services: $pv_services, advanced_filters: $advanced_filters, start: $start, max_results: $max_results, get_total_count: $get_total_count, sort: $sort, name_match_mode: $name_match_mode, fields: $fields, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/users/{id}/ratedSongs/{songId}
#
# Returns: string
export def "get-api-users-id-rated-songs-song-id" [
  id: int
  song_id: int
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
    path: "/api/users/{id}/ratedSongs/{songId}"
    path_params: [{name: id, var: id}, {name: songId, var: song_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, song_id: $song_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/users/{id}/reports
#
# Returns: bool
export def "post-api-users-id-reports" [
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
  --accept: string@accept-completer # Response content type
  --reason: string # nullable
  --report-type: string@report-type-completer-1
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/users/{id}/reports"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: reason, var: reason}, {name: reportType, var: report_type}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, reason: $reason, report_type: $report_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/users/{id}/settings/{settingName}
export def "post-api-users-id-settings-setting-name" [
  id: int
  setting_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/users/{id}/settings/{settingName}"
    path_params: [{name: id, var: id}, {name: settingName, var: setting_name}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, setting_name: $setting_name, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/users/{id}/songLists
#
# Returns: record<items: table<author: record, deleted: bool, description: string, eventDate: string, events: list, featuredCategory: string, id: int, latestComments: list, mainPicture: record, name: string, status: string, tags: list>, term: string, totalCount: int>
export def "get-api-users-id-song-lists" [
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
  --accept: string@accept-completer # Response content type
  --query: string # default: ""
  --tag-id: list<int>
  --child-tags: oneof<nothing, bool> # default: false
  --name-match-mode: string@name-match-mode-completer
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --sort: string@sort-completer-5
  --fields: string@fields-completer-11
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/users/{id}/songLists"
    path_params: [{name: id, var: id}]
    query: [{name: query, var: query}, {name: "tagId[]", var: tag_id, style: multi}, {name: childTags, var: child_tags}, {name: nameMatchMode, var: name_match_mode}, {name: start, var: start}, {name: maxResults, var: max_results}, {name: getTotalCount, var: get_total_count}, {name: sort, var: sort}, {name: fields, var: fields}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, query: $query, tag_id: $tag_id, child_tags: $child_tags, name_match_mode: $name_match_mode, start: $start, max_results: $max_results, get_total_count: $get_total_count, sort: $sort, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/venues
#
# Returns: record<items: table<additionalNames: string, address: string, addressCountryCode: string, coordinates: record, deleted: bool, description: string, events: list, id: int, name: string, names: list, status: string, version: int, webLinks: list>, term: string, totalCount: int>
export def "get-api-venues" [
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
  --query: string # default: ""
  --fields: string@fields-completer-13
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --name-match-mode: string@name-match-mode-completer
  --lang: string@lang-completer
  --sort-rule: string@sort-rule-completer-1
  --latitude: float # format: double
  --longitude: float # format: double
  --radius: float # format: double
  --distance-unit: string@distance-unit-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/venues"
    query: [{name: query, var: query}, {name: fields, var: fields}, {name: start, var: start}, {name: maxResults, var: max_results}, {name: getTotalCount, var: get_total_count}, {name: nameMatchMode, var: name_match_mode}, {name: lang, var: lang}, {name: sortRule, var: sort_rule}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: radius, var: radius}, {name: distanceUnit, var: distance_unit}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    query: $query, fields: $fields, start: $start, max_results: $max_results, get_total_count: $get_total_count, name_match_mode: $name_match_mode, lang: $lang, sort_rule: $sort_rule, latitude: $latitude, longitude: $longitude, radius: $radius, distance_unit: $distance_unit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DELETE /api/venues/{id}
export def "delete-api-venues-id" [
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
  --notes: string # default: ""
  --hard-delete: oneof<nothing, bool> # default: false
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/venues/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: notes, var: notes}, {name: hardDelete, var: hard_delete}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, notes: $notes, hard_delete: $hard_delete
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/venues/{id}/reports
export def "post-api-venues-id-reports" [
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
  --report-type: string@report-type-completer
  --notes: string
  --version-number: int # format: int32
]: nothing -> any {
  http-request {
    method: post
    path: "/api/venues/{id}/reports"
    path_params: [{name: id, var: id}]
    query: [{name: reportType, var: report_type}, {name: notes, var: notes}, {name: versionNumber, var: version_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, report_type: $report_type, notes: $notes, version_number: $version_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
