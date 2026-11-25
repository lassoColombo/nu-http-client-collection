# Auto-generated client for Semantria v4.0
# Source: https://api.apis.guru/v2/specs/semantria.com/4.0/swagger.json
# Auth: --token flag or $env.SEMANTRIA_TOKEN

const CLIENT = {
  base_url: "https://api.semantria.com"
  token_env_var: "SEMANTRIA_TOKEN"
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

def base-url-completer [] { ["https://api.semantria.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-blacklist: "table<id: string, modified: string, name: string>"
    add-blacklist: "table<id: string, modified: string, name: string>"
    update-blacklist: "table<id: string, modified: string, name: string>"
    get-categories: "table<id: string, modified: string, name: string, samples: list<string>, weight: float>"
    add-categories: "table<id: string, modified: string, name: string, samples: list<string>, weight: float>"
    update-categories: "table<id: string, modified: string, name: string, samples: list<string>, weight: float>"
    queue-collection: "record<documents: list<string>, id: string, job_id: string, tag: string>"
    retrieve-processed-collections: "record<config_id: string, entities: table<count: int, entity_type: string, label: string, mentions: list, negative_count: int, neutral_count: int, positive_count: int, title: string, type: string>, facets: table<attributes: list, count: int, label: string, mentions: list, negative_count: int, neutral_count: int, positive_count: int>, id: string, job_id: string, status: string, tag: string, taxonomy: table<hitcount: int, id: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>, themes: table<mentions: list, normalized: string, phrases_count: int, sentiment_polarity: string, sentiment_score: float, stemmed: string, themes_count: int, title: string>, topics: table<hitcount: int, id: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>>"
    receive-collection-analytic-data: "record<config_id: string, entities: table<count: int, entity_type: string, label: string, mentions: list, negative_count: int, neutral_count: int, positive_count: int, title: string, type: string>, facets: table<attributes: list, count: int, label: string, mentions: list, negative_count: int, neutral_count: int, positive_count: int>, id: string, job_id: string, status: string, tag: string, taxonomy: table<hitcount: int, id: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>, themes: table<mentions: list, normalized: string, phrases_count: int, sentiment_polarity: string, sentiment_score: float, stemmed: string, themes_count: int, title: string>, topics: table<hitcount: int, id: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>>"
    get-configurations: "table<auto_response: bool, callback: string, categories_threshold: float, chars_threshold: int, collection: record<attribute_mentions_limit: int, concept_topics_limit: int, facet_atts_limit: int, facet_mentions_limit: int, facets_limit: int, named_entities_limit: int, named_mentions_limit: int, query_topics_limit: int, theme_mentions_limit: int, themes_limit: int, user_entities_limit: int, user_mentions_limit: int>, config_id: string, document: record<auto_categories_limit: int, concept_topics_limit: int, detect_language: bool, entity_themes_limit: int, intentions: bool, model_sentiment: bool, named_entities_limit: int, named_mentions_limit: int, named_opinions_limit: int, named_relations_limit: int, phrases_limit: int, pos_types: string, possible_phrases_limit: int, query_topics_limit: int, summary_limit: int, theme_mentions_limit: int, themes_limit: int, user_entities_limit: int, user_mentions_limit: int, user_opinions_limit: int, user_relations_limit: int>, entities_threshold: int, from_template_config_id: string, is_primary: bool, language: string, modified: string, name: string, one_sentence: bool, process_html: bool, version: string>"
    add-configurations: "table<auto_response: bool, callback: string, categories_threshold: float, chars_threshold: int, collection: record<attribute_mentions_limit: int, concept_topics_limit: int, facet_atts_limit: int, facet_mentions_limit: int, facets_limit: int, named_entities_limit: int, named_mentions_limit: int, query_topics_limit: int, theme_mentions_limit: int, themes_limit: int, user_entities_limit: int, user_mentions_limit: int>, config_id: string, document: record<auto_categories_limit: int, concept_topics_limit: int, detect_language: bool, entity_themes_limit: int, intentions: bool, model_sentiment: bool, named_entities_limit: int, named_mentions_limit: int, named_opinions_limit: int, named_relations_limit: int, phrases_limit: int, pos_types: string, possible_phrases_limit: int, query_topics_limit: int, summary_limit: int, theme_mentions_limit: int, themes_limit: int, user_entities_limit: int, user_mentions_limit: int, user_opinions_limit: int, user_relations_limit: int>, entities_threshold: int, from_template_config_id: string, is_primary: bool, language: string, modified: string, name: string, one_sentence: bool, process_html: bool, version: string>"
    update-configurations: "table<auto_response: bool, callback: string, categories_threshold: float, chars_threshold: int, collection: record<attribute_mentions_limit: int, concept_topics_limit: int, facet_atts_limit: int, facet_mentions_limit: int, facets_limit: int, named_entities_limit: int, named_mentions_limit: int, query_topics_limit: int, theme_mentions_limit: int, themes_limit: int, user_entities_limit: int, user_mentions_limit: int>, config_id: string, document: record<auto_categories_limit: int, concept_topics_limit: int, detect_language: bool, entity_themes_limit: int, intentions: bool, model_sentiment: bool, named_entities_limit: int, named_mentions_limit: int, named_opinions_limit: int, named_relations_limit: int, phrases_limit: int, pos_types: string, possible_phrases_limit: int, query_topics_limit: int, summary_limit: int, theme_mentions_limit: int, themes_limit: int, user_entities_limit: int, user_mentions_limit: int, user_opinions_limit: int, user_relations_limit: int>, entities_threshold: int, from_template_config_id: string, is_primary: bool, language: string, modified: string, name: string, one_sentence: bool, process_html: bool, version: string>"
    queue-document: "record<id: string, job_id: string, tag: string, text: string>"
    queue-batch-of-documents: "record<id: string, job_id: string, tag: string, text: string>"
    retrieve-processed-documents: "record<auto_categories: table<categories: list, sentiment_polarity: string, sentiment_score: float, strength_score: float, title: string, type: string>, config_id: string, details: table<is_imperative: bool, is_polar: bool, words: list>, entities: table<count: int, entity_type: string, label: string, mentions: list, negative_count: int, neutral_count: int, positive_count: int, title: string, type: string>, id: string, intentions: table<evidence_phrase: string, type: string, what: string, who: string>, job_id: string, language: string, language_score: float, model_sentiment: record<mixed_score: float, model_name: string, negative_score: float, neutral_score: float, positive_score: float, sentiment_polarity: string>, opinions: table<quotation: string, sentiment_polarity: string, sentiment_score: float, speaker: float, topic: string, type: string>, phrases: table<intensifying_phrase: string, is_intensified: bool, is_negated: bool, negating_phrase: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>, relations: table<confidence_score: float, entities: list, extra: string, relation_type: string, type: string>, sentiment_polarity: string, sentiment_score: float, source_text: string, status: string, summary: string, taxonomy: table<hitcount: int, id: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>, themes: table<mentions: list, normalized: string, phrases_count: int, sentiment_polarity: string, sentiment_score: float, stemmed: string, themes_count: int, title: string>, topics: table<hitcount: int, id: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>>"
    receive-document-analytic-data: "record<auto_categories: table<categories: list, sentiment_polarity: string, sentiment_score: float, strength_score: float, title: string, type: string>, config_id: string, details: table<is_imperative: bool, is_polar: bool, words: list>, entities: table<count: int, entity_type: string, label: string, mentions: list, negative_count: int, neutral_count: int, positive_count: int, title: string, type: string>, id: string, intentions: table<evidence_phrase: string, type: string, what: string, who: string>, job_id: string, language: string, language_score: float, model_sentiment: record<mixed_score: float, model_name: string, negative_score: float, neutral_score: float, positive_score: float, sentiment_polarity: string>, opinions: table<quotation: string, sentiment_polarity: string, sentiment_score: float, speaker: float, topic: string, type: string>, phrases: table<intensifying_phrase: string, is_intensified: bool, is_negated: bool, negating_phrase: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>, relations: table<confidence_score: float, entities: list, extra: string, relation_type: string, type: string>, sentiment_polarity: string, sentiment_score: float, source_text: string, status: string, summary: string, taxonomy: table<hitcount: int, id: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>, themes: table<mentions: list, normalized: string, phrases_count: int, sentiment_polarity: string, sentiment_score: float, stemmed: string, themes_count: int, title: string>, topics: table<hitcount: int, id: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>>"
    get-entities: "table<id: string, label: string, modified: string, name: string, normalized: string, type: string>"
    add-entities: "table<id: string, label: string, modified: string, name: string, normalized: string, type: string>"
    update-entities: "table<id: string, label: string, modified: string, name: string, normalized: string, type: string>"
    get-features: "table<detailed_mode: record<auto_categories: bool, entity_mentions: bool, entity_opinions: bool, entity_relations: bool, entity_themes: bool, intentions: bool, language_detection: bool, model_sentiment: bool, named_entities: bool, pos_tagging: bool, queries: bool, sentiment: bool, sentiment_phrases: bool, summarization: bool, taxonomy: bool, theme_mentions: bool, themes: bool, user_categories: bool, user_entities: bool>, discovery_mode: record<entity_mentions: bool, facet_attributes: bool, facet_mentioins: bool, facets: bool, named_entities: bool, queries: bool, taxonomy: bool, theme_mentions: bool, themes: bool, user_categories: bool, user_entities: bool>, html_processing: bool, id: string, language: string, one_sentence_mode: bool, settings: record<blacklist: bool, queries: bool, sentiment_phrases: bool, taxonomy: bool, user_categories: bool, user_entities: bool>, templates: record<config_id: string, description: string, id: string, is_free: bool, language: string, name: string, type: string, version: string>>"
    get-phrases: "table<id: string, modified: string, name: string, weight: float>"
    add-phrases: "table<id: string, modified: string, name: string, weight: float>"
    update-phrases: "table<id: string, modified: string, name: string, weight: float>"
    get-queries: "table<id: string, modified: string, name: string, query: string>"
    add-queries: "table<id: string, modified: string, name: string, query: string>"
    update-queries: "table<id: string, modified: string, name: string, query: string>"
    get-statistic: "record<calls_data: int, calls_polling: int, calls_settings: int, colls_documents: int, colls_failed: int, colls_processed: int, colls_responded: int, configurations: table<calls_data: int, calls_polling: int, calls_settings: int, colls_failed: int, colls_processed: int, colls_responded: int, config_id: string, docs_failed: int, docs_processed: int, docs_responded: int, latest_used_app: string, name: string, overall_batches: int, overall_calls: int, overall_docs: int, overall_exceeded: int, overall_texts: int, overcall_colls: int, used_apps: string>, docs_failed: int, docs_processed: int, docs_responded: int, latest_used_app: string, name: string, overall_batches: int, overall_calls: int, overall_docs: int, overall_exceeded: int, overall_texts: int, overcall_colls: int, status: string, used_apps: string>"
    get-status: "record<api_version: string, service_status: string, service_version: string, supported_compression: string, supported_encoding: string, supported_languages: list<string>>"
    get-subscription: "record<basic_settings: record<auto_response_limit: int, batch_limit: int, blacklist_limit: int, callback_batch_limit: int, categories_limit: int, category_samples_limit: int, characters_limit: int, collection_limit: int, configurations_limit: int, entities_limit: int, output_data_limit: int, processed_batch_limit: int, queries_limit: int, return_source_text: bool, sentiment_limit: int>, billing_settings: record<app_seats_allocated: int, app_seats_permitted: int, data_calls_balance: int, data_calls_limit: int, data_calls_limit_interval: int, docs_balance: int, docs_limit: int, docs_limit_interval: int, docs_suggested: int, docs_suggested_interval: int, expiration_date: string, limit_type: string, polling_calls_balance: int, polling_calls_limit: int, polling_calls_limit_interval: int, priority: string, settings_calls_balance: int, settings_calls_limit: int, settings_calls_limit_interval: int>, feature_settings: record<collection: record<concept_topics: bool, facets: bool, mentions: bool, named_entities: bool, query_topics: bool, themes: bool, user_entities: bool>, document: record<auto_categories: bool, concept_topics: bool, entity_themes: bool, intentions: bool, language_detection: bool, mentions: bool, model_sentiment: bool, named_entities: bool, named_relations: bool, opinions: bool, phrases_detection: bool, pos_tagging: bool, query_topics: bool, sentiment_phrases: bool, summary: bool, themes: bool, user_entities: bool, user_relations: bool>, html_processing: bool, supported_languages: string, templates: record<config_id: string, description: string, id: string, is_free: bool, language: string, name: string, type: string, version: string>>, name: string, status: string>"
    get-taxonomy: "table<enforce_parent_matching: bool, id: string, modified: string, name: string, nodes: list<any>, topics: list<record>>"
    add-taxonomy: "table<enforce_parent_matching: bool, id: string, modified: string, name: string, nodes: list<any>, topics: list<record>>"
    update-taxonomy: "table<enforce_parent_matching: bool, id: string, modified: string, name: string, nodes: list<any>, topics: list<record>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["delete-blacklist-items" "get-blacklist" "add-blacklist" "update-blacklist" "delete-categories" "get-categories" "add-categories" "update-categories" "queue-collection" "retrieve-processed-collections" "cancel-collection" "receive-collection-analytic-data" "delete-configurations" "get-configurations" "add-configurations" "update-configurations" "queue-document" "queue-batch-of-documents" "retrieve-processed-documents" "cancel-document" "receive-document-analytic-data" "delete-entities" "get-entities" "add-entities" "update-entities" "get-features" "delete-phrases" "get-phrases" "add-phrases" "update-phrases" "delete-queries" "get-queries" "add-queries" "update-queries" "get-statistic" "get-status" "get-subscription" "delete-taxonomy" "get-taxonomy" "add-taxonomy" "update-taxonomy" "commands"] | sort) } | get name | first)
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

# Remove items from blacklist
#
# DELETE /blacklist.{content_type}
# operationId: deleteBlacklistItems
export def "delete-blacklist-items" [
  content_type: string
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
  --config-id: string # Identifier of configuration blacklist items linked to.
  --body: list
]: any -> any {
  $in | http-request {
    method: delete
    path: "/blacklist.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    content_type: $content_type, config_id: $config_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve blacklisted items
#
# GET /blacklist.{content_type}
# Returns: table<id: string, modified: string, name: string>
# operationId: getBlacklist
export def "get-blacklist" [
  content_type: string
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
  --config-id: string # Identifier of configuration blacklist linked to.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/blacklist.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    content_type: $content_type, config_id: $config_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add items to blacklist
#
# POST /blacklist.{content_type}
# Returns: table<id: string, modified: string, name: string>
# operationId: addBlacklist
export def "add-blacklist" [
  content_type: string
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
  --config-id: string # Identifier of configuration blacklist linked to.
  --body: record
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/blacklist.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    content_type: $content_type, config_id: $config_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update items in blacklist
#
# PUT /blacklist.{content_type}
# Returns: table<id: string, modified: string, name: string>
# operationId: updateBlacklist
export def "update-blacklist" [
  content_type: string
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
  --config-id: string # Identifier of configuration blacklist linked to.
  --body: record
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/blacklist.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    content_type: $content_type, config_id: $config_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove user categories
#
# DELETE /categories.{content_type}
# operationId: deleteCategories
export def "delete-categories" [
  content_type: string
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
  --config-id: string # Identifier of configuration user categories linked to.
  --body: list
]: any -> any {
  $in | http-request {
    method: delete
    path: "/categories.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    content_type: $content_type, config_id: $config_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve user categories
#
# GET /categories.{content_type}
# Returns: table<id: string, modified: string, name: string, samples: list<string>, weight: float>
# operationId: getCategories
export def "get-categories" [
  content_type: string
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
  --config-id: string # Identifier of configuration user categories linked to.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/categories.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    content_type: $content_type, config_id: $config_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add user categories
#
# POST /categories.{content_type}
# Returns: table<id: string, modified: string, name: string, samples: list<string>, weight: float>
# operationId: addCategories
export def "add-categories" [
  content_type: string
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
  --config-id: string # Identifier of configuration user categories linked to.
  --body: record
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/categories.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    content_type: $content_type, config_id: $config_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates user categories
#
# PUT /categories.{content_type}
# Returns: table<id: string, modified: string, name: string, samples: list<string>, weight: float>
# operationId: updateCategories
export def "update-categories" [
  content_type: string
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
  --config-id: string # Identifier of configuration user categories linked to.
  --body: record
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/categories.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    content_type: $content_type, config_id: $config_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Queue collection for analysis
#
# POST /collection.{content_type}
# Returns: record<documents: list<string>, id: string, job_id: string, tag: string>
# operationId: queueCollection
export def "queue-collection" [
  content_type: string
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
  --config-id: string # Identifier of configuration used for analysis.
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/collection.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    content_type: $content_type, config_id: $config_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve collections analysis
#
# GET /collection/processed.{content_type}
# Returns: record<config_id: string, entities: table<count: int, entity_type: string, label: string, mentions: list, negative_count: int, neutral_count: int, positive_count: int, title: string, type: string>, facets: table<attributes: list, count: int, label: string, mentions: list, negative_count: int, neutral_count: int, positive_count: int>, id: string, job_id: string, status: string, tag: string, taxonomy: table<hitcount: int, id: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>, themes: table<mentions: list, normalized: string, phrases_count: int, sentiment_polarity: string, sentiment_score: float, stemmed: string, themes_count: int, title: string>, topics: table<hitcount: int, id: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>>
# operationId: retrieveProcessedCollections
export def "retrieve-processed-collections" [
  content_type: string
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
  --config-id: string # Identifier of configuration used for analysis.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/collection/processed.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    content_type: $content_type, config_id: $config_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Cancel collection analysis
#
# DELETE /collection/{collection_id}.{content_type}
# operationId: cancelCollection
export def "cancel-collection" [
  collection_id: string
  content_type: string
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
  --config-id: string # Identifier of configuration used for analysis.
]: nothing -> any {
  http-request {
    method: delete
    path: "/collection/{collection_id}.{content_type}"
    path_params: [{name: collection_id, var: collection_id}, {name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id, content_type: $content_type, config_id: $config_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve collection analysis or its status in queue
#
# GET /collection/{collection_id}.{content_type}
# Returns: record<config_id: string, entities: table<count: int, entity_type: string, label: string, mentions: list, negative_count: int, neutral_count: int, positive_count: int, title: string, type: string>, facets: table<attributes: list, count: int, label: string, mentions: list, negative_count: int, neutral_count: int, positive_count: int>, id: string, job_id: string, status: string, tag: string, taxonomy: table<hitcount: int, id: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>, themes: table<mentions: list, normalized: string, phrases_count: int, sentiment_polarity: string, sentiment_score: float, stemmed: string, themes_count: int, title: string>, topics: table<hitcount: int, id: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>>
# operationId: receiveCollectionAnalyticData
export def "receive-collection-analytic-data" [
  collection_id: string
  content_type: string
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
  --config-id: string # Identifier of configuration used for analysis.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/collection/{collection_id}.{content_type}"
    path_params: [{name: collection_id, var: collection_id}, {name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id, content_type: $content_type, config_id: $config_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove user configurations
#
# DELETE /configurations.{content_type}
# operationId: deleteConfigurations
export def "delete-configurations" [
  content_type: string
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
  --body: list
]: any -> any {
  $in | http-request {
    method: delete
    path: "/configurations.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    content_type: $content_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve user configurations
#
# GET /configurations.{content_type}
# Returns: table<auto_response: bool, callback: string, categories_threshold: float, chars_threshold: int, collection: record<attribute_mentions_limit: int, concept_topics_limit: int, facet_atts_limit: int, facet_mentions_limit: int, facets_limit: int, named_entities_limit: int, named_mentions_limit: int, query_topics_limit: int, theme_mentions_limit: int, themes_limit: int, user_entities_limit: int, user_mentions_limit: int>, config_id: string, document: record<auto_categories_limit: int, concept_topics_limit: int, detect_language: bool, entity_themes_limit: int, intentions: bool, model_sentiment: bool, named_entities_limit: int, named_mentions_limit: int, named_opinions_limit: int, named_relations_limit: int, phrases_limit: int, pos_types: string, possible_phrases_limit: int, query_topics_limit: int, summary_limit: int, theme_mentions_limit: int, themes_limit: int, user_entities_limit: int, user_mentions_limit: int, user_opinions_limit: int, user_relations_limit: int>, entities_threshold: int, from_template_config_id: string, is_primary: bool, language: string, modified: string, name: string, one_sentence: bool, process_html: bool, version: string>
# operationId: getConfigurations
export def "get-configurations" [
  content_type: string
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
    path: "/configurations.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    content_type: $content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create user configurations
#
# POST /configurations.{content_type}
# Returns: table<auto_response: bool, callback: string, categories_threshold: float, chars_threshold: int, collection: record<attribute_mentions_limit: int, concept_topics_limit: int, facet_atts_limit: int, facet_mentions_limit: int, facets_limit: int, named_entities_limit: int, named_mentions_limit: int, query_topics_limit: int, theme_mentions_limit: int, themes_limit: int, user_entities_limit: int, user_mentions_limit: int>, config_id: string, document: record<auto_categories_limit: int, concept_topics_limit: int, detect_language: bool, entity_themes_limit: int, intentions: bool, model_sentiment: bool, named_entities_limit: int, named_mentions_limit: int, named_opinions_limit: int, named_relations_limit: int, phrases_limit: int, pos_types: string, possible_phrases_limit: int, query_topics_limit: int, summary_limit: int, theme_mentions_limit: int, themes_limit: int, user_entities_limit: int, user_mentions_limit: int, user_opinions_limit: int, user_relations_limit: int>, entities_threshold: int, from_template_config_id: string, is_primary: bool, language: string, modified: string, name: string, one_sentence: bool, process_html: bool, version: string>
# operationId: addConfigurations
export def "add-configurations" [
  content_type: string
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
  --body: record
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/configurations.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    content_type: $content_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update user configurations
#
# PUT /configurations.{content_type}
# Returns: table<auto_response: bool, callback: string, categories_threshold: float, chars_threshold: int, collection: record<attribute_mentions_limit: int, concept_topics_limit: int, facet_atts_limit: int, facet_mentions_limit: int, facets_limit: int, named_entities_limit: int, named_mentions_limit: int, query_topics_limit: int, theme_mentions_limit: int, themes_limit: int, user_entities_limit: int, user_mentions_limit: int>, config_id: string, document: record<auto_categories_limit: int, concept_topics_limit: int, detect_language: bool, entity_themes_limit: int, intentions: bool, model_sentiment: bool, named_entities_limit: int, named_mentions_limit: int, named_opinions_limit: int, named_relations_limit: int, phrases_limit: int, pos_types: string, possible_phrases_limit: int, query_topics_limit: int, summary_limit: int, theme_mentions_limit: int, themes_limit: int, user_entities_limit: int, user_mentions_limit: int, user_opinions_limit: int, user_relations_limit: int>, entities_threshold: int, from_template_config_id: string, is_primary: bool, language: string, modified: string, name: string, one_sentence: bool, process_html: bool, version: string>
# operationId: updateConfigurations
export def "update-configurations" [
  content_type: string
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
  --body: record
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/configurations.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    content_type: $content_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Queue document for analysis
#
# POST /document.{content_type}
# Returns: record<id: string, job_id: string, tag: string, text: string>
# operationId: queueDocument
export def "queue-document" [
  content_type: string
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
  --config-id: string # Identifier of configuration used for analysis.
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/document.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    content_type: $content_type, config_id: $config_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Queue batch of documents for analysis
#
# POST /document/batch.{content_type}
# Returns: record<id: string, job_id: string, tag: string, text: string>
# operationId: queueBatchOfDocuments
export def "queue-batch-of-documents" [
  content_type: string
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
  --config-id: string # Identifier of configuration used for analysis.
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/document/batch.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    content_type: $content_type, config_id: $config_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve documents analysis
#
# GET /document/processed.{content_type}
# Returns: record<auto_categories: table<categories: list, sentiment_polarity: string, sentiment_score: float, strength_score: float, title: string, type: string>, config_id: string, details: table<is_imperative: bool, is_polar: bool, words: list>, entities: table<count: int, entity_type: string, label: string, mentions: list, negative_count: int, neutral_count: int, positive_count: int, title: string, type: string>, id: string, intentions: table<evidence_phrase: string, type: string, what: string, who: string>, job_id: string, language: string, language_score: float, model_sentiment: record<mixed_score: float, model_name: string, negative_score: float, neutral_score: float, positive_score: float, sentiment_polarity: string>, opinions: table<quotation: string, sentiment_polarity: string, sentiment_score: float, speaker: float, topic: string, type: string>, phrases: table<intensifying_phrase: string, is_intensified: bool, is_negated: bool, negating_phrase: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>, relations: table<confidence_score: float, entities: list, extra: string, relation_type: string, type: string>, sentiment_polarity: string, sentiment_score: float, source_text: string, status: string, summary: string, taxonomy: table<hitcount: int, id: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>, themes: table<mentions: list, normalized: string, phrases_count: int, sentiment_polarity: string, sentiment_score: float, stemmed: string, themes_count: int, title: string>, topics: table<hitcount: int, id: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>>
# operationId: retrieveProcessedDocuments
export def "retrieve-processed-documents" [
  content_type: string
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
  --config-id: string # Identifier of configuration used for analysis.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/document/processed.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    content_type: $content_type, config_id: $config_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Cancel document analysis
#
# DELETE /document/{document_id}.{content_type}
# operationId: cancelDocument
export def "cancel-document" [
  document_id: string
  content_type: string
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
  --config-id: string # Identifier of configuration used for analysis.
]: nothing -> any {
  http-request {
    method: delete
    path: "/document/{document_id}.{content_type}"
    path_params: [{name: document_id, var: document_id}, {name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    document_id: $document_id, content_type: $content_type, config_id: $config_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve document analysis or its status in queue
#
# GET /document/{document_id}.{content_type}
# Returns: record<auto_categories: table<categories: list, sentiment_polarity: string, sentiment_score: float, strength_score: float, title: string, type: string>, config_id: string, details: table<is_imperative: bool, is_polar: bool, words: list>, entities: table<count: int, entity_type: string, label: string, mentions: list, negative_count: int, neutral_count: int, positive_count: int, title: string, type: string>, id: string, intentions: table<evidence_phrase: string, type: string, what: string, who: string>, job_id: string, language: string, language_score: float, model_sentiment: record<mixed_score: float, model_name: string, negative_score: float, neutral_score: float, positive_score: float, sentiment_polarity: string>, opinions: table<quotation: string, sentiment_polarity: string, sentiment_score: float, speaker: float, topic: string, type: string>, phrases: table<intensifying_phrase: string, is_intensified: bool, is_negated: bool, negating_phrase: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>, relations: table<confidence_score: float, entities: list, extra: string, relation_type: string, type: string>, sentiment_polarity: string, sentiment_score: float, source_text: string, status: string, summary: string, taxonomy: table<hitcount: int, id: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>, themes: table<mentions: list, normalized: string, phrases_count: int, sentiment_polarity: string, sentiment_score: float, stemmed: string, themes_count: int, title: string>, topics: table<hitcount: int, id: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>>
# operationId: receiveDocumentAnalyticData
export def "receive-document-analytic-data" [
  document_id: string
  content_type: string
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
  --config-id: string # Identifier of configuration used for analysis.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/document/{document_id}.{content_type}"
    path_params: [{name: document_id, var: document_id}, {name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    document_id: $document_id, content_type: $content_type, config_id: $config_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove user entities
#
# DELETE /entities.{content_type}
# operationId: deleteEntities
export def "delete-entities" [
  content_type: string
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
    path: "/entities.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    content_type: $content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve user entities
#
# GET /entities.{content_type}
# Returns: table<id: string, label: string, modified: string, name: string, normalized: string, type: string>
# operationId: getEntities
export def "get-entities" [
  content_type: string
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
  --config-id: string # Identifier of configuration user entities linked to.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/entities.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    content_type: $content_type, config_id: $config_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add user entities
#
# POST /entities.{content_type}
# Returns: table<id: string, label: string, modified: string, name: string, normalized: string, type: string>
# operationId: addEntities
export def "add-entities" [
  content_type: string
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
  --config-id: string # Identifier of configuration user entities linked to.
  --body: record
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/entities.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    content_type: $content_type, config_id: $config_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update user entities
#
# PUT /entities.{content_type}
# Returns: table<id: string, label: string, modified: string, name: string, normalized: string, type: string>
# operationId: updateEntities
export def "update-entities" [
  content_type: string
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
  --config-id: string # Identifier of configuration user entities linked to.
  --body: record
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/entities.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    content_type: $content_type, config_id: $config_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve supported features
#
# GET /features.{content_type}
# Returns: table<detailed_mode: record<auto_categories: bool, entity_mentions: bool, entity_opinions: bool, entity_relations: bool, entity_themes: bool, intentions: bool, language_detection: bool, model_sentiment: bool, named_entities: bool, pos_tagging: bool, queries: bool, sentiment: bool, sentiment_phrases: bool, summarization: bool, taxonomy: bool, theme_mentions: bool, themes: bool, user_categories: bool, user_entities: bool>, discovery_mode: record<entity_mentions: bool, facet_attributes: bool, facet_mentioins: bool, facets: bool, named_entities: bool, queries: bool, taxonomy: bool, theme_mentions: bool, themes: bool, user_categories: bool, user_entities: bool>, html_processing: bool, id: string, language: string, one_sentence_mode: bool, settings: record<blacklist: bool, queries: bool, sentiment_phrases: bool, taxonomy: bool, user_categories: bool, user_entities: bool>, templates: record<config_id: string, description: string, id: string, is_free: bool, language: string, name: string, type: string, version: string>>
# operationId: getFeatures
export def "get-features" [
  content_type: string
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
  --language: string # Filter features by specified language
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/features.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    query: [{name: language, var: language}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    content_type: $content_type, language: $language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove sentiment-bearing phrases
#
# DELETE /phrases.{content_type}
# operationId: deletePhrases
export def "delete-phrases" [
  content_type: string
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
  --config-id: string # Identifier of configuration phrases linked to.
  --body: list
]: any -> any {
  $in | http-request {
    method: delete
    path: "/phrases.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    content_type: $content_type, config_id: $config_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve sentiment-bearing phrases
#
# GET /phrases.{content_type}
# Returns: table<id: string, modified: string, name: string, weight: float>
# operationId: getPhrases
export def "get-phrases" [
  content_type: string
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
  --config-id: string # Identifier of configuration phrases linked to.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/phrases.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    content_type: $content_type, config_id: $config_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add sentiment-bearing phrases
#
# POST /phrases.{content_type}
# Returns: table<id: string, modified: string, name: string, weight: float>
# operationId: addPhrases
export def "add-phrases" [
  content_type: string
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
  --config-id: string # Identifier of configuration phrases linked to.
  --body: record
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/phrases.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    content_type: $content_type, config_id: $config_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates sentiment-bearing phrases
#
# PUT /phrases.{content_type}
# Returns: table<id: string, modified: string, name: string, weight: float>
# operationId: updatePhrases
export def "update-phrases" [
  content_type: string
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
  --config-id: string # Identifier of configuration phrases linked to.
  --body: record
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/phrases.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    content_type: $content_type, config_id: $config_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove queries
#
# DELETE /queries.{content_type}
# operationId: deleteQueries
export def "delete-queries" [
  content_type: string
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
  --config-id: string # Identifier of configuration queries linked to.
  --body: list
]: any -> any {
  $in | http-request {
    method: delete
    path: "/queries.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    content_type: $content_type, config_id: $config_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve queries
#
# GET /queries.{content_type}
# Returns: table<id: string, modified: string, name: string, query: string>
# operationId: getQueries
export def "get-queries" [
  content_type: string
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
  --config-id: string # Identifier of configuration queries linked to.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/queries.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    content_type: $content_type, config_id: $config_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add or update queries
#
# POST /queries.{content_type}
# Returns: table<id: string, modified: string, name: string, query: string>
# operationId: addQueries
export def "add-queries" [
  content_type: string
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
  --config-id: string # Identifier of configuration queries linked to.
  --body: record
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/queries.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    content_type: $content_type, config_id: $config_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update queries
#
# PUT /queries.{content_type}
# Returns: table<id: string, modified: string, name: string, query: string>
# operationId: updateQueries
export def "update-queries" [
  content_type: string
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
  --config-id: string # Identifier of configuration queries linked to.
  --body: record
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/queries.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    content_type: $content_type, config_id: $config_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve usage statistics
#
# GET /statistics.{content_type}
# Returns: record<calls_data: int, calls_polling: int, calls_settings: int, colls_documents: int, colls_failed: int, colls_processed: int, colls_responded: int, configurations: table<calls_data: int, calls_polling: int, calls_settings: int, colls_failed: int, colls_processed: int, colls_responded: int, config_id: string, docs_failed: int, docs_processed: int, docs_responded: int, latest_used_app: string, name: string, overall_batches: int, overall_calls: int, overall_docs: int, overall_exceeded: int, overall_texts: int, overcall_colls: int, used_apps: string>, docs_failed: int, docs_processed: int, docs_responded: int, latest_used_app: string, name: string, overall_batches: int, overall_calls: int, overall_docs: int, overall_exceeded: int, overall_texts: int, overcall_colls: int, status: string, used_apps: string>
# operationId: getStatistic
export def "get-statistic" [
  content_type: string
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
  --config-id: string # Configuration identifier for usage statistics retrieving.
  --interval: string # Hour, Day, Week, Month, Year values are supported.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/statistics.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}, {name: interval, var: interval}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    content_type: $content_type, config_id: $config_id, interval: $interval
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve API status
#
# GET /status.{content_type}
# Returns: record<api_version: string, service_status: string, service_version: string, supported_compression: string, supported_encoding: string, supported_languages: list<string>>
# operationId: getStatus
export def "get-status" [
  content_type: string
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
    path: "/status.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    content_type: $content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve subscription details
#
# GET /subscription.{content_type}
# Returns: record<basic_settings: record<auto_response_limit: int, batch_limit: int, blacklist_limit: int, callback_batch_limit: int, categories_limit: int, category_samples_limit: int, characters_limit: int, collection_limit: int, configurations_limit: int, entities_limit: int, output_data_limit: int, processed_batch_limit: int, queries_limit: int, return_source_text: bool, sentiment_limit: int>, billing_settings: record<app_seats_allocated: int, app_seats_permitted: int, data_calls_balance: int, data_calls_limit: int, data_calls_limit_interval: int, docs_balance: int, docs_limit: int, docs_limit_interval: int, docs_suggested: int, docs_suggested_interval: int, expiration_date: string, limit_type: string, polling_calls_balance: int, polling_calls_limit: int, polling_calls_limit_interval: int, priority: string, settings_calls_balance: int, settings_calls_limit: int, settings_calls_limit_interval: int>, feature_settings: record<collection: record<concept_topics: bool, facets: bool, mentions: bool, named_entities: bool, query_topics: bool, themes: bool, user_entities: bool>, document: record<auto_categories: bool, concept_topics: bool, entity_themes: bool, intentions: bool, language_detection: bool, mentions: bool, model_sentiment: bool, named_entities: bool, named_relations: bool, opinions: bool, phrases_detection: bool, pos_tagging: bool, query_topics: bool, sentiment_phrases: bool, summary: bool, themes: bool, user_entities: bool, user_relations: bool>, html_processing: bool, supported_languages: string, templates: record<config_id: string, description: string, id: string, is_free: bool, language: string, name: string, type: string, version: string>>, name: string, status: string>
# operationId: getSubscription
export def "get-subscription" [
  content_type: string
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
    path: "/subscription.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    content_type: $content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove taxonomy nodes
#
# DELETE /taxonomy.{content_type}
# operationId: deleteTaxonomy
export def "delete-taxonomy" [
  content_type: string
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
  --config-id: string # Identifier of configuration queries linked to.
  --body: list
]: any -> any {
  $in | http-request {
    method: delete
    path: "/taxonomy.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    content_type: $content_type, config_id: $config_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve taxonomy
#
# GET /taxonomy.{content_type}
# Returns: table<enforce_parent_matching: bool, id: string, modified: string, name: string, nodes: list<any>, topics: list<record>>
# operationId: getTaxonomy
export def "get-taxonomy" [
  content_type: string
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
  --config-id: string # Identifier of configuration taxonomy linked to.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/taxonomy.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    content_type: $content_type, config_id: $config_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add taxonomy nodes
#
# POST /taxonomy.{content_type}
# Returns: table<enforce_parent_matching: bool, id: string, modified: string, name: string, nodes: list<any>, topics: list<record>>
# operationId: addTaxonomy
export def "add-taxonomy" [
  content_type: string
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
  --config-id: string # Identifier of configuration queries linked to.
  --body: record
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/taxonomy.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    content_type: $content_type, config_id: $config_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update taxonomy nodes
#
# PUT /taxonomy.{content_type}
# Returns: table<enforce_parent_matching: bool, id: string, modified: string, name: string, nodes: list<any>, topics: list<record>>
# operationId: updateTaxonomy
export def "update-taxonomy" [
  content_type: string
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
  --config-id: string # Identifier of configuration queries linked to.
  --body: record
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/taxonomy.{content_type}"
    path_params: [{name: content_type, var: content_type}]
    query: [{name: config_id, var: config_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    content_type: $content_type, config_id: $config_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
