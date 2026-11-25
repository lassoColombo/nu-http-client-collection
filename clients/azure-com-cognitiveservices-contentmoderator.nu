# Auto-generated client for Content Moderator Client v1.0
# Source: https://api.apis.guru/v2/specs/azure.com/cognitiveservices-ContentModerator/1.0/swagger.json
# Auth: --token flag or $env.CONTENT_MODERATOR_CLIENT_TOKEN

const CLIENT = {
  base_url: "{Endpoint}"
  token_env_var: "CONTENT_MODERATOR_CLIENT_TOKEN"
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

def base-url-completer [] { ["{Endpoint}"] }
def auth-scheme-completer [] { ["ocp-apim-subscription-key"] }

# Completers for enum parameters
def content-type-completer [] { ["text/html" "text/markdown" "text/plain" "text/xml"] }
def content-type-completer-1 [] { ["Image" "Text" "Video"] }
def content-type-completer-2 [] { ["application/json" "image/jpeg"] }
def accept-completer [] { ["application/json" "text/json"] }
def content-type-completer-3 [] { ["text/plain"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    list-management-image-lists-get-all-image-lists: "table<Description: string, Id: int, Metadata: record, Name: string>"
    list-management-image-lists-create: "record<Description: string, Id: int, Metadata: record, Name: string>"
    list-management-image-lists-delete: "string"
    list-management-image-lists-get-details: "record<Description: string, Id: int, Metadata: record, Name: string>"
    list-management-image-lists-update: "record<Description: string, Id: int, Metadata: record, Name: string>"
    list-management-image-lists-refresh-index: "record<AdvancedInfo: list<record>, ContentSourceId: string, IsUpdateSuccess: bool, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string>"
    list-management-image-delete-all-images: "string"
    list-management-image-get-all-image-ids: "record<ContentIds: list<int>, ContentSource: string, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string>"
    list-management-image-add-image: "record<AdditionalInfo: table<Key: string, Value: string>, ContentId: string, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string>"
    list-management-image-delete-image: "string"
    list-management-term-lists-get-all-term-lists: "table<Description: string, Id: int, Metadata: record, Name: string>"
    list-management-term-lists-create: "record<Description: string, Id: int, Metadata: record, Name: string>"
    list-management-term-lists-delete: "string"
    list-management-term-lists-get-details: "record<Description: string, Id: int, Metadata: record, Name: string>"
    list-management-term-lists-update: "record<Description: string, Id: int, Metadata: record, Name: string>"
    list-management-term-lists-refresh-index: "record<AdvancedInfo: list<record>, ContentSourceId: string, IsUpdateSuccess: bool, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string>"
    list-management-term-delete-all-terms: "string"
    list-management-term-get-all-terms: "record<Data: record<Language: string, Status: record<Code: int, Description: string, Exception: string>, Terms: list<record>, TrackingId: string>, Paging: record<Limit: int, Offset: int, Returned: int, Total: int>>"
    list-management-term-delete-term: "string"
    image-moderation-evaluate: "record<AdultClassificationScore: float, AdvancedInfo: table<Key: string, Value: string>, CacheID: string, IsImageAdultClassified: bool, IsImageRacyClassified: bool, RacyClassificationScore: float, Result: bool, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string>"
    image-moderation-find-faces: "record<AdvancedInfo: table<Key: string, Value: string>, CacheId: string, Count: int, Faces: table<Bottom: int, Left: int, Right: int, Top: int>, Result: bool, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string>"
    image-moderation-match: "record<CacheID: string, IsMatch: bool, Matches: table<Label: string, MatchId: int, Score: float, Source: string, Tags: list>, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string>"
    image-moderation-ocr: "record<CacheId: string, Candidates: table<Confidence: float, Text: string>, Language: string, Metadata: table<Key: string, Value: string>, Status: record<Code: int, Description: string, Exception: string>, Text: string, TrackingId: string>"
    text-moderation-detect-language: "record<DetectedLanguage: string, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string>"
    text-moderation-screen-text: "record<AutoCorrectedText: string, Classification: record<Category1: record<Score: float>, Category2: record<Score: float>, Category3: record<Score: float>, ReviewRecommended: bool>, Language: string, Misrepresentation: list<string>, NormalizedText: string, OriginalText: string, PII: record<Address: list<record>, Email: list<record>, IPA: list<record>, Phone: list<record>, SSN: list<record>>, Status: record<Code: int, Description: string, Exception: string>, Terms: table<Index: int, ListId: int, OriginalIndex: int, Term: string>, TrackingId: string>"
    reviews-create-job: "record<JobId: string>"
    reviews-get-job-details: "record<CallBackEndpoint: string, Id: string, JobExecutionReport: table<Msg: string, Ts: string>, ResultMetaData: table<Key: string, Value: string>, ReviewId: string, Status: string, TeamName: string, Type: string, WorkflowId: string>"
    reviews-create-reviews: "list<string>"
    reviews-get-review: "record<CallbackEndpoint: string, Content: string, ContentId: string, CreatedBy: string, Metadata: table<Key: string, Value: string>, ReviewId: string, ReviewerResultTags: table<Key: string, Value: string>, Status: string, SubTeam: string, Type: string>"
    reviews-get-video-frames: "record<ReviewId: string, VideoFrames: table<FrameImage: string, Metadata: list, ReviewerResultTags: list, Timestamp: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["list-management-image-lists-get-all-image-lists" "list-management-image-lists-create" "list-management-image-lists-delete" "list-management-image-lists-get-details" "list-management-image-lists-update" "list-management-image-lists-refresh-index" "list-management-image-delete-all-images" "list-management-image-get-all-image-ids" "list-management-image-add-image" "list-management-image-delete-image" "list-management-term-lists-get-all-term-lists" "list-management-term-lists-create" "list-management-term-lists-delete" "list-management-term-lists-get-details" "list-management-term-lists-update" "list-management-term-lists-refresh-index" "list-management-term-delete-all-terms" "list-management-term-get-all-terms" "list-management-term-delete-term" "list-management-term-add-term" "image-moderation-evaluate" "image-moderation-find-faces" "image-moderation-match" "image-moderation-ocr" "text-moderation-detect-language" "text-moderation-screen-text" "reviews-create-job" "reviews-get-job-details" "reviews-create-reviews" "reviews-get-review" "reviews-get-video-frames" "reviews-add-video-frame" "reviews-publish-video-review" "reviews-add-video-transcript" "reviews-add-video-transcript-moderation-result" "commands"] | sort) } | get name | first)
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

# Gets all the Image Lists.
#
# GET /contentmoderator/lists/v1.0/imagelists
# Returns: table<Description: string, Id: int, Metadata: record, Name: string>
# operationId: ListManagementImageLists_GetAllImageLists
export def "list-management-image-lists-get-all-image-lists" [
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
    path: "/contentmoderator/lists/v1.0/imagelists"
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an image list.
#
# POST /contentmoderator/lists/v1.0/imagelists
# Returns: record<Description: string, Id: int, Metadata: record, Name: string>
# operationId: ListManagementImageLists_Create
export def "list-management-image-lists-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The content type. (required)
  --description: string # Description of the list.
  --metadata: record # Metadata of the list.
  --name: string # Name of the list.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contentmoderator/lists/v1.0/imagelists"
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: Metadata, var: metadata}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    content_type: $content_type, description: $description, metadata: $metadata, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes image list with the list Id equal to list Id passed.
#
# DELETE /contentmoderator/lists/v1.0/imagelists/{listId}
# Returns: string
# operationId: ListManagementImageLists_Delete
export def "list-management-image-lists-delete" [
  list_id: string
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
    path: "/contentmoderator/lists/v1.0/imagelists/{listId}"
    path_params: [{name: listId, var: list_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    list_id: $list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the details of the image list with list Id equal to list Id passed.
#
# GET /contentmoderator/lists/v1.0/imagelists/{listId}
# Returns: record<Description: string, Id: int, Metadata: record, Name: string>
# operationId: ListManagementImageLists_GetDetails
export def "list-management-image-lists-get-details" [
  list_id: string
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
    path: "/contentmoderator/lists/v1.0/imagelists/{listId}"
    path_params: [{name: listId, var: list_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    list_id: $list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an image list with list Id equal to list Id passed.
#
# PUT /contentmoderator/lists/v1.0/imagelists/{listId}
# Returns: record<Description: string, Id: int, Metadata: record, Name: string>
# operationId: ListManagementImageLists_Update
export def "list-management-image-lists-update" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The content type. (required)
  --description: string # Description of the list.
  --metadata: record # Metadata of the list.
  --name: string # Name of the list.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/contentmoderator/lists/v1.0/imagelists/{listId}"
    path_params: [{name: listId, var: list_id}]
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: Metadata, var: metadata}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    list_id: $list_id, content_type: $content_type, description: $description, metadata: $metadata, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Refreshes the index of the list with list Id equal to list Id passed.
#
# POST /contentmoderator/lists/v1.0/imagelists/{listId}/RefreshIndex
# Returns: record<AdvancedInfo: list<record>, ContentSourceId: string, IsUpdateSuccess: bool, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string>
# operationId: ListManagementImageLists_RefreshIndex
export def "list-management-image-lists-refresh-index" [
  list_id: string
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
    path: "/contentmoderator/lists/v1.0/imagelists/{listId}/RefreshIndex"
    path_params: [{name: listId, var: list_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    list_id: $list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes all images from the list with list Id equal to list Id passed.
#
# DELETE /contentmoderator/lists/v1.0/imagelists/{listId}/images
# Returns: string
# operationId: ListManagementImage_DeleteAllImages
export def "list-management-image-delete-all-images" [
  list_id: string
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
    path: "/contentmoderator/lists/v1.0/imagelists/{listId}/images"
    path_params: [{name: listId, var: list_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    list_id: $list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all image Ids from the list with list Id equal to list Id passed.
#
# GET /contentmoderator/lists/v1.0/imagelists/{listId}/images
# Returns: record<ContentIds: list<int>, ContentSource: string, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string>
# operationId: ListManagementImage_GetAllImageIds
export def "list-management-image-get-all-image-ids" [
  list_id: string
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
    path: "/contentmoderator/lists/v1.0/imagelists/{listId}/images"
    path_params: [{name: listId, var: list_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    list_id: $list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add an image to the list with list Id equal to list Id passed.
#
# POST /contentmoderator/lists/v1.0/imagelists/{listId}/images
# Returns: record<AdditionalInfo: table<Key: string, Value: string>, ContentId: string, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string>
# operationId: ListManagementImage_AddImage
export def "list-management-image-add-image" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: int # Tag for the image.
  --label: string # The image label.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/contentmoderator/lists/v1.0/imagelists/{listId}/images"
    path_params: [{name: listId, var: list_id}]
    query: [{name: tag, var: tag}, {name: label, var: label}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    list_id: $list_id, tag: $tag, label: $label
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an image from the list with list Id and image Id passed.
#
# DELETE /contentmoderator/lists/v1.0/imagelists/{listId}/images/{ImageId}
# Returns: string
# operationId: ListManagementImage_DeleteImage
export def "list-management-image-delete-image" [
  list_id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/contentmoderator/lists/v1.0/imagelists/{listId}/images/{ImageId}"
    path_params: [{name: listId, var: list_id}, {name: ImageId, var: image_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    list_id: $list_id, image_id: $image_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# gets all the Term Lists
#
# GET /contentmoderator/lists/v1.0/termlists
# Returns: table<Description: string, Id: int, Metadata: record, Name: string>
# operationId: ListManagementTermLists_GetAllTermLists
export def "list-management-term-lists-get-all-term-lists" [
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
    path: "/contentmoderator/lists/v1.0/termlists"
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Term List
#
# POST /contentmoderator/lists/v1.0/termlists
# Returns: record<Description: string, Id: int, Metadata: record, Name: string>
# operationId: ListManagementTermLists_Create
export def "list-management-term-lists-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The content type. (required)
  --description: string # Description of the list.
  --metadata: record # Metadata of the list.
  --name: string # Name of the list.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contentmoderator/lists/v1.0/termlists"
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: Metadata, var: metadata}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    content_type: $content_type, description: $description, metadata: $metadata, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes term list with the list Id equal to list Id passed.
#
# DELETE /contentmoderator/lists/v1.0/termlists/{listId}
# Returns: string
# operationId: ListManagementTermLists_Delete
export def "list-management-term-lists-delete" [
  list_id: string
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
    path: "/contentmoderator/lists/v1.0/termlists/{listId}"
    path_params: [{name: listId, var: list_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    list_id: $list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list Id details of the term list with list Id equal to list Id passed.
#
# GET /contentmoderator/lists/v1.0/termlists/{listId}
# Returns: record<Description: string, Id: int, Metadata: record, Name: string>
# operationId: ListManagementTermLists_GetDetails
export def "list-management-term-lists-get-details" [
  list_id: string
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
    path: "/contentmoderator/lists/v1.0/termlists/{listId}"
    path_params: [{name: listId, var: list_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    list_id: $list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an Term List.
#
# PUT /contentmoderator/lists/v1.0/termlists/{listId}
# Returns: record<Description: string, Id: int, Metadata: record, Name: string>
# operationId: ListManagementTermLists_Update
export def "list-management-term-lists-update" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The content type. (required)
  --description: string # Description of the list.
  --metadata: record # Metadata of the list.
  --name: string # Name of the list.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/contentmoderator/lists/v1.0/termlists/{listId}"
    path_params: [{name: listId, var: list_id}]
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: Metadata, var: metadata}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    list_id: $list_id, content_type: $content_type, description: $description, metadata: $metadata, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Refreshes the index of the list with list Id equal to list ID passed.
#
# POST /contentmoderator/lists/v1.0/termlists/{listId}/RefreshIndex
# Returns: record<AdvancedInfo: list<record>, ContentSourceId: string, IsUpdateSuccess: bool, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string>
# operationId: ListManagementTermLists_RefreshIndex
export def "list-management-term-lists-refresh-index" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # Language of the terms. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/contentmoderator/lists/v1.0/termlists/{listId}/RefreshIndex"
    path_params: [{name: listId, var: list_id}]
    query: [{name: language, var: language, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    list_id: $list_id, language: $language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes all terms from the list with list Id equal to the list Id passed.
#
# DELETE /contentmoderator/lists/v1.0/termlists/{listId}/terms
# Returns: string
# operationId: ListManagementTerm_DeleteAllTerms
export def "list-management-term-delete-all-terms" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # Language of the terms. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/contentmoderator/lists/v1.0/termlists/{listId}/terms"
    path_params: [{name: listId, var: list_id}]
    query: [{name: language, var: language, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    list_id: $list_id, language: $language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all terms from the list with list Id equal to the list Id passed.
#
# GET /contentmoderator/lists/v1.0/termlists/{listId}/terms
# Returns: record<Data: record<Language: string, Status: record<Code: int, Description: string, Exception: string>, Terms: list<record>, TrackingId: string>, Paging: record<Limit: int, Offset: int, Returned: int, Total: int>>
# operationId: ListManagementTerm_GetAllTerms
export def "list-management-term-get-all-terms" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # Language of the terms. (required)
  --offset: int # The pagination start index.
  --limit: int # The max limit.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contentmoderator/lists/v1.0/termlists/{listId}/terms"
    path_params: [{name: listId, var: list_id}]
    query: [{name: language, var: language, required: true}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    list_id: $list_id, language: $language, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a term from the list with list Id equal to the list Id passed.
#
# DELETE /contentmoderator/lists/v1.0/termlists/{listId}/terms/{term}
# Returns: string
# operationId: ListManagementTerm_DeleteTerm
export def "list-management-term-delete-term" [
  list_id: string
  term: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # Language of the terms. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/contentmoderator/lists/v1.0/termlists/{listId}/terms/{term}"
    path_params: [{name: listId, var: list_id}, {name: term, var: term}]
    query: [{name: language, var: language, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    list_id: $list_id, term: $term, language: $language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a term to the term list with list Id equal to list Id passed.
#
# POST /contentmoderator/lists/v1.0/termlists/{listId}/terms/{term}
# operationId: ListManagementTerm_AddTerm
export def "list-management-term-add-term" [
  list_id: string
  term: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # Language of the terms. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/contentmoderator/lists/v1.0/termlists/{listId}/terms/{term}"
    path_params: [{name: listId, var: list_id}, {name: term, var: term}]
    query: [{name: language, var: language, required: true}]
    accept: ["application/json"]
    ok: [201]
    auth: ocp-apim-subscription-key
  } {
    list_id: $list_id, term: $term, language: $language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns probabilities of the image containing racy or adult content.
#
# POST /contentmoderator/moderate/v1.0/ProcessImage/Evaluate
# Returns: record<AdultClassificationScore: float, AdvancedInfo: table<Key: string, Value: string>, CacheID: string, IsImageAdultClassified: bool, IsImageRacyClassified: bool, RacyClassificationScore: float, Result: bool, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string>
# operationId: ImageModeration_Evaluate
export def "image-moderation-evaluate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-image: oneof<nothing, bool> # Whether to retain the submitted image for future use; defaults to false if omitted.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/contentmoderator/moderate/v1.0/ProcessImage/Evaluate"
    query: [{name: CacheImage, var: cache_image}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    cache_image: $cache_image
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of faces found.
#
# POST /contentmoderator/moderate/v1.0/ProcessImage/FindFaces
# Returns: record<AdvancedInfo: table<Key: string, Value: string>, CacheId: string, Count: int, Faces: table<Bottom: int, Left: int, Right: int, Top: int>, Result: bool, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string>
# operationId: ImageModeration_FindFaces
export def "image-moderation-find-faces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-image: oneof<nothing, bool> # Whether to retain the submitted image for future use; defaults to false if omitted.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/contentmoderator/moderate/v1.0/ProcessImage/FindFaces"
    query: [{name: CacheImage, var: cache_image}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    cache_image: $cache_image
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fuzzily match an image against one of your custom Image Lists. You can create and manage your custom image lists using this (/docs/services/578ff44d2703741568569ab9/operations/578ff7b12703741568569abe) API. Returns ID and tags of matching image. Note: Refresh Index must be run on the corresponding Image List before additions and removals are reflected in the response.
#
# POST /contentmoderator/moderate/v1.0/ProcessImage/Match
# Returns: record<CacheID: string, IsMatch: bool, Matches: table<Label: string, MatchId: int, Score: float, Source: string, Tags: list>, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string>
# operationId: ImageModeration_Match
export def "image-moderation-match" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --list-id: string # The list Id.
  --cache-image: oneof<nothing, bool> # Whether to retain the submitted image for future use; defaults to false if omitted.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/contentmoderator/moderate/v1.0/ProcessImage/Match"
    query: [{name: listId, var: list_id}, {name: CacheImage, var: cache_image}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    list_id: $list_id, cache_image: $cache_image
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns any text found in the image for the language specified. If no language is specified in input then the detection defaults to English.
#
# POST /contentmoderator/moderate/v1.0/ProcessImage/OCR
# Returns: record<CacheId: string, Candidates: table<Confidence: float, Text: string>, Language: string, Metadata: table<Key: string, Value: string>, Status: record<Code: int, Description: string, Exception: string>, Text: string, TrackingId: string>
# operationId: ImageModeration_OCR
export def "image-moderation-ocr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # Language of the terms. (required)
  --cache-image: oneof<nothing, bool> # Whether to retain the submitted image for future use; defaults to false if omitted.
  --enhanced: oneof<nothing, bool> # When set to True, the image goes through additional processing to come with additional candidates. image/tiff is not supported when enhanced is set to true Note: This impacts the response time. (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/contentmoderator/moderate/v1.0/ProcessImage/OCR"
    query: [{name: language, var: language, required: true}, {name: CacheImage, var: cache_image}, {name: enhanced, var: enhanced}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    language: $language, cache_image: $cache_image, enhanced: $enhanced
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This operation will detect the language of given input content. Returns the ISO 639-3 code (http://www-01.sil.org/iso639-3/codes.asp) for the predominant language comprising the submitted text. Over 110 languages supported.
#
# POST /contentmoderator/moderate/v1.0/ProcessText/DetectLanguage
# Returns: record<DetectedLanguage: string, Status: record<Code: int, Description: string, Exception: string>, TrackingId: string>
# operationId: TextModeration_DetectLanguage
export def "text-moderation-detect-language" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string@content-type-completer # The content type. (required)
  --body: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contentmoderator/moderate/v1.0/ProcessText/DetectLanguage"
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    content_type: $content_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detect profanity and match against custom and shared blacklists
#
# POST /contentmoderator/moderate/v1.0/ProcessText/Screen/
# Returns: record<AutoCorrectedText: string, Classification: record<Category1: record<Score: float>, Category2: record<Score: float>, Category3: record<Score: float>, ReviewRecommended: bool>, Language: string, Misrepresentation: list<string>, NormalizedText: string, OriginalText: string, PII: record<Address: list<record>, Email: list<record>, IPA: list<record>, Phone: list<record>, SSN: list<record>>, Status: record<Code: int, Description: string, Exception: string>, Terms: table<Index: int, ListId: int, OriginalIndex: int, Term: string>, TrackingId: string>
# operationId: TextModeration_ScreenText
export def "text-moderation-screen-text" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # Language of the text.
  --autocorrect: oneof<nothing, bool> # Autocorrect text. (default: false)
  --pii: oneof<nothing, bool> # Detect personal identifiable information. (default: false)
  --list-id: string # The list Id.
  --classify: oneof<nothing, bool> # Classify input. (default: false)
  --content-type: string@content-type-completer # The content type. (required)
  --body: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contentmoderator/moderate/v1.0/ProcessText/Screen/"
    query: [{name: language, var: language}, {name: autocorrect, var: autocorrect}, {name: PII, var: pii}, {name: listId, var: list_id}, {name: classify, var: classify}]
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    language: $language, autocorrect: $autocorrect, pii: $pii, list_id: $list_id, classify: $classify, content_type: $content_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# A job Id will be returned for the content posted on this endpoint. Once the content is evaluated against the Workflow provided the review will be created or ignored based on the workflow expression. CallBack Schemas Job Completion CallBack Sample { "JobId": ", "ReviewId": "", "WorkFlowId": "default", "Status": "", "ContentType": "Image", "ContentId": "", "CallBackType": "Job", "Metadata": { "adultscore": "0.xxx", "a": "False", "racyscore": "0.xxx", "r": "True" } } Review Completion CallBack Sample { "ReviewId": "", "ModifiedOn": "2016-10-11T22:36:32.9934851Z", "ModifiedBy": "", "CallBackType": "Review", "ContentId": "", "Metadata": { "adultscore": "0.xxx", "a": "False", "racyscore": "0.xxx", "r": "True" }, "ReviewerResultTags": { "a": "False", "r": "True" } } .
#
# POST /contentmoderator/review/v1.0/teams/{teamName}/jobs
# Returns: record<JobId: string>
# operationId: Reviews_CreateJob
export def "reviews-create-job" [
  team_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --content-type: string@content-type-completer-1 # Image, Text or Video. (required)
  --content-id: string # Id/Name to identify the content submitted. (required)
  --workflow-name: string # Workflow Name that you want to invoke. (required)
  --call-back-endpoint: string # Callback endpoint for posting the create job result.
  --hdr-content-type: string@content-type-completer-2 # The content type. (required) (spec name: Content-Type)
  content_value: string # Content to evaluate for a job.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contentmoderator/review/v1.0/teams/{teamName}/jobs"
    path_params: [{name: teamName, var: team_name}]
    query: [{name: ContentType, var: content_type, required: true}, {name: ContentId, var: content_id, required: true}, {name: WorkflowName, var: workflow_name, required: true}, {name: CallBackEndpoint, var: call_back_endpoint}]
    header: [{name: Content-Type, var: hdr_content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: ContentValue, var: content_value}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    team_name: $team_name, content_type: $content_type, content_id: $content_id, workflow_name: $workflow_name, call_back_endpoint: $call_back_endpoint, hdr_content_type: $hdr_content_type, content_value: $content_value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the Job Details for a Job Id.
#
# GET /contentmoderator/review/v1.0/teams/{teamName}/jobs/{JobId}
# Returns: record<CallBackEndpoint: string, Id: string, JobExecutionReport: table<Msg: string, Ts: string>, ResultMetaData: table<Key: string, Value: string>, ReviewId: string, Status: string, TeamName: string, Type: string, WorkflowId: string>
# operationId: Reviews_GetJobDetails
export def "reviews-get-job-details" [
  team_name: string
  job_id: string
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
    path: "/contentmoderator/review/v1.0/teams/{teamName}/jobs/{JobId}"
    path_params: [{name: teamName, var: team_name}, {name: JobId, var: job_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    team_name: $team_name, job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The reviews created would show up for Reviewers on your team. As Reviewers complete reviewing, results of the Review would be POSTED (i.e. HTTP POST) on the specified CallBackEndpoint. CallBack Schemas Review Completion CallBack Sample { "ReviewId": "", "ModifiedOn": "2016-10-11T22:36:32.9934851Z", "ModifiedBy": "", "CallBackType": "Review", "ContentId": "", "Metadata": { "adultscore": "0.xxx", "a": "False", "racyscore": "0.xxx", "r": "True" }, "ReviewerResultTags": { "a": "False", "r": "True" } } .
#
# POST /contentmoderator/review/v1.0/teams/{teamName}/reviews
# Returns: list<string>
# operationId: Reviews_CreateReviews
export def "reviews-create-reviews" [
  team_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sub-team: string # SubTeam of your team, you want to assign the created review to.
  --url-content-type: string # The content type. (required)
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contentmoderator/review/v1.0/teams/{teamName}/reviews"
    path_params: [{name: teamName, var: team_name}]
    query: [{name: subTeam, var: sub_team}]
    header: [{name: UrlContentType, var: url_content_type, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    team_name: $team_name, sub_team: $sub_team, url_content_type: $url_content_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns review details for the review Id passed.
#
# GET /contentmoderator/review/v1.0/teams/{teamName}/reviews/{reviewId}
# Returns: record<CallbackEndpoint: string, Content: string, ContentId: string, CreatedBy: string, Metadata: table<Key: string, Value: string>, ReviewId: string, ReviewerResultTags: table<Key: string, Value: string>, Status: string, SubTeam: string, Type: string>
# operationId: Reviews_GetReview
export def "reviews-get-review" [
  team_name: string
  review_id: string
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
    path: "/contentmoderator/review/v1.0/teams/{teamName}/reviews/{reviewId}"
    path_params: [{name: teamName, var: team_name}, {name: reviewId, var: review_id}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    team_name: $team_name, review_id: $review_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The reviews created would show up for Reviewers on your team. As Reviewers complete reviewing, results of the Review would be POSTED (i.e. HTTP POST) on the specified CallBackEndpoint. CallBack Schemas Review Completion CallBack Sample { "ReviewId": "", "ModifiedOn": "2016-10-11T22:36:32.9934851Z", "ModifiedBy": "", "CallBackType": "Review", "ContentId": "", "Metadata": { "adultscore": "0.xxx", "a": "False", "racyscore": "0.xxx", "r": "True" }, "ReviewerResultTags": { "a": "False", "r": "True" } } .
#
# GET /contentmoderator/review/v1.0/teams/{teamName}/reviews/{reviewId}/frames
# Returns: record<ReviewId: string, VideoFrames: table<FrameImage: string, Metadata: list, ReviewerResultTags: list, Timestamp: string>>
# operationId: Reviews_GetVideoFrames
export def "reviews-get-video-frames" [
  team_name: string
  review_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-seed: int # Time stamp of the frame from where you want to start fetching the frames.
  --no-of-records: int # Number of frames to fetch.
  --filter: string # Get frames filtered by tags.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contentmoderator/review/v1.0/teams/{teamName}/reviews/{reviewId}/frames"
    path_params: [{name: teamName, var: team_name}, {name: reviewId, var: review_id}]
    query: [{name: startSeed, var: start_seed}, {name: noOfRecords, var: no_of_records}, {name: filter, var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    team_name: $team_name, review_id: $review_id, start_seed: $start_seed, no_of_records: $no_of_records, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The reviews created would show up for Reviewers on your team. As Reviewers complete reviewing, results of the Review would be POSTED (i.e. HTTP POST) on the specified CallBackEndpoint. CallBack Schemas Review Completion CallBack Sample { "ReviewId": "", "ModifiedOn": "2016-10-11T22:36:32.9934851Z", "ModifiedBy": "", "CallBackType": "Review", "ContentId": "", "Metadata": { "adultscore": "0.xxx", "a": "False", "racyscore": "0.xxx", "r": "True" }, "ReviewerResultTags": { "a": "False", "r": "True" } } .
#
# POST /contentmoderator/review/v1.0/teams/{teamName}/reviews/{reviewId}/frames
# operationId: Reviews_AddVideoFrame
export def "reviews-add-video-frame" [
  team_name: string
  review_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timescale: int # Timescale of the video you are adding frames to.
]: nothing -> any {
  http-request {
    method: post
    path: "/contentmoderator/review/v1.0/teams/{teamName}/reviews/{reviewId}/frames"
    path_params: [{name: teamName, var: team_name}, {name: reviewId, var: review_id}]
    query: [{name: timescale, var: timescale}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    team_name: $team_name, review_id: $review_id, timescale: $timescale
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Publish video review to make it available for review.
#
# POST /contentmoderator/review/v1.0/teams/{teamName}/reviews/{reviewId}/publish
# operationId: Reviews_PublishVideoReview
export def "reviews-publish-video-review" [
  team_name: string
  review_id: string
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
    path: "/contentmoderator/review/v1.0/teams/{teamName}/reviews/{reviewId}/publish"
    path_params: [{name: teamName, var: team_name}, {name: reviewId, var: review_id}]
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    team_name: $team_name, review_id: $review_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API adds a transcript file (text version of all the words spoken in a video) to a video review. The file should be a valid WebVTT format.
#
# PUT /contentmoderator/review/v1.0/teams/{teamName}/reviews/{reviewId}/transcript
# operationId: Reviews_AddVideoTranscript
export def "reviews-add-video-transcript" [
  team_name: string
  review_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string@content-type-completer-3 # The content type. (required)
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/contentmoderator/review/v1.0/teams/{teamName}/reviews/{reviewId}/transcript"
    path_params: [{name: teamName, var: team_name}, {name: reviewId, var: review_id}]
    header: [{name: Content-Type, var: content_type, required: true, default: "text/plain"}]
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    team_name: $team_name, review_id: $review_id, content_type: $content_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API adds a transcript screen text result file for a video review. Transcript screen text result file is a result of Screen Text API . In order to generate transcript screen text result file , a transcript file has to be screened for profanity using Screen Text API.
#
# PUT /contentmoderator/review/v1.0/teams/{teamName}/reviews/{reviewId}/transcriptmoderationresult
# operationId: Reviews_AddVideoTranscriptModerationResult
export def "reviews-add-video-transcript-moderation-result" [
  team_name: string
  review_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The content type. (required)
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/contentmoderator/review/v1.0/teams/{teamName}/reviews/{reviewId}/transcriptmoderationresult"
    path_params: [{name: teamName, var: team_name}, {name: reviewId, var: review_id}]
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [204]
    auth: ocp-apim-subscription-key
  } {
    team_name: $team_name, review_id: $review_id, content_type: $content_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
