# Auto-generated client for AWS Elemental MediaLive v2017-10-14
# Source: https://api.apis.guru/v2/specs/amazonaws.com/medialive/2017-10-14/openapi.json
# Auth: --token flag or $env.AWS_ELEMENTAL_MEDIALIVE_TOKEN

const CLIENT = {
  base_url: "http://medialive.us-east-1.amazonaws.com"
  token_env_var: "AWS_ELEMENTAL_MEDIALIVE_TOKEN"
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

def base-url-completer [] { ["http://medialive.us-east-1.amazonaws.com" "http://medialive.us-east-2.amazonaws.com" "http://medialive.us-west-1.amazonaws.com" "http://medialive.us-west-2.amazonaws.com" "http://medialive.us-gov-west-1.amazonaws.com" "http://medialive.us-gov-east-1.amazonaws.com" "http://medialive.ca-central-1.amazonaws.com" "http://medialive.eu-north-1.amazonaws.com" "http://medialive.eu-west-1.amazonaws.com" "http://medialive.eu-west-2.amazonaws.com" "http://medialive.eu-west-3.amazonaws.com" "http://medialive.eu-central-1.amazonaws.com" "http://medialive.eu-south-1.amazonaws.com" "http://medialive.af-south-1.amazonaws.com" "http://medialive.ap-northeast-1.amazonaws.com" "http://medialive.ap-northeast-2.amazonaws.com" "http://medialive.ap-northeast-3.amazonaws.com" "http://medialive.ap-southeast-1.amazonaws.com" "http://medialive.ap-southeast-2.amazonaws.com" "http://medialive.ap-east-1.amazonaws.com" "http://medialive.ap-south-1.amazonaws.com" "http://medialive.sa-east-1.amazonaws.com" "http://medialive.me-south-1.amazonaws.com" "https://medialive.us-east-1.amazonaws.com" "https://medialive.us-east-2.amazonaws.com" "https://medialive.us-west-1.amazonaws.com" "https://medialive.us-west-2.amazonaws.com" "https://medialive.us-gov-west-1.amazonaws.com" "https://medialive.us-gov-east-1.amazonaws.com" "https://medialive.ca-central-1.amazonaws.com" "https://medialive.eu-north-1.amazonaws.com" "https://medialive.eu-west-1.amazonaws.com" "https://medialive.eu-west-2.amazonaws.com" "https://medialive.eu-west-3.amazonaws.com" "https://medialive.eu-central-1.amazonaws.com" "https://medialive.eu-south-1.amazonaws.com" "https://medialive.af-south-1.amazonaws.com" "https://medialive.ap-northeast-1.amazonaws.com" "https://medialive.ap-northeast-2.amazonaws.com" "https://medialive.ap-northeast-3.amazonaws.com" "https://medialive.ap-southeast-1.amazonaws.com" "https://medialive.ap-southeast-2.amazonaws.com" "https://medialive.ap-east-1.amazonaws.com" "https://medialive.ap-south-1.amazonaws.com" "https://medialive.sa-east-1.amazonaws.com" "https://medialive.me-south-1.amazonaws.com" "http://medialive.cn-north-1.amazonaws.com.cn" "http://medialive.cn-northwest-1.amazonaws.com.cn" "https://medialive.cn-north-1.amazonaws.com.cn" "https://medialive.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def channel-class-completer [] { ["SINGLE_PIPELINE" "STANDARD"] }
def log-level-completer [] { ["DEBUG" "DISABLED" "ERROR" "INFO" "WARNING"] }
def type-completer [] { ["AWS_CDI" "INPUT_DEVICE" "MEDIACONNECT" "MP4_FILE" "RTMP_PULL" "RTMP_PUSH" "RTP_PUSH" "TS_FILE" "UDP_PUSH" "URL_PULL"] }
def accept-completer [] { ["image/jpeg"] }
def force-completer [] { ["NO" "YES"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    accept-input-device-transfer: "record"
    batch-delete: "record<Failed: table<Arn: string, Code: string, Id: string, Message: string>, Successful: table<Arn: string, Id: string, State: string>>"
    batch-start: "record<Failed: table<Arn: string, Code: string, Id: string, Message: string>, Successful: table<Arn: string, Id: string, State: string>>"
    batch-stop: "record<Failed: table<Arn: string, Code: string, Id: string, Message: string>, Successful: table<Arn: string, Id: string, State: string>>"
    batch-update-schedule: "record<Creates: record<ScheduleActions: list<record>>, Deletes: record<ScheduleActions: list<record>>>"
    delete-schedule: "record"
    describe-schedule: "record<NextToken: string, ScheduleActions: table<ActionName: string, ScheduleActionSettings: record, ScheduleActionStartSettings: record>>"
    cancel-input-device-transfer: "record"
    claim-device: "record"
    create-channel: "record<Channel: record<Arn: string, CdiInputSpecification: record<Resolution: string>, ChannelClass: string, Destinations: list<record>, EgressEndpoints: list<record>, EncoderSettings: record<AudioDescriptions: list, AvailBlanking: record, AvailConfiguration: record, BlackoutSlate: record, CaptionDescriptions: list, FeatureActivations: record, GlobalConfiguration: record, MotionGraphicsConfiguration: record, NielsenConfiguration: record, OutputGroups: list, TimecodeConfig: record, VideoDescriptions: list>, Id: string, InputAttachments: list<record>, InputSpecification: record<Codec: string, MaximumBitrate: string, Resolution: string>, LogLevel: string, Maintenance: record<MaintenanceDay: string, MaintenanceDeadline: string, MaintenanceScheduledDate: string, MaintenanceStartTime: string>, Name: string, PipelineDetails: list<record>, PipelinesRunningCount: int, RoleArn: string, State: string, Tags: record, Vpc: record<AvailabilityZones: list, NetworkInterfaceIds: list, SecurityGroupIds: list, SubnetIds: list>>>"
    list-channels: "record<Channels: table<Arn: string, CdiInputSpecification: record, ChannelClass: string, Destinations: list, EgressEndpoints: list, Id: string, InputAttachments: list, InputSpecification: record, LogLevel: string, Maintenance: record, Name: string, PipelinesRunningCount: int, RoleArn: string, State: string, Tags: record, Vpc: record>, NextToken: string>"
    create-input: "record<Input: record<Arn: string, AttachedChannels: list<string>, Destinations: list<record>, Id: string, InputClass: string, InputDevices: list<record>, InputPartnerIds: list<string>, InputSourceType: string, MediaConnectFlows: list<record>, Name: string, RoleArn: string, SecurityGroups: list<string>, Sources: list<record>, State: string, Tags: record, Type: string>>"
    list-inputs: "record<Inputs: table<Arn: string, AttachedChannels: list, Destinations: list, Id: string, InputClass: string, InputDevices: list, InputPartnerIds: list, InputSourceType: string, MediaConnectFlows: list, Name: string, RoleArn: string, SecurityGroups: list, Sources: list, State: string, Tags: record, Type: string>, NextToken: string>"
    create-input-security-group: "record<SecurityGroup: record<Arn: string, Id: string, Inputs: list<string>, State: string, Tags: record, WhitelistRules: list<record>>>"
    list-input-security-groups: "record<InputSecurityGroups: table<Arn: string, Id: string, Inputs: list, State: string, Tags: record, WhitelistRules: list>, NextToken: string>"
    create-multiplex: "record<Multiplex: record<Arn: string, AvailabilityZones: list<string>, Destinations: list<record>, Id: string, MultiplexSettings: record<MaximumVideoBufferDelayMilliseconds: int, TransportStreamBitrate: int, TransportStreamId: int, TransportStreamReservedBitrate: int>, Name: string, PipelinesRunningCount: int, ProgramCount: int, State: string, Tags: record>>"
    list-multiplexes: "record<Multiplexes: table<Arn: string, AvailabilityZones: list, Id: string, MultiplexSettings: record, Name: string, PipelinesRunningCount: int, ProgramCount: int, State: string, Tags: record>, NextToken: string>"
    create-multiplex-program: "record<MultiplexProgram: record<ChannelId: string, MultiplexProgramSettings: record<PreferredChannelPipeline: string, ProgramNumber: int, ServiceDescriptor: record, VideoSettings: record>, PacketIdentifiersMap: record<AudioPids: list, DvbSubPids: list, DvbTeletextPid: int, EtvPlatformPid: int, EtvSignalPid: int, KlvDataPids: list, PcrPid: int, PmtPid: int, PrivateMetadataPid: int, Scte27Pids: list, Scte35Pid: int, TimedMetadataPid: int, VideoPid: int>, PipelineDetails: list<record>, ProgramName: string>>"
    list-multiplex-programs: "record<MultiplexPrograms: table<ChannelId: string, ProgramName: string>, NextToken: string>"
    create-partner-input: "record<Input: record<Arn: string, AttachedChannels: list<string>, Destinations: list<record>, Id: string, InputClass: string, InputDevices: list<record>, InputPartnerIds: list<string>, InputSourceType: string, MediaConnectFlows: list<record>, Name: string, RoleArn: string, SecurityGroups: list<string>, Sources: list<record>, State: string, Tags: record, Type: string>>"
    list-tags-for-resource: "record<Tags: record>"
    delete-channel: "record<Arn: string, CdiInputSpecification: record<Resolution: string>, ChannelClass: string, Destinations: table<Id: string, MediaPackageSettings: list, MultiplexSettings: record, Settings: list>, EgressEndpoints: table<SourceIp: string>, EncoderSettings: record<AudioDescriptions: list<record>, AvailBlanking: record<AvailBlankingImage: record, State: string>, AvailConfiguration: record<AvailSettings: record>, BlackoutSlate: record<BlackoutSlateImage: record, NetworkEndBlackout: string, NetworkEndBlackoutImage: record, NetworkId: string, State: string>, CaptionDescriptions: list<record>, FeatureActivations: record<InputPrepareScheduleActions: string>, GlobalConfiguration: record<InitialAudioGain: int, InputEndAction: string, InputLossBehavior: record, OutputLockingMode: string, OutputTimingSource: string, SupportLowFramerateInputs: string>, MotionGraphicsConfiguration: record<MotionGraphicsInsertion: string, MotionGraphicsSettings: record>, NielsenConfiguration: record<DistributorId: string, NielsenPcmToId3Tagging: string>, OutputGroups: list<record>, TimecodeConfig: record<Source: string, SyncThreshold: int>, VideoDescriptions: list<record>>, Id: string, InputAttachments: table<AutomaticInputFailoverSettings: record, InputAttachmentName: string, InputId: string, InputSettings: record>, InputSpecification: record<Codec: string, MaximumBitrate: string, Resolution: string>, LogLevel: string, Maintenance: record<MaintenanceDay: string, MaintenanceDeadline: string, MaintenanceScheduledDate: string, MaintenanceStartTime: string>, Name: string, PipelineDetails: table<ActiveInputAttachmentName: string, ActiveInputSwitchActionName: string, ActiveMotionGraphicsActionName: string, ActiveMotionGraphicsUri: string, PipelineId: string>, PipelinesRunningCount: int, RoleArn: string, State: string, Tags: record, Vpc: record<AvailabilityZones: list<string>, NetworkInterfaceIds: list<string>, SecurityGroupIds: list<string>, SubnetIds: list<string>>>"
    describe-channel: "record<Arn: string, CdiInputSpecification: record<Resolution: string>, ChannelClass: string, Destinations: table<Id: string, MediaPackageSettings: list, MultiplexSettings: record, Settings: list>, EgressEndpoints: table<SourceIp: string>, EncoderSettings: record<AudioDescriptions: list<record>, AvailBlanking: record<AvailBlankingImage: record, State: string>, AvailConfiguration: record<AvailSettings: record>, BlackoutSlate: record<BlackoutSlateImage: record, NetworkEndBlackout: string, NetworkEndBlackoutImage: record, NetworkId: string, State: string>, CaptionDescriptions: list<record>, FeatureActivations: record<InputPrepareScheduleActions: string>, GlobalConfiguration: record<InitialAudioGain: int, InputEndAction: string, InputLossBehavior: record, OutputLockingMode: string, OutputTimingSource: string, SupportLowFramerateInputs: string>, MotionGraphicsConfiguration: record<MotionGraphicsInsertion: string, MotionGraphicsSettings: record>, NielsenConfiguration: record<DistributorId: string, NielsenPcmToId3Tagging: string>, OutputGroups: list<record>, TimecodeConfig: record<Source: string, SyncThreshold: int>, VideoDescriptions: list<record>>, Id: string, InputAttachments: table<AutomaticInputFailoverSettings: record, InputAttachmentName: string, InputId: string, InputSettings: record>, InputSpecification: record<Codec: string, MaximumBitrate: string, Resolution: string>, LogLevel: string, Maintenance: record<MaintenanceDay: string, MaintenanceDeadline: string, MaintenanceScheduledDate: string, MaintenanceStartTime: string>, Name: string, PipelineDetails: table<ActiveInputAttachmentName: string, ActiveInputSwitchActionName: string, ActiveMotionGraphicsActionName: string, ActiveMotionGraphicsUri: string, PipelineId: string>, PipelinesRunningCount: int, RoleArn: string, State: string, Tags: record, Vpc: record<AvailabilityZones: list<string>, NetworkInterfaceIds: list<string>, SecurityGroupIds: list<string>, SubnetIds: list<string>>>"
    update-channel: "record<Channel: record<Arn: string, CdiInputSpecification: record<Resolution: string>, ChannelClass: string, Destinations: list<record>, EgressEndpoints: list<record>, EncoderSettings: record<AudioDescriptions: list, AvailBlanking: record, AvailConfiguration: record, BlackoutSlate: record, CaptionDescriptions: list, FeatureActivations: record, GlobalConfiguration: record, MotionGraphicsConfiguration: record, NielsenConfiguration: record, OutputGroups: list, TimecodeConfig: record, VideoDescriptions: list>, Id: string, InputAttachments: list<record>, InputSpecification: record<Codec: string, MaximumBitrate: string, Resolution: string>, LogLevel: string, Maintenance: record<MaintenanceDay: string, MaintenanceDeadline: string, MaintenanceScheduledDate: string, MaintenanceStartTime: string>, Name: string, PipelineDetails: list<record>, PipelinesRunningCount: int, RoleArn: string, State: string, Tags: record, Vpc: record<AvailabilityZones: list, NetworkInterfaceIds: list, SecurityGroupIds: list, SubnetIds: list>>>"
    delete-input: "record"
    describe-input: "record<Arn: string, AttachedChannels: list<string>, Destinations: table<Ip: string, Port: string, Url: string, Vpc: record>, Id: string, InputClass: string, InputDevices: table<Id: string>, InputPartnerIds: list<string>, InputSourceType: string, MediaConnectFlows: table<FlowArn: string>, Name: string, RoleArn: string, SecurityGroups: list<string>, Sources: table<PasswordParam: string, Url: string, Username: string>, State: string, Tags: record, Type: string>"
    update-input: "record<Input: record<Arn: string, AttachedChannels: list<string>, Destinations: list<record>, Id: string, InputClass: string, InputDevices: list<record>, InputPartnerIds: list<string>, InputSourceType: string, MediaConnectFlows: list<record>, Name: string, RoleArn: string, SecurityGroups: list<string>, Sources: list<record>, State: string, Tags: record, Type: string>>"
    delete-input-security-group: "record"
    describe-input-security-group: "record<Arn: string, Id: string, Inputs: list<string>, State: string, Tags: record, WhitelistRules: table<Cidr: string>>"
    update-input-security-group: "record<SecurityGroup: record<Arn: string, Id: string, Inputs: list<string>, State: string, Tags: record, WhitelistRules: list<record>>>"
    delete-multiplex: "record<Arn: string, AvailabilityZones: list<string>, Destinations: table<MediaConnectSettings: record>, Id: string, MultiplexSettings: record<MaximumVideoBufferDelayMilliseconds: int, TransportStreamBitrate: int, TransportStreamId: int, TransportStreamReservedBitrate: int>, Name: string, PipelinesRunningCount: int, ProgramCount: int, State: string, Tags: record>"
    describe-multiplex: "record<Arn: string, AvailabilityZones: list<string>, Destinations: table<MediaConnectSettings: record>, Id: string, MultiplexSettings: record<MaximumVideoBufferDelayMilliseconds: int, TransportStreamBitrate: int, TransportStreamId: int, TransportStreamReservedBitrate: int>, Name: string, PipelinesRunningCount: int, ProgramCount: int, State: string, Tags: record>"
    update-multiplex: "record<Multiplex: record<Arn: string, AvailabilityZones: list<string>, Destinations: list<record>, Id: string, MultiplexSettings: record<MaximumVideoBufferDelayMilliseconds: int, TransportStreamBitrate: int, TransportStreamId: int, TransportStreamReservedBitrate: int>, Name: string, PipelinesRunningCount: int, ProgramCount: int, State: string, Tags: record>>"
    delete-multiplex-program: "record<ChannelId: string, MultiplexProgramSettings: record<PreferredChannelPipeline: string, ProgramNumber: int, ServiceDescriptor: record<ProviderName: string, ServiceName: string>, VideoSettings: record<ConstantBitrate: int, StatmuxSettings: record>>, PacketIdentifiersMap: record<AudioPids: list<int>, DvbSubPids: list<int>, DvbTeletextPid: int, EtvPlatformPid: int, EtvSignalPid: int, KlvDataPids: list<int>, PcrPid: int, PmtPid: int, PrivateMetadataPid: int, Scte27Pids: list<int>, Scte35Pid: int, TimedMetadataPid: int, VideoPid: int>, PipelineDetails: table<ActiveChannelPipeline: string, PipelineId: string>, ProgramName: string>"
    describe-multiplex-program: "record<ChannelId: string, MultiplexProgramSettings: record<PreferredChannelPipeline: string, ProgramNumber: int, ServiceDescriptor: record<ProviderName: string, ServiceName: string>, VideoSettings: record<ConstantBitrate: int, StatmuxSettings: record>>, PacketIdentifiersMap: record<AudioPids: list<int>, DvbSubPids: list<int>, DvbTeletextPid: int, EtvPlatformPid: int, EtvSignalPid: int, KlvDataPids: list<int>, PcrPid: int, PmtPid: int, PrivateMetadataPid: int, Scte27Pids: list<int>, Scte35Pid: int, TimedMetadataPid: int, VideoPid: int>, PipelineDetails: table<ActiveChannelPipeline: string, PipelineId: string>, ProgramName: string>"
    update-multiplex-program: "record<MultiplexProgram: record<ChannelId: string, MultiplexProgramSettings: record<PreferredChannelPipeline: string, ProgramNumber: int, ServiceDescriptor: record, VideoSettings: record>, PacketIdentifiersMap: record<AudioPids: list, DvbSubPids: list, DvbTeletextPid: int, EtvPlatformPid: int, EtvSignalPid: int, KlvDataPids: list, PcrPid: int, PmtPid: int, PrivateMetadataPid: int, Scte27Pids: list, Scte35Pid: int, TimedMetadataPid: int, VideoPid: int>, PipelineDetails: list<record>, ProgramName: string>>"
    delete-reservation: "record<Arn: string, Count: int, CurrencyCode: string, Duration: int, DurationUnits: string, End: string, FixedPrice: float, Name: string, OfferingDescription: string, OfferingId: string, OfferingType: string, Region: string, RenewalSettings: record<AutomaticRenewal: string, RenewalCount: int>, ReservationId: string, ResourceSpecification: record<ChannelClass: string, Codec: string, MaximumBitrate: string, MaximumFramerate: string, Resolution: string, ResourceType: string, SpecialFeature: string, VideoQuality: string>, Start: string, State: string, Tags: record, UsagePrice: float>"
    describe-reservation: "record<Arn: string, Count: int, CurrencyCode: string, Duration: int, DurationUnits: string, End: string, FixedPrice: float, Name: string, OfferingDescription: string, OfferingId: string, OfferingType: string, Region: string, RenewalSettings: record<AutomaticRenewal: string, RenewalCount: int>, ReservationId: string, ResourceSpecification: record<ChannelClass: string, Codec: string, MaximumBitrate: string, MaximumFramerate: string, Resolution: string, ResourceType: string, SpecialFeature: string, VideoQuality: string>, Start: string, State: string, Tags: record, UsagePrice: float>"
    update-reservation: "record<Reservation: record<Arn: string, Count: int, CurrencyCode: string, Duration: int, DurationUnits: string, End: string, FixedPrice: float, Name: string, OfferingDescription: string, OfferingId: string, OfferingType: string, Region: string, RenewalSettings: record<AutomaticRenewal: string, RenewalCount: int>, ReservationId: string, ResourceSpecification: record<ChannelClass: string, Codec: string, MaximumBitrate: string, MaximumFramerate: string, Resolution: string, ResourceType: string, SpecialFeature: string, VideoQuality: string>, Start: string, State: string, Tags: record, UsagePrice: float>>"
    describe-input-device: "record<Arn: string, ConnectionState: string, DeviceSettingsSyncState: string, DeviceUpdateStatus: string, HdDeviceSettings: record<ActiveInput: string, ConfiguredInput: string, DeviceState: string, Framerate: float, Height: int, MaxBitrate: int, ScanType: string, Width: int, LatencyMs: int>, Id: string, MacAddress: string, Name: string, NetworkSettings: record<DnsAddresses: list<string>, Gateway: string, IpAddress: string, IpScheme: string, SubnetMask: string>, SerialNumber: string, Type: string, UhdDeviceSettings: record<ActiveInput: string, ConfiguredInput: string, DeviceState: string, Framerate: float, Height: int, MaxBitrate: int, ScanType: string, Width: int, LatencyMs: int>, Tags: record>"
    update-input-device: "record<Arn: string, ConnectionState: string, DeviceSettingsSyncState: string, DeviceUpdateStatus: string, HdDeviceSettings: record<ActiveInput: string, ConfiguredInput: string, DeviceState: string, Framerate: float, Height: int, MaxBitrate: int, ScanType: string, Width: int, LatencyMs: int>, Id: string, MacAddress: string, Name: string, NetworkSettings: record<DnsAddresses: list<string>, Gateway: string, IpAddress: string, IpScheme: string, SubnetMask: string>, SerialNumber: string, Type: string, UhdDeviceSettings: record<ActiveInput: string, ConfiguredInput: string, DeviceState: string, Framerate: float, Height: int, MaxBitrate: int, ScanType: string, Width: int, LatencyMs: int>, Tags: record>"
    describe-input-device-thumbnail: "record<Body: string>"
    describe-offering: "record<Arn: string, CurrencyCode: string, Duration: int, DurationUnits: string, FixedPrice: float, OfferingDescription: string, OfferingId: string, OfferingType: string, Region: string, ResourceSpecification: record<ChannelClass: string, Codec: string, MaximumBitrate: string, MaximumFramerate: string, Resolution: string, ResourceType: string, SpecialFeature: string, VideoQuality: string>, UsagePrice: float>"
    list-input-device-transfers: "record<InputDeviceTransfers: table<Id: string, Message: string, TargetCustomerId: string, TransferType: string>, NextToken: string>"
    list-input-devices: "record<InputDevices: table<Arn: string, ConnectionState: string, DeviceSettingsSyncState: string, DeviceUpdateStatus: string, HdDeviceSettings: record, Id: string, MacAddress: string, Name: string, NetworkSettings: record, SerialNumber: string, Type: string, UhdDeviceSettings: record, Tags: record>, NextToken: string>"
    list-offerings: "record<NextToken: string, Offerings: table<Arn: string, CurrencyCode: string, Duration: int, DurationUnits: string, FixedPrice: float, OfferingDescription: string, OfferingId: string, OfferingType: string, Region: string, ResourceSpecification: record, UsagePrice: float>>"
    list-reservations: "record<NextToken: string, Reservations: table<Arn: string, Count: int, CurrencyCode: string, Duration: int, DurationUnits: string, End: string, FixedPrice: float, Name: string, OfferingDescription: string, OfferingId: string, OfferingType: string, Region: string, RenewalSettings: record, ReservationId: string, ResourceSpecification: record, Start: string, State: string, Tags: record, UsagePrice: float>>"
    purchase-offering: "record<Reservation: record<Arn: string, Count: int, CurrencyCode: string, Duration: int, DurationUnits: string, End: string, FixedPrice: float, Name: string, OfferingDescription: string, OfferingId: string, OfferingType: string, Region: string, RenewalSettings: record<AutomaticRenewal: string, RenewalCount: int>, ReservationId: string, ResourceSpecification: record<ChannelClass: string, Codec: string, MaximumBitrate: string, MaximumFramerate: string, Resolution: string, ResourceType: string, SpecialFeature: string, VideoQuality: string>, Start: string, State: string, Tags: record, UsagePrice: float>>"
    reboot-input-device: "record"
    reject-input-device-transfer: "record"
    start-channel: "record<Arn: string, CdiInputSpecification: record<Resolution: string>, ChannelClass: string, Destinations: table<Id: string, MediaPackageSettings: list, MultiplexSettings: record, Settings: list>, EgressEndpoints: table<SourceIp: string>, EncoderSettings: record<AudioDescriptions: list<record>, AvailBlanking: record<AvailBlankingImage: record, State: string>, AvailConfiguration: record<AvailSettings: record>, BlackoutSlate: record<BlackoutSlateImage: record, NetworkEndBlackout: string, NetworkEndBlackoutImage: record, NetworkId: string, State: string>, CaptionDescriptions: list<record>, FeatureActivations: record<InputPrepareScheduleActions: string>, GlobalConfiguration: record<InitialAudioGain: int, InputEndAction: string, InputLossBehavior: record, OutputLockingMode: string, OutputTimingSource: string, SupportLowFramerateInputs: string>, MotionGraphicsConfiguration: record<MotionGraphicsInsertion: string, MotionGraphicsSettings: record>, NielsenConfiguration: record<DistributorId: string, NielsenPcmToId3Tagging: string>, OutputGroups: list<record>, TimecodeConfig: record<Source: string, SyncThreshold: int>, VideoDescriptions: list<record>>, Id: string, InputAttachments: table<AutomaticInputFailoverSettings: record, InputAttachmentName: string, InputId: string, InputSettings: record>, InputSpecification: record<Codec: string, MaximumBitrate: string, Resolution: string>, LogLevel: string, Maintenance: record<MaintenanceDay: string, MaintenanceDeadline: string, MaintenanceScheduledDate: string, MaintenanceStartTime: string>, Name: string, PipelineDetails: table<ActiveInputAttachmentName: string, ActiveInputSwitchActionName: string, ActiveMotionGraphicsActionName: string, ActiveMotionGraphicsUri: string, PipelineId: string>, PipelinesRunningCount: int, RoleArn: string, State: string, Tags: record, Vpc: record<AvailabilityZones: list<string>, NetworkInterfaceIds: list<string>, SecurityGroupIds: list<string>, SubnetIds: list<string>>>"
    start-input-device-maintenance-window: "record"
    start-multiplex: "record<Arn: string, AvailabilityZones: list<string>, Destinations: table<MediaConnectSettings: record>, Id: string, MultiplexSettings: record<MaximumVideoBufferDelayMilliseconds: int, TransportStreamBitrate: int, TransportStreamId: int, TransportStreamReservedBitrate: int>, Name: string, PipelinesRunningCount: int, ProgramCount: int, State: string, Tags: record>"
    stop-channel: "record<Arn: string, CdiInputSpecification: record<Resolution: string>, ChannelClass: string, Destinations: table<Id: string, MediaPackageSettings: list, MultiplexSettings: record, Settings: list>, EgressEndpoints: table<SourceIp: string>, EncoderSettings: record<AudioDescriptions: list<record>, AvailBlanking: record<AvailBlankingImage: record, State: string>, AvailConfiguration: record<AvailSettings: record>, BlackoutSlate: record<BlackoutSlateImage: record, NetworkEndBlackout: string, NetworkEndBlackoutImage: record, NetworkId: string, State: string>, CaptionDescriptions: list<record>, FeatureActivations: record<InputPrepareScheduleActions: string>, GlobalConfiguration: record<InitialAudioGain: int, InputEndAction: string, InputLossBehavior: record, OutputLockingMode: string, OutputTimingSource: string, SupportLowFramerateInputs: string>, MotionGraphicsConfiguration: record<MotionGraphicsInsertion: string, MotionGraphicsSettings: record>, NielsenConfiguration: record<DistributorId: string, NielsenPcmToId3Tagging: string>, OutputGroups: list<record>, TimecodeConfig: record<Source: string, SyncThreshold: int>, VideoDescriptions: list<record>>, Id: string, InputAttachments: table<AutomaticInputFailoverSettings: record, InputAttachmentName: string, InputId: string, InputSettings: record>, InputSpecification: record<Codec: string, MaximumBitrate: string, Resolution: string>, LogLevel: string, Maintenance: record<MaintenanceDay: string, MaintenanceDeadline: string, MaintenanceScheduledDate: string, MaintenanceStartTime: string>, Name: string, PipelineDetails: table<ActiveInputAttachmentName: string, ActiveInputSwitchActionName: string, ActiveMotionGraphicsActionName: string, ActiveMotionGraphicsUri: string, PipelineId: string>, PipelinesRunningCount: int, RoleArn: string, State: string, Tags: record, Vpc: record<AvailabilityZones: list<string>, NetworkInterfaceIds: list<string>, SecurityGroupIds: list<string>, SubnetIds: list<string>>>"
    stop-multiplex: "record<Arn: string, AvailabilityZones: list<string>, Destinations: table<MediaConnectSettings: record>, Id: string, MultiplexSettings: record<MaximumVideoBufferDelayMilliseconds: int, TransportStreamBitrate: int, TransportStreamId: int, TransportStreamReservedBitrate: int>, Name: string, PipelinesRunningCount: int, ProgramCount: int, State: string, Tags: record>"
    transfer-input-device: "record"
    update-channel-class: "record<Channel: record<Arn: string, CdiInputSpecification: record<Resolution: string>, ChannelClass: string, Destinations: list<record>, EgressEndpoints: list<record>, EncoderSettings: record<AudioDescriptions: list, AvailBlanking: record, AvailConfiguration: record, BlackoutSlate: record, CaptionDescriptions: list, FeatureActivations: record, GlobalConfiguration: record, MotionGraphicsConfiguration: record, NielsenConfiguration: record, OutputGroups: list, TimecodeConfig: record, VideoDescriptions: list>, Id: string, InputAttachments: list<record>, InputSpecification: record<Codec: string, MaximumBitrate: string, Resolution: string>, LogLevel: string, Maintenance: record<MaintenanceDay: string, MaintenanceDeadline: string, MaintenanceScheduledDate: string, MaintenanceStartTime: string>, Name: string, PipelineDetails: list<record>, PipelinesRunningCount: int, RoleArn: string, State: string, Tags: record, Vpc: record<AvailabilityZones: list, NetworkInterfaceIds: list, SecurityGroupIds: list, SubnetIds: list>>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["accept-input-device-transfer" "batch-delete" "batch-start" "batch-stop" "batch-update-schedule" "delete-schedule" "describe-schedule" "cancel-input-device-transfer" "claim-device" "create-channel" "list-channels" "create-input" "list-inputs" "create-input-security-group" "list-input-security-groups" "create-multiplex" "list-multiplexes" "create-multiplex-program" "list-multiplex-programs" "create-partner-input" "create-tags" "list-tags-for-resource" "delete-channel" "describe-channel" "update-channel" "delete-input" "describe-input" "update-input" "delete-input-security-group" "describe-input-security-group" "update-input-security-group" "delete-multiplex" "describe-multiplex" "update-multiplex" "delete-multiplex-program" "describe-multiplex-program" "update-multiplex-program" "delete-reservation" "describe-reservation" "update-reservation" "delete-tags" "describe-input-device" "update-input-device" "describe-input-device-thumbnail" "describe-offering" "list-input-device-transfers" "list-input-devices" "list-offerings" "list-reservations" "purchase-offering" "reboot-input-device" "reject-input-device-transfer" "start-channel" "start-input-device-maintenance-window" "start-multiplex" "stop-channel" "stop-multiplex" "transfer-input-device" "update-channel-class" "commands"] | sort) } | get name | first)
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

# Accept an incoming input device transfer. The ownership of the device will transfer to your AWS account.
#
# POST /prod/inputDevices/{inputDeviceId}/accept
# Returns: record
# operationId: AcceptInputDeviceTransfer
export def "accept-input-device-transfer" [
  input_device_id: string
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
    path: "/prod/inputDevices/{inputDeviceId}/accept"
    path_params: [{name: inputDeviceId, var: input_device_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    input_device_id: $input_device_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts delete of resources.
#
# POST /prod/batch/delete
# Returns: record<Failed: table<Arn: string, Code: string, Id: string, Message: string>, Successful: table<Arn: string, Id: string, State: string>>
# operationId: BatchDelete
export def "batch-delete" [
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
  --channel-ids: list<string> # Placeholder documentation for __listOf__string
  --input-ids: list<string> # Placeholder documentation for __listOf__string
  --input-security-group-ids: list<string> # Placeholder documentation for __listOf__string
  --multiplex-ids: list<string> # Placeholder documentation for __listOf__string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/prod/batch/delete"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: channelIds, var: channel_ids}, {name: inputIds, var: input_ids}, {name: inputSecurityGroupIds, var: input_security_group_ids}, {name: multiplexIds, var: multiplex_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, channel_ids: $channel_ids, input_ids: $input_ids, input_security_group_ids: $input_security_group_ids, multiplex_ids: $multiplex_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts existing resources
#
# POST /prod/batch/start
# Returns: record<Failed: table<Arn: string, Code: string, Id: string, Message: string>, Successful: table<Arn: string, Id: string, State: string>>
# operationId: BatchStart
export def "batch-start" [
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
  --channel-ids: list<string> # Placeholder documentation for __listOf__string
  --multiplex-ids: list<string> # Placeholder documentation for __listOf__string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/prod/batch/start"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: channelIds, var: channel_ids}, {name: multiplexIds, var: multiplex_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, channel_ids: $channel_ids, multiplex_ids: $multiplex_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops running resources
#
# POST /prod/batch/stop
# Returns: record<Failed: table<Arn: string, Code: string, Id: string, Message: string>, Successful: table<Arn: string, Id: string, State: string>>
# operationId: BatchStop
export def "batch-stop" [
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
  --channel-ids: list<string> # Placeholder documentation for __listOf__string
  --multiplex-ids: list<string> # Placeholder documentation for __listOf__string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/prod/batch/stop"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: channelIds, var: channel_ids}, {name: multiplexIds, var: multiplex_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, channel_ids: $channel_ids, multiplex_ids: $multiplex_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a channel schedule
#
# PUT /prod/channels/{channelId}/schedule
# Returns: record<Creates: record<ScheduleActions: list<record>>, Deletes: record<ScheduleActions: list<record>>>
# operationId: BatchUpdateSchedule
export def "batch-update-schedule" [
  channel_id: string
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
  --creates: record # A list of schedule actions to create (in a request) or that have been created (in a response). — shape: {ScheduleActions?: list}
  --deletes: record # A list of schedule actions to delete. — shape: {ActionNames?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/prod/channels/{channelId}/schedule"
    path_params: [{name: channelId, var: channel_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: creates, var: creates}, {name: deletes, var: deletes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, creates: $creates, deletes: $deletes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete all schedule actions on a channel.
#
# DELETE /prod/channels/{channelId}/schedule
# Returns: record
# operationId: DeleteSchedule
export def "delete-schedule" [
  channel_id: string
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
    path: "/prod/channels/{channelId}/schedule"
    path_params: [{name: channelId, var: channel_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a channel schedule
#
# GET /prod/channels/{channelId}/schedule
# Returns: record<NextToken: string, ScheduleActions: table<ActionName: string, ScheduleActionSettings: record, ScheduleActionStartSettings: record>>
# operationId: DescribeSchedule
export def "describe-schedule" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int
  --next-token: string
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/prod/channels/{channelId}/schedule"
    path_params: [{name: channelId, var: channel_id}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel an input device transfer that you have requested.
#
# POST /prod/inputDevices/{inputDeviceId}/cancel
# Returns: record
# operationId: CancelInputDeviceTransfer
export def "cancel-input-device-transfer" [
  input_device_id: string
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
    path: "/prod/inputDevices/{inputDeviceId}/cancel"
    path_params: [{name: inputDeviceId, var: input_device_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    input_device_id: $input_device_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send a request to claim an AWS Elemental device that you have purchased from a third-party vendor. After the request succeeds, you will own the device.
#
# POST /prod/claimDevice
# Returns: record
# operationId: ClaimDevice
export def "claim-device" [
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
  --id: string # Placeholder documentation for __string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/prod/claimDevice"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new channel
#
# POST /prod/channels
# Returns: record<Channel: record<Arn: string, CdiInputSpecification: record<Resolution: string>, ChannelClass: string, Destinations: list<record>, EgressEndpoints: list<record>, EncoderSettings: record<AudioDescriptions: list, AvailBlanking: record, AvailConfiguration: record, BlackoutSlate: record, CaptionDescriptions: list, FeatureActivations: record, GlobalConfiguration: record, MotionGraphicsConfiguration: record, NielsenConfiguration: record, OutputGroups: list, TimecodeConfig: record, VideoDescriptions: list>, Id: string, InputAttachments: list<record>, InputSpecification: record<Codec: string, MaximumBitrate: string, Resolution: string>, LogLevel: string, Maintenance: record<MaintenanceDay: string, MaintenanceDeadline: string, MaintenanceScheduledDate: string, MaintenanceStartTime: string>, Name: string, PipelineDetails: list<record>, PipelinesRunningCount: int, RoleArn: string, State: string, Tags: record, Vpc: record<AvailabilityZones: list, NetworkInterfaceIds: list, SecurityGroupIds: list, SubnetIds: list>>>
# operationId: CreateChannel
export def "create-channel" [
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
  --cdi-input-specification: record # Placeholder documentation for CdiInputSpecification — shape: {Resolution?: "SD"|"HD"|"FHD"|"UHD"}
  --channel-class: string@channel-class-completer # A standard channel has two encoding pipelines and a single pipeline channel only has one.
  --destinations: list # Placeholder documentation for __listOfOutputDestination — item shape: {Id?: string, MediaPackageSettings?: list, MultiplexSettings?: record, Settings?: list}
  --encoder-settings: record # Encoder Settings — shape: {AudioDescriptions?: list, AvailBlanking?: record, AvailConfiguration?: record, BlackoutSlate?: record, CaptionDescriptions?: list, FeatureActivations?: record, GlobalConfiguration?: record, MotionGraphicsConfiguration?: record, NielsenConfiguration?: record, OutputGroups?: list, TimecodeConfig?: record, VideoDescriptions?: list}
  --input-attachments: list # Placeholder documentation for __listOfInputAttachment — item shape: {AutomaticInputFailoverSettings?: record, InputAttachmentName?: string, InputId?: string, InputSettings?: record}
  --input-specification: record # Placeholder documentation for InputSpecification — shape: {Codec?: "MPEG2"|"AVC"|"HEVC", MaximumBitrate?: "MAX_10_MBPS"|"MAX_20_MBPS"|"MAX_50_MBPS", Resolution?: "SD"|"HD"|"UHD"}
  --log-level: string@log-level-completer # The log level the user wants for their channel.
  --maintenance: record # Placeholder documentation for MaintenanceCreateSettings — shape: {MaintenanceDay?: "MONDAY"|"TUESDAY"|"WEDNESDAY"|"THURSDAY"|"FRIDAY"|"SATURDAY"|"SUNDAY", MaintenanceStartTime?: string}
  --name: string # Placeholder documentation for __string
  --request-id: string # Placeholder documentation for __string
  --reserved: string # Placeholder documentation for __string
  --role-arn: string # Placeholder documentation for __string
  --tags: record # Placeholder documentation for Tags
  --vpc: record # The properties for a private VPC Output When this property is specified, the output egress addresses will be created in a user specified VPC — shape: {PublicAddressAllocationIds?: list<string>, SecurityGroupIds?: list<string>, SubnetIds?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/prod/channels"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: cdiInputSpecification, var: cdi_input_specification}, {name: channelClass, var: channel_class}, {name: destinations, var: destinations}, {name: encoderSettings, var: encoder_settings}, {name: inputAttachments, var: input_attachments}, {name: inputSpecification, var: input_specification}, {name: logLevel, var: log_level}, {name: maintenance, var: maintenance}, {name: name, var: name}, {name: requestId, var: request_id}, {name: reserved, var: reserved}, {name: roleArn, var: role_arn}, {name: tags, var: tags}, {name: vpc, var: vpc}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, cdi_input_specification: $cdi_input_specification, channel_class: $channel_class, destinations: $destinations, encoder_settings: $encoder_settings, input_attachments: $input_attachments, input_specification: $input_specification, log_level: $log_level, maintenance: $maintenance, name: $name, request_id: $request_id, reserved: $reserved, role_arn: $role_arn, tags: $tags, vpc: $vpc
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Produces list of channels that have been created
#
# GET /prod/channels
# Returns: record<Channels: table<Arn: string, CdiInputSpecification: record, ChannelClass: string, Destinations: list, EgressEndpoints: list, Id: string, InputAttachments: list, InputSpecification: record, LogLevel: string, Maintenance: record, Name: string, PipelinesRunningCount: int, RoleArn: string, State: string, Tags: record, Vpc: record>, NextToken: string>
# operationId: ListChannels
export def "list-channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int
  --next-token: string
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/prod/channels"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an input
#
# POST /prod/inputs
# Returns: record<Input: record<Arn: string, AttachedChannels: list<string>, Destinations: list<record>, Id: string, InputClass: string, InputDevices: list<record>, InputPartnerIds: list<string>, InputSourceType: string, MediaConnectFlows: list<record>, Name: string, RoleArn: string, SecurityGroups: list<string>, Sources: list<record>, State: string, Tags: record, Type: string>>
# operationId: CreateInput
export def "create-input" [
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
  --destinations: list # Placeholder documentation for __listOfInputDestinationRequest — item shape: {StreamName?: string}
  --input-devices: list # Placeholder documentation for __listOfInputDeviceSettings — item shape: {Id?: string}
  --input-security-groups: list<string> # Placeholder documentation for __listOf__string
  --media-connect-flows: list # Placeholder documentation for __listOfMediaConnectFlowRequest — item shape: {FlowArn?: string}
  --name: string # Placeholder documentation for __string
  --request-id: string # Placeholder documentation for __string
  --role-arn: string # Placeholder documentation for __string
  --sources: list # Placeholder documentation for __listOfInputSourceRequest — item shape: {PasswordParam?: string, Url?: string, Username?: string}
  --tags: record # Placeholder documentation for Tags
  --type: string@type-completer # The different types of inputs that AWS Elemental MediaLive supports.
  --vpc: record # Settings for a private VPC Input. When this property is specified, the input destination addresses will be created in a VPC rather than with public Internet addresses. This property requires setting the roleArn property on Input creation. Not compatible with the inputSecurityGroups property. — shape: {SecurityGroupIds?: list<string>, SubnetIds?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/prod/inputs"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: destinations, var: destinations}, {name: inputDevices, var: input_devices}, {name: inputSecurityGroups, var: input_security_groups}, {name: mediaConnectFlows, var: media_connect_flows}, {name: name, var: name}, {name: requestId, var: request_id}, {name: roleArn, var: role_arn}, {name: sources, var: sources}, {name: tags, var: tags}, {name: type, var: type}, {name: vpc, var: vpc}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, destinations: $destinations, input_devices: $input_devices, input_security_groups: $input_security_groups, media_connect_flows: $media_connect_flows, name: $name, request_id: $request_id, role_arn: $role_arn, sources: $sources, tags: $tags, type: $type, vpc: $vpc
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Produces list of inputs that have been created
#
# GET /prod/inputs
# Returns: record<Inputs: table<Arn: string, AttachedChannels: list, Destinations: list, Id: string, InputClass: string, InputDevices: list, InputPartnerIds: list, InputSourceType: string, MediaConnectFlows: list, Name: string, RoleArn: string, SecurityGroups: list, Sources: list, State: string, Tags: record, Type: string>, NextToken: string>
# operationId: ListInputs
export def "list-inputs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int
  --next-token: string
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/prod/inputs"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Input Security Group
#
# POST /prod/inputSecurityGroups
# Returns: record<SecurityGroup: record<Arn: string, Id: string, Inputs: list<string>, State: string, Tags: record, WhitelistRules: list<record>>>
# operationId: CreateInputSecurityGroup
export def "create-input-security-group" [
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
  --tags: record # Placeholder documentation for Tags
  --whitelist-rules: list # Placeholder documentation for __listOfInputWhitelistRuleCidr — item shape: {Cidr?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/prod/inputSecurityGroups"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}, {name: whitelistRules, var: whitelist_rules}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, tags: $tags, whitelist_rules: $whitelist_rules
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Produces a list of Input Security Groups for an account
#
# GET /prod/inputSecurityGroups
# Returns: record<InputSecurityGroups: table<Arn: string, Id: string, Inputs: list, State: string, Tags: record, WhitelistRules: list>, NextToken: string>
# operationId: ListInputSecurityGroups
export def "list-input-security-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int
  --next-token: string
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/prod/inputSecurityGroups"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new multiplex.
#
# POST /prod/multiplexes
# Returns: record<Multiplex: record<Arn: string, AvailabilityZones: list<string>, Destinations: list<record>, Id: string, MultiplexSettings: record<MaximumVideoBufferDelayMilliseconds: int, TransportStreamBitrate: int, TransportStreamId: int, TransportStreamReservedBitrate: int>, Name: string, PipelinesRunningCount: int, ProgramCount: int, State: string, Tags: record>>
# operationId: CreateMultiplex
export def "create-multiplex" [
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
  availability_zones: list<string> # Placeholder documentation for __listOf__string
  multiplex_settings: record # Contains configuration for a Multiplex event — shape: {MaximumVideoBufferDelayMilliseconds?: int, TransportStreamBitrate?: int, TransportStreamId?: int, TransportStreamReservedBitrate?: int}
  name: string # Placeholder documentation for __string
  request_id: string # Placeholder documentation for __string
  --tags: record # Placeholder documentation for Tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/prod/multiplexes"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: availabilityZones, var: availability_zones}, {name: multiplexSettings, var: multiplex_settings}, {name: name, var: name}, {name: requestId, var: request_id}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, availability_zones: $availability_zones, multiplex_settings: $multiplex_settings, name: $name, request_id: $request_id, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of the existing multiplexes.
#
# GET /prod/multiplexes
# Returns: record<Multiplexes: table<Arn: string, AvailabilityZones: list, Id: string, MultiplexSettings: record, Name: string, PipelinesRunningCount: int, ProgramCount: int, State: string, Tags: record>, NextToken: string>
# operationId: ListMultiplexes
export def "list-multiplexes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of items to return.
  --next-token: string # The token to retrieve the next page of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/prod/multiplexes"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new program in the multiplex.
#
# POST /prod/multiplexes/{multiplexId}/programs
# Returns: record<MultiplexProgram: record<ChannelId: string, MultiplexProgramSettings: record<PreferredChannelPipeline: string, ProgramNumber: int, ServiceDescriptor: record, VideoSettings: record>, PacketIdentifiersMap: record<AudioPids: list, DvbSubPids: list, DvbTeletextPid: int, EtvPlatformPid: int, EtvSignalPid: int, KlvDataPids: list, PcrPid: int, PmtPid: int, PrivateMetadataPid: int, Scte27Pids: list, Scte35Pid: int, TimedMetadataPid: int, VideoPid: int>, PipelineDetails: list<record>, ProgramName: string>>
# operationId: CreateMultiplexProgram
export def "create-multiplex-program" [
  multiplex_id: string
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
  multiplex_program_settings: record # Multiplex Program settings configuration. — shape: {PreferredChannelPipeline?: "CURRENTLY_ACTIVE"|"PIPELINE_0"|"PIPELINE_1", ProgramNumber?: int, ServiceDescriptor?: record, VideoSettings?: record}
  program_name: string # Placeholder documentation for __string
  request_id: string # Placeholder documentation for __string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/prod/multiplexes/{multiplexId}/programs"
    path_params: [{name: multiplexId, var: multiplex_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: multiplexProgramSettings, var: multiplex_program_settings}, {name: programName, var: program_name}, {name: requestId, var: request_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    multiplex_id: $multiplex_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, multiplex_program_settings: $multiplex_program_settings, program_name: $program_name, request_id: $request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the programs that currently exist for a specific multiplex.
#
# GET /prod/multiplexes/{multiplexId}/programs
# Returns: record<MultiplexPrograms: table<ChannelId: string, ProgramName: string>, NextToken: string>
# operationId: ListMultiplexPrograms
export def "list-multiplex-programs" [
  multiplex_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of items to return.
  --next-token: string # The token to retrieve the next page of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/prod/multiplexes/{multiplexId}/programs"
    path_params: [{name: multiplexId, var: multiplex_id}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    multiplex_id: $multiplex_id, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a partner input
#
# POST /prod/inputs/{inputId}/partners
# Returns: record<Input: record<Arn: string, AttachedChannels: list<string>, Destinations: list<record>, Id: string, InputClass: string, InputDevices: list<record>, InputPartnerIds: list<string>, InputSourceType: string, MediaConnectFlows: list<record>, Name: string, RoleArn: string, SecurityGroups: list<string>, Sources: list<record>, State: string, Tags: record, Type: string>>
# operationId: CreatePartnerInput
export def "create-partner-input" [
  input_id: string
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
  --request-id: string # Placeholder documentation for __string
  --tags: record # Placeholder documentation for Tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/prod/inputs/{inputId}/partners"
    path_params: [{name: inputId, var: input_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: requestId, var: request_id}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    input_id: $input_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, request_id: $request_id, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create tags for a resource
#
# POST /prod/tags/{resource-arn}
# operationId: CreateTags
export def "create-tags" [
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
  --tags: record # Placeholder documentation for Tags
]: any -> any {
  $in | http-request {
    method: post
    path: "/prod/tags/{resource-arn}"
    path_params: [{name: resource-arn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Produces list of tags that have been created for a resource
#
# GET /prod/tags/{resource-arn}
# Returns: record<Tags: record>
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
    path: "/prod/tags/{resource-arn}"
    path_params: [{name: resource-arn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts deletion of channel. The associated outputs are also deleted.
#
# DELETE /prod/channels/{channelId}
# Returns: record<Arn: string, CdiInputSpecification: record<Resolution: string>, ChannelClass: string, Destinations: table<Id: string, MediaPackageSettings: list, MultiplexSettings: record, Settings: list>, EgressEndpoints: table<SourceIp: string>, EncoderSettings: record<AudioDescriptions: list<record>, AvailBlanking: record<AvailBlankingImage: record, State: string>, AvailConfiguration: record<AvailSettings: record>, BlackoutSlate: record<BlackoutSlateImage: record, NetworkEndBlackout: string, NetworkEndBlackoutImage: record, NetworkId: string, State: string>, CaptionDescriptions: list<record>, FeatureActivations: record<InputPrepareScheduleActions: string>, GlobalConfiguration: record<InitialAudioGain: int, InputEndAction: string, InputLossBehavior: record, OutputLockingMode: string, OutputTimingSource: string, SupportLowFramerateInputs: string>, MotionGraphicsConfiguration: record<MotionGraphicsInsertion: string, MotionGraphicsSettings: record>, NielsenConfiguration: record<DistributorId: string, NielsenPcmToId3Tagging: string>, OutputGroups: list<record>, TimecodeConfig: record<Source: string, SyncThreshold: int>, VideoDescriptions: list<record>>, Id: string, InputAttachments: table<AutomaticInputFailoverSettings: record, InputAttachmentName: string, InputId: string, InputSettings: record>, InputSpecification: record<Codec: string, MaximumBitrate: string, Resolution: string>, LogLevel: string, Maintenance: record<MaintenanceDay: string, MaintenanceDeadline: string, MaintenanceScheduledDate: string, MaintenanceStartTime: string>, Name: string, PipelineDetails: table<ActiveInputAttachmentName: string, ActiveInputSwitchActionName: string, ActiveMotionGraphicsActionName: string, ActiveMotionGraphicsUri: string, PipelineId: string>, PipelinesRunningCount: int, RoleArn: string, State: string, Tags: record, Vpc: record<AvailabilityZones: list<string>, NetworkInterfaceIds: list<string>, SecurityGroupIds: list<string>, SubnetIds: list<string>>>
# operationId: DeleteChannel
export def "delete-channel" [
  channel_id: string
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
    path: "/prod/channels/{channelId}"
    path_params: [{name: channelId, var: channel_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets details about a channel
#
# GET /prod/channels/{channelId}
# Returns: record<Arn: string, CdiInputSpecification: record<Resolution: string>, ChannelClass: string, Destinations: table<Id: string, MediaPackageSettings: list, MultiplexSettings: record, Settings: list>, EgressEndpoints: table<SourceIp: string>, EncoderSettings: record<AudioDescriptions: list<record>, AvailBlanking: record<AvailBlankingImage: record, State: string>, AvailConfiguration: record<AvailSettings: record>, BlackoutSlate: record<BlackoutSlateImage: record, NetworkEndBlackout: string, NetworkEndBlackoutImage: record, NetworkId: string, State: string>, CaptionDescriptions: list<record>, FeatureActivations: record<InputPrepareScheduleActions: string>, GlobalConfiguration: record<InitialAudioGain: int, InputEndAction: string, InputLossBehavior: record, OutputLockingMode: string, OutputTimingSource: string, SupportLowFramerateInputs: string>, MotionGraphicsConfiguration: record<MotionGraphicsInsertion: string, MotionGraphicsSettings: record>, NielsenConfiguration: record<DistributorId: string, NielsenPcmToId3Tagging: string>, OutputGroups: list<record>, TimecodeConfig: record<Source: string, SyncThreshold: int>, VideoDescriptions: list<record>>, Id: string, InputAttachments: table<AutomaticInputFailoverSettings: record, InputAttachmentName: string, InputId: string, InputSettings: record>, InputSpecification: record<Codec: string, MaximumBitrate: string, Resolution: string>, LogLevel: string, Maintenance: record<MaintenanceDay: string, MaintenanceDeadline: string, MaintenanceScheduledDate: string, MaintenanceStartTime: string>, Name: string, PipelineDetails: table<ActiveInputAttachmentName: string, ActiveInputSwitchActionName: string, ActiveMotionGraphicsActionName: string, ActiveMotionGraphicsUri: string, PipelineId: string>, PipelinesRunningCount: int, RoleArn: string, State: string, Tags: record, Vpc: record<AvailabilityZones: list<string>, NetworkInterfaceIds: list<string>, SecurityGroupIds: list<string>, SubnetIds: list<string>>>
# operationId: DescribeChannel
export def "describe-channel" [
  channel_id: string
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
    path: "/prod/channels/{channelId}"
    path_params: [{name: channelId, var: channel_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a channel.
#
# PUT /prod/channels/{channelId}
# Returns: record<Channel: record<Arn: string, CdiInputSpecification: record<Resolution: string>, ChannelClass: string, Destinations: list<record>, EgressEndpoints: list<record>, EncoderSettings: record<AudioDescriptions: list, AvailBlanking: record, AvailConfiguration: record, BlackoutSlate: record, CaptionDescriptions: list, FeatureActivations: record, GlobalConfiguration: record, MotionGraphicsConfiguration: record, NielsenConfiguration: record, OutputGroups: list, TimecodeConfig: record, VideoDescriptions: list>, Id: string, InputAttachments: list<record>, InputSpecification: record<Codec: string, MaximumBitrate: string, Resolution: string>, LogLevel: string, Maintenance: record<MaintenanceDay: string, MaintenanceDeadline: string, MaintenanceScheduledDate: string, MaintenanceStartTime: string>, Name: string, PipelineDetails: list<record>, PipelinesRunningCount: int, RoleArn: string, State: string, Tags: record, Vpc: record<AvailabilityZones: list, NetworkInterfaceIds: list, SecurityGroupIds: list, SubnetIds: list>>>
# operationId: UpdateChannel
export def "update-channel" [
  channel_id: string
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
  --cdi-input-specification: record # Placeholder documentation for CdiInputSpecification — shape: {Resolution?: "SD"|"HD"|"FHD"|"UHD"}
  --destinations: list # Placeholder documentation for __listOfOutputDestination — item shape: {Id?: string, MediaPackageSettings?: list, MultiplexSettings?: record, Settings?: list}
  --encoder-settings: record # Encoder Settings — shape: {AudioDescriptions?: list, AvailBlanking?: record, AvailConfiguration?: record, BlackoutSlate?: record, CaptionDescriptions?: list, FeatureActivations?: record, GlobalConfiguration?: record, MotionGraphicsConfiguration?: record, NielsenConfiguration?: record, OutputGroups?: list, TimecodeConfig?: record, VideoDescriptions?: list}
  --input-attachments: list # Placeholder documentation for __listOfInputAttachment — item shape: {AutomaticInputFailoverSettings?: record, InputAttachmentName?: string, InputId?: string, InputSettings?: record}
  --input-specification: record # Placeholder documentation for InputSpecification — shape: {Codec?: "MPEG2"|"AVC"|"HEVC", MaximumBitrate?: "MAX_10_MBPS"|"MAX_20_MBPS"|"MAX_50_MBPS", Resolution?: "SD"|"HD"|"UHD"}
  --log-level: string@log-level-completer # The log level the user wants for their channel.
  --maintenance: record # Placeholder documentation for MaintenanceUpdateSettings — shape: {MaintenanceDay?: "MONDAY"|"TUESDAY"|"WEDNESDAY"|"THURSDAY"|"FRIDAY"|"SATURDAY"|"SUNDAY", MaintenanceScheduledDate?: string, MaintenanceStartTime?: string}
  --name: string # Placeholder documentation for __string
  --role-arn: string # Placeholder documentation for __string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/prod/channels/{channelId}"
    path_params: [{name: channelId, var: channel_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: cdiInputSpecification, var: cdi_input_specification}, {name: destinations, var: destinations}, {name: encoderSettings, var: encoder_settings}, {name: inputAttachments, var: input_attachments}, {name: inputSpecification, var: input_specification}, {name: logLevel, var: log_level}, {name: maintenance, var: maintenance}, {name: name, var: name}, {name: roleArn, var: role_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, cdi_input_specification: $cdi_input_specification, destinations: $destinations, encoder_settings: $encoder_settings, input_attachments: $input_attachments, input_specification: $input_specification, log_level: $log_level, maintenance: $maintenance, name: $name, role_arn: $role_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the input end point
#
# DELETE /prod/inputs/{inputId}
# Returns: record
# operationId: DeleteInput
export def "delete-input" [
  input_id: string
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
    path: "/prod/inputs/{inputId}"
    path_params: [{name: inputId, var: input_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    input_id: $input_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Produces details about an input
#
# GET /prod/inputs/{inputId}
# Returns: record<Arn: string, AttachedChannels: list<string>, Destinations: table<Ip: string, Port: string, Url: string, Vpc: record>, Id: string, InputClass: string, InputDevices: table<Id: string>, InputPartnerIds: list<string>, InputSourceType: string, MediaConnectFlows: table<FlowArn: string>, Name: string, RoleArn: string, SecurityGroups: list<string>, Sources: table<PasswordParam: string, Url: string, Username: string>, State: string, Tags: record, Type: string>
# operationId: DescribeInput
export def "describe-input" [
  input_id: string
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
    path: "/prod/inputs/{inputId}"
    path_params: [{name: inputId, var: input_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    input_id: $input_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an input.
#
# PUT /prod/inputs/{inputId}
# Returns: record<Input: record<Arn: string, AttachedChannels: list<string>, Destinations: list<record>, Id: string, InputClass: string, InputDevices: list<record>, InputPartnerIds: list<string>, InputSourceType: string, MediaConnectFlows: list<record>, Name: string, RoleArn: string, SecurityGroups: list<string>, Sources: list<record>, State: string, Tags: record, Type: string>>
# operationId: UpdateInput
export def "update-input" [
  input_id: string
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
  --destinations: list # Placeholder documentation for __listOfInputDestinationRequest — item shape: {StreamName?: string}
  --input-devices: list # Placeholder documentation for __listOfInputDeviceRequest — item shape: {Id?: string}
  --input-security-groups: list<string> # Placeholder documentation for __listOf__string
  --media-connect-flows: list # Placeholder documentation for __listOfMediaConnectFlowRequest — item shape: {FlowArn?: string}
  --name: string # Placeholder documentation for __string
  --role-arn: string # Placeholder documentation for __string
  --sources: list # Placeholder documentation for __listOfInputSourceRequest — item shape: {PasswordParam?: string, Url?: string, Username?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/prod/inputs/{inputId}"
    path_params: [{name: inputId, var: input_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: destinations, var: destinations}, {name: inputDevices, var: input_devices}, {name: inputSecurityGroups, var: input_security_groups}, {name: mediaConnectFlows, var: media_connect_flows}, {name: name, var: name}, {name: roleArn, var: role_arn}, {name: sources, var: sources}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    input_id: $input_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, destinations: $destinations, input_devices: $input_devices, input_security_groups: $input_security_groups, media_connect_flows: $media_connect_flows, name: $name, role_arn: $role_arn, sources: $sources
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an Input Security Group
#
# DELETE /prod/inputSecurityGroups/{inputSecurityGroupId}
# Returns: record
# operationId: DeleteInputSecurityGroup
export def "delete-input-security-group" [
  input_security_group_id: string
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
    path: "/prod/inputSecurityGroups/{inputSecurityGroupId}"
    path_params: [{name: inputSecurityGroupId, var: input_security_group_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    input_security_group_id: $input_security_group_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Produces a summary of an Input Security Group
#
# GET /prod/inputSecurityGroups/{inputSecurityGroupId}
# Returns: record<Arn: string, Id: string, Inputs: list<string>, State: string, Tags: record, WhitelistRules: table<Cidr: string>>
# operationId: DescribeInputSecurityGroup
export def "describe-input-security-group" [
  input_security_group_id: string
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
    path: "/prod/inputSecurityGroups/{inputSecurityGroupId}"
    path_params: [{name: inputSecurityGroupId, var: input_security_group_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    input_security_group_id: $input_security_group_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an Input Security Group's Whilelists.
#
# PUT /prod/inputSecurityGroups/{inputSecurityGroupId}
# Returns: record<SecurityGroup: record<Arn: string, Id: string, Inputs: list<string>, State: string, Tags: record, WhitelistRules: list<record>>>
# operationId: UpdateInputSecurityGroup
export def "update-input-security-group" [
  input_security_group_id: string
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
  --tags: record # Placeholder documentation for Tags
  --whitelist-rules: list # Placeholder documentation for __listOfInputWhitelistRuleCidr — item shape: {Cidr?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/prod/inputSecurityGroups/{inputSecurityGroupId}"
    path_params: [{name: inputSecurityGroupId, var: input_security_group_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}, {name: whitelistRules, var: whitelist_rules}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    input_security_group_id: $input_security_group_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, tags: $tags, whitelist_rules: $whitelist_rules
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a multiplex. The multiplex must be idle.
#
# DELETE /prod/multiplexes/{multiplexId}
# Returns: record<Arn: string, AvailabilityZones: list<string>, Destinations: table<MediaConnectSettings: record>, Id: string, MultiplexSettings: record<MaximumVideoBufferDelayMilliseconds: int, TransportStreamBitrate: int, TransportStreamId: int, TransportStreamReservedBitrate: int>, Name: string, PipelinesRunningCount: int, ProgramCount: int, State: string, Tags: record>
# operationId: DeleteMultiplex
export def "delete-multiplex" [
  multiplex_id: string
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
    path: "/prod/multiplexes/{multiplexId}"
    path_params: [{name: multiplexId, var: multiplex_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    multiplex_id: $multiplex_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets details about a multiplex.
#
# GET /prod/multiplexes/{multiplexId}
# Returns: record<Arn: string, AvailabilityZones: list<string>, Destinations: table<MediaConnectSettings: record>, Id: string, MultiplexSettings: record<MaximumVideoBufferDelayMilliseconds: int, TransportStreamBitrate: int, TransportStreamId: int, TransportStreamReservedBitrate: int>, Name: string, PipelinesRunningCount: int, ProgramCount: int, State: string, Tags: record>
# operationId: DescribeMultiplex
export def "describe-multiplex" [
  multiplex_id: string
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
    path: "/prod/multiplexes/{multiplexId}"
    path_params: [{name: multiplexId, var: multiplex_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    multiplex_id: $multiplex_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a multiplex.
#
# PUT /prod/multiplexes/{multiplexId}
# Returns: record<Multiplex: record<Arn: string, AvailabilityZones: list<string>, Destinations: list<record>, Id: string, MultiplexSettings: record<MaximumVideoBufferDelayMilliseconds: int, TransportStreamBitrate: int, TransportStreamId: int, TransportStreamReservedBitrate: int>, Name: string, PipelinesRunningCount: int, ProgramCount: int, State: string, Tags: record>>
# operationId: UpdateMultiplex
export def "update-multiplex" [
  multiplex_id: string
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
  --multiplex-settings: record # Contains configuration for a Multiplex event — shape: {MaximumVideoBufferDelayMilliseconds?: int, TransportStreamBitrate?: int, TransportStreamId?: int, TransportStreamReservedBitrate?: int}
  --name: string # Placeholder documentation for __string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/prod/multiplexes/{multiplexId}"
    path_params: [{name: multiplexId, var: multiplex_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: multiplexSettings, var: multiplex_settings}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    multiplex_id: $multiplex_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, multiplex_settings: $multiplex_settings, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a program from a multiplex.
#
# DELETE /prod/multiplexes/{multiplexId}/programs/{programName}
# Returns: record<ChannelId: string, MultiplexProgramSettings: record<PreferredChannelPipeline: string, ProgramNumber: int, ServiceDescriptor: record<ProviderName: string, ServiceName: string>, VideoSettings: record<ConstantBitrate: int, StatmuxSettings: record>>, PacketIdentifiersMap: record<AudioPids: list<int>, DvbSubPids: list<int>, DvbTeletextPid: int, EtvPlatformPid: int, EtvSignalPid: int, KlvDataPids: list<int>, PcrPid: int, PmtPid: int, PrivateMetadataPid: int, Scte27Pids: list<int>, Scte35Pid: int, TimedMetadataPid: int, VideoPid: int>, PipelineDetails: table<ActiveChannelPipeline: string, PipelineId: string>, ProgramName: string>
# operationId: DeleteMultiplexProgram
export def "delete-multiplex-program" [
  multiplex_id: string
  program_name: string
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
    path: "/prod/multiplexes/{multiplexId}/programs/{programName}"
    path_params: [{name: multiplexId, var: multiplex_id}, {name: programName, var: program_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    multiplex_id: $multiplex_id, program_name: $program_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the details for a program in a multiplex.
#
# GET /prod/multiplexes/{multiplexId}/programs/{programName}
# Returns: record<ChannelId: string, MultiplexProgramSettings: record<PreferredChannelPipeline: string, ProgramNumber: int, ServiceDescriptor: record<ProviderName: string, ServiceName: string>, VideoSettings: record<ConstantBitrate: int, StatmuxSettings: record>>, PacketIdentifiersMap: record<AudioPids: list<int>, DvbSubPids: list<int>, DvbTeletextPid: int, EtvPlatformPid: int, EtvSignalPid: int, KlvDataPids: list<int>, PcrPid: int, PmtPid: int, PrivateMetadataPid: int, Scte27Pids: list<int>, Scte35Pid: int, TimedMetadataPid: int, VideoPid: int>, PipelineDetails: table<ActiveChannelPipeline: string, PipelineId: string>, ProgramName: string>
# operationId: DescribeMultiplexProgram
export def "describe-multiplex-program" [
  multiplex_id: string
  program_name: string
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
    path: "/prod/multiplexes/{multiplexId}/programs/{programName}"
    path_params: [{name: multiplexId, var: multiplex_id}, {name: programName, var: program_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    multiplex_id: $multiplex_id, program_name: $program_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a program in a multiplex.
#
# PUT /prod/multiplexes/{multiplexId}/programs/{programName}
# Returns: record<MultiplexProgram: record<ChannelId: string, MultiplexProgramSettings: record<PreferredChannelPipeline: string, ProgramNumber: int, ServiceDescriptor: record, VideoSettings: record>, PacketIdentifiersMap: record<AudioPids: list, DvbSubPids: list, DvbTeletextPid: int, EtvPlatformPid: int, EtvSignalPid: int, KlvDataPids: list, PcrPid: int, PmtPid: int, PrivateMetadataPid: int, Scte27Pids: list, Scte35Pid: int, TimedMetadataPid: int, VideoPid: int>, PipelineDetails: list<record>, ProgramName: string>>
# operationId: UpdateMultiplexProgram
export def "update-multiplex-program" [
  multiplex_id: string
  program_name: string
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
  --multiplex-program-settings: record # Multiplex Program settings configuration. — shape: {PreferredChannelPipeline?: "CURRENTLY_ACTIVE"|"PIPELINE_0"|"PIPELINE_1", ProgramNumber?: int, ServiceDescriptor?: record, VideoSettings?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/prod/multiplexes/{multiplexId}/programs/{programName}"
    path_params: [{name: multiplexId, var: multiplex_id}, {name: programName, var: program_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: multiplexProgramSettings, var: multiplex_program_settings}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    multiplex_id: $multiplex_id, program_name: $program_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, multiplex_program_settings: $multiplex_program_settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an expired reservation.
#
# DELETE /prod/reservations/{reservationId}
# Returns: record<Arn: string, Count: int, CurrencyCode: string, Duration: int, DurationUnits: string, End: string, FixedPrice: float, Name: string, OfferingDescription: string, OfferingId: string, OfferingType: string, Region: string, RenewalSettings: record<AutomaticRenewal: string, RenewalCount: int>, ReservationId: string, ResourceSpecification: record<ChannelClass: string, Codec: string, MaximumBitrate: string, MaximumFramerate: string, Resolution: string, ResourceType: string, SpecialFeature: string, VideoQuality: string>, Start: string, State: string, Tags: record, UsagePrice: float>
# operationId: DeleteReservation
export def "delete-reservation" [
  reservation_id: string
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
    path: "/prod/reservations/{reservationId}"
    path_params: [{name: reservationId, var: reservation_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    reservation_id: $reservation_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get details for a reservation.
#
# GET /prod/reservations/{reservationId}
# Returns: record<Arn: string, Count: int, CurrencyCode: string, Duration: int, DurationUnits: string, End: string, FixedPrice: float, Name: string, OfferingDescription: string, OfferingId: string, OfferingType: string, Region: string, RenewalSettings: record<AutomaticRenewal: string, RenewalCount: int>, ReservationId: string, ResourceSpecification: record<ChannelClass: string, Codec: string, MaximumBitrate: string, MaximumFramerate: string, Resolution: string, ResourceType: string, SpecialFeature: string, VideoQuality: string>, Start: string, State: string, Tags: record, UsagePrice: float>
# operationId: DescribeReservation
export def "describe-reservation" [
  reservation_id: string
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
    path: "/prod/reservations/{reservationId}"
    path_params: [{name: reservationId, var: reservation_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    reservation_id: $reservation_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update reservation.
#
# PUT /prod/reservations/{reservationId}
# Returns: record<Reservation: record<Arn: string, Count: int, CurrencyCode: string, Duration: int, DurationUnits: string, End: string, FixedPrice: float, Name: string, OfferingDescription: string, OfferingId: string, OfferingType: string, Region: string, RenewalSettings: record<AutomaticRenewal: string, RenewalCount: int>, ReservationId: string, ResourceSpecification: record<ChannelClass: string, Codec: string, MaximumBitrate: string, MaximumFramerate: string, Resolution: string, ResourceType: string, SpecialFeature: string, VideoQuality: string>, Start: string, State: string, Tags: record, UsagePrice: float>>
# operationId: UpdateReservation
export def "update-reservation" [
  reservation_id: string
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
  --name: string # Placeholder documentation for __string
  --renewal-settings: record # The Renewal settings for Reservations — shape: {AutomaticRenewal?: "DISABLED"|"ENABLED"|"UNAVAILABLE", RenewalCount?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/prod/reservations/{reservationId}"
    path_params: [{name: reservationId, var: reservation_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: renewalSettings, var: renewal_settings}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    reservation_id: $reservation_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, renewal_settings: $renewal_settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes tags for a resource
#
# DELETE /prod/tags/{resource-arn}
# operationId: DeleteTags
export def "delete-tags" [
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
  --tag-keys: list<string> # An array of tag keys to delete (required)
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
    path: "/prod/tags/{resource-arn}"
    path_params: [{name: resource-arn, var: resource_arn}]
    query: [{name: tagKeys, var: tag_keys, style: multi, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    resource_arn: $resource_arn, tag_keys: $tag_keys, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details for the input device
#
# GET /prod/inputDevices/{inputDeviceId}
# Returns: record<Arn: string, ConnectionState: string, DeviceSettingsSyncState: string, DeviceUpdateStatus: string, HdDeviceSettings: record<ActiveInput: string, ConfiguredInput: string, DeviceState: string, Framerate: float, Height: int, MaxBitrate: int, ScanType: string, Width: int, LatencyMs: int>, Id: string, MacAddress: string, Name: string, NetworkSettings: record<DnsAddresses: list<string>, Gateway: string, IpAddress: string, IpScheme: string, SubnetMask: string>, SerialNumber: string, Type: string, UhdDeviceSettings: record<ActiveInput: string, ConfiguredInput: string, DeviceState: string, Framerate: float, Height: int, MaxBitrate: int, ScanType: string, Width: int, LatencyMs: int>, Tags: record>
# operationId: DescribeInputDevice
export def "describe-input-device" [
  input_device_id: string
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
    path: "/prod/inputDevices/{inputDeviceId}"
    path_params: [{name: inputDeviceId, var: input_device_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    input_device_id: $input_device_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the parameters for the input device.
#
# PUT /prod/inputDevices/{inputDeviceId}
# Returns: record<Arn: string, ConnectionState: string, DeviceSettingsSyncState: string, DeviceUpdateStatus: string, HdDeviceSettings: record<ActiveInput: string, ConfiguredInput: string, DeviceState: string, Framerate: float, Height: int, MaxBitrate: int, ScanType: string, Width: int, LatencyMs: int>, Id: string, MacAddress: string, Name: string, NetworkSettings: record<DnsAddresses: list<string>, Gateway: string, IpAddress: string, IpScheme: string, SubnetMask: string>, SerialNumber: string, Type: string, UhdDeviceSettings: record<ActiveInput: string, ConfiguredInput: string, DeviceState: string, Framerate: float, Height: int, MaxBitrate: int, ScanType: string, Width: int, LatencyMs: int>, Tags: record>
# operationId: UpdateInputDevice
export def "update-input-device" [
  input_device_id: string
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
  --hd-device-settings: record # Configurable settings for the input device. — shape: {ConfiguredInput?: "AUTO"|"HDMI"|"SDI", MaxBitrate?: int, LatencyMs?: int}
  --name: string # Placeholder documentation for __string
  --uhd-device-settings: record # Configurable settings for the input device. — shape: {ConfiguredInput?: "AUTO"|"HDMI"|"SDI", MaxBitrate?: int, LatencyMs?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/prod/inputDevices/{inputDeviceId}"
    path_params: [{name: inputDeviceId, var: input_device_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: hdDeviceSettings, var: hd_device_settings}, {name: name, var: name}, {name: uhdDeviceSettings, var: uhd_device_settings}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    input_device_id: $input_device_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, hd_device_settings: $hd_device_settings, name: $name, uhd_device_settings: $uhd_device_settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the latest thumbnail data for the input device.
#
# GET /prod/inputDevices/{inputDeviceId}/thumbnailData
# Returns: record<Body: string>
# operationId: DescribeInputDeviceThumbnail
export def "describe-input-device-thumbnail" [
  input_device_id: string
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
  --hdr-accept: string@accept-completer # The HTTP Accept header. Indicates the requested type for the thumbnail. (required) (spec name: accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/prod/inputDevices/{inputDeviceId}/thumbnailData"
    path_params: [{name: inputDeviceId, var: input_device_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: accept, var: hdr_accept, required: true, default: "image/jpeg"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    input_device_id: $input_device_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, hdr_accept: $hdr_accept
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get details for an offering.
#
# GET /prod/offerings/{offeringId}
# Returns: record<Arn: string, CurrencyCode: string, Duration: int, DurationUnits: string, FixedPrice: float, OfferingDescription: string, OfferingId: string, OfferingType: string, Region: string, ResourceSpecification: record<ChannelClass: string, Codec: string, MaximumBitrate: string, MaximumFramerate: string, Resolution: string, ResourceType: string, SpecialFeature: string, VideoQuality: string>, UsagePrice: float>
# operationId: DescribeOffering
export def "describe-offering" [
  offering_id: string
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
    path: "/prod/offerings/{offeringId}"
    path_params: [{name: offeringId, var: offering_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List input devices that are currently being transferred. List input devices that you are transferring from your AWS account or input devices that another AWS account is transferring to you.
#
# GET /prod/inputDeviceTransfers
# Returns: record<InputDeviceTransfers: table<Id: string, Message: string, TargetCustomerId: string, TransferType: string>, NextToken: string>
# operationId: ListInputDeviceTransfers
export def "list-input-device-transfers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int
  --next-token: string
  --transfer-type: string # required
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/prod/inputDeviceTransfers"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: transferType, var: transfer_type, required: true}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, transfer_type: $transfer_type, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List input devices
#
# GET /prod/inputDevices
# Returns: record<InputDevices: table<Arn: string, ConnectionState: string, DeviceSettingsSyncState: string, DeviceUpdateStatus: string, HdDeviceSettings: record, Id: string, MacAddress: string, Name: string, NetworkSettings: record, SerialNumber: string, Type: string, UhdDeviceSettings: record, Tags: record>, NextToken: string>
# operationId: ListInputDevices
export def "list-input-devices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int
  --next-token: string
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/prod/inputDevices"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List offerings available for purchase.
#
# GET /prod/offerings
# Returns: record<NextToken: string, Offerings: table<Arn: string, CurrencyCode: string, Duration: int, DurationUnits: string, FixedPrice: float, OfferingDescription: string, OfferingId: string, OfferingType: string, Region: string, ResourceSpecification: record, UsagePrice: float>>
# operationId: ListOfferings
export def "list-offerings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --channel-class: string # Filter by channel class, 'STANDARD' or 'SINGLE_PIPELINE'
  --channel-configuration: string # Filter to offerings that match the configuration of an existing channel, e.g. '2345678' (a channel ID)
  --codec: string # Filter by codec, 'AVC', 'HEVC', 'MPEG2', 'AUDIO', or 'LINK'
  --duration: string # Filter by offering duration, e.g. '12'
  --max-results: int
  --maximum-bitrate: string # Filter by bitrate, 'MAX_10_MBPS', 'MAX_20_MBPS', or 'MAX_50_MBPS'
  --maximum-framerate: string # Filter by framerate, 'MAX_30_FPS' or 'MAX_60_FPS'
  --next-token: string
  --resolution: string # Filter by resolution, 'SD', 'HD', 'FHD', or 'UHD'
  --resource-type: string # Filter by resource type, 'INPUT', 'OUTPUT', 'MULTIPLEX', or 'CHANNEL'
  --special-feature: string # Filter by special feature, 'ADVANCED_AUDIO' or 'AUDIO_NORMALIZATION'
  --video-quality: string # Filter by video quality, 'STANDARD', 'ENHANCED', or 'PREMIUM'
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/prod/offerings"
    query: [{name: channelClass, var: channel_class}, {name: channelConfiguration, var: channel_configuration}, {name: codec, var: codec}, {name: duration, var: duration}, {name: maxResults, var: max_results}, {name: maximumBitrate, var: maximum_bitrate}, {name: maximumFramerate, var: maximum_framerate}, {name: nextToken, var: next_token}, {name: resolution, var: resolution}, {name: resourceType, var: resource_type}, {name: specialFeature, var: special_feature}, {name: videoQuality, var: video_quality}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_class: $channel_class, channel_configuration: $channel_configuration, codec: $codec, duration: $duration, max_results: $max_results, maximum_bitrate: $maximum_bitrate, maximum_framerate: $maximum_framerate, next_token: $next_token, resolution: $resolution, resource_type: $resource_type, special_feature: $special_feature, video_quality: $video_quality, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List purchased reservations.
#
# GET /prod/reservations
# Returns: record<NextToken: string, Reservations: table<Arn: string, Count: int, CurrencyCode: string, Duration: int, DurationUnits: string, End: string, FixedPrice: float, Name: string, OfferingDescription: string, OfferingId: string, OfferingType: string, Region: string, RenewalSettings: record, ReservationId: string, ResourceSpecification: record, Start: string, State: string, Tags: record, UsagePrice: float>>
# operationId: ListReservations
export def "list-reservations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --channel-class: string # Filter by channel class, 'STANDARD' or 'SINGLE_PIPELINE'
  --codec: string # Filter by codec, 'AVC', 'HEVC', 'MPEG2', 'AUDIO', or 'LINK'
  --max-results: int
  --maximum-bitrate: string # Filter by bitrate, 'MAX_10_MBPS', 'MAX_20_MBPS', or 'MAX_50_MBPS'
  --maximum-framerate: string # Filter by framerate, 'MAX_30_FPS' or 'MAX_60_FPS'
  --next-token: string
  --resolution: string # Filter by resolution, 'SD', 'HD', 'FHD', or 'UHD'
  --resource-type: string # Filter by resource type, 'INPUT', 'OUTPUT', 'MULTIPLEX', or 'CHANNEL'
  --special-feature: string # Filter by special feature, 'ADVANCED_AUDIO' or 'AUDIO_NORMALIZATION'
  --video-quality: string # Filter by video quality, 'STANDARD', 'ENHANCED', or 'PREMIUM'
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/prod/reservations"
    query: [{name: channelClass, var: channel_class}, {name: codec, var: codec}, {name: maxResults, var: max_results}, {name: maximumBitrate, var: maximum_bitrate}, {name: maximumFramerate, var: maximum_framerate}, {name: nextToken, var: next_token}, {name: resolution, var: resolution}, {name: resourceType, var: resource_type}, {name: specialFeature, var: special_feature}, {name: videoQuality, var: video_quality}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_class: $channel_class, codec: $codec, max_results: $max_results, maximum_bitrate: $maximum_bitrate, maximum_framerate: $maximum_framerate, next_token: $next_token, resolution: $resolution, resource_type: $resource_type, special_feature: $special_feature, video_quality: $video_quality, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Purchase an offering and create a reservation.
#
# POST /prod/offerings/{offeringId}/purchase
# Returns: record<Reservation: record<Arn: string, Count: int, CurrencyCode: string, Duration: int, DurationUnits: string, End: string, FixedPrice: float, Name: string, OfferingDescription: string, OfferingId: string, OfferingType: string, Region: string, RenewalSettings: record<AutomaticRenewal: string, RenewalCount: int>, ReservationId: string, ResourceSpecification: record<ChannelClass: string, Codec: string, MaximumBitrate: string, MaximumFramerate: string, Resolution: string, ResourceType: string, SpecialFeature: string, VideoQuality: string>, Start: string, State: string, Tags: record, UsagePrice: float>>
# operationId: PurchaseOffering
export def "purchase-offering" [
  offering_id: string
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
  count: int # Placeholder documentation for __integerMin1
  --name: string # Placeholder documentation for __string
  --renewal-settings: record # The Renewal settings for Reservations — shape: {AutomaticRenewal?: "DISABLED"|"ENABLED"|"UNAVAILABLE", RenewalCount?: int}
  --request-id: string # Placeholder documentation for __string
  --start: string # Placeholder documentation for __string
  --tags: record # Placeholder documentation for Tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/prod/offerings/{offeringId}/purchase"
    path_params: [{name: offeringId, var: offering_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: count, var: count}, {name: name, var: name}, {name: renewalSettings, var: renewal_settings}, {name: requestId, var: request_id}, {name: start, var: start}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    offering_id: $offering_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, count: $count, name: $name, renewal_settings: $renewal_settings, request_id: $request_id, start: $start, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send a reboot command to the specified input device. The device will begin rebooting within a few seconds of sending the command. When the reboot is complete, the device’s connection status will change to connected.
#
# POST /prod/inputDevices/{inputDeviceId}/reboot
# Returns: record
# operationId: RebootInputDevice
export def "reboot-input-device" [
  input_device_id: string
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
  --force: string@force-completer # Whether or not to force reboot the input device.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/prod/inputDevices/{inputDeviceId}/reboot"
    path_params: [{name: inputDeviceId, var: input_device_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: force, var: force}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    input_device_id: $input_device_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, force: $force
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reject the transfer of the specified input device to your AWS account.
#
# POST /prod/inputDevices/{inputDeviceId}/reject
# Returns: record
# operationId: RejectInputDeviceTransfer
export def "reject-input-device-transfer" [
  input_device_id: string
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
    path: "/prod/inputDevices/{inputDeviceId}/reject"
    path_params: [{name: inputDeviceId, var: input_device_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    input_device_id: $input_device_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts an existing channel
#
# POST /prod/channels/{channelId}/start
# Returns: record<Arn: string, CdiInputSpecification: record<Resolution: string>, ChannelClass: string, Destinations: table<Id: string, MediaPackageSettings: list, MultiplexSettings: record, Settings: list>, EgressEndpoints: table<SourceIp: string>, EncoderSettings: record<AudioDescriptions: list<record>, AvailBlanking: record<AvailBlankingImage: record, State: string>, AvailConfiguration: record<AvailSettings: record>, BlackoutSlate: record<BlackoutSlateImage: record, NetworkEndBlackout: string, NetworkEndBlackoutImage: record, NetworkId: string, State: string>, CaptionDescriptions: list<record>, FeatureActivations: record<InputPrepareScheduleActions: string>, GlobalConfiguration: record<InitialAudioGain: int, InputEndAction: string, InputLossBehavior: record, OutputLockingMode: string, OutputTimingSource: string, SupportLowFramerateInputs: string>, MotionGraphicsConfiguration: record<MotionGraphicsInsertion: string, MotionGraphicsSettings: record>, NielsenConfiguration: record<DistributorId: string, NielsenPcmToId3Tagging: string>, OutputGroups: list<record>, TimecodeConfig: record<Source: string, SyncThreshold: int>, VideoDescriptions: list<record>>, Id: string, InputAttachments: table<AutomaticInputFailoverSettings: record, InputAttachmentName: string, InputId: string, InputSettings: record>, InputSpecification: record<Codec: string, MaximumBitrate: string, Resolution: string>, LogLevel: string, Maintenance: record<MaintenanceDay: string, MaintenanceDeadline: string, MaintenanceScheduledDate: string, MaintenanceStartTime: string>, Name: string, PipelineDetails: table<ActiveInputAttachmentName: string, ActiveInputSwitchActionName: string, ActiveMotionGraphicsActionName: string, ActiveMotionGraphicsUri: string, PipelineId: string>, PipelinesRunningCount: int, RoleArn: string, State: string, Tags: record, Vpc: record<AvailabilityZones: list<string>, NetworkInterfaceIds: list<string>, SecurityGroupIds: list<string>, SubnetIds: list<string>>>
# operationId: StartChannel
export def "start-channel" [
  channel_id: string
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
    path: "/prod/channels/{channelId}/start"
    path_params: [{name: channelId, var: channel_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start a maintenance window for the specified input device. Starting a maintenance window will give the device up to two hours to install software. If the device was streaming prior to the maintenance, it will resume streaming when the software is fully installed. Devices automatically install updates while they are powered on and their MediaLive channels are stopped. A maintenance window allows you to update a device without having to stop MediaLive channels that use the device. The device must remain powered on and connected to the internet for the duration of the maintenance.
#
# POST /prod/inputDevices/{inputDeviceId}/startInputDeviceMaintenanceWindow
# Returns: record
# operationId: StartInputDeviceMaintenanceWindow
export def "start-input-device-maintenance-window" [
  input_device_id: string
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
    path: "/prod/inputDevices/{inputDeviceId}/startInputDeviceMaintenanceWindow"
    path_params: [{name: inputDeviceId, var: input_device_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    input_device_id: $input_device_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start (run) the multiplex. Starting the multiplex does not start the channels. You must explicitly start each channel.
#
# POST /prod/multiplexes/{multiplexId}/start
# Returns: record<Arn: string, AvailabilityZones: list<string>, Destinations: table<MediaConnectSettings: record>, Id: string, MultiplexSettings: record<MaximumVideoBufferDelayMilliseconds: int, TransportStreamBitrate: int, TransportStreamId: int, TransportStreamReservedBitrate: int>, Name: string, PipelinesRunningCount: int, ProgramCount: int, State: string, Tags: record>
# operationId: StartMultiplex
export def "start-multiplex" [
  multiplex_id: string
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
    path: "/prod/multiplexes/{multiplexId}/start"
    path_params: [{name: multiplexId, var: multiplex_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    multiplex_id: $multiplex_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops a running channel
#
# POST /prod/channels/{channelId}/stop
# Returns: record<Arn: string, CdiInputSpecification: record<Resolution: string>, ChannelClass: string, Destinations: table<Id: string, MediaPackageSettings: list, MultiplexSettings: record, Settings: list>, EgressEndpoints: table<SourceIp: string>, EncoderSettings: record<AudioDescriptions: list<record>, AvailBlanking: record<AvailBlankingImage: record, State: string>, AvailConfiguration: record<AvailSettings: record>, BlackoutSlate: record<BlackoutSlateImage: record, NetworkEndBlackout: string, NetworkEndBlackoutImage: record, NetworkId: string, State: string>, CaptionDescriptions: list<record>, FeatureActivations: record<InputPrepareScheduleActions: string>, GlobalConfiguration: record<InitialAudioGain: int, InputEndAction: string, InputLossBehavior: record, OutputLockingMode: string, OutputTimingSource: string, SupportLowFramerateInputs: string>, MotionGraphicsConfiguration: record<MotionGraphicsInsertion: string, MotionGraphicsSettings: record>, NielsenConfiguration: record<DistributorId: string, NielsenPcmToId3Tagging: string>, OutputGroups: list<record>, TimecodeConfig: record<Source: string, SyncThreshold: int>, VideoDescriptions: list<record>>, Id: string, InputAttachments: table<AutomaticInputFailoverSettings: record, InputAttachmentName: string, InputId: string, InputSettings: record>, InputSpecification: record<Codec: string, MaximumBitrate: string, Resolution: string>, LogLevel: string, Maintenance: record<MaintenanceDay: string, MaintenanceDeadline: string, MaintenanceScheduledDate: string, MaintenanceStartTime: string>, Name: string, PipelineDetails: table<ActiveInputAttachmentName: string, ActiveInputSwitchActionName: string, ActiveMotionGraphicsActionName: string, ActiveMotionGraphicsUri: string, PipelineId: string>, PipelinesRunningCount: int, RoleArn: string, State: string, Tags: record, Vpc: record<AvailabilityZones: list<string>, NetworkInterfaceIds: list<string>, SecurityGroupIds: list<string>, SubnetIds: list<string>>>
# operationId: StopChannel
export def "stop-channel" [
  channel_id: string
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
    path: "/prod/channels/{channelId}/stop"
    path_params: [{name: channelId, var: channel_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops a running multiplex. If the multiplex isn't running, this action has no effect.
#
# POST /prod/multiplexes/{multiplexId}/stop
# Returns: record<Arn: string, AvailabilityZones: list<string>, Destinations: table<MediaConnectSettings: record>, Id: string, MultiplexSettings: record<MaximumVideoBufferDelayMilliseconds: int, TransportStreamBitrate: int, TransportStreamId: int, TransportStreamReservedBitrate: int>, Name: string, PipelinesRunningCount: int, ProgramCount: int, State: string, Tags: record>
# operationId: StopMultiplex
export def "stop-multiplex" [
  multiplex_id: string
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
    path: "/prod/multiplexes/{multiplexId}/stop"
    path_params: [{name: multiplexId, var: multiplex_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    multiplex_id: $multiplex_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start an input device transfer to another AWS account. After you make the request, the other account must accept or reject the transfer.
#
# POST /prod/inputDevices/{inputDeviceId}/transfer
# Returns: record
# operationId: TransferInputDevice
export def "transfer-input-device" [
  input_device_id: string
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
  --target-customer-id: string # Placeholder documentation for __string
  --target-region: string # Placeholder documentation for __string
  --transfer-message: string # Placeholder documentation for __string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/prod/inputDevices/{inputDeviceId}/transfer"
    path_params: [{name: inputDeviceId, var: input_device_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: targetCustomerId, var: target_customer_id}, {name: targetRegion, var: target_region}, {name: transferMessage, var: transfer_message}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    input_device_id: $input_device_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, target_customer_id: $target_customer_id, target_region: $target_region, transfer_message: $transfer_message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes the class of the channel.
#
# PUT /prod/channels/{channelId}/channelClass
# Returns: record<Channel: record<Arn: string, CdiInputSpecification: record<Resolution: string>, ChannelClass: string, Destinations: list<record>, EgressEndpoints: list<record>, EncoderSettings: record<AudioDescriptions: list, AvailBlanking: record, AvailConfiguration: record, BlackoutSlate: record, CaptionDescriptions: list, FeatureActivations: record, GlobalConfiguration: record, MotionGraphicsConfiguration: record, NielsenConfiguration: record, OutputGroups: list, TimecodeConfig: record, VideoDescriptions: list>, Id: string, InputAttachments: list<record>, InputSpecification: record<Codec: string, MaximumBitrate: string, Resolution: string>, LogLevel: string, Maintenance: record<MaintenanceDay: string, MaintenanceDeadline: string, MaintenanceScheduledDate: string, MaintenanceStartTime: string>, Name: string, PipelineDetails: list<record>, PipelinesRunningCount: int, RoleArn: string, State: string, Tags: record, Vpc: record<AvailabilityZones: list, NetworkInterfaceIds: list, SecurityGroupIds: list, SubnetIds: list>>>
# operationId: UpdateChannelClass
export def "update-channel-class" [
  channel_id: string
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
  channel_class: string@channel-class-completer # A standard channel has two encoding pipelines and a single pipeline channel only has one.
  --destinations: list # Placeholder documentation for __listOfOutputDestination — item shape: {Id?: string, MediaPackageSettings?: list, MultiplexSettings?: record, Settings?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/prod/channels/{channelId}/channelClass"
    path_params: [{name: channelId, var: channel_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: channelClass, var: channel_class}, {name: destinations, var: destinations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, channel_class: $channel_class, destinations: $destinations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
