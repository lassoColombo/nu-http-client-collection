# Auto-generated client for LUIS Authoring Client v3.0-preview
# Source: https://api.apis.guru/v2/specs/azure.com/cognitiveservices-LUIS-Authoring/3.0-preview/swagger.json
# Auth: --token flag or $env.LUIS_AUTHORING_CLIENT_TOKEN

const CLIENT = {
  base_url: "{Endpoint}/luis/authoring/v3.0-preview"
  token_env_var: "LUIS_AUTHORING_CLIENT_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: ocp-apim-subscription-key, in: header, header_name: Ocp-Apim-Subscription-Key, prefix: ""}
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

def base-url-completer [] { ["{Endpoint}/luis/authoring/v3.0-preview"] }
def auth-scheme-completer [] { ["ocp-apim-subscription-key"] }

# Completers for enum parameters
def accept-completer [] { ["JSON" "application/json"] }
def accept-completer-1 [] { ["application/json" "application/octet-stream"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    apps-list: "table<activeVersion: string, createdDateTime: string, culture: string, description: string, domain: string, endpointHitsCount: int, endpoints: record, id: string, name: string, usageScenario: string, versionsCount: int>"
    apps-add: "string"
    apps-list-cortana-endpoints: "record<endpointKeys: list<string>, endpointUrls: record>"
    apps-list-supported-cultures: "table<code: string, name: string>"
    apps-list-available-custom-prebuilt-domains: "table<culture: string, description: string, entities: list<record>, examples: string, intents: list<record>, name: string>"
    apps-add-custom-prebuilt-domain: "string"
    apps-list-available-custom-prebuilt-domains-for-culture: "table<culture: string, description: string, entities: list<record>, examples: string, intents: list<record>, name: string>"
    apps-list-domains: "list<string>"
    apps-import: "string"
    apps-list-usage-scenarios: "list<string>"
    apps-delete: "record<code: string, message: string>"
    apps-get: "record<activeVersion: string, createdDateTime: string, culture: string, description: string, domain: string, endpointHitsCount: int, endpoints: record, id: string, name: string, usageScenario: string, versionsCount: int>"
    apps-update: "record<code: string, message: string>"
    azure-accounts-remove-from-app: "record<code: string, message: string>"
    azure-accounts-get-assigned: "table<accountName: string, azureSubscriptionId: string, resourceGroup: string>"
    azure-accounts-assign-to-app: "record<code: string, message: string>"
    apps-list-endpoints: "record"
    permissions-delete: "record<code: string, message: string>"
    permissions-list: "record<emails: list<string>, owner: string>"
    permissions-add: "record<code: string, message: string>"
    permissions-update: "record<code: string, message: string>"
    apps-publish: "record<assignedEndpointKey: string, endpointRegion: string, endpointUrl: string, failedRegions: string, isStaging: bool, publishedDateTime: string, region: string, versionId: string>"
    apps-get-publish-settings: "record<id: string, sentimentAnalysis: bool, speech: bool, spellChecker: bool>"
    apps-update-publish-settings: "record<code: string, message: string>"
    apps-download-query-logs: "binary"
    apps-get-settings: "record<id: string, public: bool>"
    apps-update-settings: "record<code: string, message: string>"
    versions-list: "table<assignedEndpointKey: record, createdDateTime: string, endpointHitsCount: int, endpointUrl: string, entitiesCount: int, externalApiKeys: record, intentsCount: int, lastModifiedDateTime: string, lastPublishedDateTime: string, lastTrainedDateTime: string, trainingStatus: string, version: string>"
    versions-import: "string"
    versions-delete: "record<code: string, message: string>"
    versions-get: "record<assignedEndpointKey: record, createdDateTime: string, endpointHitsCount: int, endpointUrl: string, entitiesCount: int, externalApiKeys: record, intentsCount: int, lastModifiedDateTime: string, lastPublishedDateTime: string, lastTrainedDateTime: string, trainingStatus: string, version: string>"
    versions-update: "record<code: string, message: string>"
    versions-clone: "string"
    model-list-closed-lists: "table<subLists: list<record>, id: string, name: string, readableType: string, typeId: int, roles: list<record>>"
    model-add-closed-list: "string"
    model-delete-closed-list: "record<code: string, message: string>"
    model-get-closed-list: "record<subLists: table<id: int, canonicalForm: string, list: list>, id: string, name: string, readableType: string, typeId: int, roles: table<id: string, name: string>>"
    model-patch-closed-list: "record<code: string, message: string>"
    model-update-closed-list: "record<code: string, message: string>"
    model-add-sub-list: "int"
    model-delete-sub-list: "record<code: string, message: string>"
    model-update-sub-list: "record<code: string, message: string>"
    model-list-closed-list-entity-roles: "table<id: string, name: string>"
    model-create-closed-list-entity-role: "string"
    model-delete-closed-list-entity-role: "record<code: string, message: string>"
    model-get-closed-list-entity-role: "record<id: string, name: string>"
    model-update-closed-list-entity-role: "record<code: string, message: string>"
    model-list-composite-entities: "table<children: list<record>, id: string, name: string, readableType: string, typeId: int, roles: list<record>>"
    model-delete-composite-entity: "record<code: string, message: string>"
    model-get-composite-entity: "record<children: table<children: list, id: string, instanceOf: string, name: string, readableType: string, typeId: int>, id: string, name: string, readableType: string, typeId: int, roles: table<id: string, name: string>>"
    model-update-composite-entity: "record<code: string, message: string>"
    model-add-composite-entity-child: "string"
    model-delete-composite-entity-child: "record<code: string, message: string>"
    model-list-composite-entity-roles: "table<id: string, name: string>"
    model-create-composite-entity-role: "string"
    model-delete-composite-entity-role: "record<code: string, message: string>"
    model-get-composite-entity-role: "record<id: string, name: string>"
    model-update-composite-entity-role: "record<code: string, message: string>"
    model-add-custom-prebuilt-domain: "list<string>"
    model-delete-custom-prebuilt-domain: "record<code: string, message: string>"
    model-list-custom-prebuilt-entities: "table<customPrebuiltDomainName: string, customPrebuiltModelName: string, id: string, name: string, readableType: string, typeId: int, roles: list<record>>"
    model-add-custom-prebuilt-entity: "string"
    model-list-custom-prebuilt-entity-roles: "table<id: string, name: string>"
    model-create-custom-prebuilt-entity-role: "string"
    model-delete-custom-entity-role: "record<code: string, message: string>"
    model-get-custom-entity-role: "record<id: string, name: string>"
    model-update-custom-prebuilt-entity-role: "record<code: string, message: string>"
    model-list-custom-prebuilt-intents: "table<customPrebuiltDomainName: string, customPrebuiltModelName: string, id: string, name: string, readableType: string, typeId: int>"
    model-add-custom-prebuilt-intent: "string"
    model-list-custom-prebuilt-models: "table<id: string, name: string, readableType: string, typeId: int, customPrebuiltDomainName: string, customPrebuiltModelName: string, roles: list<record>>"
    model-list-entities: "table<children: list<record>, customPrebuiltDomainName: string, customPrebuiltModelName: string, id: string, name: string, readableType: string, typeId: int, roles: list<record>>"
    model-add-entity: "string"
    model-delete-entity: "record<code: string, message: string>"
    model-get-entity: "record<children: table<children: list, id: string, instanceOf: string, name: string, readableType: string, typeId: int>, customPrebuiltDomainName: string, customPrebuiltModelName: string, id: string, name: string, readableType: string, typeId: int, roles: table<id: string, name: string>>"
    model-update-entity-child: "record<code: string, message: string>"
    model-add-entity-child: "string"
    model-delete-entity-feature: "record<code: string, message: string>"
    model-get-entity-features: "table<featureName: string, modelName: string>"
    features-add-entity-feature: "record<code: string, message: string>"
    model-replace-entity-features: "record<code: string, message: string>"
    model-list-entity-roles: "table<id: string, name: string>"
    model-create-entity-role: "string"
    model-delete-entity-role: "record<code: string, message: string>"
    model-get-entity-role: "record<id: string, name: string>"
    model-update-entity-role: "record<code: string, message: string>"
    model-list-entity-suggestions: "table<entityPredictions: list<record>, intentPredictions: list<record>, text: string, tokenizedText: list<string>>"
    examples-add: "record<ExampleId: int, UtteranceText: string>"
    examples-list: "table<entityLabels: list<record>, entityPredictions: list<record>, id: int, intentLabel: string, intentPredictions: list<record>, text: string, tokenizedText: list<string>>"
    examples-batch: "table<error: record<code: string, message: string>, hasError: bool, value: record<ExampleId: int, UtteranceText: string>>"
    examples-delete: "record<code: string, message: string>"
    versions-export: "record<closedLists: table<name: string, roles: list, subLists: list>, composites: table<children: list, features: list, inherits: record, name: string, roles: list>, culture: string, desc: string, entities: table<children: list, features: list, inherits: record, name: string, roles: list>, hierarchicals: table<children: list, features: list, inherits: record, name: string, roles: list>, intents: table<children: list, features: list, inherits: record, name: string, roles: list>, name: string, patternAnyEntities: table<explicitList: list, name: string, roles: list>, patterns: table<intent: string, pattern: string>, phraselists: table<activated: bool, enabledForAllModels: bool, mode: bool, name: string, words: string>, prebuiltEntities: table<name: string, roles: list>, regex_entities: table<name: string, regexPattern: string, roles: list>, regex_features: table<activated: bool, name: string, pattern: string>, utterances: table<entities: list, intent: string, text: string>, versionId: string>"
    features-list: "record<patternFeatures: table<pattern: string, enabledForAllModels: bool, id: int, isActive: bool, name: string>, phraselistFeatures: table<isExchangeable: bool, phrases: string, enabledForAllModels: bool, id: int, isActive: bool, name: string>>"
    model-list-hierarchical-entities: "table<children: list<record>, id: string, name: string, readableType: string, typeId: int, roles: list<record>>"
    model-delete-hierarchical-entity: "record<code: string, message: string>"
    model-get-hierarchical-entity: "record<children: table<children: list, id: string, instanceOf: string, name: string, readableType: string, typeId: int>, id: string, name: string, readableType: string, typeId: int, roles: table<id: string, name: string>>"
    model-update-hierarchical-entity: "record<code: string, message: string>"
    model-delete-hierarchical-entity-child: "record<code: string, message: string>"
    model-get-hierarchical-entity-child: "record<readableType: string, typeId: int, children: table<children: list, id: string, instanceOf: string, name: string, readableType: string, typeId: int>, id: string, instanceOf: string, name: string>"
    model-update-hierarchical-entity-child: "record<code: string, message: string>"
    model-list-hierarchical-entity-roles: "table<id: string, name: string>"
    model-create-hierarchical-entity-role: "string"
    model-delete-hierarchical-entity-role: "record<code: string, message: string>"
    model-get-hierarchical-entity-role: "record<id: string, name: string>"
    model-update-hierarchical-entity-role: "record<code: string, message: string>"
    model-list-intents: "table<customPrebuiltDomainName: string, customPrebuiltModelName: string, id: string, name: string, readableType: string, typeId: int>"
    model-add-intent: "string"
    model-delete-intent: "record<code: string, message: string>"
    model-get-intent: "record<customPrebuiltDomainName: string, customPrebuiltModelName: string, id: string, name: string, readableType: string, typeId: int>"
    model-update-intent: "record<code: string, message: string>"
    model-delete-intent-feature: "record<code: string, message: string>"
    model-get-intent-features: "table<featureName: string, modelName: string>"
    features-add-intent-feature: "record<code: string, message: string>"
    model-replace-intent-features: "record<code: string, message: string>"
    pattern-list-intent-patterns: "table<id: string, intent: string, pattern: string>"
    model-list-intent-suggestions: "table<entityPredictions: list<record>, intentPredictions: list<record>, text: string, tokenizedText: list<string>>"
    model-list-prebuilt-entities: "table<description: string, examples: string, name: string>"
    model-list-models: "table<id: string, name: string, readableType: string, typeId: int, children: list<record>, roles: list<record>, subLists: list<record>, customPrebuiltDomainName: string, customPrebuiltModelName: string, regexPattern: string, explicitList: list<record>>"
    model-examples: "table<id: int, text: string>"
    model-list-pattern-any-entity-infos: "table<explicitList: list<record>, id: string, name: string, readableType: string, typeId: int, roles: list<record>>"
    model-create-pattern-any-entity-model: "string"
    model-delete-pattern-any-entity-model: "record<code: string, message: string>"
    model-get-pattern-any-entity-info: "record<explicitList: table<explicitListItem: string, id: int>, id: string, name: string, readableType: string, typeId: int, roles: table<id: string, name: string>>"
    model-update-pattern-any-entity-model: "record<code: string, message: string>"
    model-get-explicit-list: "table<explicitListItem: string, id: int>"
    model-add-explicit-list-item: "int"
    model-delete-explicit-list-item: "record<code: string, message: string>"
    model-get-explicit-list-item: "record<explicitListItem: string, id: int>"
    model-update-explicit-list-item: "record<code: string, message: string>"
    model-list-pattern-any-entity-roles: "table<id: string, name: string>"
    model-create-pattern-any-entity-role: "string"
    model-delete-pattern-any-entity-role: "record<code: string, message: string>"
    model-get-pattern-any-entity-role: "record<id: string, name: string>"
    model-update-pattern-any-entity-role: "record<code: string, message: string>"
    pattern-add-pattern: "record<id: string, intent: string, pattern: string>"
    pattern-delete-patterns: "record<code: string, message: string>"
    pattern-list-patterns: "table<id: string, intent: string, pattern: string>"
    pattern-batch-add-patterns: "table<id: string, intent: string, pattern: string>"
    pattern-update-patterns: "table<id: string, intent: string, pattern: string>"
    pattern-delete-pattern: "record<code: string, message: string>"
    pattern-update-pattern: "record<id: string, intent: string, pattern: string>"
    features-list-phrase-lists: "table<isExchangeable: bool, phrases: string, enabledForAllModels: bool, id: int, isActive: bool, name: string>"
    features-add-phrase-list: "int"
    features-delete-phrase-list: "record<code: string, message: string>"
    features-get-phrase-list: "record<isExchangeable: bool, phrases: string, enabledForAllModels: bool, id: int, isActive: bool, name: string>"
    features-update-phrase-list: "record<code: string, message: string>"
    model-list-prebuilts: "table<id: string, name: string, readableType: string, typeId: int, roles: list<record>>"
    model-add-prebuilt: "table<id: string, name: string, readableType: string, typeId: int, roles: list<record>>"
    model-list-prebuilt-entity-roles: "table<id: string, name: string>"
    model-create-prebuilt-entity-role: "string"
    model-delete-prebuilt-entity-role: "record<code: string, message: string>"
    model-get-prebuilt-entity-role: "record<id: string, name: string>"
    model-update-prebuilt-entity-role: "record<code: string, message: string>"
    model-delete-prebuilt: "record<code: string, message: string>"
    model-get-prebuilt: "record<id: string, name: string, readableType: string, typeId: int, roles: table<id: string, name: string>>"
    model-list-regex-entity-infos: "table<regexPattern: string, id: string, name: string, readableType: string, typeId: int, roles: list<record>>"
    model-create-regex-entity-model: "string"
    model-list-regex-entity-roles: "table<id: string, name: string>"
    model-create-regex-entity-role: "string"
    model-delete-regex-entity-role: "record<code: string, message: string>"
    model-get-regex-entity-role: "record<id: string, name: string>"
    model-update-regex-entity-role: "record<code: string, message: string>"
    model-delete-regex-entity-model: "record<code: string, message: string>"
    model-get-regex-entity-entity-info: "record<regexPattern: string, id: string, name: string, readableType: string, typeId: int, roles: table<id: string, name: string>>"
    model-update-regex-entity-model: "record<code: string, message: string>"
    settings-list: "table<name: string, value: string>"
    settings-update: "record<code: string, message: string>"
    versions-delete-unlabelled-utterance: "record<code: string, message: string>"
    train-get-status: "table<details: record<exampleCount: int, failureReason: string, status: string, statusId: int, trainingDateTime: string>, modelId: string>"
    train-train-version: "record<status: string, statusId: int>"
    azure-accounts-list-user-luis-accounts: "table<accountName: string, azureSubscriptionId: string, resourceGroup: string>"
    apps-package-published-application-as-gzip: "binary"
    apps-package-trained-application-as-gzip: "binary"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["apps-list" "apps-add" "apps-list-cortana-endpoints" "apps-list-supported-cultures" "apps-list-available-custom-prebuilt-domains" "apps-add-custom-prebuilt-domain" "apps-list-available-custom-prebuilt-domains-for-culture" "apps-list-domains" "apps-import" "apps-list-usage-scenarios" "apps-delete" "apps-get" "apps-update" "azure-accounts-remove-from-app" "azure-accounts-get-assigned" "azure-accounts-assign-to-app" "apps-list-endpoints" "permissions-delete" "permissions-list" "permissions-add" "permissions-update" "apps-publish" "apps-get-publish-settings" "apps-update-publish-settings" "apps-download-query-logs" "apps-get-settings" "apps-update-settings" "versions-list" "versions-import" "versions-delete" "versions-get" "versions-update" "versions-clone" "model-list-closed-lists" "model-add-closed-list" "model-delete-closed-list" "model-get-closed-list" "model-patch-closed-list" "model-update-closed-list" "model-add-sub-list" "model-delete-sub-list" "model-update-sub-list" "model-list-closed-list-entity-roles" "model-create-closed-list-entity-role" "model-delete-closed-list-entity-role" "model-get-closed-list-entity-role" "model-update-closed-list-entity-role" "model-list-composite-entities" "model-delete-composite-entity" "model-get-composite-entity" "model-update-composite-entity" "model-add-composite-entity-child" "model-delete-composite-entity-child" "model-list-composite-entity-roles" "model-create-composite-entity-role" "model-delete-composite-entity-role" "model-get-composite-entity-role" "model-update-composite-entity-role" "model-add-custom-prebuilt-domain" "model-delete-custom-prebuilt-domain" "model-list-custom-prebuilt-entities" "model-add-custom-prebuilt-entity" "model-list-custom-prebuilt-entity-roles" "model-create-custom-prebuilt-entity-role" "model-delete-custom-entity-role" "model-get-custom-entity-role" "model-update-custom-prebuilt-entity-role" "model-list-custom-prebuilt-intents" "model-add-custom-prebuilt-intent" "model-list-custom-prebuilt-models" "model-list-entities" "model-add-entity" "model-delete-entity" "model-get-entity" "model-update-entity-child" "model-add-entity-child" "model-delete-entity-feature" "model-get-entity-features" "features-add-entity-feature" "model-replace-entity-features" "model-list-entity-roles" "model-create-entity-role" "model-delete-entity-role" "model-get-entity-role" "model-update-entity-role" "model-list-entity-suggestions" "examples-add" "examples-list" "examples-batch" "examples-delete" "versions-export" "features-list" "model-list-hierarchical-entities" "model-delete-hierarchical-entity" "model-get-hierarchical-entity" "model-update-hierarchical-entity" "model-delete-hierarchical-entity-child" "model-get-hierarchical-entity-child" "model-update-hierarchical-entity-child" "model-list-hierarchical-entity-roles" "model-create-hierarchical-entity-role" "model-delete-hierarchical-entity-role" "model-get-hierarchical-entity-role" "model-update-hierarchical-entity-role" "model-list-intents" "model-add-intent" "model-delete-intent" "model-get-intent" "model-update-intent" "model-delete-intent-feature" "model-get-intent-features" "features-add-intent-feature" "model-replace-intent-features" "pattern-list-intent-patterns" "model-list-intent-suggestions" "model-list-prebuilt-entities" "model-list-models" "model-examples" "model-list-pattern-any-entity-infos" "model-create-pattern-any-entity-model" "model-delete-pattern-any-entity-model" "model-get-pattern-any-entity-info" "model-update-pattern-any-entity-model" "model-get-explicit-list" "model-add-explicit-list-item" "model-delete-explicit-list-item" "model-get-explicit-list-item" "model-update-explicit-list-item" "model-list-pattern-any-entity-roles" "model-create-pattern-any-entity-role" "model-delete-pattern-any-entity-role" "model-get-pattern-any-entity-role" "model-update-pattern-any-entity-role" "pattern-add-pattern" "pattern-delete-patterns" "pattern-list-patterns" "pattern-batch-add-patterns" "pattern-update-patterns" "pattern-delete-pattern" "pattern-update-pattern" "features-list-phrase-lists" "features-add-phrase-list" "features-delete-phrase-list" "features-get-phrase-list" "features-update-phrase-list" "model-list-prebuilts" "model-add-prebuilt" "model-list-prebuilt-entity-roles" "model-create-prebuilt-entity-role" "model-delete-prebuilt-entity-role" "model-get-prebuilt-entity-role" "model-update-prebuilt-entity-role" "model-delete-prebuilt" "model-get-prebuilt" "model-list-regex-entity-infos" "model-create-regex-entity-model" "model-list-regex-entity-roles" "model-create-regex-entity-role" "model-delete-regex-entity-role" "model-get-regex-entity-role" "model-update-regex-entity-role" "model-delete-regex-entity-model" "model-get-regex-entity-entity-info" "model-update-regex-entity-model" "settings-list" "settings-update" "versions-delete-unlabelled-utterance" "train-get-status" "train-train-version" "azure-accounts-list-user-luis-accounts" "apps-package-published-application-as-gzip" "apps-package-trained-application-as-gzip" "commands"] | sort) } | get name | first)
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

# Lists all of the user's applications.
#
# GET /apps/
# Returns: table<activeVersion: string, createdDateTime: string, culture: string, description: string, domain: string, endpointHitsCount: int, endpoints: record, id: string, name: string, usageScenario: string, versionsCount: int>
# operationId: Apps_List
export def "apps-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/"
    query: [{name: skip, var: skip}, {name: take, var: take}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    skip: $skip, take: $take
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new LUIS app.
#
# POST /apps/
# Returns: string
# operationId: Apps_Add
export def "apps-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  culture: string # The culture for the new application. It is the language that your app understands and speaks. E.g.: "en-us". Note: the culture cannot be changed after the app is created.
  --description: string # Description of the new application. Optional.
  --domain: string # The domain for the new application. Optional. E.g.: Comics.
  --initial-version-id: string # The initial version ID. Optional. Default value is: "0.1"
  name: string # The name for the new application.
  --usage-scenario: string # Defines the scenario for the new application. Optional. E.g.: IoT.
]: any -> any {
  $in | http-request {
    method: post
    path: "/apps/"
    body: {content_type: "application/json", kind: json, fields: [{name: culture, var: culture}, {name: description, var: description}, {name: domain, var: domain}, {name: initialVersionId, var: initial_version_id}, {name: name, var: name}, {name: usageScenario, var: usage_scenario}]}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    culture: $culture, description: $description, domain: $domain, initial_version_id: $initial_version_id, name: $name, usage_scenario: $usage_scenario
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the endpoint URLs for the prebuilt Cortana applications.
#
# GET /apps/assistants
# Returns: record<endpointKeys: list<string>, endpointUrls: record>
# operationId: Apps_ListCortanaEndpoints
export def "apps-list-cortana-endpoints" [
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
    path: "/apps/assistants"
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of supported cultures. Cultures are equivalent to the written language and locale. For example,"en-us" represents the U.S. variation of English.
#
# GET /apps/cultures
# Returns: table<code: string, name: string>
# operationId: Apps_ListSupportedCultures
export def "apps-list-supported-cultures" [
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
    path: "/apps/cultures"
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all the available custom prebuilt domains for all cultures.
#
# GET /apps/customprebuiltdomains
# Returns: table<culture: string, description: string, entities: list<record>, examples: string, intents: list<record>, name: string>
# operationId: Apps_ListAvailableCustomPrebuiltDomains
export def "apps-list-available-custom-prebuilt-domains" [
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
    path: "/apps/customprebuiltdomains"
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a prebuilt domain along with its intent and entity models as a new application.
#
# POST /apps/customprebuiltdomains
# Returns: string
# operationId: Apps_AddCustomPrebuiltDomain
export def "apps-add-custom-prebuilt-domain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --culture: string # The culture of the new domain.
  --domain-name: string # The domain name.
]: any -> any {
  $in | http-request {
    method: post
    path: "/apps/customprebuiltdomains"
    body: {content_type: "application/json", kind: json, fields: [{name: culture, var: culture}, {name: domainName, var: domain_name}]}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    culture: $culture, domain_name: $domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all the available prebuilt domains for a specific culture.
#
# GET /apps/customprebuiltdomains/{culture}
# Returns: table<culture: string, description: string, entities: list<record>, examples: string, intents: list<record>, name: string>
# operationId: Apps_ListAvailableCustomPrebuiltDomainsForCulture
export def "apps-list-available-custom-prebuilt-domains-for-culture" [
  culture: string
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
    path: "/apps/customprebuiltdomains/{culture}"
    path_params: [{name: culture, var: culture}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    culture: $culture
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the available application domains.
#
# GET /apps/domains
# Returns: list<string>
# operationId: Apps_ListDomains
export def "apps-list-domains" [
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
    path: "/apps/domains"
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Imports an application to LUIS, the application's structure is included in the request body.
#
# POST /apps/import
# Returns: string
# operationId: Apps_Import
export def "apps-import" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-name: string # The application name to create. If not specified, the application name will be read from the imported object. If the application name already exists, an error is returned.
  --closed-lists: list # List of list entities. — item shape: {name?: string, roles?: list<string>, subLists?: list}
  --composites: list # List of composite entities. — item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list<string>}
  --culture: string # The culture of the application. E.g.: en-us.
  --desc: string # The description of the application.
  --entities: list # List of entities. — item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list<string>}
  --hierarchicals: list # List of hierarchical entities. — item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list<string>}
  --intents: list # List of intents. — item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list<string>}
  --name: string # The name of the application.
  --pattern-any-entities: list # List of Pattern.Any entities. — item shape: {explicitList?: list<string>, name?: string, roles?: list<string>}
  --patterns: list # List of patterns. — item shape: {intent?: string, pattern?: string}
  --phraselists: list # List of model features. — item shape: {activated?: bool, enabledForAllModels?: bool, mode?: bool, name?: string, words?: string}
  --prebuilt-entities: list # List of prebuilt entities. — item shape: {name?: string, roles?: list<string>}
  --regex-entities: list # List of regular expression entities. — item shape: {name?: string, regexPattern?: string, roles?: list<string>}
  --regex-features: list # List of pattern features. — item shape: {activated?: bool, name?: string, pattern?: string}
  --utterances: list # List of example utterances. — item shape: {entities?: list, intent?: string, text?: string}
  --version-id: string # The version ID of the application that was exported.
]: any -> any {
  $in | http-request {
    method: post
    path: "/apps/import"
    query: [{name: appName, var: app_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: closedLists, var: closed_lists}, {name: composites, var: composites}, {name: culture, var: culture}, {name: desc, var: desc}, {name: entities, var: entities}, {name: hierarchicals, var: hierarchicals}, {name: intents, var: intents}, {name: name, var: name}, {name: patternAnyEntities, var: pattern_any_entities}, {name: patterns, var: patterns}, {name: phraselists, var: phraselists}, {name: prebuiltEntities, var: prebuilt_entities}, {name: regex_entities, var: regex_entities}, {name: regex_features, var: regex_features}, {name: utterances, var: utterances}, {name: versionId, var: version_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    app_name: $app_name, closed_lists: $closed_lists, composites: $composites, culture: $culture, desc: $desc, entities: $entities, hierarchicals: $hierarchicals, intents: $intents, name: $name, pattern_any_entities: $pattern_any_entities, patterns: $patterns, phraselists: $phraselists, prebuilt_entities: $prebuilt_entities, regex_entities: $regex_entities, regex_features: $regex_features, utterances: $utterances, version_id: $version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the application available usage scenarios.
#
# GET /apps/usagescenarios
# Returns: list<string>
# operationId: Apps_ListUsageScenarios
export def "apps-list-usage-scenarios" [
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
    path: "/apps/usagescenarios"
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an application.
#
# DELETE /apps/{appId}
# Returns: record<code: string, message: string>
# operationId: Apps_Delete
export def "apps-delete" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # A flag to indicate whether to force an operation. (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/apps/{appId}"
    path_params: [{name: appId, var: app_id}]
    query: [{name: force, var: force}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, force: $force
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the application info.
#
# GET /apps/{appId}
# Returns: record<activeVersion: string, createdDateTime: string, culture: string, description: string, domain: string, endpointHitsCount: int, endpoints: record, id: string, name: string, usageScenario: string, versionsCount: int>
# operationId: Apps_Get
export def "apps-get" [
  app_id: string
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
    path: "/apps/{appId}"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the name or description of the application.
#
# PUT /apps/{appId}
# Returns: record<code: string, message: string>
# operationId: Apps_Update
export def "apps-update" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The application's new description.
  --name: string # The application's new name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/apps/{appId}"
    path_params: [{name: appId, var: app_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, description: $description, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# apps - Removes an assigned LUIS Azure account from an application
#
# DELETE /apps/{appId}/azureaccounts
# Returns: record<code: string, message: string>
# operationId: AzureAccounts_RemoveFromApp
export def "azure-accounts-remove-from-app" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The bearer authorization header to use; containing the user's ARM token used to validate Azure accounts information. (required)
  account_name: string # The Azure account name.
  azure_subscription_id: string # The id for the Azure subscription.
  resource_group: string # The Azure resource group name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/apps/{appId}/azureaccounts"
    path_params: [{name: appId, var: app_id}]
    header: [{name: Authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountName, var: account_name}, {name: azureSubscriptionId, var: azure_subscription_id}, {name: resourceGroup, var: resource_group}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, authorization: $authorization, account_name: $account_name, azure_subscription_id: $azure_subscription_id, resource_group: $resource_group
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# apps - Get LUIS Azure accounts assigned to the application
#
# GET /apps/{appId}/azureaccounts
# Returns: table<accountName: string, azureSubscriptionId: string, resourceGroup: string>
# operationId: AzureAccounts_GetAssigned
export def "azure-accounts-get-assigned" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The bearer authorization header to use; containing the user's ARM token used to validate Azure accounts information. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/azureaccounts"
    path_params: [{name: appId, var: app_id}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# apps - Assign a LUIS Azure account to an application
#
# POST /apps/{appId}/azureaccounts
# Returns: record<code: string, message: string>
# operationId: AzureAccounts_AssignToApp
export def "azure-accounts-assign-to-app" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The bearer authorization header to use; containing the user's ARM token used to validate Azure accounts information. (required)
  account_name: string # The Azure account name.
  azure_subscription_id: string # The id for the Azure subscription.
  resource_group: string # The Azure resource group name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apps/{appId}/azureaccounts"
    path_params: [{name: appId, var: app_id}]
    header: [{name: Authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountName, var: account_name}, {name: azureSubscriptionId, var: azure_subscription_id}, {name: resourceGroup, var: resource_group}]}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, authorization: $authorization, account_name: $account_name, azure_subscription_id: $azure_subscription_id, resource_group: $resource_group
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the available endpoint deployment regions and URLs.
#
# GET /apps/{appId}/endpoints
# Returns: record
# operationId: Apps_ListEndpoints
export def "apps-list-endpoints" [
  app_id: string
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
    path: "/apps/{appId}/endpoints"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a user from the allowed list of users to access this LUIS application. Users are removed using their email address.
#
# DELETE /apps/{appId}/permissions
# Returns: record<code: string, message: string>
# operationId: Permissions_Delete
export def "permissions-delete" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email address of the user.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/apps/{appId}/permissions"
    path_params: [{name: appId, var: app_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of user emails that have permissions to access your application.
#
# GET /apps/{appId}/permissions
# Returns: record<emails: list<string>, owner: string>
# operationId: Permissions_List
export def "permissions-list" [
  app_id: string
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
    path: "/apps/{appId}/permissions"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a user to the allowed list of users to access this LUIS application. Users are added using their email address.
#
# POST /apps/{appId}/permissions
# Returns: record<code: string, message: string>
# operationId: Permissions_Add
export def "permissions-add" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email address of the user.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apps/{appId}/permissions"
    path_params: [{name: appId, var: app_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replaces the current user access list with the new list sent in the body. If an empty list is sent, all access to other users will be removed.
#
# PUT /apps/{appId}/permissions
# Returns: record<code: string, message: string>
# operationId: Permissions_Update
export def "permissions-update" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --emails: list<string> # The email address of the users.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/apps/{appId}/permissions"
    path_params: [{name: appId, var: app_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: emails, var: emails}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, emails: $emails
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Publishes a specific version of the application.
#
# POST /apps/{appId}/publish
# Returns: record<assignedEndpointKey: string, endpointRegion: string, endpointUrl: string, failedRegions: string, isStaging: bool, publishedDateTime: string, region: string, versionId: string>
# operationId: Apps_Publish
export def "apps-publish" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-staging: oneof<nothing, bool> # Indicates if the staging slot should be used, instead of the Production one. (default: false)
  --version-id: string # The version ID to publish.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apps/{appId}/publish"
    path_params: [{name: appId, var: app_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: isStaging, var: is_staging}, {name: versionId, var: version_id}]}
    accept: ["application/json"]
    ok: [201, 207]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, is_staging: $is_staging, version_id: $version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the application publish settings including 'UseAllTrainingData'.
#
# GET /apps/{appId}/publishsettings
# Returns: record<id: string, sentimentAnalysis: bool, speech: bool, spellChecker: bool>
# operationId: Apps_GetPublishSettings
export def "apps-get-publish-settings" [
  app_id: string
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
    path: "/apps/{appId}/publishsettings"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the application publish settings including 'UseAllTrainingData'.
#
# PUT /apps/{appId}/publishsettings
# Returns: record<code: string, message: string>
# operationId: Apps_UpdatePublishSettings
export def "apps-update-publish-settings" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sentiment-analysis: oneof<nothing, bool> # Setting sentiment analysis as true returns the Sentiment of the input utterance along with the response
  --speech: oneof<nothing, bool> # Setting speech as public enables speech priming in your app
  --spell-checker: oneof<nothing, bool> # Setting spell checker as public enables spell checking the input utterance.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/apps/{appId}/publishsettings"
    path_params: [{name: appId, var: app_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: sentimentAnalysis, var: sentiment_analysis}, {name: speech, var: speech}, {name: spellChecker, var: spell_checker}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, sentiment_analysis: $sentiment_analysis, speech: $speech, spell_checker: $spell_checker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the logs of the past month's endpoint queries for the application.
#
# GET /apps/{appId}/querylogs
# Returns: binary
# operationId: Apps_DownloadQueryLogs
export def "apps-download-query-logs" [
  app_id: string
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
    path: "/apps/{appId}/querylogs"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the application settings including 'UseAllTrainingData'.
#
# GET /apps/{appId}/settings
# Returns: record<id: string, public: bool>
# operationId: Apps_GetSettings
export def "apps-get-settings" [
  app_id: string
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
    path: "/apps/{appId}/settings"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the application settings including 'UseAllTrainingData'.
#
# PUT /apps/{appId}/settings
# Returns: record<code: string, message: string>
# operationId: Apps_UpdateSettings
export def "apps-update-settings" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --public: oneof<nothing, bool> # Setting your application as public allows other people to use your application's endpoint using their own keys.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/apps/{appId}/settings"
    path_params: [{name: appId, var: app_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: public, var: public}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, public: $public
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of versions for this application ID.
#
# GET /apps/{appId}/versions
# Returns: table<assignedEndpointKey: record, createdDateTime: string, endpointHitsCount: int, endpointUrl: string, entitiesCount: int, externalApiKeys: record, intentsCount: int, lastModifiedDateTime: string, lastPublishedDateTime: string, lastTrainedDateTime: string, trainingStatus: string, version: string>
# operationId: Versions_List
export def "versions-list" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/versions"
    path_params: [{name: appId, var: app_id}]
    query: [{name: skip, var: skip}, {name: take, var: take}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, skip: $skip, take: $take
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Imports a new version into a LUIS application.
#
# POST /apps/{appId}/versions/import
# Returns: string
# operationId: Versions_Import
export def "versions-import" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version-id: string # The new versionId to import. If not specified, the versionId will be read from the imported object.
  --closed-lists: list # List of list entities. — item shape: {name?: string, roles?: list<string>, subLists?: list}
  --composites: list # List of composite entities. — item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list<string>}
  --culture: string # The culture of the application. E.g.: en-us.
  --desc: string # The description of the application.
  --entities: list # List of entities. — item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list<string>}
  --hierarchicals: list # List of hierarchical entities. — item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list<string>}
  --intents: list # List of intents. — item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list<string>}
  --name: string # The name of the application.
  --pattern-any-entities: list # List of Pattern.Any entities. — item shape: {explicitList?: list<string>, name?: string, roles?: list<string>}
  --patterns: list # List of patterns. — item shape: {intent?: string, pattern?: string}
  --phraselists: list # List of model features. — item shape: {activated?: bool, enabledForAllModels?: bool, mode?: bool, name?: string, words?: string}
  --prebuilt-entities: list # List of prebuilt entities. — item shape: {name?: string, roles?: list<string>}
  --regex-entities: list # List of regular expression entities. — item shape: {name?: string, regexPattern?: string, roles?: list<string>}
  --regex-features: list # List of pattern features. — item shape: {activated?: bool, name?: string, pattern?: string}
  --utterances: list # List of example utterances. — item shape: {entities?: list, intent?: string, text?: string}
  --body-version-id: string # The version ID of the application that was exported. (spec name: versionId)
]: any -> any {
  $in | http-request {
    method: post
    path: "/apps/{appId}/versions/import"
    path_params: [{name: appId, var: app_id}]
    query: [{name: versionId, var: version_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: closedLists, var: closed_lists}, {name: composites, var: composites}, {name: culture, var: culture}, {name: desc, var: desc}, {name: entities, var: entities}, {name: hierarchicals, var: hierarchicals}, {name: intents, var: intents}, {name: name, var: name}, {name: patternAnyEntities, var: pattern_any_entities}, {name: patterns, var: patterns}, {name: phraselists, var: phraselists}, {name: prebuiltEntities, var: prebuilt_entities}, {name: regex_entities, var: regex_entities}, {name: regex_features, var: regex_features}, {name: utterances, var: utterances}, {name: versionId, var: body_version_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, closed_lists: $closed_lists, composites: $composites, culture: $culture, desc: $desc, entities: $entities, hierarchicals: $hierarchicals, intents: $intents, name: $name, pattern_any_entities: $pattern_any_entities, patterns: $patterns, phraselists: $phraselists, prebuilt_entities: $prebuilt_entities, regex_entities: $regex_entities, regex_features: $regex_features, utterances: $utterances, body_version_id: $body_version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an application version.
#
# DELETE /apps/{appId}/versions/{versionId}/
# Returns: record<code: string, message: string>
# operationId: Versions_Delete
export def "versions-delete" [
  app_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/apps/{appId}/versions/{versionId}/"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the version information such as date created, last modified date, endpoint URL, count of intents and entities, training and publishing status.
#
# GET /apps/{appId}/versions/{versionId}/
# Returns: record<assignedEndpointKey: record, createdDateTime: string, endpointHitsCount: int, endpointUrl: string, entitiesCount: int, externalApiKeys: record, intentsCount: int, lastModifiedDateTime: string, lastPublishedDateTime: string, lastTrainedDateTime: string, trainingStatus: string, version: string>
# operationId: Versions_Get
export def "versions-get" [
  app_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/versions/{versionId}/"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the name or description of the application version.
#
# PUT /apps/{appId}/versions/{versionId}/
# Returns: record<code: string, message: string>
# operationId: Versions_Update
export def "versions-update" [
  app_id: string
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
  --version: string # The new version for the cloned model.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/apps/{appId}/versions/{versionId}/"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new version from the selected version.
#
# POST /apps/{appId}/versions/{versionId}/clone
# Returns: string
# operationId: Versions_Clone
export def "versions-clone" [
  app_id: string
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
  --version: string # The new version for the cloned model.
]: any -> any {
  $in | http-request {
    method: post
    path: "/apps/{appId}/versions/{versionId}/clone"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: version, var: version}]}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about all the list entity models in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/closedlists
# Returns: table<subLists: list<record>, id: string, name: string, readableType: string, typeId: int, roles: list<record>>
# operationId: Model_ListClosedLists
export def "model-list-closed-lists" [
  app_id: string
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
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/versions/{versionId}/closedlists"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    query: [{name: skip, var: skip}, {name: take, var: take}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, skip: $skip, take: $take
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a list entity model to a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/closedlists
# Returns: string
# operationId: Model_AddClosedList
export def "model-add-closed-list" [
  app_id: string
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
  --name: string # Name of the list entity.
  --sub-lists: list # Sublists for the feature. — item shape: {canonicalForm?: string, list?: list<string>}
]: any -> any {
  $in | http-request {
    method: post
    path: "/apps/{appId}/versions/{versionId}/closedlists"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: subLists, var: sub_lists}]}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, name: $name, sub_lists: $sub_lists
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a list entity model from a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/closedlists/{clEntityId}
# Returns: record<code: string, message: string>
# operationId: Model_DeleteClosedList
export def "model-delete-closed-list" [
  app_id: string
  version_id: string
  cl_entity_id: string
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
    path: "/apps/{appId}/versions/{versionId}/closedlists/{clEntityId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: clEntityId, var: cl_entity_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, cl_entity_id: $cl_entity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a list entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/closedlists/{clEntityId}
# Returns: record<subLists: table<id: int, canonicalForm: string, list: list>, id: string, name: string, readableType: string, typeId: int, roles: table<id: string, name: string>>
# operationId: Model_GetClosedList
export def "model-get-closed-list" [
  app_id: string
  version_id: string
  cl_entity_id: string
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
    path: "/apps/{appId}/versions/{versionId}/closedlists/{clEntityId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: clEntityId, var: cl_entity_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, cl_entity_id: $cl_entity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a batch of sublists to an existing list entity in a version of the application.
#
# PATCH /apps/{appId}/versions/{versionId}/closedlists/{clEntityId}
# Returns: record<code: string, message: string>
# operationId: Model_PatchClosedList
export def "model-patch-closed-list" [
  app_id: string
  version_id: string
  cl_entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sub-lists: list # Sublists to add. — item shape: {canonicalForm?: string, list?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/apps/{appId}/versions/{versionId}/closedlists/{clEntityId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: clEntityId, var: cl_entity_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: subLists, var: sub_lists}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, cl_entity_id: $cl_entity_id, sub_lists: $sub_lists
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the list entity in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/closedlists/{clEntityId}
# Returns: record<code: string, message: string>
# operationId: Model_UpdateClosedList
export def "model-update-closed-list" [
  app_id: string
  version_id: string
  cl_entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The new name of the list entity.
  --sub-lists: list # The new sublists for the feature. — item shape: {canonicalForm?: string, list?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/apps/{appId}/versions/{versionId}/closedlists/{clEntityId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: clEntityId, var: cl_entity_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: subLists, var: sub_lists}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, cl_entity_id: $cl_entity_id, name: $name, sub_lists: $sub_lists
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a sublist to an existing list entity in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/closedlists/{clEntityId}/sublists
# Returns: int
# operationId: Model_AddSubList
export def "model-add-sub-list" [
  app_id: string
  version_id: string
  cl_entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --canonical-form: string # The standard form that the list represents.
  --list: list<string> # List of synonym words.
]: any -> any {
  $in | http-request {
    method: post
    path: "/apps/{appId}/versions/{versionId}/closedlists/{clEntityId}/sublists"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: clEntityId, var: cl_entity_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: canonicalForm, var: canonical_form}, {name: list, var: list}]}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, cl_entity_id: $cl_entity_id, canonical_form: $canonical_form, list: $list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a sublist of a specific list entity model from a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/closedlists/{clEntityId}/sublists/{subListId}
# Returns: record<code: string, message: string>
# operationId: Model_DeleteSubList
export def "model-delete-sub-list" [
  app_id: string
  version_id: string
  cl_entity_id: string
  sub_list_id: int
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
    path: "/apps/{appId}/versions/{versionId}/closedlists/{clEntityId}/sublists/{subListId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: clEntityId, var: cl_entity_id}, {name: subListId, var: sub_list_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, cl_entity_id: $cl_entity_id, sub_list_id: $sub_list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates one of the list entity's sublists in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/closedlists/{clEntityId}/sublists/{subListId}
# Returns: record<code: string, message: string>
# operationId: Model_UpdateSubList
export def "model-update-sub-list" [
  app_id: string
  version_id: string
  cl_entity_id: string
  sub_list_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --canonical-form: string # The standard form that the list represents.
  --list: list<string> # List of synonym words.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/apps/{appId}/versions/{versionId}/closedlists/{clEntityId}/sublists/{subListId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: clEntityId, var: cl_entity_id}, {name: subListId, var: sub_list_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: canonicalForm, var: canonical_form}, {name: list, var: list}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, cl_entity_id: $cl_entity_id, sub_list_id: $sub_list_id, canonical_form: $canonical_form, list: $list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all roles for a list entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/closedlists/{entityId}/roles
# Returns: table<id: string, name: string>
# operationId: Model_ListClosedListEntityRoles
export def "model-list-closed-list-entity-roles" [
  app_id: string
  version_id: string
  entity_id: string
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
    path: "/apps/{appId}/versions/{versionId}/closedlists/{entityId}/roles"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a role for a list entity in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/closedlists/{entityId}/roles
# Returns: string
# operationId: Model_CreateClosedListEntityRole
export def "model-create-closed-list-entity-role" [
  app_id: string
  version_id: string
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> any {
  $in | http-request {
    method: post
    path: "/apps/{appId}/versions/{versionId}/closedlists/{entityId}/roles"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a role for a given list entity in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/closedlists/{entityId}/roles/{roleId}
# Returns: record<code: string, message: string>
# operationId: Model_DeleteClosedListEntityRole
export def "model-delete-closed-list-entity-role" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
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
    path: "/apps/{appId}/versions/{versionId}/closedlists/{entityId}/roles/{roleId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}, {name: roleId, var: role_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, role_id: $role_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get one role for a given list entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/closedlists/{entityId}/roles/{roleId}
# Returns: record<id: string, name: string>
# operationId: Model_GetClosedListEntityRole
export def "model-get-closed-list-entity-role" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
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
    path: "/apps/{appId}/versions/{versionId}/closedlists/{entityId}/roles/{roleId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}, {name: roleId, var: role_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, role_id: $role_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a role for a given list entity in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/closedlists/{entityId}/roles/{roleId}
# Returns: record<code: string, message: string>
# operationId: Model_UpdateClosedListEntityRole
export def "model-update-closed-list-entity-role" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/apps/{appId}/versions/{versionId}/closedlists/{entityId}/roles/{roleId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}, {name: roleId, var: role_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, role_id: $role_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about all the composite entity models in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/compositeentities
# Returns: table<children: list<record>, id: string, name: string, readableType: string, typeId: int, roles: list<record>>
# operationId: Model_ListCompositeEntities
export def "model-list-composite-entities" [
  app_id: string
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
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/versions/{versionId}/compositeentities"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    query: [{name: skip, var: skip}, {name: take, var: take}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, skip: $skip, take: $take
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a composite entity from a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}
# Returns: record<code: string, message: string>
# operationId: Model_DeleteCompositeEntity
export def "model-delete-composite-entity" [
  app_id: string
  version_id: string
  c_entity_id: string
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
    path: "/apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: cEntityId, var: c_entity_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, c_entity_id: $c_entity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a composite entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}
# Returns: record<children: table<children: list, id: string, instanceOf: string, name: string, readableType: string, typeId: int>, id: string, name: string, readableType: string, typeId: int, roles: table<id: string, name: string>>
# operationId: Model_GetCompositeEntity
export def "model-get-composite-entity" [
  app_id: string
  version_id: string
  c_entity_id: string
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
    path: "/apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: cEntityId, var: c_entity_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, c_entity_id: $c_entity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a composite entity in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}
# Returns: record<code: string, message: string>
# operationId: Model_UpdateCompositeEntity
export def "model-update-composite-entity" [
  app_id: string
  version_id: string
  c_entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --children: list<string> # Child entities.
  --name: string # Entity name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: cEntityId, var: c_entity_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: children, var: children}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, c_entity_id: $c_entity_id, children: $children, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a single child in an existing composite entity model in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}/children
# Returns: string
# operationId: Model_AddCompositeEntityChild
export def "model-add-composite-entity-child" [
  app_id: string
  version_id: string
  c_entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}/children"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: cEntityId, var: c_entity_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, c_entity_id: $c_entity_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a composite entity extractor child from a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}/children/{cChildId}
# Returns: record<code: string, message: string>
# operationId: Model_DeleteCompositeEntityChild
export def "model-delete-composite-entity-child" [
  app_id: string
  version_id: string
  c_entity_id: string
  c_child_id: string
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
    path: "/apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}/children/{cChildId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: cEntityId, var: c_entity_id}, {name: cChildId, var: c_child_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, c_entity_id: $c_entity_id, c_child_id: $c_child_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all roles for a composite entity in a version of the application
#
# GET /apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}/roles
# Returns: table<id: string, name: string>
# operationId: Model_ListCompositeEntityRoles
export def "model-list-composite-entity-roles" [
  app_id: string
  version_id: string
  c_entity_id: string
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
    path: "/apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}/roles"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: cEntityId, var: c_entity_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, c_entity_id: $c_entity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a role for a composite entity in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}/roles
# Returns: string
# operationId: Model_CreateCompositeEntityRole
export def "model-create-composite-entity-role" [
  app_id: string
  version_id: string
  c_entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> any {
  $in | http-request {
    method: post
    path: "/apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}/roles"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: cEntityId, var: c_entity_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, c_entity_id: $c_entity_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a role for a given composite entity in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}/roles/{roleId}
# Returns: record<code: string, message: string>
# operationId: Model_DeleteCompositeEntityRole
export def "model-delete-composite-entity-role" [
  app_id: string
  version_id: string
  c_entity_id: string
  role_id: string
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
    path: "/apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}/roles/{roleId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: cEntityId, var: c_entity_id}, {name: roleId, var: role_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, c_entity_id: $c_entity_id, role_id: $role_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get one role for a given composite entity in a version of the application
#
# GET /apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}/roles/{roleId}
# Returns: record<id: string, name: string>
# operationId: Model_GetCompositeEntityRole
export def "model-get-composite-entity-role" [
  app_id: string
  version_id: string
  c_entity_id: string
  role_id: string
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
    path: "/apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}/roles/{roleId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: cEntityId, var: c_entity_id}, {name: roleId, var: role_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, c_entity_id: $c_entity_id, role_id: $role_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a role for a given composite entity in a version of the application
#
# PUT /apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}/roles/{roleId}
# Returns: record<code: string, message: string>
# operationId: Model_UpdateCompositeEntityRole
export def "model-update-composite-entity-role" [
  app_id: string
  version_id: string
  c_entity_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}/roles/{roleId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: cEntityId, var: c_entity_id}, {name: roleId, var: role_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, c_entity_id: $c_entity_id, role_id: $role_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a customizable prebuilt domain along with all of its intent and entity models in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/customprebuiltdomains
# Returns: list<string>
# operationId: Model_AddCustomPrebuiltDomain
export def "model-add-custom-prebuilt-domain" [
  app_id: string
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
  --domain-name: string # The domain name.
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apps/{appId}/versions/{versionId}/customprebuiltdomains"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: domainName, var: domain_name}]}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, domain_name: $domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a prebuilt domain's models in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/customprebuiltdomains/{domainName}
# Returns: record<code: string, message: string>
# operationId: Model_DeleteCustomPrebuiltDomain
export def "model-delete-custom-prebuilt-domain" [
  app_id: string
  version_id: string
  domain_name: string
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
    path: "/apps/{appId}/versions/{versionId}/customprebuiltdomains/{domainName}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: domainName, var: domain_name}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, domain_name: $domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all prebuilt entities used in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/customprebuiltentities
# Returns: table<customPrebuiltDomainName: string, customPrebuiltModelName: string, id: string, name: string, readableType: string, typeId: int, roles: list<record>>
# operationId: Model_ListCustomPrebuiltEntities
export def "model-list-custom-prebuilt-entities" [
  app_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/versions/{versionId}/customprebuiltentities"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a prebuilt entity model to a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/customprebuiltentities
# Returns: string
# operationId: Model_AddCustomPrebuiltEntity
export def "model-add-custom-prebuilt-entity" [
  app_id: string
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
  --domain-name: string # The domain name.
  --model-name: string # The intent name or entity name.
]: any -> any {
  $in | http-request {
    method: post
    path: "/apps/{appId}/versions/{versionId}/customprebuiltentities"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: domainName, var: domain_name}, {name: modelName, var: model_name}]}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, domain_name: $domain_name, model_name: $model_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all roles for a prebuilt entity in a version of the application
#
# GET /apps/{appId}/versions/{versionId}/customprebuiltentities/{entityId}/roles
# Returns: table<id: string, name: string>
# operationId: Model_ListCustomPrebuiltEntityRoles
export def "model-list-custom-prebuilt-entity-roles" [
  app_id: string
  version_id: string
  entity_id: string
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
    path: "/apps/{appId}/versions/{versionId}/customprebuiltentities/{entityId}/roles"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a role for a prebuilt entity in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/customprebuiltentities/{entityId}/roles
# Returns: string
# operationId: Model_CreateCustomPrebuiltEntityRole
export def "model-create-custom-prebuilt-entity-role" [
  app_id: string
  version_id: string
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> any {
  $in | http-request {
    method: post
    path: "/apps/{appId}/versions/{versionId}/customprebuiltentities/{entityId}/roles"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a role for a given prebuilt entity in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/customprebuiltentities/{entityId}/roles/{roleId}
# Returns: record<code: string, message: string>
# operationId: Model_DeleteCustomEntityRole
export def "model-delete-custom-entity-role" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
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
    path: "/apps/{appId}/versions/{versionId}/customprebuiltentities/{entityId}/roles/{roleId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}, {name: roleId, var: role_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, role_id: $role_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get one role for a given prebuilt entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/customprebuiltentities/{entityId}/roles/{roleId}
# Returns: record<id: string, name: string>
# operationId: Model_GetCustomEntityRole
export def "model-get-custom-entity-role" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
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
    path: "/apps/{appId}/versions/{versionId}/customprebuiltentities/{entityId}/roles/{roleId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}, {name: roleId, var: role_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, role_id: $role_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a role for a given prebuilt entity in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/customprebuiltentities/{entityId}/roles/{roleId}
# Returns: record<code: string, message: string>
# operationId: Model_UpdateCustomPrebuiltEntityRole
export def "model-update-custom-prebuilt-entity-role" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/apps/{appId}/versions/{versionId}/customprebuiltentities/{entityId}/roles/{roleId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}, {name: roleId, var: role_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, role_id: $role_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about customizable prebuilt intents added to a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/customprebuiltintents
# Returns: table<customPrebuiltDomainName: string, customPrebuiltModelName: string, id: string, name: string, readableType: string, typeId: int>
# operationId: Model_ListCustomPrebuiltIntents
export def "model-list-custom-prebuilt-intents" [
  app_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/versions/{versionId}/customprebuiltintents"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a customizable prebuilt intent model to a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/customprebuiltintents
# Returns: string
# operationId: Model_AddCustomPrebuiltIntent
export def "model-add-custom-prebuilt-intent" [
  app_id: string
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
  --domain-name: string # The domain name.
  --model-name: string # The intent name or entity name.
]: any -> any {
  $in | http-request {
    method: post
    path: "/apps/{appId}/versions/{versionId}/customprebuiltintents"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: domainName, var: domain_name}, {name: modelName, var: model_name}]}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, domain_name: $domain_name, model_name: $model_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all prebuilt intent and entity model information used in a version of this application.
#
# GET /apps/{appId}/versions/{versionId}/customprebuiltmodels
# Returns: table<id: string, name: string, readableType: string, typeId: int, customPrebuiltDomainName: string, customPrebuiltModelName: string, roles: list<record>>
# operationId: Model_ListCustomPrebuiltModels
export def "model-list-custom-prebuilt-models" [
  app_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/versions/{versionId}/customprebuiltmodels"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about all the simple entity models in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/entities
# Returns: table<children: list<record>, customPrebuiltDomainName: string, customPrebuiltModelName: string, id: string, name: string, readableType: string, typeId: int, roles: list<record>>
# operationId: Model_ListEntities
export def "model-list-entities" [
  app_id: string
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
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/versions/{versionId}/entities"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    query: [{name: skip, var: skip}, {name: take, var: take}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, skip: $skip, take: $take
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds an entity extractor to a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/entities
# Returns: string
# operationId: Model_AddEntity
export def "model-add-entity" [
  app_id: string
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
  --children: list # Child entities. — item shape: {children?: list, instanceOf?: string, name?: string}
  --name: string # Entity name.
]: any -> any {
  $in | http-request {
    method: post
    path: "/apps/{appId}/versions/{versionId}/entities"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: children, var: children}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, children: $children, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an entity or a child from a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/entities/{entityId}
# Returns: record<code: string, message: string>
# operationId: Model_DeleteEntity
export def "model-delete-entity" [
  app_id: string
  version_id: string
  entity_id: string
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
    path: "/apps/{appId}/versions/{versionId}/entities/{entityId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about an entity model in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/entities/{entityId}
# Returns: record<children: table<children: list, id: string, instanceOf: string, name: string, readableType: string, typeId: int>, customPrebuiltDomainName: string, customPrebuiltModelName: string, id: string, name: string, readableType: string, typeId: int, roles: table<id: string, name: string>>
# operationId: Model_GetEntity
export def "model-get-entity" [
  app_id: string
  version_id: string
  entity_id: string
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
    path: "/apps/{appId}/versions/{versionId}/entities/{entityId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the name of an entity extractor or the name and instanceOf model of a child entity extractor.
#
# PATCH /apps/{appId}/versions/{versionId}/entities/{entityId}
# Returns: record<code: string, message: string>
# operationId: Model_UpdateEntityChild
export def "model-update-entity-child" [
  app_id: string
  version_id: string
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --instance-of: string # The instance of model name
  --name: string # Entity name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/apps/{appId}/versions/{versionId}/entities/{entityId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceOf, var: instance_of}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, instance_of: $instance_of, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a single child in an existing entity model hierarchy in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/entities/{entityId}/children
# Returns: string
# operationId: Model_AddEntityChild
export def "model-add-entity-child" [
  app_id: string
  version_id: string
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --children: list # Child entities. — item shape: {children?: list, instanceOf?: string, name?: string}
  --instance-of: string # The instance of model name
  --name: string # Entity name.
]: any -> any {
  $in | http-request {
    method: post
    path: "/apps/{appId}/versions/{versionId}/entities/{entityId}/children"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: children, var: children}, {name: instanceOf, var: instance_of}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, children: $children, instance_of: $instance_of, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a relation from the feature relations used by the entity in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/entities/{entityId}/features
# Returns: record<code: string, message: string>
# operationId: Model_DeleteEntityFeature
export def "model-delete-entity-feature" [
  app_id: string
  version_id: string
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --feature-name: string # The name of the feature used.
  --model-name: string # The name of the model used.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/apps/{appId}/versions/{versionId}/entities/{entityId}/features"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: featureName, var: feature_name}, {name: modelName, var: model_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, feature_name: $feature_name, model_name: $model_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the information of the features used by the entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/entities/{entityId}/features
# Returns: table<featureName: string, modelName: string>
# operationId: Model_GetEntityFeatures
export def "model-get-entity-features" [
  app_id: string
  version_id: string
  entity_id: string
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
    path: "/apps/{appId}/versions/{versionId}/entities/{entityId}/features"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a new feature relation to be used by the entity in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/entities/{entityId}/features
# Returns: record<code: string, message: string>
# operationId: Features_AddEntityFeature
export def "features-add-entity-feature" [
  app_id: string
  version_id: string
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --feature-name: string # The name of the feature used.
  --model-name: string # The name of the model used.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apps/{appId}/versions/{versionId}/entities/{entityId}/features"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: featureName, var: feature_name}, {name: modelName, var: model_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, feature_name: $feature_name, model_name: $model_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the information of the features used by the entity in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/entities/{entityId}/features
# Returns: record<code: string, message: string>
# operationId: Model_ReplaceEntityFeatures
export def "model-replace-entity-features" [
  app_id: string
  version_id: string
  entity_id: string
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
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/apps/{appId}/versions/{versionId}/entities/{entityId}/features"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all roles for an entity in a version of the application
#
# GET /apps/{appId}/versions/{versionId}/entities/{entityId}/roles
# Returns: table<id: string, name: string>
# operationId: Model_ListEntityRoles
export def "model-list-entity-roles" [
  app_id: string
  version_id: string
  entity_id: string
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
    path: "/apps/{appId}/versions/{versionId}/entities/{entityId}/roles"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an entity role in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/entities/{entityId}/roles
# Returns: string
# operationId: Model_CreateEntityRole
export def "model-create-entity-role" [
  app_id: string
  version_id: string
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> any {
  $in | http-request {
    method: post
    path: "/apps/{appId}/versions/{versionId}/entities/{entityId}/roles"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an entity role in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/entities/{entityId}/roles/{roleId}
# Returns: record<code: string, message: string>
# operationId: Model_DeleteEntityRole
export def "model-delete-entity-role" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
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
    path: "/apps/{appId}/versions/{versionId}/entities/{entityId}/roles/{roleId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}, {name: roleId, var: role_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, role_id: $role_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get one role for a given entity in a version of the application
#
# GET /apps/{appId}/versions/{versionId}/entities/{entityId}/roles/{roleId}
# Returns: record<id: string, name: string>
# operationId: Model_GetEntityRole
export def "model-get-entity-role" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
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
    path: "/apps/{appId}/versions/{versionId}/entities/{entityId}/roles/{roleId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}, {name: roleId, var: role_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, role_id: $role_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a role for a given entity in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/entities/{entityId}/roles/{roleId}
# Returns: record<code: string, message: string>
# operationId: Model_UpdateEntityRole
export def "model-update-entity-role" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/apps/{appId}/versions/{versionId}/entities/{entityId}/roles/{roleId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}, {name: roleId, var: role_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, role_id: $role_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get suggested example utterances that would improve the accuracy of the entity model in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/entities/{entityId}/suggest
# Returns: table<entityPredictions: list<record>, intentPredictions: list<record>, text: string, tokenizedText: list<string>>
# operationId: Model_ListEntitySuggestions
export def "model-list-entity-suggestions" [
  app_id: string
  version_id: string
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/versions/{versionId}/entities/{entityId}/suggest"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}]
    query: [{name: take, var: take}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, take: $take
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a labeled example utterance in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/example
# Returns: record<ExampleId: int, UtteranceText: string>
# operationId: Examples_Add
export def "examples-add" [
  app_id: string
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
  --entity-labels: list # The identified entities within the example utterance. — item shape: {endCharIndex: int, entityName: string, role?: string, startCharIndex: int}
  --intent-name: string # The identified intent representing the example utterance.
  --text: string # The example utterance.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apps/{appId}/versions/{versionId}/example"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: entityLabels, var: entity_labels}, {name: intentName, var: intent_name}, {name: text, var: text}]}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_labels: $entity_labels, intent_name: $intent_name, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns example utterances to be reviewed from a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/examples
# Returns: table<entityLabels: list<record>, entityPredictions: list<record>, id: int, intentLabel: string, intentPredictions: list<record>, text: string, tokenizedText: list<string>>
# operationId: Examples_List
export def "examples-list" [
  app_id: string
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
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/versions/{versionId}/examples"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    query: [{name: skip, var: skip}, {name: take, var: take}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, skip: $skip, take: $take
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a batch of labeled example utterances to a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/examples
# Returns: table<error: record<code: string, message: string>, hasError: bool, value: record<ExampleId: int, UtteranceText: string>>
# operationId: Examples_Batch
export def "examples-batch" [
  app_id: string
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
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apps/{appId}/versions/{versionId}/examples"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [201, 207]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the labeled example utterances with the specified ID from a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/examples/{exampleId}
# Returns: record<code: string, message: string>
# operationId: Examples_Delete
export def "examples-delete" [
  app_id: string
  version_id: string
  example_id: int
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
    path: "/apps/{appId}/versions/{versionId}/examples/{exampleId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: exampleId, var: example_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, example_id: $example_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports a LUIS application to JSON format.
#
# GET /apps/{appId}/versions/{versionId}/export
# Returns: record<closedLists: table<name: string, roles: list, subLists: list>, composites: table<children: list, features: list, inherits: record, name: string, roles: list>, culture: string, desc: string, entities: table<children: list, features: list, inherits: record, name: string, roles: list>, hierarchicals: table<children: list, features: list, inherits: record, name: string, roles: list>, intents: table<children: list, features: list, inherits: record, name: string, roles: list>, name: string, patternAnyEntities: table<explicitList: list, name: string, roles: list>, patterns: table<intent: string, pattern: string>, phraselists: table<activated: bool, enabledForAllModels: bool, mode: bool, name: string, words: string>, prebuiltEntities: table<name: string, roles: list>, regex_entities: table<name: string, regexPattern: string, roles: list>, regex_features: table<activated: bool, name: string, pattern: string>, utterances: table<entities: list, intent: string, text: string>, versionId: string>
# operationId: Versions_Export
export def "versions-export" [
  app_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/versions/{versionId}/export"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all the extraction phraselist and pattern features in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/features
# Returns: record<patternFeatures: table<pattern: string, enabledForAllModels: bool, id: int, isActive: bool, name: string>, phraselistFeatures: table<isExchangeable: bool, phrases: string, enabledForAllModels: bool, id: int, isActive: bool, name: string>>
# operationId: Features_List
export def "features-list" [
  app_id: string
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
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/versions/{versionId}/features"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    query: [{name: skip, var: skip}, {name: take, var: take}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, skip: $skip, take: $take
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about all the hierarchical entity models in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/hierarchicalentities
# Returns: table<children: list<record>, id: string, name: string, readableType: string, typeId: int, roles: list<record>>
# operationId: Model_ListHierarchicalEntities
export def "model-list-hierarchical-entities" [
  app_id: string
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
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/versions/{versionId}/hierarchicalentities"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    query: [{name: skip, var: skip}, {name: take, var: take}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, skip: $skip, take: $take
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a hierarchical entity from a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}
# Returns: record<code: string, message: string>
# operationId: Model_DeleteHierarchicalEntity
export def "model-delete-hierarchical-entity" [
  app_id: string
  version_id: string
  h_entity_id: string
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
    path: "/apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: hEntityId, var: h_entity_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, h_entity_id: $h_entity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a hierarchical entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}
# Returns: record<children: table<children: list, id: string, instanceOf: string, name: string, readableType: string, typeId: int>, id: string, name: string, readableType: string, typeId: int, roles: table<id: string, name: string>>
# operationId: Model_GetHierarchicalEntity
export def "model-get-hierarchical-entity" [
  app_id: string
  version_id: string
  h_entity_id: string
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
    path: "/apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: hEntityId, var: h_entity_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, h_entity_id: $h_entity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the name of a hierarchical entity model in a version of the application.
#
# PATCH /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}
# Returns: record<code: string, message: string>
# operationId: Model_UpdateHierarchicalEntity
export def "model-update-hierarchical-entity" [
  app_id: string
  version_id: string
  h_entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity's new name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: hEntityId, var: h_entity_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, h_entity_id: $h_entity_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a hierarchical entity extractor child in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/children/{hChildId}
# Returns: record<code: string, message: string>
# operationId: Model_DeleteHierarchicalEntityChild
export def "model-delete-hierarchical-entity-child" [
  app_id: string
  version_id: string
  h_entity_id: string
  h_child_id: string
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
    path: "/apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/children/{hChildId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: hEntityId, var: h_entity_id}, {name: hChildId, var: h_child_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, h_entity_id: $h_entity_id, h_child_id: $h_child_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the child's model contained in an hierarchical entity child model in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/children/{hChildId}
# Returns: record<readableType: string, typeId: int, children: table<children: list, id: string, instanceOf: string, name: string, readableType: string, typeId: int>, id: string, instanceOf: string, name: string>
# operationId: Model_GetHierarchicalEntityChild
export def "model-get-hierarchical-entity-child" [
  app_id: string
  version_id: string
  h_entity_id: string
  h_child_id: string
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
    path: "/apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/children/{hChildId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: hEntityId, var: h_entity_id}, {name: hChildId, var: h_child_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, h_entity_id: $h_entity_id, h_child_id: $h_child_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Renames a single child in an existing hierarchical entity model in a version of the application.
#
# PATCH /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/children/{hChildId}
# Returns: record<code: string, message: string>
# operationId: Model_UpdateHierarchicalEntityChild
export def "model-update-hierarchical-entity-child" [
  app_id: string
  version_id: string
  h_entity_id: string
  h_child_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/children/{hChildId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: hEntityId, var: h_entity_id}, {name: hChildId, var: h_child_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, h_entity_id: $h_entity_id, h_child_id: $h_child_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all roles for a hierarchical entity in a version of the application
#
# GET /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/roles
# Returns: table<id: string, name: string>
# operationId: Model_ListHierarchicalEntityRoles
export def "model-list-hierarchical-entity-roles" [
  app_id: string
  version_id: string
  h_entity_id: string
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
    path: "/apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/roles"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: hEntityId, var: h_entity_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, h_entity_id: $h_entity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a role for an hierarchical entity in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/roles
# Returns: string
# operationId: Model_CreateHierarchicalEntityRole
export def "model-create-hierarchical-entity-role" [
  app_id: string
  version_id: string
  h_entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> any {
  $in | http-request {
    method: post
    path: "/apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/roles"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: hEntityId, var: h_entity_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, h_entity_id: $h_entity_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a role for a given hierarchical role in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/roles/{roleId}
# Returns: record<code: string, message: string>
# operationId: Model_DeleteHierarchicalEntityRole
export def "model-delete-hierarchical-entity-role" [
  app_id: string
  version_id: string
  h_entity_id: string
  role_id: string
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
    path: "/apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/roles/{roleId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: hEntityId, var: h_entity_id}, {name: roleId, var: role_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, h_entity_id: $h_entity_id, role_id: $role_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get one role for a given hierarchical entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/roles/{roleId}
# Returns: record<id: string, name: string>
# operationId: Model_GetHierarchicalEntityRole
export def "model-get-hierarchical-entity-role" [
  app_id: string
  version_id: string
  h_entity_id: string
  role_id: string
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
    path: "/apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/roles/{roleId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: hEntityId, var: h_entity_id}, {name: roleId, var: role_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, h_entity_id: $h_entity_id, role_id: $role_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a role for a given hierarchical entity in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/roles/{roleId}
# Returns: record<code: string, message: string>
# operationId: Model_UpdateHierarchicalEntityRole
export def "model-update-hierarchical-entity-role" [
  app_id: string
  version_id: string
  h_entity_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/roles/{roleId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: hEntityId, var: h_entity_id}, {name: roleId, var: role_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, h_entity_id: $h_entity_id, role_id: $role_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the intent models in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/intents
# Returns: table<customPrebuiltDomainName: string, customPrebuiltModelName: string, id: string, name: string, readableType: string, typeId: int>
# operationId: Model_ListIntents
export def "model-list-intents" [
  app_id: string
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
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/versions/{versionId}/intents"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    query: [{name: skip, var: skip}, {name: take, var: take}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, skip: $skip, take: $take
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds an intent to a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/intents
# Returns: string
# operationId: Model_AddIntent
export def "model-add-intent" [
  app_id: string
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
  --name: string # Name of the new entity extractor.
]: any -> any {
  $in | http-request {
    method: post
    path: "/apps/{appId}/versions/{versionId}/intents"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an intent from a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/intents/{intentId}
# Returns: record<code: string, message: string>
# operationId: Model_DeleteIntent
export def "model-delete-intent" [
  app_id: string
  version_id: string
  intent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-utterances: oneof<nothing, bool> # If true, deletes the intent's example utterances. If false, moves the example utterances to the None intent. The default value is false. (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/apps/{appId}/versions/{versionId}/intents/{intentId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: intentId, var: intent_id}]
    query: [{name: deleteUtterances, var: delete_utterances}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, intent_id: $intent_id, delete_utterances: $delete_utterances
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the intent model in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/intents/{intentId}
# Returns: record<customPrebuiltDomainName: string, customPrebuiltModelName: string, id: string, name: string, readableType: string, typeId: int>
# operationId: Model_GetIntent
export def "model-get-intent" [
  app_id: string
  version_id: string
  intent_id: string
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
    path: "/apps/{appId}/versions/{versionId}/intents/{intentId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: intentId, var: intent_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, intent_id: $intent_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the name of an intent in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/intents/{intentId}
# Returns: record<code: string, message: string>
# operationId: Model_UpdateIntent
export def "model-update-intent" [
  app_id: string
  version_id: string
  intent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity's new name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/apps/{appId}/versions/{versionId}/intents/{intentId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: intentId, var: intent_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, intent_id: $intent_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a relation from the feature relations used by the intent in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/intents/{intentId}/features
# Returns: record<code: string, message: string>
# operationId: Model_DeleteIntentFeature
export def "model-delete-intent-feature" [
  app_id: string
  version_id: string
  intent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --feature-name: string # The name of the feature used.
  --model-name: string # The name of the model used.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/apps/{appId}/versions/{versionId}/intents/{intentId}/features"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: intentId, var: intent_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: featureName, var: feature_name}, {name: modelName, var: model_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, intent_id: $intent_id, feature_name: $feature_name, model_name: $model_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the information of the features used by the intent in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/intents/{intentId}/features
# Returns: table<featureName: string, modelName: string>
# operationId: Model_GetIntentFeatures
export def "model-get-intent-features" [
  app_id: string
  version_id: string
  intent_id: string
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
    path: "/apps/{appId}/versions/{versionId}/intents/{intentId}/features"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: intentId, var: intent_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, intent_id: $intent_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a new feature relation to be used by the intent in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/intents/{intentId}/features
# Returns: record<code: string, message: string>
# operationId: Features_AddIntentFeature
export def "features-add-intent-feature" [
  app_id: string
  version_id: string
  intent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --feature-name: string # The name of the feature used.
  --model-name: string # The name of the model used.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apps/{appId}/versions/{versionId}/intents/{intentId}/features"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: intentId, var: intent_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: featureName, var: feature_name}, {name: modelName, var: model_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, intent_id: $intent_id, feature_name: $feature_name, model_name: $model_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the information of the features used by the intent in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/intents/{intentId}/features
# Returns: record<code: string, message: string>
# operationId: Model_ReplaceIntentFeatures
export def "model-replace-intent-features" [
  app_id: string
  version_id: string
  intent_id: string
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
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/apps/{appId}/versions/{versionId}/intents/{intentId}/features"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: intentId, var: intent_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, intent_id: $intent_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns patterns for the specific intent in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/intents/{intentId}/patternrules
# Returns: table<id: string, intent: string, pattern: string>
# operationId: Pattern_ListIntentPatterns
export def "pattern-list-intent-patterns" [
  app_id: string
  version_id: string
  intent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/versions/{versionId}/intents/{intentId}/patternrules"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: intentId, var: intent_id}]
    query: [{name: skip, var: skip}, {name: take, var: take}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, intent_id: $intent_id, skip: $skip, take: $take
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Suggests example utterances that would improve the accuracy of the intent model in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/intents/{intentId}/suggest
# Returns: table<entityPredictions: list<record>, intentPredictions: list<record>, text: string, tokenizedText: list<string>>
# operationId: Model_ListIntentSuggestions
export def "model-list-intent-suggestions" [
  app_id: string
  version_id: string
  intent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/versions/{versionId}/intents/{intentId}/suggest"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: intentId, var: intent_id}]
    query: [{name: take, var: take}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, intent_id: $intent_id, take: $take
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all the available prebuilt entities in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/listprebuilts
# Returns: table<description: string, examples: string, name: string>
# operationId: Model_ListPrebuiltEntities
export def "model-list-prebuilt-entities" [
  app_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/versions/{versionId}/listprebuilts"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about all the intent and entity models in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/models
# Returns: table<id: string, name: string, readableType: string, typeId: int, children: list<record>, roles: list<record>, subLists: list<record>, customPrebuiltDomainName: string, customPrebuiltModelName: string, regexPattern: string, explicitList: list<record>>
# operationId: Model_ListModels
export def "model-list-models" [
  app_id: string
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
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/versions/{versionId}/models"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    query: [{name: skip, var: skip}, {name: take, var: take}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, skip: $skip, take: $take
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the example utterances for the given intent or entity model in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/models/{modelId}/examples
# Returns: table<id: int, text: string>
# operationId: Model_Examples
export def "model-examples" [
  app_id: string
  version_id: string
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/versions/{versionId}/models/{modelId}/examples"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: modelId, var: model_id}]
    query: [{name: skip, var: skip}, {name: take, var: take}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, model_id: $model_id, skip: $skip, take: $take
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information about the Pattern.Any entity models in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/patternanyentities
# Returns: table<explicitList: list<record>, id: string, name: string, readableType: string, typeId: int, roles: list<record>>
# operationId: Model_ListPatternAnyEntityInfos
export def "model-list-pattern-any-entity-infos" [
  app_id: string
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
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/versions/{versionId}/patternanyentities"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    query: [{name: skip, var: skip}, {name: take, var: take}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, skip: $skip, take: $take
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a pattern.any entity extractor to a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/patternanyentities
# Returns: string
# operationId: Model_CreatePatternAnyEntityModel
export def "model-create-pattern-any-entity-model" [
  app_id: string
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
  --explicit-list: list<string> # The Pattern.Any explicit list.
  --name: string # The model name.
]: any -> any {
  $in | http-request {
    method: post
    path: "/apps/{appId}/versions/{versionId}/patternanyentities"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: explicitList, var: explicit_list}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, explicit_list: $explicit_list, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Pattern.Any entity extractor from a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}
# Returns: record<code: string, message: string>
# operationId: Model_DeletePatternAnyEntityModel
export def "model-delete-pattern-any-entity-model" [
  app_id: string
  version_id: string
  entity_id: string
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
    path: "/apps/{appId}/versions/{versionId}/patternanyentities/{entityId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the Pattern.Any model in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}
# Returns: record<explicitList: table<explicitListItem: string, id: int>, id: string, name: string, readableType: string, typeId: int, roles: table<id: string, name: string>>
# operationId: Model_GetPatternAnyEntityInfo
export def "model-get-pattern-any-entity-info" [
  app_id: string
  version_id: string
  entity_id: string
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
    path: "/apps/{appId}/versions/{versionId}/patternanyentities/{entityId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the name and explicit (exception) list of a Pattern.Any entity model in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}
# Returns: record<code: string, message: string>
# operationId: Model_UpdatePatternAnyEntityModel
export def "model-update-pattern-any-entity-model" [
  app_id: string
  version_id: string
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --explicit-list: list<string> # The Pattern.Any explicit list.
  --name: string # The model name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/apps/{appId}/versions/{versionId}/patternanyentities/{entityId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: explicitList, var: explicit_list}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, explicit_list: $explicit_list, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the explicit (exception) list of the pattern.any entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/explicitlist
# Returns: table<explicitListItem: string, id: int>
# operationId: Model_GetExplicitList
export def "model-get-explicit-list" [
  app_id: string
  version_id: string
  entity_id: string
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
    path: "/apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/explicitlist"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new exception to the explicit list for the Pattern.Any entity in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/explicitlist
# Returns: int
# operationId: Model_AddExplicitListItem
export def "model-add-explicit-list-item" [
  app_id: string
  version_id: string
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --explicit-list-item: string # The explicit list item.
]: any -> any {
  $in | http-request {
    method: post
    path: "/apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/explicitlist"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: explicitListItem, var: explicit_list_item}]}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, explicit_list_item: $explicit_list_item
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an item from the explicit (exception) list for a Pattern.any entity in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/explicitlist/{itemId}
# Returns: record<code: string, message: string>
# operationId: Model_DeleteExplicitListItem
export def "model-delete-explicit-list-item" [
  app_id: string
  version_id: string
  entity_id: string
  item_id: int
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
    path: "/apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/explicitlist/{itemId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}, {name: itemId, var: item_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, item_id: $item_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the explicit (exception) list of the pattern.any entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/explicitlist/{itemId}
# Returns: record<explicitListItem: string, id: int>
# operationId: Model_GetExplicitListItem
export def "model-get-explicit-list-item" [
  app_id: string
  version_id: string
  entity_id: string
  item_id: int
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
    path: "/apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/explicitlist/{itemId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}, {name: itemId, var: item_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, item_id: $item_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an explicit (exception) list item for a Pattern.Any entity in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/explicitlist/{itemId}
# Returns: record<code: string, message: string>
# operationId: Model_UpdateExplicitListItem
export def "model-update-explicit-list-item" [
  app_id: string
  version_id: string
  entity_id: string
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --explicit-list-item: string # The explicit list item.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/explicitlist/{itemId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}, {name: itemId, var: item_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: explicitListItem, var: explicit_list_item}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, item_id: $item_id, explicit_list_item: $explicit_list_item
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all roles for a Pattern.any entity in a version of the application
#
# GET /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/roles
# Returns: table<id: string, name: string>
# operationId: Model_ListPatternAnyEntityRoles
export def "model-list-pattern-any-entity-roles" [
  app_id: string
  version_id: string
  entity_id: string
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
    path: "/apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/roles"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a role for an Pattern.any entity in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/roles
# Returns: string
# operationId: Model_CreatePatternAnyEntityRole
export def "model-create-pattern-any-entity-role" [
  app_id: string
  version_id: string
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> any {
  $in | http-request {
    method: post
    path: "/apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/roles"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a role for a given Pattern.any entity in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/roles/{roleId}
# Returns: record<code: string, message: string>
# operationId: Model_DeletePatternAnyEntityRole
export def "model-delete-pattern-any-entity-role" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
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
    path: "/apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/roles/{roleId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}, {name: roleId, var: role_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, role_id: $role_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get one role for a given Pattern.any entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/roles/{roleId}
# Returns: record<id: string, name: string>
# operationId: Model_GetPatternAnyEntityRole
export def "model-get-pattern-any-entity-role" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
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
    path: "/apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/roles/{roleId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}, {name: roleId, var: role_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, role_id: $role_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a role for a given Pattern.any entity in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/roles/{roleId}
# Returns: record<code: string, message: string>
# operationId: Model_UpdatePatternAnyEntityRole
export def "model-update-pattern-any-entity-role" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/roles/{roleId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}, {name: roleId, var: role_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, role_id: $role_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a pattern to a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/patternrule
# Returns: record<id: string, intent: string, pattern: string>
# operationId: Pattern_AddPattern
export def "pattern-add-pattern" [
  app_id: string
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
  --intent: string # The intent's name which the pattern belongs to.
  --pattern: string # The pattern text.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apps/{appId}/versions/{versionId}/patternrule"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: intent, var: intent}, {name: pattern, var: pattern}]}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, intent: $intent, pattern: $pattern
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a list of patterns in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/patternrules
# Returns: record<code: string, message: string>
# operationId: Pattern_DeletePatterns
export def "pattern-delete-patterns" [
  app_id: string
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
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/apps/{appId}/versions/{versionId}/patternrules"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets patterns in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/patternrules
# Returns: table<id: string, intent: string, pattern: string>
# operationId: Pattern_ListPatterns
export def "pattern-list-patterns" [
  app_id: string
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
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/versions/{versionId}/patternrules"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    query: [{name: skip, var: skip}, {name: take, var: take}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, skip: $skip, take: $take
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a batch of patterns in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/patternrules
# Returns: table<id: string, intent: string, pattern: string>
# operationId: Pattern_BatchAddPatterns
export def "pattern-batch-add-patterns" [
  app_id: string
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
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apps/{appId}/versions/{versionId}/patternrules"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates patterns in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/patternrules
# Returns: table<id: string, intent: string, pattern: string>
# operationId: Pattern_UpdatePatterns
export def "pattern-update-patterns" [
  app_id: string
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
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/apps/{appId}/versions/{versionId}/patternrules"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the pattern with the specified ID from a version of the application..
#
# DELETE /apps/{appId}/versions/{versionId}/patternrules/{patternId}
# Returns: record<code: string, message: string>
# operationId: Pattern_DeletePattern
export def "pattern-delete-pattern" [
  app_id: string
  version_id: string
  pattern_id: string
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
    path: "/apps/{appId}/versions/{versionId}/patternrules/{patternId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: patternId, var: pattern_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, pattern_id: $pattern_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a pattern in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/patternrules/{patternId}
# Returns: record<id: string, intent: string, pattern: string>
# operationId: Pattern_UpdatePattern
export def "pattern-update-pattern" [
  app_id: string
  version_id: string
  pattern_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The pattern ID. (format: uuid)
  --intent: string # The intent's name which the pattern belongs to.
  --pattern: string # The pattern text.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/apps/{appId}/versions/{versionId}/patternrules/{patternId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: patternId, var: pattern_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: intent, var: intent}, {name: pattern, var: pattern}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, pattern_id: $pattern_id, id: $id, intent: $intent, pattern: $pattern
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all the phraselist features in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/phraselists
# Returns: table<isExchangeable: bool, phrases: string, enabledForAllModels: bool, id: int, isActive: bool, name: string>
# operationId: Features_ListPhraseLists
export def "features-list-phrase-lists" [
  app_id: string
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
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/versions/{versionId}/phraselists"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    query: [{name: skip, var: skip}, {name: take, var: take}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, skip: $skip, take: $take
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new phraselist feature in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/phraselists
# Returns: int
# operationId: Features_AddPhraseList
export def "features-add-phrase-list" [
  app_id: string
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
  --enabled-for-all-models: oneof<nothing, bool> # Indicates if the Phraselist is enabled for all models in the application. (default: true)
  --is-exchangeable: oneof<nothing, bool> # An interchangeable phrase list feature serves as a list of synonyms for training. A non-exchangeable phrase list serves as separate features for training. So, if your non-interchangeable phrase list contains 5 phrases, they will be mapped to 5 separate features. You can think of the non-interchangeable phrase list as an additional bag of words to add to LUIS existing vocabulary features. It is used as a lexicon lookup feature where its value is 1 if the lexicon contains a given word or 0 if it doesn’t. Default value is true. (default: true)
  --name: string # The Phraselist name.
  --phrases: string # List of comma-separated phrases that represent the Phraselist.
]: any -> any {
  $in | http-request {
    method: post
    path: "/apps/{appId}/versions/{versionId}/phraselists"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabledForAllModels, var: enabled_for_all_models}, {name: isExchangeable, var: is_exchangeable}, {name: name, var: name}, {name: phrases, var: phrases}]}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, enabled_for_all_models: $enabled_for_all_models, is_exchangeable: $is_exchangeable, name: $name, phrases: $phrases
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a phraselist feature from a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/phraselists/{phraselistId}
# Returns: record<code: string, message: string>
# operationId: Features_DeletePhraseList
export def "features-delete-phrase-list" [
  app_id: string
  version_id: string
  phraselist_id: int
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
    path: "/apps/{appId}/versions/{versionId}/phraselists/{phraselistId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: phraselistId, var: phraselist_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, phraselist_id: $phraselist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets phraselist feature info in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/phraselists/{phraselistId}
# Returns: record<isExchangeable: bool, phrases: string, enabledForAllModels: bool, id: int, isActive: bool, name: string>
# operationId: Features_GetPhraseList
export def "features-get-phrase-list" [
  app_id: string
  version_id: string
  phraselist_id: int
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
    path: "/apps/{appId}/versions/{versionId}/phraselists/{phraselistId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: phraselistId, var: phraselist_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, phraselist_id: $phraselist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the phrases, the state and the name of the phraselist feature in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/phraselists/{phraselistId}
# Returns: record<code: string, message: string>
# operationId: Features_UpdatePhraseList
export def "features-update-phrase-list" [
  app_id: string
  version_id: string
  phraselist_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled-for-all-models: oneof<nothing, bool> # Indicates if the Phraselist is enabled for all models in the application. (default: true)
  --is-active: oneof<nothing, bool> # Indicates if the Phraselist is enabled. (default: true)
  --is-exchangeable: oneof<nothing, bool> # An exchangeable phrase list feature are serves as single feature to the LUIS underlying training algorithm. It is used as a lexicon lookup feature where its value is 1 if the lexicon contains a given word or 0 if it doesn’t. Think of an exchangeable as a synonyms list. A non-exchangeable phrase list feature has all the phrases in the list serve as separate features to the underlying training algorithm. So, if you your phrase list feature contains 5 phrases, they will be mapped to 5 separate features. You can think of the non-exchangeable phrase list feature as an additional bag of words that you are willing to add to LUIS existing vocabulary features. Think of a non-exchangeable as set of different words. Default value is true. (default: true)
  --name: string # The Phraselist name.
  --phrases: string # List of comma-separated phrases that represent the Phraselist.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/apps/{appId}/versions/{versionId}/phraselists/{phraselistId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: phraselistId, var: phraselist_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabledForAllModels, var: enabled_for_all_models}, {name: isActive, var: is_active}, {name: isExchangeable, var: is_exchangeable}, {name: name, var: name}, {name: phrases, var: phrases}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, phraselist_id: $phraselist_id, enabled_for_all_models: $enabled_for_all_models, is_active: $is_active, is_exchangeable: $is_exchangeable, name: $name, phrases: $phrases
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about all the prebuilt entities in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/prebuilts
# Returns: table<id: string, name: string, readableType: string, typeId: int, roles: list<record>>
# operationId: Model_ListPrebuilts
export def "model-list-prebuilts" [
  app_id: string
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
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/versions/{versionId}/prebuilts"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    query: [{name: skip, var: skip}, {name: take, var: take}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, skip: $skip, take: $take
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a list of prebuilt entities to a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/prebuilts
# Returns: table<id: string, name: string, readableType: string, typeId: int, roles: list<record>>
# operationId: Model_AddPrebuilt
export def "model-add-prebuilt" [
  app_id: string
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
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apps/{appId}/versions/{versionId}/prebuilts"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a prebuilt entity's roles in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/prebuilts/{entityId}/roles
# Returns: table<id: string, name: string>
# operationId: Model_ListPrebuiltEntityRoles
export def "model-list-prebuilt-entity-roles" [
  app_id: string
  version_id: string
  entity_id: string
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
    path: "/apps/{appId}/versions/{versionId}/prebuilts/{entityId}/roles"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a role for a prebuilt entity in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/prebuilts/{entityId}/roles
# Returns: string
# operationId: Model_CreatePrebuiltEntityRole
export def "model-create-prebuilt-entity-role" [
  app_id: string
  version_id: string
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> any {
  $in | http-request {
    method: post
    path: "/apps/{appId}/versions/{versionId}/prebuilts/{entityId}/roles"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a role in a prebuilt entity in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/prebuilts/{entityId}/roles/{roleId}
# Returns: record<code: string, message: string>
# operationId: Model_DeletePrebuiltEntityRole
export def "model-delete-prebuilt-entity-role" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
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
    path: "/apps/{appId}/versions/{versionId}/prebuilts/{entityId}/roles/{roleId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}, {name: roleId, var: role_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, role_id: $role_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get one role for a given prebuilt entity in a version of the application
#
# GET /apps/{appId}/versions/{versionId}/prebuilts/{entityId}/roles/{roleId}
# Returns: record<id: string, name: string>
# operationId: Model_GetPrebuiltEntityRole
export def "model-get-prebuilt-entity-role" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
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
    path: "/apps/{appId}/versions/{versionId}/prebuilts/{entityId}/roles/{roleId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}, {name: roleId, var: role_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, role_id: $role_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a role for a given prebuilt entity in a version of the application
#
# PUT /apps/{appId}/versions/{versionId}/prebuilts/{entityId}/roles/{roleId}
# Returns: record<code: string, message: string>
# operationId: Model_UpdatePrebuiltEntityRole
export def "model-update-prebuilt-entity-role" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/apps/{appId}/versions/{versionId}/prebuilts/{entityId}/roles/{roleId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}, {name: roleId, var: role_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, role_id: $role_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a prebuilt entity extractor from a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/prebuilts/{prebuiltId}
# Returns: record<code: string, message: string>
# operationId: Model_DeletePrebuilt
export def "model-delete-prebuilt" [
  app_id: string
  version_id: string
  prebuilt_id: string
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
    path: "/apps/{appId}/versions/{versionId}/prebuilts/{prebuiltId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: prebuiltId, var: prebuilt_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, prebuilt_id: $prebuilt_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a prebuilt entity model in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/prebuilts/{prebuiltId}
# Returns: record<id: string, name: string, readableType: string, typeId: int, roles: table<id: string, name: string>>
# operationId: Model_GetPrebuilt
export def "model-get-prebuilt" [
  app_id: string
  version_id: string
  prebuilt_id: string
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
    path: "/apps/{appId}/versions/{versionId}/prebuilts/{prebuiltId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: prebuiltId, var: prebuilt_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, prebuilt_id: $prebuilt_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the regular expression entity models in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/regexentities
# Returns: table<regexPattern: string, id: string, name: string, readableType: string, typeId: int, roles: list<record>>
# operationId: Model_ListRegexEntityInfos
export def "model-list-regex-entity-infos" [
  app_id: string
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
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/versions/{versionId}/regexentities"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    query: [{name: skip, var: skip}, {name: take, var: take}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, skip: $skip, take: $take
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a regular expression entity model to a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/regexentities
# Returns: string
# operationId: Model_CreateRegexEntityModel
export def "model-create-regex-entity-model" [
  app_id: string
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
  --name: string # The model name.
  --regex-pattern: string # The regular expression entity pattern.
]: any -> any {
  $in | http-request {
    method: post
    path: "/apps/{appId}/versions/{versionId}/regexentities"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: regexPattern, var: regex_pattern}]}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, name: $name, regex_pattern: $regex_pattern
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all roles for a regular expression entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/regexentities/{entityId}/roles
# Returns: table<id: string, name: string>
# operationId: Model_ListRegexEntityRoles
export def "model-list-regex-entity-roles" [
  app_id: string
  version_id: string
  entity_id: string
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
    path: "/apps/{appId}/versions/{versionId}/regexentities/{entityId}/roles"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a role for an regular expression entity in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/regexentities/{entityId}/roles
# Returns: string
# operationId: Model_CreateRegexEntityRole
export def "model-create-regex-entity-role" [
  app_id: string
  version_id: string
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> any {
  $in | http-request {
    method: post
    path: "/apps/{appId}/versions/{versionId}/regexentities/{entityId}/roles"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a role for a given regular expression in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/regexentities/{entityId}/roles/{roleId}
# Returns: record<code: string, message: string>
# operationId: Model_DeleteRegexEntityRole
export def "model-delete-regex-entity-role" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
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
    path: "/apps/{appId}/versions/{versionId}/regexentities/{entityId}/roles/{roleId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}, {name: roleId, var: role_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, role_id: $role_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get one role for a given regular expression entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/regexentities/{entityId}/roles/{roleId}
# Returns: record<id: string, name: string>
# operationId: Model_GetRegexEntityRole
export def "model-get-regex-entity-role" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
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
    path: "/apps/{appId}/versions/{versionId}/regexentities/{entityId}/roles/{roleId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}, {name: roleId, var: role_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, role_id: $role_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a role for a given regular expression entity in a version of the application
#
# PUT /apps/{appId}/versions/{versionId}/regexentities/{entityId}/roles/{roleId}
# Returns: record<code: string, message: string>
# operationId: Model_UpdateRegexEntityRole
export def "model-update-regex-entity-role" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/apps/{appId}/versions/{versionId}/regexentities/{entityId}/roles/{roleId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: entityId, var: entity_id}, {name: roleId, var: role_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, entity_id: $entity_id, role_id: $role_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a regular expression entity from a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/regexentities/{regexEntityId}
# Returns: record<code: string, message: string>
# operationId: Model_DeleteRegexEntityModel
export def "model-delete-regex-entity-model" [
  app_id: string
  version_id: string
  regex_entity_id: string
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
    path: "/apps/{appId}/versions/{versionId}/regexentities/{regexEntityId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: regexEntityId, var: regex_entity_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, regex_entity_id: $regex_entity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a regular expression entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/regexentities/{regexEntityId}
# Returns: record<regexPattern: string, id: string, name: string, readableType: string, typeId: int, roles: table<id: string, name: string>>
# operationId: Model_GetRegexEntityEntityInfo
export def "model-get-regex-entity-entity-info" [
  app_id: string
  version_id: string
  regex_entity_id: string
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
    path: "/apps/{appId}/versions/{versionId}/regexentities/{regexEntityId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: regexEntityId, var: regex_entity_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, regex_entity_id: $regex_entity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the regular expression entity in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/regexentities/{regexEntityId}
# Returns: record<code: string, message: string>
# operationId: Model_UpdateRegexEntityModel
export def "model-update-regex-entity-model" [
  app_id: string
  version_id: string
  regex_entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The model name.
  --regex-pattern: string # The regular expression entity pattern.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/apps/{appId}/versions/{versionId}/regexentities/{regexEntityId}"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}, {name: regexEntityId, var: regex_entity_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: regexPattern, var: regex_pattern}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, regex_entity_id: $regex_entity_id, name: $name, regex_pattern: $regex_pattern
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the settings in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/settings
# Returns: table<name: string, value: string>
# operationId: Settings_List
export def "settings-list" [
  app_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/versions/{versionId}/settings"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the settings in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/settings
# Returns: record<code: string, message: string>
# operationId: Settings_Update
export def "settings-update" [
  app_id: string
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
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/apps/{appId}/versions/{versionId}/settings"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deleted an unlabelled utterance in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/suggest
# Returns: record<code: string, message: string>
# operationId: Versions_DeleteUnlabelledUtterance
export def "versions-delete-unlabelled-utterance" [
  app_id: string
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
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/apps/{appId}/versions/{versionId}/suggest"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the training status of all models (intents and entities) for the specified LUIS app. You must call the train API to train the LUIS app before you call this API to get training status. "appID" specifies the LUIS app ID. "versionId" specifies the version number of the LUIS app. For example, "0.1".
#
# GET /apps/{appId}/versions/{versionId}/train
# Returns: table<details: record<exampleCount: int, failureReason: string, status: string, statusId: int, trainingDateTime: string>, modelId: string>
# operationId: Train_GetStatus
export def "train-get-status" [
  app_id: string
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
    path: "/apps/{appId}/versions/{versionId}/train"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    accept: ["application/json", JSON]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Sends a training request for a version of a specified LUIS app. This POST request initiates a request asynchronously. To determine whether the training request is successful, submit a GET request to get training status. Note: The application version is not fully trained unless all the models (intents and entities) are trained successfully or are up to date. To verify training success, get the training status at least once after training is complete.
#
# POST /apps/{appId}/versions/{versionId}/train
# Returns: record<status: string, statusId: int>
# operationId: Train_TrainVersion
export def "train-train-version" [
  app_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/versions/{versionId}/train"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# user - Get LUIS Azure accounts
#
# GET /azureaccounts
# Returns: table<accountName: string, azureSubscriptionId: string, resourceGroup: string>
# operationId: AzureAccounts_ListUserLUISAccounts
export def "azure-accounts-list-user-luis-accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The bearer authorization header to use; containing the user's ARM token used to validate Azure accounts information. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/azureaccounts"
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# package - Gets published LUIS application package in binary stream GZip format
#
# GET /package/{appId}/slot/{slotName}/gzip
# Returns: binary
# operationId: Apps_PackagePublishedApplicationAsGzip
export def "apps-package-published-application-as-gzip" [
  app_id: string
  slot_name: string
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
    path: "/package/{appId}/slot/{slotName}/gzip"
    path_params: [{name: appId, var: app_id}, {name: slotName, var: slot_name}]
    accept: ["application/octet-stream", "application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, slot_name: $slot_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# package - Gets trained LUIS application package in binary stream GZip format
#
# GET /package/{appId}/versions/{versionId}/gzip
# Returns: binary
# operationId: Apps_PackageTrainedApplicationAsGzip
export def "apps-package-trained-application-as-gzip" [
  app_id: string
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
  --accept: string@accept-completer-1 # Response content type
]: nothing -> any {
  http-request {
    method: get
    path: "/package/{appId}/versions/{versionId}/gzip"
    path_params: [{name: appId, var: app_id}, {name: versionId, var: version_id}]
    accept: ["application/octet-stream", "application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    app_id: $app_id, version_id: $version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
