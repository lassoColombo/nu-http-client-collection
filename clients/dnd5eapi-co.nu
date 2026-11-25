# Auto-generated client for D&D 5e API v0.1
# Source: https://api.apis.guru/v2/specs/dnd5eapi.co/0.1/openapi.json
# Auth: --token flag or $env.D_D_5E_API_TOKEN

const CLIENT = {
  base_url: "https://www.dnd5eapi.co"
  token_env_var: "D_D_5E_API_TOKEN"
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

def base-url-completer [] { ["https://www.dnd5eapi.co" "http://localhost:3000"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def index-completer [] { ["cha" "con" "dex" "int" "str" "wis"] }
def index-completer-1 [] { ["chaotic-evil" "chaotic-good" "chaotic-neutral" "lawful-evil" "lawful-good" "lawful-neutral" "neutral" "neutral-evil" "neutral-good"] }
def index-completer-2 [] { ["acolyte"] }
def index-completer-3 [] { ["barbarian" "bard" "cleric" "druid" "fighter" "monk" "paladin" "ranger" "rogue" "sorcerer" "warlock" "wizard"] }
def index-completer-4 [] { ["blinded" "charmed" "deafened" "exhaustion" "frightened" "grappled" "incapacitated" "invisible" "paralyzed" "petrified" "poisoned" "prone" "restrained" "stunned" "unconscious"] }
def index-completer-5 [] { ["acid" "bludgeoning" "cold" "fire" "force" "lightning" "necrotic" "piercing" "poison" "psychic" "radiant" "slashing" "thunder"] }
def index-completer-6 [] { ["grappler"] }
def index-completer-7 [] { ["abyssal" "celestial" "common" "deep-speech" "draconic" "dwarvish" "elvish" "giant" "gnomish" "goblin" "halfling" "infernal" "orc" "primordial" "sylvan" "undercommon"] }
def index-completer-8 [] { ["abjuration" "conjuration" "divination" "enchantment" "evocation" "illusion" "necromancy" "transmutation"] }
def index-completer-9 [] { ["dragonborn" "dwarf" "elf" "gnome" "half-elf" "half-orc" "halfling" "human" "tiefling"] }
def index-completer-10 [] { ["ability-checks" "ability-scores-and-modifiers" "actions-in-combat" "advantage-and-disadvantage" "between-adventures" "casting-a-spell" "cover" "damage-and-healing" "diseases" "fantasy-historical-pantheons" "madness" "making-an-attack" "mounted-combat" "movement" "movement-and-position" "objects" "poisons" "proficiency-bonus" "resting" "saving-throws" "sentient-magic-items" "standard-exchange-rates" "the-environment" "the-order-of-combat" "the-planes-of-existence" "time" "traps" "underwater-combat" "using-each-ability" "what-is-a-spell"] }
def index-completer-11 [] { ["adventuring" "appendix" "combat" "equipment" "spellcasting" "using-ability-scores"] }
def index-completer-12 [] { ["acrobatics" "animal-handling" "arcana" "athletics" "deception" "history" "insight" "intimidation" "investigation" "medicine" "nature" "perception" "performance" "persuasion" "religion" "sleight-of-hand" "stealth" "survival"] }
def index-completer-13 [] { ["berserker" "champion" "devotion" "draconic" "evocation" "fiend" "hunter" "land" "life" "lore" "open-hand" "thief"] }
def index-completer-14 [] { ["high-elf" "hill-dwarf" "lightfoot-halfling" "rock-gnome"] }
def index-completer-15 [] { ["artificers-lore" "brave" "breath-weapon" "damage-resistance" "darkvision" "draconic-ancestry" "draconic-ancestry-black" "draconic-ancestry-blue" "draconic-ancestry-brass" "draconic-ancestry-bronze" "draconic-ancestry-copper" "draconic-ancestry-gold" "draconic-ancestry-green" "draconic-ancestry-red" "draconic-ancestry-silver" "draconic-ancestry-white" "dwarven-combat-training" "dwarven-resilience" "dwarven-toughness" "elf-weapon-training" "extra-language" "fey-ancestry" "gnome-cunning" "halfling-nimbleness" "hellish-resistance" "high-elf-cantrip" "infernal-legacy" "keen-senses" "lucky" "menacing" "naturally-stealthy" "relentless-endurance" "savage-attacks" "skill-versatility" "stonecunning" "tinker" "tool-proficiency" "trance"] }
def index-completer-16 [] { ["ammunition" "finesse" "heavy" "light" "loading" "monk" "reach" "special" "thrown" "two-handed" "versatile"] }
def endpoint-completer [] { ["ability-scores" "alignments" "backgrounds" "classes" "conditions" "damage-types" "equipment" "equipment-categories" "feats" "features" "languages" "magic-items" "magic-schools" "monsters" "proficiencies" "races" "rule-sections" "rules" "skills" "spells" "subclasses" "subraces" "traits" "weapon-properties"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-api: "record"
    get-api-ability-scores-index: "record<index: string, name: string, url: string, desc: list<string>, full_name: string, skills: table<index: string, name: string, url: string>>"
    get-api-alignments-index: "record<index: string, name: string, url: string, abbreviation: string, desc: string>"
    get-api-backgrounds-index: "record<index: string, name: string, url: string, bonds: record<choose: float, desc: string, from: any, type: string>, feature: record<desc: list<string>, name: string>, flaws: record<choose: float, desc: string, from: any, type: string>, ideals: record<choose: float, desc: string, from: any, type: string>, language_options: record<choose: float, desc: string, from: any, type: string>, personality_traits: record, starting_equipment: table<index: string, name: string, url: string>, starting_equipment_options: record<choose: float, desc: string, from: any, type: string>, starting_proficiencies: table<index: string, name: string, url: string>>"
    get-api-classes-index: "record<index: string, name: string, url: string, class_levels: string, hit_die: float, multi_classing: record<prerequisite_options: list<record>, prerequisites: list<record>, proficiencies: list<record>, proficiency_choices: list<record>>, proficiencies: table<index: string, name: string, url: string>, proficiency_choices: table<choose: float, desc: string, from: any, type: string>, saving_throws: table<index: string, name: string, url: string>, spellcasting: record<info: list<record>, level: float, spellcasting_ability: record<index: string, name: string, url: string>>, spells: string, starting_equipment: table<equipment: record, quantity: float>, starting_equipment_options: table<choose: float, desc: string, from: any, type: string>, subclasses: table<index: string, name: string, url: string>>"
    get-api-classes-index-features: "record<count: float, results: table<index: string, name: string, url: string>>"
    get-api-classes-index-levels: "table<ability_score_bonuses: float, class_specific: any, features: list<record>, index: string, level: float, prof_bonus: float, spellcasting: record<cantrips_known: float, spell_slots_level_1: float, spell_slots_level_2: float, spell_slots_level_3: float, spell_slots_level_4: float, spell_slots_level_5: float, spell_slots_level_6: float, spell_slots_level_7: float, spell_slots_level_8: float, spell_slots_level_9: float, spells_known: float>, url: string>"
    get-api-classes-index-levels-class-level: "record<ability_score_bonuses: float, class_specific: any, features: table<index: string, name: string, url: string>, index: string, level: float, prof_bonus: float, spellcasting: record<cantrips_known: float, spell_slots_level_1: float, spell_slots_level_2: float, spell_slots_level_3: float, spell_slots_level_4: float, spell_slots_level_5: float, spell_slots_level_6: float, spell_slots_level_7: float, spell_slots_level_8: float, spell_slots_level_9: float, spells_known: float>, url: string>"
    get-api-classes-index-levels-class-level-features: "record<count: float, results: table<index: string, name: string, url: string>>"
    get-api-classes-index-levels-spell-level-spells: "record<count: float, results: table<index: string, name: string, url: string>>"
    get-api-classes-index-multi-classing: "record<prerequisite_options: table<choose: float, desc: string, from: any, type: string>, prerequisites: table<ability_score: record, minimum_score: float>, proficiencies: table<index: string, name: string, url: string>, proficiency_choices: table<choose: float, desc: string, from: any, type: string>>"
    get-api-classes-index-proficiencies: "record<count: float, results: table<index: string, name: string, url: string>>"
    get-api-classes-index-spellcasting: "record<info: table<desc: list, name: string>, level: float, spellcasting_ability: record<index: string, name: string, url: string>>"
    get-api-classes-index-spells: "record<count: float, results: table<index: string, name: string, url: string>>"
    get-api-classes-index-subclasses: "record<count: float, results: table<index: string, name: string, url: string>>"
    get-api-conditions-index: "record<index: string, name: string, url: string, desc: list<string>>"
    get-api-damage-types-index: "record<index: string, name: string, url: string, desc: list<string>>"
    get-api-equipment-categories-index: "record<index: string, name: string, url: string, equipment: table<index: string, name: string, url: string>>"
    get-api-feats-index: "record<index: string, name: string, url: string, desc: list<string>, prerequisites: table<ability_score: record, minimum_score: float>>"
    get-api-features-index: "record<index: string, name: string, url: string, desc: list<string>, class: record<index: string, name: string, url: string>, feature_specific: any, level: float, parent: record<index: string, name: string, url: string>, prerequisites: list<any>, subclass: record<index: string, name: string, url: string>>"
    get-api-languages-index: "record<index: string, name: string, url: string, desc: string, script: string, type: string, typical_speakers: list<string>>"
    get-api-magic-items-index: "record<index: string, name: string, url: string, desc: list<string>, equipment_category: record<index: string, name: string, url: string>, rarity: record<name: string>, variant: bool, variants: table<index: string, name: string, url: string>>"
    get-api-magic-schools-index: "record<index: string, name: string, url: string, desc: string>"
    get-api-monsters: "record<count: float, results: table<index: string, name: string, url: string>>"
    get-api-monsters-index: "record<index: string, name: string, url: string, desc: list<string>, charisma: float, constitution: float, dexterity: float, intelligence: float, strength: float, wisdom: float, actions: table<action_options: record, actions: list, attack_bonus: float, attacks: list, damage: list, dc: record, desc: string, multiattack_type: string, name: string, options: record>, alignments: string, armor_class: list<record>, challenge_rating: float, condition_immunities: table<index: string, name: string, url: string>, damage_immunities: list<string>, damage_resistances: list<string>, damage_vulnerabilities: list<string>, forms: table<index: string, name: string, url: string>, hit_dice: string, hit_points: float, hit_points_roll: string, image: string, languages: string, legendary_actions: table<action_options: record, actions: list, attack_bonus: float, attacks: list, damage: list, dc: record, desc: string, multiattack_type: string, name: string, options: record>, proficiencies: table<proficiency: record, value: float>, reactions: table<action_options: record, actions: list, attack_bonus: float, attacks: list, damage: list, dc: record, desc: string, multiattack_type: string, name: string, options: record>, senses: record<blindsight: string, darkvision: string, passive_perception: float, tremorsense: string, truesight: string>, size: string, special_abilities: table<attack_bonus: float, damage: list, dc: record, desc: string, name: string, spellcasting: record, usage: record>, speed: record<burrow: string, climb: string, fly: string, swim: string, walk: string>, subtype: string, type: string, xp: float>"
    get-api-proficiencies-index: "record<index: string, name: string, url: string, classes: table<index: string, name: string, url: string>, races: table<index: string, name: string, url: string>, reference: record<index: string, name: string, url: string>, type: string>"
    get-api-races-index: "record<index: string, name: string, url: string, ability_bonuses: table<ability_score: record, bonus: float>, age: string, alignment: string, language_desc: string, languages: table<index: string, name: string, url: string>, size: string, size_description: string, speed: float, starting_proficiencies: table<index: string, name: string, url: string>, starting_proficiency_options: record<choose: float, desc: string, from: any, type: string>, subraces: table<index: string, name: string, url: string>, traits: table<index: string, name: string, url: string>>"
    get-api-races-index-proficiencies: "record<count: float, results: table<index: string, name: string, url: string>>"
    get-api-races-index-subraces: "record<count: float, results: table<index: string, name: string, url: string>>"
    get-api-races-index-traits: "record<count: float, results: table<index: string, name: string, url: string>>"
    get-api-rule-sections-index: "record<index: string, name: string, url: string, desc: string>"
    get-api-rules-index: "record<index: string, name: string, url: string, desc: string, subsections: table<index: string, name: string, url: string>>"
    get-api-skills-index: "record<index: string, name: string, url: string, desc: list<string>, ability_score: record<index: string, name: string, url: string>>"
    get-api-spells: "record<count: float, results: table<index: string, name: string, url: string>>"
    get-api-spells-index: "record<index: string, name: string, url: string, desc: list<string>, area_of_effect: record<size: float, type: string>, attack_type: string, casting_time: string, classes: table<index: string, name: string, url: string>, components: list<string>, concentration: bool, damage: any, duration: string, higher_level: list<string>, level: float, material: string, range: string, ritual: bool, school: record<index: string, name: string, url: string>, subclasses: table<index: string, name: string, url: string>>"
    get-api-subclasses-index: "record<index: string, name: string, url: string, desc: list<string>, class: record<index: string, name: string, url: string>, spells: table<prerequisites: list, spell: record>, subclass_flavor: string, subclass_levels: string>"
    get-api-subclasses-index-features: "record<count: float, results: table<index: string, name: string, url: string>>"
    get-api-subclasses-index-levels: "table<class: record<index: string, name: string, url: string>, features: list<record>, index: string, level: float, subclass: record<index: string, name: string, url: string>, url: string>"
    get-api-subclasses-index-levels-subclass-level: "record<ability_score_bonuses: float, classspecific: any, features: table<index: string, name: string, url: string>, index: string, level: float, prof_bonus: float, spellcasting: record<cantrips_known: float, spell_slots_level_1: float, spell_slots_level_2: float, spell_slots_level_3: float, spell_slots_level_4: float, spell_slots_level_5: float, spell_slots_level_6: float, spell_slots_level_7: float, spell_slots_level_8: float, spell_slots_level_9: float, spells_known: float>, url: string>"
    get-api-subclasses-index-levels-subclass-level-features: "record<count: float, results: table<index: string, name: string, url: string>>"
    get-api-subraces-index: "record<index: string, name: string, url: string, ability_bonuses: table<ability_score: record, bonus: float>, desc: string, language_options: record<choose: float, desc: string, from: any, type: string>, languages: table<index: string, name: string, url: string>, race: record<index: string, name: string, url: string>, racial_traits: table<index: string, name: string, url: string>, starting_proficiencies: table<index: string, name: string, url: string>>"
    get-api-subraces-index-proficiencies: "record<count: float, results: table<index: string, name: string, url: string>>"
    get-api-subraces-index-traits: "record<count: float, results: table<index: string, name: string, url: string>>"
    get-api-traits-index: "record<index: string, name: string, url: string, desc: list<string>, language_options: record<choose: float, desc: string, from: any, type: string>, proficiencies: table<index: string, name: string, url: string>, proficiency_choices: record<choose: float, desc: string, from: any, type: string>, races: table<index: string, name: string, url: string>, subraces: table<index: string, name: string, url: string>, trait_specific: any>"
    get-api-weapon-properties-index: "record<index: string, name: string, url: string, desc: list<string>>"
    get-api-endpoint: "record<count: float, results: table<index: string, name: string, url: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-api" "get-api-ability-scores-index" "get-api-alignments-index" "get-api-backgrounds-index" "get-api-classes-index" "get-api-classes-index-features" "get-api-classes-index-levels" "get-api-classes-index-levels-class-level" "get-api-classes-index-levels-class-level-features" "get-api-classes-index-levels-spell-level-spells" "get-api-classes-index-multi-classing" "get-api-classes-index-proficiencies" "get-api-classes-index-spellcasting" "get-api-classes-index-spells" "get-api-classes-index-subclasses" "get-api-conditions-index" "get-api-damage-types-index" "get-api-equipment-categories-index" "get-api-equipment-index" "get-api-feats-index" "get-api-features-index" "get-api-languages-index" "get-api-magic-items-index" "get-api-magic-schools-index" "get-api-monsters" "get-api-monsters-index" "get-api-proficiencies-index" "get-api-races-index" "get-api-races-index-proficiencies" "get-api-races-index-subraces" "get-api-races-index-traits" "get-api-rule-sections-index" "get-api-rules-index" "get-api-skills-index" "get-api-spells" "get-api-spells-index" "get-api-subclasses-index" "get-api-subclasses-index-features" "get-api-subclasses-index-levels" "get-api-subclasses-index-levels-subclass-level" "get-api-subclasses-index-levels-subclass-level-features" "get-api-subraces-index" "get-api-subraces-index-proficiencies" "get-api-subraces-index-traits" "get-api-traits-index" "get-api-weapon-properties-index" "get-api-endpoint" "commands"] | sort) } | get name | first)
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

# Get all resource URLs.
#
# GET /api
# Returns: record
export def "get-api" [
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
    path: "/api"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an ability score by index.
#
# GET /api/ability-scores/{index}
# Returns: record<index: string, name: string, url: string, desc: list<string>, full_name: string, skills: table<index: string, name: string, url: string>>
export def "get-api-ability-scores-index" [
  index: string@index-completer
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
    path: "/api/ability-scores/{index}"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an alignment by index.
#
# GET /api/alignments/{index}
# Returns: record<index: string, name: string, url: string, abbreviation: string, desc: string>
export def "get-api-alignments-index" [
  index: string@index-completer-1
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
    path: "/api/alignments/{index}"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a background by index.
#
# GET /api/backgrounds/{index}
# Returns: record<index: string, name: string, url: string, bonds: record<choose: float, desc: string, from: any, type: string>, feature: record<desc: list<string>, name: string>, flaws: record<choose: float, desc: string, from: any, type: string>, ideals: record<choose: float, desc: string, from: any, type: string>, language_options: record<choose: float, desc: string, from: any, type: string>, personality_traits: record, starting_equipment: table<index: string, name: string, url: string>, starting_equipment_options: record<choose: float, desc: string, from: any, type: string>, starting_proficiencies: table<index: string, name: string, url: string>>
export def "get-api-backgrounds-index" [
  index: string@index-completer-2
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
    path: "/api/backgrounds/{index}"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a class by index.
#
# GET /api/classes/{index}
# Returns: record<index: string, name: string, url: string, class_levels: string, hit_die: float, multi_classing: record<prerequisite_options: list<record>, prerequisites: list<record>, proficiencies: list<record>, proficiency_choices: list<record>>, proficiencies: table<index: string, name: string, url: string>, proficiency_choices: table<choose: float, desc: string, from: any, type: string>, saving_throws: table<index: string, name: string, url: string>, spellcasting: record<info: list<record>, level: float, spellcasting_ability: record<index: string, name: string, url: string>>, spells: string, starting_equipment: table<equipment: record, quantity: float>, starting_equipment_options: table<choose: float, desc: string, from: any, type: string>, subclasses: table<index: string, name: string, url: string>>
export def "get-api-classes-index" [
  index: string@index-completer-3
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
    path: "/api/classes/{index}"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get features available for a class.
#
# GET /api/classes/{index}/features
# Returns: record<count: float, results: table<index: string, name: string, url: string>>
export def "get-api-classes-index-features" [
  index: string@index-completer-3
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
    path: "/api/classes/{index}/features"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all level resources for a class.
#
# GET /api/classes/{index}/levels
# Returns: table<ability_score_bonuses: float, class_specific: any, features: list<record>, index: string, level: float, prof_bonus: float, spellcasting: record<cantrips_known: float, spell_slots_level_1: float, spell_slots_level_2: float, spell_slots_level_3: float, spell_slots_level_4: float, spell_slots_level_5: float, spell_slots_level_6: float, spell_slots_level_7: float, spell_slots_level_8: float, spell_slots_level_9: float, spells_known: float>, url: string>
export def "get-api-classes-index-levels" [
  index: string@index-completer-3
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subclass: string # Adds subclasses for class to the response
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/classes/{index}/levels"
    path_params: [{name: index, var: index}]
    query: [{name: subclass, var: subclass}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index, subclass: $subclass
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get level resource for a class and level.
#
# GET /api/classes/{index}/levels/{class_level}
# Returns: record<ability_score_bonuses: float, class_specific: any, features: table<index: string, name: string, url: string>, index: string, level: float, prof_bonus: float, spellcasting: record<cantrips_known: float, spell_slots_level_1: float, spell_slots_level_2: float, spell_slots_level_3: float, spell_slots_level_4: float, spell_slots_level_5: float, spell_slots_level_6: float, spell_slots_level_7: float, spell_slots_level_8: float, spell_slots_level_9: float, spells_known: float>, url: string>
export def "get-api-classes-index-levels-class-level" [
  index: string@index-completer-3
  class_level: float
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
    path: "/api/classes/{index}/levels/{class_level}"
    path_params: [{name: index, var: index}, {name: class_level, var: class_level}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index, class_level: $class_level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get features available to a class at the requested level.
#
# GET /api/classes/{index}/levels/{class_level}/features
# Returns: record<count: float, results: table<index: string, name: string, url: string>>
export def "get-api-classes-index-levels-class-level-features" [
  index: string@index-completer-3
  class_level: float
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
    path: "/api/classes/{index}/levels/{class_level}/features"
    path_params: [{name: index, var: index}, {name: class_level, var: class_level}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index, class_level: $class_level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get spells of the requested level available to the class.
#
# GET /api/classes/{index}/levels/{spell_level}/spells
# Returns: record<count: float, results: table<index: string, name: string, url: string>>
export def "get-api-classes-index-levels-spell-level-spells" [
  index: string@index-completer-3
  spell_level: float
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
    path: "/api/classes/{index}/levels/{spell_level}/spells"
    path_params: [{name: index, var: index}, {name: spell_level, var: spell_level}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index, spell_level: $spell_level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get multiclassing resource for a class.
#
# GET /api/classes/{index}/multi-classing
# Returns: record<prerequisite_options: table<choose: float, desc: string, from: any, type: string>, prerequisites: table<ability_score: record, minimum_score: float>, proficiencies: table<index: string, name: string, url: string>, proficiency_choices: table<choose: float, desc: string, from: any, type: string>>
export def "get-api-classes-index-multi-classing" [
  index: string@index-completer-3
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
    path: "/api/classes/{index}/multi-classing"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get proficiencies available for a class.
#
# GET /api/classes/{index}/proficiencies
# Returns: record<count: float, results: table<index: string, name: string, url: string>>
export def "get-api-classes-index-proficiencies" [
  index: string@index-completer-3
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
    path: "/api/classes/{index}/proficiencies"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get spellcasting info for a class.
#
# GET /api/classes/{index}/spellcasting
# Returns: record<info: table<desc: list, name: string>, level: float, spellcasting_ability: record<index: string, name: string, url: string>>
export def "get-api-classes-index-spellcasting" [
  index: string@index-completer-3
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
    path: "/api/classes/{index}/spellcasting"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get spells available for a class.
#
# GET /api/classes/{index}/spells
# Returns: record<count: float, results: table<index: string, name: string, url: string>>
export def "get-api-classes-index-spells" [
  index: string@index-completer-3
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
    path: "/api/classes/{index}/spells"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get subclasses available for a class.
#
# GET /api/classes/{index}/subclasses
# Returns: record<count: float, results: table<index: string, name: string, url: string>>
export def "get-api-classes-index-subclasses" [
  index: string@index-completer-3
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
    path: "/api/classes/{index}/subclasses"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a condition by index.
#
# GET /api/conditions/{index}
# Returns: record<index: string, name: string, url: string, desc: list<string>>
export def "get-api-conditions-index" [
  index: string@index-completer-4
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
    path: "/api/conditions/{index}"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a damage type by index.
#
# GET /api/damage-types/{index}
# Returns: record<index: string, name: string, url: string, desc: list<string>>
export def "get-api-damage-types-index" [
  index: string@index-completer-5
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
    path: "/api/damage-types/{index}"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an equipment category by index.
#
# GET /api/equipment-categories/{index}
# Returns: record<index: string, name: string, url: string, equipment: table<index: string, name: string, url: string>>
export def "get-api-equipment-categories-index" [
  index: string
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
    path: "/api/equipment-categories/{index}"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an equipment item by index.
#
# GET /api/equipment/{index}
export def "get-api-equipment-index" [
  index: string
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
    path: "/api/equipment/{index}"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a feat by index.
#
# GET /api/feats/{index}
# Returns: record<index: string, name: string, url: string, desc: list<string>, prerequisites: table<ability_score: record, minimum_score: float>>
export def "get-api-feats-index" [
  index: string@index-completer-6
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
    path: "/api/feats/{index}"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a feature by index.
#
# GET /api/features/{index}
# Returns: record<index: string, name: string, url: string, desc: list<string>, class: record<index: string, name: string, url: string>, feature_specific: any, level: float, parent: record<index: string, name: string, url: string>, prerequisites: list<any>, subclass: record<index: string, name: string, url: string>>
export def "get-api-features-index" [
  index: string
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
    path: "/api/features/{index}"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a language by index.
#
# GET /api/languages/{index}
# Returns: record<index: string, name: string, url: string, desc: string, script: string, type: string, typical_speakers: list<string>>
export def "get-api-languages-index" [
  index: string@index-completer-7
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
    path: "/api/languages/{index}"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a magic item by index.
#
# GET /api/magic-items/{index}
# Returns: record<index: string, name: string, url: string, desc: list<string>, equipment_category: record<index: string, name: string, url: string>, rarity: record<name: string>, variant: bool, variants: table<index: string, name: string, url: string>>
export def "get-api-magic-items-index" [
  index: string
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
    path: "/api/magic-items/{index}"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a magic school by index.
#
# GET /api/magic-schools/{index}
# Returns: record<index: string, name: string, url: string, desc: string>
export def "get-api-magic-schools-index" [
  index: string@index-completer-8
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
    path: "/api/magic-schools/{index}"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of monsters with optional filtering
#
# GET /api/monsters
# Returns: record<count: float, results: table<index: string, name: string, url: string>>
export def "get-api-monsters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --challenge-rating: list<float> # The challenge rating or ratings to filter on.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/monsters"
    query: [{name: challenge_rating, var: challenge_rating, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    challenge_rating: $challenge_rating
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get monster by index.
#
# GET /api/monsters/{index}
# Returns: record<index: string, name: string, url: string, desc: list<string>, charisma: float, constitution: float, dexterity: float, intelligence: float, strength: float, wisdom: float, actions: table<action_options: record, actions: list, attack_bonus: float, attacks: list, damage: list, dc: record, desc: string, multiattack_type: string, name: string, options: record>, alignments: string, armor_class: list<record>, challenge_rating: float, condition_immunities: table<index: string, name: string, url: string>, damage_immunities: list<string>, damage_resistances: list<string>, damage_vulnerabilities: list<string>, forms: table<index: string, name: string, url: string>, hit_dice: string, hit_points: float, hit_points_roll: string, image: string, languages: string, legendary_actions: table<action_options: record, actions: list, attack_bonus: float, attacks: list, damage: list, dc: record, desc: string, multiattack_type: string, name: string, options: record>, proficiencies: table<proficiency: record, value: float>, reactions: table<action_options: record, actions: list, attack_bonus: float, attacks: list, damage: list, dc: record, desc: string, multiattack_type: string, name: string, options: record>, senses: record<blindsight: string, darkvision: string, passive_perception: float, tremorsense: string, truesight: string>, size: string, special_abilities: table<attack_bonus: float, damage: list, dc: record, desc: string, name: string, spellcasting: record, usage: record>, speed: record<burrow: string, climb: string, fly: string, swim: string, walk: string>, subtype: string, type: string, xp: float>
export def "get-api-monsters-index" [
  index: string
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
    path: "/api/monsters/{index}"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a proficiency by index.
#
# GET /api/proficiencies/{index}
# Returns: record<index: string, name: string, url: string, classes: table<index: string, name: string, url: string>, races: table<index: string, name: string, url: string>, reference: record<index: string, name: string, url: string>, type: string>
export def "get-api-proficiencies-index" [
  index: string
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
    path: "/api/proficiencies/{index}"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a race by index.
#
# GET /api/races/{index}
# Returns: record<index: string, name: string, url: string, ability_bonuses: table<ability_score: record, bonus: float>, age: string, alignment: string, language_desc: string, languages: table<index: string, name: string, url: string>, size: string, size_description: string, speed: float, starting_proficiencies: table<index: string, name: string, url: string>, starting_proficiency_options: record<choose: float, desc: string, from: any, type: string>, subraces: table<index: string, name: string, url: string>, traits: table<index: string, name: string, url: string>>
export def "get-api-races-index" [
  index: string@index-completer-9
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
    path: "/api/races/{index}"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get proficiencies available for a race.
#
# GET /api/races/{index}/proficiencies
# Returns: record<count: float, results: table<index: string, name: string, url: string>>
export def "get-api-races-index-proficiencies" [
  index: string@index-completer-9
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
    path: "/api/races/{index}/proficiencies"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get subraces available for a race.
#
# GET /api/races/{index}/subraces
# Returns: record<count: float, results: table<index: string, name: string, url: string>>
export def "get-api-races-index-subraces" [
  index: string@index-completer-9
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
    path: "/api/races/{index}/subraces"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get traits available for a race.
#
# GET /api/races/{index}/traits
# Returns: record<count: float, results: table<index: string, name: string, url: string>>
export def "get-api-races-index-traits" [
  index: string@index-completer-9
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
    path: "/api/races/{index}/traits"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a rule section by index.
#
# GET /api/rule-sections/{index}
# Returns: record<index: string, name: string, url: string, desc: string>
export def "get-api-rule-sections-index" [
  index: string@index-completer-10
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
    path: "/api/rule-sections/{index}"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a rule by index.
#
# GET /api/rules/{index}
# Returns: record<index: string, name: string, url: string, desc: string, subsections: table<index: string, name: string, url: string>>
export def "get-api-rules-index" [
  index: string@index-completer-11
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
    path: "/api/rules/{index}"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a skill by index.
#
# GET /api/skills/{index}
# Returns: record<index: string, name: string, url: string, desc: list<string>, ability_score: record<index: string, name: string, url: string>>
export def "get-api-skills-index" [
  index: string@index-completer-12
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
    path: "/api/skills/{index}"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of spells with optional filtering.
#
# GET /api/spells
# Returns: record<count: float, results: table<index: string, name: string, url: string>>
export def "get-api-spells" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --level: list<int> # The level or levels to filter on.
  --school: list<string> # The magic school or schools to filter on.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/spells"
    query: [{name: level, var: level, style: multi}, {name: school, var: school, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    level: $level, school: $school
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a spell by index.
#
# GET /api/spells/{index}
# Returns: record<index: string, name: string, url: string, desc: list<string>, area_of_effect: record<size: float, type: string>, attack_type: string, casting_time: string, classes: table<index: string, name: string, url: string>, components: list<string>, concentration: bool, damage: any, duration: string, higher_level: list<string>, level: float, material: string, range: string, ritual: bool, school: record<index: string, name: string, url: string>, subclasses: table<index: string, name: string, url: string>>
export def "get-api-spells-index" [
  index: string
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
    path: "/api/spells/{index}"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a subclass by index.
#
# GET /api/subclasses/{index}
# Returns: record<index: string, name: string, url: string, desc: list<string>, class: record<index: string, name: string, url: string>, spells: table<prerequisites: list, spell: record>, subclass_flavor: string, subclass_levels: string>
export def "get-api-subclasses-index" [
  index: string@index-completer-13
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
    path: "/api/subclasses/{index}"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get features available for a subclass.
#
# GET /api/subclasses/{index}/features
# Returns: record<count: float, results: table<index: string, name: string, url: string>>
export def "get-api-subclasses-index-features" [
  index: string@index-completer-13
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
    path: "/api/subclasses/{index}/features"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all level resources for a subclass.
#
# GET /api/subclasses/{index}/levels
# Returns: table<class: record<index: string, name: string, url: string>, features: list<record>, index: string, level: float, subclass: record<index: string, name: string, url: string>, url: string>
export def "get-api-subclasses-index-levels" [
  index: string@index-completer-13
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
    path: "/api/subclasses/{index}/levels"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get level resources for a subclass and level.
#
# GET /api/subclasses/{index}/levels/{subclass_level}
# Returns: record<ability_score_bonuses: float, classspecific: any, features: table<index: string, name: string, url: string>, index: string, level: float, prof_bonus: float, spellcasting: record<cantrips_known: float, spell_slots_level_1: float, spell_slots_level_2: float, spell_slots_level_3: float, spell_slots_level_4: float, spell_slots_level_5: float, spell_slots_level_6: float, spell_slots_level_7: float, spell_slots_level_8: float, spell_slots_level_9: float, spells_known: float>, url: string>
export def "get-api-subclasses-index-levels-subclass-level" [
  index: string@index-completer-13
  subclass_level: int
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
    path: "/api/subclasses/{index}/levels/{subclass_level}"
    path_params: [{name: index, var: index}, {name: subclass_level, var: subclass_level}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index, subclass_level: $subclass_level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get features of the requested spell level available to the class.
#
# GET /api/subclasses/{index}/levels/{subclass_level}/features
# Returns: record<count: float, results: table<index: string, name: string, url: string>>
export def "get-api-subclasses-index-levels-subclass-level-features" [
  index: string@index-completer-13
  subclass_level: int
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
    path: "/api/subclasses/{index}/levels/{subclass_level}/features"
    path_params: [{name: index, var: index}, {name: subclass_level, var: subclass_level}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index, subclass_level: $subclass_level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a subrace by index.
#
# GET /api/subraces/{index}
# Returns: record<index: string, name: string, url: string, ability_bonuses: table<ability_score: record, bonus: float>, desc: string, language_options: record<choose: float, desc: string, from: any, type: string>, languages: table<index: string, name: string, url: string>, race: record<index: string, name: string, url: string>, racial_traits: table<index: string, name: string, url: string>, starting_proficiencies: table<index: string, name: string, url: string>>
export def "get-api-subraces-index" [
  index: string@index-completer-14
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
    path: "/api/subraces/{index}"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get proficiences available for a subrace.
#
# GET /api/subraces/{index}/proficiencies
# Returns: record<count: float, results: table<index: string, name: string, url: string>>
export def "get-api-subraces-index-proficiencies" [
  index: string@index-completer-14
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
    path: "/api/subraces/{index}/proficiencies"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get traits available for a subrace.
#
# GET /api/subraces/{index}/traits
# Returns: record<count: float, results: table<index: string, name: string, url: string>>
export def "get-api-subraces-index-traits" [
  index: string@index-completer-14
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
    path: "/api/subraces/{index}/traits"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a trait by index.
#
# GET /api/traits/{index}
# Returns: record<index: string, name: string, url: string, desc: list<string>, language_options: record<choose: float, desc: string, from: any, type: string>, proficiencies: table<index: string, name: string, url: string>, proficiency_choices: record<choose: float, desc: string, from: any, type: string>, races: table<index: string, name: string, url: string>, subraces: table<index: string, name: string, url: string>, trait_specific: any>
export def "get-api-traits-index" [
  index: string@index-completer-15
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
    path: "/api/traits/{index}"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a weapon property by index.
#
# GET /api/weapon-properties/{index}
# Returns: record<index: string, name: string, url: string, desc: list<string>>
export def "get-api-weapon-properties-index" [
  index: string@index-completer-16
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
    path: "/api/weapon-properties/{index}"
    path_params: [{name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of all available resources for an endpoint.
#
# GET /api/{endpoint}
# Returns: record<count: float, results: table<index: string, name: string, url: string>>
export def "get-api-endpoint" [
  endpoint: string@endpoint-completer
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
    path: "/api/{endpoint}"
    path_params: [{name: endpoint, var: endpoint}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    endpoint: $endpoint
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
