# Auto-generated client for AGCO API v1
# Source: https://api.apis.guru/v2/specs/agco-ats.com/v1/openapi.json
# Auth: --token flag or $env.AGCO_API_TOKEN

const CLIENT = {
  base_url: "https://secure.agco-ats.com"
  token_env_var: "AGCO_API_TOKEN"
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

def base-url-completer [] { ["https://secure.agco-ats.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }
def state-completer [] { ["Active" "Damaged" "Inactive"] }
def state-completer-1 [] { ["Active" "Inactive" "None"] }
def bearer-action-completer [] { ["Disable" "None" "Reset"] }
def mac-action-completer [] { ["Disable" "None" "Reset"] }
def duration-units-completer [] { ["Days" "Hours" "Minutes" "Weeks"] }
def accept-completer-1 [] { ["application/json" "text/json"] }
def state-completer-2 [] { ["Available" "Created" "Removed"] }
def license-activation-type-completer [] { ["EDT" "EDTLite"] }
def status-completer [] { ["Active" "All" "Inactive"] }
def subscription-type-completer [] { ["ExcludeByDefault" "IncludeByDefault" "Required"] }
def data-required-completer [] { ["No" "Optional" "Yes"] }
def status-completer-1 [] { ["Active" "All" "Completed"] }
def subscription-type-filter-completer [] { ["All" "Default" "RequiredOnly"] }
def state-completer-3 [] { ["CreatePending" "Invalidated" "Original" "Processed" "Processing" "RequestPending" "Requested" "Validated"] }
def state-completer-4 [] { ["Cancelled" "Completed" "NotSubmitted" "Submitted"] }
def state-completer-5 [] { ["Cancelled" "Completed" "OutForProcessing" "OutForTranslation" "PendingApproval" "Processing"] }
def type-completer [] { ["Commercial" "Internal" "RightToRepair" "Temporary"] }
def deleted-completer [] { ["All" "Deleted" "NotDeleted"] }
def status-completer-2 [] { ["Cancelled" "Failed" "InProgress" "Ready" "Succeeded"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    aftermarket-services-get-certs: "record"
    aftermarket-services-put-ecu: "record<ActivationCode: string, DamagedDescription: string, EngineSerialNumber: string, ReplacesECUSerialNumber: string, SerialNumber: string, State: string>"
    aftermarket-services-get-engine-iqa-codes: "list<string>"
    aftermarket-services-put-iqa-codes: "bool"
    aftermarket-services-get-production-data: "table<DataType: string, DataValues: string>"
    aftermarket-services-get-connection-status: "bool"
    aftermarket-services-get-user-status: "record<DealerCode: string, State: string, VoucherCode: string>"
    aftermarket-services-update-user-status: "bool"
    authentication-default: "record<Email: string, MACId: string, MACToken: string, Name: string, Token: string, UserID: int, Username: string>"
    authorization-categories-get: "record<Entities: table<Description: string, ID: string, Name: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    authorization-categories-post: "string"
    authorization-categories-get-users: "record<Entities: table<Categories: list, User: record>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    authorization-code-definitions-get-authorization-code-definition: "record<Entities: table<AuthorizationID: string, CreatedByUserID: int, CreatedDate: string, DataFields: list, DeletedByUserID: int, DeletedDate: string, Description: string, DurationAccuracy: int, DurationAmount: int, DurationUnits: string, HashLength: int, ID: string, IsDeleted: bool, Name: string, RandomLength: int, ValidationFields: list>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    authorization-code-definitions-post-authorization-code-definition: "string"
    get-api-v2-authorization-code-definitions-id: "record<AuthorizationID: string, CreatedByUserID: int, CreatedDate: string, DataFields: table<DigitsPrecision: int, MaxExponent: int, MaxValue: float, MinExponent: int, MinValue: float, Name: string, ScaleFactor: float, Signed: bool, Type: string>, DeletedByUserID: int, DeletedDate: string, Description: string, DurationAccuracy: int, DurationAmount: int, DurationUnits: string, HashLength: int, ID: string, IsDeleted: bool, Name: string, RandomLength: int, ValidationFields: table<Name: string, Type: string>>"
    authorization-codes-get-authorization-codes: "record<Entities: table<Code: string, CreatedByUserID: int, CreatedDate: string, DataParameters: list, DefinitionID: string, DeletedByUserID: int, DeletedDate: string, EffectiveDate: string, ID: int, IsDeleted: bool, ValidationParameters: list>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    authorization-codes-post-authorization-code: "int"
    authorization-codes-get-authorization-code: "record<Code: string, CreatedByUserID: int, CreatedDate: string, DataParameters: table<Name: string, Value: string>, DefinitionID: string, DeletedByUserID: int, DeletedDate: string, EffectiveDate: string, ID: int, IsDeleted: bool, ValidationParameters: table<Name: string, Value: string>>"
    authorization-codes-get-contact-information: "record<AuthorizationCodeID: int, Code: string, Contact: string, CreatedBy: string, CreatedDate: string, DealerCode: string, Dealership: string, DefinitionName: string, Email: string, ID: int, Notes: string, Phone: string>"
    authorization-codes-validate-authorization-code: "record<ExpirationDate: string, IsValid: bool>"
    authorization-contact-information-get: "record<Entities: table<AuthorizationCodeID: int, Code: string, Contact: string, CreatedBy: string, CreatedDate: string, DealerCode: string, Dealership: string, DefinitionName: string, Email: string, ID: int, Notes: string, Phone: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    authorization-contact-information-post: "int"
    brands-brands: "list<string>"
    bundles-get-bundles: "record<Entities: table<Active: bool, BundleID: string, BundleNumber: int, Description: string, UpdateGroupID: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    bundles-post-bundle: "string"
    bundles-get-bundle: "record<Active: bool, BundleID: string, BundleNumber: int, Description: string, UpdateGroupID: string>"
    clients-get: "record<Entities: table<ClientID: string, LastCheckin: string, Tag: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    update-system-get-cached-files: "list<string>"
    package-reports-default: "table<Categories: list<record>, PackageDescription: string, PackageID: string>"
    get-api-v2-clients-id: "record<ClientID: string, LastCheckin: string, Tag: string>"
    clients-get-available-subscriptions: "record<Entities: table<AvailableSubscriptions: list, UpdateGroup: record>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    clients-get-subscriptions: "record<Entities: table<ClientID: string, Include: bool, PackageTypeID: string, UpdateGroupID: string, UpdateGroupSubscriptionID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    content-definitions-get-content-definitions: "record<Entities: table<Attributes: list, ContentDefinitionID: int, Description: string, Name: string, PackageTypeID: string, TypeID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    content-definitions-post-content-definition: "int"
    content-definitions-get-content-definition: "record<Attributes: table<ContentDefinitionID: int, ID: int, Name: string, Value: string>, ContentDefinitionID: int, Description: string, Name: string, PackageTypeID: string, TypeID: int>"
    content-definitions-get-content-definition-attributes: "record<Entities: table<ContentDefinitionID: int, ID: int, Name: string, Value: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    content-definitions-post-content-definition-attribute: "int"
    content-release-get-content-release-version: "record<Entities: table<ContentDefinitionID: int, ContentReleaseID: int, Deleted: bool, PublisherUserID: int, ReleaseID: int, TestReportUrl: string, UpdatedDate: string, Version: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    content-release-post-content-release: "int"
    get-api-v2-content-releases-content-release-id: "record<ContentDefinitionID: int, ContentReleaseID: int, Deleted: bool, PublisherUserID: int, ReleaseID: int, TestReportUrl: string, UpdatedDate: string, Version: int>"
    content-submission-types-get-content-submission-types: "table<AttributeTemplate: string, BuildDefinitionID: int, CategoryTemplate: string, Description: string, Enabled: bool, ID: int, InventoryPackageID: string, JobID: int, Name: string, ReleaseNotesDescription: string>"
    content-submission-types-post-content-submission-type: "int"
    content-submission-types-get-content-submission-type: "record<AttributeTemplate: string, BuildDefinitionID: int, CategoryTemplate: string, Description: string, Enabled: bool, ID: int, InventoryPackageID: string, JobID: int, Name: string, ReleaseNotesDescription: string>"
    content-submissions-get-content-submissions: "record<Entities: table<Attributes: list, BuildID: int, ContentDefinitionID: int, ContentSubmissionID: int, Definition: record, JobRunID: int, PackageID: string, ReleaseNotes: string, Repository: string, Revision: int, SubmissionDate: string, UserID: int, Version: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    content-submissions-post-content-submission: "int"
    content-submissions-get-content-submission: "record<Attributes: table<ContentSubmissionID: int, ID: int, Name: string, Value: string>, BuildID: int, ContentDefinitionID: int, ContentSubmissionID: int, Definition: record<Attributes: list<record>, ContentDefinitionID: int, Description: string, Name: string, PackageTypeID: string, TypeID: int>, JobRunID: int, PackageID: string, ReleaseNotes: string, Repository: string, Revision: int, SubmissionDate: string, UserID: int, Version: int>"
    content-submissions-get-content-submission-attributes: "record<Entities: table<ContentSubmissionID: int, ID: int, Name: string, Value: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    content-submissions-post-content-submission-attribute: "int"
    content-submissions-get-content-submission-status: "record<ActivityRuns: table<ActivityRunID: int, EndDate: string, JobActivityID: int, JobRunID: int, Parameters: list, StartDate: string, Status: record, Steps: list>, EndDate: string, JobID: int, JobRunID: int, Parameters: table<Direction: string, Name: string, Value: string>, StartDate: string, Status: string>"
    dealer-by-country-get-countries: "record<Entities: table<Count: int, Country: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    dealers-get-dealers: "record<Entities: table<BillingAddress: string, BillingAddress2: string, BillingAddress3: string, BillingAddress4: string, BillingCity: string, BillingCountry: string, BillingCountryCode: string, BillingState: string, BillingZip: string, Brands: list, DealerCode: string, DealerName: string, DealerStatus: string, DealerStatusUpdateDate: string, Filler: string, IsValid: bool, LanguagePreference: string, Region1: string, Region2: string, RegionMapping: string, RoleBrand: string, ShippingAddress2: string, ShippingAddress3: string, ShippingAddress4: string, ShippingCity: string, ShippingCountry: string, ShippingState: string, ShippingStreet: string, ShippingZip: string, Telephone: string, VATCode: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    dealers-get-dealerby-dealer-code: "record<BillingAddress: string, BillingAddress2: string, BillingAddress3: string, BillingAddress4: string, BillingCity: string, BillingCountry: string, BillingCountryCode: string, BillingState: string, BillingZip: string, Brands: list<string>, DealerCode: string, DealerName: string, DealerStatus: string, DealerStatusUpdateDate: string, Filler: string, IsValid: bool, LanguagePreference: string, Region1: string, Region2: string, RegionMapping: string, RoleBrand: string, ShippingAddress2: string, ShippingAddress3: string, ShippingAddress4: string, ShippingCity: string, ShippingCountry: string, ShippingState: string, ShippingStreet: string, ShippingZip: string, Telephone: string, VATCode: string>"
    files-get-files: "record<Entities: table<CRC: string, ContentType: string, Description: string, Id: string, IsPublic: bool, Name: string, Path: string, Size: int, State: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    files-post-file: "string"
    files-get-file: "record<CRC: string, ContentType: string, Description: string, Id: string, IsPublic: bool, Name: string, Path: string, Size: int, State: string>"
    files-get-file-contents: "record"
    files-put-file-contents: "record"
    global-image-categories-get-files: "record<Entities: table<Id: string, Name: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    global-image-categories-post-file: "string"
    global-image-categories-get-file: "record<Id: string, Name: string>"
    global-images-get-global-images: "record<Entities: table<CRC: string, Categories: list, Date: string, Description: string, Height: int, Id: string, Name: string, Publisher: string, Size: int, State: string, ThumbnailCRC: string, ThumbnailSize: int, Width: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    global-images-post-global-image: "string"
    global-images-get-global-image: "record<CRC: string, Categories: table<Id: string, Name: string>, Date: string, Description: string, Height: int, Id: string, Name: string, Publisher: string, Size: int, State: string, ThumbnailCRC: string, ThumbnailSize: int, Width: int>"
    global-images-get-global-image-contents: "record"
    global-images-put-global-image-contents: "record"
    languages-get-languages: "record<Entities: table<Description: string, IsDeleted: bool, LocaleId: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    languages-create-language: "int"
    languages-get-language: "record<Description: string, IsDeleted: bool, LocaleId: int>"
    license-activations-post: "record<Key: string, LicenseData: string>"
    license-activations-post-register-edt-lite: "bool"
    license-activations-put: "record<Key: string, LicenseData: string>"
    licenses-get: "record<Entities: table<Active: bool, CreatedDate: string, DeactivatedDate: string, LicenseActivationType: string, LicenseID: string, LicenseVersion: string, RefreshDate: string, SystemInfo: string, UpdatedLicenseVersion: string, VoucherCode: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    get-api-v2-licenses-id: "record<Active: bool, CreatedDate: string, DeactivatedDate: string, LicenseActivationType: string, LicenseID: string, LicenseVersion: string, RefreshDate: string, SystemInfo: string, UpdatedLicenseVersion: string, VoucherCode: string>"
    logs-get-logs: "record<Entities: table<ID: string, Message: string, TimeStamp: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    logs-post-log: "string"
    logs-get-log: "record<ID: string, Message: string, TimeStamp: string>"
    package-types-get: "record<Entities: table<Attribute: string, Category: string, Description: string, Icon: string, InventoryFrequency: int, InventoryPackage: string, LocalizedDescription: string, LocalizedName: string, MaxDeltaPackages: int, PackageTypeID: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    package-types-post: "string"
    get-api-v2-package-types-id: "record<Attribute: string, Category: string, Description: string, Icon: string, InventoryFrequency: int, InventoryPackage: string, LocalizedDescription: string, LocalizedName: string, MaxDeltaPackages: int, PackageTypeID: string>"
    package-typeto-bundles-get: "record<Entities: table<BundleID: string, PackageTypeID: string, PackageVersion: int, Priority: int, SubscriptionType: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    packages-get-packages: "record<Entities: table<Autorun: bool, CRC: string, Description: string, LocalizedName: string, Notes: string, PackageID: string, PackageTypeID: string, PreviousVersion: int, ReleaseDate: string, Released: bool, RemoveOnSuccess: bool, Size: int, Switches: string, Url: string, Version: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    packages-post-package: "string"
    packages-get-package: "record<Autorun: bool, CRC: string, Description: string, LocalizedName: string, Notes: string, PackageID: string, PackageTypeID: string, PreviousVersion: int, ReleaseDate: string, Released: bool, RemoveOnSuccess: bool, Size: int, Switches: string, Url: string, Version: int>"
    permissions-get-permissions: "record<Entities: table<DataDescription: string, DataRequired: string, Description: string, Id: int, Name: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    permissions-post-permission: "int"
    permissions-get-permission: "record<DataDescription: string, DataRequired: string, Description: string, Id: int, Name: string>"
    priority-packages-get-priority-packages: "record<Entities: table<Autorun: bool, CRC: string, ClientID: string, Description: string, Notes: string, PackageID: string, PackageTypeID: string, PreviousVersion: int, PriorityPackageID: string, ReleaseDate: string, Released: bool, RemoveOnSuccess: bool, Size: int, Switches: string, TimeStamp: string, Url: string, Version: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    priority-packages-post-priority-packages: "string"
    priority-packages-get-priority-package: "record<Autorun: bool, CRC: string, ClientID: string, Description: string, Notes: string, PackageID: string, PackageTypeID: string, PreviousVersion: int, PriorityPackageID: string, ReleaseDate: string, Released: bool, RemoveOnSuccess: bool, Size: int, Switches: string, TimeStamp: string, Url: string, Version: int>"
    release-get-releases: "record<Entities: table<BuildDate: string, BundleIDs: list, ReleaseDate: string, ReleaseID: int, ReleaseNumber: string, Visible: bool>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    release-post-release: "int"
    release-get-release: "record<BuildDate: string, BundleIDs: list<string>, ReleaseDate: string, ReleaseID: int, ReleaseNumber: string, Visible: bool>"
    reporting-bundle-status-summary: "record<Entities: table<AverageDownloadTime: string, AverageInstallTime: string, Downloaded: int, Error: int, Installed: int, Package: string, PackageID: string, PackageStatusItems: list>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    reporting-bundles-in-update-group: "record<Entities: table<Active: bool, BundleID: string, BundleNumber: int, Description: string, UpdateGroupID: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    reporting-client-info: "record<ClientID: string, Package: table<Categories: list, PackageDescription: string, PackageID: string>>"
    reporting-current-packages-in-update-group: "table<Autorun: bool, CRC: string, Description: string, LocalizedName: string, Notes: string, PackageID: string, PackageTypeID: string, PreviousVersion: int, ReleaseDate: string, Released: bool, RemoveOnSuccess: bool, Size: int, Switches: string, Url: string, Version: int>"
    reporting-get-client: "record<ClientID: string, LastCheckin: string, Tag: string>"
    reporting-get-subscriptions: "record<Entities: table<Active: bool, ClientID: string, LastCheckin: string, RelationshipID: string, UpdateGroupID: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    reporting-package-status-summary: "record<AverageDownloadTime: string, AverageInstallTime: string, Downloaded: int, Error: int, Installed: int, Package: string, PackageID: string, PackageStatusItems: table<ClientID: string, ClientKey: string, DownloadTime: string, Downloaded: string, InstallCompleted: string, InstallResult: string, InstallStarted: string, InstallTime: string, Percentage: string, Size: string, Timestamp: string>>"
    reporting-registered-clients: "record<Entities: table<ClientID: string, LastCheckin: string, MinutesElapsed: int, ReportResult: string, ReportResultIsValid: bool, ReportValue: string, Tag: string>, Metadata: record<Limit: int, Offset: int, ReportResultExpected: string, ReportResultLabel: string, ReportValueLabel: string, TotalCount: int>>"
    reporting-update-groups: "record<Entities: table<Description: string, ID: string, InventoryFrequency: int, InventoryPackage: string, LocalizedDescription: string, LocalizedName: string, Priority: int, ReportField: string, UpdateType: string, ValidatingField: string, ValueToValidate: string, Version: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    reporting-update-metrics: "record<ActiveVersion: string, ActiveVersionByClient: table<BundleNumber: int, ClientCount: int, ReleaseName: string>, CurrentStateByClient: table<ClientCount: int, State: string>, CutOffDate: string, DataRefreshed: string, FilteredClientCount: int, PackageErrors: table<ClientCount: int, ErrorCode: string, LongDescription: string, ShortDescription: string>, TotalClientCount: int>"
    roles-get-roles: "record<Entities: table<Description: string, Id: int, Name: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    roles-post-role: "int"
    roles-get-role: "record<Description: string, Id: int, Name: string>"
    roles-get-role-permissions: "record<Entities: table<DataDescription: string, DataRequired: string, Description: string, Id: int, Name: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    user-permissions-get-users: "record<Entities: table<ChangePassword: string, Email: string, Name: string, Password: string, UserID: int, Username: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    string-definitions-get-definitions: "record<Entities: table<DescriptionForTranslator: string, DoNotTranslate: bool, Id: string, ParameterCount: int, Timestamp: string, Translations: list>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    string-definitions-get-definition: "record<DescriptionForTranslator: string, DoNotTranslate: bool, Id: string, ParameterCount: int, Timestamp: string, Translations: table<AuthorId: int, LanguageId: int, State: string, StringId: string, StringValue: string, Timestamp: string>>"
    string-translations-get-translations: "record<Entities: table<AuthorId: int, LanguageId: int, State: string, StringId: string, StringValue: string, Timestamp: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    string-translations-get-translation: "record<AuthorId: int, LanguageId: int, State: string, StringId: string, StringValue: string, Timestamp: string>"
    translation-keys-get: "record<Entities: table<ID: int, KeyName: string, StringID: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    translation-keys-create-translation-key: "int"
    translation-keys-get-translation-key: "record<ID: int, KeyName: string, StringID: string>"
    translation-requests-get-translation-requests: "record<Entities: table<ApprovalUserId: int, CCEmailAddresses: list, ChargeToAccount: string, Deadline: string, Id: int, LocaleIds: list, Notes: string, QuestionsUserId: int, State: string, SubmittedBy: int, TranslatorEmail: string, TranslatorName: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    translation-requests-create-translation-request: "int"
    translation-requests-get-translation-request: "record<ApprovalUserId: int, CCEmailAddresses: list<string>, ChargeToAccount: string, Deadline: string, Id: int, LocaleIds: list<int>, Notes: string, QuestionsUserId: int, State: string, SubmittedBy: int, TranslatorEmail: string, TranslatorName: string>"
    translation-sets-get-translation-sets: "record<Entities: table<Attributes: list, FileIDs: list, Id: int, InDate: string, Notes: string, OutDate: string, State: string, TranslationRequestID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    translation-sets-get-translation-set: "record<Attributes: table<ID: int, Name: string, TranslationSetID: int, Value: string>, FileIDs: list<string>, Id: int, InDate: string, Notes: string, OutDate: string, State: string, TranslationRequestID: int>"
    translation-sets-get-translation-set-attributes: "record<Entities: table<ID: int, Name: string, TranslationSetID: int, Value: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    translation-sets-post-translation-set-attribute: "int"
    translation-sets-get-source-strings: "record<Entities: table<DescriptionForTranslator: string, LanguageID: int, StringID: string, StringValue: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    translation-sets-get-statistics: "record<LanguageIDs: list<int>, StringCount: int>"
    translation-sets-get-translation-set-strings: "record<Entities: table<LanguageID: int, StringID: string, StringValue: string, TranslationSetId: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    update-group-client-relationships-get-subscriptions: "record<Entities: table<Active: bool, ClientID: string, LastCheckin: string, RelationshipID: string, UpdateGroupID: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    update-group-client-relationships-post-subscription: "string"
    update-group-client-relationships-get-subscription: "record<Active: bool, ClientID: string, LastCheckin: string, RelationshipID: string, UpdateGroupID: string>"
    update-group-subscriptions-get-update-group-subscriptions: "record<Entities: table<ClientID: string, Include: bool, PackageTypeID: string, UpdateGroupID: string, UpdateGroupSubscriptionID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    update-group-subscriptions-post-update-group-subscription: "int"
    update-group-subscriptions-get-update-group-subscription: "record<ClientID: string, Include: bool, PackageTypeID: string, UpdateGroupID: string, UpdateGroupSubscriptionID: int>"
    update-groups-get: "record<Entities: table<Description: string, ID: string, InventoryFrequency: int, InventoryPackage: string, LocalizedDescription: string, LocalizedName: string, Priority: int, ReportField: string, UpdateType: string, ValidatingField: string, ValueToValidate: string, Version: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    update-groups-post: "string"
    get-api-v2-update-groups-id: "record<Description: string, ID: string, InventoryFrequency: int, InventoryPackage: string, LocalizedDescription: string, LocalizedName: string, Priority: int, ReportField: string, UpdateType: string, ValidatingField: string, ValueToValidate: string, Version: string>"
    update-groups-get-update-group-bundles: "record<Entities: table<Active: bool, BundleID: string, BundleNumber: int, Description: string, UpdateGroupID: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    update-system-get-checkin: "record<Packages: table<Autorun: bool, CRC: string, Description: string, LocalizedName: string, Notes: string, PackageID: string, PackageTypeID: string, PreviousVersion: int, ReleaseDate: string, Released: bool, RemoveOnSuccess: bool, Size: int, Switches: string, Url: string, Version: int>, RemovePackages: list<string>>"
    user-content-definitions-get-user-content-definitions: "record<Entities: table<ContentDefinitionID: int, UserContentDefinitionID: int, UserID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    user-content-definitions-post-user-content-definition: "int"
    user-content-definitions-get-user-content-definition: "record<ContentDefinitionID: int, UserContentDefinitionID: int, UserID: int>"
    users-get: "record<Entities: table<ChangePassword: string, Email: string, Name: string, Password: string, UserID: int, Username: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    users-post: "record<ChangePassword: string, Email: string, Name: string, Password: string, UserID: int, Username: string>"
    users-get-current-user: "record<ChangePassword: string, Email: string, Name: string, Password: string, UserID: int, Username: string>"
    get-api-v2-users-current-permissions: "record<Entities: table<PermissionId: int, PermissionName: string, UserID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    user-permissions-get-current-user-roles: "record<Entities: table<Description: string, Id: int, Name: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    get-api-v2-users-id: "record<ChangePassword: string, Email: string, Name: string, Password: string, UserID: int, Username: string>"
    user-permissions-get-permissions: "record<Entities: table<PermissionId: int, PermissionName: string, UserID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    user-permissions-get-roles: "record<Entities: table<Description: string, Id: int, Name: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    voucher-history-get-voucher-history: "record<Entities: table<ChangedDate: string, CreatedDate: string, DealerCode: string, Deleted: bool, Email: string, ExpirationDate: string, ID: int, LicenseTo: string, ModifiedBy: string, OrderNumber: string, Punched: bool, PunchedDate: string, Purpose: string, Type: string, VoucherCode: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    vouchers-get: "record<Entities: table<CreatedDate: string, DealerCode: string, Deleted: bool, Email: string, ExpirationDate: string, LicenseTo: string, ModifiedBy: string, OrderNumber: string, Punched: bool, PunchedDate: string, Purpose: string, Type: string, VoucherCode: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    vouchers-post: "string"
    get-api-v2-vouchers-voucher-code: "record<CreatedDate: string, DealerCode: string, Deleted: bool, Email: string, ExpirationDate: string, LicenseTo: string, ModifiedBy: string, OrderNumber: string, Punched: bool, PunchedDate: string, Purpose: string, Type: string, VoucherCode: string>"
    vouchers-get-voucher-history: "record<Entities: table<ChangedDate: string, CreatedDate: string, DealerCode: string, Deleted: bool, Email: string, ExpirationDate: string, ID: int, LicenseTo: string, ModifiedBy: string, OrderNumber: string, Punched: bool, PunchedDate: string, Purpose: string, Type: string, VoucherCode: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    activities-get-activities: "record<Entities: table<ActivityID: int, Deleted: bool, Name: string, Parameters: list, Steps: list>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    activities-post-activity: "int"
    activities-get-activity: "record<ActivityID: int, Deleted: bool, Name: string, Parameters: table<Direction: string, Name: string, Type: string>, Steps: table<ActivityID: int, ActivityStepID: int, ImplementationID: string, ParameterMappings: list, RunOrder: int, StepID: int, StepName: string, UseConfig: string>>"
    activity-runs-get-activity-runs: "record<Entities: table<ActivityRunID: int, EndDate: string, JobActivityID: int, JobRunID: int, Parameters: list, StartDate: string, Status: record, Steps: list>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    activity-runs-get-activity-run: "record<ActivityRunID: int, EndDate: string, JobActivityID: int, JobRunID: int, Parameters: table<Direction: string, Name: string, Value: string>, StartDate: string, Status: record<CurrentStep: int, Status: string, StepProgress: int, StepStatus: string>, Steps: table<ActivityID: int, ActivityStepID: int, ImplementationID: string, ParameterMappings: list, RunOrder: int, StepID: int, StepName: string, UseConfig: string>>"
    activity-runs-get-activity-run-status: "record<CurrentStep: int, Status: string, StepProgress: int, StepStatus: string>"
    agents-get-agents: "record<Entities: table<AgentID: int, KeepAliveInterval: int, MachineName: string, Status: record, StepConfigurations: list, UserID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    agents-post-agent: "int"
    agents-get-current-agent-async: "record<AgentID: int, KeepAliveInterval: int, MachineName: string, Status: record<LastStatusUpdate: string, Online: bool>, StepConfigurations: table<Configurations: list, StepImplementationID: string>, UserID: int>"
    agents-get-current-agent-activity-run: "record<ActivityRunID: int, EndDate: string, JobActivityID: int, JobRunID: int, Parameters: table<Direction: string, Name: string, Value: string>, StartDate: string, Status: record<CurrentStep: int, Status: string, StepProgress: int, StepStatus: string>, Steps: table<ActivityID: int, ActivityStepID: int, ImplementationID: string, ParameterMappings: list, RunOrder: int, StepID: int, StepName: string, UseConfig: string>>"
    agents-get-agent-async: "record<AgentID: int, KeepAliveInterval: int, MachineName: string, Status: record<LastStatusUpdate: string, Online: bool>, StepConfigurations: table<Configurations: list, StepImplementationID: string>, UserID: int>"
    agents-get-agent-activity-run: "record<ActivityRunID: int, EndDate: string, JobActivityID: int, JobRunID: int, Parameters: table<Direction: string, Name: string, Value: string>, StartDate: string, Status: record<CurrentStep: int, Status: string, StepProgress: int, StepStatus: string>, Steps: table<ActivityID: int, ActivityStepID: int, ImplementationID: string, ParameterMappings: list, RunOrder: int, StepID: int, StepName: string, UseConfig: string>>"
    job-runs-get-job-runs: "record<Entities: table<ActivityRuns: list, EndDate: string, JobID: int, JobRunID: int, Parameters: list, StartDate: string, Status: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    job-runs-post-job-run: "int"
    job-runs-get-job-run: "record<ActivityRuns: table<ActivityRunID: int, EndDate: string, JobActivityID: int, JobRunID: int, Parameters: list, StartDate: string, Status: record, Steps: list>, EndDate: string, JobID: int, JobRunID: int, Parameters: table<Direction: string, Name: string, Value: string>, StartDate: string, Status: string>"
    jobs-get-jobs: "record<Entities: table<Activities: list, Deleted: bool, JobID: int, Name: string, Parameters: list>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    jobs-post-job: "int"
    jobs-get-job: "record<Activities: table<ActivityID: int, JobActivityID: int, JobID: int, ParameterMappings: list, RunOrder: int>, Deleted: bool, JobID: int, Name: string, Parameters: table<Direction: string, Name: string, Type: string>>"
    steps-get-steps: "record<Entities: table<ConfigRequired: bool, Deleted: bool, Description: string, ImplementationID: string, Name: string, Parameters: list, StepID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>"
    steps-post-step: "int"
    steps-get-step: "record<ConfigRequired: bool, Deleted: bool, Description: string, ImplementationID: string, Name: string, Parameters: table<Direction: string, Name: string, Type: string>, StepID: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["aftermarket-services-get-certs" "aftermarket-services-put-ecu" "aftermarket-services-get-engine-iqa-codes" "aftermarket-services-put-iqa-codes" "aftermarket-services-get-production-data" "aftermarket-services-get-connection-status" "aftermarket-services-get-user-status" "aftermarket-services-update-user-status" "authentication-put-manage-tokens" "authentication-default" "authentication-is-alive" "authentication-request-password-reset" "authentication-reset-pasword" "authorization-categories-get" "authorization-categories-post" "authorization-categories-get-users" "authorization-categories-delete" "authorization-categories-put" "authorization-categories-remove-user" "authorization-categories-add-user" "authorization-code-definitions-get-authorization-code-definition" "authorization-code-definitions-post-authorization-code-definition" "authorization-code-definitions-remove-category-from-definition" "authorization-code-definitions-add-category-to-definition" "authorization-code-definitions-delete-authorization-code-definition" "get-api-v2-authorization-code-definitions-id" "authorization-code-definitions-put-authorization-code-definition" "authorization-codes-get-authorization-codes" "authorization-codes-post-authorization-code" "authorization-codes-delete-authorization-code" "authorization-codes-get-authorization-code" "authorization-codes-put-authorization-code" "authorization-codes-get-contact-information" "authorization-codes-validate-authorization-code" "authorization-contact-information-get" "authorization-contact-information-post" "brands-brands" "bundles-get-bundles" "bundles-post-bundle" "bundles-delete-bundle" "bundles-get-bundle" "bundles-put-bundle" "clients-get" "update-system-get-cached-files" "package-reports-default" "put-api-v2-clients-client-id-package-reports" "package-reports-batch" "get-api-v2-clients-id" "clients-put" "clients-get-available-subscriptions" "clients-get-subscriptions" "content-definitions-put-content-definition-attributes" "content-definitions-delete-content-definition-attribute" "content-definitions-put-content-definition-attribute-async" "content-definitions-get-content-definitions" "content-definitions-post-content-definition" "content-definitions-delete-content-definition" "content-definitions-get-content-definition" "content-definitions-put-content-definition" "content-definitions-get-content-definition-attributes" "content-definitions-post-content-definition-attribute" "content-definitions-post-content-definition-attributes" "content-release-get-content-release-version" "content-release-post-content-release" "content-release-delete-content-release-versionn" "get-api-v2-content-releases-content-release-id" "content-release-put-content-definition" "content-submissions-put-content-submission-attributes" "content-submissions-delete-content-submission-attribute" "content-submissions-put-content-submission-attribute-async" "content-submission-types-get-content-submission-types" "content-submission-types-post-content-submission-type" "content-submission-types-delete-content-submission-type" "content-submission-types-get-content-submission-type" "content-submission-types-put-content-submission-type" "content-submissions-get-content-submissions" "content-submissions-post-content-submission" "content-submissions-delete-content-submission" "content-submissions-get-content-submission" "content-submissions-put-content-submission" "content-submissions-get-content-submission-attributes" "content-submissions-post-content-submission-attribute" "content-submissions-post-content-submission-attributes" "content-submissions-get-content-submission-status" "dealer-by-country-get-countries" "dealers-get-dealers" "dealers-get-dealerby-dealer-code" "files-get-files" "files-post-file" "files-delete-file" "files-get-file" "files-put-file" "files-get-file-contents" "files-put-file-contents" "global-image-categories-get-files" "global-image-categories-post-file" "global-image-categories-get-file" "global-images-get-global-images" "global-images-post-global-image" "global-images-delete-file" "global-images-get-global-image" "global-images-put-global-image" "global-images-get-global-image-contents" "global-images-put-global-image-contents" "languages-get-languages" "languages-create-language" "languages-delete-language" "languages-get-language" "languages-update-language" "license-activations-post" "license-activations-post-register-edt-lite" "license-activations-put" "license-activations-put-confirm" "licenses-get" "get-api-v2-licenses-id" "logs-get-logs" "logs-post-log" "logs-get-log" "notifications-post-mail" "package-types-get" "package-types-post" "package-types-delete" "get-api-v2-package-types-id" "package-types-put" "package-types-remove-package-type-user" "package-types-add-package-type-user" "package-typeto-bundles-delete" "package-typeto-bundles-get" "package-typeto-bundles-post" "package-typeto-bundles-put" "packages-get-packages" "packages-post-package" "packages-delete-package" "packages-get-package" "packages-put-package" "permissions-get-permissions" "permissions-post-permission" "permissions-delete-permission" "permissions-get-permission" "permissions-put-permission" "priority-packages-get-priority-packages" "priority-packages-post-priority-packages" "priority-packages-delete-priority-packages" "priority-packages-get-priority-package" "release-get-releases" "release-post-release" "release-get-release" "release-delete-release-bundle" "release-post-release-bundle" "release-put-content-definition" "reporting-bundle-status-summary" "reporting-bundles-in-update-group" "reporting-client-info" "reporting-current-packages-in-update-group" "reporting-get-client" "reporting-get-subscriptions" "reporting-package-status-summary" "reporting-registered-clients" "reporting-update-groups" "reporting-update-metrics" "roles-get-roles" "roles-post-role" "roles-delete-role" "roles-get-role" "roles-put-role" "roles-get-role-permissions" "roles-put-role-permissions" "user-permissions-get-users" "put-api-v2-roles-id-users" "string-definitions-get-definitions" "string-definitions-post-definition" "string-definitions-update-definitions" "string-definitions-get-definition" "string-translations-get-translations" "string-translations-update-translations" "string-translations-get-translation" "string-translations-update-translation" "translation-keys-get" "translation-keys-create-translation-key" "translation-keys-get-translation-key" "translation-keys-update-translation-key" "translation-requests-get-translation-requests" "translation-requests-create-translation-request" "translation-requests-get-translation-request" "translation-requests-update-translation-request" "translation-requests-update-translation-request-strings" "translation-sets-update-translation-set-attributes" "translation-sets-delete-translation-set-attribute" "translation-sets-update-translation-set-attribute" "translation-sets-get-translation-sets" "translation-sets-get-translation-set" "translation-sets-update-translation-set" "translation-sets-get-translation-set-attributes" "translation-sets-post-translation-set-attribute" "translation-sets-post-translation-set-attributes" "translation-sets-get-source-strings" "translation-sets-get-statistics" "translation-sets-get-translation-set-strings" "translation-sets-update-translation-set-strings" "update-group-client-relationships-get-subscriptions" "update-group-client-relationships-post-subscription" "update-group-client-relationships-put-subscription-by-client-id-update-group-id" "update-group-client-relationships-get-subscription" "update-group-client-relationships-put-subscription" "update-group-subscriptions-get-update-group-subscriptions" "update-group-subscriptions-post-update-group-subscription" "update-group-subscriptions-post-update-group-subscriptions" "update-group-subscriptions-put-update-group-subscriptions" "update-group-subscriptions-delete-update-group-subscription" "update-group-subscriptions-get-update-group-subscription" "update-group-subscriptions-put-update-group-subscription" "update-groups-get" "update-groups-post" "update-groups-delete" "get-api-v2-update-groups-id" "update-groups-put" "update-groups-get-update-group-bundles" "update-groups-remove-update-group-user" "update-groups-add-update-group-user" "update-system-get-checkin" "user-content-definitions-get-user-content-definitions" "user-content-definitions-post-user-content-definition" "user-content-definitions-delete-user-content-definition" "user-content-definitions-get-user-content-definition" "users-get" "users-post" "users-get-current-user" "users-put-current-user" "get-api-v2-users-current-permissions" "user-permissions-get-current-user-roles" "users-delete" "get-api-v2-users-id" "users-put" "user-permissions-get-permissions" "user-permissions-get-roles" "user-permissions-put" "voucher-history-get-voucher-history" "vouchers-get" "vouchers-post" "vouchers-delete" "get-api-v2-vouchers-voucher-code" "vouchers-put" "vouchers-get-voucher-history" "activities-get-activities" "activities-post-activity" "activities-delete-activity" "activities-get-activity" "activities-put-activity" "activity-runs-get-activity-runs" "activity-runs-get-activity-run" "activity-runs-put-activity-run" "activity-runs-get-activity-run-status" "activity-runs-put-activity-run-status" "agents-get-agents" "agents-post-agent" "agents-get-current-agent-async" "agents-get-current-agent-activity-run" "agents-delete-agent" "agents-get-agent-async" "agents-put-agent" "agents-get-agent-activity-run" "agents-put-agent-activity-run" "agents-put-agent-status" "job-runs-get-job-runs" "job-runs-post-job-run" "job-runs-delete-job-run" "job-runs-get-job-run" "job-runs-put-job-run" "jobs-get-jobs" "jobs-post-job" "jobs-delete-job" "jobs-get-job" "jobs-put-job" "steps-get-steps" "steps-post-step" "steps-get-step" "steps-put-step" "commands"] | sort) } | get name | first)
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

# No Documentation Found.
#
# GET /api/v2/AftermarketServices/Certificates
# Returns: record
# operationId: AftermarketServices_GetCerts
export def "aftermarket-services-get-certs" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/api/v2/AftermarketServices/Certificates"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Activate or Deactivate an ECU, or Report an ECU as Damaged.
#
# PUT /api/v2/AftermarketServices/ECUs/{serialNumber}
# Returns: record<ActivationCode: string, DamagedDescription: string, EngineSerialNumber: string, ReplacesECUSerialNumber: string, SerialNumber: string, State: string>
# operationId: AftermarketServices_PutECU
export def "aftermarket-services-put-ecu" [
  serial_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --edt-instance-id: string # The EDT Instance Id of the kit calling this method. (required)
  --activation-code: string # The code used to activate the ECU. May not be modified. Returned only on activation. (format: byte)
  --damaged-description: string # A description why the ECU cannot be deactivated.
  engine_serial_number: string # The serial number of the ECU’s engine
  --replaces-ecu-serial-number: string # The serial number of the ECU that this ECU replaces. Required if activating an ECU..
  --body-serial-number: string # The serial number of the ECU (spec name: SerialNumber)
  state: string@state-completer # The state of the ECU
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v2/AftermarketServices/ECUs/{serialNumber}"
    path_params: [{name: serialNumber, var: serial_number}]
    query: [{name: EDTInstanceId, var: edt_instance_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: ActivationCode, var: activation_code}, {name: DamagedDescription, var: damaged_description}, {name: EngineSerialNumber, var: engine_serial_number}, {name: ReplacesECUSerialNumber, var: replaces_ecu_serial_number}, {name: SerialNumber, var: body_serial_number, required: true}, {name: State, var: state}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    serial_number: $serial_number, edt_instance_id: $edt_instance_id, activation_code: $activation_code, damaged_description: $damaged_description, engine_serial_number: $engine_serial_number, replaces_ecu_serial_number: $replaces_ecu_serial_number, body_serial_number: $body_serial_number, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get injector codes given engine.
#
# GET /api/v2/AftermarketServices/Engines/{serialNumber}/IQACodes
# Returns: list<string>
# operationId: AftermarketServices_GetEngineIQACodes
export def "aftermarket-services-get-engine-iqa-codes" [
  serial_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --edt-instance-id: string # The EDT Instance Id of the kit calling this method. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/AftermarketServices/Engines/{serialNumber}/IQACodes"
    path_params: [{name: serialNumber, var: serial_number}]
    query: [{name: EDTInstanceId, var: edt_instance_id, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    serial_number: $serial_number, edt_instance_id: $edt_instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Report the IQA codes used by an engine
#
# PUT /api/v2/AftermarketServices/Engines/{serialNumber}/IQACodes
# Returns: bool
# operationId: AftermarketServices_PutIQACodes
export def "aftermarket-services-put-iqa-codes" [
  serial_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --edt-instance-id: string # The EDT Instance Id of the kit calling this method. (required)
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/AftermarketServices/Engines/{serialNumber}/IQACodes"
    path_params: [{name: serialNumber, var: serial_number}]
    query: [{name: EDTInstanceId, var: edt_instance_id, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    serial_number: $serial_number, edt_instance_id: $edt_instance_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get production calibration data for given engine.
#
# GET /api/v2/AftermarketServices/Engines/{serialNumber}/ProductionData
# Returns: table<DataType: string, DataValues: string>
# operationId: AftermarketServices_GetProductionData
export def "aftermarket-services-get-production-data" [
  serial_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --edt-instance-id: string # The EDT Instance Id of the kit calling this method. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/AftermarketServices/Engines/{serialNumber}/ProductionData"
    path_params: [{name: serialNumber, var: serial_number}]
    query: [{name: EDTInstanceId, var: edt_instance_id, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    serial_number: $serial_number, edt_instance_id: $edt_instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Check whether there is connectivity to AGCO Power Web Services
#
# GET /api/v2/AftermarketServices/Hello
# Returns: bool
# operationId: AftermarketServices_GetConnectionStatus
export def "aftermarket-services-get-connection-status" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/api/v2/AftermarketServices/Hello"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve the status of an EDT Kit Registration with AGCO Power Web Services
#
# GET /api/v2/AftermarketServices/UserStatuses
# Returns: record<DealerCode: string, State: string, VoucherCode: string>
# operationId: AftermarketServices_GetUserStatus
export def "aftermarket-services-get-user-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --voucher-code: string # required
  --dealer-code: string # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/AftermarketServices/UserStatuses"
    query: [{name: voucherCode, var: voucher_code, required: true}, {name: dealerCode, var: dealer_code, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    voucher_code: $voucher_code, dealer_code: $dealer_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update the status of an EDT Kit Registration with AGCO Power Web Services
#
# PUT /api/v2/AftermarketServices/UserStatuses
# Returns: bool
# operationId: AftermarketServices_UpdateUserStatus
export def "aftermarket-services-update-user-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  dealer_code: string # The dealer code of the voucher
  --state: string@state-completer-1 # The state of the voucher
  voucher_code: string # The voucher code
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/AftermarketServices/UserStatuses"
    body: {content_type: "application/json", kind: json, fields: [{name: DealerCode, var: dealer_code}, {name: State, var: state}, {name: VoucherCode, var: voucher_code}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    dealer_code: $dealer_code, state: $state, voucher_code: $voucher_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Manage API tokens.
#
# PUT /api/v2/AuthenticatedUsers/{UserID}/Tokens
# operationId: Authentication_PutManageTokens
export def "authentication-put-manage-tokens" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bearer-action: string@bearer-action-completer # The action to perform on the bearer token. Optional. Defaults to ‘None’.
  --mac-action: string@mac-action-completer # The action to perform on the MAC token. Optional. Defaults to ‘None’.
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/AuthenticatedUsers/{UserID}/Tokens"
    path_params: [{name: UserID, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: BearerAction, var: bearer_action}, {name: MACAction, var: mac_action}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, bearer_action: $bearer_action, mac_action: $mac_action
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Authenticate a user.
#
# POST /api/v2/Authentication
# Returns: record<Email: string, MACId: string, MACToken: string, Name: string, Token: string, UserID: int, Username: string>
# operationId: Authentication_Default
export def "authentication-default" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --bearer-action: string@bearer-action-completer # The action to perform on the bearer token. Optional. Defaults to ‘None’.
  --mac-action: string@mac-action-completer # The action to perform on the MAC token. Optional. Defaults to ‘None’.
  password: string # A secret word or phrase that must be used to gain admission
  username: string # A unique ID a user needs to login with
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v2/Authentication"
    body: {content_type: "application/json", kind: json, fields: [{name: BearerAction, var: bearer_action}, {name: MACAction, var: mac_action}, {name: password, var: password}, {name: username, var: username}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    bearer_action: $bearer_action, mac_action: $mac_action, password: $password, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Acknowledges the connection to the API
#
# GET /api/v2/Authentication/IsAlive
# operationId: Authentication_IsAlive
export def "authentication-is-alive" [
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
    path: "/api/v2/Authentication/IsAlive"
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request a password reset.
#
# POST /api/v2/Authentication/RequestPasswordReset
# operationId: Authentication_RequestPasswordReset
export def "authentication-request-password-reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  parameter_name: string # The query string parameter name to use for supplying the password reset token
  url: string # The URL to direct the user to reset the password.
  username: string # The username to reset the password for
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/Authentication/RequestPasswordReset"
    body: {content_type: "application/json", kind: json, fields: [{name: ParameterName, var: parameter_name}, {name: Url, var: url}, {name: Username, var: username}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    parameter_name: $parameter_name, url: $url, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset a password
#
# POST /api/v2/Authentication/ResetPasword
# operationId: Authentication_ResetPasword
export def "authentication-reset-pasword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  new_password: string # The new password
  --body-token: string # The password reset token (spec name: Token)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/Authentication/ResetPasword"
    body: {content_type: "application/json", kind: json, fields: [{name: NewPassword, var: new_password}, {name: Token, var: body_token, required: true}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    new_password: $new_password, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get authorization categories.
#
# GET /api/v2/AuthorizationCategories
# Returns: record<Entities: table<Description: string, ID: string, Name: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: AuthorizationCategories_Get
export def "authorization-categories-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
  --user-id: int # Optional. Filter by categories visible to the provided user with the provided userID. (format: int32)
  --definition-id: string # Optional. Filter by categories containing a definition with the provided ID.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/AuthorizationCategories"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: userID, var: user_id}, {name: definitionID, var: definition_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, user_id: $user_id, definition_id: $definition_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add an authorization category.
#
# POST /api/v2/AuthorizationCategories
# Returns: string
# operationId: AuthorizationCategories_Post
export def "authorization-categories-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # A description of the Category.
  --id: string # The ID of the Category.
  --name: string # The Name of the Category.
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/AuthorizationCategories"
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: ID, var: id}, {name: Name, var: name}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    description: $description, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a report of access that users have to Authorization Categories.
#
# GET /api/v2/AuthorizationCategories/Users
# Returns: record<Entities: table<Categories: list, User: record>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: AuthorizationCategories_GetUsers
export def "authorization-categories-get-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: int # Optional. Defaults to 10. (format: int32)
  --offset: int # Optional. Defaults to 0. (format: int32)
  --user-i-ds: string # Optional. Includes only users with IDs on the provided comma-separated list.
  --category-i-ds: string # Optional. Includes only users with categories with IDs on the provided comma-separated list.
  --include-categories: oneof<nothing, bool> # If true, include full Authorization Category detail. Defaults to false.
  --include-users: oneof<nothing, bool> # If true, include full User detail. Defaults to false.
  --user-search: string # Optional. Includes only users with a Name, Username, or Email containing the provided value.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/AuthorizationCategories/Users"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: userIDs, var: user_i_ds}, {name: categoryIDs, var: category_i_ds}, {name: includeCategories, var: include_categories}, {name: includeUsers, var: include_users}, {name: userSearch, var: user_search}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, user_i_ds: $user_i_ds, category_i_ds: $category_i_ds, include_categories: $include_categories, include_users: $include_users, user_search: $user_search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove an authorization category.
#
# DELETE /api/v2/AuthorizationCategories/{id}
# operationId: AuthorizationCategories_Delete
export def "authorization-categories-delete" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v2/AuthorizationCategories/{id}"
    path_params: [{name: id, var: id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an authorization category.
#
# PUT /api/v2/AuthorizationCategories/{id}
# operationId: AuthorizationCategories_Put
export def "authorization-categories-put" [
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
  --description: string # A description of the Category.
  --body-id: string # The ID of the Category. (spec name: ID)
  --name: string # The Name of the Category.
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/AuthorizationCategories/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: ID, var: body_id}, {name: Name, var: name}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id, description: $description, body_id: $body_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a category a user could see.
#
# DELETE /api/v2/AuthorizationCategories/{id}/Users/{userID}
# operationId: AuthorizationCategories_RemoveUser
export def "authorization-categories-remove-user" [
  id: string
  user_id: int
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
    path: "/api/v2/AuthorizationCategories/{id}/Users/{userID}"
    path_params: [{name: id, var: id}, {name: userID, var: user_id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a category that a user can see.
#
# POST /api/v2/AuthorizationCategories/{id}/Users/{userID}
# operationId: AuthorizationCategories_AddUser
export def "authorization-categories-add-user" [
  id: string
  user_id: int
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
    path: "/api/v2/AuthorizationCategories/{id}/Users/{userID}"
    path_params: [{name: id, var: id}, {name: userID, var: user_id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get authorization code definitions.
#
# GET /api/v2/AuthorizationCodeDefinitions
# Returns: record<Entities: table<AuthorizationID: string, CreatedByUserID: int, CreatedDate: string, DataFields: list, DeletedByUserID: int, DeletedDate: string, Description: string, DurationAccuracy: int, DurationAmount: int, DurationUnits: string, HashLength: int, ID: string, IsDeleted: bool, Name: string, RandomLength: int, ValidationFields: list>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: AuthorizationCodeDefinitions_GetAuthorizationCodeDefinition
export def "authorization-code-definitions-get-authorization-code-definition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
  --name: string # Optional. If specified, filters definitions by name. Starting and ending wildcards (*) supported.
  --created-by-user-id: int # Optional. If specified, filters definitions to those created by the given User ID. (format: int32)
  --deleted-by-user-id: int # Optional. If specified, filters definitions to those deleted by the given User ID. (format: int32)
  --include-deleted: oneof<nothing, bool> # Optional. Whether to include deleted definitions. 'False' by default.
  --category-id: string # Optional. If specified, filters definitions with the designated categoryID.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/AuthorizationCodeDefinitions"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: name, var: name}, {name: createdByUserID, var: created_by_user_id}, {name: deletedByUserID, var: deleted_by_user_id}, {name: includeDeleted, var: include_deleted}, {name: categoryID, var: category_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, name: $name, created_by_user_id: $created_by_user_id, deleted_by_user_id: $deleted_by_user_id, include_deleted: $include_deleted, category_id: $category_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add an authorization code definition.
#
# POST /api/v2/AuthorizationCodeDefinitions
# Returns: string
# operationId: AuthorizationCodeDefinitions_PostAuthorizationCodeDefinition
export def "authorization-code-definitions-post-authorization-code-definition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --authorization-id: string # The value used for securing codes generated.
  --created-by-user-id: int # The ID of the user that created this definition. Read only. (format: int32)
  --created-date: string # A timestamp of when this definition was created. Read only. (format: date-time)
  --data-fields: list # The defined fields to include in authorization codes generated from this definition. May not be updated. — item shape: {DigitsPrecision?: int, MaxExponent?: int, MaxValue?: float, MinExponent?: int, MinValue?: float, Name: string, ScaleFactor?: float, Signed?: bool, Type: "Boolean"|"Decimal"|"Float"|"VariableLengthByteArray"}
  --deleted-by-user-id: int # The ID of the user that deleted this definition. Read only. (format: int32)
  --deleted-date: string # A timestamp of when this definition was deleted. Read only. (format: date-time)
  --description: string # A description of this definition. May not be updated.
  --duration-accuracy: int # The number of bits used for timestamp verification. Defaults to 5. May not be updated. (format: int32)
  --duration-amount: int # The amount of duration for the specified duration unit used to calculate the Authorization Code. Defaults to 1. May not be updated. (format: int32)
  --duration-units: string@duration-units-completer # The units of duration used to calculate the Authorization Code. Defaults to 'Days'. May not be updated.
  --hash-length: int # The bit length of the hash data which will be used for the authorization code. Defaults to 20. May not be updated. (format: int32)
  --id: string # The ID of the authorization code definition. Read only.
  --is-deleted: oneof<nothing, bool> # Indicates whether this definition is enabled. True if generating codes is disabled.
  name: string # The name of the authorization code definition. May not be updated.
  --random-length: int # The bit length of random data which will be included in the authorization code. This is necessary to allow creation of "identical" authorization codes containing the same timestamp. Defaults to 5. May not be updated. (format: int32)
  --validation-fields: list # The defined fields to verify when reading authorization codes generated from this definition. May not be updated. — item shape: {Name: string, Type: "Boolean"|"Float"|"Int"|"StringCaseInsensitive"|"StringCaseSensitive"}
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/AuthorizationCodeDefinitions"
    body: {content_type: "application/json", kind: json, fields: [{name: AuthorizationID, var: authorization_id}, {name: CreatedByUserID, var: created_by_user_id}, {name: CreatedDate, var: created_date}, {name: DataFields, var: data_fields}, {name: DeletedByUserID, var: deleted_by_user_id}, {name: DeletedDate, var: deleted_date}, {name: Description, var: description}, {name: DurationAccuracy, var: duration_accuracy}, {name: DurationAmount, var: duration_amount}, {name: DurationUnits, var: duration_units}, {name: HashLength, var: hash_length}, {name: ID, var: id}, {name: IsDeleted, var: is_deleted}, {name: Name, var: name}, {name: RandomLength, var: random_length}, {name: ValidationFields, var: validation_fields}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    authorization_id: $authorization_id, created_by_user_id: $created_by_user_id, created_date: $created_date, data_fields: $data_fields, deleted_by_user_id: $deleted_by_user_id, deleted_date: $deleted_date, description: $description, duration_accuracy: $duration_accuracy, duration_amount: $duration_amount, duration_units: $duration_units, hash_length: $hash_length, id: $id, is_deleted: $is_deleted, name: $name, random_length: $random_length, validation_fields: $validation_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Deletes the category from the authorization code definition.
#
# DELETE /api/v2/AuthorizationCodeDefinitions/{ID}/Categories/{categoryID}
# operationId: AuthorizationCodeDefinitions_RemoveCategoryFromDefinition
export def "authorization-code-definitions-remove-category-from-definition" [
  id: string
  category_id: string
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
    path: "/api/v2/AuthorizationCodeDefinitions/{ID}/Categories/{categoryID}"
    path_params: [{name: ID, var: id}, {name: categoryID, var: category_id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id, category_id: $category_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a category to an authorizationCodeDefintion.
#
# POST /api/v2/AuthorizationCodeDefinitions/{ID}/Categories/{categoryID}
# operationId: AuthorizationCodeDefinitions_AddCategoryToDefinition
export def "authorization-code-definitions-add-category-to-definition" [
  id: string
  category_id: string
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
    path: "/api/v2/AuthorizationCodeDefinitions/{ID}/Categories/{categoryID}"
    path_params: [{name: ID, var: id}, {name: categoryID, var: category_id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id, category_id: $category_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable an authorization code definition
#
# DELETE /api/v2/AuthorizationCodeDefinitions/{id}
# operationId: AuthorizationCodeDefinitions_DeleteAuthorizationCodeDefinition
export def "authorization-code-definitions-delete-authorization-code-definition" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v2/AuthorizationCodeDefinitions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an authorization code definition by its ID
#
# GET /api/v2/AuthorizationCodeDefinitions/{id}
# Returns: record<AuthorizationID: string, CreatedByUserID: int, CreatedDate: string, DataFields: table<DigitsPrecision: int, MaxExponent: int, MaxValue: float, MinExponent: int, MinValue: float, Name: string, ScaleFactor: float, Signed: bool, Type: string>, DeletedByUserID: int, DeletedDate: string, Description: string, DurationAccuracy: int, DurationAmount: int, DurationUnits: string, HashLength: int, ID: string, IsDeleted: bool, Name: string, RandomLength: int, ValidationFields: table<Name: string, Type: string>>
export def "get-api-v2-authorization-code-definitions-id" [
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
    path: "/api/v2/AuthorizationCodeDefinitions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update an authorization code definition
#
# PUT /api/v2/AuthorizationCodeDefinitions/{id}
# operationId: AuthorizationCodeDefinitions_PutAuthorizationCodeDefinition
export def "authorization-code-definitions-put-authorization-code-definition" [
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
  --authorization-id: string # The value used for securing codes generated.
  --created-by-user-id: int # The ID of the user that created this definition. Read only. (format: int32)
  --created-date: string # A timestamp of when this definition was created. Read only. (format: date-time)
  --data-fields: list # The defined fields to include in authorization codes generated from this definition. May not be updated. — item shape: {DigitsPrecision?: int, MaxExponent?: int, MaxValue?: float, MinExponent?: int, MinValue?: float, Name: string, ScaleFactor?: float, Signed?: bool, Type: "Boolean"|"Decimal"|"Float"|"VariableLengthByteArray"}
  --deleted-by-user-id: int # The ID of the user that deleted this definition. Read only. (format: int32)
  --deleted-date: string # A timestamp of when this definition was deleted. Read only. (format: date-time)
  --description: string # A description of this definition. May not be updated.
  --duration-accuracy: int # The number of bits used for timestamp verification. Defaults to 5. May not be updated. (format: int32)
  --duration-amount: int # The amount of duration for the specified duration unit used to calculate the Authorization Code. Defaults to 1. May not be updated. (format: int32)
  --duration-units: string@duration-units-completer # The units of duration used to calculate the Authorization Code. Defaults to 'Days'. May not be updated.
  --hash-length: int # The bit length of the hash data which will be used for the authorization code. Defaults to 20. May not be updated. (format: int32)
  --body-id: string # The ID of the authorization code definition. Read only. (spec name: ID)
  --is-deleted: oneof<nothing, bool> # Indicates whether this definition is enabled. True if generating codes is disabled.
  name: string # The name of the authorization code definition. May not be updated.
  --random-length: int # The bit length of random data which will be included in the authorization code. This is necessary to allow creation of "identical" authorization codes containing the same timestamp. Defaults to 5. May not be updated. (format: int32)
  --validation-fields: list # The defined fields to verify when reading authorization codes generated from this definition. May not be updated. — item shape: {Name: string, Type: "Boolean"|"Float"|"Int"|"StringCaseInsensitive"|"StringCaseSensitive"}
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/AuthorizationCodeDefinitions/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: AuthorizationID, var: authorization_id}, {name: CreatedByUserID, var: created_by_user_id}, {name: CreatedDate, var: created_date}, {name: DataFields, var: data_fields}, {name: DeletedByUserID, var: deleted_by_user_id}, {name: DeletedDate, var: deleted_date}, {name: Description, var: description}, {name: DurationAccuracy, var: duration_accuracy}, {name: DurationAmount, var: duration_amount}, {name: DurationUnits, var: duration_units}, {name: HashLength, var: hash_length}, {name: ID, var: body_id}, {name: IsDeleted, var: is_deleted}, {name: Name, var: name}, {name: RandomLength, var: random_length}, {name: ValidationFields, var: validation_fields}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id, authorization_id: $authorization_id, created_by_user_id: $created_by_user_id, created_date: $created_date, data_fields: $data_fields, deleted_by_user_id: $deleted_by_user_id, deleted_date: $deleted_date, description: $description, duration_accuracy: $duration_accuracy, duration_amount: $duration_amount, duration_units: $duration_units, hash_length: $hash_length, body_id: $body_id, is_deleted: $is_deleted, name: $name, random_length: $random_length, validation_fields: $validation_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get authorization codes.
#
# GET /api/v2/AuthorizationCodes
# Returns: record<Entities: table<Code: string, CreatedByUserID: int, CreatedDate: string, DataParameters: list, DefinitionID: string, DeletedByUserID: int, DeletedDate: string, EffectiveDate: string, ID: int, IsDeleted: bool, ValidationParameters: list>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: AuthorizationCodes_GetAuthorizationCodes
export def "authorization-codes-get-authorization-codes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --code: string # Optional. If provided, searches for entities with the provided authorization code.
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
  --definition-id: string # Optional. If specified, filters codes by definition id.
  --created-by-user-id: int # Optional. If specified, filters codes to those created by the given User ID. (format: int32)
  --deleted-by-user-id: int # Optional. If specified, filters codes to those deleted by the given User ID. (format: int32)
  --include-deleted: oneof<nothing, bool> # Optional. Whether to include deleted codes. 'False' by default.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/AuthorizationCodes"
    query: [{name: code, var: code}, {name: limit, var: limit}, {name: offset, var: offset}, {name: definitionID, var: definition_id}, {name: createdByUserID, var: created_by_user_id}, {name: deletedByUserID, var: deleted_by_user_id}, {name: includeDeleted, var: include_deleted}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    code: $code, limit: $limit, offset: $offset, definition_id: $definition_id, created_by_user_id: $created_by_user_id, deleted_by_user_id: $deleted_by_user_id, include_deleted: $include_deleted
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Generates an authorization code using the provided definition and parameters.
#
# POST /api/v2/AuthorizationCodes
# Returns: int
# operationId: AuthorizationCodes_PostAuthorizationCode
export def "authorization-codes-post-authorization-code" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --code: string # The code to enter to unlock a feature. Read only.
  --created-by-user-id: int # The ID of the user that created this authorization code. Read only. (format: int32)
  --created-date: string # A timestamp of when this code was created. Read only. (format: date-time)
  --data-parameters: list # The parameters and values contained as data in this authorization code. May not be updated. — item shape: {Name: string, Value: string}
  --definition-id: string # The id of the definition for this authorization code. May not be updated.
  --deleted-by-user-id: int # The ID of the user that deleted this authorization code. Read only. (format: int32)
  --deleted-date: string # A timestamp of when this authorization code was deleted. Read only. (format: date-time)
  --effective-date: string # A date at which this code should begin being valid. Optional. Set on create only. (format: date-time)
  --id: int # The identifier for the authorization code. Read only. (format: int32)
  --is-deleted: oneof<nothing, bool> # Indicates whether this code is deleted.
  --validation-parameters: list # The parameters and values used to validate this authorization code. May not be updated. — item shape: {Name: string, Value: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/AuthorizationCodes"
    body: {content_type: "application/json", kind: json, fields: [{name: Code, var: code}, {name: CreatedByUserID, var: created_by_user_id}, {name: CreatedDate, var: created_date}, {name: DataParameters, var: data_parameters}, {name: DefinitionID, var: definition_id}, {name: DeletedByUserID, var: deleted_by_user_id}, {name: DeletedDate, var: deleted_date}, {name: EffectiveDate, var: effective_date}, {name: ID, var: id}, {name: IsDeleted, var: is_deleted}, {name: ValidationParameters, var: validation_parameters}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    code: $code, created_by_user_id: $created_by_user_id, created_date: $created_date, data_parameters: $data_parameters, definition_id: $definition_id, deleted_by_user_id: $deleted_by_user_id, deleted_date: $deleted_date, effective_date: $effective_date, id: $id, is_deleted: $is_deleted, validation_parameters: $validation_parameters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Hide an authorization code.
#
# DELETE /api/v2/AuthorizationCodes/{id}
# operationId: AuthorizationCodes_DeleteAuthorizationCode
export def "authorization-codes-delete-authorization-code" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v2/AuthorizationCodes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an authorization code by its ID.
#
# GET /api/v2/AuthorizationCodes/{id}
# Returns: record<Code: string, CreatedByUserID: int, CreatedDate: string, DataParameters: table<Name: string, Value: string>, DefinitionID: string, DeletedByUserID: int, DeletedDate: string, EffectiveDate: string, ID: int, IsDeleted: bool, ValidationParameters: table<Name: string, Value: string>>
# operationId: AuthorizationCodes_GetAuthorizationCode
export def "authorization-codes-get-authorization-code" [
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
    path: "/api/v2/AuthorizationCodes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update an authorization code.
#
# PUT /api/v2/AuthorizationCodes/{id}
# operationId: AuthorizationCodes_PutAuthorizationCode
export def "authorization-codes-put-authorization-code" [
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
  --code: string # The code to enter to unlock a feature. Read only.
  --created-by-user-id: int # The ID of the user that created this authorization code. Read only. (format: int32)
  --created-date: string # A timestamp of when this code was created. Read only. (format: date-time)
  --data-parameters: list # The parameters and values contained as data in this authorization code. May not be updated. — item shape: {Name: string, Value: string}
  --definition-id: string # The id of the definition for this authorization code. May not be updated.
  --deleted-by-user-id: int # The ID of the user that deleted this authorization code. Read only. (format: int32)
  --deleted-date: string # A timestamp of when this authorization code was deleted. Read only. (format: date-time)
  --effective-date: string # A date at which this code should begin being valid. Optional. Set on create only. (format: date-time)
  --body-id: int # The identifier for the authorization code. Read only. (format: int32) (spec name: ID)
  --is-deleted: oneof<nothing, bool> # Indicates whether this code is deleted.
  --validation-parameters: list # The parameters and values used to validate this authorization code. May not be updated. — item shape: {Name: string, Value: string}
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/AuthorizationCodes/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Code, var: code}, {name: CreatedByUserID, var: created_by_user_id}, {name: CreatedDate, var: created_date}, {name: DataParameters, var: data_parameters}, {name: DefinitionID, var: definition_id}, {name: DeletedByUserID, var: deleted_by_user_id}, {name: DeletedDate, var: deleted_date}, {name: EffectiveDate, var: effective_date}, {name: ID, var: body_id}, {name: IsDeleted, var: is_deleted}, {name: ValidationParameters, var: validation_parameters}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id, code: $code, created_by_user_id: $created_by_user_id, created_date: $created_date, data_parameters: $data_parameters, definition_id: $definition_id, deleted_by_user_id: $deleted_by_user_id, deleted_date: $deleted_date, effective_date: $effective_date, body_id: $body_id, is_deleted: $is_deleted, validation_parameters: $validation_parameters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get contact information for an authorization code.
#
# GET /api/v2/AuthorizationCodes/{id}/ContactInformation
# Returns: record<AuthorizationCodeID: int, Code: string, Contact: string, CreatedBy: string, CreatedDate: string, DealerCode: string, Dealership: string, DefinitionName: string, Email: string, ID: int, Notes: string, Phone: string>
# operationId: AuthorizationCodes_GetContactInformation
export def "authorization-codes-get-contact-information" [
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
    path: "/api/v2/AuthorizationCodes/{id}/ContactInformation"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# No Documentation Found.
#
# GET /api/v2/AuthorizationCodes/{id}/Validate
# Returns: record<ExpirationDate: string, IsValid: bool>
# operationId: AuthorizationCodes_ValidateAuthorizationCode
export def "authorization-codes-validate-authorization-code" [
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
    path: "/api/v2/AuthorizationCodes/{id}/Validate"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get contact information for authorization codes.
#
# GET /api/v2/AuthorizationContactInformation
# Returns: record<Entities: table<AuthorizationCodeID: int, Code: string, Contact: string, CreatedBy: string, CreatedDate: string, DealerCode: string, Dealership: string, DefinitionName: string, Email: string, ID: int, Notes: string, Phone: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: AuthorizationContactInformation_Get
export def "authorization-contact-information-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
  --authorization-code: string # Optional. Search by authorization code.
  --after-date: string # Optional. Include only data for authorization codes created after a provided date. (format: date-time)
  --before-date: string # Optional. Include only data for authorization codes created before a provided date. (format: date-time)
  --dealer-code: string # Optional. Search by dealer code.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/AuthorizationContactInformation"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: authorizationCode, var: authorization_code}, {name: afterDate, var: after_date}, {name: beforeDate, var: before_date}, {name: dealerCode, var: dealer_code}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, authorization_code: $authorization_code, after_date: $after_date, before_date: $before_date, dealer_code: $dealer_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add contact information for authorization code.
#
# POST /api/v2/AuthorizationContactInformation
# Returns: int
# operationId: AuthorizationContactInformation_Post
export def "authorization-contact-information-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  authorization_code_id: int # AuthorizationCode ID that the contact information ties into. (format: int32)
  --code: string # The authorization code. Read Only.
  contact: string # Name of contact requesting an authorization code. Minimum length of 3 characters.
  --created-by: string # The name of the user that created this code. Read Only.
  --created-date: string # The date the authorization code was created. (format: date-time)
  dealer_code: string # Dealer code that relates to the dealership. Minimum length of 3 characters.
  dealership: string # Name of dealership. Minimum length of 3 characters.
  --definition-name: string # The name of the definition used for generating this authorization code. Read Only.
  --email: string # Email of contact.
  --id: int # ID of authorizationContactInformation (format: int32)
  --notes: string # Optional notes used for internal use.
  phone: string # Phone number of contact.
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/AuthorizationContactInformation"
    body: {content_type: "application/json", kind: json, fields: [{name: AuthorizationCodeID, var: authorization_code_id}, {name: Code, var: code}, {name: Contact, var: contact}, {name: CreatedBy, var: created_by}, {name: CreatedDate, var: created_date}, {name: DealerCode, var: dealer_code}, {name: Dealership, var: dealership}, {name: DefinitionName, var: definition_name}, {name: Email, var: email}, {name: ID, var: id}, {name: Notes, var: notes}, {name: Phone, var: phone}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    authorization_code_id: $authorization_code_id, code: $code, contact: $contact, created_by: $created_by, created_date: $created_date, dealer_code: $dealer_code, dealership: $dealership, definition_name: $definition_name, email: $email, id: $id, notes: $notes, phone: $phone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a list of Brands.
#
# GET /api/v2/Brands
# Returns: list<string>
# operationId: Brands_Brands
export def "brands-brands" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/api/v2/Brands"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the list of bundles.
#
# GET /api/v2/Bundles
# Returns: record<Entities: table<Active: bool, BundleID: string, BundleNumber: int, Description: string, UpdateGroupID: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: Bundles_GetBundles
export def "bundles-get-bundles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --update-group-id: string # Optional. Filter by UpdateGroup ID.
  --active: oneof<nothing, bool> # Optional. Filter by active status.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
  --bundle-number: int # Optional. If provided, filters by BundleNumber. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Bundles"
    query: [{name: UpdateGroupID, var: update_group_id}, {name: Active, var: active}, {name: limit, var: limit}, {name: offset, var: offset}, {name: BundleNumber, var: bundle_number}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    update_group_id: $update_group_id, active: $active, limit: $limit, offset: $offset, bundle_number: $bundle_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a Bundle to the Update System.
#
# POST /api/v2/Bundles
# Returns: string
# operationId: Bundles_PostBundle
export def "bundles-post-bundle" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --active: oneof<nothing, bool> # Default Value: false. During the creation of the Bundle, this field must be false.
  --bundle-id: string # Read-Only.
  bundle_number: int # The bundle number (format: int32)
  description: string # The Bundle description.
  update_group_id: string # The update group this bundle belongs to.
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/Bundles"
    body: {content_type: "application/json", kind: json, fields: [{name: Active, var: active}, {name: BundleID, var: bundle_id}, {name: BundleNumber, var: bundle_number}, {name: Description, var: description}, {name: UpdateGroupID, var: update_group_id}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    active: $active, bundle_id: $bundle_id, bundle_number: $bundle_number, description: $description, update_group_id: $update_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a Bundle.
#
# DELETE /api/v2/Bundles/{ID}
# operationId: Bundles_DeleteBundle
export def "bundles-delete-bundle" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v2/Bundles/{ID}"
    path_params: [{name: ID, var: id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific Bundle by ID.
#
# GET /api/v2/Bundles/{ID}
# Returns: record<Active: bool, BundleID: string, BundleNumber: int, Description: string, UpdateGroupID: string>
# operationId: Bundles_GetBundle
export def "bundles-get-bundle" [
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
    path: "/api/v2/Bundles/{ID}"
    path_params: [{name: ID, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Modify a Bundle in the Update System.
#
# PUT /api/v2/Bundles/{ID}
# operationId: Bundles_PutBundle
export def "bundles-put-bundle" [
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
  --active: oneof<nothing, bool> # Default Value: false. During the creation of the Bundle, this field must be false.
  --bundle-id: string # Read-Only.
  bundle_number: int # The bundle number (format: int32)
  description: string # The Bundle description.
  update_group_id: string # The update group this bundle belongs to.
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/Bundles/{ID}"
    path_params: [{name: ID, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Active, var: active}, {name: BundleID, var: bundle_id}, {name: BundleNumber, var: bundle_number}, {name: Description, var: description}, {name: UpdateGroupID, var: update_group_id}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id, active: $active, bundle_id: $bundle_id, bundle_number: $bundle_number, description: $description, update_group_id: $update_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a List of Clients in the Update System.
#
# GET /api/v2/Clients
# Returns: record<Entities: table<ClientID: string, LastCheckin: string, Tag: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: Clients_Get
export def "clients-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --tag: string # Optional. Filter clients by Tag. Wildcards are supported (*).
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Clients"
    query: [{name: Tag, var: tag}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    tag: $tag, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a list of Cached Files installed on the client Machine.
#
# GET /api/v2/Clients/{ClientID}/CachedFiles
# Returns: list<string>
# operationId: UpdateSystem_GetCachedFiles
export def "update-system-get-cached-files" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --expired: oneof<nothing, bool> # Only Expired Files (true|false) (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Clients/{ClientID}/CachedFiles"
    path_params: [{name: ClientID, var: client_id}]
    query: [{name: Expired, var: expired, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, expired: $expired
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the package reports for a client.
#
# GET /api/v2/Clients/{ClientID}/PackageReports
# Returns: table<Categories: list<record>, PackageDescription: string, PackageID: string>
# operationId: PackageReports_Default
export def "package-reports-default" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/api/v2/Clients/{ClientID}/PackageReports"
    path_params: [{name: ClientID, var: client_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Submit a package report
#
# PUT /api/v2/Clients/{ClientID}/PackageReports
export def "put-api-v2-clients-client-id-package-reports" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --categories: list # The package report's categories. — item shape: {Values?: list, category: string}
  --package-description: string # Read Only. The package description
  --package-id: string # The PackageID.
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/Clients/{ClientID}/PackageReports"
    path_params: [{name: ClientID, var: client_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Categories, var: categories}, {name: PackageDescription, var: package_description}, {name: PackageID, var: package_id}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    client_id: $client_id, categories: $categories, package_description: $package_description, package_id: $package_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit a batch of package reports
#
# PUT /api/v2/Clients/{ClientID}/PackageReports/Batch
# operationId: PackageReports_Batch
export def "package-reports-batch" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/Clients/{ClientID}/PackageReports/Batch"
    path_params: [{name: ClientID, var: client_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    client_id: $client_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Client in the Update System.
#
# GET /api/v2/Clients/{ID}
# Returns: record<ClientID: string, LastCheckin: string, Tag: string>
export def "get-api-v2-clients-id" [
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
    path: "/api/v2/Clients/{ID}"
    path_params: [{name: ID, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a Client.
#
# PUT /api/v2/Clients/{ID}
# operationId: Clients_Put
export def "clients-put" [
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
  --client-id: string # Read Only. The id of the client
  --last-checkin: string # Read Only. The time of the client's last checkin with the server. (format: date-time)
  --tag: string # A description of the client that can be used for easy reference
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/Clients/{ID}"
    path_params: [{name: ID, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientID, var: client_id}, {name: LastCheckin, var: last_checkin}, {name: Tag, var: tag}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id, client_id: $client_id, last_checkin: $last_checkin, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Client's Available Update Group Subscriptions
#
# GET /api/v2/Clients/{ID}/AvailableUpdateGroupSubscriptions
# Returns: record<Entities: table<AvailableSubscriptions: list, UpdateGroup: record>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: Clients_GetAvailableSubscriptions
export def "clients-get-available-subscriptions" [
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
  --accept: string@accept-completer-1 # Response content type
  --update-group-id: string # Optional. Filter by Update Group.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Clients/{ID}/AvailableUpdateGroupSubscriptions"
    path_params: [{name: ID, var: id}]
    query: [{name: UpdateGroupID, var: update_group_id}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, update_group_id: $update_group_id, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a Client's Current Update Group Subscriptions
#
# GET /api/v2/Clients/{ID}/UpdateGroupSubscriptions
# Returns: record<Entities: table<ClientID: string, Include: bool, PackageTypeID: string, UpdateGroupID: string, UpdateGroupSubscriptionID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: Clients_GetSubscriptions
export def "clients-get-subscriptions" [
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
  --accept: string@accept-completer-1 # Response content type
  --update-group-id: string # Optional. Filter by Update Group.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Clients/{ID}/UpdateGroupSubscriptions"
    path_params: [{name: ID, var: id}]
    query: [{name: UpdateGroupID, var: update_group_id}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, update_group_id: $update_group_id, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# No Documentation Found.
#
# PUT /api/v2/ContentDefinitionAttributes/Batch
# operationId: ContentDefinitions_PutContentDefinitionAttributes
export def "content-definitions-put-content-definition-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/ContentDefinitionAttributes/Batch"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an Attribute from a ContentDefinition
#
# DELETE /api/v2/ContentDefinitionAttributes/{contentDefinitionAttributeID}
# operationId: ContentDefinitions_DeleteContentDefinitionAttribute
export def "content-definitions-delete-content-definition-attribute" [
  content_definition_attribute_id: int
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
    path: "/api/v2/ContentDefinitionAttributes/{contentDefinitionAttributeID}"
    path_params: [{name: contentDefinitionAttributeID, var: content_definition_attribute_id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    content_definition_attribute_id: $content_definition_attribute_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an Attribute for a ContentDefinition
#
# PUT /api/v2/ContentDefinitionAttributes/{contentDefinitionAttributeID}
# operationId: ContentDefinitions_PutContentDefinitionAttributeAsync
export def "content-definitions-put-content-definition-attribute-async" [
  content_definition_attribute_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-definition-id: int # The ID of the content definition to which this attribute belongs. (format: int32)
  --id: int # The ID of this attribute. (format: int32)
  name: string # The name of this Attribute.
  --value: string # The value of this Attribute
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/ContentDefinitionAttributes/{contentDefinitionAttributeID}"
    path_params: [{name: contentDefinitionAttributeID, var: content_definition_attribute_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ContentDefinitionID, var: content_definition_id}, {name: ID, var: id}, {name: Name, var: name}, {name: Value, var: value}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    content_definition_attribute_id: $content_definition_attribute_id, content_definition_id: $content_definition_id, id: $id, name: $name, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get ContentDefinitions
#
# GET /api/v2/ContentDefinitions
# Returns: record<Entities: table<Attributes: list, ContentDefinitionID: int, Description: string, Name: string, PackageTypeID: string, TypeID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: ContentDefinitions_GetContentDefinitions
export def "content-definitions-get-content-definitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
  --user-id: int # Optional. Filter by UserID. (format: int32)
  --include-attributes: string # Names of Attributes to include when retrieving this definition. This should be a comma-separated list. If not provided, Attributes are not included. If '*', all Attributes are included.
  --name: string # Optional. Filter by Name. Supports beginning and ending wildcard (*).
  --type-id: int # Optional. Filter by TypeID. (format: int32)
  --package-type-id: string # Optional. Filter by PackageTypeID.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/ContentDefinitions"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: userID, var: user_id}, {name: includeAttributes, var: include_attributes}, {name: name, var: name}, {name: typeID, var: type_id}, {name: packageTypeID, var: package_type_id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, user_id: $user_id, include_attributes: $include_attributes, name: $name, type_id: $type_id, package_type_id: $package_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a ContentDefinition
#
# POST /api/v2/ContentDefinitions
# Returns: int
# operationId: ContentDefinitions_PostContentDefinition
export def "content-definitions-post-content-definition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --attributes: list # Attributes of this ContentDefinition — item shape: {ContentDefinitionID?: int, ID?: int, Name: string, Value?: string}
  --content-definition-id: int # The ID of this content definition. (format: int32)
  description: string # The description used on the package type in the AGCO Update System
  --name: string # The name of this content. Name must be valid for Attribute on PackageType.
  --package-type-id: string # Read Only. The ID of the package type used for this content.
  --type-id: int # The type of content. (format: int32)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/ContentDefinitions"
    body: {content_type: "application/json", kind: json, fields: [{name: Attributes, var: attributes}, {name: ContentDefinitionID, var: content_definition_id}, {name: Description, var: description}, {name: Name, var: name}, {name: PackageTypeID, var: package_type_id}, {name: TypeID, var: type_id}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    attributes: $attributes, content_definition_id: $content_definition_id, description: $description, name: $name, package_type_id: $package_type_id, type_id: $type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a ContentDefinition
#
# DELETE /api/v2/ContentDefinitions/{contentDefinitionID}
# operationId: ContentDefinitions_DeleteContentDefinition
export def "content-definitions-delete-content-definition" [
  content_definition_id: int
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
    path: "/api/v2/ContentDefinitions/{contentDefinitionID}"
    path_params: [{name: contentDefinitionID, var: content_definition_id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    content_definition_id: $content_definition_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a ContentDefinition by ID
#
# GET /api/v2/ContentDefinitions/{contentDefinitionID}
# Returns: record<Attributes: table<ContentDefinitionID: int, ID: int, Name: string, Value: string>, ContentDefinitionID: int, Description: string, Name: string, PackageTypeID: string, TypeID: int>
# operationId: ContentDefinitions_GetContentDefinition
export def "content-definitions-get-content-definition" [
  content_definition_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --include-attributes: string # Names of Attributes to include when retrieving this definition. This should be a comma-separated list. If not provided, Attributes are not included. If '*', all Attributes are included.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/ContentDefinitions/{contentDefinitionID}"
    path_params: [{name: contentDefinitionID, var: content_definition_id}]
    query: [{name: includeAttributes, var: include_attributes}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    content_definition_id: $content_definition_id, include_attributes: $include_attributes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a ContentDefinition
#
# PUT /api/v2/ContentDefinitions/{contentDefinitionID}
# operationId: ContentDefinitions_PutContentDefinition
export def "content-definitions-put-content-definition" [
  content_definition_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: list # Attributes of this ContentDefinition — item shape: {ContentDefinitionID?: int, ID?: int, Name: string, Value?: string}
  --body-content-definition-id: int # The ID of this content definition. (format: int32) (spec name: ContentDefinitionID)
  description: string # The description used on the package type in the AGCO Update System
  --name: string # The name of this content. Name must be valid for Attribute on PackageType.
  --package-type-id: string # Read Only. The ID of the package type used for this content.
  --type-id: int # The type of content. (format: int32)
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/ContentDefinitions/{contentDefinitionID}"
    path_params: [{name: contentDefinitionID, var: content_definition_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Attributes, var: attributes}, {name: ContentDefinitionID, var: body_content_definition_id}, {name: Description, var: description}, {name: Name, var: name}, {name: PackageTypeID, var: package_type_id}, {name: TypeID, var: type_id}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    content_definition_id: $content_definition_id, attributes: $attributes, body_content_definition_id: $body_content_definition_id, description: $description, name: $name, package_type_id: $package_type_id, type_id: $type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Attributes for a ContentDefinition
#
# GET /api/v2/ContentDefinitions/{contentDefinitionID}/Attributes
# Returns: record<Entities: table<ContentDefinitionID: int, ID: int, Name: string, Value: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: ContentDefinitions_GetContentDefinitionAttributes
export def "content-definitions-get-content-definition-attributes" [
  content_definition_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
  --name: string # Optional. Filter the attributes by Name.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/ContentDefinitions/{contentDefinitionID}/Attributes"
    path_params: [{name: contentDefinitionID, var: content_definition_id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: name, var: name}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    content_definition_id: $content_definition_id, limit: $limit, offset: $offset, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add an Attribute to a ContentDefinition
#
# POST /api/v2/ContentDefinitions/{contentDefinitionID}/Attributes
# Returns: int
# operationId: ContentDefinitions_PostContentDefinitionAttribute
export def "content-definitions-post-content-definition-attribute" [
  content_definition_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --body-content-definition-id: int # The ID of the content definition to which this attribute belongs. (format: int32) (spec name: ContentDefinitionID)
  --id: int # The ID of this attribute. (format: int32)
  name: string # The name of this Attribute.
  --value: string # The value of this Attribute
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/ContentDefinitions/{contentDefinitionID}/Attributes"
    path_params: [{name: contentDefinitionID, var: content_definition_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ContentDefinitionID, var: body_content_definition_id}, {name: ID, var: id}, {name: Name, var: name}, {name: Value, var: value}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    content_definition_id: $content_definition_id, body_content_definition_id: $body_content_definition_id, id: $id, name: $name, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# No Documentation Found.
#
# POST /api/v2/ContentDefinitions/{contentDefinitionID}/Attributes/Batch
# operationId: ContentDefinitions_PostContentDefinitionAttributes
export def "content-definitions-post-content-definition-attributes" [
  content_definition_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/ContentDefinitions/{contentDefinitionID}/Attributes/Batch"
    path_params: [{name: contentDefinitionID, var: content_definition_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    content_definition_id: $content_definition_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get ContentReleaseVersion
#
# GET /api/v2/ContentReleases
# Returns: record<Entities: table<ContentDefinitionID: int, ContentReleaseID: int, Deleted: bool, PublisherUserID: int, ReleaseID: int, TestReportUrl: string, UpdatedDate: string, Version: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: ContentRelease_GetContentReleaseVersion
export def "content-release-get-content-release-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
  --deleted: oneof<nothing, bool> # Optional. Filter by deleted.
  --release-id: int # Optional. Filter by releaseID. (format: int32)
  --user-id: int # Optional. Filter by UserID. (format: int32)
  --content-definition-id: int # Optional. Filter by ContentDefinitionID. (format: int32)
  --version: int # Optional. Filter by Version. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/ContentReleases"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: deleted, var: deleted}, {name: releaseID, var: release_id}, {name: userId, var: user_id}, {name: contentDefinitionID, var: content_definition_id}, {name: version, var: version}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, deleted: $deleted, release_id: $release_id, user_id: $user_id, content_definition_id: $content_definition_id, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a ContentReleaseVersion
#
# POST /api/v2/ContentReleases
# Returns: int
# operationId: ContentRelease_PostContentRelease
export def "content-release-post-content-release" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --content-definition-id: int # ContentDefinitionID (format: int32)
  --content-release-id: int # ContentReleaseID (format: int32)
  --deleted: oneof<nothing, bool> # deleted flag
  --publisher-user-id: int # PublisherUser ID (format: int32)
  --release-id: int # rele4ase Id (format: int32)
  --test-report-url: string # The URL at which test reports for this content can be found
  --updated-date: string # Updated Date (format: date-time)
  --version: int # version (format: int32)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/ContentReleases"
    body: {content_type: "application/json", kind: json, fields: [{name: ContentDefinitionID, var: content_definition_id}, {name: ContentReleaseID, var: content_release_id}, {name: Deleted, var: deleted}, {name: PublisherUserID, var: publisher_user_id}, {name: ReleaseID, var: release_id}, {name: TestReportUrl, var: test_report_url}, {name: UpdatedDate, var: updated_date}, {name: Version, var: version}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    content_definition_id: $content_definition_id, content_release_id: $content_release_id, deleted: $deleted, publisher_user_id: $publisher_user_id, release_id: $release_id, test_report_url: $test_report_url, updated_date: $updated_date, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a ContentReleaseVersion
#
# DELETE /api/v2/ContentReleases/{ContentReleaseId}
# operationId: ContentRelease_DeleteContentReleaseVersionn
export def "content-release-delete-content-release-versionn" [
  content_release_id: int
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
    path: "/api/v2/ContentReleases/{ContentReleaseId}"
    path_params: [{name: ContentReleaseId, var: content_release_id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    content_release_id: $content_release_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Content Release Version by ID
#
# GET /api/v2/ContentReleases/{ContentReleaseId}
# Returns: record<ContentDefinitionID: int, ContentReleaseID: int, Deleted: bool, PublisherUserID: int, ReleaseID: int, TestReportUrl: string, UpdatedDate: string, Version: int>
export def "get-api-v2-content-releases-content-release-id" [
  content_release_id: int
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/api/v2/ContentReleases/{ContentReleaseId}"
    path_params: [{name: ContentReleaseId, var: content_release_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    content_release_id: $content_release_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a ContentReleaseVersion
#
# PUT /api/v2/ContentReleases/{ContentReleaseId}
# operationId: ContentRelease_PutContentDefinition
export def "content-release-put-content-definition" [
  content_release_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-definition-id: int # ContentDefinitionID (format: int32)
  --body-content-release-id: int # ContentReleaseID (format: int32) (spec name: ContentReleaseID)
  --deleted: oneof<nothing, bool> # deleted flag
  --publisher-user-id: int # PublisherUser ID (format: int32)
  --release-id: int # rele4ase Id (format: int32)
  --test-report-url: string # The URL at which test reports for this content can be found
  --updated-date: string # Updated Date (format: date-time)
  --version: int # version (format: int32)
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/ContentReleases/{ContentReleaseId}"
    path_params: [{name: ContentReleaseId, var: content_release_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ContentDefinitionID, var: content_definition_id}, {name: ContentReleaseID, var: body_content_release_id}, {name: Deleted, var: deleted}, {name: PublisherUserID, var: publisher_user_id}, {name: ReleaseID, var: release_id}, {name: TestReportUrl, var: test_report_url}, {name: UpdatedDate, var: updated_date}, {name: Version, var: version}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    content_release_id: $content_release_id, content_definition_id: $content_definition_id, body_content_release_id: $body_content_release_id, deleted: $deleted, publisher_user_id: $publisher_user_id, release_id: $release_id, test_report_url: $test_report_url, updated_date: $updated_date, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# No Documentation Found.
#
# PUT /api/v2/ContentSubmissionAttributes/Batch
# operationId: ContentSubmissions_PutContentSubmissionAttributes
export def "content-submissions-put-content-submission-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/ContentSubmissionAttributes/Batch"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an Attribute from a ContentSubmission
#
# DELETE /api/v2/ContentSubmissionAttributes/{contentSubmissionAttributeID}
# operationId: ContentSubmissions_DeleteContentSubmissionAttribute
export def "content-submissions-delete-content-submission-attribute" [
  content_submission_attribute_id: int
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
    path: "/api/v2/ContentSubmissionAttributes/{contentSubmissionAttributeID}"
    path_params: [{name: contentSubmissionAttributeID, var: content_submission_attribute_id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    content_submission_attribute_id: $content_submission_attribute_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an Attribute for a ContentSubmission
#
# PUT /api/v2/ContentSubmissionAttributes/{contentSubmissionAttributeID}
# operationId: ContentSubmissions_PutContentSubmissionAttributeAsync
export def "content-submissions-put-content-submission-attribute-async" [
  content_submission_attribute_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-submission-id: int # The ID of the content submission to which this attribute belongs. (format: int32)
  --id: int # The ID of this attribute. (format: int32)
  name: string # The name of this Attribute.
  --value: string # The value of this Attribute
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/ContentSubmissionAttributes/{contentSubmissionAttributeID}"
    path_params: [{name: contentSubmissionAttributeID, var: content_submission_attribute_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ContentSubmissionID, var: content_submission_id}, {name: ID, var: id}, {name: Name, var: name}, {name: Value, var: value}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    content_submission_attribute_id: $content_submission_attribute_id, content_submission_id: $content_submission_id, id: $id, name: $name, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns available Content Submission Types.
#
# GET /api/v2/ContentSubmissionTypes
# Returns: table<AttributeTemplate: string, BuildDefinitionID: int, CategoryTemplate: string, Description: string, Enabled: bool, ID: int, InventoryPackageID: string, JobID: int, Name: string, ReleaseNotesDescription: string>
# operationId: ContentSubmissionTypes_GetContentSubmissionTypes
export def "content-submission-types-get-content-submission-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --enabled: oneof<nothing, bool>
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/ContentSubmissionTypes"
    query: [{name: enabled, var: enabled}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a Content Submission Type
#
# POST /api/v2/ContentSubmissionTypes
# Returns: int
# operationId: ContentSubmissionTypes_PostContentSubmissionType
export def "content-submission-types-post-content-submission-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --attribute-template: string # A template for the Attribute from which to read the version of the package installed. The following placeholders are valid: {ContentDefinitionType}, {ContentDefinitionID}, {ContentDefinitionName}
  --build-definition-id: int # The ID of the Azure DevOps Build Definition for which to create a Build. Either 'BuildDefinitionID' or 'JobID' is required. (format: int32)
  --category-template: string # A template for the category from which to read the version of the package installed. The following placeholders are valid: {ContentDefinitionType}, {ContentDefinitionID}, {ContentDefinitionName}
  description: string # A description for the Content Submission Type
  --enabled: oneof<nothing, bool> # Indicates whether this submission type is available to be used
  --id: int # The ID of the Content Submission Type (format: int32)
  --inventory-package-id: string # The ID of the Inventory Package from which to read the version of the package installed.
  --job-id: int # The ID of the JobDefinition for which to initiate a Job. A value of '0' will cause a submission to fail. Either 'BuildDefinitionID' or 'JobID' is required. (format: int32)
  name: string # The Name of the Content Submission Type
  --release-notes-description: string # A description of how release notes for this Content Submission Type are used
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/ContentSubmissionTypes"
    body: {content_type: "application/json", kind: json, fields: [{name: AttributeTemplate, var: attribute_template}, {name: BuildDefinitionID, var: build_definition_id}, {name: CategoryTemplate, var: category_template}, {name: Description, var: description}, {name: Enabled, var: enabled}, {name: ID, var: id}, {name: InventoryPackageID, var: inventory_package_id}, {name: JobID, var: job_id}, {name: Name, var: name}, {name: ReleaseNotesDescription, var: release_notes_description}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    attribute_template: $attribute_template, build_definition_id: $build_definition_id, category_template: $category_template, description: $description, enabled: $enabled, id: $id, inventory_package_id: $inventory_package_id, job_id: $job_id, name: $name, release_notes_description: $release_notes_description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove a Content Submission Type
#
# DELETE /api/v2/ContentSubmissionTypes/{id}
# operationId: ContentSubmissionTypes_DeleteContentSubmissionType
export def "content-submission-types-delete-content-submission-type" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v2/ContentSubmissionTypes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a Content Submission Type by its ID.
#
# GET /api/v2/ContentSubmissionTypes/{id}
# Returns: record<AttributeTemplate: string, BuildDefinitionID: int, CategoryTemplate: string, Description: string, Enabled: bool, ID: int, InventoryPackageID: string, JobID: int, Name: string, ReleaseNotesDescription: string>
# operationId: ContentSubmissionTypes_GetContentSubmissionType
export def "content-submission-types-get-content-submission-type" [
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
    path: "/api/v2/ContentSubmissionTypes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a Content Submission Type
#
# PUT /api/v2/ContentSubmissionTypes/{id}
# operationId: ContentSubmissionTypes_PutContentSubmissionType
export def "content-submission-types-put-content-submission-type" [
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
  --attribute-template: string # A template for the Attribute from which to read the version of the package installed. The following placeholders are valid: {ContentDefinitionType}, {ContentDefinitionID}, {ContentDefinitionName}
  --build-definition-id: int # The ID of the Azure DevOps Build Definition for which to create a Build. Either 'BuildDefinitionID' or 'JobID' is required. (format: int32)
  --category-template: string # A template for the category from which to read the version of the package installed. The following placeholders are valid: {ContentDefinitionType}, {ContentDefinitionID}, {ContentDefinitionName}
  description: string # A description for the Content Submission Type
  --enabled: oneof<nothing, bool> # Indicates whether this submission type is available to be used
  --body-id: int # The ID of the Content Submission Type (format: int32) (spec name: ID)
  --inventory-package-id: string # The ID of the Inventory Package from which to read the version of the package installed.
  --job-id: int # The ID of the JobDefinition for which to initiate a Job. A value of '0' will cause a submission to fail. Either 'BuildDefinitionID' or 'JobID' is required. (format: int32)
  name: string # The Name of the Content Submission Type
  --release-notes-description: string # A description of how release notes for this Content Submission Type are used
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/ContentSubmissionTypes/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: AttributeTemplate, var: attribute_template}, {name: BuildDefinitionID, var: build_definition_id}, {name: CategoryTemplate, var: category_template}, {name: Description, var: description}, {name: Enabled, var: enabled}, {name: ID, var: body_id}, {name: InventoryPackageID, var: inventory_package_id}, {name: JobID, var: job_id}, {name: Name, var: name}, {name: ReleaseNotesDescription, var: release_notes_description}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id, attribute_template: $attribute_template, build_definition_id: $build_definition_id, category_template: $category_template, description: $description, enabled: $enabled, body_id: $body_id, inventory_package_id: $inventory_package_id, job_id: $job_id, name: $name, release_notes_description: $release_notes_description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get ContentSubmissions
#
# GET /api/v2/ContentSubmissions
# Returns: record<Entities: table<Attributes: list, BuildID: int, ContentDefinitionID: int, ContentSubmissionID: int, Definition: record, JobRunID: int, PackageID: string, ReleaseNotes: string, Repository: string, Revision: int, SubmissionDate: string, UserID: int, Version: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: ContentSubmissions_GetContentSubmissions
export def "content-submissions-get-content-submissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
  --user-id: int # Optional. Filter by UserID. (format: int32)
  --content-definition-id: int # Optional. Filter by ContentDefinitionID (format: int32)
  --include-attributes: string # Names of Attributes to include when retrieving this submission. This should be a comma-separated list. If not provided, Attributes are not included. If '*', all Attributes are included.
  --release-id: int # Optional. Filter the submissions by whether they are part of the Release with the specified Release ID. (format: int32)
  --type-id: int # Optional. Filter submissions by their ContentDefinition's Type ID. (format: int32)
  --version: int # Optional. Filter submissions by their Version. (format: int32)
  --include-definition: oneof<nothing, bool> # Optional. If true, includes the ContentDefinition for each submission.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/ContentSubmissions"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: userID, var: user_id}, {name: contentDefinitionID, var: content_definition_id}, {name: includeAttributes, var: include_attributes}, {name: releaseID, var: release_id}, {name: typeID, var: type_id}, {name: version, var: version}, {name: includeDefinition, var: include_definition}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, user_id: $user_id, content_definition_id: $content_definition_id, include_attributes: $include_attributes, release_id: $release_id, type_id: $type_id, version: $version, include_definition: $include_definition
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a ContentSubmission
#
# POST /api/v2/ContentSubmissions
# Returns: int
# operationId: ContentSubmissions_PostContentSubmission
export def "content-submissions-post-content-submission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --attributes: list # Attributes of this ContentSubmission — item shape: {ContentSubmissionID?: int, ID?: int, Name: string, Value?: string}
  --build-id: int # ReadOnly. The ID of the Azure DevOps Build which will build the content package. (format: int32)
  --content-definition-id: int # The ID of the Content Definition. (format: int32)
  --content-submission-id: int # The ID of this Content Submission. (format: int32)
  --definition: record # The definition of the content for submission — shape: {Attributes?: list, ContentDefinitionID?: int, Description: string, Name?: string, PackageTypeID?: string, TypeID?: int}
  --job-run-id: int # ReadOnly. The ID of the JobRun which will build the content package. (format: int32)
  --package-id: string # The ID of package generated by this content submission.
  --release-notes: string # Release Notes for this ContentSubmission
  --repository: string # The SVN repository used as the source of this content submission
  --revision: int # The SVN revision used as the source of this content submission. (format: int32)
  --submission-date: string # Read Only. The UTC date and time the content submission was made. (format: date-time)
  --user-id: int # Read Only. The ID of the user who submitted the content (format: int32)
  --version: int # Optional. The version number assigned to this Content Submission and the resulting Package. If not provided, version shall be 1 if it is the first content submission for the ContentDefinitionID otherwise it shall be the highest content submission version for the specified ContentDefinitionID incremented by 1. (format: int32)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/ContentSubmissions"
    body: {content_type: "application/json", kind: json, fields: [{name: Attributes, var: attributes}, {name: BuildID, var: build_id}, {name: ContentDefinitionID, var: content_definition_id}, {name: ContentSubmissionID, var: content_submission_id}, {name: Definition, var: definition}, {name: JobRunID, var: job_run_id}, {name: PackageID, var: package_id}, {name: ReleaseNotes, var: release_notes}, {name: Repository, var: repository}, {name: Revision, var: revision}, {name: SubmissionDate, var: submission_date}, {name: UserID, var: user_id}, {name: Version, var: version}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    attributes: $attributes, build_id: $build_id, content_definition_id: $content_definition_id, content_submission_id: $content_submission_id, definition: $definition, job_run_id: $job_run_id, package_id: $package_id, release_notes: $release_notes, repository: $repository, revision: $revision, submission_date: $submission_date, user_id: $user_id, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a ContentSubmission
#
# DELETE /api/v2/ContentSubmissions/{contentSubmissionID}
# operationId: ContentSubmissions_DeleteContentSubmission
export def "content-submissions-delete-content-submission" [
  content_submission_id: int
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
    path: "/api/v2/ContentSubmissions/{contentSubmissionID}"
    path_params: [{name: contentSubmissionID, var: content_submission_id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    content_submission_id: $content_submission_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a ContentSubmission by ID
#
# GET /api/v2/ContentSubmissions/{contentSubmissionID}
# Returns: record<Attributes: table<ContentSubmissionID: int, ID: int, Name: string, Value: string>, BuildID: int, ContentDefinitionID: int, ContentSubmissionID: int, Definition: record<Attributes: list<record>, ContentDefinitionID: int, Description: string, Name: string, PackageTypeID: string, TypeID: int>, JobRunID: int, PackageID: string, ReleaseNotes: string, Repository: string, Revision: int, SubmissionDate: string, UserID: int, Version: int>
# operationId: ContentSubmissions_GetContentSubmission
export def "content-submissions-get-content-submission" [
  content_submission_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --include-attributes: string # Names of Attributes to include when retrieving this submission. This should be a comma-separated list.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/ContentSubmissions/{contentSubmissionID}"
    path_params: [{name: contentSubmissionID, var: content_submission_id}]
    query: [{name: includeAttributes, var: include_attributes}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    content_submission_id: $content_submission_id, include_attributes: $include_attributes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a ContentSubmission
#
# PUT /api/v2/ContentSubmissions/{contentSubmissionID}
# operationId: ContentSubmissions_PutContentSubmission
export def "content-submissions-put-content-submission" [
  content_submission_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: list # Attributes of this ContentSubmission — item shape: {ContentSubmissionID?: int, ID?: int, Name: string, Value?: string}
  --build-id: int # ReadOnly. The ID of the Azure DevOps Build which will build the content package. (format: int32)
  --content-definition-id: int # The ID of the Content Definition. (format: int32)
  --body-content-submission-id: int # The ID of this Content Submission. (format: int32) (spec name: ContentSubmissionID)
  --definition: record # The definition of the content for submission — shape: {Attributes?: list, ContentDefinitionID?: int, Description: string, Name?: string, PackageTypeID?: string, TypeID?: int}
  --job-run-id: int # ReadOnly. The ID of the JobRun which will build the content package. (format: int32)
  --package-id: string # The ID of package generated by this content submission.
  --release-notes: string # Release Notes for this ContentSubmission
  --repository: string # The SVN repository used as the source of this content submission
  --revision: int # The SVN revision used as the source of this content submission. (format: int32)
  --submission-date: string # Read Only. The UTC date and time the content submission was made. (format: date-time)
  --user-id: int # Read Only. The ID of the user who submitted the content (format: int32)
  --version: int # Optional. The version number assigned to this Content Submission and the resulting Package. If not provided, version shall be 1 if it is the first content submission for the ContentDefinitionID otherwise it shall be the highest content submission version for the specified ContentDefinitionID incremented by 1. (format: int32)
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/ContentSubmissions/{contentSubmissionID}"
    path_params: [{name: contentSubmissionID, var: content_submission_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Attributes, var: attributes}, {name: BuildID, var: build_id}, {name: ContentDefinitionID, var: content_definition_id}, {name: ContentSubmissionID, var: body_content_submission_id}, {name: Definition, var: definition}, {name: JobRunID, var: job_run_id}, {name: PackageID, var: package_id}, {name: ReleaseNotes, var: release_notes}, {name: Repository, var: repository}, {name: Revision, var: revision}, {name: SubmissionDate, var: submission_date}, {name: UserID, var: user_id}, {name: Version, var: version}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    content_submission_id: $content_submission_id, attributes: $attributes, build_id: $build_id, content_definition_id: $content_definition_id, body_content_submission_id: $body_content_submission_id, definition: $definition, job_run_id: $job_run_id, package_id: $package_id, release_notes: $release_notes, repository: $repository, revision: $revision, submission_date: $submission_date, user_id: $user_id, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Attributes for a ContentSubmission
#
# GET /api/v2/ContentSubmissions/{contentSubmissionID}/Attributes
# Returns: record<Entities: table<ContentSubmissionID: int, ID: int, Name: string, Value: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: ContentSubmissions_GetContentSubmissionAttributes
export def "content-submissions-get-content-submission-attributes" [
  content_submission_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
  --name: string # Optional. Filter the attributes by Name.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/ContentSubmissions/{contentSubmissionID}/Attributes"
    path_params: [{name: contentSubmissionID, var: content_submission_id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: name, var: name}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    content_submission_id: $content_submission_id, limit: $limit, offset: $offset, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add an Attribute to a ContentSubmission
#
# POST /api/v2/ContentSubmissions/{contentSubmissionID}/Attributes
# Returns: int
# operationId: ContentSubmissions_PostContentSubmissionAttribute
export def "content-submissions-post-content-submission-attribute" [
  content_submission_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --body-content-submission-id: int # The ID of the content submission to which this attribute belongs. (format: int32) (spec name: ContentSubmissionID)
  --id: int # The ID of this attribute. (format: int32)
  name: string # The name of this Attribute.
  --value: string # The value of this Attribute
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/ContentSubmissions/{contentSubmissionID}/Attributes"
    path_params: [{name: contentSubmissionID, var: content_submission_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ContentSubmissionID, var: body_content_submission_id}, {name: ID, var: id}, {name: Name, var: name}, {name: Value, var: value}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    content_submission_id: $content_submission_id, body_content_submission_id: $body_content_submission_id, id: $id, name: $name, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# No Documentation Found.
#
# POST /api/v2/ContentSubmissions/{contentSubmissionID}/Attributes/Batch
# operationId: ContentSubmissions_PostContentSubmissionAttributes
export def "content-submissions-post-content-submission-attributes" [
  content_submission_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/ContentSubmissions/{contentSubmissionID}/Attributes/Batch"
    path_params: [{name: contentSubmissionID, var: content_submission_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    content_submission_id: $content_submission_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the status of a ContentSubmission
#
# GET /api/v2/ContentSubmissions/{contentSubmissionID}/Status
# Returns: record<ActivityRuns: table<ActivityRunID: int, EndDate: string, JobActivityID: int, JobRunID: int, Parameters: list, StartDate: string, Status: record, Steps: list>, EndDate: string, JobID: int, JobRunID: int, Parameters: table<Direction: string, Name: string, Value: string>, StartDate: string, Status: string>
# operationId: ContentSubmissions_GetContentSubmissionStatus
export def "content-submissions-get-content-submission-status" [
  content_submission_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --include-activity-run-details: oneof<nothing, bool> # True to include all status details if JobRun. Defaults to false
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/ContentSubmissions/{contentSubmissionID}/Status"
    path_params: [{name: contentSubmissionID, var: content_submission_id}]
    query: [{name: includeActivityRunDetails, var: include_activity_run_details}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    content_submission_id: $content_submission_id, include_activity_run_details: $include_activity_run_details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a total count of dealers per country
#
# GET /api/v2/DealerByCountry
# Returns: record<Entities: table<Count: int, Country: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: DealerByCountry_GetCountries
export def "dealer-by-country-get-countries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/DealerByCountry"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a list of dealers.
#
# GET /api/v2/Dealers
# Returns: record<Entities: table<BillingAddress: string, BillingAddress2: string, BillingAddress3: string, BillingAddress4: string, BillingCity: string, BillingCountry: string, BillingCountryCode: string, BillingState: string, BillingZip: string, Brands: list, DealerCode: string, DealerName: string, DealerStatus: string, DealerStatusUpdateDate: string, Filler: string, IsValid: bool, LanguagePreference: string, Region1: string, Region2: string, RegionMapping: string, RoleBrand: string, ShippingAddress2: string, ShippingAddress3: string, ShippingAddress4: string, ShippingCity: string, ShippingCountry: string, ShippingState: string, ShippingStreet: string, ShippingZip: string, Telephone: string, VATCode: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: Dealers_GetDealers
export def "dealers-get-dealers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --brand: string # The brand to filter by.
  --shipping-country: string # The country to filter by.
  --dealer-name: string # The partial Dealer Name to filter by. Wildcard supported (*).
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Dealers"
    query: [{name: Brand, var: brand}, {name: ShippingCountry, var: shipping_country}, {name: DealerName, var: dealer_name}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    brand: $brand, shipping_country: $shipping_country, dealer_name: $dealer_name, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Lookup a dealer using a dealer code.
#
# GET /api/v2/Dealers/{DealerCode}
# Returns: record<BillingAddress: string, BillingAddress2: string, BillingAddress3: string, BillingAddress4: string, BillingCity: string, BillingCountry: string, BillingCountryCode: string, BillingState: string, BillingZip: string, Brands: list<string>, DealerCode: string, DealerName: string, DealerStatus: string, DealerStatusUpdateDate: string, Filler: string, IsValid: bool, LanguagePreference: string, Region1: string, Region2: string, RegionMapping: string, RoleBrand: string, ShippingAddress2: string, ShippingAddress3: string, ShippingAddress4: string, ShippingCity: string, ShippingCountry: string, ShippingState: string, ShippingStreet: string, ShippingZip: string, Telephone: string, VATCode: string>
# operationId: Dealers_GetDealerbyDealerCode
export def "dealers-get-dealerby-dealer-code" [
  dealer_code: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/api/v2/Dealers/{DealerCode}"
    path_params: [{name: DealerCode, var: dealer_code}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    dealer_code: $dealer_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a paged response of file metadata.
#
# GET /api/v2/Files
# Returns: record<Entities: table<CRC: string, ContentType: string, Description: string, Id: string, IsPublic: bool, Name: string, Path: string, Size: int, State: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: Files_GetFiles
export def "files-get-files" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --include-deleted: oneof<nothing, bool> # Indicates whether to include files marked as removed.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Files"
    query: [{name: includeDeleted, var: include_deleted}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    include_deleted: $include_deleted, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create the metadata for a file before uploading. The State of the File should be 'Created'.
#
# POST /api/v2/Files
# Returns: string
# operationId: Files_PostFile
export def "files-post-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  crc: string # The crc of the file (SHA256, HEX-encoded). Must be provided when creating a file.
  content_type: string # The type of file; sent as the content-type header.
  description: string # The description of the file.
  --id: string # The Id of the file.
  --is-public: oneof<nothing, bool> # Indicates whether this file is available to the public for download.
  name: string # The name of the file when downloaded.
  path: string # The Path of the file.
  --size: int # The size of the file in bytes. Null until assigned by server when marked as 'Available'. Read Only (format: int64)
  state: string@state-completer-2 # Indicates the state of this file. Must be 'Created' when created.
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/Files"
    body: {content_type: "application/json", kind: json, fields: [{name: CRC, var: crc}, {name: ContentType, var: content_type}, {name: Description, var: description}, {name: Id, var: id}, {name: IsPublic, var: is_public, required: true}, {name: Name, var: name}, {name: Path, var: path}, {name: Size, var: size}, {name: State, var: state}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    crc: $crc, content_type: $content_type, description: $description, id: $id, is_public: $is_public, name: $name, path: $path, size: $size, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Mark a file as 'Removed'. Disables download of the file and hides metadata from GET all method
#
# DELETE /api/v2/Files/{ID}
# operationId: Files_DeleteFile
export def "files-delete-file" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v2/Files/{ID}"
    path_params: [{name: ID, var: id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a file's metadata.
#
# GET /api/v2/Files/{ID}
# Returns: record<CRC: string, ContentType: string, Description: string, Id: string, IsPublic: bool, Name: string, Path: string, Size: int, State: string>
# operationId: Files_GetFile
export def "files-get-file" [
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
    path: "/api/v2/Files/{ID}"
    path_params: [{name: ID, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update the metadata for a file. Size may not be modified by the client.
#
# PUT /api/v2/Files/{ID}
# operationId: Files_PutFile
export def "files-put-file" [
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
  crc: string # The crc of the file (SHA256, HEX-encoded). Must be provided when creating a file.
  content_type: string # The type of file; sent as the content-type header.
  description: string # The description of the file.
  --body-id: string # The Id of the file. (spec name: Id)
  --is-public: oneof<nothing, bool> # Indicates whether this file is available to the public for download.
  name: string # The name of the file when downloaded.
  path: string # The Path of the file.
  --size: int # The size of the file in bytes. Null until assigned by server when marked as 'Available'. Read Only (format: int64)
  state: string@state-completer-2 # Indicates the state of this file. Must be 'Created' when created.
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/Files/{ID}"
    path_params: [{name: ID, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: CRC, var: crc}, {name: ContentType, var: content_type}, {name: Description, var: description}, {name: Id, var: body_id}, {name: IsPublic, var: is_public, required: true}, {name: Name, var: name}, {name: Path, var: path}, {name: Size, var: size}, {name: State, var: state}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id, crc: $crc, content_type: $content_type, description: $description, body_id: $body_id, is_public: $is_public, name: $name, path: $path, size: $size, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download the contents of a file. The current State of the File should be 'Available'.
#
# GET /api/v2/Files/{ID}/FileContents
# Returns: record
# operationId: Files_GetFileContents
export def "files-get-file-contents" [
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
    path: "/api/v2/Files/{ID}/FileContents"
    path_params: [{name: ID, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Upload the contents of a file. The current State of the File should be 'Created'.
#
# PUT /api/v2/Files/{ID}/FileContents
# Returns: record
# operationId: Files_PutFileContents
export def "files-put-file-contents" [
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
    method: put
    path: "/api/v2/Files/{ID}/FileContents"
    path_params: [{name: ID, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a paged response of file metadata.
#
# GET /api/v2/GlobalImageCategories
# Returns: record<Entities: table<Id: string, Name: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: GlobalImageCategories_GetFiles
export def "global-image-categories-get-files" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/GlobalImageCategories"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create the metadata for a file before uploading. The State should be 'Created'.
#
# POST /api/v2/GlobalImageCategories
# Returns: string
# operationId: GlobalImageCategories_PostFile
export def "global-image-categories-post-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: string # The Id of the GlobalImage Categories.
  name: string # The name of the globalImage Catetory.
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/GlobalImageCategories"
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: Name, var: name}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a file's metadata.
#
# GET /api/v2/GlobalImageCategories/{ID}
# Returns: record<Id: string, Name: string>
# operationId: GlobalImageCategories_GetFile
export def "global-image-categories-get-file" [
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
    path: "/api/v2/GlobalImageCategories/{ID}"
    path_params: [{name: ID, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a paged response of GlobalImage.
#
# GET /api/v2/GlobalImages
# Returns: record<Entities: table<CRC: string, Categories: list, Date: string, Description: string, Height: int, Id: string, Name: string, Publisher: string, Size: int, State: string, ThumbnailCRC: string, ThumbnailSize: int, Width: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: GlobalImages_GetGlobalImages
export def "global-images-get-global-images" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search: string # Optional. Searches for matching global images with the matching Category Name, Publisher or Description
  --category-id: string
  --publisher: string
  --include-deleted: oneof<nothing, bool> # Indicates whether to include GlobalImages marked as removed.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/GlobalImages"
    query: [{name: search, var: search}, {name: categoryId, var: category_id}, {name: publisher, var: publisher}, {name: includeDeleted, var: include_deleted}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    search: $search, category_id: $category_id, publisher: $publisher, include_deleted: $include_deleted, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create the metadata for a GlobalImage before uploading. The State should be 'Created'.
#
# POST /api/v2/GlobalImages
# Returns: string
# operationId: GlobalImages_PostGlobalImage
export def "global-images-post-global-image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --override-publisher-or-date: oneof<nothing, bool> # Whether to set the publisher and date to the provided values.
  crc: string # The Hash of the file (SHA256, HEX-encoded).
  --categories: list # The category of the file. — item shape: {Id?: string, Name: string}
  --date: string # The date of the file. (format: date-time)
  description: string # The description of the file.
  height: int # The height of the file. (format: int32)
  --id: string # The Id of the GlobalImage Metadata.
  name: string # The name of the file when downloaded.
  --publisher: string # The Publisher of the file.
  --size: int # The size of the file in bytes. Null until assigned by server when marked as 'Available'. Read Only (format: int64)
  state: string@state-completer-2 # Indicates the state of this file. Must be 'Created' when created. Read Only.
  thumbnail_crc: string # The Hash of the thumbnail file (SHA256, HEX-encoded).
  --thumbnail-size: int # The size of the thumbnail file in bytes. Null until assigned by server when marked as 'Available'. Read Only (format: int64)
  width: int # The width of the file. (format: int32)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/GlobalImages"
    query: [{name: overridePublisherOrDate, var: override_publisher_or_date}]
    body: {content_type: "application/json", kind: json, fields: [{name: CRC, var: crc}, {name: Categories, var: categories}, {name: Date, var: date}, {name: Description, var: description}, {name: Height, var: height}, {name: Id, var: id}, {name: Name, var: name}, {name: Publisher, var: publisher}, {name: Size, var: size}, {name: State, var: state}, {name: ThumbnailCRC, var: thumbnail_crc}, {name: ThumbnailSize, var: thumbnail_size}, {name: Width, var: width}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    override_publisher_or_date: $override_publisher_or_date, crc: $crc, categories: $categories, date: $date, description: $description, height: $height, id: $id, name: $name, publisher: $publisher, size: $size, state: $state, thumbnail_crc: $thumbnail_crc, thumbnail_size: $thumbnail_size, width: $width
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Mark a file as 'Removed'. Disables download of the image and hides metadata from GET all method
#
# DELETE /api/v2/GlobalImages/{ID}
# operationId: GlobalImages_DeleteFile
export def "global-images-delete-file" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v2/GlobalImages/{ID}"
    path_params: [{name: ID, var: id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a GlobalImage's metadata.
#
# GET /api/v2/GlobalImages/{ID}
# Returns: record<CRC: string, Categories: table<Id: string, Name: string>, Date: string, Description: string, Height: int, Id: string, Name: string, Publisher: string, Size: int, State: string, ThumbnailCRC: string, ThumbnailSize: int, Width: int>
# operationId: GlobalImages_GetGlobalImage
export def "global-images-get-global-image" [
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
    path: "/api/v2/GlobalImages/{ID}"
    path_params: [{name: ID, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update the metadata for an image.
#
# PUT /api/v2/GlobalImages/{ID}
# operationId: GlobalImages_PutGlobalImage
export def "global-images-put-global-image" [
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
  --override-publisher-or-date: oneof<nothing, bool> # Whether to set the publisher and date to the provided values.
  crc: string # The Hash of the file (SHA256, HEX-encoded).
  --categories: list # The category of the file. — item shape: {Id?: string, Name: string}
  --date: string # The date of the file. (format: date-time)
  description: string # The description of the file.
  height: int # The height of the file. (format: int32)
  --body-id: string # The Id of the GlobalImage Metadata. (spec name: Id)
  name: string # The name of the file when downloaded.
  --publisher: string # The Publisher of the file.
  --size: int # The size of the file in bytes. Null until assigned by server when marked as 'Available'. Read Only (format: int64)
  state: string@state-completer-2 # Indicates the state of this file. Must be 'Created' when created. Read Only.
  thumbnail_crc: string # The Hash of the thumbnail file (SHA256, HEX-encoded).
  --thumbnail-size: int # The size of the thumbnail file in bytes. Null until assigned by server when marked as 'Available'. Read Only (format: int64)
  width: int # The width of the file. (format: int32)
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/GlobalImages/{ID}"
    path_params: [{name: ID, var: id}]
    query: [{name: overridePublisherOrDate, var: override_publisher_or_date}]
    body: {content_type: "application/json", kind: json, fields: [{name: CRC, var: crc}, {name: Categories, var: categories}, {name: Date, var: date}, {name: Description, var: description}, {name: Height, var: height}, {name: Id, var: body_id}, {name: Name, var: name}, {name: Publisher, var: publisher}, {name: Size, var: size}, {name: State, var: state}, {name: ThumbnailCRC, var: thumbnail_crc}, {name: ThumbnailSize, var: thumbnail_size}, {name: Width, var: width}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id, override_publisher_or_date: $override_publisher_or_date, crc: $crc, categories: $categories, date: $date, description: $description, height: $height, body_id: $body_id, name: $name, publisher: $publisher, size: $size, state: $state, thumbnail_crc: $thumbnail_crc, thumbnail_size: $thumbnail_size, width: $width
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download the contents of a GlobalImage. The current State of the GlobalImage should be 'Available'.
#
# GET /api/v2/GlobalImages/{ID}/ImageContents
# Returns: record
# operationId: GlobalImages_GetGlobalImageContents
export def "global-images-get-global-image-contents" [
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
  --is-full-image: oneof<nothing, bool> # Indicated whether to download the full image or the thumbnail. Defaults to 'true'.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/GlobalImages/{ID}/ImageContents"
    path_params: [{name: ID, var: id}]
    query: [{name: isFullImage, var: is_full_image}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, is_full_image: $is_full_image
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Upload the contents of a GlobalImage. The current State of the File for the GlobalImage should be 'Created'.
#
# PUT /api/v2/GlobalImages/{ID}/ImageContents
# Returns: record
# operationId: GlobalImages_PutGlobalImageContents
export def "global-images-put-global-image-contents" [
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
  --is-full-image: oneof<nothing, bool> # Indicated whether this is the full image or the thumbnail. Defaults to 'true'.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/api/v2/GlobalImages/{ID}/ImageContents"
    path_params: [{name: ID, var: id}]
    query: [{name: isFullImage, var: is_full_image}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, is_full_image: $is_full_image
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a list of the languages for which translations are supported. Returns a PagedResponse of Language objects.
#
# GET /api/v2/Languages
# Returns: record<Entities: table<Description: string, IsDeleted: bool, LocaleId: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: Languages_GetLanguages
export def "languages-get-languages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: int # limit the number of Language objects returned. Optional (defaults to 10). (format: int32)
  --offset: int # the number of Language objects to skip. Optional (defaults to 0). (format: int32)
  --include-deleted: oneof<nothing, bool> # whether to include languages marked as deleted. Defaults to false
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Languages"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: includeDeleted, var: include_deleted}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, include_deleted: $include_deleted
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a Language to support for translations. Accepts a Language object. Returns the Id of the created object.
#
# POST /api/v2/Languages
# Returns: int
# operationId: Languages_CreateLanguage
export def "languages-create-language" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  description: string # The description of the language (e.g. “English – United States”).
  --is-deleted: oneof<nothing, bool> # Indicates whether the API supports the language. Must be false when created. Read Only.
  locale_id: int # The Locale Id of the language. (format: int32)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/Languages"
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: IsDeleted, var: is_deleted}, {name: LocaleId, var: locale_id}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    description: $description, is_deleted: $is_deleted, locale_id: $locale_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove a Language from those supported for translations. Marks language as deleted.
#
# DELETE /api/v2/Languages/{LocaleID}
# operationId: Languages_DeleteLanguage
export def "languages-delete-language" [
  locale_id: int
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
    path: "/api/v2/Languages/{LocaleID}"
    path_params: [{name: LocaleID, var: locale_id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    locale_id: $locale_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a language by its id. Returns a Language object
#
# GET /api/v2/Languages/{LocaleID}
# Returns: record<Description: string, IsDeleted: bool, LocaleId: int>
# operationId: Languages_GetLanguage
export def "languages-get-language" [
  locale_id: int
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/api/v2/Languages/{LocaleID}"
    path_params: [{name: LocaleID, var: locale_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    locale_id: $locale_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a language’s description. Accepts a Language object.
#
# PUT /api/v2/Languages/{LocaleID}
# operationId: Languages_UpdateLanguage
export def "languages-update-language" [
  locale_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string # The description of the language (e.g. “English – United States”).
  --is-deleted: oneof<nothing, bool> # Indicates whether the API supports the language. Must be false when created. Read Only.
  --body-locale-id: int # The Locale Id of the language. (format: int32) (spec name: LocaleId)
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/Languages/{LocaleID}"
    path_params: [{name: LocaleID, var: locale_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: IsDeleted, var: is_deleted}, {name: LocaleId, var: body_locale_id, required: true}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    locale_id: $locale_id, description: $description, is_deleted: $is_deleted, body_locale_id: $body_locale_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a license activation.
#
# POST /api/v2/LicenseActivations
# Returns: record<Key: string, LicenseData: string>
# operationId: LicenseActivations_Post
export def "license-activations-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  dealer_code: string # The Dealer Code of the dealer activating the license
  --license-activation-type: string@license-activation-type-completer # The type of license to create (e.g. EDT, EDT Lite)
  postal_code: string # The dealer's postal code (zip code)
  system_info: string # Information about the system being activated
  voucher_code: string # The Voucher Code to use for activation
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v2/LicenseActivations"
    body: {content_type: "application/json", kind: json, fields: [{name: DealerCode, var: dealer_code}, {name: LicenseActivationType, var: license_activation_type}, {name: PostalCode, var: postal_code}, {name: SystemInfo, var: system_info}, {name: VoucherCode, var: voucher_code}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    dealer_code: $dealer_code, license_activation_type: $license_activation_type, postal_code: $postal_code, system_info: $system_info, voucher_code: $voucher_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Register an EDT Lite with the Server
#
# POST /api/v2/LicenseActivations/RegisterEDTLite
# Returns: bool
# operationId: LicenseActivations_PostRegisterEDTLite
export def "license-activations-post-register-edt-lite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dealer-code: string # The dealer code with which the EDT Lite was created.
  expiration_date: string # The date at which the content of the EDT Lite expires. (format: date-time)
  instance_id: string # The identifier for the EDT Lite.
  voucher_code: string # The voucher code with which the EDT Lite was created.
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/LicenseActivations/RegisterEDTLite"
    body: {content_type: "application/json", kind: json, fields: [{name: DealerCode, var: dealer_code}, {name: ExpirationDate, var: expiration_date}, {name: InstanceID, var: instance_id}, {name: VoucherCode, var: voucher_code}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    dealer_code: $dealer_code, expiration_date: $expiration_date, instance_id: $instance_id, voucher_code: $voucher_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a license activiation.
#
# PUT /api/v2/LicenseActivations/{ID}
# Returns: record<Key: string, LicenseData: string>
# operationId: LicenseActivations_Put
export def "license-activations-put" [
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
  license_version: string # The license version to update
  --system-info: string # Information about the system being activated
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v2/LicenseActivations/{ID}"
    path_params: [{name: ID, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: LicenseVersion, var: license_version}, {name: SystemInfo, var: system_info}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, license_version: $license_version, system_info: $system_info
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Confirm that the client has applied the updated license.
#
# PUT /api/v2/LicenseActivations/{ID}/Confirm
# operationId: LicenseActivations_PutConfirm
export def "license-activations-put-confirm" [
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
  license_version: string # The license version to confirm
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/LicenseActivations/{ID}/Confirm"
    path_params: [{name: ID, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: LicenseVersion, var: license_version}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id, license_version: $license_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of licenses with the specified criteria.
#
# GET /api/v2/Licenses
# Returns: record<Entities: table<Active: bool, CreatedDate: string, DeactivatedDate: string, LicenseActivationType: string, LicenseID: string, LicenseVersion: string, RefreshDate: string, SystemInfo: string, UpdatedLicenseVersion: string, VoucherCode: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: Licenses_Get
export def "licenses-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --voucher-code: string # Optional. Filter by VoucherCode
  --dealer-code: string # Optional. Filter by DealerCode
  --status: string@status-completer # Optional. Filter by Status. By default only active licenses will be returned.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Licenses"
    query: [{name: VoucherCode, var: voucher_code}, {name: DealerCode, var: dealer_code}, {name: Status, var: status}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    voucher_code: $voucher_code, dealer_code: $dealer_code, status: $status, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a license.
#
# GET /api/v2/Licenses/{ID}
# Returns: record<Active: bool, CreatedDate: string, DeactivatedDate: string, LicenseActivationType: string, LicenseID: string, LicenseVersion: string, RefreshDate: string, SystemInfo: string, UpdatedLicenseVersion: string, VoucherCode: string>
export def "get-api-v2-licenses-id" [
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
    path: "/api/v2/Licenses/{ID}"
    path_params: [{name: ID, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the API System logs, most recent first.
#
# GET /api/v2/Logs
# Returns: record<Entities: table<ID: string, Message: string, TimeStamp: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: Logs_GetLogs
export def "logs-get-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Logs"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a Log entry
#
# POST /api/v2/Logs
# Returns: string
# operationId: Logs_PostLog
export def "logs-post-log" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --message: string # Message to enter into the log (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/api/v2/Logs"
    query: [{name: Message, var: message, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a log by ID
#
# GET /api/v2/Logs/{ID}
# Returns: record<ID: string, Message: string, TimeStamp: string>
# operationId: Logs_GetLog
export def "logs-get-log" [
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
    path: "/api/v2/Logs/{ID}"
    path_params: [{name: ID, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Sends an email message.
#
# POST /api/v2/Notifications
# operationId: Notifications_PostMail
export def "notifications-post-mail" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cc-addresses: list<string>
  --is-body-html: oneof<nothing, bool>
  message_body: string
  subject: string
  to_addresses: list<string>
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/Notifications"
    body: {content_type: "application/json", kind: json, fields: [{name: CC_Addresses, var: cc_addresses}, {name: IsBodyHtml, var: is_body_html, required: true}, {name: MessageBody, var: message_body}, {name: Subject, var: subject}, {name: To_Addresses, var: to_addresses}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    cc_addresses: $cc_addresses, is_body_html: $is_body_html, message_body: $message_body, subject: $subject, to_addresses: $to_addresses
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all of the Package Types.
#
# GET /api/v2/PackageTypes
# Returns: record<Entities: table<Attribute: string, Category: string, Description: string, Icon: string, InventoryFrequency: int, InventoryPackage: string, LocalizedDescription: string, LocalizedName: string, MaxDeltaPackages: int, PackageTypeID: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: PackageTypes_Get
export def "package-types-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
  --user-id: int # Optional. The user ID to sort packageTypes by the user's access (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/PackageTypes"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: userID, var: user_id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a Package Type.
#
# POST /api/v2/PackageTypes
# Returns: string
# operationId: PackageTypes_Post
export def "package-types-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --attribute: string # The inventory attribute (from the InventoryPackage) used to determine what version of this package type is installed.
  --category: string # The inventory category (from the InventoryPackage) used to determine what version of this package type is installed.
  description: string # The description of the package type
  --icon: string # Optional. The icon to use for the PackageType, in base 64
  --inventory-frequency: int # The number of minutes to wait before requesting another inventory. The default value is 1440 (24 hours). (format: int32)
  --inventory-package: string # The inventory package used to determine what version of this package type is installed.
  --localized-description: string # Optional. The StringID used to localize the description of the PackageType
  --localized-name: string # Optional. The StringID used to localize the name of the PackageType
  --max-delta-packages: int # The maximum number of "chained" delta packages to use when updating the client (format: int32)
  --package-type-id: string # Read Only. The package type id.
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/PackageTypes"
    body: {content_type: "application/json", kind: json, fields: [{name: Attribute, var: attribute}, {name: Category, var: category}, {name: Description, var: description}, {name: Icon, var: icon}, {name: InventoryFrequency, var: inventory_frequency}, {name: InventoryPackage, var: inventory_package}, {name: LocalizedDescription, var: localized_description}, {name: LocalizedName, var: localized_name}, {name: MaxDeltaPackages, var: max_delta_packages}, {name: PackageTypeID, var: package_type_id}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    attribute: $attribute, category: $category, description: $description, icon: $icon, inventory_frequency: $inventory_frequency, inventory_package: $inventory_package, localized_description: $localized_description, localized_name: $localized_name, max_delta_packages: $max_delta_packages, package_type_id: $package_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a Package Type.
#
# DELETE /api/v2/PackageTypes/{ID}
# operationId: PackageTypes_Delete
export def "package-types-delete" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v2/PackageTypes/{ID}"
    path_params: [{name: ID, var: id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific Package Type.
#
# GET /api/v2/PackageTypes/{ID}
# Returns: record<Attribute: string, Category: string, Description: string, Icon: string, InventoryFrequency: int, InventoryPackage: string, LocalizedDescription: string, LocalizedName: string, MaxDeltaPackages: int, PackageTypeID: string>
export def "get-api-v2-package-types-id" [
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
    path: "/api/v2/PackageTypes/{ID}"
    path_params: [{name: ID, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Modify a Package Type.
#
# PUT /api/v2/PackageTypes/{ID}
# operationId: PackageTypes_Put
export def "package-types-put" [
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
  --attribute: string # The inventory attribute (from the InventoryPackage) used to determine what version of this package type is installed.
  --category: string # The inventory category (from the InventoryPackage) used to determine what version of this package type is installed.
  description: string # The description of the package type
  --icon: string # Optional. The icon to use for the PackageType, in base 64
  --inventory-frequency: int # The number of minutes to wait before requesting another inventory. The default value is 1440 (24 hours). (format: int32)
  --inventory-package: string # The inventory package used to determine what version of this package type is installed.
  --localized-description: string # Optional. The StringID used to localize the description of the PackageType
  --localized-name: string # Optional. The StringID used to localize the name of the PackageType
  --max-delta-packages: int # The maximum number of "chained" delta packages to use when updating the client (format: int32)
  --package-type-id: string # Read Only. The package type id.
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/PackageTypes/{ID}"
    path_params: [{name: ID, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Attribute, var: attribute}, {name: Category, var: category}, {name: Description, var: description}, {name: Icon, var: icon}, {name: InventoryFrequency, var: inventory_frequency}, {name: InventoryPackage, var: inventory_package}, {name: LocalizedDescription, var: localized_description}, {name: LocalizedName, var: localized_name}, {name: MaxDeltaPackages, var: max_delta_packages}, {name: PackageTypeID, var: package_type_id}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id, attribute: $attribute, category: $category, description: $description, icon: $icon, inventory_frequency: $inventory_frequency, inventory_package: $inventory_package, localized_description: $localized_description, localized_name: $localized_name, max_delta_packages: $max_delta_packages, package_type_id: $package_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a package type a user could see.
#
# DELETE /api/v2/PackageTypes/{id}/Users/{userID}
# operationId: PackageTypes_RemovePackageTypeUser
export def "package-types-remove-package-type-user" [
  id: string
  user_id: int
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
    path: "/api/v2/PackageTypes/{id}/Users/{userID}"
    path_params: [{name: id, var: id}, {name: userID, var: user_id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a package type that a user can see.
#
# POST /api/v2/PackageTypes/{id}/Users/{userID}
# operationId: PackageTypes_AddPackageTypeUser
export def "package-types-add-package-type-user" [
  id: string
  user_id: int
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
    path: "/api/v2/PackageTypes/{id}/Users/{userID}"
    path_params: [{name: id, var: id}, {name: userID, var: user_id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Package Type to Bundle Relationship.
#
# DELETE /api/v2/PackageTypetoBundles
# operationId: PackageTypetoBundles_Delete
export def "package-typeto-bundles-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bundle-id: string # The BundleID (required)
  --package-type-id: string # The PackageTypeID (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v2/PackageTypetoBundles"
    query: [{name: BundleID, var: bundle_id, required: true}, {name: PackageTypeID, var: package_type_id, required: true}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    bundle_id: $bundle_id, package_type_id: $package_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all of the Package Type to Bundle Relationships.
#
# GET /api/v2/PackageTypetoBundles
# Returns: record<Entities: table<BundleID: string, PackageTypeID: string, PackageVersion: int, Priority: int, SubscriptionType: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: PackageTypetoBundles_Get
export def "package-typeto-bundles-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --bundle-id: string # Optional. Filter by BundleID.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/PackageTypetoBundles"
    query: [{name: BundleID, var: bundle_id}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    bundle_id: $bundle_id, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a new Package Type ID to Bundle Relationship.
#
# POST /api/v2/PackageTypetoBundles
# operationId: PackageTypetoBundles_Post
export def "package-typeto-bundles-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  bundle_id: string # The bundle to include the package in.
  package_type_id: string # The package type id of the package to include
  package_version: int # The package version of the package to include (format: int32)
  priority: int # The execution priority of the package relative to other packages in the bundle. Range 1 - 100, lower value indication higher priority. (format: int32)
  --subscription-type: string@subscription-type-completer # Optional. The type of subscription supported. The default subscription type is Required.
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/PackageTypetoBundles"
    body: {content_type: "application/json", kind: json, fields: [{name: BundleID, var: bundle_id}, {name: PackageTypeID, var: package_type_id}, {name: PackageVersion, var: package_version}, {name: Priority, var: priority}, {name: SubscriptionType, var: subscription_type}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    bundle_id: $bundle_id, package_type_id: $package_type_id, package_version: $package_version, priority: $priority, subscription_type: $subscription_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Package Type ID to Bundle Relationship.
#
# PUT /api/v2/PackageTypetoBundles
# operationId: PackageTypetoBundles_Put
export def "package-typeto-bundles-put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  bundle_id: string # The bundle to include the package in.
  package_type_id: string # The package type id of the package to include
  package_version: int # The package version of the package to include (format: int32)
  priority: int # The execution priority of the package relative to other packages in the bundle. Range 1 - 100, lower value indication higher priority. (format: int32)
  --subscription-type: string@subscription-type-completer # Optional. The type of subscription supported. The default subscription type is Required.
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/PackageTypetoBundles"
    body: {content_type: "application/json", kind: json, fields: [{name: BundleID, var: bundle_id}, {name: PackageTypeID, var: package_type_id}, {name: PackageVersion, var: package_version}, {name: Priority, var: priority}, {name: SubscriptionType, var: subscription_type}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    bundle_id: $bundle_id, package_type_id: $package_type_id, package_version: $package_version, priority: $priority, subscription_type: $subscription_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Packages.
#
# GET /api/v2/Packages
# Returns: record<Entities: table<Autorun: bool, CRC: string, Description: string, LocalizedName: string, Notes: string, PackageID: string, PackageTypeID: string, PreviousVersion: int, ReleaseDate: string, Released: bool, RemoveOnSuccess: bool, Size: int, Switches: string, Url: string, Version: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: Packages_GetPackages
export def "packages-get-packages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
  --package-type-id: string # Optional. If provided, filters by PackageTypeID.
  --version: int # Optional. If provided, filters by Version. (format: int32)
  --released: oneof<nothing, bool> # Optional. If provided, filters by Released.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Packages"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: PackageTypeID, var: package_type_id}, {name: Version, var: version}, {name: Released, var: released}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, package_type_id: $package_type_id, version: $version, released: $released
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a Package to the Update System.
#
# POST /api/v2/Packages
# Returns: string
# operationId: Packages_PostPackage
export def "packages-post-package" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --autorun: oneof<nothing, bool> # Value is true if package should run automatically. Default value is false.
  crc: string # The CRC used to validate the download.
  description: string # The package description
  --localized-name: string # Optional. The StringID used to localize the name of the Package
  --notes: string # Notes about the package
  --package-id: string # Read Only. The package ID
  package_type_id: string # The id of the package type this package belongs to.
  --previous-version: int # For delta packages, the previous version required. For non-delta packages, the Previous version is 0. Default value is 0. (format: int32)
  release_date: string # The date the package was released (format: date-time)
  --released: oneof<nothing, bool> # True if the package is released. Default value is False.
  --remove-on-success: oneof<nothing, bool> # True to remove the package after successful execution. Default value is False.
  --size: int # The size of the file at the specified URL. If a size is not supplied at creation time, the size will be determined by the response from the URL. If the size provided does not match the size in the response from the URL an error will be returned. (format: int64)
  --switches: string # The command line arguments for the package. Default value is an empty string.
  url: string # The Url to download the package from.
  version: int # The version. (format: int32)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/Packages"
    body: {content_type: "application/json", kind: json, fields: [{name: Autorun, var: autorun}, {name: CRC, var: crc}, {name: Description, var: description}, {name: LocalizedName, var: localized_name}, {name: Notes, var: notes}, {name: PackageID, var: package_id}, {name: PackageTypeID, var: package_type_id}, {name: PreviousVersion, var: previous_version}, {name: ReleaseDate, var: release_date}, {name: Released, var: released}, {name: RemoveOnSuccess, var: remove_on_success}, {name: Size, var: size}, {name: Switches, var: switches}, {name: Url, var: url}, {name: Version, var: version}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    autorun: $autorun, crc: $crc, description: $description, localized_name: $localized_name, notes: $notes, package_id: $package_id, package_type_id: $package_type_id, previous_version: $previous_version, release_date: $release_date, released: $released, remove_on_success: $remove_on_success, size: $size, switches: $switches, url: $url, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a Package.
#
# DELETE /api/v2/Packages/{ID}
# operationId: Packages_DeletePackage
export def "packages-delete-package" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v2/Packages/{ID}"
    path_params: [{name: ID, var: id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find a Package.
#
# GET /api/v2/Packages/{ID}
# Returns: record<Autorun: bool, CRC: string, Description: string, LocalizedName: string, Notes: string, PackageID: string, PackageTypeID: string, PreviousVersion: int, ReleaseDate: string, Released: bool, RemoveOnSuccess: bool, Size: int, Switches: string, Url: string, Version: int>
# operationId: Packages_GetPackage
export def "packages-get-package" [
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
    path: "/api/v2/Packages/{ID}"
    path_params: [{name: ID, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Modify a Packge to the Update System.
#
# PUT /api/v2/Packages/{ID}
# operationId: Packages_PutPackage
export def "packages-put-package" [
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
  --autorun: oneof<nothing, bool> # Value is true if package should run automatically. Default value is false.
  crc: string # The CRC used to validate the download.
  description: string # The package description
  --localized-name: string # Optional. The StringID used to localize the name of the Package
  --notes: string # Notes about the package
  --package-id: string # Read Only. The package ID
  package_type_id: string # The id of the package type this package belongs to.
  --previous-version: int # For delta packages, the previous version required. For non-delta packages, the Previous version is 0. Default value is 0. (format: int32)
  release_date: string # The date the package was released (format: date-time)
  --released: oneof<nothing, bool> # True if the package is released. Default value is False.
  --remove-on-success: oneof<nothing, bool> # True to remove the package after successful execution. Default value is False.
  --size: int # The size of the file at the specified URL. If a size is not supplied at creation time, the size will be determined by the response from the URL. If the size provided does not match the size in the response from the URL an error will be returned. (format: int64)
  --switches: string # The command line arguments for the package. Default value is an empty string.
  url: string # The Url to download the package from.
  version: int # The version. (format: int32)
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/Packages/{ID}"
    path_params: [{name: ID, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Autorun, var: autorun}, {name: CRC, var: crc}, {name: Description, var: description}, {name: LocalizedName, var: localized_name}, {name: Notes, var: notes}, {name: PackageID, var: package_id}, {name: PackageTypeID, var: package_type_id}, {name: PreviousVersion, var: previous_version}, {name: ReleaseDate, var: release_date}, {name: Released, var: released}, {name: RemoveOnSuccess, var: remove_on_success}, {name: Size, var: size}, {name: Switches, var: switches}, {name: Url, var: url}, {name: Version, var: version}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id, autorun: $autorun, crc: $crc, description: $description, localized_name: $localized_name, notes: $notes, package_id: $package_id, package_type_id: $package_type_id, previous_version: $previous_version, release_date: $release_date, released: $released, remove_on_success: $remove_on_success, size: $size, switches: $switches, url: $url, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Permissions
#
# GET /api/v2/Permissions
# Returns: record<Entities: table<DataDescription: string, DataRequired: string, Description: string, Id: int, Name: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: Permissions_GetPermissions
export def "permissions-get-permissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
  --name: string # Filter by permission name. Supports ending wildcard (*). Optional.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Permissions"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: name, var: name}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Adds a Permission
#
# POST /api/v2/Permissions
# Returns: int
# operationId: Permissions_PostPermission
export def "permissions-post-permission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-description: string # Description of data to be provided with Role Authorization
  data_required: string@data-required-completer # Indicates if data is required or optional
  --description: string
  --id: int # The identifier of the permission. (format: int32)
  name: string # The name of the permission.
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/Permissions"
    body: {content_type: "application/json", kind: json, fields: [{name: DataDescription, var: data_description}, {name: DataRequired, var: data_required}, {name: Description, var: description}, {name: Id, var: id}, {name: Name, var: name}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    data_description: $data_description, data_required: $data_required, description: $description, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Deletes a Permission
#
# DELETE /api/v2/Permissions/{id}
# operationId: Permissions_DeletePermission
export def "permissions-delete-permission" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v2/Permissions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a Permission
#
# GET /api/v2/Permissions/{id}
# Returns: record<DataDescription: string, DataRequired: string, Description: string, Id: int, Name: string>
# operationId: Permissions_GetPermission
export def "permissions-get-permission" [
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
    path: "/api/v2/Permissions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates a Permission
#
# PUT /api/v2/Permissions/{id}
# operationId: Permissions_PutPermission
export def "permissions-put-permission" [
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
  --data-description: string # Description of data to be provided with Role Authorization
  data_required: string@data-required-completer # Indicates if data is required or optional
  --description: string
  --body-id: int # The identifier of the permission. (format: int32) (spec name: Id)
  name: string # The name of the permission.
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/Permissions/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: DataDescription, var: data_description}, {name: DataRequired, var: data_required}, {name: Description, var: description}, {name: Id, var: body_id}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, data_description: $data_description, data_required: $data_required, description: $description, body_id: $body_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of Priority Packages by Client.
#
# GET /api/v2/PriorityPackages
# Returns: record<Entities: table<Autorun: bool, CRC: string, ClientID: string, Description: string, Notes: string, PackageID: string, PackageTypeID: string, PreviousVersion: int, PriorityPackageID: string, ReleaseDate: string, Released: bool, RemoveOnSuccess: bool, Size: int, Switches: string, TimeStamp: string, Url: string, Version: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: PriorityPackages_GetPriorityPackages
export def "priority-packages-get-priority-packages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --client-id: string # Optional. Filter priority packages by ClientID.
  --status: string@status-completer-1 # Optional. Filter returned packages by status. By default only active packages will be returned.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/PriorityPackages"
    query: [{name: ClientID, var: client_id}, {name: Status, var: status}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, status: $status, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a Priority Package for a Client.
#
# POST /api/v2/PriorityPackages
# Returns: string
# operationId: PriorityPackages_PostPriorityPackages
export def "priority-packages-post-priority-packages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --autorun: oneof<nothing, bool> # Read Only. From the package specified by package ID. Value is true if package should run automatically. Default value is false.
  --crc: string # Read Only. From the package specified by package ID.
  client_id: string # The ID of the client to receive the priority package
  --description: string # Read Only. From the package specified by package ID.
  --notes: string # Read Only. From the package specified by package ID.
  package_id: string # The ID of the package to push as a priority package.
  --package-type-id: string # Read Only. From the package specified by package ID.
  --previous-version: int # Read Only. From the package specified by package ID. (format: int32)
  --priority-package-id: string # Read Only. The ID of the priority package.
  --release-date: string # Read Only. From the package specified by package ID. The date the package was released (format: date-time)
  --released: oneof<nothing, bool> # Read Only. From the package specified by package ID.
  --remove-on-success: oneof<nothing, bool> # Read Only. From the package specified by package ID.
  --size: int # Read Only. From the package specified by package ID. (format: int64)
  --switches: string # The command line arguments for the priority package. Default value is an empty string.
  --time-stamp: string # Read Only. The timestamp of the priority package. (format: date-time)
  --url: string # Read Only. From the package specified by package ID.
  --version: int # Read Only. From the package specified by package ID. (format: int32)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/PriorityPackages"
    body: {content_type: "application/json", kind: json, fields: [{name: Autorun, var: autorun}, {name: CRC, var: crc}, {name: ClientID, var: client_id}, {name: Description, var: description}, {name: Notes, var: notes}, {name: PackageID, var: package_id}, {name: PackageTypeID, var: package_type_id}, {name: PreviousVersion, var: previous_version}, {name: PriorityPackageID, var: priority_package_id}, {name: ReleaseDate, var: release_date}, {name: Released, var: released}, {name: RemoveOnSuccess, var: remove_on_success}, {name: Size, var: size}, {name: Switches, var: switches}, {name: TimeStamp, var: time_stamp}, {name: Url, var: url}, {name: Version, var: version}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    autorun: $autorun, crc: $crc, client_id: $client_id, description: $description, notes: $notes, package_id: $package_id, package_type_id: $package_type_id, previous_version: $previous_version, priority_package_id: $priority_package_id, release_date: $release_date, released: $released, remove_on_success: $remove_on_success, size: $size, switches: $switches, time_stamp: $time_stamp, url: $url, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a Priority Package for a Client.
#
# DELETE /api/v2/PriorityPackages/{ID}
# operationId: PriorityPackages_DeletePriorityPackages
export def "priority-packages-delete-priority-packages" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v2/PriorityPackages/{ID}"
    path_params: [{name: ID, var: id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Priority Packages for a Client.
#
# GET /api/v2/PriorityPackages/{ID}
# Returns: record<Autorun: bool, CRC: string, ClientID: string, Description: string, Notes: string, PackageID: string, PackageTypeID: string, PreviousVersion: int, PriorityPackageID: string, ReleaseDate: string, Released: bool, RemoveOnSuccess: bool, Size: int, Switches: string, TimeStamp: string, Url: string, Version: int>
# operationId: PriorityPackages_GetPriorityPackage
export def "priority-packages-get-priority-package" [
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
    path: "/api/v2/PriorityPackages/{ID}"
    path_params: [{name: ID, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Release
#
# GET /api/v2/Releases
# Returns: record<Entities: table<BuildDate: string, BundleIDs: list, ReleaseDate: string, ReleaseID: int, ReleaseNumber: string, Visible: bool>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: Release_GetReleases
export def "release-get-releases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
  --visible: oneof<nothing, bool> # Optional. Filter by visible.
  --bundle-id: string # Optional. Filter by BundleID.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Releases"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: visible, var: visible}, {name: bundleID, var: bundle_id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, visible: $visible, bundle_id: $bundle_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a Release
#
# POST /api/v2/Releases
# Returns: int
# operationId: Release_PostRelease
export def "release-post-release" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --build-date: string # Build Date (format: date-time)
  --bundle-i-ds: list<string> # IDs of AUC Bundles associated with this Release.
  --release-date: string # Release Date (format: date-time)
  --release-id: int # Release ID (format: int32)
  --release-number: string # Release Number
  --visible: oneof<nothing, bool> # Visible
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/Releases"
    body: {content_type: "application/json", kind: json, fields: [{name: BuildDate, var: build_date}, {name: BundleIDs, var: bundle_i_ds}, {name: ReleaseDate, var: release_date}, {name: ReleaseID, var: release_id}, {name: ReleaseNumber, var: release_number}, {name: Visible, var: visible}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    build_date: $build_date, bundle_i_ds: $bundle_i_ds, release_date: $release_date, release_id: $release_id, release_number: $release_number, visible: $visible
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a Release by ID
#
# GET /api/v2/Releases/{ReleaseId}
# Returns: record<BuildDate: string, BundleIDs: list<string>, ReleaseDate: string, ReleaseID: int, ReleaseNumber: string, Visible: bool>
# operationId: Release_GetRelease
export def "release-get-release" [
  release_id: int
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/api/v2/Releases/{ReleaseId}"
    path_params: [{name: ReleaseId, var: release_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    release_id: $release_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Deletes the association between a release and a bundle.
#
# DELETE /api/v2/Releases/{ReleaseId}/Bundle/{BundleId}
# operationId: Release_DeleteReleaseBundle
export def "release-delete-release-bundle" [
  release_id: int
  bundle_id: string
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
    path: "/api/v2/Releases/{ReleaseId}/Bundle/{BundleId}"
    path_params: [{name: ReleaseId, var: release_id}, {name: BundleId, var: bundle_id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    release_id: $release_id, bundle_id: $bundle_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates the release with a bundle.
#
# POST /api/v2/Releases/{ReleaseId}/Bundle/{BundleId}
# operationId: Release_PostReleaseBundle
export def "release-post-release-bundle" [
  release_id: int
  bundle_id: string
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
    path: "/api/v2/Releases/{ReleaseId}/Bundle/{BundleId}"
    path_params: [{name: ReleaseId, var: release_id}, {name: BundleId, var: bundle_id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    release_id: $release_id, bundle_id: $bundle_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Release
#
# PUT /api/v2/Releases/{releaseId}
# operationId: Release_PutContentDefinition
export def "release-put-content-definition" [
  release_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --build-date: string # Build Date (format: date-time)
  --bundle-i-ds: list<string> # IDs of AUC Bundles associated with this Release.
  --release-date: string # Release Date (format: date-time)
  --body-release-id: int # Release ID (format: int32) (spec name: ReleaseID)
  --release-number: string # Release Number
  --visible: oneof<nothing, bool> # Visible
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/Releases/{releaseId}"
    path_params: [{name: releaseId, var: release_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: BuildDate, var: build_date}, {name: BundleIDs, var: bundle_i_ds}, {name: ReleaseDate, var: release_date}, {name: ReleaseID, var: body_release_id}, {name: ReleaseNumber, var: release_number}, {name: Visible, var: visible}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    release_id: $release_id, build_date: $build_date, bundle_i_ds: $bundle_i_ds, release_date: $release_date, body_release_id: $body_release_id, release_number: $release_number, visible: $visible
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a summary of all Packages in a Bundle
#
# GET /api/v2/Reporting/BundleStatusSummary
# Returns: record<Entities: table<AverageDownloadTime: string, AverageInstallTime: string, Downloaded: int, Error: int, Installed: int, Package: string, PackageID: string, PackageStatusItems: list>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: Reporting_BundleStatusSummary
export def "reporting-bundle-status-summary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --bundle-id: string # The BundleID (required)
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Reporting/BundleStatusSummary"
    query: [{name: BundleID, var: bundle_id, required: true}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    bundle_id: $bundle_id, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a list of bundles for UpdateGroup.
#
# GET /api/v2/Reporting/BundlesInUpdateGroup
# Returns: record<Entities: table<Active: bool, BundleID: string, BundleNumber: int, Description: string, UpdateGroupID: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: Reporting_BundlesInUpdateGroup
export def "reporting-bundles-in-update-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --id: string # The UpdateGroupID (required)
  --include-inactive: oneof<nothing, bool> # Include Inactive Bundles (true|false) (required)
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Reporting/BundlesInUpdateGroup"
    query: [{name: ID, var: id, required: true}, {name: IncludeInactive, var: include_inactive, required: true}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include_inactive: $include_inactive, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Client Information
#
# GET /api/v2/Reporting/ClientInfo
# Returns: record<ClientID: string, Package: table<Categories: list, PackageDescription: string, PackageID: string>>
# operationId: Reporting_ClientInfo
export def "reporting-client-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --client-id: string # The Client ID (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Reporting/ClientInfo"
    query: [{name: ClientID, var: client_id, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the current packages for an update group.
#
# GET /api/v2/Reporting/CurrentPackagesInUpdateGroup
# Returns: table<Autorun: bool, CRC: string, Description: string, LocalizedName: string, Notes: string, PackageID: string, PackageTypeID: string, PreviousVersion: int, ReleaseDate: string, Released: bool, RemoveOnSuccess: bool, Size: int, Switches: string, Url: string, Version: int>
# operationId: Reporting_CurrentPackagesInUpdateGroup
export def "reporting-current-packages-in-update-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: string # The UpdateGroupID (required)
  --subscription-type-filter: string@subscription-type-filter-completer # Optional. The subscription type filter to use. By default the Default packages (Required and IncludeByDefault) will be returned.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Reporting/CurrentPackagesInUpdateGroup"
    query: [{name: ID, var: id, required: true}, {name: SubscriptionTypeFilter, var: subscription_type_filter}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, subscription_type_filter: $subscription_type_filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a Client in the Update System.
#
# GET /api/v2/Reporting/GetClient
# Returns: record<ClientID: string, LastCheckin: string, Tag: string>
# operationId: Reporting_GetClient
export def "reporting-get-client" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: string # The Client ID (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Reporting/GetClient"
    query: [{name: ID, var: id, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a list of current Client Subscriptions.
#
# GET /api/v2/Reporting/GetSubscriptions
# Returns: record<Entities: table<Active: bool, ClientID: string, LastCheckin: string, RelationshipID: string, UpdateGroupID: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: Reporting_GetSubscriptions
export def "reporting-get-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --client-id: string # Optional. Filter by Client ID
  --update-group-id: string # Optional. Filter by Update Group ID
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Reporting/GetSubscriptions"
    query: [{name: ClientID, var: client_id}, {name: UpdateGroupID, var: update_group_id}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, update_group_id: $update_group_id, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a summary report for a Specific Package
#
# GET /api/v2/Reporting/PackageStatusSummary
# Returns: record<AverageDownloadTime: string, AverageInstallTime: string, Downloaded: int, Error: int, Installed: int, Package: string, PackageID: string, PackageStatusItems: table<ClientID: string, ClientKey: string, DownloadTime: string, Downloaded: string, InstallCompleted: string, InstallResult: string, InstallStarted: string, InstallTime: string, Percentage: string, Size: string, Timestamp: string>>
# operationId: Reporting_PackageStatusSummary
export def "reporting-package-status-summary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --package-id: string # The Package ID (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Reporting/PackageStatusSummary"
    query: [{name: PackageID, var: package_id, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    package_id: $package_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a list of subscribed clients
#
# GET /api/v2/Reporting/RegisteredClients
# Returns: record<Entities: table<ClientID: string, LastCheckin: string, MinutesElapsed: int, ReportResult: string, ReportResultIsValid: bool, ReportValue: string, Tag: string>, Metadata: record<Limit: int, Offset: int, ReportResultExpected: string, ReportResultLabel: string, ReportValueLabel: string, TotalCount: int>>
# operationId: Reporting_RegisteredClients
export def "reporting-registered-clients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --update-group-id: string # Optional but required when including any or all of following parameters: ReportValue, ReportResult, ReportResultIsValid. The Update Group ID. If not provided, all clients will be returned.
  --client-id: string # Optional. Filter where ClientID matches a value. Wildcards are supported (*).
  --tag: string # Optional. Filter where Tag matches a value. Wildcards are supported (*).
  --report-result: string # Optional and UpdateGroupID must be included. Filter where ReportResult matches a value. Wildcards are supported (*).
  --report-result-is-valid: oneof<nothing, bool> # Optional and UpdateGroupID must be included. When 'true' filters results where ReportResult equals ReportResultExpected. When 'false' filters results where ValueToValidate does not equal ReportResults.
  --report-value: string # Optional and UpdateGroupID must be included. Filter where ReportValue matches a value. Wildcards are supported (*).
  --last-check-in-before: string # Optional. Filter where LastCheckIn occured before the provided date. (format: date-time)
  --last-check-in-after: string # Optional. Filter where LastCheckIn occured after the provided date. (format: date-time)
  --order-by: string # Optional. Specify the order in which results should be returned. Use this format: [FieldName] [ASC|ASCENDING|DESC|DESCENDING],... If sort direction is not provided for a field, it will be sorted ascending.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Reporting/RegisteredClients"
    query: [{name: UpdateGroupID, var: update_group_id}, {name: ClientID, var: client_id}, {name: Tag, var: tag}, {name: ReportResult, var: report_result}, {name: ReportResultIsValid, var: report_result_is_valid}, {name: ReportValue, var: report_value}, {name: LastCheckInBefore, var: last_check_in_before}, {name: LastCheckInAfter, var: last_check_in_after}, {name: OrderBy, var: order_by}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    update_group_id: $update_group_id, client_id: $client_id, tag: $tag, report_result: $report_result, report_result_is_valid: $report_result_is_valid, report_value: $report_value, last_check_in_before: $last_check_in_before, last_check_in_after: $last_check_in_after, order_by: $order_by, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a list of Update Groups. Update Groups are used by the client to register for a specific type of update.
#
# GET /api/v2/Reporting/UpdateGroups
# Returns: record<Entities: table<Description: string, ID: string, InventoryFrequency: int, InventoryPackage: string, LocalizedDescription: string, LocalizedName: string, Priority: int, ReportField: string, UpdateType: string, ValidatingField: string, ValueToValidate: string, Version: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: Reporting_UpdateGroups
export def "reporting-update-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Reporting/UpdateGroups"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get data for pie charts in UpdateMetrics.
#
# GET /api/v2/Reporting/UpdateMetrics
# Returns: record<ActiveVersion: string, ActiveVersionByClient: table<BundleNumber: int, ClientCount: int, ReleaseName: string>, CurrentStateByClient: table<ClientCount: int, State: string>, CutOffDate: string, DataRefreshed: string, FilteredClientCount: int, PackageErrors: table<ClientCount: int, ErrorCode: string, LongDescription: string, ShortDescription: string>, TotalClientCount: int>
# operationId: Reporting_UpdateMetrics
export def "reporting-update-metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --update-group-id: string # The UpdateType in which clients must be for the report to include them. (required)
  --bundle-number: int # Optional. Tells us which chart to show based upon filter. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Reporting/UpdateMetrics"
    query: [{name: UpdateGroupID, var: update_group_id, required: true}, {name: bundleNumber, var: bundle_number}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    update_group_id: $update_group_id, bundle_number: $bundle_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Roles
#
# GET /api/v2/Roles
# Returns: record<Entities: table<Description: string, Id: int, Name: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: Roles_GetRoles
export def "roles-get-roles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
  --name: string # Optional. Finds a role with the given name.
  --permission-id: int # format: int32
  --permission-name: string # Optional. Filters roles by whether they contain the provided permission.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Roles"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: name, var: name}, {name: permissionID, var: permission_id}, {name: permissionName, var: permission_name}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, name: $name, permission_id: $permission_id, permission_name: $permission_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Adds a User Role
#
# POST /api/v2/Roles
# Returns: int
# operationId: Roles_PostRole
export def "roles-post-role" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  description: string # Role description
  --id: int # The role's identifier. (format: int32)
  name: string # The name of the role. Must be alpha-numeric strings separated by a period (.).
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/Roles"
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: Id, var: id}, {name: Name, var: name}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    description: $description, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Deletes a User Role
#
# DELETE /api/v2/Roles/{id}
# operationId: Roles_DeleteRole
export def "roles-delete-role" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v2/Roles/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a User Role
#
# GET /api/v2/Roles/{id}
# Returns: record<Description: string, Id: int, Name: string>
# operationId: Roles_GetRole
export def "roles-get-role" [
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
    path: "/api/v2/Roles/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates a User Role
#
# PUT /api/v2/Roles/{id}
# operationId: Roles_PutRole
export def "roles-put-role" [
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
  description: string # Role description
  --body-id: int # The role's identifier. (format: int32) (spec name: Id)
  name: string # The name of the role. Must be alpha-numeric strings separated by a period (.).
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/Roles/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: Id, var: body_id}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, description: $description, body_id: $body_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the Permissions for a Role
#
# GET /api/v2/Roles/{id}/Permissions
# Returns: record<Entities: table<DataDescription: string, DataRequired: string, Description: string, Id: int, Name: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: Roles_GetRolePermissions
export def "roles-get-role-permissions" [
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
  --accept: string@accept-completer-1 # Response content type
  --name: string # Filter by permission name. Optional.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Roles/{id}/Permissions"
    path_params: [{name: id, var: id}]
    query: [{name: name, var: name}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Manage the Permissions for a Role
#
# PUT /api/v2/Roles/{id}/Permissions
# operationId: Roles_PutRolePermissions
export def "roles-put-role-permissions" [
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
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/Roles/{id}/Permissions"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all user's in a role
#
# GET /api/v2/Roles/{id}/Users
# Returns: record<Entities: table<ChangePassword: string, Email: string, Name: string, Password: string, UserID: int, Username: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: UserPermissions_GetUsers
export def "user-permissions-get-users" [
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
  --accept: string@accept-completer-1 # Response content type
  --limit: int # The page limit. The default page limit is 10. (format: int32)
  --offset: int # The page offset. The default page offset is 0. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Roles/{id}/Users"
    path_params: [{name: id, var: id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a Role's users
#
# PUT /api/v2/Roles/{id}/Users
export def "put-api-v2-roles-id-users" [
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
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/Roles/{id}/Users"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a paged response of Global String Definitions.
#
# GET /api/v2/StringDefinitions
# Returns: record<Entities: table<DescriptionForTranslator: string, DoNotTranslate: bool, Id: string, ParameterCount: int, Timestamp: string, Translations: list>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: StringDefinitions_GetDefinitions
export def "string-definitions-get-definitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: int # Optional. The page limit. The default page limit is 10. Ignored if 'stringIds' is provided. (format: int32)
  --modified-after-timestamp: string # Optional. Return only the StringDefinition objects that have a Timestamp value greater than that provided. This will be an encoded byte array.
  --include-translations: oneof<nothing, bool> # Optional. Indicates whether to include the StringTranslations for the StringDefinition. Defaults to false.
  --string-text: string # Optional. The text for which to search in the StringDefinition object’s translations. Only StringDefinition objects for matching StringTranslation objects are returned. Does not filter if no value is provided. Supports beginning and/or ending wildcards. includeTranslations must be true.
  --description-text: string # Optional. The text for which to search in the StringDefinition description field. Only matching objects are returned. Does not filter if no value is provided. Supports beginning and/or ending wildcards.
  --use-full-text: oneof<nothing, bool> # Optional. This flag is used to determin whether to use the FullText Search or not.
  --include-deleted-languages: oneof<nothing, bool> # Optional. Indicates whether to include languages marked as deleted. includeTranslations must be true. Defaults to false.
  --language-ids: string # Optional. A comma-delimited list of language ids. Only StringTranslation objects with a matching language id will be returned. Optional. By default all locales are returned. includeTranslations must be true. The StringDefinition is still returned even if the filtered translations list is empty.
  --string-ids: string # Optional. A comma-delimited list of string ids. Up to 40 string IDs may be provided. May not be used with 'modifiedAfterTimestamp', 'stringText', 'descriptionText', or 'useFullText'.
  --matching-translations-only: oneof<nothing, bool> # Optional. If false, all translations for returned String Definitions are included. Must be used with 'stringText' provided and 'includeTranslations' = true.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/StringDefinitions"
    query: [{name: limit, var: limit}, {name: modifiedAfterTimestamp, var: modified_after_timestamp}, {name: includeTranslations, var: include_translations}, {name: stringText, var: string_text}, {name: descriptionText, var: description_text}, {name: useFullText, var: use_full_text}, {name: includeDeletedLanguages, var: include_deleted_languages}, {name: languageIds, var: language_ids}, {name: stringIds, var: string_ids}, {name: matchingTranslationsOnly, var: matching_translations_only}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, modified_after_timestamp: $modified_after_timestamp, include_translations: $include_translations, string_text: $string_text, description_text: $description_text, use_full_text: $use_full_text, include_deleted_languages: $include_deleted_languages, language_ids: $language_ids, string_ids: $string_ids, matching_translations_only: $matching_translations_only
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create StringDefinition object. The originating translation must be provided. Accepts an array of StringDefinition objects. Returns nothing.
#
# POST /api/v2/StringDefinitions/Batch
# operationId: StringDefinitions_PostDefinition
export def "string-definitions-post-definition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/StringDefinitions/Batch"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update StringDefinition objects. Accepts an array of StringDefinition objects. This endpoint will add StringDefinitionChange objects to the database. The DescriptionForTranslator may not be modified after a String is submitted for translation.
#
# PUT /api/v2/StringDefinitions/Batch
# operationId: StringDefinitions_UpdateDefinitions
export def "string-definitions-update-definitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/StringDefinitions/Batch"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a paged response of Global String Definitions.
#
# GET /api/v2/StringDefinitions/{ID}
# Returns: record<DescriptionForTranslator: string, DoNotTranslate: bool, Id: string, ParameterCount: int, Timestamp: string, Translations: table<AuthorId: int, LanguageId: int, State: string, StringId: string, StringValue: string, Timestamp: string>>
# operationId: StringDefinitions_GetDefinition
export def "string-definitions-get-definition" [
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
  --include-translations: oneof<nothing, bool> # Optional. Indicates whether to include the StringTranslations for the StringDefinition. Defaults to false.
  --include-deleted-languages: oneof<nothing, bool> # Optional. Indicates whether to include languages marked as deleted. includeTranslations must be true. Defaults to false.
  --language-ids: string # Optional. A comma-delimited list of language ids. Only StringTranslation objects with a matching language id will be returned. Optional. By default all locales are returned. includeTranslations must be true. The StringDefinition is still returned even if the filtered translations list is empty.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/StringDefinitions/{ID}"
    path_params: [{name: ID, var: id}]
    query: [{name: includeTranslations, var: include_translations}, {name: includeDeletedLanguages, var: include_deleted_languages}, {name: languageIds, var: language_ids}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include_translations: $include_translations, include_deleted_languages: $include_deleted_languages, language_ids: $language_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a paged response of Global String Translations.
#
# GET /api/v2/StringTranslations
# Returns: record<Entities: table<AuthorId: int, LanguageId: int, State: string, StringId: string, StringValue: string, Timestamp: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: StringTranslations_GetTranslations
export def "string-translations-get-translations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --modified-after-timestamp: string # Optional. Return only the StringDefinition objects that have a Timestamp value greater than that provided. This will be an encoded byte array.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/StringTranslations"
    query: [{name: limit, var: limit}, {name: modifiedAfterTimestamp, var: modified_after_timestamp}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, modified_after_timestamp: $modified_after_timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update corrections to string translations
#
# PUT /api/v2/StringTranslations/Batch
# operationId: StringTranslations_UpdateTranslations
export def "string-translations-update-translations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/StringTranslations/Batch"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single translation based upon stringId and languageId
#
# GET /api/v2/StringTranslations/{stringId}/{languageId}
# Returns: record<AuthorId: int, LanguageId: int, State: string, StringId: string, StringValue: string, Timestamp: string>
# operationId: StringTranslations_GetTranslation
export def "string-translations-get-translation" [
  string_id: string
  language_id: int
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/api/v2/StringTranslations/{stringId}/{languageId}"
    path_params: [{name: stringId, var: string_id}, {name: languageId, var: language_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    string_id: $string_id, language_id: $language_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a string value or a state for a string translation.
#
# PUT /api/v2/StringTranslations/{stringId}/{languageId}
# operationId: StringTranslations_UpdateTranslation
export def "string-translations-update-translation" [
  string_id: string
  language_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author-id: int # The id of the user to last edit thie translation (format: int32)
  --body-language-id: int # The id of the language of the translation (format: int32) (spec name: LanguageId)
  --state: string@state-completer-3 # The state of the translation
  --body-string-id: string # The id of the string that is translated (spec name: StringId)
  string_value: string # The translated string
  --timestamp: string # A value indicating the last modification of this translation. Read Only. (format: byte)
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/StringTranslations/{stringId}/{languageId}"
    path_params: [{name: stringId, var: string_id}, {name: languageId, var: language_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: AuthorId, var: author_id}, {name: LanguageId, var: body_language_id}, {name: State, var: state}, {name: StringId, var: body_string_id}, {name: StringValue, var: string_value}, {name: Timestamp, var: timestamp}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    string_id: $string_id, language_id: $language_id, author_id: $author_id, body_language_id: $body_language_id, state: $state, body_string_id: $body_string_id, string_value: $string_value, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a paged response of TranslationKeys.
#
# GET /api/v2/TranslationKeys
# Returns: record<Entities: table<ID: int, KeyName: string, StringID: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: TranslationKeys_Get
export def "translation-keys-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: int # format: int32
  --offset: int # format: int32
  --key-names: string # Can filter by keyNames, a comma deliminated list.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/TranslationKeys"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: keyNames, var: key_names}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, key_names: $key_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a translationKey object.
#
# POST /api/v2/TranslationKeys
# Returns: int
# operationId: TranslationKeys_CreateTranslationKey
export def "translation-keys-create-translation-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: int # The identifier for the translationKey. Read Only. (format: int32)
  key_name: string # The key name of the item. One example is tkODX_HWIKM14R01
  string_id: string # Foreign key to StringDefinitionID
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/TranslationKeys"
    body: {content_type: "application/json", kind: json, fields: [{name: ID, var: id}, {name: KeyName, var: key_name}, {name: StringID, var: string_id}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, key_name: $key_name, string_id: $string_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get TranslationKey by ID
#
# GET /api/v2/TranslationKeys/{ID}
# Returns: record<ID: int, KeyName: string, StringID: string>
# operationId: TranslationKeys_GetTranslationKey
export def "translation-keys-get-translation-key" [
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
    path: "/api/v2/TranslationKeys/{ID}"
    path_params: [{name: ID, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update the StringID of the translationKey object.
#
# PUT /api/v2/TranslationKeys/{ID}
# operationId: TranslationKeys_UpdateTranslationKey
export def "translation-keys-update-translation-key" [
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
  --body-id: int # The identifier for the translationKey. Read Only. (format: int32) (spec name: ID)
  key_name: string # The key name of the item. One example is tkODX_HWIKM14R01
  string_id: string # Foreign key to StringDefinitionID
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/TranslationKeys/{ID}"
    path_params: [{name: ID, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ID, var: body_id}, {name: KeyName, var: key_name}, {name: StringID, var: string_id}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id, body_id: $body_id, key_name: $key_name, string_id: $string_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all TranslationRequest objects. Returns a PagedResponse of TranslationRequest objects with their language ids and string ids.
#
# GET /api/v2/TranslationRequests
# Returns: record<Entities: table<ApprovalUserId: int, CCEmailAddresses: list, ChargeToAccount: string, Deadline: string, Id: int, LocaleIds: list, Notes: string, QuestionsUserId: int, State: string, SubmittedBy: int, TranslatorEmail: string, TranslatorName: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: TranslationRequests_GetTranslationRequests
export def "translation-requests-get-translation-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: int # format: int32
  --offset: int # format: int32
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/TranslationRequests"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a translation request. Accepts a TranslationRequest object. Returns the Id of the created object. The state of the TranslationRequest must be ‘NotSubmitted’.
#
# POST /api/v2/TranslationRequests
# Returns: int
# operationId: TranslationRequests_CreateTranslationRequest
export def "translation-requests-create-translation-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --approval-user-id: int # The ID of the user from which approval for the request is required (format: int32)
  cc_email_addresses: list<string> # Additional email addresses to CC on emails pertaining to the request
  charge_to_account: string # The account to charge for the request
  deadline: string # The date by which the translations in the request are needed. Defaults to 30 days from the current date (format: date-time)
  --id: int # The ID of the request (format: int32)
  locale_ids: list<int> # Locale IDs to which these strings are requested to be translated
  notes: string # Additional notes or comments about the request
  --questions-user-id: int # The ID of the user to which to address questions regarding the request (format: int32)
  state: string@state-completer-4 # The state of the request
  --submitted-by: int # The ID of the User that submitted the request (format: int32)
  --translator-email: string # The email address for the translator
  --translator-name: string # The name of the translator
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/TranslationRequests"
    body: {content_type: "application/json", kind: json, fields: [{name: ApprovalUserId, var: approval_user_id}, {name: CCEmailAddresses, var: cc_email_addresses}, {name: ChargeToAccount, var: charge_to_account}, {name: Deadline, var: deadline}, {name: Id, var: id}, {name: LocaleIds, var: locale_ids}, {name: Notes, var: notes}, {name: QuestionsUserId, var: questions_user_id}, {name: State, var: state}, {name: SubmittedBy, var: submitted_by}, {name: TranslatorEmail, var: translator_email}, {name: TranslatorName, var: translator_name}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    approval_user_id: $approval_user_id, cc_email_addresses: $cc_email_addresses, charge_to_account: $charge_to_account, deadline: $deadline, id: $id, locale_ids: $locale_ids, notes: $notes, questions_user_id: $questions_user_id, state: $state, submitted_by: $submitted_by, translator_email: $translator_email, translator_name: $translator_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a TranslationRequest object by id. Returns TranslationRequest object with its language ids and string ids.
#
# GET /api/v2/TranslationRequests/{Id}
# Returns: record<ApprovalUserId: int, CCEmailAddresses: list<string>, ChargeToAccount: string, Deadline: string, Id: int, LocaleIds: list<int>, Notes: string, QuestionsUserId: int, State: string, SubmittedBy: int, TranslatorEmail: string, TranslatorName: string>
# operationId: TranslationRequests_GetTranslationRequest
export def "translation-requests-get-translation-request" [
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
    path: "/api/v2/TranslationRequests/{Id}"
    path_params: [{name: Id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a TranslationRequest object by id. Accepts a TranslationRequest object.
#
# PUT /api/v2/TranslationRequests/{Id}
# operationId: TranslationRequests_UpdateTranslationRequest
export def "translation-requests-update-translation-request" [
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
  --do-resend-request: oneof<nothing, bool>
  --approval-user-id: int # The ID of the user from which approval for the request is required (format: int32)
  cc_email_addresses: list<string> # Additional email addresses to CC on emails pertaining to the request
  charge_to_account: string # The account to charge for the request
  deadline: string # The date by which the translations in the request are needed. Defaults to 30 days from the current date (format: date-time)
  --body-id: int # The ID of the request (format: int32) (spec name: Id)
  locale_ids: list<int> # Locale IDs to which these strings are requested to be translated
  notes: string # Additional notes or comments about the request
  --questions-user-id: int # The ID of the user to which to address questions regarding the request (format: int32)
  state: string@state-completer-4 # The state of the request
  --submitted-by: int # The ID of the User that submitted the request (format: int32)
  --translator-email: string # The email address for the translator
  --translator-name: string # The name of the translator
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/TranslationRequests/{Id}"
    path_params: [{name: Id, var: id}]
    query: [{name: doResendRequest, var: do_resend_request}]
    body: {content_type: "application/json", kind: json, fields: [{name: ApprovalUserId, var: approval_user_id}, {name: CCEmailAddresses, var: cc_email_addresses}, {name: ChargeToAccount, var: charge_to_account}, {name: Deadline, var: deadline}, {name: Id, var: body_id}, {name: LocaleIds, var: locale_ids}, {name: Notes, var: notes}, {name: QuestionsUserId, var: questions_user_id}, {name: State, var: state}, {name: SubmittedBy, var: submitted_by}, {name: TranslatorEmail, var: translator_email}, {name: TranslatorName, var: translator_name}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id, do_resend_request: $do_resend_request, approval_user_id: $approval_user_id, cc_email_addresses: $cc_email_addresses, charge_to_account: $charge_to_account, deadline: $deadline, body_id: $body_id, locale_ids: $locale_ids, notes: $notes, questions_user_id: $questions_user_id, state: $state, submitted_by: $submitted_by, translator_email: $translator_email, translator_name: $translator_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# No Documentation Found.
#
# PUT /api/v2/TranslationRequests/{Id}/Strings
# operationId: TranslationRequests_UpdateTranslationRequestStrings
export def "translation-requests-update-translation-request-strings" [
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
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/TranslationRequests/{Id}/Strings"
    path_params: [{name: Id, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# No Documentation Found.
#
# PUT /api/v2/TranslationSetAttributes/Batch
# operationId: TranslationSets_UpdateTranslationSetAttributes
export def "translation-sets-update-translation-set-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/TranslationSetAttributes/Batch"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a set of TranslationSetAttribute object
#
# DELETE /api/v2/TranslationSetAttributes/{ID}
# operationId: TranslationSets_DeleteTranslationSetAttribute
export def "translation-sets-delete-translation-set-attribute" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v2/TranslationSetAttributes/{ID}"
    path_params: [{name: ID, var: id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a TranslationSetAttribute object
#
# PUT /api/v2/TranslationSetAttributes/{ID}
# operationId: TranslationSets_UpdateTranslationSetAttribute
export def "translation-sets-update-translation-set-attribute" [
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
  --body-id: int # The ID of this attribute. (format: int32) (spec name: ID)
  name: string # The name of this Attribute.
  --translation-set-id: int # The ID of the translation set to which this attribute belongs. (format: int32)
  --value: string # The value of this Attribute
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/TranslationSetAttributes/{ID}"
    path_params: [{name: ID, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ID, var: body_id}, {name: Name, var: name}, {name: TranslationSetID, var: translation_set_id}, {name: Value, var: value}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id, body_id: $body_id, name: $name, translation_set_id: $translation_set_id, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a PagedResponse of TranslationSet objects. Related TranslationSetStrings are NOT returned
#
# GET /api/v2/TranslationSets
# Returns: record<Entities: table<Attributes: list, FileIDs: list, Id: int, InDate: string, Notes: string, OutDate: string, State: string, TranslationRequestID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: TranslationSets_GetTranslationSets
export def "translation-sets-get-translation-sets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: int # format: int32
  --offset: int # format: int32
  --translation-request-id: int # format: int32
  --state: string@state-completer-5
  --string-id: string
  --language-id: int # format: int32
  --include-attributes: string # Names of Attributes to include when retrieving this submission. This should be a comma-separated list. If not provided, Attributes are not included. If '*', all Attributes are included.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/TranslationSets"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: translationRequestID, var: translation_request_id}, {name: state, var: state}, {name: stringId, var: string_id}, {name: languageId, var: language_id}, {name: includeAttributes, var: include_attributes}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, translation_request_id: $translation_request_id, state: $state, string_id: $string_id, language_id: $language_id, include_attributes: $include_attributes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a TranslationSet object by its id. Related TranslationSetStrings are NOT returned.
#
# GET /api/v2/TranslationSets/{ID}
# Returns: record<Attributes: table<ID: int, Name: string, TranslationSetID: int, Value: string>, FileIDs: list<string>, Id: int, InDate: string, Notes: string, OutDate: string, State: string, TranslationRequestID: int>
# operationId: TranslationSets_GetTranslationSet
export def "translation-sets-get-translation-set" [
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
  --include-attributes: string # Names of Attributes to include when retrieving this Translation set. This should be a comma-separated list. If not provided, Attributes are not included. If '*', all Attributes are included.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/TranslationSets/{ID}"
    path_params: [{name: ID, var: id}]
    query: [{name: includeAttributes, var: include_attributes}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include_attributes: $include_attributes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a Translation Set. Accepts a TranslationSet object. Only the state property may be updated.
#
# PUT /api/v2/TranslationSets/{ID}
# operationId: TranslationSets_UpdateTranslationSet
export def "translation-sets-update-translation-set" [
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
  --attributes: list # Attributes of the Translation Set — item shape: {ID?: int, Name: string, TranslationSetID?: int, Value?: string}
  file_i_ds: list<string> # IDs for files related to this translation set. For example, the original and processed files
  --body-id: int # The id of the TranslationSet. (format: int32) (spec name: Id)
  --in-date: string # Read Only. The date the translation set was returned. (format: date-time)
  --notes: string # Notes on the TranslationSet
  --out-date: string # Read Only. The date the translation set was sent out. (format: date-time)
  state: string@state-completer-5 # An enum indicating the state of the translation set
  --translation-request-id: int # Read Only. The Id of the TranslationRequest which generated this translation set. (format: int32)
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/TranslationSets/{ID}"
    path_params: [{name: ID, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Attributes, var: attributes}, {name: FileIDs, var: file_i_ds}, {name: Id, var: body_id}, {name: InDate, var: in_date}, {name: Notes, var: notes}, {name: OutDate, var: out_date}, {name: State, var: state}, {name: TranslationRequestID, var: translation_request_id}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id, attributes: $attributes, file_i_ds: $file_i_ds, body_id: $body_id, in_date: $in_date, notes: $notes, out_date: $out_date, state: $state, translation_request_id: $translation_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a PagedResponse of TranslationSetAttribute objects
#
# GET /api/v2/TranslationSets/{ID}/Attributes
# Returns: record<Entities: table<ID: int, Name: string, TranslationSetID: int, Value: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: TranslationSets_GetTranslationSetAttributes
export def "translation-sets-get-translation-set-attributes" [
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
  --limit: int # format: int32
  --offset: int # format: int32
  --name: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/TranslationSets/{ID}/Attributes"
    path_params: [{name: ID, var: id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: name, var: name}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, limit: $limit, offset: $offset, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a TranslationSetAttribute object
#
# POST /api/v2/TranslationSets/{ID}/Attributes
# Returns: int
# operationId: TranslationSets_PostTranslationSetAttribute
export def "translation-sets-post-translation-set-attribute" [
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
  --body-id: int # The ID of this attribute. (format: int32) (spec name: ID)
  name: string # The name of this Attribute.
  --translation-set-id: int # The ID of the translation set to which this attribute belongs. (format: int32)
  --value: string # The value of this Attribute
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/TranslationSets/{ID}/Attributes"
    path_params: [{name: ID, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ID, var: body_id}, {name: Name, var: name}, {name: TranslationSetID, var: translation_set_id}, {name: Value, var: value}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body_id: $body_id, name: $name, translation_set_id: $translation_set_id, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# No Documentation Found.
#
# POST /api/v2/TranslationSets/{ID}/Attributes/Batch
# operationId: TranslationSets_PostTranslationSetAttributes
export def "translation-sets-post-translation-set-attributes" [
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
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/TranslationSets/{ID}/Attributes/Batch"
    path_params: [{name: ID, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the information needed to translate a string in a translation set
#
# GET /api/v2/TranslationSets/{ID}/SourceStrings
# Returns: record<Entities: table<DescriptionForTranslator: string, LanguageID: int, StringID: string, StringValue: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: TranslationSets_GetSourceStrings
export def "translation-sets-get-source-strings" [
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
  --limit: int # format: int32
  --offset: int # format: int32
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/TranslationSets/{ID}/SourceStrings"
    path_params: [{name: ID, var: id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the statistics for translation sets such as the language ids and count of string definitions.
#
# GET /api/v2/TranslationSets/{ID}/Statistics
# Returns: record<LanguageIDs: list<int>, StringCount: int>
# operationId: TranslationSets_GetStatistics
export def "translation-sets-get-statistics" [
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
    path: "/api/v2/TranslationSets/{ID}/Statistics"
    path_params: [{name: ID, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a PagedResponse of TranslationSetString objects
#
# GET /api/v2/TranslationSets/{ID}/Strings
# Returns: record<Entities: table<LanguageID: int, StringID: string, StringValue: string, TranslationSetId: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: TranslationSets_GetTranslationSetStrings
export def "translation-sets-get-translation-set-strings" [
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
  --limit: int # format: int32
  --offset: int # format: int32
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/TranslationSets/{ID}/Strings"
    path_params: [{name: ID, var: id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# No Documentation Found.
#
# PUT /api/v2/TranslationSets/{ID}/Strings
# operationId: TranslationSets_UpdateTranslationSetStrings
export def "translation-sets-update-translation-set-strings" [
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
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/TranslationSets/{ID}/Strings"
    path_params: [{name: ID, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of current Client Subscriptions.
#
# GET /api/v2/UpdateGroupClientRelationships
# Returns: record<Entities: table<Active: bool, ClientID: string, LastCheckin: string, RelationshipID: string, UpdateGroupID: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: UpdateGroupClientRelationships_GetSubscriptions
export def "update-group-client-relationships-get-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --client-id: string # Optional. Filter by Client ID
  --update-group-id: string # Optional. Filter by Update Group ID
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
  --active: oneof<nothing, bool> # Optional. Filter by Active
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/UpdateGroupClientRelationships"
    query: [{name: ClientID, var: client_id}, {name: UpdateGroupID, var: update_group_id}, {name: limit, var: limit}, {name: offset, var: offset}, {name: Active, var: active}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, update_group_id: $update_group_id, limit: $limit, offset: $offset, active: $active
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a subscription
#
# POST /api/v2/UpdateGroupClientRelationships
# Returns: string
# operationId: UpdateGroupClientRelationships_PostSubscription
export def "update-group-client-relationships-post-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --active: oneof<nothing, bool> # The subscription status. The status is active by default.
  client_id: string # Read Only after creation. The client id of the subscriber.
  --last-checkin: string # ReadOnly. The timestamp of the last checkin. (format: date-time)
  --relationship-id: string # Read Only after creation. The relationship id. A relationship id will be assigned if not provided on creation.
  update_group_id: string # Read Only after creation. The update group to subscribe to.
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/UpdateGroupClientRelationships"
    body: {content_type: "application/json", kind: json, fields: [{name: Active, var: active}, {name: ClientID, var: client_id}, {name: LastCheckin, var: last_checkin}, {name: RelationshipID, var: relationship_id}, {name: UpdateGroupID, var: update_group_id}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    active: $active, client_id: $client_id, last_checkin: $last_checkin, relationship_id: $relationship_id, update_group_id: $update_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DEPRECATED. Set client subscription status for an update group.
#
# PUT /api/v2/UpdateGroupClientRelationships
# operationId: UpdateGroupClientRelationships_PutSubscriptionByClientIDUpdateGroupID
export def "update-group-client-relationships-put-subscription-by-client-id-update-group-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # The Client ID. This can be a client ID that has not been registered yet. (required)
  --update-group-id: string # The Update Group ID (required)
  --active: oneof<nothing, bool> # Subscribe the client to the Update Group. (required)
]: nothing -> any {
  http-request {
    method: put
    path: "/api/v2/UpdateGroupClientRelationships"
    query: [{name: ClientID, var: client_id, required: true}, {name: UpdateGroupID, var: update_group_id, required: true}, {name: Active, var: active, required: true}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    client_id: $client_id, update_group_id: $update_group_id, active: $active
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a subscription by RelationshipID
#
# GET /api/v2/UpdateGroupClientRelationships/{RelationshipID}
# Returns: record<Active: bool, ClientID: string, LastCheckin: string, RelationshipID: string, UpdateGroupID: string>
# operationId: UpdateGroupClientRelationships_GetSubscription
export def "update-group-client-relationships-get-subscription" [
  relationship_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/api/v2/UpdateGroupClientRelationships/{RelationshipID}"
    path_params: [{name: RelationshipID, var: relationship_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    relationship_id: $relationship_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates a Subscription
#
# PUT /api/v2/UpdateGroupClientRelationships/{RelationshipID}
# operationId: UpdateGroupClientRelationships_PutSubscription
export def "update-group-client-relationships-put-subscription" [
  relationship_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # The subscription status. The status is active by default.
  client_id: string # Read Only after creation. The client id of the subscriber.
  --last-checkin: string # ReadOnly. The timestamp of the last checkin. (format: date-time)
  --body-relationship-id: string # Read Only after creation. The relationship id. A relationship id will be assigned if not provided on creation. (spec name: RelationshipID)
  update_group_id: string # Read Only after creation. The update group to subscribe to.
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/UpdateGroupClientRelationships/{RelationshipID}"
    path_params: [{name: RelationshipID, var: relationship_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Active, var: active}, {name: ClientID, var: client_id}, {name: LastCheckin, var: last_checkin}, {name: RelationshipID, var: body_relationship_id}, {name: UpdateGroupID, var: update_group_id}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    relationship_id: $relationship_id, active: $active, client_id: $client_id, last_checkin: $last_checkin, body_relationship_id: $body_relationship_id, update_group_id: $update_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Update Group Subscriptions
#
# GET /api/v2/UpdateGroupSubscriptions
# Returns: record<Entities: table<ClientID: string, Include: bool, PackageTypeID: string, UpdateGroupID: string, UpdateGroupSubscriptionID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: UpdateGroupSubscriptions_GetUpdateGroupSubscriptions
export def "update-group-subscriptions-get-update-group-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --update-group-id: string # Optional. Filter by Update Group ID.
  --package-type-id: string # Optional. Filter by Package Type ID.
  --client-id: string # Optional. Filter by Client ID.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/UpdateGroupSubscriptions"
    query: [{name: UpdateGroupID, var: update_group_id}, {name: PackageTypeID, var: package_type_id}, {name: ClientID, var: client_id}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    update_group_id: $update_group_id, package_type_id: $package_type_id, client_id: $client_id, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add an Update Group Subscription
#
# POST /api/v2/UpdateGroupSubscriptions
# Returns: int
# operationId: UpdateGroupSubscriptions_PostUpdateGroupSubscription
export def "update-group-subscriptions-post-update-group-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  client_id: string # The ClientID.
  --include: oneof<nothing, bool> # True to receive content of type indicated by PackageTypeID.
  package_type_id: string # The PackageType to set subscription status for
  update_group_id: string # The Update Group this subscription is relevant for.
  --update-group-subscription-id: int # The Update Group Subscription ID. This ID will be automatically assigned when creating an Update Group Subscription. (format: int32)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/UpdateGroupSubscriptions"
    body: {content_type: "application/json", kind: json, fields: [{name: ClientID, var: client_id}, {name: Include, var: include, required: true}, {name: PackageTypeID, var: package_type_id}, {name: UpdateGroupID, var: update_group_id}, {name: UpdateGroupSubscriptionID, var: update_group_subscription_id}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, include: $include, package_type_id: $package_type_id, update_group_id: $update_group_id, update_group_subscription_id: $update_group_subscription_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# No Documentation Found.
#
# POST /api/v2/UpdateGroupSubscriptions/Batch
# operationId: UpdateGroupSubscriptions_PostUpdateGroupSubscriptions
export def "update-group-subscriptions-post-update-group-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/UpdateGroupSubscriptions/Batch"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# No Documentation Found.
#
# PUT /api/v2/UpdateGroupSubscriptions/Batch
# operationId: UpdateGroupSubscriptions_PutUpdateGroupSubscriptions
export def "update-group-subscriptions-put-update-group-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/UpdateGroupSubscriptions/Batch"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an Update Group Subscription
#
# DELETE /api/v2/UpdateGroupSubscriptions/{UpdateGroupSubscriptionID}
# operationId: UpdateGroupSubscriptions_DeleteUpdateGroupSubscription
export def "update-group-subscriptions-delete-update-group-subscription" [
  update_group_subscription_id: int
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
    path: "/api/v2/UpdateGroupSubscriptions/{UpdateGroupSubscriptionID}"
    path_params: [{name: UpdateGroupSubscriptionID, var: update_group_subscription_id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    update_group_subscription_id: $update_group_subscription_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an Update Group Subscription
#
# GET /api/v2/UpdateGroupSubscriptions/{UpdateGroupSubscriptionID}
# Returns: record<ClientID: string, Include: bool, PackageTypeID: string, UpdateGroupID: string, UpdateGroupSubscriptionID: int>
# operationId: UpdateGroupSubscriptions_GetUpdateGroupSubscription
export def "update-group-subscriptions-get-update-group-subscription" [
  update_group_subscription_id: int
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/api/v2/UpdateGroupSubscriptions/{UpdateGroupSubscriptionID}"
    path_params: [{name: UpdateGroupSubscriptionID, var: update_group_subscription_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    update_group_subscription_id: $update_group_subscription_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update an Update Group Subscription
#
# PUT /api/v2/UpdateGroupSubscriptions/{UpdateGroupSubscriptionID}
# operationId: UpdateGroupSubscriptions_PutUpdateGroupSubscription
export def "update-group-subscriptions-put-update-group-subscription" [
  update_group_subscription_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  client_id: string # The ClientID.
  --include: oneof<nothing, bool> # True to receive content of type indicated by PackageTypeID.
  package_type_id: string # The PackageType to set subscription status for
  update_group_id: string # The Update Group this subscription is relevant for.
  --body-update-group-subscription-id: int # The Update Group Subscription ID. This ID will be automatically assigned when creating an Update Group Subscription. (format: int32) (spec name: UpdateGroupSubscriptionID)
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/UpdateGroupSubscriptions/{UpdateGroupSubscriptionID}"
    path_params: [{name: UpdateGroupSubscriptionID, var: update_group_subscription_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientID, var: client_id}, {name: Include, var: include, required: true}, {name: PackageTypeID, var: package_type_id}, {name: UpdateGroupID, var: update_group_id}, {name: UpdateGroupSubscriptionID, var: body_update_group_subscription_id}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    update_group_subscription_id: $update_group_subscription_id, client_id: $client_id, include: $include, package_type_id: $package_type_id, update_group_id: $update_group_id, body_update_group_subscription_id: $body_update_group_subscription_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of Update Groups. Update Groups are used by the client to register for a specific type of update.
#
# GET /api/v2/UpdateGroups
# Returns: record<Entities: table<Description: string, ID: string, InventoryFrequency: int, InventoryPackage: string, LocalizedDescription: string, LocalizedName: string, Priority: int, ReportField: string, UpdateType: string, ValidatingField: string, ValueToValidate: string, Version: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: UpdateGroups_Get
export def "update-groups-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
  --user-id: int # Optional. The user ID to sort update groups by the user's access (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/UpdateGroups"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: userID, var: user_id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a new Update Group. The report field is a string that has a dot based request for a specific piece of submitted data.
#
# POST /api/v2/UpdateGroups
# Returns: string
# operationId: UpdateGroups_Post
export def "update-groups-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  description: string # The description of the update group
  --id: string
  --inventory-frequency: int # The time in minutes between inventory checks. Default value is 1440 minutes (one day). (format: int32)
  --inventory-package: string # The Package ID of the package used for inventory
  --localized-description: string # Optional. The StringID used to localize the description of the update group
  --localized-name: string # Optional. The StringID used to localize the name of the update group
  priority: int # The execution priority of the package relative to other packages in the bundle. Range 1 - 100, lower value indication higher priority. (format: int32)
  --report-field: string # A field to return in the status report for this update group. Specify the field with the format [Label]: {[InventoryPackageID].[Category].[Attribute]}. (i.e. example: {bec778ca-278d-424a-867a-4653a1a19e86.MyCategory.MyAttribute})
  update_type: string # The update type name
  --validating-field: string # A field used for validation in the status report for this update group. Specify the field with the format [Label]: {[InventoryPackageID].[Category].[Attribute]}. (i.e. example: {bec778ca-278d-424a-867a-4653a1a19e86.MyCategory.MyAttribute})
  --value-to-validate: string # The value to validate the ValidationField against.
  --version: string # The version of the UpdateGroup, this value is incremented with each modification to a related Bundle or PackageType (format: byte)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/UpdateGroups"
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: ID, var: id}, {name: InventoryFrequency, var: inventory_frequency}, {name: InventoryPackage, var: inventory_package}, {name: LocalizedDescription, var: localized_description}, {name: LocalizedName, var: localized_name}, {name: Priority, var: priority}, {name: ReportField, var: report_field}, {name: UpdateType, var: update_type}, {name: ValidatingField, var: validating_field}, {name: ValueToValidate, var: value_to_validate}, {name: Version, var: version}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    description: $description, id: $id, inventory_frequency: $inventory_frequency, inventory_package: $inventory_package, localized_description: $localized_description, localized_name: $localized_name, priority: $priority, report_field: $report_field, update_type: $update_type, validating_field: $validating_field, value_to_validate: $value_to_validate, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an Update Group.
#
# DELETE /api/v2/UpdateGroups/{ID}
# operationId: UpdateGroups_Delete
export def "update-groups-delete" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v2/UpdateGroups/{ID}"
    path_params: [{name: ID, var: id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific Update Group by ID.
#
# GET /api/v2/UpdateGroups/{ID}
# Returns: record<Description: string, ID: string, InventoryFrequency: int, InventoryPackage: string, LocalizedDescription: string, LocalizedName: string, Priority: int, ReportField: string, UpdateType: string, ValidatingField: string, ValueToValidate: string, Version: string>
export def "get-api-v2-update-groups-id" [
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
    path: "/api/v2/UpdateGroups/{ID}"
    path_params: [{name: ID, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Modify an Update Group.
#
# PUT /api/v2/UpdateGroups/{ID}
# operationId: UpdateGroups_Put
export def "update-groups-put" [
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
  description: string # The description of the update group
  --body-id: string # (spec name: ID)
  --inventory-frequency: int # The time in minutes between inventory checks. Default value is 1440 minutes (one day). (format: int32)
  --inventory-package: string # The Package ID of the package used for inventory
  --localized-description: string # Optional. The StringID used to localize the description of the update group
  --localized-name: string # Optional. The StringID used to localize the name of the update group
  priority: int # The execution priority of the package relative to other packages in the bundle. Range 1 - 100, lower value indication higher priority. (format: int32)
  --report-field: string # A field to return in the status report for this update group. Specify the field with the format [Label]: {[InventoryPackageID].[Category].[Attribute]}. (i.e. example: {bec778ca-278d-424a-867a-4653a1a19e86.MyCategory.MyAttribute})
  update_type: string # The update type name
  --validating-field: string # A field used for validation in the status report for this update group. Specify the field with the format [Label]: {[InventoryPackageID].[Category].[Attribute]}. (i.e. example: {bec778ca-278d-424a-867a-4653a1a19e86.MyCategory.MyAttribute})
  --value-to-validate: string # The value to validate the ValidationField against.
  --version: string # The version of the UpdateGroup, this value is incremented with each modification to a related Bundle or PackageType (format: byte)
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/UpdateGroups/{ID}"
    path_params: [{name: ID, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: ID, var: body_id}, {name: InventoryFrequency, var: inventory_frequency}, {name: InventoryPackage, var: inventory_package}, {name: LocalizedDescription, var: localized_description}, {name: LocalizedName, var: localized_name}, {name: Priority, var: priority}, {name: ReportField, var: report_field}, {name: UpdateType, var: update_type}, {name: ValidatingField, var: validating_field}, {name: ValueToValidate, var: value_to_validate}, {name: Version, var: version}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id, description: $description, body_id: $body_id, inventory_frequency: $inventory_frequency, inventory_package: $inventory_package, localized_description: $localized_description, localized_name: $localized_name, priority: $priority, report_field: $report_field, update_type: $update_type, validating_field: $validating_field, value_to_validate: $value_to_validate, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of bundles for UpdateGroup.
#
# GET /api/v2/UpdateGroups/{ID}/Bundles
# Returns: record<Entities: table<Active: bool, BundleID: string, BundleNumber: int, Description: string, UpdateGroupID: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: UpdateGroups_GetUpdateGroupBundles
export def "update-groups-get-update-group-bundles" [
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
  --accept: string@accept-completer-1 # Response content type
  --include-inactive: oneof<nothing, bool> # Include Inactive Bundles (true|false) (required)
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/UpdateGroups/{ID}/Bundles"
    path_params: [{name: ID, var: id}]
    query: [{name: IncludeInactive, var: include_inactive, required: true}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include_inactive: $include_inactive, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Deletes an update group a user could see.
#
# DELETE /api/v2/UpdateGroups/{id}/Users/{userID}
# operationId: UpdateGroups_RemoveUpdateGroupUser
export def "update-groups-remove-update-group-user" [
  id: string
  user_id: int
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
    path: "/api/v2/UpdateGroups/{id}/Users/{userID}"
    path_params: [{name: id, var: id}, {name: userID, var: user_id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add an updateGroup that a user can see.
#
# POST /api/v2/UpdateGroups/{id}/Users/{userID}
# operationId: UpdateGroups_AddUpdateGroupUser
export def "update-groups-add-update-group-user" [
  id: string
  user_id: int
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
    path: "/api/v2/UpdateGroups/{id}/Users/{userID}"
    path_params: [{name: id, var: id}, {name: userID, var: user_id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks the Client ID into the Update System.
#
# GET /api/v2/UpdateSystem
# Returns: record<Packages: table<Autorun: bool, CRC: string, Description: string, LocalizedName: string, Notes: string, PackageID: string, PackageTypeID: string, PreviousVersion: int, ReleaseDate: string, Released: bool, RemoveOnSuccess: bool, Size: int, Switches: string, Url: string, Version: int>, RemovePackages: list<string>>
# operationId: UpdateSystem_GetCheckin
export def "update-system-get-checkin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --client-id: string # The Client ID to check-in. If this is a new client ID it will be added to Clients. (required)
  --preview: oneof<nothing, bool> # Get Pkgs w\o updating Datetimes(true|false) (required)
  --run-all-inventories: oneof<nothing, bool> # Force return inventories. Defaults to false.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/UpdateSystem"
    query: [{name: ClientID, var: client_id, required: true}, {name: Preview, var: preview, required: true}, {name: RunAllInventories, var: run_all_inventories}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, preview: $preview, run_all_inventories: $run_all_inventories
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get UserContentDefinitions
#
# GET /api/v2/UserContentDefinitions
# Returns: record<Entities: table<ContentDefinitionID: int, UserContentDefinitionID: int, UserID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: UserContentDefinitions_GetUserContentDefinitions
export def "user-content-definitions-get-user-content-definitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
  --user-id: int # Optional. Filter by UserID. (format: int32)
  --content-definition-id: int # Optional. Filter by ContentDefinitionID (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/UserContentDefinitions"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: userID, var: user_id}, {name: contentDefinitionID, var: content_definition_id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, user_id: $user_id, content_definition_id: $content_definition_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a UserContentDefinition
#
# POST /api/v2/UserContentDefinitions
# Returns: int
# operationId: UserContentDefinitions_PostUserContentDefinition
export def "user-content-definitions-post-user-content-definition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --content-definition-id: int # The ID of the ContentDefinition. (format: int32)
  --user-content-definition-id: int # Read Only. The ID of the User to ContentDefinition relationship. (format: int32)
  --user-id: int # The ID of the user. (format: int32)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/UserContentDefinitions"
    body: {content_type: "application/json", kind: json, fields: [{name: ContentDefinitionID, var: content_definition_id}, {name: UserContentDefinitionID, var: user_content_definition_id}, {name: UserID, var: user_id}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    content_definition_id: $content_definition_id, user_content_definition_id: $user_content_definition_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a UserContentDefinition
#
# DELETE /api/v2/UserContentDefinitions/{userContentDefinitionID}
# operationId: UserContentDefinitions_DeleteUserContentDefinition
export def "user-content-definitions-delete-user-content-definition" [
  user_content_definition_id: int
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
    path: "/api/v2/UserContentDefinitions/{userContentDefinitionID}"
    path_params: [{name: userContentDefinitionID, var: user_content_definition_id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    user_content_definition_id: $user_content_definition_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a UserContentDefinition by ID
#
# GET /api/v2/UserContentDefinitions/{userContentDefinitionID}
# Returns: record<ContentDefinitionID: int, UserContentDefinitionID: int, UserID: int>
# operationId: UserContentDefinitions_GetUserContentDefinition
export def "user-content-definitions-get-user-content-definition" [
  user_content_definition_id: int
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/api/v2/UserContentDefinitions/{userContentDefinitionID}"
    path_params: [{name: userContentDefinitionID, var: user_content_definition_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    user_content_definition_id: $user_content_definition_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get users
#
# GET /api/v2/Users
# Returns: record<Entities: table<ChangePassword: string, Email: string, Name: string, Password: string, UserID: int, Username: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: Users_Get
export def "users-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --username: string # Optional. Search by username. Supports beginning and ending wildcards (*).
  --email: string # Optional. Search by email. Supports beginning and ending wildcards (*).
  --name: string # Optional. Search by name. Supports beginning and ending wildcards (*).
  --has-role: string # Optional. Return only users having the provided role name.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Users"
    query: [{name: username, var: username}, {name: email, var: email}, {name: name, var: name}, {name: hasRole, var: has_role}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, email: $email, name: $name, has_role: $has_role, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a user
#
# POST /api/v2/Users
# Returns: record<ChangePassword: string, Email: string, Name: string, Password: string, UserID: int, Username: string>
# operationId: Users_Post
export def "users-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --change-password: string # Never Returned. When changing a user's password, this field must contain the new password.
  --email: string # The user's email address
  --name: string # The user's name
  --password: string # Never Returned. Required when creating a new user or updating a user. When changing a user's password this field must contain the current password.
  --user-id: int # The user ID (format: int32)
  --username: string # The username used for authentication
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v2/Users"
    body: {content_type: "application/json", kind: json, fields: [{name: ChangePassword, var: change_password}, {name: Email, var: email}, {name: Name, var: name}, {name: Password, var: password}, {name: UserID, var: user_id}, {name: Username, var: username}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    change_password: $change_password, email: $email, name: $name, password: $password, user_id: $user_id, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the current user
#
# GET /api/v2/Users/Current
# Returns: record<ChangePassword: string, Email: string, Name: string, Password: string, UserID: int, Username: string>
# operationId: Users_GetCurrentUser
export def "users-get-current-user" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/api/v2/Users/Current"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a user
#
# PUT /api/v2/Users/Current
# operationId: Users_PutCurrentUser
export def "users-put-current-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --change-password: string # Never Returned. When changing a user's password, this field must contain the new password.
  --email: string # The user's email address
  --name: string # The user's name
  --password: string # Never Returned. Required when creating a new user or updating a user. When changing a user's password this field must contain the current password.
  --user-id: int # The user ID (format: int32)
  --username: string # The username used for authentication
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/Users/Current"
    body: {content_type: "application/json", kind: json, fields: [{name: ChangePassword, var: change_password}, {name: Email, var: email}, {name: Name, var: name}, {name: Password, var: password}, {name: UserID, var: user_id}, {name: Username, var: username}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    change_password: $change_password, email: $email, name: $name, password: $password, user_id: $user_id, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user's permissions
#
# GET /api/v2/Users/Current/Permissions
# Returns: record<Entities: table<PermissionId: int, PermissionName: string, UserID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
export def "get-api-v2-users-current-permissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --permission: string # Filter by permission name. Supports ending wildcard (*). Optional.
  --limit: int # The page limit. The default page limit is 10. (format: int32)
  --offset: int # The page offset. The default page offset is 0. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Users/Current/Permissions"
    query: [{name: Permission, var: permission}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    permission: $permission, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the current user's roles
#
# GET /api/v2/Users/Current/Roles
# Returns: record<Entities: table<Description: string, Id: int, Name: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: UserPermissions_GetCurrentUserRoles
export def "user-permissions-get-current-user-roles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --role: string # Filter by role name. Supports ending wildcard (*). Optional.
  --limit: int # The page limit. The default page limit is 10. (format: int32)
  --offset: int # The page offset. The default page offset is 0. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Users/Current/Roles"
    query: [{name: Role, var: role}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    role: $role, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a user
#
# DELETE /api/v2/Users/{id}
# operationId: Users_Delete
export def "users-delete" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v2/Users/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific user
#
# GET /api/v2/Users/{id}
# Returns: record<ChangePassword: string, Email: string, Name: string, Password: string, UserID: int, Username: string>
export def "get-api-v2-users-id" [
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
    path: "/api/v2/Users/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a user
#
# PUT /api/v2/Users/{id}
# operationId: Users_Put
export def "users-put" [
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
  --change-password: string # Never Returned. When changing a user's password, this field must contain the new password.
  --email: string # The user's email address
  --name: string # The user's name
  --password: string # Never Returned. Required when creating a new user or updating a user. When changing a user's password this field must contain the current password.
  --user-id: int # The user ID (format: int32)
  --username: string # The username used for authentication
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/Users/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ChangePassword, var: change_password}, {name: Email, var: email}, {name: Name, var: name}, {name: Password, var: password}, {name: UserID, var: user_id}, {name: Username, var: username}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, change_password: $change_password, email: $email, name: $name, password: $password, user_id: $user_id, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user's permissions
#
# GET /api/v2/Users/{id}/Permissions
# Returns: record<Entities: table<PermissionId: int, PermissionName: string, UserID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: UserPermissions_GetPermissions
export def "user-permissions-get-permissions" [
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
  --accept: string@accept-completer-1 # Response content type
  --permission: string # Filter by permission name. Supports ending wildcard (*). Optional.
  --limit: int # The page limit. The default page limit is 10. (format: int32)
  --offset: int # The page offset. The default page offset is 0. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Users/{id}/Permissions"
    path_params: [{name: id, var: id}]
    query: [{name: Permission, var: permission}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, permission: $permission, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a user's roles
#
# GET /api/v2/Users/{id}/Roles
# Returns: record<Entities: table<Description: string, Id: int, Name: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: UserPermissions_GetRoles
export def "user-permissions-get-roles" [
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
  --accept: string@accept-completer-1 # Response content type
  --role: string # Filter by role name. Supports ending wildcard (*). Optional.
  --limit: int # The page limit. The default page limit is 10. (format: int32)
  --offset: int # The page offset. The default page offset is 0. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Users/{id}/Roles"
    path_params: [{name: id, var: id}]
    query: [{name: Role, var: role}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, role: $role, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a user's roles
#
# PUT /api/v2/Users/{id}/Roles
# operationId: UserPermissions_Put
export def "user-permissions-put" [
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
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/Users/{id}/Roles"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets voucher history data
#
# GET /api/v2/VoucherHistory
# Returns: record<Entities: table<ChangedDate: string, CreatedDate: string, DealerCode: string, Deleted: bool, Email: string, ExpirationDate: string, ID: int, LicenseTo: string, ModifiedBy: string, OrderNumber: string, Punched: bool, PunchedDate: string, Purpose: string, Type: string, VoucherCode: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: VoucherHistory_GetVoucherHistory
export def "voucher-history-get-voucher-history" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --voucher-code: string # Optional. Filter history data by Voucher Code.
  --changed-before: string # Optional. Filter history data where changes occured before provided date. (format: date-time)
  --changed-after: string # Optional. Filter history data where changes occured after provided date. (format: date-time)
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/VoucherHistory"
    query: [{name: VoucherCode, var: voucher_code}, {name: ChangedBefore, var: changed_before}, {name: ChangedAfter, var: changed_after}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    voucher_code: $voucher_code, changed_before: $changed_before, changed_after: $changed_after, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a list of vouchers
#
# GET /api/v2/Vouchers
# Returns: record<Entities: table<CreatedDate: string, DealerCode: string, Deleted: bool, Email: string, ExpirationDate: string, LicenseTo: string, ModifiedBy: string, OrderNumber: string, Punched: bool, PunchedDate: string, Purpose: string, Type: string, VoucherCode: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: Vouchers_Get
export def "vouchers-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --type: string@type-completer # Optional. Filter vouchers by Type
  --dealer-code: string # Optional. Filter vouchers by DealerCode
  --license-to: string # Optional. Filter vouchers by LicenseTo. Wildcard supported (*).
  --purpose: string # Optional. Filter vouchers by Purpose. Wildcard supported (*).
  --order-number: string # Optional. Filter vouchers by OrderNumber
  --email: string # Optional. Filter vouchers by Email. Wildcard supported (*).
  --modified-by: string # Optional. Filter vouchers by ModifiedBy
  --created-after: string # Optional. Filter vouchers by CreatedDate (format: date-time)
  --created-before: string # Optional. Filter vouchers by CreatedDate (format: date-time)
  --punched-after: string # Optional. Filter vouchers by PunchedDate (format: date-time)
  --punched-before: string # Optional. Filter vouchers by PunchedDate (format: date-time)
  --punched: oneof<nothing, bool> # Optional. Filter vouchers by Punched status
  --expiration-after: string # Optional. Filter vouchers by ExpirationDate (format: date-time)
  --expiration-before: string # Optional. Filter vouchers by ExpirationDate (format: date-time)
  --deleted: string@deleted-completer # Optional. Filter vouchers by Deleted state. By default only vouchers that are not deleted are returned.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Vouchers"
    query: [{name: Type, var: type}, {name: DealerCode, var: dealer_code}, {name: LicenseTo, var: license_to}, {name: Purpose, var: purpose}, {name: OrderNumber, var: order_number}, {name: Email, var: email}, {name: ModifiedBy, var: modified_by}, {name: CreatedAfter, var: created_after}, {name: CreatedBefore, var: created_before}, {name: PunchedAfter, var: punched_after}, {name: PunchedBefore, var: punched_before}, {name: Punched, var: punched}, {name: ExpirationAfter, var: expiration_after}, {name: ExpirationBefore, var: expiration_before}, {name: Deleted, var: deleted}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, dealer_code: $dealer_code, license_to: $license_to, purpose: $purpose, order_number: $order_number, email: $email, modified_by: $modified_by, created_after: $created_after, created_before: $created_before, punched_after: $punched_after, punched_before: $punched_before, punched: $punched, expiration_after: $expiration_after, expiration_before: $expiration_before, deleted: $deleted, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a voucher
#
# POST /api/v2/Vouchers
# Returns: string
# operationId: Vouchers_Post
export def "vouchers-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --created-date: string # Read-Only. The date the voucher was created. (format: date-time)
  --dealer-code: string # The dealer code the voucher is assigned to. Required for commercial and right to repair vouchers.
  --deleted: oneof<nothing, bool> # Read-Only. True if voucher has been deleted.
  --email: string # Required for internal vouchers.
  --expiration-date: string # The expiration date of the voucher. Required for Temporary and Right to Repair Vouchers. (format: date-time)
  --license-to: string # Required for Internal Vouchers
  --modified-by: string # Read-Only. The user that made the last modification to the voucher.
  --order-number: string # The order number of a license. Required for Commercial and Right To Repair Vouchers. Not supported for other Vouchers.
  --punched: oneof<nothing, bool> # True if voucher has aleady been used. False if the voucher has not been used.
  --punched-date: string # Read-Only. The date the voucher was punched. (format: date-time)
  --purpose: string # Required for Internal Vouchers. Not supported for other Vouchers.
  --type: string@type-completer # The type of voucher. Commercial is the default if not specified.
  --voucher-code: string # The voucher code.
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/Vouchers"
    body: {content_type: "application/json", kind: json, fields: [{name: CreatedDate, var: created_date}, {name: DealerCode, var: dealer_code}, {name: Deleted, var: deleted}, {name: Email, var: email}, {name: ExpirationDate, var: expiration_date}, {name: LicenseTo, var: license_to}, {name: ModifiedBy, var: modified_by}, {name: OrderNumber, var: order_number}, {name: Punched, var: punched}, {name: PunchedDate, var: punched_date}, {name: Purpose, var: purpose}, {name: Type, var: type}, {name: VoucherCode, var: voucher_code}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    created_date: $created_date, dealer_code: $dealer_code, deleted: $deleted, email: $email, expiration_date: $expiration_date, license_to: $license_to, modified_by: $modified_by, order_number: $order_number, punched: $punched, punched_date: $punched_date, purpose: $purpose, type: $type, voucher_code: $voucher_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a voucher
#
# DELETE /api/v2/Vouchers/{VoucherCode}
# operationId: Vouchers_Delete
export def "vouchers-delete" [
  voucher_code: string
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
    path: "/api/v2/Vouchers/{VoucherCode}"
    path_params: [{name: VoucherCode, var: voucher_code}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    voucher_code: $voucher_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a voucher
#
# GET /api/v2/Vouchers/{VoucherCode}
# Returns: record<CreatedDate: string, DealerCode: string, Deleted: bool, Email: string, ExpirationDate: string, LicenseTo: string, ModifiedBy: string, OrderNumber: string, Punched: bool, PunchedDate: string, Purpose: string, Type: string, VoucherCode: string>
export def "get-api-v2-vouchers-voucher-code" [
  voucher_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --deleted: string@deleted-completer # Optional. Filter vouchers by Deleted state. By default only vouchers that are not deleted are returned.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Vouchers/{VoucherCode}"
    path_params: [{name: VoucherCode, var: voucher_code}]
    query: [{name: Deleted, var: deleted}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    voucher_code: $voucher_code, deleted: $deleted
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a voucher
#
# PUT /api/v2/Vouchers/{VoucherCode}
# operationId: Vouchers_Put
export def "vouchers-put" [
  voucher_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-date: string # Read-Only. The date the voucher was created. (format: date-time)
  --dealer-code: string # The dealer code the voucher is assigned to. Required for commercial and right to repair vouchers.
  --deleted: oneof<nothing, bool> # Read-Only. True if voucher has been deleted.
  --email: string # Required for internal vouchers.
  --expiration-date: string # The expiration date of the voucher. Required for Temporary and Right to Repair Vouchers. (format: date-time)
  --license-to: string # Required for Internal Vouchers
  --modified-by: string # Read-Only. The user that made the last modification to the voucher.
  --order-number: string # The order number of a license. Required for Commercial and Right To Repair Vouchers. Not supported for other Vouchers.
  --punched: oneof<nothing, bool> # True if voucher has aleady been used. False if the voucher has not been used.
  --punched-date: string # Read-Only. The date the voucher was punched. (format: date-time)
  --purpose: string # Required for Internal Vouchers. Not supported for other Vouchers.
  --type: string@type-completer # The type of voucher. Commercial is the default if not specified.
  --body-voucher-code: string # The voucher code. (spec name: VoucherCode)
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/Vouchers/{VoucherCode}"
    path_params: [{name: VoucherCode, var: voucher_code}]
    body: {content_type: "application/json", kind: json, fields: [{name: CreatedDate, var: created_date}, {name: DealerCode, var: dealer_code}, {name: Deleted, var: deleted}, {name: Email, var: email}, {name: ExpirationDate, var: expiration_date}, {name: LicenseTo, var: license_to}, {name: ModifiedBy, var: modified_by}, {name: OrderNumber, var: order_number}, {name: Punched, var: punched}, {name: PunchedDate, var: punched_date}, {name: Purpose, var: purpose}, {name: Type, var: type}, {name: VoucherCode, var: body_voucher_code}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    voucher_code: $voucher_code, created_date: $created_date, dealer_code: $dealer_code, deleted: $deleted, email: $email, expiration_date: $expiration_date, license_to: $license_to, modified_by: $modified_by, order_number: $order_number, punched: $punched, punched_date: $punched_date, purpose: $purpose, type: $type, body_voucher_code: $body_voucher_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a voucher's history.
#
# GET /api/v2/Vouchers/{VoucherCode}/VoucherHistory
# Returns: record<Entities: table<ChangedDate: string, CreatedDate: string, DealerCode: string, Deleted: bool, Email: string, ExpirationDate: string, ID: int, LicenseTo: string, ModifiedBy: string, OrderNumber: string, Punched: bool, PunchedDate: string, Purpose: string, Type: string, VoucherCode: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: Vouchers_GetVoucherHistory
export def "vouchers-get-voucher-history" [
  voucher_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/Vouchers/{VoucherCode}/VoucherHistory"
    path_params: [{name: VoucherCode, var: voucher_code}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    voucher_code: $voucher_code, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Activities
#
# GET /api/v2/activities
# Returns: record<Entities: table<ActivityID: int, Deleted: bool, Name: string, Parameters: list, Steps: list>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: Activities_GetActivities
export def "activities-get-activities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
  --is-include-deleted: oneof<nothing, bool> # Does it include deleted activity, or not
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/activities"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: isIncludeDeleted, var: is_include_deleted}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, is_include_deleted: $is_include_deleted
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create an Activity
#
# POST /api/v2/activities
# Returns: int
# operationId: Activities_PostActivity
export def "activities-post-activity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --activity-id: int # The ID of the activity (format: int32)
  --deleted: oneof<nothing, bool>
  --name: string # The name of the activity
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/activities"
    body: {content_type: "application/json", kind: json, fields: [{name: ActivityID, var: activity_id}, {name: Deleted, var: deleted}, {name: Name, var: name}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    activity_id: $activity_id, deleted: $deleted, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Mark the delete flag for the Activity
#
# DELETE /api/v2/activities/{activityID}
# operationId: Activities_DeleteActivity
export def "activities-delete-activity" [
  activity_id: int
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
    path: "/api/v2/activities/{activityID}"
    path_params: [{name: activityID, var: activity_id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    activity_id: $activity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an Activity by ID
#
# GET /api/v2/activities/{activityID}
# Returns: record<ActivityID: int, Deleted: bool, Name: string, Parameters: table<Direction: string, Name: string, Type: string>, Steps: table<ActivityID: int, ActivityStepID: int, ImplementationID: string, ParameterMappings: list, RunOrder: int, StepID: int, StepName: string, UseConfig: string>>
# operationId: Activities_GetActivity
export def "activities-get-activity" [
  activity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --is-include-deleted: oneof<nothing, bool> # Does it include deleted activity, or not
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/activities/{activityID}"
    path_params: [{name: activityID, var: activity_id}]
    query: [{name: isIncludeDeleted, var: is_include_deleted}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    activity_id: $activity_id, is_include_deleted: $is_include_deleted
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update an Activity
#
# PUT /api/v2/activities/{activityID}
# operationId: Activities_PutActivity
export def "activities-put-activity" [
  activity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-activity-id: int # The ID of the activity (format: int32) (spec name: ActivityID)
  --deleted: oneof<nothing, bool>
  --name: string # The name of the activity
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/activities/{activityID}"
    path_params: [{name: activityID, var: activity_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ActivityID, var: body_activity_id}, {name: Deleted, var: deleted}, {name: Name, var: name}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    activity_id: $activity_id, body_activity_id: $body_activity_id, deleted: $deleted, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get ActivityRuns
#
# GET /api/v2/activityRuns
# Returns: record<Entities: table<ActivityRunID: int, EndDate: string, JobActivityID: int, JobRunID: int, Parameters: list, StartDate: string, Status: record, Steps: list>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: ActivityRuns_GetActivityRuns
export def "activity-runs-get-activity-runs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
  --status: string@status-completer-2 # Optional. Filter activity runs by status. Value should be a comma separated list of status to include. If not specified, the default status filter is “InProgress”.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/activityRuns"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: status, var: status}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get an ActivityRun by ID
#
# GET /api/v2/activityRuns/{activityRunID}
# Returns: record<ActivityRunID: int, EndDate: string, JobActivityID: int, JobRunID: int, Parameters: table<Direction: string, Name: string, Value: string>, StartDate: string, Status: record<CurrentStep: int, Status: string, StepProgress: int, StepStatus: string>, Steps: table<ActivityID: int, ActivityStepID: int, ImplementationID: string, ParameterMappings: list, RunOrder: int, StepID: int, StepName: string, UseConfig: string>>
# operationId: ActivityRuns_GetActivityRun
export def "activity-runs-get-activity-run" [
  activity_run_id: int
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/api/v2/activityRuns/{activityRunID}"
    path_params: [{name: activityRunID, var: activity_run_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    activity_run_id: $activity_run_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update an ActivityRun
#
# PUT /api/v2/activityRuns/{activityRunID}
# operationId: ActivityRuns_PutActivityRun
export def "activity-runs-put-activity-run" [
  activity_run_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-activity-run-id: int # The identifier for the ActivityRun (format: int32) (spec name: ActivityRunID)
  --end-date: string # Read Only. The UTC date and time when the activity completed (format: date-time)
  --job-activity-id: int # Read Only. The ID of the Job Activity that defines this activity run (format: int32)
  --job-run-id: int # Read Only. The ID of the JobRun under which this ActivityRun is executing (format: int32)
  --start-date: string # Read Only. The UTC date and time when the activity started (format: date-time)
  status: record # A DTO for an IActivityRunStatus — shape: {CurrentStep?: int, Status?: "Ready"|"InProgress"|"Succeeded"|"Cancelled"|"Failed", StepProgress?: int, StepStatus?: string}
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/activityRuns/{activityRunID}"
    path_params: [{name: activityRunID, var: activity_run_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ActivityRunID, var: body_activity_run_id}, {name: EndDate, var: end_date}, {name: JobActivityID, var: job_activity_id}, {name: JobRunID, var: job_run_id}, {name: StartDate, var: start_date}, {name: Status, var: status}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    activity_run_id: $activity_run_id, body_activity_run_id: $body_activity_run_id, end_date: $end_date, job_activity_id: $job_activity_id, job_run_id: $job_run_id, start_date: $start_date, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the ActivityRunStatus of an ActivityRun
#
# GET /api/v2/activityRuns/{activityRunID}/status
# Returns: record<CurrentStep: int, Status: string, StepProgress: int, StepStatus: string>
# operationId: ActivityRuns_GetActivityRunStatus
export def "activity-runs-get-activity-run-status" [
  activity_run_id: int
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/api/v2/activityRuns/{activityRunID}/status"
    path_params: [{name: activityRunID, var: activity_run_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    activity_run_id: $activity_run_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update the ActivityRunStatus of an ActivityRun
#
# PUT /api/v2/activityRuns/{activityRunID}/status
# operationId: ActivityRuns_PutActivityRunStatus
export def "activity-runs-put-activity-run-status" [
  activity_run_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --current-step: int # The activity step currently executing, indicated by numeric order (format: int32)
  --status: string@status-completer-2 # The status of the ActivityRun
  --step-progress: int # The percent progress from the currently executing step. This value shall be null if progress is not available (format: int32)
  --step-status: string # The status text from the currently executing step
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/activityRuns/{activityRunID}/status"
    path_params: [{name: activityRunID, var: activity_run_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: CurrentStep, var: current_step}, {name: Status, var: status}, {name: StepProgress, var: step_progress}, {name: StepStatus, var: step_status}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    activity_run_id: $activity_run_id, current_step: $current_step, status: $status, step_progress: $step_progress, step_status: $step_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Agents
#
# GET /api/v2/agents
# Returns: record<Entities: table<AgentID: int, KeepAliveInterval: int, MachineName: string, Status: record, StepConfigurations: list, UserID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: Agents_GetAgents
export def "agents-get-agents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/agents"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create an Agent
#
# POST /api/v2/agents
# Returns: int
# operationId: Agents_PostAgent
export def "agents-post-agent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --agent-id: int # The id of the Agent (format: int32)
  keep_alive_interval: int # The 'Heartbeat Interval' used by the Build Agent. (format: int32)
  machine_name: string # The machine name of the computer the agent is running on
  status: record # A DTO for an IAgentStatus — shape: {LastStatusUpdate?: string, Online: bool}
  user_id: int # The UserID of the Agent (format: int32)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/agents"
    body: {content_type: "application/json", kind: json, fields: [{name: AgentID, var: agent_id}, {name: KeepAliveInterval, var: keep_alive_interval}, {name: MachineName, var: machine_name}, {name: Status, var: status}, {name: UserID, var: user_id}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    agent_id: $agent_id, keep_alive_interval: $keep_alive_interval, machine_name: $machine_name, status: $status, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Agent associated with the current user
#
# GET /api/v2/agents/Current
# Returns: record<AgentID: int, KeepAliveInterval: int, MachineName: string, Status: record<LastStatusUpdate: string, Online: bool>, StepConfigurations: table<Configurations: list, StepImplementationID: string>, UserID: int>
# operationId: Agents_GetCurrentAgentAsync
export def "agents-get-current-agent-async" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/api/v2/agents/Current"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the ActivityRun of Agent associated with the current user
#
# GET /api/v2/agents/Current/ActivityRun
# Returns: record<ActivityRunID: int, EndDate: string, JobActivityID: int, JobRunID: int, Parameters: table<Direction: string, Name: string, Value: string>, StartDate: string, Status: record<CurrentStep: int, Status: string, StepProgress: int, StepStatus: string>, Steps: table<ActivityID: int, ActivityStepID: int, ImplementationID: string, ParameterMappings: list, RunOrder: int, StepID: int, StepName: string, UseConfig: string>>
# operationId: Agents_GetCurrentAgentActivityRun
export def "agents-get-current-agent-activity-run" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/api/v2/agents/Current/ActivityRun"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an Agent
#
# DELETE /api/v2/agents/{agentID}
# operationId: Agents_DeleteAgent
export def "agents-delete-agent" [
  agent_id: int
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
    path: "/api/v2/agents/{agentID}"
    path_params: [{name: agentID, var: agent_id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    agent_id: $agent_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Agent
#
# GET /api/v2/agents/{agentID}
# Returns: record<AgentID: int, KeepAliveInterval: int, MachineName: string, Status: record<LastStatusUpdate: string, Online: bool>, StepConfigurations: table<Configurations: list, StepImplementationID: string>, UserID: int>
# operationId: Agents_GetAgentAsync
export def "agents-get-agent-async" [
  agent_id: int
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/api/v2/agents/{agentID}"
    path_params: [{name: agentID, var: agent_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    agent_id: $agent_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update an Agent
#
# PUT /api/v2/agents/{agentID}
# operationId: Agents_PutAgent
export def "agents-put-agent" [
  agent_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-agent-id: int # The id of the Agent (format: int32) (spec name: AgentID)
  keep_alive_interval: int # The 'Heartbeat Interval' used by the Build Agent. (format: int32)
  machine_name: string # The machine name of the computer the agent is running on
  status: record # A DTO for an IAgentStatus — shape: {LastStatusUpdate?: string, Online: bool}
  user_id: int # The UserID of the Agent (format: int32)
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/agents/{agentID}"
    path_params: [{name: agentID, var: agent_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: AgentID, var: body_agent_id}, {name: KeepAliveInterval, var: keep_alive_interval}, {name: MachineName, var: machine_name}, {name: Status, var: status}, {name: UserID, var: user_id}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    agent_id: $agent_id, body_agent_id: $body_agent_id, keep_alive_interval: $keep_alive_interval, machine_name: $machine_name, status: $status, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an Agent's ActivityRun
#
# GET /api/v2/agents/{agentID}/ActivityRun
# Returns: record<ActivityRunID: int, EndDate: string, JobActivityID: int, JobRunID: int, Parameters: table<Direction: string, Name: string, Value: string>, StartDate: string, Status: record<CurrentStep: int, Status: string, StepProgress: int, StepStatus: string>, Steps: table<ActivityID: int, ActivityStepID: int, ImplementationID: string, ParameterMappings: list, RunOrder: int, StepID: int, StepName: string, UseConfig: string>>
# operationId: Agents_GetAgentActivityRun
export def "agents-get-agent-activity-run" [
  agent_id: int
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/api/v2/agents/{agentID}/ActivityRun"
    path_params: [{name: agentID, var: agent_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    agent_id: $agent_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update the ActivityRun assigned to the Agent.
#
# PUT /api/v2/agents/{agentID}/ActivityRun
# operationId: Agents_PutAgentActivityRun
export def "agents-put-agent-activity-run" [
  agent_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --activity-run-id: int # The identifier for the ActivityRun (format: int32)
  --end-date: string # Read Only. The UTC date and time when the activity completed (format: date-time)
  --job-activity-id: int # Read Only. The ID of the Job Activity that defines this activity run (format: int32)
  --job-run-id: int # Read Only. The ID of the JobRun under which this ActivityRun is executing (format: int32)
  --start-date: string # Read Only. The UTC date and time when the activity started (format: date-time)
  status: record # A DTO for an IActivityRunStatus — shape: {CurrentStep?: int, Status?: "Ready"|"InProgress"|"Succeeded"|"Cancelled"|"Failed", StepProgress?: int, StepStatus?: string}
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/agents/{agentID}/ActivityRun"
    path_params: [{name: agentID, var: agent_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ActivityRunID, var: activity_run_id}, {name: EndDate, var: end_date}, {name: JobActivityID, var: job_activity_id}, {name: JobRunID, var: job_run_id}, {name: StartDate, var: start_date}, {name: Status, var: status}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    agent_id: $agent_id, activity_run_id: $activity_run_id, end_date: $end_date, job_activity_id: $job_activity_id, job_run_id: $job_run_id, start_date: $start_date, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an Agent
#
# PUT /api/v2/agents/{agentID}/Status
# operationId: Agents_PutAgentStatus
export def "agents-put-agent-status" [
  agent_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --last-status-update: string # ReadOnly. The UTC date and time of the last status update (format: date-time)
  --online: oneof<nothing, bool> # Indicates if the agent is online
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/agents/{agentID}/Status"
    path_params: [{name: agentID, var: agent_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: LastStatusUpdate, var: last_status_update}, {name: Online, var: online, required: true}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    agent_id: $agent_id, last_status_update: $last_status_update, online: $online
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get JobRuns
#
# GET /api/v2/jobRuns
# Returns: record<Entities: table<ActivityRuns: list, EndDate: string, JobID: int, JobRunID: int, Parameters: list, StartDate: string, Status: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: JobRuns_GetJobRuns
export def "job-runs-get-job-runs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
  --include-activity-run-details: oneof<nothing, bool> # Optional. Indicates whether to include ActivityRun details. Defaults to false.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/jobRuns"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: includeActivityRunDetails, var: include_activity_run_details}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, include_activity_run_details: $include_activity_run_details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a JobRun
#
# POST /api/v2/jobRuns
# Returns: int
# operationId: JobRuns_PostJobRun
export def "job-runs-post-job-run" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --end-date: string # The UTC date and time when the job completed (format: date-time)
  --job-id: int # The ID of the job that defines the run (format: int32)
  --job-run-id: int # The ID of this JobRun (format: int32)
  --start-date: string # The UTC date and time when the job started (format: date-time)
  --status: string@status-completer-2 # The status of this JobRun
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/jobRuns"
    body: {content_type: "application/json", kind: json, fields: [{name: EndDate, var: end_date}, {name: JobID, var: job_id}, {name: JobRunID, var: job_run_id}, {name: StartDate, var: start_date}, {name: Status, var: status}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    end_date: $end_date, job_id: $job_id, job_run_id: $job_run_id, start_date: $start_date, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a JobRun
#
# DELETE /api/v2/jobRuns/{jobRunID}
# operationId: JobRuns_DeleteJobRun
export def "job-runs-delete-job-run" [
  job_run_id: int
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
    path: "/api/v2/jobRuns/{jobRunID}"
    path_params: [{name: jobRunID, var: job_run_id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    job_run_id: $job_run_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a JobRun by ID
#
# GET /api/v2/jobRuns/{jobRunID}
# Returns: record<ActivityRuns: table<ActivityRunID: int, EndDate: string, JobActivityID: int, JobRunID: int, Parameters: list, StartDate: string, Status: record, Steps: list>, EndDate: string, JobID: int, JobRunID: int, Parameters: table<Direction: string, Name: string, Value: string>, StartDate: string, Status: string>
# operationId: JobRuns_GetJobRun
export def "job-runs-get-job-run" [
  job_run_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --include-activity-run-details: oneof<nothing, bool> # Optional. Indicates whether to include ActivityRun details. Defaults to false.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/jobRuns/{jobRunID}"
    path_params: [{name: jobRunID, var: job_run_id}]
    query: [{name: includeActivityRunDetails, var: include_activity_run_details}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    job_run_id: $job_run_id, include_activity_run_details: $include_activity_run_details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a JobRun
#
# PUT /api/v2/jobRuns/{jobRunID}
# operationId: JobRuns_PutJobRun
export def "job-runs-put-job-run" [
  job_run_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-date: string # The UTC date and time when the job completed (format: date-time)
  --job-id: int # The ID of the job that defines the run (format: int32)
  --body-job-run-id: int # The ID of this JobRun (format: int32) (spec name: JobRunID)
  --start-date: string # The UTC date and time when the job started (format: date-time)
  --status: string@status-completer-2 # The status of this JobRun
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/jobRuns/{jobRunID}"
    path_params: [{name: jobRunID, var: job_run_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndDate, var: end_date}, {name: JobID, var: job_id}, {name: JobRunID, var: body_job_run_id}, {name: StartDate, var: start_date}, {name: Status, var: status}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    job_run_id: $job_run_id, end_date: $end_date, job_id: $job_id, body_job_run_id: $body_job_run_id, start_date: $start_date, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Jobs
#
# GET /api/v2/jobs
# Returns: record<Entities: table<Activities: list, Deleted: bool, JobID: int, Name: string, Parameters: list>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: Jobs_GetJobs
export def "jobs-get-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
  --is-include-deleted: oneof<nothing, bool> # Does it include deleted job, or not
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/jobs"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: isIncludeDeleted, var: is_include_deleted}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, is_include_deleted: $is_include_deleted
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a Job
#
# POST /api/v2/jobs
# Returns: int
# operationId: Jobs_PostJob
export def "jobs-post-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --deleted: oneof<nothing, bool> # Indicates if the job has been deleted.
  --job-id: int # The ID of the job (format: int32)
  --name: string # The name of the job
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/jobs"
    body: {content_type: "application/json", kind: json, fields: [{name: Deleted, var: deleted}, {name: JobID, var: job_id}, {name: Name, var: name}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    deleted: $deleted, job_id: $job_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Mark the delete flag for the Job
#
# DELETE /api/v2/jobs/{jobID}
# operationId: Jobs_DeleteJob
export def "jobs-delete-job" [
  job_id: int
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
    path: "/api/v2/jobs/{jobID}"
    path_params: [{name: jobID, var: job_id}]
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Job by ID
#
# GET /api/v2/jobs/{jobID}
# Returns: record<Activities: table<ActivityID: int, JobActivityID: int, JobID: int, ParameterMappings: list, RunOrder: int>, Deleted: bool, JobID: int, Name: string, Parameters: table<Direction: string, Name: string, Type: string>>
# operationId: Jobs_GetJob
export def "jobs-get-job" [
  job_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --is-include-deleted: oneof<nothing, bool> # Does it include deleted job, or not
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/jobs/{jobID}"
    path_params: [{name: jobID, var: job_id}]
    query: [{name: isIncludeDeleted, var: is_include_deleted}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, is_include_deleted: $is_include_deleted
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a Job
#
# PUT /api/v2/jobs/{jobID}
# operationId: Jobs_PutJob
export def "jobs-put-job" [
  job_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --deleted: oneof<nothing, bool> # Indicates if the job has been deleted.
  --body-job-id: int # The ID of the job (format: int32) (spec name: JobID)
  --name: string # The name of the job
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/jobs/{jobID}"
    path_params: [{name: jobID, var: job_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Deleted, var: deleted}, {name: JobID, var: body_job_id}, {name: Name, var: name}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    job_id: $job_id, deleted: $deleted, body_job_id: $body_job_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Steps
#
# GET /api/v2/steps
# Returns: record<Entities: table<ConfigRequired: bool, Deleted: bool, Description: string, ImplementationID: string, Name: string, Parameters: list, StepID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>>
# operationId: Steps_GetSteps
export def "steps-get-steps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
  --include-deleted: oneof<nothing, bool> # Does it include deleted step, or not
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/steps"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: includeDeleted, var: include_deleted}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, include_deleted: $include_deleted
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a Step
#
# POST /api/v2/steps
# Returns: int
# operationId: Steps_PostStep
export def "steps-post-step" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-required: oneof<nothing, bool> # Indicates if the step requires configuration values to be provided by the build agent
  --deleted: oneof<nothing, bool> # Read Only. Indicates if the record is deleted.
  --description: string # A description of the step to be presented to a user
  implementation_id: string # The implementation ID used to lookup the step implementation when it is executed
  name: string # The name of the step
  --step-id: int # The ID of the step (format: int32)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/steps"
    body: {content_type: "application/json", kind: json, fields: [{name: ConfigRequired, var: config_required, required: true}, {name: Deleted, var: deleted}, {name: Description, var: description}, {name: ImplementationID, var: implementation_id}, {name: Name, var: name}, {name: StepID, var: step_id}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    config_required: $config_required, deleted: $deleted, description: $description, implementation_id: $implementation_id, name: $name, step_id: $step_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a Step by ID
#
# GET /api/v2/steps/{stepID}
# Returns: record<ConfigRequired: bool, Deleted: bool, Description: string, ImplementationID: string, Name: string, Parameters: table<Direction: string, Name: string, Type: string>, StepID: int>
# operationId: Steps_GetStep
export def "steps-get-step" [
  step_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --is-include-deleted: oneof<nothing, bool> # Does it include deleted step, or not
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/steps/{stepID}"
    path_params: [{name: stepID, var: step_id}]
    query: [{name: isIncludeDeleted, var: is_include_deleted}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    step_id: $step_id, is_include_deleted: $is_include_deleted
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a Step
#
# PUT /api/v2/steps/{stepID}
# operationId: Steps_PutStep
export def "steps-put-step" [
  step_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --config-required: oneof<nothing, bool> # Indicates if the step requires configuration values to be provided by the build agent
  --deleted: oneof<nothing, bool> # Read Only. Indicates if the record is deleted.
  --description: string # A description of the step to be presented to a user
  implementation_id: string # The implementation ID used to lookup the step implementation when it is executed
  name: string # The name of the step
  --body-step-id: int # The ID of the step (format: int32) (spec name: StepID)
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2/steps/{stepID}"
    path_params: [{name: stepID, var: step_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ConfigRequired, var: config_required, required: true}, {name: Deleted, var: deleted}, {name: Description, var: description}, {name: ImplementationID, var: implementation_id}, {name: Name, var: name}, {name: StepID, var: body_step_id}]}
    accept: ["*/*"]
    ok: [204]
    auth: bearer
  } {
    step_id: $step_id, config_required: $config_required, deleted: $deleted, description: $description, implementation_id: $implementation_id, name: $name, body_step_id: $body_step_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
