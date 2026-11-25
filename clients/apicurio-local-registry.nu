# Auto-generated client for Apicurio Registry API [v2] v2.4.x
# Source: https://api.apis.guru/v2/specs/apicurio.local/registry/2.4.x/openapi.json
# Auth: --token flag or $env.APICURIO_REGISTRY_API_V2_TOKEN

const CLIENT = {
  base_url: "http://apicurio.local"
  token_env_var: "APICURIO_REGISTRY_API_V2_TOKEN"
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

def base-url-completer [] { ["http://apicurio.local"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/zip"] }
def level-completer [] { ["CONFIG" "DEBUG" "ERROR" "FINE" "FINER" "FINEST" "INFO" "SEVERE" "TRACE" "WARN" "WARNING"] }
def role-completer [] { ["ADMIN" "DEVELOPER" "READ_ONLY"] }
def type-completer [] { ["COMPATIBILITY" "VALIDITY"] }
def rule-completer [] { ["COMPATIBILITY" "VALIDITY"] }
def order-completer [] { ["asc" "desc"] }
def orderby-completer [] { ["createdOn" "name"] }
def if-exists-completer [] { ["FAIL" "RETURN" "RETURN_OR_UPDATE" "UPDATE"] }
def x-registry-hash-algorithm-completer [] { ["MD5" "SHA256"] }
def state-completer [] { ["DEPRECATED" "DISABLED" "ENABLED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    list-artifact-types: "table<name: string>"
    list-config-properties: "table<description: string, label: string, name: string, type: string, value: string>"
    get-config-property: "record<description: string, label: string, name: string, type: string, value: string>"
    export-data: "record<downloadId: string, href: string>"
    list-log-configurations: "table<name: string, level: string>"
    remove-log-configuration: "record<name: string, level: string>"
    get-log-configuration: "record<name: string, level: string>"
    set-log-configuration: "record<name: string, level: string>"
    list-role-mappings: "table<principalId: string, principalName: string, role: string>"
    get-role-mapping: "record<principalId: string, principalName: string, role: string>"
    list-global-rules: "list<string>"
    get-global-rule-config: "record<config: string, type: string>"
    update-global-rule-config: "record<config: string, type: string>"
    list-groups: "record<count: int, groups: table<createdBy: string, createdOn: string, description: string, id: string, modifiedBy: string, modifiedOn: string>>"
    create-group: "record<createdBy: string, createdOn: string, description: string, id: string, modifiedBy: string, modifiedOn: string, properties: record>"
    get-group-by-id: "record<createdBy: string, createdOn: string, description: string, id: string, modifiedBy: string, modifiedOn: string, properties: record>"
    list-artifacts-in-group: "record<artifacts: table<createdBy: string, createdOn: string, description: string, groupId: string, id: string, labels: list, modifiedBy: string, modifiedOn: string, name: string, state: string, type: string>, count: int>"
    create-artifact: "record<contentId: int, createdBy: string, createdOn: string, description: string, globalId: int, groupId: string, id: string, labels: list<string>, modifiedBy: string, modifiedOn: string, name: string, properties: record, references: table<artifactId: string, groupId: string, name: string, version: string>, state: string, type: string, version: string>"
    get-latest-artifact: "binary"
    update-artifact: "record<contentId: int, createdBy: string, createdOn: string, description: string, globalId: int, groupId: string, id: string, labels: list<string>, modifiedBy: string, modifiedOn: string, name: string, properties: record, references: table<artifactId: string, groupId: string, name: string, version: string>, state: string, type: string, version: string>"
    get-artifact-meta-data: "record<contentId: int, createdBy: string, createdOn: string, description: string, globalId: int, groupId: string, id: string, labels: list<string>, modifiedBy: string, modifiedOn: string, name: string, properties: record, references: table<artifactId: string, groupId: string, name: string, version: string>, state: string, type: string, version: string>"
    get-artifact-version-meta-data-by-content: "record<contentId: int, createdBy: string, createdOn: string, description: string, globalId: int, groupId: string, id: string, labels: list<string>, name: string, properties: record, state: string, type: string, version: string>"
    get-artifact-owner: "record<owner: string>"
    list-artifact-rules: "list<string>"
    get-artifact-rule-config: "record<config: string, type: string>"
    update-artifact-rule-config: "record<config: string, type: string>"
    list-artifact-versions: "record<count: int, versions: table<contentId: int, createdBy: string, createdOn: string, description: string, globalId: int, labels: list, name: string, properties: record, references: list, state: string, type: string, version: string>>"
    create-artifact-version: "record<contentId: int, createdBy: string, createdOn: string, description: string, globalId: int, groupId: string, id: string, labels: list<string>, name: string, properties: record, state: string, type: string, version: string>"
    get-artifact-version: "binary"
    get-artifact-version-meta-data: "record<contentId: int, createdBy: string, createdOn: string, description: string, globalId: int, groupId: string, id: string, labels: list<string>, name: string, properties: record, state: string, type: string, version: string>"
    get-artifact-version-references: "table<artifactId: string, groupId: string, name: string, version: string>"
    get-content-by-hash: "binary"
    references-by-content-hash: "table<artifactId: string, groupId: string, name: string, version: string>"
    get-content-by-id: "binary"
    references-by-content-id: "table<artifactId: string, groupId: string, name: string, version: string>"
    get-content-by-global-id: "binary"
    references-by-global-id: "table<artifactId: string, groupId: string, name: string, version: string>"
    search-artifacts: "record<artifacts: table<createdBy: string, createdOn: string, description: string, groupId: string, id: string, labels: list, modifiedBy: string, modifiedOn: string, name: string, state: string, type: string>, count: int>"
    search-artifacts-by-content: "record<artifacts: table<createdBy: string, createdOn: string, description: string, groupId: string, id: string, labels: list, modifiedBy: string, modifiedOn: string, name: string, state: string, type: string>, count: int>"
    get-system-info: "record<builtOn: string, description: string, name: string, version: string>"
    get-resource-limits: "record<maxArtifactDescriptionLengthChars: int, maxArtifactLabelsCount: int, maxArtifactNameLengthChars: int, maxArtifactPropertiesCount: int, maxArtifactsCount: int, maxLabelSizeBytes: int, maxPropertyKeySizeBytes: int, maxPropertyValueSizeBytes: int, maxRequestsPerSecondCount: int, maxSchemaSizeBytes: int, maxTotalSchemasCount: int, maxVersionsPerArtifactCount: int>"
    get-current-user-info: "record<admin: bool, developer: bool, displayName: string, username: string, viewer: bool>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["list-artifact-types" "list-config-properties" "reset-config-property" "get-config-property" "update-config-property" "export-data" "import-data" "list-log-configurations" "remove-log-configuration" "get-log-configuration" "set-log-configuration" "list-role-mappings" "create-role-mapping" "delete-role-mapping" "get-role-mapping" "update-role-mapping" "delete-all-global-rules" "list-global-rules" "create-global-rule" "delete-global-rule" "get-global-rule-config" "update-global-rule-config" "list-groups" "create-group" "delete-group-by-id" "get-group-by-id" "delete-artifacts-in-group" "list-artifacts-in-group" "create-artifact" "delete-artifact" "get-latest-artifact" "update-artifact" "get-artifact-meta-data" "get-artifact-version-meta-data-by-content" "update-artifact-meta-data" "get-artifact-owner" "update-artifact-owner" "delete-artifact-rules" "list-artifact-rules" "create-artifact-rule" "delete-artifact-rule" "get-artifact-rule-config" "update-artifact-rule-config" "update-artifact-state" "test-update-artifact" "list-artifact-versions" "create-artifact-version" "get-artifact-version" "delete-artifact-version-meta-data" "get-artifact-version-meta-data" "update-artifact-version-meta-data" "get-artifact-version-references" "update-artifact-version-state" "get-content-by-hash" "references-by-content-hash" "get-content-by-id" "references-by-content-id" "get-content-by-global-id" "references-by-global-id" "search-artifacts" "search-artifacts-by-content" "get-system-info" "get-resource-limits" "get-current-user-info" "commands"] | sort) } | get name | first)
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

# List artifact types
#
# GET /admin/artifactTypes
# Returns: table<name: string>
# operationId: listArtifactTypes
export def "list-artifact-types" [
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
    path: "/admin/artifactTypes"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all configuration properties
#
# GET /admin/config/properties
# Returns: table<description: string, label: string, name: string, type: string, value: string>
# operationId: listConfigProperties
export def "list-config-properties" [
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
    path: "/admin/config/properties"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset a configuration property
#
# DELETE /admin/config/properties/{propertyName}
# operationId: resetConfigProperty
export def "reset-config-property" [
  property_name: string
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
    path: "/admin/config/properties/{propertyName}"
    path_params: [{name: propertyName, var: property_name}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    property_name: $property_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get configuration property value
#
# GET /admin/config/properties/{propertyName}
# Returns: record<description: string, label: string, name: string, type: string, value: string>
# operationId: getConfigProperty
export def "get-config-property" [
  property_name: string
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
    path: "/admin/config/properties/{propertyName}"
    path_params: [{name: propertyName, var: property_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    property_name: $property_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a configuration property
#
# PUT /admin/config/properties/{propertyName}
# operationId: updateConfigProperty
export def "update-config-property" [
  property_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  value: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/admin/config/properties/{propertyName}"
    path_params: [{name: propertyName, var: property_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    property_name: $property_name, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export registry data
#
# GET /admin/export
# Returns: record<downloadId: string, href: string>
# operationId: exportData
export def "export-data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --for-browser: oneof<nothing, bool> # Indicates if the operation is done for a browser. If true, the response will be a JSON payload with a property called `href`. This `href` will be a single-use, naked download link suitable for use by a web browser to download the content.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin/export"
    query: [{name: forBrowser, var: for_browser}]
    accept: ["application/json", "application/zip"]
    ok: [200]
    auth: bearer
  } {
    for_browser: $for_browser
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Import registry data
#
# POST /admin/import
# operationId: importData
export def "import-data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-registry-preserve-global-id: oneof<nothing, bool> # If this header is set to false, global ids of imported data will be ignored and replaced by next id in global id sequence. This allows to import any data even thought the global ids would cause a conflict.
  --x-registry-preserve-content-id: oneof<nothing, bool> # If this header is set to false, content ids of imported data will be ignored and replaced by next id in content id sequence. The mapping between content and artifacts will be preserved. This allows to import any data even thought the content ids would cause a conflict.
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/admin/import"
    header: [{name: X-Registry-Preserve-GlobalId, var: x_registry_preserve_global_id}, {name: X-Registry-Preserve-ContentId, var: x_registry_preserve_content_id}]
    body: {content_type: "application/zip", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_registry_preserve_global_id: $x_registry_preserve_global_id, x_registry_preserve_content_id: $x_registry_preserve_content_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List logging configurations
#
# GET /admin/loggers
# Returns: table<name: string, level: string>
# operationId: listLogConfigurations
export def "list-log-configurations" [
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
    path: "/admin/loggers"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes logger configuration
#
# DELETE /admin/loggers/{logger}
# Returns: record<name: string, level: string>
# operationId: removeLogConfiguration
export def "remove-log-configuration" [
  logger: string
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
    path: "/admin/loggers/{logger}"
    path_params: [{name: logger, var: logger}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    logger: $logger
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single logger configuration
#
# GET /admin/loggers/{logger}
# Returns: record<name: string, level: string>
# operationId: getLogConfiguration
export def "get-log-configuration" [
  logger: string
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
    path: "/admin/loggers/{logger}"
    path_params: [{name: logger, var: logger}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    logger: $logger
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set a logger's configuration
#
# PUT /admin/loggers/{logger}
# Returns: record<name: string, level: string>
# operationId: setLogConfiguration
export def "set-log-configuration" [
  logger: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  level: string@level-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/admin/loggers/{logger}"
    path_params: [{name: logger, var: logger}]
    body: {content_type: "application/json", kind: json, fields: [{name: level, var: level}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    logger: $logger, level: $level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all role mappings
#
# GET /admin/roleMappings
# Returns: table<principalId: string, principalName: string, role: string>
# operationId: listRoleMappings
export def "list-role-mappings" [
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
    path: "/admin/roleMappings"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new role mapping
#
# POST /admin/roleMappings
# operationId: createRoleMapping
export def "create-role-mapping" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  principal_id: string
  --principal-name: string # A friendly name for the principal.
  role: string@role-completer
]: any -> any {
  $in | http-request {
    method: post
    path: "/admin/roleMappings"
    body: {content_type: "application/json", kind: json, fields: [{name: principalId, var: principal_id}, {name: principalName, var: principal_name}, {name: role, var: role}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    principal_id: $principal_id, principal_name: $principal_name, role: $role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a role mapping
#
# DELETE /admin/roleMappings/{principalId}
# operationId: deleteRoleMapping
export def "delete-role-mapping" [
  principal_id: string
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
    path: "/admin/roleMappings/{principalId}"
    path_params: [{name: principalId, var: principal_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    principal_id: $principal_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a single role mapping
#
# GET /admin/roleMappings/{principalId}
# Returns: record<principalId: string, principalName: string, role: string>
# operationId: getRoleMapping
export def "get-role-mapping" [
  principal_id: string
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
    path: "/admin/roleMappings/{principalId}"
    path_params: [{name: principalId, var: principal_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    principal_id: $principal_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a role mapping
#
# PUT /admin/roleMappings/{principalId}
# operationId: updateRoleMapping
export def "update-role-mapping" [
  principal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  role: string@role-completer
]: any -> any {
  $in | http-request {
    method: put
    path: "/admin/roleMappings/{principalId}"
    path_params: [{name: principalId, var: principal_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: role, var: role}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    principal_id: $principal_id, role: $role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete all global rules
#
# DELETE /admin/rules
# operationId: deleteAllGlobalRules
export def "delete-all-global-rules" [
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
    path: "/admin/rules"
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List global rules
#
# GET /admin/rules
# Returns: list<string>
# operationId: listGlobalRules
export def "list-global-rules" [
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
    path: "/admin/rules"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create global rule
#
# POST /admin/rules
# operationId: createGlobalRule
export def "create-global-rule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  config: string
  --type: string@type-completer # e.g. VALIDITY
]: any -> any {
  $in | http-request {
    method: post
    path: "/admin/rules"
    body: {content_type: "application/json", kind: json, fields: [{name: config, var: config}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    config: $config, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete global rule
#
# DELETE /admin/rules/{rule}
# operationId: deleteGlobalRule
export def "delete-global-rule" [
  rule: string@rule-completer
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
    path: "/admin/rules/{rule}"
    path_params: [{name: rule, var: rule}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    rule: $rule
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get global rule configuration
#
# GET /admin/rules/{rule}
# Returns: record<config: string, type: string>
# operationId: getGlobalRuleConfig
export def "get-global-rule-config" [
  rule: string@rule-completer
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
    path: "/admin/rules/{rule}"
    path_params: [{name: rule, var: rule}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    rule: $rule
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update global rule configuration
#
# PUT /admin/rules/{rule}
# Returns: record<config: string, type: string>
# operationId: updateGlobalRuleConfig
export def "update-global-rule-config" [
  rule: string@rule-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  config: string
  --type: string@type-completer # e.g. VALIDITY
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/admin/rules/{rule}"
    path_params: [{name: rule, var: rule}]
    body: {content_type: "application/json", kind: json, fields: [{name: config, var: config}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    rule: $rule, config: $config, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List groups
#
# GET /groups
# Returns: record<count: int, groups: table<createdBy: string, createdOn: string, description: string, id: string, modifiedBy: string, modifiedOn: string>>
# operationId: listGroups
export def "list-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of groups to return. Defaults to 20.
  --offset: int # The number of groups to skip before starting the result set. Defaults to 0.
  --order: string@order-completer # Sort order, ascending (`asc`) or descending (`desc`).
  --orderby: string@orderby-completer # The field to sort by. Can be one of: * `name` * `createdOn`
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: order, var: order}, {name: orderby, var: orderby}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, order: $order, orderby: $orderby
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new group
#
# POST /groups
# Returns: record<createdBy: string, createdOn: string, description: string, id: string, modifiedBy: string, modifiedOn: string, properties: record>
# operationId: createGroup
export def "create-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  id: string
  --properties: record # User-defined name-value pairs. Name and value must be strings.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/groups"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: id, var: id}, {name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    description: $description, id: $id, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a group by the specified ID.
#
# DELETE /groups/{groupId}
# operationId: deleteGroupById
export def "delete-group-by-id" [
  group_id: string
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
    path: "/groups/{groupId}"
    path_params: [{name: groupId, var: group_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a group by the specified ID.
#
# GET /groups/{groupId}
# Returns: record<createdBy: string, createdOn: string, description: string, id: string, modifiedBy: string, modifiedOn: string, properties: record>
# operationId: getGroupById
export def "get-group-by-id" [
  group_id: string
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
    path: "/groups/{groupId}"
    path_params: [{name: groupId, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete artifacts in group
#
# DELETE /groups/{groupId}/artifacts
# operationId: deleteArtifactsInGroup
export def "delete-artifacts-in-group" [
  group_id: string
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
    path: "/groups/{groupId}/artifacts"
    path_params: [{name: groupId, var: group_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List artifacts in group
#
# GET /groups/{groupId}/artifacts
# Returns: record<artifacts: table<createdBy: string, createdOn: string, description: string, groupId: string, id: string, labels: list, modifiedBy: string, modifiedOn: string, name: string, state: string, type: string>, count: int>
# operationId: listArtifactsInGroup
export def "list-artifacts-in-group" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of artifacts to return. Defaults to 20.
  --offset: int # The number of artifacts to skip before starting the result set. Defaults to 0.
  --order: string@order-completer # Sort order, ascending (`asc`) or descending (`desc`).
  --orderby: string@orderby-completer # The field to sort by. Can be one of: * `name` * `createdOn`
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups/{groupId}/artifacts"
    path_params: [{name: groupId, var: group_id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: order, var: order}, {name: orderby, var: orderby}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, limit: $limit, offset: $offset, order: $order, orderby: $orderby
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create artifact
#
# POST /groups/{groupId}/artifacts
# Returns: record<contentId: int, createdBy: string, createdOn: string, description: string, globalId: int, groupId: string, id: string, labels: list<string>, modifiedBy: string, modifiedOn: string, name: string, properties: record, references: table<artifactId: string, groupId: string, name: string, version: string>, state: string, type: string, version: string>
# operationId: createArtifact
export def "create-artifact" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-exists: string@if-exists-completer # Set this option to instruct the server on what to do if the artifact already exists.
  --canonical: oneof<nothing, bool> # Used only when the `ifExists` query parameter is set to `RETURN_OR_UPDATE`, this parameter can be set to `true` to indicate that the server should "canonicalize" the content when searching for a matching version. The canonicalization algorithm is unique to each artifact type, but typically involves removing extra whitespace and formatting the content in a consistent manner.
  --x-registry-artifact-type: string # Specifies the type of the artifact being added. Possible values include: * Avro (`AVRO`) * Protobuf (`PROTOBUF`) * JSON Schema (`JSON`) * Kafka Connect (`KCONNECT`) * OpenAPI (`OPENAPI`) * AsyncAPI (`ASYNCAPI`) * GraphQL (`GRAPHQL`) * Web Services Description Language (`WSDL`) * XML Schema (`XSD`) (e.g. AVRO)
  --x-registry-artifact-id: string # A client-provided, globally unique identifier for the new artifact.
  --x-registry-version: string # Specifies the version number of this initial version of the artifact content. This would typically be a simple integer or a SemVer value. If not provided, the server will assign a version number automatically (starting with version `1`). (e.g. "3.1.6")
  --x-registry-description: string # Specifies the description of artifact being added. Description must be ASCII-only string. If this is not provided, the server will extract the description from the artifact content. (e.g. "Artifact description")
  --x-registry-description-encoded: string # Specifies the description of artifact being added. Value of this must be Base64 encoded string. If this is not provided, the server will extract the description from the artifact content. (e.g. "QXJ0aWZhY3QgZGVzY3JpcHRpb24K")
  --x-registry-name: string # Specifies the name of artifact being added. Name must be ASCII-only string. If this is not provided, the server will extract the name from the artifact content. (e.g. "Artifact name")
  --x-registry-name-encoded: string # Specifies the name of artifact being added. Value of this must be Base64 encoded string. If this is not provided, the server will extract the name from the artifact content. (e.g. "QXJ0aWZhY3QgbmFtZQo=")
  --x-registry-content-hash: string # Specifies the (optional) hash of the artifact to be verified.
  --x-registry-hash-algorithm: string@x-registry-hash-algorithm-completer # The algorithm to use when checking the content validity. (available: SHA256, MD5; default: SHA256)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/groups/{groupId}/artifacts"
    path_params: [{name: groupId, var: group_id}]
    query: [{name: ifExists, var: if_exists}, {name: canonical, var: canonical}]
    header: [{name: X-Registry-ArtifactType, var: x_registry_artifact_type}, {name: X-Registry-ArtifactId, var: x_registry_artifact_id}, {name: X-Registry-Version, var: x_registry_version}, {name: X-Registry-Description, var: x_registry_description}, {name: X-Registry-Description-Encoded, var: x_registry_description_encoded}, {name: X-Registry-Name, var: x_registry_name}, {name: X-Registry-Name-Encoded, var: x_registry_name_encoded}, {name: X-Registry-Content-Hash, var: x_registry_content_hash}, {name: X-Registry-Hash-Algorithm, var: x_registry_hash_algorithm}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, if_exists: $if_exists, canonical: $canonical, x_registry_artifact_type: $x_registry_artifact_type, x_registry_artifact_id: $x_registry_artifact_id, x_registry_version: $x_registry_version, x_registry_description: $x_registry_description, x_registry_description_encoded: $x_registry_description_encoded, x_registry_name: $x_registry_name, x_registry_name_encoded: $x_registry_name_encoded, x_registry_content_hash: $x_registry_content_hash, x_registry_hash_algorithm: $x_registry_hash_algorithm, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete artifact
#
# DELETE /groups/{groupId}/artifacts/{artifactId}
# operationId: deleteArtifact
export def "delete-artifact" [
  group_id: string
  artifact_id: string
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
    path: "/groups/{groupId}/artifacts/{artifactId}"
    path_params: [{name: groupId, var: group_id}, {name: artifactId, var: artifact_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    group_id: $group_id, artifact_id: $artifact_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get latest artifact
#
# GET /groups/{groupId}/artifacts/{artifactId}
# Returns: binary
# operationId: getLatestArtifact
export def "get-latest-artifact" [
  group_id: string
  artifact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dereference: oneof<nothing, bool> # Allows the user to specify if the content should be dereferenced when being returned
]: nothing -> any {
  http-request {
    method: get
    path: "/groups/{groupId}/artifacts/{artifactId}"
    path_params: [{name: groupId, var: group_id}, {name: artifactId, var: artifact_id}]
    query: [{name: dereference, var: dereference}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, artifact_id: $artifact_id, dereference: $dereference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update artifact
#
# PUT /groups/{groupId}/artifacts/{artifactId}
# Returns: record<contentId: int, createdBy: string, createdOn: string, description: string, globalId: int, groupId: string, id: string, labels: list<string>, modifiedBy: string, modifiedOn: string, name: string, properties: record, references: table<artifactId: string, groupId: string, name: string, version: string>, state: string, type: string, version: string>
# operationId: updateArtifact
export def "update-artifact" [
  group_id: string
  artifact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-registry-version: string # Specifies the version number of this new version of the artifact content. This would typically be a simple integer or a SemVer value. If not provided, the server will assign a version number automatically. (e.g. "3.1.6")
  --x-registry-name: string # Specifies the artifact name of this new version of the artifact content. Name must be ASCII-only string. If this is not provided, the server will extract the name from the artifact content. (e.g. "Artifact name")
  --x-registry-name-encoded: string # Specifies the artifact name of this new version of the artifact content. Value of this must be Base64 encoded string. If this is not provided, the server will extract the name from the artifact content. (e.g. "QXJ0aWZhY3QgbmFtZQo=")
  --x-registry-description: string # Specifies the artifact description of this new version of the artifact content. Description must be ASCII-only string. If this is not provided, the server will extract the description from the artifact content. (e.g. "Artifact description")
  --x-registry-description-encoded: string # Specifies the artifact description of this new version of the artifact content. Value of this must be Base64 encoded string. If this is not provided, the server will extract the description from the artifact content. (e.g. "QXJ0aWZhY3QgZGVzY3JpcHRpb24K")
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/groups/{groupId}/artifacts/{artifactId}"
    path_params: [{name: groupId, var: group_id}, {name: artifactId, var: artifact_id}]
    header: [{name: X-Registry-Version, var: x_registry_version}, {name: X-Registry-Name, var: x_registry_name}, {name: X-Registry-Name-Encoded, var: x_registry_name_encoded}, {name: X-Registry-Description, var: x_registry_description}, {name: X-Registry-Description-Encoded, var: x_registry_description_encoded}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, artifact_id: $artifact_id, x_registry_version: $x_registry_version, x_registry_name: $x_registry_name, x_registry_name_encoded: $x_registry_name_encoded, x_registry_description: $x_registry_description, x_registry_description_encoded: $x_registry_description_encoded, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get artifact metadata
#
# GET /groups/{groupId}/artifacts/{artifactId}/meta
# Returns: record<contentId: int, createdBy: string, createdOn: string, description: string, globalId: int, groupId: string, id: string, labels: list<string>, modifiedBy: string, modifiedOn: string, name: string, properties: record, references: table<artifactId: string, groupId: string, name: string, version: string>, state: string, type: string, version: string>
# operationId: getArtifactMetaData
export def "get-artifact-meta-data" [
  group_id: string
  artifact_id: string
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
    path: "/groups/{groupId}/artifacts/{artifactId}/meta"
    path_params: [{name: groupId, var: group_id}, {name: artifactId, var: artifact_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, artifact_id: $artifact_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get artifact version metadata by content
#
# POST /groups/{groupId}/artifacts/{artifactId}/meta
# Returns: record<contentId: int, createdBy: string, createdOn: string, description: string, globalId: int, groupId: string, id: string, labels: list<string>, name: string, properties: record, state: string, type: string, version: string>
# operationId: getArtifactVersionMetaDataByContent
export def "get-artifact-version-meta-data-by-content" [
  group_id: string
  artifact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --canonical: oneof<nothing, bool> # Parameter that can be set to `true` to indicate that the server should "canonicalize" the content when searching for a matching version. Canonicalization is unique to each artifact type, but typically involves removing any extra whitespace and formatting the content in a consistent manner.
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/groups/{groupId}/artifacts/{artifactId}/meta"
    path_params: [{name: groupId, var: group_id}, {name: artifactId, var: artifact_id}]
    query: [{name: canonical, var: canonical}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, artifact_id: $artifact_id, canonical: $canonical, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update artifact metadata
#
# PUT /groups/{groupId}/artifacts/{artifactId}/meta
# operationId: updateArtifactMetaData
export def "update-artifact-meta-data" [
  group_id: string
  artifact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  --labels: list<string>
  --name: string
  --properties: record # User-defined name-value pairs. Name and value must be strings.
]: any -> any {
  $in | http-request {
    method: put
    path: "/groups/{groupId}/artifacts/{artifactId}/meta"
    path_params: [{name: groupId, var: group_id}, {name: artifactId, var: artifact_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: labels, var: labels}, {name: name, var: name}, {name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    group_id: $group_id, artifact_id: $artifact_id, description: $description, labels: $labels, name: $name, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get artifact owner
#
# GET /groups/{groupId}/artifacts/{artifactId}/owner
# Returns: record<owner: string>
# operationId: getArtifactOwner
export def "get-artifact-owner" [
  group_id: string
  artifact_id: string
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
    path: "/groups/{groupId}/artifacts/{artifactId}/owner"
    path_params: [{name: groupId, var: group_id}, {name: artifactId, var: artifact_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, artifact_id: $artifact_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update artifact owner
#
# PUT /groups/{groupId}/artifacts/{artifactId}/owner
# operationId: updateArtifactOwner
export def "update-artifact-owner" [
  group_id: string
  artifact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/groups/{groupId}/artifacts/{artifactId}/owner"
    path_params: [{name: groupId, var: group_id}, {name: artifactId, var: artifact_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: owner, var: owner}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    group_id: $group_id, artifact_id: $artifact_id, owner: $owner
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete artifact rules
#
# DELETE /groups/{groupId}/artifacts/{artifactId}/rules
# operationId: deleteArtifactRules
export def "delete-artifact-rules" [
  group_id: string
  artifact_id: string
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
    path: "/groups/{groupId}/artifacts/{artifactId}/rules"
    path_params: [{name: groupId, var: group_id}, {name: artifactId, var: artifact_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    group_id: $group_id, artifact_id: $artifact_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List artifact rules
#
# GET /groups/{groupId}/artifacts/{artifactId}/rules
# Returns: list<string>
# operationId: listArtifactRules
export def "list-artifact-rules" [
  group_id: string
  artifact_id: string
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
    path: "/groups/{groupId}/artifacts/{artifactId}/rules"
    path_params: [{name: groupId, var: group_id}, {name: artifactId, var: artifact_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, artifact_id: $artifact_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create artifact rule
#
# POST /groups/{groupId}/artifacts/{artifactId}/rules
# operationId: createArtifactRule
export def "create-artifact-rule" [
  group_id: string
  artifact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  config: string
  --type: string@type-completer # e.g. VALIDITY
]: any -> any {
  $in | http-request {
    method: post
    path: "/groups/{groupId}/artifacts/{artifactId}/rules"
    path_params: [{name: groupId, var: group_id}, {name: artifactId, var: artifact_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: config, var: config}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    group_id: $group_id, artifact_id: $artifact_id, config: $config, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete artifact rule
#
# DELETE /groups/{groupId}/artifacts/{artifactId}/rules/{rule}
# operationId: deleteArtifactRule
export def "delete-artifact-rule" [
  group_id: string
  artifact_id: string
  rule: string@rule-completer
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
    path: "/groups/{groupId}/artifacts/{artifactId}/rules/{rule}"
    path_params: [{name: groupId, var: group_id}, {name: artifactId, var: artifact_id}, {name: rule, var: rule}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    group_id: $group_id, artifact_id: $artifact_id, rule: $rule
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get artifact rule configuration
#
# GET /groups/{groupId}/artifacts/{artifactId}/rules/{rule}
# Returns: record<config: string, type: string>
# operationId: getArtifactRuleConfig
export def "get-artifact-rule-config" [
  group_id: string
  artifact_id: string
  rule: string@rule-completer
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
    path: "/groups/{groupId}/artifacts/{artifactId}/rules/{rule}"
    path_params: [{name: groupId, var: group_id}, {name: artifactId, var: artifact_id}, {name: rule, var: rule}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, artifact_id: $artifact_id, rule: $rule
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update artifact rule configuration
#
# PUT /groups/{groupId}/artifacts/{artifactId}/rules/{rule}
# Returns: record<config: string, type: string>
# operationId: updateArtifactRuleConfig
export def "update-artifact-rule-config" [
  group_id: string
  artifact_id: string
  rule: string@rule-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  config: string
  --type: string@type-completer # e.g. VALIDITY
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/groups/{groupId}/artifacts/{artifactId}/rules/{rule}"
    path_params: [{name: groupId, var: group_id}, {name: artifactId, var: artifact_id}, {name: rule, var: rule}]
    body: {content_type: "application/json", kind: json, fields: [{name: config, var: config}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, artifact_id: $artifact_id, rule: $rule, config: $config, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update artifact state
#
# PUT /groups/{groupId}/artifacts/{artifactId}/state
# operationId: updateArtifactState
export def "update-artifact-state" [
  group_id: string
  artifact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  state: string@state-completer # Describes the state of an artifact or artifact version. The following states are possible: * ENABLED * DISABLED * DEPRECATED
]: any -> any {
  $in | http-request {
    method: put
    path: "/groups/{groupId}/artifacts/{artifactId}/state"
    path_params: [{name: groupId, var: group_id}, {name: artifactId, var: artifact_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: state, var: state}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    group_id: $group_id, artifact_id: $artifact_id, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test update artifact
#
# PUT /groups/{groupId}/artifacts/{artifactId}/test
# operationId: testUpdateArtifact
export def "test-update-artifact" [
  group_id: string
  artifact_id: string
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
    method: put
    path: "/groups/{groupId}/artifacts/{artifactId}/test"
    path_params: [{name: groupId, var: group_id}, {name: artifactId, var: artifact_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    group_id: $group_id, artifact_id: $artifact_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List artifact versions
#
# GET /groups/{groupId}/artifacts/{artifactId}/versions
# Returns: record<count: int, versions: table<contentId: int, createdBy: string, createdOn: string, description: string, globalId: int, labels: list, name: string, properties: record, references: list, state: string, type: string, version: string>>
# operationId: listArtifactVersions
export def "list-artifact-versions" [
  group_id: string
  artifact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of versions to skip before starting to collect the result set. Defaults to 0.
  --limit: int # The number of versions to return. Defaults to 20.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups/{groupId}/artifacts/{artifactId}/versions"
    path_params: [{name: groupId, var: group_id}, {name: artifactId, var: artifact_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, artifact_id: $artifact_id, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create artifact version
#
# POST /groups/{groupId}/artifacts/{artifactId}/versions
# Returns: record<contentId: int, createdBy: string, createdOn: string, description: string, globalId: int, groupId: string, id: string, labels: list<string>, name: string, properties: record, state: string, type: string, version: string>
# operationId: createArtifactVersion
export def "create-artifact-version" [
  group_id: string
  artifact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-registry-version: string # Specifies the version number of this new version of the artifact content. This would typically be a simple integer or a SemVer value. It must be unique within the artifact. If this is not provided, the server will generate a new, unique version number for this new updated content. (e.g. "3.1.6")
  --x-registry-name: string # Specifies the artifact name of this new version of the artifact content. Name must be ASCII-only string. If this is not provided, the server will extract the name from the artifact content. (e.g. "Artifact name")
  --x-registry-description: string # Specifies the artifact description of this new version of the artifact content. Description must be ASCII-only string. If this is not provided, the server will extract the description from the artifact content. (e.g. "Artifact description")
  --x-registry-description-encoded: string # Specifies the artifact description of this new version of the artifact content. Value of this must be Base64 encoded string. If this is not provided, the server will extract the description from the artifact content. (e.g. "QXJ0aWZhY3QgZGVzY3JpcHRpb24K")
  --x-registry-name-encoded: string # Specifies the artifact name of this new version of the artifact content. Value of this must be Base64 encoded string. If this is not provided, the server will extract the name from the artifact content. (e.g. "QXJ0aWZhY3QgbmFtZQo=")
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/groups/{groupId}/artifacts/{artifactId}/versions"
    path_params: [{name: groupId, var: group_id}, {name: artifactId, var: artifact_id}]
    header: [{name: X-Registry-Version, var: x_registry_version}, {name: X-Registry-Name, var: x_registry_name}, {name: X-Registry-Description, var: x_registry_description}, {name: X-Registry-Description-Encoded, var: x_registry_description_encoded}, {name: X-Registry-Name-Encoded, var: x_registry_name_encoded}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, artifact_id: $artifact_id, x_registry_version: $x_registry_version, x_registry_name: $x_registry_name, x_registry_description: $x_registry_description, x_registry_description_encoded: $x_registry_description_encoded, x_registry_name_encoded: $x_registry_name_encoded, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get artifact version
#
# GET /groups/{groupId}/artifacts/{artifactId}/versions/{version}
# Returns: binary
# operationId: getArtifactVersion
export def "get-artifact-version" [
  group_id: string
  artifact_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dereference: oneof<nothing, bool> # Allows the user to specify if the content should be dereferenced when being returned
]: nothing -> any {
  http-request {
    method: get
    path: "/groups/{groupId}/artifacts/{artifactId}/versions/{version}"
    path_params: [{name: groupId, var: group_id}, {name: artifactId, var: artifact_id}, {name: version, var: version}]
    query: [{name: dereference, var: dereference}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, artifact_id: $artifact_id, version: $version, dereference: $dereference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete artifact version metadata
#
# DELETE /groups/{groupId}/artifacts/{artifactId}/versions/{version}/meta
# operationId: deleteArtifactVersionMetaData
export def "delete-artifact-version-meta-data" [
  group_id: string
  artifact_id: string
  version: string
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
    path: "/groups/{groupId}/artifacts/{artifactId}/versions/{version}/meta"
    path_params: [{name: groupId, var: group_id}, {name: artifactId, var: artifact_id}, {name: version, var: version}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    group_id: $group_id, artifact_id: $artifact_id, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get artifact version metadata
#
# GET /groups/{groupId}/artifacts/{artifactId}/versions/{version}/meta
# Returns: record<contentId: int, createdBy: string, createdOn: string, description: string, globalId: int, groupId: string, id: string, labels: list<string>, name: string, properties: record, state: string, type: string, version: string>
# operationId: getArtifactVersionMetaData
export def "get-artifact-version-meta-data" [
  group_id: string
  artifact_id: string
  version: string
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
    path: "/groups/{groupId}/artifacts/{artifactId}/versions/{version}/meta"
    path_params: [{name: groupId, var: group_id}, {name: artifactId, var: artifact_id}, {name: version, var: version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, artifact_id: $artifact_id, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update artifact version metadata
#
# PUT /groups/{groupId}/artifacts/{artifactId}/versions/{version}/meta
# operationId: updateArtifactVersionMetaData
export def "update-artifact-version-meta-data" [
  group_id: string
  artifact_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  --labels: list<string>
  --name: string
  --properties: record # User-defined name-value pairs. Name and value must be strings.
]: any -> any {
  $in | http-request {
    method: put
    path: "/groups/{groupId}/artifacts/{artifactId}/versions/{version}/meta"
    path_params: [{name: groupId, var: group_id}, {name: artifactId, var: artifact_id}, {name: version, var: version}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: labels, var: labels}, {name: name, var: name}, {name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    group_id: $group_id, artifact_id: $artifact_id, version: $version, description: $description, labels: $labels, name: $name, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get artifact version
#
# GET /groups/{groupId}/artifacts/{artifactId}/versions/{version}/references
# Returns: table<artifactId: string, groupId: string, name: string, version: string>
# operationId: getArtifactVersionReferences
export def "get-artifact-version-references" [
  group_id: string
  artifact_id: string
  version: string
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
    path: "/groups/{groupId}/artifacts/{artifactId}/versions/{version}/references"
    path_params: [{name: groupId, var: group_id}, {name: artifactId, var: artifact_id}, {name: version, var: version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, artifact_id: $artifact_id, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update artifact version state
#
# PUT /groups/{groupId}/artifacts/{artifactId}/versions/{version}/state
# operationId: updateArtifactVersionState
export def "update-artifact-version-state" [
  group_id: string
  artifact_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  state: string@state-completer # Describes the state of an artifact or artifact version. The following states are possible: * ENABLED * DISABLED * DEPRECATED
]: any -> any {
  $in | http-request {
    method: put
    path: "/groups/{groupId}/artifacts/{artifactId}/versions/{version}/state"
    path_params: [{name: groupId, var: group_id}, {name: artifactId, var: artifact_id}, {name: version, var: version}]
    body: {content_type: "application/json", kind: json, fields: [{name: state, var: state}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    group_id: $group_id, artifact_id: $artifact_id, version: $version, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get artifact content by SHA-256 hash
#
# GET /ids/contentHashes/{contentHash}/
# Returns: binary
# operationId: getContentByHash
export def "get-content-by-hash" [
  content_hash: string
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
    path: "/ids/contentHashes/{contentHash}/"
    path_params: [{name: contentHash, var: content_hash}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    content_hash: $content_hash
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List artifact references by hash
#
# GET /ids/contentHashes/{contentHash}/references
# Returns: table<artifactId: string, groupId: string, name: string, version: string>
# operationId: referencesByContentHash
export def "references-by-content-hash" [
  content_hash: string
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
    path: "/ids/contentHashes/{contentHash}/references"
    path_params: [{name: contentHash, var: content_hash}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content_hash: $content_hash
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get artifact content by ID
#
# GET /ids/contentIds/{contentId}/
# Returns: binary
# operationId: getContentById
export def "get-content-by-id" [
  content_id: int
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
    path: "/ids/contentIds/{contentId}/"
    path_params: [{name: contentId, var: content_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    content_id: $content_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List artifact references by content ID
#
# GET /ids/contentIds/{contentId}/references
# Returns: table<artifactId: string, groupId: string, name: string, version: string>
# operationId: referencesByContentId
export def "references-by-content-id" [
  content_id: int
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
    path: "/ids/contentIds/{contentId}/references"
    path_params: [{name: contentId, var: content_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content_id: $content_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get artifact by global ID
#
# GET /ids/globalIds/{globalId}
# Returns: binary
# operationId: getContentByGlobalId
export def "get-content-by-global-id" [
  global_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dereference: oneof<nothing, bool> # Allows the user to specify if the content should be dereferenced when being returned
]: nothing -> any {
  http-request {
    method: get
    path: "/ids/globalIds/{globalId}"
    path_params: [{name: globalId, var: global_id}]
    query: [{name: dereference, var: dereference}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    global_id: $global_id, dereference: $dereference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List artifact references by global ID
#
# GET /ids/globalIds/{globalId}/references
# Returns: table<artifactId: string, groupId: string, name: string, version: string>
# operationId: referencesByGlobalId
export def "references-by-global-id" [
  global_id: int
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
    path: "/ids/globalIds/{globalId}/references"
    path_params: [{name: globalId, var: global_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_id: $global_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for artifacts
#
# GET /search/artifacts
# Returns: record<artifacts: table<createdBy: string, createdOn: string, description: string, groupId: string, id: string, labels: list, modifiedBy: string, modifiedOn: string, name: string, state: string, type: string>, count: int>
# operationId: searchArtifacts
export def "search-artifacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Filter by artifact name.
  --offset: int # The number of artifacts to skip before starting to collect the result set. Defaults to 0. (default: 0)
  --limit: int # The number of artifacts to return. Defaults to 20. (default: 20)
  --order: string@order-completer # Sort order, ascending (`asc`) or descending (`desc`).
  --orderby: string@orderby-completer # The field to sort by. Can be one of: * `name` * `createdOn`
  --labels: list<string> # Filter by label. Include one or more label to only return artifacts containing all of the specified labels.
  --properties: list<string> # Filter by one or more name/value property. Separate each name/value pair using a colon. For example `properties=foo:bar` will return only artifacts with a custom property named `foo` and value `bar`.
  --description: string # Filter by description.
  --group: string # Filter by artifact group.
  --global-id: int # Filter by globalId. (format: int64)
  --content-id: int # Filter by contentId. (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search/artifacts"
    query: [{name: name, var: name}, {name: offset, var: offset}, {name: limit, var: limit}, {name: order, var: order}, {name: orderby, var: orderby}, {name: labels, var: labels, style: multi}, {name: properties, var: properties, style: multi}, {name: description, var: description}, {name: group, var: group}, {name: globalId, var: global_id}, {name: contentId, var: content_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, offset: $offset, limit: $limit, order: $order, orderby: $orderby, labels: $labels, properties: $properties, description: $description, group: $group, global_id: $global_id, content_id: $content_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for artifacts by content
#
# POST /search/artifacts
# Returns: record<artifacts: table<createdBy: string, createdOn: string, description: string, groupId: string, id: string, labels: list, modifiedBy: string, modifiedOn: string, name: string, state: string, type: string>, count: int>
# operationId: searchArtifactsByContent
export def "search-artifacts-by-content" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --canonical: oneof<nothing, bool> # Parameter that can be set to `true` to indicate that the server should "canonicalize" the content when searching for matching artifacts. Canonicalization is unique to each artifact type, but typically involves removing any extra whitespace and formatting the content in a consistent manner. Must be used along with the `artifactType` query parameter.
  --artifact-type: string # Indicates the type of artifact represented by the content being used for the search. This is only needed when using the `canonical` query parameter, so that the server knows how to canonicalize the content prior to searching for matching artifacts. (e.g. AVRO)
  --offset: int # The number of artifacts to skip before starting to collect the result set. Defaults to 0. (default: 0)
  --limit: int # The number of artifacts to return. Defaults to 20. (default: 20)
  --order: string@order-completer # Sort order, ascending (`asc`) or descending (`desc`).
  --orderby: string@orderby-completer # The field to sort by. Can be one of: * `name` * `createdOn`
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/search/artifacts"
    query: [{name: canonical, var: canonical}, {name: artifactType, var: artifact_type}, {name: offset, var: offset}, {name: limit, var: limit}, {name: order, var: order}, {name: orderby, var: orderby}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    canonical: $canonical, artifact_type: $artifact_type, offset: $offset, limit: $limit, order: $order, orderby: $orderby, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get system information
#
# GET /system/info
# Returns: record<builtOn: string, description: string, name: string, version: string>
# operationId: getSystemInfo
export def "get-system-info" [
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
    path: "/system/info"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get resource limits information
#
# GET /system/limits
# Returns: record<maxArtifactDescriptionLengthChars: int, maxArtifactLabelsCount: int, maxArtifactNameLengthChars: int, maxArtifactPropertiesCount: int, maxArtifactsCount: int, maxLabelSizeBytes: int, maxPropertyKeySizeBytes: int, maxPropertyValueSizeBytes: int, maxRequestsPerSecondCount: int, maxSchemaSizeBytes: int, maxTotalSchemasCount: int, maxVersionsPerArtifactCount: int>
# operationId: getResourceLimits
export def "get-resource-limits" [
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
    path: "/system/limits"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get current user
#
# GET /users/me
# Returns: record<admin: bool, developer: bool, displayName: string, username: string, viewer: bool>
# operationId: getCurrentUserInfo
export def "get-current-user-info" [
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
    path: "/users/me"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
