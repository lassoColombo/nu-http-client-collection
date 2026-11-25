# Auto-generated client for BillingManagementClient v2019-10-01-preview
# Source: https://api.apis.guru/v2/specs/azure.com/billing/2019-10-01-preview/swagger.json
# Auth: --token flag or $env.BILLINGMANAGEMENTCLIENT_TOKEN

const CLIENT = {
  base_url: "https://management.azure.com"
  token_env_var: "BILLINGMANAGEMENTCLIENT_TOKEN"
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

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def auto-renew-completer [] { ["false" "true"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    billing-accounts-list: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    billing-accounts-get: "record<properties: record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, companyName: string, country: string, firstName: string, lastName: string, postalCode: string, region: string>, agreementType: string, billingProfiles: list<record>, customerType: string, departments: list<record>, displayName: string, enrollmentAccounts: list<record>, enrollmentDetails: record<billingCycle: string, channel: string, countryCode: string, currency: string, endDate: string, language: string, policies: record, startDate: string, status: string>, organizationId: string>, id: string, name: string, type: string>"
    billing-accounts-update: "record<properties: record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, companyName: string, country: string, firstName: string, lastName: string, postalCode: string, region: string>, agreementType: string, billingProfiles: list<record>, customerType: string, departments: list<record>, displayName: string, enrollmentAccounts: list<record>, enrollmentDetails: record<billingCycle: string, channel: string, countryCode: string, currency: string, endDate: string, language: string, policies: record, startDate: string, status: string>, organizationId: string>, id: string, name: string, type: string>"
    agreements-list-by-billing-account: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    agreements-get: "record<properties: record<agreementLink: string, effectiveDate: string, expirationDate: string, participants: list<record>, status: string>, id: string, name: string, type: string>"
    billing-permissions-list-by-billing-account: "record<value: table<actions: list, notActions: list>>"
    billing-profiles-list-by-billing-account: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    billing-profiles-get: "record<properties: record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, companyName: string, country: string, firstName: string, lastName: string, postalCode: string, region: string>, currency: string, displayName: string, enabledAzurePlans: list<record>, invoiceDay: int, invoiceEmailOptIn: bool, invoiceSections: list<record>, poNumber: string>, id: string, name: string, type: string>"
    billing-profiles-update: "record<properties: record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, companyName: string, country: string, firstName: string, lastName: string, postalCode: string, region: string>, currency: string, displayName: string, enabledAzurePlans: list<record>, invoiceDay: int, invoiceEmailOptIn: bool, invoiceSections: list<record>, poNumber: string>, id: string, name: string, type: string>"
    billing-profiles-create: "record<properties: record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, companyName: string, country: string, firstName: string, lastName: string, postalCode: string, region: string>, currency: string, displayName: string, enabledAzurePlans: list<record>, invoiceDay: int, invoiceEmailOptIn: bool, invoiceSections: list<record>, poNumber: string>, id: string, name: string, type: string>"
    available-balances-get-by-billing-profile: "record<properties: record<amount: record<currency: string, value: float>>, id: string, name: string, type: string>"
    billing-permissions-list-by-billing-profile: "record<value: table<actions: list, notActions: list>>"
    billing-role-assignments-list-by-billing-profile: "record<value: table<properties: record, id: string, name: string, type: string>>"
    billing-role-assignments-delete-by-billing-profile: "record<properties: record<createdByPrincipalId: string, createdByPrincipalTenantId: string, createdOn: string, name: string, principalId: string, roleDefinitionName: string, scope: string>, id: string, name: string, type: string>"
    billing-role-assignments-get-by-billing-profile: "record<properties: record<createdByPrincipalId: string, createdByPrincipalTenantId: string, createdOn: string, name: string, principalId: string, roleDefinitionName: string, scope: string>, id: string, name: string, type: string>"
    billing-role-definitions-list-by-billing-profile: "record<value: table<properties: record, id: string, name: string, type: string>>"
    billing-role-definitions-get-by-billing-profile: "record<properties: record<description: string, permissions: list<record>, roleName: string>, id: string, name: string, type: string>"
    billing-subscriptions-list-by-billing-profile: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    billing-role-assignments-add-by-billing-profile: "record<value: table<properties: record, id: string, name: string, type: string>>"
    customers-list-by-billing-profile: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    partner-transfers-initiate: "record<properties: record<billingAccountId: string, billingProfileId: string, canceledBy: string, creationTime: string, detailedTransferStatus: list<record>, expirationTime: string, initiatorCustomerType: string, initiatorEmailId: string, invoiceSectionId: string, lastModifiedTime: string, recipientEmailId: string, resellerId: string, resellerName: string, transferStatus: string>>"
    partner-transfers-list: "record<nextLink: string, value: table<properties: record>>"
    partner-transfers-cancel: "record<properties: record<billingAccountId: string, billingProfileId: string, canceledBy: string, creationTime: string, detailedTransferStatus: list<record>, expirationTime: string, initiatorCustomerType: string, initiatorEmailId: string, invoiceSectionId: string, lastModifiedTime: string, recipientEmailId: string, resellerId: string, resellerName: string, transferStatus: string>>"
    partner-transfers-get: "record<properties: record<billingAccountId: string, billingProfileId: string, canceledBy: string, creationTime: string, detailedTransferStatus: list<record>, expirationTime: string, initiatorCustomerType: string, initiatorEmailId: string, invoiceSectionId: string, lastModifiedTime: string, recipientEmailId: string, resellerId: string, resellerName: string, transferStatus: string>>"
    instructions-list-by-billing-profile: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    instructions-get: "record<properties: record<amount: float, endDate: string, startDate: string>, id: string, name: string, type: string>"
    instructions-put: "record<properties: record<amount: float, endDate: string, startDate: string>, id: string, name: string, type: string>"
    invoice-sections-list-by-billing-profile: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    invoice-sections-get: "record<properties: record<displayName: string>, id: string, name: string, type: string>"
    invoice-sections-update: "record<properties: record<displayName: string>, id: string, name: string, type: string>"
    invoice-sections-create: "record<properties: record<displayName: string>, id: string, name: string, type: string>"
    billing-permissions-list-by-invoice-sections: "record<value: table<actions: list, notActions: list>>"
    billing-role-assignments-list-by-invoice-section: "record<value: table<properties: record, id: string, name: string, type: string>>"
    billing-role-assignments-delete-by-invoice-section: "record<properties: record<createdByPrincipalId: string, createdByPrincipalTenantId: string, createdOn: string, name: string, principalId: string, roleDefinitionName: string, scope: string>, id: string, name: string, type: string>"
    billing-role-assignments-get-by-invoice-section: "record<properties: record<createdByPrincipalId: string, createdByPrincipalTenantId: string, createdOn: string, name: string, principalId: string, roleDefinitionName: string, scope: string>, id: string, name: string, type: string>"
    billing-role-definitions-list-by-invoice-section: "record<value: table<properties: record, id: string, name: string, type: string>>"
    billing-role-definitions-get-by-invoice-section: "record<properties: record<description: string, permissions: list<record>, roleName: string>, id: string, name: string, type: string>"
    billing-subscriptions-list-by-invoice-section: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    billing-subscriptions-get: "record<properties: record<billingProfileDisplayName: string, billingProfileId: string, customerDisplayName: string, customerId: string, displayName: string, invoiceSectionDisplayName: string, invoiceSectionId: string, lastMonthCharges: record<currency: string, value: float>, monthToDateCharges: record<currency: string, value: float>, reseller: record<description: string, resellerId: string>, skuDescription: string, skuId: string, subscriptionBillingStatus: string, subscriptionId: string>, id: string, name: string, type: string>"
    billing-subscriptions-transfer: "record<properties: record<billingSubscriptionName: string>>"
    billing-subscriptions-validate-transfer: "record<errorDetails: record<code: string, details: string, message: string>, isTransferEligible: bool>"
    billing-role-assignments-add-by-invoice-section: "record<value: table<properties: record, id: string, name: string, type: string>>"
    transfers-initiate: "record<properties: record<billingAccountId: string, billingProfileId: string, canceledBy: string, creationTime: string, detailedTransferStatus: list<record>, expirationTime: string, initiatorCustomerType: string, initiatorEmailId: string, invoiceSectionId: string, lastModifiedTime: string, recipientEmailId: string, resellerId: string, resellerName: string, transferStatus: string>>"
    products-list-by-invoice-section: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    products-get: "record<properties: record<availabilityId: string, billingFrequency: string, billingProfileDisplayName: string, billingProfileId: string, customerDisplayName: string, customerId: string, displayName: string, endDate: string, invoiceSectionDisplayName: string, invoiceSectionId: string, lastCharge: record<currency: string, value: float>, lastChargeDate: string, parentProductId: string, productType: string, productTypeId: string, purchaseDate: string, quantity: float, reseller: record<description: string, resellerId: string>, skuDescription: string, skuId: string, status: string>, id: string, name: string, type: string>"
    products-transfer: "record<properties: record<availabilityId: string, billingFrequency: string, billingProfileDisplayName: string, billingProfileId: string, customerDisplayName: string, customerId: string, displayName: string, endDate: string, invoiceSectionDisplayName: string, invoiceSectionId: string, lastCharge: record<currency: string, value: float>, lastChargeDate: string, parentProductId: string, productType: string, productTypeId: string, purchaseDate: string, quantity: float, reseller: record<description: string, resellerId: string>, skuDescription: string, skuId: string, status: string>, id: string, name: string, type: string>"
    products-update-auto-renew-by-invoice-section: "record<properties: record<endDate: string>>"
    products-validate-transfer: "record<errorDetails: record<code: string, details: string, message: string>, isTransferEligible: bool>"
    transactions-list-by-invoice-section: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    transfers-list: "record<nextLink: string, value: table<properties: record>>"
    transfers-cancel: "record<properties: record<billingAccountId: string, billingProfileId: string, canceledBy: string, creationTime: string, detailedTransferStatus: list<record>, expirationTime: string, initiatorCustomerType: string, initiatorEmailId: string, invoiceSectionId: string, lastModifiedTime: string, recipientEmailId: string, resellerId: string, resellerName: string, transferStatus: string>>"
    transfers-get: "record<properties: record<billingAccountId: string, billingProfileId: string, canceledBy: string, creationTime: string, detailedTransferStatus: list<record>, expirationTime: string, initiatorCustomerType: string, initiatorEmailId: string, invoiceSectionId: string, lastModifiedTime: string, recipientEmailId: string, resellerId: string, resellerName: string, transferStatus: string>>"
    invoices-list-by-billing-profile: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    invoices-get: "record<properties: record<amountDue: record<currency: string, value: float>, billedAmount: record<currency: string, value: float>, billingProfileDisplayName: string, billingProfileId: string, documents: list<record>, dueDate: string, invoiceDate: string, invoicePeriodEndDate: string, invoicePeriodStartDate: string, invoiceType: any, payments: list<record>, purchaseOrderNumber: string, status: string>, id: string, name: string, type: string>"
    price-sheet-download: "record<expiryTime: string, url: string>"
    payment-methods-list-by-billing-profile: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    policies-get-by-billing-profile: "record<properties: record<marketplacePurchases: string, reservationPurchases: string, viewCharges: string>, id: string, name: string, type: string>"
    policies-update: "record<properties: record<marketplacePurchases: string, reservationPurchases: string, viewCharges: string>, id: string, name: string, type: string>"
    price-sheet-download-by-billing-profile: "record<expiryTime: string, url: string>"
    transactions-list-by-billing-profile: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    transactions-get: "record<properties: record<billingProfileDisplayName: string, billingProfileId: string, customerDisplayName: string, customerId: string, date: string, invoice: string, invoiceSectionDisplayName: string, invoiceSectionId: string, kind: string, orderId: string, orderName: string, productDescription: string, productFamily: string, productType: string, productTypeId: string, quantity: int, subscriptionId: string, subscriptionName: string, transactionAmount: record<currency: string, value: float>, transactionType: string>, id: string, name: string, type: string>"
    billing-role-assignments-list-by-billing-account: "record<value: table<properties: record, id: string, name: string, type: string>>"
    billing-role-assignments-delete-by-billing-account: "record<properties: record<createdByPrincipalId: string, createdByPrincipalTenantId: string, createdOn: string, name: string, principalId: string, roleDefinitionName: string, scope: string>, id: string, name: string, type: string>"
    billing-role-assignments-get-by-billing-account: "record<properties: record<createdByPrincipalId: string, createdByPrincipalTenantId: string, createdOn: string, name: string, principalId: string, roleDefinitionName: string, scope: string>, id: string, name: string, type: string>"
    billing-role-definitions-list-by-billing-account: "record<value: table<properties: record, id: string, name: string, type: string>>"
    billing-role-definitions-get-by-billing-account: "record<properties: record<description: string, permissions: list<record>, roleName: string>, id: string, name: string, type: string>"
    billing-subscriptions-list-by-billing-account: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    invoices-list-by-billing-subscription: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    invoices-get-by-id: "record<properties: record<amountDue: record<currency: string, value: float>, billedAmount: record<currency: string, value: float>, billingProfileDisplayName: string, billingProfileId: string, documents: list<record>, dueDate: string, invoiceDate: string, invoicePeriodEndDate: string, invoicePeriodStartDate: string, invoiceType: any, payments: list<record>, purchaseOrderNumber: string, status: string>, id: string, name: string, type: string>"
    billing-role-assignments-add-by-billing-account: "record<value: table<properties: record, id: string, name: string, type: string>>"
    customers-list-by-billing-account: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    customers-get: "record<properties: record<displayName: string, enabledAzurePlans: list<record>, resellers: list<record>>, id: string, name: string, type: string>"
    billing-permissions-list-by-customer: "record<value: table<actions: list, notActions: list>>"
    billing-subscriptions-list-by-customer: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    billing-subscriptions-get-by-customer: "record<properties: record<billingProfileDisplayName: string, billingProfileId: string, customerDisplayName: string, customerId: string, displayName: string, invoiceSectionDisplayName: string, invoiceSectionId: string, lastMonthCharges: record<currency: string, value: float>, monthToDateCharges: record<currency: string, value: float>, reseller: record<description: string, resellerId: string>, skuDescription: string, skuId: string, subscriptionBillingStatus: string, subscriptionId: string>, id: string, name: string, type: string>"
    policies-get-by-customer: "record<properties: record<viewCharges: string>, id: string, name: string, type: string>"
    policies-update-customer: "record<properties: record<viewCharges: string>, id: string, name: string, type: string>"
    products-list-by-customer: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    products-get-by-customer: "record<properties: record<availabilityId: string, billingFrequency: string, billingProfileDisplayName: string, billingProfileId: string, customerDisplayName: string, customerId: string, displayName: string, endDate: string, invoiceSectionDisplayName: string, invoiceSectionId: string, lastCharge: record<currency: string, value: float>, lastChargeDate: string, parentProductId: string, productType: string, productTypeId: string, purchaseDate: string, quantity: float, reseller: record<description: string, resellerId: string>, skuDescription: string, skuId: string, status: string>, id: string, name: string, type: string>"
    transactions-list-by-customer: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    departments-list-by-billing-account-name: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    departments-get: "record<properties: record<costCenter: string, departmentName: string, enrollmentAccounts: list<record>, status: string>, id: string, name: string, type: string>"
    enrollment-accounts-list-by-billing-account-name: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    enrollment-accounts-get-by-enrollment-account-id: "record<properties: record<accountName: string, accountOwner: string, costCenter: string, department: record<properties: record, id: string, name: string, type: string>, endDate: string, startDate: string, status: string>, id: string, name: string, type: string>"
    invoices-list-by-billing-account: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    billing-accounts-list-invoice-sections-by-create-subscription-permission: "record<nextLink: string, value: table<billingProfileDisplayName: string, billingProfileId: string, enabledAzurePlans: list, invoiceSectionDisplayName: string, invoiceSectionId: string>>"
    payment-methods-list-by-billing-account: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    products-list-by-billing-account: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    transactions-list-by-billing-account: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    operations-list: "record<nextLink: string, value: table<display: record, name: string>>"
    recipient-transfers-list: "record<nextLink: string, value: table<properties: record>>"
    recipient-transfers-get: "record<properties: record<allowedProductType: list<string>, canceledBy: string, creationTime: string, detailedTransferStatus: list<record>, expirationTime: string, initiatorCustomerType: string, initiatorEmailId: string, lastModifiedTime: string, recipientEmailId: string, resellerId: string, resellerName: string, transferStatus: string>>"
    recipient-transfers-accept: "record<properties: record<allowedProductType: list<string>, canceledBy: string, creationTime: string, detailedTransferStatus: list<record>, expirationTime: string, initiatorCustomerType: string, initiatorEmailId: string, lastModifiedTime: string, recipientEmailId: string, resellerId: string, resellerName: string, transferStatus: string>>"
    recipient-transfers-decline: "record<properties: record<allowedProductType: list<string>, canceledBy: string, creationTime: string, detailedTransferStatus: list<record>, expirationTime: string, initiatorCustomerType: string, initiatorEmailId: string, lastModifiedTime: string, recipientEmailId: string, resellerId: string, resellerName: string, transferStatus: string>>"
    recipient-transfers-validate: "record<value: table<properties: record>>"
    address-validate: "record<status: string, suggestedAddresses: table<addressLine1: string, addressLine2: string, addressLine3: string, city: string, companyName: string, country: string, firstName: string, lastName: string, postalCode: string, region: string>, validationMessage: string>"
    line-of-credits-get: "record<properties: record<creditLimit: record<currency: string, value: float>, reason: string, remainingBalance: record<currency: string, value: float>, status: string>, id: string, name: string, type: string>"
    line-of-credits-update: "record<properties: record<creditLimit: record<currency: string, value: float>, reason: string, remainingBalance: record<currency: string, value: float>, status: string>, id: string, name: string, type: string>"
    billing-property-get: "record<properties: record<billingAccountDisplayName: string, billingAccountId: string, billingProfileDisplayName: string, billingProfileId: string, billingTenantId: string, costCenter: string, invoiceSectionDisplayName: string, invoiceSectionId: string, productId: string, productName: string, skuDescription: string, skuId: string>, id: string, name: string, type: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["billing-accounts-list" "billing-accounts-get" "billing-accounts-update" "agreements-list-by-billing-account" "agreements-get" "billing-permissions-list-by-billing-account" "billing-profiles-list-by-billing-account" "billing-profiles-get" "billing-profiles-update" "billing-profiles-create" "available-balances-get-by-billing-profile" "billing-permissions-list-by-billing-profile" "billing-role-assignments-list-by-billing-profile" "billing-role-assignments-delete-by-billing-profile" "billing-role-assignments-get-by-billing-profile" "billing-role-definitions-list-by-billing-profile" "billing-role-definitions-get-by-billing-profile" "billing-subscriptions-list-by-billing-profile" "billing-role-assignments-add-by-billing-profile" "customers-list-by-billing-profile" "partner-transfers-initiate" "partner-transfers-list" "partner-transfers-cancel" "partner-transfers-get" "instructions-list-by-billing-profile" "instructions-get" "instructions-put" "invoice-sections-list-by-billing-profile" "invoice-sections-get" "invoice-sections-update" "invoice-sections-create" "billing-permissions-list-by-invoice-sections" "billing-role-assignments-list-by-invoice-section" "billing-role-assignments-delete-by-invoice-section" "billing-role-assignments-get-by-invoice-section" "billing-role-definitions-list-by-invoice-section" "billing-role-definitions-get-by-invoice-section" "billing-subscriptions-list-by-invoice-section" "billing-subscriptions-get" "billing-subscriptions-transfer" "billing-subscriptions-validate-transfer" "billing-role-assignments-add-by-invoice-section" "invoice-sections-elevate-to-billing-profile" "transfers-initiate" "products-list-by-invoice-section" "products-get" "products-transfer" "products-update-auto-renew-by-invoice-section" "products-validate-transfer" "transactions-list-by-invoice-section" "transfers-list" "transfers-cancel" "transfers-get" "invoices-list-by-billing-profile" "invoices-get" "price-sheet-download" "payment-methods-list-by-billing-profile" "policies-get-by-billing-profile" "policies-update" "price-sheet-download-by-billing-profile" "transactions-list-by-billing-profile" "transactions-get" "billing-role-assignments-list-by-billing-account" "billing-role-assignments-delete-by-billing-account" "billing-role-assignments-get-by-billing-account" "billing-role-definitions-list-by-billing-account" "billing-role-definitions-get-by-billing-account" "billing-subscriptions-list-by-billing-account" "invoices-list-by-billing-subscription" "invoices-get-by-id" "billing-role-assignments-add-by-billing-account" "customers-list-by-billing-account" "customers-get" "billing-permissions-list-by-customer" "billing-subscriptions-list-by-customer" "billing-subscriptions-get-by-customer" "policies-get-by-customer" "policies-update-customer" "products-list-by-customer" "products-get-by-customer" "transactions-list-by-customer" "departments-list-by-billing-account-name" "departments-get" "enrollment-accounts-list-by-billing-account-name" "enrollment-accounts-get-by-enrollment-account-id" "invoices-list-by-billing-account" "billing-accounts-list-invoice-sections-by-create-subscription-permission" "payment-methods-list-by-billing-account" "products-list-by-billing-account" "transactions-list-by-billing-account" "operations-list" "recipient-transfers-list" "recipient-transfers-get" "recipient-transfers-accept" "recipient-transfers-decline" "recipient-transfers-validate" "address-validate" "line-of-credits-get" "line-of-credits-update" "billing-property-get" "commands"] | sort) } | get name | first)
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

# Lists all billing accounts for a user which he has access to.
#
# GET /providers/Microsoft.Billing/billingAccounts
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: BillingAccounts_List
export def "billing-accounts-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --expand: string # May be used to expand the address, invoiceSections and billingProfiles.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts"
    query: [{name: api-version, var: api_version, required: true}, {name: "$expand", var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the billing account by id.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}
# Returns: record<properties: record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, companyName: string, country: string, firstName: string, lastName: string, postalCode: string, region: string>, agreementType: string, billingProfiles: list<record>, customerType: string, departments: list<record>, displayName: string, enrollmentAccounts: list<record>, enrollmentDetails: record<billingCycle: string, channel: string, countryCode: string, currency: string, endDate: string, language: string, policies: record, startDate: string, status: string>, organizationId: string>, id: string, name: string, type: string>
# operationId: BillingAccounts_Get
export def "billing-accounts-get" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --expand: string # May be used to expand the address, invoiceSections and billingProfiles.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}"
    path_params: [{name: billingAccountName, var: billing_account_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$expand", var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, api_version: $api_version, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The operation to update a billing account.
#
# PATCH /providers/Microsoft.Billing/billingAccounts/{billingAccountName}
# Returns: record<properties: record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, companyName: string, country: string, firstName: string, lastName: string, postalCode: string, region: string>, agreementType: string, billingProfiles: list<record>, customerType: string, departments: list<record>, displayName: string, enrollmentAccounts: list<record>, enrollmentDetails: record<billingCycle: string, channel: string, countryCode: string, currency: string, endDate: string, language: string, policies: record, startDate: string, status: string>, organizationId: string>, id: string, name: string, type: string>
# operationId: BillingAccounts_Update
export def "billing-accounts-update" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --properties: any # The properties of the billing account. — shape: {address?: any, billingProfiles?: list, departments?: list, enrollmentAccounts?: list, enrollmentDetails?: any}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}"
    path_params: [{name: billingAccountName, var: billing_account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all agreements for a billing account.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/agreements
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: Agreements_ListByBillingAccount
export def "agreements-list-by-billing-account" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --expand: string # May be used to expand the participants.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/agreements"
    path_params: [{name: billingAccountName, var: billing_account_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$expand", var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, api_version: $api_version, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the agreement by name.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/agreements/{agreementName}
# Returns: record<properties: record<agreementLink: string, effectiveDate: string, expirationDate: string, participants: list<record>, status: string>, id: string, name: string, type: string>
# operationId: Agreements_Get
export def "agreements-get" [
  billing_account_name: string
  agreement_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --expand: string # May be used to expand the participants.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/agreements/{agreementName}"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: agreementName, var: agreement_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$expand", var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, agreement_name: $agreement_name, api_version: $api_version, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all billing permissions for the caller under a billing account.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingPermissions
# Returns: record<value: table<actions: list, notActions: list>>
# operationId: BillingPermissions_ListByBillingAccount
export def "billing-permissions-list-by-billing-account" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingPermissions"
    path_params: [{name: billingAccountName, var: billing_account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all billing profiles for a user which that user has access to.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: BillingProfiles_ListByBillingAccount
export def "billing-profiles-list-by-billing-account" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --expand: string # May be used to expand the invoiceSections.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles"
    path_params: [{name: billingAccountName, var: billing_account_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$expand", var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, api_version: $api_version, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the billing profile by id.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}
# Returns: record<properties: record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, companyName: string, country: string, firstName: string, lastName: string, postalCode: string, region: string>, currency: string, displayName: string, enabledAzurePlans: list<record>, invoiceDay: int, invoiceEmailOptIn: bool, invoiceSections: list<record>, poNumber: string>, id: string, name: string, type: string>
# operationId: BillingProfiles_Get
export def "billing-profiles-get" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --expand: string # May be used to expand the invoiceSections.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$expand", var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, api_version: $api_version, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The operation to update a billing profile.
#
# PATCH /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}
# Returns: record<properties: record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, companyName: string, country: string, firstName: string, lastName: string, postalCode: string, region: string>, currency: string, displayName: string, enabledAzurePlans: list<record>, invoiceDay: int, invoiceEmailOptIn: bool, invoiceSections: list<record>, poNumber: string>, id: string, name: string, type: string>
# operationId: BillingProfiles_Update
export def "billing-profiles-update" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --properties: any # The properties of the billing profile. — shape: {address?: any, displayName?: string, enabledAzurePlans?: list, invoiceEmailOptIn?: bool, invoiceSections?: list, poNumber?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The operation to create a BillingProfile.
#
# PUT /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}
# Returns: record<properties: record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, companyName: string, country: string, firstName: string, lastName: string, postalCode: string, region: string>, currency: string, displayName: string, enabledAzurePlans: list<record>, invoiceDay: int, invoiceEmailOptIn: bool, invoiceSections: list<record>, poNumber: string>, id: string, name: string, type: string>
# operationId: BillingProfiles_Create
export def "billing-profiles-create" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --address: any # Address details. — shape: {addressLine1?: string, addressLine2?: string, addressLine3?: string, city?: string, companyName?: string, country?: string, firstName?: string, lastName?: string, postalCode?: string, region?: string}
  --display-name: string # The billing profile name.
  --enabled-azure-plans: list # Enabled azure plans for this billing profile. — item shape: {skuId?: string}
  --invoice-email-opt-in: oneof<nothing, bool> # If the billing profile is opted in to receive invoices via email.
  --po-number: string # Purchase order number.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: displayName, var: display_name}, {name: enabledAzurePlans, var: enabled_azure_plans}, {name: invoiceEmailOptIn, var: invoice_email_opt_in}, {name: poNumber, var: po_number}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, api_version: $api_version, address: $address, display_name: $display_name, enabled_azure_plans: $enabled_azure_plans, invoice_email_opt_in: $invoice_email_opt_in, po_number: $po_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The latest available credit balance for a given billingAccountName and billingProfileName.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/availableBalance/default
# Returns: record<properties: record<amount: record<currency: string, value: float>>, id: string, name: string, type: string>
# operationId: AvailableBalances_GetByBillingProfile
export def "available-balances-get-by-billing-profile" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/availableBalance/default"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all billing permissions the caller has for a billing account.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/billingPermissions
# Returns: record<value: table<actions: list, notActions: list>>
# operationId: BillingPermissions_ListByBillingProfile
export def "billing-permissions-list-by-billing-profile" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/billingPermissions"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the role assignments on the Billing Profile
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/billingRoleAssignments
# Returns: record<value: table<properties: record, id: string, name: string, type: string>>
# operationId: BillingRoleAssignments_ListByBillingProfile
export def "billing-role-assignments-list-by-billing-profile" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/billingRoleAssignments"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the role assignment on this Billing Profile
#
# DELETE /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/billingRoleAssignments/{billingRoleAssignmentName}
# Returns: record<properties: record<createdByPrincipalId: string, createdByPrincipalTenantId: string, createdOn: string, name: string, principalId: string, roleDefinitionName: string, scope: string>, id: string, name: string, type: string>
# operationId: BillingRoleAssignments_DeleteByBillingProfile
export def "billing-role-assignments-delete-by-billing-profile" [
  billing_account_name: string
  billing_profile_name: string
  billing_role_assignment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/billingRoleAssignments/{billingRoleAssignmentName}"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: billingRoleAssignmentName, var: billing_role_assignment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, billing_role_assignment_name: $billing_role_assignment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the role assignment for the caller on the Billing Profile
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/billingRoleAssignments/{billingRoleAssignmentName}
# Returns: record<properties: record<createdByPrincipalId: string, createdByPrincipalTenantId: string, createdOn: string, name: string, principalId: string, roleDefinitionName: string, scope: string>, id: string, name: string, type: string>
# operationId: BillingRoleAssignments_GetByBillingProfile
export def "billing-role-assignments-get-by-billing-profile" [
  billing_account_name: string
  billing_profile_name: string
  billing_role_assignment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/billingRoleAssignments/{billingRoleAssignmentName}"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: billingRoleAssignmentName, var: billing_role_assignment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, billing_role_assignment_name: $billing_role_assignment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the role definition for a Billing Profile
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/billingRoleDefinitions
# Returns: record<value: table<properties: record, id: string, name: string, type: string>>
# operationId: BillingRoleDefinitions_ListByBillingProfile
export def "billing-role-definitions-list-by-billing-profile" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/billingRoleDefinitions"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the role definition for a role
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/billingRoleDefinitions/{billingRoleDefinitionName}
# Returns: record<properties: record<description: string, permissions: list<record>, roleName: string>, id: string, name: string, type: string>
# operationId: BillingRoleDefinitions_GetByBillingProfile
export def "billing-role-definitions-get-by-billing-profile" [
  billing_account_name: string
  billing_profile_name: string
  billing_role_definition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/billingRoleDefinitions/{billingRoleDefinitionName}"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: billingRoleDefinitionName, var: billing_role_definition_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, billing_role_definition_name: $billing_role_definition_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists billing subscriptions by billing profile name.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/billingSubscriptions
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: BillingSubscriptions_ListByBillingProfile
export def "billing-subscriptions-list-by-billing-profile" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/billingSubscriptions"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The operation to add a role assignment to a billing profile.
#
# POST /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/createBillingRoleAssignment
# Returns: record<value: table<properties: record, id: string, name: string, type: string>>
# operationId: BillingRoleAssignments_AddByBillingProfile
export def "billing-role-assignments-add-by-billing-profile" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --billing-role-definition-id: string # The role definition id
  --principal-id: string # The user's principal id that the role gets assigned to
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/createBillingRoleAssignment"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: billingRoleDefinitionId, var: billing_role_definition_id}, {name: principalId, var: principal_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, api_version: $api_version, billing_role_definition_id: $billing_role_definition_id, principal_id: $principal_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists customers by billing profile which the current user can work with on-behalf of a partner.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/customers
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: Customers_ListByBillingProfile
export def "customers-list-by-billing-profile" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --filter: string # May be used to filter the list of customers.
  --skiptoken: string # Skiptoken is only used if a previous operation returned a partial result. If a previous response contains a nextLink element, the value of the nextLink element will include a skiptoken parameter that specifies a starting point to use for subsequent calls.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/customers"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$filter", var: filter}, {name: "$skiptoken", var: skiptoken}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, api_version: $api_version, filter: $filter, skiptoken: $skiptoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiates the request to transfer the legacy subscriptions or RIs.
#
# POST /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/customers/{customerName}/initiateTransfer
# Returns: record<properties: record<billingAccountId: string, billingProfileId: string, canceledBy: string, creationTime: string, detailedTransferStatus: list<record>, expirationTime: string, initiatorCustomerType: string, initiatorEmailId: string, invoiceSectionId: string, lastModifiedTime: string, recipientEmailId: string, resellerId: string, resellerName: string, transferStatus: string>>
# operationId: PartnerTransfers_Initiate
export def "partner-transfers-initiate" [
  billing_account_name: string
  billing_profile_name: string
  customer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --properties: record # Request parameters to initiate transfer. — shape: {recipientEmailId?: string, resellerId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/customers/{customerName}/initiateTransfer"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: customerName, var: customer_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, customer_name: $customer_name, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all transfer's details initiated from given invoice section.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/customers/{customerName}/transfers
# Returns: record<nextLink: string, value: table<properties: record>>
# operationId: PartnerTransfers_List
export def "partner-transfers-list" [
  billing_account_name: string
  billing_profile_name: string
  customer_name: string
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
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/customers/{customerName}/transfers"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: customerName, var: customer_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, customer_name: $customer_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels the transfer for given transfer Id.
#
# DELETE /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/customers/{customerName}/transfers/{transferName}
# Returns: record<properties: record<billingAccountId: string, billingProfileId: string, canceledBy: string, creationTime: string, detailedTransferStatus: list<record>, expirationTime: string, initiatorCustomerType: string, initiatorEmailId: string, invoiceSectionId: string, lastModifiedTime: string, recipientEmailId: string, resellerId: string, resellerName: string, transferStatus: string>>
# operationId: PartnerTransfers_Cancel
export def "partner-transfers-cancel" [
  billing_account_name: string
  billing_profile_name: string
  customer_name: string
  transfer_name: string
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
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/customers/{customerName}/transfers/{transferName}"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: customerName, var: customer_name}, {name: transferName, var: transfer_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, customer_name: $customer_name, transfer_name: $transfer_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the transfer details for given transfer Id.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/customers/{customerName}/transfers/{transferName}
# Returns: record<properties: record<billingAccountId: string, billingProfileId: string, canceledBy: string, creationTime: string, detailedTransferStatus: list<record>, expirationTime: string, initiatorCustomerType: string, initiatorEmailId: string, invoiceSectionId: string, lastModifiedTime: string, recipientEmailId: string, resellerId: string, resellerName: string, transferStatus: string>>
# operationId: PartnerTransfers_Get
export def "partner-transfers-get" [
  billing_account_name: string
  billing_profile_name: string
  customer_name: string
  transfer_name: string
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
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/customers/{customerName}/transfers/{transferName}"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: customerName, var: customer_name}, {name: transferName, var: transfer_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, customer_name: $customer_name, transfer_name: $transfer_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the instructions by billing profile id.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/instructions
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: Instructions_ListByBillingProfile
export def "instructions-list-by-billing-profile" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/instructions"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the instruction by name.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/instructions/{instructionName}
# Returns: record<properties: record<amount: float, endDate: string, startDate: string>, id: string, name: string, type: string>
# operationId: Instructions_Get
export def "instructions-get" [
  billing_account_name: string
  billing_profile_name: string
  instruction_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/instructions/{instructionName}"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: instructionName, var: instruction_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, instruction_name: $instruction_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The operation to create or update a instruction.
#
# PUT /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/instructions/{instructionName}
# Returns: record<properties: record<amount: float, endDate: string, startDate: string>, id: string, name: string, type: string>
# operationId: Instructions_Put
export def "instructions-put" [
  billing_account_name: string
  billing_profile_name: string
  instruction_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --properties: any # A billing instruction used during invoice generation. — shape: {amount: float, endDate: string, startDate: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/instructions/{instructionName}"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: instructionName, var: instruction_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, instruction_name: $instruction_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all invoice sections for a user which he has access to.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: InvoiceSections_ListByBillingProfile
export def "invoice-sections-list-by-billing-profile" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the InvoiceSection by id.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}
# Returns: record<properties: record<displayName: string>, id: string, name: string, type: string>
# operationId: InvoiceSections_Get
export def "invoice-sections-get" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: invoiceSectionName, var: invoice_section_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, invoice_section_name: $invoice_section_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The operation to update a InvoiceSection.
#
# PATCH /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}
# Returns: record<properties: record<displayName: string>, id: string, name: string, type: string>
# operationId: InvoiceSections_Update
export def "invoice-sections-update" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --properties: any # The properties of an InvoiceSection. — shape: {displayName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: invoiceSectionName, var: invoice_section_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, invoice_section_name: $invoice_section_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The operation to create an invoice section.
#
# PUT /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}
# Returns: record<properties: record<displayName: string>, id: string, name: string, type: string>
# operationId: InvoiceSections_Create
export def "invoice-sections-create" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --display-name: string # The name of the InvoiceSection.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: invoiceSectionName, var: invoice_section_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: displayName, var: display_name}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, invoice_section_name: $invoice_section_name, api_version: $api_version, display_name: $display_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all billing permissions for the caller under invoice section.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/billingPermissions
# Returns: record<value: table<actions: list, notActions: list>>
# operationId: BillingPermissions_ListByInvoiceSections
export def "billing-permissions-list-by-invoice-sections" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/billingPermissions"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: invoiceSectionName, var: invoice_section_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, invoice_section_name: $invoice_section_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the role assignments on the invoice Section
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/billingRoleAssignments
# Returns: record<value: table<properties: record, id: string, name: string, type: string>>
# operationId: BillingRoleAssignments_ListByInvoiceSection
export def "billing-role-assignments-list-by-invoice-section" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/billingRoleAssignments"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: invoiceSectionName, var: invoice_section_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, invoice_section_name: $invoice_section_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the role assignment on the invoice Section
#
# DELETE /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/billingRoleAssignments/{billingRoleAssignmentName}
# Returns: record<properties: record<createdByPrincipalId: string, createdByPrincipalTenantId: string, createdOn: string, name: string, principalId: string, roleDefinitionName: string, scope: string>, id: string, name: string, type: string>
# operationId: BillingRoleAssignments_DeleteByInvoiceSection
export def "billing-role-assignments-delete-by-invoice-section" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  billing_role_assignment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/billingRoleAssignments/{billingRoleAssignmentName}"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: invoiceSectionName, var: invoice_section_name}, {name: billingRoleAssignmentName, var: billing_role_assignment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, invoice_section_name: $invoice_section_name, billing_role_assignment_name: $billing_role_assignment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the role assignment for the caller on the invoice Section
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/billingRoleAssignments/{billingRoleAssignmentName}
# Returns: record<properties: record<createdByPrincipalId: string, createdByPrincipalTenantId: string, createdOn: string, name: string, principalId: string, roleDefinitionName: string, scope: string>, id: string, name: string, type: string>
# operationId: BillingRoleAssignments_GetByInvoiceSection
export def "billing-role-assignments-get-by-invoice-section" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  billing_role_assignment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/billingRoleAssignments/{billingRoleAssignmentName}"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: invoiceSectionName, var: invoice_section_name}, {name: billingRoleAssignmentName, var: billing_role_assignment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, invoice_section_name: $invoice_section_name, billing_role_assignment_name: $billing_role_assignment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the role definition for an invoice Section
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/billingRoleDefinitions
# Returns: record<value: table<properties: record, id: string, name: string, type: string>>
# operationId: BillingRoleDefinitions_ListByInvoiceSection
export def "billing-role-definitions-list-by-invoice-section" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/billingRoleDefinitions"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: invoiceSectionName, var: invoice_section_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, invoice_section_name: $invoice_section_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the role definition for a role
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/billingRoleDefinitions/{billingRoleDefinitionName}
# Returns: record<properties: record<description: string, permissions: list<record>, roleName: string>, id: string, name: string, type: string>
# operationId: BillingRoleDefinitions_GetByInvoiceSection
export def "billing-role-definitions-get-by-invoice-section" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  billing_role_definition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/billingRoleDefinitions/{billingRoleDefinitionName}"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: invoiceSectionName, var: invoice_section_name}, {name: billingRoleDefinitionName, var: billing_role_definition_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, invoice_section_name: $invoice_section_name, billing_role_definition_name: $billing_role_definition_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists billing subscription by invoice section name.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/billingSubscriptions
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: BillingSubscriptions_ListByInvoiceSection
export def "billing-subscriptions-list-by-invoice-section" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/billingSubscriptions"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: invoiceSectionName, var: invoice_section_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, invoice_section_name: $invoice_section_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single billing subscription by name.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/billingSubscriptions/{billingSubscriptionName}
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# Returns: record<properties: record<billingProfileDisplayName: string, billingProfileId: string, customerDisplayName: string, customerId: string, displayName: string, invoiceSectionDisplayName: string, invoiceSectionId: string, lastMonthCharges: record<currency: string, value: float>, monthToDateCharges: record<currency: string, value: float>, reseller: record<description: string, resellerId: string>, skuDescription: string, skuId: string, subscriptionBillingStatus: string, subscriptionId: string>, id: string, name: string, type: string>
# operationId: BillingSubscriptions_Get
export def "billing-subscriptions-get" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  billing_subscription_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/billingSubscriptions/{billingSubscriptionName}"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: invoiceSectionName, var: invoice_section_name}, {name: billingSubscriptionName, var: billing_subscription_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, invoice_section_name: $invoice_section_name, billing_subscription_name: $billing_subscription_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transfers the subscription from one invoice section to another within a billing account.
#
# POST /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/billingSubscriptions/{billingSubscriptionName}/transfer
# Returns: record<properties: record<billingSubscriptionName: string>>
# operationId: BillingSubscriptions_Transfer
export def "billing-subscriptions-transfer" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  billing_subscription_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --destination-billing-profile-id: string # The destination billing profile id.
  --destination-invoice-section-id: string # The destination invoice section id.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/billingSubscriptions/{billingSubscriptionName}/transfer"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: invoiceSectionName, var: invoice_section_name}, {name: billingSubscriptionName, var: billing_subscription_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: destinationBillingProfileId, var: destination_billing_profile_id}, {name: destinationInvoiceSectionId, var: destination_invoice_section_id}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, invoice_section_name: $invoice_section_name, billing_subscription_name: $billing_subscription_name, destination_billing_profile_id: $destination_billing_profile_id, destination_invoice_section_id: $destination_invoice_section_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validates the transfer of billing subscriptions across invoice sections.
#
# POST /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/billingSubscriptions/{billingSubscriptionName}/validateTransferEligibility
# Returns: record<errorDetails: record<code: string, details: string, message: string>, isTransferEligible: bool>
# operationId: BillingSubscriptions_ValidateTransfer
export def "billing-subscriptions-validate-transfer" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  billing_subscription_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --destination-billing-profile-id: string # The destination billing profile id.
  --destination-invoice-section-id: string # The destination invoice section id.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/billingSubscriptions/{billingSubscriptionName}/validateTransferEligibility"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: invoiceSectionName, var: invoice_section_name}, {name: billingSubscriptionName, var: billing_subscription_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: destinationBillingProfileId, var: destination_billing_profile_id}, {name: destinationInvoiceSectionId, var: destination_invoice_section_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, invoice_section_name: $invoice_section_name, billing_subscription_name: $billing_subscription_name, destination_billing_profile_id: $destination_billing_profile_id, destination_invoice_section_id: $destination_invoice_section_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The operation to add a role assignment to a invoice Section.
#
# POST /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/createBillingRoleAssignment
# Returns: record<value: table<properties: record, id: string, name: string, type: string>>
# operationId: BillingRoleAssignments_AddByInvoiceSection
export def "billing-role-assignments-add-by-invoice-section" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --billing-role-definition-id: string # The role definition id
  --principal-id: string # The user's principal id that the role gets assigned to
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/createBillingRoleAssignment"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: invoiceSectionName, var: invoice_section_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: billingRoleDefinitionId, var: billing_role_definition_id}, {name: principalId, var: principal_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, invoice_section_name: $invoice_section_name, api_version: $api_version, billing_role_definition_id: $billing_role_definition_id, principal_id: $principal_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Elevates the caller's access to match their billing profile access.
#
# POST /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/elevate
# operationId: InvoiceSections_ElevateToBillingProfile
export def "invoice-sections-elevate-to-billing-profile" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
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
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/elevate"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: invoiceSectionName, var: invoice_section_name}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, invoice_section_name: $invoice_section_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiates the request to transfer the legacy subscriptions or RIs.
#
# POST /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/initiateTransfer
# Returns: record<properties: record<billingAccountId: string, billingProfileId: string, canceledBy: string, creationTime: string, detailedTransferStatus: list<record>, expirationTime: string, initiatorCustomerType: string, initiatorEmailId: string, invoiceSectionId: string, lastModifiedTime: string, recipientEmailId: string, resellerId: string, resellerName: string, transferStatus: string>>
# operationId: Transfers_Initiate
export def "transfers-initiate" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --properties: record # Request parameters to initiate transfer. — shape: {recipientEmailId?: string, resellerId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/initiateTransfer"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: invoiceSectionName, var: invoice_section_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, invoice_section_name: $invoice_section_name, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists products by invoice section name.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/products
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: Products_ListByInvoiceSection
export def "products-list-by-invoice-section" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --filter: string # May be used to filter by product type. The filter supports 'eq', 'lt', 'gt', 'le', 'ge', and 'and'. It does not currently support 'ne', 'or', or 'not'. Tag filter is a key value pair string where key and value is separated by a colon (:).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/products"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: invoiceSectionName, var: invoice_section_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, invoice_section_name: $invoice_section_name, api_version: $api_version, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single product by name.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/products/{productName}
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# Returns: record<properties: record<availabilityId: string, billingFrequency: string, billingProfileDisplayName: string, billingProfileId: string, customerDisplayName: string, customerId: string, displayName: string, endDate: string, invoiceSectionDisplayName: string, invoiceSectionId: string, lastCharge: record<currency: string, value: float>, lastChargeDate: string, parentProductId: string, productType: string, productTypeId: string, purchaseDate: string, quantity: float, reseller: record<description: string, resellerId: string>, skuDescription: string, skuId: string, status: string>, id: string, name: string, type: string>
# operationId: Products_Get
export def "products-get" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  product_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/products/{productName}"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: invoiceSectionName, var: invoice_section_name}, {name: productName, var: product_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, invoice_section_name: $invoice_section_name, product_name: $product_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The operation to transfer a Product to another invoice section.
#
# POST /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/products/{productName}/transfer
# Returns: record<properties: record<availabilityId: string, billingFrequency: string, billingProfileDisplayName: string, billingProfileId: string, customerDisplayName: string, customerId: string, displayName: string, endDate: string, invoiceSectionDisplayName: string, invoiceSectionId: string, lastCharge: record<currency: string, value: float>, lastChargeDate: string, parentProductId: string, productType: string, productTypeId: string, purchaseDate: string, quantity: float, reseller: record<description: string, resellerId: string>, skuDescription: string, skuId: string, status: string>, id: string, name: string, type: string>
# operationId: Products_Transfer
export def "products-transfer" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  product_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --destination-billing-profile-id: string # The destination billing profile id.
  --destination-invoice-section-id: string # The destination invoice section id.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/products/{productName}/transfer"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: invoiceSectionName, var: invoice_section_name}, {name: productName, var: product_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: destinationBillingProfileId, var: destination_billing_profile_id}, {name: destinationInvoiceSectionId, var: destination_invoice_section_id}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, invoice_section_name: $invoice_section_name, product_name: $product_name, api_version: $api_version, destination_billing_profile_id: $destination_billing_profile_id, destination_invoice_section_id: $destination_invoice_section_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel auto renew for product by product id and invoice section name
#
# POST /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/products/{productName}/updateAutoRenew
# Returns: record<properties: record<endDate: string>>
# operationId: Products_UpdateAutoRenewByInvoiceSection
export def "products-update-auto-renew-by-invoice-section" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  product_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --auto-renew: string@auto-renew-completer # Request parameters to update auto renew policy a product.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/products/{productName}/updateAutoRenew"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: invoiceSectionName, var: invoice_section_name}, {name: productName, var: product_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: autoRenew, var: auto_renew}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, invoice_section_name: $invoice_section_name, product_name: $product_name, api_version: $api_version, auto_renew: $auto_renew
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validates the transfer of products across invoice sections.
#
# POST /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/products/{productName}/validateTransferEligibility
# Returns: record<errorDetails: record<code: string, details: string, message: string>, isTransferEligible: bool>
# operationId: Products_ValidateTransfer
export def "products-validate-transfer" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  product_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --destination-billing-profile-id: string # The destination billing profile id.
  --destination-invoice-section-id: string # The destination invoice section id.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/products/{productName}/validateTransferEligibility"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: invoiceSectionName, var: invoice_section_name}, {name: productName, var: product_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: destinationBillingProfileId, var: destination_billing_profile_id}, {name: destinationInvoiceSectionId, var: destination_invoice_section_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, invoice_section_name: $invoice_section_name, product_name: $product_name, destination_billing_profile_id: $destination_billing_profile_id, destination_invoice_section_id: $destination_invoice_section_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the transactions by invoice section name for given start date and end date.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/transactions
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: Transactions_ListByInvoiceSection
export def "transactions-list-by-invoice-section" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --period-start-date: string # Start date (required)
  --period-end-date: string # End date (required)
  --filter: string # May be used to filter by transaction kind. The filter supports 'eq', 'lt', 'gt', 'le', 'ge', and 'and'. It does not currently support 'ne', 'or', or 'not'. Tag filter is a key value pair string where key and value is separated by a colon (:).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/transactions"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: invoiceSectionName, var: invoice_section_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: periodStartDate, var: period_start_date, required: true}, {name: periodEndDate, var: period_end_date, required: true}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, invoice_section_name: $invoice_section_name, api_version: $api_version, period_start_date: $period_start_date, period_end_date: $period_end_date, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all transfer's details initiated from given invoice section.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/transfers
# Returns: record<nextLink: string, value: table<properties: record>>
# operationId: Transfers_List
export def "transfers-list" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
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
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/transfers"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: invoiceSectionName, var: invoice_section_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, invoice_section_name: $invoice_section_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels the transfer for given transfer Id.
#
# DELETE /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/transfers/{transferName}
# Returns: record<properties: record<billingAccountId: string, billingProfileId: string, canceledBy: string, creationTime: string, detailedTransferStatus: list<record>, expirationTime: string, initiatorCustomerType: string, initiatorEmailId: string, invoiceSectionId: string, lastModifiedTime: string, recipientEmailId: string, resellerId: string, resellerName: string, transferStatus: string>>
# operationId: Transfers_Cancel
export def "transfers-cancel" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  transfer_name: string
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
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/transfers/{transferName}"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: invoiceSectionName, var: invoice_section_name}, {name: transferName, var: transfer_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, invoice_section_name: $invoice_section_name, transfer_name: $transfer_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the transfer details for given transfer Id.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/transfers/{transferName}
# Returns: record<properties: record<billingAccountId: string, billingProfileId: string, canceledBy: string, creationTime: string, detailedTransferStatus: list<record>, expirationTime: string, initiatorCustomerType: string, initiatorEmailId: string, invoiceSectionId: string, lastModifiedTime: string, recipientEmailId: string, resellerId: string, resellerName: string, transferStatus: string>>
# operationId: Transfers_Get
export def "transfers-get" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  transfer_name: string
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
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/transfers/{transferName}"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: invoiceSectionName, var: invoice_section_name}, {name: transferName, var: transfer_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, invoice_section_name: $invoice_section_name, transfer_name: $transfer_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of invoices for a billing profile.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoices
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: Invoices_ListByBillingProfile
export def "invoices-list-by-billing-profile" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --period-start-date: string # Invoice period start date. (required)
  --period-end-date: string # Invoice period end date. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoices"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: periodStartDate, var: period_start_date, required: true}, {name: periodEndDate, var: period_end_date, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, api_version: $api_version, period_start_date: $period_start_date, period_end_date: $period_end_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the invoice by name.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoices/{invoiceName}
# Returns: record<properties: record<amountDue: record<currency: string, value: float>, billedAmount: record<currency: string, value: float>, billingProfileDisplayName: string, billingProfileId: string, documents: list<record>, dueDate: string, invoiceDate: string, invoicePeriodEndDate: string, invoicePeriodStartDate: string, invoiceType: any, payments: list<record>, purchaseOrderNumber: string, status: string>, id: string, name: string, type: string>
# operationId: Invoices_Get
export def "invoices-get" [
  billing_account_name: string
  billing_profile_name: string
  invoice_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoices/{invoiceName}"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: invoiceName, var: invoice_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, invoice_name: $invoice_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download price sheet for an invoice.
#
# POST /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoices/{invoiceName}/pricesheet/default/download
# Returns: record<expiryTime: string, url: string>
# operationId: PriceSheet_Download
export def "price-sheet-download" [
  billing_account_name: string
  billing_profile_name: string
  invoice_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoices/{invoiceName}/pricesheet/default/download"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: invoiceName, var: invoice_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, invoice_name: $invoice_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the Payment Methods by billing profile Id.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/paymentMethods
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: PaymentMethods_ListByBillingProfile
export def "payment-methods-list-by-billing-profile" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/paymentMethods"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The policy for a given billing account name and billing profile name.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/policies/default
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# Returns: record<properties: record<marketplacePurchases: string, reservationPurchases: string, viewCharges: string>, id: string, name: string, type: string>
# operationId: Policies_GetByBillingProfile
export def "policies-get-by-billing-profile" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/policies/default"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The operation to update a policy.
#
# PUT /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/policies/default
# Returns: record<properties: record<marketplacePurchases: string, reservationPurchases: string, viewCharges: string>, id: string, name: string, type: string>
# operationId: Policies_Update
export def "policies-update" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --properties: any # The properties of policy. — shape: {marketplacePurchases?: "AllAllowed"|"OnlyFreeAllowed"|"NotAllowed", reservationPurchases?: "Allowed"|"NotAllowed", viewCharges?: "Allowed"|"NotAllowed"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/policies/default"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download price sheet for a billing profile.
#
# POST /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/pricesheet/default/download
# Returns: record<expiryTime: string, url: string>
# operationId: PriceSheet_DownloadByBillingProfile
export def "price-sheet-download-by-billing-profile" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/pricesheet/default/download"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the transactions by billing profile name for given start date and end date.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/transactions
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: Transactions_ListByBillingProfile
export def "transactions-list-by-billing-profile" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --period-start-date: string # Start date (required)
  --period-end-date: string # End date (required)
  --filter: string # May be used to filter by transaction kind. The filter supports 'eq', 'lt', 'gt', 'le', 'ge', and 'and'. It does not currently support 'ne', 'or', or 'not'. Tag filter is a key value pair string where key and value is separated by a colon (:).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/transactions"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: periodStartDate, var: period_start_date, required: true}, {name: periodEndDate, var: period_end_date, required: true}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, api_version: $api_version, period_start_date: $period_start_date, period_end_date: $period_end_date, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the transaction.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/transactions/{transactionName}
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# Returns: record<properties: record<billingProfileDisplayName: string, billingProfileId: string, customerDisplayName: string, customerId: string, date: string, invoice: string, invoiceSectionDisplayName: string, invoiceSectionId: string, kind: string, orderId: string, orderName: string, productDescription: string, productFamily: string, productType: string, productTypeId: string, quantity: int, subscriptionId: string, subscriptionName: string, transactionAmount: record<currency: string, value: float>, transactionType: string>, id: string, name: string, type: string>
# operationId: Transactions_Get
export def "transactions-get" [
  billing_account_name: string
  billing_profile_name: string
  transaction_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --period-start-date: string # Start date (required)
  --period-end-date: string # End date (required)
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/transactions/{transactionName}"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingProfileName, var: billing_profile_name}, {name: transactionName, var: transaction_name}]
    query: [{name: periodStartDate, var: period_start_date, required: true}, {name: periodEndDate, var: period_end_date, required: true}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_profile_name: $billing_profile_name, transaction_name: $transaction_name, period_start_date: $period_start_date, period_end_date: $period_end_date, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the role assignments on the Billing Account
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingRoleAssignments
# Returns: record<value: table<properties: record, id: string, name: string, type: string>>
# operationId: BillingRoleAssignments_ListByBillingAccount
export def "billing-role-assignments-list-by-billing-account" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingRoleAssignments"
    path_params: [{name: billingAccountName, var: billing_account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the role assignment on this billing account
#
# DELETE /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingRoleAssignments/{billingRoleAssignmentName}
# Returns: record<properties: record<createdByPrincipalId: string, createdByPrincipalTenantId: string, createdOn: string, name: string, principalId: string, roleDefinitionName: string, scope: string>, id: string, name: string, type: string>
# operationId: BillingRoleAssignments_DeleteByBillingAccount
export def "billing-role-assignments-delete-by-billing-account" [
  billing_account_name: string
  billing_role_assignment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingRoleAssignments/{billingRoleAssignmentName}"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingRoleAssignmentName, var: billing_role_assignment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_role_assignment_name: $billing_role_assignment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the role assignment for the caller
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingRoleAssignments/{billingRoleAssignmentName}
# Returns: record<properties: record<createdByPrincipalId: string, createdByPrincipalTenantId: string, createdOn: string, name: string, principalId: string, roleDefinitionName: string, scope: string>, id: string, name: string, type: string>
# operationId: BillingRoleAssignments_GetByBillingAccount
export def "billing-role-assignments-get-by-billing-account" [
  billing_account_name: string
  billing_role_assignment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingRoleAssignments/{billingRoleAssignmentName}"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingRoleAssignmentName, var: billing_role_assignment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_role_assignment_name: $billing_role_assignment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the role definition for a billing account
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingRoleDefinitions
# Returns: record<value: table<properties: record, id: string, name: string, type: string>>
# operationId: BillingRoleDefinitions_ListByBillingAccount
export def "billing-role-definitions-list-by-billing-account" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingRoleDefinitions"
    path_params: [{name: billingAccountName, var: billing_account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the role definition for a role
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingRoleDefinitions/{billingRoleDefinitionName}
# Returns: record<properties: record<description: string, permissions: list<record>, roleName: string>, id: string, name: string, type: string>
# operationId: BillingRoleDefinitions_GetByBillingAccount
export def "billing-role-definitions-get-by-billing-account" [
  billing_account_name: string
  billing_role_definition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingRoleDefinitions/{billingRoleDefinitionName}"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingRoleDefinitionName, var: billing_role_definition_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_role_definition_name: $billing_role_definition_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists billing subscriptions by billing account name.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingSubscriptions
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: BillingSubscriptions_ListByBillingAccount
export def "billing-subscriptions-list-by-billing-account" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingSubscriptions"
    path_params: [{name: billingAccountName, var: billing_account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists invoices by billing subscriptions name.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingSubscriptions/{billingSubscriptionName}/invoices
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: Invoices_ListByBillingSubscription
export def "invoices-list-by-billing-subscription" [
  billing_account_name: string
  billing_subscription_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --period-start-date: string # Invoice period start date. (required)
  --period-end-date: string # Invoice period end date. (required)
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingSubscriptions/{billingSubscriptionName}/invoices"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingSubscriptionName, var: billing_subscription_name}]
    query: [{name: periodStartDate, var: period_start_date, required: true}, {name: periodEndDate, var: period_end_date, required: true}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_subscription_name: $billing_subscription_name, period_start_date: $period_start_date, period_end_date: $period_end_date, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the invoice by name.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingSubscriptions/{billingSubscriptionName}/invoices/{invoiceName}
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# Returns: record<properties: record<amountDue: record<currency: string, value: float>, billedAmount: record<currency: string, value: float>, billingProfileDisplayName: string, billingProfileId: string, documents: list<record>, dueDate: string, invoiceDate: string, invoicePeriodEndDate: string, invoicePeriodStartDate: string, invoiceType: any, payments: list<record>, purchaseOrderNumber: string, status: string>, id: string, name: string, type: string>
# operationId: Invoices_GetById
export def "invoices-get-by-id" [
  billing_account_name: string
  billing_subscription_name: string
  invoice_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingSubscriptions/{billingSubscriptionName}/invoices/{invoiceName}"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: billingSubscriptionName, var: billing_subscription_name}, {name: invoiceName, var: invoice_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, billing_subscription_name: $billing_subscription_name, invoice_name: $invoice_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The operation to add a role assignment to a billing account.
#
# POST /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/createBillingRoleAssignment
# Returns: record<value: table<properties: record, id: string, name: string, type: string>>
# operationId: BillingRoleAssignments_AddByBillingAccount
export def "billing-role-assignments-add-by-billing-account" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --billing-role-definition-id: string # The role definition id
  --principal-id: string # The user's principal id that the role gets assigned to
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/createBillingRoleAssignment"
    path_params: [{name: billingAccountName, var: billing_account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: billingRoleDefinitionId, var: billing_role_definition_id}, {name: principalId, var: principal_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, api_version: $api_version, billing_role_definition_id: $billing_role_definition_id, principal_id: $principal_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists customers which the current user can work with on-behalf of a partner.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/customers
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: Customers_ListByBillingAccount
export def "customers-list-by-billing-account" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --filter: string # May be used to filter the list of customers.
  --skiptoken: string # Skiptoken is only used if a previous operation returned a partial result. If a previous response contains a nextLink element, the value of the nextLink element will include a skiptoken parameter that specifies a starting point to use for subsequent calls.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/customers"
    path_params: [{name: billingAccountName, var: billing_account_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$filter", var: filter}, {name: "$skiptoken", var: skiptoken}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, api_version: $api_version, filter: $filter, skiptoken: $skiptoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a customer by its id.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/customers/{customerName}
# Returns: record<properties: record<displayName: string, enabledAzurePlans: list<record>, resellers: list<record>>, id: string, name: string, type: string>
# operationId: Customers_Get
export def "customers-get" [
  billing_account_name: string
  customer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --expand: string # May be used to expand enabledAzurePlans, resellers.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/customers/{customerName}"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: customerName, var: customer_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$expand", var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, customer_name: $customer_name, api_version: $api_version, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all billing permissions the caller has for a customer.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/customers/{customerName}/billingPermissions
# Returns: record<value: table<actions: list, notActions: list>>
# operationId: BillingPermissions_ListByCustomer
export def "billing-permissions-list-by-customer" [
  billing_account_name: string
  customer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/customers/{customerName}/billingPermissions"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: customerName, var: customer_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, customer_name: $customer_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists billing subscription by customer id.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/customers/{customerName}/billingSubscriptions
# Docs: https://docs.microsoft.com/en-us/rest/api/consumption/
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: BillingSubscriptions_ListByCustomer
export def "billing-subscriptions-list-by-customer" [
  billing_account_name: string
  customer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/customers/{customerName}/billingSubscriptions"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: customerName, var: customer_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, customer_name: $customer_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single billing subscription by id.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/customers/{customerName}/billingSubscriptions/{billingSubscriptionName}
# Docs: https://docs.microsoft.com/en-us/rest/api/consumption/
# Returns: record<properties: record<billingProfileDisplayName: string, billingProfileId: string, customerDisplayName: string, customerId: string, displayName: string, invoiceSectionDisplayName: string, invoiceSectionId: string, lastMonthCharges: record<currency: string, value: float>, monthToDateCharges: record<currency: string, value: float>, reseller: record<description: string, resellerId: string>, skuDescription: string, skuId: string, subscriptionBillingStatus: string, subscriptionId: string>, id: string, name: string, type: string>
# operationId: BillingSubscriptions_GetByCustomer
export def "billing-subscriptions-get-by-customer" [
  billing_account_name: string
  customer_name: string
  billing_subscription_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/customers/{customerName}/billingSubscriptions/{billingSubscriptionName}"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: customerName, var: customer_name}, {name: billingSubscriptionName, var: billing_subscription_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, customer_name: $customer_name, billing_subscription_name: $billing_subscription_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The policy for a given billing account name and customer name.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/customers/{customerName}/policies/default
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# Returns: record<properties: record<viewCharges: string>, id: string, name: string, type: string>
# operationId: Policies_GetByCustomer
export def "policies-get-by-customer" [
  billing_account_name: string
  customer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/customers/{customerName}/policies/default"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: customerName, var: customer_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, customer_name: $customer_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The operation to update a Customer policy.
#
# PUT /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/customers/{customerName}/policies/default
# Returns: record<properties: record<viewCharges: string>, id: string, name: string, type: string>
# operationId: Policies_UpdateCustomer
export def "policies-update-customer" [
  billing_account_name: string
  customer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --properties: any # The properties of a Customer's policy. — shape: {viewCharges?: "Allowed"|"NotAllowed"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/customers/{customerName}/policies/default"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: customerName, var: customer_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, customer_name: $customer_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists products by customer id.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/customers/{customerName}/products
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: Products_ListByCustomer
export def "products-list-by-customer" [
  billing_account_name: string
  customer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --filter: string # May be used to filter by product type. The filter supports 'eq', 'lt', 'gt', 'le', 'ge', and 'and'. It does not currently support 'ne', 'or', or 'not'. Tag filter is a key value pair string where key and value is separated by a colon (:).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/customers/{customerName}/products"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: customerName, var: customer_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, customer_name: $customer_name, api_version: $api_version, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a customer's product by name.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/customers/{customerName}/products/{productName}
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# Returns: record<properties: record<availabilityId: string, billingFrequency: string, billingProfileDisplayName: string, billingProfileId: string, customerDisplayName: string, customerId: string, displayName: string, endDate: string, invoiceSectionDisplayName: string, invoiceSectionId: string, lastCharge: record<currency: string, value: float>, lastChargeDate: string, parentProductId: string, productType: string, productTypeId: string, purchaseDate: string, quantity: float, reseller: record<description: string, resellerId: string>, skuDescription: string, skuId: string, status: string>, id: string, name: string, type: string>
# operationId: Products_GetByCustomer
export def "products-get-by-customer" [
  billing_account_name: string
  customer_name: string
  product_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/customers/{customerName}/products/{productName}"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: customerName, var: customer_name}, {name: productName, var: product_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, customer_name: $customer_name, product_name: $product_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the transactions by customer id for given start date and end date.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/customers/{customerName}/transactions
# Docs: https://docs.microsoft.com/en-us/rest/api/consumption/
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: Transactions_ListByCustomer
export def "transactions-list-by-customer" [
  billing_account_name: string
  customer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --period-start-date: string # Start date (required)
  --period-end-date: string # End date (required)
  --filter: string # May be used to filter by transaction kind. The filter supports 'eq', 'lt', 'gt', 'le', 'ge', and 'and'. It does not currently support 'ne', 'or', or 'not'. Tag filter is a key value pair string where key and value is separated by a colon (:).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/customers/{customerName}/transactions"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: customerName, var: customer_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: periodStartDate, var: period_start_date, required: true}, {name: periodEndDate, var: period_end_date, required: true}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, customer_name: $customer_name, api_version: $api_version, period_start_date: $period_start_date, period_end_date: $period_end_date, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all departments for a user which he has access to.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/departments
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: Departments_ListByBillingAccountName
export def "departments-list-by-billing-account-name" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --expand: string # May be used to expand the enrollmentAccounts.
  --filter: string # The filter supports 'eq', 'lt', 'gt', 'le', 'ge', and 'and'. It does not currently support 'ne', 'or', or 'not'. Tag filter is a key value pair string where key and value is separated by a colon (:).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/departments"
    path_params: [{name: billingAccountName, var: billing_account_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$expand", var: expand}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, api_version: $api_version, expand: $expand, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the department by id.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/departments/{departmentName}
# Returns: record<properties: record<costCenter: string, departmentName: string, enrollmentAccounts: list<record>, status: string>, id: string, name: string, type: string>
# operationId: Departments_Get
export def "departments-get" [
  billing_account_name: string
  department_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --expand: string # May be used to expand the enrollmentAccounts.
  --filter: string # The filter supports 'eq', 'lt', 'gt', 'le', 'ge', and 'and'. It does not currently support 'ne', 'or', or 'not'. Tag filter is a key value pair string where key and value is separated by a colon (:).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/departments/{departmentName}"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: departmentName, var: department_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$expand", var: expand}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, department_name: $department_name, api_version: $api_version, expand: $expand, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all Enrollment Accounts for a user which he has access to.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/enrollmentAccounts
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: EnrollmentAccounts_ListByBillingAccountName
export def "enrollment-accounts-list-by-billing-account-name" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --expand: string # May be used to expand the department.
  --filter: string # The filter supports 'eq', 'lt', 'gt', 'le', 'ge', and 'and'. It does not currently support 'ne', 'or', or 'not'. Tag filter is a key value pair string where key and value is separated by a colon (:).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/enrollmentAccounts"
    path_params: [{name: billingAccountName, var: billing_account_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$expand", var: expand}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, api_version: $api_version, expand: $expand, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the enrollment account by id.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/enrollmentAccounts/{enrollmentAccountName}
# Returns: record<properties: record<accountName: string, accountOwner: string, costCenter: string, department: record<properties: record, id: string, name: string, type: string>, endDate: string, startDate: string, status: string>, id: string, name: string, type: string>
# operationId: EnrollmentAccounts_GetByEnrollmentAccountId
export def "enrollment-accounts-get-by-enrollment-account-id" [
  billing_account_name: string
  enrollment_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --expand: string # May be used to expand the Department.
  --filter: string # The filter supports 'eq', 'lt', 'gt', 'le', 'ge', and 'and'. It does not currently support 'ne', 'or', or 'not'. Tag filter is a key value pair string where key and value is separated by a colon (:).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/enrollmentAccounts/{enrollmentAccountName}"
    path_params: [{name: billingAccountName, var: billing_account_name}, {name: enrollmentAccountName, var: enrollment_account_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$expand", var: expand}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, enrollment_account_name: $enrollment_account_name, api_version: $api_version, expand: $expand, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of invoices for a billing account.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/invoices
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: Invoices_ListByBillingAccount
export def "invoices-list-by-billing-account" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --period-start-date: string # Invoice period start date. (required)
  --period-end-date: string # Invoice period end date. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/invoices"
    path_params: [{name: billingAccountName, var: billing_account_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: periodStartDate, var: period_start_date, required: true}, {name: periodEndDate, var: period_end_date, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, api_version: $api_version, period_start_date: $period_start_date, period_end_date: $period_end_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all invoice sections with create subscription permission for a user.
#
# POST /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/listInvoiceSectionsWithCreateSubscriptionPermission
# Returns: record<nextLink: string, value: table<billingProfileDisplayName: string, billingProfileId: string, enabledAzurePlans: list, invoiceSectionDisplayName: string, invoiceSectionId: string>>
# operationId: BillingAccounts_ListInvoiceSectionsByCreateSubscriptionPermission
export def "billing-accounts-list-invoice-sections-by-create-subscription-permission" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/listInvoiceSectionsWithCreateSubscriptionPermission"
    path_params: [{name: billingAccountName, var: billing_account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the Payment Methods by billing account Id.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/paymentMethods
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/2019-10-01-preview/paymentmethods
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: PaymentMethods_ListByBillingAccount
export def "payment-methods-list-by-billing-account" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/paymentMethods"
    path_params: [{name: billingAccountName, var: billing_account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists products by billing account name.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/products
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: Products_ListByBillingAccount
export def "products-list-by-billing-account" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --filter: string # May be used to filter by product type. The filter supports 'eq', 'lt', 'gt', 'le', 'ge', and 'and'. It does not currently support 'ne', 'or', or 'not'. Tag filter is a key value pair string where key and value is separated by a colon (:).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/products"
    path_params: [{name: billingAccountName, var: billing_account_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, api_version: $api_version, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the transactions by billing account name for given start and end date.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/transactions
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: Transactions_ListByBillingAccount
export def "transactions-list-by-billing-account" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --period-start-date: string # Start date (required)
  --period-end-date: string # End date (required)
  --filter: string # May be used to filter by transaction kind. The filter supports 'eq', 'lt', 'gt', 'le', 'ge', and 'and'. It does not currently support 'ne', 'or', or 'not'. Tag filter is a key value pair string where key and value is separated by a colon (:).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/billingAccounts/{billingAccountName}/transactions"
    path_params: [{name: billingAccountName, var: billing_account_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: periodStartDate, var: period_start_date, required: true}, {name: periodEndDate, var: period_end_date, required: true}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_account_name: $billing_account_name, api_version: $api_version, period_start_date: $period_start_date, period_end_date: $period_end_date, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the available billing REST API operations.
#
# GET /providers/Microsoft.Billing/operations
# Returns: record<nextLink: string, value: table<display: record, name: string>>
# operationId: Operations_List
export def "operations-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Billing/operations"
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the transfers received by caller.
#
# GET /providers/Microsoft.Billing/transfers
# Returns: record<nextLink: string, value: table<properties: record>>
# operationId: RecipientTransfers_List
export def "recipient-transfers-list" [
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
    path: "/providers/Microsoft.Billing/transfers"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the transfer with given transfer Id.
#
# GET /providers/Microsoft.Billing/transfers/{transferName}
# Returns: record<properties: record<allowedProductType: list<string>, canceledBy: string, creationTime: string, detailedTransferStatus: list<record>, expirationTime: string, initiatorCustomerType: string, initiatorEmailId: string, lastModifiedTime: string, recipientEmailId: string, resellerId: string, resellerName: string, transferStatus: string>>
# operationId: RecipientTransfers_Get
export def "recipient-transfers-get" [
  transfer_name: string
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
    path: "/providers/Microsoft.Billing/transfers/{transferName}"
    path_params: [{name: transferName, var: transfer_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    transfer_name: $transfer_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accepts the transfer with given transfer Id.
#
# POST /providers/Microsoft.Billing/transfers/{transferName}/acceptTransfer
# Returns: record<properties: record<allowedProductType: list<string>, canceledBy: string, creationTime: string, detailedTransferStatus: list<record>, expirationTime: string, initiatorCustomerType: string, initiatorEmailId: string, lastModifiedTime: string, recipientEmailId: string, resellerId: string, resellerName: string, transferStatus: string>>
# operationId: RecipientTransfers_Accept
export def "recipient-transfers-accept" [
  transfer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --properties: record # Request parameters to accept transfer. — shape: {productDetails?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/providers/Microsoft.Billing/transfers/{transferName}/acceptTransfer"
    path_params: [{name: transferName, var: transfer_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    transfer_name: $transfer_name, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Declines the transfer with given transfer Id.
#
# POST /providers/Microsoft.Billing/transfers/{transferName}/declineTransfer
# Returns: record<properties: record<allowedProductType: list<string>, canceledBy: string, creationTime: string, detailedTransferStatus: list<record>, expirationTime: string, initiatorCustomerType: string, initiatorEmailId: string, lastModifiedTime: string, recipientEmailId: string, resellerId: string, resellerName: string, transferStatus: string>>
# operationId: RecipientTransfers_Decline
export def "recipient-transfers-decline" [
  transfer_name: string
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
    path: "/providers/Microsoft.Billing/transfers/{transferName}/declineTransfer"
    path_params: [{name: transferName, var: transfer_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    transfer_name: $transfer_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validates if the products can be transferred in the context of the given transfer name.
#
# POST /providers/Microsoft.Billing/transfers/{transferName}/validateTransfer
# Returns: record<value: table<properties: record>>
# operationId: RecipientTransfers_Validate
export def "recipient-transfers-validate" [
  transfer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --properties: record # Request parameters to accept transfer. — shape: {productDetails?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/providers/Microsoft.Billing/transfers/{transferName}/validateTransfer"
    path_params: [{name: transferName, var: transfer_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    transfer_name: $transfer_name, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validates the address.
#
# POST /providers/Microsoft.Billing/validateAddress
# Returns: record<status: string, suggestedAddresses: table<addressLine1: string, addressLine2: string, addressLine3: string, city: string, companyName: string, country: string, firstName: string, lastName: string, postalCode: string, region: string>, validationMessage: string>
# operationId: Address_Validate
export def "address-validate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --address-line1: string # Address Line1.
  --address-line2: string # Address Line2.
  --address-line3: string # Address Line3.
  --city: string # Address City.
  --company-name: string # Company Name.
  --country: string # Country code uses ISO2, 2-digit format.
  --first-name: string # First Name.
  --last-name: string # Last Name.
  --postal-code: string # Address Postal Code.
  --region: string # Address Region.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/providers/Microsoft.Billing/validateAddress"
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: addressLine1, var: address_line1}, {name: addressLine2, var: address_line2}, {name: addressLine3, var: address_line3}, {name: city, var: city}, {name: companyName, var: company_name}, {name: country, var: country}, {name: firstName, var: first_name}, {name: lastName, var: last_name}, {name: postalCode, var: postal_code}, {name: region, var: region}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, address_line1: $address_line1, address_line2: $address_line2, address_line3: $address_line3, city: $city, company_name: $company_name, country: $country, first_name: $first_name, last_name: $last_name, postal_code: $postal_code, region: $region
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the current line of credit.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Billing/billingAccounts/default/lineOfCredit/default
# Returns: record<properties: record<creditLimit: record<currency: string, value: float>, reason: string, remainingBalance: record<currency: string, value: float>, status: string>, id: string, name: string, type: string>
# operationId: LineOfCredits_Get
export def "line-of-credits-get" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Billing/billingAccounts/default/lineOfCredit/default"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Increase the current line of credit.
#
# PUT /subscriptions/{subscriptionId}/providers/Microsoft.Billing/billingAccounts/default/lineOfCredit/default
# Returns: record<properties: record<creditLimit: record<currency: string, value: float>, reason: string, remainingBalance: record<currency: string, value: float>, status: string>, id: string, name: string, type: string>
# operationId: LineOfCredits_Update
export def "line-of-credits-update" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
  --properties: any # The properties of the line of credit. — shape: {creditLimit?: any, remainingBalance?: any, status?: "Approved"|"Rejected"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Billing/billingAccounts/default/lineOfCredit/default"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get billing property by subscription Id.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Billing/billingProperty/default
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# Returns: record<properties: record<billingAccountDisplayName: string, billingAccountId: string, billingProfileDisplayName: string, billingProfileId: string, billingTenantId: string, costCenter: string, invoiceSectionDisplayName: string, invoiceSectionId: string, productId: string, productName: string, skuDescription: string, skuId: string>, id: string, name: string, type: string>
# operationId: BillingProperty_Get
export def "billing-property-get" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Billing/billingProperty/default"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
