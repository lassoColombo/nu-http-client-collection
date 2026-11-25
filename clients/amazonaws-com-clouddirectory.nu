# Auto-generated client for Amazon CloudDirectory v2017-01-11
# Source: https://api.apis.guru/v2/specs/amazonaws.com/clouddirectory/2017-01-11/openapi.json
# Auth: --token flag or $env.AMAZON_CLOUDDIRECTORY_TOKEN

const CLIENT = {
  base_url: "http://clouddirectory.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_CLOUDDIRECTORY_TOKEN"
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

def base-url-completer [] { ["http://clouddirectory.us-east-1.amazonaws.com" "http://clouddirectory.us-east-2.amazonaws.com" "http://clouddirectory.us-west-1.amazonaws.com" "http://clouddirectory.us-west-2.amazonaws.com" "http://clouddirectory.us-gov-west-1.amazonaws.com" "http://clouddirectory.us-gov-east-1.amazonaws.com" "http://clouddirectory.ca-central-1.amazonaws.com" "http://clouddirectory.eu-north-1.amazonaws.com" "http://clouddirectory.eu-west-1.amazonaws.com" "http://clouddirectory.eu-west-2.amazonaws.com" "http://clouddirectory.eu-west-3.amazonaws.com" "http://clouddirectory.eu-central-1.amazonaws.com" "http://clouddirectory.eu-south-1.amazonaws.com" "http://clouddirectory.af-south-1.amazonaws.com" "http://clouddirectory.ap-northeast-1.amazonaws.com" "http://clouddirectory.ap-northeast-2.amazonaws.com" "http://clouddirectory.ap-northeast-3.amazonaws.com" "http://clouddirectory.ap-southeast-1.amazonaws.com" "http://clouddirectory.ap-southeast-2.amazonaws.com" "http://clouddirectory.ap-east-1.amazonaws.com" "http://clouddirectory.ap-south-1.amazonaws.com" "http://clouddirectory.sa-east-1.amazonaws.com" "http://clouddirectory.me-south-1.amazonaws.com" "https://clouddirectory.us-east-1.amazonaws.com" "https://clouddirectory.us-east-2.amazonaws.com" "https://clouddirectory.us-west-1.amazonaws.com" "https://clouddirectory.us-west-2.amazonaws.com" "https://clouddirectory.us-gov-west-1.amazonaws.com" "https://clouddirectory.us-gov-east-1.amazonaws.com" "https://clouddirectory.ca-central-1.amazonaws.com" "https://clouddirectory.eu-north-1.amazonaws.com" "https://clouddirectory.eu-west-1.amazonaws.com" "https://clouddirectory.eu-west-2.amazonaws.com" "https://clouddirectory.eu-west-3.amazonaws.com" "https://clouddirectory.eu-central-1.amazonaws.com" "https://clouddirectory.eu-south-1.amazonaws.com" "https://clouddirectory.af-south-1.amazonaws.com" "https://clouddirectory.ap-northeast-1.amazonaws.com" "https://clouddirectory.ap-northeast-2.amazonaws.com" "https://clouddirectory.ap-northeast-3.amazonaws.com" "https://clouddirectory.ap-southeast-1.amazonaws.com" "https://clouddirectory.ap-southeast-2.amazonaws.com" "https://clouddirectory.ap-east-1.amazonaws.com" "https://clouddirectory.ap-south-1.amazonaws.com" "https://clouddirectory.sa-east-1.amazonaws.com" "https://clouddirectory.me-south-1.amazonaws.com" "http://clouddirectory.cn-north-1.amazonaws.com.cn" "http://clouddirectory.cn-northwest-1.amazonaws.com.cn" "https://clouddirectory.cn-north-1.amazonaws.com.cn" "https://clouddirectory.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-consistency-level-completer [] { ["EVENTUAL" "SERIALIZABLE"] }
def object-type-completer [] { ["INDEX" "LEAF_NODE" "NODE" "POLICY"] }
def facet-style-completer [] { ["DYNAMIC" "STATIC"] }
def consistency-level-completer [] { ["EVENTUAL" "SERIALIZABLE"] }
def state-completer [] { ["DELETED" "DISABLED" "ENABLED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    add-facet-to-object: "record"
    apply-schema: "record<AppliedSchemaArn: string, DirectoryArn: string>"
    attach-object: "record<AttachedObjectIdentifier: string>"
    attach-policy: "record"
    attach-to-index: "record<AttachedObjectIdentifier: string>"
    attach-typed-link: "record<TypedLinkSpecifier: record<TypedLinkFacet: record<SchemaArn: string, TypedLinkName: string>, SourceObjectReference: record<Selector: string>, TargetObjectReference: record<Selector: string>, IdentityAttributeValues: list<record>>>"
    batch-read: "record<Responses: table<SuccessfulResponse: record, ExceptionResponse: record>>"
    batch-write: "record<Responses: table<CreateObject: record, AttachObject: record, DetachObject: record, UpdateObjectAttributes: record, DeleteObject: record, AddFacetToObject: record, RemoveFacetFromObject: record, AttachPolicy: record, DetachPolicy: record, CreateIndex: record, AttachToIndex: record, DetachFromIndex: record, AttachTypedLink: record, DetachTypedLink: record, UpdateLinkAttributes: record>>"
    create-directory: "record<DirectoryArn: string, Name: string, ObjectIdentifier: string, AppliedSchemaArn: string>"
    create-facet: "record"
    create-index: "record<ObjectIdentifier: string>"
    create-object: "record<ObjectIdentifier: string>"
    create-schema: "record<SchemaArn: string>"
    create-typed-link-facet: "record"
    delete-directory: "record<DirectoryArn: string>"
    delete-facet: "record"
    delete-object: "record"
    delete-schema: "record<SchemaArn: string>"
    delete-typed-link-facet: "record"
    detach-from-index: "record<DetachedObjectIdentifier: string>"
    detach-object: "record<DetachedObjectIdentifier: string>"
    detach-policy: "record"
    disable-directory: "record<DirectoryArn: string>"
    enable-directory: "record<DirectoryArn: string>"
    get-applied-schema-version: "record<AppliedSchemaArn: string>"
    get-directory: "record<Directory: record<Name: string, DirectoryArn: string, State: string, CreationDateTime: string>>"
    get-facet: "record<Facet: record<Name: string, ObjectType: string, FacetStyle: string>>"
    update-facet: "record"
    get-link-attributes: "record<Attributes: table<Key: record, Value: record>>"
    get-object-attributes: "record<Attributes: table<Key: record, Value: record>>"
    get-object-information: "record<SchemaFacets: table<SchemaArn: string, FacetName: string>, ObjectIdentifier: string>"
    get-schema-as-json: "record<Name: string, Document: string>"
    put-schema-from-json: "record<Arn: string>"
    get-typed-link-facet-information: "record<IdentityAttributeOrder: list<string>>"
    list-applied-schema-arns: "record<SchemaArns: list<string>, NextToken: string>"
    list-attached-indices: "record<IndexAttachments: table<IndexedAttributes: list, ObjectIdentifier: string>, NextToken: string>"
    list-development-schema-arns: "record<SchemaArns: list<string>, NextToken: string>"
    list-directories: "record<Directories: table<Name: string, DirectoryArn: string, State: string, CreationDateTime: string>, NextToken: string>"
    list-facet-attributes: "record<Attributes: table<Name: string, AttributeDefinition: record, AttributeReference: record, RequiredBehavior: string>, NextToken: string>"
    list-facet-names: "record<FacetNames: list<string>, NextToken: string>"
    list-incoming-typed-links: "record<LinkSpecifiers: table<TypedLinkFacet: record, SourceObjectReference: record, TargetObjectReference: record, IdentityAttributeValues: list>, NextToken: string>"
    list-index: "record<IndexAttachments: table<IndexedAttributes: list, ObjectIdentifier: string>, NextToken: string>"
    list-managed-schema-arns: "record<SchemaArns: list<string>, NextToken: string>"
    list-object-attributes: "record<Attributes: table<Key: record, Value: record>, NextToken: string>"
    list-object-children: "record<Children: record, NextToken: string>"
    list-object-parent-paths: "record<PathToObjectIdentifiersList: table<Path: string, ObjectIdentifiers: list>, NextToken: string>"
    list-object-parents: "record<Parents: record, NextToken: string, ParentLinks: table<ObjectIdentifier: string, LinkName: string>>"
    list-object-policies: "record<AttachedPolicyIds: list<string>, NextToken: string>"
    list-outgoing-typed-links: "record<TypedLinkSpecifiers: table<TypedLinkFacet: record, SourceObjectReference: record, TargetObjectReference: record, IdentityAttributeValues: list>, NextToken: string>"
    list-policy-attachments: "record<ObjectIdentifiers: list<string>, NextToken: string>"
    list-published-schema-arns: "record<SchemaArns: list<string>, NextToken: string>"
    list-tags-for-resource: "record<Tags: table<Key: string, Value: string>, NextToken: string>"
    list-typed-link-facet-attributes: "record<Attributes: table<Name: string, Type: string, DefaultValue: record, IsImmutable: bool, Rules: record, RequiredBehavior: string>, NextToken: string>"
    list-typed-link-facet-names: "record<FacetNames: list<string>, NextToken: string>"
    lookup-policy: "record<PolicyToPathList: table<Path: string, Policies: list>, NextToken: string>"
    publish-schema: "record<PublishedSchemaArn: string>"
    remove-facet-from-object: "record"
    tag-resource: "record"
    untag-resource: "record"
    update-link-attributes: "record"
    update-object-attributes: "record<ObjectIdentifier: string>"
    update-schema: "record<SchemaArn: string>"
    update-typed-link-facet: "record"
    upgrade-applied-schema: "record<UpgradedSchemaArn: string, DirectoryArn: string>"
    upgrade-published-schema: "record<UpgradedSchemaArn: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["add-facet-to-object" "apply-schema" "attach-object" "attach-policy" "attach-to-index" "attach-typed-link" "batch-read" "batch-write" "create-directory" "create-facet" "create-index" "create-object" "create-schema" "create-typed-link-facet" "delete-directory" "delete-facet" "delete-object" "delete-schema" "delete-typed-link-facet" "detach-from-index" "detach-object" "detach-policy" "detach-typed-link" "disable-directory" "enable-directory" "get-applied-schema-version" "get-directory" "get-facet" "update-facet" "get-link-attributes" "get-object-attributes" "get-object-information" "get-schema-as-json" "put-schema-from-json" "get-typed-link-facet-information" "list-applied-schema-arns" "list-attached-indices" "list-development-schema-arns" "list-directories" "list-facet-attributes" "list-facet-names" "list-incoming-typed-links" "list-index" "list-managed-schema-arns" "list-object-attributes" "list-object-children" "list-object-parent-paths" "list-object-parents" "list-object-policies" "list-outgoing-typed-links" "list-policy-attachments" "list-published-schema-arns" "list-tags-for-resource" "list-typed-link-facet-attributes" "list-typed-link-facet-names" "lookup-policy" "publish-schema" "remove-facet-from-object" "tag-resource" "untag-resource" "update-link-attributes" "update-object-attributes" "update-schema" "update-typed-link-facet" "upgrade-applied-schema" "upgrade-published-schema" "commands"] | sort) } | get name | first)
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

# Adds a new Facet to an object. An object can have more than one facet applied on it.
#
# PUT /amazonclouddirectory/2017-01-11/object/facets
# Returns: record
# operationId: AddFacetToObject
export def "add-facet-to-object" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory where the object resides. For more information, see arns. (required)
  schema_facet: record # A facet. — shape: {SchemaArn?: string, FacetName?: string}
  --object-attribute-list: list # Attributes on the facet that you are adding to the object. — item shape: {Key: record, Value: record}
  object_reference: record # The reference that identifies an object. — shape: {Selector?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/object/facets"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: SchemaFacet, var: schema_facet}, {name: ObjectAttributeList, var: object_attribute_list}, {name: ObjectReference, var: object_reference}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, schema_facet: $schema_facet, object_attribute_list: $object_attribute_list, object_reference: $object_reference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Copies the input published schema, at the specified version, into the Directory with the same name and version as that of the published schema.
#
# PUT /amazonclouddirectory/2017-01-11/schema/apply
# Returns: record<AppliedSchemaArn: string, DirectoryArn: string>
# operationId: ApplySchema
export def "apply-schema" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory into which the schema is copied. For more information, see arns. (required)
  published_schema_arn: string # Published schema Amazon Resource Name (ARN) that needs to be copied. For more information, see arns.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/schema/apply"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: PublishedSchemaArn, var: published_schema_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, published_schema_arn: $published_schema_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attaches an existing object to another object. An object can be accessed in two ways: Using the path Using ObjectIdentifier
#
# PUT /amazonclouddirectory/2017-01-11/object/attach
# Returns: record<AttachedObjectIdentifier: string>
# operationId: AttachObject
export def "attach-object" [
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
  --x-amz-data-partition: string # Amazon Resource Name (ARN) that is associated with the Directory where both objects reside. For more information, see arns. (required)
  parent_reference: record # The reference that identifies an object. — shape: {Selector?: string}
  child_reference: record # The reference that identifies an object. — shape: {Selector?: string}
  link_name: string # The link name with which the child object is attached to the parent.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/object/attach"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: ParentReference, var: parent_reference}, {name: ChildReference, var: child_reference}, {name: LinkName, var: link_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, parent_reference: $parent_reference, child_reference: $child_reference, link_name: $link_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attaches a policy object to a regular object. An object can have a limited number of attached policies.
#
# PUT /amazonclouddirectory/2017-01-11/policy/attach
# Returns: record
# operationId: AttachPolicy
export def "attach-policy" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory where both objects reside. For more information, see arns. (required)
  policy_reference: record # The reference that identifies an object. — shape: {Selector?: string}
  object_reference: record # The reference that identifies an object. — shape: {Selector?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/policy/attach"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: PolicyReference, var: policy_reference}, {name: ObjectReference, var: object_reference}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, policy_reference: $policy_reference, object_reference: $object_reference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attaches the specified object to the specified index.
#
# PUT /amazonclouddirectory/2017-01-11/index/attach
# Returns: record<AttachedObjectIdentifier: string>
# operationId: AttachToIndex
export def "attach-to-index" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) of the directory where the object and index exist. (required)
  index_reference: record # The reference that identifies an object. — shape: {Selector?: string}
  target_reference: record # The reference that identifies an object. — shape: {Selector?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/index/attach"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexReference, var: index_reference}, {name: TargetReference, var: target_reference}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, index_reference: $index_reference, target_reference: $target_reference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attaches a typed link to a specified source and target object. For more information, see Typed Links (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink).
#
# PUT /amazonclouddirectory/2017-01-11/typedlink/attach
# Returns: record<TypedLinkSpecifier: record<TypedLinkFacet: record<SchemaArn: string, TypedLinkName: string>, SourceObjectReference: record<Selector: string>, TargetObjectReference: record<Selector: string>, IdentityAttributeValues: list<record>>>
# operationId: AttachTypedLink
export def "attach-typed-link" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) of the directory where you want to attach the typed link. (required)
  source_object_reference: record # The reference that identifies an object. — shape: {Selector?: string}
  target_object_reference: record # The reference that identifies an object. — shape: {Selector?: string}
  typed_link_facet: record # Identifies the schema Amazon Resource Name (ARN) and facet name for the typed link. — shape: {SchemaArn?: string, TypedLinkName?: string}
  attributes: list # A set of attributes that are associated with the typed link. — item shape: {AttributeName: string, Value: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/typedlink/attach"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: SourceObjectReference, var: source_object_reference}, {name: TargetObjectReference, var: target_object_reference}, {name: TypedLinkFacet, var: typed_link_facet}, {name: Attributes, var: attributes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, source_object_reference: $source_object_reference, target_object_reference: $target_object_reference, typed_link_facet: $typed_link_facet, attributes: $attributes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Performs all the read operations in a batch.
#
# POST /amazonclouddirectory/2017-01-11/batchread
# Returns: record<Responses: table<SuccessfulResponse: record, ExceptionResponse: record>>
# operationId: BatchRead
export def "batch-read" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory. For more information, see arns. (required)
  --x-amz-consistency-level: string@x-amz-consistency-level-completer # Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  operations: list # A list of operations that are part of the batch. — item shape: {ListObjectAttributes?: record, ListObjectChildren?: record, ListAttachedIndices?: record, ListObjectParentPaths?: record, GetObjectInformation?: record, GetObjectAttributes?: record, ListObjectParents?: record, ListObjectPolicies?: record, ListPolicyAttachments?: record, LookupPolicy?: record, ListIndex?: record, ListOutgoingTypedLinks?: record, ListIncomingTypedLinks?: record, GetLinkAttributes?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/amazonclouddirectory/2017-01-11/batchread"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}, {name: x-amz-consistency-level, var: x_amz_consistency_level}]
    body: {content_type: "application/json", kind: json, fields: [{name: Operations, var: operations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, x_amz_consistency_level: $x_amz_consistency_level, operations: $operations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Performs all the write operations in a batch. Either all the operations succeed or none.
#
# PUT /amazonclouddirectory/2017-01-11/batchwrite
# Returns: record<Responses: table<CreateObject: record, AttachObject: record, DetachObject: record, UpdateObjectAttributes: record, DeleteObject: record, AddFacetToObject: record, RemoveFacetFromObject: record, AttachPolicy: record, DetachPolicy: record, CreateIndex: record, AttachToIndex: record, DetachFromIndex: record, AttachTypedLink: record, DetachTypedLink: record, UpdateLinkAttributes: record>>
# operationId: BatchWrite
export def "batch-write" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory. For more information, see arns. (required)
  operations: list # A list of operations that are part of the batch. — item shape: {CreateObject?: record, AttachObject?: record, DetachObject?: record, UpdateObjectAttributes?: record, DeleteObject?: record, AddFacetToObject?: record, RemoveFacetFromObject?: record, AttachPolicy?: record, DetachPolicy?: record, CreateIndex?: record, AttachToIndex?: record, DetachFromIndex?: record, AttachTypedLink?: record, DetachTypedLink?: record, UpdateLinkAttributes?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/batchwrite"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Operations, var: operations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, operations: $operations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Directory by copying the published schema into the directory. A directory cannot be created without a schema. You can also quickly create a directory using a managed schema, called the QuickStartSchema. For more information, see Managed Schema (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_managed.html) in the Amazon Cloud Directory Developer Guide.
#
# PUT /amazonclouddirectory/2017-01-11/directory/create
# Returns: record<DirectoryArn: string, Name: string, ObjectIdentifier: string, AppliedSchemaArn: string>
# operationId: CreateDirectory
export def "create-directory" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) of the published schema that will be copied into the data Directory. For more information, see arns. (required)
  name: string # The name of the Directory. Should be unique per account, per region.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/directory/create"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Facet in a schema. Facet creation is allowed only in development or applied schemas.
#
# PUT /amazonclouddirectory/2017-01-11/facet/create
# Returns: record
# operationId: CreateFacet
export def "create-facet" [
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
  --x-amz-data-partition: string # The schema ARN in which the new Facet will be created. For more information, see arns. (required)
  name: string # The name of the Facet, which is unique for a given schema.
  --attributes: list # The attributes that are associated with the Facet. — item shape: {Name: string, AttributeDefinition?: record, AttributeReference?: record, RequiredBehavior?: "REQUIRED_ALWAYS"|"NOT_REQUIRED"}
  --object-type: string@object-type-completer # Specifies whether a given object created from this facet is of type node, leaf node, policy or index. Node: Can have multiple children but one parent. Leaf node: Cannot have children but can have multiple parents. Policy: Allows you to store a policy document and policy type. For more information, see Policies (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directory.html#key_concepts_policies). Index: Can be created with the Index API.
  --facet-style: string@facet-style-completer # There are two different styles that you can define on any given facet, Static and Dynamic. For static facets, all attributes must be defined in the schema. For dynamic facets, attributes can be defined during data plane operations.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/facet/create"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Attributes, var: attributes}, {name: ObjectType, var: object_type}, {name: FacetStyle, var: facet_style}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, name: $name, attributes: $attributes, object_type: $object_type, facet_style: $facet_style
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an index object. See Indexing and search (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/indexing_search.html) for more information.
#
# PUT /amazonclouddirectory/2017-01-11/index
# Returns: record<ObjectIdentifier: string>
# operationId: CreateIndex
export def "create-index" [
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
  --x-amz-data-partition: string # The ARN of the directory where the index should be created. (required)
  ordered_indexed_attribute_list: list # Specifies the attributes that should be indexed on. Currently only a single attribute is supported. — item shape: {SchemaArn: string, FacetName: string, Name: string}
  --is-unique: oneof<nothing, bool> # Indicates whether the attribute that is being indexed has unique values or not.
  --parent-reference: record # The reference that identifies an object. — shape: {Selector?: string}
  --link-name: string # The name of the link between the parent object and the index object.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/index"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: OrderedIndexedAttributeList, var: ordered_indexed_attribute_list}, {name: IsUnique, var: is_unique, required: true}, {name: ParentReference, var: parent_reference}, {name: LinkName, var: link_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, ordered_indexed_attribute_list: $ordered_indexed_attribute_list, is_unique: $is_unique, parent_reference: $parent_reference, link_name: $link_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an object in a Directory. Additionally attaches the object to a parent, if a parent reference and LinkName is specified. An object is simply a collection of Facet attributes. You can also use this API call to create a policy object, if the facet from which you create the object is a policy facet.
#
# PUT /amazonclouddirectory/2017-01-11/object
# Returns: record<ObjectIdentifier: string>
# operationId: CreateObject
export def "create-object" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory in which the object will be created. For more information, see arns. (required)
  schema_facets: list # A list of schema facets to be associated with the object. Do not provide minor version components. See SchemaFacet for details. — item shape: {SchemaArn?: string, FacetName?: string}
  --object-attribute-list: list # The attribute map whose attribute ARN contains the key and attribute value as the map value. — item shape: {Key: record, Value: record}
  --parent-reference: record # The reference that identifies an object. — shape: {Selector?: string}
  --link-name: string # The name of link that is used to attach this object to a parent.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/object"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: SchemaFacets, var: schema_facets}, {name: ObjectAttributeList, var: object_attribute_list}, {name: ParentReference, var: parent_reference}, {name: LinkName, var: link_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, schema_facets: $schema_facets, object_attribute_list: $object_attribute_list, parent_reference: $parent_reference, link_name: $link_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new schema in a development state. A schema can exist in three phases: Development: This is a mutable phase of the schema. All new schemas are in the development phase. Once the schema is finalized, it can be published. Published: Published schemas are immutable and have a version associated with them. Applied: Applied schemas are mutable in a way that allows you to add new schema facets. You can also add new, nonrequired attributes to existing schema facets. You can apply only published schemas to directories.
#
# PUT /amazonclouddirectory/2017-01-11/schema/create
# Returns: record<SchemaArn: string>
# operationId: CreateSchema
export def "create-schema" [
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
  name: string # The name that is associated with the schema. This is unique to each account and in each region.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/schema/create"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a TypedLinkFacet. For more information, see Typed Links (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink).
#
# PUT /amazonclouddirectory/2017-01-11/typedlink/facet/create
# Returns: record
# operationId: CreateTypedLinkFacet
export def "create-typed-link-facet" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the schema. For more information, see arns. (required)
  facet: record # Defines the typed links structure and its attributes. To create a typed link facet, use the CreateTypedLinkFacet API. — shape: {Name?: string, Attributes?: list, IdentityAttributeOrder?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/typedlink/facet/create"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Facet, var: facet}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, facet: $facet
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a directory. Only disabled directories can be deleted. A deleted directory cannot be undone. Exercise extreme caution when deleting directories.
#
# PUT /amazonclouddirectory/2017-01-11/directory
# Returns: record<DirectoryArn: string>
# operationId: DeleteDirectory
export def "delete-directory" [
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
  --x-amz-data-partition: string # The ARN of the directory to delete. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/directory"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a given Facet. All attributes and Rules that are associated with the facet will be deleted. Only development schema facets are allowed deletion.
#
# PUT /amazonclouddirectory/2017-01-11/facet/delete
# Returns: record
# operationId: DeleteFacet
export def "delete-facet" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Facet. For more information, see arns. (required)
  name: string # The name of the facet to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/facet/delete"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an object and its associated attributes. Only objects with no children and no parents can be deleted. The maximum number of attributes that can be deleted during an object deletion is 30. For more information, see Amazon Cloud Directory Limits (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/limits.html).
#
# PUT /amazonclouddirectory/2017-01-11/object/delete
# Returns: record
# operationId: DeleteObject
export def "delete-object" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory where the object resides. For more information, see arns. (required)
  object_reference: record # The reference that identifies an object. — shape: {Selector?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/object/delete"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: ObjectReference, var: object_reference}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, object_reference: $object_reference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a given schema. Schemas in a development and published state can only be deleted.
#
# PUT /amazonclouddirectory/2017-01-11/schema
# Returns: record<SchemaArn: string>
# operationId: DeleteSchema
export def "delete-schema" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) of the development schema. For more information, see arns. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/schema"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a TypedLinkFacet. For more information, see Typed Links (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink).
#
# PUT /amazonclouddirectory/2017-01-11/typedlink/facet/delete
# Returns: record
# operationId: DeleteTypedLinkFacet
export def "delete-typed-link-facet" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the schema. For more information, see arns. (required)
  name: string # The unique name of the typed link facet.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/typedlink/facet/delete"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detaches the specified object from the specified index.
#
# PUT /amazonclouddirectory/2017-01-11/index/detach
# Returns: record<DetachedObjectIdentifier: string>
# operationId: DetachFromIndex
export def "detach-from-index" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) of the directory the index and object exist in. (required)
  index_reference: record # The reference that identifies an object. — shape: {Selector?: string}
  target_reference: record # The reference that identifies an object. — shape: {Selector?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/index/detach"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexReference, var: index_reference}, {name: TargetReference, var: target_reference}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, index_reference: $index_reference, target_reference: $target_reference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detaches a given object from the parent object. The object that is to be detached from the parent is specified by the link name.
#
# PUT /amazonclouddirectory/2017-01-11/object/detach
# Returns: record<DetachedObjectIdentifier: string>
# operationId: DetachObject
export def "detach-object" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory where objects reside. For more information, see arns. (required)
  parent_reference: record # The reference that identifies an object. — shape: {Selector?: string}
  link_name: string # The link name associated with the object that needs to be detached.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/object/detach"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: ParentReference, var: parent_reference}, {name: LinkName, var: link_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, parent_reference: $parent_reference, link_name: $link_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detaches a policy from an object.
#
# PUT /amazonclouddirectory/2017-01-11/policy/detach
# Returns: record
# operationId: DetachPolicy
export def "detach-policy" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory where both objects reside. For more information, see arns. (required)
  policy_reference: record # The reference that identifies an object. — shape: {Selector?: string}
  object_reference: record # The reference that identifies an object. — shape: {Selector?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/policy/detach"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: PolicyReference, var: policy_reference}, {name: ObjectReference, var: object_reference}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, policy_reference: $policy_reference, object_reference: $object_reference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detaches a typed link from a specified source and target object. For more information, see Typed Links (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink).
#
# PUT /amazonclouddirectory/2017-01-11/typedlink/detach
# operationId: DetachTypedLink
export def "detach-typed-link" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) of the directory where you want to detach the typed link. (required)
  typed_link_specifier: record # Contains all the information that is used to uniquely identify a typed link. The parameters discussed in this topic are used to uniquely specify the typed link being operated on. The AttachTypedLink API returns a typed link specifier while the DetachTypedLink API accepts one as input. Similarly, the ListIncomingTypedLinks and ListOutgoingTypedLinks API operations provide typed link specifiers as output. You can also construct a typed link specifier from scratch. — shape: {TypedLinkFacet?: record, SourceObjectReference?: record, TargetObjectReference?: record, IdentityAttributeValues?: list}
]: any -> any {
  $in | http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/typedlink/detach"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: TypedLinkSpecifier, var: typed_link_specifier}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, typed_link_specifier: $typed_link_specifier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables the specified directory. Disabled directories cannot be read or written to. Only enabled directories can be disabled. Disabled directories may be reenabled.
#
# PUT /amazonclouddirectory/2017-01-11/directory/disable
# Returns: record<DirectoryArn: string>
# operationId: DisableDirectory
export def "disable-directory" [
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
  --x-amz-data-partition: string # The ARN of the directory to disable. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/directory/disable"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables the specified directory. Only disabled directories can be enabled. Once enabled, the directory can then be read and written to.
#
# PUT /amazonclouddirectory/2017-01-11/directory/enable
# Returns: record<DirectoryArn: string>
# operationId: EnableDirectory
export def "enable-directory" [
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
  --x-amz-data-partition: string # The ARN of the directory to enable. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/directory/enable"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns current applied schema version ARN, including the minor version in use.
#
# POST /amazonclouddirectory/2017-01-11/schema/getappliedschema
# Returns: record<AppliedSchemaArn: string>
# operationId: GetAppliedSchemaVersion
export def "get-applied-schema-version" [
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
  schema_arn: string # The ARN of the applied schema.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/amazonclouddirectory/2017-01-11/schema/getappliedschema"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: SchemaArn, var: schema_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, schema_arn: $schema_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves metadata about a directory.
#
# POST /amazonclouddirectory/2017-01-11/directory/get
# Returns: record<Directory: record<Name: string, DirectoryArn: string, State: string, CreationDateTime: string>>
# operationId: GetDirectory
export def "get-directory" [
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
  --x-amz-data-partition: string # The ARN of the directory. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/amazonclouddirectory/2017-01-11/directory/get"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets details of the Facet, such as facet name, attributes, Rules, or ObjectType. You can call this on all kinds of schema facets -- published, development, or applied.
#
# POST /amazonclouddirectory/2017-01-11/facet
# Returns: record<Facet: record<Name: string, ObjectType: string, FacetStyle: string>>
# operationId: GetFacet
export def "get-facet" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Facet. For more information, see arns. (required)
  name: string # The name of the facet to retrieve.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/amazonclouddirectory/2017-01-11/facet"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Does the following: Adds new Attributes, Rules, or ObjectTypes. Updates existing Attributes, Rules, or ObjectTypes. Deletes existing Attributes, Rules, or ObjectTypes.
#
# PUT /amazonclouddirectory/2017-01-11/facet
# Returns: record
# operationId: UpdateFacet
export def "update-facet" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Facet. For more information, see arns. (required)
  name: string # The name of the facet.
  --attribute-updates: list # List of attributes that need to be updated in a given schema Facet. Each attribute is followed by AttributeAction, which specifies the type of update operation to perform. — item shape: {Attribute?: record, Action?: "CREATE_OR_UPDATE"|"DELETE"}
  --object-type: string@object-type-completer # The object type that is associated with the facet. See CreateFacetRequest$ObjectType for more details.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/facet"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: AttributeUpdates, var: attribute_updates}, {name: ObjectType, var: object_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, name: $name, attribute_updates: $attribute_updates, object_type: $object_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves attributes that are associated with a typed link.
#
# POST /amazonclouddirectory/2017-01-11/typedlink/attributes/get
# Returns: record<Attributes: table<Key: record, Value: record>>
# operationId: GetLinkAttributes
export def "get-link-attributes" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory where the typed link resides. For more information, see arns or Typed Links (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink). (required)
  typed_link_specifier: record # Contains all the information that is used to uniquely identify a typed link. The parameters discussed in this topic are used to uniquely specify the typed link being operated on. The AttachTypedLink API returns a typed link specifier while the DetachTypedLink API accepts one as input. Similarly, the ListIncomingTypedLinks and ListOutgoingTypedLinks API operations provide typed link specifiers as output. You can also construct a typed link specifier from scratch. — shape: {TypedLinkFacet?: record, SourceObjectReference?: record, TargetObjectReference?: record, IdentityAttributeValues?: list}
  attribute_names: list<string> # A list of attribute names whose values will be retrieved.
  --consistency-level: string@consistency-level-completer # The consistency level at which to retrieve the attributes on a typed link.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/amazonclouddirectory/2017-01-11/typedlink/attributes/get"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: TypedLinkSpecifier, var: typed_link_specifier}, {name: AttributeNames, var: attribute_names}, {name: ConsistencyLevel, var: consistency_level}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, typed_link_specifier: $typed_link_specifier, attribute_names: $attribute_names, consistency_level: $consistency_level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves attributes within a facet that are associated with an object.
#
# POST /amazonclouddirectory/2017-01-11/object/attributes/get
# Returns: record<Attributes: table<Key: record, Value: record>>
# operationId: GetObjectAttributes
export def "get-object-attributes" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory where the object resides. (required)
  --x-amz-consistency-level: string@x-amz-consistency-level-completer # The consistency level at which to retrieve the attributes on an object.
  object_reference: record # The reference that identifies an object. — shape: {Selector?: string}
  schema_facet: record # A facet. — shape: {SchemaArn?: string, FacetName?: string}
  attribute_names: list<string> # List of attribute names whose values will be retrieved.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/amazonclouddirectory/2017-01-11/object/attributes/get"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}, {name: x-amz-consistency-level, var: x_amz_consistency_level}]
    body: {content_type: "application/json", kind: json, fields: [{name: ObjectReference, var: object_reference}, {name: SchemaFacet, var: schema_facet}, {name: AttributeNames, var: attribute_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, x_amz_consistency_level: $x_amz_consistency_level, object_reference: $object_reference, schema_facet: $schema_facet, attribute_names: $attribute_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves metadata about an object.
#
# POST /amazonclouddirectory/2017-01-11/object/information
# Returns: record<SchemaFacets: table<SchemaArn: string, FacetName: string>, ObjectIdentifier: string>
# operationId: GetObjectInformation
export def "get-object-information" [
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
  --x-amz-data-partition: string # The ARN of the directory being retrieved. (required)
  --x-amz-consistency-level: string@x-amz-consistency-level-completer # The consistency level at which to retrieve the object information.
  object_reference: record # The reference that identifies an object. — shape: {Selector?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/amazonclouddirectory/2017-01-11/object/information"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}, {name: x-amz-consistency-level, var: x_amz_consistency_level}]
    body: {content_type: "application/json", kind: json, fields: [{name: ObjectReference, var: object_reference}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, x_amz_consistency_level: $x_amz_consistency_level, object_reference: $object_reference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a JSON representation of the schema. See JSON Schema Format (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_jsonformat.html#schemas_json) for more information.
#
# POST /amazonclouddirectory/2017-01-11/schema/json
# Returns: record<Name: string, Document: string>
# operationId: GetSchemaAsJson
export def "get-schema-as-json" [
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
  --x-amz-data-partition: string # The ARN of the schema to retrieve. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/amazonclouddirectory/2017-01-11/schema/json"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows a schema to be updated using JSON upload. Only available for development schemas. See JSON Schema Format (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_jsonformat.html#schemas_json) for more information.
#
# PUT /amazonclouddirectory/2017-01-11/schema/json
# Returns: record<Arn: string>
# operationId: PutSchemaFromJson
export def "put-schema-from-json" [
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
  --x-amz-data-partition: string # The ARN of the schema to update. (required)
  document: string # The replacement JSON schema.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/schema/json"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Document, var: document}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, document: $document
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the identity attribute order for a specific TypedLinkFacet. For more information, see Typed Links (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink).
#
# POST /amazonclouddirectory/2017-01-11/typedlink/facet/get
# Returns: record<IdentityAttributeOrder: list<string>>
# operationId: GetTypedLinkFacetInformation
export def "get-typed-link-facet-information" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the schema. For more information, see arns. (required)
  name: string # The unique name of the typed link facet.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/amazonclouddirectory/2017-01-11/typedlink/facet/get"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists schema major versions applied to a directory. If SchemaArn is provided, lists the minor version.
#
# POST /amazonclouddirectory/2017-01-11/schema/applied
# Returns: record<SchemaArns: list<string>, NextToken: string>
# operationId: ListAppliedSchemaArns
export def "list-applied-schema-arns" [
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
  directory_arn: string # The ARN of the directory you are listing.
  --schema-arn: string # The response for ListAppliedSchemaArns when this parameter is used will list all minor version ARNs for a major version.
  --body-next-token: string # The pagination token. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to retrieve. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/amazonclouddirectory/2017-01-11/schema/applied"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: DirectoryArn, var: directory_arn}, {name: SchemaArn, var: schema_arn}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, directory_arn: $directory_arn, schema_arn: $schema_arn, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists indices attached to the specified object.
#
# POST /amazonclouddirectory/2017-01-11/object/indices
# Returns: record<IndexAttachments: table<IndexedAttributes: list, ObjectIdentifier: string>, NextToken: string>
# operationId: ListAttachedIndices
export def "list-attached-indices" [
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
  --x-amz-data-partition: string # The ARN of the directory. (required)
  --x-amz-consistency-level: string@x-amz-consistency-level-completer # The consistency level to use for this operation.
  target_reference: record # The reference that identifies an object. — shape: {Selector?: string}
  --body-next-token: string # The pagination token. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to retrieve. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/amazonclouddirectory/2017-01-11/object/indices"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}, {name: x-amz-consistency-level, var: x_amz_consistency_level}]
    body: {content_type: "application/json", kind: json, fields: [{name: TargetReference, var: target_reference}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, x_amz_consistency_level: $x_amz_consistency_level, target_reference: $target_reference, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves each Amazon Resource Name (ARN) of schemas in the development state.
#
# POST /amazonclouddirectory/2017-01-11/schema/development
# Returns: record<SchemaArns: list<string>, NextToken: string>
# operationId: ListDevelopmentSchemaArns
export def "list-development-schema-arns" [
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
  --body-next-token: string # The pagination token. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to retrieve. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/amazonclouddirectory/2017-01-11/schema/development"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists directories created within an account.
#
# POST /amazonclouddirectory/2017-01-11/directory/list
# Returns: record<Directories: table<Name: string, DirectoryArn: string, State: string, CreationDateTime: string>, NextToken: string>
# operationId: ListDirectories
export def "list-directories" [
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
  --body-next-token: string # The pagination token. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to retrieve. (spec name: MaxResults)
  --state: string@state-completer # The state of the directories in the list. Can be either Enabled, Disabled, or Deleted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/amazonclouddirectory/2017-01-11/directory/list"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: state, var: state}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body_next_token: $body_next_token, body_max_results: $body_max_results, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves attributes attached to the facet.
#
# POST /amazonclouddirectory/2017-01-11/facet/attributes
# Returns: record<Attributes: table<Name: string, AttributeDefinition: record, AttributeReference: record, RequiredBehavior: string>, NextToken: string>
# operationId: ListFacetAttributes
export def "list-facet-attributes" [
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
  --x-amz-data-partition: string # The ARN of the schema where the facet resides. (required)
  name: string # The name of the facet whose attributes will be retrieved.
  --body-next-token: string # The pagination token. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to retrieve. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/amazonclouddirectory/2017-01-11/facet/attributes"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, name: $name, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the names of facets that exist in a schema.
#
# POST /amazonclouddirectory/2017-01-11/facet/list
# Returns: record<FacetNames: list<string>, NextToken: string>
# operationId: ListFacetNames
export def "list-facet-names" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) to retrieve facet names from. (required)
  --body-next-token: string # The pagination token. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to retrieve. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/amazonclouddirectory/2017-01-11/facet/list"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a paginated list of all the incoming TypedLinkSpecifier information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see Typed Links (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink).
#
# POST /amazonclouddirectory/2017-01-11/typedlink/incoming
# Returns: record<LinkSpecifiers: table<TypedLinkFacet: record, SourceObjectReference: record, TargetObjectReference: record, IdentityAttributeValues: list>, NextToken: string>
# operationId: ListIncomingTypedLinks
export def "list-incoming-typed-links" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) of the directory where you want to list the typed links. (required)
  object_reference: record # The reference that identifies an object. — shape: {Selector?: string}
  --filter-attribute-ranges: list # Provides range filters for multiple attributes. When providing ranges to typed link selection, any inexact ranges must be specified at the end. Any attributes that do not have a range specified are presumed to match the entire range. — item shape: {AttributeName?: string, Range: record}
  --filter-typed-link: record # Identifies the schema Amazon Resource Name (ARN) and facet name for the typed link. — shape: {SchemaArn?: string, TypedLinkName?: string}
  --next-token: string # The pagination token.
  --max-results: int # The maximum number of results to retrieve.
  --consistency-level: string@consistency-level-completer # The consistency level to execute the request at.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/amazonclouddirectory/2017-01-11/typedlink/incoming"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: ObjectReference, var: object_reference}, {name: FilterAttributeRanges, var: filter_attribute_ranges}, {name: FilterTypedLink, var: filter_typed_link}, {name: NextToken, var: next_token}, {name: MaxResults, var: max_results}, {name: ConsistencyLevel, var: consistency_level}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, object_reference: $object_reference, filter_attribute_ranges: $filter_attribute_ranges, filter_typed_link: $filter_typed_link, next_token: $next_token, max_results: $max_results, consistency_level: $consistency_level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists objects attached to the specified index.
#
# POST /amazonclouddirectory/2017-01-11/index/targets
# Returns: record<IndexAttachments: table<IndexedAttributes: list, ObjectIdentifier: string>, NextToken: string>
# operationId: ListIndex
export def "list-index" [
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
  --x-amz-data-partition: string # The ARN of the directory that the index exists in. (required)
  --x-amz-consistency-level: string@x-amz-consistency-level-completer # The consistency level to execute the request at.
  --ranges-on-indexed-values: list # Specifies the ranges of indexed values that you want to query. — item shape: {AttributeKey?: record, Range?: record}
  index_reference: record # The reference that identifies an object. — shape: {Selector?: string}
  --body-max-results: int # The maximum number of objects in a single page to retrieve from the index during a request. For more information, see Amazon Cloud Directory Limits (http://docs.aws.amazon.com/clouddirectory/latest/developerguide/limits.html). (spec name: MaxResults)
  --body-next-token: string # The pagination token. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/amazonclouddirectory/2017-01-11/index/targets"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}, {name: x-amz-consistency-level, var: x_amz_consistency_level}]
    body: {content_type: "application/json", kind: json, fields: [{name: RangesOnIndexedValues, var: ranges_on_indexed_values}, {name: IndexReference, var: index_reference}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, x_amz_consistency_level: $x_amz_consistency_level, ranges_on_indexed_values: $ranges_on_indexed_values, index_reference: $index_reference, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the major version families of each managed schema. If a major version ARN is provided as SchemaArn, the minor version revisions in that family are listed instead.
#
# POST /amazonclouddirectory/2017-01-11/schema/managed
# Returns: record<SchemaArns: list<string>, NextToken: string>
# operationId: ListManagedSchemaArns
export def "list-managed-schema-arns" [
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
  --schema-arn: string # The response for ListManagedSchemaArns. When this parameter is used, all minor version ARNs for a major version are listed.
  --body-next-token: string # The pagination token. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to retrieve. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/amazonclouddirectory/2017-01-11/schema/managed"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: SchemaArn, var: schema_arn}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, schema_arn: $schema_arn, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all attributes that are associated with an object.
#
# POST /amazonclouddirectory/2017-01-11/object/attributes
# Returns: record<Attributes: table<Key: record, Value: record>, NextToken: string>
# operationId: ListObjectAttributes
export def "list-object-attributes" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory where the object resides. For more information, see arns. (required)
  --x-amz-consistency-level: string@x-amz-consistency-level-completer # Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  object_reference: record # The reference that identifies an object. — shape: {Selector?: string}
  --body-next-token: string # The pagination token. (spec name: NextToken)
  --body-max-results: int # The maximum number of items to be retrieved in a single call. This is an approximate number. (spec name: MaxResults)
  --facet-filter: record # A facet. — shape: {SchemaArn?: string, FacetName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/amazonclouddirectory/2017-01-11/object/attributes"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}, {name: x-amz-consistency-level, var: x_amz_consistency_level}]
    body: {content_type: "application/json", kind: json, fields: [{name: ObjectReference, var: object_reference}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: FacetFilter, var: facet_filter}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, x_amz_consistency_level: $x_amz_consistency_level, object_reference: $object_reference, body_next_token: $body_next_token, body_max_results: $body_max_results, facet_filter: $facet_filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a paginated list of child objects that are associated with a given object.
#
# POST /amazonclouddirectory/2017-01-11/object/children
# Returns: record<Children: record, NextToken: string>
# operationId: ListObjectChildren
export def "list-object-children" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory where the object resides. For more information, see arns. (required)
  --x-amz-consistency-level: string@x-amz-consistency-level-completer # Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  object_reference: record # The reference that identifies an object. — shape: {Selector?: string}
  --body-next-token: string # The pagination token. (spec name: NextToken)
  --body-max-results: int # The maximum number of items to be retrieved in a single call. This is an approximate number. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/amazonclouddirectory/2017-01-11/object/children"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}, {name: x-amz-consistency-level, var: x_amz_consistency_level}]
    body: {content_type: "application/json", kind: json, fields: [{name: ObjectReference, var: object_reference}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, x_amz_consistency_level: $x_amz_consistency_level, object_reference: $object_reference, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves all available parent paths for any object type such as node, leaf node, policy node, and index node objects. For more information about objects, see Directory Structure (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directorystructure.html). Use this API to evaluate all parents for an object. The call returns all objects from the root of the directory up to the requested object. The API returns the number of paths based on user-defined MaxResults, in case there are multiple paths to the parent. The order of the paths and nodes returned is consistent among multiple API calls unless the objects are deleted or moved. Paths not leading to the directory root are ignored from the target object.
#
# POST /amazonclouddirectory/2017-01-11/object/parentpaths
# Returns: record<PathToObjectIdentifiersList: table<Path: string, ObjectIdentifiers: list>, NextToken: string>
# operationId: ListObjectParentPaths
export def "list-object-parent-paths" [
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
  --x-amz-data-partition: string # The ARN of the directory to which the parent path applies. (required)
  object_reference: record # The reference that identifies an object. — shape: {Selector?: string}
  --body-next-token: string # The pagination token. (spec name: NextToken)
  --body-max-results: int # The maximum number of items to be retrieved in a single call. This is an approximate number. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/amazonclouddirectory/2017-01-11/object/parentpaths"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: ObjectReference, var: object_reference}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, object_reference: $object_reference, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists parent objects that are associated with a given object in pagination fashion.
#
# POST /amazonclouddirectory/2017-01-11/object/parent
# Returns: record<Parents: record, NextToken: string, ParentLinks: table<ObjectIdentifier: string, LinkName: string>>
# operationId: ListObjectParents
export def "list-object-parents" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory where the object resides. For more information, see arns. (required)
  --x-amz-consistency-level: string@x-amz-consistency-level-completer # Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  object_reference: record # The reference that identifies an object. — shape: {Selector?: string}
  --body-next-token: string # The pagination token. (spec name: NextToken)
  --body-max-results: int # The maximum number of items to be retrieved in a single call. This is an approximate number. (spec name: MaxResults)
  --include-all-links-to-each-parent: oneof<nothing, bool> # When set to True, returns all ListObjectParentsResponse$ParentLinks. There could be multiple links between a parent-child pair.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/amazonclouddirectory/2017-01-11/object/parent"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}, {name: x-amz-consistency-level, var: x_amz_consistency_level}]
    body: {content_type: "application/json", kind: json, fields: [{name: ObjectReference, var: object_reference}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: IncludeAllLinksToEachParent, var: include_all_links_to_each_parent}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, x_amz_consistency_level: $x_amz_consistency_level, object_reference: $object_reference, body_next_token: $body_next_token, body_max_results: $body_max_results, include_all_links_to_each_parent: $include_all_links_to_each_parent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns policies attached to an object in pagination fashion.
#
# POST /amazonclouddirectory/2017-01-11/object/policy
# Returns: record<AttachedPolicyIds: list<string>, NextToken: string>
# operationId: ListObjectPolicies
export def "list-object-policies" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory where objects reside. For more information, see arns. (required)
  --x-amz-consistency-level: string@x-amz-consistency-level-completer # Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  object_reference: record # The reference that identifies an object. — shape: {Selector?: string}
  --body-next-token: string # The pagination token. (spec name: NextToken)
  --body-max-results: int # The maximum number of items to be retrieved in a single call. This is an approximate number. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/amazonclouddirectory/2017-01-11/object/policy"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}, {name: x-amz-consistency-level, var: x_amz_consistency_level}]
    body: {content_type: "application/json", kind: json, fields: [{name: ObjectReference, var: object_reference}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, x_amz_consistency_level: $x_amz_consistency_level, object_reference: $object_reference, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a paginated list of all the outgoing TypedLinkSpecifier information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see Typed Links (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink).
#
# POST /amazonclouddirectory/2017-01-11/typedlink/outgoing
# Returns: record<TypedLinkSpecifiers: table<TypedLinkFacet: record, SourceObjectReference: record, TargetObjectReference: record, IdentityAttributeValues: list>, NextToken: string>
# operationId: ListOutgoingTypedLinks
export def "list-outgoing-typed-links" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) of the directory where you want to list the typed links. (required)
  object_reference: record # The reference that identifies an object. — shape: {Selector?: string}
  --filter-attribute-ranges: list # Provides range filters for multiple attributes. When providing ranges to typed link selection, any inexact ranges must be specified at the end. Any attributes that do not have a range specified are presumed to match the entire range. — item shape: {AttributeName?: string, Range: record}
  --filter-typed-link: record # Identifies the schema Amazon Resource Name (ARN) and facet name for the typed link. — shape: {SchemaArn?: string, TypedLinkName?: string}
  --next-token: string # The pagination token.
  --max-results: int # The maximum number of results to retrieve.
  --consistency-level: string@consistency-level-completer # The consistency level to execute the request at.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/amazonclouddirectory/2017-01-11/typedlink/outgoing"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: ObjectReference, var: object_reference}, {name: FilterAttributeRanges, var: filter_attribute_ranges}, {name: FilterTypedLink, var: filter_typed_link}, {name: NextToken, var: next_token}, {name: MaxResults, var: max_results}, {name: ConsistencyLevel, var: consistency_level}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, object_reference: $object_reference, filter_attribute_ranges: $filter_attribute_ranges, filter_typed_link: $filter_typed_link, next_token: $next_token, max_results: $max_results, consistency_level: $consistency_level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all of the ObjectIdentifiers to which a given policy is attached.
#
# POST /amazonclouddirectory/2017-01-11/policy/attachment
# Returns: record<ObjectIdentifiers: list<string>, NextToken: string>
# operationId: ListPolicyAttachments
export def "list-policy-attachments" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory where objects reside. For more information, see arns. (required)
  --x-amz-consistency-level: string@x-amz-consistency-level-completer # Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  policy_reference: record # The reference that identifies an object. — shape: {Selector?: string}
  --body-next-token: string # The pagination token. (spec name: NextToken)
  --body-max-results: int # The maximum number of items to be retrieved in a single call. This is an approximate number. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/amazonclouddirectory/2017-01-11/policy/attachment"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}, {name: x-amz-consistency-level, var: x_amz_consistency_level}]
    body: {content_type: "application/json", kind: json, fields: [{name: PolicyReference, var: policy_reference}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, x_amz_consistency_level: $x_amz_consistency_level, policy_reference: $policy_reference, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the major version families of each published schema. If a major version ARN is provided as SchemaArn, the minor version revisions in that family are listed instead.
#
# POST /amazonclouddirectory/2017-01-11/schema/published
# Returns: record<SchemaArns: list<string>, NextToken: string>
# operationId: ListPublishedSchemaArns
export def "list-published-schema-arns" [
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
  --schema-arn: string # The response for ListPublishedSchemaArns when this parameter is used will list all minor version ARNs for a major version.
  --body-next-token: string # The pagination token. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to retrieve. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/amazonclouddirectory/2017-01-11/schema/published"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: SchemaArn, var: schema_arn}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, schema_arn: $schema_arn, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns tags for a resource. Tagging is currently supported only for directories with a limit of 50 tags per directory. All 50 tags are returned for a given directory with this API call.
#
# POST /amazonclouddirectory/2017-01-11/tags
# Returns: record<Tags: table<Key: string, Value: string>, NextToken: string>
# operationId: ListTagsForResource
export def "list-tags-for-resource" [
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
  resource_arn: string # The Amazon Resource Name (ARN) of the resource. Tagging is only supported for directories.
  --body-next-token: string # The pagination token. This is for future use. Currently pagination is not supported for tagging. (spec name: NextToken)
  --body-max-results: int # The MaxResults parameter sets the maximum number of results returned in a single page. This is for future use and is not supported currently. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/amazonclouddirectory/2017-01-11/tags"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, resource_arn: $resource_arn, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a paginated list of all attribute definitions for a particular TypedLinkFacet. For more information, see Typed Links (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink).
#
# POST /amazonclouddirectory/2017-01-11/typedlink/facet/attributes
# Returns: record<Attributes: table<Name: string, Type: string, DefaultValue: record, IsImmutable: bool, Rules: record, RequiredBehavior: string>, NextToken: string>
# operationId: ListTypedLinkFacetAttributes
export def "list-typed-link-facet-attributes" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the schema. For more information, see arns. (required)
  name: string # The unique name of the typed link facet.
  --body-next-token: string # The pagination token. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to retrieve. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/amazonclouddirectory/2017-01-11/typedlink/facet/attributes"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, name: $name, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a paginated list of TypedLink facet names for a particular schema. For more information, see Typed Links (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink).
#
# POST /amazonclouddirectory/2017-01-11/typedlink/facet/list
# Returns: record<FacetNames: list<string>, NextToken: string>
# operationId: ListTypedLinkFacetNames
export def "list-typed-link-facet-names" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the schema. For more information, see arns. (required)
  --body-next-token: string # The pagination token. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to retrieve. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/amazonclouddirectory/2017-01-11/typedlink/facet/list"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all policies from the root of the Directory to the object specified. If there are no policies present, an empty list is returned. If policies are present, and if some objects don't have the policies attached, it returns the ObjectIdentifier for such objects. If policies are present, it returns ObjectIdentifier, policyId, and policyType. Paths that don't lead to the root from the target object are ignored. For more information, see Policies (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directory.html#key_concepts_policies).
#
# POST /amazonclouddirectory/2017-01-11/policy/lookup
# Returns: record<PolicyToPathList: table<Path: string, Policies: list>, NextToken: string>
# operationId: LookupPolicy
export def "lookup-policy" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory. For more information, see arns. (required)
  object_reference: record # The reference that identifies an object. — shape: {Selector?: string}
  --body-next-token: string # The token to request the next page of results. (spec name: NextToken)
  --body-max-results: int # The maximum number of items to be retrieved in a single call. This is an approximate number. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/amazonclouddirectory/2017-01-11/policy/lookup"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: ObjectReference, var: object_reference}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, object_reference: $object_reference, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Publishes a development schema with a major version and a recommended minor version.
#
# PUT /amazonclouddirectory/2017-01-11/schema/publish
# Returns: record<PublishedSchemaArn: string>
# operationId: PublishSchema
export def "publish-schema" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the development schema. For more information, see arns. (required)
  version: string # The major version under which the schema will be published. Schemas have both a major and minor version associated with them.
  --minor-version: string # The minor version under which the schema will be published. This parameter is recommended. Schemas have both a major and minor version associated with them.
  --name: string # The new name under which the schema will be published. If this is not provided, the development schema is considered.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/schema/publish"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Version, var: version}, {name: MinorVersion, var: minor_version}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, version: $version, minor_version: $minor_version, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the specified facet from the specified object.
#
# PUT /amazonclouddirectory/2017-01-11/object/facets/delete
# Returns: record
# operationId: RemoveFacetFromObject
export def "remove-facet-from-object" [
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
  --x-amz-data-partition: string # The ARN of the directory in which the object resides. (required)
  schema_facet: record # A facet. — shape: {SchemaArn?: string, FacetName?: string}
  object_reference: record # The reference that identifies an object. — shape: {Selector?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/object/facets/delete"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: SchemaFacet, var: schema_facet}, {name: ObjectReference, var: object_reference}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, schema_facet: $schema_facet, object_reference: $object_reference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# An API operation for adding tags to a resource.
#
# PUT /amazonclouddirectory/2017-01-11/tags/add
# Returns: record
# operationId: TagResource
export def "tag-resource" [
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
  resource_arn: string # The Amazon Resource Name (ARN) of the resource. Tagging is only supported for directories.
  tags: list # A list of tag key-value pairs. — item shape: {Key?: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/tags/add"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, resource_arn: $resource_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# An API operation for removing tags from a resource.
#
# PUT /amazonclouddirectory/2017-01-11/tags/remove
# Returns: record
# operationId: UntagResource
export def "untag-resource" [
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
  resource_arn: string # The Amazon Resource Name (ARN) of the resource. Tagging is only supported for directories.
  tag_keys: list<string> # Keys of the tag that need to be removed from the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/tags/remove"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: TagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, resource_arn: $resource_arn, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a given typed link’s attributes. Attributes to be updated must not contribute to the typed link’s identity, as defined by its IdentityAttributeOrder.
#
# POST /amazonclouddirectory/2017-01-11/typedlink/attributes/update
# Returns: record
# operationId: UpdateLinkAttributes
export def "update-link-attributes" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory where the updated typed link resides. For more information, see arns or Typed Links (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink). (required)
  typed_link_specifier: record # Contains all the information that is used to uniquely identify a typed link. The parameters discussed in this topic are used to uniquely specify the typed link being operated on. The AttachTypedLink API returns a typed link specifier while the DetachTypedLink API accepts one as input. Similarly, the ListIncomingTypedLinks and ListOutgoingTypedLinks API operations provide typed link specifiers as output. You can also construct a typed link specifier from scratch. — shape: {TypedLinkFacet?: record, SourceObjectReference?: record, TargetObjectReference?: record, IdentityAttributeValues?: list}
  attribute_updates: list # The attributes update structure. — item shape: {AttributeKey?: record, AttributeAction?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/amazonclouddirectory/2017-01-11/typedlink/attributes/update"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: TypedLinkSpecifier, var: typed_link_specifier}, {name: AttributeUpdates, var: attribute_updates}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, typed_link_specifier: $typed_link_specifier, attribute_updates: $attribute_updates
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a given object's attributes.
#
# PUT /amazonclouddirectory/2017-01-11/object/update
# Returns: record<ObjectIdentifier: string>
# operationId: UpdateObjectAttributes
export def "update-object-attributes" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory where the object resides. For more information, see arns. (required)
  object_reference: record # The reference that identifies an object. — shape: {Selector?: string}
  attribute_updates: list # The attributes update structure. — item shape: {ObjectAttributeKey?: record, ObjectAttributeAction?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/object/update"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: ObjectReference, var: object_reference}, {name: AttributeUpdates, var: attribute_updates}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, object_reference: $object_reference, attribute_updates: $attribute_updates
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the schema name with a new name. Only development schema names can be updated.
#
# PUT /amazonclouddirectory/2017-01-11/schema/update
# Returns: record<SchemaArn: string>
# operationId: UpdateSchema
export def "update-schema" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) of the development schema. For more information, see arns. (required)
  name: string # The name of the schema.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/schema/update"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a TypedLinkFacet. For more information, see Typed Links (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink).
#
# PUT /amazonclouddirectory/2017-01-11/typedlink/facet
# Returns: record
# operationId: UpdateTypedLinkFacet
export def "update-typed-link-facet" [
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
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the schema. For more information, see arns. (required)
  name: string # The unique name of the typed link facet.
  attribute_updates: list # Attributes update structure. — item shape: {Attribute: record, Action: "CREATE_OR_UPDATE"|"DELETE"}
  identity_attribute_order: list<string> # The order of identity attributes for the facet, from most significant to least significant. The ability to filter typed links considers the order that the attributes are defined on the typed link facet. When providing ranges to a typed link selection, any inexact ranges must be specified at the end. Any attributes that do not have a range specified are presumed to match the entire range. Filters are interpreted in the order of the attributes on the typed link facet, not the order in which they are supplied to any API calls. For more information about identity attributes, see Typed Links (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/typedlink/facet"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-data-partition, var: x_amz_data_partition, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: AttributeUpdates, var: attribute_updates}, {name: IdentityAttributeOrder, var: identity_attribute_order}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_data_partition: $x_amz_data_partition, name: $name, attribute_updates: $attribute_updates, identity_attribute_order: $identity_attribute_order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upgrades a single directory in-place using the PublishedSchemaArn with schema updates found in MinorVersion. Backwards-compatible minor version upgrades are instantaneously available for readers on all objects in the directory. Note: This is a synchronous API call and upgrades only one schema on a given directory per call. To upgrade multiple directories from one schema, you would need to call this API on each directory.
#
# PUT /amazonclouddirectory/2017-01-11/schema/upgradeapplied
# Returns: record<UpgradedSchemaArn: string, DirectoryArn: string>
# operationId: UpgradeAppliedSchema
export def "upgrade-applied-schema" [
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
  published_schema_arn: string # The revision of the published schema to upgrade the directory to.
  directory_arn: string # The ARN for the directory to which the upgraded schema will be applied.
  --body-dry-run: oneof<nothing, bool> # Used for testing whether the major version schemas are backward compatible or not. If schema compatibility fails, an exception would be thrown else the call would succeed but no changes will be saved. This parameter is optional. (spec name: DryRun)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/schema/upgradeapplied"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: PublishedSchemaArn, var: published_schema_arn}, {name: DirectoryArn, var: directory_arn}, {name: DryRun, var: body_dry_run}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, published_schema_arn: $published_schema_arn, directory_arn: $directory_arn, body_dry_run: $body_dry_run
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upgrades a published schema under a new minor version revision using the current contents of DevelopmentSchemaArn.
#
# PUT /amazonclouddirectory/2017-01-11/schema/upgradepublished
# Returns: record<UpgradedSchemaArn: string>
# operationId: UpgradePublishedSchema
export def "upgrade-published-schema" [
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
  development_schema_arn: string # The ARN of the development schema with the changes used for the upgrade.
  published_schema_arn: string # The ARN of the published schema to be upgraded.
  minor_version: string # Identifies the minor version of the published schema that will be created. This parameter is NOT optional.
  --body-dry-run: oneof<nothing, bool> # Used for testing whether the Development schema provided is backwards compatible, or not, with the publish schema provided by the user to be upgraded. If schema compatibility fails, an exception would be thrown else the call would succeed. This parameter is optional and defaults to false. (spec name: DryRun)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/amazonclouddirectory/2017-01-11/schema/upgradepublished"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: DevelopmentSchemaArn, var: development_schema_arn}, {name: PublishedSchemaArn, var: published_schema_arn}, {name: MinorVersion, var: minor_version}, {name: DryRun, var: body_dry_run}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, development_schema_arn: $development_schema_arn, published_schema_arn: $published_schema_arn, minor_version: $minor_version, body_dry_run: $body_dry_run
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
