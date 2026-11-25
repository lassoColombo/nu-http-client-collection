# Auto-generated client for Face Client v1.0
# Source: https://api.apis.guru/v2/specs/azure.com/cognitiveservices-Face/1.0/swagger.json
# Auth: --token flag or $env.FACE_CLIENT_TOKEN

const CLIENT = {
  base_url: "{Endpoint}/face/v1.0"
  token_env_var: "FACE_CLIENT_TOKEN"
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

def base-url-completer [] { ["{Endpoint}/face/v1.0"] }
def auth-scheme-completer [] { ["ocp-apim-subscription-key"] }

# Completers for enum parameters
def recognition-model-completer [] { ["recognition_01" "recognition_02"] }
def detection-model-completer [] { ["detection_01" "detection_02"] }
def mode-completer [] { ["matchFace" "matchPerson"] }
def type-completer [] { ["FaceList" "LargeFaceList" "LargePersonGroup" "PersonGroup"] }
def mode-completer-1 [] { ["CreateNew"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    face-detect-with-url: "table<faceAttributes: record<accessories: list, age: float, blur: record, emotion: record, exposure: record, facialHair: record, gender: string, glasses: string, hair: record, headPose: record, makeup: record, noise: record, occlusion: record, smile: float>, faceId: string, faceLandmarks: record<eyeLeftBottom: record, eyeLeftInner: record, eyeLeftOuter: record, eyeLeftTop: record, eyeRightBottom: record, eyeRightInner: record, eyeRightOuter: record, eyeRightTop: record, eyebrowLeftInner: record, eyebrowLeftOuter: record, eyebrowRightInner: record, eyebrowRightOuter: record, mouthLeft: record, mouthRight: record, noseLeftAlarOutTip: record, noseLeftAlarTop: record, noseRightAlarOutTip: record, noseRightAlarTop: record, noseRootLeft: record, noseRootRight: record, noseTip: record, pupilLeft: record, pupilRight: record, underLipBottom: record, underLipTop: record, upperLipBottom: record, upperLipTop: record>, faceRectangle: record<height: int, left: int, top: int, width: int>, recognitionModel: string>"
    face-list-list: "table<faceListId: string, persistedFaces: list<record>, recognitionModel: string, name: string, userData: string>"
    face-list-get: "record<faceListId: string, persistedFaces: table<persistedFaceId: string, userData: string>, recognitionModel: string, name: string, userData: string>"
    face-list-add-face-from-url: "record<persistedFaceId: string, userData: string>"
    face-find-similar: "table<confidence: float, faceId: string, persistedFaceId: string>"
    face-group: "record<groups: list<list<string>>, messyGroup: list<string>>"
    face-identify: "table<candidates: list<record>, faceId: string>"
    large-face-list-list: "table<largeFaceListId: string, recognitionModel: string, name: string, userData: string>"
    large-face-list-get: "record<largeFaceListId: string, recognitionModel: string, name: string, userData: string>"
    large-face-list-list-faces: "table<persistedFaceId: string, userData: string>"
    large-face-list-add-face-from-url: "record<persistedFaceId: string, userData: string>"
    large-face-list-get-face: "record<persistedFaceId: string, userData: string>"
    large-face-list-get-training-status: "record<createdDateTime: string, lastActionDateTime: string, lastSuccessfulTrainingDateTime: string, message: string, status: string>"
    large-person-group-list: "table<largePersonGroupId: string, recognitionModel: string, name: string, userData: string>"
    large-person-group-get: "record<largePersonGroupId: string, recognitionModel: string, name: string, userData: string>"
    large-person-group-person-list: "table<persistedFaceIds: list<string>, personId: string, name: string, userData: string>"
    large-person-group-person-create: "record<persistedFaceIds: list<string>, personId: string, name: string, userData: string>"
    large-person-group-person-get: "record<persistedFaceIds: list<string>, personId: string, name: string, userData: string>"
    large-person-group-person-add-face-from-url: "record<persistedFaceId: string, userData: string>"
    large-person-group-person-get-face: "record<persistedFaceId: string, userData: string>"
    large-person-group-get-training-status: "record<createdDateTime: string, lastActionDateTime: string, lastSuccessfulTrainingDateTime: string, message: string, status: string>"
    snapshot-get-operation-status: "record<createdTime: string, lastActionTime: string, message: string, resourceLocation: string, status: string>"
    person-group-list: "table<personGroupId: string, recognitionModel: string, name: string, userData: string>"
    person-group-get: "record<personGroupId: string, recognitionModel: string, name: string, userData: string>"
    person-group-person-list: "table<persistedFaceIds: list<string>, personId: string, name: string, userData: string>"
    person-group-person-create: "record<persistedFaceIds: list<string>, personId: string, name: string, userData: string>"
    person-group-person-get: "record<persistedFaceIds: list<string>, personId: string, name: string, userData: string>"
    person-group-person-add-face-from-url: "record<persistedFaceId: string, userData: string>"
    person-group-person-get-face: "record<persistedFaceId: string, userData: string>"
    person-group-get-training-status: "record<createdDateTime: string, lastActionDateTime: string, lastSuccessfulTrainingDateTime: string, message: string, status: string>"
    snapshot-list: "table<account: string, applyScope: list<string>, createdTime: string, id: string, lastUpdateTime: string, type: string, userData: string>"
    snapshot-get: "record<account: string, applyScope: list<string>, createdTime: string, id: string, lastUpdateTime: string, type: string, userData: string>"
    face-verify-face-to-face: "record<confidence: float, isIdentical: bool>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["face-detect-with-url" "face-list-list" "face-list-delete" "face-list-get" "face-list-update" "face-list-create" "face-list-add-face-from-url" "face-list-delete-face" "face-find-similar" "face-group" "face-identify" "large-face-list-list" "large-face-list-delete" "large-face-list-get" "large-face-list-update" "large-face-list-create" "large-face-list-list-faces" "large-face-list-add-face-from-url" "large-face-list-delete-face" "large-face-list-get-face" "large-face-list-update-face" "large-face-list-train" "large-face-list-get-training-status" "large-person-group-list" "large-person-group-delete" "large-person-group-get" "large-person-group-update" "large-person-group-create" "large-person-group-person-list" "large-person-group-person-create" "large-person-group-person-delete" "large-person-group-person-get" "large-person-group-person-update" "large-person-group-person-add-face-from-url" "large-person-group-person-delete-face" "large-person-group-person-get-face" "large-person-group-person-update-face" "large-person-group-train" "large-person-group-get-training-status" "snapshot-get-operation-status" "person-group-list" "person-group-delete" "person-group-get" "person-group-update" "person-group-create" "person-group-person-list" "person-group-person-create" "person-group-person-delete" "person-group-person-get" "person-group-person-update" "person-group-person-add-face-from-url" "person-group-person-delete-face" "person-group-person-get-face" "person-group-person-update-face" "person-group-train" "person-group-get-training-status" "snapshot-list" "snapshot-take" "snapshot-delete" "snapshot-get" "snapshot-update" "snapshot-apply" "face-verify-face-to-face" "commands"] | sort) } | get name | first)
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

# Detect human faces in an image, return face rectangles, and optionally with faceIds, landmarks, and attributes. * No image will be stored. Only the extracted face feature will be stored on server. The faceId is an identifier of the face feature and will be used in [Face - Identify](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395239), [Face - Verify](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039523a), and [Face - Find Similar](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395237). The stored face feature(s) will expire and be deleted 24 hours after the original detection call. * Optional parameters include faceId, landmarks, and attributes. Attributes include age, gender, headPose, smile, facialHair, glasses, emotion, hair, makeup, occlusion, accessories, blur, exposure and noise. Some of the results returned for specific attributes may not be highly accurate. * JPEG, PNG, GIF (the first frame), and BMP format are supported. The allowed image file size is from 1KB to 6MB. * Up to 100 faces can be returned for an image. Faces are ranked by face rectangle size from large to small. * For optimal results when querying [Face - Identify](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395239), [Face - Verify](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039523a), and [Face - Find Similar](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395237) ('returnFaceId' is true), please use faces that are: frontal, clear, and with a minimum size of 200x200 pixels (100 pixels between eyes). * The minimum detectable face size is 36x36 pixels in an image no larger than 1920x1080 pixels. Images with dimensions higher than 1920x1080 pixels will need a proportionally larger minimum face size. * Different 'detectionModel' values can be provided. To use and compare different detection models, please refer to [How to specify a detection model](https://docs.microsoft.com/en-us/azure/cognitive-services/face/face-api-how-to-topics/specify-detection-model) | Model | Recommended use-case(s) | | ---------- | -------- | | 'detection_01': | The default detection model for [Face - Detect](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236). Recommend for near frontal face detection. For scenarios with exceptionally large angle (head-pose) faces, occluded faces or wrong image orientation, the faces in such cases may not be detected. | | 'detection_02': | Detection model released in 2019 May with improved accuracy especially on small, side and blurry faces. | * Different 'recognitionModel' values are provided. If follow-up operations like Verify, Identify, Find Similar are needed, please specify the recognition model with 'recognitionModel' parameter. The default value for 'recognitionModel' is 'recognition_01', if latest model needed, please explicitly specify the model you need in this parameter. Once specified, the detected faceIds will be associated with the specified recognition model. More details, please refer to [How to specify a recognition model](https://docs.microsoft.com/en-us/azure/cognitive-services/face/face-api-how-to-topics/specify-recognition-model) | Model | Recommended use-case(s) | | ---------- | -------- | | 'recognition_01': | The default recognition model for [Face - Detect](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236). All those faceIds created before 2019 March are bonded with this recognition model. | | 'recognition_02': | Recognition model released in 2019 March. 'recognition_02' is recommended since its overall accuracy is improved compared with 'recognition_01'. |
#
# POST /detect
# Returns: table<faceAttributes: record<accessories: list, age: float, blur: record, emotion: record, exposure: record, facialHair: record, gender: string, glasses: string, hair: record, headPose: record, makeup: record, noise: record, occlusion: record, smile: float>, faceId: string, faceLandmarks: record<eyeLeftBottom: record, eyeLeftInner: record, eyeLeftOuter: record, eyeLeftTop: record, eyeRightBottom: record, eyeRightInner: record, eyeRightOuter: record, eyeRightTop: record, eyebrowLeftInner: record, eyebrowLeftOuter: record, eyebrowRightInner: record, eyebrowRightOuter: record, mouthLeft: record, mouthRight: record, noseLeftAlarOutTip: record, noseLeftAlarTop: record, noseRightAlarOutTip: record, noseRightAlarTop: record, noseRootLeft: record, noseRootRight: record, noseTip: record, pupilLeft: record, pupilRight: record, underLipBottom: record, underLipTop: record, upperLipBottom: record, upperLipTop: record>, faceRectangle: record<height: int, left: int, top: int, width: int>, recognitionModel: string>
# operationId: Face_DetectWithUrl
export def "face-detect-with-url" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --return-face-id: oneof<nothing, bool> # A value indicating whether the operation should return faceIds of detected faces. (default: true)
  --return-face-landmarks: oneof<nothing, bool> # A value indicating whether the operation should return landmarks of the detected faces. (default: false)
  --return-face-attributes: list<string> # Analyze and return the one or more specified face attributes in the comma-separated string like "returnFaceAttributes=age,gender". Supported face attributes include age, gender, headPose, smile, facialHair, glasses and emotion. Note that each face attribute analysis has additional computational and time cost.
  --recognition-model: string@recognition-model-completer # Name of recognition model. Recognition model is used when the face features are extracted and associated with detected faceIds, (Large)FaceList or (Large)PersonGroup. A recognition model name can be provided when performing Face - Detect or (Large)FaceList - Create or (Large)PersonGroup - Create. The default value is 'recognition_01', if latest model needed, please explicitly specify the model you need. (default: recognition_01)
  --return-recognition-model: oneof<nothing, bool> # A value indicating whether the operation should return 'recognitionModel' in response. (default: false)
  --detection-model: string@detection-model-completer # Name of detection model. Detection model is used to detect faces in the submitted image. A detection model name can be provided when performing Face - Detect or (Large)FaceList - Add Face or (Large)PersonGroup - Add Face. The default value is 'detection_01', if another model is needed, please explicitly specify it. (default: detection_01)
  url: string # Publicly reachable URL of an image
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/detect"
    query: [{name: returnFaceId, var: return_face_id}, {name: returnFaceLandmarks, var: return_face_landmarks}, {name: returnFaceAttributes, var: return_face_attributes, style: csv}, {name: recognitionModel, var: recognition_model}, {name: returnRecognitionModel, var: return_recognition_model}, {name: detectionModel, var: detection_model}]
    body: {content_type: "application/json", kind: json, fields: [{name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    return_face_id: $return_face_id, return_face_landmarks: $return_face_landmarks, return_face_attributes: $return_face_attributes, recognition_model: $recognition_model, return_recognition_model: $return_recognition_model, detection_model: $detection_model, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List face lists’ faceListId, name, userData and recognitionModel. To get face information inside faceList use [FaceList - Get](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039524c)
#
# GET /facelists
# Returns: table<faceListId: string, persistedFaces: list<record>, recognitionModel: string, name: string, userData: string>
# operationId: FaceList_List
export def "face-list-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --return-recognition-model: oneof<nothing, bool> # A value indicating whether the operation should return 'recognitionModel' in response. (default: false)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/facelists"
    query: [{name: returnRecognitionModel, var: return_recognition_model}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    return_recognition_model: $return_recognition_model
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specified face list.
#
# DELETE /facelists/{faceListId}
# operationId: FaceList_Delete
export def "face-list-delete" [
  face_list_id: string
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
    path: "/facelists/{faceListId}"
    path_params: [{name: faceListId, var: face_list_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    face_list_id: $face_list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a face list’s faceListId, name, userData, recognitionModel and faces in the face list.
#
# GET /facelists/{faceListId}
# Returns: record<faceListId: string, persistedFaces: table<persistedFaceId: string, userData: string>, recognitionModel: string, name: string, userData: string>
# operationId: FaceList_Get
export def "face-list-get" [
  face_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --return-recognition-model: oneof<nothing, bool> # A value indicating whether the operation should return 'recognitionModel' in response. (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/facelists/{faceListId}"
    path_params: [{name: faceListId, var: face_list_id}]
    query: [{name: returnRecognitionModel, var: return_recognition_model}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    face_list_id: $face_list_id, return_recognition_model: $return_recognition_model
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update information of a face list.
#
# PATCH /facelists/{faceListId}
# operationId: FaceList_Update
export def "face-list-update" [
  face_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # User defined name, maximum length is 128.
  --user-data: string # User specified data. Length should not exceed 16KB.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/facelists/{faceListId}"
    path_params: [{name: faceListId, var: face_list_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: userData, var: user_data}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    face_list_id: $face_list_id, name: $name, user_data: $user_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an empty face list with user-specified faceListId, name, an optional userData and recognitionModel. Up to 64 face lists are allowed in one subscription. Face list is a list of faces, up to 1,000 faces, and used by [Face - Find Similar](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395237). After creation, user should use [FaceList - Add Face](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395250) to import the faces. No image will be stored. Only the extracted face features are stored on server until [FaceList - Delete](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039524f) is called. Find Similar is used for scenario like finding celebrity-like faces, similar face filtering, or as a light way face identification. But if the actual use is to identify person, please use [PersonGroup](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395244) / [LargePersonGroup](/docs/services/563879b61984550e40cbbe8d/operations/599acdee6ac60f11b48b5a9d) and [Face - Identify](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395239). Please consider [LargeFaceList](/docs/services/563879b61984550e40cbbe8d/operations/5a157b68d2de3616c086f2cc) when the face number is large. It can support up to 1,000,000 faces. 'recognitionModel' should be specified to associate with this face list. The default value for 'recognitionModel' is 'recognition_01', if the latest model needed, please explicitly specify the model you need in this parameter. New faces that are added to an existing face list will use the recognition model that's already associated with the collection. Existing face features in a face list can't be updated to features extracted by another version of recognition model. * 'recognition_01': The default recognition model for [FaceList- Create](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039524b). All those face lists created before 2019 March are bonded with this recognition model. * 'recognition_02': Recognition model released in 2019 March. 'recognition_02' is recommended since its overall accuracy is improved compared with 'recognition_01'.
#
# PUT /facelists/{faceListId}
# operationId: FaceList_Create
export def "face-list-create" [
  face_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --recognition-model: string@recognition-model-completer # Name of recognition model. Recognition model is used when the face features are extracted and associated with detected faceIds, (Large)FaceList or (Large)PersonGroup. A recognition model name can be provided when performing Face - Detect or (Large)FaceList - Create or (Large)PersonGroup - Create. The default value is 'recognition_01', if latest model needed, please explicitly specify the model you need. (default: recognition_01)
  --name: string # User defined name, maximum length is 128.
  --user-data: string # User specified data. Length should not exceed 16KB.
]: any -> any {
  $in | http-request {
    method: put
    path: "/facelists/{faceListId}"
    path_params: [{name: faceListId, var: face_list_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: recognitionModel, var: recognition_model}, {name: name, var: name}, {name: userData, var: user_data}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    face_list_id: $face_list_id, recognition_model: $recognition_model, name: $name, user_data: $user_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a face to a specified face list, up to 1,000 faces. To deal with an image contains multiple faces, input face can be specified as an image with a targetFace rectangle. It returns a persistedFaceId representing the added face. No image will be stored. Only the extracted face feature will be stored on server until [FaceList - Delete Face](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395251) or [FaceList - Delete](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039524f) is called. Note persistedFaceId is different from faceId generated by [Face - Detect](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236). * Higher face image quality means better detection and recognition precision. Please consider high-quality faces: frontal, clear, and face size is 200x200 pixels (100 pixels between eyes) or bigger. * JPEG, PNG, GIF (the first frame), and BMP format are supported. The allowed image file size is from 1KB to 6MB. * "targetFace" rectangle should contain one face. Zero or multiple faces will be regarded as an error. If the provided "targetFace" rectangle is not returned from [Face - Detect](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236), there’s no guarantee to detect and add the face successfully. * Out of detectable face size (36x36 - 4096x4096 pixels), large head-pose, or large occlusions will cause failures. * Adding/deleting faces to/from a same face list are processed sequentially and to/from different face lists are in parallel. * The minimum detectable face size is 36x36 pixels in an image no larger than 1920x1080 pixels. Images with dimensions higher than 1920x1080 pixels will need a proportionally larger minimum face size. * Different 'detectionModel' values can be provided. To use and compare different detection models, please refer to [How to specify a detection model](https://docs.microsoft.com/en-us/azure/cognitive-services/face/face-api-how-to-topics/specify-detection-model) | Model | Recommended use-case(s) | | ---------- | -------- | | 'detection_01': | The default detection model for [FaceList - Add Face](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395250). Recommend for near frontal face detection. For scenarios with exceptionally large angle (head-pose) faces, occluded faces or wrong image orientation, the faces in such cases may not be detected. | | 'detection_02': | Detection model released in 2019 May with improved accuracy especially on small, side and blurry faces. |
#
# POST /facelists/{faceListId}/persistedfaces
# Returns: record<persistedFaceId: string, userData: string>
# operationId: FaceList_AddFaceFromUrl
export def "face-list-add-face-from-url" [
  face_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-data: string # User-specified data about the face for any purpose. The maximum length is 1KB.
  --target-face: list<int> # A face rectangle to specify the target face to be added to a person in the format of "targetFace=left,top,width,height". E.g. "targetFace=10,10,100,100". If there is more than one face in the image, targetFace is required to specify which face to add. No targetFace means there is only one face detected in the entire image.
  --detection-model: string@detection-model-completer # Name of detection model. Detection model is used to detect faces in the submitted image. A detection model name can be provided when performing Face - Detect or (Large)FaceList - Add Face or (Large)PersonGroup - Add Face. The default value is 'detection_01', if another model is needed, please explicitly specify it. (default: detection_01)
  url: string # Publicly reachable URL of an image
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/facelists/{faceListId}/persistedfaces"
    path_params: [{name: faceListId, var: face_list_id}]
    query: [{name: userData, var: user_data}, {name: targetFace, var: target_face, style: csv}, {name: detectionModel, var: detection_model}]
    body: {content_type: "application/json", kind: json, fields: [{name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    face_list_id: $face_list_id, user_data: $user_data, target_face: $target_face, detection_model: $detection_model, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a face from a face list by specified faceListId and persistedFaceId. Adding/deleting faces to/from a same face list are processed sequentially and to/from different face lists are in parallel.
#
# DELETE /facelists/{faceListId}/persistedfaces/{persistedFaceId}
# operationId: FaceList_DeleteFace
export def "face-list-delete-face" [
  face_list_id: string
  persisted_face_id: string
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
    path: "/facelists/{faceListId}/persistedfaces/{persistedFaceId}"
    path_params: [{name: faceListId, var: face_list_id}, {name: persistedFaceId, var: persisted_face_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    face_list_id: $face_list_id, persisted_face_id: $persisted_face_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Given query face's faceId, to search the similar-looking faces from a faceId array, a face list or a large face list. faceId array contains the faces created by [Face - Detect](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236), which will expire 24 hours after creation. A "faceListId" is created by [FaceList - Create](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039524b) containing persistedFaceIds that will not expire. And a "largeFaceListId" is created by [LargeFaceList - Create](/docs/services/563879b61984550e40cbbe8d/operations/5a157b68d2de3616c086f2cc) containing persistedFaceIds that will also not expire. Depending on the input the returned similar faces list contains faceIds or persistedFaceIds ranked by similarity. Find similar has two working modes, "matchPerson" and "matchFace". "matchPerson" is the default mode that it tries to find faces of the same person as possible by using internal same-person thresholds. It is useful to find a known person's other photos. Note that an empty list will be returned if no faces pass the internal thresholds. "matchFace" mode ignores same-person thresholds and returns ranked similar faces anyway, even the similarity is low. It can be used in the cases like searching celebrity-looking faces. The 'recognitionModel' associated with the query face's faceId should be the same as the 'recognitionModel' used by the target faceId array, face list or large face list.
#
# POST /findsimilars
# Returns: table<confidence: float, faceId: string, persistedFaceId: string>
# operationId: Face_FindSimilar
export def "face-find-similar" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  face_id: string # FaceId of the query face. User needs to call Face - Detect first to get a valid faceId. Note that this faceId is not persisted and will expire 24 hours after the detection call (format: uuid)
  --face-ids: list<string> # An array of candidate faceIds. All of them are created by Face - Detect and the faceIds will expire 24 hours after the detection call. The number of faceIds is limited to 1000. Parameter faceListId, largeFaceListId and faceIds should not be provided at the same time.
  --face-list-id: string # An existing user-specified unique candidate face list, created in Face List - Create a Face List. Face list contains a set of persistedFaceIds which are persisted and will never expire. Parameter faceListId, largeFaceListId and faceIds should not be provided at the same time.
  --large-face-list-id: string # An existing user-specified unique candidate large face list, created in LargeFaceList - Create. Large face list contains a set of persistedFaceIds which are persisted and will never expire. Parameter faceListId, largeFaceListId and faceIds should not be provided at the same time.
  --max-num-of-candidates-returned: int # The number of top similar faces returned. The valid range is [1, 1000]. (default: 20)
  --mode: string@mode-completer # Similar face searching mode. It can be "matchPerson" or "matchFace". (default: matchPerson)
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/findsimilars"
    body: {content_type: "application/json", kind: json, fields: [{name: faceId, var: face_id}, {name: faceIds, var: face_ids}, {name: faceListId, var: face_list_id}, {name: largeFaceListId, var: large_face_list_id}, {name: maxNumOfCandidatesReturned, var: max_num_of_candidates_returned}, {name: mode, var: mode}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    face_id: $face_id, face_ids: $face_ids, face_list_id: $face_list_id, large_face_list_id: $large_face_list_id, max_num_of_candidates_returned: $max_num_of_candidates_returned, mode: $mode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Divide candidate faces into groups based on face similarity. * The output is one or more disjointed face groups and a messyGroup. A face group contains faces that have similar looking, often of the same person. Face groups are ranked by group size, i.e. number of faces. Notice that faces belonging to a same person might be split into several groups in the result. * MessyGroup is a special face group containing faces that cannot find any similar counterpart face from original faces. The messyGroup will not appear in the result if all faces found their counterparts. * Group API needs at least 2 candidate faces and 1000 at most. We suggest to try [Face - Verify](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039523a) when you only have 2 candidate faces. * The 'recognitionModel' associated with the query faces' faceIds should be the same.
#
# POST /group
# Returns: record<groups: list<list<string>>, messyGroup: list<string>>
# operationId: Face_Group
export def "face-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  face_ids: list<string> # Array of candidate faceId created by Face - Detect. The maximum is 1000 faces
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/group"
    body: {content_type: "application/json", kind: json, fields: [{name: faceIds, var: face_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    face_ids: $face_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# 1-to-many identification to find the closest matches of the specific query person face from a person group or large person group. For each face in the faceIds array, Face Identify will compute similarities between the query face and all the faces in the person group (given by personGroupId) or large person group (given by largePersonGroupId), and return candidate person(s) for that face ranked by similarity confidence. The person group/large person group should be trained to make it ready for identification. See more in [PersonGroup - Train](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395249) and [LargePersonGroup - Train](/docs/services/563879b61984550e40cbbe8d/operations/599ae2d16ac60f11b48b5aa4). Remarks: * The algorithm allows more than one face to be identified independently at the same request, but no more than 10 faces. * Each person in the person group/large person group could have more than one face, but no more than 248 faces. * Higher face image quality means better identification precision. Please consider high-quality faces: frontal, clear, and face size is 200x200 pixels (100 pixels between eyes) or bigger. * Number of candidates returned is restricted by maxNumOfCandidatesReturned and confidenceThreshold. If no person is identified, the returned candidates will be an empty array. * Try [Face - Find Similar](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395237) when you need to find similar faces from a face list/large face list instead of a person group/large person group. * The 'recognitionModel' associated with the query faces' faceIds should be the same as the 'recognitionModel' used by the target person group or large person group.
#
# POST /identify
# Returns: table<candidates: list<record>, faceId: string>
# operationId: Face_Identify
export def "face-identify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --confidence-threshold: float # A number ranging from 0 to 1 indicating a level of confidence associated with a property.
  face_ids: list<string> # Array of query faces faceIds, created by the Face - Detect. Each of the faces are identified independently. The valid number of faceIds is between [1, 10].
  --large-person-group-id: string # LargePersonGroupId of the target large person group, created by LargePersonGroup - Create. Parameter personGroupId and largePersonGroupId should not be provided at the same time.
  --max-num-of-candidates-returned: int # The range of maxNumOfCandidatesReturned is between 1 and 5 (default is 1). (default: 1)
  --person-group-id: string # PersonGroupId of the target person group, created by PersonGroup - Create. Parameter personGroupId and largePersonGroupId should not be provided at the same time.
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/identify"
    body: {content_type: "application/json", kind: json, fields: [{name: confidenceThreshold, var: confidence_threshold}, {name: faceIds, var: face_ids}, {name: largePersonGroupId, var: large_person_group_id}, {name: maxNumOfCandidatesReturned, var: max_num_of_candidates_returned}, {name: personGroupId, var: person_group_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    confidence_threshold: $confidence_threshold, face_ids: $face_ids, large_person_group_id: $large_person_group_id, max_num_of_candidates_returned: $max_num_of_candidates_returned, person_group_id: $person_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List large face lists’ information of largeFaceListId, name, userData and recognitionModel. To get face information inside largeFaceList use [LargeFaceList Face - Get](/docs/services/563879b61984550e40cbbe8d/operations/5a158cf2d2de3616c086f2d5) * Large face lists are stored in alphabetical order of largeFaceListId. * "start" parameter (string, optional) is a user-provided largeFaceListId value that returned entries have larger ids by string comparison. "start" set to empty to indicate return from the first item. * "top" parameter (int, optional) specifies the number of entries to return. A maximal of 1000 entries can be returned in one call. To fetch more, you can specify "start" with the last returned entry’s Id of the current call. For example, total 5 large person lists: "list1", ..., "list5". "start=&top=" will return all 5 lists. "start=&top=2" will return "list1", "list2". "start=list2&top=3" will return "list3", "list4", "list5".
#
# GET /largefacelists
# Returns: table<largeFaceListId: string, recognitionModel: string, name: string, userData: string>
# operationId: LargeFaceList_List
export def "large-face-list-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --return-recognition-model: oneof<nothing, bool> # A value indicating whether the operation should return 'recognitionModel' in response. (default: false)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/largefacelists"
    query: [{name: returnRecognitionModel, var: return_recognition_model}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    return_recognition_model: $return_recognition_model
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specified large face list.
#
# DELETE /largefacelists/{largeFaceListId}
# operationId: LargeFaceList_Delete
export def "large-face-list-delete" [
  large_face_list_id: string
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
    path: "/largefacelists/{largeFaceListId}"
    path_params: [{name: largeFaceListId, var: large_face_list_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    large_face_list_id: $large_face_list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a large face list’s largeFaceListId, name, userData and recognitionModel.
#
# GET /largefacelists/{largeFaceListId}
# Returns: record<largeFaceListId: string, recognitionModel: string, name: string, userData: string>
# operationId: LargeFaceList_Get
export def "large-face-list-get" [
  large_face_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --return-recognition-model: oneof<nothing, bool> # A value indicating whether the operation should return 'recognitionModel' in response. (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/largefacelists/{largeFaceListId}"
    path_params: [{name: largeFaceListId, var: large_face_list_id}]
    query: [{name: returnRecognitionModel, var: return_recognition_model}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    large_face_list_id: $large_face_list_id, return_recognition_model: $return_recognition_model
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update information of a large face list.
#
# PATCH /largefacelists/{largeFaceListId}
# operationId: LargeFaceList_Update
export def "large-face-list-update" [
  large_face_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # User defined name, maximum length is 128.
  --user-data: string # User specified data. Length should not exceed 16KB.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/largefacelists/{largeFaceListId}"
    path_params: [{name: largeFaceListId, var: large_face_list_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: userData, var: user_data}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    large_face_list_id: $large_face_list_id, name: $name, user_data: $user_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an empty large face list with user-specified largeFaceListId, name, an optional userData and recognitionModel. Large face list is a list of faces, up to 1,000,000 faces, and used by [Face - Find Similar](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395237). After creation, user should use [LargeFaceList Face - Add](/docs/services/563879b61984550e40cbbe8d/operations/5a158c10d2de3616c086f2d3) to import the faces and [LargeFaceList - Train](/docs/services/563879b61984550e40cbbe8d/operations/5a158422d2de3616c086f2d1) to make it ready for [Face - Find Similar](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395237). No image will be stored. Only the extracted face features are stored on server until [LargeFaceList - Delete](/docs/services/563879b61984550e40cbbe8d/operations/5a1580d5d2de3616c086f2cd) is called. Find Similar is used for scenario like finding celebrity-like faces, similar face filtering, or as a light way face identification. But if the actual use is to identify person, please use [PersonGroup](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395244) / [LargePersonGroup](/docs/services/563879b61984550e40cbbe8d/operations/599acdee6ac60f11b48b5a9d) and [Face - Identify](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395239). 'recognitionModel' should be specified to associate with this large face list. The default value for 'recognitionModel' is 'recognition_01', if the latest model needed, please explicitly specify the model you need in this parameter. New faces that are added to an existing large face list will use the recognition model that's already associated with the collection. Existing face features in a large face list can't be updated to features extracted by another version of recognition model. * 'recognition_01': The default recognition model for [LargeFaceList- Create](/docs/services/563879b61984550e40cbbe8d/operations/5a157b68d2de3616c086f2cc). All those large face lists created before 2019 March are bonded with this recognition model. * 'recognition_02': Recognition model released in 2019 March. 'recognition_02' is recommended since its overall accuracy is improved compared with 'recognition_01'. Large face list quota: * Free-tier subscription quota: 64 large face lists. * S0-tier subscription quota: 1,000,000 large face lists.
#
# PUT /largefacelists/{largeFaceListId}
# operationId: LargeFaceList_Create
export def "large-face-list-create" [
  large_face_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --recognition-model: string@recognition-model-completer # Name of recognition model. Recognition model is used when the face features are extracted and associated with detected faceIds, (Large)FaceList or (Large)PersonGroup. A recognition model name can be provided when performing Face - Detect or (Large)FaceList - Create or (Large)PersonGroup - Create. The default value is 'recognition_01', if latest model needed, please explicitly specify the model you need. (default: recognition_01)
  --name: string # User defined name, maximum length is 128.
  --user-data: string # User specified data. Length should not exceed 16KB.
]: any -> any {
  $in | http-request {
    method: put
    path: "/largefacelists/{largeFaceListId}"
    path_params: [{name: largeFaceListId, var: large_face_list_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: recognitionModel, var: recognition_model}, {name: name, var: name}, {name: userData, var: user_data}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    large_face_list_id: $large_face_list_id, recognition_model: $recognition_model, name: $name, user_data: $user_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all faces in a large face list, and retrieve face information (including userData and persistedFaceIds of registered faces of the face).
#
# GET /largefacelists/{largeFaceListId}/persistedfaces
# Returns: table<persistedFaceId: string, userData: string>
# operationId: LargeFaceList_ListFaces
export def "large-face-list-list-faces" [
  large_face_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Starting face id to return (used to list a range of faces).
  --top: int # Number of faces to return starting with the face id indicated by the 'start' parameter.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/largefacelists/{largeFaceListId}/persistedfaces"
    path_params: [{name: largeFaceListId, var: large_face_list_id}]
    query: [{name: start, var: start}, {name: top, var: top}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    large_face_list_id: $large_face_list_id, start: $start, top: $top
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a face to a specified large face list, up to 1,000,000 faces. To deal with an image contains multiple faces, input face can be specified as an image with a targetFace rectangle. It returns a persistedFaceId representing the added face. No image will be stored. Only the extracted face feature will be stored on server until [LargeFaceList Face - Delete](/docs/services/563879b61984550e40cbbe8d/operations/5a158c8ad2de3616c086f2d4) or [LargeFaceList - Delete](/docs/services/563879b61984550e40cbbe8d/operations/5a1580d5d2de3616c086f2cd) is called. Note persistedFaceId is different from faceId generated by [Face - Detect](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236). * Higher face image quality means better recognition precision. Please consider high-quality faces: frontal, clear, and face size is 200x200 pixels (100 pixels between eyes) or bigger. * JPEG, PNG, GIF (the first frame), and BMP format are supported. The allowed image file size is from 1KB to 6MB. * "targetFace" rectangle should contain one face. Zero or multiple faces will be regarded as an error. If the provided "targetFace" rectangle is not returned from [Face - Detect](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236), there’s no guarantee to detect and add the face successfully. * Out of detectable face size (36x36 - 4096x4096 pixels), large head-pose, or large occlusions will cause failures. * Adding/deleting faces to/from a same face list are processed sequentially and to/from different face lists are in parallel. * The minimum detectable face size is 36x36 pixels in an image no larger than 1920x1080 pixels. Images with dimensions higher than 1920x1080 pixels will need a proportionally larger minimum face size. * Different 'detectionModel' values can be provided. To use and compare different detection models, please refer to [How to specify a detection model](https://docs.microsoft.com/en-us/azure/cognitive-services/face/face-api-how-to-topics/specify-detection-model) | Model | Recommended use-case(s) | | ---------- | -------- | | 'detection_01': | The default detection model for [LargeFaceList - Add Face](/docs/services/563879b61984550e40cbbe8d/operations/5a158c10d2de3616c086f2d3). Recommend for near frontal face detection. For scenarios with exceptionally large angle (head-pose) faces, occluded faces or wrong image orientation, the faces in such cases may not be detected. | | 'detection_02': | Detection model released in 2019 May with improved accuracy especially on small, side and blurry faces. | Quota: * Free-tier subscription quota: 1,000 faces per large face list. * S0-tier subscription quota: 1,000,000 faces per large face list.
#
# POST /largefacelists/{largeFaceListId}/persistedfaces
# Returns: record<persistedFaceId: string, userData: string>
# operationId: LargeFaceList_AddFaceFromUrl
export def "large-face-list-add-face-from-url" [
  large_face_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-data: string # User-specified data about the face for any purpose. The maximum length is 1KB.
  --target-face: list<int> # A face rectangle to specify the target face to be added to a person in the format of "targetFace=left,top,width,height". E.g. "targetFace=10,10,100,100". If there is more than one face in the image, targetFace is required to specify which face to add. No targetFace means there is only one face detected in the entire image.
  --detection-model: string@detection-model-completer # Name of detection model. Detection model is used to detect faces in the submitted image. A detection model name can be provided when performing Face - Detect or (Large)FaceList - Add Face or (Large)PersonGroup - Add Face. The default value is 'detection_01', if another model is needed, please explicitly specify it. (default: detection_01)
  url: string # Publicly reachable URL of an image
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/largefacelists/{largeFaceListId}/persistedfaces"
    path_params: [{name: largeFaceListId, var: large_face_list_id}]
    query: [{name: userData, var: user_data}, {name: targetFace, var: target_face, style: csv}, {name: detectionModel, var: detection_model}]
    body: {content_type: "application/json", kind: json, fields: [{name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    large_face_list_id: $large_face_list_id, user_data: $user_data, target_face: $target_face, detection_model: $detection_model, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a face from a large face list by specified largeFaceListId and persistedFaceId. Adding/deleting faces to/from a same large face list are processed sequentially and to/from different large face lists are in parallel.
#
# DELETE /largefacelists/{largeFaceListId}/persistedfaces/{persistedFaceId}
# operationId: LargeFaceList_DeleteFace
export def "large-face-list-delete-face" [
  large_face_list_id: string
  persisted_face_id: string
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
    path: "/largefacelists/{largeFaceListId}/persistedfaces/{persistedFaceId}"
    path_params: [{name: largeFaceListId, var: large_face_list_id}, {name: persistedFaceId, var: persisted_face_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    large_face_list_id: $large_face_list_id, persisted_face_id: $persisted_face_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve information about a persisted face (specified by persistedFaceId and its belonging largeFaceListId).
#
# GET /largefacelists/{largeFaceListId}/persistedfaces/{persistedFaceId}
# Returns: record<persistedFaceId: string, userData: string>
# operationId: LargeFaceList_GetFace
export def "large-face-list-get-face" [
  large_face_list_id: string
  persisted_face_id: string
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
    path: "/largefacelists/{largeFaceListId}/persistedfaces/{persistedFaceId}"
    path_params: [{name: largeFaceListId, var: large_face_list_id}, {name: persistedFaceId, var: persisted_face_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    large_face_list_id: $large_face_list_id, persisted_face_id: $persisted_face_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a persisted face's userData field.
#
# PATCH /largefacelists/{largeFaceListId}/persistedfaces/{persistedFaceId}
# operationId: LargeFaceList_UpdateFace
export def "large-face-list-update-face" [
  large_face_list_id: string
  persisted_face_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-data: string # User-provided data attached to the face. The size limit is 1KB.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/largefacelists/{largeFaceListId}/persistedfaces/{persistedFaceId}"
    path_params: [{name: largeFaceListId, var: large_face_list_id}, {name: persistedFaceId, var: persisted_face_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: userData, var: user_data}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    large_face_list_id: $large_face_list_id, persisted_face_id: $persisted_face_id, user_data: $user_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Queue a large face list training task, the training task may not be started immediately.
#
# POST /largefacelists/{largeFaceListId}/train
# operationId: LargeFaceList_Train
export def "large-face-list-train" [
  large_face_list_id: string
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
    path: "/largefacelists/{largeFaceListId}/train"
    path_params: [{name: largeFaceListId, var: large_face_list_id}]
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    large_face_list_id: $large_face_list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the training status of a large face list (completed or ongoing).
#
# GET /largefacelists/{largeFaceListId}/training
# Returns: record<createdDateTime: string, lastActionDateTime: string, lastSuccessfulTrainingDateTime: string, message: string, status: string>
# operationId: LargeFaceList_GetTrainingStatus
export def "large-face-list-get-training-status" [
  large_face_list_id: string
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
    path: "/largefacelists/{largeFaceListId}/training"
    path_params: [{name: largeFaceListId, var: large_face_list_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    large_face_list_id: $large_face_list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all existing large person groups’ largePersonGroupId, name, userData and recognitionModel. * Large person groups are stored in alphabetical order of largePersonGroupId. * "start" parameter (string, optional) is a user-provided largePersonGroupId value that returned entries have larger ids by string comparison. "start" set to empty to indicate return from the first item. * "top" parameter (int, optional) specifies the number of entries to return. A maximal of 1000 entries can be returned in one call. To fetch more, you can specify "start" with the last returned entry’s Id of the current call. For example, total 5 large person groups: "group1", ..., "group5". "start=&top=" will return all 5 groups. "start=&top=2" will return "group1", "group2". "start=group2&top=3" will return "group3", "group4", "group5".
#
# GET /largepersongroups
# Returns: table<largePersonGroupId: string, recognitionModel: string, name: string, userData: string>
# operationId: LargePersonGroup_List
export def "large-person-group-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # List large person groups from the least largePersonGroupId greater than the "start".
  --top: int # The number of large person groups to list. (default: 1000)
  --return-recognition-model: oneof<nothing, bool> # A value indicating whether the operation should return 'recognitionModel' in response. (default: false)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/largepersongroups"
    query: [{name: start, var: start}, {name: top, var: top}, {name: returnRecognitionModel, var: return_recognition_model}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    start: $start, top: $top, return_recognition_model: $return_recognition_model
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing large person group. Persisted face features of all people in the large person group will also be deleted.
#
# DELETE /largepersongroups/{largePersonGroupId}
# operationId: LargePersonGroup_Delete
export def "large-person-group-delete" [
  large_person_group_id: string
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
    path: "/largepersongroups/{largePersonGroupId}"
    path_params: [{name: largePersonGroupId, var: large_person_group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    large_person_group_id: $large_person_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the information of a large person group, including its name, userData and recognitionModel. This API returns large person group information only, use [LargePersonGroup Person - List](/docs/services/563879b61984550e40cbbe8d/operations/599adda06ac60f11b48b5aa1) instead to retrieve person information under the large person group.
#
# GET /largepersongroups/{largePersonGroupId}
# Returns: record<largePersonGroupId: string, recognitionModel: string, name: string, userData: string>
# operationId: LargePersonGroup_Get
export def "large-person-group-get" [
  large_person_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --return-recognition-model: oneof<nothing, bool> # A value indicating whether the operation should return 'recognitionModel' in response. (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/largepersongroups/{largePersonGroupId}"
    path_params: [{name: largePersonGroupId, var: large_person_group_id}]
    query: [{name: returnRecognitionModel, var: return_recognition_model}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    large_person_group_id: $large_person_group_id, return_recognition_model: $return_recognition_model
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing large person group's display name and userData. The properties which does not appear in request body will not be updated.
#
# PATCH /largepersongroups/{largePersonGroupId}
# operationId: LargePersonGroup_Update
export def "large-person-group-update" [
  large_person_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # User defined name, maximum length is 128.
  --user-data: string # User specified data. Length should not exceed 16KB.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/largepersongroups/{largePersonGroupId}"
    path_params: [{name: largePersonGroupId, var: large_person_group_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: userData, var: user_data}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    large_person_group_id: $large_person_group_id, name: $name, user_data: $user_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new large person group with user-specified largePersonGroupId, name, an optional userData and recognitionModel. A large person group is the container of the uploaded person data, including face recognition feature, and up to 1,000,000 people. After creation, use [LargePersonGroup Person - Create](/docs/services/563879b61984550e40cbbe8d/operations/599adcba3a7b9412a4d53f40) to add person into the group, and call [LargePersonGroup - Train](/docs/services/563879b61984550e40cbbe8d/operations/599ae2d16ac60f11b48b5aa4) to get this group ready for [Face - Identify](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395239). No image will be stored. Only the person's extracted face features and userData will be stored on server until [LargePersonGroup Person - Delete](/docs/services/563879b61984550e40cbbe8d/operations/599ade5c6ac60f11b48b5aa2) or [LargePersonGroup - Delete](/docs/services/563879b61984550e40cbbe8d/operations/599adc216ac60f11b48b5a9f) is called. 'recognitionModel' should be specified to associate with this large person group. The default value for 'recognitionModel' is 'recognition_01', if the latest model needed, please explicitly specify the model you need in this parameter. New faces that are added to an existing large person group will use the recognition model that's already associated with the collection. Existing face features in a large person group can't be updated to features extracted by another version of recognition model. * 'recognition_01': The default recognition model for [LargePersonGroup - Create](/docs/services/563879b61984550e40cbbe8d/operations/599acdee6ac60f11b48b5a9d). All those large person groups created before 2019 March are bonded with this recognition model. * 'recognition_02': Recognition model released in 2019 March. 'recognition_02' is recommended since its overall accuracy is improved compared with 'recognition_01'. Large person group quota: * Free-tier subscription quota: 1,000 large person groups. * S0-tier subscription quota: 1,000,000 large person groups.
#
# PUT /largepersongroups/{largePersonGroupId}
# operationId: LargePersonGroup_Create
export def "large-person-group-create" [
  large_person_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --recognition-model: string@recognition-model-completer # Name of recognition model. Recognition model is used when the face features are extracted and associated with detected faceIds, (Large)FaceList or (Large)PersonGroup. A recognition model name can be provided when performing Face - Detect or (Large)FaceList - Create or (Large)PersonGroup - Create. The default value is 'recognition_01', if latest model needed, please explicitly specify the model you need. (default: recognition_01)
  --name: string # User defined name, maximum length is 128.
  --user-data: string # User specified data. Length should not exceed 16KB.
]: any -> any {
  $in | http-request {
    method: put
    path: "/largepersongroups/{largePersonGroupId}"
    path_params: [{name: largePersonGroupId, var: large_person_group_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: recognitionModel, var: recognition_model}, {name: name, var: name}, {name: userData, var: user_data}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    large_person_group_id: $large_person_group_id, recognition_model: $recognition_model, name: $name, user_data: $user_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all persons in a large person group, and retrieve person information (including personId, name, userData and persistedFaceIds of registered faces of the person).
#
# GET /largepersongroups/{largePersonGroupId}/persons
# Returns: table<persistedFaceIds: list<string>, personId: string, name: string, userData: string>
# operationId: LargePersonGroupPerson_List
export def "large-person-group-person-list" [
  large_person_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Starting person id to return (used to list a range of persons).
  --top: int # Number of persons to return starting with the person id indicated by the 'start' parameter.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/largepersongroups/{largePersonGroupId}/persons"
    path_params: [{name: largePersonGroupId, var: large_person_group_id}]
    query: [{name: start, var: start}, {name: top, var: top}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    large_person_group_id: $large_person_group_id, start: $start, top: $top
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new person in a specified large person group.
#
# POST /largepersongroups/{largePersonGroupId}/persons
# Returns: record<persistedFaceIds: list<string>, personId: string, name: string, userData: string>
# operationId: LargePersonGroupPerson_Create
export def "large-person-group-person-create" [
  large_person_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # User defined name, maximum length is 128.
  --user-data: string # User specified data. Length should not exceed 16KB.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/largepersongroups/{largePersonGroupId}/persons"
    path_params: [{name: largePersonGroupId, var: large_person_group_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: userData, var: user_data}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    large_person_group_id: $large_person_group_id, name: $name, user_data: $user_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing person from a large person group. The persistedFaceId, userData, person name and face feature in the person entry will all be deleted.
#
# DELETE /largepersongroups/{largePersonGroupId}/persons/{personId}
# operationId: LargePersonGroupPerson_Delete
export def "large-person-group-person-delete" [
  large_person_group_id: string
  person_id: string
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
    path: "/largepersongroups/{largePersonGroupId}/persons/{personId}"
    path_params: [{name: largePersonGroupId, var: large_person_group_id}, {name: personId, var: person_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    large_person_group_id: $large_person_group_id, person_id: $person_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a person's name and userData, and the persisted faceIds representing the registered person face feature.
#
# GET /largepersongroups/{largePersonGroupId}/persons/{personId}
# Returns: record<persistedFaceIds: list<string>, personId: string, name: string, userData: string>
# operationId: LargePersonGroupPerson_Get
export def "large-person-group-person-get" [
  large_person_group_id: string
  person_id: string
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
    path: "/largepersongroups/{largePersonGroupId}/persons/{personId}"
    path_params: [{name: largePersonGroupId, var: large_person_group_id}, {name: personId, var: person_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    large_person_group_id: $large_person_group_id, person_id: $person_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update name or userData of a person.
#
# PATCH /largepersongroups/{largePersonGroupId}/persons/{personId}
# operationId: LargePersonGroupPerson_Update
export def "large-person-group-person-update" [
  large_person_group_id: string
  person_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # User defined name, maximum length is 128.
  --user-data: string # User specified data. Length should not exceed 16KB.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/largepersongroups/{largePersonGroupId}/persons/{personId}"
    path_params: [{name: largePersonGroupId, var: large_person_group_id}, {name: personId, var: person_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: userData, var: user_data}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    large_person_group_id: $large_person_group_id, person_id: $person_id, name: $name, user_data: $user_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a face to a person into a large person group for face identification or verification. To deal with an image contains multiple faces, input face can be specified as an image with a targetFace rectangle. It returns a persistedFaceId representing the added face. No image will be stored. Only the extracted face feature will be stored on server until [LargePersonGroup PersonFace - Delete](/docs/services/563879b61984550e40cbbe8d/operations/599ae2966ac60f11b48b5aa3), [LargePersonGroup Person - Delete](/docs/services/563879b61984550e40cbbe8d/operations/599ade5c6ac60f11b48b5aa2) or [LargePersonGroup - Delete](/docs/services/563879b61984550e40cbbe8d/operations/599adc216ac60f11b48b5a9f) is called. Note persistedFaceId is different from faceId generated by [Face - Detect](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236). * Higher face image quality means better recognition precision. Please consider high-quality faces: frontal, clear, and face size is 200x200 pixels (100 pixels between eyes) or bigger. * Each person entry can hold up to 248 faces. * JPEG, PNG, GIF (the first frame), and BMP format are supported. The allowed image file size is from 1KB to 6MB. * "targetFace" rectangle should contain one face. Zero or multiple faces will be regarded as an error. If the provided "targetFace" rectangle is not returned from [Face - Detect](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236), there’s no guarantee to detect and add the face successfully. * Out of detectable face size (36x36 - 4096x4096 pixels), large head-pose, or large occlusions will cause failures. * Adding/deleting faces to/from a same person will be processed sequentially. Adding/deleting faces to/from different persons are processed in parallel. * The minimum detectable face size is 36x36 pixels in an image no larger than 1920x1080 pixels. Images with dimensions higher than 1920x1080 pixels will need a proportionally larger minimum face size. * Different 'detectionModel' values can be provided. To use and compare different detection models, please refer to [How to specify a detection model](https://docs.microsoft.com/en-us/azure/cognitive-services/face/face-api-how-to-topics/specify-detection-model) | Model | Recommended use-case(s) | | ---------- | -------- | | 'detection_01': | The default detection model for [LargePersonGroup Person - Add Face](/docs/services/563879b61984550e40cbbe8d/operations/599adf2a3a7b9412a4d53f42). Recommend for near frontal face detection. For scenarios with exceptionally large angle (head-pose) faces, occluded faces or wrong image orientation, the faces in such cases may not be detected. | | 'detection_02': | Detection model released in 2019 May with improved accuracy especially on small, side and blurry faces. |
#
# POST /largepersongroups/{largePersonGroupId}/persons/{personId}/persistedfaces
# Returns: record<persistedFaceId: string, userData: string>
# operationId: LargePersonGroupPerson_AddFaceFromUrl
export def "large-person-group-person-add-face-from-url" [
  large_person_group_id: string
  person_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-data: string # User-specified data about the face for any purpose. The maximum length is 1KB.
  --target-face: list<int> # A face rectangle to specify the target face to be added to a person in the format of "targetFace=left,top,width,height". E.g. "targetFace=10,10,100,100". If there is more than one face in the image, targetFace is required to specify which face to add. No targetFace means there is only one face detected in the entire image.
  --detection-model: string@detection-model-completer # Name of detection model. Detection model is used to detect faces in the submitted image. A detection model name can be provided when performing Face - Detect or (Large)FaceList - Add Face or (Large)PersonGroup - Add Face. The default value is 'detection_01', if another model is needed, please explicitly specify it. (default: detection_01)
  url: string # Publicly reachable URL of an image
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/largepersongroups/{largePersonGroupId}/persons/{personId}/persistedfaces"
    path_params: [{name: largePersonGroupId, var: large_person_group_id}, {name: personId, var: person_id}]
    query: [{name: userData, var: user_data}, {name: targetFace, var: target_face, style: csv}, {name: detectionModel, var: detection_model}]
    body: {content_type: "application/json", kind: json, fields: [{name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    large_person_group_id: $large_person_group_id, person_id: $person_id, user_data: $user_data, target_face: $target_face, detection_model: $detection_model, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a face from a person in a large person group by specified largePersonGroupId, personId and persistedFaceId. Adding/deleting faces to/from a same person will be processed sequentially. Adding/deleting faces to/from different persons are processed in parallel.
#
# DELETE /largepersongroups/{largePersonGroupId}/persons/{personId}/persistedfaces/{persistedFaceId}
# operationId: LargePersonGroupPerson_DeleteFace
export def "large-person-group-person-delete-face" [
  large_person_group_id: string
  person_id: string
  persisted_face_id: string
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
    path: "/largepersongroups/{largePersonGroupId}/persons/{personId}/persistedfaces/{persistedFaceId}"
    path_params: [{name: largePersonGroupId, var: large_person_group_id}, {name: personId, var: person_id}, {name: persistedFaceId, var: persisted_face_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    large_person_group_id: $large_person_group_id, person_id: $person_id, persisted_face_id: $persisted_face_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve information about a persisted face (specified by persistedFaceId, personId and its belonging largePersonGroupId).
#
# GET /largepersongroups/{largePersonGroupId}/persons/{personId}/persistedfaces/{persistedFaceId}
# Returns: record<persistedFaceId: string, userData: string>
# operationId: LargePersonGroupPerson_GetFace
export def "large-person-group-person-get-face" [
  large_person_group_id: string
  person_id: string
  persisted_face_id: string
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
    path: "/largepersongroups/{largePersonGroupId}/persons/{personId}/persistedfaces/{persistedFaceId}"
    path_params: [{name: largePersonGroupId, var: large_person_group_id}, {name: personId, var: person_id}, {name: persistedFaceId, var: persisted_face_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    large_person_group_id: $large_person_group_id, person_id: $person_id, persisted_face_id: $persisted_face_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a person persisted face's userData field.
#
# PATCH /largepersongroups/{largePersonGroupId}/persons/{personId}/persistedfaces/{persistedFaceId}
# operationId: LargePersonGroupPerson_UpdateFace
export def "large-person-group-person-update-face" [
  large_person_group_id: string
  person_id: string
  persisted_face_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-data: string # User-provided data attached to the face. The size limit is 1KB.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/largepersongroups/{largePersonGroupId}/persons/{personId}/persistedfaces/{persistedFaceId}"
    path_params: [{name: largePersonGroupId, var: large_person_group_id}, {name: personId, var: person_id}, {name: persistedFaceId, var: persisted_face_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: userData, var: user_data}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    large_person_group_id: $large_person_group_id, person_id: $person_id, persisted_face_id: $persisted_face_id, user_data: $user_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Queue a large person group training task, the training task may not be started immediately.
#
# POST /largepersongroups/{largePersonGroupId}/train
# operationId: LargePersonGroup_Train
export def "large-person-group-train" [
  large_person_group_id: string
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
    path: "/largepersongroups/{largePersonGroupId}/train"
    path_params: [{name: largePersonGroupId, var: large_person_group_id}]
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    large_person_group_id: $large_person_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the training status of a large person group (completed or ongoing).
#
# GET /largepersongroups/{largePersonGroupId}/training
# Returns: record<createdDateTime: string, lastActionDateTime: string, lastSuccessfulTrainingDateTime: string, message: string, status: string>
# operationId: LargePersonGroup_GetTrainingStatus
export def "large-person-group-get-training-status" [
  large_person_group_id: string
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
    path: "/largepersongroups/{largePersonGroupId}/training"
    path_params: [{name: largePersonGroupId, var: large_person_group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    large_person_group_id: $large_person_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the status of a take/apply snapshot operation.
#
# GET /operations/{operationId}
# Returns: record<createdTime: string, lastActionTime: string, message: string, resourceLocation: string, status: string>
# operationId: Snapshot_GetOperationStatus
export def "snapshot-get-operation-status" [
  operation_id: string
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
    path: "/operations/{operationId}"
    path_params: [{name: operationId, var: operation_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    operation_id: $operation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List person groups’ personGroupId, name, userData and recognitionModel. * Person groups are stored in alphabetical order of personGroupId. * "start" parameter (string, optional) is a user-provided personGroupId value that returned entries have larger ids by string comparison. "start" set to empty to indicate return from the first item. * "top" parameter (int, optional) specifies the number of entries to return. A maximal of 1000 entries can be returned in one call. To fetch more, you can specify "start" with the last returned entry’s Id of the current call. For example, total 5 person groups: "group1", ..., "group5". "start=&top=" will return all 5 groups. "start=&top=2" will return "group1", "group2". "start=group2&top=3" will return "group3", "group4", "group5".
#
# GET /persongroups
# Returns: table<personGroupId: string, recognitionModel: string, name: string, userData: string>
# operationId: PersonGroup_List
export def "person-group-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # List person groups from the least personGroupId greater than the "start".
  --top: int # The number of person groups to list. (default: 1000)
  --return-recognition-model: oneof<nothing, bool> # A value indicating whether the operation should return 'recognitionModel' in response. (default: false)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/persongroups"
    query: [{name: start, var: start}, {name: top, var: top}, {name: returnRecognitionModel, var: return_recognition_model}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    start: $start, top: $top, return_recognition_model: $return_recognition_model
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing person group. Persisted face features of all people in the person group will also be deleted.
#
# DELETE /persongroups/{personGroupId}
# operationId: PersonGroup_Delete
export def "person-group-delete" [
  person_group_id: string
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
    path: "/persongroups/{personGroupId}"
    path_params: [{name: personGroupId, var: person_group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    person_group_id: $person_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve person group name, userData and recognitionModel. To get person information under this personGroup, use [PersonGroup Person - List](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395241).
#
# GET /persongroups/{personGroupId}
# Returns: record<personGroupId: string, recognitionModel: string, name: string, userData: string>
# operationId: PersonGroup_Get
export def "person-group-get" [
  person_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --return-recognition-model: oneof<nothing, bool> # A value indicating whether the operation should return 'recognitionModel' in response. (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/persongroups/{personGroupId}"
    path_params: [{name: personGroupId, var: person_group_id}]
    query: [{name: returnRecognitionModel, var: return_recognition_model}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    person_group_id: $person_group_id, return_recognition_model: $return_recognition_model
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing person group's display name and userData. The properties which does not appear in request body will not be updated.
#
# PATCH /persongroups/{personGroupId}
# operationId: PersonGroup_Update
export def "person-group-update" [
  person_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # User defined name, maximum length is 128.
  --user-data: string # User specified data. Length should not exceed 16KB.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/persongroups/{personGroupId}"
    path_params: [{name: personGroupId, var: person_group_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: userData, var: user_data}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    person_group_id: $person_group_id, name: $name, user_data: $user_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new person group with specified personGroupId, name, user-provided userData and recognitionModel. A person group is the container of the uploaded person data, including face recognition features. After creation, use [PersonGroup Person - Create](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039523c) to add persons into the group, and then call [PersonGroup - Train](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395249) to get this group ready for [Face - Identify](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395239). No image will be stored. Only the person's extracted face features and userData will be stored on server until [PersonGroup Person - Delete](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039523d) or [PersonGroup - Delete](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395245) is called. 'recognitionModel' should be specified to associate with this person group. The default value for 'recognitionModel' is 'recognition_01', if the latest model needed, please explicitly specify the model you need in this parameter. New faces that are added to an existing person group will use the recognition model that's already associated with the collection. Existing face features in a person group can't be updated to features extracted by another version of recognition model. * 'recognition_01': The default recognition model for [PersonGroup - Create](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395244). All those person groups created before 2019 March are bonded with this recognition model. * 'recognition_02': Recognition model released in 2019 March. 'recognition_02' is recommended since its overall accuracy is improved compared with 'recognition_01'. Person group quota: * Free-tier subscription quota: 1,000 person groups. Each holds up to 1,000 persons. * S0-tier subscription quota: 1,000,000 person groups. Each holds up to 10,000 persons. * to handle larger scale face identification problem, please consider using [LargePersonGroup](/docs/services/563879b61984550e40cbbe8d/operations/599acdee6ac60f11b48b5a9d).
#
# PUT /persongroups/{personGroupId}
# operationId: PersonGroup_Create
export def "person-group-create" [
  person_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --recognition-model: string@recognition-model-completer # Name of recognition model. Recognition model is used when the face features are extracted and associated with detected faceIds, (Large)FaceList or (Large)PersonGroup. A recognition model name can be provided when performing Face - Detect or (Large)FaceList - Create or (Large)PersonGroup - Create. The default value is 'recognition_01', if latest model needed, please explicitly specify the model you need. (default: recognition_01)
  --name: string # User defined name, maximum length is 128.
  --user-data: string # User specified data. Length should not exceed 16KB.
]: any -> any {
  $in | http-request {
    method: put
    path: "/persongroups/{personGroupId}"
    path_params: [{name: personGroupId, var: person_group_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: recognitionModel, var: recognition_model}, {name: name, var: name}, {name: userData, var: user_data}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    person_group_id: $person_group_id, recognition_model: $recognition_model, name: $name, user_data: $user_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all persons in a person group, and retrieve person information (including personId, name, userData and persistedFaceIds of registered faces of the person).
#
# GET /persongroups/{personGroupId}/persons
# Returns: table<persistedFaceIds: list<string>, personId: string, name: string, userData: string>
# operationId: PersonGroupPerson_List
export def "person-group-person-list" [
  person_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Starting person id to return (used to list a range of persons).
  --top: int # Number of persons to return starting with the person id indicated by the 'start' parameter.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/persongroups/{personGroupId}/persons"
    path_params: [{name: personGroupId, var: person_group_id}]
    query: [{name: start, var: start}, {name: top, var: top}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    person_group_id: $person_group_id, start: $start, top: $top
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new person in a specified person group.
#
# POST /persongroups/{personGroupId}/persons
# Returns: record<persistedFaceIds: list<string>, personId: string, name: string, userData: string>
# operationId: PersonGroupPerson_Create
export def "person-group-person-create" [
  person_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # User defined name, maximum length is 128.
  --user-data: string # User specified data. Length should not exceed 16KB.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/persongroups/{personGroupId}/persons"
    path_params: [{name: personGroupId, var: person_group_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: userData, var: user_data}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    person_group_id: $person_group_id, name: $name, user_data: $user_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing person from a person group. The persistedFaceId, userData, person name and face feature in the person entry will all be deleted.
#
# DELETE /persongroups/{personGroupId}/persons/{personId}
# operationId: PersonGroupPerson_Delete
export def "person-group-person-delete" [
  person_group_id: string
  person_id: string
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
    path: "/persongroups/{personGroupId}/persons/{personId}"
    path_params: [{name: personGroupId, var: person_group_id}, {name: personId, var: person_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    person_group_id: $person_group_id, person_id: $person_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a person's information, including registered persisted faces, name and userData.
#
# GET /persongroups/{personGroupId}/persons/{personId}
# Returns: record<persistedFaceIds: list<string>, personId: string, name: string, userData: string>
# operationId: PersonGroupPerson_Get
export def "person-group-person-get" [
  person_group_id: string
  person_id: string
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
    path: "/persongroups/{personGroupId}/persons/{personId}"
    path_params: [{name: personGroupId, var: person_group_id}, {name: personId, var: person_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    person_group_id: $person_group_id, person_id: $person_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update name or userData of a person.
#
# PATCH /persongroups/{personGroupId}/persons/{personId}
# operationId: PersonGroupPerson_Update
export def "person-group-person-update" [
  person_group_id: string
  person_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # User defined name, maximum length is 128.
  --user-data: string # User specified data. Length should not exceed 16KB.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/persongroups/{personGroupId}/persons/{personId}"
    path_params: [{name: personGroupId, var: person_group_id}, {name: personId, var: person_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: userData, var: user_data}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    person_group_id: $person_group_id, person_id: $person_id, name: $name, user_data: $user_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a face to a person into a person group for face identification or verification. To deal with an image contains multiple faces, input face can be specified as an image with a targetFace rectangle. It returns a persistedFaceId representing the added face. No image will be stored. Only the extracted face feature will be stored on server until [PersonGroup PersonFace - Delete](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039523e), [PersonGroup Person - Delete](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039523d) or [PersonGroup - Delete](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395245) is called. Note persistedFaceId is different from faceId generated by [Face - Detect](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236). * Higher face image quality means better recognition precision. Please consider high-quality faces: frontal, clear, and face size is 200x200 pixels (100 pixels between eyes) or bigger. * Each person entry can hold up to 248 faces. * JPEG, PNG, GIF (the first frame), and BMP format are supported. The allowed image file size is from 1KB to 6MB. * "targetFace" rectangle should contain one face. Zero or multiple faces will be regarded as an error. If the provided "targetFace" rectangle is not returned from [Face - Detect](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236), there’s no guarantee to detect and add the face successfully. * Out of detectable face size (36x36 - 4096x4096 pixels), large head-pose, or large occlusions will cause failures. * Adding/deleting faces to/from a same person will be processed sequentially. Adding/deleting faces to/from different persons are processed in parallel. * The minimum detectable face size is 36x36 pixels in an image no larger than 1920x1080 pixels. Images with dimensions higher than 1920x1080 pixels will need a proportionally larger minimum face size. * Different 'detectionModel' values can be provided. To use and compare different detection models, please refer to [How to specify a detection model](https://docs.microsoft.com/en-us/azure/cognitive-services/face/face-api-how-to-topics/specify-detection-model) | Model | Recommended use-case(s) | | ---------- | -------- | | 'detection_01': | The default detection model for [PersonGroup Person - Add Face](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039523b). Recommend for near frontal face detection. For scenarios with exceptionally large angle (head-pose) faces, occluded faces or wrong image orientation, the faces in such cases may not be detected. | | 'detection_02': | Detection model released in 2019 May with improved accuracy especially on small, side and blurry faces. |
#
# POST /persongroups/{personGroupId}/persons/{personId}/persistedfaces
# Returns: record<persistedFaceId: string, userData: string>
# operationId: PersonGroupPerson_AddFaceFromUrl
export def "person-group-person-add-face-from-url" [
  person_group_id: string
  person_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-data: string # User-specified data about the face for any purpose. The maximum length is 1KB.
  --target-face: list<int> # A face rectangle to specify the target face to be added to a person in the format of "targetFace=left,top,width,height". E.g. "targetFace=10,10,100,100". If there is more than one face in the image, targetFace is required to specify which face to add. No targetFace means there is only one face detected in the entire image.
  --detection-model: string@detection-model-completer # Name of detection model. Detection model is used to detect faces in the submitted image. A detection model name can be provided when performing Face - Detect or (Large)FaceList - Add Face or (Large)PersonGroup - Add Face. The default value is 'detection_01', if another model is needed, please explicitly specify it. (default: detection_01)
  url: string # Publicly reachable URL of an image
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/persongroups/{personGroupId}/persons/{personId}/persistedfaces"
    path_params: [{name: personGroupId, var: person_group_id}, {name: personId, var: person_id}]
    query: [{name: userData, var: user_data}, {name: targetFace, var: target_face, style: csv}, {name: detectionModel, var: detection_model}]
    body: {content_type: "application/json", kind: json, fields: [{name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    person_group_id: $person_group_id, person_id: $person_id, user_data: $user_data, target_face: $target_face, detection_model: $detection_model, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a face from a person in a person group by specified personGroupId, personId and persistedFaceId. Adding/deleting faces to/from a same person will be processed sequentially. Adding/deleting faces to/from different persons are processed in parallel.
#
# DELETE /persongroups/{personGroupId}/persons/{personId}/persistedfaces/{persistedFaceId}
# operationId: PersonGroupPerson_DeleteFace
export def "person-group-person-delete-face" [
  person_group_id: string
  person_id: string
  persisted_face_id: string
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
    path: "/persongroups/{personGroupId}/persons/{personId}/persistedfaces/{persistedFaceId}"
    path_params: [{name: personGroupId, var: person_group_id}, {name: personId, var: person_id}, {name: persistedFaceId, var: persisted_face_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    person_group_id: $person_group_id, person_id: $person_id, persisted_face_id: $persisted_face_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve information about a persisted face (specified by persistedFaceId, personId and its belonging personGroupId).
#
# GET /persongroups/{personGroupId}/persons/{personId}/persistedfaces/{persistedFaceId}
# Returns: record<persistedFaceId: string, userData: string>
# operationId: PersonGroupPerson_GetFace
export def "person-group-person-get-face" [
  person_group_id: string
  person_id: string
  persisted_face_id: string
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
    path: "/persongroups/{personGroupId}/persons/{personId}/persistedfaces/{persistedFaceId}"
    path_params: [{name: personGroupId, var: person_group_id}, {name: personId, var: person_id}, {name: persistedFaceId, var: persisted_face_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    person_group_id: $person_group_id, person_id: $person_id, persisted_face_id: $persisted_face_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a face to a person into a person group for face identification or verification. To deal with an image contains multiple faces, input face can be specified as an image with a targetFace rectangle. It returns a persistedFaceId representing the added face. No image will be stored. Only the extracted face feature will be stored on server until [PersonGroup PersonFace - Delete](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039523e), [PersonGroup Person - Delete](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039523d) or [PersonGroup - Delete](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395245) is called. Note persistedFaceId is different from faceId generated by [Face - Detect](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236). * Higher face image quality means better recognition precision. Please consider high-quality faces: frontal, clear, and face size is 200x200 pixels (100 pixels between eyes) or bigger. * Each person entry can hold up to 248 faces. * JPEG, PNG, GIF (the first frame), and BMP format are supported. The allowed image file size is from 1KB to 6MB. * "targetFace" rectangle should contain one face. Zero or multiple faces will be regarded as an error. If the provided "targetFace" rectangle is not returned from [Face - Detect](/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236), there’s no guarantee to detect and add the face successfully. * Out of detectable face size (36x36 - 4096x4096 pixels), large head-pose, or large occlusions will cause failures. * Adding/deleting faces to/from a same person will be processed sequentially. Adding/deleting faces to/from different persons are processed in parallel.
#
# PATCH /persongroups/{personGroupId}/persons/{personId}/persistedfaces/{persistedFaceId}
# operationId: PersonGroupPerson_UpdateFace
export def "person-group-person-update-face" [
  person_group_id: string
  person_id: string
  persisted_face_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-data: string # User-provided data attached to the face. The size limit is 1KB.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/persongroups/{personGroupId}/persons/{personId}/persistedfaces/{persistedFaceId}"
    path_params: [{name: personGroupId, var: person_group_id}, {name: personId, var: person_id}, {name: persistedFaceId, var: persisted_face_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: userData, var: user_data}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    person_group_id: $person_group_id, person_id: $person_id, persisted_face_id: $persisted_face_id, user_data: $user_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Queue a person group training task, the training task may not be started immediately.
#
# POST /persongroups/{personGroupId}/train
# operationId: PersonGroup_Train
export def "person-group-train" [
  person_group_id: string
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
    path: "/persongroups/{personGroupId}/train"
    path_params: [{name: personGroupId, var: person_group_id}]
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    person_group_id: $person_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the training status of a person group (completed or ongoing).
#
# GET /persongroups/{personGroupId}/training
# Returns: record<createdDateTime: string, lastActionDateTime: string, lastSuccessfulTrainingDateTime: string, message: string, status: string>
# operationId: PersonGroup_GetTrainingStatus
export def "person-group-get-training-status" [
  person_group_id: string
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
    path: "/persongroups/{personGroupId}/training"
    path_params: [{name: personGroupId, var: person_group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    person_group_id: $person_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all accessible snapshots with related information, including snapshots that were taken by the user, or snapshots to be applied to the user (subscription id was included in the applyScope in Snapshot - Take).
#
# GET /snapshots
# Returns: table<account: string, applyScope: list<string>, createdTime: string, id: string, lastUpdateTime: string, type: string, userData: string>
# operationId: Snapshot_List
export def "snapshot-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer # User specified object type as a search filter.
  --apply-scope: list<string> # User specified snapshot apply scopes as a search filter. ApplyScope is an array of the target Azure subscription ids for the snapshot, specified by the user who created the snapshot by Snapshot - Take.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/snapshots"
    query: [{name: type, var: type}, {name: applyScope, var: apply_scope, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    type: $type, apply_scope: $apply_scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit an operation to take a snapshot of face list, large face list, person group or large person group, with user-specified snapshot type, source object id, apply scope and an optional user data. The snapshot interfaces are for users to backup and restore their face data from one face subscription to another, inside same region or across regions. The workflow contains two phases, user first calls Snapshot - Take to create a copy of the source object and store it as a snapshot, then calls Snapshot - Apply to paste the snapshot to target subscription. The snapshots are stored in a centralized location (per Azure instance), so that they can be applied cross accounts and regions. Taking snapshot is an asynchronous operation. An operation id can be obtained from the "Operation-Location" field in response header, to be used in OperationStatus - Get for tracking the progress of creating the snapshot. The snapshot id will be included in the "resourceLocation" field in OperationStatus - Get response when the operation status is "succeeded". Snapshot taking time depends on the number of person and face entries in the source object. It could be in seconds, or up to several hours for 1,000,000 persons with multiple faces. Snapshots will be automatically expired and cleaned in 48 hours after it is created by Snapshot - Take. User can delete the snapshot using Snapshot - Delete by themselves any time before expiration. Taking snapshot for a certain object will not block any other operations against the object. All read-only operations (Get/List and Identify/FindSimilar/Verify) can be conducted as usual. For all writable operations, including Add/Update/Delete the source object or its persons/faces and Train, they are not blocked but not recommended because writable updates may not be reflected on the snapshot during its taking. After snapshot taking is completed, all readable and writable operations can work as normal. Snapshot will also include the training results of the source object, which means target subscription the snapshot applied to does not need re-train the target object before calling Identify/FindSimilar. * Free-tier subscription quota: 100 take operations per month. * S0-tier subscription quota: 100 take operations per day.
#
# POST /snapshots
# operationId: Snapshot_Take
export def "snapshot-take" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  apply_scope: list<string> # Array of the target Face subscription ids for the snapshot, specified by the user who created the snapshot when calling Snapshot - Take. For each snapshot, only subscriptions included in the applyScope of Snapshot - Take can apply it.
  object_id: string # User specified source object id to take snapshot from.
  type: string@type-completer # User specified type for the source object to take snapshot from. Currently FaceList, PersonGroup, LargeFaceList and LargePersonGroup are supported.
  --user-data: string # User specified data about the snapshot for any purpose. Length should not exceed 16KB.
]: any -> any {
  $in | http-request {
    method: post
    path: "/snapshots"
    body: {content_type: "application/json", kind: json, fields: [{name: applyScope, var: apply_scope}, {name: objectId, var: object_id}, {name: type, var: type}, {name: userData, var: user_data}]}
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    apply_scope: $apply_scope, object_id: $object_id, type: $type, user_data: $user_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing snapshot according to the snapshotId. All object data and information in the snapshot will also be deleted. Only the source subscription who took the snapshot can delete the snapshot. If the user does not delete a snapshot with this API, the snapshot will still be automatically deleted in 48 hours after creation.
#
# DELETE /snapshots/{snapshotId}
# operationId: Snapshot_Delete
export def "snapshot-delete" [
  snapshot_id: string
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
    path: "/snapshots/{snapshotId}"
    path_params: [{name: snapshotId, var: snapshot_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    snapshot_id: $snapshot_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve information about a snapshot. Snapshot is only accessible to the source subscription who took it, and target subscriptions included in the applyScope in Snapshot - Take.
#
# GET /snapshots/{snapshotId}
# Returns: record<account: string, applyScope: list<string>, createdTime: string, id: string, lastUpdateTime: string, type: string, userData: string>
# operationId: Snapshot_Get
export def "snapshot-get" [
  snapshot_id: string
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
    path: "/snapshots/{snapshotId}"
    path_params: [{name: snapshotId, var: snapshot_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    snapshot_id: $snapshot_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the information of a snapshot. Only the source subscription who took the snapshot can update the snapshot.
#
# PATCH /snapshots/{snapshotId}
# operationId: Snapshot_Update
export def "snapshot-update" [
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --apply-scope: list<string> # Array of the target Face subscription ids for the snapshot, specified by the user who created the snapshot when calling Snapshot - Take. For each snapshot, only subscriptions included in the applyScope of Snapshot - Take can apply it.
  --user-data: string # User specified data about the snapshot for any purpose. Length should not exceed 16KB.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/snapshots/{snapshotId}"
    path_params: [{name: snapshotId, var: snapshot_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: applyScope, var: apply_scope}, {name: userData, var: user_data}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    snapshot_id: $snapshot_id, apply_scope: $apply_scope, user_data: $user_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit an operation to apply a snapshot to current subscription. For each snapshot, only subscriptions included in the applyScope of Snapshot - Take can apply it. The snapshot interfaces are for users to backup and restore their face data from one face subscription to another, inside same region or across regions. The workflow contains two phases, user first calls Snapshot - Take to create a copy of the source object and store it as a snapshot, then calls Snapshot - Apply to paste the snapshot to target subscription. The snapshots are stored in a centralized location (per Azure instance), so that they can be applied cross accounts and regions. Applying snapshot is an asynchronous operation. An operation id can be obtained from the "Operation-Location" field in response header, to be used in OperationStatus - Get for tracking the progress of applying the snapshot. The target object id will be included in the "resourceLocation" field in OperationStatus - Get response when the operation status is "succeeded". Snapshot applying time depends on the number of person and face entries in the snapshot object. It could be in seconds, or up to 1 hour for 1,000,000 persons with multiple faces. Snapshots will be automatically expired and cleaned in 48 hours after it is created by Snapshot - Take. So the target subscription is required to apply the snapshot in 48 hours since its creation. Applying a snapshot will not block any other operations against the target object, however it is not recommended because the correctness cannot be guaranteed during snapshot applying. After snapshot applying is completed, all operations towards the target object can work as normal. Snapshot also includes the training results of the source object, which means target subscription the snapshot applied to does not need re-train the target object before calling Identify/FindSimilar. One snapshot can be applied multiple times in parallel, while currently only CreateNew apply mode is supported, which means the apply operation will fail if target subscription already contains an object of same type and using the same objectId. Users can specify the "objectId" in request body to avoid such conflicts. * Free-tier subscription quota: 100 apply operations per month. * S0-tier subscription quota: 100 apply operations per day.
#
# POST /snapshots/{snapshotId}/apply
# operationId: Snapshot_Apply
export def "snapshot-apply" [
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mode: string@mode-completer-1 # Snapshot applying mode. Currently only CreateNew is supported, which means the apply operation will fail if target subscription already contains an object of same type and using the same objectId. Users can specify the "objectId" in request body to avoid such conflicts. (default: CreateNew)
  object_id: string # User specified target object id to be created from the snapshot.
]: any -> any {
  $in | http-request {
    method: post
    path: "/snapshots/{snapshotId}/apply"
    path_params: [{name: snapshotId, var: snapshot_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: mode, var: mode}, {name: objectId, var: object_id}]}
    accept: ["application/json"]
    ok: [202]
    auth: ocp-apim-subscription-key
  } {
    snapshot_id: $snapshot_id, mode: $mode, object_id: $object_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify whether two faces belong to a same person or whether one face belongs to a person. Remarks: * Higher face image quality means better identification precision. Please consider high-quality faces: frontal, clear, and face size is 200x200 pixels (100 pixels between eyes) or bigger. * For the scenarios that are sensitive to accuracy please make your own judgment. * The 'recognitionModel' associated with the query faces' faceIds should be the same as the 'recognitionModel' used by the target face, person group or large person group.
#
# POST /verify
# Returns: record<confidence: float, isIdentical: bool>
# operationId: Face_VerifyFaceToFace
export def "face-verify-face-to-face" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  face_id1: string # FaceId of the first face, comes from Face - Detect (format: uuid)
  face_id2: string # FaceId of the second face, comes from Face - Detect (format: uuid)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/verify"
    body: {content_type: "application/json", kind: json, fields: [{name: faceId1, var: face_id1}, {name: faceId2, var: face_id2}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    face_id1: $face_id1, face_id2: $face_id2
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
