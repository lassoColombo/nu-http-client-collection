# Auto-generated client for Cloud Private Catalog Producer v1beta1
# Source: https://api.apis.guru/v2/specs/googleapis.com/cloudprivatecatalogproducer/v1beta1/openapi.json
# Auth: --token flag or $env.CLOUD_PRIVATE_CATALOG_PRODUCER_TOKEN

const CLIENT = {
  base_url: "https://cloudprivatecatalogproducer.googleapis.com"
  token_env_var: "CLOUD_PRIVATE_CATALOG_PRODUCER_TOKEN"
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

def base-url-completer [] { ["https://cloudprivatecatalogproducer.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def alt-completer [] { ["json" "media" "proto"] }
def xgafv-completer [] { ["1" "2"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    cloudprivatecatalogproducer-catalogs-list: "record<catalogs: table<createTime: string, description: string, displayName: string, name: string, parent: string, updateTime: string>, nextPageToken: string>"
    cloudprivatecatalogproducer-catalogs-create: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    cloudprivatecatalogproducer-operations-list: "record<nextPageToken: string, operations: table<done: bool, error: record, metadata: record, name: string, response: record>>"
    cloudprivatecatalogproducer-catalogs-products-versions-delete: "record"
    cloudprivatecatalogproducer-catalogs-products-versions-get: "record<asset: record, createTime: string, description: string, name: string, originalAsset: record, updateTime: string>"
    cloudprivatecatalogproducer-catalogs-products-versions-patch: "record<asset: record, createTime: string, description: string, name: string, originalAsset: record, updateTime: string>"
    cloudprivatecatalogproducer-operations-cancel: "record"
    cloudprivatecatalogproducer-catalogs-products-copy: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    cloudprivatecatalogproducer-catalogs-undelete: "record<createTime: string, description: string, displayName: string, name: string, parent: string, updateTime: string>"
    cloudprivatecatalogproducer-catalogs-associations-list: "record<associations: table<createTime: string, name: string, resource: string>, nextPageToken: string>"
    cloudprivatecatalogproducer-catalogs-associations-create: "record<createTime: string, name: string, resource: string>"
    cloudprivatecatalogproducer-catalogs-products-list: "record<nextPageToken: string, products: table<assetType: string, createTime: string, displayMetadata: record, iconUri: string, name: string, updateTime: string>>"
    cloudprivatecatalogproducer-catalogs-products-create: "record<assetType: string, createTime: string, displayMetadata: record, iconUri: string, name: string, updateTime: string>"
    cloudprivatecatalogproducer-catalogs-products-versions-list: "record<nextPageToken: string, versions: table<asset: record, createTime: string, description: string, name: string, originalAsset: record, updateTime: string>>"
    cloudprivatecatalogproducer-catalogs-products-versions-create: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    cloudprivatecatalogproducer-catalogs-products-icons-upload: "record"
    cloudprivatecatalogproducer-catalogs-get-iam-policy: "record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int>"
    cloudprivatecatalogproducer-catalogs-set-iam-policy: "record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int>"
    cloudprivatecatalogproducer-catalogs-test-iam-permissions: "record<permissions: list<string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["cloudprivatecatalogproducer-catalogs-list" "cloudprivatecatalogproducer-catalogs-create" "cloudprivatecatalogproducer-operations-list" "cloudprivatecatalogproducer-catalogs-products-versions-delete" "cloudprivatecatalogproducer-catalogs-products-versions-get" "cloudprivatecatalogproducer-catalogs-products-versions-patch" "cloudprivatecatalogproducer-operations-cancel" "cloudprivatecatalogproducer-catalogs-products-copy" "cloudprivatecatalogproducer-catalogs-undelete" "cloudprivatecatalogproducer-catalogs-associations-list" "cloudprivatecatalogproducer-catalogs-associations-create" "cloudprivatecatalogproducer-catalogs-products-list" "cloudprivatecatalogproducer-catalogs-products-create" "cloudprivatecatalogproducer-catalogs-products-versions-list" "cloudprivatecatalogproducer-catalogs-products-versions-create" "cloudprivatecatalogproducer-catalogs-products-icons-upload" "cloudprivatecatalogproducer-catalogs-get-iam-policy" "cloudprivatecatalogproducer-catalogs-set-iam-policy" "cloudprivatecatalogproducer-catalogs-test-iam-permissions" "commands"] | sort) } | get name | first)
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

# Lists Catalog resources that the producer has access to, within the scope of the parent resource.
#
# GET /v1beta1/catalogs
# Returns: record<catalogs: table<createTime: string, description: string, displayName: string, name: string, parent: string, updateTime: string>, nextPageToken: string>
# operationId: cloudprivatecatalogproducer.catalogs.list
export def "cloudprivatecatalogproducer-catalogs-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --page-size: int # The maximum number of catalogs to return.
  --page-token: string # A pagination token returned from a previous call to ListCatalogs that indicates where this listing should continue from. This field is optional.
  --parent: string # The resource name of the parent resource.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/catalogs"
    query: [{name: alt, var: alt}, {name: key, var: key}, {name: access_token, var: access_token}, {name: upload_protocol, var: upload_protocol}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: "$.xgafv", var: xgafv}, {name: oauth_token, var: oauth_token}, {name: callback, var: callback}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: parent, var: parent}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, key: $key, access_token: $access_token, upload_protocol: $upload_protocol, pretty_print: $pretty_print, quota_user: $quota_user, fields: $fields, upload_type: $upload_type, xgafv: $xgafv, oauth_token: $oauth_token, callback: $callback, page_size: $page_size, page_token: $page_token, parent: $parent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Catalog resource.
#
# POST /v1beta1/catalogs
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: cloudprivatecatalogproducer.catalogs.create
export def "cloudprivatecatalogproducer-catalogs-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --create-time: string # Output only. The time when the catalog was created. (format: google-datetime)
  --description: string # Required. The user-supplied description of the catalog. Maximum of 512 characters.
  --display-name: string # Required. The user-supplied descriptive name of the catalog as it appears in UIs. Maximum 256 characters in length.
  --name: string # Output only. The resource name of the catalog, in the format `catalogs/{catalog_id}'. A unique identifier for the catalog, which is generated by catalog service.
  --parent: string # Required. The parent resource name of the catalog, which can't be changed after a catalog is created. It can only be an organization. Values are of the form `//cloudresourcemanager.googleapis.com/organizations/`. Maximum 256 characters in length.
  --update-time: string # Output only. The time when the catalog was last updated. (format: google-datetime)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/catalogs"
    query: [{name: alt, var: alt}, {name: key, var: key}, {name: access_token, var: access_token}, {name: upload_protocol, var: upload_protocol}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: "$.xgafv", var: xgafv}, {name: oauth_token, var: oauth_token}, {name: callback, var: callback}]
    body: {content_type: "application/json", kind: json, fields: [{name: createTime, var: create_time}, {name: description, var: description}, {name: displayName, var: display_name}, {name: name, var: name}, {name: parent, var: parent}, {name: updateTime, var: update_time}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, key: $key, access_token: $access_token, upload_protocol: $upload_protocol, pretty_print: $pretty_print, quota_user: $quota_user, fields: $fields, upload_type: $upload_type, xgafv: $xgafv, oauth_token: $oauth_token, callback: $callback, create_time: $create_time, description: $description, display_name: $display_name, name: $name, parent: $parent, update_time: $update_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists operations that match the specified filter in the request. If the server doesn't support this method, it returns `UNIMPLEMENTED`. NOTE: the `name` binding allows API services to override the binding to use different resource name schemes, such as `users/*/operations`. To override the binding, API services can add a binding such as `"/v1/{name=users/*}/operations"` to their service configuration. For backwards compatibility, the default name includes the operations collection id, however overriding users must ensure the name binding is the parent resource, without the operations collection id.
#
# GET /v1beta1/operations
# Returns: record<nextPageToken: string, operations: table<done: bool, error: record, metadata: record, name: string, response: record>>
# operationId: cloudprivatecatalogproducer.operations.list
export def "cloudprivatecatalogproducer-operations-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --filter: string # The standard list filter.
  --name: string # The name of the operation's parent resource.
  --page-size: int # The standard list page size.
  --page-token: string # The standard list page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/operations"
    query: [{name: alt, var: alt}, {name: key, var: key}, {name: access_token, var: access_token}, {name: upload_protocol, var: upload_protocol}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: "$.xgafv", var: xgafv}, {name: oauth_token, var: oauth_token}, {name: callback, var: callback}, {name: filter, var: filter}, {name: name, var: name}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, key: $key, access_token: $access_token, upload_protocol: $upload_protocol, pretty_print: $pretty_print, quota_user: $quota_user, fields: $fields, upload_type: $upload_type, xgafv: $xgafv, oauth_token: $oauth_token, callback: $callback, filter: $filter, name: $name, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Hard deletes a Version.
#
# DELETE /v1beta1/{name}
# Returns: record
# operationId: cloudprivatecatalogproducer.catalogs.products.versions.delete
export def "cloudprivatecatalogproducer-catalogs-products-versions-delete" [
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
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --force: oneof<nothing, bool> # Forces deletion of the `Catalog` and its `Association` resources. If the `Catalog` is still associated with other resources and force is not set to true, then the operation fails.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1beta1/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: alt, var: alt}, {name: key, var: key}, {name: access_token, var: access_token}, {name: upload_protocol, var: upload_protocol}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: "$.xgafv", var: xgafv}, {name: oauth_token, var: oauth_token}, {name: callback, var: callback}, {name: force, var: force}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    name: $name, alt: $alt, key: $key, access_token: $access_token, upload_protocol: $upload_protocol, pretty_print: $pretty_print, quota_user: $quota_user, fields: $fields, upload_type: $upload_type, xgafv: $xgafv, oauth_token: $oauth_token, callback: $callback, force: $force
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the requested Version resource.
#
# GET /v1beta1/{name}
# Returns: record<asset: record, createTime: string, description: string, name: string, originalAsset: record, updateTime: string>
# operationId: cloudprivatecatalogproducer.catalogs.products.versions.get
export def "cloudprivatecatalogproducer-catalogs-products-versions-get" [
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
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: alt, var: alt}, {name: key, var: key}, {name: access_token, var: access_token}, {name: upload_protocol, var: upload_protocol}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: "$.xgafv", var: xgafv}, {name: oauth_token, var: oauth_token}, {name: callback, var: callback}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    name: $name, alt: $alt, key: $key, access_token: $access_token, upload_protocol: $upload_protocol, pretty_print: $pretty_print, quota_user: $quota_user, fields: $fields, upload_type: $upload_type, xgafv: $xgafv, oauth_token: $oauth_token, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a specific Version resource.
#
# PATCH /v1beta1/{name}
# Returns: record<asset: record, createTime: string, description: string, name: string, originalAsset: record, updateTime: string>
# operationId: cloudprivatecatalogproducer.catalogs.products.versions.patch
export def "cloudprivatecatalogproducer-catalogs-products-versions-patch" [
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
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --update-mask: string # Field mask that controls which fields of the version should be updated.
  --asset: record # Output only. The asset which has been validated and is ready to be provisioned. See Version.original_asset for the schema.
  --create-time: string # Output only. The time when the version was created. (format: google-datetime)
  --description: string # The user-supplied description of the version. Maximum of 256 characters.
  --body-name: string # Required. The resource name of the version, in the format `catalogs/{catalog_id}/products/{product_id}/versions/a-z*[a-z0-9]'. A unique identifier for the version under a product, which can't be changed after the version is created. The final segment of the name must between 1 and 63 characters in length. (spec name: name)
  --original-asset: record # The user-supplied asset payload. The maximum size of the payload is 2MB. The JSON schema of the payload is defined as: ``` type: object properties: mainTemplate: type: string description: The file name of the main template and name prefix of schema file. The content of the main template should be set in the imports list. The schema file name is expected to be .schema in the imports list. required: true imports: type: array description: Import template and schema file contents. Required to have both and .schema files. required: true minItems: 2 items: type: object properties: name: type: string content: type: string ```
  --update-time: string # Output only. The time when the version was last updated. (format: google-datetime)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1beta1/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: alt, var: alt}, {name: key, var: key}, {name: access_token, var: access_token}, {name: upload_protocol, var: upload_protocol}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: "$.xgafv", var: xgafv}, {name: oauth_token, var: oauth_token}, {name: callback, var: callback}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: asset, var: asset}, {name: createTime, var: create_time}, {name: description, var: description}, {name: name, var: body_name}, {name: originalAsset, var: original_asset}, {name: updateTime, var: update_time}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    name: $name, alt: $alt, key: $key, access_token: $access_token, upload_protocol: $upload_protocol, pretty_print: $pretty_print, quota_user: $quota_user, fields: $fields, upload_type: $upload_type, xgafv: $xgafv, oauth_token: $oauth_token, callback: $callback, update_mask: $update_mask, asset: $asset, create_time: $create_time, description: $description, body_name: $body_name, original_asset: $original_asset, update_time: $update_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts asynchronous cancellation on a long-running operation. The server makes a best effort to cancel the operation, but success is not guaranteed. If the server doesn't support this method, it returns `google.rpc.Code.UNIMPLEMENTED`. Clients can use Operations.GetOperation or other methods to check whether the cancellation succeeded or whether the operation completed despite cancellation. On successful cancellation, the operation is not deleted; instead, it becomes an operation with an Operation.error value with a google.rpc.Status.code of 1, corresponding to `Code.CANCELLED`.
#
# POST /v1beta1/{name}:cancel
# Returns: record
# operationId: cloudprivatecatalogproducer.operations.cancel
export def "cloudprivatecatalogproducer-operations-cancel" [
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
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:cancel"
    path_params: [{name: name, var: name}]
    query: [{name: alt, var: alt}, {name: key, var: key}, {name: access_token, var: access_token}, {name: upload_protocol, var: upload_protocol}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: "$.xgafv", var: xgafv}, {name: oauth_token, var: oauth_token}, {name: callback, var: callback}]
    body: {content_type: "application/json", kind: json}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    name: $name, alt: $alt, key: $key, access_token: $access_token, upload_protocol: $upload_protocol, pretty_print: $pretty_print, quota_user: $quota_user, fields: $fields, upload_type: $upload_type, xgafv: $xgafv, oauth_token: $oauth_token, callback: $callback, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Copies a Product under another Catalog.
#
# POST /v1beta1/{name}:copy
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: cloudprivatecatalogproducer.catalogs.products.copy
export def "cloudprivatecatalogproducer-catalogs-products-copy" [
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
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --destination-product-name: string # The resource name of the destination product that is copied to.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:copy"
    path_params: [{name: name, var: name}]
    query: [{name: alt, var: alt}, {name: key, var: key}, {name: access_token, var: access_token}, {name: upload_protocol, var: upload_protocol}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: "$.xgafv", var: xgafv}, {name: oauth_token, var: oauth_token}, {name: callback, var: callback}]
    body: {content_type: "application/json", kind: json, fields: [{name: destinationProductName, var: destination_product_name}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    name: $name, alt: $alt, key: $key, access_token: $access_token, upload_protocol: $upload_protocol, pretty_print: $pretty_print, quota_user: $quota_user, fields: $fields, upload_type: $upload_type, xgafv: $xgafv, oauth_token: $oauth_token, callback: $callback, destination_product_name: $destination_product_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Undeletes a deleted Catalog and all resources under it.
#
# POST /v1beta1/{name}:undelete
# Returns: record<createTime: string, description: string, displayName: string, name: string, parent: string, updateTime: string>
# operationId: cloudprivatecatalogproducer.catalogs.undelete
export def "cloudprivatecatalogproducer-catalogs-undelete" [
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
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:undelete"
    path_params: [{name: name, var: name}]
    query: [{name: alt, var: alt}, {name: key, var: key}, {name: access_token, var: access_token}, {name: upload_protocol, var: upload_protocol}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: "$.xgafv", var: xgafv}, {name: oauth_token, var: oauth_token}, {name: callback, var: callback}]
    body: {content_type: "application/json", kind: json}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    name: $name, alt: $alt, key: $key, access_token: $access_token, upload_protocol: $upload_protocol, pretty_print: $pretty_print, quota_user: $quota_user, fields: $fields, upload_type: $upload_type, xgafv: $xgafv, oauth_token: $oauth_token, callback: $callback, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all Association resources under a catalog.
#
# GET /v1beta1/{parent}/associations
# Returns: record<associations: table<createTime: string, name: string, resource: string>, nextPageToken: string>
# operationId: cloudprivatecatalogproducer.catalogs.associations.list
export def "cloudprivatecatalogproducer-catalogs-associations-list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --page-size: int # The maximum number of catalog associations to return.
  --page-token: string # A pagination token returned from the previous call to `ListAssociations`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/associations"
    path_params: [{name: parent, var: parent}]
    query: [{name: alt, var: alt}, {name: key, var: key}, {name: access_token, var: access_token}, {name: upload_protocol, var: upload_protocol}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: "$.xgafv", var: xgafv}, {name: oauth_token, var: oauth_token}, {name: callback, var: callback}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, alt: $alt, key: $key, access_token: $access_token, upload_protocol: $upload_protocol, pretty_print: $pretty_print, quota_user: $quota_user, fields: $fields, upload_type: $upload_type, xgafv: $xgafv, oauth_token: $oauth_token, callback: $callback, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Association instance under a given Catalog.
#
# POST /v1beta1/{parent}/associations
# Returns: record<createTime: string, name: string, resource: string>
# operationId: cloudprivatecatalogproducer.catalogs.associations.create
export def "cloudprivatecatalogproducer-catalogs-associations-create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --association: record # An association tuple that pairs a `Catalog` to a resource that can use the `Catalog`. After association, a google.cloud.privatecatalog.v1beta1.Catalog becomes available to consumers under specified Association.resource and all of its child nodes. Users who have the `cloudprivatecatalog.targets.get` permission on any of the resource nodes can access the catalog and child products under the node. For example, suppose the cloud resource hierarchy is as follows: * organizations/example.com * folders/team * projects/test After creating an association with `organizations/example.com`, the catalog `catalogs/1` is accessible from the following paths: * organizations/example.com * folders/team * projects/test Users can access them by google.cloud.v1beta1.PrivateCatalog.SearchCatalogs action. — shape: {createTime?: string, name?: string, resource?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{parent}/associations"
    path_params: [{name: parent, var: parent}]
    query: [{name: alt, var: alt}, {name: key, var: key}, {name: access_token, var: access_token}, {name: upload_protocol, var: upload_protocol}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: "$.xgafv", var: xgafv}, {name: oauth_token, var: oauth_token}, {name: callback, var: callback}]
    body: {content_type: "application/json", kind: json, fields: [{name: association, var: association}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, alt: $alt, key: $key, access_token: $access_token, upload_protocol: $upload_protocol, pretty_print: $pretty_print, quota_user: $quota_user, fields: $fields, upload_type: $upload_type, xgafv: $xgafv, oauth_token: $oauth_token, callback: $callback, association: $association
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists Product resources that the producer has access to, within the scope of the parent catalog.
#
# GET /v1beta1/{parent}/products
# Returns: record<nextPageToken: string, products: table<assetType: string, createTime: string, displayMetadata: record, iconUri: string, name: string, updateTime: string>>
# operationId: cloudprivatecatalogproducer.catalogs.products.list
export def "cloudprivatecatalogproducer-catalogs-products-list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --filter: string # A filter expression used to restrict the returned results based upon properties of the product.
  --page-size: int # The maximum number of products to return.
  --page-token: string # A pagination token returned from a previous call to ListProducts that indicates where this listing should continue from. This field is optional.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/products"
    path_params: [{name: parent, var: parent}]
    query: [{name: alt, var: alt}, {name: key, var: key}, {name: access_token, var: access_token}, {name: upload_protocol, var: upload_protocol}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: "$.xgafv", var: xgafv}, {name: oauth_token, var: oauth_token}, {name: callback, var: callback}, {name: filter, var: filter}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, alt: $alt, key: $key, access_token: $access_token, upload_protocol: $upload_protocol, pretty_print: $pretty_print, quota_user: $quota_user, fields: $fields, upload_type: $upload_type, xgafv: $xgafv, oauth_token: $oauth_token, callback: $callback, filter: $filter, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Product instance under a given Catalog.
#
# POST /v1beta1/{parent}/products
# Returns: record<assetType: string, createTime: string, displayMetadata: record, iconUri: string, name: string, updateTime: string>
# operationId: cloudprivatecatalogproducer.catalogs.products.create
export def "cloudprivatecatalogproducer-catalogs-products-create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --asset-type: string # Required. The type of the product asset, which cannot be changed after the product is created. It supports the values `google.deploymentmanager.Template` and `google.cloudprivatecatalog.ListingOnly`. Other values will be rejected by the server. Read only after creation. The following fields or resource types have different validation rules under each `asset_type` values: * Product.display_metadata has different validation schema for each asset type value. See its comment for details. * Version resource isn't allowed to be added under the `google.cloudprivatecatalog.ListingOnly` type.
  --create-time: string # Output only. The time when the product was created. (format: google-datetime)
  --display-metadata: record # The user-supplied display metadata to describe the product. The JSON schema of the metadata differs by Product.asset_type. When the type is `google.deploymentmanager.Template`, the schema is as follows: ``` "$schema": http://json-schema.org/draft-04/schema# type: object properties: name: type: string minLength: 1 maxLength: 64 description: type: string minLength: 1 maxLength: 2048 tagline: type: string minLength: 1 maxLength: 100 support_info: type: string minLength: 1 maxLength: 2048 creator: type: string minLength: 1 maxLength: 100 documentation: type: array items: type: object properties: url: type: string pattern: "^(https?)://[-a-zA-Z0-9+&@#/%?=~_|!:,.;]*[-a-zA-Z0-9+&@#/%=~_|]" title: type: string minLength: 1 maxLength: 64 description: type: string minLength: 1 maxLength: 2048 required: - name - description additionalProperties: false ``` When the asset type is `google.cloudprivatecatalog.ListingOnly`, the schema is as follows: ``` "$schema": http://json-schema.org/draft-04/schema# type: object properties: name: type: string minLength: 1 maxLength: 64 description: type: string minLength: 1 maxLength: 2048 tagline: type: string minLength: 1 maxLength: 100 support_info: type: string minLength: 1 maxLength: 2048 creator: type: string minLength: 1 maxLength: 100 documentation: type: array items: type: object properties: url: type: string pattern: "^(https?)://[-a-zA-Z0-9+&@#/%?=~_|!:,.;]*[-a-zA-Z0-9+&@#/%=~_|]" title: type: string minLength: 1 maxLength: 64 description: type: string minLength: 1 maxLength: 2048 signup_url: type: string pattern: "^(https?)://[-a-zA-Z0-9+&@#/%?=~_|!:,.;]*[-a-zA-Z0-9+&@#/%=~_|]" required: - name - description - signup_url additionalProperties: false ```
  --icon-uri: string # Output only. The public accessible URI of the icon uploaded by PrivateCatalogProducer.UploadIcon. If no icon is uploaded, it will be the default icon's URI.
  --name: string # Required. The resource name of the product in the format `catalogs/{catalog_id}/products/a-z*[a-z0-9]'. A unique identifier for the product under a catalog, which cannot be changed after the product is created. The final segment of the name must between 1 and 256 characters in length.
  --update-time: string # Output only. The time when the product was last updated. (format: google-datetime)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{parent}/products"
    path_params: [{name: parent, var: parent}]
    query: [{name: alt, var: alt}, {name: key, var: key}, {name: access_token, var: access_token}, {name: upload_protocol, var: upload_protocol}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: "$.xgafv", var: xgafv}, {name: oauth_token, var: oauth_token}, {name: callback, var: callback}]
    body: {content_type: "application/json", kind: json, fields: [{name: assetType, var: asset_type}, {name: createTime, var: create_time}, {name: displayMetadata, var: display_metadata}, {name: iconUri, var: icon_uri}, {name: name, var: name}, {name: updateTime, var: update_time}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, alt: $alt, key: $key, access_token: $access_token, upload_protocol: $upload_protocol, pretty_print: $pretty_print, quota_user: $quota_user, fields: $fields, upload_type: $upload_type, xgafv: $xgafv, oauth_token: $oauth_token, callback: $callback, asset_type: $asset_type, create_time: $create_time, display_metadata: $display_metadata, icon_uri: $icon_uri, name: $name, update_time: $update_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists Version resources that the producer has access to, within the scope of the parent Product.
#
# GET /v1beta1/{parent}/versions
# Returns: record<nextPageToken: string, versions: table<asset: record, createTime: string, description: string, name: string, originalAsset: record, updateTime: string>>
# operationId: cloudprivatecatalogproducer.catalogs.products.versions.list
export def "cloudprivatecatalogproducer-catalogs-products-versions-list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --page-size: int # The maximum number of versions to return.
  --page-token: string # A pagination token returned from a previous call to ListVersions that indicates where this listing should continue from. This field is optional.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/versions"
    path_params: [{name: parent, var: parent}]
    query: [{name: alt, var: alt}, {name: key, var: key}, {name: access_token, var: access_token}, {name: upload_protocol, var: upload_protocol}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: "$.xgafv", var: xgafv}, {name: oauth_token, var: oauth_token}, {name: callback, var: callback}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, alt: $alt, key: $key, access_token: $access_token, upload_protocol: $upload_protocol, pretty_print: $pretty_print, quota_user: $quota_user, fields: $fields, upload_type: $upload_type, xgafv: $xgafv, oauth_token: $oauth_token, callback: $callback, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Version instance under a given Product.
#
# POST /v1beta1/{parent}/versions
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: cloudprivatecatalogproducer.catalogs.products.versions.create
export def "cloudprivatecatalogproducer-catalogs-products-versions-create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --asset: record # Output only. The asset which has been validated and is ready to be provisioned. See Version.original_asset for the schema.
  --create-time: string # Output only. The time when the version was created. (format: google-datetime)
  --description: string # The user-supplied description of the version. Maximum of 256 characters.
  --name: string # Required. The resource name of the version, in the format `catalogs/{catalog_id}/products/{product_id}/versions/a-z*[a-z0-9]'. A unique identifier for the version under a product, which can't be changed after the version is created. The final segment of the name must between 1 and 63 characters in length.
  --original-asset: record # The user-supplied asset payload. The maximum size of the payload is 2MB. The JSON schema of the payload is defined as: ``` type: object properties: mainTemplate: type: string description: The file name of the main template and name prefix of schema file. The content of the main template should be set in the imports list. The schema file name is expected to be .schema in the imports list. required: true imports: type: array description: Import template and schema file contents. Required to have both and .schema files. required: true minItems: 2 items: type: object properties: name: type: string content: type: string ```
  --update-time: string # Output only. The time when the version was last updated. (format: google-datetime)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{parent}/versions"
    path_params: [{name: parent, var: parent}]
    query: [{name: alt, var: alt}, {name: key, var: key}, {name: access_token, var: access_token}, {name: upload_protocol, var: upload_protocol}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: "$.xgafv", var: xgafv}, {name: oauth_token, var: oauth_token}, {name: callback, var: callback}]
    body: {content_type: "application/json", kind: json, fields: [{name: asset, var: asset}, {name: createTime, var: create_time}, {name: description, var: description}, {name: name, var: name}, {name: originalAsset, var: original_asset}, {name: updateTime, var: update_time}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, alt: $alt, key: $key, access_token: $access_token, upload_protocol: $upload_protocol, pretty_print: $pretty_print, quota_user: $quota_user, fields: $fields, upload_type: $upload_type, xgafv: $xgafv, oauth_token: $oauth_token, callback: $callback, asset: $asset, create_time: $create_time, description: $description, name: $name, original_asset: $original_asset, update_time: $update_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Icon instance under a given Product. If Product only has a default icon, a new Icon instance is created and associated with the given Product. If Product already has a non-default icon, the action creates a new Icon instance, associates the newly created Icon with the given Product and deletes the old icon.
#
# POST /v1beta1/{product}/icons:upload
# Returns: record
# operationId: cloudprivatecatalogproducer.catalogs.products.icons.upload
export def "cloudprivatecatalogproducer-catalogs-products-icons-upload" [
  product: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --icon: string # The raw icon bytes user-supplied to be uploaded to the product. The format of the icon can only be PNG or JPEG. The minimum allowed dimensions are 130x130 pixels and the maximum dimensions are 10000x10000 pixels. Required. (format: byte)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{product}/icons:upload"
    path_params: [{name: product, var: product}]
    query: [{name: alt, var: alt}, {name: key, var: key}, {name: access_token, var: access_token}, {name: upload_protocol, var: upload_protocol}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: "$.xgafv", var: xgafv}, {name: oauth_token, var: oauth_token}, {name: callback, var: callback}]
    body: {content_type: "application/json", kind: json, fields: [{name: icon, var: icon}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    product: $product, alt: $alt, key: $key, access_token: $access_token, upload_protocol: $upload_protocol, pretty_print: $pretty_print, quota_user: $quota_user, fields: $fields, upload_type: $upload_type, xgafv: $xgafv, oauth_token: $oauth_token, callback: $callback, icon: $icon
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets IAM policy for the specified Catalog.
#
# GET /v1beta1/{resource}:getIamPolicy
# Returns: record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int>
# operationId: cloudprivatecatalogproducer.catalogs.getIamPolicy
export def "cloudprivatecatalogproducer-catalogs-get-iam-policy" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --options-requested-policy-version: int # Optional. The policy format version to be returned. Valid values are 0, 1, and 3. Requests specifying an invalid value will be rejected. Requests for policies with any conditional bindings must specify version 3. Policies without any conditional bindings may specify any valid value or leave the field unset.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{resource}:getIamPolicy"
    path_params: [{name: resource, var: resource}]
    query: [{name: alt, var: alt}, {name: key, var: key}, {name: access_token, var: access_token}, {name: upload_protocol, var: upload_protocol}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: "$.xgafv", var: xgafv}, {name: oauth_token, var: oauth_token}, {name: callback, var: callback}, {name: "options.requestedPolicyVersion", var: options_requested_policy_version}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    resource: $resource, alt: $alt, key: $key, access_token: $access_token, upload_protocol: $upload_protocol, pretty_print: $pretty_print, quota_user: $quota_user, fields: $fields, upload_type: $upload_type, xgafv: $xgafv, oauth_token: $oauth_token, callback: $callback, options_requested_policy_version: $options_requested_policy_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the IAM policy for the specified Catalog.
#
# POST /v1beta1/{resource}:setIamPolicy
# Returns: record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int>
# operationId: cloudprivatecatalogproducer.catalogs.setIamPolicy
export def "cloudprivatecatalogproducer-catalogs-set-iam-policy" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --policy: record # An Identity and Access Management (IAM) policy, which specifies access controls for Google Cloud resources. A `Policy` is a collection of `bindings`. A `binding` binds one or more `members` to a single `role`. Members can be user accounts, service accounts, Google groups, and domains (such as G Suite). A `role` is a named list of permissions; each `role` can be an IAM predefined role or a user-created custom role. Optionally, a `binding` can specify a `condition`, which is a logical expression that allows access to a resource only if the expression evaluates to `true`. A condition can add constraints based on attributes of the request, the resource, or both. **JSON example:** { "bindings": [ { "role": "roles/resourcemanager.organizationAdmin", "members": [ "user:mike@example.com", "group:admins@example.com", "domain:google.com", "serviceAccount:my-project-id@appspot.gserviceaccount.com" ] }, { "role": "roles/resourcemanager.organizationViewer", "members": ["user:eve@example.com"], "condition": { "title": "expirable access", "description": "Does not grant access after Sep 2020", "expression": "request.time < timestamp('2020-10-01T00:00:00.000Z')", } } ], "etag": "BwWWja0YfJA=", "version": 3 } **YAML example:** bindings: - members: - user:mike@example.com - group:admins@example.com - domain:google.com - serviceAccount:my-project-id@appspot.gserviceaccount.com role: roles/resourcemanager.organizationAdmin - members: - user:eve@example.com role: roles/resourcemanager.organizationViewer condition: title: expirable access description: Does not grant access after Sep 2020 expression: request.time < timestamp('2020-10-01T00:00:00.000Z') - etag: BwWWja0YfJA= - version: 3 For a description of IAM and its features, see the [IAM documentation](https://cloud.google.com/iam/docs/). — shape: {auditConfigs?: list, bindings?: list, etag?: string, version?: int}
  --update-mask: string # OPTIONAL: A FieldMask specifying which fields of the policy to modify. Only the fields in the mask will be modified. If no mask is provided, the following default mask is used: paths: "bindings, etag" This field is only used by Cloud IAM. (format: google-fieldmask)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{resource}:setIamPolicy"
    path_params: [{name: resource, var: resource}]
    query: [{name: alt, var: alt}, {name: key, var: key}, {name: access_token, var: access_token}, {name: upload_protocol, var: upload_protocol}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: "$.xgafv", var: xgafv}, {name: oauth_token, var: oauth_token}, {name: callback, var: callback}]
    body: {content_type: "application/json", kind: json, fields: [{name: policy, var: policy}, {name: updateMask, var: update_mask}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    resource: $resource, alt: $alt, key: $key, access_token: $access_token, upload_protocol: $upload_protocol, pretty_print: $pretty_print, quota_user: $quota_user, fields: $fields, upload_type: $upload_type, xgafv: $xgafv, oauth_token: $oauth_token, callback: $callback, policy: $policy, update_mask: $update_mask
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tests the IAM permissions for the specified Catalog.
#
# POST /v1beta1/{resource}:testIamPermissions
# Returns: record<permissions: list<string>>
# operationId: cloudprivatecatalogproducer.catalogs.testIamPermissions
export def "cloudprivatecatalogproducer-catalogs-test-iam-permissions" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --permissions: list<string> # The set of permissions to check for the `resource`. Permissions with wildcards (such as '*' or 'storage.*') are not allowed. For more information see [IAM Overview](https://cloud.google.com/iam/docs/overview#permissions).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{resource}:testIamPermissions"
    path_params: [{name: resource, var: resource}]
    query: [{name: alt, var: alt}, {name: key, var: key}, {name: access_token, var: access_token}, {name: upload_protocol, var: upload_protocol}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: "$.xgafv", var: xgafv}, {name: oauth_token, var: oauth_token}, {name: callback, var: callback}]
    body: {content_type: "application/json", kind: json, fields: [{name: permissions, var: permissions}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    resource: $resource, alt: $alt, key: $key, access_token: $access_token, upload_protocol: $upload_protocol, pretty_print: $pretty_print, quota_user: $quota_user, fields: $fields, upload_type: $upload_type, xgafv: $xgafv, oauth_token: $oauth_token, callback: $callback, permissions: $permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
