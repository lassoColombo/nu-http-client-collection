# Auto-generated client for Nookipedia v1.5.0
# Source: https://api.apis.guru/v2/specs/dodo.ac/1.5.0/openapi.json
# Auth: --token flag or $env.NOOKIPEDIA_TOKEN

const CLIENT = {
  base_url: "https://api.nookipedia.com"
  token_env_var: "NOOKIPEDIA_TOKEN"
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

def base-url-completer [] { ["https://api.nookipedia.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def category-completer [] { ["Accessories" "Bags" "Bottoms" "Dress-up" "Headwear" "Shoes" "Socks" "Tops" "Umbrellas"] }
def labeltheme-completer [] { ["Comfy" "Everyday" "Fairy tale" "Formal" "Goth" "Outdoorsy" "Party" "Sporty" "Theatrical" "Vacation" "Work"] }
def category-completer-1 [] { ["Housewares" "Miscellaneous" "Wall-mounted"] }
def species-completer [] { ["alligator" "anteater" "bear" "bird" "bull" "cat" "chicken" "cow" "cub" "deer" "dog" "duck" "eagle" "elephant" "frog" "goat" "gorilla" "hamster" "hippo" "horse" "kangaroo" "koala" "lion" "monkey" "mouse" "octopus" "ostrich" "penguin" "pig" "rabbit" "rhino" "sheep" "squirrel" "tiger" "wolf"] }
def personality-completer [] { ["cranky" "jock" "lazy" "normal" "peppy" "sisterly" "smug" "snooty"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-nh-art: "table<art_name: string, art_style: string, authenticity: string, author: string, availability: string, buy: int, description: string, fake_image_url: string, has_fake: bool, image_url: string, length: float, name: string, sell: int, url: string, width: float, year: string>"
    get-nh-art-artwork: "record<art_name: string, art_style: string, authenticity: string, author: string, availability: string, buy: int, description: string, fake_image_url: string, has_fake: bool, image_url: string, length: float, name: string, sell: int, url: string, width: float, year: string>"
    get-nh-bugs: "table<catchphrases: list<string>, image_url: string, location: string, name: string, north: record<availability_array: list, months: string, months_array: list, times_by_month: record>, number: int, rarity: string, render_url: string, sell_flick: int, sell_nook: int, south: record<availability_array: list, months: string, months_array: list, times_by_month: record>, tank_length: float, tank_width: float, total_catch: int, url: string>"
    get-nh-bugs-bug: "record<catchphrases: list<string>, image_url: string, location: string, name: string, north: record<availability_array: list<record>, months: string, months_array: list<int>, times_by_month: record<\"1\": string, \"2\": string, \"3\": string, \"4\": string, \"5\": string, \"6\": string, \"7\": string, \"8\": string, \"9\": string, \"10\": string, \"11\": string, \"12\": string>>, number: int, rarity: string, render_url: string, sell_flick: int, sell_nook: int, south: record<availability_array: list<record>, months: string, months_array: list<int>, times_by_month: record<\"1\": string, \"2\": string, \"3\": string, \"4\": string, \"5\": string, \"6\": string, \"7\": string, \"8\": string, \"9\": string, \"10\": string, \"11\": string, \"12\": string>>, tank_length: float, tank_width: float, total_catch: int, url: string>"
    get-nh-clothing: "table<availability: list<record>, buy: list<record>, category: string, label_themes: list<string>, name: string, notes: string, seasonality: string, sell: int, styles: list<string>, unlocked: bool, url: string, variation_total: int, variations: list<record>, version_added: string, vill_equip: bool>"
    get-nh-clothing-clothing: "record<availability: table<from: string, note: string>, buy: table<currency: string, price: int>, category: string, label_themes: list<string>, name: string, notes: string, seasonality: string, sell: int, styles: list<string>, unlocked: bool, url: string, variation_total: int, variations: table<colors: list, image_url: string, variation: string>, version_added: string, vill_equip: bool>"
    get-nh-events: "table<date: string, event: string, type: string, url: string>"
    get-nh-fish: "table<catchphrases: list<string>, image_url: string, location: string, name: string, north: record<availability_array: list, months: string, months_array: list, times_by_month: record>, number: int, rarity: string, render_url: string, sell_cj: int, sell_nook: int, shadow_size: string, south: record<availability_array: list, months: string, months_array: list, times_by_month: record>, tank_length: float, tank_width: float, total_catch: int, url: string>"
    get-nh-fish-fish: "record<catchphrases: list<string>, image_url: string, location: string, name: string, north: record<availability_array: list<record>, months: string, months_array: list<int>, times_by_month: record<\"1\": string, \"2\": string, \"3\": string, \"4\": string, \"5\": string, \"6\": string, \"7\": string, \"8\": string, \"9\": string, \"10\": string, \"11\": string, \"12\": string>>, number: int, rarity: string, render_url: string, sell_cj: int, sell_nook: int, shadow_size: string, south: record<availability_array: list<record>, months: string, months_array: list<int>, times_by_month: record<\"1\": string, \"4\": string, \"5\": string, \"6\": string, \"7\": string, \"8\": string, \"9\": string, \"10\": string, \"11\": string, \"12\": string, \"2'\": string, \"3'\": string>>, tank_length: float, tank_width: float, total_catch: int, url: string>"
    get-nh-fossils-all: "table<description: string, fossils: list<record>, name: string, room: int, url: string>"
    get-nh-fossils-all-fossil: "record<description: string, fossils: table<colors: list, fossil_group: string, hha_base: int, image_url: string, interactable: bool, length: int, name: string, sell: int, url: string, width: int>, matched: record<name: string, type: string>, name: string, room: int, url: string>"
    get-nh-fossils-groups: "table<description: string, name: string, room: int, url: string>"
    get-nh-fossils-groups-fossil-group: "record<description: string, name: string, room: int, url: string>"
    get-nh-fossils-individuals: "table<colors: list<string>, fossil_group: string, hha_base: int, image_url: string, interactable: bool, length: int, name: string, sell: int, url: string, width: int>"
    get-nh-fossils-individuals-fossil: "record<colors: list<string>, fossil_group: string, hha_base: int, image_url: string, interactable: bool, length: int, name: string, sell: int, url: string, width: int>"
    get-nh-furniture: "table<availability: list<record>, buy: list<record>, category: string, custom_body_part: string, custom_kit_type: string, custom_kits: int, custom_pattern_part: string, customizable: bool, door_decor: bool, functions: list<string>, grid_length: float, grid_width: float, height: float, hha_base: int, hha_category: string, item_series: string, item_set: string, lucky: bool, lucky_season: string, name: string, notes: string, pattern_total: int, sell: int, tag: string, themes: list<string>, unlocked: bool, url: string, variation_total: int, variations: list<record>, version_added: string>"
    get-nh-furniture-furniture: "record<availability: table<from: string, note: string>, buy: table<currency: string, price: int>, category: string, custom_body_part: string, custom_kit_type: string, custom_kits: int, custom_pattern_part: string, customizable: bool, door_decor: bool, functions: list<string>, grid_length: float, grid_width: float, height: float, hha_base: int, hha_category: string, item_series: string, item_set: string, lucky: bool, lucky_season: string, name: string, notes: string, pattern_total: int, sell: int, tag: string, themes: list<string>, unlocked: bool, url: string, variation_total: int, variations: table<colors: list, image_url: string, pattern: string, variation: string>, version_added: string>"
    get-nh-interior: "table<availability: list<record>, buy: list<record>, category: string, colors: string, grid_length: float, grid_width: float, hha_base: int, hha_category: string, image_url: string, item_series: string, item_set: string, name: string, notes: string, sell: int, tag: string, themes: list<string>, unlocked: bool, url: string, version_added: string>"
    get-nh-interior-item: "record<availability: table<from: string, note: string>, buy: table<currency: string, price: int>, category: string, colors: string, grid_length: float, grid_width: float, hha_base: int, hha_category: string, image_url: string, item_series: string, item_set: string, name: string, notes: string, sell: int, tag: string, themes: list<string>, unlocked: bool, url: string, version_added: string>"
    get-nh-items: "table<availability: list<record>, buy: list<record>, edible: bool, hha_base: int, image_url: string, is_fence: bool, material_name_sort: int, material_seasonality: string, material_seasonality_sort: int, material_sort: int, material_type: string, name: string, notes: string, plant_type: string, sell: int, stack: int, unlocked: bool, url: string, version_added: string>"
    get-nh-items-item: "record<availability: table<from: string, note: string>, buy: table<currency: string, price: int>, edible: bool, hha_base: int, image_url: string, is_fence: bool, material_name_sort: int, material_seasonality: string, material_seasonality_sort: int, material_sort: int, material_type: string, name: string, notes: string, plant_type: string, sell: int, stack: int, unlocked: bool, url: string, version_added: string>"
    get-nh-photos: "table<availability: list<record>, buy: list<record>, category: string, custom_body_part: string, custom_kits: int, customizable: bool, grid_length: float, grid_width: float, interactable: bool, name: string, sell: int, unlocked: bool, url: string, variations: list<record>, version_added: string>"
    get-nh-photos-item: "record<availability: table<from: string, note: string>, buy: table<currency: string, price: int>, category: string, custom_body_part: string, custom_kits: int, customizable: bool, grid_length: float, grid_width: float, interactable: bool, name: string, sell: int, unlocked: bool, url: string, variations: table<colors: list, image_url: string, variation: string>, version_added: string>"
    get-nh-recipes: "table<availability: list<record>, buy: list<record>, image_url: string, materials: list<record>, name: string, recipes_to_unlock: int, sell: int, serial_id: int, url: string>"
    get-nh-recipes-item: "record<availability: table<from: string, note: string>, buy: table<currency: string, price: int>, image_url: string, materials: table<count: int, name: string>, name: string, recipes_to_unlock: int, sell: int, serial_id: int, url: string>"
    get-nh-sea: "table<catchphrases: list<string>, image_url: string, name: string, north: record<availability_array: list, months: string, months_array: list, times_by_month: record>, number: int, rarity: string, render_url: string, sell_nook: int, shadow_movement: string, shadow_size: string, south: record<availability_array: list, months: string, months_array: list, times_by_month: record>, tank_length: float, tank_width: float, total_catch: int, url: string>"
    get-nh-sea-sea-creature: "record<catchphrases: list<string>, image_url: string, name: string, north: record<availability_array: list<record>, months: string, months_array: list<int>, times_by_month: record<\"1\": string, \"2\": string, \"3\": string, \"4\": string, \"5\": string, \"6\": string, \"7\": string, \"8\": string, \"9\": string, \"10\": string, \"11\": string, \"12\": string>>, number: int, rarity: string, render_url: string, sell_nook: int, shadow_movement: string, shadow_size: string, south: record<availability_array: list<record>, months: string, months_array: list<int>, times_by_month: record<\"1\": string, \"2\": string, \"3\": string, \"4\": string, \"5\": string, \"6\": string, \"7\": string, \"8\": string, \"9\": string, \"10\": string, \"11\": string, \"12\": string>>, tank_length: float, tank_width: float, total_catch: int, url: string>"
    get-nh-tools: "table<availability: list<record>, buy: list<record>, custom_body_part: string, custom_kits: int, customizable: bool, hha_base: int, name: string, notes: string, sell: int, unlocked: bool, url: string, uses: int, variations: list<record>, version_added: string>"
    get-nh-tools-tool: "record<availability: table<from: string, note: string>, buy: table<currency: string, price: int>, custom_body_part: string, custom_kits: int, customizable: bool, hha_base: int, name: string, notes: string, sell: int, unlocked: bool, url: string, uses: int, variations: table<image_url: string, variation: string>, version_added: string>"
    get-villagers: "table<alt_name: string, appearances: list<string>, birthday_day: string, birthday_month: string, clothing: string, debut: string, gender: string, id: string, image_url: string, islander: bool, name: string, nh_details: record<catchphrase: string, clothing: string, clothing_variation: string, fav_colors: list, fav_styles: list, hobby: string, house_exterior_url: string, house_flooring: string, house_interior_url: string, house_music: string, house_music_note: string, house_wallpaper: string, icon_url: string, image_url: string, photo_url: string, quote: string, sub-personality: string>, personality: string, phrase: string, prev_phrases: list<string>, quote: string, sign: string, species: string, text_color: string, title_color: string, url: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-nh-art" "get-nh-art-artwork" "get-nh-bugs" "get-nh-bugs-bug" "get-nh-clothing" "get-nh-clothing-clothing" "get-nh-events" "get-nh-fish" "get-nh-fish-fish" "get-nh-fossils-all" "get-nh-fossils-all-fossil" "get-nh-fossils-groups" "get-nh-fossils-groups-fossil-group" "get-nh-fossils-individuals" "get-nh-fossils-individuals-fossil" "get-nh-furniture" "get-nh-furniture-furniture" "get-nh-interior" "get-nh-interior-item" "get-nh-items" "get-nh-items-item" "get-nh-photos" "get-nh-photos-item" "get-nh-recipes" "get-nh-recipes-item" "get-nh-sea" "get-nh-sea-sea-creature" "get-nh-tools" "get-nh-tools-tool" "get-villagers" "commands"] | sort) } | get name | first)
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

# All New Horizons artwork
#
# GET /nh/art
# Returns: table<art_name: string, art_style: string, authenticity: string, author: string, availability: string, buy: int, description: string, fake_image_url: string, has_fake: bool, image_url: string, length: float, name: string, sell: int, url: string, width: float, year: string>
export def "get-nh-art" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hasfake: string # When set to `true`, only artwork that has a fake will be returned. When set to `false`, only artwork without fakes will be returned.
  --excludedetails: string # When set to `true`, only artwork names are returned. Instead of an array of objects with all details, the return will be an array of strings.
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL. Note that requesting specific image sizes for long lists may result in a very long response time.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API. (required, format: uuid)
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/nh/art"
    query: [{name: hasfake, var: hasfake}, {name: excludedetails, var: excludedetails}, {name: thumbsize, var: thumbsize}]
    header: [{name: X-API-KEY, var: x_api_key, required: true}, {name: Accept-Version, var: accept_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hasfake: $hasfake, excludedetails: $excludedetails, thumbsize: $thumbsize, x_api_key: $x_api_key, accept_version: $accept_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Single New Horizons artwork
#
# GET /nh/art/{artwork}
# Returns: record<art_name: string, art_style: string, authenticity: string, author: string, availability: string, buy: int, description: string, fake_image_url: string, has_fake: bool, image_url: string, length: float, name: string, sell: int, url: string, width: float, year: string>
export def "get-nh-art-artwork" [
  artwork: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API. (required, format: uuid)
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/nh/art/{artwork}"
    path_params: [{name: artwork, var: artwork}]
    query: [{name: thumbsize, var: thumbsize}]
    header: [{name: X-API-KEY, var: x_api_key, required: true}, {name: Accept-Version, var: accept_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    artwork: $artwork, thumbsize: $thumbsize, x_api_key: $x_api_key, accept_version: $accept_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# All New Horizons bugs
#
# GET /nh/bugs
# Returns: table<catchphrases: list<string>, image_url: string, location: string, name: string, north: record<availability_array: list, months: string, months_array: list, times_by_month: record>, number: int, rarity: string, render_url: string, sell_flick: int, sell_nook: int, south: record<availability_array: list, months: string, months_array: list, times_by_month: record>, tank_length: float, tank_width: float, total_catch: int, url: string>
export def "get-nh-bugs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --month: string # Retrive only the bug that are available in a specific month. Value may be the month's name (`jan`, `january`), the integer representing the month (`01`, `1`), or `current` for the current month. When `current` is specified, the return body will be an object with two arrays inside, one called `north` and the other `south` containing the bug available in each respective hemisphere. Note that the current month is calculated based off the API server's time, so it may be slightly off for you at the beginning or end of the month.
  --excludedetails: string # When set to `true`, only bug names are returned. Instead of an array of objects with all details, the return will be an array of strings. This is particularly useful when used with the `month` filter, for users who want just a list of bugs in a given month but not all their respective details.
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL. Note that requesting specific image sizes for long lists may result in a very long response time.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API. (required, format: uuid)
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/nh/bugs"
    query: [{name: month, var: month}, {name: excludedetails, var: excludedetails}, {name: thumbsize, var: thumbsize}]
    header: [{name: X-API-KEY, var: x_api_key, required: true}, {name: Accept-Version, var: accept_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    month: $month, excludedetails: $excludedetails, thumbsize: $thumbsize, x_api_key: $x_api_key, accept_version: $accept_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Single New Horizons bug
#
# GET /nh/bugs/{bug}
# Returns: record<catchphrases: list<string>, image_url: string, location: string, name: string, north: record<availability_array: list<record>, months: string, months_array: list<int>, times_by_month: record<"1": string, "2": string, "3": string, "4": string, "5": string, "6": string, "7": string, "8": string, "9": string, "10": string, "11": string, "12": string>>, number: int, rarity: string, render_url: string, sell_flick: int, sell_nook: int, south: record<availability_array: list<record>, months: string, months_array: list<int>, times_by_month: record<"1": string, "2": string, "3": string, "4": string, "5": string, "6": string, "7": string, "8": string, "9": string, "10": string, "11": string, "12": string>>, tank_length: float, tank_width: float, total_catch: int, url: string>
export def "get-nh-bugs-bug" [
  bug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API. (required, format: uuid)
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/nh/bugs/{bug}"
    path_params: [{name: bug, var: bug}]
    query: [{name: thumbsize, var: thumbsize}]
    header: [{name: X-API-KEY, var: x_api_key, required: true}, {name: Accept-Version, var: accept_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bug: $bug, thumbsize: $thumbsize, x_api_key: $x_api_key, accept_version: $accept_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# All New Horizons clothing
#
# GET /nh/clothing
# Returns: table<availability: list<record>, buy: list<record>, category: string, label_themes: list<string>, name: string, notes: string, seasonality: string, sell: int, styles: list<string>, unlocked: bool, url: string, variation_total: int, variations: list<record>, version_added: string, vill_equip: bool>
export def "get-nh-clothing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string@category-completer # Specify the category of clothing to return.
  --color: list<string> # Return clothing that matches the provided colors (may specify one or two colors). Colors are used for gifting villagers.
  --style: list<string> # Return clothing that matches the provided styles (may specify one or two styles). Styles are used for gifting villagers.
  --labeltheme: string@labeltheme-completer # Return clothing that have the specified Label theme. This is used for completing the requested outfit theme for [Label](https://nookipedia.com/wiki/Label) when she visits the player's island.
  --excludedetails: string # When set to `true`, only clothing names are returned. Instead of an array of objects with all details, the return will be an array of strings.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API. (required, format: uuid)
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/nh/clothing"
    query: [{name: category, var: category}, {name: color, var: color, style: multi}, {name: style, var: style, style: multi}, {name: labeltheme, var: labeltheme}, {name: excludedetails, var: excludedetails}]
    header: [{name: X-API-KEY, var: x_api_key, required: true}, {name: Accept-Version, var: accept_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    category: $category, color: $color, style: $style, labeltheme: $labeltheme, excludedetails: $excludedetails, x_api_key: $x_api_key, accept_version: $accept_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Single New Horizons clothing
#
# GET /nh/clothing/{clothing}
# Returns: record<availability: table<from: string, note: string>, buy: table<currency: string, price: int>, category: string, label_themes: list<string>, name: string, notes: string, seasonality: string, sell: int, styles: list<string>, unlocked: bool, url: string, variation_total: int, variations: table<colors: list, image_url: string, variation: string>, version_added: string, vill_equip: bool>
export def "get-nh-clothing-clothing" [
  clothing: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API. (required, format: uuid)
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/nh/clothing/{clothing}"
    path_params: [{name: clothing, var: clothing}]
    query: [{name: thumbsize, var: thumbsize}]
    header: [{name: X-API-KEY, var: x_api_key, required: true}, {name: Accept-Version, var: accept_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clothing: $clothing, thumbsize: $thumbsize, x_api_key: $x_api_key, accept_version: $accept_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# All New Horizons events
#
# GET /nh/events
# Returns: table<date: string, event: string, type: string, url: string>
export def "get-nh-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # Specify a specific date (in the current or next year) to retrieve events for. Accepts many date formats, such as `YYYY-MM-DD` or `Month Day, Year`, as well as `today` to retrieve the current day's events (UTC time).
  --year: string # Specify the year to retrieve events for. Must be the current or next year.
  --month: string # Specify the month to retrieve events for (accepts multiple formats, such as `Oct`, `October`, or `10`). Most likely want to use alongside `year`, otherwise events in both the current and next year are returned.
  --day: int # Specify the day of the month to retrieve events for.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API. (required, format: uuid)
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/nh/events"
    query: [{name: date, var: date}, {name: year, var: year}, {name: month, var: month}, {name: day, var: day}]
    header: [{name: X-API-KEY, var: x_api_key, required: true}, {name: Accept-Version, var: accept_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    date: $date, year: $year, month: $month, day: $day, x_api_key: $x_api_key, accept_version: $accept_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# All New Horizons fish
#
# GET /nh/fish
# Returns: table<catchphrases: list<string>, image_url: string, location: string, name: string, north: record<availability_array: list, months: string, months_array: list, times_by_month: record>, number: int, rarity: string, render_url: string, sell_cj: int, sell_nook: int, shadow_size: string, south: record<availability_array: list, months: string, months_array: list, times_by_month: record>, tank_length: float, tank_width: float, total_catch: int, url: string>
export def "get-nh-fish" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --month: string # Retrive only the fish that are available in a specific month. Value may be the month's name (`jan`, `january`), the integer representing the month (`01`, `1`), or `current` for the current month. When `current` is specified, the return body will be an object with two arrays inside, one called `north` and the other `south` containing the fish available in each respective hemisphere. Note that the current month is calculated based off the API server's time, so it may be slightly off for you at the beginning or end of the month.
  --excludedetails: string # When set to `true`, only fish names are returned. Instead of an array of objects with all details, the return will be an array of strings. This is particularly useful when used with the `month` filter, for users who want just a list of fish in a given month but not all their respective details.
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL. Note that requesting specific image sizes for long lists may result in a very long response time.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API. (required, format: uuid)
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/nh/fish"
    query: [{name: month, var: month}, {name: excludedetails, var: excludedetails}, {name: thumbsize, var: thumbsize}]
    header: [{name: X-API-KEY, var: x_api_key, required: true}, {name: Accept-Version, var: accept_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    month: $month, excludedetails: $excludedetails, thumbsize: $thumbsize, x_api_key: $x_api_key, accept_version: $accept_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Single New Horizons fish
#
# GET /nh/fish/{fish}
# Returns: record<catchphrases: list<string>, image_url: string, location: string, name: string, north: record<availability_array: list<record>, months: string, months_array: list<int>, times_by_month: record<"1": string, "2": string, "3": string, "4": string, "5": string, "6": string, "7": string, "8": string, "9": string, "10": string, "11": string, "12": string>>, number: int, rarity: string, render_url: string, sell_cj: int, sell_nook: int, shadow_size: string, south: record<availability_array: list<record>, months: string, months_array: list<int>, times_by_month: record<"1": string, "4": string, "5": string, "6": string, "7": string, "8": string, "9": string, "10": string, "11": string, "12": string, "2'": string, "3'": string>>, tank_length: float, tank_width: float, total_catch: int, url: string>
export def "get-nh-fish-fish" [
  fish: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API. (required, format: uuid)
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/nh/fish/{fish}"
    path_params: [{name: fish, var: fish}]
    query: [{name: thumbsize, var: thumbsize}]
    header: [{name: X-API-KEY, var: x_api_key, required: true}, {name: Accept-Version, var: accept_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    fish: $fish, thumbsize: $thumbsize, x_api_key: $x_api_key, accept_version: $accept_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# All New Horizons fossil groups or individual fossil
#
# GET /nh/fossils/all
# Returns: table<description: string, fossils: list<record>, name: string, room: int, url: string>
export def "get-nh-fossils-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API. (required, format: uuid)
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/nh/fossils/all"
    query: [{name: thumbsize, var: thumbsize}]
    header: [{name: X-API-KEY, var: x_api_key, required: true}, {name: Accept-Version, var: accept_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thumbsize: $thumbsize, x_api_key: $x_api_key, accept_version: $accept_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Single New Horizons fossil group with individual fossils
#
# GET /nh/fossils/all/{fossil}
# Returns: record<description: string, fossils: table<colors: list, fossil_group: string, hha_base: int, image_url: string, interactable: bool, length: int, name: string, sell: int, url: string, width: int>, matched: record<name: string, type: string>, name: string, room: int, url: string>
export def "get-nh-fossils-all-fossil" [
  fossil: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API. (required, format: uuid)
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/nh/fossils/all/{fossil}"
    path_params: [{name: fossil, var: fossil}]
    query: [{name: thumbsize, var: thumbsize}]
    header: [{name: X-API-KEY, var: x_api_key, required: true}, {name: Accept-Version, var: accept_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    fossil: $fossil, thumbsize: $thumbsize, x_api_key: $x_api_key, accept_version: $accept_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# All New Horizons fossil groups
#
# GET /nh/fossils/groups
# Returns: table<description: string, name: string, room: int, url: string>
export def "get-nh-fossils-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API. (required, format: uuid)
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/nh/fossils/groups"
    query: [{name: thumbsize, var: thumbsize}]
    header: [{name: X-API-KEY, var: x_api_key, required: true}, {name: Accept-Version, var: accept_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thumbsize: $thumbsize, x_api_key: $x_api_key, accept_version: $accept_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Single New Horizons fossil group
#
# GET /nh/fossils/groups/{fossil_group}
# Returns: record<description: string, name: string, room: int, url: string>
export def "get-nh-fossils-groups-fossil-group" [
  fossil_group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API. (required, format: uuid)
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/nh/fossils/groups/{fossil_group}"
    path_params: [{name: fossil_group, var: fossil_group}]
    query: [{name: thumbsize, var: thumbsize}]
    header: [{name: X-API-KEY, var: x_api_key, required: true}, {name: Accept-Version, var: accept_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    fossil_group: $fossil_group, thumbsize: $thumbsize, x_api_key: $x_api_key, accept_version: $accept_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# All New Horizons fossils
#
# GET /nh/fossils/individuals
# Returns: table<colors: list<string>, fossil_group: string, hha_base: int, image_url: string, interactable: bool, length: int, name: string, sell: int, url: string, width: int>
export def "get-nh-fossils-individuals" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API. (required, format: uuid)
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/nh/fossils/individuals"
    query: [{name: thumbsize, var: thumbsize}]
    header: [{name: X-API-KEY, var: x_api_key, required: true}, {name: Accept-Version, var: accept_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thumbsize: $thumbsize, x_api_key: $x_api_key, accept_version: $accept_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Single New Horizons fossil
#
# GET /nh/fossils/individuals/{fossil}
# Returns: record<colors: list<string>, fossil_group: string, hha_base: int, image_url: string, interactable: bool, length: int, name: string, sell: int, url: string, width: int>
export def "get-nh-fossils-individuals-fossil" [
  fossil: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API. (required, format: uuid)
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/nh/fossils/individuals/{fossil}"
    path_params: [{name: fossil, var: fossil}]
    query: [{name: thumbsize, var: thumbsize}]
    header: [{name: X-API-KEY, var: x_api_key, required: true}, {name: Accept-Version, var: accept_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    fossil: $fossil, thumbsize: $thumbsize, x_api_key: $x_api_key, accept_version: $accept_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# All New Horizons furniture
#
# GET /nh/furniture
# Returns: table<availability: list<record>, buy: list<record>, category: string, custom_body_part: string, custom_kit_type: string, custom_kits: int, custom_pattern_part: string, customizable: bool, door_decor: bool, functions: list<string>, grid_length: float, grid_width: float, height: float, hha_base: int, hha_category: string, item_series: string, item_set: string, lucky: bool, lucky_season: string, name: string, notes: string, pattern_total: int, sell: int, tag: string, themes: list<string>, unlocked: bool, url: string, variation_total: int, variations: list<record>, version_added: string>
export def "get-nh-furniture" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string@category-completer-1 # Specify the category of furniture to return (houswares, miscellaneous, or wall-mounted).
  --color: list<string> # Return furniture that matches the provided colors (may specify one or two colors).
  --excludedetails: string # When set to `true`, only furniture names are returned. Instead of an array of objects with all details, the return will be an array of strings.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API. (required, format: uuid)
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/nh/furniture"
    query: [{name: category, var: category}, {name: color, var: color, style: multi}, {name: excludedetails, var: excludedetails}]
    header: [{name: X-API-KEY, var: x_api_key, required: true}, {name: Accept-Version, var: accept_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    category: $category, color: $color, excludedetails: $excludedetails, x_api_key: $x_api_key, accept_version: $accept_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Single New Horizons furniture
#
# GET /nh/furniture/{furniture}
# Returns: record<availability: table<from: string, note: string>, buy: table<currency: string, price: int>, category: string, custom_body_part: string, custom_kit_type: string, custom_kits: int, custom_pattern_part: string, customizable: bool, door_decor: bool, functions: list<string>, grid_length: float, grid_width: float, height: float, hha_base: int, hha_category: string, item_series: string, item_set: string, lucky: bool, lucky_season: string, name: string, notes: string, pattern_total: int, sell: int, tag: string, themes: list<string>, unlocked: bool, url: string, variation_total: int, variations: table<colors: list, image_url: string, pattern: string, variation: string>, version_added: string>
export def "get-nh-furniture-furniture" [
  furniture: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API. (required, format: uuid)
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/nh/furniture/{furniture}"
    path_params: [{name: furniture, var: furniture}]
    query: [{name: thumbsize, var: thumbsize}]
    header: [{name: X-API-KEY, var: x_api_key, required: true}, {name: Accept-Version, var: accept_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    furniture: $furniture, thumbsize: $thumbsize, x_api_key: $x_api_key, accept_version: $accept_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# All New Horizons interior items
#
# GET /nh/interior
# Returns: table<availability: list<record>, buy: list<record>, category: string, colors: string, grid_length: float, grid_width: float, hha_base: int, hha_category: string, image_url: string, item_series: string, item_set: string, name: string, notes: string, sell: int, tag: string, themes: list<string>, unlocked: bool, url: string, version_added: string>
export def "get-nh-interior" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --color: list<string> # Return furniture that matches the provided colors (may specify one or two colors).
  --excludedetails: string # When set to `true`, only interior item names are returned. Instead of an array of objects with all details, the return will be an array of strings.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API. (required, format: uuid)
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/nh/interior"
    query: [{name: color, var: color, style: multi}, {name: excludedetails, var: excludedetails}]
    header: [{name: X-API-KEY, var: x_api_key, required: true}, {name: Accept-Version, var: accept_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    color: $color, excludedetails: $excludedetails, x_api_key: $x_api_key, accept_version: $accept_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Single New Horizons interior item
#
# GET /nh/interior/{item}
# Returns: record<availability: table<from: string, note: string>, buy: table<currency: string, price: int>, category: string, colors: string, grid_length: float, grid_width: float, hha_base: int, hha_category: string, image_url: string, item_series: string, item_set: string, name: string, notes: string, sell: int, tag: string, themes: list<string>, unlocked: bool, url: string, version_added: string>
export def "get-nh-interior-item" [
  item: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --color: list<string> # Return furniture that matches the provided colors (may specify one or two colors).
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API. (required, format: uuid)
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/nh/interior/{item}"
    path_params: [{name: item, var: item}]
    query: [{name: color, var: color, style: multi}, {name: thumbsize, var: thumbsize}]
    header: [{name: X-API-KEY, var: x_api_key, required: true}, {name: Accept-Version, var: accept_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item: $item, color: $color, thumbsize: $thumbsize, x_api_key: $x_api_key, accept_version: $accept_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Miscellaneous New Horizons items
#
# GET /nh/items
# Returns: table<availability: list<record>, buy: list<record>, edible: bool, hha_base: int, image_url: string, is_fence: bool, material_name_sort: int, material_seasonality: string, material_seasonality_sort: int, material_sort: int, material_type: string, name: string, notes: string, plant_type: string, sell: int, stack: int, unlocked: bool, url: string, version_added: string>
export def "get-nh-items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --excludedetails: string # When set to `true`, only item names are returned. Instead of an array of objects with all details, the return will be an array of strings.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API. (required, format: uuid)
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/nh/items"
    query: [{name: excludedetails, var: excludedetails}]
    header: [{name: X-API-KEY, var: x_api_key, required: true}, {name: Accept-Version, var: accept_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    excludedetails: $excludedetails, x_api_key: $x_api_key, accept_version: $accept_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Single New Horizons miscellaneous item
#
# GET /nh/items/{item}
# Returns: record<availability: table<from: string, note: string>, buy: table<currency: string, price: int>, edible: bool, hha_base: int, image_url: string, is_fence: bool, material_name_sort: int, material_seasonality: string, material_seasonality_sort: int, material_sort: int, material_type: string, name: string, notes: string, plant_type: string, sell: int, stack: int, unlocked: bool, url: string, version_added: string>
export def "get-nh-items-item" [
  item: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API. (required, format: uuid)
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/nh/items/{item}"
    path_params: [{name: item, var: item}]
    query: [{name: thumbsize, var: thumbsize}]
    header: [{name: X-API-KEY, var: x_api_key, required: true}, {name: Accept-Version, var: accept_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item: $item, thumbsize: $thumbsize, x_api_key: $x_api_key, accept_version: $accept_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# All New Horizons photos and posters
#
# GET /nh/photos
# Returns: table<availability: list<record>, buy: list<record>, category: string, custom_body_part: string, custom_kits: int, customizable: bool, grid_length: float, grid_width: float, interactable: bool, name: string, sell: int, unlocked: bool, url: string, variations: list<record>, version_added: string>
export def "get-nh-photos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --excludedetails: string # When set to `true`, only item names are returned. Instead of an array of objects with all details, the return will be an array of strings.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API. (required, format: uuid)
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/nh/photos"
    query: [{name: excludedetails, var: excludedetails}]
    header: [{name: X-API-KEY, var: x_api_key, required: true}, {name: Accept-Version, var: accept_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    excludedetails: $excludedetails, x_api_key: $x_api_key, accept_version: $accept_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Single New Horizons photo or poster
#
# GET /nh/photos/{item}
# Returns: record<availability: table<from: string, note: string>, buy: table<currency: string, price: int>, category: string, custom_body_part: string, custom_kits: int, customizable: bool, grid_length: float, grid_width: float, interactable: bool, name: string, sell: int, unlocked: bool, url: string, variations: table<colors: list, image_url: string, variation: string>, version_added: string>
export def "get-nh-photos-item" [
  item: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API. (required, format: uuid)
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/nh/photos/{item}"
    path_params: [{name: item, var: item}]
    query: [{name: thumbsize, var: thumbsize}]
    header: [{name: X-API-KEY, var: x_api_key, required: true}, {name: Accept-Version, var: accept_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item: $item, thumbsize: $thumbsize, x_api_key: $x_api_key, accept_version: $accept_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# All New Horizons recipes
#
# GET /nh/recipes
# Returns: table<availability: list<record>, buy: list<record>, image_url: string, materials: list<record>, name: string, recipes_to_unlock: int, sell: int, serial_id: int, url: string>
export def "get-nh-recipes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --material: string # Specify a material to only get recipes that use that material. You can specify `material` up to six times (no recipe uses more than six materials).
  --excludedetails: string # When set to `true`, only recipe names are returned. Instead of an array of objects with all details, the return will be an array of strings.
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL. Note that requesting specific image sizes for long lists may result in a very long response time.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API. (required, format: uuid)
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/nh/recipes"
    query: [{name: material, var: material}, {name: excludedetails, var: excludedetails}, {name: thumbsize, var: thumbsize}]
    header: [{name: X-API-KEY, var: x_api_key, required: true}, {name: Accept-Version, var: accept_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    material: $material, excludedetails: $excludedetails, thumbsize: $thumbsize, x_api_key: $x_api_key, accept_version: $accept_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Single New Horizons recipe
#
# GET /nh/recipes/{item}
# Returns: record<availability: table<from: string, note: string>, buy: table<currency: string, price: int>, image_url: string, materials: table<count: int, name: string>, name: string, recipes_to_unlock: int, sell: int, serial_id: int, url: string>
export def "get-nh-recipes-item" [
  item: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API. (required, format: uuid)
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/nh/recipes/{item}"
    path_params: [{name: item, var: item}]
    query: [{name: thumbsize, var: thumbsize}]
    header: [{name: X-API-KEY, var: x_api_key, required: true}, {name: Accept-Version, var: accept_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item: $item, thumbsize: $thumbsize, x_api_key: $x_api_key, accept_version: $accept_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# All New Horizons sea creatures
#
# GET /nh/sea
# Returns: table<catchphrases: list<string>, image_url: string, name: string, north: record<availability_array: list, months: string, months_array: list, times_by_month: record>, number: int, rarity: string, render_url: string, sell_nook: int, shadow_movement: string, shadow_size: string, south: record<availability_array: list, months: string, months_array: list, times_by_month: record>, tank_length: float, tank_width: float, total_catch: int, url: string>
export def "get-nh-sea" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --month: string # Retrive only the sea creature that are available in a specific month. Value may be the month's name (`jan`, `january`), the integer representing the month (`01`, `1`), or `current` for the current month. When `current` is specified, the return body will be an object with two arrays inside, one called `north` and the other `south` containing the sea creature available in each respective hemisphere. Note that the current month is calculated based off the API server's time, so it may be slightly off for you at the beginning or end of the month.
  --excludedetails: string # When set to `true`, only sea creature names are returned. Instead of an array of objects with all details, the return will be an array of strings. This is particularly useful when used with the `month` filter, for users who want just a list of sea creatures in a given month but not all their respective details.
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL. Note that requesting specific image sizes for long lists may result in a very long response time.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API. (required, format: uuid)
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/nh/sea"
    query: [{name: month, var: month}, {name: excludedetails, var: excludedetails}, {name: thumbsize, var: thumbsize}]
    header: [{name: X-API-KEY, var: x_api_key, required: true}, {name: Accept-Version, var: accept_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    month: $month, excludedetails: $excludedetails, thumbsize: $thumbsize, x_api_key: $x_api_key, accept_version: $accept_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Single New Horizons sea creature
#
# GET /nh/sea/{sea_creature}
# Returns: record<catchphrases: list<string>, image_url: string, name: string, north: record<availability_array: list<record>, months: string, months_array: list<int>, times_by_month: record<"1": string, "2": string, "3": string, "4": string, "5": string, "6": string, "7": string, "8": string, "9": string, "10": string, "11": string, "12": string>>, number: int, rarity: string, render_url: string, sell_nook: int, shadow_movement: string, shadow_size: string, south: record<availability_array: list<record>, months: string, months_array: list<int>, times_by_month: record<"1": string, "2": string, "3": string, "4": string, "5": string, "6": string, "7": string, "8": string, "9": string, "10": string, "11": string, "12": string>>, tank_length: float, tank_width: float, total_catch: int, url: string>
export def "get-nh-sea-sea-creature" [
  sea_creature: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API. (required, format: uuid)
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/nh/sea/{sea_creature}"
    path_params: [{name: sea_creature, var: sea_creature}]
    query: [{name: thumbsize, var: thumbsize}]
    header: [{name: X-API-KEY, var: x_api_key, required: true}, {name: Accept-Version, var: accept_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sea_creature: $sea_creature, thumbsize: $thumbsize, x_api_key: $x_api_key, accept_version: $accept_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# All New Horizons tools
#
# GET /nh/tools
# Returns: table<availability: list<record>, buy: list<record>, custom_body_part: string, custom_kits: int, customizable: bool, hha_base: int, name: string, notes: string, sell: int, unlocked: bool, url: string, uses: int, variations: list<record>, version_added: string>
export def "get-nh-tools" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --excludedetails: string # When set to `true`, only tool names are returned. Instead of an array of objects with all details, the return will be an array of strings.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API. (required, format: uuid)
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/nh/tools"
    query: [{name: excludedetails, var: excludedetails}]
    header: [{name: X-API-KEY, var: x_api_key, required: true}, {name: Accept-Version, var: accept_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    excludedetails: $excludedetails, x_api_key: $x_api_key, accept_version: $accept_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Single New Horizons tool
#
# GET /nh/tools/{tool}
# Returns: record<availability: table<from: string, note: string>, buy: table<currency: string, price: int>, custom_body_part: string, custom_kits: int, customizable: bool, hha_base: int, name: string, notes: string, sell: int, unlocked: bool, url: string, uses: int, variations: table<image_url: string, variation: string>, version_added: string>
export def "get-nh-tools-tool" [
  tool: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API. (required, format: uuid)
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/nh/tools/{tool}"
    path_params: [{name: tool, var: tool}]
    query: [{name: thumbsize, var: thumbsize}]
    header: [{name: X-API-KEY, var: x_api_key, required: true}, {name: Accept-Version, var: accept_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tool: $tool, thumbsize: $thumbsize, x_api_key: $x_api_key, accept_version: $accept_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Villagers
#
# GET /villagers
# Returns: table<alt_name: string, appearances: list<string>, birthday_day: string, birthday_month: string, clothing: string, debut: string, gender: string, id: string, image_url: string, islander: bool, name: string, nh_details: record<catchphrase: string, clothing: string, clothing_variation: string, fav_colors: list, fav_styles: list, hobby: string, house_exterior_url: string, house_flooring: string, house_interior_url: string, house_music: string, house_music_note: string, house_wallpaper: string, icon_url: string, image_url: string, photo_url: string, quote: string, sub-personality: string>, personality: string, phrase: string, prev_phrases: list<string>, quote: string, sign: string, species: string, text_color: string, title_color: string, url: string>
export def "get-villagers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Villager name. For most names you will get back an array with one object, but note that names are not a unique identifier across the series, as there are 3 names that are shared by multiple villagers (Lulu, Petunia, Carmen). For those 3 names you will get back an array with 2 objects. How you disambiguate between these villagers is up to you.
  --species: string@species-completer # Retrieve villagers of a certain species.
  --personality: string@personality-completer # Retrieve villagers with a certain personality. For 'sisterly', note that the community often also calls it 'uchi' or 'big sister'.
  --game: list<string> # Retrieve villagers that appear in all listed games. For example, if you want only villagers that appear in both *New Horizons* and *Pocket Camp*, you would send in `?game=nh&game=pc`.
  --birthmonth: string # Retrieve villagers born in a specific month. Value may be the month's name (`jan`, `january`) or the integer representing the month (`01`, `1`).
  --birthday: string # Use with `birthmonth` to get villager(s) born on a specific day. Value should be an int, 1 through 31.
  --nhdetails: string # When set to `true`, an `nh_details` object will be included that contains *New Horizons* details about the villager. If the villager does not appear in *New Horizons*, the returned `nh_details` field will be set to null.
  --excludedetails: string # When set to `true`, only villager names are returned. Instead of an array of objects with all details, the return will be an array of strings.
  --thumbsize: int # Specify the desired width of returned image URLs. When unspecified, the linked image(s) returned by the API will be full-resolution. Note that images can only be reduced in size; specifying a width greater than than the maximum size will return the default full-size image URL. Note that requesting specific image sizes for long lists may result in a very long response time.
  --x-api-key: string # Your UUID secret key, granted to you by the Nookipedia team. Required for accessing the API. (required, format: uuid)
  --accept-version: string # The version of the API you are calling, written as `1.0.0`. This is specified as required as good practice, but it is not actually enforced by the API. If you do not specify a version, you will be served the latest version, which may eventually result in breaking changes. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/villagers"
    query: [{name: name, var: name}, {name: species, var: species}, {name: personality, var: personality}, {name: game, var: game, style: multi}, {name: birthmonth, var: birthmonth}, {name: birthday, var: birthday}, {name: nhdetails, var: nhdetails}, {name: excludedetails, var: excludedetails}, {name: thumbsize, var: thumbsize}]
    header: [{name: X-API-KEY, var: x_api_key, required: true}, {name: Accept-Version, var: accept_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, species: $species, personality: $personality, game: $game, birthmonth: $birthmonth, birthday: $birthday, nhdetails: $nhdetails, excludedetails: $excludedetails, thumbsize: $thumbsize, x_api_key: $x_api_key, accept_version: $accept_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
