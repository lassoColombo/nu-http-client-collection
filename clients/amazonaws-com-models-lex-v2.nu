# Auto-generated client for Amazon Lex Model Building V2 v2020-08-07
# Source: https://api.apis.guru/v2/specs/amazonaws.com/models.lex.v2/2020-08-07/openapi.json
# Auth: --token flag or $env.AMAZON_LEX_MODEL_BUILDING_V2_TOKEN

const CLIENT = {
  base_url: "http://models-v2-lex.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_LEX_MODEL_BUILDING_V2_TOKEN"
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

def base-url-completer [] { ["http://models-v2-lex.us-east-1.amazonaws.com" "http://models-v2-lex.us-east-2.amazonaws.com" "http://models-v2-lex.us-west-1.amazonaws.com" "http://models-v2-lex.us-west-2.amazonaws.com" "http://models-v2-lex.us-gov-west-1.amazonaws.com" "http://models-v2-lex.us-gov-east-1.amazonaws.com" "http://models-v2-lex.ca-central-1.amazonaws.com" "http://models-v2-lex.eu-north-1.amazonaws.com" "http://models-v2-lex.eu-west-1.amazonaws.com" "http://models-v2-lex.eu-west-2.amazonaws.com" "http://models-v2-lex.eu-west-3.amazonaws.com" "http://models-v2-lex.eu-central-1.amazonaws.com" "http://models-v2-lex.eu-south-1.amazonaws.com" "http://models-v2-lex.af-south-1.amazonaws.com" "http://models-v2-lex.ap-northeast-1.amazonaws.com" "http://models-v2-lex.ap-northeast-2.amazonaws.com" "http://models-v2-lex.ap-northeast-3.amazonaws.com" "http://models-v2-lex.ap-southeast-1.amazonaws.com" "http://models-v2-lex.ap-southeast-2.amazonaws.com" "http://models-v2-lex.ap-east-1.amazonaws.com" "http://models-v2-lex.ap-south-1.amazonaws.com" "http://models-v2-lex.sa-east-1.amazonaws.com" "http://models-v2-lex.me-south-1.amazonaws.com" "https://models-v2-lex.us-east-1.amazonaws.com" "https://models-v2-lex.us-east-2.amazonaws.com" "https://models-v2-lex.us-west-1.amazonaws.com" "https://models-v2-lex.us-west-2.amazonaws.com" "https://models-v2-lex.us-gov-west-1.amazonaws.com" "https://models-v2-lex.us-gov-east-1.amazonaws.com" "https://models-v2-lex.ca-central-1.amazonaws.com" "https://models-v2-lex.eu-north-1.amazonaws.com" "https://models-v2-lex.eu-west-1.amazonaws.com" "https://models-v2-lex.eu-west-2.amazonaws.com" "https://models-v2-lex.eu-west-3.amazonaws.com" "https://models-v2-lex.eu-central-1.amazonaws.com" "https://models-v2-lex.eu-south-1.amazonaws.com" "https://models-v2-lex.af-south-1.amazonaws.com" "https://models-v2-lex.ap-northeast-1.amazonaws.com" "https://models-v2-lex.ap-northeast-2.amazonaws.com" "https://models-v2-lex.ap-northeast-3.amazonaws.com" "https://models-v2-lex.ap-southeast-1.amazonaws.com" "https://models-v2-lex.ap-southeast-2.amazonaws.com" "https://models-v2-lex.ap-east-1.amazonaws.com" "https://models-v2-lex.ap-south-1.amazonaws.com" "https://models-v2-lex.sa-east-1.amazonaws.com" "https://models-v2-lex.me-south-1.amazonaws.com" "http://models-v2-lex.cn-north-1.amazonaws.com.cn" "http://models-v2-lex.cn-northwest-1.amazonaws.com.cn" "https://models-v2-lex.cn-north-1.amazonaws.com.cn" "https://models-v2-lex.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def bot-type-completer [] { ["Bot" "BotNetwork"] }
def file-format-completer [] { ["LexJson" "TSV"] }
def effect-completer [] { ["Allow" "Deny"] }
def merge-strategy-completer [] { ["Append" "FailOnConflict" "Overwrite"] }
def search-order-completer [] { ["Ascending" "Descending"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    batch-create-custom-vocabulary-item: "record<botId: string, botVersion: string, localeId: string, errors: table<itemId: string, errorMessage: string, errorCode: string>, resources: table<itemId: string, phrase: string, weight: int, displayAs: string>>"
    batch-delete-custom-vocabulary-item: "record<botId: string, botVersion: string, localeId: string, errors: table<itemId: string, errorMessage: string, errorCode: string>, resources: table<itemId: string, phrase: string, weight: int, displayAs: string>>"
    batch-update-custom-vocabulary-item: "record<botId: string, botVersion: string, localeId: string, errors: table<itemId: string, errorMessage: string, errorCode: string>, resources: table<itemId: string, phrase: string, weight: int, displayAs: string>>"
    build-bot-locale: "record<botId: string, botVersion: string, localeId: string, botLocaleStatus: string, lastBuildSubmittedDateTime: string>"
    delete-bot-locale: "record<botId: string, botVersion: string, localeId: string, botLocaleStatus: string>"
    describe-bot-locale: "record<botId: string, botVersion: string, localeId: string, localeName: string, description: string, nluIntentConfidenceThreshold: float, voiceSettings: record<voiceId: string, engine: string>, intentsCount: int, slotTypesCount: int, botLocaleStatus: string, failureReasons: list<string>, creationDateTime: string, lastUpdatedDateTime: string, lastBuildSubmittedDateTime: string, botLocaleHistoryEvents: table<event: string, eventDate: string>, recommendedActions: list<string>>"
    update-bot-locale: "record<botId: string, botVersion: string, localeId: string, localeName: string, description: string, nluIntentConfidenceThreshold: float, voiceSettings: record<voiceId: string, engine: string>, botLocaleStatus: string, failureReasons: list<string>, creationDateTime: string, lastUpdatedDateTime: string, recommendedActions: list<string>>"
    create-bot: "record<botId: string, botName: string, description: string, roleArn: string, dataPrivacy: record<childDirected: bool>, idleSessionTTLInSeconds: int, botStatus: string, creationDateTime: string, botTags: record, testBotAliasTags: record, botType: string, botMembers: table<botMemberId: string, botMemberName: string, botMemberAliasId: string, botMemberAliasName: string, botMemberVersion: string>>"
    list-bots: "record<botSummaries: table<botId: string, botName: string, description: string, botStatus: string, latestBotVersion: string, lastUpdatedDateTime: string, botType: string>, nextToken: string>"
    create-bot-alias: "record<botAliasId: string, botAliasName: string, description: string, botVersion: string, botAliasLocaleSettings: record, conversationLogSettings: record<textLogSettings: list<record>, audioLogSettings: list<record>>, sentimentAnalysisSettings: record<detectSentiment: bool>, botAliasStatus: string, botId: string, creationDateTime: string, tags: record>"
    list-bot-aliases: "record<botAliasSummaries: table<botAliasId: string, botAliasName: string, description: string, botVersion: string, botAliasStatus: string, creationDateTime: string, lastUpdatedDateTime: string>, nextToken: string, botId: string>"
    create-bot-locale: "record<botId: string, botVersion: string, localeName: string, localeId: string, description: string, nluIntentConfidenceThreshold: float, voiceSettings: record<voiceId: string, engine: string>, botLocaleStatus: string, creationDateTime: string>"
    list-bot-locales: "record<botId: string, botVersion: string, nextToken: string, botLocaleSummaries: table<localeId: string, localeName: string, description: string, botLocaleStatus: string, lastUpdatedDateTime: string, lastBuildSubmittedDateTime: string>>"
    create-bot-version: "record<botId: string, description: string, botVersion: string, botVersionLocaleSpecification: record, botStatus: string, creationDateTime: string>"
    list-bot-versions: "record<botId: string, botVersionSummaries: table<botName: string, botVersion: string, description: string, botStatus: string, creationDateTime: string>, nextToken: string>"
    create-export: "record<exportId: string, resourceSpecification: record<botExportSpecification: record<botId: string, botVersion: string>, botLocaleExportSpecification: record<botId: string, botVersion: string, localeId: string>, customVocabularyExportSpecification: record<botId: string, botVersion: string, localeId: string>>, fileFormat: string, exportStatus: string, creationDateTime: string>"
    list-exports: "record<botId: string, botVersion: string, exportSummaries: table<exportId: string, resourceSpecification: record, fileFormat: string, exportStatus: string, creationDateTime: string, lastUpdatedDateTime: string>, nextToken: string, localeId: string>"
    create-intent: "record<intentId: string, intentName: string, description: string, parentIntentSignature: string, sampleUtterances: table<utterance: string>, dialogCodeHook: record<enabled: bool>, fulfillmentCodeHook: record<enabled: bool, postFulfillmentStatusSpecification: record<successResponse: record, failureResponse: record, timeoutResponse: record, successNextStep: record, successConditional: record, failureNextStep: record, failureConditional: record, timeoutNextStep: record, timeoutConditional: record>, fulfillmentUpdatesSpecification: record<active: bool, startResponse: record, updateResponse: record, timeoutInSeconds: int>, active: bool>, intentConfirmationSetting: record<promptSpecification: record<messageGroups: list, maxRetries: int, allowInterrupt: bool, messageSelectionStrategy: string, promptAttemptsSpecification: record>, declinationResponse: record<messageGroups: list, allowInterrupt: bool>, active: bool, confirmationResponse: record<messageGroups: list, allowInterrupt: bool>, confirmationNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, confirmationConditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, declinationNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, declinationConditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, failureResponse: record<messageGroups: list, allowInterrupt: bool>, failureNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, failureConditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, codeHook: record<enableCodeHookInvocation: bool, active: bool, invocationLabel: string, postCodeHookSpecification: record>, elicitationCodeHook: record<enableCodeHookInvocation: bool, invocationLabel: string>>, intentClosingSetting: record<closingResponse: record<messageGroups: list, allowInterrupt: bool>, active: bool, nextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, conditional: record<active: bool, conditionalBranches: list, defaultBranch: record>>, inputContexts: table<name: string>, outputContexts: table<name: string, timeToLiveInSeconds: int, turnsToLive: int>, kendraConfiguration: record<kendraIndex: string, queryFilterStringEnabled: bool, queryFilterString: string>, botId: string, botVersion: string, localeId: string, creationDateTime: string, initialResponseSetting: record<initialResponse: record<messageGroups: list, allowInterrupt: bool>, nextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, conditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, codeHook: record<enableCodeHookInvocation: bool, active: bool, invocationLabel: string, postCodeHookSpecification: record>>>"
    list-intents: "record<botId: string, botVersion: string, localeId: string, intentSummaries: table<intentId: string, intentName: string, description: string, parentIntentSignature: string, inputContexts: list, outputContexts: list, lastUpdatedDateTime: string>, nextToken: string>"
    create-resource-policy: "record<resourceArn: string, revisionId: string>"
    delete-resource-policy: "record<resourceArn: string, revisionId: string>"
    describe-resource-policy: "record<resourceArn: string, policy: string, revisionId: string>"
    update-resource-policy: "record<resourceArn: string, revisionId: string>"
    create-resource-policy-statement: "record<resourceArn: string, revisionId: string>"
    create-slot: "record<slotId: string, slotName: string, description: string, slotTypeId: string, valueElicitationSetting: record<defaultValueSpecification: record<defaultValueList: list>, slotConstraint: string, promptSpecification: record<messageGroups: list, maxRetries: int, allowInterrupt: bool, messageSelectionStrategy: string, promptAttemptsSpecification: record>, sampleUtterances: list<record>, waitAndContinueSpecification: record<waitingResponse: record, continueResponse: record, stillWaitingResponse: record, active: bool>, slotCaptureSetting: record<captureResponse: record, captureNextStep: record, captureConditional: record, failureResponse: record, failureNextStep: record, failureConditional: record, codeHook: record, elicitationCodeHook: record>>, obfuscationSetting: record<obfuscationSettingType: string>, botId: string, botVersion: string, localeId: string, intentId: string, creationDateTime: string, multipleValuesSetting: record<allowMultipleValues: bool>, subSlotSetting: record<expression: string, slotSpecifications: record>>"
    list-slots: "record<botId: string, botVersion: string, localeId: string, intentId: string, slotSummaries: table<slotId: string, slotName: string, description: string, slotConstraint: string, slotTypeId: string, valueElicitationPromptSpecification: record, lastUpdatedDateTime: string>, nextToken: string>"
    create-slot-type: "record<slotTypeId: string, slotTypeName: string, description: string, slotTypeValues: table<sampleValue: record, synonyms: list>, valueSelectionSetting: record<resolutionStrategy: string, regexFilter: record<pattern: string>, advancedRecognitionSetting: record<audioRecognitionStrategy: string>>, parentSlotTypeSignature: string, botId: string, botVersion: string, localeId: string, creationDateTime: string, externalSourceSetting: record<grammarSlotTypeSetting: record<source: record>>, compositeSlotTypeSetting: record<subSlots: list<record>>>"
    list-slot-types: "record<botId: string, botVersion: string, localeId: string, slotTypeSummaries: table<slotTypeId: string, slotTypeName: string, description: string, parentSlotTypeSignature: string, lastUpdatedDateTime: string, slotTypeCategory: string>, nextToken: string>"
    create-upload-url: "record<importId: string, uploadUrl: string>"
    delete-bot: "record<botId: string, botStatus: string>"
    describe-bot: "record<botId: string, botName: string, description: string, roleArn: string, dataPrivacy: record<childDirected: bool>, idleSessionTTLInSeconds: int, botStatus: string, creationDateTime: string, lastUpdatedDateTime: string, botType: string, botMembers: table<botMemberId: string, botMemberName: string, botMemberAliasId: string, botMemberAliasName: string, botMemberVersion: string>, failureReasons: list<string>>"
    update-bot: "record<botId: string, botName: string, description: string, roleArn: string, dataPrivacy: record<childDirected: bool>, idleSessionTTLInSeconds: int, botStatus: string, creationDateTime: string, lastUpdatedDateTime: string, botType: string, botMembers: table<botMemberId: string, botMemberName: string, botMemberAliasId: string, botMemberAliasName: string, botMemberVersion: string>>"
    delete-bot-alias: "record<botAliasId: string, botId: string, botAliasStatus: string>"
    describe-bot-alias: "record<botAliasId: string, botAliasName: string, description: string, botVersion: string, botAliasLocaleSettings: record, conversationLogSettings: record<textLogSettings: list<record>, audioLogSettings: list<record>>, sentimentAnalysisSettings: record<detectSentiment: bool>, botAliasHistoryEvents: table<botVersion: string, startDate: string, endDate: string>, botAliasStatus: string, botId: string, creationDateTime: string, lastUpdatedDateTime: string, parentBotNetworks: table<botId: string, botVersion: string>>"
    update-bot-alias: "record<botAliasId: string, botAliasName: string, description: string, botVersion: string, botAliasLocaleSettings: record, conversationLogSettings: record<textLogSettings: list<record>, audioLogSettings: list<record>>, sentimentAnalysisSettings: record<detectSentiment: bool>, botAliasStatus: string, botId: string, creationDateTime: string, lastUpdatedDateTime: string>"
    delete-bot-version: "record<botId: string, botVersion: string, botStatus: string>"
    describe-bot-version: "record<botId: string, botName: string, botVersion: string, description: string, roleArn: string, dataPrivacy: record<childDirected: bool>, idleSessionTTLInSeconds: int, botStatus: string, failureReasons: list<string>, creationDateTime: string, parentBotNetworks: table<botId: string, botVersion: string>, botType: string, botMembers: table<botMemberId: string, botMemberName: string, botMemberAliasId: string, botMemberAliasName: string, botMemberVersion: string>>"
    delete-custom-vocabulary: "record<botId: string, botVersion: string, localeId: string, customVocabularyStatus: string>"
    delete-export: "record<exportId: string, exportStatus: string>"
    describe-export: "record<exportId: string, resourceSpecification: record<botExportSpecification: record<botId: string, botVersion: string>, botLocaleExportSpecification: record<botId: string, botVersion: string, localeId: string>, customVocabularyExportSpecification: record<botId: string, botVersion: string, localeId: string>>, fileFormat: string, exportStatus: string, failureReasons: list<string>, downloadUrl: string, creationDateTime: string, lastUpdatedDateTime: string>"
    update-export: "record<exportId: string, resourceSpecification: record<botExportSpecification: record<botId: string, botVersion: string>, botLocaleExportSpecification: record<botId: string, botVersion: string, localeId: string>, customVocabularyExportSpecification: record<botId: string, botVersion: string, localeId: string>>, fileFormat: string, exportStatus: string, creationDateTime: string, lastUpdatedDateTime: string>"
    delete-import: "record<importId: string, importStatus: string>"
    describe-import: "record<importId: string, resourceSpecification: record<botImportSpecification: record<botName: string, roleArn: string, dataPrivacy: record, idleSessionTTLInSeconds: int, botTags: record, testBotAliasTags: record>, botLocaleImportSpecification: record<botId: string, botVersion: string, localeId: string, nluIntentConfidenceThreshold: float, voiceSettings: record>, customVocabularyImportSpecification: record<botId: string, botVersion: string, localeId: string>>, importedResourceId: string, importedResourceName: string, mergeStrategy: string, importStatus: string, failureReasons: list<string>, creationDateTime: string, lastUpdatedDateTime: string>"
    describe-intent: "record<intentId: string, intentName: string, description: string, parentIntentSignature: string, sampleUtterances: table<utterance: string>, dialogCodeHook: record<enabled: bool>, fulfillmentCodeHook: record<enabled: bool, postFulfillmentStatusSpecification: record<successResponse: record, failureResponse: record, timeoutResponse: record, successNextStep: record, successConditional: record, failureNextStep: record, failureConditional: record, timeoutNextStep: record, timeoutConditional: record>, fulfillmentUpdatesSpecification: record<active: bool, startResponse: record, updateResponse: record, timeoutInSeconds: int>, active: bool>, slotPriorities: table<priority: int, slotId: string>, intentConfirmationSetting: record<promptSpecification: record<messageGroups: list, maxRetries: int, allowInterrupt: bool, messageSelectionStrategy: string, promptAttemptsSpecification: record>, declinationResponse: record<messageGroups: list, allowInterrupt: bool>, active: bool, confirmationResponse: record<messageGroups: list, allowInterrupt: bool>, confirmationNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, confirmationConditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, declinationNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, declinationConditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, failureResponse: record<messageGroups: list, allowInterrupt: bool>, failureNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, failureConditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, codeHook: record<enableCodeHookInvocation: bool, active: bool, invocationLabel: string, postCodeHookSpecification: record>, elicitationCodeHook: record<enableCodeHookInvocation: bool, invocationLabel: string>>, intentClosingSetting: record<closingResponse: record<messageGroups: list, allowInterrupt: bool>, active: bool, nextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, conditional: record<active: bool, conditionalBranches: list, defaultBranch: record>>, inputContexts: table<name: string>, outputContexts: table<name: string, timeToLiveInSeconds: int, turnsToLive: int>, kendraConfiguration: record<kendraIndex: string, queryFilterStringEnabled: bool, queryFilterString: string>, botId: string, botVersion: string, localeId: string, creationDateTime: string, lastUpdatedDateTime: string, initialResponseSetting: record<initialResponse: record<messageGroups: list, allowInterrupt: bool>, nextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, conditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, codeHook: record<enableCodeHookInvocation: bool, active: bool, invocationLabel: string, postCodeHookSpecification: record>>>"
    update-intent: "record<intentId: string, intentName: string, description: string, parentIntentSignature: string, sampleUtterances: table<utterance: string>, dialogCodeHook: record<enabled: bool>, fulfillmentCodeHook: record<enabled: bool, postFulfillmentStatusSpecification: record<successResponse: record, failureResponse: record, timeoutResponse: record, successNextStep: record, successConditional: record, failureNextStep: record, failureConditional: record, timeoutNextStep: record, timeoutConditional: record>, fulfillmentUpdatesSpecification: record<active: bool, startResponse: record, updateResponse: record, timeoutInSeconds: int>, active: bool>, slotPriorities: table<priority: int, slotId: string>, intentConfirmationSetting: record<promptSpecification: record<messageGroups: list, maxRetries: int, allowInterrupt: bool, messageSelectionStrategy: string, promptAttemptsSpecification: record>, declinationResponse: record<messageGroups: list, allowInterrupt: bool>, active: bool, confirmationResponse: record<messageGroups: list, allowInterrupt: bool>, confirmationNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, confirmationConditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, declinationNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, declinationConditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, failureResponse: record<messageGroups: list, allowInterrupt: bool>, failureNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, failureConditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, codeHook: record<enableCodeHookInvocation: bool, active: bool, invocationLabel: string, postCodeHookSpecification: record>, elicitationCodeHook: record<enableCodeHookInvocation: bool, invocationLabel: string>>, intentClosingSetting: record<closingResponse: record<messageGroups: list, allowInterrupt: bool>, active: bool, nextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, conditional: record<active: bool, conditionalBranches: list, defaultBranch: record>>, inputContexts: table<name: string>, outputContexts: table<name: string, timeToLiveInSeconds: int, turnsToLive: int>, kendraConfiguration: record<kendraIndex: string, queryFilterStringEnabled: bool, queryFilterString: string>, botId: string, botVersion: string, localeId: string, creationDateTime: string, lastUpdatedDateTime: string, initialResponseSetting: record<initialResponse: record<messageGroups: list, allowInterrupt: bool>, nextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, conditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, codeHook: record<enableCodeHookInvocation: bool, active: bool, invocationLabel: string, postCodeHookSpecification: record>>>"
    delete-resource-policy-statement: "record<resourceArn: string, revisionId: string>"
    describe-slot: "record<slotId: string, slotName: string, description: string, slotTypeId: string, valueElicitationSetting: record<defaultValueSpecification: record<defaultValueList: list>, slotConstraint: string, promptSpecification: record<messageGroups: list, maxRetries: int, allowInterrupt: bool, messageSelectionStrategy: string, promptAttemptsSpecification: record>, sampleUtterances: list<record>, waitAndContinueSpecification: record<waitingResponse: record, continueResponse: record, stillWaitingResponse: record, active: bool>, slotCaptureSetting: record<captureResponse: record, captureNextStep: record, captureConditional: record, failureResponse: record, failureNextStep: record, failureConditional: record, codeHook: record, elicitationCodeHook: record>>, obfuscationSetting: record<obfuscationSettingType: string>, botId: string, botVersion: string, localeId: string, intentId: string, creationDateTime: string, lastUpdatedDateTime: string, multipleValuesSetting: record<allowMultipleValues: bool>, subSlotSetting: record<expression: string, slotSpecifications: record>>"
    update-slot: "record<slotId: string, slotName: string, description: string, slotTypeId: string, valueElicitationSetting: record<defaultValueSpecification: record<defaultValueList: list>, slotConstraint: string, promptSpecification: record<messageGroups: list, maxRetries: int, allowInterrupt: bool, messageSelectionStrategy: string, promptAttemptsSpecification: record>, sampleUtterances: list<record>, waitAndContinueSpecification: record<waitingResponse: record, continueResponse: record, stillWaitingResponse: record, active: bool>, slotCaptureSetting: record<captureResponse: record, captureNextStep: record, captureConditional: record, failureResponse: record, failureNextStep: record, failureConditional: record, codeHook: record, elicitationCodeHook: record>>, obfuscationSetting: record<obfuscationSettingType: string>, botId: string, botVersion: string, localeId: string, intentId: string, creationDateTime: string, lastUpdatedDateTime: string, multipleValuesSetting: record<allowMultipleValues: bool>, subSlotSetting: record<expression: string, slotSpecifications: record>>"
    describe-slot-type: "record<slotTypeId: string, slotTypeName: string, description: string, slotTypeValues: table<sampleValue: record, synonyms: list>, valueSelectionSetting: record<resolutionStrategy: string, regexFilter: record<pattern: string>, advancedRecognitionSetting: record<audioRecognitionStrategy: string>>, parentSlotTypeSignature: string, botId: string, botVersion: string, localeId: string, creationDateTime: string, lastUpdatedDateTime: string, externalSourceSetting: record<grammarSlotTypeSetting: record<source: record>>, compositeSlotTypeSetting: record<subSlots: list<record>>>"
    update-slot-type: "record<slotTypeId: string, slotTypeName: string, description: string, slotTypeValues: table<sampleValue: record, synonyms: list>, valueSelectionSetting: record<resolutionStrategy: string, regexFilter: record<pattern: string>, advancedRecognitionSetting: record<audioRecognitionStrategy: string>>, parentSlotTypeSignature: string, botId: string, botVersion: string, localeId: string, creationDateTime: string, lastUpdatedDateTime: string, externalSourceSetting: record<grammarSlotTypeSetting: record<source: record>>, compositeSlotTypeSetting: record<subSlots: list<record>>>"
    delete-utterances: "record"
    describe-bot-recommendation: "record<botId: string, botVersion: string, localeId: string, botRecommendationStatus: string, botRecommendationId: string, failureReasons: list<string>, creationDateTime: string, lastUpdatedDateTime: string, transcriptSourceSetting: record<s3BucketTranscriptSource: record<s3BucketName: string, pathFormat: record, transcriptFormat: string, transcriptFilter: record, kmsKeyArn: string>>, encryptionSetting: record<kmsKeyArn: string, botLocaleExportPassword: string, associatedTranscriptsPassword: string>, botRecommendationResults: record<botLocaleExportUrl: string, associatedTranscriptsUrl: string, statistics: record<intents: record, slotTypes: record>>>"
    update-bot-recommendation: "record<botId: string, botVersion: string, localeId: string, botRecommendationStatus: string, botRecommendationId: string, creationDateTime: string, lastUpdatedDateTime: string, transcriptSourceSetting: record<s3BucketTranscriptSource: record<s3BucketName: string, pathFormat: record, transcriptFormat: string, transcriptFilter: record, kmsKeyArn: string>>, encryptionSetting: record<kmsKeyArn: string, botLocaleExportPassword: string, associatedTranscriptsPassword: string>>"
    describe-custom-vocabulary-metadata: "record<botId: string, botVersion: string, localeId: string, customVocabularyStatus: string, creationDateTime: string, lastUpdatedDateTime: string>"
    list-aggregated-utterances: "record<botId: string, botAliasId: string, botVersion: string, localeId: string, aggregationDuration: record<relativeAggregationDuration: record<timeDimension: string, timeValue: int>>, aggregationWindowStartTime: string, aggregationWindowEndTime: string, aggregationLastRefreshedDateTime: string, aggregatedUtterancesSummaries: table<utterance: string, hitCount: int, missedCount: int, utteranceFirstRecordedInAggregationDuration: string, utteranceLastRecordedInAggregationDuration: string, containsDataFromDeletedResources: bool>, nextToken: string>"
    list-bot-recommendations: "record<botId: string, botVersion: string, localeId: string, botRecommendationSummaries: table<botRecommendationStatus: string, botRecommendationId: string, creationDateTime: string, lastUpdatedDateTime: string>, nextToken: string>"
    start-bot-recommendation: "record<botId: string, botVersion: string, localeId: string, botRecommendationStatus: string, botRecommendationId: string, creationDateTime: string, transcriptSourceSetting: record<s3BucketTranscriptSource: record<s3BucketName: string, pathFormat: record, transcriptFormat: string, transcriptFilter: record, kmsKeyArn: string>>, encryptionSetting: record<kmsKeyArn: string, botLocaleExportPassword: string, associatedTranscriptsPassword: string>>"
    list-built-in-intents: "record<builtInIntentSummaries: table<intentSignature: string, description: string>, nextToken: string, localeId: string>"
    list-built-in-slot-types: "record<builtInSlotTypeSummaries: table<slotTypeSignature: string, description: string>, nextToken: string, localeId: string>"
    list-custom-vocabulary-items: "record<botId: string, botVersion: string, localeId: string, customVocabularyItems: table<itemId: string, phrase: string, weight: int, displayAs: string>, nextToken: string>"
    list-imports: "record<botId: string, botVersion: string, importSummaries: table<importId: string, importedResourceId: string, importedResourceName: string, importStatus: string, mergeStrategy: string, creationDateTime: string, lastUpdatedDateTime: string, importedResourceType: string>, nextToken: string, localeId: string>"
    start-import: "record<importId: string, resourceSpecification: record<botImportSpecification: record<botName: string, roleArn: string, dataPrivacy: record, idleSessionTTLInSeconds: int, botTags: record, testBotAliasTags: record>, botLocaleImportSpecification: record<botId: string, botVersion: string, localeId: string, nluIntentConfidenceThreshold: float, voiceSettings: record>, customVocabularyImportSpecification: record<botId: string, botVersion: string, localeId: string>>, mergeStrategy: string, importStatus: string, creationDateTime: string>"
    list-recommended-intents: "record<botId: string, botVersion: string, localeId: string, botRecommendationId: string, summaryList: table<intentId: string, intentName: string, sampleUtterancesCount: int>, nextToken: string>"
    list-tags-for-resource: "record<tags: record>"
    tag-resource: "record"
    search-associated-transcripts: "record<botId: string, botVersion: string, localeId: string, botRecommendationId: string, nextIndex: int, associatedTranscripts: table<transcript: string>, totalResults: int>"
    stop-bot-recommendation: "record<botId: string, botVersion: string, localeId: string, botRecommendationStatus: string, botRecommendationId: string>"
    untag-resource: "record"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["batch-create-custom-vocabulary-item" "batch-delete-custom-vocabulary-item" "batch-update-custom-vocabulary-item" "build-bot-locale" "delete-bot-locale" "describe-bot-locale" "update-bot-locale" "create-bot" "list-bots" "create-bot-alias" "list-bot-aliases" "create-bot-locale" "list-bot-locales" "create-bot-version" "list-bot-versions" "create-export" "list-exports" "create-intent" "list-intents" "create-resource-policy" "delete-resource-policy" "describe-resource-policy" "update-resource-policy" "create-resource-policy-statement" "create-slot" "list-slots" "create-slot-type" "list-slot-types" "create-upload-url" "delete-bot" "describe-bot" "update-bot" "delete-bot-alias" "describe-bot-alias" "update-bot-alias" "delete-bot-version" "describe-bot-version" "delete-custom-vocabulary" "delete-export" "describe-export" "update-export" "delete-import" "describe-import" "delete-intent" "describe-intent" "update-intent" "delete-resource-policy-statement" "delete-slot" "describe-slot" "update-slot" "delete-slot-type" "describe-slot-type" "update-slot-type" "delete-utterances" "describe-bot-recommendation" "update-bot-recommendation" "describe-custom-vocabulary-metadata" "list-aggregated-utterances" "list-bot-recommendations" "start-bot-recommendation" "list-built-in-intents" "list-built-in-slot-types" "list-custom-vocabulary-items" "list-imports" "start-import" "list-recommended-intents" "list-tags-for-resource" "tag-resource" "search-associated-transcripts" "stop-bot-recommendation" "untag-resource" "commands"] | sort) } | get name | first)
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

# Create a batch of custom vocabulary items for a given bot locale's custom vocabulary.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/customvocabulary/DEFAULT/batchcreate
# Returns: record<botId: string, botVersion: string, localeId: string, errors: table<itemId: string, errorMessage: string, errorCode: string>, resources: table<itemId: string, phrase: string, weight: int, displayAs: string>>
# operationId: BatchCreateCustomVocabularyItem
export def "batch-create-custom-vocabulary-item" [
  bot_id: string
  bot_version: string
  locale_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  custom_vocabulary_item_list: list # A list of new custom vocabulary items. Each entry must contain a phrase and can optionally contain a displayAs and/or a weight. — item shape: {phrase: string, weight?: int, displayAs?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/customvocabulary/DEFAULT/batchcreate"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: customVocabularyItemList, var: custom_vocabulary_item_list}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, locale_id: $locale_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, custom_vocabulary_item_list: $custom_vocabulary_item_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a batch of custom vocabulary items for a given bot locale's custom vocabulary.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/customvocabulary/DEFAULT/batchdelete
# Returns: record<botId: string, botVersion: string, localeId: string, errors: table<itemId: string, errorMessage: string, errorCode: string>, resources: table<itemId: string, phrase: string, weight: int, displayAs: string>>
# operationId: BatchDeleteCustomVocabularyItem
export def "batch-delete-custom-vocabulary-item" [
  bot_id: string
  bot_version: string
  locale_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  custom_vocabulary_item_list: list # A list of custom vocabulary items requested to be deleted. Each entry must contain the unique custom vocabulary entry identifier. — item shape: {itemId: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/customvocabulary/DEFAULT/batchdelete"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: customVocabularyItemList, var: custom_vocabulary_item_list}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, locale_id: $locale_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, custom_vocabulary_item_list: $custom_vocabulary_item_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a batch of custom vocabulary items for a given bot locale's custom vocabulary.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/customvocabulary/DEFAULT/batchupdate
# Returns: record<botId: string, botVersion: string, localeId: string, errors: table<itemId: string, errorMessage: string, errorCode: string>, resources: table<itemId: string, phrase: string, weight: int, displayAs: string>>
# operationId: BatchUpdateCustomVocabularyItem
export def "batch-update-custom-vocabulary-item" [
  bot_id: string
  bot_version: string
  locale_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  custom_vocabulary_item_list: list # A list of custom vocabulary items with updated fields. Each entry must contain a phrase and can optionally contain a displayAs and/or a weight. — item shape: {itemId: string, phrase: string, weight?: int, displayAs?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/customvocabulary/DEFAULT/batchupdate"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: customVocabularyItemList, var: custom_vocabulary_item_list}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, locale_id: $locale_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, custom_vocabulary_item_list: $custom_vocabulary_item_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Builds a bot, its intents, and its slot types into a specific locale. A bot can be built into multiple locales. At runtime the locale is used to choose a specific build of the bot.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/
# Returns: record<botId: string, botVersion: string, localeId: string, botLocaleStatus: string, lastBuildSubmittedDateTime: string>
# operationId: BuildBotLocale
export def "build-bot-locale" [
  bot_id: string
  bot_version: string
  locale_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, locale_id: $locale_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a locale from a bot. When you delete a locale, all intents, slots, and slot types defined for the locale are also deleted.
#
# DELETE /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/
# Returns: record<botId: string, botVersion: string, localeId: string, botLocaleStatus: string>
# operationId: DeleteBotLocale
export def "delete-bot-locale" [
  bot_id: string
  bot_version: string
  locale_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, locale_id: $locale_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the settings that a bot has for a specific locale.
#
# GET /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/
# Returns: record<botId: string, botVersion: string, localeId: string, localeName: string, description: string, nluIntentConfidenceThreshold: float, voiceSettings: record<voiceId: string, engine: string>, intentsCount: int, slotTypesCount: int, botLocaleStatus: string, failureReasons: list<string>, creationDateTime: string, lastUpdatedDateTime: string, lastBuildSubmittedDateTime: string, botLocaleHistoryEvents: table<event: string, eventDate: string>, recommendedActions: list<string>>
# operationId: DescribeBotLocale
export def "describe-bot-locale" [
  bot_id: string
  bot_version: string
  locale_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, locale_id: $locale_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the settings that a bot has for a specific locale.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/
# Returns: record<botId: string, botVersion: string, localeId: string, localeName: string, description: string, nluIntentConfidenceThreshold: float, voiceSettings: record<voiceId: string, engine: string>, botLocaleStatus: string, failureReasons: list<string>, creationDateTime: string, lastUpdatedDateTime: string, recommendedActions: list<string>>
# operationId: UpdateBotLocale
export def "update-bot-locale" [
  bot_id: string
  bot_version: string
  locale_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # The new description of the locale.
  nlu_intent_confidence_threshold: float # The new confidence threshold where Amazon Lex inserts the AMAZON.FallbackIntent and AMAZON.KendraSearchIntent intents in the list of possible intents for an utterance. (format: double)
  --voice-settings: record # Defines settings for using an Amazon Polly voice to communicate with a user. — shape: {voiceId?: string, engine?: "standard"|"neural"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: nluIntentConfidenceThreshold, var: nlu_intent_confidence_threshold}, {name: voiceSettings, var: voice_settings}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, locale_id: $locale_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, nlu_intent_confidence_threshold: $nlu_intent_confidence_threshold, voice_settings: $voice_settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Amazon Lex conversational bot.
#
# PUT /bots/
# Returns: record<botId: string, botName: string, description: string, roleArn: string, dataPrivacy: record<childDirected: bool>, idleSessionTTLInSeconds: int, botStatus: string, creationDateTime: string, botTags: record, testBotAliasTags: record, botType: string, botMembers: table<botMemberId: string, botMemberName: string, botMemberAliasId: string, botMemberAliasName: string, botMemberVersion: string>>
# operationId: CreateBot
export def "create-bot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  bot_name: string # The name of the bot. The bot name must be unique in the account that creates the bot.
  --description: string # A description of the bot. It appears in lists to help you identify a particular bot.
  role_arn: string # The Amazon Resource Name (ARN) of an IAM role that has permission to access the bot.
  data_privacy: record # By default, data stored by Amazon Lex is encrypted. The DataPrivacy structure provides settings that determine how Amazon Lex handles special cases of securing the data for your bot. — shape: {childDirected?: bool}
  idle_session_ttl_in_seconds: int # The time, in seconds, that Amazon Lex should keep information about a user's conversation with the bot. A user interaction remains active for the amount of time specified. If no conversation occurs during this time, the session expires and Amazon Lex deletes any data provided before the timeout. You can specify between 60 (1 minute) and 86,400 (24 hours) seconds.
  --bot-tags: record # A list of tags to add to the bot. You can only add tags when you create a bot. You can't use the UpdateBot operation to update tags. To update tags, use the TagResource operation.
  --test-bot-alias-tags: record # A list of tags to add to the test alias for a bot. You can only add tags when you create a bot. You can't use the UpdateAlias operation to update tags. To update tags on the test alias, use the TagResource operation.
  --bot-type: string@bot-type-completer # The type of a bot to create.
  --bot-members: list # The list of bot members in a network to be created. — item shape: {botMemberId: string, botMemberName: string, botMemberAliasId: string, botMemberAliasName: string, botMemberVersion: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/bots/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: botName, var: bot_name}, {name: description, var: description}, {name: roleArn, var: role_arn}, {name: dataPrivacy, var: data_privacy}, {name: idleSessionTTLInSeconds, var: idle_session_ttl_in_seconds}, {name: botTags, var: bot_tags}, {name: testBotAliasTags, var: test_bot_alias_tags}, {name: botType, var: bot_type}, {name: botMembers, var: bot_members}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, bot_name: $bot_name, description: $description, role_arn: $role_arn, data_privacy: $data_privacy, idle_session_ttl_in_seconds: $idle_session_ttl_in_seconds, bot_tags: $bot_tags, test_bot_alias_tags: $test_bot_alias_tags, bot_type: $bot_type, bot_members: $bot_members
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of available bots.
#
# POST /bots/
# Returns: record<botSummaries: table<botId: string, botName: string, description: string, botStatus: string, latestBotVersion: string, lastUpdatedDateTime: string, botType: string>, nextToken: string>
# operationId: ListBots
export def "list-bots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --sort-by: record # Specifies attributes for sorting a list of bots. — shape: {attribute?: "BotName", order?: "Ascending"|"Descending"}
  --filters: list # Provides the specification of a filter used to limit the bots in the response to only those that match the filter specification. You can only specify one filter and one string to filter on. — item shape: {name: "BotName"|"BotType", values: list<string>, operator: "CO"|"EQ"|"NE"}
  --body-max-results: int # The maximum number of bots to return in each page of results. If there are fewer results than the maximum page size, only the actual number of results are returned. (spec name: maxResults)
  --body-next-token: string # If the response from the ListBots operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use the returned token in the nextToken parameter of a ListBots request to return the next page of results. For a complete set of results, call the ListBots operation until the nextToken returned in the response is null. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/bots/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: sortBy, var: sort_by}, {name: filters, var: filters}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, sort_by: $sort_by, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an alias for the specified version of a bot. Use an alias to enable you to change the version of a bot without updating applications that use the bot. For example, you can create an alias called "PROD" that your applications use to call the Amazon Lex bot.
#
# PUT /bots/{botId}/botaliases/
# Returns: record<botAliasId: string, botAliasName: string, description: string, botVersion: string, botAliasLocaleSettings: record, conversationLogSettings: record<textLogSettings: list<record>, audioLogSettings: list<record>>, sentimentAnalysisSettings: record<detectSentiment: bool>, botAliasStatus: string, botId: string, creationDateTime: string, tags: record>
# operationId: CreateBotAlias
export def "create-bot-alias" [
  bot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  bot_alias_name: string # The alias to create. The name must be unique for the bot.
  --description: string # A description of the alias. Use this description to help identify the alias.
  --bot-version: string # The version of the bot that this alias points to. You can use the UpdateBotAlias (https://docs.aws.amazon.com/lexv2/latest/APIReference/API_UpdateBotAlias.html) operation to change the bot version associated with the alias.
  --bot-alias-locale-settings: record # Maps configuration information to a specific locale. You can use this parameter to specify a specific Lambda function to run different functions in different locales.
  --conversation-log-settings: record # Configures conversation logging that saves audio, text, and metadata for the conversations with your users. — shape: {textLogSettings?: list, audioLogSettings?: list}
  --sentiment-analysis-settings: record # Determines whether Amazon Lex will use Amazon Comprehend to detect the sentiment of user utterances. — shape: {detectSentiment?: bool}
  --tags: record # A list of tags to add to the bot alias. You can only add tags when you create an alias, you can't use the UpdateBotAlias operation to update the tags on a bot alias. To update tags, use the TagResource operation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/bots/{botId}/botaliases/"
    path_params: [{name: botId, var: bot_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: botAliasName, var: bot_alias_name}, {name: description, var: description}, {name: botVersion, var: bot_version}, {name: botAliasLocaleSettings, var: bot_alias_locale_settings}, {name: conversationLogSettings, var: conversation_log_settings}, {name: sentimentAnalysisSettings, var: sentiment_analysis_settings}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    bot_id: $bot_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, bot_alias_name: $bot_alias_name, description: $description, bot_version: $bot_version, bot_alias_locale_settings: $bot_alias_locale_settings, conversation_log_settings: $conversation_log_settings, sentiment_analysis_settings: $sentiment_analysis_settings, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of aliases for the specified bot.
#
# POST /bots/{botId}/botaliases/
# Returns: record<botAliasSummaries: table<botAliasId: string, botAliasName: string, description: string, botVersion: string, botAliasStatus: string, creationDateTime: string, lastUpdatedDateTime: string>, nextToken: string, botId: string>
# operationId: ListBotAliases
export def "list-bot-aliases" [
  bot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body-max-results: int # The maximum number of aliases to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (spec name: maxResults)
  --body-next-token: string # If the response from the ListBotAliases operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use that token in the nextToken parameter to return the next page of results. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/bots/{botId}/botaliases/"
    path_params: [{name: botId, var: bot_id}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bot_id: $bot_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a locale in the bot. The locale contains the intents and slot types that the bot uses in conversations with users in the specified language and locale. You must add a locale to a bot before you can add intents and slot types to the bot.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/
# Returns: record<botId: string, botVersion: string, localeName: string, localeId: string, description: string, nluIntentConfidenceThreshold: float, voiceSettings: record<voiceId: string, engine: string>, botLocaleStatus: string, creationDateTime: string>
# operationId: CreateBotLocale
export def "create-bot-locale" [
  bot_id: string
  bot_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  locale_id: string # The identifier of the language and locale that the bot will be used in. The string must match one of the supported locales. All of the intents, slot types, and slots used in the bot must have the same locale. For more information, see Supported languages (https://docs.aws.amazon.com/lexv2/latest/dg/how-languages.html).
  --description: string # A description of the bot locale. Use this to help identify the bot locale in lists.
  nlu_intent_confidence_threshold: float # Determines the threshold where Amazon Lex will insert the AMAZON.FallbackIntent, AMAZON.KendraSearchIntent, or both when returning alternative intents. AMAZON.FallbackIntent and AMAZON.KendraSearchIntent are only inserted if they are configured for the bot. For example, suppose a bot is configured with the confidence threshold of 0.80 and the AMAZON.FallbackIntent. Amazon Lex returns three alternative intents with the following confidence scores: IntentA (0.70), IntentB (0.60), IntentC (0.50). The response from the RecognizeText operation would be: AMAZON.FallbackIntent IntentA IntentB IntentC (format: double)
  --voice-settings: record # Defines settings for using an Amazon Polly voice to communicate with a user. — shape: {voiceId?: string, engine?: "standard"|"neural"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: localeId, var: locale_id}, {name: description, var: description}, {name: nluIntentConfidenceThreshold, var: nlu_intent_confidence_threshold}, {name: voiceSettings, var: voice_settings}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, locale_id: $locale_id, description: $description, nlu_intent_confidence_threshold: $nlu_intent_confidence_threshold, voice_settings: $voice_settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of locales for the specified bot.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/
# Returns: record<botId: string, botVersion: string, nextToken: string, botLocaleSummaries: table<localeId: string, localeName: string, description: string, botLocaleStatus: string, lastUpdatedDateTime: string, lastBuildSubmittedDateTime: string>>
# operationId: ListBotLocales
export def "list-bot-locales" [
  bot_id: string
  bot_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --sort-by: record # Specifies attributes for sorting a list of bot locales. — shape: {attribute?: "BotLocaleName", order?: "Ascending"|"Descending"}
  --filters: list # Provides the specification for a filter used to limit the response to only those locales that match the filter specification. You can only specify one filter and one value to filter on. — item shape: {name: "BotLocaleName", values: list<string>, operator: "CO"|"EQ"}
  --body-max-results: int # The maximum number of aliases to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (spec name: maxResults)
  --body-next-token: string # If the response from the ListBotLocales operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use that token as the nextToken parameter to return the next page of results. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: sortBy, var: sort_by}, {name: filters, var: filters}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, sort_by: $sort_by, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new version of the bot based on the DRAFT version. If the DRAFT version of this resource hasn't changed since you created the last version, Amazon Lex doesn't create a new version, it returns the last created version. When you create the first version of a bot, Amazon Lex sets the version to 1. Subsequent versions increment by 1.
#
# PUT /bots/{botId}/botversions/
# Returns: record<botId: string, description: string, botVersion: string, botVersionLocaleSpecification: record, botStatus: string, creationDateTime: string>
# operationId: CreateBotVersion
export def "create-bot-version" [
  bot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # A description of the version. Use the description to help identify the version in lists.
  bot_version_locale_specification: record # Specifies the locales that Amazon Lex adds to this version. You can choose the Draft version or any other previously published version for each locale. When you specify a source version, the locale data is copied from the source version to the new version.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/bots/{botId}/botversions/"
    path_params: [{name: botId, var: bot_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: botVersionLocaleSpecification, var: bot_version_locale_specification}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    bot_id: $bot_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, bot_version_locale_specification: $bot_version_locale_specification
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about all of the versions of a bot. The ListBotVersions operation returns a summary of each version of a bot. For example, if a bot has three numbered versions, the ListBotVersions operation returns for summaries, one for each numbered version and one for the DRAFT version. The ListBotVersions operation always returns at least one version, the DRAFT version.
#
# POST /bots/{botId}/botversions/
# Returns: record<botId: string, botVersionSummaries: table<botName: string, botVersion: string, description: string, botStatus: string, creationDateTime: string>, nextToken: string>
# operationId: ListBotVersions
export def "list-bot-versions" [
  bot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --sort-by: record # Specifies attributes for sorting a list of bot versions. — shape: {attribute?: "BotVersion", order?: "Ascending"|"Descending"}
  --body-max-results: int # The maximum number of versions to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (spec name: maxResults)
  --body-next-token: string # If the response to the ListBotVersion operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use that token in the nextToken parameter to return the next page of results. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/bots/{botId}/botversions/"
    path_params: [{name: botId, var: bot_id}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: sortBy, var: sort_by}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bot_id: $bot_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, sort_by: $sort_by, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a zip archive containing the contents of a bot or a bot locale. The archive contains a directory structure that contains JSON files that define the bot. You can create an archive that contains the complete definition of a bot, or you can specify that the archive contain only the definition of a single bot locale. For more information about exporting bots, and about the structure of the export archive, see Importing and exporting bots (https://docs.aws.amazon.com/lexv2/latest/dg/importing-exporting.html)
#
# PUT /exports/
# Returns: record<exportId: string, resourceSpecification: record<botExportSpecification: record<botId: string, botVersion: string>, botLocaleExportSpecification: record<botId: string, botVersion: string, localeId: string>, customVocabularyExportSpecification: record<botId: string, botVersion: string, localeId: string>>, fileFormat: string, exportStatus: string, creationDateTime: string>
# operationId: CreateExport
export def "create-export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  resource_specification: record # Provides information about the bot or bot locale that you want to export. You can specify the botExportSpecification or the botLocaleExportSpecification, but not both. — shape: {botExportSpecification?: record, botLocaleExportSpecification?: record, customVocabularyExportSpecification?: record}
  file_format: string@file-format-completer # The file format of the bot or bot locale definition files.
  --file-password: string # An password to use to encrypt the exported archive. Using a password is optional, but you should encrypt the archive to protect the data in transit between Amazon Lex and your local computer. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/exports/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceSpecification, var: resource_specification}, {name: fileFormat, var: file_format}, {name: filePassword, var: file_password}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, resource_specification: $resource_specification, file_format: $file_format, file_password: $file_password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the exports for a bot, bot locale, or custom vocabulary. Exports are kept in the list for 7 days.
#
# POST /exports/
# Returns: record<botId: string, botVersion: string, exportSummaries: table<exportId: string, resourceSpecification: record, fileFormat: string, exportStatus: string, creationDateTime: string, lastUpdatedDateTime: string>, nextToken: string, localeId: string>
# operationId: ListExports
export def "list-exports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --bot-id: string # The unique identifier that Amazon Lex assigned to the bot.
  --bot-version: string # The version of the bot to list exports for.
  --sort-by: record # Provides information about sorting a list of exports. — shape: {attribute?: "LastUpdatedDateTime", order?: "Ascending"|"Descending"}
  --filters: list # Provides the specification of a filter used to limit the exports in the response to only those that match the filter specification. You can only specify one filter and one string to filter on. — item shape: {name: "ExportResourceType", values: list<string>, operator: "CO"|"EQ"}
  --body-max-results: int # The maximum number of exports to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (spec name: maxResults)
  --body-next-token: string # If the response from the ListExports operation contains more results that specified in the maxResults parameter, a token is returned in the response. Use the returned token in the nextToken parameter of a ListExports request to return the next page of results. For a complete set of results, call the ListExports operation until the nextToken returned in the response is null. (spec name: nextToken)
  --locale-id: string # Specifies the resources that should be exported. If you don't specify a resource type in the filters parameter, both bot locales and custom vocabularies are exported.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/exports/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: sortBy, var: sort_by}, {name: filters, var: filters}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}, {name: localeId, var: locale_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, bot_id: $bot_id, bot_version: $bot_version, sort_by: $sort_by, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token, locale_id: $locale_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an intent. To define the interaction between the user and your bot, you define one or more intents. For example, for a pizza ordering bot you would create an OrderPizza intent. When you create an intent, you must provide a name. You can optionally provide the following: Sample utterances. For example, "I want to order a pizza" and "Can I order a pizza." You can't provide utterances for built-in intents. Information to be gathered. You specify slots for the information that you bot requests from the user. You can specify standard slot types, such as date and time, or custom slot types for your application. How the intent is fulfilled. You can provide a Lambda function or configure the intent to return the intent information to your client application. If you use a Lambda function, Amazon Lex invokes the function when all of the intent information is available. A confirmation prompt to send to the user to confirm an intent. For example, "Shall I order your pizza?" A conclusion statement to send to the user after the intent is fulfilled. For example, "I ordered your pizza." A follow-up prompt that asks the user for additional activity. For example, "Do you want a drink with your pizza?"
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/
# Returns: record<intentId: string, intentName: string, description: string, parentIntentSignature: string, sampleUtterances: table<utterance: string>, dialogCodeHook: record<enabled: bool>, fulfillmentCodeHook: record<enabled: bool, postFulfillmentStatusSpecification: record<successResponse: record, failureResponse: record, timeoutResponse: record, successNextStep: record, successConditional: record, failureNextStep: record, failureConditional: record, timeoutNextStep: record, timeoutConditional: record>, fulfillmentUpdatesSpecification: record<active: bool, startResponse: record, updateResponse: record, timeoutInSeconds: int>, active: bool>, intentConfirmationSetting: record<promptSpecification: record<messageGroups: list, maxRetries: int, allowInterrupt: bool, messageSelectionStrategy: string, promptAttemptsSpecification: record>, declinationResponse: record<messageGroups: list, allowInterrupt: bool>, active: bool, confirmationResponse: record<messageGroups: list, allowInterrupt: bool>, confirmationNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, confirmationConditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, declinationNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, declinationConditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, failureResponse: record<messageGroups: list, allowInterrupt: bool>, failureNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, failureConditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, codeHook: record<enableCodeHookInvocation: bool, active: bool, invocationLabel: string, postCodeHookSpecification: record>, elicitationCodeHook: record<enableCodeHookInvocation: bool, invocationLabel: string>>, intentClosingSetting: record<closingResponse: record<messageGroups: list, allowInterrupt: bool>, active: bool, nextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, conditional: record<active: bool, conditionalBranches: list, defaultBranch: record>>, inputContexts: table<name: string>, outputContexts: table<name: string, timeToLiveInSeconds: int, turnsToLive: int>, kendraConfiguration: record<kendraIndex: string, queryFilterStringEnabled: bool, queryFilterString: string>, botId: string, botVersion: string, localeId: string, creationDateTime: string, initialResponseSetting: record<initialResponse: record<messageGroups: list, allowInterrupt: bool>, nextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, conditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, codeHook: record<enableCodeHookInvocation: bool, active: bool, invocationLabel: string, postCodeHookSpecification: record>>>
# operationId: CreateIntent
export def "create-intent" [
  bot_id: string
  bot_version: string
  locale_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  intent_name: string # The name of the intent. Intent names must be unique in the locale that contains the intent and cannot match the name of any built-in intent.
  --description: string # A description of the intent. Use the description to help identify the intent in lists.
  --parent-intent-signature: string # A unique identifier for the built-in intent to base this intent on.
  --sample-utterances: list # An array of strings that a user might say to signal the intent. For example, "I want a pizza", or "I want a {PizzaSize} pizza". In an utterance, slot names are enclosed in curly braces ("{", "}") to indicate where they should be displayed in the utterance shown to the user.. — item shape: {utterance: string}
  --dialog-code-hook: record # Settings that determine the Lambda function that Amazon Lex uses for processing user responses. — shape: {enabled?: bool}
  --fulfillment-code-hook: record # Determines if a Lambda function should be invoked for a specific intent. — shape: {enabled?: bool, postFulfillmentStatusSpecification?: record, fulfillmentUpdatesSpecification?: record, active?: bool}
  --intent-confirmation-setting: record # Provides a prompt for making sure that the user is ready for the intent to be fulfilled. — shape: {promptSpecification?: record, declinationResponse?: record, active?: bool, confirmationResponse?: record, confirmationNextStep?: record, confirmationConditional?: record, declinationNextStep?: record, declinationConditional?: record, failureResponse?: record, failureNextStep?: record, failureConditional?: record, codeHook?: record, elicitationCodeHook?: record}
  --intent-closing-setting: record # Provides a statement the Amazon Lex conveys to the user when the intent is successfully fulfilled. — shape: {closingResponse?: record, active?: bool, nextStep?: record, conditional?: record}
  --input-contexts: list # A list of contexts that must be active for this intent to be considered by Amazon Lex. When an intent has an input context list, Amazon Lex only considers using the intent in an interaction with the user when the specified contexts are included in the active context list for the session. If the contexts are not active, then Amazon Lex will not use the intent. A context can be automatically activated using the outputContexts property or it can be set at runtime. For example, if there are two intents with different input contexts that respond to the same utterances, only the intent with the active context will respond. An intent may have up to 5 input contexts. If an intent has multiple input contexts, all of the contexts must be active to consider the intent. — item shape: {name: string}
  --output-contexts: list # A lists of contexts that the intent activates when it is fulfilled. You can use an output context to indicate the intents that Amazon Lex should consider for the next turn of the conversation with a customer. When you use the outputContextsList property, all of the contexts specified in the list are activated when the intent is fulfilled. You can set up to 10 output contexts. You can also set the number of conversation turns that the context should be active, or the length of time that the context should be active. — item shape: {name: string, timeToLiveInSeconds: int, turnsToLive: int}
  --kendra-configuration: record # Provides configuration information for the AMAZON.KendraSearchIntent intent. When you use this intent, Amazon Lex searches the specified Amazon Kendra index and returns documents from the index that match the user's utterance. — shape: {kendraIndex?: string, queryFilterStringEnabled?: bool, queryFilterString?: string}
  --initial-response-setting: record # Configuration setting for a response sent to the user before Amazon Lex starts eliciting slots. — shape: {initialResponse?: record, nextStep?: record, conditional?: record, codeHook?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: intentName, var: intent_name}, {name: description, var: description}, {name: parentIntentSignature, var: parent_intent_signature}, {name: sampleUtterances, var: sample_utterances}, {name: dialogCodeHook, var: dialog_code_hook}, {name: fulfillmentCodeHook, var: fulfillment_code_hook}, {name: intentConfirmationSetting, var: intent_confirmation_setting}, {name: intentClosingSetting, var: intent_closing_setting}, {name: inputContexts, var: input_contexts}, {name: outputContexts, var: output_contexts}, {name: kendraConfiguration, var: kendra_configuration}, {name: initialResponseSetting, var: initial_response_setting}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, locale_id: $locale_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, intent_name: $intent_name, description: $description, parent_intent_signature: $parent_intent_signature, sample_utterances: $sample_utterances, dialog_code_hook: $dialog_code_hook, fulfillment_code_hook: $fulfillment_code_hook, intent_confirmation_setting: $intent_confirmation_setting, intent_closing_setting: $intent_closing_setting, input_contexts: $input_contexts, output_contexts: $output_contexts, kendra_configuration: $kendra_configuration, initial_response_setting: $initial_response_setting
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of intents that meet the specified criteria.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/
# Returns: record<botId: string, botVersion: string, localeId: string, intentSummaries: table<intentId: string, intentName: string, description: string, parentIntentSignature: string, inputContexts: list, outputContexts: list, lastUpdatedDateTime: string>, nextToken: string>
# operationId: ListIntents
export def "list-intents" [
  bot_id: string
  bot_version: string
  locale_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --sort-by: record # Specifies attributes for sorting a list of intents. — shape: {attribute?: "IntentName"|"LastUpdatedDateTime", order?: "Ascending"|"Descending"}
  --filters: list # Provides the specification of a filter used to limit the intents in the response to only those that match the filter specification. You can only specify one filter and only one string to filter on. — item shape: {name: "IntentName", values: list<string>, operator: "CO"|"EQ"}
  --body-max-results: int # The maximum number of intents to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (spec name: maxResults)
  --body-next-token: string # If the response from the ListIntents operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use the returned token in the nextToken parameter of a ListIntents request to return the next page of results. For a complete set of results, call the ListIntents operation until the nextToken returned in the response is null. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: sortBy, var: sort_by}, {name: filters, var: filters}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, locale_id: $locale_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, sort_by: $sort_by, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new resource policy with the specified policy statements.
#
# POST /policy/{resourceArn}/
# Returns: record<resourceArn: string, revisionId: string>
# operationId: CreateResourcePolicy
export def "create-resource-policy" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  policy: string # A resource policy to add to the resource. The policy is a JSON structure that contains one or more statements that define the policy. The policy must follow the IAM syntax. For more information about the contents of a JSON policy document, see IAM JSON policy reference (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies.html). If the policy isn't valid, Amazon Lex returns a validation exception.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/policy/{resourceArn}/"
    path_params: [{name: resourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: policy, var: policy}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, policy: $policy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an existing policy from a bot or bot alias. If the resource doesn't have a policy attached, Amazon Lex returns an exception.
#
# DELETE /policy/{resourceArn}/
# Returns: record<resourceArn: string, revisionId: string>
# operationId: DeleteResourcePolicy
export def "delete-resource-policy" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expected-revision-id: string # The identifier of the revision to edit. If this ID doesn't match the current revision number, Amazon Lex returns an exception If you don't specify a revision ID, Amazon Lex will delete the current policy.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/policy/{resourceArn}/"
    path_params: [{name: resourceArn, var: resource_arn}]
    query: [{name: expectedRevisionId, var: expected_revision_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    resource_arn: $resource_arn, expected_revision_id: $expected_revision_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the resource policy and policy revision for a bot or bot alias.
#
# GET /policy/{resourceArn}/
# Returns: record<resourceArn: string, policy: string, revisionId: string>
# operationId: DescribeResourcePolicy
export def "describe-resource-policy" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/policy/{resourceArn}/"
    path_params: [{name: resourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replaces the existing resource policy for a bot or bot alias with a new one. If the policy doesn't exist, Amazon Lex returns an exception.
#
# PUT /policy/{resourceArn}/
# Returns: record<resourceArn: string, revisionId: string>
# operationId: UpdateResourcePolicy
export def "update-resource-policy" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expected-revision-id: string # The identifier of the revision of the policy to update. If this revision ID doesn't match the current revision ID, Amazon Lex throws an exception. If you don't specify a revision, Amazon Lex overwrites the contents of the policy with the new values.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  policy: string # A resource policy to add to the resource. The policy is a JSON structure that contains one or more statements that define the policy. The policy must follow the IAM syntax. For more information about the contents of a JSON policy document, see IAM JSON policy reference (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies.html). If the policy isn't valid, Amazon Lex returns a validation exception.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/policy/{resourceArn}/"
    path_params: [{name: resourceArn, var: resource_arn}]
    query: [{name: expectedRevisionId, var: expected_revision_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: policy, var: policy}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, expected_revision_id: $expected_revision_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, policy: $policy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a new resource policy statement to a bot or bot alias. If a resource policy exists, the statement is added to the current resource policy. If a policy doesn't exist, a new policy is created. You can't create a resource policy statement that allows cross-account access.
#
# POST /policy/{resourceArn}/statements/
# Returns: record<resourceArn: string, revisionId: string>
# operationId: CreateResourcePolicyStatement
export def "create-resource-policy-statement" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expected-revision-id: string # The identifier of the revision of the policy to edit. If this revision ID doesn't match the current revision ID, Amazon Lex throws an exception. If you don't specify a revision, Amazon Lex overwrites the contents of the policy with the new values.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  statement_id: string # The name of the statement. The ID is the same as the Sid IAM property. The statement name must be unique within the policy. For more information, see IAM JSON policy elements: Sid (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_sid.html).
  effect: string@effect-completer # Determines whether the statement allows or denies access to the resource.
  principal: list # An IAM principal, such as an IAM users, IAM roles, or AWS services that is allowed or denied access to a resource. For more information, see AWS JSON policy elements: Principal (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html). — item shape: {service?: string, arn?: string}
  action: list<string> # The Amazon Lex action that this policy either allows or denies. The action must apply to the resource type of the specified ARN. For more information, see Actions, resources, and condition keys for Amazon Lex V2 (https://docs.aws.amazon.com/service-authorization/latest/reference/list_amazonlexv2.html).
  --condition: record # Specifies a condition when the policy is in effect. If the principal of the policy is a service principal, you must provide two condition blocks, one with a SourceAccount global condition key and one with a SourceArn global condition key. For more information, see IAM JSON policy elements: Condition (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_condition.html).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/policy/{resourceArn}/statements/"
    path_params: [{name: resourceArn, var: resource_arn}]
    query: [{name: expectedRevisionId, var: expected_revision_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: statementId, var: statement_id}, {name: effect, var: effect}, {name: principal, var: principal}, {name: action, var: action}, {name: condition, var: condition}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, expected_revision_id: $expected_revision_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, statement_id: $statement_id, effect: $effect, principal: $principal, action: $action, condition: $condition
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a slot in an intent. A slot is a variable needed to fulfill an intent. For example, an OrderPizza intent might need slots for size, crust, and number of pizzas. For each slot, you define one or more utterances that Amazon Lex uses to elicit a response from the user.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/slots/
# Returns: record<slotId: string, slotName: string, description: string, slotTypeId: string, valueElicitationSetting: record<defaultValueSpecification: record<defaultValueList: list>, slotConstraint: string, promptSpecification: record<messageGroups: list, maxRetries: int, allowInterrupt: bool, messageSelectionStrategy: string, promptAttemptsSpecification: record>, sampleUtterances: list<record>, waitAndContinueSpecification: record<waitingResponse: record, continueResponse: record, stillWaitingResponse: record, active: bool>, slotCaptureSetting: record<captureResponse: record, captureNextStep: record, captureConditional: record, failureResponse: record, failureNextStep: record, failureConditional: record, codeHook: record, elicitationCodeHook: record>>, obfuscationSetting: record<obfuscationSettingType: string>, botId: string, botVersion: string, localeId: string, intentId: string, creationDateTime: string, multipleValuesSetting: record<allowMultipleValues: bool>, subSlotSetting: record<expression: string, slotSpecifications: record>>
# operationId: CreateSlot
export def "create-slot" [
  bot_id: string
  bot_version: string
  locale_id: string
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  slot_name: string # The name of the slot. Slot names must be unique within the bot that contains the slot.
  --description: string # A description of the slot. Use this to help identify the slot in lists.
  --slot-type-id: string # The unique identifier for the slot type associated with this slot. The slot type determines the values that can be entered into the slot.
  value_elicitation_setting: record # Specifies the elicitation setting details for constituent sub slots of a composite slot. — shape: {defaultValueSpecification?: record, slotConstraint?: "Required"|"Optional", promptSpecification?: record, sampleUtterances?: list, waitAndContinueSpecification?: record, slotCaptureSetting?: record}
  --obfuscation-setting: record # Determines whether Amazon Lex obscures slot values in conversation logs. — shape: {obfuscationSettingType?: "None"|"DefaultObfuscation"}
  --multiple-values-setting: record # Indicates whether a slot can return multiple values. — shape: {allowMultipleValues?: bool}
  --sub-slot-setting: record # Specifications for the constituent sub slots and the expression for the composite slot. — shape: {expression?: string, slotSpecifications?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/slots/"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}, {name: intentId, var: intent_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: slotName, var: slot_name}, {name: description, var: description}, {name: slotTypeId, var: slot_type_id}, {name: valueElicitationSetting, var: value_elicitation_setting}, {name: obfuscationSetting, var: obfuscation_setting}, {name: multipleValuesSetting, var: multiple_values_setting}, {name: subSlotSetting, var: sub_slot_setting}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, locale_id: $locale_id, intent_id: $intent_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, slot_name: $slot_name, description: $description, slot_type_id: $slot_type_id, value_elicitation_setting: $value_elicitation_setting, obfuscation_setting: $obfuscation_setting, multiple_values_setting: $multiple_values_setting, sub_slot_setting: $sub_slot_setting
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of slots that match the specified criteria.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/slots/
# Returns: record<botId: string, botVersion: string, localeId: string, intentId: string, slotSummaries: table<slotId: string, slotName: string, description: string, slotConstraint: string, slotTypeId: string, valueElicitationPromptSpecification: record, lastUpdatedDateTime: string>, nextToken: string>
# operationId: ListSlots
export def "list-slots" [
  bot_id: string
  bot_version: string
  locale_id: string
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
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --sort-by: record # Specifies attributes for sorting a list of bots. — shape: {attribute?: "SlotName"|"LastUpdatedDateTime", order?: "Ascending"|"Descending"}
  --filters: list # Provides the specification of a filter used to limit the slots in the response to only those that match the filter specification. You can only specify one filter and only one string to filter on. — item shape: {name: "SlotName", values: list<string>, operator: "CO"|"EQ"}
  --body-max-results: int # The maximum number of slots to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (spec name: maxResults)
  --body-next-token: string # If the response from the ListSlots operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use that token in the nextToken parameter to return the next page of results. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/slots/"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}, {name: intentId, var: intent_id}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: sortBy, var: sort_by}, {name: filters, var: filters}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, locale_id: $locale_id, intent_id: $intent_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, sort_by: $sort_by, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a custom slot type To create a custom slot type, specify a name for the slot type and a set of enumeration values, the values that a slot of this type can assume.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/slottypes/
# Returns: record<slotTypeId: string, slotTypeName: string, description: string, slotTypeValues: table<sampleValue: record, synonyms: list>, valueSelectionSetting: record<resolutionStrategy: string, regexFilter: record<pattern: string>, advancedRecognitionSetting: record<audioRecognitionStrategy: string>>, parentSlotTypeSignature: string, botId: string, botVersion: string, localeId: string, creationDateTime: string, externalSourceSetting: record<grammarSlotTypeSetting: record<source: record>>, compositeSlotTypeSetting: record<subSlots: list<record>>>
# operationId: CreateSlotType
export def "create-slot-type" [
  bot_id: string
  bot_version: string
  locale_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  slot_type_name: string # The name for the slot. A slot type name must be unique within the account.
  --description: string # A description of the slot type. Use the description to help identify the slot type in lists.
  --slot-type-values: list # A list of SlotTypeValue objects that defines the values that the slot type can take. Each value can have a list of synonyms, additional values that help train the machine learning model about the values that it resolves for a slot. — item shape: {sampleValue?: record, synonyms?: list}
  --value-selection-setting: record # Contains settings used by Amazon Lex to select a slot value. — shape: {resolutionStrategy?: "OriginalValue"|"TopResolution"|"Concatenation", regexFilter?: record, advancedRecognitionSetting?: record}
  --parent-slot-type-signature: string # The built-in slot type used as a parent of this slot type. When you define a parent slot type, the new slot type has the configuration of the parent slot type. Only AMAZON.AlphaNumeric is supported.
  --external-source-setting: record # Provides information about the external source of the slot type's definition. — shape: {grammarSlotTypeSetting?: record}
  --composite-slot-type-setting: record # A composite slot is a combination of two or more slots that capture multiple pieces of information in a single user input. — shape: {subSlots?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/slottypes/"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: slotTypeName, var: slot_type_name}, {name: description, var: description}, {name: slotTypeValues, var: slot_type_values}, {name: valueSelectionSetting, var: value_selection_setting}, {name: parentSlotTypeSignature, var: parent_slot_type_signature}, {name: externalSourceSetting, var: external_source_setting}, {name: compositeSlotTypeSetting, var: composite_slot_type_setting}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, locale_id: $locale_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, slot_type_name: $slot_type_name, description: $description, slot_type_values: $slot_type_values, value_selection_setting: $value_selection_setting, parent_slot_type_signature: $parent_slot_type_signature, external_source_setting: $external_source_setting, composite_slot_type_setting: $composite_slot_type_setting
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of slot types that match the specified criteria.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/slottypes/
# Returns: record<botId: string, botVersion: string, localeId: string, slotTypeSummaries: table<slotTypeId: string, slotTypeName: string, description: string, parentSlotTypeSignature: string, lastUpdatedDateTime: string, slotTypeCategory: string>, nextToken: string>
# operationId: ListSlotTypes
export def "list-slot-types" [
  bot_id: string
  bot_version: string
  locale_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --sort-by: record # Specifies attributes for sorting a list of slot types. — shape: {attribute?: "SlotTypeName"|"LastUpdatedDateTime", order?: "Ascending"|"Descending"}
  --filters: list # Provides the specification of a filter used to limit the slot types in the response to only those that match the filter specification. You can only specify one filter and only one string to filter on. — item shape: {name: "SlotTypeName"|"ExternalSourceType", values: list<string>, operator: "CO"|"EQ"}
  --body-max-results: int # The maximum number of slot types to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (spec name: maxResults)
  --body-next-token: string # If the response from the ListSlotTypes operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use that token in the nextToken parameter to return the next page of results. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/slottypes/"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: sortBy, var: sort_by}, {name: filters, var: filters}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, locale_id: $locale_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, sort_by: $sort_by, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a pre-signed S3 write URL that you use to upload the zip archive when importing a bot or a bot locale.
#
# POST /createuploadurl/
# Returns: record<importId: string, uploadUrl: string>
# operationId: CreateUploadUrl
export def "create-upload-url" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/createuploadurl/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes all versions of a bot, including the Draft version. To delete a specific version, use the DeleteBotVersion operation. When you delete a bot, all of the resources contained in the bot are also deleted. Deleting a bot removes all locales, intents, slot, and slot types defined for the bot. If a bot has an alias, the DeleteBot operation returns a ResourceInUseException exception. If you want to delete the bot and the alias, set the skipResourceInUseCheck parameter to true.
#
# DELETE /bots/{botId}/
# Returns: record<botId: string, botStatus: string>
# operationId: DeleteBot
export def "delete-bot" [
  bot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip-resource-in-use-check: oneof<nothing, bool> # By default, Amazon Lex checks if any other resource, such as an alias or bot network, is using the bot version before it is deleted and throws a ResourceInUseException exception if the bot is being used by another resource. Set this parameter to true to skip this check and remove the bot even if it is being used by another resource.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/bots/{botId}/"
    path_params: [{name: botId, var: bot_id}]
    query: [{name: skipResourceInUseCheck, var: skip_resource_in_use_check}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    bot_id: $bot_id, skip_resource_in_use_check: $skip_resource_in_use_check, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides metadata information about a bot.
#
# GET /bots/{botId}/
# Returns: record<botId: string, botName: string, description: string, roleArn: string, dataPrivacy: record<childDirected: bool>, idleSessionTTLInSeconds: int, botStatus: string, creationDateTime: string, lastUpdatedDateTime: string, botType: string, botMembers: table<botMemberId: string, botMemberName: string, botMemberAliasId: string, botMemberAliasName: string, botMemberVersion: string>, failureReasons: list<string>>
# operationId: DescribeBot
export def "describe-bot" [
  bot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bots/{botId}/"
    path_params: [{name: botId, var: bot_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bot_id: $bot_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the configuration of an existing bot.
#
# PUT /bots/{botId}/
# Returns: record<botId: string, botName: string, description: string, roleArn: string, dataPrivacy: record<childDirected: bool>, idleSessionTTLInSeconds: int, botStatus: string, creationDateTime: string, lastUpdatedDateTime: string, botType: string, botMembers: table<botMemberId: string, botMemberName: string, botMemberAliasId: string, botMemberAliasName: string, botMemberVersion: string>>
# operationId: UpdateBot
export def "update-bot" [
  bot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  bot_name: string # The new name of the bot. The name must be unique in the account that creates the bot.
  --description: string # A description of the bot.
  role_arn: string # The Amazon Resource Name (ARN) of an IAM role that has permissions to access the bot.
  data_privacy: record # By default, data stored by Amazon Lex is encrypted. The DataPrivacy structure provides settings that determine how Amazon Lex handles special cases of securing the data for your bot. — shape: {childDirected?: bool}
  idle_session_ttl_in_seconds: int # The time, in seconds, that Amazon Lex should keep information about a user's conversation with the bot. A user interaction remains active for the amount of time specified. If no conversation occurs during this time, the session expires and Amazon Lex deletes any data provided before the timeout. You can specify between 60 (1 minute) and 86,400 (24 hours) seconds.
  --bot-type: string@bot-type-completer # The type of the bot to be updated.
  --bot-members: list # The list of bot members in the network associated with the update action. — item shape: {botMemberId: string, botMemberName: string, botMemberAliasId: string, botMemberAliasName: string, botMemberVersion: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/bots/{botId}/"
    path_params: [{name: botId, var: bot_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: botName, var: bot_name}, {name: description, var: description}, {name: roleArn, var: role_arn}, {name: dataPrivacy, var: data_privacy}, {name: idleSessionTTLInSeconds, var: idle_session_ttl_in_seconds}, {name: botType, var: bot_type}, {name: botMembers, var: bot_members}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    bot_id: $bot_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, bot_name: $bot_name, description: $description, role_arn: $role_arn, data_privacy: $data_privacy, idle_session_ttl_in_seconds: $idle_session_ttl_in_seconds, bot_type: $bot_type, bot_members: $bot_members
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified bot alias.
#
# DELETE /bots/{botId}/botaliases/{botAliasId}/
# Returns: record<botAliasId: string, botId: string, botAliasStatus: string>
# operationId: DeleteBotAlias
export def "delete-bot-alias" [
  bot_id: string
  bot_alias_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip-resource-in-use-check: oneof<nothing, bool> # By default, Amazon Lex checks if any other resource, such as a bot network, is using the bot alias before it is deleted and throws a ResourceInUseException exception if the alias is being used by another resource. Set this parameter to true to skip this check and remove the alias even if it is being used by another resource.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/bots/{botId}/botaliases/{botAliasId}/"
    path_params: [{name: botId, var: bot_id}, {name: botAliasId, var: bot_alias_id}]
    query: [{name: skipResourceInUseCheck, var: skip_resource_in_use_check}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    bot_id: $bot_id, bot_alias_id: $bot_alias_id, skip_resource_in_use_check: $skip_resource_in_use_check, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information about a specific bot alias.
#
# GET /bots/{botId}/botaliases/{botAliasId}/
# Returns: record<botAliasId: string, botAliasName: string, description: string, botVersion: string, botAliasLocaleSettings: record, conversationLogSettings: record<textLogSettings: list<record>, audioLogSettings: list<record>>, sentimentAnalysisSettings: record<detectSentiment: bool>, botAliasHistoryEvents: table<botVersion: string, startDate: string, endDate: string>, botAliasStatus: string, botId: string, creationDateTime: string, lastUpdatedDateTime: string, parentBotNetworks: table<botId: string, botVersion: string>>
# operationId: DescribeBotAlias
export def "describe-bot-alias" [
  bot_id: string
  bot_alias_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bots/{botId}/botaliases/{botAliasId}/"
    path_params: [{name: botId, var: bot_id}, {name: botAliasId, var: bot_alias_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bot_id: $bot_id, bot_alias_id: $bot_alias_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the configuration of an existing bot alias.
#
# PUT /bots/{botId}/botaliases/{botAliasId}/
# Returns: record<botAliasId: string, botAliasName: string, description: string, botVersion: string, botAliasLocaleSettings: record, conversationLogSettings: record<textLogSettings: list<record>, audioLogSettings: list<record>>, sentimentAnalysisSettings: record<detectSentiment: bool>, botAliasStatus: string, botId: string, creationDateTime: string, lastUpdatedDateTime: string>
# operationId: UpdateBotAlias
export def "update-bot-alias" [
  bot_id: string
  bot_alias_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  bot_alias_name: string # The new name to assign to the bot alias.
  --description: string # The new description to assign to the bot alias.
  --bot-version: string # The new bot version to assign to the bot alias.
  --bot-alias-locale-settings: record # The new Lambda functions to use in each locale for the bot alias.
  --conversation-log-settings: record # Configures conversation logging that saves audio, text, and metadata for the conversations with your users. — shape: {textLogSettings?: list, audioLogSettings?: list}
  --sentiment-analysis-settings: record # Determines whether Amazon Lex will use Amazon Comprehend to detect the sentiment of user utterances. — shape: {detectSentiment?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/bots/{botId}/botaliases/{botAliasId}/"
    path_params: [{name: botId, var: bot_id}, {name: botAliasId, var: bot_alias_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: botAliasName, var: bot_alias_name}, {name: description, var: description}, {name: botVersion, var: bot_version}, {name: botAliasLocaleSettings, var: bot_alias_locale_settings}, {name: conversationLogSettings, var: conversation_log_settings}, {name: sentimentAnalysisSettings, var: sentiment_analysis_settings}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    bot_id: $bot_id, bot_alias_id: $bot_alias_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, bot_alias_name: $bot_alias_name, description: $description, bot_version: $bot_version, bot_alias_locale_settings: $bot_alias_locale_settings, conversation_log_settings: $conversation_log_settings, sentiment_analysis_settings: $sentiment_analysis_settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a specific version of a bot. To delete all versions of a bot, use the DeleteBot (https://docs.aws.amazon.com/lexv2/latest/APIReference/API_DeleteBot.html) operation.
#
# DELETE /bots/{botId}/botversions/{botVersion}/
# Returns: record<botId: string, botVersion: string, botStatus: string>
# operationId: DeleteBotVersion
export def "delete-bot-version" [
  bot_id: string
  bot_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip-resource-in-use-check: oneof<nothing, bool> # By default, Amazon Lex checks if any other resource, such as an alias or bot network, is using the bot version before it is deleted and throws a ResourceInUseException exception if the version is being used by another resource. Set this parameter to true to skip this check and remove the version even if it is being used by another resource.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/bots/{botId}/botversions/{botVersion}/"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}]
    query: [{name: skipResourceInUseCheck, var: skip_resource_in_use_check}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, skip_resource_in_use_check: $skip_resource_in_use_check, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides metadata about a version of a bot.
#
# GET /bots/{botId}/botversions/{botVersion}/
# Returns: record<botId: string, botName: string, botVersion: string, description: string, roleArn: string, dataPrivacy: record<childDirected: bool>, idleSessionTTLInSeconds: int, botStatus: string, failureReasons: list<string>, creationDateTime: string, parentBotNetworks: table<botId: string, botVersion: string>, botType: string, botMembers: table<botMemberId: string, botMemberName: string, botMemberAliasId: string, botMemberAliasName: string, botMemberVersion: string>>
# operationId: DescribeBotVersion
export def "describe-bot-version" [
  bot_id: string
  bot_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bots/{botId}/botversions/{botVersion}/"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a custom vocabulary from the specified locale in the specified bot.
#
# DELETE /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/customvocabulary
# Returns: record<botId: string, botVersion: string, localeId: string, customVocabularyStatus: string>
# operationId: DeleteCustomVocabulary
export def "delete-custom-vocabulary" [
  bot_id: string
  bot_version: string
  locale_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/customvocabulary"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, locale_id: $locale_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a previous export and the associated files stored in an S3 bucket.
#
# DELETE /exports/{exportId}/
# Returns: record<exportId: string, exportStatus: string>
# operationId: DeleteExport
export def "delete-export" [
  export_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/exports/{exportId}/"
    path_params: [{name: exportId, var: export_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    export_id: $export_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a specific export.
#
# GET /exports/{exportId}/
# Returns: record<exportId: string, resourceSpecification: record<botExportSpecification: record<botId: string, botVersion: string>, botLocaleExportSpecification: record<botId: string, botVersion: string, localeId: string>, customVocabularyExportSpecification: record<botId: string, botVersion: string, localeId: string>>, fileFormat: string, exportStatus: string, failureReasons: list<string>, downloadUrl: string, creationDateTime: string, lastUpdatedDateTime: string>
# operationId: DescribeExport
export def "describe-export" [
  export_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/exports/{exportId}/"
    path_params: [{name: exportId, var: export_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    export_id: $export_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the password used to protect an export zip archive. The password is not required. If you don't supply a password, Amazon Lex generates a zip file that is not protected by a password. This is the archive that is available at the pre-signed S3 URL provided by the DescribeExport (https://docs.aws.amazon.com/lexv2/latest/APIReference/API_DescribeExport.html) operation.
#
# PUT /exports/{exportId}/
# Returns: record<exportId: string, resourceSpecification: record<botExportSpecification: record<botId: string, botVersion: string>, botLocaleExportSpecification: record<botId: string, botVersion: string, localeId: string>, customVocabularyExportSpecification: record<botId: string, botVersion: string, localeId: string>>, fileFormat: string, exportStatus: string, creationDateTime: string, lastUpdatedDateTime: string>
# operationId: UpdateExport
export def "update-export" [
  export_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --file-password: string # The new password to use to encrypt the export zip archive. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/exports/{exportId}/"
    path_params: [{name: exportId, var: export_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: filePassword, var: file_password}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    export_id: $export_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, file_password: $file_password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a previous import and the associated file stored in an S3 bucket.
#
# DELETE /imports/{importId}/
# Returns: record<importId: string, importStatus: string>
# operationId: DeleteImport
export def "delete-import" [
  import_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/imports/{importId}/"
    path_params: [{name: importId, var: import_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    import_id: $import_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a specific import.
#
# GET /imports/{importId}/
# Returns: record<importId: string, resourceSpecification: record<botImportSpecification: record<botName: string, roleArn: string, dataPrivacy: record, idleSessionTTLInSeconds: int, botTags: record, testBotAliasTags: record>, botLocaleImportSpecification: record<botId: string, botVersion: string, localeId: string, nluIntentConfidenceThreshold: float, voiceSettings: record>, customVocabularyImportSpecification: record<botId: string, botVersion: string, localeId: string>>, importedResourceId: string, importedResourceName: string, mergeStrategy: string, importStatus: string, failureReasons: list<string>, creationDateTime: string, lastUpdatedDateTime: string>
# operationId: DescribeImport
export def "describe-import" [
  import_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/imports/{importId}/"
    path_params: [{name: importId, var: import_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    import_id: $import_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the specified intent. Deleting an intent also deletes the slots associated with the intent.
#
# DELETE /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/
# operationId: DeleteIntent
export def "delete-intent" [
  bot_id: string
  bot_version: string
  locale_id: string
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}, {name: intentId, var: intent_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, locale_id: $locale_id, intent_id: $intent_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns metadata about an intent.
#
# GET /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/
# Returns: record<intentId: string, intentName: string, description: string, parentIntentSignature: string, sampleUtterances: table<utterance: string>, dialogCodeHook: record<enabled: bool>, fulfillmentCodeHook: record<enabled: bool, postFulfillmentStatusSpecification: record<successResponse: record, failureResponse: record, timeoutResponse: record, successNextStep: record, successConditional: record, failureNextStep: record, failureConditional: record, timeoutNextStep: record, timeoutConditional: record>, fulfillmentUpdatesSpecification: record<active: bool, startResponse: record, updateResponse: record, timeoutInSeconds: int>, active: bool>, slotPriorities: table<priority: int, slotId: string>, intentConfirmationSetting: record<promptSpecification: record<messageGroups: list, maxRetries: int, allowInterrupt: bool, messageSelectionStrategy: string, promptAttemptsSpecification: record>, declinationResponse: record<messageGroups: list, allowInterrupt: bool>, active: bool, confirmationResponse: record<messageGroups: list, allowInterrupt: bool>, confirmationNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, confirmationConditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, declinationNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, declinationConditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, failureResponse: record<messageGroups: list, allowInterrupt: bool>, failureNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, failureConditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, codeHook: record<enableCodeHookInvocation: bool, active: bool, invocationLabel: string, postCodeHookSpecification: record>, elicitationCodeHook: record<enableCodeHookInvocation: bool, invocationLabel: string>>, intentClosingSetting: record<closingResponse: record<messageGroups: list, allowInterrupt: bool>, active: bool, nextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, conditional: record<active: bool, conditionalBranches: list, defaultBranch: record>>, inputContexts: table<name: string>, outputContexts: table<name: string, timeToLiveInSeconds: int, turnsToLive: int>, kendraConfiguration: record<kendraIndex: string, queryFilterStringEnabled: bool, queryFilterString: string>, botId: string, botVersion: string, localeId: string, creationDateTime: string, lastUpdatedDateTime: string, initialResponseSetting: record<initialResponse: record<messageGroups: list, allowInterrupt: bool>, nextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, conditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, codeHook: record<enableCodeHookInvocation: bool, active: bool, invocationLabel: string, postCodeHookSpecification: record>>>
# operationId: DescribeIntent
export def "describe-intent" [
  bot_id: string
  bot_version: string
  locale_id: string
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}, {name: intentId, var: intent_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, locale_id: $locale_id, intent_id: $intent_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the settings for an intent.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/
# Returns: record<intentId: string, intentName: string, description: string, parentIntentSignature: string, sampleUtterances: table<utterance: string>, dialogCodeHook: record<enabled: bool>, fulfillmentCodeHook: record<enabled: bool, postFulfillmentStatusSpecification: record<successResponse: record, failureResponse: record, timeoutResponse: record, successNextStep: record, successConditional: record, failureNextStep: record, failureConditional: record, timeoutNextStep: record, timeoutConditional: record>, fulfillmentUpdatesSpecification: record<active: bool, startResponse: record, updateResponse: record, timeoutInSeconds: int>, active: bool>, slotPriorities: table<priority: int, slotId: string>, intentConfirmationSetting: record<promptSpecification: record<messageGroups: list, maxRetries: int, allowInterrupt: bool, messageSelectionStrategy: string, promptAttemptsSpecification: record>, declinationResponse: record<messageGroups: list, allowInterrupt: bool>, active: bool, confirmationResponse: record<messageGroups: list, allowInterrupt: bool>, confirmationNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, confirmationConditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, declinationNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, declinationConditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, failureResponse: record<messageGroups: list, allowInterrupt: bool>, failureNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, failureConditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, codeHook: record<enableCodeHookInvocation: bool, active: bool, invocationLabel: string, postCodeHookSpecification: record>, elicitationCodeHook: record<enableCodeHookInvocation: bool, invocationLabel: string>>, intentClosingSetting: record<closingResponse: record<messageGroups: list, allowInterrupt: bool>, active: bool, nextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, conditional: record<active: bool, conditionalBranches: list, defaultBranch: record>>, inputContexts: table<name: string>, outputContexts: table<name: string, timeToLiveInSeconds: int, turnsToLive: int>, kendraConfiguration: record<kendraIndex: string, queryFilterStringEnabled: bool, queryFilterString: string>, botId: string, botVersion: string, localeId: string, creationDateTime: string, lastUpdatedDateTime: string, initialResponseSetting: record<initialResponse: record<messageGroups: list, allowInterrupt: bool>, nextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, conditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, codeHook: record<enableCodeHookInvocation: bool, active: bool, invocationLabel: string, postCodeHookSpecification: record>>>
# operationId: UpdateIntent
export def "update-intent" [
  bot_id: string
  bot_version: string
  locale_id: string
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  intent_name: string # The new name for the intent.
  --description: string # The new description of the intent.
  --parent-intent-signature: string # The signature of the new built-in intent to use as the parent of this intent.
  --sample-utterances: list # New utterances used to invoke the intent. — item shape: {utterance: string}
  --dialog-code-hook: record # Settings that determine the Lambda function that Amazon Lex uses for processing user responses. — shape: {enabled?: bool}
  --fulfillment-code-hook: record # Determines if a Lambda function should be invoked for a specific intent. — shape: {enabled?: bool, postFulfillmentStatusSpecification?: record, fulfillmentUpdatesSpecification?: record, active?: bool}
  --slot-priorities: list # A new list of slots and their priorities that are contained by the intent. — item shape: {priority: int, slotId: string}
  --intent-confirmation-setting: record # Provides a prompt for making sure that the user is ready for the intent to be fulfilled. — shape: {promptSpecification?: record, declinationResponse?: record, active?: bool, confirmationResponse?: record, confirmationNextStep?: record, confirmationConditional?: record, declinationNextStep?: record, declinationConditional?: record, failureResponse?: record, failureNextStep?: record, failureConditional?: record, codeHook?: record, elicitationCodeHook?: record}
  --intent-closing-setting: record # Provides a statement the Amazon Lex conveys to the user when the intent is successfully fulfilled. — shape: {closingResponse?: record, active?: bool, nextStep?: record, conditional?: record}
  --input-contexts: list # A new list of contexts that must be active in order for Amazon Lex to consider the intent. — item shape: {name: string}
  --output-contexts: list # A new list of contexts that Amazon Lex activates when the intent is fulfilled. — item shape: {name: string, timeToLiveInSeconds: int, turnsToLive: int}
  --kendra-configuration: record # Provides configuration information for the AMAZON.KendraSearchIntent intent. When you use this intent, Amazon Lex searches the specified Amazon Kendra index and returns documents from the index that match the user's utterance. — shape: {kendraIndex?: string, queryFilterStringEnabled?: bool, queryFilterString?: string}
  --initial-response-setting: record # Configuration setting for a response sent to the user before Amazon Lex starts eliciting slots. — shape: {initialResponse?: record, nextStep?: record, conditional?: record, codeHook?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}, {name: intentId, var: intent_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: intentName, var: intent_name}, {name: description, var: description}, {name: parentIntentSignature, var: parent_intent_signature}, {name: sampleUtterances, var: sample_utterances}, {name: dialogCodeHook, var: dialog_code_hook}, {name: fulfillmentCodeHook, var: fulfillment_code_hook}, {name: slotPriorities, var: slot_priorities}, {name: intentConfirmationSetting, var: intent_confirmation_setting}, {name: intentClosingSetting, var: intent_closing_setting}, {name: inputContexts, var: input_contexts}, {name: outputContexts, var: output_contexts}, {name: kendraConfiguration, var: kendra_configuration}, {name: initialResponseSetting, var: initial_response_setting}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, locale_id: $locale_id, intent_id: $intent_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, intent_name: $intent_name, description: $description, parent_intent_signature: $parent_intent_signature, sample_utterances: $sample_utterances, dialog_code_hook: $dialog_code_hook, fulfillment_code_hook: $fulfillment_code_hook, slot_priorities: $slot_priorities, intent_confirmation_setting: $intent_confirmation_setting, intent_closing_setting: $intent_closing_setting, input_contexts: $input_contexts, output_contexts: $output_contexts, kendra_configuration: $kendra_configuration, initial_response_setting: $initial_response_setting
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a policy statement from a resource policy. If you delete the last statement from a policy, the policy is deleted. If you specify a statement ID that doesn't exist in the policy, or if the bot or bot alias doesn't have a policy attached, Amazon Lex returns an exception.
#
# DELETE /policy/{resourceArn}/statements/{statementId}/
# Returns: record<resourceArn: string, revisionId: string>
# operationId: DeleteResourcePolicyStatement
export def "delete-resource-policy-statement" [
  resource_arn: string
  statement_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expected-revision-id: string # The identifier of the revision of the policy to delete the statement from. If this revision ID doesn't match the current revision ID, Amazon Lex throws an exception. If you don't specify a revision, Amazon Lex removes the current contents of the statement.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/policy/{resourceArn}/statements/{statementId}/"
    path_params: [{name: resourceArn, var: resource_arn}, {name: statementId, var: statement_id}]
    query: [{name: expectedRevisionId, var: expected_revision_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    resource_arn: $resource_arn, statement_id: $statement_id, expected_revision_id: $expected_revision_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified slot from an intent.
#
# DELETE /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/slots/{slotId}/
# operationId: DeleteSlot
export def "delete-slot" [
  bot_id: string
  bot_version: string
  locale_id: string
  intent_id: string
  slot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/slots/{slotId}/"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}, {name: intentId, var: intent_id}, {name: slotId, var: slot_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, locale_id: $locale_id, intent_id: $intent_id, slot_id: $slot_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets metadata information about a slot.
#
# GET /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/slots/{slotId}/
# Returns: record<slotId: string, slotName: string, description: string, slotTypeId: string, valueElicitationSetting: record<defaultValueSpecification: record<defaultValueList: list>, slotConstraint: string, promptSpecification: record<messageGroups: list, maxRetries: int, allowInterrupt: bool, messageSelectionStrategy: string, promptAttemptsSpecification: record>, sampleUtterances: list<record>, waitAndContinueSpecification: record<waitingResponse: record, continueResponse: record, stillWaitingResponse: record, active: bool>, slotCaptureSetting: record<captureResponse: record, captureNextStep: record, captureConditional: record, failureResponse: record, failureNextStep: record, failureConditional: record, codeHook: record, elicitationCodeHook: record>>, obfuscationSetting: record<obfuscationSettingType: string>, botId: string, botVersion: string, localeId: string, intentId: string, creationDateTime: string, lastUpdatedDateTime: string, multipleValuesSetting: record<allowMultipleValues: bool>, subSlotSetting: record<expression: string, slotSpecifications: record>>
# operationId: DescribeSlot
export def "describe-slot" [
  bot_id: string
  bot_version: string
  locale_id: string
  intent_id: string
  slot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/slots/{slotId}/"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}, {name: intentId, var: intent_id}, {name: slotId, var: slot_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, locale_id: $locale_id, intent_id: $intent_id, slot_id: $slot_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the settings for a slot.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/slots/{slotId}/
# Returns: record<slotId: string, slotName: string, description: string, slotTypeId: string, valueElicitationSetting: record<defaultValueSpecification: record<defaultValueList: list>, slotConstraint: string, promptSpecification: record<messageGroups: list, maxRetries: int, allowInterrupt: bool, messageSelectionStrategy: string, promptAttemptsSpecification: record>, sampleUtterances: list<record>, waitAndContinueSpecification: record<waitingResponse: record, continueResponse: record, stillWaitingResponse: record, active: bool>, slotCaptureSetting: record<captureResponse: record, captureNextStep: record, captureConditional: record, failureResponse: record, failureNextStep: record, failureConditional: record, codeHook: record, elicitationCodeHook: record>>, obfuscationSetting: record<obfuscationSettingType: string>, botId: string, botVersion: string, localeId: string, intentId: string, creationDateTime: string, lastUpdatedDateTime: string, multipleValuesSetting: record<allowMultipleValues: bool>, subSlotSetting: record<expression: string, slotSpecifications: record>>
# operationId: UpdateSlot
export def "update-slot" [
  bot_id: string
  bot_version: string
  locale_id: string
  intent_id: string
  slot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  slot_name: string # The new name for the slot.
  --description: string # The new description for the slot.
  --slot-type-id: string # The unique identifier of the new slot type to associate with this slot.
  value_elicitation_setting: record # Specifies the elicitation setting details for constituent sub slots of a composite slot. — shape: {defaultValueSpecification?: record, slotConstraint?: "Required"|"Optional", promptSpecification?: record, sampleUtterances?: list, waitAndContinueSpecification?: record, slotCaptureSetting?: record}
  --obfuscation-setting: record # Determines whether Amazon Lex obscures slot values in conversation logs. — shape: {obfuscationSettingType?: "None"|"DefaultObfuscation"}
  --multiple-values-setting: record # Indicates whether a slot can return multiple values. — shape: {allowMultipleValues?: bool}
  --sub-slot-setting: record # Specifications for the constituent sub slots and the expression for the composite slot. — shape: {expression?: string, slotSpecifications?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/slots/{slotId}/"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}, {name: intentId, var: intent_id}, {name: slotId, var: slot_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: slotName, var: slot_name}, {name: description, var: description}, {name: slotTypeId, var: slot_type_id}, {name: valueElicitationSetting, var: value_elicitation_setting}, {name: obfuscationSetting, var: obfuscation_setting}, {name: multipleValuesSetting, var: multiple_values_setting}, {name: subSlotSetting, var: sub_slot_setting}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, locale_id: $locale_id, intent_id: $intent_id, slot_id: $slot_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, slot_name: $slot_name, description: $description, slot_type_id: $slot_type_id, value_elicitation_setting: $value_elicitation_setting, obfuscation_setting: $obfuscation_setting, multiple_values_setting: $multiple_values_setting, sub_slot_setting: $sub_slot_setting
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a slot type from a bot locale. If a slot is using the slot type, Amazon Lex throws a ResourceInUseException exception. To avoid the exception, set the skipResourceInUseCheck parameter to true.
#
# DELETE /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/slottypes/{slotTypeId}/
# operationId: DeleteSlotType
export def "delete-slot-type" [
  bot_id: string
  bot_version: string
  locale_id: string
  slot_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip-resource-in-use-check: oneof<nothing, bool> # By default, the DeleteSlotType operations throws a ResourceInUseException exception if you try to delete a slot type used by a slot. Set the skipResourceInUseCheck parameter to true to skip this check and remove the slot type even if a slot uses it.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/slottypes/{slotTypeId}/"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}, {name: slotTypeId, var: slot_type_id}]
    query: [{name: skipResourceInUseCheck, var: skip_resource_in_use_check}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, locale_id: $locale_id, slot_type_id: $slot_type_id, skip_resource_in_use_check: $skip_resource_in_use_check, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets metadata information about a slot type.
#
# GET /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/slottypes/{slotTypeId}/
# Returns: record<slotTypeId: string, slotTypeName: string, description: string, slotTypeValues: table<sampleValue: record, synonyms: list>, valueSelectionSetting: record<resolutionStrategy: string, regexFilter: record<pattern: string>, advancedRecognitionSetting: record<audioRecognitionStrategy: string>>, parentSlotTypeSignature: string, botId: string, botVersion: string, localeId: string, creationDateTime: string, lastUpdatedDateTime: string, externalSourceSetting: record<grammarSlotTypeSetting: record<source: record>>, compositeSlotTypeSetting: record<subSlots: list<record>>>
# operationId: DescribeSlotType
export def "describe-slot-type" [
  bot_id: string
  bot_version: string
  locale_id: string
  slot_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/slottypes/{slotTypeId}/"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}, {name: slotTypeId, var: slot_type_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, locale_id: $locale_id, slot_type_id: $slot_type_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the configuration of an existing slot type.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/slottypes/{slotTypeId}/
# Returns: record<slotTypeId: string, slotTypeName: string, description: string, slotTypeValues: table<sampleValue: record, synonyms: list>, valueSelectionSetting: record<resolutionStrategy: string, regexFilter: record<pattern: string>, advancedRecognitionSetting: record<audioRecognitionStrategy: string>>, parentSlotTypeSignature: string, botId: string, botVersion: string, localeId: string, creationDateTime: string, lastUpdatedDateTime: string, externalSourceSetting: record<grammarSlotTypeSetting: record<source: record>>, compositeSlotTypeSetting: record<subSlots: list<record>>>
# operationId: UpdateSlotType
export def "update-slot-type" [
  bot_id: string
  bot_version: string
  locale_id: string
  slot_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  slot_type_name: string # The new name of the slot type.
  --description: string # The new description of the slot type.
  --slot-type-values: list # A new list of values and their optional synonyms that define the values that the slot type can take. — item shape: {sampleValue?: record, synonyms?: list}
  --value-selection-setting: record # Contains settings used by Amazon Lex to select a slot value. — shape: {resolutionStrategy?: "OriginalValue"|"TopResolution"|"Concatenation", regexFilter?: record, advancedRecognitionSetting?: record}
  --parent-slot-type-signature: string # The new built-in slot type that should be used as the parent of this slot type.
  --external-source-setting: record # Provides information about the external source of the slot type's definition. — shape: {grammarSlotTypeSetting?: record}
  --composite-slot-type-setting: record # A composite slot is a combination of two or more slots that capture multiple pieces of information in a single user input. — shape: {subSlots?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/slottypes/{slotTypeId}/"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}, {name: slotTypeId, var: slot_type_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: slotTypeName, var: slot_type_name}, {name: description, var: description}, {name: slotTypeValues, var: slot_type_values}, {name: valueSelectionSetting, var: value_selection_setting}, {name: parentSlotTypeSignature, var: parent_slot_type_signature}, {name: externalSourceSetting, var: external_source_setting}, {name: compositeSlotTypeSetting, var: composite_slot_type_setting}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, locale_id: $locale_id, slot_type_id: $slot_type_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, slot_type_name: $slot_type_name, description: $description, slot_type_values: $slot_type_values, value_selection_setting: $value_selection_setting, parent_slot_type_signature: $parent_slot_type_signature, external_source_setting: $external_source_setting, composite_slot_type_setting: $composite_slot_type_setting
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes stored utterances. Amazon Lex stores the utterances that users send to your bot. Utterances are stored for 15 days for use with the ListAggregatedUtterances (https://docs.aws.amazon.com/lexv2/latest/APIReference/API_ListAggregatedUtterances.html) operation, and then stored indefinitely for use in improving the ability of your bot to respond to user input.. Use the DeleteUtterances operation to manually delete utterances for a specific session. When you use the DeleteUtterances operation, utterances stored for improving your bot's ability to respond to user input are deleted immediately. Utterances stored for use with the ListAggregatedUtterances operation are deleted after 15 days.
#
# DELETE /bots/{botId}/utterances/
# Returns: record
# operationId: DeleteUtterances
export def "delete-utterances" [
  bot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale-id: string # The identifier of the language and locale where the utterances were collected. The string must match one of the supported locales. For more information, see Supported languages (https://docs.aws.amazon.com/lexv2/latest/dg/how-languages.html).
  --session-id: string # The unique identifier of the session with the user. The ID is returned in the response from the RecognizeText (https://docs.aws.amazon.com/lexv2/latest/APIReference/API_runtime_RecognizeText.html) and RecognizeUtterance (https://docs.aws.amazon.com/lexv2/latest/APIReference/API_runtime_RecognizeUtterance.html) operations.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/bots/{botId}/utterances/"
    path_params: [{name: botId, var: bot_id}]
    query: [{name: localeId, var: locale_id}, {name: sessionId, var: session_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    bot_id: $bot_id, locale_id: $locale_id, session_id: $session_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides metadata information about a bot recommendation. This information will enable you to get a description on the request inputs, to download associated transcripts after processing is complete, and to download intents and slot-types generated by the bot recommendation.
#
# GET /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/{botRecommendationId}/
# Returns: record<botId: string, botVersion: string, localeId: string, botRecommendationStatus: string, botRecommendationId: string, failureReasons: list<string>, creationDateTime: string, lastUpdatedDateTime: string, transcriptSourceSetting: record<s3BucketTranscriptSource: record<s3BucketName: string, pathFormat: record, transcriptFormat: string, transcriptFilter: record, kmsKeyArn: string>>, encryptionSetting: record<kmsKeyArn: string, botLocaleExportPassword: string, associatedTranscriptsPassword: string>, botRecommendationResults: record<botLocaleExportUrl: string, associatedTranscriptsUrl: string, statistics: record<intents: record, slotTypes: record>>>
# operationId: DescribeBotRecommendation
export def "describe-bot-recommendation" [
  bot_id: string
  bot_version: string
  locale_id: string
  bot_recommendation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/{botRecommendationId}/"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}, {name: botRecommendationId, var: bot_recommendation_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, locale_id: $locale_id, bot_recommendation_id: $bot_recommendation_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing bot recommendation request.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/{botRecommendationId}/
# Returns: record<botId: string, botVersion: string, localeId: string, botRecommendationStatus: string, botRecommendationId: string, creationDateTime: string, lastUpdatedDateTime: string, transcriptSourceSetting: record<s3BucketTranscriptSource: record<s3BucketName: string, pathFormat: record, transcriptFormat: string, transcriptFilter: record, kmsKeyArn: string>>, encryptionSetting: record<kmsKeyArn: string, botLocaleExportPassword: string, associatedTranscriptsPassword: string>>
# operationId: UpdateBotRecommendation
export def "update-bot-recommendation" [
  bot_id: string
  bot_version: string
  locale_id: string
  bot_recommendation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  encryption_setting: record # The object representing the passwords that were used to encrypt the data related to the bot recommendation, as well as the KMS key ARN used to encrypt the associated metadata. — shape: {kmsKeyArn?: string, botLocaleExportPassword?: string, associatedTranscriptsPassword?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/{botRecommendationId}/"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}, {name: botRecommendationId, var: bot_recommendation_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: encryptionSetting, var: encryption_setting}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, locale_id: $locale_id, bot_recommendation_id: $bot_recommendation_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, encryption_setting: $encryption_setting
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides metadata information about a custom vocabulary.
#
# GET /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/customvocabulary/DEFAULT/metadata
# Returns: record<botId: string, botVersion: string, localeId: string, customVocabularyStatus: string, creationDateTime: string, lastUpdatedDateTime: string>
# operationId: DescribeCustomVocabularyMetadata
export def "describe-custom-vocabulary-metadata" [
  bot_id: string
  bot_version: string
  locale_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/customvocabulary/DEFAULT/metadata"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, locale_id: $locale_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides a list of utterances that users have sent to the bot. Utterances are aggregated by the text of the utterance. For example, all instances where customers used the phrase "I want to order pizza" are aggregated into the same line in the response. You can see both detected utterances and missed utterances. A detected utterance is where the bot properly recognized the utterance and activated the associated intent. A missed utterance was not recognized by the bot and didn't activate an intent. Utterances can be aggregated for a bot alias or for a bot version, but not both at the same time. Utterances statistics are not generated under the following conditions: The childDirected field was set to true when the bot was created. You are using slot obfuscation with one or more slots. You opted out of participating in improving Amazon Lex.
#
# POST /bots/{botId}/aggregatedutterances/
# Returns: record<botId: string, botAliasId: string, botVersion: string, localeId: string, aggregationDuration: record<relativeAggregationDuration: record<timeDimension: string, timeValue: int>>, aggregationWindowStartTime: string, aggregationWindowEndTime: string, aggregationLastRefreshedDateTime: string, aggregatedUtterancesSummaries: table<utterance: string, hitCount: int, missedCount: int, utteranceFirstRecordedInAggregationDuration: string, utteranceLastRecordedInAggregationDuration: string, containsDataFromDeletedResources: bool>, nextToken: string>
# operationId: ListAggregatedUtterances
export def "list-aggregated-utterances" [
  bot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --bot-alias-id: string # The identifier of the bot alias associated with this request. If you specify the bot alias, you can't specify the bot version.
  --bot-version: string # The identifier of the bot version associated with this request. If you specify the bot version, you can't specify the bot alias.
  locale_id: string # The identifier of the language and locale where the utterances were collected. For more information, see Supported languages (https://docs.aws.amazon.com/lexv2/latest/dg/how-languages.html).
  aggregation_duration: record # Provides parameters for setting the time window and duration for aggregating utterance data. — shape: {relativeAggregationDuration?: record}
  --sort-by: record # Specifies attributes for sorting a list of utterances. — shape: {attribute?: "HitCount"|"MissedCount", order?: "Ascending"|"Descending"}
  --filters: list # Provides the specification of a filter used to limit the utterances in the response to only those that match the filter specification. You can only specify one filter and one string to filter on. — item shape: {name: "Utterance", values: list<string>, operator: "CO"|"EQ"}
  --body-max-results: int # The maximum number of utterances to return in each page of results. If there are fewer results than the maximum page size, only the actual number of results are returned. If you don't specify the maxResults parameter, 1,000 results are returned. (spec name: maxResults)
  --body-next-token: string # If the response from the ListAggregatedUtterances operation contains more results that specified in the maxResults parameter, a token is returned in the response. Use that token in the nextToken parameter to return the next page of results. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/bots/{botId}/aggregatedutterances/"
    path_params: [{name: botId, var: bot_id}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: botAliasId, var: bot_alias_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}, {name: aggregationDuration, var: aggregation_duration}, {name: sortBy, var: sort_by}, {name: filters, var: filters}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bot_id: $bot_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, bot_alias_id: $bot_alias_id, bot_version: $bot_version, locale_id: $locale_id, aggregation_duration: $aggregation_duration, sort_by: $sort_by, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of bot recommendations that meet the specified criteria.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/
# Returns: record<botId: string, botVersion: string, localeId: string, botRecommendationSummaries: table<botRecommendationStatus: string, botRecommendationId: string, creationDateTime: string, lastUpdatedDateTime: string>, nextToken: string>
# operationId: ListBotRecommendations
export def "list-bot-recommendations" [
  bot_id: string
  bot_version: string
  locale_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body-max-results: int # The maximum number of bot recommendations to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (spec name: maxResults)
  --body-next-token: string # If the response from the ListBotRecommendation operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use that token in the nextToken parameter to return the next page of results. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, locale_id: $locale_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this to provide your transcript data, and to start the bot recommendation process.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/
# Returns: record<botId: string, botVersion: string, localeId: string, botRecommendationStatus: string, botRecommendationId: string, creationDateTime: string, transcriptSourceSetting: record<s3BucketTranscriptSource: record<s3BucketName: string, pathFormat: record, transcriptFormat: string, transcriptFilter: record, kmsKeyArn: string>>, encryptionSetting: record<kmsKeyArn: string, botLocaleExportPassword: string, associatedTranscriptsPassword: string>>
# operationId: StartBotRecommendation
export def "start-bot-recommendation" [
  bot_id: string
  bot_version: string
  locale_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  transcript_source_setting: record # Indicates the setting of the location where the transcript is stored. — shape: {s3BucketTranscriptSource?: record}
  --encryption-setting: record # The object representing the passwords that were used to encrypt the data related to the bot recommendation, as well as the KMS key ARN used to encrypt the associated metadata. — shape: {kmsKeyArn?: string, botLocaleExportPassword?: string, associatedTranscriptsPassword?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: transcriptSourceSetting, var: transcript_source_setting}, {name: encryptionSetting, var: encryption_setting}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, locale_id: $locale_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, transcript_source_setting: $transcript_source_setting, encryption_setting: $encryption_setting
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of built-in intents provided by Amazon Lex that you can use in your bot. To use a built-in intent as a the base for your own intent, include the built-in intent signature in the parentIntentSignature parameter when you call the CreateIntent operation. For more information, see CreateIntent (https://docs.aws.amazon.com/lexv2/latest/APIReference/API_CreateIntent.html).
#
# POST /builtins/locales/{localeId}/intents/
# Returns: record<builtInIntentSummaries: table<intentSignature: string, description: string>, nextToken: string, localeId: string>
# operationId: ListBuiltInIntents
export def "list-built-in-intents" [
  locale_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --sort-by: record # Specifies attributes for sorting a list of built-in intents. — shape: {attribute?: "IntentSignature", order?: "Ascending"|"Descending"}
  --body-max-results: int # The maximum number of built-in intents to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (spec name: maxResults)
  --body-next-token: string # If the response from the ListBuiltInIntents operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use that token in the nextToken parameter to return the next page of results. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/builtins/locales/{localeId}/intents/"
    path_params: [{name: localeId, var: locale_id}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: sortBy, var: sort_by}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    locale_id: $locale_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, sort_by: $sort_by, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of built-in slot types that meet the specified criteria.
#
# POST /builtins/locales/{localeId}/slottypes/
# Returns: record<builtInSlotTypeSummaries: table<slotTypeSignature: string, description: string>, nextToken: string, localeId: string>
# operationId: ListBuiltInSlotTypes
export def "list-built-in-slot-types" [
  locale_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --sort-by: record # Specifies attributes for sorting a list of built-in slot types. — shape: {attribute?: "SlotTypeSignature", order?: "Ascending"|"Descending"}
  --body-max-results: int # The maximum number of built-in slot types to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (spec name: maxResults)
  --body-next-token: string # If the response from the ListBuiltInSlotTypes operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use that token in the nextToken parameter to return the next page of results. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/builtins/locales/{localeId}/slottypes/"
    path_params: [{name: localeId, var: locale_id}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: sortBy, var: sort_by}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    locale_id: $locale_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, sort_by: $sort_by, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Paginated list of custom vocabulary items for a given bot locale's custom vocabulary.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/customvocabulary/DEFAULT/list
# Returns: record<botId: string, botVersion: string, localeId: string, customVocabularyItems: table<itemId: string, phrase: string, weight: int, displayAs: string>, nextToken: string>
# operationId: ListCustomVocabularyItems
export def "list-custom-vocabulary-items" [
  bot_id: string
  bot_version: string
  locale_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body-max-results: int # The maximum number of items returned by the list operation. (spec name: maxResults)
  --body-next-token: string # The nextToken identifier to the list custom vocabulary request. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/customvocabulary/DEFAULT/list"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, locale_id: $locale_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the imports for a bot, bot locale, or custom vocabulary. Imports are kept in the list for 7 days.
#
# POST /imports/
# Returns: record<botId: string, botVersion: string, importSummaries: table<importId: string, importedResourceId: string, importedResourceName: string, importStatus: string, mergeStrategy: string, creationDateTime: string, lastUpdatedDateTime: string, importedResourceType: string>, nextToken: string, localeId: string>
# operationId: ListImports
export def "list-imports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --bot-id: string # The unique identifier that Amazon Lex assigned to the bot.
  --bot-version: string # The version of the bot to list imports for.
  --sort-by: record # Provides information for sorting a list of imports. — shape: {attribute?: "LastUpdatedDateTime", order?: "Ascending"|"Descending"}
  --filters: list # Provides the specification of a filter used to limit the bots in the response to only those that match the filter specification. You can only specify one filter and one string to filter on. — item shape: {name: "ImportResourceType", values: list<string>, operator: "CO"|"EQ"}
  --body-max-results: int # The maximum number of imports to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (spec name: maxResults)
  --body-next-token: string # If the response from the ListImports operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use the returned token in the nextToken parameter of a ListImports request to return the next page of results. For a complete set of results, call the ListImports operation until the nextToken returned in the response is null. (spec name: nextToken)
  --locale-id: string # Specifies the locale that should be present in the list. If you don't specify a resource type in the filters parameter, the list contains both bot locales and custom vocabularies.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/imports/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: sortBy, var: sort_by}, {name: filters, var: filters}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}, {name: localeId, var: locale_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, bot_id: $bot_id, bot_version: $bot_version, sort_by: $sort_by, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token, locale_id: $locale_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts importing a bot, bot locale, or custom vocabulary from a zip archive that you uploaded to an S3 bucket.
#
# PUT /imports/
# Returns: record<importId: string, resourceSpecification: record<botImportSpecification: record<botName: string, roleArn: string, dataPrivacy: record, idleSessionTTLInSeconds: int, botTags: record, testBotAliasTags: record>, botLocaleImportSpecification: record<botId: string, botVersion: string, localeId: string, nluIntentConfidenceThreshold: float, voiceSettings: record>, customVocabularyImportSpecification: record<botId: string, botVersion: string, localeId: string>>, mergeStrategy: string, importStatus: string, creationDateTime: string>
# operationId: StartImport
export def "start-import" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  import_id: string # The unique identifier for the import. It is included in the response from the CreateUploadUrl (https://docs.aws.amazon.com/lexv2/latest/APIReference/API_CreateUploadUrl.html) operation.
  resource_specification: record # Provides information about the bot or bot locale that you want to import. You can specify the botImportSpecification or the botLocaleImportSpecification, but not both. — shape: {botImportSpecification?: record, botLocaleImportSpecification?: record, customVocabularyImportSpecification?: record}
  merge_strategy: string@merge-strategy-completer # The strategy to use when there is a name conflict between the imported resource and an existing resource. When the merge strategy is FailOnConflict existing resources are not overwritten and the import fails.
  --file-password: string # The password used to encrypt the zip archive that contains the resource definition. You should always encrypt the zip archive to protect it during transit between your site and Amazon Lex. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/imports/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: importId, var: import_id}, {name: resourceSpecification, var: resource_specification}, {name: mergeStrategy, var: merge_strategy}, {name: filePassword, var: file_password}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, import_id: $import_id, resource_specification: $resource_specification, merge_strategy: $merge_strategy, file_password: $file_password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of recommended intents provided by the bot recommendation that you can use in your bot. Intents in the response are ordered by relevance.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/{botRecommendationId}/intents
# Returns: record<botId: string, botVersion: string, localeId: string, botRecommendationId: string, summaryList: table<intentId: string, intentName: string, sampleUtterancesCount: int>, nextToken: string>
# operationId: ListRecommendedIntents
export def "list-recommended-intents" [
  bot_id: string
  bot_version: string
  locale_id: string
  bot_recommendation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body-next-token: string # If the response from the ListRecommendedIntents operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use that token in the nextToken parameter to return the next page of results. (spec name: nextToken)
  --body-max-results: int # The maximum number of bot recommendations to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/{botRecommendationId}/intents"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}, {name: botRecommendationId, var: bot_recommendation_id}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, locale_id: $locale_id, bot_recommendation_id: $bot_recommendation_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of tags associated with a resource. Only bots, bot aliases, and bot channels can have tags associated with them.
#
# GET /tags/{resourceARN}
# Returns: record<tags: record>
# operationId: ListTagsForResource
export def "list-tags-for-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tags/{resourceARN}"
    path_params: [{name: resourceARN, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds the specified tags to the specified resource. If a tag key already exists, the existing value is replaced with the new value.
#
# POST /tags/{resourceARN}
# Returns: record
# operationId: TagResource
export def "tag-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  tags: record # A list of tag keys to add to the resource. If a tag key already exists, the existing value is replaced with the new value.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tags/{resourceARN}"
    path_params: [{name: resourceARN, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for associated transcripts that meet the specified criteria.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/{botRecommendationId}/associatedtranscripts
# Returns: record<botId: string, botVersion: string, localeId: string, botRecommendationId: string, nextIndex: int, associatedTranscripts: table<transcript: string>, totalResults: int>
# operationId: SearchAssociatedTranscripts
export def "search-associated-transcripts" [
  bot_id: string
  bot_version: string
  locale_id: string
  bot_recommendation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --search-order: string@search-order-completer # How SearchResults are ordered. Valid values are Ascending or Descending. The default is Descending.
  filters: list # A list of filter objects. — item shape: {name: "IntentId"|"SlotTypeId", values: list<string>}
  --max-results: int # The maximum number of bot recommendations to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned.
  --next-index: int # If the response from the SearchAssociatedTranscriptsRequest operation contains more results than specified in the maxResults parameter, an index is returned in the response. Use that index in the nextIndex parameter to return the next page of results.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/{botRecommendationId}/associatedtranscripts"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}, {name: botRecommendationId, var: bot_recommendation_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: searchOrder, var: search_order}, {name: filters, var: filters}, {name: maxResults, var: max_results}, {name: nextIndex, var: next_index}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, locale_id: $locale_id, bot_recommendation_id: $bot_recommendation_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, search_order: $search_order, filters: $filters, max_results: $max_results, next_index: $next_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop an already running Bot Recommendation request.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/{botRecommendationId}/stopbotrecommendation
# Returns: record<botId: string, botVersion: string, localeId: string, botRecommendationStatus: string, botRecommendationId: string>
# operationId: StopBotRecommendation
export def "stop-bot-recommendation" [
  bot_id: string
  bot_version: string
  locale_id: string
  bot_recommendation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/{botRecommendationId}/stopbotrecommendation"
    path_params: [{name: botId, var: bot_id}, {name: botVersion, var: bot_version}, {name: localeId, var: locale_id}, {name: botRecommendationId, var: bot_recommendation_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    bot_id: $bot_id, bot_version: $bot_version, locale_id: $locale_id, bot_recommendation_id: $bot_recommendation_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes tags from a bot, bot alias, or bot channel.
#
# DELETE /tags/{resourceARN}
# Returns: record
# operationId: UntagResource
export def "untag-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-keys: list<string> # A list of tag keys to remove from the resource. If a tag key does not exist on the resource, it is ignored. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/tags/{resourceARN}"
    path_params: [{name: resourceARN, var: resource_arn}]
    query: [{name: tagKeys, var: tag_keys, style: multi, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, tag_keys: $tag_keys, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
