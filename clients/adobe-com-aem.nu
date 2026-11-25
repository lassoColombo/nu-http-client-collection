# Auto-generated client for Adobe Experience Manager (AEM) API v3.7.1-pre.0
# Source: https://api.apis.guru/v2/specs/adobe.com/aem/3.7.1-pre.0/openapi.json
# Auth: --token flag or $env.ADOBE_EXPERIENCE_MANAGER_AEM_API_TOKEN

const CLIENT = {
  base_url: "https://api.apis.guru"
  token_env_var: "ADOBE_EXPERIENCE_MANAGER_AEM_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: basic, in: header, header_name: Authorization, prefix: Basic}
    {name: basic-credentials, in: header, header_name: Authorization, prefix: Basic, base64: true}
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

def base-url-completer [] { ["https://api.apis.guru" "http://adobe.local"] }
def auth-scheme-completer [] { ["basic" "none" "basic-credentials"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-query: "string"
    post-query: "string"
    post-set-password: "string"
    get-install-status: "record<status: record<finished: bool, itemCount: int>>"
    post-package-service-json: "string"
    post-package-update: "string"
    get-crxde-status: "string"
    get-package: "binary"
    get-package-filter: "string"
    get-agents: "string"
    post-truststore-pkcs12: "string"
    get-truststore: "binary"
    get-login-page: "string"
    post-authorizables: "string"
    ssl-setup: "string"
    post-truststore: "string"
    get-truststore-info: "record<aliases: table<alias: string, entryType: string, issuer: string, notAfter: string, notBefore: string, serialNumber: int, subject: string>, exists: bool>"
    get-bundle-info: "record<data: table<category: string, fragment: bool, id: int, name: string, props: list, state: string, stateRaw: int, symbolicName: string, version: string>, s: list<int>, status: string>"
    post-saml-configuration: "record<bundle_location: string, description: string, pid: string, properties: record<addGroupMemberships: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: bool>, assertionConsumerServiceURL: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: string>, clockTolerance: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: int>, createUser: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: bool>, defaultGroups: record<description: string, is_set: bool, name: string, optional: bool, type: int, values: list>, defaultRedirectUrl: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: string>, digestMethod: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: string>, groupMembershipAttribute: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: string>, handleLogout: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: bool>, idpCertAlias: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: string>, idpHttpRedirect: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: bool>, idpUrl: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: string>, keyStorePassword: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: string>, logoutUrl: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: string>, nameIdFormat: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: string>, path: record<description: string, is_set: bool, name: string, optional: bool, type: int, values: list>, \"service.ranking\": record<description: string, is_set: bool, name: string, optional: bool, type: int, value: int>, serviceProviderEntityId: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: string>, signatureMethod: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: string>, spPrivateKeyAlias: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: string>, synchronizeAttributes: record<description: string, is_set: bool, name: string, optional: bool, type: int, values: list>, useEncryption: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: bool>, userIDAttribute: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: string>, userIntermediatePath: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: string>>, service_location: string, title: string>"
    get-aem-product-info: "list<string>"
    get-aem-health-check: "string"
    post-authorizable-keystore: "record<aliases: table<algorithm: string, alias: string, chain: list, entryType: string, format: string>, exists: bool>"
    get-authorizable-keystore: "record<aliases: table<algorithm: string, alias: string, chain: list, entryType: string, format: string>, exists: bool>"
    get-keystore: "binary"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["post-cq-actions" "post-config-adobe-granite-saml-authentication-handler" "post-config-aem-password-reset" "post-config-aem-health-check-servlet" "post-config-apache-felix-jetty-based-http-service" "post-config-apache-http-components-proxy-configuration" "post-config-apache-sling-dav-ex-servlet" "post-config-apache-sling-referrer-filter" "post-config-apache-sling-get-servlet" "post-config-property" "get-query" "post-query" "post-set-password" "get-install-status" "post-package-service" "post-package-service-json" "get-package-manager-servlet" "post-package-update" "get-crxde-status" "get-package" "get-package-filter" "get-agents" "delete-agent" "get-agent" "post-agent" "post-truststore-pkcs12" "get-truststore" "get-login-page" "post-authorizables" "ssl-setup" "post-truststore" "get-truststore-info" "post-tree-activation" "post-bundle" "get-bundle-info" "get-config-mgr" "post-saml-configuration" "post-jmx-repository" "get-aem-product-info" "get-aem-health-check" "post-authorizable-keystore" "get-authorizable-keystore" "get-keystore" "post-path" "delete-node" "get-node" "post-node" "post-node-rw" "commands"] | sort) } | get name | first)
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

# POST /.cqactions.html
#
# operationId: postCqActions
export def "post-cq-actions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorizable-id: string # required
  --changelog: string # required
]: nothing -> any {
  http-request {
    method: post
    path: "/.cqactions.html"
    query: [{name: authorizableId, var: authorizable_id, required: true}, {name: changelog, var: changelog, required: true}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    authorizable_id: $authorizable_id, changelog: $changelog
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /apps/system/config/com.adobe.granite.auth.saml.SamlAuthenticationHandler.config
#
# operationId: postConfigAdobeGraniteSamlAuthenticationHandler
export def "post-config-adobe-granite-saml-authentication-handler" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key-store-password: string
  --key-store-password-type-hint: string
  --service-ranking: int
  --service-ranking-type-hint: string
  --idp-http-redirect: oneof<nothing, bool>
  --idp-http-redirect-type-hint: string
  --create-user: oneof<nothing, bool>
  --create-user-type-hint: string
  --default-redirect-url: string
  --default-redirect-url-type-hint: string
  --user-id-attribute: string
  --user-id-attribute-type-hint: string
  --default-groups: list<string>
  --default-groups-type-hint: string
  --idp-cert-alias: string
  --idp-cert-alias-type-hint: string
  --add-group-memberships: oneof<nothing, bool>
  --add-group-memberships-type-hint: string
  --path: list<string>
  --path-type-hint: string
  --synchronize-attributes: list<string>
  --synchronize-attributes-type-hint: string
  --clock-tolerance: int
  --clock-tolerance-type-hint: string
  --group-membership-attribute: string
  --group-membership-attribute-type-hint: string
  --idp-url: string
  --idp-url-type-hint: string
  --logout-url: string
  --logout-url-type-hint: string
  --service-provider-entity-id: string
  --service-provider-entity-id-type-hint: string
  --assertion-consumer-service-url: string
  --assertion-consumer-service-url-type-hint: string
  --handle-logout: oneof<nothing, bool>
  --handle-logout-type-hint: string
  --sp-private-key-alias: string
  --sp-private-key-alias-type-hint: string
  --use-encryption: oneof<nothing, bool>
  --use-encryption-type-hint: string
  --name-id-format: string
  --name-id-format-type-hint: string
  --digest-method: string
  --digest-method-type-hint: string
  --signature-method: string
  --signature-method-type-hint: string
  --user-intermediate-path: string
  --user-intermediate-path-type-hint: string
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/system/config/com.adobe.granite.auth.saml.SamlAuthenticationHandler.config"
    query: [{name: keyStorePassword, var: key_store_password}, {name: "keyStorePassword@TypeHint", var: key_store_password_type_hint}, {name: "service.ranking", var: service_ranking}, {name: "service.ranking@TypeHint", var: service_ranking_type_hint}, {name: idpHttpRedirect, var: idp_http_redirect}, {name: "idpHttpRedirect@TypeHint", var: idp_http_redirect_type_hint}, {name: createUser, var: create_user}, {name: "createUser@TypeHint", var: create_user_type_hint}, {name: defaultRedirectUrl, var: default_redirect_url}, {name: "defaultRedirectUrl@TypeHint", var: default_redirect_url_type_hint}, {name: userIDAttribute, var: user_id_attribute}, {name: "userIDAttribute@TypeHint", var: user_id_attribute_type_hint}, {name: defaultGroups, var: default_groups, style: multi}, {name: "defaultGroups@TypeHint", var: default_groups_type_hint}, {name: idpCertAlias, var: idp_cert_alias}, {name: "idpCertAlias@TypeHint", var: idp_cert_alias_type_hint}, {name: addGroupMemberships, var: add_group_memberships}, {name: "addGroupMemberships@TypeHint", var: add_group_memberships_type_hint}, {name: path, var: path, style: multi}, {name: "path@TypeHint", var: path_type_hint}, {name: synchronizeAttributes, var: synchronize_attributes, style: multi}, {name: "synchronizeAttributes@TypeHint", var: synchronize_attributes_type_hint}, {name: clockTolerance, var: clock_tolerance}, {name: "clockTolerance@TypeHint", var: clock_tolerance_type_hint}, {name: groupMembershipAttribute, var: group_membership_attribute}, {name: "groupMembershipAttribute@TypeHint", var: group_membership_attribute_type_hint}, {name: idpUrl, var: idp_url}, {name: "idpUrl@TypeHint", var: idp_url_type_hint}, {name: logoutUrl, var: logout_url}, {name: "logoutUrl@TypeHint", var: logout_url_type_hint}, {name: serviceProviderEntityId, var: service_provider_entity_id}, {name: "serviceProviderEntityId@TypeHint", var: service_provider_entity_id_type_hint}, {name: assertionConsumerServiceURL, var: assertion_consumer_service_url}, {name: "assertionConsumerServiceURL@TypeHint", var: assertion_consumer_service_url_type_hint}, {name: handleLogout, var: handle_logout}, {name: "handleLogout@TypeHint", var: handle_logout_type_hint}, {name: spPrivateKeyAlias, var: sp_private_key_alias}, {name: "spPrivateKeyAlias@TypeHint", var: sp_private_key_alias_type_hint}, {name: useEncryption, var: use_encryption}, {name: "useEncryption@TypeHint", var: use_encryption_type_hint}, {name: nameIdFormat, var: name_id_format}, {name: "nameIdFormat@TypeHint", var: name_id_format_type_hint}, {name: digestMethod, var: digest_method}, {name: "digestMethod@TypeHint", var: digest_method_type_hint}, {name: signatureMethod, var: signature_method}, {name: "signatureMethod@TypeHint", var: signature_method_type_hint}, {name: userIntermediatePath, var: user_intermediate_path}, {name: "userIntermediatePath@TypeHint", var: user_intermediate_path_type_hint}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    key_store_password: $key_store_password, key_store_password_type_hint: $key_store_password_type_hint, service_ranking: $service_ranking, service_ranking_type_hint: $service_ranking_type_hint, idp_http_redirect: $idp_http_redirect, idp_http_redirect_type_hint: $idp_http_redirect_type_hint, create_user: $create_user, create_user_type_hint: $create_user_type_hint, default_redirect_url: $default_redirect_url, default_redirect_url_type_hint: $default_redirect_url_type_hint, user_id_attribute: $user_id_attribute, user_id_attribute_type_hint: $user_id_attribute_type_hint, default_groups: $default_groups, default_groups_type_hint: $default_groups_type_hint, idp_cert_alias: $idp_cert_alias, idp_cert_alias_type_hint: $idp_cert_alias_type_hint, add_group_memberships: $add_group_memberships, add_group_memberships_type_hint: $add_group_memberships_type_hint, path: $path, path_type_hint: $path_type_hint, synchronize_attributes: $synchronize_attributes, synchronize_attributes_type_hint: $synchronize_attributes_type_hint, clock_tolerance: $clock_tolerance, clock_tolerance_type_hint: $clock_tolerance_type_hint, group_membership_attribute: $group_membership_attribute, group_membership_attribute_type_hint: $group_membership_attribute_type_hint, idp_url: $idp_url, idp_url_type_hint: $idp_url_type_hint, logout_url: $logout_url, logout_url_type_hint: $logout_url_type_hint, service_provider_entity_id: $service_provider_entity_id, service_provider_entity_id_type_hint: $service_provider_entity_id_type_hint, assertion_consumer_service_url: $assertion_consumer_service_url, assertion_consumer_service_url_type_hint: $assertion_consumer_service_url_type_hint, handle_logout: $handle_logout, handle_logout_type_hint: $handle_logout_type_hint, sp_private_key_alias: $sp_private_key_alias, sp_private_key_alias_type_hint: $sp_private_key_alias_type_hint, use_encryption: $use_encryption, use_encryption_type_hint: $use_encryption_type_hint, name_id_format: $name_id_format, name_id_format_type_hint: $name_id_format_type_hint, digest_method: $digest_method, digest_method_type_hint: $digest_method_type_hint, signature_method: $signature_method, signature_method_type_hint: $signature_method_type_hint, user_intermediate_path: $user_intermediate_path, user_intermediate_path_type_hint: $user_intermediate_path_type_hint
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /apps/system/config/com.shinesolutions.aem.passwordreset.Activator
#
# operationId: postConfigAemPasswordReset
export def "post-config-aem-password-reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pwdreset-authorizables: list<string>
  --pwdreset-authorizables-type-hint: string
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/system/config/com.shinesolutions.aem.passwordreset.Activator"
    query: [{name: "pwdreset.authorizables", var: pwdreset_authorizables, style: multi}, {name: "pwdreset.authorizables@TypeHint", var: pwdreset_authorizables_type_hint}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    pwdreset_authorizables: $pwdreset_authorizables, pwdreset_authorizables_type_hint: $pwdreset_authorizables_type_hint
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /apps/system/config/com.shinesolutions.healthcheck.hc.impl.ActiveBundleHealthCheck
#
# operationId: postConfigAemHealthCheckServlet
export def "post-config-aem-health-check-servlet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bundles-ignored: list<string>
  --bundles-ignored-type-hint: string
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/system/config/com.shinesolutions.healthcheck.hc.impl.ActiveBundleHealthCheck"
    query: [{name: "bundles.ignored", var: bundles_ignored, style: multi}, {name: "bundles.ignored@TypeHint", var: bundles_ignored_type_hint}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    bundles_ignored: $bundles_ignored, bundles_ignored_type_hint: $bundles_ignored_type_hint
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /apps/system/config/org.apache.felix.http
#
# operationId: postConfigApacheFelixJettyBasedHttpService
export def "post-config-apache-felix-jetty-based-http-service" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --org-apache-felix-https-nio: oneof<nothing, bool>
  --org-apache-felix-https-nio-type-hint: string
  --org-apache-felix-https-keystore: string
  --org-apache-felix-https-keystore-type-hint: string
  --org-apache-felix-https-keystore-password: string
  --org-apache-felix-https-keystore-password-type-hint: string
  --org-apache-felix-https-keystore-key: string
  --org-apache-felix-https-keystore-key-type-hint: string
  --org-apache-felix-https-keystore-key-password: string
  --org-apache-felix-https-keystore-key-password-type-hint: string
  --org-apache-felix-https-truststore: string
  --org-apache-felix-https-truststore-type-hint: string
  --org-apache-felix-https-truststore-password: string
  --org-apache-felix-https-truststore-password-type-hint: string
  --org-apache-felix-https-clientcertificate: string
  --org-apache-felix-https-clientcertificate-type-hint: string
  --org-apache-felix-https-enable: oneof<nothing, bool>
  --org-apache-felix-https-enable-type-hint: string
  --org-osgi-service-http-port-secure: string
  --org-osgi-service-http-port-secure-type-hint: string
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/system/config/org.apache.felix.http"
    query: [{name: "org.apache.felix.https.nio", var: org_apache_felix_https_nio}, {name: "org.apache.felix.https.nio@TypeHint", var: org_apache_felix_https_nio_type_hint}, {name: "org.apache.felix.https.keystore", var: org_apache_felix_https_keystore}, {name: "org.apache.felix.https.keystore@TypeHint", var: org_apache_felix_https_keystore_type_hint}, {name: "org.apache.felix.https.keystore.password", var: org_apache_felix_https_keystore_password}, {name: "org.apache.felix.https.keystore.password@TypeHint", var: org_apache_felix_https_keystore_password_type_hint}, {name: "org.apache.felix.https.keystore.key", var: org_apache_felix_https_keystore_key}, {name: "org.apache.felix.https.keystore.key@TypeHint", var: org_apache_felix_https_keystore_key_type_hint}, {name: "org.apache.felix.https.keystore.key.password", var: org_apache_felix_https_keystore_key_password}, {name: "org.apache.felix.https.keystore.key.password@TypeHint", var: org_apache_felix_https_keystore_key_password_type_hint}, {name: "org.apache.felix.https.truststore", var: org_apache_felix_https_truststore}, {name: "org.apache.felix.https.truststore@TypeHint", var: org_apache_felix_https_truststore_type_hint}, {name: "org.apache.felix.https.truststore.password", var: org_apache_felix_https_truststore_password}, {name: "org.apache.felix.https.truststore.password@TypeHint", var: org_apache_felix_https_truststore_password_type_hint}, {name: "org.apache.felix.https.clientcertificate", var: org_apache_felix_https_clientcertificate}, {name: "org.apache.felix.https.clientcertificate@TypeHint", var: org_apache_felix_https_clientcertificate_type_hint}, {name: "org.apache.felix.https.enable", var: org_apache_felix_https_enable}, {name: "org.apache.felix.https.enable@TypeHint", var: org_apache_felix_https_enable_type_hint}, {name: "org.osgi.service.http.port.secure", var: org_osgi_service_http_port_secure}, {name: "org.osgi.service.http.port.secure@TypeHint", var: org_osgi_service_http_port_secure_type_hint}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    org_apache_felix_https_nio: $org_apache_felix_https_nio, org_apache_felix_https_nio_type_hint: $org_apache_felix_https_nio_type_hint, org_apache_felix_https_keystore: $org_apache_felix_https_keystore, org_apache_felix_https_keystore_type_hint: $org_apache_felix_https_keystore_type_hint, org_apache_felix_https_keystore_password: $org_apache_felix_https_keystore_password, org_apache_felix_https_keystore_password_type_hint: $org_apache_felix_https_keystore_password_type_hint, org_apache_felix_https_keystore_key: $org_apache_felix_https_keystore_key, org_apache_felix_https_keystore_key_type_hint: $org_apache_felix_https_keystore_key_type_hint, org_apache_felix_https_keystore_key_password: $org_apache_felix_https_keystore_key_password, org_apache_felix_https_keystore_key_password_type_hint: $org_apache_felix_https_keystore_key_password_type_hint, org_apache_felix_https_truststore: $org_apache_felix_https_truststore, org_apache_felix_https_truststore_type_hint: $org_apache_felix_https_truststore_type_hint, org_apache_felix_https_truststore_password: $org_apache_felix_https_truststore_password, org_apache_felix_https_truststore_password_type_hint: $org_apache_felix_https_truststore_password_type_hint, org_apache_felix_https_clientcertificate: $org_apache_felix_https_clientcertificate, org_apache_felix_https_clientcertificate_type_hint: $org_apache_felix_https_clientcertificate_type_hint, org_apache_felix_https_enable: $org_apache_felix_https_enable, org_apache_felix_https_enable_type_hint: $org_apache_felix_https_enable_type_hint, org_osgi_service_http_port_secure: $org_osgi_service_http_port_secure, org_osgi_service_http_port_secure_type_hint: $org_osgi_service_http_port_secure_type_hint
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /apps/system/config/org.apache.http.proxyconfigurator.config
#
# operationId: postConfigApacheHttpComponentsProxyConfiguration
export def "post-config-apache-http-components-proxy-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --proxy-host: string
  --proxy-host-type-hint: string
  --proxy-port: int
  --proxy-port-type-hint: string
  --proxy-exceptions: list<string>
  --proxy-exceptions-type-hint: string
  --proxy-enabled: oneof<nothing, bool>
  --proxy-enabled-type-hint: string
  --proxy-user: string
  --proxy-user-type-hint: string
  --proxy-password: string
  --proxy-password-type-hint: string
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/system/config/org.apache.http.proxyconfigurator.config"
    query: [{name: "proxy.host", var: proxy_host}, {name: "proxy.host@TypeHint", var: proxy_host_type_hint}, {name: "proxy.port", var: proxy_port}, {name: "proxy.port@TypeHint", var: proxy_port_type_hint}, {name: "proxy.exceptions", var: proxy_exceptions, style: multi}, {name: "proxy.exceptions@TypeHint", var: proxy_exceptions_type_hint}, {name: "proxy.enabled", var: proxy_enabled}, {name: "proxy.enabled@TypeHint", var: proxy_enabled_type_hint}, {name: "proxy.user", var: proxy_user}, {name: "proxy.user@TypeHint", var: proxy_user_type_hint}, {name: "proxy.password", var: proxy_password}, {name: "proxy.password@TypeHint", var: proxy_password_type_hint}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    proxy_host: $proxy_host, proxy_host_type_hint: $proxy_host_type_hint, proxy_port: $proxy_port, proxy_port_type_hint: $proxy_port_type_hint, proxy_exceptions: $proxy_exceptions, proxy_exceptions_type_hint: $proxy_exceptions_type_hint, proxy_enabled: $proxy_enabled, proxy_enabled_type_hint: $proxy_enabled_type_hint, proxy_user: $proxy_user, proxy_user_type_hint: $proxy_user_type_hint, proxy_password: $proxy_password, proxy_password_type_hint: $proxy_password_type_hint
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /apps/system/config/org.apache.sling.jcr.davex.impl.servlets.SlingDavExServlet
#
# operationId: postConfigApacheSlingDavExServlet
export def "post-config-apache-sling-dav-ex-servlet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alias: string
  --alias-type-hint: string
  --dav-create-absolute-uri: oneof<nothing, bool>
  --dav-create-absolute-uri-type-hint: string
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/system/config/org.apache.sling.jcr.davex.impl.servlets.SlingDavExServlet"
    query: [{name: alias, var: alias}, {name: "alias@TypeHint", var: alias_type_hint}, {name: "dav.create-absolute-uri", var: dav_create_absolute_uri}, {name: "dav.create-absolute-uri@TypeHint", var: dav_create_absolute_uri_type_hint}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    alias: $alias, alias_type_hint: $alias_type_hint, dav_create_absolute_uri: $dav_create_absolute_uri, dav_create_absolute_uri_type_hint: $dav_create_absolute_uri_type_hint
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /apps/system/config/org.apache.sling.security.impl.ReferrerFilter
#
# operationId: postConfigApacheSlingReferrerFilter
export def "post-config-apache-sling-referrer-filter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-empty: oneof<nothing, bool>
  --allow-empty-type-hint: string
  --allow-hosts: string
  --allow-hosts-type-hint: string
  --allow-hosts-regexp: string
  --allow-hosts-regexp-type-hint: string
  --filter-methods: string
  --filter-methods-type-hint: string
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/system/config/org.apache.sling.security.impl.ReferrerFilter"
    query: [{name: "allow.empty", var: allow_empty}, {name: "allow.empty@TypeHint", var: allow_empty_type_hint}, {name: "allow.hosts", var: allow_hosts}, {name: "allow.hosts@TypeHint", var: allow_hosts_type_hint}, {name: "allow.hosts.regexp", var: allow_hosts_regexp}, {name: "allow.hosts.regexp@TypeHint", var: allow_hosts_regexp_type_hint}, {name: "filter.methods", var: filter_methods}, {name: "filter.methods@TypeHint", var: filter_methods_type_hint}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    allow_empty: $allow_empty, allow_empty_type_hint: $allow_empty_type_hint, allow_hosts: $allow_hosts, allow_hosts_type_hint: $allow_hosts_type_hint, allow_hosts_regexp: $allow_hosts_regexp, allow_hosts_regexp_type_hint: $allow_hosts_regexp_type_hint, filter_methods: $filter_methods, filter_methods_type_hint: $filter_methods_type_hint
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /apps/system/config/org.apache.sling.servlets.get.DefaultGetServlet
#
# operationId: postConfigApacheSlingGetServlet
export def "post-config-apache-sling-get-servlet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --json-maximumresults: string
  --json-maximumresults-type-hint: string
  --enable-html: oneof<nothing, bool>
  --enable-html-type-hint: string
  --enable-txt: oneof<nothing, bool>
  --enable-txt-type-hint: string
  --enable-xml: oneof<nothing, bool>
  --enable-xml-type-hint: string
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/system/config/org.apache.sling.servlets.get.DefaultGetServlet"
    query: [{name: "json.maximumresults", var: json_maximumresults}, {name: "json.maximumresults@TypeHint", var: json_maximumresults_type_hint}, {name: "enable.html", var: enable_html}, {name: "enable.html@TypeHint", var: enable_html_type_hint}, {name: "enable.txt", var: enable_txt}, {name: "enable.txt@TypeHint", var: enable_txt_type_hint}, {name: "enable.xml", var: enable_xml}, {name: "enable.xml@TypeHint", var: enable_xml_type_hint}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    json_maximumresults: $json_maximumresults, json_maximumresults_type_hint: $json_maximumresults_type_hint, enable_html: $enable_html, enable_html_type_hint: $enable_html_type_hint, enable_txt: $enable_txt, enable_txt_type_hint: $enable_txt_type_hint, enable_xml: $enable_xml, enable_xml_type_hint: $enable_xml_type_hint
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /apps/system/config/{configNodeName}
#
# operationId: postConfigProperty
export def "post-config-property" [
  config_node_name: string
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
    path: "/apps/system/config/{configNodeName}"
    path_params: [{name: configNodeName, var: config_node_name}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    config_node_name: $config_node_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /bin/querybuilder.json
#
# Returns: string
# operationId: getQuery
export def "get-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # required
  --p-limit: float # required
  --1-property: string # required
  --1-property-value: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/bin/querybuilder.json"
    query: [{name: path, var: path, required: true}, {name: "p.limit", var: p_limit, required: true}, {name: "1_property", var: "1_property", required: true}, {name: "1_property.value", var: "1_property_value", required: true}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    path: $path, p_limit: $p_limit, "1_property": $1_property, "1_property_value": $1_property_value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /bin/querybuilder.json
#
# Returns: string
# operationId: postQuery
export def "post-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # required
  --p-limit: float # required
  --1-property: string # required
  --1-property-value: string # required
]: nothing -> any {
  http-request {
    method: post
    path: "/bin/querybuilder.json"
    query: [{name: path, var: path, required: true}, {name: "p.limit", var: p_limit, required: true}, {name: "1_property", var: "1_property", required: true}, {name: "1_property.value", var: "1_property_value", required: true}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    path: $path, p_limit: $p_limit, "1_property": $1_property, "1_property_value": $1_property_value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /crx/explorer/ui/setpassword.jsp
#
# Returns: string
# operationId: postSetPassword
export def "post-set-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --old: string # required
  --plain: string # required
  --verify: string # required
]: nothing -> any {
  http-request {
    method: post
    path: "/crx/explorer/ui/setpassword.jsp"
    query: [{name: old, var: old, required: true}, {name: plain, var: plain, required: true}, {name: verify, var: verify, required: true}]
    accept: ["text/plain"]
    ok: []
    auth: basic
  } {
    old: $old, plain: $plain, verify: $verify
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /crx/packmgr/installstatus.jsp
#
# Returns: record<status: record<finished: bool, itemCount: int>>
# operationId: getInstallStatus
export def "get-install-status" [
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
    path: "/crx/packmgr/installstatus.jsp"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /crx/packmgr/service.jsp
#
# operationId: postPackageService
export def "post-package-service" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cmd: string # required
]: nothing -> any {
  http-request {
    method: post
    path: "/crx/packmgr/service.jsp"
    query: [{name: cmd, var: cmd, required: true}]
    accept: ["text/xml"]
    ok: []
    auth: basic
  } {
    cmd: $cmd
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /crx/packmgr/service/.json/{path}
#
# Returns: string
# operationId: postPackageServiceJson
export def "post-package-service-json" [
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
  --cmd: string # required
  --group-name: string
  --package-name: string
  --package-version: string
  --charset: string
  --force: oneof<nothing, bool>
  --recursive: oneof<nothing, bool>
  --package: string # format: binary
]: any -> any {
  $in | http-request {
    method: post
    path: "/crx/packmgr/service/.json/{path}"
    path_params: [{name: path, var: path}]
    query: [{name: cmd, var: cmd, required: true}, {name: groupName, var: group_name}, {name: packageName, var: package_name}, {name: packageVersion, var: package_version}, {name: _charset_, var: charset}, {name: force, var: force}, {name: recursive, var: recursive}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: package, var: package}], files: [package]}
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    path: $path, cmd: $cmd, group_name: $group_name, package_name: $package_name, package_version: $package_version, charset: $charset, force: $force, recursive: $recursive, package: $package
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /crx/packmgr/service/script.html
#
# operationId: getPackageManagerServlet
export def "get-package-manager-servlet" [
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
    path: "/crx/packmgr/service/script.html"
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /crx/packmgr/update.jsp
#
# Returns: string
# operationId: postPackageUpdate
export def "post-package-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-name: string # required
  --package-name: string # required
  --version: string # required
  --path: string # required
  --filter: string
  --charset: string
]: nothing -> any {
  http-request {
    method: post
    path: "/crx/packmgr/update.jsp"
    query: [{name: groupName, var: group_name, required: true}, {name: packageName, var: package_name, required: true}, {name: version, var: version, required: true}, {name: path, var: path, required: true}, {name: filter, var: filter}, {name: _charset_, var: charset}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    group_name: $group_name, package_name: $package_name, version: $version, path: $path, filter: $filter, charset: $charset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /crx/server/crx.default/jcr:root/.1.json
#
# Returns: string
# operationId: getCrxdeStatus
export def "get-crxde-status" [
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
    path: "/crx/server/crx.default/jcr:root/.1.json"
    accept: ["plain/text"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /etc/packages/{group}/{name}-{version}.zip
#
# Returns: binary
# operationId: getPackage
export def "get-package" [
  group: string
  name: string
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
    method: get
    path: "/etc/packages/{group}/{name}-{version}.zip"
    path_params: [{name: group, var: group}, {name: name, var: name}, {name: version, var: version}]
    accept: ["application/octet-stream"]
    ok: []
    auth: basic
  } {
    group: $group, name: $name, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /etc/packages/{group}/{name}-{version}.zip/jcr:content/vlt:definition/filter.tidy.2.json
#
# Returns: string
# operationId: getPackageFilter
export def "get-package-filter" [
  group: string
  name: string
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
    method: get
    path: "/etc/packages/{group}/{name}-{version}.zip/jcr:content/vlt:definition/filter.tidy.2.json"
    path_params: [{name: group, var: group}, {name: name, var: name}, {name: version, var: version}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    group: $group, name: $name, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /etc/replication/agents.{runmode}.-1.json
#
# Returns: string
# operationId: getAgents
export def "get-agents" [
  runmode: string
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
    path: "/etc/replication/agents.{runmode}.-1.json"
    path_params: [{name: runmode, var: runmode}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    runmode: $runmode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /etc/replication/agents.{runmode}/{name}
#
# operationId: deleteAgent
export def "delete-agent" [
  runmode: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/etc/replication/agents.{runmode}/{name}"
    path_params: [{name: runmode, var: runmode}, {name: name, var: name}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    runmode: $runmode, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /etc/replication/agents.{runmode}/{name}
#
# operationId: getAgent
export def "get-agent" [
  runmode: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/etc/replication/agents.{runmode}/{name}"
    path_params: [{name: runmode, var: runmode}, {name: name, var: name}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    runmode: $runmode, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /etc/replication/agents.{runmode}/{name}
#
# operationId: postAgent
export def "post-agent" [
  runmode: string
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
  --jcr-content-cq-distribute: oneof<nothing, bool>
  --jcr-content-cq-distribute-type-hint: string
  --jcr-content-cq-name: string
  --jcr-content-cq-template: string
  --jcr-content-enabled: oneof<nothing, bool>
  --jcr-content-jcr-description: string
  --jcr-content-jcr-last-modified: string
  --jcr-content-jcr-last-modified-by: string
  --jcr-content-jcr-mixin-types: string
  --jcr-content-jcr-title: string
  --jcr-content-log-level: string
  --jcr-content-no-status-update: oneof<nothing, bool>
  --jcr-content-no-versioning: oneof<nothing, bool>
  --jcr-content-protocol-connect-timeout: float
  --jcr-content-protocol-http-connection-closed: oneof<nothing, bool>
  --jcr-content-protocol-http-expired: string
  --jcr-content-protocol-http-headers: list<string>
  --jcr-content-protocol-http-headers-type-hint: string
  --jcr-content-protocol-http-method: string
  --jcr-content-protocol-https-relaxed: oneof<nothing, bool>
  --jcr-content-protocol-interface: string
  --jcr-content-protocol-socket-timeout: float
  --jcr-content-protocol-version: string
  --jcr-content-proxy-ntlm-domain: string
  --jcr-content-proxy-ntlm-host: string
  --jcr-content-proxy-host: string
  --jcr-content-proxy-password: string
  --jcr-content-proxy-port: float
  --jcr-content-proxy-user: string
  --jcr-content-queue-batch-max-size: float
  --jcr-content-queue-batch-mode: string
  --jcr-content-queue-batch-wait-time: float
  --jcr-content-retry-delay: string
  --jcr-content-reverse-replication: oneof<nothing, bool>
  --jcr-content-serialization-type: string
  --jcr-content-sling-resource-type: string
  --jcr-content-ssl: string
  --jcr-content-transport-ntlm-domain: string
  --jcr-content-transport-ntlm-host: string
  --jcr-content-transport-password: string
  --jcr-content-transport-uri: string
  --jcr-content-transport-user: string
  --jcr-content-trigger-distribute: oneof<nothing, bool>
  --jcr-content-trigger-modified: oneof<nothing, bool>
  --jcr-content-trigger-on-off-time: oneof<nothing, bool>
  --jcr-content-trigger-receive: oneof<nothing, bool>
  --jcr-content-trigger-specific: oneof<nothing, bool>
  --jcr-content-user-id: string
  --jcr-primary-type: string
  --operation: string
]: nothing -> any {
  http-request {
    method: post
    path: "/etc/replication/agents.{runmode}/{name}"
    path_params: [{name: runmode, var: runmode}, {name: name, var: name}]
    query: [{name: "jcr:content/cq:distribute", var: jcr_content_cq_distribute}, {name: "jcr:content/cq:distribute@TypeHint", var: jcr_content_cq_distribute_type_hint}, {name: "jcr:content/cq:name", var: jcr_content_cq_name}, {name: "jcr:content/cq:template", var: jcr_content_cq_template}, {name: "jcr:content/enabled", var: jcr_content_enabled}, {name: "jcr:content/jcr:description", var: jcr_content_jcr_description}, {name: "jcr:content/jcr:lastModified", var: jcr_content_jcr_last_modified}, {name: "jcr:content/jcr:lastModifiedBy", var: jcr_content_jcr_last_modified_by}, {name: "jcr:content/jcr:mixinTypes", var: jcr_content_jcr_mixin_types}, {name: "jcr:content/jcr:title", var: jcr_content_jcr_title}, {name: "jcr:content/logLevel", var: jcr_content_log_level}, {name: "jcr:content/noStatusUpdate", var: jcr_content_no_status_update}, {name: "jcr:content/noVersioning", var: jcr_content_no_versioning}, {name: "jcr:content/protocolConnectTimeout", var: jcr_content_protocol_connect_timeout}, {name: "jcr:content/protocolHTTPConnectionClosed", var: jcr_content_protocol_http_connection_closed}, {name: "jcr:content/protocolHTTPExpired", var: jcr_content_protocol_http_expired}, {name: "jcr:content/protocolHTTPHeaders", var: jcr_content_protocol_http_headers, style: multi}, {name: "jcr:content/protocolHTTPHeaders@TypeHint", var: jcr_content_protocol_http_headers_type_hint}, {name: "jcr:content/protocolHTTPMethod", var: jcr_content_protocol_http_method}, {name: "jcr:content/protocolHTTPSRelaxed", var: jcr_content_protocol_https_relaxed}, {name: "jcr:content/protocolInterface", var: jcr_content_protocol_interface}, {name: "jcr:content/protocolSocketTimeout", var: jcr_content_protocol_socket_timeout}, {name: "jcr:content/protocolVersion", var: jcr_content_protocol_version}, {name: "jcr:content/proxyNTLMDomain", var: jcr_content_proxy_ntlm_domain}, {name: "jcr:content/proxyNTLMHost", var: jcr_content_proxy_ntlm_host}, {name: "jcr:content/proxyHost", var: jcr_content_proxy_host}, {name: "jcr:content/proxyPassword", var: jcr_content_proxy_password}, {name: "jcr:content/proxyPort", var: jcr_content_proxy_port}, {name: "jcr:content/proxyUser", var: jcr_content_proxy_user}, {name: "jcr:content/queueBatchMaxSize", var: jcr_content_queue_batch_max_size}, {name: "jcr:content/queueBatchMode", var: jcr_content_queue_batch_mode}, {name: "jcr:content/queueBatchWaitTime", var: jcr_content_queue_batch_wait_time}, {name: "jcr:content/retryDelay", var: jcr_content_retry_delay}, {name: "jcr:content/reverseReplication", var: jcr_content_reverse_replication}, {name: "jcr:content/serializationType", var: jcr_content_serialization_type}, {name: "jcr:content/sling:resourceType", var: jcr_content_sling_resource_type}, {name: "jcr:content/ssl", var: jcr_content_ssl}, {name: "jcr:content/transportNTLMDomain", var: jcr_content_transport_ntlm_domain}, {name: "jcr:content/transportNTLMHost", var: jcr_content_transport_ntlm_host}, {name: "jcr:content/transportPassword", var: jcr_content_transport_password}, {name: "jcr:content/transportUri", var: jcr_content_transport_uri}, {name: "jcr:content/transportUser", var: jcr_content_transport_user}, {name: "jcr:content/triggerDistribute", var: jcr_content_trigger_distribute}, {name: "jcr:content/triggerModified", var: jcr_content_trigger_modified}, {name: "jcr:content/triggerOnOffTime", var: jcr_content_trigger_on_off_time}, {name: "jcr:content/triggerReceive", var: jcr_content_trigger_receive}, {name: "jcr:content/triggerSpecific", var: jcr_content_trigger_specific}, {name: "jcr:content/userId", var: jcr_content_user_id}, {name: "jcr:primaryType", var: jcr_primary_type}, {name: ":operation", var: operation}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    runmode: $runmode, name: $name, jcr_content_cq_distribute: $jcr_content_cq_distribute, jcr_content_cq_distribute_type_hint: $jcr_content_cq_distribute_type_hint, jcr_content_cq_name: $jcr_content_cq_name, jcr_content_cq_template: $jcr_content_cq_template, jcr_content_enabled: $jcr_content_enabled, jcr_content_jcr_description: $jcr_content_jcr_description, jcr_content_jcr_last_modified: $jcr_content_jcr_last_modified, jcr_content_jcr_last_modified_by: $jcr_content_jcr_last_modified_by, jcr_content_jcr_mixin_types: $jcr_content_jcr_mixin_types, jcr_content_jcr_title: $jcr_content_jcr_title, jcr_content_log_level: $jcr_content_log_level, jcr_content_no_status_update: $jcr_content_no_status_update, jcr_content_no_versioning: $jcr_content_no_versioning, jcr_content_protocol_connect_timeout: $jcr_content_protocol_connect_timeout, jcr_content_protocol_http_connection_closed: $jcr_content_protocol_http_connection_closed, jcr_content_protocol_http_expired: $jcr_content_protocol_http_expired, jcr_content_protocol_http_headers: $jcr_content_protocol_http_headers, jcr_content_protocol_http_headers_type_hint: $jcr_content_protocol_http_headers_type_hint, jcr_content_protocol_http_method: $jcr_content_protocol_http_method, jcr_content_protocol_https_relaxed: $jcr_content_protocol_https_relaxed, jcr_content_protocol_interface: $jcr_content_protocol_interface, jcr_content_protocol_socket_timeout: $jcr_content_protocol_socket_timeout, jcr_content_protocol_version: $jcr_content_protocol_version, jcr_content_proxy_ntlm_domain: $jcr_content_proxy_ntlm_domain, jcr_content_proxy_ntlm_host: $jcr_content_proxy_ntlm_host, jcr_content_proxy_host: $jcr_content_proxy_host, jcr_content_proxy_password: $jcr_content_proxy_password, jcr_content_proxy_port: $jcr_content_proxy_port, jcr_content_proxy_user: $jcr_content_proxy_user, jcr_content_queue_batch_max_size: $jcr_content_queue_batch_max_size, jcr_content_queue_batch_mode: $jcr_content_queue_batch_mode, jcr_content_queue_batch_wait_time: $jcr_content_queue_batch_wait_time, jcr_content_retry_delay: $jcr_content_retry_delay, jcr_content_reverse_replication: $jcr_content_reverse_replication, jcr_content_serialization_type: $jcr_content_serialization_type, jcr_content_sling_resource_type: $jcr_content_sling_resource_type, jcr_content_ssl: $jcr_content_ssl, jcr_content_transport_ntlm_domain: $jcr_content_transport_ntlm_domain, jcr_content_transport_ntlm_host: $jcr_content_transport_ntlm_host, jcr_content_transport_password: $jcr_content_transport_password, jcr_content_transport_uri: $jcr_content_transport_uri, jcr_content_transport_user: $jcr_content_transport_user, jcr_content_trigger_distribute: $jcr_content_trigger_distribute, jcr_content_trigger_modified: $jcr_content_trigger_modified, jcr_content_trigger_on_off_time: $jcr_content_trigger_on_off_time, jcr_content_trigger_receive: $jcr_content_trigger_receive, jcr_content_trigger_specific: $jcr_content_trigger_specific, jcr_content_user_id: $jcr_content_user_id, jcr_primary_type: $jcr_primary_type, operation: $operation
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /etc/truststore
#
# Returns: string
# operationId: postTruststorePKCS12
export def "post-truststore-pkcs12" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --truststore-p12: string # format: binary
]: any -> any {
  $in | http-request {
    method: post
    path: "/etc/truststore"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: "truststore.p12", var: truststore_p12}], files: ["truststore.p12"]}
    accept: ["text/plain"]
    ok: []
    auth: basic
  } {
    truststore_p12: $truststore_p12
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /etc/truststore/truststore.p12
#
# Returns: binary
# operationId: getTruststore
export def "get-truststore" [
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
    path: "/etc/truststore/truststore.p12"
    accept: ["application/octet-stream"]
    ok: []
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /libs/granite/core/content/login.html
#
# Returns: string
# operationId: getLoginPage
export def "get-login-page" [
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
    path: "/libs/granite/core/content/login.html"
    accept: ["text/html"]
    ok: []
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /libs/granite/security/post/authorizables
#
# Returns: string
# operationId: postAuthorizables
export def "post-authorizables" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorizable-id: string # required
  --intermediate-path: string # required
  --create-user: string
  --create-group: string
  --rep-password: string
  --profile-given-name: string
]: nothing -> any {
  http-request {
    method: post
    path: "/libs/granite/security/post/authorizables"
    query: [{name: authorizableId, var: authorizable_id, required: true}, {name: intermediatePath, var: intermediate_path, required: true}, {name: createUser, var: create_user}, {name: createGroup, var: create_group}, {name: "rep:password", var: rep_password}, {name: "profile/givenName", var: profile_given_name}]
    accept: ["text/html"]
    ok: []
    auth: basic
  } {
    authorizable_id: $authorizable_id, intermediate_path: $intermediate_path, create_user: $create_user, create_group: $create_group, rep_password: $rep_password, profile_given_name: $profile_given_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /libs/granite/security/post/sslSetup.html
#
# Returns: string
# operationId: sslSetup
export def "ssl-setup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --keystore-password: string # required
  --keystore-password-confirm: string # required
  --truststore-password: string # required
  --truststore-password-confirm: string # required
  --https-hostname: string # required
  --https-port: string # required
  --certificate-file: string # format: binary
  --privatekey-file: string # format: binary
]: any -> any {
  $in | http-request {
    method: post
    path: "/libs/granite/security/post/sslSetup.html"
    query: [{name: keystorePassword, var: keystore_password, required: true}, {name: keystorePasswordConfirm, var: keystore_password_confirm, required: true}, {name: truststorePassword, var: truststore_password, required: true}, {name: truststorePasswordConfirm, var: truststore_password_confirm, required: true}, {name: httpsHostname, var: https_hostname, required: true}, {name: httpsPort, var: https_port, required: true}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: certificateFile, var: certificate_file}, {name: privatekeyFile, var: privatekey_file}], files: [certificateFile, privatekeyFile]}
    accept: ["text/plain"]
    ok: []
    auth: basic
  } {
    keystore_password: $keystore_password, keystore_password_confirm: $keystore_password_confirm, truststore_password: $truststore_password, truststore_password_confirm: $truststore_password_confirm, https_hostname: $https_hostname, https_port: $https_port, certificate_file: $certificate_file, privatekey_file: $privatekey_file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /libs/granite/security/post/truststore
#
# Returns: string
# operationId: postTruststore
export def "post-truststore" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string
  --new-password: string
  --re-password: string
  --key-store-type: string
  --remove-alias: string
  --certificate: string # format: binary
]: any -> any {
  $in | http-request {
    method: post
    path: "/libs/granite/security/post/truststore"
    query: [{name: ":operation", var: operation}, {name: newPassword, var: new_password}, {name: rePassword, var: re_password}, {name: keyStoreType, var: key_store_type}, {name: removeAlias, var: remove_alias}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: certificate, var: certificate}], files: [certificate]}
    accept: ["text/plain"]
    ok: []
    auth: basic
  } {
    operation: $operation, new_password: $new_password, re_password: $re_password, key_store_type: $key_store_type, remove_alias: $remove_alias, certificate: $certificate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /libs/granite/security/truststore.json
#
# Returns: record<aliases: table<alias: string, entryType: string, issuer: string, notAfter: string, notBefore: string, serialNumber: int, subject: string>, exists: bool>
# operationId: getTruststoreInfo
export def "get-truststore-info" [
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
    path: "/libs/granite/security/truststore.json"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /libs/replication/treeactivation.html
#
# operationId: postTreeActivation
export def "post-tree-activation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ignoredeactivated: oneof<nothing, bool> # required
  --onlymodified: oneof<nothing, bool> # required
  --path: string # required
  --cmd: string # required, default: activate
]: nothing -> any {
  http-request {
    method: post
    path: "/libs/replication/treeactivation.html"
    query: [{name: ignoredeactivated, var: ignoredeactivated, required: true}, {name: onlymodified, var: onlymodified, required: true}, {name: path, var: path, required: true}, {name: cmd, var: cmd, required: true, default: activate}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    ignoredeactivated: $ignoredeactivated, onlymodified: $onlymodified, path: $path, cmd: $cmd
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /system/console/bundles/{name}
#
# operationId: postBundle
export def "post-bundle" [
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
  --action: string # required
]: nothing -> any {
  http-request {
    method: post
    path: "/system/console/bundles/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: action, var: action, required: true}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    name: $name, action: $action
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /system/console/bundles/{name}.json
#
# Returns: record<data: table<category: string, fragment: bool, id: int, name: string, props: list, state: string, stateRaw: int, symbolicName: string, version: string>, s: list<int>, status: string>
# operationId: getBundleInfo
export def "get-bundle-info" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/system/console/bundles/{name}.json"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /system/console/configMgr
#
# operationId: getConfigMgr
export def "get-config-mgr" [
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
    path: "/system/console/configMgr"
    accept: ["text/xml"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /system/console/configMgr/com.adobe.granite.auth.saml.SamlAuthenticationHandler
#
# Returns: record<bundle_location: string, description: string, pid: string, properties: record<addGroupMemberships: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: bool>, assertionConsumerServiceURL: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: string>, clockTolerance: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: int>, createUser: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: bool>, defaultGroups: record<description: string, is_set: bool, name: string, optional: bool, type: int, values: list>, defaultRedirectUrl: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: string>, digestMethod: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: string>, groupMembershipAttribute: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: string>, handleLogout: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: bool>, idpCertAlias: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: string>, idpHttpRedirect: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: bool>, idpUrl: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: string>, keyStorePassword: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: string>, logoutUrl: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: string>, nameIdFormat: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: string>, path: record<description: string, is_set: bool, name: string, optional: bool, type: int, values: list>, "service.ranking": record<description: string, is_set: bool, name: string, optional: bool, type: int, value: int>, serviceProviderEntityId: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: string>, signatureMethod: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: string>, spPrivateKeyAlias: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: string>, synchronizeAttributes: record<description: string, is_set: bool, name: string, optional: bool, type: int, values: list>, useEncryption: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: bool>, userIDAttribute: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: string>, userIntermediatePath: record<description: string, is_set: bool, name: string, optional: bool, type: int, value: string>>, service_location: string, title: string>
# operationId: postSamlConfiguration
export def "post-saml-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --post: oneof<nothing, bool>
  --apply: oneof<nothing, bool>
  --delete: oneof<nothing, bool>
  --action: string
  --location: string
  --path: list<string>
  --service-ranking: int
  --idp-url: string
  --idp-cert-alias: string
  --idp-http-redirect: oneof<nothing, bool>
  --service-provider-entity-id: string
  --assertion-consumer-service-url: string
  --sp-private-key-alias: string
  --key-store-password: string
  --default-redirect-url: string
  --user-id-attribute: string
  --use-encryption: oneof<nothing, bool>
  --create-user: oneof<nothing, bool>
  --add-group-memberships: oneof<nothing, bool>
  --group-membership-attribute: string
  --default-groups: list<string>
  --name-id-format: string
  --synchronize-attributes: list<string>
  --handle-logout: oneof<nothing, bool>
  --logout-url: string
  --clock-tolerance: int
  --digest-method: string
  --signature-method: string
  --user-intermediate-path: string
  --propertylist: list<string>
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/system/console/configMgr/com.adobe.granite.auth.saml.SamlAuthenticationHandler"
    query: [{name: post, var: post}, {name: apply, var: apply}, {name: delete, var: delete}, {name: action, var: action}, {name: "$location", var: location}, {name: path, var: path, style: multi}, {name: "service.ranking", var: service_ranking}, {name: idpUrl, var: idp_url}, {name: idpCertAlias, var: idp_cert_alias}, {name: idpHttpRedirect, var: idp_http_redirect}, {name: serviceProviderEntityId, var: service_provider_entity_id}, {name: assertionConsumerServiceURL, var: assertion_consumer_service_url}, {name: spPrivateKeyAlias, var: sp_private_key_alias}, {name: keyStorePassword, var: key_store_password}, {name: defaultRedirectUrl, var: default_redirect_url}, {name: userIDAttribute, var: user_id_attribute}, {name: useEncryption, var: use_encryption}, {name: createUser, var: create_user}, {name: addGroupMemberships, var: add_group_memberships}, {name: groupMembershipAttribute, var: group_membership_attribute}, {name: defaultGroups, var: default_groups, style: multi}, {name: nameIdFormat, var: name_id_format}, {name: synchronizeAttributes, var: synchronize_attributes, style: multi}, {name: handleLogout, var: handle_logout}, {name: logoutUrl, var: logout_url}, {name: clockTolerance, var: clock_tolerance}, {name: digestMethod, var: digest_method}, {name: signatureMethod, var: signature_method}, {name: userIntermediatePath, var: user_intermediate_path}, {name: propertylist, var: propertylist, style: csv}]
    accept: ["text/plain"]
    ok: [200, 302]
    auth: basic
  } {
    post: $post, apply: $apply, delete: $delete, action: $action, location: $location, path: $path, service_ranking: $service_ranking, idp_url: $idp_url, idp_cert_alias: $idp_cert_alias, idp_http_redirect: $idp_http_redirect, service_provider_entity_id: $service_provider_entity_id, assertion_consumer_service_url: $assertion_consumer_service_url, sp_private_key_alias: $sp_private_key_alias, key_store_password: $key_store_password, default_redirect_url: $default_redirect_url, user_id_attribute: $user_id_attribute, use_encryption: $use_encryption, create_user: $create_user, add_group_memberships: $add_group_memberships, group_membership_attribute: $group_membership_attribute, default_groups: $default_groups, name_id_format: $name_id_format, synchronize_attributes: $synchronize_attributes, handle_logout: $handle_logout, logout_url: $logout_url, clock_tolerance: $clock_tolerance, digest_method: $digest_method, signature_method: $signature_method, user_intermediate_path: $user_intermediate_path, propertylist: $propertylist
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /system/console/jmx/com.adobe.granite:type=Repository/op/{action}
#
# operationId: postJmxRepository
export def "post-jmx-repository" [
  action: string
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
    path: "/system/console/jmx/com.adobe.granite:type=Repository/op/{action}"
    path_params: [{name: action, var: action}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    action: $action
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /system/console/status-productinfo.json
#
# Returns: list<string>
# operationId: getAemProductInfo
export def "get-aem-product-info" [
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
    path: "/system/console/status-productinfo.json"
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /system/health
#
# Returns: string
# operationId: getAemHealthCheck
export def "get-aem-health-check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: string
  --combine-tags-or: oneof<nothing, bool>
]: nothing -> any {
  http-request {
    method: get
    path: "/system/health"
    query: [{name: tags, var: tags}, {name: combineTagsOr, var: combine_tags_or}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    tags: $tags, combine_tags_or: $combine_tags_or
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /{intermediatePath}/{authorizableId}.ks.html
#
# Returns: record<aliases: table<algorithm: string, alias: string, chain: list, entryType: string, format: string>, exists: bool>
# operationId: postAuthorizableKeystore
export def "post-authorizable-keystore" [
  intermediate_path: string
  authorizable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string
  --current-password: string
  --new-password: string
  --re-password: string
  --key-password: string
  --key-store-pass: string
  --alias: string
  --new-alias: string
  --remove-alias: string
  --cert-chain: string # format: binary
  --key-store: string # format: binary
  --pk: string # format: binary
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{intermediatePath}/{authorizableId}.ks.html"
    path_params: [{name: intermediatePath, var: intermediate_path}, {name: authorizableId, var: authorizable_id}]
    query: [{name: ":operation", var: operation}, {name: currentPassword, var: current_password}, {name: newPassword, var: new_password}, {name: rePassword, var: re_password}, {name: keyPassword, var: key_password}, {name: keyStorePass, var: key_store_pass}, {name: alias, var: alias}, {name: newAlias, var: new_alias}, {name: removeAlias, var: remove_alias}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: cert-chain, var: cert_chain}, {name: keyStore, var: key_store}, {name: pk, var: pk}], files: [cert-chain, keyStore, pk]}
    accept: ["text/plain"]
    ok: [200]
    auth: basic
  } {
    intermediate_path: $intermediate_path, authorizable_id: $authorizable_id, operation: $operation, current_password: $current_password, new_password: $new_password, re_password: $re_password, key_password: $key_password, key_store_pass: $key_store_pass, alias: $alias, new_alias: $new_alias, remove_alias: $remove_alias, cert_chain: $cert_chain, key_store: $key_store, pk: $pk
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /{intermediatePath}/{authorizableId}.ks.json
#
# Returns: record<aliases: table<algorithm: string, alias: string, chain: list, entryType: string, format: string>, exists: bool>
# operationId: getAuthorizableKeystore
export def "get-authorizable-keystore" [
  intermediate_path: string
  authorizable_id: string
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
    path: "/{intermediatePath}/{authorizableId}.ks.json"
    path_params: [{name: intermediatePath, var: intermediate_path}, {name: authorizableId, var: authorizable_id}]
    accept: ["text/plain"]
    ok: [200]
    auth: basic
  } {
    intermediate_path: $intermediate_path, authorizable_id: $authorizable_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /{intermediatePath}/{authorizableId}/keystore/store.p12
#
# Returns: binary
# operationId: getKeystore
export def "get-keystore" [
  intermediate_path: string
  authorizable_id: string
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
    path: "/{intermediatePath}/{authorizableId}/keystore/store.p12"
    path_params: [{name: intermediatePath, var: intermediate_path}, {name: authorizableId, var: authorizable_id}]
    accept: ["application/octet-stream"]
    ok: []
    auth: basic
  } {
    intermediate_path: $intermediate_path, authorizable_id: $authorizable_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /{path}/
#
# operationId: postPath
export def "post-path" [
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
  --jcr-primary-type: string # required
  --name: string # required
]: nothing -> any {
  http-request {
    method: post
    path: "/{path}/"
    path_params: [{name: path, var: path}]
    query: [{name: "jcr:primaryType", var: jcr_primary_type, required: true}, {name: ":name", var: name, required: true}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    path: $path, jcr_primary_type: $jcr_primary_type, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /{path}/{name}
#
# operationId: deleteNode
export def "delete-node" [
  path: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/{path}/{name}"
    path_params: [{name: path, var: path}, {name: name, var: name}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    path: $path, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /{path}/{name}
#
# operationId: getNode
export def "get-node" [
  path: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/{path}/{name}"
    path_params: [{name: path, var: path}, {name: name, var: name}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    path: $path, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /{path}/{name}
#
# operationId: postNode
export def "post-node" [
  path: string
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
  --operation: string
  --delete-authorizable: string
  --file: string # format: binary
]: any -> any {
  $in | http-request {
    method: post
    path: "/{path}/{name}"
    path_params: [{name: path, var: path}, {name: name, var: name}]
    query: [{name: ":operation", var: operation}, {name: deleteAuthorizable, var: delete_authorizable}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}], files: [file]}
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    path: $path, name: $name, operation: $operation, delete_authorizable: $delete_authorizable, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /{path}/{name}.rw.html
#
# operationId: postNodeRw
export def "post-node-rw" [
  path: string
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
  --add-members: string
]: nothing -> any {
  http-request {
    method: post
    path: "/{path}/{name}.rw.html"
    path_params: [{name: path, var: path}, {name: name, var: name}]
    query: [{name: addMembers, var: add_members}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    path: $path, name: $name, add_members: $add_members
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
