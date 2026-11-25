# Auto-generated client for Slack Web API v1.7.0
# Source: https://api.apis.guru/v2/specs/slack.com/1.7.0/openapi.json
# Auth: --token flag or $env.SLACK_WEB_API_TOKEN

const CLIENT = {
  base_url: "https://slack.com/api"
  token_env_var: "SLACK_WEB_API_TOKEN"
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

def base-url-completer [] { ["https://slack.com/api"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    admin-apps-approve: "record<ok: bool>"
    admin-apps-approved-list: "record<ok: bool>"
    admin-apps-requests-list: "record<ok: bool>"
    admin-apps-restrict: "record<ok: bool>"
    admin-apps-restricted-list: "record<ok: bool>"
    admin-conversations-archive: "record<ok: bool>"
    admin-conversations-convert-to-private: "record<ok: bool>"
    admin-conversations-create: "record<channel_id: string, ok: bool>"
    admin-conversations-delete: "record<ok: bool>"
    admin-conversations-disconnect-shared: "record<ok: bool>"
    admin-conversations-ekm-list-original-connected-channel-info: "record<ok: bool>"
    admin-conversations-get-conversation-prefs: "record<ok: bool, prefs: record<can_thread: record<type: list, user: list>, who_can_post: record<type: list, user: list>>>"
    admin-conversations-get-teams: "record<ok: bool, response_metadata: record<next_cursor: string>, team_ids: list<string>>"
    admin-conversations-invite: "record<ok: bool>"
    admin-conversations-rename: "record<ok: bool>"
    admin-conversations-restrict-access-add-group: "record<ok: bool>"
    admin-conversations-restrict-access-list-groups: "record<ok: bool>"
    admin-conversations-restrict-access-remove-group: "record<ok: bool>"
    admin-conversations-search: "record<channels: table<accepted_user: string, created: int, creator: string, id: string, is_archived: bool, is_channel: bool, is_frozen: bool, is_general: bool, is_member: bool, is_moved: int, is_mpim: bool, is_non_threadable: bool, is_org_shared: bool, is_pending_ext_shared: bool, is_private: bool, is_read_only: bool, is_shared: bool, is_thread_only: bool, last_read: string, latest: list, members: list, name: string, name_normalized: string, num_members: int, pending_shared: list, previous_names: list, priority: float, purpose: record, topic: record, unlinked: int, unread_count: int, unread_count_display: int>, next_cursor: string>"
    admin-conversations-set-conversation-prefs: "record<ok: bool>"
    admin-conversations-set-teams: "record<ok: bool>"
    admin-conversations-unarchive: "record<ok: bool>"
    admin-emoji-add: "record<ok: bool>"
    admin-emoji-add-alias: "record<ok: bool>"
    admin-emoji-list: "record<ok: bool>"
    admin-emoji-remove: "record<ok: bool>"
    admin-emoji-rename: "record<ok: bool>"
    admin-invite-requests-approve: "record<ok: bool>"
    admin-invite-requests-approved-list: "record<ok: bool>"
    admin-invite-requests-denied-list: "record<ok: bool>"
    admin-invite-requests-deny: "record<ok: bool>"
    admin-invite-requests-list: "record<ok: bool>"
    admin-teams-admins-list: "record<ok: bool>"
    admin-teams-create: "record<ok: bool>"
    admin-teams-list: "record<ok: bool>"
    admin-teams-owners-list: "record<ok: bool>"
    admin-teams-settings-info: "record<ok: bool>"
    admin-teams-settings-set-default-channels: "record<ok: bool>"
    admin-teams-settings-set-description: "record<ok: bool>"
    admin-teams-settings-set-discoverability: "record<ok: bool>"
    admin-teams-settings-set-icon: "record<ok: bool>"
    admin-teams-settings-set-name: "record<ok: bool>"
    admin-usergroups-add-channels: "record<ok: bool>"
    admin-usergroups-add-teams: "record<ok: bool>"
    admin-usergroups-list-channels: "record<ok: bool>"
    admin-usergroups-remove-channels: "record<ok: bool>"
    admin-users-assign: "record<ok: bool>"
    admin-users-invite: "record<ok: bool>"
    admin-users-list: "record<ok: bool>"
    admin-users-remove: "record<ok: bool>"
    admin-users-session-invalidate: "record<ok: bool>"
    admin-users-session-reset: "record<ok: bool>"
    admin-users-set-admin: "record<ok: bool>"
    admin-users-set-expiration: "record<ok: bool>"
    admin-users-set-owner: "record<ok: bool>"
    admin-users-set-regular: "record<ok: bool>"
    api-test: "record<ok: bool>"
    apps-event-authorizations-list: "record<ok: bool>"
    apps-permissions-info: "record<info: record<app_home: record<resources: record, scopes: list>, channel: record<resources: record, scopes: list>, group: record<resources: record, scopes: list>, im: record<resources: record, scopes: list>, mpim: record<resources: record, scopes: list>, team: record<resources: record, scopes: list>>, ok: bool>"
    apps-permissions-request: "record<ok: bool>"
    apps-permissions-resources-list: "record<ok: bool, resources: table<id: string, type: string>, response_metadata: record<next_cursor: string>>"
    apps-permissions-scopes-list: "record<ok: bool, scopes: record<app_home: list<string>, channel: list<string>, group: list<string>, im: list<string>, mpim: list<string>, team: list<string>, user: list<string>>>"
    apps-permissions-users-list: "record<ok: bool>"
    apps-permissions-users-request: "record<ok: bool>"
    apps-uninstall: "record<ok: bool>"
    auth-revoke: "record<ok: bool, revoked: bool>"
    auth-test: "record<bot_id: string, is_enterprise_install: bool, ok: bool, team: string, team_id: string, url: string, user: string, user_id: string>"
    bots-info: "record<bot: record<app_id: string, deleted: bool, icons: record<image_36: string, image_48: string, image_72: string>, id: string, name: string, updated: int, user_id: string>, ok: bool>"
    calls-add: "record<ok: bool>"
    calls-end: "record<ok: bool>"
    calls-info: "record<ok: bool>"
    calls-participants-add: "record<ok: bool>"
    calls-participants-remove: "record<ok: bool>"
    calls-update: "record<ok: bool>"
    chat-delete: "record<channel: string, ok: bool, ts: string>"
    chat-delete-scheduled-message: "record<ok: bool>"
    chat-get-permalink: "record<channel: string, ok: bool, permalink: string>"
    chat-me-message: "record<channel: string, ok: bool, ts: string>"
    chat-post-ephemeral: "record<message_ts: string, ok: bool>"
    chat-post-message: "record<channel: string, message: record<attachments: list<record>, blocks: list<record>, bot_id: list<any>, bot_profile: record<app_id: string, deleted: bool, icons: record, id: string, name: string, team_id: string, updated: int>, client_msg_id: string, comment: record<comment: string, created: int, id: string, is_intro: bool, is_starred: bool, num_stars: int, pinned_info: record, pinned_to: list, reactions: list, timestamp: int, user: string>, display_as_bot: bool, file: record<channels: list, comments_count: int, created: int, date_delete: int, display_as_bot: bool, editable: bool, editor: string, external_id: string, external_type: string, external_url: string, filetype: string, groups: list, has_rich_preview: bool, id: string, image_exif_rotation: int, ims: list, is_external: bool, is_public: bool, is_starred: bool, is_tombstoned: bool, last_editor: string, mimetype: string, mode: string, name: string, non_owner_editable: bool, num_stars: int, original_h: int, original_w: int, permalink: string, permalink_public: string, pinned_info: record, pinned_to: list, pretty_type: string, preview: string, public_url_shared: bool, reactions: list, shares: record, size: int, source_team: string, state: string, thumb_1024: string, thumb_1024_h: int, thumb_1024_w: int, thumb_160: string, thumb_360: string, thumb_360_h: int, thumb_360_w: int, thumb_480: string, thumb_480_h: int, thumb_480_w: int, thumb_64: string, thumb_720: string, thumb_720_h: int, thumb_720_w: int, thumb_80: string, thumb_800: string, thumb_800_h: int, thumb_800_w: int, thumb_960: string, thumb_960_h: int, thumb_960_w: int, thumb_tiny: string, timestamp: int, title: string, updated: int, url_private: string, url_private_download: string, user: string, user_team: string, username: string>, files: list<record>, icons: record<emoji: string, image_64: string>, inviter: string, is_delayed_message: bool, is_intro: bool, is_starred: bool, last_read: string, latest_reply: string, name: string, old_name: string, parent_user_id: string, permalink: string, pinned_to: list<string>, purpose: string, reactions: list<record>, reply_count: int, reply_users: list<string>, reply_users_count: int, source_team: string, subscribed: bool, subtype: string, team: string, text: string, thread_ts: string, topic: string, ts: string, type: string, unread_count: int, upload: bool, user: string, user_profile: record<avatar_hash: string, display_name: string, display_name_normalized: string, first_name: string, image_72: string, is_restricted: bool, is_ultra_restricted: bool, name: string, real_name: string, real_name_normalized: string, team: string>, user_team: string, username: string>, ok: bool, ts: string>"
    chat-schedule-message: "record<channel: string, message: record<bot_id: string, bot_profile: record<app_id: string, deleted: bool, icons: record, id: string, name: string, team_id: string, updated: int>, team: string, text: string, type: string, user: string, username: string>, ok: bool, post_at: int, scheduled_message_id: string>"
    chat-scheduled-messages-list: "record<ok: bool, response_metadata: record<next_cursor: string>, scheduled_messages: table<channel_id: string, date_created: int, id: string, post_at: int, text: string>>"
    chat-unfurl: "record<ok: bool>"
    chat-update: "record<channel: string, message: record<attachments: list<record>, blocks: record, text: string>, ok: bool, text: string, ts: string>"
    conversations-archive: "record<ok: bool>"
    conversations-close: "record<already_closed: bool, no_op: bool, ok: bool>"
    conversations-create: "record<channel: list<any>, ok: bool>"
    conversations-history: "record<channel_actions_count: int, channel_actions_ts: list<any>, has_more: bool, messages: table<attachments: list, blocks: list, bot_id: list, bot_profile: record, client_msg_id: string, comment: record, display_as_bot: bool, file: record, files: list, icons: record, inviter: string, is_delayed_message: bool, is_intro: bool, is_starred: bool, last_read: string, latest_reply: string, name: string, old_name: string, parent_user_id: string, permalink: string, pinned_to: list, purpose: string, reactions: list, reply_count: int, reply_users: list, reply_users_count: int, source_team: string, subscribed: bool, subtype: string, team: string, text: string, thread_ts: string, topic: string, ts: string, type: string, unread_count: int, upload: bool, user: string, user_profile: record, user_team: string, username: string>, ok: bool, pin_count: int>"
    conversations-info: "record<channel: list<any>, ok: bool>"
    conversations-invite: "record<channel: list<any>, ok: bool>"
    conversations-join: "record<channel: list<any>, ok: bool, response_metadata: record<warnings: list<string>>, warning: string>"
    conversations-kick: "record<ok: bool>"
    conversations-leave: "record<not_in_channel: bool, ok: bool>"
    conversations-list: "record<channels: list<list<any>>, ok: bool, response_metadata: record<next_cursor: string>>"
    conversations-mark: "record<ok: bool>"
    conversations-members: "record<members: list<string>, ok: bool, response_metadata: record<next_cursor: string>>"
    conversations-open: "record<already_open: bool, channel: list<any>, no_op: bool, ok: bool>"
    conversations-rename: "record<channel: list<any>, ok: bool>"
    conversations-replies: "record<has_more: bool, messages: list<list<any>>, ok: bool>"
    conversations-set-purpose: "record<channel: list<any>, ok: bool>"
    conversations-set-topic: "record<channel: list<any>, ok: bool>"
    conversations-unarchive: "record<ok: bool>"
    dialog-open: "record<ok: bool>"
    dnd-end-dnd: "record<ok: bool>"
    dnd-end-snooze: "record<dnd_enabled: bool, next_dnd_end_ts: int, next_dnd_start_ts: int, ok: bool, snooze_enabled: bool>"
    dnd-info: "record<dnd_enabled: bool, next_dnd_end_ts: int, next_dnd_start_ts: int, ok: bool, snooze_enabled: bool, snooze_endtime: int, snooze_remaining: int>"
    dnd-set-snooze: "record<ok: bool, snooze_enabled: bool, snooze_endtime: int, snooze_remaining: int>"
    dnd-team-info: "record<ok: bool>"
    emoji-list: "record<ok: bool>"
    files-comments-delete: "record<ok: bool>"
    files-delete: "record<ok: bool>"
    files-info: "record<comments: list<any>, content_html: any, editor: string, file: record<channels: list<string>, comments_count: int, created: int, date_delete: int, display_as_bot: bool, editable: bool, editor: string, external_id: string, external_type: string, external_url: string, filetype: string, groups: list<string>, has_rich_preview: bool, id: string, image_exif_rotation: int, ims: list<string>, is_external: bool, is_public: bool, is_starred: bool, is_tombstoned: bool, last_editor: string, mimetype: string, mode: string, name: string, non_owner_editable: bool, num_stars: int, original_h: int, original_w: int, permalink: string, permalink_public: string, pinned_info: record, pinned_to: list<string>, pretty_type: string, preview: string, public_url_shared: bool, reactions: list<record>, shares: record<private: any, public: any>, size: int, source_team: string, state: string, thumb_1024: string, thumb_1024_h: int, thumb_1024_w: int, thumb_160: string, thumb_360: string, thumb_360_h: int, thumb_360_w: int, thumb_480: string, thumb_480_h: int, thumb_480_w: int, thumb_64: string, thumb_720: string, thumb_720_h: int, thumb_720_w: int, thumb_80: string, thumb_800: string, thumb_800_h: int, thumb_800_w: int, thumb_960: string, thumb_960_h: int, thumb_960_w: int, thumb_tiny: string, timestamp: int, title: string, updated: int, url_private: string, url_private_download: string, user: string, user_team: string, username: string>, ok: bool, paging: record<count: int, page: int, pages: int, per_page: int, spill: int, total: int>, response_metadata: list<any>>"
    files-list: "record<files: table<channels: list, comments_count: int, created: int, date_delete: int, display_as_bot: bool, editable: bool, editor: string, external_id: string, external_type: string, external_url: string, filetype: string, groups: list, has_rich_preview: bool, id: string, image_exif_rotation: int, ims: list, is_external: bool, is_public: bool, is_starred: bool, is_tombstoned: bool, last_editor: string, mimetype: string, mode: string, name: string, non_owner_editable: bool, num_stars: int, original_h: int, original_w: int, permalink: string, permalink_public: string, pinned_info: record, pinned_to: list, pretty_type: string, preview: string, public_url_shared: bool, reactions: list, shares: record, size: int, source_team: string, state: string, thumb_1024: string, thumb_1024_h: int, thumb_1024_w: int, thumb_160: string, thumb_360: string, thumb_360_h: int, thumb_360_w: int, thumb_480: string, thumb_480_h: int, thumb_480_w: int, thumb_64: string, thumb_720: string, thumb_720_h: int, thumb_720_w: int, thumb_80: string, thumb_800: string, thumb_800_h: int, thumb_800_w: int, thumb_960: string, thumb_960_h: int, thumb_960_w: int, thumb_tiny: string, timestamp: int, title: string, updated: int, url_private: string, url_private_download: string, user: string, user_team: string, username: string>, ok: bool, paging: record<count: int, page: int, pages: int, per_page: int, spill: int, total: int>>"
    files-remote-add: "record<ok: bool>"
    files-remote-info: "record<ok: bool>"
    files-remote-list: "record<ok: bool>"
    files-remote-remove: "record<ok: bool>"
    files-remote-share: "record<ok: bool>"
    files-remote-update: "record<ok: bool>"
    files-revoke-public-url: "record<file: record<channels: list<string>, comments_count: int, created: int, date_delete: int, display_as_bot: bool, editable: bool, editor: string, external_id: string, external_type: string, external_url: string, filetype: string, groups: list<string>, has_rich_preview: bool, id: string, image_exif_rotation: int, ims: list<string>, is_external: bool, is_public: bool, is_starred: bool, is_tombstoned: bool, last_editor: string, mimetype: string, mode: string, name: string, non_owner_editable: bool, num_stars: int, original_h: int, original_w: int, permalink: string, permalink_public: string, pinned_info: record, pinned_to: list<string>, pretty_type: string, preview: string, public_url_shared: bool, reactions: list<record>, shares: record<private: any, public: any>, size: int, source_team: string, state: string, thumb_1024: string, thumb_1024_h: int, thumb_1024_w: int, thumb_160: string, thumb_360: string, thumb_360_h: int, thumb_360_w: int, thumb_480: string, thumb_480_h: int, thumb_480_w: int, thumb_64: string, thumb_720: string, thumb_720_h: int, thumb_720_w: int, thumb_80: string, thumb_800: string, thumb_800_h: int, thumb_800_w: int, thumb_960: string, thumb_960_h: int, thumb_960_w: int, thumb_tiny: string, timestamp: int, title: string, updated: int, url_private: string, url_private_download: string, user: string, user_team: string, username: string>, ok: bool>"
    files-shared-public-url: "record<file: record<channels: list<string>, comments_count: int, created: int, date_delete: int, display_as_bot: bool, editable: bool, editor: string, external_id: string, external_type: string, external_url: string, filetype: string, groups: list<string>, has_rich_preview: bool, id: string, image_exif_rotation: int, ims: list<string>, is_external: bool, is_public: bool, is_starred: bool, is_tombstoned: bool, last_editor: string, mimetype: string, mode: string, name: string, non_owner_editable: bool, num_stars: int, original_h: int, original_w: int, permalink: string, permalink_public: string, pinned_info: record, pinned_to: list<string>, pretty_type: string, preview: string, public_url_shared: bool, reactions: list<record>, shares: record<private: any, public: any>, size: int, source_team: string, state: string, thumb_1024: string, thumb_1024_h: int, thumb_1024_w: int, thumb_160: string, thumb_360: string, thumb_360_h: int, thumb_360_w: int, thumb_480: string, thumb_480_h: int, thumb_480_w: int, thumb_64: string, thumb_720: string, thumb_720_h: int, thumb_720_w: int, thumb_80: string, thumb_800: string, thumb_800_h: int, thumb_800_w: int, thumb_960: string, thumb_960_h: int, thumb_960_w: int, thumb_tiny: string, timestamp: int, title: string, updated: int, url_private: string, url_private_download: string, user: string, user_team: string, username: string>, ok: bool>"
    files-upload: "record<file: record<channels: list<string>, comments_count: int, created: int, date_delete: int, display_as_bot: bool, editable: bool, editor: string, external_id: string, external_type: string, external_url: string, filetype: string, groups: list<string>, has_rich_preview: bool, id: string, image_exif_rotation: int, ims: list<string>, is_external: bool, is_public: bool, is_starred: bool, is_tombstoned: bool, last_editor: string, mimetype: string, mode: string, name: string, non_owner_editable: bool, num_stars: int, original_h: int, original_w: int, permalink: string, permalink_public: string, pinned_info: record, pinned_to: list<string>, pretty_type: string, preview: string, public_url_shared: bool, reactions: list<record>, shares: record<private: any, public: any>, size: int, source_team: string, state: string, thumb_1024: string, thumb_1024_h: int, thumb_1024_w: int, thumb_160: string, thumb_360: string, thumb_360_h: int, thumb_360_w: int, thumb_480: string, thumb_480_h: int, thumb_480_w: int, thumb_64: string, thumb_720: string, thumb_720_h: int, thumb_720_w: int, thumb_80: string, thumb_800: string, thumb_800_h: int, thumb_800_w: int, thumb_960: string, thumb_960_h: int, thumb_960_w: int, thumb_tiny: string, timestamp: int, title: string, updated: int, url_private: string, url_private_download: string, user: string, user_team: string, username: string>, ok: bool>"
    migration-exchange: "record<enterprise_id: string, invalid_user_ids: list<string>, ok: bool, team_id: string, user_id_map: record>"
    oauth-access: "record<ok: bool>"
    oauth-token: "record<ok: bool>"
    oauth-v2-access: "record<ok: bool>"
    pins-add: "record<ok: bool>"
    pins-list: "list<any>"
    pins-remove: "record<ok: bool>"
    reactions-add: "record<ok: bool>"
    reactions-get: "record"
    reactions-list: "record<items: list<list<any>>, ok: bool, paging: record<count: int, page: int, pages: int, per_page: int, spill: int, total: int>, response_metadata: list<any>>"
    reactions-remove: "record<ok: bool>"
    reminders-add: "record<ok: bool, reminder: record<complete_ts: int, creator: string, id: string, recurring: bool, text: string, time: int, user: string>>"
    reminders-complete: "record<ok: bool>"
    reminders-delete: "record<ok: bool>"
    reminders-info: "record<ok: bool, reminder: record<complete_ts: int, creator: string, id: string, recurring: bool, text: string, time: int, user: string>>"
    reminders-list: "record<ok: bool, reminders: table<complete_ts: int, creator: string, id: string, recurring: bool, text: string, time: int, user: string>>"
    rtm-connect: "record<ok: bool, self: record<id: string, name: string>, team: record<domain: string, id: string, name: string>, url: string>"
    search-messages: "record<ok: bool>"
    stars-add: "record<ok: bool>"
    stars-list: "record<items: list<list<any>>, ok: bool, paging: record<count: int, page: int, pages: int, per_page: int, spill: int, total: int>>"
    stars-remove: "record<ok: bool>"
    team-access-logs: "record<logins: table<count: int, country: string, date_first: int, date_last: int, ip: string, isp: string, region: string, user_agent: string, user_id: string, username: string>, ok: bool, paging: record<count: int, page: int, pages: int, per_page: int, spill: int, total: int>>"
    team-billable-info: "record<ok: bool>"
    team-info: "record<ok: bool, team: record<archived: bool, avatar_base_url: string, created: int, date_create: int, deleted: bool, description: string, discoverable: list<any>, domain: string, email_domain: string, enterprise_id: string, enterprise_name: string, external_org_migrations: record<current: list, date_updated: int>, has_compliance_export: bool, icon: record<image_102: string, image_132: string, image_230: string, image_34: string, image_44: string, image_68: string, image_88: string, image_default: bool>, id: string, is_assigned: bool, is_enterprise: int, is_over_storage_limit: bool, limit_ts: int, locale: string, messages_count: int, msg_edit_window_mins: int, name: string, over_integrations_limit: bool, over_storage_limit: bool, pay_prod_cur: string, plan: string, primary_owner: record<email: string, id: string>, sso_provider: record<label: string, name: string, type: string>>>"
    team-integration-logs: "record<logs: table<admin_app_id: string, app_id: string, app_type: string, change_type: string, channel: string, date: string, scope: string, service_id: string, service_type: string, user_id: string, user_name: string>, ok: bool, paging: record<count: int, page: int, pages: int, per_page: int, spill: int, total: int>>"
    team-profile-get: "record<ok: bool, profile: record<fields: list<record>>>"
    usergroups-create: "record<ok: bool, usergroup: record<auto_provision: bool, auto_type: list<any>, channel_count: int, created_by: string, date_create: int, date_delete: int, date_update: int, deleted_by: list<any>, description: string, enterprise_subteam_id: string, handle: string, id: string, is_external: bool, is_subteam: bool, is_usergroup: bool, name: string, prefs: record<channels: list, groups: list>, team_id: string, updated_by: string, user_count: int, users: list<string>>>"
    usergroups-disable: "record<ok: bool, usergroup: record<auto_provision: bool, auto_type: list<any>, channel_count: int, created_by: string, date_create: int, date_delete: int, date_update: int, deleted_by: list<any>, description: string, enterprise_subteam_id: string, handle: string, id: string, is_external: bool, is_subteam: bool, is_usergroup: bool, name: string, prefs: record<channels: list, groups: list>, team_id: string, updated_by: string, user_count: int, users: list<string>>>"
    usergroups-enable: "record<ok: bool, usergroup: record<auto_provision: bool, auto_type: list<any>, channel_count: int, created_by: string, date_create: int, date_delete: int, date_update: int, deleted_by: list<any>, description: string, enterprise_subteam_id: string, handle: string, id: string, is_external: bool, is_subteam: bool, is_usergroup: bool, name: string, prefs: record<channels: list, groups: list>, team_id: string, updated_by: string, user_count: int, users: list<string>>>"
    usergroups-list: "record<ok: bool, usergroups: table<auto_provision: bool, auto_type: list, channel_count: int, created_by: string, date_create: int, date_delete: int, date_update: int, deleted_by: list, description: string, enterprise_subteam_id: string, handle: string, id: string, is_external: bool, is_subteam: bool, is_usergroup: bool, name: string, prefs: record, team_id: string, updated_by: string, user_count: int, users: list>>"
    usergroups-update: "record<ok: bool, usergroup: record<auto_provision: bool, auto_type: list<any>, channel_count: int, created_by: string, date_create: int, date_delete: int, date_update: int, deleted_by: list<any>, description: string, enterprise_subteam_id: string, handle: string, id: string, is_external: bool, is_subteam: bool, is_usergroup: bool, name: string, prefs: record<channels: list, groups: list>, team_id: string, updated_by: string, user_count: int, users: list<string>>>"
    usergroups-users-list: "record<ok: bool, users: list<string>>"
    usergroups-users-update: "record<ok: bool, usergroup: record<auto_provision: bool, auto_type: list<any>, channel_count: int, created_by: string, date_create: int, date_delete: int, date_update: int, deleted_by: list<any>, description: string, enterprise_subteam_id: string, handle: string, id: string, is_external: bool, is_subteam: bool, is_usergroup: bool, name: string, prefs: record<channels: list, groups: list>, team_id: string, updated_by: string, user_count: int, users: list<string>>>"
    users-conversations: "record<channels: list<list<any>>, ok: bool, response_metadata: record<next_cursor: string>>"
    users-delete-photo: "record<ok: bool>"
    users-get-presence: "record<auto_away: bool, connection_count: int, last_activity: int, manual_away: bool, ok: bool, online: bool, presence: string>"
    users-identity: "list<any>"
    users-info: "record<ok: bool, user: list<any>>"
    users-list: "record<cache_ts: int, members: list<list<any>>, ok: bool, response_metadata: list<any>>"
    users-lookup-by-email: "record<ok: bool, user: list<any>>"
    users-profile-get: "record<ok: bool, profile: record<always_active: bool, api_app_id: string, avatar_hash: string, bot_id: string, display_name: string, display_name_normalized: string, email: string, fields: list<record>, first_name: string, guest_expiration_ts: int, guest_invited_by: string, image_1024: string, image_192: string, image_24: string, image_32: string, image_48: string, image_512: string, image_72: string, image_original: string, is_app_user: bool, is_custom_image: bool, is_restricted: bool, is_ultra_restricted: bool, last_avatar_image_hash: string, last_name: string, memberships_count: int, name: string, phone: string, pronouns: string, real_name: string, real_name_normalized: string, skype: string, status_default_emoji: string, status_default_text: string, status_default_text_canonical: string, status_emoji: string, status_expiration: int, status_text: string, status_text_canonical: string, team: string, title: string, updated: int, user_id: string, username: string>>"
    users-profile-set: "record<email_pending: string, ok: bool, profile: record<always_active: bool, api_app_id: string, avatar_hash: string, bot_id: string, display_name: string, display_name_normalized: string, email: string, fields: list<record>, first_name: string, guest_expiration_ts: int, guest_invited_by: string, image_1024: string, image_192: string, image_24: string, image_32: string, image_48: string, image_512: string, image_72: string, image_original: string, is_app_user: bool, is_custom_image: bool, is_restricted: bool, is_ultra_restricted: bool, last_avatar_image_hash: string, last_name: string, memberships_count: int, name: string, phone: string, pronouns: string, real_name: string, real_name_normalized: string, skype: string, status_default_emoji: string, status_default_text: string, status_default_text_canonical: string, status_emoji: string, status_expiration: int, status_text: string, status_text_canonical: string, team: string, title: string, updated: int, user_id: string, username: string>, username: string>"
    users-set-active: "record<ok: bool>"
    users-set-photo: "record<ok: bool, profile: record<avatar_hash: string, image_1024: string, image_192: string, image_24: string, image_32: string, image_48: string, image_512: string, image_72: string, image_original: string>>"
    users-set-presence: "record<ok: bool>"
    views-open: "record<ok: bool>"
    views-publish: "record<ok: bool>"
    views-push: "record<ok: bool>"
    views-update: "record<ok: bool>"
    workflows-step-completed: "record<ok: bool>"
    workflows-step-failed: "record<ok: bool>"
    workflows-update-step: "record<ok: bool>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["admin-apps-approve" "admin-apps-approved-list" "admin-apps-requests-list" "admin-apps-restrict" "admin-apps-restricted-list" "admin-conversations-archive" "admin-conversations-convert-to-private" "admin-conversations-create" "admin-conversations-delete" "admin-conversations-disconnect-shared" "admin-conversations-ekm-list-original-connected-channel-info" "admin-conversations-get-conversation-prefs" "admin-conversations-get-teams" "admin-conversations-invite" "admin-conversations-rename" "admin-conversations-restrict-access-add-group" "admin-conversations-restrict-access-list-groups" "admin-conversations-restrict-access-remove-group" "admin-conversations-search" "admin-conversations-set-conversation-prefs" "admin-conversations-set-teams" "admin-conversations-unarchive" "admin-emoji-add" "admin-emoji-add-alias" "admin-emoji-list" "admin-emoji-remove" "admin-emoji-rename" "admin-invite-requests-approve" "admin-invite-requests-approved-list" "admin-invite-requests-denied-list" "admin-invite-requests-deny" "admin-invite-requests-list" "admin-teams-admins-list" "admin-teams-create" "admin-teams-list" "admin-teams-owners-list" "admin-teams-settings-info" "admin-teams-settings-set-default-channels" "admin-teams-settings-set-description" "admin-teams-settings-set-discoverability" "admin-teams-settings-set-icon" "admin-teams-settings-set-name" "admin-usergroups-add-channels" "admin-usergroups-add-teams" "admin-usergroups-list-channels" "admin-usergroups-remove-channels" "admin-users-assign" "admin-users-invite" "admin-users-list" "admin-users-remove" "admin-users-session-invalidate" "admin-users-session-reset" "admin-users-set-admin" "admin-users-set-expiration" "admin-users-set-owner" "admin-users-set-regular" "api-test" "apps-event-authorizations-list" "apps-permissions-info" "apps-permissions-request" "apps-permissions-resources-list" "apps-permissions-scopes-list" "apps-permissions-users-list" "apps-permissions-users-request" "apps-uninstall" "auth-revoke" "auth-test" "bots-info" "calls-add" "calls-end" "calls-info" "calls-participants-add" "calls-participants-remove" "calls-update" "chat-delete" "chat-delete-scheduled-message" "chat-get-permalink" "chat-me-message" "chat-post-ephemeral" "chat-post-message" "chat-schedule-message" "chat-scheduled-messages-list" "chat-unfurl" "chat-update" "conversations-archive" "conversations-close" "conversations-create" "conversations-history" "conversations-info" "conversations-invite" "conversations-join" "conversations-kick" "conversations-leave" "conversations-list" "conversations-mark" "conversations-members" "conversations-open" "conversations-rename" "conversations-replies" "conversations-set-purpose" "conversations-set-topic" "conversations-unarchive" "dialog-open" "dnd-end-dnd" "dnd-end-snooze" "dnd-info" "dnd-set-snooze" "dnd-team-info" "emoji-list" "files-comments-delete" "files-delete" "files-info" "files-list" "files-remote-add" "files-remote-info" "files-remote-list" "files-remote-remove" "files-remote-share" "files-remote-update" "files-revoke-public-url" "files-shared-public-url" "files-upload" "migration-exchange" "oauth-access" "oauth-token" "oauth-v2-access" "pins-add" "pins-list" "pins-remove" "reactions-add" "reactions-get" "reactions-list" "reactions-remove" "reminders-add" "reminders-complete" "reminders-delete" "reminders-info" "reminders-list" "rtm-connect" "search-messages" "stars-add" "stars-list" "stars-remove" "team-access-logs" "team-billable-info" "team-info" "team-integration-logs" "team-profile-get" "usergroups-create" "usergroups-disable" "usergroups-enable" "usergroups-list" "usergroups-update" "usergroups-users-list" "usergroups-users-update" "users-conversations" "users-delete-photo" "users-get-presence" "users-identity" "users-info" "users-list" "users-lookup-by-email" "users-profile-get" "users-profile-set" "users-set-active" "users-set-photo" "users-set-presence" "views-open" "views-publish" "views-push" "views-update" "workflows-step-completed" "workflows-step-failed" "workflows-update-step" "commands"] | sort) } | get name | first)
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

# Approve an app for installation on a workspace.
#
# POST /admin.apps.approve
# Docs: https://api.slack.com/methods/admin.apps.approve — API method documentation
# Returns: record<ok: bool>
# operationId: admin_apps_approve
export def "admin-apps-approve" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.apps:write` (required) (spec name: token)
  --app-id: string # The id of the app to approve.
  --request-id: string # The id of the request to approve.
  --team-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.apps.approve"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: app_id, var: app_id}, {name: request_id, var: request_id}, {name: team_id, var: team_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, app_id: $app_id, request_id: $request_id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List approved apps for an org or workspace.
#
# GET /admin.apps.approved.list
# Docs: https://api.slack.com/methods/admin.apps.approved.list — API method documentation
# Returns: record<ok: bool>
# operationId: admin_apps_approved_list
export def "admin-apps-approved-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `admin.apps:read` (required) (spec name: token)
  --limit: int # The maximum number of items to return. Must be between 1 - 1000 both inclusive.
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page
  --team-id: string
  --enterprise-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin.apps.approved.list"
    query: [{name: token, var: qp_token, required: true}, {name: limit, var: limit}, {name: cursor, var: cursor}, {name: team_id, var: team_id}, {name: enterprise_id, var: enterprise_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, limit: $limit, cursor: $cursor, team_id: $team_id, enterprise_id: $enterprise_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List app requests for a team/workspace.
#
# GET /admin.apps.requests.list
# Docs: https://api.slack.com/methods/admin.apps.requests.list — API method documentation
# Returns: record<ok: bool>
# operationId: admin_apps_requests_list
export def "admin-apps-requests-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `admin.apps:read` (required) (spec name: token)
  --limit: int # The maximum number of items to return. Must be between 1 - 1000 both inclusive.
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page
  --team-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin.apps.requests.list"
    query: [{name: token, var: qp_token, required: true}, {name: limit, var: limit}, {name: cursor, var: cursor}, {name: team_id, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, limit: $limit, cursor: $cursor, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restrict an app for installation on a workspace.
#
# POST /admin.apps.restrict
# Docs: https://api.slack.com/methods/admin.apps.restrict — API method documentation
# Returns: record<ok: bool>
# operationId: admin_apps_restrict
export def "admin-apps-restrict" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.apps:write` (required) (spec name: token)
  --app-id: string # The id of the app to restrict.
  --request-id: string # The id of the request to restrict.
  --team-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.apps.restrict"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: app_id, var: app_id}, {name: request_id, var: request_id}, {name: team_id, var: team_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, app_id: $app_id, request_id: $request_id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List restricted apps for an org or workspace.
#
# GET /admin.apps.restricted.list
# Docs: https://api.slack.com/methods/admin.apps.restricted.list — API method documentation
# Returns: record<ok: bool>
# operationId: admin_apps_restricted_list
export def "admin-apps-restricted-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `admin.apps:read` (required) (spec name: token)
  --limit: int # The maximum number of items to return. Must be between 1 - 1000 both inclusive.
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page
  --team-id: string
  --enterprise-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin.apps.restricted.list"
    query: [{name: token, var: qp_token, required: true}, {name: limit, var: limit}, {name: cursor, var: cursor}, {name: team_id, var: team_id}, {name: enterprise_id, var: enterprise_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, limit: $limit, cursor: $cursor, team_id: $team_id, enterprise_id: $enterprise_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Archive a public or private channel.
#
# POST /admin.conversations.archive
# Docs: https://api.slack.com/methods/admin.conversations.archive — API method documentation
# Returns: record<ok: bool>
# operationId: admin_conversations_archive
export def "admin-conversations-archive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:write` (required) (spec name: token)
  channel_id: string # The channel to archive.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.conversations.archive"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel_id, var: channel_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Convert a public channel to a private channel.
#
# POST /admin.conversations.convertToPrivate
# Docs: https://api.slack.com/methods/admin.conversations.convertToPrivate — API method documentation
# Returns: record<ok: bool>
# operationId: admin_conversations_convertToPrivate
export def "admin-conversations-convert-to-private" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:write` (required) (spec name: token)
  channel_id: string # The channel to convert to private.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.conversations.convertToPrivate"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel_id, var: channel_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a public or private channel-based conversation.
#
# POST /admin.conversations.create
# Docs: https://api.slack.com/methods/admin.conversations.create — API method documentation
# Returns: record<channel_id: string, ok: bool>
# operationId: admin_conversations_create
export def "admin-conversations-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:write` (required) (spec name: token)
  --description: string # Description of the public or private channel to create.
  --is-private: oneof<nothing, bool> # When `true`, creates a private channel instead of a public channel
  name: string # Name of the public or private channel to create.
  --org-wide: oneof<nothing, bool> # When `true`, the channel will be available org-wide. Note: if the channel is not `org_wide=true`, you must specify a `team_id` for this channel
  --team-id: string # The workspace to create the channel in. Note: this argument is required unless you set `org_wide=true`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.conversations.create"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: description, var: description}, {name: is_private, var: is_private, required: true}, {name: name, var: name}, {name: org_wide, var: org_wide}, {name: team_id, var: team_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, description: $description, is_private: $is_private, name: $name, org_wide: $org_wide, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a public or private channel.
#
# POST /admin.conversations.delete
# Docs: https://api.slack.com/methods/admin.conversations.delete — API method documentation
# Returns: record<ok: bool>
# operationId: admin_conversations_delete
export def "admin-conversations-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:write` (required) (spec name: token)
  channel_id: string # The channel to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.conversations.delete"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel_id, var: channel_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disconnect a connected channel from one or more workspaces.
#
# POST /admin.conversations.disconnectShared
# Docs: https://api.slack.com/methods/admin.conversations.disconnectShared — API method documentation
# Returns: record<ok: bool>
# operationId: admin_conversations_disconnectShared
export def "admin-conversations-disconnect-shared" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:write` (required) (spec name: token)
  channel_id: string # The channel to be disconnected from some workspaces.
  --leaving-team-ids: string # The team to be removed from the channel. Currently only a single team id can be specified.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.conversations.disconnectShared"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel_id, var: channel_id}, {name: leaving_team_ids, var: leaving_team_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel_id: $channel_id, leaving_team_ids: $leaving_team_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all disconnected channels—i.e., channels that were once connected to other workspaces and then disconnected—and the corresponding original channel IDs for key revocation with EKM.
#
# GET /admin.conversations.ekm.listOriginalConnectedChannelInfo
# Docs: https://api.slack.com/methods/admin.conversations.ekm.listOriginalConnectedChannelInfo — API method documentation
# Returns: record<ok: bool>
# operationId: admin_conversations_ekm_listOriginalConnectedChannelInfo
export def "admin-conversations-ekm-list-original-connected-channel-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `admin.conversations:read` (required) (spec name: token)
  --channel-ids: string # A comma-separated list of channels to filter to.
  --team-ids: string # A comma-separated list of the workspaces to which the channels you would like returned belong.
  --limit: int # The maximum number of items to return. Must be between 1 - 1000 both inclusive.
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin.conversations.ekm.listOriginalConnectedChannelInfo"
    query: [{name: token, var: qp_token, required: true}, {name: channel_ids, var: channel_ids}, {name: team_ids, var: team_ids}, {name: limit, var: limit}, {name: cursor, var: cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, channel_ids: $channel_ids, team_ids: $team_ids, limit: $limit, cursor: $cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get conversation preferences for a public or private channel.
#
# GET /admin.conversations.getConversationPrefs
# Docs: https://api.slack.com/methods/admin.conversations.getConversationPrefs — API method documentation
# Returns: record<ok: bool, prefs: record<can_thread: record<type: list, user: list>, who_can_post: record<type: list, user: list>>>
# operationId: admin_conversations_getConversationPrefs
export def "admin-conversations-get-conversation-prefs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --channel-id: string # The channel to get preferences for. (required)
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:read` (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin.conversations.getConversationPrefs"
    query: [{name: channel_id, var: channel_id, required: true}]
    header: [{name: token, var: hdr_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the workspaces a given public or private channel is connected to within this Enterprise org.
#
# GET /admin.conversations.getTeams
# Docs: https://api.slack.com/methods/admin.conversations.getTeams — API method documentation
# Returns: record<ok: bool, response_metadata: record<next_cursor: string>, team_ids: list<string>>
# operationId: admin_conversations_getTeams
export def "admin-conversations-get-teams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --channel-id: string # The channel to determine connected workspaces within the organization for. (required)
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page
  --limit: int # The maximum number of items to return. Must be between 1 - 1000 both inclusive.
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:read` (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin.conversations.getTeams"
    query: [{name: channel_id, var: channel_id, required: true}, {name: cursor, var: cursor}, {name: limit, var: limit}]
    header: [{name: token, var: hdr_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, cursor: $cursor, limit: $limit, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invite a user to a public or private channel.
#
# POST /admin.conversations.invite
# Docs: https://api.slack.com/methods/admin.conversations.invite — API method documentation
# Returns: record<ok: bool>
# operationId: admin_conversations_invite
export def "admin-conversations-invite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:write` (required) (spec name: token)
  channel_id: string # The channel that the users will be invited to.
  user_ids: string # The users to invite.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.conversations.invite"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel_id, var: channel_id}, {name: user_ids, var: user_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel_id: $channel_id, user_ids: $user_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rename a public or private channel.
#
# POST /admin.conversations.rename
# Docs: https://api.slack.com/methods/admin.conversations.rename — API method documentation
# Returns: record<ok: bool>
# operationId: admin_conversations_rename
export def "admin-conversations-rename" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:write` (required) (spec name: token)
  channel_id: string # The channel to rename.
  name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.conversations.rename"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel_id, var: channel_id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel_id: $channel_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add an allowlist of IDP groups for accessing a channel
#
# POST /admin.conversations.restrictAccess.addGroup
# Docs: https://api.slack.com/methods/admin.conversations.restrictAccess.addGroup — API method documentation
# Returns: record<ok: bool>
# operationId: admin_conversations_restrictAccess_addGroup
export def "admin-conversations-restrict-access-add-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  channel_id: string # The channel to link this group to.
  group_id: string # The [IDP Group](https://slack.com/help/articles/115001435788-Connect-identity-provider-groups-to-your-Enterprise-Grid-org) ID to be an allowlist for the private channel.
  --team-id: string # The workspace where the channel exists. This argument is required for channels only tied to one workspace, and optional for channels that are shared across an organization.
  --body-token: string # Authentication token. Requires scope: `admin.conversations:write` (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.conversations.restrictAccess.addGroup"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel_id, var: channel_id}, {name: group_id, var: group_id}, {name: team_id, var: team_id}, {name: token, var: body_token, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, group_id: $group_id, team_id: $team_id, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all IDP Groups linked to a channel
#
# GET /admin.conversations.restrictAccess.listGroups
# Docs: https://api.slack.com/methods/admin.conversations.restrictAccess.listGroups — API method documentation
# Returns: record<ok: bool>
# operationId: admin_conversations_restrictAccess_listGroups
export def "admin-conversations-restrict-access-list-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `admin.conversations:read` (required) (spec name: token)
  --channel-id: string # required
  --team-id: string # The workspace where the channel exists. This argument is required for channels only tied to one workspace, and optional for channels that are shared across an organization.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin.conversations.restrictAccess.listGroups"
    query: [{name: token, var: qp_token, required: true}, {name: channel_id, var: channel_id, required: true}, {name: team_id, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, channel_id: $channel_id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a linked IDP group linked from a private channel
#
# POST /admin.conversations.restrictAccess.removeGroup
# Docs: https://api.slack.com/methods/admin.conversations.restrictAccess.removeGroup — API method documentation
# Returns: record<ok: bool>
# operationId: admin_conversations_restrictAccess_removeGroup
export def "admin-conversations-restrict-access-remove-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  channel_id: string # The channel to remove the linked group from.
  group_id: string # The [IDP Group](https://slack.com/help/articles/115001435788-Connect-identity-provider-groups-to-your-Enterprise-Grid-org) ID to remove from the private channel.
  team_id: string # The workspace where the channel exists. This argument is required for channels only tied to one workspace, and optional for channels that are shared across an organization.
  --body-token: string # Authentication token. Requires scope: `admin.conversations:write` (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.conversations.restrictAccess.removeGroup"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel_id, var: channel_id}, {name: group_id, var: group_id}, {name: team_id, var: team_id}, {name: token, var: body_token, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, group_id: $group_id, team_id: $team_id, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for public or private channels in an Enterprise organization.
#
# GET /admin.conversations.search
# Docs: https://api.slack.com/methods/admin.conversations.search — API method documentation
# Returns: record<channels: table<accepted_user: string, created: int, creator: string, id: string, is_archived: bool, is_channel: bool, is_frozen: bool, is_general: bool, is_member: bool, is_moved: int, is_mpim: bool, is_non_threadable: bool, is_org_shared: bool, is_pending_ext_shared: bool, is_private: bool, is_read_only: bool, is_shared: bool, is_thread_only: bool, last_read: string, latest: list, members: list, name: string, name_normalized: string, num_members: int, pending_shared: list, previous_names: list, priority: float, purpose: record, topic: record, unlinked: int, unread_count: int, unread_count_display: int>, next_cursor: string>
# operationId: admin_conversations_search
export def "admin-conversations-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-ids: string # Comma separated string of team IDs, signifying the workspaces to search through.
  --query: string # Name of the the channel to query by.
  --limit: int # Maximum number of items to be returned. Must be between 1 - 20 both inclusive. Default is 10.
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page.
  --search-channel-types: string # The type of channel to include or exclude in the search. For example `private` will search private channels, while `private_exclude` will exclude them. For a full list of types, check the [Types section](#types).
  --sort: string # Possible values are `relevant` (search ranking based on what we think is closest), `name` (alphabetical), `member_count` (number of users in the channel), and `created` (date channel was created). You can optionally pair this with the `sort_dir` arg to change how it is sorted
  --sort-dir: string # Sort direction. Possible values are `asc` for ascending order like (1, 2, 3) or (a, b, c), and `desc` for descending order like (3, 2, 1) or (c, b, a)
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:read` (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin.conversations.search"
    query: [{name: team_ids, var: team_ids}, {name: query, var: query}, {name: limit, var: limit}, {name: cursor, var: cursor}, {name: search_channel_types, var: search_channel_types}, {name: sort, var: sort}, {name: sort_dir, var: sort_dir}]
    header: [{name: token, var: hdr_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_ids: $team_ids, query: $query, limit: $limit, cursor: $cursor, search_channel_types: $search_channel_types, sort: $sort, sort_dir: $sort_dir, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the posting permissions for a public or private channel.
#
# POST /admin.conversations.setConversationPrefs
# Docs: https://api.slack.com/methods/admin.conversations.setConversationPrefs — API method documentation
# Returns: record<ok: bool>
# operationId: admin_conversations_setConversationPrefs
export def "admin-conversations-set-conversation-prefs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:write` (required) (spec name: token)
  channel_id: string # The channel to set the prefs for
  prefs: string # The prefs for this channel in a stringified JSON format.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.conversations.setConversationPrefs"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel_id, var: channel_id}, {name: prefs, var: prefs}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel_id: $channel_id, prefs: $prefs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the workspaces in an Enterprise grid org that connect to a public or private channel.
#
# POST /admin.conversations.setTeams
# Docs: https://api.slack.com/methods/admin.conversations.setTeams — API method documentation
# Returns: record<ok: bool>
# operationId: admin_conversations_setTeams
export def "admin-conversations-set-teams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:write` (required) (spec name: token)
  channel_id: string # The encoded `channel_id` to add or remove to workspaces.
  --org-channel: oneof<nothing, bool> # True if channel has to be converted to an org channel
  --target-team-ids: string # A comma-separated list of workspaces to which the channel should be shared. Not required if the channel is being shared org-wide.
  --team-id: string # The workspace to which the channel belongs. Omit this argument if the channel is a cross-workspace shared channel.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.conversations.setTeams"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel_id, var: channel_id}, {name: org_channel, var: org_channel}, {name: target_team_ids, var: target_team_ids}, {name: team_id, var: team_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel_id: $channel_id, org_channel: $org_channel, target_team_ids: $target_team_ids, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unarchive a public or private channel.
#
# POST /admin.conversations.unarchive
# Docs: https://api.slack.com/methods/admin.conversations.unarchive — API method documentation
# Returns: record<ok: bool>
# operationId: admin_conversations_unarchive
export def "admin-conversations-unarchive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:write` (required) (spec name: token)
  channel_id: string # The channel to unarchive.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.conversations.unarchive"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel_id, var: channel_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add an emoji.
#
# POST /admin.emoji.add
# Docs: https://api.slack.com/methods/admin.emoji.add — API method documentation
# Returns: record<ok: bool>
# operationId: admin_emoji_add
export def "admin-emoji-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the emoji to be removed. Colons (`:myemoji:`) around the value are not required, although they may be included.
  --body-token: string # Authentication token. Requires scope: `admin.teams:write` (spec name: token)
  url: string # The URL of a file to use as an image for the emoji. Square images under 128KB and with transparent backgrounds work best.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.emoji.add"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: name, var: name}, {name: token, var: body_token, required: true}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, body_token: $body_token, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add an emoji alias.
#
# POST /admin.emoji.addAlias
# Docs: https://api.slack.com/methods/admin.emoji.addAlias — API method documentation
# Returns: record<ok: bool>
# operationId: admin_emoji_addAlias
export def "admin-emoji-add-alias" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  alias_for: string # The alias of the emoji.
  name: string # The name of the emoji to be aliased. Colons (`:myemoji:`) around the value are not required, although they may be included.
  --body-token: string # Authentication token. Requires scope: `admin.teams:write` (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.emoji.addAlias"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: alias_for, var: alias_for}, {name: name, var: name}, {name: token, var: body_token, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alias_for: $alias_for, name: $name, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List emoji for an Enterprise Grid organization.
#
# GET /admin.emoji.list
# Docs: https://api.slack.com/methods/admin.emoji.list — API method documentation
# Returns: record<ok: bool>
# operationId: admin_emoji_list
export def "admin-emoji-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `admin.teams:read` (required) (spec name: token)
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page
  --limit: int # The maximum number of items to return. Must be between 1 - 1000 both inclusive.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin.emoji.list"
    query: [{name: token, var: qp_token, required: true}, {name: cursor, var: cursor}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, cursor: $cursor, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an emoji across an Enterprise Grid organization
#
# POST /admin.emoji.remove
# Docs: https://api.slack.com/methods/admin.emoji.remove — API method documentation
# Returns: record<ok: bool>
# operationId: admin_emoji_remove
export def "admin-emoji-remove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the emoji to be removed. Colons (`:myemoji:`) around the value are not required, although they may be included.
  --body-token: string # Authentication token. Requires scope: `admin.teams:write` (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.emoji.remove"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: name, var: name}, {name: token, var: body_token, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rename an emoji.
#
# POST /admin.emoji.rename
# Docs: https://api.slack.com/methods/admin.emoji.rename — API method documentation
# Returns: record<ok: bool>
# operationId: admin_emoji_rename
export def "admin-emoji-rename" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the emoji to be renamed. Colons (`:myemoji:`) around the value are not required, although they may be included.
  new_name: string # The new name of the emoji.
  --body-token: string # Authentication token. Requires scope: `admin.teams:write` (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.emoji.rename"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: name, var: name}, {name: new_name, var: new_name}, {name: token, var: body_token, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, new_name: $new_name, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Approve a workspace invite request.
#
# POST /admin.inviteRequests.approve
# Docs: https://api.slack.com/methods/admin.inviteRequests.approve — API method documentation
# Returns: record<ok: bool>
# operationId: admin_inviteRequests_approve
export def "admin-invite-requests-approve" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.invites:write` (required) (spec name: token)
  invite_request_id: string # ID of the request to invite.
  --team-id: string # ID for the workspace where the invite request was made.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.inviteRequests.approve"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: invite_request_id, var: invite_request_id}, {name: team_id, var: team_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, invite_request_id: $invite_request_id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all approved workspace invite requests.
#
# GET /admin.inviteRequests.approved.list
# Docs: https://api.slack.com/methods/admin.inviteRequests.approved.list — API method documentation
# Returns: record<ok: bool>
# operationId: admin_inviteRequests_approved_list
export def "admin-invite-requests-approved-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # ID for the workspace where the invite requests were made.
  --cursor: string # Value of the `next_cursor` field sent as part of the previous API response
  --limit: int # The number of results that will be returned by the API on each invocation. Must be between 1 - 1000, both inclusive
  --hdr-token: string # Authentication token. Requires scope: `admin.invites:read` (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin.inviteRequests.approved.list"
    query: [{name: team_id, var: team_id}, {name: cursor, var: cursor}, {name: limit, var: limit}]
    header: [{name: token, var: hdr_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, cursor: $cursor, limit: $limit, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all denied workspace invite requests.
#
# GET /admin.inviteRequests.denied.list
# Docs: https://api.slack.com/methods/admin.inviteRequests.denied.list — API method documentation
# Returns: record<ok: bool>
# operationId: admin_inviteRequests_denied_list
export def "admin-invite-requests-denied-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # ID for the workspace where the invite requests were made.
  --cursor: string # Value of the `next_cursor` field sent as part of the previous api response
  --limit: int # The number of results that will be returned by the API on each invocation. Must be between 1 - 1000 both inclusive
  --hdr-token: string # Authentication token. Requires scope: `admin.invites:read` (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin.inviteRequests.denied.list"
    query: [{name: team_id, var: team_id}, {name: cursor, var: cursor}, {name: limit, var: limit}]
    header: [{name: token, var: hdr_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, cursor: $cursor, limit: $limit, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deny a workspace invite request.
#
# POST /admin.inviteRequests.deny
# Docs: https://api.slack.com/methods/admin.inviteRequests.deny — API method documentation
# Returns: record<ok: bool>
# operationId: admin_inviteRequests_deny
export def "admin-invite-requests-deny" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.invites:write` (required) (spec name: token)
  invite_request_id: string # ID of the request to invite.
  --team-id: string # ID for the workspace where the invite request was made.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.inviteRequests.deny"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: invite_request_id, var: invite_request_id}, {name: team_id, var: team_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, invite_request_id: $invite_request_id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all pending workspace invite requests.
#
# GET /admin.inviteRequests.list
# Docs: https://api.slack.com/methods/admin.inviteRequests.list — API method documentation
# Returns: record<ok: bool>
# operationId: admin_inviteRequests_list
export def "admin-invite-requests-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # ID for the workspace where the invite requests were made.
  --cursor: string # Value of the `next_cursor` field sent as part of the previous API response
  --limit: int # The number of results that will be returned by the API on each invocation. Must be between 1 - 1000, both inclusive
  --hdr-token: string # Authentication token. Requires scope: `admin.invites:read` (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin.inviteRequests.list"
    query: [{name: team_id, var: team_id}, {name: cursor, var: cursor}, {name: limit, var: limit}]
    header: [{name: token, var: hdr_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, cursor: $cursor, limit: $limit, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all of the admins on a given workspace.
#
# GET /admin.teams.admins.list
# Docs: https://api.slack.com/methods/admin.teams.admins.list — API method documentation
# Returns: record<ok: bool>
# operationId: admin_teams_admins_list
export def "admin-teams-admins-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `admin.teams:read` (required) (spec name: token)
  --limit: int # The maximum number of items to return.
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page.
  --team-id: string # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin.teams.admins.list"
    query: [{name: token, var: qp_token, required: true}, {name: limit, var: limit}, {name: cursor, var: cursor}, {name: team_id, var: team_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, limit: $limit, cursor: $cursor, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an Enterprise team.
#
# POST /admin.teams.create
# Docs: https://api.slack.com/methods/admin.teams.create — API method documentation
# Returns: record<ok: bool>
# operationId: admin_teams_create
export def "admin-teams-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.teams:write` (required) (spec name: token)
  --team-description: string # Description for the team.
  --team-discoverability: string # Who can join the team. A team's discoverability can be `open`, `closed`, `invite_only`, or `unlisted`.
  team_domain: string # Team domain (for example, slacksoftballteam).
  team_name: string # Team name (for example, Slack Softball Team).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.teams.create"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: team_description, var: team_description}, {name: team_discoverability, var: team_discoverability}, {name: team_domain, var: team_domain}, {name: team_name, var: team_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, team_description: $team_description, team_discoverability: $team_discoverability, team_domain: $team_domain, team_name: $team_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all teams on an Enterprise organization
#
# GET /admin.teams.list
# Docs: https://api.slack.com/methods/admin.teams.list — API method documentation
# Returns: record<ok: bool>
# operationId: admin_teams_list
export def "admin-teams-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of items to return. Must be between 1 - 100 both inclusive.
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page.
  --hdr-token: string # Authentication token. Requires scope: `admin.teams:read` (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin.teams.list"
    query: [{name: limit, var: limit}, {name: cursor, var: cursor}]
    header: [{name: token, var: hdr_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, cursor: $cursor, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all of the owners on a given workspace.
#
# GET /admin.teams.owners.list
# Docs: https://api.slack.com/methods/admin.teams.owners.list — API method documentation
# Returns: record<ok: bool>
# operationId: admin_teams_owners_list
export def "admin-teams-owners-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `admin.teams:read` (required) (spec name: token)
  --team-id: string # required
  --limit: int # The maximum number of items to return. Must be between 1 - 1000 both inclusive.
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin.teams.owners.list"
    query: [{name: token, var: qp_token, required: true}, {name: team_id, var: team_id, required: true}, {name: limit, var: limit}, {name: cursor, var: cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, team_id: $team_id, limit: $limit, cursor: $cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch information about settings in a workspace
#
# GET /admin.teams.settings.info
# Docs: https://api.slack.com/methods/admin.teams.settings.info — API method documentation
# Returns: record<ok: bool>
# operationId: admin_teams_settings_info
export def "admin-teams-settings-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # required
  --hdr-token: string # Authentication token. Requires scope: `admin.teams:read` (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin.teams.settings.info"
    query: [{name: team_id, var: team_id, required: true}]
    header: [{name: token, var: hdr_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the default channels of a workspace.
#
# POST /admin.teams.settings.setDefaultChannels
# Docs: https://api.slack.com/methods/admin.teams.settings.setDefaultChannels — API method documentation
# Returns: record<ok: bool>
# operationId: admin_teams_settings_setDefaultChannels
export def "admin-teams-settings-set-default-channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  channel_ids: string # An array of channel IDs.
  team_id: string # ID for the workspace to set the default channel for.
  --body-token: string # Authentication token. Requires scope: `admin.teams:write` (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.teams.settings.setDefaultChannels"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel_ids, var: channel_ids}, {name: team_id, var: team_id}, {name: token, var: body_token, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_ids: $channel_ids, team_id: $team_id, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the description of a given workspace.
#
# POST /admin.teams.settings.setDescription
# Docs: https://api.slack.com/methods/admin.teams.settings.setDescription — API method documentation
# Returns: record<ok: bool>
# operationId: admin_teams_settings_setDescription
export def "admin-teams-settings-set-description" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.teams:write` (required) (spec name: token)
  description: string # The new description for the workspace.
  team_id: string # ID for the workspace to set the description for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.teams.settings.setDescription"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: description, var: description}, {name: team_id, var: team_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, description: $description, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# An API method that allows admins to set the discoverability of a given workspace
#
# POST /admin.teams.settings.setDiscoverability
# Docs: https://api.slack.com/methods/admin.teams.settings.setDiscoverability — API method documentation
# Returns: record<ok: bool>
# operationId: admin_teams_settings_setDiscoverability
export def "admin-teams-settings-set-discoverability" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.teams:write` (required) (spec name: token)
  discoverability: string # This workspace's discovery setting. It must be set to one of `open`, `invite_only`, `closed`, or `unlisted`.
  team_id: string # The ID of the workspace to set discoverability on.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.teams.settings.setDiscoverability"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: discoverability, var: discoverability}, {name: team_id, var: team_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, discoverability: $discoverability, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the icon of a workspace.
#
# POST /admin.teams.settings.setIcon
# Docs: https://api.slack.com/methods/admin.teams.settings.setIcon — API method documentation
# Returns: record<ok: bool>
# operationId: admin_teams_settings_setIcon
export def "admin-teams-settings-set-icon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  image_url: string # Image URL for the icon
  team_id: string # ID for the workspace to set the icon for.
  --body-token: string # Authentication token. Requires scope: `admin.teams:write` (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.teams.settings.setIcon"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: image_url, var: image_url}, {name: team_id, var: team_id}, {name: token, var: body_token, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_url: $image_url, team_id: $team_id, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the name of a given workspace.
#
# POST /admin.teams.settings.setName
# Docs: https://api.slack.com/methods/admin.teams.settings.setName — API method documentation
# Returns: record<ok: bool>
# operationId: admin_teams_settings_setName
export def "admin-teams-settings-set-name" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.teams:write` (required) (spec name: token)
  name: string # The new name of the workspace.
  team_id: string # ID for the workspace to set the name for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.teams.settings.setName"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: name, var: name}, {name: team_id, var: team_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, name: $name, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add one or more default channels to an IDP group.
#
# POST /admin.usergroups.addChannels
# Docs: https://api.slack.com/methods/admin.usergroups.addChannels — API method documentation
# Returns: record<ok: bool>
# operationId: admin_usergroups_addChannels
export def "admin-usergroups-add-channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.usergroups:write` (required) (spec name: token)
  channel_ids: string # Comma separated string of channel IDs.
  --team-id: string # The workspace to add default channels in.
  usergroup_id: string # ID of the IDP group to add default channels for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.usergroups.addChannels"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel_ids, var: channel_ids}, {name: team_id, var: team_id}, {name: usergroup_id, var: usergroup_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel_ids: $channel_ids, team_id: $team_id, usergroup_id: $usergroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associate one or more default workspaces with an organization-wide IDP group.
#
# POST /admin.usergroups.addTeams
# Docs: https://api.slack.com/methods/admin.usergroups.addTeams — API method documentation
# Returns: record<ok: bool>
# operationId: admin_usergroups_addTeams
export def "admin-usergroups-add-teams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.teams:write` (required) (spec name: token)
  --auto-provision: oneof<nothing, bool> # When `true`, this method automatically creates new workspace accounts for the IDP group members.
  team_ids: string # A comma separated list of encoded team (workspace) IDs. Each workspace *MUST* belong to the organization associated with the token.
  usergroup_id: string # An encoded usergroup (IDP Group) ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.usergroups.addTeams"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: auto_provision, var: auto_provision}, {name: team_ids, var: team_ids}, {name: usergroup_id, var: usergroup_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, auto_provision: $auto_provision, team_ids: $team_ids, usergroup_id: $usergroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the channels linked to an org-level IDP group (user group).
#
# GET /admin.usergroups.listChannels
# Docs: https://api.slack.com/methods/admin.usergroups.listChannels — API method documentation
# Returns: record<ok: bool>
# operationId: admin_usergroups_listChannels
export def "admin-usergroups-list-channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --usergroup-id: string # ID of the IDP group to list default channels for. (required)
  --team-id: string # ID of the the workspace.
  --include-num-members: oneof<nothing, bool> # Flag to include or exclude the count of members per channel.
  --hdr-token: string # Authentication token. Requires scope: `admin.usergroups:read` (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin.usergroups.listChannels"
    query: [{name: usergroup_id, var: usergroup_id, required: true}, {name: team_id, var: team_id}, {name: include_num_members, var: include_num_members}]
    header: [{name: token, var: hdr_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    usergroup_id: $usergroup_id, team_id: $team_id, include_num_members: $include_num_members, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove one or more default channels from an org-level IDP group (user group).
#
# POST /admin.usergroups.removeChannels
# Docs: https://api.slack.com/methods/admin.usergroups.removeChannels — API method documentation
# Returns: record<ok: bool>
# operationId: admin_usergroups_removeChannels
export def "admin-usergroups-remove-channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.usergroups:write` (required) (spec name: token)
  channel_ids: string # Comma-separated string of channel IDs
  usergroup_id: string # ID of the IDP Group
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.usergroups.removeChannels"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel_ids, var: channel_ids}, {name: usergroup_id, var: usergroup_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel_ids: $channel_ids, usergroup_id: $usergroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add an Enterprise user to a workspace.
#
# POST /admin.users.assign
# Docs: https://api.slack.com/methods/admin.users.assign — API method documentation
# Returns: record<ok: bool>
# operationId: admin_users_assign
export def "admin-users-assign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.users:write` (required) (spec name: token)
  --channel-ids: string # Comma separated values of channel IDs to add user in the new workspace.
  --is-restricted: oneof<nothing, bool> # True if user should be added to the workspace as a guest.
  --is-ultra-restricted: oneof<nothing, bool> # True if user should be added to the workspace as a single-channel guest.
  team_id: string # The ID (`T1234`) of the workspace.
  user_id: string # The ID of the user to add to the workspace.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.users.assign"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel_ids, var: channel_ids}, {name: is_restricted, var: is_restricted}, {name: is_ultra_restricted, var: is_ultra_restricted}, {name: team_id, var: team_id}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel_ids: $channel_ids, is_restricted: $is_restricted, is_ultra_restricted: $is_ultra_restricted, team_id: $team_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invite a user to a workspace.
#
# POST /admin.users.invite
# Docs: https://api.slack.com/methods/admin.users.invite — API method documentation
# Returns: record<ok: bool>
# operationId: admin_users_invite
export def "admin-users-invite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.users:write` (required) (spec name: token)
  channel_ids: string # A comma-separated list of `channel_id`s for this user to join. At least one channel is required.
  --custom-message: string # An optional message to send to the user in the invite email.
  email: string # The email address of the person to invite.
  --guest-expiration-ts: string # Timestamp when guest account should be disabled. Only include this timestamp if you are inviting a guest user and you want their account to expire on a certain date.
  --is-restricted: oneof<nothing, bool> # Is this user a multi-channel guest user? (default: false)
  --is-ultra-restricted: oneof<nothing, bool> # Is this user a single channel guest user? (default: false)
  --real-name: string # Full name of the user.
  --resend: oneof<nothing, bool> # Allow this invite to be resent in the future if a user has not signed up yet. (default: false)
  team_id: string # The ID (`T1234`) of the workspace.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.users.invite"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel_ids, var: channel_ids}, {name: custom_message, var: custom_message}, {name: email, var: email}, {name: guest_expiration_ts, var: guest_expiration_ts}, {name: is_restricted, var: is_restricted}, {name: is_ultra_restricted, var: is_ultra_restricted}, {name: real_name, var: real_name}, {name: resend, var: resend}, {name: team_id, var: team_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel_ids: $channel_ids, custom_message: $custom_message, email: $email, guest_expiration_ts: $guest_expiration_ts, is_restricted: $is_restricted, is_ultra_restricted: $is_ultra_restricted, real_name: $real_name, resend: $resend, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List users on a workspace
#
# GET /admin.users.list
# Docs: https://api.slack.com/methods/admin.users.list — API method documentation
# Returns: record<ok: bool>
# operationId: admin_users_list
export def "admin-users-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The ID (`T1234`) of the workspace. (required)
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page.
  --limit: int # Limit for how many users to be retrieved per page
  --hdr-token: string # Authentication token. Requires scope: `admin.users:read` (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin.users.list"
    query: [{name: team_id, var: team_id, required: true}, {name: cursor, var: cursor}, {name: limit, var: limit}]
    header: [{name: token, var: hdr_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, cursor: $cursor, limit: $limit, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a user from a workspace.
#
# POST /admin.users.remove
# Docs: https://api.slack.com/methods/admin.users.remove — API method documentation
# Returns: record<ok: bool>
# operationId: admin_users_remove
export def "admin-users-remove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.users:write` (required) (spec name: token)
  team_id: string # The ID (`T1234`) of the workspace.
  user_id: string # The ID of the user to remove.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.users.remove"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: team_id, var: team_id}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, team_id: $team_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invalidate a single session for a user by session_id
#
# POST /admin.users.session.invalidate
# Docs: https://api.slack.com/methods/admin.users.session.invalidate — API method documentation
# Returns: record<ok: bool>
# operationId: admin_users_session_invalidate
export def "admin-users-session-invalidate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.users:write` (required) (spec name: token)
  session_id: int
  team_id: string # ID of the team that the session belongs to
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.users.session.invalidate"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: session_id, var: session_id}, {name: team_id, var: team_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, session_id: $session_id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Wipes all valid sessions on all devices for a given user
#
# POST /admin.users.session.reset
# Docs: https://api.slack.com/methods/admin.users.session.reset — API method documentation
# Returns: record<ok: bool>
# operationId: admin_users_session_reset
export def "admin-users-session-reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.users:write` (required) (spec name: token)
  --mobile-only: oneof<nothing, bool> # Only expire mobile sessions (default: false)
  user_id: string # The ID of the user to wipe sessions for
  --web-only: oneof<nothing, bool> # Only expire web sessions (default: false)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.users.session.reset"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: mobile_only, var: mobile_only}, {name: user_id, var: user_id}, {name: web_only, var: web_only}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, mobile_only: $mobile_only, user_id: $user_id, web_only: $web_only
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set an existing guest, regular user, or owner to be an admin user.
#
# POST /admin.users.setAdmin
# Docs: https://api.slack.com/methods/admin.users.setAdmin — API method documentation
# Returns: record<ok: bool>
# operationId: admin_users_setAdmin
export def "admin-users-set-admin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.users:write` (required) (spec name: token)
  team_id: string # The ID (`T1234`) of the workspace.
  user_id: string # The ID of the user to designate as an admin.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.users.setAdmin"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: team_id, var: team_id}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, team_id: $team_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set an expiration for a guest user
#
# POST /admin.users.setExpiration
# Docs: https://api.slack.com/methods/admin.users.setExpiration — API method documentation
# Returns: record<ok: bool>
# operationId: admin_users_setExpiration
export def "admin-users-set-expiration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.users:write` (required) (spec name: token)
  expiration_ts: int # Timestamp when guest account should be disabled.
  team_id: string # The ID (`T1234`) of the workspace.
  user_id: string # The ID of the user to set an expiration for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.users.setExpiration"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: expiration_ts, var: expiration_ts}, {name: team_id, var: team_id}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, expiration_ts: $expiration_ts, team_id: $team_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set an existing guest, regular user, or admin user to be a workspace owner.
#
# POST /admin.users.setOwner
# Docs: https://api.slack.com/methods/admin.users.setOwner — API method documentation
# Returns: record<ok: bool>
# operationId: admin_users_setOwner
export def "admin-users-set-owner" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.users:write` (required) (spec name: token)
  team_id: string # The ID (`T1234`) of the workspace.
  user_id: string # Id of the user to promote to owner.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.users.setOwner"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: team_id, var: team_id}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, team_id: $team_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set an existing guest user, admin user, or owner to be a regular user.
#
# POST /admin.users.setRegular
# Docs: https://api.slack.com/methods/admin.users.setRegular — API method documentation
# Returns: record<ok: bool>
# operationId: admin_users_setRegular
export def "admin-users-set-regular" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.users:write` (required) (spec name: token)
  team_id: string # The ID (`T1234`) of the workspace.
  user_id: string # The ID of the user to designate as a regular user.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin.users.setRegular"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: team_id, var: team_id}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, team_id: $team_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks API calling code.
#
# GET /api.test
# Docs: https://api.slack.com/methods/api.test — API method documentation
# Returns: record<ok: bool>
# operationId: api_test
export def "api-test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --error: string # Error response to return
  --foo: string # example property to return
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api.test"
    query: [{name: error, var: error}, {name: foo, var: foo}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    error: $error, foo: $foo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of authorizations for the given event context. Each authorization represents an app installation that the event is visible to.
#
# GET /apps.event.authorizations.list
# Docs: https://api.slack.com/methods/apps.event.authorizations.list — API method documentation
# Returns: record<ok: bool>
# operationId: apps_event_authorizations_list
export def "apps-event-authorizations-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --event-context: string # required
  --cursor: string
  --limit: int
  --hdr-token: string # Authentication token. Requires scope: `authorizations:read` (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps.event.authorizations.list"
    query: [{name: event_context, var: event_context, required: true}, {name: cursor, var: cursor}, {name: limit, var: limit}]
    header: [{name: token, var: hdr_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    event_context: $event_context, cursor: $cursor, limit: $limit, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of permissions this app has on a team.
#
# GET /apps.permissions.info
# Docs: https://api.slack.com/methods/apps.permissions.info — API method documentation
# Returns: record<info: record<app_home: record<resources: record, scopes: list>, channel: record<resources: record, scopes: list>, group: record<resources: record, scopes: list>, im: record<resources: record, scopes: list>, mpim: record<resources: record, scopes: list>, team: record<resources: record, scopes: list>>, ok: bool>
# operationId: apps_permissions_info
export def "apps-permissions-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `none` (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps.permissions.info"
    query: [{name: token, var: qp_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows an app to request additional scopes
#
# GET /apps.permissions.request
# Docs: https://api.slack.com/methods/apps.permissions.request — API method documentation
# Returns: record<ok: bool>
# operationId: apps_permissions_request
export def "apps-permissions-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `none` (required) (spec name: token)
  --scopes: string # A comma separated list of scopes to request for (required)
  --trigger-id: string # Token used to trigger the permissions API (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps.permissions.request"
    query: [{name: token, var: qp_token, required: true}, {name: scopes, var: scopes, required: true}, {name: trigger_id, var: trigger_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, scopes: $scopes, trigger_id: $trigger_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of resource grants this app has on a team.
#
# GET /apps.permissions.resources.list
# Docs: https://api.slack.com/methods/apps.permissions.resources.list — API method documentation
# Returns: record<ok: bool, resources: table<id: string, type: string>, response_metadata: record<next_cursor: string>>
# operationId: apps_permissions_resources_list
export def "apps-permissions-resources-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `none` (required) (spec name: token)
  --cursor: string # Paginate through collections of data by setting the `cursor` parameter to a `next_cursor` attribute returned by a previous request's `response_metadata`. Default value fetches the first "page" of the collection. See [pagination](/docs/pagination) for more detail.
  --limit: int # The maximum number of items to return.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps.permissions.resources.list"
    query: [{name: token, var: qp_token, required: true}, {name: cursor, var: cursor}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, cursor: $cursor, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of scopes this app has on a team.
#
# GET /apps.permissions.scopes.list
# Docs: https://api.slack.com/methods/apps.permissions.scopes.list — API method documentation
# Returns: record<ok: bool, scopes: record<app_home: list<string>, channel: list<string>, group: list<string>, im: list<string>, mpim: list<string>, team: list<string>, user: list<string>>>
# operationId: apps_permissions_scopes_list
export def "apps-permissions-scopes-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `none` (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps.permissions.scopes.list"
    query: [{name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of user grants and corresponding scopes this app has on a team.
#
# GET /apps.permissions.users.list
# Docs: https://api.slack.com/methods/apps.permissions.users.list — API method documentation
# Returns: record<ok: bool>
# operationId: apps_permissions_users_list
export def "apps-permissions-users-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `none` (required) (spec name: token)
  --cursor: string # Paginate through collections of data by setting the `cursor` parameter to a `next_cursor` attribute returned by a previous request's `response_metadata`. Default value fetches the first "page" of the collection. See [pagination](/docs/pagination) for more detail.
  --limit: int # The maximum number of items to return.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps.permissions.users.list"
    query: [{name: token, var: qp_token, required: true}, {name: cursor, var: cursor}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, cursor: $cursor, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables an app to trigger a permissions modal to grant an app access to a user access scope.
#
# GET /apps.permissions.users.request
# Docs: https://api.slack.com/methods/apps.permissions.users.request — API method documentation
# Returns: record<ok: bool>
# operationId: apps_permissions_users_request
export def "apps-permissions-users-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `none` (required) (spec name: token)
  --scopes: string # A comma separated list of user scopes to request for (required)
  --trigger-id: string # Token used to trigger the request (required)
  --user: string # The user this scope is being requested for (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps.permissions.users.request"
    query: [{name: token, var: qp_token, required: true}, {name: scopes, var: scopes, required: true}, {name: trigger_id, var: trigger_id, required: true}, {name: user, var: user, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, scopes: $scopes, trigger_id: $trigger_id, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uninstalls your app from a workspace.
#
# GET /apps.uninstall
# Docs: https://api.slack.com/methods/apps.uninstall — API method documentation
# Returns: record<ok: bool>
# operationId: apps_uninstall
export def "apps-uninstall" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `none` (spec name: token)
  --client-id: string # Issued when you created your application.
  --client-secret: string # Issued when you created your application.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps.uninstall"
    query: [{name: token, var: qp_token}, {name: client_id, var: client_id}, {name: client_secret, var: client_secret}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, client_id: $client_id, client_secret: $client_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Revokes a token.
#
# GET /auth.revoke
# Docs: https://api.slack.com/methods/auth.revoke — API method documentation
# Returns: record<ok: bool, revoked: bool>
# operationId: auth_revoke
export def "auth-revoke" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `none` (required) (spec name: token)
  --test: oneof<nothing, bool> # Setting this parameter to `1` triggers a _testing mode_ where the specified token will not actually be revoked.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/auth.revoke"
    query: [{name: token, var: qp_token, required: true}, {name: test, var: test}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, test: $test
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks authentication & identity.
#
# GET /auth.test
# Docs: https://api.slack.com/methods/auth.test — API method documentation
# Returns: record<bot_id: string, is_enterprise_install: bool, ok: bool, team: string, team_id: string, url: string, user: string, user_id: string>
# operationId: auth_test
export def "auth-test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `none` (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/auth.test"
    header: [{name: token, var: hdr_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a bot user.
#
# GET /bots.info
# Docs: https://api.slack.com/methods/bots.info — API method documentation
# Returns: record<bot: record<app_id: string, deleted: bool, icons: record<image_36: string, image_48: string, image_72: string>, id: string, name: string, updated: int, user_id: string>, ok: bool>
# operationId: bots_info
export def "bots-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `users:read` (required) (spec name: token)
  --bot: string # Bot user to get info on
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bots.info"
    query: [{name: token, var: qp_token, required: true}, {name: bot, var: bot}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, bot: $bot
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Registers a new Call.
#
# POST /calls.add
# Docs: https://api.slack.com/methods/calls.add — API method documentation
# Returns: record<ok: bool>
# operationId: calls_add
export def "calls-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `calls:write` (required) (spec name: token)
  --created-by: string # The valid Slack user ID of the user who created this Call. When this method is called with a user token, the `created_by` field is optional and defaults to the authed user of the token. Otherwise, the field is required.
  --date-start: int # Call start time in UTC UNIX timestamp format
  --desktop-app-join-url: string # When supplied, available Slack clients will attempt to directly launch the 3rd-party Call with this URL.
  --external-display-id: string # An optional, human-readable ID supplied by the 3rd-party Call provider. If supplied, this ID will be displayed in the Call object.
  external_unique_id: string # An ID supplied by the 3rd-party Call provider. It must be unique across all Calls from that service.
  join_url: string # The URL required for a client to join the Call.
  --title: string # The name of the Call.
  --users: string # The list of users to register as participants in the Call. [Read more on how to specify users here](/apis/calls#users).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls.add"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: created_by, var: created_by}, {name: date_start, var: date_start}, {name: desktop_app_join_url, var: desktop_app_join_url}, {name: external_display_id, var: external_display_id}, {name: external_unique_id, var: external_unique_id}, {name: join_url, var: join_url}, {name: title, var: title}, {name: users, var: users}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, created_by: $created_by, date_start: $date_start, desktop_app_join_url: $desktop_app_join_url, external_display_id: $external_display_id, external_unique_id: $external_unique_id, join_url: $join_url, title: $title, users: $users
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ends a Call.
#
# POST /calls.end
# Docs: https://api.slack.com/methods/calls.end — API method documentation
# Returns: record<ok: bool>
# operationId: calls_end
export def "calls-end" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `calls:write` (required) (spec name: token)
  --duration: int # Call duration in seconds
  id: string # `id` returned when registering the call using the [`calls.add`](/methods/calls.add) method.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls.end"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: duration, var: duration}, {name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, duration: $duration, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a Call.
#
# GET /calls.info
# Docs: https://api.slack.com/methods/calls.info — API method documentation
# Returns: record<ok: bool>
# operationId: calls_info
export def "calls-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # `id` of the Call returned by the [`calls.add`](/methods/calls.add) method. (required)
  --hdr-token: string # Authentication token. Requires scope: `calls:read` (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/calls.info"
    query: [{name: id, var: id, required: true}]
    header: [{name: token, var: hdr_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Registers new participants added to a Call.
#
# POST /calls.participants.add
# Docs: https://api.slack.com/methods/calls.participants.add — API method documentation
# Returns: record<ok: bool>
# operationId: calls_participants_add
export def "calls-participants-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `calls:write` (required) (spec name: token)
  id: string # `id` returned by the [`calls.add`](/methods/calls.add) method.
  users: string # The list of users to add as participants in the Call. [Read more on how to specify users here](/apis/calls#users).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls.participants.add"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: id, var: id}, {name: users, var: users}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, id: $id, users: $users
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Registers participants removed from a Call.
#
# POST /calls.participants.remove
# Docs: https://api.slack.com/methods/calls.participants.remove — API method documentation
# Returns: record<ok: bool>
# operationId: calls_participants_remove
export def "calls-participants-remove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `calls:write` (required) (spec name: token)
  id: string # `id` returned by the [`calls.add`](/methods/calls.add) method.
  users: string # The list of users to remove as participants in the Call. [Read more on how to specify users here](/apis/calls#users).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls.participants.remove"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: id, var: id}, {name: users, var: users}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, id: $id, users: $users
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates information about a Call.
#
# POST /calls.update
# Docs: https://api.slack.com/methods/calls.update — API method documentation
# Returns: record<ok: bool>
# operationId: calls_update
export def "calls-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `calls:write` (required) (spec name: token)
  --desktop-app-join-url: string # When supplied, available Slack clients will attempt to directly launch the 3rd-party Call with this URL.
  id: string # `id` returned by the [`calls.add`](/methods/calls.add) method.
  --join-url: string # The URL required for a client to join the Call.
  --title: string # The name of the Call.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls.update"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: desktop_app_join_url, var: desktop_app_join_url}, {name: id, var: id}, {name: join_url, var: join_url}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, desktop_app_join_url: $desktop_app_join_url, id: $id, join_url: $join_url, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a message.
#
# POST /chat.delete
# Docs: https://api.slack.com/methods/chat.delete — API method documentation
# Returns: record<channel: string, ok: bool, ts: string>
# operationId: chat_delete
export def "chat-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `chat:write` (spec name: token)
  --as-user: oneof<nothing, bool> # Pass true to delete the message as the authed user with `chat:write:user` scope. [Bot users](/bot-users) in this context are considered authed users. If unused or false, the message will be deleted with `chat:write:bot` scope.
  --channel: string # Channel containing the message to be deleted.
  --ts: float # Timestamp of the message to be deleted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/chat.delete"
    header: [{name: token, var: hdr_token}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: as_user, var: as_user}, {name: channel, var: channel}, {name: ts, var: ts}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, as_user: $as_user, channel: $channel, ts: $ts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a pending scheduled message from the queue.
#
# POST /chat.deleteScheduledMessage
# Docs: https://api.slack.com/methods/chat.deleteScheduledMessage — API method documentation
# Returns: record<ok: bool>
# operationId: chat_deleteScheduledMessage
export def "chat-delete-scheduled-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `chat:write` (required) (spec name: token)
  --as-user: oneof<nothing, bool> # Pass true to delete the message as the authed user with `chat:write:user` scope. [Bot users](/bot-users) in this context are considered authed users. If unused or false, the message will be deleted with `chat:write:bot` scope.
  channel: string # The channel the scheduled_message is posting to
  scheduled_message_id: string # `scheduled_message_id` returned from call to chat.scheduleMessage
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/chat.deleteScheduledMessage"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: as_user, var: as_user}, {name: channel, var: channel}, {name: scheduled_message_id, var: scheduled_message_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, as_user: $as_user, channel: $channel, scheduled_message_id: $scheduled_message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a permalink URL for a specific extant message
#
# GET /chat.getPermalink
# Docs: https://api.slack.com/methods/chat.getPermalink — API method documentation
# Returns: record<channel: string, ok: bool, permalink: string>
# operationId: chat_getPermalink
export def "chat-get-permalink" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `none` (required) (spec name: token)
  --channel: string # The ID of the conversation or channel containing the message (required)
  --message-ts: string # A message's `ts` value, uniquely identifying it within a channel (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/chat.getPermalink"
    query: [{name: token, var: qp_token, required: true}, {name: channel, var: channel, required: true}, {name: message_ts, var: message_ts, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, channel: $channel, message_ts: $message_ts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Share a me message into a channel.
#
# POST /chat.meMessage
# Docs: https://api.slack.com/methods/chat.meMessage — API method documentation
# Returns: record<channel: string, ok: bool, ts: string>
# operationId: chat_meMessage
export def "chat-me-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `chat:write` (spec name: token)
  --channel: string # Channel to send message to. Can be a public channel, private group or IM channel. Can be an encoded ID, or a name.
  --text: string # Text of the message to send.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/chat.meMessage"
    header: [{name: token, var: hdr_token}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel, var: channel}, {name: text, var: text}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel: $channel, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends an ephemeral message to a user in a channel.
#
# POST /chat.postEphemeral
# Docs: https://api.slack.com/methods/chat.postEphemeral — API method documentation
# Returns: record<message_ts: string, ok: bool>
# operationId: chat_postEphemeral
export def "chat-post-ephemeral" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `chat:write` (required) (spec name: token)
  --as-user: oneof<nothing, bool> # Pass true to post the message as the authed user. Defaults to true if the chat:write:bot scope is not included. Otherwise, defaults to false.
  --attachments: string # A JSON-based array of structured attachments, presented as a URL-encoded string.
  --blocks: string # A JSON-based array of structured blocks, presented as a URL-encoded string.
  channel: string # Channel, private group, or IM channel to send message to. Can be an encoded ID, or a name.
  --icon-emoji: string # Emoji to use as the icon for this message. Overrides `icon_url`. Must be used in conjunction with `as_user` set to `false`, otherwise ignored. See [authorship](#authorship) below.
  --icon-url: string # URL to an image to use as the icon for this message. Must be used in conjunction with `as_user` set to false, otherwise ignored. See [authorship](#authorship) below.
  --link-names: oneof<nothing, bool> # Find and link channel names and usernames.
  --parse: string # Change how messages are treated. Defaults to `none`. See [below](#formatting).
  --text: string # How this field works and whether it is required depends on other fields you use in your API call. [See below](#text_usage) for more detail.
  --thread-ts: string # Provide another message's `ts` value to post this message in a thread. Avoid using a reply's `ts` value; use its parent's value instead. Ephemeral messages in threads are only shown if there is already an active thread.
  user: string # `id` of the user who will receive the ephemeral message. The user should be in the channel specified by the `channel` argument.
  --username: string # Set your bot's user name. Must be used in conjunction with `as_user` set to false, otherwise ignored. See [authorship](#authorship) below.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/chat.postEphemeral"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: as_user, var: as_user}, {name: attachments, var: attachments}, {name: blocks, var: blocks}, {name: channel, var: channel}, {name: icon_emoji, var: icon_emoji}, {name: icon_url, var: icon_url}, {name: link_names, var: link_names}, {name: parse, var: parse}, {name: text, var: text}, {name: thread_ts, var: thread_ts}, {name: user, var: user}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, as_user: $as_user, attachments: $attachments, blocks: $blocks, channel: $channel, icon_emoji: $icon_emoji, icon_url: $icon_url, link_names: $link_names, parse: $parse, text: $text, thread_ts: $thread_ts, user: $user, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends a message to a channel.
#
# POST /chat.postMessage
# Docs: https://api.slack.com/methods/chat.postMessage — API method documentation
# Returns: record<channel: string, message: record<attachments: list<record>, blocks: list<record>, bot_id: list<any>, bot_profile: record<app_id: string, deleted: bool, icons: record, id: string, name: string, team_id: string, updated: int>, client_msg_id: string, comment: record<comment: string, created: int, id: string, is_intro: bool, is_starred: bool, num_stars: int, pinned_info: record, pinned_to: list, reactions: list, timestamp: int, user: string>, display_as_bot: bool, file: record<channels: list, comments_count: int, created: int, date_delete: int, display_as_bot: bool, editable: bool, editor: string, external_id: string, external_type: string, external_url: string, filetype: string, groups: list, has_rich_preview: bool, id: string, image_exif_rotation: int, ims: list, is_external: bool, is_public: bool, is_starred: bool, is_tombstoned: bool, last_editor: string, mimetype: string, mode: string, name: string, non_owner_editable: bool, num_stars: int, original_h: int, original_w: int, permalink: string, permalink_public: string, pinned_info: record, pinned_to: list, pretty_type: string, preview: string, public_url_shared: bool, reactions: list, shares: record, size: int, source_team: string, state: string, thumb_1024: string, thumb_1024_h: int, thumb_1024_w: int, thumb_160: string, thumb_360: string, thumb_360_h: int, thumb_360_w: int, thumb_480: string, thumb_480_h: int, thumb_480_w: int, thumb_64: string, thumb_720: string, thumb_720_h: int, thumb_720_w: int, thumb_80: string, thumb_800: string, thumb_800_h: int, thumb_800_w: int, thumb_960: string, thumb_960_h: int, thumb_960_w: int, thumb_tiny: string, timestamp: int, title: string, updated: int, url_private: string, url_private_download: string, user: string, user_team: string, username: string>, files: list<record>, icons: record<emoji: string, image_64: string>, inviter: string, is_delayed_message: bool, is_intro: bool, is_starred: bool, last_read: string, latest_reply: string, name: string, old_name: string, parent_user_id: string, permalink: string, pinned_to: list<string>, purpose: string, reactions: list<record>, reply_count: int, reply_users: list<string>, reply_users_count: int, source_team: string, subscribed: bool, subtype: string, team: string, text: string, thread_ts: string, topic: string, ts: string, type: string, unread_count: int, upload: bool, user: string, user_profile: record<avatar_hash: string, display_name: string, display_name_normalized: string, first_name: string, image_72: string, is_restricted: bool, is_ultra_restricted: bool, name: string, real_name: string, real_name_normalized: string, team: string>, user_team: string, username: string>, ok: bool, ts: string>
# operationId: chat_postMessage
export def "chat-post-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `chat:write` (required) (spec name: token)
  --as-user: string # Pass true to post the message as the authed user, instead of as a bot. Defaults to false. See [authorship](#authorship) below.
  --attachments: string # A JSON-based array of structured attachments, presented as a URL-encoded string.
  --blocks: string # A JSON-based array of structured blocks, presented as a URL-encoded string.
  channel: string # Channel, private group, or IM channel to send message to. Can be an encoded ID, or a name. See [below](#channels) for more details.
  --icon-emoji: string # Emoji to use as the icon for this message. Overrides `icon_url`. Must be used in conjunction with `as_user` set to `false`, otherwise ignored. See [authorship](#authorship) below.
  --icon-url: string # URL to an image to use as the icon for this message. Must be used in conjunction with `as_user` set to false, otherwise ignored. See [authorship](#authorship) below.
  --link-names: oneof<nothing, bool> # Find and link channel names and usernames.
  --mrkdwn: oneof<nothing, bool> # Disable Slack markup parsing by setting to `false`. Enabled by default.
  --parse: string # Change how messages are treated. Defaults to `none`. See [below](#formatting).
  --reply-broadcast: oneof<nothing, bool> # Used in conjunction with `thread_ts` and indicates whether reply should be made visible to everyone in the channel or conversation. Defaults to `false`.
  --text: string # How this field works and whether it is required depends on other fields you use in your API call. [See below](#text_usage) for more detail.
  --thread-ts: string # Provide another message's `ts` value to make this message a reply. Avoid using a reply's `ts` value; use its parent instead.
  --unfurl-links: oneof<nothing, bool> # Pass true to enable unfurling of primarily text-based content.
  --unfurl-media: oneof<nothing, bool> # Pass false to disable unfurling of media content.
  --username: string # Set your bot's user name. Must be used in conjunction with `as_user` set to false, otherwise ignored. See [authorship](#authorship) below.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/chat.postMessage"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: as_user, var: as_user}, {name: attachments, var: attachments}, {name: blocks, var: blocks}, {name: channel, var: channel}, {name: icon_emoji, var: icon_emoji}, {name: icon_url, var: icon_url}, {name: link_names, var: link_names}, {name: mrkdwn, var: mrkdwn}, {name: parse, var: parse}, {name: reply_broadcast, var: reply_broadcast}, {name: text, var: text}, {name: thread_ts, var: thread_ts}, {name: unfurl_links, var: unfurl_links}, {name: unfurl_media, var: unfurl_media}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, as_user: $as_user, attachments: $attachments, blocks: $blocks, channel: $channel, icon_emoji: $icon_emoji, icon_url: $icon_url, link_names: $link_names, mrkdwn: $mrkdwn, parse: $parse, reply_broadcast: $reply_broadcast, text: $text, thread_ts: $thread_ts, unfurl_links: $unfurl_links, unfurl_media: $unfurl_media, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Schedules a message to be sent to a channel.
#
# POST /chat.scheduleMessage
# Docs: https://api.slack.com/methods/chat.scheduleMessage — API method documentation
# Returns: record<channel: string, message: record<bot_id: string, bot_profile: record<app_id: string, deleted: bool, icons: record, id: string, name: string, team_id: string, updated: int>, team: string, text: string, type: string, user: string, username: string>, ok: bool, post_at: int, scheduled_message_id: string>
# operationId: chat_scheduleMessage
export def "chat-schedule-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `chat:write` (spec name: token)
  --as-user: oneof<nothing, bool> # Pass true to post the message as the authed user, instead of as a bot. Defaults to false. See [chat.postMessage](chat.postMessage#authorship).
  --attachments: string # A JSON-based array of structured attachments, presented as a URL-encoded string.
  --blocks: string # A JSON-based array of structured blocks, presented as a URL-encoded string.
  --channel: string # Channel, private group, or DM channel to send message to. Can be an encoded ID, or a name. See [below](#channels) for more details.
  --link-names: oneof<nothing, bool> # Find and link channel names and usernames.
  --parse: string # Change how messages are treated. Defaults to `none`. See [chat.postMessage](chat.postMessage#formatting).
  --post-at: string # Unix EPOCH timestamp of time in future to send the message.
  --reply-broadcast: oneof<nothing, bool> # Used in conjunction with `thread_ts` and indicates whether reply should be made visible to everyone in the channel or conversation. Defaults to `false`.
  --text: string # How this field works and whether it is required depends on other fields you use in your API call. [See below](#text_usage) for more detail.
  --thread-ts: float # Provide another message's `ts` value to make this message a reply. Avoid using a reply's `ts` value; use its parent instead.
  --unfurl-links: oneof<nothing, bool> # Pass true to enable unfurling of primarily text-based content.
  --unfurl-media: oneof<nothing, bool> # Pass false to disable unfurling of media content.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/chat.scheduleMessage"
    header: [{name: token, var: hdr_token}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: as_user, var: as_user}, {name: attachments, var: attachments}, {name: blocks, var: blocks}, {name: channel, var: channel}, {name: link_names, var: link_names}, {name: parse, var: parse}, {name: post_at, var: post_at}, {name: reply_broadcast, var: reply_broadcast}, {name: text, var: text}, {name: thread_ts, var: thread_ts}, {name: unfurl_links, var: unfurl_links}, {name: unfurl_media, var: unfurl_media}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, as_user: $as_user, attachments: $attachments, blocks: $blocks, channel: $channel, link_names: $link_names, parse: $parse, post_at: $post_at, reply_broadcast: $reply_broadcast, text: $text, thread_ts: $thread_ts, unfurl_links: $unfurl_links, unfurl_media: $unfurl_media
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of scheduled messages.
#
# GET /chat.scheduledMessages.list
# Docs: https://api.slack.com/methods/chat.scheduledMessages.list — API method documentation
# Returns: record<ok: bool, response_metadata: record<next_cursor: string>, scheduled_messages: table<channel_id: string, date_created: int, id: string, post_at: int, text: string>>
# operationId: chat_scheduledMessages_list
export def "chat-scheduled-messages-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --channel: string # The channel of the scheduled messages
  --latest: float # A UNIX timestamp of the latest value in the time range
  --oldest: float # A UNIX timestamp of the oldest value in the time range
  --limit: int # Maximum number of original entries to return.
  --cursor: string # For pagination purposes, this is the `cursor` value returned from a previous call to `chat.scheduledmessages.list` indicating where you want to start this call from.
  --hdr-token: string # Authentication token. Requires scope: `none` (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/chat.scheduledMessages.list"
    query: [{name: channel, var: channel}, {name: latest, var: latest}, {name: oldest, var: oldest}, {name: limit, var: limit}, {name: cursor, var: cursor}]
    header: [{name: token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel: $channel, latest: $latest, oldest: $oldest, limit: $limit, cursor: $cursor, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provide custom unfurl behavior for user-posted URLs
#
# POST /chat.unfurl
# Docs: https://api.slack.com/methods/chat.unfurl — API method documentation
# Returns: record<ok: bool>
# operationId: chat_unfurl
export def "chat-unfurl" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `links:write` (required) (spec name: token)
  channel: string # Channel ID of the message
  ts: string # Timestamp of the message to add unfurl behavior to.
  --unfurls: string # URL-encoded JSON map with keys set to URLs featured in the the message, pointing to their unfurl blocks or message attachments.
  --user-auth-message: string # Provide a simply-formatted string to send as an ephemeral message to the user as invitation to authenticate further and enable full unfurling behavior
  --user-auth-required: oneof<nothing, bool> # Set to `true` or `1` to indicate the user must install your Slack app to trigger unfurls for this domain
  --user-auth-url: string # Send users to this custom URL where they will complete authentication in your app to fully trigger unfurling. Value should be properly URL-encoded.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/chat.unfurl"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel, var: channel}, {name: ts, var: ts}, {name: unfurls, var: unfurls}, {name: user_auth_message, var: user_auth_message}, {name: user_auth_required, var: user_auth_required}, {name: user_auth_url, var: user_auth_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel: $channel, ts: $ts, unfurls: $unfurls, user_auth_message: $user_auth_message, user_auth_required: $user_auth_required, user_auth_url: $user_auth_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a message.
#
# POST /chat.update
# Docs: https://api.slack.com/methods/chat.update — API method documentation
# Returns: record<channel: string, message: record<attachments: list<record>, blocks: record, text: string>, ok: bool, text: string, ts: string>
# operationId: chat_update
export def "chat-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `chat:write` (required) (spec name: token)
  --as-user: string # Pass true to update the message as the authed user. [Bot users](/bot-users) in this context are considered authed users.
  --attachments: string # A JSON-based array of structured attachments, presented as a URL-encoded string. This field is required when not presenting `text`. If you don't include this field, the message's previous `attachments` will be retained. To remove previous `attachments`, include an empty array for this field.
  --blocks: string # A JSON-based array of [structured blocks](/block-kit/building), presented as a URL-encoded string. If you don't include this field, the message's previous `blocks` will be retained. To remove previous `blocks`, include an empty array for this field.
  channel: string # Channel containing the message to be updated.
  --link-names: string # Find and link channel names and usernames. Defaults to `none`. If you do not specify a value for this field, the original value set for the message will be overwritten with the default, `none`.
  --parse: string # Change how messages are treated. Defaults to `client`, unlike `chat.postMessage`. Accepts either `none` or `full`. If you do not specify a value for this field, the original value set for the message will be overwritten with the default, `client`.
  --text: string # New text for the message, using the [default formatting rules](/reference/surfaces/formatting). It's not required when presenting `blocks` or `attachments`.
  ts: string # Timestamp of the message to be updated.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/chat.update"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: as_user, var: as_user}, {name: attachments, var: attachments}, {name: blocks, var: blocks}, {name: channel, var: channel}, {name: link_names, var: link_names}, {name: parse, var: parse}, {name: text, var: text}, {name: ts, var: ts}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, as_user: $as_user, attachments: $attachments, blocks: $blocks, channel: $channel, link_names: $link_names, parse: $parse, text: $text, ts: $ts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Archives a conversation.
#
# POST /conversations.archive
# Docs: https://api.slack.com/methods/conversations.archive — API method documentation
# Returns: record<ok: bool>
# operationId: conversations_archive
export def "conversations-archive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `conversations:write` (spec name: token)
  --channel: string # ID of conversation to archive
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conversations.archive"
    header: [{name: token, var: hdr_token}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel, var: channel}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel: $channel
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Closes a direct message or multi-person direct message.
#
# POST /conversations.close
# Docs: https://api.slack.com/methods/conversations.close — API method documentation
# Returns: record<already_closed: bool, no_op: bool, ok: bool>
# operationId: conversations_close
export def "conversations-close" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `conversations:write` (spec name: token)
  --channel: string # Conversation to close.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conversations.close"
    header: [{name: token, var: hdr_token}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel, var: channel}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel: $channel
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiates a public or private channel-based conversation
#
# POST /conversations.create
# Docs: https://api.slack.com/methods/conversations.create — API method documentation
# Returns: record<channel: list<any>, ok: bool>
# operationId: conversations_create
export def "conversations-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `conversations:write` (spec name: token)
  --is-private: oneof<nothing, bool> # Create a private channel instead of a public one
  --name: string # Name of the public or private channel to create
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conversations.create"
    header: [{name: token, var: hdr_token}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: is_private, var: is_private}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, is_private: $is_private, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches a conversation's history of messages and events.
#
# GET /conversations.history
# Docs: https://api.slack.com/methods/conversations.history — API method documentation
# Returns: record<channel_actions_count: int, channel_actions_ts: list<any>, has_more: bool, messages: table<attachments: list, blocks: list, bot_id: list, bot_profile: record, client_msg_id: string, comment: record, display_as_bot: bool, file: record, files: list, icons: record, inviter: string, is_delayed_message: bool, is_intro: bool, is_starred: bool, last_read: string, latest_reply: string, name: string, old_name: string, parent_user_id: string, permalink: string, pinned_to: list, purpose: string, reactions: list, reply_count: int, reply_users: list, reply_users_count: int, source_team: string, subscribed: bool, subtype: string, team: string, text: string, thread_ts: string, topic: string, ts: string, type: string, unread_count: int, upload: bool, user: string, user_profile: record, user_team: string, username: string>, ok: bool, pin_count: int>
# operationId: conversations_history
export def "conversations-history" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `conversations:history` (spec name: token)
  --channel: string # Conversation ID to fetch history for.
  --latest: float # End of time range of messages to include in results.
  --oldest: float # Start of time range of messages to include in results.
  --inclusive: oneof<nothing, bool> # Include messages with latest or oldest timestamp in results only when either timestamp is specified.
  --limit: int # The maximum number of items to return. Fewer than the requested number of items may be returned, even if the end of the users list hasn't been reached.
  --cursor: string # Paginate through collections of data by setting the `cursor` parameter to a `next_cursor` attribute returned by a previous request's `response_metadata`. Default value fetches the first "page" of the collection. See [pagination](/docs/pagination) for more detail.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/conversations.history"
    query: [{name: token, var: qp_token}, {name: channel, var: channel}, {name: latest, var: latest}, {name: oldest, var: oldest}, {name: inclusive, var: inclusive}, {name: limit, var: limit}, {name: cursor, var: cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, channel: $channel, latest: $latest, oldest: $oldest, inclusive: $inclusive, limit: $limit, cursor: $cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve information about a conversation.
#
# GET /conversations.info
# Docs: https://api.slack.com/methods/conversations.info — API method documentation
# Returns: record<channel: list<any>, ok: bool>
# operationId: conversations_info
export def "conversations-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `conversations:read` (spec name: token)
  --channel: string # Conversation ID to learn more about
  --include-locale: oneof<nothing, bool> # Set this to `true` to receive the locale for this conversation. Defaults to `false`
  --include-num-members: oneof<nothing, bool> # Set to `true` to include the member count for the specified conversation. Defaults to `false`
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/conversations.info"
    query: [{name: token, var: qp_token}, {name: channel, var: channel}, {name: include_locale, var: include_locale}, {name: include_num_members, var: include_num_members}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, channel: $channel, include_locale: $include_locale, include_num_members: $include_num_members
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invites users to a channel.
#
# POST /conversations.invite
# Docs: https://api.slack.com/methods/conversations.invite — API method documentation
# Returns: record<channel: list<any>, ok: bool>
# operationId: conversations_invite
export def "conversations-invite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `conversations:write` (spec name: token)
  --channel: string # The ID of the public or private channel to invite user(s) to.
  --users: string # A comma separated list of user IDs. Up to 1000 users may be listed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conversations.invite"
    header: [{name: token, var: hdr_token}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel, var: channel}, {name: users, var: users}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel: $channel, users: $users
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Joins an existing conversation.
#
# POST /conversations.join
# Docs: https://api.slack.com/methods/conversations.join — API method documentation
# Returns: record<channel: list<any>, ok: bool, response_metadata: record<warnings: list<string>>, warning: string>
# operationId: conversations_join
export def "conversations-join" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `channels:write` (spec name: token)
  --channel: string # ID of conversation to join
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conversations.join"
    header: [{name: token, var: hdr_token}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel, var: channel}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel: $channel
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a user from a conversation.
#
# POST /conversations.kick
# Docs: https://api.slack.com/methods/conversations.kick — API method documentation
# Returns: record<ok: bool>
# operationId: conversations_kick
export def "conversations-kick" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `conversations:write` (spec name: token)
  --channel: string # ID of conversation to remove user from.
  --user: string # User ID to be removed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conversations.kick"
    header: [{name: token, var: hdr_token}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel, var: channel}, {name: user, var: user}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel: $channel, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Leaves a conversation.
#
# POST /conversations.leave
# Docs: https://api.slack.com/methods/conversations.leave — API method documentation
# Returns: record<not_in_channel: bool, ok: bool>
# operationId: conversations_leave
export def "conversations-leave" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `conversations:write` (spec name: token)
  --channel: string # Conversation to leave
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conversations.leave"
    header: [{name: token, var: hdr_token}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel, var: channel}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel: $channel
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all channels in a Slack team.
#
# GET /conversations.list
# Docs: https://api.slack.com/methods/conversations.list — API method documentation
# Returns: record<channels: list<list<any>>, ok: bool, response_metadata: record<next_cursor: string>>
# operationId: conversations_list
export def "conversations-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `conversations:read` (spec name: token)
  --exclude-archived: oneof<nothing, bool> # Set to `true` to exclude archived channels from the list
  --types: string # Mix and match channel types by providing a comma-separated list of any combination of `public_channel`, `private_channel`, `mpim`, `im`
  --limit: int # The maximum number of items to return. Fewer than the requested number of items may be returned, even if the end of the list hasn't been reached. Must be an integer no larger than 1000.
  --cursor: string # Paginate through collections of data by setting the `cursor` parameter to a `next_cursor` attribute returned by a previous request's `response_metadata`. Default value fetches the first "page" of the collection. See [pagination](/docs/pagination) for more detail.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/conversations.list"
    query: [{name: token, var: qp_token}, {name: exclude_archived, var: exclude_archived}, {name: types, var: types}, {name: limit, var: limit}, {name: cursor, var: cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, exclude_archived: $exclude_archived, types: $types, limit: $limit, cursor: $cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the read cursor in a channel.
#
# POST /conversations.mark
# Docs: https://api.slack.com/methods/conversations.mark — API method documentation
# Returns: record<ok: bool>
# operationId: conversations_mark
export def "conversations-mark" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `conversations:write` (spec name: token)
  --channel: string # Channel or conversation to set the read cursor for.
  --ts: float # Unique identifier of message you want marked as most recently seen in this conversation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conversations.mark"
    header: [{name: token, var: hdr_token}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel, var: channel}, {name: ts, var: ts}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel: $channel, ts: $ts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve members of a conversation.
#
# GET /conversations.members
# Docs: https://api.slack.com/methods/conversations.members — API method documentation
# Returns: record<members: list<string>, ok: bool, response_metadata: record<next_cursor: string>>
# operationId: conversations_members
export def "conversations-members" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `conversations:read` (spec name: token)
  --channel: string # ID of the conversation to retrieve members for
  --limit: int # The maximum number of items to return. Fewer than the requested number of items may be returned, even if the end of the users list hasn't been reached.
  --cursor: string # Paginate through collections of data by setting the `cursor` parameter to a `next_cursor` attribute returned by a previous request's `response_metadata`. Default value fetches the first "page" of the collection. See [pagination](/docs/pagination) for more detail.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/conversations.members"
    query: [{name: token, var: qp_token}, {name: channel, var: channel}, {name: limit, var: limit}, {name: cursor, var: cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, channel: $channel, limit: $limit, cursor: $cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Opens or resumes a direct message or multi-person direct message.
#
# POST /conversations.open
# Docs: https://api.slack.com/methods/conversations.open — API method documentation
# Returns: record<already_open: bool, channel: list<any>, no_op: bool, ok: bool>
# operationId: conversations_open
export def "conversations-open" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `conversations:write` (spec name: token)
  --channel: string # Resume a conversation by supplying an `im` or `mpim`'s ID. Or provide the `users` field instead.
  --return-im: oneof<nothing, bool> # Boolean, indicates you want the full IM channel definition in the response.
  --users: string # Comma separated lists of users. If only one user is included, this creates a 1:1 DM. The ordering of the users is preserved whenever a multi-person direct message is returned. Supply a `channel` when not supplying `users`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conversations.open"
    header: [{name: token, var: hdr_token}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel, var: channel}, {name: return_im, var: return_im}, {name: users, var: users}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel: $channel, return_im: $return_im, users: $users
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Renames a conversation.
#
# POST /conversations.rename
# Docs: https://api.slack.com/methods/conversations.rename — API method documentation
# Returns: record<channel: list<any>, ok: bool>
# operationId: conversations_rename
export def "conversations-rename" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `conversations:write` (spec name: token)
  --channel: string # ID of conversation to rename
  --name: string # New name for conversation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conversations.rename"
    header: [{name: token, var: hdr_token}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel, var: channel}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel: $channel, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a thread of messages posted to a conversation
#
# GET /conversations.replies
# Docs: https://api.slack.com/methods/conversations.replies — API method documentation
# Returns: record<has_more: bool, messages: list<list<any>>, ok: bool>
# operationId: conversations_replies
export def "conversations-replies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `conversations:history` (spec name: token)
  --channel: string # Conversation ID to fetch thread from.
  --ts: float # Unique identifier of a thread's parent message. `ts` must be the timestamp of an existing message with 0 or more replies. If there are no replies then just the single message referenced by `ts` will return - it is just an ordinary, unthreaded message.
  --latest: float # End of time range of messages to include in results.
  --oldest: float # Start of time range of messages to include in results.
  --inclusive: oneof<nothing, bool> # Include messages with latest or oldest timestamp in results only when either timestamp is specified.
  --limit: int # The maximum number of items to return. Fewer than the requested number of items may be returned, even if the end of the users list hasn't been reached.
  --cursor: string # Paginate through collections of data by setting the `cursor` parameter to a `next_cursor` attribute returned by a previous request's `response_metadata`. Default value fetches the first "page" of the collection. See [pagination](/docs/pagination) for more detail.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/conversations.replies"
    query: [{name: token, var: qp_token}, {name: channel, var: channel}, {name: ts, var: ts}, {name: latest, var: latest}, {name: oldest, var: oldest}, {name: inclusive, var: inclusive}, {name: limit, var: limit}, {name: cursor, var: cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, channel: $channel, ts: $ts, latest: $latest, oldest: $oldest, inclusive: $inclusive, limit: $limit, cursor: $cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the purpose for a conversation.
#
# POST /conversations.setPurpose
# Docs: https://api.slack.com/methods/conversations.setPurpose — API method documentation
# Returns: record<channel: list<any>, ok: bool>
# operationId: conversations_setPurpose
export def "conversations-set-purpose" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `conversations:write` (spec name: token)
  --channel: string # Conversation to set the purpose of
  --purpose: string # A new, specialer purpose
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conversations.setPurpose"
    header: [{name: token, var: hdr_token}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel, var: channel}, {name: purpose, var: purpose}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel: $channel, purpose: $purpose
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the topic for a conversation.
#
# POST /conversations.setTopic
# Docs: https://api.slack.com/methods/conversations.setTopic — API method documentation
# Returns: record<channel: list<any>, ok: bool>
# operationId: conversations_setTopic
export def "conversations-set-topic" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `conversations:write` (spec name: token)
  --channel: string # Conversation to set the topic of
  --topic: string # The new topic string. Does not support formatting or linkification.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conversations.setTopic"
    header: [{name: token, var: hdr_token}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel, var: channel}, {name: topic, var: topic}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel: $channel, topic: $topic
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reverses conversation archival.
#
# POST /conversations.unarchive
# Docs: https://api.slack.com/methods/conversations.unarchive — API method documentation
# Returns: record<ok: bool>
# operationId: conversations_unarchive
export def "conversations-unarchive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `conversations:write` (spec name: token)
  --channel: string # ID of conversation to unarchive
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conversations.unarchive"
    header: [{name: token, var: hdr_token}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel, var: channel}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel: $channel
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Open a dialog with a user
#
# GET /dialog.open
# Docs: https://api.slack.com/methods/dialog.open — API method documentation
# Returns: record<ok: bool>
# operationId: dialog_open
export def "dialog-open" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dialog: string # The dialog definition. This must be a JSON-encoded string. (required)
  --trigger-id: string # Exchange a trigger to post to the user. (required)
  --hdr-token: string # Authentication token. Requires scope: `none` (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dialog.open"
    query: [{name: dialog, var: dialog, required: true}, {name: trigger_id, var: trigger_id, required: true}]
    header: [{name: token, var: hdr_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dialog: $dialog, trigger_id: $trigger_id, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ends the current user's Do Not Disturb session immediately.
#
# POST /dnd.endDnd
# Docs: https://api.slack.com/methods/dnd.endDnd — API method documentation
# Returns: record<ok: bool>
# operationId: dnd_endDnd
export def "dnd-end-dnd" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `dnd:write` (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/dnd.endDnd"
    header: [{name: token, var: hdr_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ends the current user's snooze mode immediately.
#
# POST /dnd.endSnooze
# Docs: https://api.slack.com/methods/dnd.endSnooze — API method documentation
# Returns: record<dnd_enabled: bool, next_dnd_end_ts: int, next_dnd_start_ts: int, ok: bool, snooze_enabled: bool>
# operationId: dnd_endSnooze
export def "dnd-end-snooze" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `dnd:write` (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/dnd.endSnooze"
    header: [{name: token, var: hdr_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a user's current Do Not Disturb status.
#
# GET /dnd.info
# Docs: https://api.slack.com/methods/dnd.info — API method documentation
# Returns: record<dnd_enabled: bool, next_dnd_end_ts: int, next_dnd_start_ts: int, ok: bool, snooze_enabled: bool, snooze_endtime: int, snooze_remaining: int>
# operationId: dnd_info
export def "dnd-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `dnd:read` (spec name: token)
  --user: string # User to fetch status for (defaults to current user)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dnd.info"
    query: [{name: token, var: qp_token}, {name: user, var: user}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Turns on Do Not Disturb mode for the current user, or changes its duration.
#
# POST /dnd.setSnooze
# Docs: https://api.slack.com/methods/dnd.setSnooze — API method documentation
# Returns: record<ok: bool, snooze_enabled: bool, snooze_endtime: int, snooze_remaining: int>
# operationId: dnd_setSnooze
export def "dnd-set-snooze" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  num_minutes: string # Number of minutes, from now, to snooze until.
  --body-token: string # Authentication token. Requires scope: `dnd:write` (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dnd.setSnooze"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: num_minutes, var: num_minutes}, {name: token, var: body_token, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    num_minutes: $num_minutes, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the Do Not Disturb status for up to 50 users on a team.
#
# GET /dnd.teamInfo
# Docs: https://api.slack.com/methods/dnd.teamInfo — API method documentation
# Returns: record<ok: bool>
# operationId: dnd_teamInfo
export def "dnd-team-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `dnd:read` (spec name: token)
  --users: string # Comma-separated list of users to fetch Do Not Disturb status for
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dnd.teamInfo"
    query: [{name: token, var: qp_token}, {name: users, var: users}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, users: $users
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists custom emoji for a team.
#
# GET /emoji.list
# Docs: https://api.slack.com/methods/emoji.list — API method documentation
# Returns: record<ok: bool>
# operationId: emoji_list
export def "emoji-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `emoji:read` (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/emoji.list"
    query: [{name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing comment on a file.
#
# POST /files.comments.delete
# Docs: https://api.slack.com/methods/files.comments.delete — API method documentation
# Returns: record<ok: bool>
# operationId: files_comments_delete
export def "files-comments-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `files:write:user` (spec name: token)
  --file: string # File to delete a comment from.
  --id: string # The comment to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files.comments.delete"
    header: [{name: token, var: hdr_token}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: file, var: file}, {name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, file: $file, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a file.
#
# POST /files.delete
# Docs: https://api.slack.com/methods/files.delete — API method documentation
# Returns: record<ok: bool>
# operationId: files_delete
export def "files-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `files:write:user` (spec name: token)
  --file: string # ID of file to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files.delete"
    header: [{name: token, var: hdr_token}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: file, var: file}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a file.
#
# GET /files.info
# Docs: https://api.slack.com/methods/files.info — API method documentation
# Returns: record<comments: list<any>, content_html: any, editor: string, file: record<channels: list<string>, comments_count: int, created: int, date_delete: int, display_as_bot: bool, editable: bool, editor: string, external_id: string, external_type: string, external_url: string, filetype: string, groups: list<string>, has_rich_preview: bool, id: string, image_exif_rotation: int, ims: list<string>, is_external: bool, is_public: bool, is_starred: bool, is_tombstoned: bool, last_editor: string, mimetype: string, mode: string, name: string, non_owner_editable: bool, num_stars: int, original_h: int, original_w: int, permalink: string, permalink_public: string, pinned_info: record, pinned_to: list<string>, pretty_type: string, preview: string, public_url_shared: bool, reactions: list<record>, shares: record<private: any, public: any>, size: int, source_team: string, state: string, thumb_1024: string, thumb_1024_h: int, thumb_1024_w: int, thumb_160: string, thumb_360: string, thumb_360_h: int, thumb_360_w: int, thumb_480: string, thumb_480_h: int, thumb_480_w: int, thumb_64: string, thumb_720: string, thumb_720_h: int, thumb_720_w: int, thumb_80: string, thumb_800: string, thumb_800_h: int, thumb_800_w: int, thumb_960: string, thumb_960_h: int, thumb_960_w: int, thumb_tiny: string, timestamp: int, title: string, updated: int, url_private: string, url_private_download: string, user: string, user_team: string, username: string>, ok: bool, paging: record<count: int, page: int, pages: int, per_page: int, spill: int, total: int>, response_metadata: list<any>>
# operationId: files_info
export def "files-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `files:read` (spec name: token)
  --file: string # Specify a file by providing its ID.
  --count: string
  --page: string
  --limit: int # The maximum number of items to return. Fewer than the requested number of items may be returned, even if the end of the list hasn't been reached.
  --cursor: string # Parameter for pagination. File comments are paginated for a single file. Set `cursor` equal to the `next_cursor` attribute returned by the previous request's `response_metadata`. This parameter is optional, but pagination is mandatory: the default value simply fetches the first "page" of the collection of comments. See [pagination](/docs/pagination) for more details.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files.info"
    query: [{name: token, var: qp_token}, {name: file, var: file}, {name: count, var: count}, {name: page, var: page}, {name: limit, var: limit}, {name: cursor, var: cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, file: $file, count: $count, page: $page, limit: $limit, cursor: $cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List for a team, in a channel, or from a user with applied filters.
#
# GET /files.list
# Docs: https://api.slack.com/methods/files.list — API method documentation
# Returns: record<files: table<channels: list, comments_count: int, created: int, date_delete: int, display_as_bot: bool, editable: bool, editor: string, external_id: string, external_type: string, external_url: string, filetype: string, groups: list, has_rich_preview: bool, id: string, image_exif_rotation: int, ims: list, is_external: bool, is_public: bool, is_starred: bool, is_tombstoned: bool, last_editor: string, mimetype: string, mode: string, name: string, non_owner_editable: bool, num_stars: int, original_h: int, original_w: int, permalink: string, permalink_public: string, pinned_info: record, pinned_to: list, pretty_type: string, preview: string, public_url_shared: bool, reactions: list, shares: record, size: int, source_team: string, state: string, thumb_1024: string, thumb_1024_h: int, thumb_1024_w: int, thumb_160: string, thumb_360: string, thumb_360_h: int, thumb_360_w: int, thumb_480: string, thumb_480_h: int, thumb_480_w: int, thumb_64: string, thumb_720: string, thumb_720_h: int, thumb_720_w: int, thumb_80: string, thumb_800: string, thumb_800_h: int, thumb_800_w: int, thumb_960: string, thumb_960_h: int, thumb_960_w: int, thumb_tiny: string, timestamp: int, title: string, updated: int, url_private: string, url_private_download: string, user: string, user_team: string, username: string>, ok: bool, paging: record<count: int, page: int, pages: int, per_page: int, spill: int, total: int>>
# operationId: files_list
export def "files-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `files:read` (spec name: token)
  --user: string # Filter files created by a single user.
  --channel: string # Filter files appearing in a specific channel, indicated by its ID.
  --ts-from: float # Filter files created after this timestamp (inclusive).
  --ts-to: float # Filter files created before this timestamp (inclusive).
  --types: string # Filter files by type ([see below](#file_types)). You can pass multiple values in the types argument, like `types=spaces,snippets`.The default value is `all`, which does not filter the list.
  --count: string
  --page: string
  --show-files-hidden-by-limit: oneof<nothing, bool> # Show truncated file info for files hidden due to being too old, and the team who owns the file being over the file limit.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files.list"
    query: [{name: token, var: qp_token}, {name: user, var: user}, {name: channel, var: channel}, {name: ts_from, var: ts_from}, {name: ts_to, var: ts_to}, {name: types, var: types}, {name: count, var: count}, {name: page, var: page}, {name: show_files_hidden_by_limit, var: show_files_hidden_by_limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, user: $user, channel: $channel, ts_from: $ts_from, ts_to: $ts_to, types: $types, count: $count, page: $page, show_files_hidden_by_limit: $show_files_hidden_by_limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a file from a remote service
#
# POST /files.remote.add
# Docs: https://api.slack.com/methods/files.remote.add — API method documentation
# Returns: record<ok: bool>
# operationId: files_remote_add
export def "files-remote-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-id: string # Creator defined GUID for the file.
  --external-url: string # URL of the remote file.
  --filetype: string # type of file
  --indexable-file-contents: string # A text file (txt, pdf, doc, etc.) containing textual search terms that are used to improve discovery of the remote file.
  --preview-image: string # Preview of the document via `multipart/form-data`.
  --title: string # Title of the file being shared.
  --body-token: string # Authentication token. Requires scope: `remote_files:write` (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files.remote.add"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: external_id, var: external_id}, {name: external_url, var: external_url}, {name: filetype, var: filetype}, {name: indexable_file_contents, var: indexable_file_contents}, {name: preview_image, var: preview_image}, {name: title, var: title}, {name: token, var: body_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    external_id: $external_id, external_url: $external_url, filetype: $filetype, indexable_file_contents: $indexable_file_contents, preview_image: $preview_image, title: $title, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve information about a remote file added to Slack
#
# GET /files.remote.info
# Docs: https://api.slack.com/methods/files.remote.info — API method documentation
# Returns: record<ok: bool>
# operationId: files_remote_info
export def "files-remote-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `remote_files:read` (spec name: token)
  --file: string # Specify a file by providing its ID.
  --external-id: string # Creator defined GUID for the file.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files.remote.info"
    query: [{name: token, var: qp_token}, {name: file, var: file}, {name: external_id, var: external_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, file: $file, external_id: $external_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve information about a remote file added to Slack
#
# GET /files.remote.list
# Docs: https://api.slack.com/methods/files.remote.list — API method documentation
# Returns: record<ok: bool>
# operationId: files_remote_list
export def "files-remote-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `remote_files:read` (spec name: token)
  --channel: string # Filter files appearing in a specific channel, indicated by its ID.
  --ts-from: float # Filter files created after this timestamp (inclusive).
  --ts-to: float # Filter files created before this timestamp (inclusive).
  --limit: int # The maximum number of items to return.
  --cursor: string # Paginate through collections of data by setting the `cursor` parameter to a `next_cursor` attribute returned by a previous request's `response_metadata`. Default value fetches the first "page" of the collection. See [pagination](/docs/pagination) for more detail.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files.remote.list"
    query: [{name: token, var: qp_token}, {name: channel, var: channel}, {name: ts_from, var: ts_from}, {name: ts_to, var: ts_to}, {name: limit, var: limit}, {name: cursor, var: cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, channel: $channel, ts_from: $ts_from, ts_to: $ts_to, limit: $limit, cursor: $cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a remote file.
#
# POST /files.remote.remove
# Docs: https://api.slack.com/methods/files.remote.remove — API method documentation
# Returns: record<ok: bool>
# operationId: files_remote_remove
export def "files-remote-remove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-id: string # Creator defined GUID for the file.
  --file: string # Specify a file by providing its ID.
  --body-token: string # Authentication token. Requires scope: `remote_files:write` (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files.remote.remove"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: external_id, var: external_id}, {name: file, var: file}, {name: token, var: body_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    external_id: $external_id, file: $file, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Share a remote file into a channel.
#
# GET /files.remote.share
# Docs: https://api.slack.com/methods/files.remote.share — API method documentation
# Returns: record<ok: bool>
# operationId: files_remote_share
export def "files-remote-share" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `remote_files:share` (spec name: token)
  --file: string # Specify a file registered with Slack by providing its ID. Either this field or `external_id` or both are required.
  --external-id: string # The globally unique identifier (GUID) for the file, as set by the app registering the file with Slack. Either this field or `file` or both are required.
  --channels: string # Comma-separated list of channel IDs where the file will be shared.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files.remote.share"
    query: [{name: token, var: qp_token}, {name: file, var: file}, {name: external_id, var: external_id}, {name: channels, var: channels}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, file: $file, external_id: $external_id, channels: $channels
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing remote file.
#
# POST /files.remote.update
# Docs: https://api.slack.com/methods/files.remote.update — API method documentation
# Returns: record<ok: bool>
# operationId: files_remote_update
export def "files-remote-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-id: string # Creator defined GUID for the file.
  --external-url: string # URL of the remote file.
  --file: string # Specify a file by providing its ID.
  --filetype: string # type of file
  --indexable-file-contents: string # File containing contents that can be used to improve searchability for the remote file.
  --preview-image: string # Preview of the document via `multipart/form-data`.
  --title: string # Title of the file being shared.
  --body-token: string # Authentication token. Requires scope: `remote_files:write` (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files.remote.update"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: external_id, var: external_id}, {name: external_url, var: external_url}, {name: file, var: file}, {name: filetype, var: filetype}, {name: indexable_file_contents, var: indexable_file_contents}, {name: preview_image, var: preview_image}, {name: title, var: title}, {name: token, var: body_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    external_id: $external_id, external_url: $external_url, file: $file, filetype: $filetype, indexable_file_contents: $indexable_file_contents, preview_image: $preview_image, title: $title, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Revokes public/external sharing access for a file
#
# POST /files.revokePublicURL
# Docs: https://api.slack.com/methods/files.revokePublicURL — API method documentation
# Returns: record<file: record<channels: list<string>, comments_count: int, created: int, date_delete: int, display_as_bot: bool, editable: bool, editor: string, external_id: string, external_type: string, external_url: string, filetype: string, groups: list<string>, has_rich_preview: bool, id: string, image_exif_rotation: int, ims: list<string>, is_external: bool, is_public: bool, is_starred: bool, is_tombstoned: bool, last_editor: string, mimetype: string, mode: string, name: string, non_owner_editable: bool, num_stars: int, original_h: int, original_w: int, permalink: string, permalink_public: string, pinned_info: record, pinned_to: list<string>, pretty_type: string, preview: string, public_url_shared: bool, reactions: list<record>, shares: record<private: any, public: any>, size: int, source_team: string, state: string, thumb_1024: string, thumb_1024_h: int, thumb_1024_w: int, thumb_160: string, thumb_360: string, thumb_360_h: int, thumb_360_w: int, thumb_480: string, thumb_480_h: int, thumb_480_w: int, thumb_64: string, thumb_720: string, thumb_720_h: int, thumb_720_w: int, thumb_80: string, thumb_800: string, thumb_800_h: int, thumb_800_w: int, thumb_960: string, thumb_960_h: int, thumb_960_w: int, thumb_tiny: string, timestamp: int, title: string, updated: int, url_private: string, url_private_download: string, user: string, user_team: string, username: string>, ok: bool>
# operationId: files_revokePublicURL
export def "files-revoke-public-url" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `files:write:user` (spec name: token)
  --file: string # File to revoke
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files.revokePublicURL"
    header: [{name: token, var: hdr_token}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: file, var: file}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables a file for public/external sharing.
#
# POST /files.sharedPublicURL
# Docs: https://api.slack.com/methods/files.sharedPublicURL — API method documentation
# Returns: record<file: record<channels: list<string>, comments_count: int, created: int, date_delete: int, display_as_bot: bool, editable: bool, editor: string, external_id: string, external_type: string, external_url: string, filetype: string, groups: list<string>, has_rich_preview: bool, id: string, image_exif_rotation: int, ims: list<string>, is_external: bool, is_public: bool, is_starred: bool, is_tombstoned: bool, last_editor: string, mimetype: string, mode: string, name: string, non_owner_editable: bool, num_stars: int, original_h: int, original_w: int, permalink: string, permalink_public: string, pinned_info: record, pinned_to: list<string>, pretty_type: string, preview: string, public_url_shared: bool, reactions: list<record>, shares: record<private: any, public: any>, size: int, source_team: string, state: string, thumb_1024: string, thumb_1024_h: int, thumb_1024_w: int, thumb_160: string, thumb_360: string, thumb_360_h: int, thumb_360_w: int, thumb_480: string, thumb_480_h: int, thumb_480_w: int, thumb_64: string, thumb_720: string, thumb_720_h: int, thumb_720_w: int, thumb_80: string, thumb_800: string, thumb_800_h: int, thumb_800_w: int, thumb_960: string, thumb_960_h: int, thumb_960_w: int, thumb_tiny: string, timestamp: int, title: string, updated: int, url_private: string, url_private_download: string, user: string, user_team: string, username: string>, ok: bool>
# operationId: files_sharedPublicURL
export def "files-shared-public-url" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `files:write:user` (spec name: token)
  --file: string # File to share
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files.sharedPublicURL"
    header: [{name: token, var: hdr_token}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: file, var: file}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uploads or creates a file.
#
# POST /files.upload
# Docs: https://api.slack.com/methods/files.upload — API method documentation
# Returns: record<file: record<channels: list<string>, comments_count: int, created: int, date_delete: int, display_as_bot: bool, editable: bool, editor: string, external_id: string, external_type: string, external_url: string, filetype: string, groups: list<string>, has_rich_preview: bool, id: string, image_exif_rotation: int, ims: list<string>, is_external: bool, is_public: bool, is_starred: bool, is_tombstoned: bool, last_editor: string, mimetype: string, mode: string, name: string, non_owner_editable: bool, num_stars: int, original_h: int, original_w: int, permalink: string, permalink_public: string, pinned_info: record, pinned_to: list<string>, pretty_type: string, preview: string, public_url_shared: bool, reactions: list<record>, shares: record<private: any, public: any>, size: int, source_team: string, state: string, thumb_1024: string, thumb_1024_h: int, thumb_1024_w: int, thumb_160: string, thumb_360: string, thumb_360_h: int, thumb_360_w: int, thumb_480: string, thumb_480_h: int, thumb_480_w: int, thumb_64: string, thumb_720: string, thumb_720_h: int, thumb_720_w: int, thumb_80: string, thumb_800: string, thumb_800_h: int, thumb_800_w: int, thumb_960: string, thumb_960_h: int, thumb_960_w: int, thumb_tiny: string, timestamp: int, title: string, updated: int, url_private: string, url_private_download: string, user: string, user_team: string, username: string>, ok: bool>
# operationId: files_upload
export def "files-upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --channels: string # Comma-separated list of channel names or IDs where the file will be shared.
  --content: string # File contents via a POST variable. If omitting this parameter, you must provide a `file`.
  --file: string # File contents via `multipart/form-data`. If omitting this parameter, you must submit `content`.
  --filename: string # Filename of file.
  --filetype: string # A [file type](/types/file#file_types) identifier.
  --initial-comment: string # The message text introducing the file in specified `channels`.
  --thread-ts: float # Provide another message's `ts` value to upload this file as a reply. Never use a reply's `ts` value; use its parent instead.
  --title: string # Title of file.
  --body-token: string # Authentication token. Requires scope: `files:write:user` (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files.upload"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channels, var: channels}, {name: content, var: content}, {name: file, var: file}, {name: filename, var: filename}, {name: filetype, var: filetype}, {name: initial_comment, var: initial_comment}, {name: thread_ts, var: thread_ts}, {name: title, var: title}, {name: token, var: body_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channels: $channels, content: $content, file: $file, filename: $filename, filetype: $filetype, initial_comment: $initial_comment, thread_ts: $thread_ts, title: $title, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# For Enterprise Grid workspaces, map local user IDs to global user IDs
#
# GET /migration.exchange
# Docs: https://api.slack.com/methods/migration.exchange — API method documentation
# Returns: record<enterprise_id: string, invalid_user_ids: list<string>, ok: bool, team_id: string, user_id_map: record>
# operationId: migration_exchange
export def "migration-exchange" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `tokens.basic` (required) (spec name: token)
  --users: string # A comma-separated list of user ids, up to 400 per request (required)
  --team-id: string # Specify team_id starts with `T` in case of Org Token
  --to-old: oneof<nothing, bool> # Specify `true` to convert `W` global user IDs to workspace-specific `U` IDs. Defaults to `false`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/migration.exchange"
    query: [{name: token, var: qp_token, required: true}, {name: users, var: users, required: true}, {name: team_id, var: team_id}, {name: to_old, var: to_old}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, users: $users, team_id: $team_id, to_old: $to_old
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exchanges a temporary OAuth verifier code for an access token.
#
# GET /oauth.access
# Docs: https://api.slack.com/methods/oauth.access — API method documentation
# Returns: record<ok: bool>
# operationId: oauth_access
export def "oauth-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Issued when you created your application.
  --client-secret: string # Issued when you created your application.
  --code: string # The `code` param returned via the OAuth callback.
  --redirect-uri: string # This must match the originally submitted URI (if one was sent).
  --single-channel: oneof<nothing, bool> # Request the user to add your app only to a single channel. Only valid with a [legacy workspace app](https://api.slack.com/legacy-workspace-apps).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/oauth.access"
    query: [{name: client_id, var: client_id}, {name: client_secret, var: client_secret}, {name: code, var: code}, {name: redirect_uri, var: redirect_uri}, {name: single_channel, var: single_channel}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, client_secret: $client_secret, code: $code, redirect_uri: $redirect_uri, single_channel: $single_channel
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exchanges a temporary OAuth verifier code for a workspace token.
#
# GET /oauth.token
# Docs: https://api.slack.com/methods/oauth.token — API method documentation
# Returns: record<ok: bool>
# operationId: oauth_token
export def "oauth-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Issued when you created your application.
  --client-secret: string # Issued when you created your application.
  --code: string # The `code` param returned via the OAuth callback.
  --redirect-uri: string # This must match the originally submitted URI (if one was sent).
  --single-channel: oneof<nothing, bool> # Request the user to add your app only to a single channel.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/oauth.token"
    query: [{name: client_id, var: client_id}, {name: client_secret, var: client_secret}, {name: code, var: code}, {name: redirect_uri, var: redirect_uri}, {name: single_channel, var: single_channel}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, client_secret: $client_secret, code: $code, redirect_uri: $redirect_uri, single_channel: $single_channel
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exchanges a temporary OAuth verifier code for an access token.
#
# GET /oauth.v2.access
# Docs: https://api.slack.com/methods/oauth.v2.access — API method documentation
# Returns: record<ok: bool>
# operationId: oauth_v2_access
export def "oauth-v2-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Issued when you created your application.
  --client-secret: string # Issued when you created your application.
  --code: string # The `code` param returned via the OAuth callback. (required)
  --redirect-uri: string # This must match the originally submitted URI (if one was sent).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/oauth.v2.access"
    query: [{name: client_id, var: client_id}, {name: client_secret, var: client_secret}, {name: code, var: code, required: true}, {name: redirect_uri, var: redirect_uri}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, client_secret: $client_secret, code: $code, redirect_uri: $redirect_uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Pins an item to a channel.
#
# POST /pins.add
# Docs: https://api.slack.com/methods/pins.add — API method documentation
# Returns: record<ok: bool>
# operationId: pins_add
export def "pins-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `pins:write` (required) (spec name: token)
  channel: string # Channel to pin the item in.
  --timestamp: string # Timestamp of the message to pin.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/pins.add"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel, var: channel}, {name: timestamp, var: timestamp}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel: $channel, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists items pinned to a channel.
#
# GET /pins.list
# Docs: https://api.slack.com/methods/pins.list — API method documentation
# Returns: list<any>
# operationId: pins_list
export def "pins-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `pins:read` (required) (spec name: token)
  --channel: string # Channel to get pinned items for. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/pins.list"
    query: [{name: token, var: qp_token, required: true}, {name: channel, var: channel, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, channel: $channel
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Un-pins an item from a channel.
#
# POST /pins.remove
# Docs: https://api.slack.com/methods/pins.remove — API method documentation
# Returns: record<ok: bool>
# operationId: pins_remove
export def "pins-remove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `pins:write` (required) (spec name: token)
  channel: string # Channel where the item is pinned to.
  --timestamp: string # Timestamp of the message to un-pin.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/pins.remove"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel, var: channel}, {name: timestamp, var: timestamp}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel: $channel, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a reaction to an item.
#
# POST /reactions.add
# Docs: https://api.slack.com/methods/reactions.add — API method documentation
# Returns: record<ok: bool>
# operationId: reactions_add
export def "reactions-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `reactions:write` (required) (spec name: token)
  channel: string # Channel where the message to add reaction to was posted.
  name: string # Reaction (emoji) name.
  timestamp: string # Timestamp of the message to add reaction to.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/reactions.add"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel, var: channel}, {name: name, var: name}, {name: timestamp, var: timestamp}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel: $channel, name: $name, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets reactions for an item.
#
# GET /reactions.get
# Docs: https://api.slack.com/methods/reactions.get — API method documentation
# Returns: record
# operationId: reactions_get
export def "reactions-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `reactions:read` (required) (spec name: token)
  --channel: string # Channel where the message to get reactions for was posted.
  --file: string # File to get reactions for.
  --file-comment: string # File comment to get reactions for.
  --qp-full: oneof<nothing, bool> # If true always return the complete reaction list. (spec name: full)
  --timestamp: string # Timestamp of the message to get reactions for.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/reactions.get"
    query: [{name: token, var: qp_token, required: true}, {name: channel, var: channel}, {name: file, var: file}, {name: file_comment, var: file_comment}, {name: full, var: qp_full}, {name: timestamp, var: timestamp}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, channel: $channel, file: $file, file_comment: $file_comment, qp_full: $qp_full, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists reactions made by a user.
#
# GET /reactions.list
# Docs: https://api.slack.com/methods/reactions.list — API method documentation
# Returns: record<items: list<list<any>>, ok: bool, paging: record<count: int, page: int, pages: int, per_page: int, spill: int, total: int>, response_metadata: list<any>>
# operationId: reactions_list
export def "reactions-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `reactions:read` (required) (spec name: token)
  --user: string # Show reactions made by this user. Defaults to the authed user.
  --qp-full: oneof<nothing, bool> # If true always return the complete reaction list. (spec name: full)
  --count: int
  --page: int
  --cursor: string # Parameter for pagination. Set `cursor` equal to the `next_cursor` attribute returned by the previous request's `response_metadata`. This parameter is optional, but pagination is mandatory: the default value simply fetches the first "page" of the collection. See [pagination](/docs/pagination) for more details.
  --limit: int # The maximum number of items to return. Fewer than the requested number of items may be returned, even if the end of the list hasn't been reached.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/reactions.list"
    query: [{name: token, var: qp_token, required: true}, {name: user, var: user}, {name: full, var: qp_full}, {name: count, var: count}, {name: page, var: page}, {name: cursor, var: cursor}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, user: $user, qp_full: $qp_full, count: $count, page: $page, cursor: $cursor, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a reaction from an item.
#
# POST /reactions.remove
# Docs: https://api.slack.com/methods/reactions.remove — API method documentation
# Returns: record<ok: bool>
# operationId: reactions_remove
export def "reactions-remove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `reactions:write` (required) (spec name: token)
  --channel: string # Channel where the message to remove reaction from was posted.
  --file: string # File to remove reaction from.
  --file-comment: string # File comment to remove reaction from.
  name: string # Reaction (emoji) name.
  --timestamp: string # Timestamp of the message to remove reaction from.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/reactions.remove"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel, var: channel}, {name: file, var: file}, {name: file_comment, var: file_comment}, {name: name, var: name}, {name: timestamp, var: timestamp}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel: $channel, file: $file, file_comment: $file_comment, name: $name, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a reminder.
#
# POST /reminders.add
# Docs: https://api.slack.com/methods/reminders.add — API method documentation
# Returns: record<ok: bool, reminder: record<complete_ts: int, creator: string, id: string, recurring: bool, text: string, time: int, user: string>>
# operationId: reminders_add
export def "reminders-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `reminders:write` (required) (spec name: token)
  text: string # The content of the reminder
  time: string # When this reminder should happen: the Unix timestamp (up to five years from now), the number of seconds until the reminder (if within 24 hours), or a natural language description (Ex. "in 15 minutes," or "every Thursday")
  --user: string # The user who will receive the reminder. If no user is specified, the reminder will go to user who created it.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/reminders.add"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: text, var: text}, {name: time, var: time}, {name: user, var: user}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, text: $text, time: $time, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Marks a reminder as complete.
#
# POST /reminders.complete
# Docs: https://api.slack.com/methods/reminders.complete — API method documentation
# Returns: record<ok: bool>
# operationId: reminders_complete
export def "reminders-complete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `reminders:write` (spec name: token)
  --reminder: string # The ID of the reminder to be marked as complete
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/reminders.complete"
    header: [{name: token, var: hdr_token}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: reminder, var: reminder}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, reminder: $reminder
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a reminder.
#
# POST /reminders.delete
# Docs: https://api.slack.com/methods/reminders.delete — API method documentation
# Returns: record<ok: bool>
# operationId: reminders_delete
export def "reminders-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `reminders:write` (spec name: token)
  --reminder: string # The ID of the reminder
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/reminders.delete"
    header: [{name: token, var: hdr_token}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: reminder, var: reminder}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, reminder: $reminder
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a reminder.
#
# GET /reminders.info
# Docs: https://api.slack.com/methods/reminders.info — API method documentation
# Returns: record<ok: bool, reminder: record<complete_ts: int, creator: string, id: string, recurring: bool, text: string, time: int, user: string>>
# operationId: reminders_info
export def "reminders-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `reminders:read` (spec name: token)
  --reminder: string # The ID of the reminder
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/reminders.info"
    query: [{name: token, var: qp_token}, {name: reminder, var: reminder}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, reminder: $reminder
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all reminders created by or for a given user.
#
# GET /reminders.list
# Docs: https://api.slack.com/methods/reminders.list — API method documentation
# Returns: record<ok: bool, reminders: table<complete_ts: int, creator: string, id: string, recurring: bool, text: string, time: int, user: string>>
# operationId: reminders_list
export def "reminders-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `reminders:read` (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/reminders.list"
    query: [{name: token, var: qp_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a Real Time Messaging session.
#
# GET /rtm.connect
# Docs: https://api.slack.com/methods/rtm.connect — API method documentation
# Returns: record<ok: bool, self: record<id: string, name: string>, team: record<domain: string, id: string, name: string>, url: string>
# operationId: rtm_connect
export def "rtm-connect" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `rtm:stream` (required) (spec name: token)
  --batch-presence-aware: oneof<nothing, bool> # Batch presence deliveries via subscription. Enabling changes the shape of `presence_change` events. See [batch presence](/docs/presence-and-status#batching).
  --presence-sub: oneof<nothing, bool> # Only deliver presence events when requested by subscription. See [presence subscriptions](/docs/presence-and-status#subscriptions).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rtm.connect"
    query: [{name: token, var: qp_token, required: true}, {name: batch_presence_aware, var: batch_presence_aware}, {name: presence_sub, var: presence_sub}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, batch_presence_aware: $batch_presence_aware, presence_sub: $presence_sub
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Searches for messages matching a query.
#
# GET /search.messages
# Docs: https://api.slack.com/methods/search.messages — API method documentation
# Returns: record<ok: bool>
# operationId: search_messages
export def "search-messages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `search:read` (required) (spec name: token)
  --count: int # Pass the number of results you want per "page". Maximum of `100`.
  --highlight: oneof<nothing, bool> # Pass a value of `true` to enable query highlight markers (see below).
  --page: int
  --query: string # Search query. (required)
  --sort: string # Return matches sorted by either `score` or `timestamp`.
  --sort-dir: string # Change sort direction to ascending (`asc`) or descending (`desc`).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search.messages"
    query: [{name: token, var: qp_token, required: true}, {name: count, var: count}, {name: highlight, var: highlight}, {name: page, var: page}, {name: query, var: query, required: true}, {name: sort, var: sort}, {name: sort_dir, var: sort_dir}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, count: $count, highlight: $highlight, page: $page, query: $query, sort: $sort, sort_dir: $sort_dir
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a star to an item.
#
# POST /stars.add
# Docs: https://api.slack.com/methods/stars.add — API method documentation
# Returns: record<ok: bool>
# operationId: stars_add
export def "stars-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `stars:write` (required) (spec name: token)
  --channel: string # Channel to add star to, or channel where the message to add star to was posted (used with `timestamp`).
  --file: string # File to add star to.
  --file-comment: string # File comment to add star to.
  --timestamp: string # Timestamp of the message to add star to.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/stars.add"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel, var: channel}, {name: file, var: file}, {name: file_comment, var: file_comment}, {name: timestamp, var: timestamp}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel: $channel, file: $file, file_comment: $file_comment, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists stars for a user.
#
# GET /stars.list
# Docs: https://api.slack.com/methods/stars.list — API method documentation
# Returns: record<items: list<list<any>>, ok: bool, paging: record<count: int, page: int, pages: int, per_page: int, spill: int, total: int>>
# operationId: stars_list
export def "stars-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `stars:read` (spec name: token)
  --count: string
  --page: string
  --cursor: string # Parameter for pagination. Set `cursor` equal to the `next_cursor` attribute returned by the previous request's `response_metadata`. This parameter is optional, but pagination is mandatory: the default value simply fetches the first "page" of the collection. See [pagination](/docs/pagination) for more details.
  --limit: int # The maximum number of items to return. Fewer than the requested number of items may be returned, even if the end of the list hasn't been reached.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/stars.list"
    query: [{name: token, var: qp_token}, {name: count, var: count}, {name: page, var: page}, {name: cursor, var: cursor}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, count: $count, page: $page, cursor: $cursor, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a star from an item.
#
# POST /stars.remove
# Docs: https://api.slack.com/methods/stars.remove — API method documentation
# Returns: record<ok: bool>
# operationId: stars_remove
export def "stars-remove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `stars:write` (required) (spec name: token)
  --channel: string # Channel to remove star from, or channel where the message to remove star from was posted (used with `timestamp`).
  --file: string # File to remove star from.
  --file-comment: string # File comment to remove star from.
  --timestamp: string # Timestamp of the message to remove star from.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/stars.remove"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channel, var: channel}, {name: file, var: file}, {name: file_comment, var: file_comment}, {name: timestamp, var: timestamp}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channel: $channel, file: $file, file_comment: $file_comment, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the access logs for the current team.
#
# GET /team.accessLogs
# Docs: https://api.slack.com/methods/team.accessLogs — API method documentation
# Returns: record<logins: table<count: int, country: string, date_first: int, date_last: int, ip: string, isp: string, region: string, user_agent: string, user_id: string, username: string>, ok: bool, paging: record<count: int, page: int, pages: int, per_page: int, spill: int, total: int>>
# operationId: team_accessLogs
export def "team-access-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `admin` (required) (spec name: token)
  --before: string # End of time range of logs to include in results (inclusive).
  --count: string
  --page: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/team.accessLogs"
    query: [{name: token, var: qp_token, required: true}, {name: before, var: before}, {name: count, var: count}, {name: page, var: page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, before: $before, count: $count, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets billable users information for the current team.
#
# GET /team.billableInfo
# Docs: https://api.slack.com/methods/team.billableInfo — API method documentation
# Returns: record<ok: bool>
# operationId: team_billableInfo
export def "team-billable-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `admin` (required) (spec name: token)
  --user: string # A user to retrieve the billable information for. Defaults to all users.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/team.billableInfo"
    query: [{name: token, var: qp_token, required: true}, {name: user, var: user}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the current team.
#
# GET /team.info
# Docs: https://api.slack.com/methods/team.info — API method documentation
# Returns: record<ok: bool, team: record<archived: bool, avatar_base_url: string, created: int, date_create: int, deleted: bool, description: string, discoverable: list<any>, domain: string, email_domain: string, enterprise_id: string, enterprise_name: string, external_org_migrations: record<current: list, date_updated: int>, has_compliance_export: bool, icon: record<image_102: string, image_132: string, image_230: string, image_34: string, image_44: string, image_68: string, image_88: string, image_default: bool>, id: string, is_assigned: bool, is_enterprise: int, is_over_storage_limit: bool, limit_ts: int, locale: string, messages_count: int, msg_edit_window_mins: int, name: string, over_integrations_limit: bool, over_storage_limit: bool, pay_prod_cur: string, plan: string, primary_owner: record<email: string, id: string>, sso_provider: record<label: string, name: string, type: string>>>
# operationId: team_info
export def "team-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `team:read` (required) (spec name: token)
  --team: string # Team to get info on, if omitted, will return information about the current team. Will only return team that the authenticated token is allowed to see through external shared channels
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/team.info"
    query: [{name: token, var: qp_token, required: true}, {name: team, var: team}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, team: $team
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the integration logs for the current team.
#
# GET /team.integrationLogs
# Docs: https://api.slack.com/methods/team.integrationLogs — API method documentation
# Returns: record<logs: table<admin_app_id: string, app_id: string, app_type: string, change_type: string, channel: string, date: string, scope: string, service_id: string, service_type: string, user_id: string, user_name: string>, ok: bool, paging: record<count: int, page: int, pages: int, per_page: int, spill: int, total: int>>
# operationId: team_integrationLogs
export def "team-integration-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `admin` (required) (spec name: token)
  --app-id: string # Filter logs to this Slack app. Defaults to all logs.
  --change-type: string # Filter logs with this change type. Defaults to all logs.
  --count: string
  --page: string
  --service-id: string # Filter logs to this service. Defaults to all logs.
  --user: string # Filter logs generated by this user’s actions. Defaults to all logs.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/team.integrationLogs"
    query: [{name: token, var: qp_token, required: true}, {name: app_id, var: app_id}, {name: change_type, var: change_type}, {name: count, var: count}, {name: page, var: page}, {name: service_id, var: service_id}, {name: user, var: user}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, app_id: $app_id, change_type: $change_type, count: $count, page: $page, service_id: $service_id, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a team's profile.
#
# GET /team.profile.get
# Docs: https://api.slack.com/methods/team.profile.get — API method documentation
# Returns: record<ok: bool, profile: record<fields: list<record>>>
# operationId: team_profile_get
export def "team-profile-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `users.profile:read` (required) (spec name: token)
  --visibility: string # Filter by visibility.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/team.profile.get"
    query: [{name: token, var: qp_token, required: true}, {name: visibility, var: visibility}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, visibility: $visibility
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a User Group
#
# POST /usergroups.create
# Docs: https://api.slack.com/methods/usergroups.create — API method documentation
# Returns: record<ok: bool, usergroup: record<auto_provision: bool, auto_type: list<any>, channel_count: int, created_by: string, date_create: int, date_delete: int, date_update: int, deleted_by: list<any>, description: string, enterprise_subteam_id: string, handle: string, id: string, is_external: bool, is_subteam: bool, is_usergroup: bool, name: string, prefs: record<channels: list, groups: list>, team_id: string, updated_by: string, user_count: int, users: list<string>>>
# operationId: usergroups_create
export def "usergroups-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `usergroups:write` (required) (spec name: token)
  --channels: string # A comma separated string of encoded channel IDs for which the User Group uses as a default.
  --description: string # A short description of the User Group.
  --handle: string # A mention handle. Must be unique among channels, users and User Groups.
  --include-count: oneof<nothing, bool> # Include the number of users in each User Group.
  name: string # A name for the User Group. Must be unique among User Groups.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/usergroups.create"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channels, var: channels}, {name: description, var: description}, {name: handle, var: handle}, {name: include_count, var: include_count}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channels: $channels, description: $description, handle: $handle, include_count: $include_count, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable an existing User Group
#
# POST /usergroups.disable
# Docs: https://api.slack.com/methods/usergroups.disable — API method documentation
# Returns: record<ok: bool, usergroup: record<auto_provision: bool, auto_type: list<any>, channel_count: int, created_by: string, date_create: int, date_delete: int, date_update: int, deleted_by: list<any>, description: string, enterprise_subteam_id: string, handle: string, id: string, is_external: bool, is_subteam: bool, is_usergroup: bool, name: string, prefs: record<channels: list, groups: list>, team_id: string, updated_by: string, user_count: int, users: list<string>>>
# operationId: usergroups_disable
export def "usergroups-disable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `usergroups:write` (required) (spec name: token)
  --include-count: oneof<nothing, bool> # Include the number of users in the User Group.
  usergroup: string # The encoded ID of the User Group to disable.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/usergroups.disable"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: include_count, var: include_count}, {name: usergroup, var: usergroup}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, include_count: $include_count, usergroup: $usergroup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable a User Group
#
# POST /usergroups.enable
# Docs: https://api.slack.com/methods/usergroups.enable — API method documentation
# Returns: record<ok: bool, usergroup: record<auto_provision: bool, auto_type: list<any>, channel_count: int, created_by: string, date_create: int, date_delete: int, date_update: int, deleted_by: list<any>, description: string, enterprise_subteam_id: string, handle: string, id: string, is_external: bool, is_subteam: bool, is_usergroup: bool, name: string, prefs: record<channels: list, groups: list>, team_id: string, updated_by: string, user_count: int, users: list<string>>>
# operationId: usergroups_enable
export def "usergroups-enable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `usergroups:write` (required) (spec name: token)
  --include-count: oneof<nothing, bool> # Include the number of users in the User Group.
  usergroup: string # The encoded ID of the User Group to enable.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/usergroups.enable"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: include_count, var: include_count}, {name: usergroup, var: usergroup}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, include_count: $include_count, usergroup: $usergroup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all User Groups for a team
#
# GET /usergroups.list
# Docs: https://api.slack.com/methods/usergroups.list — API method documentation
# Returns: record<ok: bool, usergroups: table<auto_provision: bool, auto_type: list, channel_count: int, created_by: string, date_create: int, date_delete: int, date_update: int, deleted_by: list, description: string, enterprise_subteam_id: string, handle: string, id: string, is_external: bool, is_subteam: bool, is_usergroup: bool, name: string, prefs: record, team_id: string, updated_by: string, user_count: int, users: list>>
# operationId: usergroups_list
export def "usergroups-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-users: oneof<nothing, bool> # Include the list of users for each User Group.
  --qp-token: string # Authentication token. Requires scope: `usergroups:read` (required) (spec name: token)
  --include-count: oneof<nothing, bool> # Include the number of users in each User Group.
  --include-disabled: oneof<nothing, bool> # Include disabled User Groups.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/usergroups.list"
    query: [{name: include_users, var: include_users}, {name: token, var: qp_token, required: true}, {name: include_count, var: include_count}, {name: include_disabled, var: include_disabled}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    include_users: $include_users, qp_token: $qp_token, include_count: $include_count, include_disabled: $include_disabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing User Group
#
# POST /usergroups.update
# Docs: https://api.slack.com/methods/usergroups.update — API method documentation
# Returns: record<ok: bool, usergroup: record<auto_provision: bool, auto_type: list<any>, channel_count: int, created_by: string, date_create: int, date_delete: int, date_update: int, deleted_by: list<any>, description: string, enterprise_subteam_id: string, handle: string, id: string, is_external: bool, is_subteam: bool, is_usergroup: bool, name: string, prefs: record<channels: list, groups: list>, team_id: string, updated_by: string, user_count: int, users: list<string>>>
# operationId: usergroups_update
export def "usergroups-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `usergroups:write` (required) (spec name: token)
  --channels: string # A comma separated string of encoded channel IDs for which the User Group uses as a default.
  --description: string # A short description of the User Group.
  --handle: string # A mention handle. Must be unique among channels, users and User Groups.
  --include-count: oneof<nothing, bool> # Include the number of users in the User Group.
  --name: string # A name for the User Group. Must be unique among User Groups.
  usergroup: string # The encoded ID of the User Group to update.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/usergroups.update"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: channels, var: channels}, {name: description, var: description}, {name: handle, var: handle}, {name: include_count, var: include_count}, {name: name, var: name}, {name: usergroup, var: usergroup}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, channels: $channels, description: $description, handle: $handle, include_count: $include_count, name: $name, usergroup: $usergroup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all users in a User Group
#
# GET /usergroups.users.list
# Docs: https://api.slack.com/methods/usergroups.users.list — API method documentation
# Returns: record<ok: bool, users: list<string>>
# operationId: usergroups_users_list
export def "usergroups-users-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `usergroups:read` (required) (spec name: token)
  --include-disabled: oneof<nothing, bool> # Allow results that involve disabled User Groups.
  --usergroup: string # The encoded ID of the User Group to update. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/usergroups.users.list"
    query: [{name: token, var: qp_token, required: true}, {name: include_disabled, var: include_disabled}, {name: usergroup, var: usergroup, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, include_disabled: $include_disabled, usergroup: $usergroup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the list of users for a User Group
#
# POST /usergroups.users.update
# Docs: https://api.slack.com/methods/usergroups.users.update — API method documentation
# Returns: record<ok: bool, usergroup: record<auto_provision: bool, auto_type: list<any>, channel_count: int, created_by: string, date_create: int, date_delete: int, date_update: int, deleted_by: list<any>, description: string, enterprise_subteam_id: string, handle: string, id: string, is_external: bool, is_subteam: bool, is_usergroup: bool, name: string, prefs: record<channels: list, groups: list>, team_id: string, updated_by: string, user_count: int, users: list<string>>>
# operationId: usergroups_users_update
export def "usergroups-users-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `usergroups:write` (required) (spec name: token)
  --include-count: oneof<nothing, bool> # Include the number of users in the User Group.
  usergroup: string # The encoded ID of the User Group to update.
  users: string # A comma separated string of encoded user IDs that represent the entire list of users for the User Group.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/usergroups.users.update"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: include_count, var: include_count}, {name: usergroup, var: usergroup}, {name: users, var: users}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, include_count: $include_count, usergroup: $usergroup, users: $users
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List conversations the calling user may access.
#
# GET /users.conversations
# Docs: https://api.slack.com/methods/users.conversations — API method documentation
# Returns: record<channels: list<list<any>>, ok: bool, response_metadata: record<next_cursor: string>>
# operationId: users_conversations
export def "users-conversations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `conversations:read` (spec name: token)
  --user: string # Browse conversations by a specific user ID's membership. Non-public channels are restricted to those where the calling user shares membership.
  --types: string # Mix and match channel types by providing a comma-separated list of any combination of `public_channel`, `private_channel`, `mpim`, `im`
  --exclude-archived: oneof<nothing, bool> # Set to `true` to exclude archived channels from the list
  --limit: int # The maximum number of items to return. Fewer than the requested number of items may be returned, even if the end of the list hasn't been reached. Must be an integer no larger than 1000.
  --cursor: string # Paginate through collections of data by setting the `cursor` parameter to a `next_cursor` attribute returned by a previous request's `response_metadata`. Default value fetches the first "page" of the collection. See [pagination](/docs/pagination) for more detail.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users.conversations"
    query: [{name: token, var: qp_token}, {name: user, var: user}, {name: types, var: types}, {name: exclude_archived, var: exclude_archived}, {name: limit, var: limit}, {name: cursor, var: cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, user: $user, types: $types, exclude_archived: $exclude_archived, limit: $limit, cursor: $cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the user profile photo
#
# POST /users.deletePhoto
# Docs: https://api.slack.com/methods/users.deletePhoto — API method documentation
# Returns: record<ok: bool>
# operationId: users_deletePhoto
export def "users-delete-photo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # Authentication token. Requires scope: `users.profile:write` (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users.deletePhoto"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: token, var: body_token, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets user presence information.
#
# GET /users.getPresence
# Docs: https://api.slack.com/methods/users.getPresence — API method documentation
# Returns: record<auto_away: bool, connection_count: int, last_activity: int, manual_away: bool, ok: bool, online: bool, presence: string>
# operationId: users_getPresence
export def "users-get-presence" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `users:read` (required) (spec name: token)
  --user: string # User to get presence info on. Defaults to the authed user.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users.getPresence"
    query: [{name: token, var: qp_token, required: true}, {name: user, var: user}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user's identity.
#
# GET /users.identity
# Docs: https://api.slack.com/methods/users.identity — API method documentation
# Returns: list<any>
# operationId: users_identity
export def "users-identity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `identity.basic` (spec name: token)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users.identity"
    query: [{name: token, var: qp_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a user.
#
# GET /users.info
# Docs: https://api.slack.com/methods/users.info — API method documentation
# Returns: record<ok: bool, user: list<any>>
# operationId: users_info
export def "users-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `users:read` (required) (spec name: token)
  --include-locale: oneof<nothing, bool> # Set this to `true` to receive the locale for this user. Defaults to `false`
  --user: string # User to get info on
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users.info"
    query: [{name: token, var: qp_token, required: true}, {name: include_locale, var: include_locale}, {name: user, var: user}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, include_locale: $include_locale, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all users in a Slack team.
#
# GET /users.list
# Docs: https://api.slack.com/methods/users.list — API method documentation
# Returns: record<cache_ts: int, members: list<list<any>>, ok: bool, response_metadata: list<any>>
# operationId: users_list
export def "users-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `users:read` (spec name: token)
  --limit: int # The maximum number of items to return. Fewer than the requested number of items may be returned, even if the end of the users list hasn't been reached. Providing no `limit` value will result in Slack attempting to deliver you the entire result set. If the collection is too large you may experience `limit_required` or HTTP 500 errors.
  --cursor: string # Paginate through collections of data by setting the `cursor` parameter to a `next_cursor` attribute returned by a previous request's `response_metadata`. Default value fetches the first "page" of the collection. See [pagination](/docs/pagination) for more detail.
  --include-locale: oneof<nothing, bool> # Set this to `true` to receive the locale for users. Defaults to `false`
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users.list"
    query: [{name: token, var: qp_token}, {name: limit, var: limit}, {name: cursor, var: cursor}, {name: include_locale, var: include_locale}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, limit: $limit, cursor: $cursor, include_locale: $include_locale
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find a user with an email address.
#
# GET /users.lookupByEmail
# Docs: https://api.slack.com/methods/users.lookupByEmail — API method documentation
# Returns: record<ok: bool, user: list<any>>
# operationId: users_lookupByEmail
export def "users-lookup-by-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `users:read.email` (required) (spec name: token)
  --email: string # An email address belonging to a user in the workspace (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users.lookupByEmail"
    query: [{name: token, var: qp_token, required: true}, {name: email, var: email, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a user's profile information.
#
# GET /users.profile.get
# Docs: https://api.slack.com/methods/users.profile.get — API method documentation
# Returns: record<ok: bool, profile: record<always_active: bool, api_app_id: string, avatar_hash: string, bot_id: string, display_name: string, display_name_normalized: string, email: string, fields: list<record>, first_name: string, guest_expiration_ts: int, guest_invited_by: string, image_1024: string, image_192: string, image_24: string, image_32: string, image_48: string, image_512: string, image_72: string, image_original: string, is_app_user: bool, is_custom_image: bool, is_restricted: bool, is_ultra_restricted: bool, last_avatar_image_hash: string, last_name: string, memberships_count: int, name: string, phone: string, pronouns: string, real_name: string, real_name_normalized: string, skype: string, status_default_emoji: string, status_default_text: string, status_default_text_canonical: string, status_emoji: string, status_expiration: int, status_text: string, status_text_canonical: string, team: string, title: string, updated: int, user_id: string, username: string>>
# operationId: users_profile_get
export def "users-profile-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `users.profile:read` (required) (spec name: token)
  --include-labels: oneof<nothing, bool> # Include labels for each ID in custom profile fields
  --user: string # User to retrieve profile info for
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users.profile.get"
    query: [{name: token, var: qp_token, required: true}, {name: include_labels, var: include_labels}, {name: user, var: user}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token, include_labels: $include_labels, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the profile information for a user.
#
# POST /users.profile.set
# Docs: https://api.slack.com/methods/users.profile.set — API method documentation
# Returns: record<email_pending: string, ok: bool, profile: record<always_active: bool, api_app_id: string, avatar_hash: string, bot_id: string, display_name: string, display_name_normalized: string, email: string, fields: list<record>, first_name: string, guest_expiration_ts: int, guest_invited_by: string, image_1024: string, image_192: string, image_24: string, image_32: string, image_48: string, image_512: string, image_72: string, image_original: string, is_app_user: bool, is_custom_image: bool, is_restricted: bool, is_ultra_restricted: bool, last_avatar_image_hash: string, last_name: string, memberships_count: int, name: string, phone: string, pronouns: string, real_name: string, real_name_normalized: string, skype: string, status_default_emoji: string, status_default_text: string, status_default_text_canonical: string, status_emoji: string, status_expiration: int, status_text: string, status_text_canonical: string, team: string, title: string, updated: int, user_id: string, username: string>, username: string>
# operationId: users_profile_set
export def "users-profile-set" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `users.profile:write` (required) (spec name: token)
  --name: string # Name of a single key to set. Usable only if `profile` is not passed.
  --profile: string # Collection of key:value pairs presented as a URL-encoded JSON hash. At most 50 fields may be set. Each field name is limited to 255 characters.
  --user: string # ID of user to change. This argument may only be specified by team admins on paid teams.
  --value: string # Value to set a single key to. Usable only if `profile` is not passed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users.profile.set"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: name, var: name}, {name: profile, var: profile}, {name: user, var: user}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, name: $name, profile: $profile, user: $user, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Marked a user as active. Deprecated and non-functional.
#
# POST /users.setActive
# Docs: https://api.slack.com/methods/users.setActive — API method documentation
# Returns: record<ok: bool>
# operationId: users_setActive
export def "users-set-active" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `users:write` (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/users.setActive"
    header: [{name: token, var: hdr_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the user profile photo
#
# POST /users.setPhoto
# Docs: https://api.slack.com/methods/users.setPhoto — API method documentation
# Returns: record<ok: bool, profile: record<avatar_hash: string, image_1024: string, image_192: string, image_24: string, image_32: string, image_48: string, image_512: string, image_72: string, image_original: string>>
# operationId: users_setPhoto
export def "users-set-photo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --crop-w: string # Width/height of crop box (always square)
  --crop-x: string # X coordinate of top-left corner of crop box
  --crop-y: string # Y coordinate of top-left corner of crop box
  --image: string # File contents via `multipart/form-data`.
  --body-token: string # Authentication token. Requires scope: `users.profile:write` (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users.setPhoto"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: crop_w, var: crop_w}, {name: crop_x, var: crop_x}, {name: crop_y, var: crop_y}, {name: image, var: image}, {name: token, var: body_token, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    crop_w: $crop_w, crop_x: $crop_x, crop_y: $crop_y, image: $image, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Manually sets user presence.
#
# POST /users.setPresence
# Docs: https://api.slack.com/methods/users.setPresence — API method documentation
# Returns: record<ok: bool>
# operationId: users_setPresence
export def "users-set-presence" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `users:write` (required) (spec name: token)
  presence: string # Either `auto` or `away`
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users.setPresence"
    header: [{name: token, var: hdr_token, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: presence, var: presence}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, presence: $presence
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Open a view for a user.
#
# GET /views.open
# Docs: https://api.slack.com/methods/views.open — API method documentation
# Returns: record<ok: bool>
# operationId: views_open
export def "views-open" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trigger-id: string # Exchange a trigger to post to the user. (required)
  --view: string # A [view payload](/reference/surfaces/views). This must be a JSON-encoded string. (required)
  --hdr-token: string # Authentication token. Requires scope: `none` (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/views.open"
    query: [{name: trigger_id, var: trigger_id, required: true}, {name: view, var: view, required: true}]
    header: [{name: token, var: hdr_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    trigger_id: $trigger_id, view: $view, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Publish a static view for a User.
#
# GET /views.publish
# Docs: https://api.slack.com/methods/views.publish — API method documentation
# Returns: record<ok: bool>
# operationId: views_publish
export def "views-publish" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # `id` of the user you want publish a view to. (required)
  --view: string # A [view payload](/reference/surfaces/views). This must be a JSON-encoded string. (required)
  --hash: string # A string that represents view state to protect against possible race conditions.
  --hdr-token: string # Authentication token. Requires scope: `none` (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/views.publish"
    query: [{name: user_id, var: user_id, required: true}, {name: view, var: view, required: true}, {name: hash, var: hash}]
    header: [{name: token, var: hdr_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, view: $view, hash: $hash, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Push a view onto the stack of a root view.
#
# GET /views.push
# Docs: https://api.slack.com/methods/views.push — API method documentation
# Returns: record<ok: bool>
# operationId: views_push
export def "views-push" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trigger-id: string # Exchange a trigger to post to the user. (required)
  --view: string # A [view payload](/reference/surfaces/views). This must be a JSON-encoded string. (required)
  --hdr-token: string # Authentication token. Requires scope: `none` (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/views.push"
    query: [{name: trigger_id, var: trigger_id, required: true}, {name: view, var: view, required: true}]
    header: [{name: token, var: hdr_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    trigger_id: $trigger_id, view: $view, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing view.
#
# GET /views.update
# Docs: https://api.slack.com/methods/views.update — API method documentation
# Returns: record<ok: bool>
# operationId: views_update
export def "views-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --view-id: string # A unique identifier of the view to be updated. Either `view_id` or `external_id` is required.
  --external-id: string # A unique identifier of the view set by the developer. Must be unique for all views on a team. Max length of 255 characters. Either `view_id` or `external_id` is required.
  --view: string # A [view object](/reference/surfaces/views). This must be a JSON-encoded string.
  --hash: string # A string that represents view state to protect against possible race conditions.
  --hdr-token: string # Authentication token. Requires scope: `none` (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/views.update"
    query: [{name: view_id, var: view_id}, {name: external_id, var: external_id}, {name: view, var: view}, {name: hash, var: hash}]
    header: [{name: token, var: hdr_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    view_id: $view_id, external_id: $external_id, view: $view, hash: $hash, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Indicate that an app's step in a workflow completed execution.
#
# GET /workflows.stepCompleted
# Docs: https://api.slack.com/methods/workflows.stepCompleted — API method documentation
# Returns: record<ok: bool>
# operationId: workflows_stepCompleted
export def "workflows-step-completed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --workflow-step-execute-id: string # Context identifier that maps to the correct workflow step execution. (required)
  --outputs: string # Key-value object of outputs from your step. Keys of this object reflect the configured `key` properties of your [`outputs`](/reference/workflows/workflow_step#output) array from your `workflow_step` object.
  --hdr-token: string # Authentication token. Requires scope: `workflow.steps:execute` (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/workflows.stepCompleted"
    query: [{name: workflow_step_execute_id, var: workflow_step_execute_id, required: true}, {name: outputs, var: outputs}]
    header: [{name: token, var: hdr_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workflow_step_execute_id: $workflow_step_execute_id, outputs: $outputs, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Indicate that an app's step in a workflow failed to execute.
#
# GET /workflows.stepFailed
# Docs: https://api.slack.com/methods/workflows.stepFailed — API method documentation
# Returns: record<ok: bool>
# operationId: workflows_stepFailed
export def "workflows-step-failed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --workflow-step-execute-id: string # Context identifier that maps to the correct workflow step execution. (required)
  --error: string # A JSON-based object with a `message` property that should contain a human readable error message. (required)
  --hdr-token: string # Authentication token. Requires scope: `workflow.steps:execute` (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/workflows.stepFailed"
    query: [{name: workflow_step_execute_id, var: workflow_step_execute_id, required: true}, {name: error, var: error, required: true}]
    header: [{name: token, var: hdr_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workflow_step_execute_id: $workflow_step_execute_id, error: $error, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the configuration for a workflow extension step.
#
# GET /workflows.updateStep
# Docs: https://api.slack.com/methods/workflows.updateStep — API method documentation
# Returns: record<ok: bool>
# operationId: workflows_updateStep
export def "workflows-update-step" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --workflow-step-edit-id: string # A context identifier provided with `view_submission` payloads used to call back to `workflows.updateStep`. (required)
  --inputs: string # A JSON key-value map of inputs required from a user during configuration. This is the data your app expects to receive when the workflow step starts. **Please note**: the embedded variable format is set and replaced by the workflow system. You cannot create custom variables that will be replaced at runtime. [Read more about variables in workflow steps here](/workflows/steps#variables).
  --outputs: string # An JSON array of output objects used during step execution. This is the data your app agrees to provide when your workflow step was executed.
  --step-name: string # An optional field that can be used to override the step name that is shown in the Workflow Builder.
  --step-image-url: string # An optional field that can be used to override app image that is shown in the Workflow Builder.
  --hdr-token: string # Authentication token. Requires scope: `workflow.steps:execute` (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/workflows.updateStep"
    query: [{name: workflow_step_edit_id, var: workflow_step_edit_id, required: true}, {name: inputs, var: inputs}, {name: outputs, var: outputs}, {name: step_name, var: step_name}, {name: step_image_url, var: step_image_url}]
    header: [{name: token, var: hdr_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workflow_step_edit_id: $workflow_step_edit_id, inputs: $inputs, outputs: $outputs, step_name: $step_name, step_image_url: $step_image_url, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
