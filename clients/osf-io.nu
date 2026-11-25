# Auto-generated client for OSF APIv2 Documentation v2.0
# Source: https://api.apis.guru/v2/specs/osf.io/2.0/openapi.json
# Auth: --token flag or $env.OSF_APIV2_DOCUMENTATION_TOKEN

const CLIENT = {
  base_url: "https://api.test.osf.io/v2"
  token_env_var: "OSF_APIV2_DOCUMENTATION_TOKEN"
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

def base-url-completer [] { ["https://api.test.osf.io/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["*/*" "application/json"] }
def accept-completer-1 [] { ["data" "meta"] }
def accept-completer-2 [] { ["application/json" "links" "meta"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    addons-list: "table<attributes: record<categories: list, description: string, name: string, url: string>, id: string, type: string>"
    citations-styles-list: "table<attributes: record<date_parsed: string, short_title: string, summary: string, title: string>, id: string, links: record, type: string>"
    citations-styles-read: "record<attributes: record<date_parsed: string, short_title: string, summary: string, title: string>, id: string, links: record, type: string>"
    collections-list: "table<attributes: record<bookmarks: bool, collected_type_choices: list, date_created: string, date_modified: string, is_promoted: bool, is_public: bool, issue_choices: list, program_area_choices: list, status_choices: list, title: string, volume_choices: list>, id: string, links: record<self: string>, relationships: record<collected_metadata: string, linked_nodes: string, linked_preprints: string, linked_registrations: string, node_links: string, provider: string>, type: string>"
    collections-detail: "table<attributes: record<bookmarks: bool, collected_type_choices: list, date_created: string, date_modified: string, is_promoted: bool, is_public: bool, issue_choices: list, program_area_choices: list, status_choices: list, title: string, volume_choices: list>, id: string, links: record<self: string>, relationships: record<collected_metadata: string, linked_nodes: string, linked_preprints: string, linked_registrations: string, node_links: string, provider: string>, type: string>"
    comments-read: "record<attributes: record<can_edit: bool, content: string, date_created: string, date_modified: string, deleted: bool, has_children: bool, has_report: bool, is_abuse: bool, is_ham: bool, modified: bool, page: string>, id: string, links: record<self: string>, relationships: record<node: string, replies: string, reports: string, target: string, user: string>, type: string>"
    draft-registrations-read: "record<attributes: record<category: string, current_user_permissions: list<string>, datetime_initiated: string, datetime_updated: string, description: string, has_project: bool, node_license: record<copyright_holders: list, year: int>, registration_metadata: record, registration_responses: record, tags: list<string>, title: string>, id: string, links: record<html: string>, relationships: record<branched_from: string, initiator: string, registration_schema: string>, type: string>"
    draft-registrations-create: "record<attributes: record<category: string, current_user_permissions: list<string>, datetime_initiated: string, datetime_updated: string, description: string, has_project: bool, node_license: record<copyright_holders: list, year: int>, registration_metadata: record, registration_responses: record, tags: list<string>, title: string>, id: string, links: record<html: string>, relationships: record<branched_from: string, initiator: string, registration_schema: string>, type: string>"
    get-draft-registrations-draft-id: "record<attributes: record<category: string, current_user_permissions: list<string>, datetime_initiated: string, datetime_updated: string, description: string, has_project: bool, node_license: record<copyright_holders: list, year: int>, registration_metadata: record, registration_responses: record, tags: list<string>, title: string>, id: string, links: record<html: string>, relationships: record<branched_from: string, initiator: string, registration_schema: string>, type: string>"
    get-draft-registrations-draft-id-institutions: "record<attributes: record<auth_url: string, description: string, logo_path: string, name: string>, id: string, links: record<self: string>, relationships: record<nodes: string, registrations: string, users: string>, type: string>"
    nodes-draft-registrations-subjects: "record<attributes: record<taxonomy_name: string, text: string>, embeds: record<parent: record<data: record>>, id: string, links: record<self: string>, relationships: record<children: string, parent: string>, type: string>"
    files-detail: "table<attributes: record<checkout: string, current_user_can_comment: bool, current_version: int, date_created: string, date_modified: string, delete_allowed: bool, extra: record, guid: string, kind: string, last_touched: string, materialized_path: string, name: string, path: string, provider: string, size: int, tags: list>, id: string, links: record<delete: string, download: string, info: string, move: string, new_folder: string, self: string, upload: string>, relationships: record<checkout: string, comments: string, node: string, versions: string>, type: string>"
    files-versions: "table<attributes: record<content_type: record, date_created: string, size: int>, id: string, links: record<html: string, self: string>, type: string>"
    files-version-detail: "table<attributes: record<content_type: record, date_created: string, size: int>, id: string, links: record<html: string, self: string>, type: string>"
    institutions-list: "table<attributes: record<auth_url: string, description: string, logo_path: string, name: string>, id: string, links: record<self: string>, relationships: record<nodes: string, registrations: string, users: string>, type: string>"
    institutions-detail: "table<attributes: record<auth_url: string, description: string, logo_path: string, name: string>, id: string, links: record<self: string>, relationships: record<nodes: string, registrations: string, users: string>, type: string>"
    institutions-node-list: "table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, description: string, fork: bool, forked_date: string, node_license: string, preprint: bool, public: bool, registration: bool, tags: list, template_from: string, title: string>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, draft_registrations: string, files: string, forked_from: string, forks: string, identifiers: string, license: string, linked_nodes: string, logs: string, node_links: string, parent: string, preprints: string, registrations: string, root: string, template_node: string, view_only_links: string, wikis: string>, type: string>"
    institutions-users-list: "table<attributes: record<active: bool, date_registered: string, family_name: string, full_name: string, given_name: string, locale: string, middle_names: string, suffix: string, timezone: string>, id: string, links: record<html: string, profile_image: string>, relationships: record<institutions: string, nodes: string>, type: string>"
    licenses-read: "record<attributes: record<name: string, required_fields: list<string>, text: string>, id: string, links: record<self: string>, type: string>"
    license-list: "table<attributes: record<name: string, required_fields: list, text: string>, id: string, links: record<self: string>, type: string>"
    logs-read: "record<attributes: record<action: string, date: string, params: record<addon: string, anonymous_link: bool, bucket: string, citation_name: string, contributors: string, data_set: string, destination: string, figshare_title: string, file: string, filename: string, folder: string, folder_name: string, forward_url: string, github_repo: string, github_user: string, identifiers: string, institution: string, kind: string, license: string, old_page: string, page: string, page_id: string, params_node: string, params_project: string, path: string, pointer: string, preprint: string, preprint_provider: string, previous_institution: string, source: string, study: string, tag: string, tags: string, target: string, template_node: string, title_new: string, title_original: string, updated_fields: string, urls: string, version: string, wiki: string>>, id: string, links: record<self: string>, relationships: record<linked_node: string, node: string, original_node: string, template_node: string, user: string>, type: string>"
    nodes-list: "table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, description: string, fork: bool, forked_date: string, node_license: string, preprint: bool, public: bool, registration: bool, tags: list, template_from: string, title: string>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, draft_registrations: string, files: string, forked_from: string, forks: string, identifiers: string, license: string, linked_nodes: string, logs: string, node_links: string, parent: string, preprints: string, registrations: string, root: string, template_node: string, view_only_links: string, wikis: string>, type: string>"
    nodes-read: "record<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list<string>, date_created: string, date_modified: string, description: string, fork: bool, forked_date: string, node_license: string, preprint: bool, public: bool, registration: bool, tags: list<string>, template_from: string, title: string>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, draft_registrations: string, files: string, forked_from: string, forks: string, identifiers: string, license: string, linked_nodes: string, logs: string, node_links: string, parent: string, preprints: string, registrations: string, root: string, template_node: string, view_only_links: string, wikis: string>, type: string>"
    nodes-addons-list: "table<attributes: record<categories: list, description: string, name: string, url: string>, id: string, type: string>"
    nodes-addon-read: "record<attributes: record<configured: bool, enabled: bool, external_account_id: string, folder_id: string, folder_path: string, label: string, node_has_auth: bool, url: string>, id: string, links: record<self: string>, type: string>"
    nodes-addons-folders-list: "table<attributes: record<categories: list, description: string, name: string, url: string>, id: string, type: string>"
    nodes-children-list: "table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, description: string, fork: bool, forked_date: string, node_license: string, preprint: bool, public: bool, registration: bool, tags: list, template_from: string, title: string>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, draft_registrations: string, files: string, forked_from: string, forks: string, identifiers: string, license: string, linked_nodes: string, logs: string, node_links: string, parent: string, preprints: string, registrations: string, root: string, template_node: string, view_only_links: string, wikis: string>, type: string>"
    nodes-citation-list: "record<attributes: record<author: string, doi: string, publisher: string, title: string>, id: string, links: record<self: string>, type: string>"
    nodes-citation-read: "record<attributes: record<citation: string>, id: string, type: string>"
    nodes-comments-list: "table<attributes: record<can_edit: bool, content: string, date_created: string, date_modified: string, deleted: bool, has_children: bool, has_report: bool, is_abuse: bool, is_ham: bool, modified: bool, page: string>, id: string, links: record<self: string>, relationships: record<node: string, replies: string, reports: string, target: string, user: string>, type: string>"
    nodes-contributors-list: "table<attributes: record<bibliographic: bool, index: int, permission: string, unregistered_contributor: string>, id: string, links: record<self: string>, relationships: record<node: string, user: string>, type: string>"
    nodes-contributors-read: "table<attributes: record<bibliographic: bool, index: int, permission: string, unregistered_contributor: string>, id: string, links: record<self: string>, relationships: record<node: string, user: string>, type: string>"
    nodes-draft-registrations-list: "table<attributes: record<category: string, current_user_permissions: list, datetime_initiated: string, datetime_updated: string, description: string, has_project: bool, node_license: record, registration_metadata: record, registration_responses: record, tags: list, title: string>, id: string, links: record<html: string>, relationships: record<branched_from: string, initiator: string, registration_schema: string>, type: string>"
    nodes-draft-registrations-read: "record<attributes: record<category: string, current_user_permissions: list<string>, datetime_initiated: string, datetime_updated: string, description: string, has_project: bool, node_license: record<copyright_holders: list, year: int>, registration_metadata: record, registration_responses: record, tags: list<string>, title: string>, id: string, links: record<html: string>, relationships: record<branched_from: string, initiator: string, registration_schema: string>, type: string>"
    nodes-providers-list: "table<attributes: record<checkout: string, current_user_can_comment: bool, current_version: int, date_created: string, date_modified: string, delete_allowed: bool, extra: record, guid: string, kind: string, last_touched: string, materialized_path: string, name: string, path: string, provider: string, size: int, tags: list>, id: string, links: record<delete: string, download: string, info: string, move: string, new_folder: string, self: string, upload: string>, relationships: record<checkout: string, comments: string, node: string, versions: string>, type: string>"
    nodes-providers-read: "record<attributes: record<checkout: string, current_user_can_comment: bool, current_version: int, date_created: string, date_modified: string, delete_allowed: bool, extra: record, guid: string, kind: string, last_touched: string, materialized_path: string, name: string, path: string, provider: string, size: int, tags: list<string>>, id: string, links: record<delete: string, download: string, info: string, move: string, new_folder: string, self: string, upload: string>, relationships: record<checkout: string, comments: string, node: string, versions: string>, type: string>"
    nodes-files-list: "table<attributes: record<checkout: string, current_user_can_comment: bool, current_version: int, date_created: string, date_modified: string, delete_allowed: bool, extra: record, guid: string, kind: string, last_touched: string, materialized_path: string, name: string, path: string, provider: string, size: int, tags: list>, id: string, links: record<delete: string, download: string, info: string, move: string, new_folder: string, self: string, upload: string>, relationships: record<checkout: string, comments: string, node: string, versions: string>, type: string>"
    nodes-files-read: "record<attributes: record<checkout: string, current_user_can_comment: bool, current_version: int, date_created: string, date_modified: string, delete_allowed: bool, extra: record, guid: string, kind: string, last_touched: string, materialized_path: string, name: string, path: string, provider: string, size: int, tags: list<string>>, id: string, links: record<delete: string, download: string, info: string, move: string, new_folder: string, self: string, upload: string>, relationships: record<checkout: string, comments: string, node: string, versions: string>, type: string>"
    nodes-forks-list: "table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, description: string, fork: bool, forked_date: string, node_license: string, preprint: bool, public: bool, registration: bool, tags: list, template_from: string, title: string>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, draft_registrations: string, files: string, forked_from: string, forks: string, identifiers: string, license: string, linked_nodes: string, logs: string, node_links: string, parent: string, preprints: string, registrations: string, root: string, template_node: string, view_only_links: string, wikis: string>, type: string>"
    nodes-identifiers-list: "table<attributes: record<category: string, value: string>, id: string, links: record<self: string>, relationships: record<referent: string>, type: string>"
    nodes-institutions-list: "table<attributes: record<auth_url: string, description: string, logo_path: string, name: string>, id: string, links: record<self: string>, relationships: record<nodes: string, registrations: string, users: string>, type: string>"
    nodes-linked-nodes-list: "table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, description: string, fork: bool, forked_date: string, node_license: string, preprint: bool, public: bool, registration: bool, tags: list, template_from: string, title: string>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, draft_registrations: string, files: string, forked_from: string, forks: string, identifiers: string, license: string, linked_nodes: string, logs: string, node_links: string, parent: string, preprints: string, registrations: string, root: string, template_node: string, view_only_links: string, wikis: string>, type: string>"
    nodes-logs-list: "table<attributes: record<action: string, date: string, params: record>, id: string, links: record<self: string>, relationships: record<linked_node: string, node: string, original_node: string, template_node: string, user: string>, type: string>"
    nodes-preprints-list: "table<attributes: record<date_created: string, date_modified: string, date_published: string, doi: string, is_preprint_orphan: bool, license_record: string, subjects: list>, id: string, links: record<doi: string, html: string, preprint_doi: string, self: string>, relationships: record<bibliographic_contributors: string, citation: string, identifiers: string, license: string, node: string, primary_file: string, provider: string>, type: string>"
    nodes-registrations-list: "table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, date_registered: string, date_withdrawn: string, description: string, embargo_end_date: string, fork: bool, node_license: string, pending_embargo_approval: bool, pending_registration_approval: bool, pending_withdrawal: bool, preprint: bool, public: bool, registered_meta: string, registration: bool, registration_supplement: string, tags: list, template_from: string, title: string, withdrawal_justification: string, withdrawn: bool>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, files: string, forks: string, identifiers: string, linked_nodes: string, logs: string, node_links: string, parent: string, registered_by: string, registered_from: string, registration_schema: string, root: string, view_only_links: string, wikis: string>, type: string>"
    nodes-view-only-links-list: "table<attributes: record<anonymous: bool, date_created: string, key: string, name: string>, id: string, relationships: record<creator: string, nodes: string>, type: string>"
    nodes-view-only-links-read: "record<attributes: record<anonymous: bool, date_created: string, key: string, name: string>, id: string, relationships: record<creator: string, nodes: string>, type: string>"
    nodes-wikis-list: "table<attributes: record<content_type: string, current_user_can_comment: string, date_modified: string, extra: string, kind: string, materialized_path: string, name: string, path: string, size: string>, id: string, links: record<download: string, info: string, self: string>, relationships: record<comments: string, node: string, user: string>, type: string>"
    preprint-provider-list: "record<attributes: record<advisory_board: string, banner_path: string, description: string, domain: string, domain_redirect_enabled: bool, email_contact: string, email_support: string, example: string, logo_path: string, name: string, social_facebook: string, social_instagram: string, subjects_acceptable: string>, id: string, links: record<external_url: string, preprints: string, self: string>, relationships: record<licenses_acceptable: string, preprints: string, taxonomies: string>, type: string>"
    preprint-provider-detail: "record<attributes: record<advisory_board: string, banner_path: string, description: string, domain: string, domain_redirect_enabled: bool, email_contact: string, email_support: string, example: string, logo_path: string, name: string, social_facebook: string, social_instagram: string, subjects_acceptable: string>, id: string, links: record<external_url: string, preprints: string, self: string>, relationships: record<licenses_acceptable: string, preprints: string, taxonomies: string>, type: string>"
    preprint-provider-licenses-list: "record<attributes: record<name: string, required_fields: list<string>, text: string>, id: string, links: record<self: string>, type: string>"
    preprint-providers-preprints-list: "table<attributes: record<date_created: string, date_modified: string, date_published: string, doi: string, is_preprint_orphan: bool, license_record: string, subjects: list>, id: string, links: record<doi: string, html: string, preprint_doi: string, self: string>, relationships: record<bibliographic_contributors: string, citation: string, identifiers: string, license: string, node: string, primary_file: string, provider: string>, type: string>"
    preprint-provider-taxonomies-list: "record<attributes: record<child_count: int, parents: list<string>, text: string>, id: string, links: record<parents: list<string>, self: string>, type: string>"
    preprints-list: "table<attributes: record<date_created: string, date_modified: string, date_published: string, doi: string, is_preprint_orphan: bool, license_record: string, subjects: list>, id: string, links: record<doi: string, html: string, preprint_doi: string, self: string>, relationships: record<bibliographic_contributors: string, citation: string, identifiers: string, license: string, node: string, primary_file: string, provider: string>, type: string>"
    preprints-read: "record<attributes: record<date_created: string, date_modified: string, date_published: string, doi: string, is_preprint_orphan: bool, license_record: string, subjects: list<string>>, id: string, links: record<doi: string, html: string, preprint_doi: string, self: string>, relationships: record<bibliographic_contributors: string, citation: string, identifiers: string, license: string, node: string, primary_file: string, provider: string>, type: string>"
    preprints-bibliographic-contributors-list: "table<attributes: record<bibliographic: bool, index: int, permission: string, unregistered_contributor: string>, id: string, links: record<self: string>, relationships: record<node: string, user: string>, type: string>"
    preprints-citation-list: "record<attributes: record<author: string, doi: string, publisher: string, title: string>, id: string, links: record<self: string>, type: string>"
    preprints-citation-read: "record<attributes: record<citation: string>, id: string, type: string>"
    preprints-contributors-list: "table<attributes: record<bibliographic: bool, index: int, permission: string, unregistered_contributor: string>, id: string, links: record<self: string>, relationships: record<node: string, user: string>, type: string>"
    registrations-list: "table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, date_registered: string, date_withdrawn: string, description: string, embargo_end_date: string, fork: bool, node_license: string, pending_embargo_approval: bool, pending_registration_approval: bool, pending_withdrawal: bool, preprint: bool, public: bool, registered_meta: string, registration: bool, registration_supplement: string, tags: list, template_from: string, title: string, withdrawal_justification: string, withdrawn: bool>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, files: string, forks: string, identifiers: string, linked_nodes: string, logs: string, node_links: string, parent: string, registered_by: string, registered_from: string, registration_schema: string, root: string, view_only_links: string, wikis: string>, type: string>"
    registrations-read: "record<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list<string>, date_created: string, date_modified: string, date_registered: string, date_withdrawn: string, description: string, embargo_end_date: string, fork: bool, node_license: string, pending_embargo_approval: bool, pending_registration_approval: bool, pending_withdrawal: bool, preprint: bool, public: bool, registered_meta: string, registration: bool, registration_supplement: string, tags: list<string>, template_from: string, title: string, withdrawal_justification: string, withdrawn: bool>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, files: string, forks: string, identifiers: string, linked_nodes: string, logs: string, node_links: string, parent: string, registered_by: string, registered_from: string, registration_schema: string, root: string, view_only_links: string, wikis: string>, type: string>"
    registrations-children-list: "table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, date_registered: string, date_withdrawn: string, description: string, embargo_end_date: string, fork: bool, node_license: string, pending_embargo_approval: bool, pending_registration_approval: bool, pending_withdrawal: bool, preprint: bool, public: bool, registered_meta: string, registration: bool, registration_supplement: string, tags: list, template_from: string, title: string, withdrawal_justification: string, withdrawn: bool>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, files: string, forks: string, identifiers: string, linked_nodes: string, logs: string, node_links: string, parent: string, registered_by: string, registered_from: string, registration_schema: string, root: string, view_only_links: string, wikis: string>, type: string>"
    registrations-citations-list: "table<attributes: record<date_parsed: string, short_title: string, summary: string, title: string>, id: string, links: record, type: string>"
    registrations-citation-read: "record<attributes: record<author: string, doi: string, publisher: string, title: string>, id: string, links: record<self: string>, type: string>"
    registrations-comments-list: "table<attributes: record<can_edit: bool, content: string, date_created: string, date_modified: string, deleted: bool, has_children: bool, has_report: bool, is_abuse: bool, is_ham: bool, modified: bool, page: string>, id: string, links: record<self: string>, relationships: record<node: string, replies: string, reports: string, target: string, user: string>, type: string>"
    registrations-contributors-list: "table<attributes: record<bibliographic: bool, index: int, permission: string, unregistered_contributor: string>, id: string, links: record<self: string>, relationships: record<node: string, user: string>, type: string>"
    registrations-contributors-read: "table<attributes: record<bibliographic: bool, index: int, permission: string, unregistered_contributor: string>, id: string, links: record<self: string>, relationships: record<node: string, user: string>, type: string>"
    registrations-providers-list: "table<attributes: record<checkout: string, current_user_can_comment: bool, current_version: int, date_created: string, date_modified: string, delete_allowed: bool, extra: record, guid: string, kind: string, last_touched: string, materialized_path: string, name: string, path: string, provider: string, size: int, tags: list>, id: string, links: record<delete: string, download: string, info: string, move: string, new_folder: string, self: string, upload: string>, relationships: record<checkout: string, comments: string, node: string, versions: string>, type: string>"
    registrations-files-list: "table<attributes: record<checkout: string, current_user_can_comment: bool, current_version: int, date_created: string, date_modified: string, delete_allowed: bool, extra: record, guid: string, kind: string, last_touched: string, materialized_path: string, name: string, path: string, provider: string, size: int, tags: list>, id: string, links: record<delete: string, download: string, info: string, move: string, new_folder: string, self: string, upload: string>, relationships: record<checkout: string, comments: string, node: string, versions: string>, type: string>"
    registrations-files-read: "record<attributes: record<checkout: string, current_user_can_comment: bool, current_version: int, date_created: string, date_modified: string, delete_allowed: bool, extra: record, guid: string, kind: string, last_touched: string, materialized_path: string, name: string, path: string, provider: string, size: int, tags: list<string>>, id: string, links: record<delete: string, download: string, info: string, move: string, new_folder: string, self: string, upload: string>, relationships: record<checkout: string, comments: string, node: string, versions: string>, type: string>"
    registrations-forks-list: "table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, date_registered: string, date_withdrawn: string, description: string, embargo_end_date: string, fork: bool, node_license: string, pending_embargo_approval: bool, pending_registration_approval: bool, pending_withdrawal: bool, preprint: bool, public: bool, registered_meta: string, registration: bool, registration_supplement: string, tags: list, template_from: string, title: string, withdrawal_justification: string, withdrawn: bool>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, files: string, forks: string, identifiers: string, linked_nodes: string, logs: string, node_links: string, parent: string, registered_by: string, registered_from: string, registration_schema: string, root: string, view_only_links: string, wikis: string>, type: string>"
    registrations-identifiers-list: "table<attributes: record<category: string, value: string>, id: string, links: record<self: string>, relationships: record<referent: string>, type: string>"
    registrations-institutions-list: "table<attributes: record<auth_url: string, description: string, logo_path: string, name: string>, id: string, links: record<self: string>, relationships: record<nodes: string, registrations: string, users: string>, type: string>"
    registrations-linked-nodes-list: "table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, description: string, fork: bool, forked_date: string, node_license: string, preprint: bool, public: bool, registration: bool, tags: list, template_from: string, title: string>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, draft_registrations: string, files: string, forked_from: string, forks: string, identifiers: string, license: string, linked_nodes: string, logs: string, node_links: string, parent: string, preprints: string, registrations: string, root: string, template_node: string, view_only_links: string, wikis: string>, type: string>"
    registrations-logs-list: "table<attributes: record<action: string, date: string, params: record>, id: string, links: record<self: string>, relationships: record<linked_node: string, node: string, original_node: string, template_node: string, user: string>, type: string>"
    registrations-view-only-links-list: "table<attributes: record<anonymous: bool, date_created: string, key: string, name: string>, id: string, relationships: record<creator: string, nodes: string>, type: string>"
    registrations-view-only-links-read: "record<attributes: record<anonymous: bool, date_created: string, key: string, name: string>, id: string, relationships: record<creator: string, nodes: string>, type: string>"
    registrations-wikis-list: "table<attributes: record<content_type: string, current_user_can_comment: string, date_modified: string, extra: string, kind: string, materialized_path: string, name: string, path: string, size: string>, id: string, links: record<download: string, info: string, self: string>, relationships: record<comments: string, node: string, user: string>, type: string>"
    schema-responses-list: "record<attributes: record<date_created: int, date_modified: int, date_submitted: int, is_original_response: bool, is_pending_current_user_approval: bool, reviews_state: string, revision_justification: string, revision_responses: record, updated_response_keys: list<any>>, id: string, links: record<self: string>, relationships: record<actions: string, initiated_by: string, registration: string, registration_schema: string>, type: string>"
    schema-response-ppost: "record<attributes: record<date_created: int, date_modified: int, date_submitted: int, is_original_response: bool, is_pending_current_user_approval: bool, reviews_state: string, revision_justification: string, revision_responses: record, updated_response_keys: list<any>>, id: string, links: record<self: string>, relationships: record<actions: string, initiated_by: string, registration: string, registration_schema: string>, type: string>"
    schema-responses-read: "record<attributes: record<date_created: int, date_modified: int, date_submitted: int, is_original_response: bool, is_pending_current_user_approval: bool, reviews_state: string, revision_justification: string, revision_responses: record, updated_response_keys: list<any>>, id: string, links: record<self: string>, relationships: record<actions: string, initiated_by: string, registration: string, registration_schema: string>, type: string>"
    schema-response-patch: "record<attributes: record<date_created: int, date_modified: int, date_submitted: int, is_original_response: bool, is_pending_current_user_approval: bool, reviews_state: string, revision_justification: string, revision_responses: record, updated_response_keys: list<any>>, id: string, links: record<self: string>, relationships: record<actions: string, initiated_by: string, registration: string, registration_schema: string>, type: string>"
    schema-response-action-read: "record<attributes: record<auto: bool, comment: string, date_created: string, from_state: string, to_state: string, trigger: string, visible: bool>, id: string, links: record<self: string>, relationships: record<creator: string, target: string>, type: string>"
    get-schema-responses-schema-response-id-actions-schema-response-action-id: "record<attributes: record<auto: bool, comment: string, date_created: string, from_state: string, to_state: string, trigger: string, visible: bool>, id: string, links: record<self: string>, relationships: record<creator: string, target: string>, type: string>"
    schema-response-blocks-read: "record<attributes: record<block_type: string, display_text: string, example_text: string, index: int, registration_response_key: string, required: bool, schema_block_group_key: string>, id: string, links: record<self: string>, relationships: record<schema: string>, type: string>"
    get-schema-responses-schema-response-id-schema-blocks-schema-response-block-id: "record<attributes: record<block_type: string, display_text: string, example_text: string, index: int, registration_response_key: string, required: bool, schema_block_group_key: string>, id: string, links: record<self: string>, relationships: record<schema: string>, type: string>"
    registration-schemas-list: "record<attributes: record<active: bool, name: string, schema: record, schema_version: int>, id: string, links: record<self: string>, relationships: record<schema_blocks: string>, type: string>"
    registration-schema-read: "record<attributes: record<active: bool, name: string, schema: record, schema_version: int>, id: string, links: record<self: string>, relationships: record<schema_blocks: string>, type: string>"
    taxonomies-list: "table<attributes: record<child_count: int, parents: list, text: string>, id: string, links: record<parents: list, self: string>, type: string>"
    taxonomies-read: "record<attributes: record<child_count: int, parents: list<string>, text: string>, id: string, links: record<parents: list<string>, self: string>, type: string>"
    users-list: "table<attributes: record<active: bool, date_registered: string, family_name: string, full_name: string, given_name: string, locale: string, middle_names: string, suffix: string, timezone: string>, id: string, links: record<html: string, profile_image: string>, relationships: record<institutions: string, nodes: string>, type: string>"
    users-read: "record<attributes: record<active: bool, date_registered: string, family_name: string, full_name: string, given_name: string, locale: string, middle_names: string, suffix: string, timezone: string>, id: string, links: record<html: string, profile_image: string>, relationships: record<institutions: string, nodes: string>, type: string>"
    users-addons-list: "table<attributes: record<user_has_auth: bool>, id: string, links: record<accounts: record, self: string>, type: string>"
    users-addons-read: "record<attributes: record<user_has_auth: bool>, id: string, links: record<accounts: record, self: string>, type: string>"
    users-addon-accounts-list: "table<attributes: record<display_name: string, profile_url: string, provider: string>, id: string, links: record<self: string>, type: string>"
    users-addon-accounts-read: "record<attributes: record<display_name: string, profile_url: string, provider: string>, id: string, links: record<self: string>, type: string>"
    users-institutions-list: "table<attributes: record<auth_url: string, description: string, logo_path: string, name: string>, id: string, links: record<self: string>, relationships: record<nodes: string, registrations: string, users: string>, type: string>"
    users-nodes-list: "table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, description: string, fork: bool, forked_date: string, node_license: string, preprint: bool, public: bool, registration: bool, tags: list, template_from: string, title: string>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, draft_registrations: string, files: string, forked_from: string, forks: string, identifiers: string, license: string, linked_nodes: string, logs: string, node_links: string, parent: string, preprints: string, registrations: string, root: string, template_node: string, view_only_links: string, wikis: string>, type: string>"
    users-preprints-list: "table<attributes: record<date_created: string, date_modified: string, date_published: string, doi: string, is_preprint_orphan: bool, license_record: string, subjects: list>, id: string, links: record<doi: string, html: string, preprint_doi: string, self: string>, relationships: record<bibliographic_contributors: string, citation: string, identifiers: string, license: string, node: string, primary_file: string, provider: string>, type: string>"
    view-only-links-read: "record<attributes: record<anonymous: bool, date_created: string, key: string, name: string>, id: string, relationships: record<creator: string, nodes: string>, type: string>"
    view-only-links-node-list: "table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, description: string, fork: bool, forked_date: string, node_license: string, preprint: bool, public: bool, registration: bool, tags: list, template_from: string, title: string>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, draft_registrations: string, files: string, forked_from: string, forks: string, identifiers: string, license: string, linked_nodes: string, logs: string, node_links: string, parent: string, preprints: string, registrations: string, root: string, template_node: string, view_only_links: string, wikis: string>, type: string>"
    wiki-read: "record<attributes: record<content_type: string, current_user_can_comment: string, date_modified: string, extra: string, kind: string, materialized_path: string, name: string, path: string, size: string>, id: string, links: record<download: string, info: string, self: string>, relationships: record<comments: string, node: string, user: string>, type: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["base-read" "logs-actions" "addons-list" "citations-styles-list" "citations-styles-read" "collections-list" "collections-create" "collections-delete" "collections-detail" "collections-metadata-registrations-list" "collections-add-metadata" "collections-metadata-delete" "collections-metadata-registrations-detail" "collections-metadata-detail" "collections-metadata-subjects-relationships" "collections-metadata-subjects-relationships-update" "collections-collected-metadata" "collections-linked-nodes-list" "collections-linked-nodes-relationships-delete" "collections-linked-nodes-relationships-create" "collections-linked-nodes-relationships" "collections-linked-preprints-list" "collections-linked-registrations-list" "collections-linked-registrations-relationships-delete" "collections-linked-registrations-relationships-create" "collections-linked-registrations-relationships" "comments-delete" "comments-read" "comments-put" "draft-registrations-read" "draft-registrations-create" "delete-draft-registrations-draft-id" "get-draft-registrations-draft-id" "patch-draft-registrations-draft-id" "draft-registration-contributors-list" "draft-registration-contributors-create" "get-draft-registrations-draft-id-contributors-user-id" "get-draft-registrations-draft-id-institutions" "nodes-draft-registrations-subjects" "files-detail" "files-patch" "files-versions" "files-version-detail" "institutions-list" "institutions-detail" "institutions-node-list" "institutions-registration-list" "institutions-users-list" "licenses-read" "license-list" "logs-read" "nodes-list" "nodes-create" "nodes-delete" "nodes-read" "nodes-partial-update" "nodes-addons-list" "nodes-addon-read" "nodes-node-addon-update" "nodes-addons-folders-list" "nodes-children-list" "nodes-children-create" "nodes-citation-list" "nodes-citation-read" "nodes-comments-list" "nodes-comment-create" "nodes-contributors-list" "nodes-contributors-create" "nodes-contributors-delete" "nodes-contributors-read" "nodes-contributors-partial-update" "nodes-draft-registrations-list" "nodes-draft-registrations-create" "nodes-draft-registrations-delete" "nodes-draft-registrations-read" "nodes-draft-registrations-partial-update" "nodes-providers-list" "nodes-providers-read" "nodes-files-list" "nodes-files-read" "nodes-forks-list" "nodes-forks-create" "nodes-identifiers-list" "nodes-institutions-list" "nodes-linked-nodes-list" "nodes-logs-list" "nodes-preprints-list" "nodes-registrations-list" "nodes-view-only-links-list" "nodes-view-only-links-read" "nodes-wikis-list" "preprint-provider-list" "preprint-provider-detail" "preprint-provider-licenses-list" "preprint-providers-preprints-list" "preprint-provider-taxonomies-list" "preprints-list" "preprints-create" "preprints-read" "preprints-partial-update" "preprints-bibliographic-contributors-list" "preprints-citation-list" "preprints-citation-read" "preprints-contributors-list" "preprints-contributors-create" "preprints-contributor-read" "registrations-list" "registrations-read" "registrations-partial-update" "registrations-children-list" "registrations-citations-list" "registrations-citation-read" "registrations-comments-list" "registrations-contributors-list" "registrations-contributors-read" "registrations-providers-list" "registrations-files-list" "registrations-files-read" "registrations-forks-list" "registrations-forks-create" "registrations-identifiers-list" "registrations-institutions-list" "registrations-linked-nodes-list" "registrations-logs-list" "registrations-view-only-links-list" "registrations-view-only-links-read" "registrations-wikis-list" "schema-responses-list" "schema-response-ppost" "schema-response-delete" "schema-responses-read" "schema-response-patch" "schema-response-action-read" "post-schema-responses-schema-response-id-actions" "get-schema-responses-schema-response-id-actions-schema-response-action-id" "schema-response-blocks-read" "get-schema-responses-schema-response-id-schema-blocks-schema-response-block-id" "registration-schemas-list" "registration-schema-read" "taxonomies-list" "taxonomies-read" "users-list" "users-read" "users-partial-update" "users-addons-list" "users-addons-read" "users-addon-accounts-list" "users-addon-accounts-read" "users-institutions-list" "users-nodes-list" "users-preprints-list" "users-registrations-list" "view-only-links-read" "view-only-links-node-list" "wiki-read" "wiki-content" "commands"] | sort) } | get name | first)
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

# Root
#
# GET /
# operationId: base_read
export def "base-read" [
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
    path: "/"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Actions
#
# GET /actions/
# operationId: logs_actions
export def "logs-actions" [
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
    path: "/actions/"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all addons
#
# GET /addons/
# Returns: table<attributes: record<categories: list, description: string, name: string, url: string>, id: string, type: string>
# operationId: addons_list
export def "addons-list" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/addons/"
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all citation styles
#
# GET /citations/styles/
# Returns: table<attributes: record<date_parsed: string, short_title: string, summary: string, title: string>, id: string, links: record, type: string>
# operationId: citations_styles_list
export def "citations-styles-list" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/citations/styles/"
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a citation style
#
# GET /citations/styles/{style_id}/
# Returns: record<attributes: record<date_parsed: string, short_title: string, summary: string, title: string>, id: string, links: record, type: string>
# operationId: citations_styles_read
export def "citations-styles-read" [
  style_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/citations/styles/{style_id}/"
    path_params: [{name: style_id, var: style_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    style_id: $style_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all Collections
#
# GET /collections/
# Returns: table<attributes: record<bookmarks: bool, collected_type_choices: list, date_created: string, date_modified: string, is_promoted: bool, is_public: bool, issue_choices: list, program_area_choices: list, status_choices: list, title: string, volume_choices: list>, id: string, links: record<self: string>, relationships: record<collected_metadata: string, linked_nodes: string, linked_preprints: string, linked_registrations: string, node_links: string, provider: string>, type: string>
# operationId: collections_list
export def "collections-list" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/collections/"
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a Collection
#
# POST /collections/
# operationId: collections_create
export def "collections-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/collections/"
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Collection
#
# DELETE /collections/{collection_id}/
# operationId: collections_delete
export def "collections-delete" [
  collection_id: string
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
    path: "/collections/{collection_id}/"
    path_params: [{name: collection_id, var: collection_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    collection_id: $collection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Collection
#
# GET /collections/{collection_id}/
# Returns: table<attributes: record<bookmarks: bool, collected_type_choices: list, date_created: string, date_modified: string, is_promoted: bool, is_public: bool, issue_choices: list, program_area_choices: list, status_choices: list, title: string, volume_choices: list>, id: string, links: record<self: string>, relationships: record<collected_metadata: string, linked_nodes: string, linked_preprints: string, linked_registrations: string, node_links: string, provider: string>, type: string>
# operationId: collections_detail
export def "collections-detail" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/collections/{collection_id}/"
    path_params: [{name: collection_id, var: collection_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a list of collected metadata for a collection
#
# GET /collections/{collection_id}/collected_metadata/
# operationId: collections_metadata_registrations_list
export def "collections-metadata-registrations-list" [
  collection_id: string
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
    path: "/collections/{collection_id}/collected_metadata/"
    path_params: [{name: collection_id, var: collection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add Metadata or Subjects to a Entity in a Collection
#
# POST /collections/{collection_id}/collected_metadata/
# operationId: collections_add_metadata
export def "collections-add-metadata" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/collections/{collection_id}/collected_metadata/"
    path_params: [{name: collection_id, var: collection_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    collection_id: $collection_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Collection Metadata from entitiy
#
# DELETE /collections/{collection_id}/collected_metadata/{cgm_id}
# operationId: collections_metadata_delete
export def "collections-metadata-delete" [
  collection_id: string
  cgm_id: string
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
    path: "/collections/{collection_id}/collected_metadata/{cgm_id}"
    path_params: [{name: collection_id, var: collection_id}, {name: cgm_id, var: cgm_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    collection_id: $collection_id, cgm_id: $cgm_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Specific Metadata for a Collection
#
# GET /collections/{collection_id}/collected_metadata/{cgm_id}
# operationId: collections_metadata_registrations_detail
export def "collections-metadata-registrations-detail" [
  collection_id: string
  cgm_id: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/collections/{collection_id}/collected_metadata/{cgm_id}"
    path_params: [{name: collection_id, var: collection_id}, {name: cgm_id, var: cgm_id}]
    accept: [data, meta]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id, cgm_id: $cgm_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add Metadata or Subjects to an Entity in a Collection
#
# POST /collections/{collection_id}/collected_metadata/{cgm_id}
# operationId: collections_metadata_detail
export def "collections-metadata-detail" [
  collection_id: string
  cgm_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/collections/{collection_id}/collected_metadata/{cgm_id}"
    path_params: [{name: collection_id, var: collection_id}, {name: cgm_id, var: cgm_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    collection_id: $collection_id, cgm_id: $cgm_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve subject metadata for a specific piece of metadata in a collection
#
# GET /collections/{collection_id}/collected_metadata/{cgm_id}/relationships/subjects/
# operationId: collections_metadata_subjects_relationships
export def "collections-metadata-subjects-relationships" [
  collection_id: string
  cgm_id: string
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
    path: "/collections/{collection_id}/collected_metadata/{cgm_id}/relationships/subjects/"
    path_params: [{name: collection_id, var: collection_id}, {name: cgm_id, var: cgm_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id, cgm_id: $cgm_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update subjects for a specific piece of metadata in a collection
#
# POST /collections/{collection_id}/collected_metadata/{cgm_id}/relationships/subjects/
# operationId: collections_metadata_subjects_relationships_update
export def "collections-metadata-subjects-relationships-update" [
  collection_id: string
  cgm_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/collections/{collection_id}/collected_metadata/{cgm_id}/relationships/subjects/"
    path_params: [{name: collection_id, var: collection_id}, {name: cgm_id, var: cgm_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    collection_id: $collection_id, cgm_id: $cgm_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve subject data for a specific piece of metadata info for a collection
#
# GET /collections/{collection_id}/collected_metadata/{cgm_id}/subjects/
# operationId: collections_collected_metadata
export def "collections-collected-metadata" [
  collection_id: string
  cgm_id: string
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
    path: "/collections/{collection_id}/collected_metadata/{cgm_id}/subjects/"
    path_params: [{name: collection_id, var: collection_id}, {name: cgm_id, var: cgm_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id, cgm_id: $cgm_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List All Linked Nodes for a Collection
#
# GET /collections/{collection_id}/linked_nodes
# operationId: collections_linked_nodes_list
export def "collections-linked-nodes-list" [
  collection_id: string
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
    path: "/collections/{collection_id}/linked_nodes"
    path_params: [{name: collection_id, var: collection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove Nodes From Collection
#
# DELETE /collections/{collection_id}/linked_nodes/relationships/
# operationId: collections_linked_nodes_relationships_delete
export def "collections-linked-nodes-relationships-delete" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: delete
    path: "/collections/{collection_id}/linked_nodes/relationships/"
    path_params: [{name: collection_id, var: collection_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Give a Sparse List of Node Ids
#
# GET /collections/{collection_id}/linked_nodes/relationships/
# operationId: collections_linked_nodes_relationships_create
export def "collections-linked-nodes-relationships-create" [
  collection_id: string
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
    path: "/collections/{collection_id}/linked_nodes/relationships/"
    path_params: [{name: collection_id, var: collection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Link Nodes to Collection
#
# POST /collections/{collection_id}/linked_nodes/relationships/
# operationId: collections_linked_nodes_relationships
export def "collections-linked-nodes-relationships" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/collections/{collection_id}/linked_nodes/relationships/"
    path_params: [{name: collection_id, var: collection_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    collection_id: $collection_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List All Linked Preprints for a Collection
#
# GET /collections/{collection_id}/linked_preprints/
# operationId: collections_linked_preprints_list
export def "collections-linked-preprints-list" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
]: nothing -> any {
  http-request {
    method: get
    path: "/collections/{collection_id}/linked_preprints/"
    path_params: [{name: collection_id, var: collection_id}]
    accept: ["application/json", links, meta]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List All Linked Registrations for a Collection
#
# GET /collections/{collection_id}/linked_registrations/
# operationId: collections_linked_registrations_list
export def "collections-linked-registrations-list" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
]: nothing -> any {
  http-request {
    method: get
    path: "/collections/{collection_id}/linked_registrations/"
    path_params: [{name: collection_id, var: collection_id}]
    accept: ["application/json", links, meta]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove Registrations From Collection
#
# DELETE /collections/{collection_id}/linked_registrations/relationships/
# operationId: collections_linked_registrations_relationships_delete
export def "collections-linked-registrations-relationships-delete" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: delete
    path: "/collections/{collection_id}/linked_registrations/relationships/"
    path_params: [{name: collection_id, var: collection_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Give a Sparse List of Registrations Ids
#
# GET /collections/{collection_id}/linked_registrations/relationships/
# operationId: collections_linked_registrations_relationships_create
export def "collections-linked-registrations-relationships-create" [
  collection_id: string
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
    path: "/collections/{collection_id}/linked_registrations/relationships/"
    path_params: [{name: collection_id, var: collection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Link Registrations to Collection
#
# POST /collections/{collection_id}/linked_registrations/relationships/
# operationId: collections_linked_registrations_relationships
export def "collections-linked-registrations-relationships" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/collections/{collection_id}/linked_registrations/relationships/"
    path_params: [{name: collection_id, var: collection_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    collection_id: $collection_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a comment
#
# DELETE /comments/{comment_id}/
# operationId: comments_delete
export def "comments-delete" [
  comment_id: string
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
    path: "/comments/{comment_id}/"
    path_params: [{name: comment_id, var: comment_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    comment_id: $comment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a comment
#
# GET /comments/{comment_id}/
# Returns: record<attributes: record<can_edit: bool, content: string, date_created: string, date_modified: string, deleted: bool, has_children: bool, has_report: bool, is_abuse: bool, is_ham: bool, modified: bool, page: string>, id: string, links: record<self: string>, relationships: record<node: string, replies: string, reports: string, target: string, user: string>, type: string>
# operationId: comments_read
export def "comments-read" [
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/comments/{comment_id}/"
    path_params: [{name: comment_id, var: comment_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    comment_id: $comment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a comment
#
# PUT /comments/{comment_id}/
# operationId: comments_put
export def "comments-put" [
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: put
    path: "/comments/{comment_id}/"
    path_params: [{name: comment_id, var: comment_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    comment_id: $comment_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of Draft Registrations
#
# GET /draft_registrations/
# Returns: record<attributes: record<category: string, current_user_permissions: list<string>, datetime_initiated: string, datetime_updated: string, description: string, has_project: bool, node_license: record<copyright_holders: list, year: int>, registration_metadata: record, registration_responses: record, tags: list<string>, title: string>, id: string, links: record<html: string>, relationships: record<branched_from: string, initiator: string, registration_schema: string>, type: string>
# operationId: draft_registrations_read
export def "draft-registrations-read" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/draft_registrations/"
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a Draft Registration
#
# POST /draft_registrations/
# Returns: record<attributes: record<category: string, current_user_permissions: list<string>, datetime_initiated: string, datetime_updated: string, description: string, has_project: bool, node_license: record<copyright_holders: list, year: int>, registration_metadata: record, registration_responses: record, tags: list<string>, title: string>, id: string, links: record<html: string>, relationships: record<branched_from: string, initiator: string, registration_schema: string>, type: string>
# operationId: draft_registrations_create
export def "draft-registrations-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  attributes: record # The properties of the Draft Registration entity. — shape: {category?: string, description?: string, node_license?: record, registration_metadata?: record, registration_responses?: record, tags?: list<string>, title?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/draft_registrations/"
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}]}
    accept: ["*/*", "application/json"]
    ok: [201]
    auth: bearer
  } {
    attributes: $attributes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a draft registration
#
# DELETE /draft_registrations/{draft_id}/
export def "delete-draft-registrations-draft-id" [
  draft_id: string
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
    path: "/draft_registrations/{draft_id}/"
    path_params: [{name: draft_id, var: draft_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    draft_id: $draft_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Draft Registration
#
# GET /draft_registrations/{draft_id}/
# Returns: record<attributes: record<category: string, current_user_permissions: list<string>, datetime_initiated: string, datetime_updated: string, description: string, has_project: bool, node_license: record<copyright_holders: list, year: int>, registration_metadata: record, registration_responses: record, tags: list<string>, title: string>, id: string, links: record<html: string>, relationships: record<branched_from: string, initiator: string, registration_schema: string>, type: string>
export def "get-draft-registrations-draft-id" [
  draft_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/draft_registrations/{draft_id}/"
    path_params: [{name: draft_id, var: draft_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    draft_id: $draft_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a Draft Registration
#
# PATCH /draft_registrations/{draft_id}/
export def "patch-draft-registrations-draft-id" [
  draft_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: patch
    path: "/draft_registrations/{draft_id}/"
    path_params: [{name: draft_id, var: draft_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    draft_id: $draft_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retreive a list Contributors from a Draft Registration
#
# GET /draft_registrations/{draft_id}/contributors/
# operationId: draft_registration_contributors_list
export def "draft-registration-contributors-list" [
  draft_id: string
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
    path: "/draft_registrations/{draft_id}/contributors/"
    path_params: [{name: draft_id, var: draft_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    draft_id: $draft_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a contributor to a Draft Registration
#
# POST /draft_registrations/{draft_id}/contributors/
# operationId: draft_registration_contributors_create
export def "draft-registration-contributors-create" [
  draft_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record # The properties of the contributor entity. — shape: {bibliographic?: bool, index?: int, permission?: "read"|"write"|"admin"}
  relationships: record # URLs to other entities or entity collections that have a relationship to the contributor entity. — shape: {user: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/draft_registrations/{draft_id}/contributors/"
    path_params: [{name: draft_id, var: draft_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: relationships, var: relationships}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    draft_id: $draft_id, attributes: $attributes, relationships: $relationships
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retreive a Contributor from a Draft Registration
#
# GET /draft_registrations/{draft_id}/contributors/{user_id}/
export def "get-draft-registrations-draft-id-contributors-user-id" [
  draft_id: string
  user_id: string
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
    path: "/draft_registrations/{draft_id}/contributors/{user_id}/"
    path_params: [{name: draft_id, var: draft_id}, {name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    draft_id: $draft_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Institutions afilliated with a Draft Registration
#
# GET /draft_registrations/{draft_id}/institutions/
# Returns: record<attributes: record<auth_url: string, description: string, logo_path: string, name: string>, id: string, links: record<self: string>, relationships: record<nodes: string, registrations: string, users: string>, type: string>
export def "get-draft-registrations-draft-id-institutions" [
  draft_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/draft_registrations/{draft_id}/institutions/"
    path_params: [{name: draft_id, var: draft_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    draft_id: $draft_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve Subjects associated with a Draft Registration
#
# GET /draft_registrations/{draft_id}/subjects/
# Returns: record<attributes: record<taxonomy_name: string, text: string>, embeds: record<parent: record<data: record>>, id: string, links: record<self: string>, relationships: record<children: string, parent: string>, type: string>
# operationId: nodes_draft_registrations_subjects
export def "nodes-draft-registrations-subjects" [
  draft_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/draft_registrations/{draft_id}/subjects/"
    path_params: [{name: draft_id, var: draft_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    draft_id: $draft_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a file
#
# GET /files/{file_id}/
# Returns: table<attributes: record<checkout: string, current_user_can_comment: bool, current_version: int, date_created: string, date_modified: string, delete_allowed: bool, extra: record, guid: string, kind: string, last_touched: string, materialized_path: string, name: string, path: string, provider: string, size: int, tags: list>, id: string, links: record<delete: string, download: string, info: string, move: string, new_folder: string, self: string, upload: string>, relationships: record<checkout: string, comments: string, node: string, versions: string>, type: string>
# operationId: files_detail
export def "files-detail" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/files/{file_id}/"
    path_params: [{name: file_id, var: file_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a file
#
# PATCH /files/{file_id}/
# operationId: files_patch
export def "files-patch" [
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
  --body: record
]: any -> any {
  $in | http-request {
    method: patch
    path: "/files/{file_id}/"
    path_params: [{name: file_id, var: file_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all file versions
#
# GET /files/{file_id}/versions/
# Returns: table<attributes: record<content_type: record, date_created: string, size: int>, id: string, links: record<html: string, self: string>, type: string>
# operationId: files_versions
export def "files-versions" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/files/{file_id}/versions/"
    path_params: [{name: file_id, var: file_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a file version
#
# GET /files/{file_id}/versions/{version_id}/
# Returns: table<attributes: record<content_type: record, date_created: string, size: int>, id: string, links: record<html: string, self: string>, type: string>
# operationId: files_version_detail
export def "files-version-detail" [
  file_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/files/{file_id}/versions/{version_id}/"
    path_params: [{name: file_id, var: file_id}, {name: version_id, var: version_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, version_id: $version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all institutions
#
# GET /institutions/
# Returns: table<attributes: record<auth_url: string, description: string, logo_path: string, name: string>, id: string, links: record<self: string>, relationships: record<nodes: string, registrations: string, users: string>, type: string>
# operationId: institutions_list
export def "institutions-list" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/institutions/"
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve an institution
#
# GET /institutions/{institution_id}/
# Returns: table<attributes: record<auth_url: string, description: string, logo_path: string, name: string>, id: string, links: record<self: string>, relationships: record<nodes: string, registrations: string, users: string>, type: string>
# operationId: institutions_detail
export def "institutions-detail" [
  institution_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/institutions/{institution_id}/"
    path_params: [{name: institution_id, var: institution_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    institution_id: $institution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all affiliated nodes
#
# GET /institutions/{institution_id}/nodes/
# Returns: table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, description: string, fork: bool, forked_date: string, node_license: string, preprint: bool, public: bool, registration: bool, tags: list, template_from: string, title: string>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, draft_registrations: string, files: string, forked_from: string, forks: string, identifiers: string, license: string, linked_nodes: string, logs: string, node_links: string, parent: string, preprints: string, registrations: string, root: string, template_node: string, view_only_links: string, wikis: string>, type: string>
# operationId: institutions_node_list
export def "institutions-node-list" [
  institution_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/institutions/{institution_id}/nodes/"
    path_params: [{name: institution_id, var: institution_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    institution_id: $institution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all affiliated registrations
#
# GET /institutions/{institution_id}/registrations/
# operationId: institutions_registration_list
export def "institutions-registration-list" [
  institution_id: string
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
    path: "/institutions/{institution_id}/registrations/"
    path_params: [{name: institution_id, var: institution_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    institution_id: $institution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all affiliated users
#
# GET /institutions/{institution_id}/users/
# Returns: table<attributes: record<active: bool, date_registered: string, family_name: string, full_name: string, given_name: string, locale: string, middle_names: string, suffix: string, timezone: string>, id: string, links: record<html: string, profile_image: string>, relationships: record<institutions: string, nodes: string>, type: string>
# operationId: institutions_users_list
export def "institutions-users-list" [
  institution_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/institutions/{institution_id}/users/"
    path_params: [{name: institution_id, var: institution_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    institution_id: $institution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a license
#
# GET /license/{license_id}/
# Returns: record<attributes: record<name: string, required_fields: list<string>, text: string>, id: string, links: record<self: string>, type: string>
# operationId: licenses_read
export def "licenses-read" [
  license_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/license/{license_id}/"
    path_params: [{name: license_id, var: license_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    license_id: $license_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all licenses
#
# GET /licenses/
# Returns: table<attributes: record<name: string, required_fields: list, text: string>, id: string, links: record<self: string>, type: string>
# operationId: license_list
export def "license-list" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/licenses/"
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a log
#
# GET /logs/{log_id}/
# Returns: record<attributes: record<action: string, date: string, params: record<addon: string, anonymous_link: bool, bucket: string, citation_name: string, contributors: string, data_set: string, destination: string, figshare_title: string, file: string, filename: string, folder: string, folder_name: string, forward_url: string, github_repo: string, github_user: string, identifiers: string, institution: string, kind: string, license: string, old_page: string, page: string, page_id: string, params_node: string, params_project: string, path: string, pointer: string, preprint: string, preprint_provider: string, previous_institution: string, source: string, study: string, tag: string, tags: string, target: string, template_node: string, title_new: string, title_original: string, updated_fields: string, urls: string, version: string, wiki: string>>, id: string, links: record<self: string>, relationships: record<linked_node: string, node: string, original_node: string, template_node: string, user: string>, type: string>
# operationId: logs_read
export def "logs-read" [
  log_id: string
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
    path: "/logs/{log_id}/"
    path_params: [{name: log_id, var: log_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    log_id: $log_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all nodes
#
# GET /nodes/
# Returns: table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, description: string, fork: bool, forked_date: string, node_license: string, preprint: bool, public: bool, registration: bool, tags: list, template_from: string, title: string>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, draft_registrations: string, files: string, forked_from: string, forks: string, identifiers: string, license: string, linked_nodes: string, logs: string, node_links: string, parent: string, preprints: string, registrations: string, root: string, template_node: string, view_only_links: string, wikis: string>, type: string>
# operationId: nodes_list
export def "nodes-list" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/nodes/"
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a node
#
# POST /nodes/
# operationId: nodes_create
export def "nodes-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  attributes: record # The properties of the node entity. — shape: {category: "analysis"|"communication"|"data"|"hypothesis"|"instrumentation"|"methods and measures"|"procedure"|"project"|"software"|"other", description?: string, node_license?: string, public?: bool, tags?: list<string>, template_from?: string, title: string}
  --relationships: record # URLs to other entities or entity collections that have a relationship to the node entity.
  type: string # The type identifier of the node entity (`nodes`).
]: any -> any {
  $in | http-request {
    method: post
    path: "/nodes/"
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: relationships, var: relationships}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    attributes: $attributes, relationships: $relationships, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a node
#
# DELETE /nodes/{node_id}/
# operationId: nodes_delete
export def "nodes-delete" [
  node_id: string
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
    path: "/nodes/{node_id}/"
    path_params: [{name: node_id, var: node_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a node
#
# GET /nodes/{node_id}/
# Returns: record<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list<string>, date_created: string, date_modified: string, description: string, fork: bool, forked_date: string, node_license: string, preprint: bool, public: bool, registration: bool, tags: list<string>, template_from: string, title: string>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, draft_registrations: string, files: string, forked_from: string, forks: string, identifiers: string, license: string, linked_nodes: string, logs: string, node_links: string, parent: string, preprints: string, registrations: string, root: string, template_node: string, view_only_links: string, wikis: string>, type: string>
# operationId: nodes_read
export def "nodes-read" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/nodes/{node_id}/"
    path_params: [{name: node_id, var: node_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a node
#
# PATCH /nodes/{node_id}/
# operationId: nodes_partial_update
export def "nodes-partial-update" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: patch
    path: "/nodes/{node_id}/"
    path_params: [{name: node_id, var: node_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all addons
#
# GET /nodes/{node_id}/addons/
# Returns: table<attributes: record<categories: list, description: string, name: string, url: string>, id: string, type: string>
# operationId: nodes_addons_list
export def "nodes-addons-list" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/nodes/{node_id}/addons/"
    path_params: [{name: node_id, var: node_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve an addon
#
# GET /nodes/{node_id}/addons/{provider}/
# Returns: record<attributes: record<configured: bool, enabled: bool, external_account_id: string, folder_id: string, folder_path: string, label: string, node_has_auth: bool, url: string>, id: string, links: record<self: string>, type: string>
# operationId: nodes_addon_read
export def "nodes-addon-read" [
  node_id: string
  provider: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/nodes/{node_id}/addons/{provider}/"
    path_params: [{name: node_id, var: node_id}, {name: provider, var: provider}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id, provider: $provider
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update an addon
#
# PATCH /nodes/{node_id}/addons/{provider}/
# operationId: nodes_node_addon_update
export def "nodes-node-addon-update" [
  node_id: string
  provider: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: patch
    path: "/nodes/{node_id}/addons/{provider}/"
    path_params: [{name: node_id, var: node_id}, {name: provider, var: provider}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id, provider: $provider, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all addon folders
#
# GET /nodes/{node_id}/addons/{provider}/folders/
# Returns: table<attributes: record<categories: list, description: string, name: string, url: string>, id: string, type: string>
# operationId: nodes_addons_folders_list
export def "nodes-addons-folders-list" [
  node_id: string
  provider: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/nodes/{node_id}/addons/{provider}/folders/"
    path_params: [{name: node_id, var: node_id}, {name: provider, var: provider}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id, provider: $provider
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all child nodes
#
# GET /nodes/{node_id}/children/
# Returns: table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, description: string, fork: bool, forked_date: string, node_license: string, preprint: bool, public: bool, registration: bool, tags: list, template_from: string, title: string>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, draft_registrations: string, files: string, forked_from: string, forks: string, identifiers: string, license: string, linked_nodes: string, logs: string, node_links: string, parent: string, preprints: string, registrations: string, root: string, template_node: string, view_only_links: string, wikis: string>, type: string>
# operationId: nodes_children_list
export def "nodes-children-list" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/nodes/{node_id}/children/"
    path_params: [{name: node_id, var: node_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a child node
#
# POST /nodes/{node_id}/children/
# operationId: nodes_children_create
export def "nodes-children-create" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  attributes: record # The properties of the node entity. — shape: {category: "analysis"|"communication"|"data"|"hypothesis"|"instrumentation"|"methods and measures"|"procedure"|"project"|"software"|"other", description?: string, node_license?: string, public?: bool, tags?: list<string>, template_from?: string, title: string}
  --relationships: record # URLs to other entities or entity collections that have a relationship to the node entity.
  type: string # The type identifier of the node entity (`nodes`).
]: any -> any {
  $in | http-request {
    method: post
    path: "/nodes/{node_id}/children/"
    path_params: [{name: node_id, var: node_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: relationships, var: relationships}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    node_id: $node_id, attributes: $attributes, relationships: $relationships, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve citation details
#
# GET /nodes/{node_id}/citation/
# Returns: record<attributes: record<author: string, doi: string, publisher: string, title: string>, id: string, links: record<self: string>, type: string>
# operationId: nodes_citation_list
export def "nodes-citation-list" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/nodes/{node_id}/citation/"
    path_params: [{name: node_id, var: node_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a styled citation
#
# GET /nodes/{node_id}/citation/{style_id}/
# Returns: record<attributes: record<citation: string>, id: string, type: string>
# operationId: nodes_citation_read
export def "nodes-citation-read" [
  node_id: string
  style_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/nodes/{node_id}/citation/{style_id}/"
    path_params: [{name: node_id, var: node_id}, {name: style_id, var: style_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id, style_id: $style_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all comments
#
# GET /nodes/{node_id}/comments/
# Returns: table<attributes: record<can_edit: bool, content: string, date_created: string, date_modified: string, deleted: bool, has_children: bool, has_report: bool, is_abuse: bool, is_ham: bool, modified: bool, page: string>, id: string, links: record<self: string>, relationships: record<node: string, replies: string, reports: string, target: string, user: string>, type: string>
# operationId: nodes_comments_list
export def "nodes-comments-list" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/nodes/{node_id}/comments/"
    path_params: [{name: node_id, var: node_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a comment
#
# POST /nodes/{node_id}/comments/
# operationId: nodes_comment_create
export def "nodes-comment-create" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record # The properties of the comment entity. — shape: {content?: string}
  --relationships: record # URLs to other entities or entity collections that have a relationship to the comment entity.
]: any -> any {
  $in | http-request {
    method: post
    path: "/nodes/{node_id}/comments/"
    path_params: [{name: node_id, var: node_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: relationships, var: relationships}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    node_id: $node_id, attributes: $attributes, relationships: $relationships
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all contributors
#
# GET /nodes/{node_id}/contributors/
# Returns: table<attributes: record<bibliographic: bool, index: int, permission: string, unregistered_contributor: string>, id: string, links: record<self: string>, relationships: record<node: string, user: string>, type: string>
# operationId: nodes_contributors_list
export def "nodes-contributors-list" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/nodes/{node_id}/contributors/"
    path_params: [{name: node_id, var: node_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a contributor
#
# POST /nodes/{node_id}/contributors/
# operationId: nodes_contributors_create
export def "nodes-contributors-create" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record # The properties of the contributor entity. — shape: {bibliographic?: bool, index?: int, permission?: "read"|"write"|"admin"}
  relationships: record # URLs to other entities or entity collections that have a relationship to the contributor entity. — shape: {user: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/nodes/{node_id}/contributors/"
    path_params: [{name: node_id, var: node_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: relationships, var: relationships}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    node_id: $node_id, attributes: $attributes, relationships: $relationships
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a contributor
#
# DELETE /nodes/{node_id}/contributors/{user_id}/
# operationId: nodes_contributors_delete
export def "nodes-contributors-delete" [
  node_id: string
  user_id: string
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
    path: "/nodes/{node_id}/contributors/{user_id}/"
    path_params: [{name: node_id, var: node_id}, {name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    node_id: $node_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a contributor
#
# GET /nodes/{node_id}/contributors/{user_id}/
# Returns: table<attributes: record<bibliographic: bool, index: int, permission: string, unregistered_contributor: string>, id: string, links: record<self: string>, relationships: record<node: string, user: string>, type: string>
# operationId: nodes_contributors_read
export def "nodes-contributors-read" [
  node_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/nodes/{node_id}/contributors/{user_id}/"
    path_params: [{name: node_id, var: node_id}, {name: user_id, var: user_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a contributor
#
# PATCH /nodes/{node_id}/contributors/{user_id}/
# operationId: nodes_contributors_partial_update
export def "nodes-contributors-partial-update" [
  node_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record # The properties of the contributor entity. — shape: {bibliographic?: bool, index?: int, permission?: "read"|"write"|"admin"}
  relationships: record # URLs to other entities or entity collections that have a relationship to the contributor entity. — shape: {user: string}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/nodes/{node_id}/contributors/{user_id}/"
    path_params: [{name: node_id, var: node_id}, {name: user_id, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: relationships, var: relationships}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id, user_id: $user_id, attributes: $attributes, relationships: $relationships
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all draft registrations
#
# GET /nodes/{node_id}/draft_registrations/
# Returns: table<attributes: record<category: string, current_user_permissions: list, datetime_initiated: string, datetime_updated: string, description: string, has_project: bool, node_license: record, registration_metadata: record, registration_responses: record, tags: list, title: string>, id: string, links: record<html: string>, relationships: record<branched_from: string, initiator: string, registration_schema: string>, type: string>
# operationId: nodes_draft_registrations_list
export def "nodes-draft-registrations-list" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/nodes/{node_id}/draft_registrations/"
    path_params: [{name: node_id, var: node_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a draft registration based on your current project Node.
#
# POST /nodes/{node_id}/draft_registrations/
# operationId: nodes_draft_registrations_create
export def "nodes-draft-registrations-create" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  attributes: record # The properties of the Draft Registration entity. — shape: {category?: string, description?: string, node_license?: record, registration_metadata?: record, registration_responses?: record, tags?: list<string>, title?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/nodes/{node_id}/draft_registrations/"
    path_params: [{name: node_id, var: node_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    node_id: $node_id, attributes: $attributes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a draft registration
#
# DELETE /nodes/{node_id}/draft_registrations/{draft_id}/
# operationId: nodes_draft_registrations_delete
export def "nodes-draft-registrations-delete" [
  node_id: string
  draft_id: string
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
    path: "/nodes/{node_id}/draft_registrations/{draft_id}/"
    path_params: [{name: node_id, var: node_id}, {name: draft_id, var: draft_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    node_id: $node_id, draft_id: $draft_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Draft Registration
#
# GET /nodes/{node_id}/draft_registrations/{draft_id}/
# Returns: record<attributes: record<category: string, current_user_permissions: list<string>, datetime_initiated: string, datetime_updated: string, description: string, has_project: bool, node_license: record<copyright_holders: list, year: int>, registration_metadata: record, registration_responses: record, tags: list<string>, title: string>, id: string, links: record<html: string>, relationships: record<branched_from: string, initiator: string, registration_schema: string>, type: string>
# operationId: nodes_draft_registrations_read
export def "nodes-draft-registrations-read" [
  node_id: string
  draft_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/nodes/{node_id}/draft_registrations/{draft_id}/"
    path_params: [{name: node_id, var: node_id}, {name: draft_id, var: draft_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id, draft_id: $draft_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a draft registration
#
# PATCH /nodes/{node_id}/draft_registrations/{draft_id}/
# operationId: nodes_draft_registrations_partial_update
export def "nodes-draft-registrations-partial-update" [
  node_id: string
  draft_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  attributes: record # The properties of the Draft Registration entity. — shape: {category?: string, description?: string, node_license?: record, registration_metadata?: record, registration_responses?: record, tags?: list<string>, title?: string}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/nodes/{node_id}/draft_registrations/{draft_id}/"
    path_params: [{name: node_id, var: node_id}, {name: draft_id, var: draft_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id, draft_id: $draft_id, attributes: $attributes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all storage providers
#
# GET /nodes/{node_id}/files/
# Returns: table<attributes: record<checkout: string, current_user_can_comment: bool, current_version: int, date_created: string, date_modified: string, delete_allowed: bool, extra: record, guid: string, kind: string, last_touched: string, materialized_path: string, name: string, path: string, provider: string, size: int, tags: list>, id: string, links: record<delete: string, download: string, info: string, move: string, new_folder: string, self: string, upload: string>, relationships: record<checkout: string, comments: string, node: string, versions: string>, type: string>
# operationId: nodes_providers_list
export def "nodes-providers-list" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/nodes/{node_id}/files/"
    path_params: [{name: node_id, var: node_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a storage provider
#
# GET /nodes/{node_id}/files/providers/{provider}/
# Returns: record<attributes: record<checkout: string, current_user_can_comment: bool, current_version: int, date_created: string, date_modified: string, delete_allowed: bool, extra: record, guid: string, kind: string, last_touched: string, materialized_path: string, name: string, path: string, provider: string, size: int, tags: list<string>>, id: string, links: record<delete: string, download: string, info: string, move: string, new_folder: string, self: string, upload: string>, relationships: record<checkout: string, comments: string, node: string, versions: string>, type: string>
# operationId: nodes_providers_read
export def "nodes-providers-read" [
  node_id: string
  provider: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/nodes/{node_id}/files/providers/{provider}/"
    path_params: [{name: node_id, var: node_id}, {name: provider, var: provider}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id, provider: $provider
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all node files
#
# GET /nodes/{node_id}/files/{provider}/
# Returns: table<attributes: record<checkout: string, current_user_can_comment: bool, current_version: int, date_created: string, date_modified: string, delete_allowed: bool, extra: record, guid: string, kind: string, last_touched: string, materialized_path: string, name: string, path: string, provider: string, size: int, tags: list>, id: string, links: record<delete: string, download: string, info: string, move: string, new_folder: string, self: string, upload: string>, relationships: record<checkout: string, comments: string, node: string, versions: string>, type: string>
# operationId: nodes_files_list
export def "nodes-files-list" [
  node_id: string
  provider: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/nodes/{node_id}/files/{provider}/"
    path_params: [{name: node_id, var: node_id}, {name: provider, var: provider}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id, provider: $provider
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a file
#
# GET /nodes/{node_id}/files/{provider}/{path}/
# Returns: record<attributes: record<checkout: string, current_user_can_comment: bool, current_version: int, date_created: string, date_modified: string, delete_allowed: bool, extra: record, guid: string, kind: string, last_touched: string, materialized_path: string, name: string, path: string, provider: string, size: int, tags: list<string>>, id: string, links: record<delete: string, download: string, info: string, move: string, new_folder: string, self: string, upload: string>, relationships: record<checkout: string, comments: string, node: string, versions: string>, type: string>
# operationId: nodes_files_read
export def "nodes-files-read" [
  node_id: string
  provider: string
  path: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/nodes/{node_id}/files/{provider}/{path}/"
    path_params: [{name: node_id, var: node_id}, {name: provider, var: provider}, {name: path, var: path}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id, provider: $provider, path: $path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all forks of this node
#
# GET /nodes/{node_id}/forks/
# Returns: table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, description: string, fork: bool, forked_date: string, node_license: string, preprint: bool, public: bool, registration: bool, tags: list, template_from: string, title: string>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, draft_registrations: string, files: string, forked_from: string, forks: string, identifiers: string, license: string, linked_nodes: string, logs: string, node_links: string, parent: string, preprints: string, registrations: string, root: string, template_node: string, view_only_links: string, wikis: string>, type: string>
# operationId: nodes_forks_list
export def "nodes-forks-list" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/nodes/{node_id}/forks/"
    path_params: [{name: node_id, var: node_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a fork of this node
#
# POST /nodes/{node_id}/forks/
# operationId: nodes_forks_create
export def "nodes-forks-create" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  attributes: record # The properties of the node entity. — shape: {category: "analysis"|"communication"|"data"|"hypothesis"|"instrumentation"|"methods and measures"|"procedure"|"project"|"software"|"other", description?: string, node_license?: string, public?: bool, tags?: list<string>, template_from?: string, title: string}
  --relationships: record # URLs to other entities or entity collections that have a relationship to the node entity.
  type: string # The type identifier of the node entity (`nodes`).
]: any -> any {
  $in | http-request {
    method: post
    path: "/nodes/{node_id}/forks/"
    path_params: [{name: node_id, var: node_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: relationships, var: relationships}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    node_id: $node_id, attributes: $attributes, relationships: $relationships, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all identifiers
#
# GET /nodes/{node_id}/identifiers/
# Returns: table<attributes: record<category: string, value: string>, id: string, links: record<self: string>, relationships: record<referent: string>, type: string>
# operationId: nodes_identifiers_list
export def "nodes-identifiers-list" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/nodes/{node_id}/identifiers/"
    path_params: [{name: node_id, var: node_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all institutions
#
# GET /nodes/{node_id}/institutions/
# Returns: table<attributes: record<auth_url: string, description: string, logo_path: string, name: string>, id: string, links: record<self: string>, relationships: record<nodes: string, registrations: string, users: string>, type: string>
# operationId: nodes_institutions_list
export def "nodes-institutions-list" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/nodes/{node_id}/institutions/"
    path_params: [{name: node_id, var: node_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all linked nodes
#
# GET /nodes/{node_id}/linked_nodes/
# Returns: table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, description: string, fork: bool, forked_date: string, node_license: string, preprint: bool, public: bool, registration: bool, tags: list, template_from: string, title: string>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, draft_registrations: string, files: string, forked_from: string, forks: string, identifiers: string, license: string, linked_nodes: string, logs: string, node_links: string, parent: string, preprints: string, registrations: string, root: string, template_node: string, view_only_links: string, wikis: string>, type: string>
# operationId: nodes_linked_nodes_list
export def "nodes-linked-nodes-list" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/nodes/{node_id}/linked_nodes/"
    path_params: [{name: node_id, var: node_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all logs
#
# GET /nodes/{node_id}/logs/
# Returns: table<attributes: record<action: string, date: string, params: record>, id: string, links: record<self: string>, relationships: record<linked_node: string, node: string, original_node: string, template_node: string, user: string>, type: string>
# operationId: nodes_logs_list
export def "nodes-logs-list" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/nodes/{node_id}/logs/"
    path_params: [{name: node_id, var: node_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all preprints
#
# GET /nodes/{node_id}/preprints/
# Returns: table<attributes: record<date_created: string, date_modified: string, date_published: string, doi: string, is_preprint_orphan: bool, license_record: string, subjects: list>, id: string, links: record<doi: string, html: string, preprint_doi: string, self: string>, relationships: record<bibliographic_contributors: string, citation: string, identifiers: string, license: string, node: string, primary_file: string, provider: string>, type: string>
# operationId: nodes_preprints_list
export def "nodes-preprints-list" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/nodes/{node_id}/preprints/"
    path_params: [{name: node_id, var: node_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all registrations
#
# GET /nodes/{node_id}/registrations/
# Returns: table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, date_registered: string, date_withdrawn: string, description: string, embargo_end_date: string, fork: bool, node_license: string, pending_embargo_approval: bool, pending_registration_approval: bool, pending_withdrawal: bool, preprint: bool, public: bool, registered_meta: string, registration: bool, registration_supplement: string, tags: list, template_from: string, title: string, withdrawal_justification: string, withdrawn: bool>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, files: string, forks: string, identifiers: string, linked_nodes: string, logs: string, node_links: string, parent: string, registered_by: string, registered_from: string, registration_schema: string, root: string, view_only_links: string, wikis: string>, type: string>
# operationId: nodes_registrations_list
export def "nodes-registrations-list" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/nodes/{node_id}/registrations/"
    path_params: [{name: node_id, var: node_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all view only links
#
# GET /nodes/{node_id}/view_only_links/
# Returns: table<attributes: record<anonymous: bool, date_created: string, key: string, name: string>, id: string, relationships: record<creator: string, nodes: string>, type: string>
# operationId: nodes_view_only_links_list
export def "nodes-view-only-links-list" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/nodes/{node_id}/view_only_links/"
    path_params: [{name: node_id, var: node_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a view only link
#
# GET /nodes/{node_id}/view_only_links/{link_id}/
# Returns: record<attributes: record<anonymous: bool, date_created: string, key: string, name: string>, id: string, relationships: record<creator: string, nodes: string>, type: string>
# operationId: nodes_view_only_links_read
export def "nodes-view-only-links-read" [
  node_id: string
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/nodes/{node_id}/view_only_links/{link_id}/"
    path_params: [{name: node_id, var: node_id}, {name: link_id, var: link_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id, link_id: $link_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all wikis
#
# GET /nodes/{node_id}/wikis/
# Returns: table<attributes: record<content_type: string, current_user_can_comment: string, date_modified: string, extra: string, kind: string, materialized_path: string, name: string, path: string, size: string>, id: string, links: record<download: string, info: string, self: string>, relationships: record<comments: string, node: string, user: string>, type: string>
# operationId: nodes_wikis_list
export def "nodes-wikis-list" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/nodes/{node_id}/wikis/"
    path_params: [{name: node_id, var: node_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all preprint providers
#
# GET /preprint_providers/
# Returns: record<attributes: record<advisory_board: string, banner_path: string, description: string, domain: string, domain_redirect_enabled: bool, email_contact: string, email_support: string, example: string, logo_path: string, name: string, social_facebook: string, social_instagram: string, subjects_acceptable: string>, id: string, links: record<external_url: string, preprints: string, self: string>, relationships: record<licenses_acceptable: string, preprints: string, taxonomies: string>, type: string>
# operationId: preprint_provider_list
export def "preprint-provider-list" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/preprint_providers/"
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a preprint provider
#
# GET /preprint_providers/{preprint_provider_id}/
# Returns: record<attributes: record<advisory_board: string, banner_path: string, description: string, domain: string, domain_redirect_enabled: bool, email_contact: string, email_support: string, example: string, logo_path: string, name: string, social_facebook: string, social_instagram: string, subjects_acceptable: string>, id: string, links: record<external_url: string, preprints: string, self: string>, relationships: record<licenses_acceptable: string, preprints: string, taxonomies: string>, type: string>
# operationId: preprint_provider_detail
export def "preprint-provider-detail" [
  preprint_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/preprint_providers/{preprint_provider_id}/"
    path_params: [{name: preprint_provider_id, var: preprint_provider_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    preprint_provider_id: $preprint_provider_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all licenses
#
# GET /preprint_providers/{preprint_provider_id}/licenses/
# Returns: record<attributes: record<name: string, required_fields: list<string>, text: string>, id: string, links: record<self: string>, type: string>
# operationId: preprint_provider_licenses_list
export def "preprint-provider-licenses-list" [
  preprint_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/preprint_providers/{preprint_provider_id}/licenses/"
    path_params: [{name: preprint_provider_id, var: preprint_provider_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    preprint_provider_id: $preprint_provider_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all preprints
#
# GET /preprint_providers/{preprint_provider_id}/preprints/
# Returns: table<attributes: record<date_created: string, date_modified: string, date_published: string, doi: string, is_preprint_orphan: bool, license_record: string, subjects: list>, id: string, links: record<doi: string, html: string, preprint_doi: string, self: string>, relationships: record<bibliographic_contributors: string, citation: string, identifiers: string, license: string, node: string, primary_file: string, provider: string>, type: string>
# operationId: preprint_providers_preprints_list
export def "preprint-providers-preprints-list" [
  preprint_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/preprint_providers/{preprint_provider_id}/preprints/"
    path_params: [{name: preprint_provider_id, var: preprint_provider_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    preprint_provider_id: $preprint_provider_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all taxonomies
#
# GET /preprint_providers/{preprint_provider_id}/taxonomies/
# Returns: record<attributes: record<child_count: int, parents: list<string>, text: string>, id: string, links: record<parents: list<string>, self: string>, type: string>
# operationId: preprint_provider_taxonomies_list
export def "preprint-provider-taxonomies-list" [
  preprint_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/preprint_providers/{preprint_provider_id}/taxonomies/"
    path_params: [{name: preprint_provider_id, var: preprint_provider_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    preprint_provider_id: $preprint_provider_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all preprints
#
# GET /preprints/
# Returns: table<attributes: record<date_created: string, date_modified: string, date_published: string, doi: string, is_preprint_orphan: bool, license_record: string, subjects: list>, id: string, links: record<doi: string, html: string, preprint_doi: string, self: string>, relationships: record<bibliographic_contributors: string, citation: string, identifiers: string, license: string, node: string, primary_file: string, provider: string>, type: string>
# operationId: preprints_list
export def "preprints-list" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/preprints/"
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a preprint
#
# POST /preprints/
# operationId: preprints_create
export def "preprints-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record # The properties of the preprint entity. — shape: {doi?: string, license_record?: string, subjects?: list<string>}
  relationships: record # URLs to other entities or entity collections that have a relationship to the preprint entity. — shape: {bibliographic_contributors?: string, license?: string, node: string, primary_file: string, provider: string}
  type: string # The type identifier of the preprint entity (`preprints`).
]: any -> any {
  $in | http-request {
    method: post
    path: "/preprints/"
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: relationships, var: relationships}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    attributes: $attributes, relationships: $relationships, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a preprint
#
# GET /preprints/{preprint_id}/
# Returns: record<attributes: record<date_created: string, date_modified: string, date_published: string, doi: string, is_preprint_orphan: bool, license_record: string, subjects: list<string>>, id: string, links: record<doi: string, html: string, preprint_doi: string, self: string>, relationships: record<bibliographic_contributors: string, citation: string, identifiers: string, license: string, node: string, primary_file: string, provider: string>, type: string>
# operationId: preprints_read
export def "preprints-read" [
  preprint_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/preprints/{preprint_id}/"
    path_params: [{name: preprint_id, var: preprint_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    preprint_id: $preprint_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a preprint
#
# PATCH /preprints/{preprint_id}/
# operationId: preprints_partial_update
export def "preprints-partial-update" [
  preprint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: patch
    path: "/preprints/{preprint_id}/"
    path_params: [{name: preprint_id, var: preprint_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    preprint_id: $preprint_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all Bibliographic Contributors
#
# GET /preprints/{preprint_id}/bibliographic_contributors/
# Returns: table<attributes: record<bibliographic: bool, index: int, permission: string, unregistered_contributor: string>, id: string, links: record<self: string>, relationships: record<node: string, user: string>, type: string>
# operationId: preprints_bibliographic_contributors_list
export def "preprints-bibliographic-contributors-list" [
  preprint_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/preprints/{preprint_id}/bibliographic_contributors/"
    path_params: [{name: preprint_id, var: preprint_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    preprint_id: $preprint_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve citation details
#
# GET /preprints/{preprint_id}/citation/
# Returns: record<attributes: record<author: string, doi: string, publisher: string, title: string>, id: string, links: record<self: string>, type: string>
# operationId: preprints_citation_list
export def "preprints-citation-list" [
  preprint_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/preprints/{preprint_id}/citation/"
    path_params: [{name: preprint_id, var: preprint_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    preprint_id: $preprint_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a styled citation
#
# GET /preprints/{preprint_id}/citation/{style_id}/
# Returns: record<attributes: record<citation: string>, id: string, type: string>
# operationId: preprints_citation_read
export def "preprints-citation-read" [
  preprint_id: string
  style_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/preprints/{preprint_id}/citation/{style_id}/"
    path_params: [{name: preprint_id, var: preprint_id}, {name: style_id, var: style_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    preprint_id: $preprint_id, style_id: $style_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all Contributors for a Preprint
#
# GET /preprints/{preprint_id}/contributors/
# Returns: table<attributes: record<bibliographic: bool, index: int, permission: string, unregistered_contributor: string>, id: string, links: record<self: string>, relationships: record<node: string, user: string>, type: string>
# operationId: preprints_contributors_list
export def "preprints-contributors-list" [
  preprint_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/preprints/{preprint_id}/contributors/"
    path_params: [{name: preprint_id, var: preprint_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    preprint_id: $preprint_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a Contributor
#
# POST /preprints/{preprint_id}/contributors/
# operationId: preprints_contributors_create
export def "preprints-contributors-create" [
  preprint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record # The properties of the contributor entity. — shape: {bibliographic?: bool, index?: int, permission?: "read"|"write"|"admin"}
]: any -> any {
  $in | http-request {
    method: post
    path: "/preprints/{preprint_id}/contributors/"
    path_params: [{name: preprint_id, var: preprint_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    preprint_id: $preprint_id, attributes: $attributes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a contributor
#
# GET /preprints/{preprint_id}/contributors/{user_id}/
# operationId: preprints_contributor_read
export def "preprints-contributor-read" [
  preprint_id: string
  user_id: string
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
    path: "/preprints/{preprint_id}/contributors/{user_id}/"
    path_params: [{name: preprint_id, var: preprint_id}, {name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    preprint_id: $preprint_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all registrations
#
# GET /registrations/
# Returns: table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, date_registered: string, date_withdrawn: string, description: string, embargo_end_date: string, fork: bool, node_license: string, pending_embargo_approval: bool, pending_registration_approval: bool, pending_withdrawal: bool, preprint: bool, public: bool, registered_meta: string, registration: bool, registration_supplement: string, tags: list, template_from: string, title: string, withdrawal_justification: string, withdrawn: bool>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, files: string, forks: string, identifiers: string, linked_nodes: string, logs: string, node_links: string, parent: string, registered_by: string, registered_from: string, registration_schema: string, root: string, view_only_links: string, wikis: string>, type: string>
# operationId: registrations_list
export def "registrations-list" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/registrations/"
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a registration
#
# GET /registrations/{registration_id}/
# Returns: record<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list<string>, date_created: string, date_modified: string, date_registered: string, date_withdrawn: string, description: string, embargo_end_date: string, fork: bool, node_license: string, pending_embargo_approval: bool, pending_registration_approval: bool, pending_withdrawal: bool, preprint: bool, public: bool, registered_meta: string, registration: bool, registration_supplement: string, tags: list<string>, template_from: string, title: string, withdrawal_justification: string, withdrawn: bool>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, files: string, forks: string, identifiers: string, linked_nodes: string, logs: string, node_links: string, parent: string, registered_by: string, registered_from: string, registration_schema: string, root: string, view_only_links: string, wikis: string>, type: string>
# operationId: registrations_read
export def "registrations-read" [
  registration_id: string
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
    path: "/registrations/{registration_id}/"
    path_params: [{name: registration_id, var: registration_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    registration_id: $registration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a registration
#
# PATCH /registrations/{registration_id}/
# operationId: registrations_partial_update
export def "registrations-partial-update" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: patch
    path: "/registrations/{registration_id}/"
    path_params: [{name: registration_id, var: registration_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    registration_id: $registration_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all child registrations
#
# GET /registrations/{registration_id}/children/
# Returns: table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, date_registered: string, date_withdrawn: string, description: string, embargo_end_date: string, fork: bool, node_license: string, pending_embargo_approval: bool, pending_registration_approval: bool, pending_withdrawal: bool, preprint: bool, public: bool, registered_meta: string, registration: bool, registration_supplement: string, tags: list, template_from: string, title: string, withdrawal_justification: string, withdrawn: bool>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, files: string, forks: string, identifiers: string, linked_nodes: string, logs: string, node_links: string, parent: string, registered_by: string, registered_from: string, registration_schema: string, root: string, view_only_links: string, wikis: string>, type: string>
# operationId: registrations_children_list
export def "registrations-children-list" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/registrations/{registration_id}/children/"
    path_params: [{name: registration_id, var: registration_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    registration_id: $registration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all citation styles
#
# GET /registrations/{registration_id}/citations/
# Returns: table<attributes: record<date_parsed: string, short_title: string, summary: string, title: string>, id: string, links: record, type: string>
# operationId: registrations_citations_list
export def "registrations-citations-list" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/registrations/{registration_id}/citations/"
    path_params: [{name: registration_id, var: registration_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    registration_id: $registration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a citation
#
# GET /registrations/{registration_id}/citations/{citation_id}/
# Returns: record<attributes: record<author: string, doi: string, publisher: string, title: string>, id: string, links: record<self: string>, type: string>
# operationId: registrations_citation_read
export def "registrations-citation-read" [
  registration_id: string
  citation_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/registrations/{registration_id}/citations/{citation_id}/"
    path_params: [{name: registration_id, var: registration_id}, {name: citation_id, var: citation_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    registration_id: $registration_id, citation_id: $citation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all comments
#
# GET /registrations/{registration_id}/comments/
# Returns: table<attributes: record<can_edit: bool, content: string, date_created: string, date_modified: string, deleted: bool, has_children: bool, has_report: bool, is_abuse: bool, is_ham: bool, modified: bool, page: string>, id: string, links: record<self: string>, relationships: record<node: string, replies: string, reports: string, target: string, user: string>, type: string>
# operationId: registrations_comments_list
export def "registrations-comments-list" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/registrations/{registration_id}/comments/"
    path_params: [{name: registration_id, var: registration_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    registration_id: $registration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all contributors
#
# GET /registrations/{registration_id}/contributors/
# Returns: table<attributes: record<bibliographic: bool, index: int, permission: string, unregistered_contributor: string>, id: string, links: record<self: string>, relationships: record<node: string, user: string>, type: string>
# operationId: registrations_contributors_list
export def "registrations-contributors-list" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/registrations/{registration_id}/contributors/"
    path_params: [{name: registration_id, var: registration_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    registration_id: $registration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a contributor
#
# GET /registrations/{registration_id}/contributors/{user_id}/
# Returns: table<attributes: record<bibliographic: bool, index: int, permission: string, unregistered_contributor: string>, id: string, links: record<self: string>, relationships: record<node: string, user: string>, type: string>
# operationId: registrations_contributors_read
export def "registrations-contributors-read" [
  registration_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/registrations/{registration_id}/contributors/{user_id}/"
    path_params: [{name: registration_id, var: registration_id}, {name: user_id, var: user_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    registration_id: $registration_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all storage providers
#
# GET /registrations/{registration_id}/files/
# Returns: table<attributes: record<checkout: string, current_user_can_comment: bool, current_version: int, date_created: string, date_modified: string, delete_allowed: bool, extra: record, guid: string, kind: string, last_touched: string, materialized_path: string, name: string, path: string, provider: string, size: int, tags: list>, id: string, links: record<delete: string, download: string, info: string, move: string, new_folder: string, self: string, upload: string>, relationships: record<checkout: string, comments: string, node: string, versions: string>, type: string>
# operationId: registrations_providers_list
export def "registrations-providers-list" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/registrations/{registration_id}/files/"
    path_params: [{name: registration_id, var: registration_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    registration_id: $registration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all files
#
# GET /registrations/{registration_id}/files/{provider}/
# Returns: table<attributes: record<checkout: string, current_user_can_comment: bool, current_version: int, date_created: string, date_modified: string, delete_allowed: bool, extra: record, guid: string, kind: string, last_touched: string, materialized_path: string, name: string, path: string, provider: string, size: int, tags: list>, id: string, links: record<delete: string, download: string, info: string, move: string, new_folder: string, self: string, upload: string>, relationships: record<checkout: string, comments: string, node: string, versions: string>, type: string>
# operationId: registrations_files_list
export def "registrations-files-list" [
  registration_id: string
  provider: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/registrations/{registration_id}/files/{provider}/"
    path_params: [{name: registration_id, var: registration_id}, {name: provider, var: provider}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    registration_id: $registration_id, provider: $provider
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a file
#
# GET /registrations/{registration_id}/files/{provider}/{path}/
# Returns: record<attributes: record<checkout: string, current_user_can_comment: bool, current_version: int, date_created: string, date_modified: string, delete_allowed: bool, extra: record, guid: string, kind: string, last_touched: string, materialized_path: string, name: string, path: string, provider: string, size: int, tags: list<string>>, id: string, links: record<delete: string, download: string, info: string, move: string, new_folder: string, self: string, upload: string>, relationships: record<checkout: string, comments: string, node: string, versions: string>, type: string>
# operationId: registrations_files_read
export def "registrations-files-read" [
  registration_id: string
  provider: string
  path: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/registrations/{registration_id}/files/{provider}/{path}/"
    path_params: [{name: registration_id, var: registration_id}, {name: provider, var: provider}, {name: path, var: path}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    registration_id: $registration_id, provider: $provider, path: $path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all forks
#
# GET /registrations/{registration_id}/forks/
# Returns: table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, date_registered: string, date_withdrawn: string, description: string, embargo_end_date: string, fork: bool, node_license: string, pending_embargo_approval: bool, pending_registration_approval: bool, pending_withdrawal: bool, preprint: bool, public: bool, registered_meta: string, registration: bool, registration_supplement: string, tags: list, template_from: string, title: string, withdrawal_justification: string, withdrawn: bool>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, files: string, forks: string, identifiers: string, linked_nodes: string, logs: string, node_links: string, parent: string, registered_by: string, registered_from: string, registration_schema: string, root: string, view_only_links: string, wikis: string>, type: string>
# operationId: registrations_forks_list
export def "registrations-forks-list" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/registrations/{registration_id}/forks/"
    path_params: [{name: registration_id, var: registration_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    registration_id: $registration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a fork
#
# POST /registrations/{registration_id}/forks/
# operationId: registrations_forks_create
export def "registrations-forks-create" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/registrations/{registration_id}/forks/"
    path_params: [{name: registration_id, var: registration_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    registration_id: $registration_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all identifiers
#
# GET /registrations/{registration_id}/identifiers/
# Returns: table<attributes: record<category: string, value: string>, id: string, links: record<self: string>, relationships: record<referent: string>, type: string>
# operationId: registrations_identifiers_list
export def "registrations-identifiers-list" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/registrations/{registration_id}/identifiers/"
    path_params: [{name: registration_id, var: registration_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    registration_id: $registration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all institutions
#
# GET /registrations/{registration_id}/institutions/
# Returns: table<attributes: record<auth_url: string, description: string, logo_path: string, name: string>, id: string, links: record<self: string>, relationships: record<nodes: string, registrations: string, users: string>, type: string>
# operationId: registrations_institutions_list
export def "registrations-institutions-list" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/registrations/{registration_id}/institutions/"
    path_params: [{name: registration_id, var: registration_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    registration_id: $registration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all linked nodes
#
# GET /registrations/{registration_id}/linked_nodes/
# Returns: table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, description: string, fork: bool, forked_date: string, node_license: string, preprint: bool, public: bool, registration: bool, tags: list, template_from: string, title: string>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, draft_registrations: string, files: string, forked_from: string, forks: string, identifiers: string, license: string, linked_nodes: string, logs: string, node_links: string, parent: string, preprints: string, registrations: string, root: string, template_node: string, view_only_links: string, wikis: string>, type: string>
# operationId: registrations_linked_nodes_list
export def "registrations-linked-nodes-list" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/registrations/{registration_id}/linked_nodes/"
    path_params: [{name: registration_id, var: registration_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    registration_id: $registration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all logs
#
# GET /registrations/{registration_id}/logs/
# Returns: table<attributes: record<action: string, date: string, params: record>, id: string, links: record<self: string>, relationships: record<linked_node: string, node: string, original_node: string, template_node: string, user: string>, type: string>
# operationId: registrations_logs_list
export def "registrations-logs-list" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/registrations/{registration_id}/logs/"
    path_params: [{name: registration_id, var: registration_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    registration_id: $registration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all view only links
#
# GET /registrations/{registration_id}/view_only_links/
# Returns: table<attributes: record<anonymous: bool, date_created: string, key: string, name: string>, id: string, relationships: record<creator: string, nodes: string>, type: string>
# operationId: registrations_view_only_links_list
export def "registrations-view-only-links-list" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/registrations/{registration_id}/view_only_links/"
    path_params: [{name: registration_id, var: registration_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    registration_id: $registration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a view only link
#
# GET /registrations/{registration_id}/view_only_links/{link_id}/
# Returns: record<attributes: record<anonymous: bool, date_created: string, key: string, name: string>, id: string, relationships: record<creator: string, nodes: string>, type: string>
# operationId: registrations_view_only_links_read
export def "registrations-view-only-links-read" [
  registration_id: string
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/registrations/{registration_id}/view_only_links/{link_id}/"
    path_params: [{name: registration_id, var: registration_id}, {name: link_id, var: link_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    registration_id: $registration_id, link_id: $link_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all wikis
#
# GET /registrations/{registration_id}/wikis/
# Returns: table<attributes: record<content_type: string, current_user_can_comment: string, date_modified: string, extra: string, kind: string, materialized_path: string, name: string, path: string, size: string>, id: string, links: record<download: string, info: string, self: string>, relationships: record<comments: string, node: string, user: string>, type: string>
# operationId: registrations_wikis_list
export def "registrations-wikis-list" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/registrations/{registration_id}/wikis/"
    path_params: [{name: registration_id, var: registration_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    registration_id: $registration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all Schema Responses
#
# GET /schema_responses/
# Returns: record<attributes: record<date_created: int, date_modified: int, date_submitted: int, is_original_response: bool, is_pending_current_user_approval: bool, reviews_state: string, revision_justification: string, revision_responses: record, updated_response_keys: list<any>>, id: string, links: record<self: string>, relationships: record<actions: string, initiated_by: string, registration: string, registration_schema: string>, type: string>
# operationId: schema_responses_list
export def "schema-responses-list" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/schema_responses/"
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new Schema Response
#
# POST /schema_responses/
# Returns: record<attributes: record<date_created: int, date_modified: int, date_submitted: int, is_original_response: bool, is_pending_current_user_approval: bool, reviews_state: string, revision_justification: string, revision_responses: record, updated_response_keys: list<any>>, id: string, links: record<self: string>, relationships: record<actions: string, initiated_by: string, registration: string, registration_schema: string>, type: string>
# operationId: schema_response_ppost
export def "schema-response-ppost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  attributes: record # The properties of the Schema Response. — shape: {date_created?: int, date_modified?: int, date_submitted?: int, is_original_response?: bool, is_pending_current_user_approval?: bool, reviews_state?: "initial"|"in_progress"|"approved"|"pending_moderation", revision_justification?: string, revision_responses?: record}
  --links: record # URLs to alternative representations of the Schema Response entity. — shape: {self?: string}
  --relationships: record # Links to other entities or entity collections that have a relationship to the file entity. — shape: {actions?: string, initiated_by?: string, registration?: string, registration_schema?: string}
  type: string # The type identifier of the Schema Response (`schema-response`).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/schema_responses/"
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: links, var: links}, {name: relationships, var: relationships}, {name: type, var: type}]}
    accept: ["*/*", "application/json"]
    ok: [201]
    auth: bearer
  } {
    attributes: $attributes, links: $links, relationships: $relationships, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a Incomplete Schema Response
#
# DELETE /schema_responses/{schema_response_id}
# operationId: schema_response_delete
export def "schema-response-delete" [
  schema_response_id: string
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
    path: "/schema_responses/{schema_response_id}"
    path_params: [{name: schema_response_id, var: schema_response_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    schema_response_id: $schema_response_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Schema Response
#
# GET /schema_responses/{schema_response_id}
# Returns: record<attributes: record<date_created: int, date_modified: int, date_submitted: int, is_original_response: bool, is_pending_current_user_approval: bool, reviews_state: string, revision_justification: string, revision_responses: record, updated_response_keys: list<any>>, id: string, links: record<self: string>, relationships: record<actions: string, initiated_by: string, registration: string, registration_schema: string>, type: string>
# operationId: schema_responses_read
export def "schema-responses-read" [
  schema_response_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/schema_responses/{schema_response_id}"
    path_params: [{name: schema_response_id, var: schema_response_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    schema_response_id: $schema_response_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a Registration's Schema Response
#
# PATCH /schema_responses/{schema_response_id}
# Returns: record<attributes: record<date_created: int, date_modified: int, date_submitted: int, is_original_response: bool, is_pending_current_user_approval: bool, reviews_state: string, revision_justification: string, revision_responses: record, updated_response_keys: list<any>>, id: string, links: record<self: string>, relationships: record<actions: string, initiated_by: string, registration: string, registration_schema: string>, type: string>
# operationId: schema_response_patch
export def "schema-response-patch" [
  schema_response_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  attributes: record # The properties of the Schema Response. — shape: {date_created?: int, date_modified?: int, date_submitted?: int, is_original_response?: bool, is_pending_current_user_approval?: bool, reviews_state?: "initial"|"in_progress"|"approved"|"pending_moderation", revision_justification?: string, revision_responses?: record}
  --links: record # URLs to alternative representations of the Schema Response entity. — shape: {self?: string}
  --relationships: record # Links to other entities or entity collections that have a relationship to the file entity. — shape: {actions?: string, initiated_by?: string, registration?: string, registration_schema?: string}
  type: string # The type identifier of the Schema Response (`schema-response`).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/schema_responses/{schema_response_id}"
    path_params: [{name: schema_response_id, var: schema_response_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: links, var: links}, {name: relationships, var: relationships}, {name: type, var: type}]}
    accept: ["*/*", "application/json"]
    ok: [201]
    auth: bearer
  } {
    schema_response_id: $schema_response_id, attributes: $attributes, links: $links, relationships: $relationships, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a list of Schema Response Actions for a Schema Response
#
# GET /schema_responses/{schema_response_id}/actions/
# Returns: record<attributes: record<auto: bool, comment: string, date_created: string, from_state: string, to_state: string, trigger: string, visible: bool>, id: string, links: record<self: string>, relationships: record<creator: string, target: string>, type: string>
# operationId: schema_response_action_read
export def "schema-response-action-read" [
  schema_response_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/schema_responses/{schema_response_id}/actions/"
    path_params: [{name: schema_response_id, var: schema_response_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    schema_response_id: $schema_response_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new Schema Response Action
#
# POST /schema_responses/{schema_response_id}/actions/
export def "post-schema-responses-schema-response-id-actions" [
  schema_response_id: string
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
    path: "/schema_responses/{schema_response_id}/actions/"
    path_params: [{name: schema_response_id, var: schema_response_id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    schema_response_id: $schema_response_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# A Schema Response Action from a Schema Response
#
# GET /schema_responses/{schema_response_id}/actions/{schema_response_action_id}
# Returns: record<attributes: record<auto: bool, comment: string, date_created: string, from_state: string, to_state: string, trigger: string, visible: bool>, id: string, links: record<self: string>, relationships: record<creator: string, target: string>, type: string>
export def "get-schema-responses-schema-response-id-actions-schema-response-action-id" [
  schema_response_id: string
  schema_response_action_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/schema_responses/{schema_response_id}/actions/{schema_response_action_id}"
    path_params: [{name: schema_response_id, var: schema_response_id}, {name: schema_response_action_id, var: schema_response_action_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    schema_response_id: $schema_response_id, schema_response_action_id: $schema_response_action_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a list of Registration Schema Blocks for a Schema Response
#
# GET /schema_responses/{schema_response_id}/schema_blocks/
# Returns: record<attributes: record<block_type: string, display_text: string, example_text: string, index: int, registration_response_key: string, required: bool, schema_block_group_key: string>, id: string, links: record<self: string>, relationships: record<schema: string>, type: string>
# operationId: schema_response_blocks_read
export def "schema-response-blocks-read" [
  schema_response_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/schema_responses/{schema_response_id}/schema_blocks/"
    path_params: [{name: schema_response_id, var: schema_response_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    schema_response_id: $schema_response_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a Registration Schema Block
#
# GET /schema_responses/{schema_response_id}/schema_blocks/{schema_response_block_id}
# Returns: record<attributes: record<block_type: string, display_text: string, example_text: string, index: int, registration_response_key: string, required: bool, schema_block_group_key: string>, id: string, links: record<self: string>, relationships: record<schema: string>, type: string>
export def "get-schema-responses-schema-response-id-schema-blocks-schema-response-block-id" [
  schema_response_id: string
  schema_response_block_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/schema_responses/{schema_response_id}/schema_blocks/{schema_response_block_id}"
    path_params: [{name: schema_response_id, var: schema_response_id}, {name: schema_response_block_id, var: schema_response_block_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    schema_response_id: $schema_response_id, schema_response_block_id: $schema_response_block_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a list of Registration Schemas
#
# GET /schemas/registrations/
# Returns: record<attributes: record<active: bool, name: string, schema: record, schema_version: int>, id: string, links: record<self: string>, relationships: record<schema_blocks: string>, type: string>
# operationId: registration_schemas_list
export def "registration-schemas-list" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/schemas/registrations/"
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a Registration Schema
#
# GET /schemas/registrations/{registration_schema_id}
# Returns: record<attributes: record<active: bool, name: string, schema: record, schema_version: int>, id: string, links: record<self: string>, relationships: record<schema_blocks: string>, type: string>
# operationId: registration_schema_read
export def "registration-schema-read" [
  registration_schema_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/schemas/registrations/{registration_schema_id}"
    path_params: [{name: registration_schema_id, var: registration_schema_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    registration_schema_id: $registration_schema_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all taxonomies
#
# GET /taxonomies/
# Returns: table<attributes: record<child_count: int, parents: list, text: string>, id: string, links: record<parents: list, self: string>, type: string>
# operationId: taxonomies_list
export def "taxonomies-list" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/taxonomies/"
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a taxonomy
#
# GET /taxonomies/{taxonomy_id}/
# Returns: record<attributes: record<child_count: int, parents: list<string>, text: string>, id: string, links: record<parents: list<string>, self: string>, type: string>
# operationId: taxonomies_read
export def "taxonomies-read" [
  taxonomy_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/taxonomies/{taxonomy_id}/"
    path_params: [{name: taxonomy_id, var: taxonomy_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    taxonomy_id: $taxonomy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all users
#
# GET /users/
# Returns: table<attributes: record<active: bool, date_registered: string, family_name: string, full_name: string, given_name: string, locale: string, middle_names: string, suffix: string, timezone: string>, id: string, links: record<html: string, profile_image: string>, relationships: record<institutions: string, nodes: string>, type: string>
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/"
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a user
#
# GET /users/{user_id}/
# Returns: record<attributes: record<active: bool, date_registered: string, family_name: string, full_name: string, given_name: string, locale: string, middle_names: string, suffix: string, timezone: string>, id: string, links: record<html: string, profile_image: string>, relationships: record<institutions: string, nodes: string>, type: string>
# operationId: users_read
export def "users-read" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/users/{user_id}/"
    path_params: [{name: user_id, var: user_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a user
#
# PATCH /users/{user_id}/
# operationId: users_partial_update
export def "users-partial-update" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  attributes: record # The properties of the user entity. — shape: {family_name?: string, full_name: string, given_name?: string, locale?: string, middle_names?: string, suffix?: string, timezone?: string}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/users/{user_id}/"
    path_params: [{name: user_id, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, attributes: $attributes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all user addons
#
# GET /users/{user_id}/addons/
# Returns: table<attributes: record<user_has_auth: bool>, id: string, links: record<accounts: record, self: string>, type: string>
# operationId: users_addons_list
export def "users-addons-list" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/users/{user_id}/addons/"
    path_params: [{name: user_id, var: user_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a user addon
#
# GET /users/{user_id}/addons/{provider}/
# Returns: record<attributes: record<user_has_auth: bool>, id: string, links: record<accounts: record, self: string>, type: string>
# operationId: users_addons_read
export def "users-addons-read" [
  user_id: string
  provider: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/users/{user_id}/addons/{provider}/"
    path_params: [{name: user_id, var: user_id}, {name: provider, var: provider}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, provider: $provider
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all addon accounts
#
# GET /users/{user_id}/addons/{provider}/accounts/
# Returns: table<attributes: record<display_name: string, profile_url: string, provider: string>, id: string, links: record<self: string>, type: string>
# operationId: Users_addon_accounts_list
export def "users-addon-accounts-list" [
  user_id: string
  provider: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/users/{user_id}/addons/{provider}/accounts/"
    path_params: [{name: user_id, var: user_id}, {name: provider, var: provider}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, provider: $provider
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve an addon account
#
# GET /users/{user_id}/addons/{provider}/accounts/{account_id}/
# Returns: record<attributes: record<display_name: string, profile_url: string, provider: string>, id: string, links: record<self: string>, type: string>
# operationId: Users_addon_accounts_read
export def "users-addon-accounts-read" [
  user_id: string
  provider: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/users/{user_id}/addons/{provider}/accounts/{account_id}/"
    path_params: [{name: user_id, var: user_id}, {name: provider, var: provider}, {name: account_id, var: account_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, provider: $provider, account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all institutions
#
# GET /users/{user_id}/institutions/
# Returns: table<attributes: record<auth_url: string, description: string, logo_path: string, name: string>, id: string, links: record<self: string>, relationships: record<nodes: string, registrations: string, users: string>, type: string>
# operationId: users_institutions_list
export def "users-institutions-list" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/users/{user_id}/institutions/"
    path_params: [{name: user_id, var: user_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all nodes
#
# GET /users/{user_id}/nodes/
# Returns: table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, description: string, fork: bool, forked_date: string, node_license: string, preprint: bool, public: bool, registration: bool, tags: list, template_from: string, title: string>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, draft_registrations: string, files: string, forked_from: string, forks: string, identifiers: string, license: string, linked_nodes: string, logs: string, node_links: string, parent: string, preprints: string, registrations: string, root: string, template_node: string, view_only_links: string, wikis: string>, type: string>
# operationId: users_nodes_list
export def "users-nodes-list" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/users/{user_id}/nodes/"
    path_params: [{name: user_id, var: user_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all preprints
#
# GET /users/{user_id}/preprints/
# Returns: table<attributes: record<date_created: string, date_modified: string, date_published: string, doi: string, is_preprint_orphan: bool, license_record: string, subjects: list>, id: string, links: record<doi: string, html: string, preprint_doi: string, self: string>, relationships: record<bibliographic_contributors: string, citation: string, identifiers: string, license: string, node: string, primary_file: string, provider: string>, type: string>
# operationId: users_preprints_list
export def "users-preprints-list" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/users/{user_id}/preprints/"
    path_params: [{name: user_id, var: user_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all registrations
#
# GET /users/{user_id}/registrations/
# operationId: users_registrations_list
export def "users-registrations-list" [
  user_id: string
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
    path: "/users/{user_id}/registrations/"
    path_params: [{name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a view only link
#
# GET /view_only_links/{link_id}/
# Returns: record<attributes: record<anonymous: bool, date_created: string, key: string, name: string>, id: string, relationships: record<creator: string, nodes: string>, type: string>
# operationId: view_only_links_read
export def "view-only-links-read" [
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/view_only_links/{link_id}/"
    path_params: [{name: link_id, var: link_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    link_id: $link_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all nodes
#
# GET /view_only_links/{link_id}/nodes/
# Returns: table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, description: string, fork: bool, forked_date: string, node_license: string, preprint: bool, public: bool, registration: bool, tags: list, template_from: string, title: string>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, draft_registrations: string, files: string, forked_from: string, forks: string, identifiers: string, license: string, linked_nodes: string, logs: string, node_links: string, parent: string, preprints: string, registrations: string, root: string, template_node: string, view_only_links: string, wikis: string>, type: string>
# operationId: view_only_links_node_list
export def "view-only-links-node-list" [
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/view_only_links/{link_id}/nodes/"
    path_params: [{name: link_id, var: link_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    link_id: $link_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a Wiki
#
# GET /wikis/{wiki_id}/
# Returns: record<attributes: record<content_type: string, current_user_can_comment: string, date_modified: string, extra: string, kind: string, materialized_path: string, name: string, path: string, size: string>, id: string, links: record<download: string, info: string, self: string>, relationships: record<comments: string, node: string, user: string>, type: string>
# operationId: wiki_read
export def "wiki-read" [
  wiki_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/wikis/{wiki_id}/"
    path_params: [{name: wiki_id, var: wiki_id}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    wiki_id: $wiki_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve the Content of a Wiki
#
# GET /wikis/{wiki_id}/content/
# operationId: wiki_content
export def "wiki-content" [
  wiki_id: string
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
    path: "/wikis/{wiki_id}/content/"
    path_params: [{name: wiki_id, var: wiki_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    wiki_id: $wiki_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
