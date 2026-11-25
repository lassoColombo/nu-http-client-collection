# Auto-generated client for Custom Vision Training Client v3.2
# Source: https://api.apis.guru/v2/specs/microsoft.com/cognitiveservices-Training/3.2/openapi.json
# Auth: --token flag or $env.CUSTOM_VISION_TRAINING_CLIENT_TOKEN

const CLIENT = {
  base_url: "https://southcentralus.api.cognitive.microsoft.com/customvision/v3.2/training"
  token_env_var: "CUSTOM_VISION_TRAINING_CLIENT_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: training-key, in: header, header_name: Training-Key, prefix: ""}
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

def base-url-completer [] { ["https://southcentralus.api.cognitive.microsoft.com/customvision/v3.2/training" "none/customvision/v3.2/training"] }
def auth-scheme-completer [] { ["training-key"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/xml"] }
def classification-type-completer [] { ["Multiclass" "Multilabel"] }
def status-completer [] { ["Failed" "Importing" "Succeeded"] }
def sort-by-completer [] { ["UncertaintyAscending" "UncertaintyDescending"] }
def order-by-completer [] { ["Newest" "Oldest"] }
def platform-completer [] { ["CoreML" "DockerFile" "ONNX" "TensorFlow" "VAIDK"] }
def flavor-completer [] { ["ARM" "Linux" "ONNX10" "ONNX12" "TensorFlowLite" "TensorFlowNormal" "Windows"] }
def order-by-completer-1 [] { ["Newest" "Oldest" "Suggested"] }
def type-completer [] { ["Negative" "Regular"] }
def training-type-completer [] { ["Advanced" "Regular"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-domains: "table<enabled: bool, exportable: bool, id: string, name: string, type: string>"
    get-domain: "record<enabled: bool, exportable: bool, id: string, name: string, type: string>"
    get-projects: "table<created: string, description: string, drModeEnabled: bool, id: string, lastModified: string, name: string, settings: record<classificationType: string, detectionParameters: string, domainId: string, imageProcessingSettings: record, targetExportPlatforms: list, useNegativeSet: bool>, status: string, thumbnailUri: string>"
    create-project: "record<created: string, description: string, drModeEnabled: bool, id: string, lastModified: string, name: string, settings: record<classificationType: string, detectionParameters: string, domainId: string, imageProcessingSettings: record<augmentationMethods: record>, targetExportPlatforms: list<string>, useNegativeSet: bool>, status: string, thumbnailUri: string>"
    import-project: "record<created: string, description: string, drModeEnabled: bool, id: string, lastModified: string, name: string, settings: record<classificationType: string, detectionParameters: string, domainId: string, imageProcessingSettings: record<augmentationMethods: record>, targetExportPlatforms: list<string>, useNegativeSet: bool>, status: string, thumbnailUri: string>"
    get-project: "record<created: string, description: string, drModeEnabled: bool, id: string, lastModified: string, name: string, settings: record<classificationType: string, detectionParameters: string, domainId: string, imageProcessingSettings: record<augmentationMethods: record>, targetExportPlatforms: list<string>, useNegativeSet: bool>, status: string, thumbnailUri: string>"
    update-project: "record<created: string, description: string, drModeEnabled: bool, id: string, lastModified: string, name: string, settings: record<classificationType: string, detectionParameters: string, domainId: string, imageProcessingSettings: record<augmentationMethods: record>, targetExportPlatforms: list<string>, useNegativeSet: bool>, status: string, thumbnailUri: string>"
    export-project: "record<estimatedImportTimeInMS: int, imageCount: int, iterationCount: int, regionCount: int, tagCount: int, token: string>"
    create-images-from-data: "record<images: table<image: record, sourceUrl: string, status: string>, isBatchSuccessful: bool>"
    create-images-from-files: "record<images: table<image: record, sourceUrl: string, status: string>, isBatchSuccessful: bool>"
    get-images-by-ids: "table<created: string, height: int, id: string, originalImageUri: string, regions: list<record>, resizedImageUri: string, tags: list<record>, thumbnailUri: string, width: int>"
    create-images-from-predictions: "record<images: table<image: record, sourceUrl: string, status: string>, isBatchSuccessful: bool>"
    create-image-regions: "record<created: table<created: string, height: float, imageId: string, left: float, regionId: string, tagId: string, tagName: string, top: float, width: float>, duplicated: table<height: float, imageId: string, left: float, tagId: string, top: float, width: float>, exceeded: table<height: float, imageId: string, left: float, tagId: string, top: float, width: float>>"
    query-suggested-images: "record<results: table<created: string, domain: string, height: int, id: string, iteration: string, originalImageUri: string, predictionUncertainty: float, predictions: list, project: string, resizedImageUri: string, thumbnailUri: string, width: int>, token: record<continuation: string, maxCount: int, session: string, sortBy: string, tagIds: list<string>, threshold: float>>"
    query-suggested-image-count: "record"
    get-tagged-images: "table<created: string, height: int, id: string, originalImageUri: string, regions: list<record>, resizedImageUri: string, tags: list<record>, thumbnailUri: string, width: int>"
    get-tagged-image-count: "int"
    create-image-tags: "record<created: table<imageId: string, tagId: string>, duplicated: table<imageId: string, tagId: string>, exceeded: table<imageId: string, tagId: string>>"
    get-untagged-images: "table<created: string, height: int, id: string, originalImageUri: string, regions: list<record>, resizedImageUri: string, tags: list<record>, thumbnailUri: string, width: int>"
    get-untagged-image-count: "int"
    create-images-from-urls: "record<images: table<image: record, sourceUrl: string, status: string>, isBatchSuccessful: bool>"
    get-image-region-proposals: "record<imageId: string, projectId: string, proposals: table<boundingBox: record, confidence: float>>"
    get-iterations: "table<classificationType: string, created: string, domainId: string, exportable: bool, exportableTo: list<string>, id: string, lastModified: string, name: string, originalPublishResourceId: string, projectId: string, publishName: string, reservedBudgetInHours: int, status: string, trainedAt: string, trainingTimeInMinutes: int, trainingType: string>"
    get-iteration: "record<classificationType: string, created: string, domainId: string, exportable: bool, exportableTo: list<string>, id: string, lastModified: string, name: string, originalPublishResourceId: string, projectId: string, publishName: string, reservedBudgetInHours: int, status: string, trainedAt: string, trainingTimeInMinutes: int, trainingType: string>"
    update-iteration: "record<classificationType: string, created: string, domainId: string, exportable: bool, exportableTo: list<string>, id: string, lastModified: string, name: string, originalPublishResourceId: string, projectId: string, publishName: string, reservedBudgetInHours: int, status: string, trainedAt: string, trainingTimeInMinutes: int, trainingType: string>"
    get-exports: "table<downloadUri: string, flavor: string, newerVersionAvailable: bool, platform: string, status: string>"
    export-iteration: "record<downloadUri: string, flavor: string, newerVersionAvailable: bool, platform: string, status: string>"
    get-iteration-performance: "record<averagePrecision: float, perTagPerformance: table<averagePrecision: float, id: string, name: string, precision: float, precisionStdDeviation: float, recall: float, recallStdDeviation: float>, precision: float, precisionStdDeviation: float, recall: float, recallStdDeviation: float>"
    get-image-performances: "table<created: string, height: int, id: string, imageUri: string, predictions: list<record>, regions: list<record>, tags: list<record>, thumbnailUri: string, width: int>"
    get-image-performance-count: "int"
    publish-iteration: "bool"
    query-predictions: "record<results: table<created: string, domain: string, id: string, iteration: string, originalImageUri: string, predictions: list, project: string, resizedImageUri: string, thumbnailUri: string>, token: record<application: string, continuation: string, endTime: string, iterationId: string, maxCount: int, orderBy: string, session: string, startTime: string, tags: list<record>>>"
    quick-test-image: "record<created: string, id: string, iteration: string, predictions: table<boundingBox: record, probability: float, tagId: string, tagName: string>, project: string>"
    quick-test-image-url: "record<created: string, id: string, iteration: string, predictions: table<boundingBox: record, probability: float, tagId: string, tagName: string>, project: string>"
    get-tags: "table<description: string, id: string, imageCount: int, name: string, type: string>"
    create-tag: "record<description: string, id: string, imageCount: int, name: string, type: string>"
    get-tag: "record<description: string, id: string, imageCount: int, name: string, type: string>"
    update-tag: "record<description: string, id: string, imageCount: int, name: string, type: string>"
    suggest-tags-and-regions: "table<created: string, id: string, iteration: string, predictionUncertainty: float, predictions: list<record>, project: string>"
    train-project: "record<classificationType: string, created: string, domainId: string, exportable: bool, exportableTo: list<string>, id: string, lastModified: string, name: string, originalPublishResourceId: string, projectId: string, publishName: string, reservedBudgetInHours: int, status: string, trainedAt: string, trainingTimeInMinutes: int, trainingType: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-domains" "get-domain" "get-projects" "create-project" "import-project" "delete-project" "get-project" "update-project" "export-project" "delete-images" "create-images-from-data" "create-images-from-files" "get-images-by-ids" "create-images-from-predictions" "delete-image-regions" "create-image-regions" "query-suggested-images" "query-suggested-image-count" "get-tagged-images" "get-tagged-image-count" "delete-image-tags" "create-image-tags" "get-untagged-images" "get-untagged-image-count" "create-images-from-urls" "get-image-region-proposals" "get-iterations" "delete-iteration" "get-iteration" "update-iteration" "get-exports" "export-iteration" "get-iteration-performance" "get-image-performances" "get-image-performance-count" "unpublish-iteration" "publish-iteration" "delete-prediction" "query-predictions" "quick-test-image" "quick-test-image-url" "get-tags" "create-tag" "delete-tag" "get-tag" "update-tag" "suggest-tags-and-regions" "train-project" "commands"] | sort) } | get name | first)
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

# Get a list of the available domains.
#
# GET /domains
# Returns: table<enabled: bool, exportable: bool, id: string, name: string, type: string>
# operationId: GetDomains
export def "get-domains" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/domains"
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get information about a specific domain.
#
# GET /domains/{domainId}
# Returns: record<enabled: bool, exportable: bool, id: string, name: string, type: string>
# operationId: GetDomain
export def "get-domain" [
  domain_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/domains/{domainId}"
    path_params: [{name: domainId, var: domain_id}]
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    domain_id: $domain_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get your projects.
#
# GET /projects
# Returns: table<created: string, description: string, drModeEnabled: bool, id: string, lastModified: string, name: string, settings: record<classificationType: string, detectionParameters: string, domainId: string, imageProcessingSettings: record, targetExportPlatforms: list, useNegativeSet: bool>, status: string, thumbnailUri: string>
# operationId: GetProjects
export def "get-projects" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/projects"
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a project.
#
# POST /projects
# Returns: record<created: string, description: string, drModeEnabled: bool, id: string, lastModified: string, name: string, settings: record<classificationType: string, detectionParameters: string, domainId: string, imageProcessingSettings: record<augmentationMethods: record>, targetExportPlatforms: list<string>, useNegativeSet: bool>, status: string, thumbnailUri: string>
# operationId: CreateProject
export def "create-project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # Name of the project. (required)
  --description: string # The description of the project.
  --domain-id: string # The id of the domain to use for this project. Defaults to General. (format: uuid)
  --classification-type: string@classification-type-completer # The type of classifier to create for this project.
  --target-export-platforms: list<string> # List of platforms the trained model is intending exporting to.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/projects"
    query: [{name: name, var: name, required: true}, {name: description, var: description}, {name: domainId, var: domain_id}, {name: classificationType, var: classification_type}, {name: targetExportPlatforms, var: target_export_platforms, style: csv}]
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    name: $name, description: $description, domain_id: $domain_id, classification_type: $classification_type, target_export_platforms: $target_export_platforms
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Imports a project.
#
# POST /projects/import
# Returns: record<created: string, description: string, drModeEnabled: bool, id: string, lastModified: string, name: string, settings: record<classificationType: string, detectionParameters: string, domainId: string, imageProcessingSettings: record<augmentationMethods: record>, targetExportPlatforms: list<string>, useNegativeSet: bool>, status: string, thumbnailUri: string>
# operationId: ImportProject
export def "import-project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-token: string # Token generated from the export project call. (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/projects/import"
    query: [{name: token, var: qp_token, required: true}]
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a specific project.
#
# DELETE /projects/{projectId}
# operationId: DeleteProject
export def "delete-project" [
  project_id: string
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
    path: "/projects/{projectId}"
    path_params: [{name: projectId, var: project_id}]
    accept: ["*/*"]
    ok: [204]
    auth: training-key
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific project.
#
# GET /projects/{projectId}
# Returns: record<created: string, description: string, drModeEnabled: bool, id: string, lastModified: string, name: string, settings: record<classificationType: string, detectionParameters: string, domainId: string, imageProcessingSettings: record<augmentationMethods: record>, targetExportPlatforms: list<string>, useNegativeSet: bool>, status: string, thumbnailUri: string>
# operationId: GetProject
export def "get-project" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/projects/{projectId}"
    path_params: [{name: projectId, var: project_id}]
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a specific project.
#
# PATCH /projects/{projectId}
# Returns: record<created: string, description: string, drModeEnabled: bool, id: string, lastModified: string, name: string, settings: record<classificationType: string, detectionParameters: string, domainId: string, imageProcessingSettings: record<augmentationMethods: record>, targetExportPlatforms: list<string>, useNegativeSet: bool>, status: string, thumbnailUri: string>
# operationId: UpdateProject
export def "update-project" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # Gets or sets the description of the project. (nullable)
  name: string # Gets or sets the name of the project.
  settings: record # Represents settings associated with a project. — shape: {classificationType?: "Multiclass"|"Multilabel", domainId?: string, imageProcessingSettings?: record, targetExportPlatforms?: list<string>}
  --status: string@status-completer # Gets the status of the project.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/projects/{projectId}"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: settings, var: settings}, {name: status, var: status}]}
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id, description: $description, name: $name, settings: $settings, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Exports a project.
#
# GET /projects/{projectId}/export
# Returns: record<estimatedImportTimeInMS: int, imageCount: int, iterationCount: int, regionCount: int, tagCount: int, token: string>
# operationId: ExportProject
export def "export-project" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/projects/{projectId}/export"
    path_params: [{name: projectId, var: project_id}]
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete images from the set of training images.
#
# DELETE /projects/{projectId}/images
# operationId: DeleteImages
export def "delete-images" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --image-ids: list<string> # Ids of the images to be deleted. Limited to 256 images per batch.
  --all-images: oneof<nothing, bool> # Flag to specify delete all images, specify this flag or a list of images. Using this flag will return a 202 response to indicate the images are being deleted.
  --all-iterations: oneof<nothing, bool> # Removes these images from all iterations, not just the current workspace. Using this flag will return a 202 response to indicate the images are being deleted.
]: nothing -> any {
  http-request {
    method: delete
    path: "/projects/{projectId}/images"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: imageIds, var: image_ids, style: csv}, {name: allImages, var: all_images}, {name: allIterations, var: all_iterations}]
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [202, 204]
    auth: training-key
  } {
    project_id: $project_id, image_ids: $image_ids, all_images: $all_images, all_iterations: $all_iterations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add the provided images to the set of training images.
#
# POST /projects/{projectId}/images
# Returns: record<images: table<image: record, sourceUrl: string, status: string>, isBatchSuccessful: bool>
# operationId: CreateImagesFromData
export def "create-images-from-data" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --tag-ids: list<string> # The tags ids with which to tag each image. Limited to 20.
  image_data: string # Binary image data. Supported formats are JPEG, GIF, PNG, and BMP. Supports images up to 6MB. (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectId}/images"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: tagIds, var: tag_ids, style: csv}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: imageData, var: image_data}], files: [imageData]}
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id, tag_ids: $tag_ids, image_data: $image_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add the provided batch of images to the set of training images.
#
# POST /projects/{projectId}/images/files
# Returns: record<images: table<image: record, sourceUrl: string, status: string>, isBatchSuccessful: bool>
# operationId: CreateImagesFromFiles
export def "create-images-from-files" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --images: list # item shape: {contents?: string, name?: string, regions?: list, tagIds?: list<string>}
  --tag-ids: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectId}/images/files"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: images, var: images}, {name: tagIds, var: tag_ids}]}
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id, images: $images, tag_ids: $tag_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get images by id for a given project iteration.
#
# GET /projects/{projectId}/images/id
# Returns: table<created: string, height: int, id: string, originalImageUri: string, regions: list<record>, resizedImageUri: string, tags: list<record>, thumbnailUri: string, width: int>
# operationId: GetImagesByIds
export def "get-images-by-ids" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --image-ids: list<string> # The list of image ids to retrieve. Limited to 256.
  --iteration-id: string # The iteration id. Defaults to workspace. (format: uuid)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/images/id"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: imageIds, var: image_ids, style: csv}, {name: iterationId, var: iteration_id}]
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id, image_ids: $image_ids, iteration_id: $iteration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add the specified predicted images to the set of training images.
#
# POST /projects/{projectId}/images/predictions
# Returns: record<images: table<image: record, sourceUrl: string, status: string>, isBatchSuccessful: bool>
# operationId: CreateImagesFromPredictions
export def "create-images-from-predictions" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --images: list # item shape: {id?: string, regions?: list, tagIds?: list<string>}
  --tag-ids: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectId}/images/predictions"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: images, var: images}, {name: tagIds, var: tag_ids}]}
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id, images: $images, tag_ids: $tag_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a set of image regions.
#
# DELETE /projects/{projectId}/images/regions
# operationId: DeleteImageRegions
export def "delete-image-regions" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --region-ids: list<string> # Regions to delete. Limited to 64. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/projects/{projectId}/images/regions"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: regionIds, var: region_ids, style: csv, required: true}]
    accept: ["*/*"]
    ok: [204]
    auth: training-key
  } {
    project_id: $project_id, region_ids: $region_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a set of image regions.
#
# POST /projects/{projectId}/images/regions
# Returns: record<created: table<created: string, height: float, imageId: string, left: float, regionId: string, tagId: string, tagName: string, top: float, width: float>, duplicated: table<height: float, imageId: string, left: float, tagId: string, top: float, width: float>, exceeded: table<height: float, imageId: string, left: float, tagId: string, top: float, width: float>>
# operationId: CreateImageRegions
export def "create-image-regions" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --regions: list # item shape: {height: float, imageId: string, left: float, tagId: string, top: float, width: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectId}/images/regions"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: regions, var: regions}]}
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id, regions: $regions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get untagged images whose suggested tags match given tags. Returns empty array if no images are found.
#
# POST /projects/{projectId}/images/suggested
# Returns: record<results: table<created: string, domain: string, height: int, id: string, iteration: string, originalImageUri: string, predictionUncertainty: float, predictions: list, project: string, resizedImageUri: string, thumbnailUri: string, width: int>, token: record<continuation: string, maxCount: int, session: string, sortBy: string, tagIds: list<string>, threshold: float>>
# operationId: QuerySuggestedImages
export def "query-suggested-images" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --iteration-id: string # IterationId to use for the suggested tags and regions. (required, format: uuid)
  --continuation: string # Continuation Id for database pagination. Initially null but later used to paginate.
  --max-count: int # Maximum number of results you want to be returned in the response. (format: int32)
  --session: string # SessionId for database query. Initially set to null but later used to paginate.
  --sort-by: string@sort-by-completer # OrderBy. Ordering mechanism for your results.
  --tag-ids: list<string> # Existing TagIds in project to filter suggested tags on.
  --threshold: float # Confidence threshold to filter suggested tags on. (format: double)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectId}/images/suggested"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: iterationId, var: iteration_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: continuation, var: continuation}, {name: maxCount, var: max_count}, {name: session, var: session}, {name: sortBy, var: sort_by}, {name: tagIds, var: tag_ids}, {name: threshold, var: threshold}]}
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id, iteration_id: $iteration_id, continuation: $continuation, max_count: $max_count, session: $session, sort_by: $sort_by, tag_ids: $tag_ids, threshold: $threshold
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get count of images whose suggested tags match given tags and their probabilities are greater than or equal to the given threshold. Returns count as 0 if none found.
#
# POST /projects/{projectId}/images/suggested/count
# Returns: record
# operationId: QuerySuggestedImageCount
export def "query-suggested-image-count" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --iteration-id: string # IterationId to use for the suggested tags and regions. (required, format: uuid)
  --tag-ids: list<string> # Existing TagIds in project to get suggested tags count for.
  --threshold: float # Confidence threshold to filter suggested tags on. (format: double)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectId}/images/suggested/count"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: iterationId, var: iteration_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: tagIds, var: tag_ids}, {name: threshold, var: threshold}]}
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id, iteration_id: $iteration_id, tag_ids: $tag_ids, threshold: $threshold
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get tagged images for a given project iteration.
#
# GET /projects/{projectId}/images/tagged
# Returns: table<created: string, height: int, id: string, originalImageUri: string, regions: list<record>, resizedImageUri: string, tags: list<record>, thumbnailUri: string, width: int>
# operationId: GetTaggedImages
export def "get-tagged-images" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --iteration-id: string # The iteration id. Defaults to workspace. (format: uuid)
  --tag-ids: list<string> # A list of tags ids to filter the images. Defaults to all tagged images when null. Limited to 20.
  --order-by: string@order-by-completer # The ordering. Defaults to newest.
  --take: int # Maximum number of images to return. Defaults to 50, limited to 256. (format: int32, default: 50)
  --skip: int # Number of images to skip before beginning the image batch. Defaults to 0. (format: int32, default: 0)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/images/tagged"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: iterationId, var: iteration_id}, {name: tagIds, var: tag_ids, style: csv}, {name: orderBy, var: order_by}, {name: take, var: take}, {name: skip, var: skip}]
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id, iteration_id: $iteration_id, tag_ids: $tag_ids, order_by: $order_by, take: $take, skip: $skip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the number of images tagged with the provided {tagIds}.
#
# GET /projects/{projectId}/images/tagged/count
# Returns: int
# operationId: GetTaggedImageCount
export def "get-tagged-image-count" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --iteration-id: string # The iteration id. Defaults to workspace. (format: uuid)
  --tag-ids: list<string> # A list of tags ids to filter the images to count. Defaults to all tags when null.
]: nothing -> any {
  http-request {
    method: get
    path: "/projects/{projectId}/images/tagged/count"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: iterationId, var: iteration_id}, {name: tagIds, var: tag_ids, style: csv}]
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id, iteration_id: $iteration_id, tag_ids: $tag_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove a set of tags from a set of images.
#
# DELETE /projects/{projectId}/images/tags
# operationId: DeleteImageTags
export def "delete-image-tags" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --image-ids: list<string> # Image ids. Limited to 64 images. (required)
  --tag-ids: list<string> # Tags to be deleted from the specified images. Limited to 20 tags. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/projects/{projectId}/images/tags"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: imageIds, var: image_ids, style: csv, required: true}, {name: tagIds, var: tag_ids, style: csv, required: true}]
    accept: ["*/*"]
    ok: [204]
    auth: training-key
  } {
    project_id: $project_id, image_ids: $image_ids, tag_ids: $tag_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associate a set of images with a set of tags.
#
# POST /projects/{projectId}/images/tags
# Returns: record<created: table<imageId: string, tagId: string>, duplicated: table<imageId: string, tagId: string>, exceeded: table<imageId: string, tagId: string>>
# operationId: CreateImageTags
export def "create-image-tags" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --tags: list # Image Tag entries to include in this batch. — item shape: {imageId?: string, tagId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectId}/images/tags"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}]}
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get untagged images for a given project iteration.
#
# GET /projects/{projectId}/images/untagged
# Returns: table<created: string, height: int, id: string, originalImageUri: string, regions: list<record>, resizedImageUri: string, tags: list<record>, thumbnailUri: string, width: int>
# operationId: GetUntaggedImages
export def "get-untagged-images" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --iteration-id: string # The iteration id. Defaults to workspace. (format: uuid)
  --order-by: string@order-by-completer # The ordering. Defaults to newest.
  --take: int # Maximum number of images to return. Defaults to 50, limited to 256. (format: int32, default: 50)
  --skip: int # Number of images to skip before beginning the image batch. Defaults to 0. (format: int32, default: 0)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/images/untagged"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: iterationId, var: iteration_id}, {name: orderBy, var: order_by}, {name: take, var: take}, {name: skip, var: skip}]
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id, iteration_id: $iteration_id, order_by: $order_by, take: $take, skip: $skip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the number of untagged images.
#
# GET /projects/{projectId}/images/untagged/count
# Returns: int
# operationId: GetUntaggedImageCount
export def "get-untagged-image-count" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --iteration-id: string # The iteration id. Defaults to workspace. (format: uuid)
]: nothing -> any {
  http-request {
    method: get
    path: "/projects/{projectId}/images/untagged/count"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: iterationId, var: iteration_id}]
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id, iteration_id: $iteration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add the provided images urls to the set of training images.
#
# POST /projects/{projectId}/images/urls
# Returns: record<images: table<image: record, sourceUrl: string, status: string>, isBatchSuccessful: bool>
# operationId: CreateImagesFromUrls
export def "create-images-from-urls" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --images: list # item shape: {regions?: list, tagIds?: list<string>, url: string}
  --tag-ids: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectId}/images/urls"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: images, var: images}, {name: tagIds, var: tag_ids}]}
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id, images: $images, tag_ids: $tag_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get region proposals for an image. Returns empty array if no proposals are found.
#
# POST /projects/{projectId}/images/{imageId}/regionproposals
# Returns: record<imageId: string, projectId: string, proposals: table<boundingBox: record, confidence: float>>
# operationId: GetImageRegionProposals
export def "get-image-region-proposals" [
  project_id: string
  image_id: string
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
    path: "/projects/{projectId}/images/{imageId}/regionproposals"
    path_params: [{name: projectId, var: project_id}, {name: imageId, var: image_id}]
    accept: ["application/json"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id, image_id: $image_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get iterations for the project.
#
# GET /projects/{projectId}/iterations
# Returns: table<classificationType: string, created: string, domainId: string, exportable: bool, exportableTo: list<string>, id: string, lastModified: string, name: string, originalPublishResourceId: string, projectId: string, publishName: string, reservedBudgetInHours: int, status: string, trainedAt: string, trainingTimeInMinutes: int, trainingType: string>
# operationId: GetIterations
export def "get-iterations" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/projects/{projectId}/iterations"
    path_params: [{name: projectId, var: project_id}]
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a specific iteration of a project.
#
# DELETE /projects/{projectId}/iterations/{iterationId}
# operationId: DeleteIteration
export def "delete-iteration" [
  project_id: string
  iteration_id: string
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
    path: "/projects/{projectId}/iterations/{iterationId}"
    path_params: [{name: projectId, var: project_id}, {name: iterationId, var: iteration_id}]
    accept: ["*/*"]
    ok: [204]
    auth: training-key
  } {
    project_id: $project_id, iteration_id: $iteration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific iteration.
#
# GET /projects/{projectId}/iterations/{iterationId}
# Returns: record<classificationType: string, created: string, domainId: string, exportable: bool, exportableTo: list<string>, id: string, lastModified: string, name: string, originalPublishResourceId: string, projectId: string, publishName: string, reservedBudgetInHours: int, status: string, trainedAt: string, trainingTimeInMinutes: int, trainingType: string>
# operationId: GetIteration
export def "get-iteration" [
  project_id: string
  iteration_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/projects/{projectId}/iterations/{iterationId}"
    path_params: [{name: projectId, var: project_id}, {name: iterationId, var: iteration_id}]
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id, iteration_id: $iteration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a specific iteration.
#
# PATCH /projects/{projectId}/iterations/{iterationId}
# Returns: record<classificationType: string, created: string, domainId: string, exportable: bool, exportableTo: list<string>, id: string, lastModified: string, name: string, originalPublishResourceId: string, projectId: string, publishName: string, reservedBudgetInHours: int, status: string, trainedAt: string, trainingTimeInMinutes: int, trainingType: string>
# operationId: UpdateIteration
export def "update-iteration" [
  project_id: string
  iteration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  name: string # Gets or sets the name of the iteration.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/projects/{projectId}/iterations/{iterationId}"
    path_params: [{name: projectId, var: project_id}, {name: iterationId, var: iteration_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id, iteration_id: $iteration_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the list of exports for a specific iteration.
#
# GET /projects/{projectId}/iterations/{iterationId}/export
# Returns: table<downloadUri: string, flavor: string, newerVersionAvailable: bool, platform: string, status: string>
# operationId: GetExports
export def "get-exports" [
  project_id: string
  iteration_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/projects/{projectId}/iterations/{iterationId}/export"
    path_params: [{name: projectId, var: project_id}, {name: iterationId, var: iteration_id}]
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id, iteration_id: $iteration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Export a trained iteration.
#
# POST /projects/{projectId}/iterations/{iterationId}/export
# Returns: record<downloadUri: string, flavor: string, newerVersionAvailable: bool, platform: string, status: string>
# operationId: ExportIteration
export def "export-iteration" [
  project_id: string
  iteration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --platform: string@platform-completer # The target platform. (required)
  --flavor: string@flavor-completer # The flavor of the target platform.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/projects/{projectId}/iterations/{iterationId}/export"
    path_params: [{name: projectId, var: project_id}, {name: iterationId, var: iteration_id}]
    query: [{name: platform, var: platform, required: true}, {name: flavor, var: flavor}]
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id, iteration_id: $iteration_id, platform: $platform, flavor: $flavor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get detailed performance information about an iteration.
#
# GET /projects/{projectId}/iterations/{iterationId}/performance
# Returns: record<averagePrecision: float, perTagPerformance: table<averagePrecision: float, id: string, name: string, precision: float, precisionStdDeviation: float, recall: float, recallStdDeviation: float>, precision: float, precisionStdDeviation: float, recall: float, recallStdDeviation: float>
# operationId: GetIterationPerformance
export def "get-iteration-performance" [
  project_id: string
  iteration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --threshold: float # The threshold used to determine true predictions. (format: float)
  --overlap-threshold: float # If applicable, the bounding box overlap threshold used to determine true predictions. (format: float)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/iterations/{iterationId}/performance"
    path_params: [{name: projectId, var: project_id}, {name: iterationId, var: iteration_id}]
    query: [{name: threshold, var: threshold}, {name: overlapThreshold, var: overlap_threshold}]
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id, iteration_id: $iteration_id, threshold: $threshold, overlap_threshold: $overlap_threshold
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get image with its prediction for a given project iteration.
#
# GET /projects/{projectId}/iterations/{iterationId}/performance/images
# Returns: table<created: string, height: int, id: string, imageUri: string, predictions: list<record>, regions: list<record>, tags: list<record>, thumbnailUri: string, width: int>
# operationId: GetImagePerformances
export def "get-image-performances" [
  project_id: string
  iteration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --tag-ids: list<string> # A list of tags ids to filter the images. Defaults to all tagged images when null. Limited to 20.
  --order-by: string@order-by-completer # The ordering. Defaults to newest.
  --take: int # Maximum number of images to return. Defaults to 50, limited to 256. (format: int32, default: 50)
  --skip: int # Number of images to skip before beginning the image batch. Defaults to 0. (format: int32, default: 0)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/iterations/{iterationId}/performance/images"
    path_params: [{name: projectId, var: project_id}, {name: iterationId, var: iteration_id}]
    query: [{name: tagIds, var: tag_ids, style: csv}, {name: orderBy, var: order_by}, {name: take, var: take}, {name: skip, var: skip}]
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id, iteration_id: $iteration_id, tag_ids: $tag_ids, order_by: $order_by, take: $take, skip: $skip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the number of images tagged with the provided {tagIds} that have prediction results from training for the provided iteration {iterationId}.
#
# GET /projects/{projectId}/iterations/{iterationId}/performance/images/count
# Returns: int
# operationId: GetImagePerformanceCount
export def "get-image-performance-count" [
  project_id: string
  iteration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --tag-ids: list<string> # A list of tags ids to filter the images to count. Defaults to all tags when null.
]: nothing -> any {
  http-request {
    method: get
    path: "/projects/{projectId}/iterations/{iterationId}/performance/images/count"
    path_params: [{name: projectId, var: project_id}, {name: iterationId, var: iteration_id}]
    query: [{name: tagIds, var: tag_ids, style: csv}]
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id, iteration_id: $iteration_id, tag_ids: $tag_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Unpublish a specific iteration.
#
# DELETE /projects/{projectId}/iterations/{iterationId}/publish
# operationId: UnpublishIteration
export def "unpublish-iteration" [
  project_id: string
  iteration_id: string
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
    path: "/projects/{projectId}/iterations/{iterationId}/publish"
    path_params: [{name: projectId, var: project_id}, {name: iterationId, var: iteration_id}]
    accept: ["*/*"]
    ok: [204]
    auth: training-key
  } {
    project_id: $project_id, iteration_id: $iteration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Publish a specific iteration.
#
# POST /projects/{projectId}/iterations/{iterationId}/publish
# Returns: bool
# operationId: PublishIteration
export def "publish-iteration" [
  project_id: string
  iteration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --publish-name: string # The name to give the published iteration. (required)
  --prediction-id: string # The id of the prediction resource to publish to. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/projects/{projectId}/iterations/{iterationId}/publish"
    path_params: [{name: projectId, var: project_id}, {name: iterationId, var: iteration_id}]
    query: [{name: publishName, var: publish_name, required: true}, {name: predictionId, var: prediction_id, required: true}]
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id, iteration_id: $iteration_id, publish_name: $publish_name, prediction_id: $prediction_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a set of predicted images and their associated prediction results.
#
# DELETE /projects/{projectId}/predictions
# operationId: DeletePrediction
export def "delete-prediction" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # The prediction ids. Limited to 64. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/projects/{projectId}/predictions"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: ids, var: ids, style: csv, required: true}]
    accept: ["*/*"]
    ok: [204]
    auth: training-key
  } {
    project_id: $project_id, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get images that were sent to your prediction endpoint.
#
# POST /projects/{projectId}/predictions/query
# Returns: record<results: table<created: string, domain: string, id: string, iteration: string, originalImageUri: string, predictions: list, project: string, resizedImageUri: string, thumbnailUri: string>, token: record<application: string, continuation: string, endTime: string, iterationId: string, maxCount: int, orderBy: string, session: string, startTime: string, tags: list<record>>>
# operationId: QueryPredictions
export def "query-predictions" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --application: string
  --continuation: string
  --end-time: string # nullable, format: date-time
  --iteration-id: string # nullable, format: uuid
  --max-count: int # format: int32
  --order-by: string@order-by-completer-1
  --session: string
  --start-time: string # nullable, format: date-time
  --tags: list # item shape: {id?: string, maxThreshold?: float, minThreshold?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectId}/predictions/query"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: application, var: application}, {name: continuation, var: continuation}, {name: endTime, var: end_time}, {name: iterationId, var: iteration_id}, {name: maxCount, var: max_count}, {name: orderBy, var: order_by}, {name: session, var: session}, {name: startTime, var: start_time}, {name: tags, var: tags}]}
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id, application: $application, continuation: $continuation, end_time: $end_time, iteration_id: $iteration_id, max_count: $max_count, order_by: $order_by, session: $session, start_time: $start_time, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Quick test an image.
#
# POST /projects/{projectId}/quicktest/image
# Returns: record<created: string, id: string, iteration: string, predictions: table<boundingBox: record, probability: float, tagId: string, tagName: string>, project: string>
# operationId: QuickTestImage
export def "quick-test-image" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --iteration-id: string # Optional. Specifies the id of a particular iteration to evaluate against. The default iteration for the project will be used when not specified. (format: uuid)
  --store: oneof<nothing, bool> # Optional. Specifies whether or not to store the result of this prediction. The default is true, to store. (default: true)
  image_data: string # Binary image data. Supported formats are JPEG, GIF, PNG, and BMP. Supports images up to 6MB. (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectId}/quicktest/image"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: iterationId, var: iteration_id}, {name: store, var: store}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: imageData, var: image_data}], files: [imageData]}
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id, iteration_id: $iteration_id, store: $store, image_data: $image_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Quick test an image url.
#
# POST /projects/{projectId}/quicktest/url
# Returns: record<created: string, id: string, iteration: string, predictions: table<boundingBox: record, probability: float, tagId: string, tagName: string>, project: string>
# operationId: QuickTestImageUrl
export def "quick-test-image-url" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --iteration-id: string # Optional. Specifies the id of a particular iteration to evaluate against. The default iteration for the project will be used when not specified. (format: uuid)
  --store: oneof<nothing, bool> # Optional. Specifies whether or not to store the result of this prediction. The default is true, to store. (default: true)
  url: string # Url of the image.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectId}/quicktest/url"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: iterationId, var: iteration_id}, {name: store, var: store}]
    body: {content_type: "application/json", kind: json, fields: [{name: url, var: url}]}
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id, iteration_id: $iteration_id, store: $store, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the tags for a given project and iteration.
#
# GET /projects/{projectId}/tags
# Returns: table<description: string, id: string, imageCount: int, name: string, type: string>
# operationId: GetTags
export def "get-tags" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --iteration-id: string # The iteration id. Defaults to workspace. (format: uuid)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/tags"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: iterationId, var: iteration_id}]
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id, iteration_id: $iteration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a tag for the project.
#
# POST /projects/{projectId}/tags
# Returns: record<description: string, id: string, imageCount: int, name: string, type: string>
# operationId: CreateTag
export def "create-tag" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # The tag name. (required)
  --description: string # Optional description for the tag.
  --type: string@type-completer # Optional type for the tag.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/projects/{projectId}/tags"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: name, var: name, required: true}, {name: description, var: description}, {name: type, var: type}]
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id, name: $name, description: $description, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a tag from the project.
#
# DELETE /projects/{projectId}/tags/{tagId}
# operationId: DeleteTag
export def "delete-tag" [
  project_id: string
  tag_id: string
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
    path: "/projects/{projectId}/tags/{tagId}"
    path_params: [{name: projectId, var: project_id}, {name: tagId, var: tag_id}]
    accept: ["*/*"]
    ok: [204]
    auth: training-key
  } {
    project_id: $project_id, tag_id: $tag_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information about a specific tag.
#
# GET /projects/{projectId}/tags/{tagId}
# Returns: record<description: string, id: string, imageCount: int, name: string, type: string>
# operationId: GetTag
export def "get-tag" [
  project_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --iteration-id: string # The iteration to retrieve this tag from. Optional, defaults to current training set. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/tags/{tagId}"
    path_params: [{name: projectId, var: project_id}, {name: tagId, var: tag_id}]
    query: [{name: iterationId, var: iteration_id}]
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id, tag_id: $tag_id, iteration_id: $iteration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a tag.
#
# PATCH /projects/{projectId}/tags/{tagId}
# Returns: record<description: string, id: string, imageCount: int, name: string, type: string>
# operationId: UpdateTag
export def "update-tag" [
  project_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # Gets or sets the description of the tag. (nullable)
  name: string # Gets or sets the name of the tag.
  type: string@type-completer # Gets or sets the type of the tag.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/projects/{projectId}/tags/{tagId}"
    path_params: [{name: projectId, var: project_id}, {name: tagId, var: tag_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: type, var: type}]}
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id, tag_id: $tag_id, description: $description, name: $name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Suggest tags and regions for an array/batch of untagged images. Returns empty array if no tags are found.
#
# POST /projects/{projectId}/tagsandregions/suggestions
# Returns: table<created: string, id: string, iteration: string, predictionUncertainty: float, predictions: list<record>, project: string>
# operationId: SuggestTagsAndRegions
export def "suggest-tags-and-regions" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --iteration-id: string # IterationId to use for tag and region suggestion. (required, format: uuid)
  --image-ids: list<string> # Array of image ids tag suggestion are needed for. Use GetUntaggedImages API to get imageIds. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: post
    path: "/projects/{projectId}/tagsandregions/suggestions"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: iterationId, var: iteration_id, required: true}, {name: imageIds, var: image_ids, style: csv, required: true}]
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id, iteration_id: $iteration_id, image_ids: $image_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Queues project for training.
#
# POST /projects/{projectId}/train
# Returns: record<classificationType: string, created: string, domainId: string, exportable: bool, exportableTo: list<string>, id: string, lastModified: string, name: string, originalPublishResourceId: string, projectId: string, publishName: string, reservedBudgetInHours: int, status: string, trainedAt: string, trainingTimeInMinutes: int, trainingType: string>
# operationId: TrainProject
export def "train-project" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --training-type: string@training-type-completer # The type of training to use to train the project (default: Regular).
  --reserved-budget-in-hours: int # The number of hours reserved as budget for training (if applicable). (format: int32, default: 0)
  --force-train: oneof<nothing, bool> # Whether to force train even if dataset and configuration does not change (default: false). (default: false)
  --notification-email-address: string # The email address to send notification to when training finishes (default: null).
  --selected-tags: list<string> # List of tags selected for this training session, other tags in the project will be ignored.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectId}/train"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: trainingType, var: training_type}, {name: reservedBudgetInHours, var: reserved_budget_in_hours}, {name: forceTrain, var: force_train}, {name: notificationEmailAddress, var: notification_email_address}]
    body: {content_type: "application/json", kind: json, fields: [{name: selectedTags, var: selected_tags}]}
    accept: ["application/json", "application/xml", "text/xml"]
    ok: [200]
    auth: training-key
  } {
    project_id: $project_id, training_type: $training_type, reserved_budget_in_hours: $reserved_budget_in_hours, force_train: $force_train, notification_email_address: $notification_email_address, selected_tags: $selected_tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
