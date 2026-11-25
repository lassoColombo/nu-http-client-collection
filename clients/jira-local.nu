# Auto-generated client for JIRA 7.6.1 v1.0.0
# Source: https://api.apis.guru/v2/specs/jira.local/1.0.0/swagger.json
# Auth: --token flag or $env.JIRA_7_6_1_TOKEN

const CLIENT = {
  base_url: "http://jira.local:8080/jira/rest"
  token_env_var: "JIRA_7_6_1_TOKEN"
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

def base-url-completer [] { ["http://jira.local:8080/jira/rest"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {}
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-api-2-application-properties" "get-advanced-settings" "set-property-via-restful-table" "get-all" "put-bulk" "get-api-2-applicationrole-key" "put" "get-attachment-meta" "remove-attachment" "get-attachment" "expand-for-humans" "expand-for-machines" "get-records" "add-record" "get-all-system-avatars" "store-temporary-avatar" "post-api-2-avatar-type-temporary-crop" "approve-upgrade" "cancel-upgrade" "acknowledge-errors" "set-ready-to-upgrade" "get-state" "get-api-2-comment-comment-id-properties" "delete-api-2-comment-comment-id-properties-property-key" "get-api-2-comment-comment-id-properties-property-key" "put-api-2-comment-comment-id-properties-property-key" "create-component" "delete-api-2-component-id" "get-component" "update-component" "get-component-related-issues" "get-configuration" "get-custom-field-option" "list" "get-api-2-dashboard-dashboard-id-items-item-id-properties" "delete-api-2-dashboard-dashboard-id-items-item-id-properties-property-key" "get-api-2-dashboard-dashboard-id-items-item-id-properties-property-key" "put-api-2-dashboard-dashboard-id-items-item-id-properties-property-key" "get-dashboard" "get-fields" "create-custom-field" "create-filter" "get-default-share-scope" "set-default-share-scope" "get-favourite-filters" "delete-filter" "get-filter" "edit-filter" "delete-api-2-filter-id-columns" "get-api-2-filter-id-columns" "put-api-2-filter-id-columns" "get-share-permissions" "add-share-permission" "delete-share-permission" "get-share-permission" "remove-group" "get-group" "create-group" "get-users-from-group" "remove-user-from-group" "add-user-to-group" "find-groups" "find-users-and-groups" "get-index-summary" "create-issue" "create-issues" "get-create-issue-meta" "get-issue-picker-resource" "delete-issue" "get-issue" "edit-issue" "assign" "add-attachment" "get-comments" "add-comment" "delete-comment" "get-comment" "update-comment" "get-edit-issue-meta" "notify" "get-api-2-issue-issue-id-or-key-properties" "delete-api-2-issue-issue-id-or-key-properties-property-key" "get-api-2-issue-issue-id-or-key-properties-property-key" "put-api-2-issue-issue-id-or-key-properties-property-key" "delete-remote-issue-link-by-global-id" "get-remote-issue-links" "create-or-update-remote-issue-link" "delete-remote-issue-link-by-id" "get-remote-issue-link-by-id" "update-remote-issue-link" "get-sub-tasks" "can-move-sub-task" "move-sub-tasks" "get-transitions" "do-transition" "remove-vote" "get-votes" "add-vote" "remove-watcher" "get-issue-watchers" "add-watcher" "get-issue-worklog" "add-worklog" "delete-worklog" "get-worklog" "update-worklog" "link-issues" "delete-issue-link" "get-issue-link" "get-issue-link-types" "create-issue-link-type" "delete-issue-link-type" "get-issue-link-type" "update-issue-link-type" "get-issue-security-schemes" "get-api-2-issuesecurityschemes-id" "get-issue-all-types" "create-issue-type" "delete-api-2-issuetype-id" "get-api-2-issuetype-id" "update-issue-type" "get-alternative-issue-types" "post-api-2-issuetype-id-avatar" "post-api-2-issuetype-id-avatar-temporary" "get-property-keys" "delete-api-2-issuetype-issue-type-id-properties-property-key" "get-api-2-issuetype-issue-type-id-properties-property-key" "put-api-2-issuetype-issue-type-id-properties-property-key" "get-auto-complete" "get-field-auto-complete-for-query-string" "validate" "are-metrics-exposed" "get-available-metrics" "get-api-2-monitoring-jmx-start-exposing" "stop" "get-permissions" "remove-preference" "get-preference" "set-preference" "get-api-2-myself" "put-api-2-myself" "change-my-password" "get-notification-schemes" "get-api-2-notificationscheme-id" "get-password-policy" "policy-check-create-user" "policy-check-update-user" "get-all-permissions" "get-permission-schemes" "create-permission-scheme" "get-scheme-attribute" "set-scheme-attribute" "delete-permission-scheme" "get-permission-scheme" "update-permission-scheme" "get-permission-scheme-grants" "create-permission-grant" "delete-permission-scheme-entity" "get-permission-scheme-grant" "get-priorities" "get-priority" "get-all-projects" "create-project" "get-all-project-types" "get-project-type-by-key" "get-accessible-project-type-by-key" "delete-project" "get-api-2-project-project-id-or-key" "update-project" "post-api-2-project-project-id-or-key-avatar" "put-api-2-project-project-id-or-key-avatar" "post-api-2-project-project-id-or-key-avatar-temporary" "delete-api-2-project-project-id-or-key-avatar-id" "get-api-2-project-project-id-or-key-avatars" "get-project-components" "get-api-2-project-project-id-or-key-properties" "delete-api-2-project-project-id-or-key-properties-property-key" "get-api-2-project-project-id-or-key-properties-property-key" "put-api-2-project-project-id-or-key-properties-property-key" "get-api-2-project-project-id-or-key-role" "delete-actor" "get-project-role" "add-actor-users" "set-actors" "get-all-statuses" "update-project-type" "get-project-versions-paginated" "get-project-versions" "get-api-2-project-project-key-or-id-issuesecuritylevelscheme" "get-api-2-project-project-key-or-id-notificationscheme" "get-assigned-permission-scheme" "assign-permission-scheme" "get-security-levels-for-project" "get-all-project-categories" "create-project-category" "remove-project-category" "get-project-category-by-id" "update-project-category" "get-api-2-projectvalidate-key" "get-reindex-info" "reindex" "reindex-issues" "get-reindex-progress" "process-requests" "get-progress-bulk" "get-progress" "get-resolutions" "get-resolution" "get-api-2-role" "create-project-role" "delete-project-role" "get-project-roles-by-id" "partial-update-project-role" "fully-update-project-role" "delete-project-role-actors-from-role" "get-project-role-actors-for-role" "add-project-role-actors-to-role" "add-field-to-default-screen" "get-fields-to-add" "get-all-tabs" "add-tab" "delete-tab" "rename-tab" "get-all-fields" "add-field" "remove-field" "move-field" "move-tab" "search" "search-using-search-request" "get-issuesecuritylevel" "get-server-info" "set-base-url" "get-issue-navigator-default-columns" "set-issue-navigator-default-columns" "get-statuses" "get-status" "get-status-categories" "get-status-category" "get-avatars" "post-api-2-universal-avatar-type-type-owner-owning-object-id-avatar" "delete-api-2-universal-avatar-type-type-owner-owning-object-id-avatar-id" "post-api-2-universal-avatar-type-type-owner-owning-object-id-temp" "get-upgrade-result" "run-upgrades-now" "remove-user" "get-api-2-user" "create-user" "put-api-2-user" "remove-user-from-application" "add-user-to-application" "find-bulk-assignable-users" "find-assignable-users" "post-api-2-user-avatar" "put-api-2-user-avatar" "post-api-2-user-avatar-temporary" "delete-api-2-user-avatar-id" "get-api-2-user-avatars" "delete-api-2-user-columns" "get-api-2-user-columns" "put-api-2-user-columns" "change-user-password" "find-users-with-all-permissions" "find-users-for-picker" "get-api-2-user-properties" "delete-api-2-user-properties-property-key" "get-api-2-user-properties-property-key" "put-api-2-user-properties-property-key" "find-users" "find-users-with-browse-permission" "create-version" "get-remote-version-links" "delete-api-2-version-id" "get-version" "update-version" "put-api-2-version-id-mergeto-move-issues-to" "move-version" "get-version-related-issues" "post-api-2-version-id-remove-and-swap" "get-version-unresolved-issues" "delete-remote-version-links-by-version-id" "get-remote-version-links-by-version-id" "post-api-2-version-version-id-remotelink" "delete-remote-version-link" "get-remote-version-link" "post-api-2-version-version-id-remotelink-global-id" "get-all-workflows" "delete-api-2-workflow-api-2-transitions-id-properties" "get-properties" "create-property" "update-property" "create-scheme" "delete-scheme" "get-by-id" "put-api-2-workflowscheme-id" "create-draft-for-parent" "delete-default" "get-default" "update-default" "delete-draft-by-id" "get-draft-by-id" "update-draft" "delete-draft-default" "get-draft-default" "update-draft-default" "delete-draft-issue-type" "get-draft-issue-type" "set-draft-issue-type" "delete-draft-workflow-mapping" "get-draft-workflow" "update-draft-workflow-mapping" "delete-api-2-workflowscheme-id-issuetype-issue-type" "get-api-2-workflowscheme-id-issuetype-issue-type" "set-issue-type" "delete-workflow-mapping" "get-workflow" "update-workflow-mapping" "get-ids-of-worklogs-deleted-since" "get-worklogs-for-ids" "get-ids-of-worklogs-modified-since" "logout" "current-user" "login" "release" "commands"] | sort) } | get name | first)
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

# Returns an application property.
#
# GET /api/2/application-properties
export def "get-api-2-application-properties" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # a String containing the property key
  --permission-level: string # when fetching a list specifies the permission level of all items in the list see {@link com.atlassian.jira.bc.admin.ApplicationPropertiesService.EditPermissionLevel}
  --key-filter: string # when fetching a list allows the list to be filtered by the property's start of key e.g. "jira.lf.*" whould fetch only those permissions that are editable and whose keys start with "jira.lf.". This is a regex.
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/application-properties"
    query: [{name: key, var: key}, {name: permissionLevel, var: permission_level}, {name: keyFilter, var: key_filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key, permission_level: $permission_level, key_filter: $key_filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the properties that are displayed on the "General Configuration > Advanced Settings" page.
#
# GET /api/2/application-properties/advanced-settings
# operationId: getAdvancedSettings
export def "get-advanced-settings" [
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
    path: "/api/2/application-properties/advanced-settings"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify an application property via PUT. The "value" field present in the PUT will override the existing value.
#
# PUT /api/2/application-properties/{id}
# operationId: setPropertyViaRestfulTable
export def "set-property-via-restful-table" [
  id: string
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
    method: put
    path: "/api/2/application-properties/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all ApplicationRoles in the system. Will also return an ETag header containing a version hash of the collection of ApplicationRoles.
#
# GET /api/2/applicationrole
# operationId: getAll
export def "get-all" [
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
    path: "/api/2/applicationrole"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the ApplicationRoles with the passed data if the version hash is the same as the server. Only the groups and default groups setting of the role may be updated. Requests to change the key or the name of the role will be silently ignored. It is acceptable to pass only the roles that are updated as roles that are present in the server but not in data to update with, will not be deleted.
#
# PUT /api/2/applicationrole
# operationId: putBulk
export def "put-bulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string
]: nothing -> any {
  http-request {
    method: put
    path: "/api/2/applicationrole"
    header: [{name: If-Match, var: if_match}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    if_match: $if_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the ApplicationRole with passed key if it exists.
#
# GET /api/2/applicationrole/{key}
# operationId: get
export def "get-api-2-applicationrole-key" [
  key: string
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
    path: "/api/2/applicationrole/{key}"
    path_params: [{name: key, var: key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the ApplicationRole with the passed data. Only the groups and default groups setting of the role may be updated. Requests to change the key or the name of the role will be silently ignored. Optional: If versionHash is passed through the If-Match header the request will be rejected if not the same as server
#
# PUT /api/2/applicationrole/{key}
# operationId: put
export def "put" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # the hash of the version to update. Optional Param
]: nothing -> any {
  http-request {
    method: put
    path: "/api/2/applicationrole/{key}"
    path_params: [{name: key, var: key}]
    header: [{name: If-Match, var: if_match}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key, if_match: $if_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the meta information for an attachments, specifically if they are enabled and the maximum upload size allowed.
#
# GET /api/2/attachment/meta
# operationId: getAttachmentMeta
export def "get-attachment-meta" [
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
    path: "/api/2/attachment/meta"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an attachment from an issue.
#
# DELETE /api/2/attachment/{id}
# operationId: removeAttachment
export def "remove-attachment" [
  id: string
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
    path: "/api/2/attachment/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the meta-data for an attachment, including the URI of the actual attached file.
#
# GET /api/2/attachment/{id}
# operationId: getAttachment
export def "get-attachment" [
  id: string
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
    path: "/api/2/attachment/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tries to expand an attachment. Output is human-readable and subject to change.
#
# GET /api/2/attachment/{id}/expand/human
# operationId: expandForHumans
export def "expand-for-humans" [
  id: string
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
    path: "/api/2/attachment/{id}/expand/human"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tries to expand an attachment. Output is raw and should be backwards-compatible through the course of time.
#
# GET /api/2/attachment/{id}/expand/raw
# operationId: expandForMachines
export def "expand-for-machines" [
  id: string
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
    path: "/api/2/attachment/{id}/expand/raw"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns auditing records filtered using provided parameters
#
# GET /api/2/auditing/record
# operationId: getRecords
export def "get-records" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # - the number of record from which search starts (format: int32)
  --limit: int # - maximum number of returned results (if is limit is <= 0 or > 1000, it will be set do default value: 1000) (format: int32)
  --filter: string # - text query; each record that will be returned must contain the provided text in one of its fields
  --from: string # - timestamp in past; 'from' must be less or equal 'to', otherwise the result set will be empty only records that where created in the same moment or after the 'from' timestamp will be provided in response
  --to: string # - timestamp in past; 'from' must be less or equal 'to', otherwise the result set will be empty only records that where created in the same moment or earlier than the 'to' timestamp will be provided in response
  --project-ids: string # - list of project ids to look for
  --user-ids: string # - list of user ids to look for
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/auditing/record"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: filter, var: filter}, {name: from, var: from}, {name: to, var: to}, {name: projectIds, var: project_ids}, {name: userIds, var: user_ids}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, filter: $filter, from: $from, to: $to, project_ids: $project_ids, user_ids: $user_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Store a record in Audit Log
#
# POST /api/2/auditing/record
# operationId: addRecord
export def "add-record" [
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
    path: "/api/2/auditing/record"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all system avatars of the given type.
#
# GET /api/2/avatar/{type}/system
# operationId: getAllSystemAvatars
export def "get-all-system-avatars" [
  type: string
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
    path: "/api/2/avatar/{type}/system"
    path_params: [{name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates temporary avatar
#
# POST /api/2/avatar/{type}/temporary
# operationId: storeTemporaryAvatar
export def "store-temporary-avatar" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filename: string # name of file being uploaded
  --size: int # size of file (format: int64)
]: nothing -> any {
  http-request {
    method: post
    path: "/api/2/avatar/{type}/temporary"
    path_params: [{name: type, var: type}]
    query: [{name: filename, var: filename}, {name: size, var: size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, filename: $filename, size: $size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the cropping instructions of the temporary avatar.
#
# POST /api/2/avatar/{type}/temporaryCrop
export def "post-api-2-avatar-type-temporary-crop" [
  type: string
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
    path: "/api/2/avatar/{type}/temporaryCrop"
    path_params: [{name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/2/cluster/zdu/approve
#
# operationId: approveUpgrade
export def "approve-upgrade" [
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
    path: "/api/2/cluster/zdu/approve"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/2/cluster/zdu/cancel
#
# operationId: cancelUpgrade
export def "cancel-upgrade" [
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
    path: "/api/2/cluster/zdu/cancel"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/2/cluster/zdu/retryUpgrade
#
# operationId: acknowledgeErrors
export def "acknowledge-errors" [
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
    path: "/api/2/cluster/zdu/retryUpgrade"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/2/cluster/zdu/start
#
# operationId: setReadyToUpgrade
export def "set-ready-to-upgrade" [
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
    path: "/api/2/cluster/zdu/start"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/2/cluster/zdu/state
#
# operationId: getState
export def "get-state" [
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
    path: "/api/2/cluster/zdu/state"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the keys of all properties for the comment identified by the key or by the id.
#
# GET /api/2/comment/{commentId}/properties
export def "get-api-2-comment-comment-id-properties" [
  comment_id: string
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
    path: "/api/2/comment/{commentId}/properties"
    path_params: [{name: commentId, var: comment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    comment_id: $comment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the property from the comment identified by the key or by the id. Ths user removing the property is required to have permissions to administer the comment.
#
# DELETE /api/2/comment/{commentId}/properties/{propertyKey}
export def "delete-api-2-comment-comment-id-properties-property-key" [
  comment_id: string
  property_key: string
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
    path: "/api/2/comment/{commentId}/properties/{propertyKey}"
    path_params: [{name: commentId, var: comment_id}, {name: propertyKey, var: property_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    comment_id: $comment_id, property_key: $property_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the value of the property with a given key from the comment identified by the key or by the id. The user who retrieves the property is required to have permissions to read the comment.
#
# GET /api/2/comment/{commentId}/properties/{propertyKey}
export def "get-api-2-comment-comment-id-properties-property-key" [
  comment_id: string
  property_key: string
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
    path: "/api/2/comment/{commentId}/properties/{propertyKey}"
    path_params: [{name: commentId, var: comment_id}, {name: propertyKey, var: property_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    comment_id: $comment_id, property_key: $property_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the value of the specified comment's property. You can use this resource to store a custom data against the comment identified by the key or by the id. The user who stores the data is required to have permissions to administer the comment.
#
# PUT /api/2/comment/{commentId}/properties/{propertyKey}
export def "put-api-2-comment-comment-id-properties-property-key" [
  comment_id: string
  property_key: string
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
    method: put
    path: "/api/2/comment/{commentId}/properties/{propertyKey}"
    path_params: [{name: commentId, var: comment_id}, {name: propertyKey, var: property_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    comment_id: $comment_id, property_key: $property_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a component via POST.
#
# POST /api/2/component
# operationId: createComponent
export def "create-component" [
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
    path: "/api/2/component"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a project component.
#
# DELETE /api/2/component/{id}
export def "delete-api-2-component-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --move-issues-to: string # The new component applied to issues whose 'id' component will be deleted. If this value is null, then the 'id' component is simply removed from the related isues.
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/2/component/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: moveIssuesTo, var: move_issues_to}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, move_issues_to: $move_issues_to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a project component.
#
# GET /api/2/component/{id}
# operationId: getComponent
export def "get-component" [
  id: string
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
    path: "/api/2/component/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a component via PUT. Any fields present in the PUT will override existing values. As a convenience, if a field is not present, it is silently ignored. If leadUserName is an empty string ("") the component lead will be removed.
#
# PUT /api/2/component/{id}
# operationId: updateComponent
export def "update-component" [
  id: string
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
    method: put
    path: "/api/2/component/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns counts of issues related to this component.
#
# GET /api/2/component/{id}/relatedIssueCounts
# operationId: getComponentRelatedIssues
export def "get-component-related-issues" [
  id: string
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
    path: "/api/2/component/{id}/relatedIssueCounts"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the information if the optional features in JIRA are enabled or disabled. If the time tracking is enabled, it also returns the detailed information about time tracking configuration.
#
# GET /api/2/configuration
# operationId: getConfiguration
export def "get-configuration" [
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
    path: "/api/2/configuration"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a full representation of the Custom Field Option that has the given id.
#
# GET /api/2/customFieldOption/{id}
# operationId: getCustomFieldOption
export def "get-custom-field-option" [
  id: string
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
    path: "/api/2/customFieldOption/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of all dashboards, optionally filtering them.
#
# GET /api/2/dashboard
# operationId: list
export def "list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # an optional filter that is applied to the list of dashboards. Valid values include "favourite" for returning only favourite dashboards, and "my" for returning dashboards that are owned by the calling user.
  --start-at: int # the index of the first dashboard to return (0-based). must be 0 or a multiple of maxResults (format: int32)
  --max-results: int # a hint as to the the maximum number of dashboards to return in each call. Note that the JIRA server reserves the right to impose a maxResults limit that is lower than the value that a client provides, dues to lack or resources or any other condition. When this happens, your results will be truncated. Callers should always check the returned maxResults to determine the value that is effectively being used. (format: int32)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/dashboard"
    query: [{name: filter, var: filter}, {name: startAt, var: start_at}, {name: maxResults, var: max_results}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, start_at: $start_at, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the keys of all properties for the dashboard item identified by the id.
#
# GET /api/2/dashboard/{dashboardId}/items/{itemId}/properties
export def "get-api-2-dashboard-dashboard-id-items-item-id-properties" [
  dashboard_id: string
  item_id: string
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
    path: "/api/2/dashboard/{dashboardId}/items/{itemId}/properties"
    path_params: [{name: dashboardId, var: dashboard_id}, {name: itemId, var: item_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dashboard_id: $dashboard_id, item_id: $item_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the property from the dashboard item identified by the key or by the id. Ths user removing the property is required to have permissions to administer the dashboard item.
#
# DELETE /api/2/dashboard/{dashboardId}/items/{itemId}/properties/{propertyKey}
export def "delete-api-2-dashboard-dashboard-id-items-item-id-properties-property-key" [
  dashboard_id: string
  item_id: string
  property_key: string
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
    path: "/api/2/dashboard/{dashboardId}/items/{itemId}/properties/{propertyKey}"
    path_params: [{name: dashboardId, var: dashboard_id}, {name: itemId, var: item_id}, {name: propertyKey, var: property_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dashboard_id: $dashboard_id, item_id: $item_id, property_key: $property_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the value of the property with a given key from the dashboard item identified by the id. The user who retrieves the property is required to have permissions to read the dashboard item.
#
# GET /api/2/dashboard/{dashboardId}/items/{itemId}/properties/{propertyKey}
export def "get-api-2-dashboard-dashboard-id-items-item-id-properties-property-key" [
  dashboard_id: string
  item_id: string
  property_key: string
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
    path: "/api/2/dashboard/{dashboardId}/items/{itemId}/properties/{propertyKey}"
    path_params: [{name: dashboardId, var: dashboard_id}, {name: itemId, var: item_id}, {name: propertyKey, var: property_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dashboard_id: $dashboard_id, item_id: $item_id, property_key: $property_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the value of the specified dashboard item's property. You can use this resource to store a custom data against the dashboard item identified by the id. The user who stores the data is required to have permissions to administer the dashboard item.
#
# PUT /api/2/dashboard/{dashboardId}/items/{itemId}/properties/{propertyKey}
export def "put-api-2-dashboard-dashboard-id-items-item-id-properties-property-key" [
  dashboard_id: string
  item_id: string
  property_key: string
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
    method: put
    path: "/api/2/dashboard/{dashboardId}/items/{itemId}/properties/{propertyKey}"
    path_params: [{name: dashboardId, var: dashboard_id}, {name: itemId, var: item_id}, {name: propertyKey, var: property_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dashboard_id: $dashboard_id, item_id: $item_id, property_key: $property_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a single dashboard.
#
# GET /api/2/dashboard/{id}
# operationId: getDashboard
export def "get-dashboard" [
  id: string
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
    path: "/api/2/dashboard/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of all fields, both System and Custom
#
# GET /api/2/field
# operationId: getFields
export def "get-fields" [
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
    path: "/api/2/field"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a custom field using a definition (object encapsulating custom field data)
#
# POST /api/2/field
# operationId: createCustomField
export def "create-custom-field" [
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
    path: "/api/2/field"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new filter, and returns newly created filter. Currently sets permissions just using the users default sharing permissions
#
# POST /api/2/filter
# operationId: createFilter
export def "create-filter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # the parameters to expand
]: nothing -> any {
  http-request {
    method: post
    path: "/api/2/filter"
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the default share scope of the logged-in user.
#
# GET /api/2/filter/defaultShareScope
# operationId: getDefaultShareScope
export def "get-default-share-scope" [
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
    path: "/api/2/filter/defaultShareScope"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the default share scope of the logged-in user. Available values are GLOBAL and PRIVATE.
#
# PUT /api/2/filter/defaultShareScope
# operationId: setDefaultShareScope
export def "set-default-share-scope" [
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
    method: put
    path: "/api/2/filter/defaultShareScope"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the favourite filters of the logged-in user.
#
# GET /api/2/filter/favourite
# operationId: getFavouriteFilters
export def "get-favourite-filters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # the parameters to expand
  --enable-shared-users: oneof<nothing, bool> # enable calculating shared users collection (default: true)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/filter/favourite"
    query: [{name: expand, var: expand}, {name: enableSharedUsers, var: enable_shared_users}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expand: $expand, enable_shared_users: $enable_shared_users
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a filter.
#
# DELETE /api/2/filter/{id}
# operationId: deleteFilter
export def "delete-filter" [
  id: int
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
    path: "/api/2/filter/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a filter given an id
#
# GET /api/2/filter/{id}
# operationId: getFilter
export def "get-filter" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # the parameters to expand
  --enable-shared-users: oneof<nothing, bool> # enable calculating shared users collection (default: true)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/filter/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: expand, var: expand}, {name: enableSharedUsers, var: enable_shared_users}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, expand: $expand, enable_shared_users: $enable_shared_users
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing filter, and returns its new value.
#
# PUT /api/2/filter/{id}
# operationId: editFilter
export def "edit-filter" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # the parameters to expand
]: nothing -> any {
  http-request {
    method: put
    path: "/api/2/filter/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resets the columns for the given filter such that the filter no longer has its own column config.
#
# DELETE /api/2/filter/{id}/columns
export def "delete-api-2-filter-id-columns" [
  id: int
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
    path: "/api/2/filter/{id}/columns"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the default columns for the given filter. Currently logged in user will be used as the user making such request.
#
# GET /api/2/filter/{id}/columns
export def "get-api-2-filter-id-columns" [
  id: int
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
    path: "/api/2/filter/{id}/columns"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the default columns for the given filter.
#
# PUT /api/2/filter/{id}/columns
export def "put-api-2-filter-id-columns" [
  id: int
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
    method: put
    path: "/api/2/filter/{id}/columns"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all share permissions of the given filter.
#
# GET /api/2/filter/{id}/permission
# operationId: getSharePermissions
export def "get-share-permissions" [
  id: int
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
    path: "/api/2/filter/{id}/permission"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a share permissions to the given filter. Adding a global permission removes all previous permissions from the filter.
#
# POST /api/2/filter/{id}/permission
# operationId: addSharePermission
export def "add-share-permission" [
  id: int
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
    path: "/api/2/filter/{id}/permission"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a share permissions from the given filter.
#
# DELETE /api/2/filter/{id}/permission/{permission-id}
# operationId: deleteSharePermission
export def "delete-share-permission" [
  id: int
  permission_id: int
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
    path: "/api/2/filter/{id}/permission/{permission-id}"
    path_params: [{name: id, var: id}, {name: permission-id, var: permission_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, permission_id: $permission_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a single share permission of the given filter.
#
# GET /api/2/filter/{id}/permission/{permissionId}
# operationId: getSharePermission
export def "get-share-permission" [
  id: int
  permission_id: int
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
    path: "/api/2/filter/{id}/permission/{permissionId}"
    path_params: [{name: id, var: id}, {name: permissionId, var: permission_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, permission_id: $permission_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a group by given group parameter. Returns no content
#
# DELETE /api/2/group
# operationId: removeGroup
export def "remove-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --groupname: string # (mandatory) The name of the group to delete.
  --swap-group: string # If you delete a group and content is restricted to that group, the content will be hidden from all users. To prevent this, use this parameter to specify a different group to transfer the restrictions (comments and worklogs only) to.
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/2/group"
    query: [{name: groupname, var: groupname}, {name: swapGroup, var: swap_group}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    groupname: $groupname, swap_group: $swap_group
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns REST representation for the requested group. Allows to get list of active users belonging to the specified group and its subgroups if "users" expand option is provided. You can page through users list by using indexes in expand param. For example to get users from index 10 to index 15 use "users[10:15]" expand value. This will return 6 users (if there are at least 16 users in this group). Indexes are 0-based and inclusive. This resource is deprecated, please use group/member API instead.
#
# GET /api/2/group
# operationId: getGroup
export def "get-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --groupname: string # A name of requested group.
  --expand: string # List of fields to expand. Currently only available expand is "users".
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/group"
    query: [{name: groupname, var: groupname}, {name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    groupname: $groupname, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a group by given group parameter Returns REST representation for the requested group.
#
# POST /api/2/group
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
]: nothing -> any {
  http-request {
    method: post
    path: "/api/2/group"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This resource returns a paginated (#pagination) list of users who are members of the specified group and its subgroups. Users in the page are ordered by user names. User of this resource is required to have sysadmin or admin permissions.
#
# GET /api/2/group/member
# operationId: getUsersFromGroup
export def "get-users-from-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --groupname: string # a name of the group for which members will be returned.
  --include-inactive-users: oneof<nothing, bool> # inactive users will be included in the response if set to true. (default: false)
  --start-at: int # the index of the first user in group to return (0 based). (format: int64, default: 0)
  --max-results: int # the maximum number of users to return (max 50). (format: int32, default: 50)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/group/member"
    query: [{name: groupname, var: groupname}, {name: includeInactiveUsers, var: include_inactive_users}, {name: startAt, var: start_at}, {name: maxResults, var: max_results}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    groupname: $groupname, include_inactive_users: $include_inactive_users, start_at: $start_at, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes given user from a group. Returns no content
#
# DELETE /api/2/group/user
# operationId: removeUserFromGroup
export def "remove-user-from-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --groupname: string # A name of requested group.
  --username: string # User to remove from a group
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/2/group/user"
    query: [{name: groupname, var: groupname}, {name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    groupname: $groupname, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds given user to a group. Returns the current state of the group.
#
# POST /api/2/group/user
# operationId: addUserToGroup
export def "add-user-to-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --groupname: string # A name of requested group.
]: nothing -> any {
  http-request {
    method: post
    path: "/api/2/group/user"
    query: [{name: groupname, var: groupname}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    groupname: $groupname
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns groups with substrings matching a given query. This is mainly for use with the group picker, so the returned groups contain html to be used as picker suggestions. The groups are also wrapped in a single response object that also contains a header for use in the picker, specifically Showing X of Y matching groups. The number of groups returned is limited by the system property "jira.ajax.autocomplete.limit" The groups will be unique and sorted.
#
# GET /api/2/groups/picker
# operationId: findGroups
export def "find-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # a String to match groups agains
  --exclude: string
  --max-results: int # format: int32
  --user-name: string
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/groups/picker"
    query: [{name: query, var: query}, {name: exclude, var: exclude}, {name: maxResults, var: max_results}, {name: userName, var: user_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    query: $query, exclude: $exclude, max_results: $max_results, user_name: $user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of users and groups matching query with highlighting. This resource cannot be accessed anonymously.
#
# GET /api/2/groupuserpicker
# operationId: findUsersAndGroups
export def "find-users-and-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A string used to search username, Name or e-mail address
  --max-results: int # the maximum number of users to return (defaults to 50). The maximum allowed value is 1000. If you specify a value that is higher than this number, your search results will be truncated. (format: int32)
  --show-avatar: oneof<nothing, bool>
  --field-id: string # The custom field id, if this request comes from a custom field, such as a user picker. Optional.
  --project-id: string # The list of project ids to further restrict the search This parameter can occur multiple times to pass in multiple project ids. Comma separated value is not supported. This parameter is only used when fieldId is present.
  --issue-type-id: string # The list of issue type ids to further restrict the search. This parameter can occur multiple times to pass in multiple issue type ids. Comma separated value is not supported. Special values such as -1 (all standard issue types), -2 (all subtask issue types) are supported. This parameter is only used when fieldId is present.
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/groupuserpicker"
    query: [{name: query, var: query}, {name: maxResults, var: max_results}, {name: showAvatar, var: show_avatar}, {name: fieldId, var: field_id}, {name: projectId, var: project_id}, {name: issueTypeId, var: issue_type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    query: $query, max_results: $max_results, show_avatar: $show_avatar, field_id: $field_id, project_id: $project_id, issue_type_id: $issue_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Summarizes index condition of current node. Returned data consists of: nodeId - Node identifier. reportTime - Time of this report creation. issueIndex - Summary of issue index status. replicationQueues - Map of index replication queues, where keys represent nodes from which replication operations came from. issueIndex can contain: indexReadable - If false the end point failed to read data from issue index (check JIRA logs for detailed stack trace), otherwise true. When false other fields of issueIndex can be not visible. countInDatabase - Count of issues found in database. countInIndex - Count of issues found while querying index. lastUpdatedInDatabase - Time of last update of issue found in database. lastUpdatedInIndex - Time of last update of issue found while querying index. replicationQueues's map values can contain: lastConsumedOperation - Last executed index replication operation by current node from sending node's queue. lastConsumedOperation.id - Identifier of the operation. lastConsumedOperation.replicationTime - Time when the operation was sent to other nodes. lastOperationInQueue - Last index replication operation in sending node's queue. lastOperationInQueue.id - Identifier of the operation. lastOperationInQueue.replicationTime - Time when the operation was sent to other nodes. queueSize - Number of operations in queue from sending node to current node.
#
# GET /api/2/index/summary
# operationId: getIndexSummary
export def "get-index-summary" [
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
    path: "/api/2/index/summary"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an issue or a sub-task from a JSON representation. The fields that can be set on create, in either the fields parameter or the update parameter can be determined using the /rest/api/2/issue/createmeta resource. If a field is not configured to appear on the create screen, then it will not be in the createmeta, and a field validation error will occur if it is submitted. Creating a sub-task is similar to creating a regular issue, with two important differences: the issueType field must correspond to a sub-task issue type (you can use /issue/createmeta to discover sub-task issue types), and you must provide a parent field in the issue create request containing the id or key of the parent issue.
#
# POST /api/2/issue
# operationId: createIssue
export def "create-issue" [
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
    path: "/api/2/issue"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates issues or sub-tasks from a JSON representation. Creates many issues in one bulk operation. Creating a sub-task is similar to creating a regular issue. More details can be found in createIssue section: {@link IssueResource#createIssue(IssueUpdateBean)}}
#
# POST /api/2/issue/bulk
# operationId: createIssues
export def "create-issues" [
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
    path: "/api/2/issue/bulk"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the meta data for creating issues. This includes the available projects, issue types and fields, including field types and whether or not those fields are required. Projects will not be returned if the user does not have permission to create issues in that project. The fields in the createmeta correspond to the fields in the create screen for the project/issuetype. Fields not in the screen will not be in the createmeta. Fields will only be returned if expand=projects.issuetypes.fields. The results can be filtered by project and/or issue type, given by the query params.
#
# GET /api/2/issue/createmeta
# operationId: getCreateIssueMeta
export def "get-create-issue-meta" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-ids: string # combined with the projectKeys param, lists the projects with which to filter the results. If absent, all projects are returned. This parameter can be specified multiple times, and/or be a comma-separated list. Specifiying a project that does not exist (or that you cannot create issues in) is not an error, but it will not be in the results.
  --project-keys: string # combined with the projectIds param, lists the projects with which to filter the results. If null, all projects are returned. This parameter can be specified multiple times, and/or be a comma-separated list. Specifiying a project that does not exist (or that you cannot create issues in) is not an error, but it will not be in the results.
  --issuetype-ids: string # combinded with issuetypeNames, lists the issue types with which to filter the results. If null, all issue types are returned. This parameter can be specified multiple times, and/or be a comma-separated list. Specifiying an issue type that does not exist is not an error.
  --issuetype-names: string # combinded with issuetypeIds, lists the issue types with which to filter the results. If null, all issue types are returned. This parameter can be specified multiple times, but is NOT interpreted as a comma-separated list. Specifiying an issue type that does not exist is not an error.
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/issue/createmeta"
    query: [{name: projectIds, var: project_ids}, {name: projectKeys, var: project_keys}, {name: issuetypeIds, var: issuetype_ids}, {name: issuetypeNames, var: issuetype_names}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_ids: $project_ids, project_keys: $project_keys, issuetype_ids: $issuetype_ids, issuetype_names: $issuetype_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns suggested issues which match the auto-completion query for the user which executes this request. This REST method will check the user's history and the user's browsing context and select this issues, which match the query.
#
# GET /api/2/issue/picker
# operationId: getIssuePickerResource
export def "get-issue-picker-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # the query.
  --current-jql: string # the JQL in context of which the request is executed. Only issues which match this JQL query will be included in results.
  --current-issue-key: string # the key of the issue in context of which the request is executed. The issue which is in context will not be included in the auto-completion result, even if it matches the query.
  --current-project-id: string # the id of the project in context of which the request is executed. Suggested issues will be only from this project.
  --show-sub-tasks: oneof<nothing, bool> # if set to false, subtasks will not be included in the list.
  --show-sub-task-parent: oneof<nothing, bool> # if set to false and request is executed in context of a subtask, the parent issue will not be included in the auto-completion result, even if it matches the query.
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/issue/picker"
    query: [{name: query, var: query}, {name: currentJQL, var: current_jql}, {name: currentIssueKey, var: current_issue_key}, {name: currentProjectId, var: current_project_id}, {name: showSubTasks, var: show_sub_tasks}, {name: showSubTaskParent, var: show_sub_task_parent}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    query: $query, current_jql: $current_jql, current_issue_key: $current_issue_key, current_project_id: $current_project_id, show_sub_tasks: $show_sub_tasks, show_sub_task_parent: $show_sub_task_parent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an issue. If the issue has subtasks you must set the parameter deleteSubtasks=true to delete the issue. You cannot delete an issue without its subtasks also being deleted.
#
# DELETE /api/2/issue/{issueIdOrKey}
# operationId: deleteIssue
export def "delete-issue" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-subtasks: string # a String of true or false indicating that any subtasks should also be deleted. If the issue has no subtasks this parameter is ignored. If the issue has subtasks and this parameter is missing or false, then the issue will not be deleted and an error will be returned.
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/2/issue/{issueIdOrKey}"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}]
    query: [{name: deleteSubtasks, var: delete_subtasks}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key, delete_subtasks: $delete_subtasks
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a full representation of the issue for the given issue key. An issue JSON consists of the issue key, a collection of fields, a link to the workflow transition sub-resource, and (optionally) the HTML rendered values of any fields that support it (e.g. if wiki syntax is enabled for the description or comments). The fields param (which can be specified multiple times) gives a comma-separated list of fields to include in the response. This can be used to retrieve a subset of fields. A particular field can be excluded by prefixing it with a minus. By default, all (*all) fields are returned in this get-issue resource. Note: the default is different when doing a jql search -- the default there is just navigable fields (*navigable). *all - include all fields *navigable - include just navigable fields summary,comment - include just the summary and comments -comment - include everything except comments (the default is *all for get-issue) *all,-comment - include everything except comments The {@code properties} param is similar to {@code fields} and specifies a comma-separated list of issue properties to include. Unlike {@code fields}, properties are not included by default. To include them all send {@code ?properties=*all}. You can also include only specified properties or exclude some properties with a minus (-) sign. {@code *all} - include all properties {@code *all, -prop1} - include all properties except {@code prop1} {@code prop1, prop1} - include {@code prop1} and {@code prop2} properties JIRA will attempt to identify the issue by the issueIdOrKey path parameter. This can be an issue id, or an issue key. If the issue cannot be found via an exact match, JIRA will also look for the issue in a case-insensitive way, or by looking to see if the issue was moved. In either of these cases, the request will proceed as normal (a 302 or other redirect will not be returned). The issue key contained in the response will indicate the current value of issue's key. The expand param is used to include, hidden by default, parts of response. This can be used to include: renderedFields - field values in HTML format names - display name of each field schema - schema for each field which describes a type of the field transitions - all possible transitions for the given issue operations - all possibles operations which may be applied on issue editmeta - information about how each field may be edited. It contains field's schema as well. changelog - history of all changes of the given issue versionedRepresentations - REST representations of all fields. Some field may contain more recent versions. RESET representations are numbered. The greatest number always represents the most recent version. It is recommended that the most recent version is used. version for these fields which provide a more recent REST representation. After including versionedRepresentations "fields" field become hidden.
#
# GET /api/2/issue/{issueIdOrKey}
# operationId: getIssue
export def "get-issue" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # the list of fields to return for the issue. By default, all fields are returned.
  --expand: string
  --properties: string # the list of properties to return for the issue. By default no properties are returned.
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/issue/{issueIdOrKey}"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}]
    query: [{name: fields, var: fields}, {name: expand, var: expand}, {name: properties, var: properties}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key, fields: $fields, expand: $expand, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edits an issue from a JSON representation. The issue can either be updated by setting explicit the field value(s) or by using an operation to change the field value. The fields that can be updated, in either the fields parameter or the update parameter, can be determined using the /rest/api/2/issue/{issueIdOrKey}/editmeta resource. If a field is not configured to appear on the edit screen, then it will not be in the editmeta, and a field validation error will occur if it is submitted. Specifying a "field_id": field_value in the "fields" is a shorthand for a "set" operation in the "update" section. Field should appear either in "fields" or "update", not in both.
#
# PUT /api/2/issue/{issueIdOrKey}
# operationId: editIssue
export def "edit-issue" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --notify-users: oneof<nothing, bool> # send the email with notification that the issue was updated to users that watch it. Admin or project admin permissions are required to disable the notification. (default: true)
]: nothing -> any {
  http-request {
    method: put
    path: "/api/2/issue/{issueIdOrKey}"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}]
    query: [{name: notifyUsers, var: notify_users}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key, notify_users: $notify_users
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assigns an issue to a user. You can use this resource to assign issues when the user submitting the request has the assign permission but not the edit issue permission. If the name is "-1" automatic assignee is used. A null name will remove the assignee.
#
# PUT /api/2/issue/{issueIdOrKey}/assignee
# operationId: assign
export def "assign" [
  issue_id_or_key: string
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
    method: put
    path: "/api/2/issue/{issueIdOrKey}/assignee"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add one or more attachments to an issue. This resource expects a multipart post. The media-type multipart/form-data is defined in RFC 1867. Most client libraries have classes that make dealing with multipart posts simple. For instance, in Java the Apache HTTP Components library provides a MultiPartEntity (http://hc.apache.org/httpcomponents-client-ga/httpmime/apidocs/org/apache/http/entity/mime/MultipartEntity.html) that makes it simple to submit a multipart POST. In order to protect against XSRF attacks, because this method accepts multipart/form-data, it has XSRF protection on it. This means you must submit a header of X-Atlassian-Token: no-check with the request, otherwise it will be blocked. The name of the multipart/form-data parameter that contains attachments must be "file" A simple example to upload a file called "myfile.txt" to issue REST-123: curl -D- -u admin:admin -X POST -H "X-Atlassian-Token: no-check" -F "file=@myfile.txt" http://myhost/rest/api/2/issue/TEST-123/attachments
#
# POST /api/2/issue/{issueIdOrKey}/attachments
# operationId: addAttachment
export def "add-attachment" [
  issue_id_or_key: string
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
    path: "/api/2/issue/{issueIdOrKey}/attachments"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all comments for an issue. Results can be ordered by the "created" field which means the date a comment was added.
#
# GET /api/2/issue/{issueIdOrKey}/comment
# operationId: getComments
export def "get-comments" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # the page offset, if not specified then defaults to 0 (format: int64)
  --max-results: int # how many results on the page should be included. Defaults to 50. (format: int32)
  --order-by: string # ordering of the results.
  --expand: string # optional flags: renderedBody (provides body rendered in HTML)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/issue/{issueIdOrKey}/comment"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}]
    query: [{name: startAt, var: start_at}, {name: maxResults, var: max_results}, {name: orderBy, var: order_by}, {name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key, start_at: $start_at, max_results: $max_results, order_by: $order_by, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a new comment to an issue.
#
# POST /api/2/issue/{issueIdOrKey}/comment
# operationId: addComment
export def "add-comment" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # optional flags: renderedBody (provides body rendered in HTML)
]: nothing -> any {
  http-request {
    method: post
    path: "/api/2/issue/{issueIdOrKey}/comment"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing comment .
#
# DELETE /api/2/issue/{issueIdOrKey}/comment/{id}
# operationId: deleteComment
export def "delete-comment" [
  issue_id_or_key: string
  id: string
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
    path: "/api/2/issue/{issueIdOrKey}/comment/{id}"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a single comment.
#
# GET /api/2/issue/{issueIdOrKey}/comment/{id}
# operationId: getComment
export def "get-comment" [
  issue_id_or_key: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # optional flags: renderedBody (provides body rendered in HTML)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/issue/{issueIdOrKey}/comment/{id}"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}, {name: id, var: id}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key, id: $id, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing comment using its JSON representation.
#
# PUT /api/2/issue/{issueIdOrKey}/comment/{id}
# operationId: updateComment
export def "update-comment" [
  issue_id_or_key: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # optional flags: renderedBody (provides body rendered in HTML)
]: nothing -> any {
  http-request {
    method: put
    path: "/api/2/issue/{issueIdOrKey}/comment/{id}"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}, {name: id, var: id}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key, id: $id, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the meta data for editing an issue. The fields in the editmeta correspond to the fields in the edit screen for the issue. Fields not in the screen will not be in the editmeta.
#
# GET /api/2/issue/{issueIdOrKey}/editmeta
# operationId: getEditIssueMeta
export def "get-edit-issue-meta" [
  issue_id_or_key: string
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
    path: "/api/2/issue/{issueIdOrKey}/editmeta"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends a notification (email) to the list or recipients defined in the request.
#
# POST /api/2/issue/{issueIdOrKey}/notify
# operationId: notify
export def "notify" [
  issue_id_or_key: string
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
    path: "/api/2/issue/{issueIdOrKey}/notify"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the keys of all properties for the issue identified by the key or by the id.
#
# GET /api/2/issue/{issueIdOrKey}/properties
export def "get-api-2-issue-issue-id-or-key-properties" [
  issue_id_or_key: string
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
    path: "/api/2/issue/{issueIdOrKey}/properties"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the property from the issue identified by the key or by the id. Ths user removing the property is required to have permissions to edit the issue.
#
# DELETE /api/2/issue/{issueIdOrKey}/properties/{propertyKey}
export def "delete-api-2-issue-issue-id-or-key-properties-property-key" [
  issue_id_or_key: string
  property_key: string
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
    path: "/api/2/issue/{issueIdOrKey}/properties/{propertyKey}"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}, {name: propertyKey, var: property_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key, property_key: $property_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the value of the property with a given key from the issue identified by the key or by the id. The user who retrieves the property is required to have permissions to read the issue.
#
# GET /api/2/issue/{issueIdOrKey}/properties/{propertyKey}
export def "get-api-2-issue-issue-id-or-key-properties-property-key" [
  issue_id_or_key: string
  property_key: string
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
    path: "/api/2/issue/{issueIdOrKey}/properties/{propertyKey}"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}, {name: propertyKey, var: property_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key, property_key: $property_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the value of the specified issue's property. You can use this resource to store a custom data against the issue identified by the key or by the id. The user who stores the data is required to have permissions to edit the issue.
#
# PUT /api/2/issue/{issueIdOrKey}/properties/{propertyKey}
export def "put-api-2-issue-issue-id-or-key-properties-property-key" [
  issue_id_or_key: string
  property_key: string
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
    method: put
    path: "/api/2/issue/{issueIdOrKey}/properties/{propertyKey}"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}, {name: propertyKey, var: property_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key, property_key: $property_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the remote issue link with the given global id on the issue.
#
# DELETE /api/2/issue/{issueIdOrKey}/remotelink
# operationId: deleteRemoteIssueLinkByGlobalId
export def "delete-remote-issue-link-by-global-id" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --global-id: string # the global id of the remote issue link
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/2/issue/{issueIdOrKey}/remotelink"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}]
    query: [{name: globalId, var: global_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key, global_id: $global_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# A REST sub-resource representing the remote issue links on the issue.
#
# GET /api/2/issue/{issueIdOrKey}/remotelink
# operationId: getRemoteIssueLinks
export def "get-remote-issue-links" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --global-id: string # The id of the remote issue link to be returned. If null (not provided) all remote links for the issue are returned. For a fullexplanation of Issue Link fields please refer to https://developer.atlassian.com/display/JIRADEV/Fields+in+Remote+Issue+Links (https://developer.atlassian.com/display/JIRADEV/Fields+in+Remote+Issue+Links)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/issue/{issueIdOrKey}/remotelink"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}]
    query: [{name: globalId, var: global_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key, global_id: $global_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates a remote issue link from a JSON representation. If a globalId is provided and a remote issue link exists with that globalId, the remote issue link is updated. Otherwise, the remote issue link is created.
#
# POST /api/2/issue/{issueIdOrKey}/remotelink
# operationId: createOrUpdateRemoteIssueLink
export def "create-or-update-remote-issue-link" [
  issue_id_or_key: string
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
    path: "/api/2/issue/{issueIdOrKey}/remotelink"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the remote issue link with the given id on the issue.
#
# DELETE /api/2/issue/{issueIdOrKey}/remotelink/{linkId}
# operationId: deleteRemoteIssueLinkById
export def "delete-remote-issue-link-by-id" [
  issue_id_or_key: string
  link_id: string
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
    path: "/api/2/issue/{issueIdOrKey}/remotelink/{linkId}"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}, {name: linkId, var: link_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key, link_id: $link_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the remote issue link with the given id on the issue.
#
# GET /api/2/issue/{issueIdOrKey}/remotelink/{linkId}
# operationId: getRemoteIssueLinkById
export def "get-remote-issue-link-by-id" [
  issue_id_or_key: string
  link_id: string
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
    path: "/api/2/issue/{issueIdOrKey}/remotelink/{linkId}"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}, {name: linkId, var: link_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key, link_id: $link_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a remote issue link from a JSON representation. Any fields not provided are set to null.
#
# PUT /api/2/issue/{issueIdOrKey}/remotelink/{linkId}
# operationId: updateRemoteIssueLink
export def "update-remote-issue-link" [
  issue_id_or_key: string
  link_id: string
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
    method: put
    path: "/api/2/issue/{issueIdOrKey}/remotelink/{linkId}"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}, {name: linkId, var: link_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key, link_id: $link_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an issue's subtask list
#
# GET /api/2/issue/{issueIdOrKey}/subtask
# operationId: getSubTasks
export def "get-sub-tasks" [
  issue_id_or_key: string
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
    path: "/api/2/issue/{issueIdOrKey}/subtask"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/2/issue/{issueIdOrKey}/subtask/move
#
# operationId: canMoveSubTask
export def "can-move-sub-task" [
  issue_id_or_key: string
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
    path: "/api/2/issue/{issueIdOrKey}/subtask/move"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reorders an issue's subtasks by moving the subtask at index "from" to index "to".
#
# POST /api/2/issue/{issueIdOrKey}/subtask/move
# operationId: moveSubTasks
export def "move-sub-tasks" [
  issue_id_or_key: string
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
    path: "/api/2/issue/{issueIdOrKey}/subtask/move"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of the transitions possible for this issue by the current user, along with fields that are required and their types. Fields will only be returned if expand=transitions.fields. The fields in the metadata correspond to the fields in the transition screen for that transition. Fields not in the screen will not be in the metadata.
#
# GET /api/2/issue/{issueIdOrKey}/transitions
# operationId: getTransitions
export def "get-transitions" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --transition-id: string
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/issue/{issueIdOrKey}/transitions"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}]
    query: [{name: transitionId, var: transition_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key, transition_id: $transition_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Perform a transition on an issue. When performing the transition you can update or set other issue fields. The fields that can be set on transtion, in either the fields parameter or the update parameter can be determined using the /rest/api/2/issue/{issueIdOrKey}/transitions?expand=transitions.fields resource. If a field is not configured to appear on the transition screen, then it will not be in the transition metadata, and a field validation error will occur if it is submitted.
#
# POST /api/2/issue/{issueIdOrKey}/transitions
# operationId: doTransition
export def "do-transition" [
  issue_id_or_key: string
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
    path: "/api/2/issue/{issueIdOrKey}/transitions"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove your vote from an issue. (i.e. "unvote")
#
# DELETE /api/2/issue/{issueIdOrKey}/votes
# operationId: removeVote
export def "remove-vote" [
  issue_id_or_key: string
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
    path: "/api/2/issue/{issueIdOrKey}/votes"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# A REST sub-resource representing the voters on the issue.
#
# GET /api/2/issue/{issueIdOrKey}/votes
# operationId: getVotes
export def "get-votes" [
  issue_id_or_key: string
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
    path: "/api/2/issue/{issueIdOrKey}/votes"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cast your vote in favour of an issue.
#
# POST /api/2/issue/{issueIdOrKey}/votes
# operationId: addVote
export def "add-vote" [
  issue_id_or_key: string
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
    path: "/api/2/issue/{issueIdOrKey}/votes"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a user from an issue's watcher list.
#
# DELETE /api/2/issue/{issueIdOrKey}/watchers
# operationId: removeWatcher
export def "remove-watcher" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # a String containing the name of the user to remove from the watcher list. Must not be null.
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/2/issue/{issueIdOrKey}/watchers"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}]
    query: [{name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of watchers for the issue with the given key.
#
# GET /api/2/issue/{issueIdOrKey}/watchers
# operationId: getIssueWatchers
export def "get-issue-watchers" [
  issue_id_or_key: string
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
    path: "/api/2/issue/{issueIdOrKey}/watchers"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a user to an issue's watcher list.
#
# POST /api/2/issue/{issueIdOrKey}/watchers
# operationId: addWatcher
export def "add-watcher" [
  issue_id_or_key: string
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
    path: "/api/2/issue/{issueIdOrKey}/watchers"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all work logs for an issue. Note: Work logs won't be returned if the Log work field is hidden for the project.
#
# GET /api/2/issue/{issueIdOrKey}/worklog
# operationId: getIssueWorklog
export def "get-issue-worklog" [
  issue_id_or_key: string
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
    path: "/api/2/issue/{issueIdOrKey}/worklog"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a new worklog entry to an issue.
#
# POST /api/2/issue/{issueIdOrKey}/worklog
# operationId: addWorklog
export def "add-worklog" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --adjust-estimate: string # (optional) allows you to provide specific instructions to update the remaining time estimate of the issue. Valid values are "new" - sets the estimate to a specific value "leave"- leaves the estimate as is "manual" - specify a specific amount to increase remaining estimate by "auto"- Default option. Will automatically adjust the value based on the new timeSpent specified on the worklog
  --new-estimate: string # (required when "new" is selected for adjustEstimate) the new value for the remaining estimate field. e.g. "2d"
  --reduce-by: string # (required when "manual" is selected for adjustEstimate) the amount to reduce the remaining estimate by e.g. "2d"
]: nothing -> any {
  http-request {
    method: post
    path: "/api/2/issue/{issueIdOrKey}/worklog"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}]
    query: [{name: adjustEstimate, var: adjust_estimate}, {name: newEstimate, var: new_estimate}, {name: reduceBy, var: reduce_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key, adjust_estimate: $adjust_estimate, new_estimate: $new_estimate, reduce_by: $reduce_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing worklog entry.
#
# DELETE /api/2/issue/{issueIdOrKey}/worklog/{id}
# operationId: deleteWorklog
export def "delete-worklog" [
  issue_id_or_key: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --adjust-estimate: string # (optional) allows you to provide specific instructions to update the remaining time estimate of the issue. Valid values are "new" - sets the estimate to a specific value "leave"- leaves the estimate as is "manual" - specify a specific amount to increase remaining estimate by "auto"- Default option. Will automatically adjust the value based on the new timeSpent specified on the worklog
  --new-estimate: string # (required when "new" is selected for adjustEstimate) the new value for the remaining estimate field. e.g. "2d"
  --increase-by: string # (required when "manual" is selected for adjustEstimate) the amount to increase the remaining estimate by e.g. "2d"
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/2/issue/{issueIdOrKey}/worklog/{id}"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}, {name: id, var: id}]
    query: [{name: adjustEstimate, var: adjust_estimate}, {name: newEstimate, var: new_estimate}, {name: increaseBy, var: increase_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key, id: $id, adjust_estimate: $adjust_estimate, new_estimate: $new_estimate, increase_by: $increase_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a specific worklog. Note: The work log won't be returned if the Log work field is hidden for the project.
#
# GET /api/2/issue/{issueIdOrKey}/worklog/{id}
# operationId: getWorklog
export def "get-worklog" [
  issue_id_or_key: string
  id: string
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
    path: "/api/2/issue/{issueIdOrKey}/worklog/{id}"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing worklog entry. Note that: Fields possible for editing are: comment, visibility, started, timeSpent and timeSpentSeconds. Either timeSpent or timeSpentSeconds can be set. Fields which are not set will not be updated. For a request to be valid, it has to have at least one field change.
#
# PUT /api/2/issue/{issueIdOrKey}/worklog/{id}
# operationId: updateWorklog
export def "update-worklog" [
  issue_id_or_key: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --adjust-estimate: string # (optional) allows you to provide specific instructions to update the remaining time estimate of the issue. Valid values are "new" - sets the estimate to a specific value "leave"- leaves the estimate as is "auto"- Default option. Will automatically adjust the value based on the new timeSpent specified on the worklog
  --new-estimate: string # (required when "new" is selected for adjustEstimate) the new value for the remaining estimate field.
]: nothing -> any {
  http-request {
    method: put
    path: "/api/2/issue/{issueIdOrKey}/worklog/{id}"
    path_params: [{name: issueIdOrKey, var: issue_id_or_key}, {name: id, var: id}]
    query: [{name: adjustEstimate, var: adjust_estimate}, {name: newEstimate, var: new_estimate}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id_or_key: $issue_id_or_key, id: $id, adjust_estimate: $adjust_estimate, new_estimate: $new_estimate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an issue link between two issues. The user requires the link issue permission for the issue which will be linked to another issue. The specified link type in the request is used to create the link and will create a link from the first issue to the second issue using the outward description. It also create a link from the second issue to the first issue using the inward description of the issue link type. It will add the supplied comment to the first issue. The comment can have a restriction who can view it. If group is specified, only users of this group can view this comment, if roleLevel is specified only users who have the specified role can view this comment. The user who creates the issue link needs to belong to the specified group or have the specified role.
#
# POST /api/2/issueLink
# operationId: linkIssues
export def "link-issues" [
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
    path: "/api/2/issueLink"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an issue link with the specified id. To be able to delete an issue link you must be able to view both issues and must have the link issue permission for at least one of the issues.
#
# DELETE /api/2/issueLink/{linkId}
# operationId: deleteIssueLink
export def "delete-issue-link" [
  link_id: string
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
    path: "/api/2/issueLink/{linkId}"
    path_params: [{name: linkId, var: link_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    link_id: $link_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an issue link with the specified id.
#
# GET /api/2/issueLink/{linkId}
# operationId: getIssueLink
export def "get-issue-link" [
  link_id: string
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
    path: "/api/2/issueLink/{linkId}"
    path_params: [{name: linkId, var: link_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    link_id: $link_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of available issue link types, if issue linking is enabled. Each issue link type has an id, a name and a label for the outward and inward link relationship.
#
# GET /api/2/issueLinkType
# operationId: getIssueLinkTypes
export def "get-issue-link-types" [
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
    path: "/api/2/issueLinkType"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new issue link type.
#
# POST /api/2/issueLinkType
# operationId: createIssueLinkType
export def "create-issue-link-type" [
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
    path: "/api/2/issueLinkType"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the specified issue link type.
#
# DELETE /api/2/issueLinkType/{issueLinkTypeId}
# operationId: deleteIssueLinkType
export def "delete-issue-link-type" [
  issue_link_type_id: string
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
    path: "/api/2/issueLinkType/{issueLinkTypeId}"
    path_params: [{name: issueLinkTypeId, var: issue_link_type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_link_type_id: $issue_link_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns for a given issue link type id all information about this issue link type.
#
# GET /api/2/issueLinkType/{issueLinkTypeId}
# operationId: getIssueLinkType
export def "get-issue-link-type" [
  issue_link_type_id: string
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
    path: "/api/2/issueLinkType/{issueLinkTypeId}"
    path_params: [{name: issueLinkTypeId, var: issue_link_type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_link_type_id: $issue_link_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the specified issue link type.
#
# PUT /api/2/issueLinkType/{issueLinkTypeId}
# operationId: updateIssueLinkType
export def "update-issue-link-type" [
  issue_link_type_id: string
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
    method: put
    path: "/api/2/issueLinkType/{issueLinkTypeId}"
    path_params: [{name: issueLinkTypeId, var: issue_link_type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_link_type_id: $issue_link_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all issue security schemes that are defined.
#
# GET /api/2/issuesecurityschemes
# operationId: getIssueSecuritySchemes
export def "get-issue-security-schemes" [
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
    path: "/api/2/issuesecurityschemes"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the issue security scheme along with that are defined.
#
# GET /api/2/issuesecurityschemes/{id}
export def "get-api-2-issuesecurityschemes-id" [
  id: int
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
    path: "/api/2/issuesecurityschemes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of all issue types visible to the user
#
# GET /api/2/issuetype
# operationId: getIssueAllTypes
export def "get-issue-all-types" [
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
    path: "/api/2/issuetype"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an issue type from a JSON representation and adds the issue newly created issue type to the default issue type scheme.
#
# POST /api/2/issuetype
# operationId: createIssueType
export def "create-issue-type" [
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
    path: "/api/2/issuetype"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified issue type. If the issue type has any associated issues, these issues will be migrated to the alternative issue type specified in the parameter. You can determine the alternative issue types by calling the /rest/api/2/issuetype/{id}/alternatives resource.
#
# DELETE /api/2/issuetype/{id}
export def "delete-api-2-issuetype-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alternative-issue-type-id: string # the id of an issue type to which issues associated with the removed issue type will be migrated.
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/2/issuetype/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: alternativeIssueTypeId, var: alternative_issue_type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, alternative_issue_type_id: $alternative_issue_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a full representation of the issue type that has the given id.
#
# GET /api/2/issuetype/{id}
export def "get-api-2-issuetype-id" [
  id: string
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
    path: "/api/2/issuetype/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified issue type from a JSON representation.
#
# PUT /api/2/issuetype/{id}
# operationId: updateIssueType
export def "update-issue-type" [
  id: string
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
    method: put
    path: "/api/2/issuetype/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of all alternative issue types for the given issue type id. The list will contain these issues types, to which issues assigned to the given issue type can be migrated. The suitable alternatives are issue types which are assigned to the same workflow, the same field configuration and the same screen scheme.
#
# GET /api/2/issuetype/{id}/alternatives
# operationId: getAlternativeIssueTypes
export def "get-alternative-issue-types" [
  id: string
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
    path: "/api/2/issuetype/{id}/alternatives"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Converts temporary avatar into a real avatar
#
# POST /api/2/issuetype/{id}/avatar
export def "post-api-2-issuetype-id-avatar" [
  id: string
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
    path: "/api/2/issuetype/{id}/avatar"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates temporary avatar using multipart. The response is sent back as JSON stored in a textarea. This is because the client uses remote iframing to submit avatars using multipart. So we must send them a valid HTML page back from which the client parses the JSON from. Creating a temporary avatar is part of a 3-step process in uploading a new avatar for an issue type: upload, crop, confirm. This endpoint allows you to use a multipart upload instead of sending the image directly as the request body. You *must* use "avatar" as the name of the upload parameter: curl -c cookiejar.txt -X POST -u admin:admin -H "X-Atlassian-Token: no-check" \ -F "avatar=@mynewavatar.png;type=image/png" \ 'http://localhost:8090/jira/rest/api/2/issuetype/1/avatar/temporary'
#
# POST /api/2/issuetype/{id}/avatar/temporary
export def "post-api-2-issuetype-id-avatar-temporary" [
  id: string
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
    path: "/api/2/issuetype/{id}/avatar/temporary"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the keys of all properties for the issue type identified by the id.
#
# GET /api/2/issuetype/{issueTypeId}/properties
# operationId: getPropertyKeys
export def "get-property-keys" [
  issue_type_id: string
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
    path: "/api/2/issuetype/{issueTypeId}/properties"
    path_params: [{name: issueTypeId, var: issue_type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_type_id: $issue_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the property from the issue type identified by the id. Ths user removing the property is required to have permissions to edit the issue type.
#
# DELETE /api/2/issuetype/{issueTypeId}/properties/{propertyKey}
export def "delete-api-2-issuetype-issue-type-id-properties-property-key" [
  issue_type_id: string
  property_key: string
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
    path: "/api/2/issuetype/{issueTypeId}/properties/{propertyKey}"
    path_params: [{name: issueTypeId, var: issue_type_id}, {name: propertyKey, var: property_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_type_id: $issue_type_id, property_key: $property_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the value of the property with a given key from the issue type identified by the id. The user who retrieves the property is required to have permissions to view the issue type.
#
# GET /api/2/issuetype/{issueTypeId}/properties/{propertyKey}
export def "get-api-2-issuetype-issue-type-id-properties-property-key" [
  issue_type_id: string
  property_key: string
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
    path: "/api/2/issuetype/{issueTypeId}/properties/{propertyKey}"
    path_params: [{name: issueTypeId, var: issue_type_id}, {name: propertyKey, var: property_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_type_id: $issue_type_id, property_key: $property_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the value of the specified issue type's property. You can use this resource to store a custom data against an issue type identified by the id. The user who stores the data is required to have permissions to edit an issue type.
#
# PUT /api/2/issuetype/{issueTypeId}/properties/{propertyKey}
export def "put-api-2-issuetype-issue-type-id-properties-property-key" [
  issue_type_id: string
  property_key: string
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
    method: put
    path: "/api/2/issuetype/{issueTypeId}/properties/{propertyKey}"
    path_params: [{name: issueTypeId, var: issue_type_id}, {name: propertyKey, var: property_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_type_id: $issue_type_id, property_key: $property_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the auto complete data required for JQL searches.
#
# GET /api/2/jql/autocompletedata
# operationId: getAutoComplete
export def "get-auto-complete" [
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
    path: "/api/2/jql/autocompletedata"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns auto complete suggestions for JQL search.
#
# GET /api/2/jql/autocompletedata/suggestions
# operationId: getFieldAutoCompleteForQueryString
export def "get-field-auto-complete-for-query-string" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --field-name: string # the field name for which the suggestions are generated.
  --field-value: string # the portion of the field value that has already been provided by the user.
  --predicate-name: string # the predicate for which the suggestions are generated. Suggestions are generated only for: "by", "from" and "to".
  --predicate-value: string # the portion of the predicate value that has already been provided by the user.
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/jql/autocompletedata/suggestions"
    query: [{name: fieldName, var: field_name}, {name: fieldValue, var: field_value}, {name: predicateName, var: predicate_name}, {name: predicateValue, var: predicate_value}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    field_name: $field_name, field_value: $field_value, predicate_name: $predicate_name, predicate_value: $predicate_value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/2/licenseValidator
#
# operationId: validate
export def "validate" [
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
    path: "/api/2/licenseValidator"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/2/monitoring/jmx/areMetricsExposed
#
# operationId: areMetricsExposed
export def "are-metrics-exposed" [
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
    path: "/api/2/monitoring/jmx/areMetricsExposed"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/2/monitoring/jmx/getAvailableMetrics
#
# operationId: getAvailableMetrics
export def "get-available-metrics" [
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
    path: "/api/2/monitoring/jmx/getAvailableMetrics"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/2/monitoring/jmx/startExposing
#
# operationId: start
export def "get-api-2-monitoring-jmx-start-exposing" [
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
    path: "/api/2/monitoring/jmx/startExposing"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/2/monitoring/jmx/stopExposing
#
# operationId: stop
export def "stop" [
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
    path: "/api/2/monitoring/jmx/stopExposing"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all permissions in the system and whether the currently logged in user has them. You can optionally provide a specific context to get permissions for (projectKey OR projectId OR issueKey OR issueId) When no context supplied the project related permissions will return true if the user has that permission in ANY project If a project context is provided, project related permissions will return true if the user has the permissions in the specified project. For permissions that are determined using issue data (e.g Current Assignee), true will be returned if the user meets the permission criteria in ANY issue in that project If an issue context is provided, it will return whether or not the user has each permission in that specific issue NB: The above means that for issue-level permissions (EDIT_ISSUE for example), hasPermission may be true when no context is provided, or when a project context is provided, but may be false for any given (or all) issues. This would occur (for example) if Reporters were given the EDIT_ISSUE permission. This is because any user could be a reporter, except in the context of a concrete issue, where the reporter is known. Global permissions will still be returned for all scopes. Prior to version 6.4 this service returned project permissions with keys corresponding to com.atlassian.jira.security.Permissions.Permission constants. Since 6.4 those keys are considered deprecated and this service returns system project permission keys corresponding to constants defined in com.atlassian.jira.permission.ProjectPermissions. Permissions with legacy keys are still also returned for backwards compatibility, they are marked with an attribute deprecatedKey=true. The attribute is missing for project permissions with the current keys.
#
# GET /api/2/mypermissions
# operationId: getPermissions
export def "get-permissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-key: string # - key of project to scope returned permissions for.
  --project-id: string # - id of project to scope returned permissions for.
  --issue-key: string # - key of the issue to scope returned permissions for.
  --issue-id: string # - id of the issue to scope returned permissions for.
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/mypermissions"
    query: [{name: projectKey, var: project_key}, {name: projectId, var: project_id}, {name: issueKey, var: issue_key}, {name: issueId, var: issue_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, project_id: $project_id, issue_key: $issue_key, issue_id: $issue_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes preference of the currently logged in user. Preference key must be provided as input parameters (key). If key parameter is not provided or wrong - status code 404. If preference is unset - status code 204.
#
# DELETE /api/2/mypreferences
# operationId: removePreference
export def "remove-preference" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # - key of the preference to be removed.
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/2/mypreferences"
    query: [{name: key, var: key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns preference of the currently logged in user. Preference key must be provided as input parameter (key). The value is returned exactly as it is. If key parameter is not provided or wrong - status code 404. If value is found - status code 200.
#
# GET /api/2/mypreferences
# operationId: getPreference
export def "get-preference" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # - key of the preference to be returned.
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/mypreferences"
    query: [{name: key, var: key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets preference of the currently logged in user. Preference key must be provided as input parameters (key). Value must be provided as post body. If key or value parameter is not provided - status code 404. If preference is set - status code 204.
#
# PUT /api/2/mypreferences
# operationId: setPreference
export def "set-preference" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # - key of the preference to be set.
]: nothing -> any {
  http-request {
    method: put
    path: "/api/2/mypreferences"
    query: [{name: key, var: key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns currently logged user. This resource cannot be accessed anonymously.
#
# GET /api/2/myself
export def "get-api-2-myself" [
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
    path: "/api/2/myself"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify currently logged user. The "value" fields present will override the existing value. Fields skipped in request will not be changed. Only email and display name can be change that way. Requires user password.
#
# PUT /api/2/myself
export def "put-api-2-myself" [
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
    method: put
    path: "/api/2/myself"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify caller password.
#
# PUT /api/2/myself/password
# operationId: changeMyPassword
export def "change-my-password" [
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
    method: put
    path: "/api/2/myself/password"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a paginated (#pagination) list of notification schemes. In order to access notification scheme, the calling user is required to have permissions to administer at least one project associated with the requested notification scheme. Each scheme contains a list of events and recipient configured to receive notifications for these events. Consumer should allow events without recipients to appear in response. The list is ordered by the scheme's name. Follow the documentation of /notificationscheme/{id} resource for all details about returned value.
#
# GET /api/2/notificationscheme
# operationId: getNotificationSchemes
export def "get-notification-schemes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # the index of the first notification scheme to return (0 based). (format: int64)
  --max-results: int # the maximum number of notification schemes to return (max 50). (format: int32)
  --expand: string
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/notificationscheme"
    query: [{name: startAt, var: start_at}, {name: maxResults, var: max_results}, {name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_at: $start_at, max_results: $max_results, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a full representation of the notification scheme for the given id. This resource will return a notification scheme containing a list of events and recipient configured to receive notifications for these events. Consumer should allow events without recipients to appear in response. User accessing the data is required to have permissions to administer at least one project associated with the requested notification scheme. Notification recipients can be: current assignee - the value of the notificationType is CurrentAssignee issue reporter - the value of the notificationType is Reporter current user - the value of the notificationType is CurrentUser project lead - the value of the notificationType is ProjectLead component lead - the value of the notificationType is ComponentLead all watchers - the value of the notification type is AllWatchers configured user - the value of the notification type is User. Parameter will contain key of the user. Information about the user will be provided if user expand parameter is used. configured group - the value of the notification type is Group. Parameter will contain name of the group. Information about the group will be provided if group expand parameter is used. configured email address - the value of the notification type is EmailAddress, additionally information about the email will be provided. users or users in groups in the configured custom fields - the value of the notification type is UserCustomField or GroupCustomField. Parameter will contain id of the custom field. Information about the field will be provided if field expand parameter is used. configured project role - the value of the notification type is ProjectRole. Parameter will contain project role id. Information about the project role will be provided if projectRole expand parameter is used. Please see the example for reference. The events can be JIRA system events or events configured by administrator. In case of the system events, data about theirs ids, names and descriptions is provided. In case of custom events, the template event is included as well.
#
# GET /api/2/notificationscheme/{id}
export def "get-api-2-notificationscheme-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/notificationscheme/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of requirements for the current password policy. For example, "The password must have at least 10 characters.", "The password must not be similar to the user's name or email address.", etc.
#
# GET /api/2/password/policy
# operationId: getPasswordPolicy
export def "get-password-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --has-old-password: oneof<nothing, bool> # whether or not the user will be required to enter their current password. Use {@code false} (the default) if this is a new user or if an administrator is forcibly changing another user's password. (default: false)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/password/policy"
    query: [{name: hasOldPassword, var: has_old_password}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    has_old_password: $has_old_password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of statements explaining why the password policy would disallow a proposed password for a new user. You can use this method to test the password policy validation. This could be done prior to an action where a new user and related password are created, using methods like the ones in UserService (https://docs.atlassian.com/jira/latest/com/atlassian/jira/bc/user/UserService.html). For example, you could use this to validate a password in a create user form in the user interface, as the user enters it. The username and new password must be not empty to perform the validation. Note, this method will help you validate against the policy only. It won't check any other validations that might be performed when creating a new user, e.g. checking whether a user with the same name already exists.
#
# POST /api/2/password/policy/createUser
# operationId: policyCheckCreateUser
export def "policy-check-create-user" [
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
    path: "/api/2/password/policy/createUser"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of statements explaining why the password policy would disallow a proposed new password for a user with an existing password. You can use this method to test the password policy validation. This could be done prior to an action where the password is actually updated, using methods like ChangePassword (https://docs.atlassian.com/jira/latest/com/atlassian/jira/web/action/user/ChangePassword.html) or ResetPassword (https://docs.atlassian.com/jira/latest/com/atlassian/jira/web/action/user/ResetPassword.html). For example, you could use this to validate a password in a change password form in the user interface, as the user enters it. The user must exist and the username and new password must be not empty, to perform the validation. Note, this method will help you validate against the policy only. It won't check any other validations that might be performed when submitting a password change/reset request, e.g. verifying whether the old password is valid.
#
# POST /api/2/password/policy/updateUser
# operationId: policyCheckUpdateUser
export def "policy-check-update-user" [
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
    path: "/api/2/password/policy/updateUser"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all permissions that are present in the JIRA instance - Global, Project and the global ones added by plugins
#
# GET /api/2/permissions
# operationId: getAllPermissions
export def "get-all-permissions" [
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
    path: "/api/2/permissions"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of all permission schemes. By default only shortened beans are returned. If you want to include permissions of all the schemes, then specify the permissions expand parameter. Permissions will be included also if you specify any other expand parameter.
#
# GET /api/2/permissionscheme
# operationId: getPermissionSchemes
export def "get-permission-schemes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/permissionscheme"
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new permission scheme. This method can create schemes with a defined permission set, or without.
#
# POST /api/2/permissionscheme
# operationId: createPermissionScheme
export def "create-permission-scheme" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> any {
  http-request {
    method: post
    path: "/api/2/permissionscheme"
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/2/permissionscheme/{permissionSchemeId}/attribute/{attributeKey}
#
# operationId: getSchemeAttribute
export def "get-scheme-attribute" [
  permission_scheme_id: int
  attribute_key: string
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
    path: "/api/2/permissionscheme/{permissionSchemeId}/attribute/{attributeKey}"
    path_params: [{name: permissionSchemeId, var: permission_scheme_id}, {name: attributeKey, var: attribute_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    permission_scheme_id: $permission_scheme_id, attribute_key: $attribute_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates or inserts the attribute for a permission scheme specified by permission scheme id. The attribute consists of the key and the value. The value will be converted to Boolean using Boolean#valueOf.
#
# PUT /api/2/permissionscheme/{permissionSchemeId}/attribute/{key}
# operationId: setSchemeAttribute
export def "set-scheme-attribute" [
  permission_scheme_id: int
  key: string
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
    method: put
    path: "/api/2/permissionscheme/{permissionSchemeId}/attribute/{key}"
    path_params: [{name: permissionSchemeId, var: permission_scheme_id}, {name: key, var: key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    permission_scheme_id: $permission_scheme_id, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a permission scheme identified by the given id.
#
# DELETE /api/2/permissionscheme/{schemeId}
# operationId: deletePermissionScheme
export def "delete-permission-scheme" [
  scheme_id: int
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
    path: "/api/2/permissionscheme/{schemeId}"
    path_params: [{name: schemeId, var: scheme_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    scheme_id: $scheme_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a permission scheme identified by the given id.
#
# GET /api/2/permissionscheme/{schemeId}
# operationId: getPermissionScheme
export def "get-permission-scheme" [
  scheme_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/permissionscheme/{schemeId}"
    path_params: [{name: schemeId, var: scheme_id}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    scheme_id: $scheme_id, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a permission scheme. If the permissions list is present then it will be set in the permission scheme, which basically means it will overwrite any permission grants that existed in the permission scheme. Sending an empty list will remove all permission grants from the permission scheme. To update just the name and description, do not send permissions list at all. To add or remove a single permission grant instead of updating the whole list at once use the {schemeId}/permission/ resource.
#
# PUT /api/2/permissionscheme/{schemeId}
# operationId: updatePermissionScheme
export def "update-permission-scheme" [
  scheme_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> any {
  http-request {
    method: put
    path: "/api/2/permissionscheme/{schemeId}"
    path_params: [{name: schemeId, var: scheme_id}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    scheme_id: $scheme_id, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all permission grants of the given permission scheme.
#
# GET /api/2/permissionscheme/{schemeId}/permission
# operationId: getPermissionSchemeGrants
export def "get-permission-scheme-grants" [
  scheme_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/permissionscheme/{schemeId}/permission"
    path_params: [{name: schemeId, var: scheme_id}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    scheme_id: $scheme_id, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a permission grant in a permission scheme.
#
# POST /api/2/permissionscheme/{schemeId}/permission
# operationId: createPermissionGrant
export def "create-permission-grant" [
  scheme_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> any {
  http-request {
    method: post
    path: "/api/2/permissionscheme/{schemeId}/permission"
    path_params: [{name: schemeId, var: scheme_id}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    scheme_id: $scheme_id, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a permission grant from a permission scheme.
#
# DELETE /api/2/permissionscheme/{schemeId}/permission/{permissionId}
# operationId: deletePermissionSchemeEntity
export def "delete-permission-scheme-entity" [
  scheme_id: int
  permission_id: int
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
    path: "/api/2/permissionscheme/{schemeId}/permission/{permissionId}"
    path_params: [{name: schemeId, var: scheme_id}, {name: permissionId, var: permission_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    scheme_id: $scheme_id, permission_id: $permission_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a permission grant identified by the given id.
#
# GET /api/2/permissionscheme/{schemeId}/permission/{permissionId}
# operationId: getPermissionSchemeGrant
export def "get-permission-scheme-grant" [
  scheme_id: int
  permission_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/permissionscheme/{schemeId}/permission/{permissionId}"
    path_params: [{name: schemeId, var: scheme_id}, {name: permissionId, var: permission_id}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    scheme_id: $scheme_id, permission_id: $permission_id, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of all issue priorities.
#
# GET /api/2/priority
# operationId: getPriorities
export def "get-priorities" [
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
    path: "/api/2/priority"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an issue priority.
#
# GET /api/2/priority/{id}
# operationId: getPriority
export def "get-priority" [
  id: string
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
    path: "/api/2/priority/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all projects which are visible for the currently logged in user. If no user is logged in, it returns the list of projects that are visible when using anonymous access.
#
# GET /api/2/project
# operationId: getAllProjects
export def "get-all-projects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # the parameters to expand
  --recent: int # if this parameter is set then only projects recently accessed by the current user (if not logged in then based on HTTP session) will be returned (maximum count limited to the specified number but no more than 20). (format: int32)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/project"
    query: [{name: expand, var: expand}, {name: recent, var: recent}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expand: $expand, recent: $recent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new project.
#
# POST /api/2/project
# operationId: createProject
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
]: nothing -> any {
  http-request {
    method: post
    path: "/api/2/project"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all the project types defined on the JIRA instance, not taking into account whether the license to use those project types is valid or not.
#
# GET /api/2/project/type
# operationId: getAllProjectTypes
export def "get-all-project-types" [
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
    path: "/api/2/project/type"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the project type with the given key.
#
# GET /api/2/project/type/{projectTypeKey}
# operationId: getProjectTypeByKey
export def "get-project-type-by-key" [
  project_type_key: string
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
    path: "/api/2/project/type/{projectTypeKey}"
    path_params: [{name: projectTypeKey, var: project_type_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_type_key: $project_type_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the project type with the given key, if it is accessible to the logged in user. This takes into account whether the user is licensed on the Application that defines the project type.
#
# GET /api/2/project/type/{projectTypeKey}/accessible
# operationId: getAccessibleProjectTypeByKey
export def "get-accessible-project-type-by-key" [
  project_type_key: string
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
    path: "/api/2/project/type/{projectTypeKey}/accessible"
    path_params: [{name: projectTypeKey, var: project_type_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_type_key: $project_type_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a project.
#
# DELETE /api/2/project/{projectIdOrKey}
# operationId: deleteProject
export def "delete-project" [
  project_id_or_key: string
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
    path: "/api/2/project/{projectIdOrKey}"
    path_params: [{name: projectIdOrKey, var: project_id_or_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id_or_key: $project_id_or_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Contains a full representation of a project in JSON format. All project keys associated with the project will only be returned if expand=projectKeys.
#
# GET /api/2/project/{projectIdOrKey}
export def "get-api-2-project-project-id-or-key" [
  project_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # the parameters to expand
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/project/{projectIdOrKey}"
    path_params: [{name: projectIdOrKey, var: project_id_or_key}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id_or_key: $project_id_or_key, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a project. Only non null values sent in JSON will be updated in the project. Values available for the assigneeType field are: "PROJECT_LEAD" and "UNASSIGNED".
#
# PUT /api/2/project/{projectIdOrKey}
# operationId: updateProject
export def "update-project" [
  project_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # the parameters to expand in returned project
]: nothing -> any {
  http-request {
    method: put
    path: "/api/2/project/{projectIdOrKey}"
    path_params: [{name: projectIdOrKey, var: project_id_or_key}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id_or_key: $project_id_or_key, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Converts temporary avatar into a real avatar
#
# POST /api/2/project/{projectIdOrKey}/avatar
export def "post-api-2-project-project-id-or-key-avatar" [
  project_id_or_key: string
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
    path: "/api/2/project/{projectIdOrKey}/avatar"
    path_params: [{name: projectIdOrKey, var: project_id_or_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id_or_key: $project_id_or_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /api/2/project/{projectIdOrKey}/avatar
export def "put-api-2-project-project-id-or-key-avatar" [
  project_id_or_key: string
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
    method: put
    path: "/api/2/project/{projectIdOrKey}/avatar"
    path_params: [{name: projectIdOrKey, var: project_id_or_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id_or_key: $project_id_or_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates temporary avatar using multipart. The response is sent back as JSON stored in a textarea. This is because the client uses remote iframing to submit avatars using multipart. So we must send them a valid HTML page back from which the client parses the JSON.
#
# POST /api/2/project/{projectIdOrKey}/avatar/temporary
export def "post-api-2-project-project-id-or-key-avatar-temporary" [
  project_id_or_key: string
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
    path: "/api/2/project/{projectIdOrKey}/avatar/temporary"
    path_params: [{name: projectIdOrKey, var: project_id_or_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id_or_key: $project_id_or_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes avatar
#
# DELETE /api/2/project/{projectIdOrKey}/avatar/{id}
export def "delete-api-2-project-project-id-or-key-avatar-id" [
  project_id_or_key: string
  id: int
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
    path: "/api/2/project/{projectIdOrKey}/avatar/{id}"
    path_params: [{name: projectIdOrKey, var: project_id_or_key}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id_or_key: $project_id_or_key, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all avatars which are visible for the currently logged in user. The avatars are grouped into system and custom.
#
# GET /api/2/project/{projectIdOrKey}/avatars
export def "get-api-2-project-project-id-or-key-avatars" [
  project_id_or_key: string
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
    path: "/api/2/project/{projectIdOrKey}/avatars"
    path_params: [{name: projectIdOrKey, var: project_id_or_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id_or_key: $project_id_or_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Contains a full representation of a the specified project's components.
#
# GET /api/2/project/{projectIdOrKey}/components
# operationId: getProjectComponents
export def "get-project-components" [
  project_id_or_key: string
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
    path: "/api/2/project/{projectIdOrKey}/components"
    path_params: [{name: projectIdOrKey, var: project_id_or_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id_or_key: $project_id_or_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the keys of all properties for the project identified by the key or by the id.
#
# GET /api/2/project/{projectIdOrKey}/properties
export def "get-api-2-project-project-id-or-key-properties" [
  project_id_or_key: string
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
    path: "/api/2/project/{projectIdOrKey}/properties"
    path_params: [{name: projectIdOrKey, var: project_id_or_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id_or_key: $project_id_or_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the property from the project identified by the key or by the id. Ths user removing the property is required to have permissions to administer the project.
#
# DELETE /api/2/project/{projectIdOrKey}/properties/{propertyKey}
export def "delete-api-2-project-project-id-or-key-properties-property-key" [
  project_id_or_key: string
  property_key: string
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
    path: "/api/2/project/{projectIdOrKey}/properties/{propertyKey}"
    path_params: [{name: projectIdOrKey, var: project_id_or_key}, {name: propertyKey, var: property_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id_or_key: $project_id_or_key, property_key: $property_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the value of the property with a given key from the project identified by the key or by the id. The user who retrieves the property is required to have permissions to read the project.
#
# GET /api/2/project/{projectIdOrKey}/properties/{propertyKey}
export def "get-api-2-project-project-id-or-key-properties-property-key" [
  project_id_or_key: string
  property_key: string
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
    path: "/api/2/project/{projectIdOrKey}/properties/{propertyKey}"
    path_params: [{name: projectIdOrKey, var: project_id_or_key}, {name: propertyKey, var: property_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id_or_key: $project_id_or_key, property_key: $property_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the value of the specified project's property. You can use this resource to store a custom data against the project identified by the key or by the id. The user who stores the data is required to have permissions to administer the project.
#
# PUT /api/2/project/{projectIdOrKey}/properties/{propertyKey}
export def "put-api-2-project-project-id-or-key-properties-property-key" [
  project_id_or_key: string
  property_key: string
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
    method: put
    path: "/api/2/project/{projectIdOrKey}/properties/{propertyKey}"
    path_params: [{name: projectIdOrKey, var: project_id_or_key}, {name: propertyKey, var: property_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id_or_key: $project_id_or_key, property_key: $property_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all roles in the given project Id or key, with links to full details on each role.
#
# GET /api/2/project/{projectIdOrKey}/role
export def "get-api-2-project-project-id-or-key-role" [
  project_id_or_key: string
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
    path: "/api/2/project/{projectIdOrKey}/role"
    path_params: [{name: projectIdOrKey, var: project_id_or_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id_or_key: $project_id_or_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes actors (users or groups) from a project role. Delete a user from the role: /rest/api/2/project/{projectIdOrKey}/role/{roleId}?user={username} Delete a group from the role: /rest/api/2/project/{projectIdOrKey}/role/{roleId}?group={groupname}
#
# DELETE /api/2/project/{projectIdOrKey}/role/{id}
# operationId: deleteActor
export def "delete-actor" [
  project_id_or_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: string # the username to remove from the project role
  --group: string # the groupname to remove from the project role
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/2/project/{projectIdOrKey}/role/{id}"
    path_params: [{name: projectIdOrKey, var: project_id_or_key}, {name: id, var: id}]
    query: [{name: user, var: user}, {name: group, var: group}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id_or_key: $project_id_or_key, id: $id, user: $user, group: $group
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the details for a given project role in a project.
#
# GET /api/2/project/{projectIdOrKey}/role/{id}
# operationId: getProjectRole
export def "get-project-role" [
  project_id_or_key: string
  id: int
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
    path: "/api/2/project/{projectIdOrKey}/role/{id}"
    path_params: [{name: projectIdOrKey, var: project_id_or_key}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id_or_key: $project_id_or_key, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds an actor (user or group) to a project role.
#
# POST /api/2/project/{projectIdOrKey}/role/{id}
# operationId: addActorUsers
export def "add-actor-users" [
  project_id_or_key: string
  id: int
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
    path: "/api/2/project/{projectIdOrKey}/role/{id}"
    path_params: [{name: projectIdOrKey, var: project_id_or_key}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id_or_key: $project_id_or_key, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a project role to include the specified actors (users or groups).
#
# PUT /api/2/project/{projectIdOrKey}/role/{id}
# operationId: setActors
export def "set-actors" [
  project_id_or_key: string
  id: int
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
    method: put
    path: "/api/2/project/{projectIdOrKey}/role/{id}"
    path_params: [{name: projectIdOrKey, var: project_id_or_key}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id_or_key: $project_id_or_key, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all issue types with valid status values for a project
#
# GET /api/2/project/{projectIdOrKey}/statuses
# operationId: getAllStatuses
export def "get-all-statuses" [
  project_id_or_key: string
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
    path: "/api/2/project/{projectIdOrKey}/statuses"
    path_params: [{name: projectIdOrKey, var: project_id_or_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id_or_key: $project_id_or_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the type of a project.
#
# PUT /api/2/project/{projectIdOrKey}/type/{newProjectTypeKey}
# operationId: updateProjectType
export def "update-project-type" [
  project_id_or_key: string
  new_project_type_key: string
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
    method: put
    path: "/api/2/project/{projectIdOrKey}/type/{newProjectTypeKey}"
    path_params: [{name: projectIdOrKey, var: project_id_or_key}, {name: newProjectTypeKey, var: new_project_type_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id_or_key: $project_id_or_key, new_project_type_key: $new_project_type_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all versions for the specified project. Results are paginated (#pagination). Results can be ordered by the following fields: sequence name startDate releaseDate
#
# GET /api/2/project/{projectIdOrKey}/version
# operationId: getProjectVersionsPaginated
export def "get-project-versions-paginated" [
  project_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # the page offset, if not specified then defaults to 0 (format: int64)
  --max-results: int # how many results on the page should be included. Defaults to 50. (format: int32)
  --order-by: string # ordering of the results.
  --expand: string # the parameters to expand
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/project/{projectIdOrKey}/version"
    path_params: [{name: projectIdOrKey, var: project_id_or_key}]
    query: [{name: startAt, var: start_at}, {name: maxResults, var: max_results}, {name: orderBy, var: order_by}, {name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id_or_key: $project_id_or_key, start_at: $start_at, max_results: $max_results, order_by: $order_by, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Contains a full representation of a the specified project's versions.
#
# GET /api/2/project/{projectIdOrKey}/versions
# operationId: getProjectVersions
export def "get-project-versions" [
  project_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # the parameters to expand
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/project/{projectIdOrKey}/versions"
    path_params: [{name: projectIdOrKey, var: project_id_or_key}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id_or_key: $project_id_or_key, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the issue security scheme for project.
#
# GET /api/2/project/{projectKeyOrId}/issuesecuritylevelscheme
export def "get-api-2-project-project-key-or-id-issuesecuritylevelscheme" [
  project_key_or_id: string
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
    path: "/api/2/project/{projectKeyOrId}/issuesecuritylevelscheme"
    path_params: [{name: projectKeyOrId, var: project_key_or_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key_or_id: $project_key_or_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a notification scheme associated with the project. Follow the documentation of /notificationscheme/{id} resource for all details about returned value.
#
# GET /api/2/project/{projectKeyOrId}/notificationscheme
export def "get-api-2-project-project-key-or-id-notificationscheme" [
  project_key_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/project/{projectKeyOrId}/notificationscheme"
    path_params: [{name: projectKeyOrId, var: project_key_or_id}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key_or_id: $project_key_or_id, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a permission scheme assigned with a project.
#
# GET /api/2/project/{projectKeyOrId}/permissionscheme
# operationId: getAssignedPermissionScheme
export def "get-assigned-permission-scheme" [
  project_key_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/project/{projectKeyOrId}/permissionscheme"
    path_params: [{name: projectKeyOrId, var: project_key_or_id}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key_or_id: $project_key_or_id, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assigns a permission scheme with a project.
#
# PUT /api/2/project/{projectKeyOrId}/permissionscheme
# operationId: assignPermissionScheme
export def "assign-permission-scheme" [
  project_key_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> any {
  http-request {
    method: put
    path: "/api/2/project/{projectKeyOrId}/permissionscheme"
    path_params: [{name: projectKeyOrId, var: project_key_or_id}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key_or_id: $project_key_or_id, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all security levels for the project that the current logged in user has access to. If the user does not have the Set Issue Security permission, the list will be empty.
#
# GET /api/2/project/{projectKeyOrId}/securitylevel
# operationId: getSecurityLevelsForProject
export def "get-security-levels-for-project" [
  project_key_or_id: string
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
    path: "/api/2/project/{projectKeyOrId}/securitylevel"
    path_params: [{name: projectKeyOrId, var: project_key_or_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key_or_id: $project_key_or_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all project categories
#
# GET /api/2/projectCategory
# operationId: getAllProjectCategories
export def "get-all-project-categories" [
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
    path: "/api/2/projectCategory"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a project category via POST.
#
# POST /api/2/projectCategory
# operationId: createProjectCategory
export def "create-project-category" [
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
    path: "/api/2/projectCategory"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a project category.
#
# DELETE /api/2/projectCategory/{id}
# operationId: removeProjectCategory
export def "remove-project-category" [
  id: int
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
    path: "/api/2/projectCategory/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Contains a representation of a project category in JSON format.
#
# GET /api/2/projectCategory/{id}
# operationId: getProjectCategoryById
export def "get-project-category-by-id" [
  id: int
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
    path: "/api/2/projectCategory/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a project category via PUT. Any fields present in the PUT will override existing values. As a convenience, if a field is not present, it is silently ignored.
#
# PUT /api/2/projectCategory/{id}
# operationId: updateProjectCategory
export def "update-project-category" [
  id: int
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
    method: put
    path: "/api/2/projectCategory/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validates a project key.
#
# GET /api/2/projectvalidate/key
export def "get-api-2-projectvalidate-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # the project key
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/projectvalidate/key"
    query: [{name: key, var: key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information on the system reindexes. If a reindex is currently taking place then information about this reindex is returned. If there is no active index task, then returns information about the latest reindex task run, otherwise returns a 404 indicating that no reindex has taken place.
#
# GET /api/2/reindex
# operationId: getReindexInfo
export def "get-reindex-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --task-id: int # the id of an indexing task you wish to obtain details on. If omitted, then defaults to the standard behaviour and returns information on the active reindex task, or the last task to run if no reindex is taking place. . If there is no reindexing task with that id then a 404 is returned. (format: int64)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/reindex"
    query: [{name: taskId, var: task_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Kicks off a reindex. Need Admin permissions to perform this reindex.
#
# POST /api/2/reindex
# operationId: reindex
export def "reindex" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # Case insensitive String indicating type of reindex. If omitted, then defaults to BACKGROUND_PREFERRED.
  --index-comments: oneof<nothing, bool> # Indicates that comments should also be reindexed. Not relevant for foreground reindex, where comments are always reindexed. (default: false)
  --index-change-history: oneof<nothing, bool> # Indicates that changeHistory should also be reindexed. Not relevant for foreground reindex, where changeHistory is always reindexed. (default: false)
  --index-worklogs: oneof<nothing, bool> # Indicates that changeHistory should also be reindexed. Not relevant for foreground reindex, where changeHistory is always reindexed. (default: false)
]: nothing -> any {
  http-request {
    method: post
    path: "/api/2/reindex"
    query: [{name: type, var: type}, {name: indexComments, var: index_comments}, {name: indexChangeHistory, var: index_change_history}, {name: indexWorklogs, var: index_worklogs}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, index_comments: $index_comments, index_change_history: $index_change_history, index_worklogs: $index_worklogs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reindexes one or more individual issues. Indexing is performed synchronously - the call returns when indexing of the issues has completed or a failure occurs. Use either explicitly specified issue IDs or a JQL query to select issues to reindex.
#
# POST /api/2/reindex/issue
# operationId: reindexIssues
export def "reindex-issues" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --issue-id: string # the IDs or keys of one or more issues to reindex.
  --index-comments: oneof<nothing, bool> # Indicates that comments should also be reindexed. (default: false)
  --index-change-history: oneof<nothing, bool> # Indicates that changeHistory should also be reindexed. (default: false)
  --index-worklogs: oneof<nothing, bool> # Indicates that changeHistory should also be reindexed. (default: false)
]: nothing -> any {
  http-request {
    method: post
    path: "/api/2/reindex/issue"
    query: [{name: issueId, var: issue_id}, {name: indexComments, var: index_comments}, {name: indexChangeHistory, var: index_change_history}, {name: indexWorklogs, var: index_worklogs}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issue_id: $issue_id, index_comments: $index_comments, index_change_history: $index_change_history, index_worklogs: $index_worklogs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information on the system reindexes. If a reindex is currently taking place then information about this reindex is returned. If there is no active index task, then returns information about the latest reindex task run, otherwise returns a 404 indicating that no reindex has taken place.
#
# GET /api/2/reindex/progress
# operationId: getReindexProgress
export def "get-reindex-progress" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --task-id: int # the id of an indexing task you wish to obtain details on. If omitted, then defaults to the standard behaviour and returns information on the active reindex task, or the last task to run if no reindex is taking place. . If there is no reindexing task with that id then a 404 is returned. (format: int64)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/reindex/progress"
    query: [{name: taskId, var: task_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Executes any pending reindex requests. Returns a JSON array containing the IDs of the reindex requests that are being processed. Execution is asynchronous - progress of the returned tasks can be monitored through other REST calls.
#
# POST /api/2/reindex/request
# operationId: processRequests
export def "process-requests" [
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
    path: "/api/2/reindex/request"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the progress of a multiple reindex requests. Only reindex requests that actually exist will be returned in the results.
#
# GET /api/2/reindex/request/bulk
# operationId: getProgressBulk
export def "get-progress-bulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --request-id: string # the reindex request IDs.
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/reindex/request/bulk"
    query: [{name: requestId, var: request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    request_id: $request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the progress of a single reindex request.
#
# GET /api/2/reindex/request/{requestId}
# operationId: getProgress
export def "get-progress" [
  request_id: int
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
    path: "/api/2/reindex/request/{requestId}"
    path_params: [{name: requestId, var: request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    request_id: $request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of all resolutions.
#
# GET /api/2/resolution
# operationId: getResolutions
export def "get-resolutions" [
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
    path: "/api/2/resolution"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a resolution.
#
# GET /api/2/resolution/{id}
# operationId: getResolution
export def "get-resolution" [
  id: string
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
    path: "/api/2/resolution/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the ProjectRoles available in JIRA. Currently this list is global.
#
# GET /api/2/role
export def "get-api-2-role" [
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
    path: "/api/2/role"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new ProjectRole to be available in JIRA. The created role does not have any default actors assigned.
#
# POST /api/2/role
# operationId: createProjectRole
export def "create-project-role" [
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
    path: "/api/2/role"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a role. May return 403 in the future
#
# DELETE /api/2/role/{id}
# operationId: deleteProjectRole
export def "delete-project-role" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --swap: int # if given, removes a role even if it is used in scheme by replacing the role with the given one (format: int64)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/2/role/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: swap, var: swap}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, swap: $swap
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific ProjectRole available in JIRA.
#
# GET /api/2/role/{id}
# operationId: getProjectRolesById
export def "get-project-roles-by-id" [
  id: int
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
    path: "/api/2/role/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Partially updates a roles name or description.
#
# POST /api/2/role/{id}
# operationId: partialUpdateProjectRole
export def "partial-update-project-role" [
  id: int
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
    path: "/api/2/role/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fully updates a roles. Both name and description must be given.
#
# PUT /api/2/role/{id}
# operationId: fullyUpdateProjectRole
export def "fully-update-project-role" [
  id: int
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
    method: put
    path: "/api/2/role/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes default actor from the given role.
#
# DELETE /api/2/role/{id}/actors
# operationId: deleteProjectRoleActorsFromRole
export def "delete-project-role-actors-from-role" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: string # if given, removes an actor from given role
  --group: string # if given, removes an actor from given role
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/2/role/{id}/actors"
    path_params: [{name: id, var: id}]
    query: [{name: user, var: user}, {name: group, var: group}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, user: $user, group: $group
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets default actors for the given role.
#
# GET /api/2/role/{id}/actors
# operationId: getProjectRoleActorsForRole
export def "get-project-role-actors-for-role" [
  id: int
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
    path: "/api/2/role/{id}/actors"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds default actors to the given role. The request data should contain a list of usernames or a list of groups to add.
#
# POST /api/2/role/{id}/actors
# operationId: addProjectRoleActorsToRole
export def "add-project-role-actors-to-role" [
  id: int
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
    path: "/api/2/role/{id}/actors"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds field or custom field to the default tab
#
# POST /api/2/screens/addToDefault/{fieldId}
# operationId: addFieldToDefaultScreen
export def "add-field-to-default-screen" [
  field_id: string
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
    path: "/api/2/screens/addToDefault/{fieldId}"
    path_params: [{name: fieldId, var: field_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    field_id: $field_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets available fields for screen. i.e ones that haven't already been added.
#
# GET /api/2/screens/{screenId}/availableFields
# operationId: getFieldsToAdd
export def "get-fields-to-add" [
  screen_id: int
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
    path: "/api/2/screens/{screenId}/availableFields"
    path_params: [{name: screenId, var: screen_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    screen_id: $screen_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of all tabs for the given screen
#
# GET /api/2/screens/{screenId}/tabs
# operationId: getAllTabs
export def "get-all-tabs" [
  screen_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-key: string # the key of the project; this parameter is optional
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/screens/{screenId}/tabs"
    path_params: [{name: screenId, var: screen_id}]
    query: [{name: projectKey, var: project_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    screen_id: $screen_id, project_key: $project_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates tab for given screen
#
# POST /api/2/screens/{screenId}/tabs
# operationId: addTab
export def "add-tab" [
  screen_id: int
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
    path: "/api/2/screens/{screenId}/tabs"
    path_params: [{name: screenId, var: screen_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    screen_id: $screen_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes tab to give screen
#
# DELETE /api/2/screens/{screenId}/tabs/{tabId}
# operationId: deleteTab
export def "delete-tab" [
  screen_id: int
  tab_id: int
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
    path: "/api/2/screens/{screenId}/tabs/{tabId}"
    path_params: [{name: screenId, var: screen_id}, {name: tabId, var: tab_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    screen_id: $screen_id, tab_id: $tab_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Renames tab on given screen
#
# PUT /api/2/screens/{screenId}/tabs/{tabId}
# operationId: renameTab
export def "rename-tab" [
  screen_id: int
  tab_id: int
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
    method: put
    path: "/api/2/screens/{screenId}/tabs/{tabId}"
    path_params: [{name: screenId, var: screen_id}, {name: tabId, var: tab_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    screen_id: $screen_id, tab_id: $tab_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all fields for a given tab
#
# GET /api/2/screens/{screenId}/tabs/{tabId}/fields
# operationId: getAllFields
export def "get-all-fields" [
  screen_id: int
  tab_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-key: string # the key of the project; this parameter is optional
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/screens/{screenId}/tabs/{tabId}/fields"
    path_params: [{name: screenId, var: screen_id}, {name: tabId, var: tab_id}]
    query: [{name: projectKey, var: project_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    screen_id: $screen_id, tab_id: $tab_id, project_key: $project_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds field to the given tab.
#
# POST /api/2/screens/{screenId}/tabs/{tabId}/fields
# operationId: addField
export def "add-field" [
  screen_id: int
  tab_id: int
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
    path: "/api/2/screens/{screenId}/tabs/{tabId}/fields"
    path_params: [{name: screenId, var: screen_id}, {name: tabId, var: tab_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    screen_id: $screen_id, tab_id: $tab_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes field from given tab
#
# DELETE /api/2/screens/{screenId}/tabs/{tabId}/fields/{id}
# operationId: removeField
export def "remove-field" [
  screen_id: int
  tab_id: int
  id: string
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
    path: "/api/2/screens/{screenId}/tabs/{tabId}/fields/{id}"
    path_params: [{name: screenId, var: screen_id}, {name: tabId, var: tab_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    screen_id: $screen_id, tab_id: $tab_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Moves field on the given tab
#
# POST /api/2/screens/{screenId}/tabs/{tabId}/fields/{id}/move
# operationId: moveField
export def "move-field" [
  screen_id: int
  tab_id: int
  id: string
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
    path: "/api/2/screens/{screenId}/tabs/{tabId}/fields/{id}/move"
    path_params: [{name: screenId, var: screen_id}, {name: tabId, var: tab_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    screen_id: $screen_id, tab_id: $tab_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Moves tab position
#
# POST /api/2/screens/{screenId}/tabs/{tabId}/move/{pos}
# operationId: moveTab
export def "move-tab" [
  screen_id: int
  tab_id: int
  pos: int
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
    path: "/api/2/screens/{screenId}/tabs/{tabId}/move/{pos}"
    path_params: [{name: screenId, var: screen_id}, {name: tabId, var: tab_id}, {name: pos, var: pos}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    screen_id: $screen_id, tab_id: $tab_id, pos: $pos
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Searches for issues using JQL. Sorting the jql parameter is a full JQL (http://confluence.atlassian.com/display/JIRA/Advanced+Searching) expression, and includes an ORDER BY clause. The fields param (which can be specified multiple times) gives a comma-separated list of fields to include in the response. This can be used to retrieve a subset of fields. A particular field can be excluded by prefixing it with a minus. By default, only navigable (*navigable) fields are returned in this search resource. Note: the default is different in the get-issue resource -- the default there all fields (*all). *all - include all fields *navigable - include just navigable fields summary,comment - include just the summary and comments -description - include navigable fields except the description (the default is *navigable for search) *all,-comment - include everything except comments GET vs POST: If the JQL query is too large to be encoded as a query param you should instead POST to this resource. Expanding Issues in the Search Result: It is possible to expand the issues returned by directly specifying the expansion on the expand parameter passed in to this resources. For instance, to expand the "changelog" for all the issues on the search result, it is neccesary to specify "changelog" as one of the values to expand.
#
# GET /api/2/search
# operationId: search
export def "search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jql: string # a JQL query string
  --start-at: int # the index of the first issue to return (0-based) (format: int32)
  --max-results: int # the maximum number of issues to return (defaults to 50). The maximum allowable value is dictated by the JIRA property 'jira.search.views.default.max'. If you specify a value that is higher than this number, your search results will be truncated. (format: int32)
  --validate-query: oneof<nothing, bool> # whether to validate the JQL query (default: true)
  --fields: string # the list of fields to return for each issue. By default, all navigable fields are returned.
  --expand: string # A comma-separated list of the parameters to expand.
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/search"
    query: [{name: jql, var: jql}, {name: startAt, var: start_at}, {name: maxResults, var: max_results}, {name: validateQuery, var: validate_query}, {name: fields, var: fields}, {name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    jql: $jql, start_at: $start_at, max_results: $max_results, validate_query: $validate_query, fields: $fields, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Performs a search using JQL.
#
# POST /api/2/search
# operationId: searchUsingSearchRequest
export def "search-using-search-request" [
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
    path: "/api/2/search"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a full representation of the security level that has the given id.
#
# GET /api/2/securitylevel/{id}
# operationId: getIssuesecuritylevel
export def "get-issuesecuritylevel" [
  id: string
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
    path: "/api/2/securitylevel/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns general information about the current JIRA server.
#
# GET /api/2/serverInfo
# operationId: getServerInfo
export def "get-server-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --do-health-check: oneof<nothing, bool>
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/serverInfo"
    query: [{name: doHealthCheck, var: do_health_check}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    do_health_check: $do_health_check
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the base URL that is configured for this JIRA instance.
#
# PUT /api/2/settings/baseUrl
# operationId: setBaseURL
export def "set-base-url" [
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
    method: put
    path: "/api/2/settings/baseUrl"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the default system columns for issue navigator. Admin permission will be required.
#
# GET /api/2/settings/columns
# operationId: getIssueNavigatorDefaultColumns
export def "get-issue-navigator-default-columns" [
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
    path: "/api/2/settings/columns"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the default system columns for issue navigator. Admin permission will be required.
#
# PUT /api/2/settings/columns
# operationId: setIssueNavigatorDefaultColumns
export def "set-issue-navigator-default-columns" [
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
    method: put
    path: "/api/2/settings/columns"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of all statuses
#
# GET /api/2/status
# operationId: getStatuses
export def "get-statuses" [
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
    path: "/api/2/status"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a full representation of the Status having the given id or name.
#
# GET /api/2/status/{idOrName}
# operationId: getStatus
export def "get-status" [
  id_or_name: string
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
    path: "/api/2/status/{idOrName}"
    path_params: [{name: idOrName, var: id_or_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_or_name: $id_or_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of all status categories
#
# GET /api/2/statuscategory
# operationId: getStatusCategories
export def "get-status-categories" [
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
    path: "/api/2/statuscategory"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a full representation of the StatusCategory having the given id or key
#
# GET /api/2/statuscategory/{idOrKey}
# operationId: getStatusCategory
export def "get-status-category" [
  id_or_key: string
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
    path: "/api/2/statuscategory/{idOrKey}"
    path_params: [{name: idOrKey, var: id_or_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_or_key: $id_or_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/2/universal_avatar/type/{type}/owner/{owningObjectId}
#
# operationId: getAvatars
export def "get-avatars" [
  type: string
  owning_object_id: string
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
    path: "/api/2/universal_avatar/type/{type}/owner/{owningObjectId}"
    path_params: [{name: type, var: type}, {name: owningObjectId, var: owning_object_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, owning_object_id: $owning_object_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/2/universal_avatar/type/{type}/owner/{owningObjectId}/avatar
export def "post-api-2-universal-avatar-type-type-owner-owning-object-id-avatar" [
  type: string
  owning_object_id: string
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
    path: "/api/2/universal_avatar/type/{type}/owner/{owningObjectId}/avatar"
    path_params: [{name: type, var: type}, {name: owningObjectId, var: owning_object_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, owning_object_id: $owning_object_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes avatar
#
# DELETE /api/2/universal_avatar/type/{type}/owner/{owningObjectId}/avatar/{id}
export def "delete-api-2-universal-avatar-type-type-owner-owning-object-id-avatar-id" [
  type: string
  owning_object_id: string
  id: int
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
    path: "/api/2/universal_avatar/type/{type}/owner/{owningObjectId}/avatar/{id}"
    path_params: [{name: type, var: type}, {name: owningObjectId, var: owning_object_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, owning_object_id: $owning_object_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/2/universal_avatar/type/{type}/owner/{owningObjectId}/temp
export def "post-api-2-universal-avatar-type-type-owner-owning-object-id-temp" [
  type: string
  owning_object_id: string
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
    path: "/api/2/universal_avatar/type/{type}/owner/{owningObjectId}/temp"
    path_params: [{name: type, var: type}, {name: owningObjectId, var: owning_object_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, owning_object_id: $owning_object_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the result of the last upgrade task. Returns {@link javax.ws.rs.core.Response#seeOther(java.net.URI)} if still running.
#
# GET /api/2/upgrade
# operationId: getUpgradeResult
export def "get-upgrade-result" [
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
    path: "/api/2/upgrade"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Runs any pending delayed upgrade tasks. Need Admin permissions to do this.
#
# POST /api/2/upgrade
# operationId: runUpgradesNow
export def "run-upgrades-now" [
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
    path: "/api/2/upgrade"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes user.
#
# DELETE /api/2/user
# operationId: removeUser
export def "remove-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # the username
  --key: string # user key
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/2/user"
    query: [{name: username, var: username}, {name: key, var: key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a user. This resource cannot be accessed anonymously.
#
# GET /api/2/user
export def "get-api-2-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # the username
  --key: string # user key
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/user"
    query: [{name: username, var: username}, {name: key, var: key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create user. By default created user will not be notified with email. If password field is not set then password will be randomly generated.
#
# POST /api/2/user
# operationId: createUser
export def "create-user" [
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
    path: "/api/2/user"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify user. The "value" fields present will override the existing value. Fields skipped in request will not be changed.
#
# PUT /api/2/user
export def "put-api-2-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # the username
  --key: string # user key
]: nothing -> any {
  http-request {
    method: put
    path: "/api/2/user"
    query: [{name: username, var: username}, {name: key, var: key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove user from given application. Admin permission will be required to perform this operation.
#
# DELETE /api/2/user/application
# operationId: removeUserFromApplication
export def "remove-user-from-application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # username
  --application-key: string # application key
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/2/user/application"
    query: [{name: username, var: username}, {name: applicationKey, var: application_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, application_key: $application_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add user to given application. Admin permission will be required to perform this operation.
#
# POST /api/2/user/application
# operationId: addUserToApplication
export def "add-user-to-application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # username
  --application-key: string # application key
]: nothing -> any {
  http-request {
    method: post
    path: "/api/2/user/application"
    query: [{name: username, var: username}, {name: applicationKey, var: application_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, application_key: $application_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of users that match the search string and can be assigned issues for all the given projects. This resource cannot be accessed anonymously.
#
# GET /api/2/user/assignable/multiProjectSearch
# operationId: findBulkAssignableUsers
export def "find-bulk-assignable-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # the username
  --project-keys: string # the keys of the projects we are finding assignable users for, comma-separated
  --start-at: int # the index of the first user to return (0-based) (format: int32)
  --max-results: int # the maximum number of users to return (defaults to 50). The maximum allowed value is 1000. If you specify a value that is higher than this number, your search results will be truncated. (format: int32)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/user/assignable/multiProjectSearch"
    query: [{name: username, var: username}, {name: projectKeys, var: project_keys}, {name: startAt, var: start_at}, {name: maxResults, var: max_results}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, project_keys: $project_keys, start_at: $start_at, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of users that match the search string. This resource cannot be accessed anonymously. Please note that this resource should be called with an issue key when a list of assignable users is retrieved for editing. For create only a project key should be supplied. The list of assignable users may be incorrect if it's called with the project key for editing.
#
# GET /api/2/user/assignable/search
# operationId: findAssignableUsers
export def "find-assignable-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # the username
  --project: string # the key of the project we are finding assignable users for
  --issue-key: string # the issue key for the issue being edited we need to find assignable users for.
  --start-at: int # the index of the first user to return (0-based) (format: int32)
  --max-results: int # the maximum number of users to return (defaults to 50). The maximum allowed value is 1000. If you specify a value that is higher than this number, your search results will be truncated. (format: int32)
  --action-descriptor-id: int # format: int32
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/user/assignable/search"
    query: [{name: username, var: username}, {name: project, var: project}, {name: issueKey, var: issue_key}, {name: startAt, var: start_at}, {name: maxResults, var: max_results}, {name: actionDescriptorId, var: action_descriptor_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, project: $project, issue_key: $issue_key, start_at: $start_at, max_results: $max_results, action_descriptor_id: $action_descriptor_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Converts temporary avatar into a real avatar
#
# POST /api/2/user/avatar
export def "post-api-2-user-avatar" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # username
]: nothing -> any {
  http-request {
    method: post
    path: "/api/2/user/avatar"
    query: [{name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /api/2/user/avatar
export def "put-api-2-user-avatar" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string
]: nothing -> any {
  http-request {
    method: put
    path: "/api/2/user/avatar"
    query: [{name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates temporary avatar using multipart. The response is sent back as JSON stored in a textarea. This is because the client uses remote iframing to submit avatars using multipart. So we must send them a valid HTML page back from which the client parses the JSON from. Creating a temporary avatar is part of a 3-step process in uploading a new avatar for a user: upload, crop, confirm. This endpoint allows you to use a multipart upload instead of sending the image directly as the request body. You *must* use "avatar" as the name of the upload parameter: curl -c cookiejar.txt -X POST -u admin:admin -H "X-Atlassian-Token: no-check" \ -F "avatar=@mynewavatar.png;type=image/png" \ 'http://localhost:8090/jira/rest/api/2/user/avatar/temporary?username=admin'
#
# POST /api/2/user/avatar/temporary
export def "post-api-2-user-avatar-temporary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # Username
]: nothing -> any {
  http-request {
    method: post
    path: "/api/2/user/avatar/temporary"
    query: [{name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes avatar
#
# DELETE /api/2/user/avatar/{id}
export def "delete-api-2-user-avatar-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # username
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/2/user/avatar/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all avatars which are visible for the currently logged in user.
#
# GET /api/2/user/avatars
export def "get-api-2-user-avatars" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # username
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/user/avatars"
    query: [{name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset the default columns for the given user to the system default. Admin permission will be required to get columns for a user other than the currently logged in user.
#
# DELETE /api/2/user/columns
export def "delete-api-2-user-columns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # username
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/2/user/columns"
    query: [{name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the default columns for the given user. Admin permission will be required to get columns for a user other than the currently logged in user.
#
# GET /api/2/user/columns
export def "get-api-2-user-columns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # username
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/user/columns"
    query: [{name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the default columns for the given user. Admin permission will be required to get columns for a user other than the currently logged in user.
#
# PUT /api/2/user/columns
export def "put-api-2-user-columns" [
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
    method: put
    path: "/api/2/user/columns"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify user password.
#
# PUT /api/2/user/password
# operationId: changeUserPassword
export def "change-user-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # the username
  --key: string # user key
]: nothing -> any {
  http-request {
    method: put
    path: "/api/2/user/password"
    query: [{name: username, var: username}, {name: key, var: key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of active users that match the search string and have all specified permissions for the project or issue. This resource can be accessed by users with ADMINISTER_PROJECT permission for the project or global ADMIN or SYSADMIN rights.
#
# GET /api/2/user/permission/search
# operationId: findUsersWithAllPermissions
export def "find-users-with-all-permissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # the username filter, list includes all users if unspecified
  --permissions: string # comma separated list of permissions for project or issue returned users must have, see Permissions (https://developer.atlassian.com/static/javadoc/jira/6.0/reference/com/atlassian/jira/security/Permissions.Permission.html) JavaDoc for the list of all possible permissions.
  --issue-key: string # the issue key for the issue for which returned users have specified permissions.
  --project-key: string # the optional project key to search for users with if no issueKey is supplied.
  --start-at: int # the index of the first user to return (0-based) (format: int32)
  --max-results: int # the maximum number of users to return (defaults to 50). The maximum allowed value is 1000. If you specify a value that is higher than this number, your search results will be truncated. (format: int32)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/user/permission/search"
    query: [{name: username, var: username}, {name: permissions, var: permissions}, {name: issueKey, var: issue_key}, {name: projectKey, var: project_key}, {name: startAt, var: start_at}, {name: maxResults, var: max_results}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, permissions: $permissions, issue_key: $issue_key, project_key: $project_key, start_at: $start_at, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of users matching query with highlighting. This resource cannot be accessed anonymously.
#
# GET /api/2/user/picker
# operationId: findUsersForPicker
export def "find-users-for-picker" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A string used to search username, Name or e-mail address
  --max-results: int # the maximum number of users to return (defaults to 50). The maximum allowed value is 1000. If you specify a value that is higher than this number, your search results will be truncated. (format: int32)
  --show-avatar: oneof<nothing, bool>
  --exclude: string
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/user/picker"
    query: [{name: query, var: query}, {name: maxResults, var: max_results}, {name: showAvatar, var: show_avatar}, {name: exclude, var: exclude}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    query: $query, max_results: $max_results, show_avatar: $show_avatar, exclude: $exclude
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the keys of all properties for the user identified by the key or by the id.
#
# GET /api/2/user/properties/
export def "get-api-2-user-properties" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-key: string # key of the user whose properties are to be returned
  --username: string # username of the user whose properties are to be returned
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/user/properties/"
    query: [{name: userKey, var: user_key}, {name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_key: $user_key, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the property from the user identified by the key or by the id. Ths user removing the property is required to have permissions to administer the user.
#
# DELETE /api/2/user/properties/{propertyKey}
export def "delete-api-2-user-properties-property-key" [
  property_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-key: string # key of the user whose property is to be removed
  --username: string # username of the user whose property is to be removed
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/2/user/properties/{propertyKey}"
    path_params: [{name: propertyKey, var: property_key}]
    query: [{name: userKey, var: user_key}, {name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    property_key: $property_key, user_key: $user_key, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the value of the property with a given key from the user identified by the key or by the id. The user who retrieves the property is required to have permissions to read the user.
#
# GET /api/2/user/properties/{propertyKey}
export def "get-api-2-user-properties-property-key" [
  property_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-key: string # key of the user whose property is to be returned
  --username: string # username of the user whose property is to be returned
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/user/properties/{propertyKey}"
    path_params: [{name: propertyKey, var: property_key}]
    query: [{name: userKey, var: user_key}, {name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    property_key: $property_key, user_key: $user_key, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the value of the specified user's property. You can use this resource to store a custom data against the user identified by the key or by the id. The user who stores the data is required to have permissions to administer the user.
#
# PUT /api/2/user/properties/{propertyKey}
export def "put-api-2-user-properties-property-key" [
  property_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-key: string # key of the user whose property is to be set
  --username: string # username of the user whose property is to be set
]: nothing -> any {
  http-request {
    method: put
    path: "/api/2/user/properties/{propertyKey}"
    path_params: [{name: propertyKey, var: property_key}]
    query: [{name: userKey, var: user_key}, {name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    property_key: $property_key, user_key: $user_key, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of users that match the search string. This resource cannot be accessed anonymously.
#
# GET /api/2/user/search
# operationId: findUsers
export def "find-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # A query string used to search username, name or e-mail address
  --start-at: int # the index of the first user to return (0-based) (format: int32)
  --max-results: int # the maximum number of users to return (defaults to 50). The maximum allowed value is 1000. If you specify a value that is higher than this number, your search results will be truncated. (format: int32)
  --include-active: oneof<nothing, bool> # If true, then active users are included in the results (default true)
  --include-inactive: oneof<nothing, bool> # If true, then inactive users are included in the results (default false)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/user/search"
    query: [{name: username, var: username}, {name: startAt, var: start_at}, {name: maxResults, var: max_results}, {name: includeActive, var: include_active}, {name: includeInactive, var: include_inactive}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, start_at: $start_at, max_results: $max_results, include_active: $include_active, include_inactive: $include_inactive
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of active users that match the search string. This resource cannot be accessed anonymously and requires the Browse Users global permission. Given an issue key this resource will provide a list of users that match the search string and have the browse issue permission for the issue provided.
#
# GET /api/2/user/viewissue/search
# operationId: findUsersWithBrowsePermission
export def "find-users-with-browse-permission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # the username filter, no users returned if left blank
  --issue-key: string # the issue key for the issue being edited we need to find viewable users for.
  --project-key: string # the optional project key to search for users with if no issueKey is supplied.
  --start-at: int # the index of the first user to return (0-based) (format: int32)
  --max-results: int # the maximum number of users to return (defaults to 50). The maximum allowed value is 1000. If you specify a value that is higher than this number, your search results will be truncated. (format: int32)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/user/viewissue/search"
    query: [{name: username, var: username}, {name: issueKey, var: issue_key}, {name: projectKey, var: project_key}, {name: startAt, var: start_at}, {name: maxResults, var: max_results}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, issue_key: $issue_key, project_key: $project_key, start_at: $start_at, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a version via POST.
#
# POST /api/2/version
# operationId: createVersion
export def "create-version" [
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
    path: "/api/2/version"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the remote version links for a given global ID.
#
# GET /api/2/version/remotelink
# operationId: getRemoteVersionLinks
export def "get-remote-version-links" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --global-id: string # the global ID of the remote resource that is linked to the versions
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/version/remotelink"
    query: [{name: globalId, var: global_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_id: $global_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a project version.
#
# DELETE /api/2/version/{id}
export def "delete-api-2-version-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --move-fix-issues-to: string # The version to set fixVersion to on issues where the deleted version is the fix version, If null then the fixVersion is removed.
  --move-affected-issues-to: string # The version to set affectedVersion to on issues where the deleted version is the affected version, If null then the affectedVersion is removed.
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/2/version/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: moveFixIssuesTo, var: move_fix_issues_to}, {name: moveAffectedIssuesTo, var: move_affected_issues_to}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, move_fix_issues_to: $move_fix_issues_to, move_affected_issues_to: $move_affected_issues_to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a project version.
#
# GET /api/2/version/{id}
# operationId: getVersion
export def "get-version" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/version/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a version via PUT. Any fields present in the PUT will override existing values. As a convenience, if a field is not present, it is silently ignored.
#
# PUT /api/2/version/{id}
# operationId: updateVersion
export def "update-version" [
  id: string
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
    method: put
    path: "/api/2/version/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Merge versions
#
# PUT /api/2/version/{id}/mergeto/{moveIssuesTo}
# operationId: merge
export def "put-api-2-version-id-mergeto-move-issues-to" [
  id: string
  move_issues_to: string
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
    method: put
    path: "/api/2/version/{id}/mergeto/{moveIssuesTo}"
    path_params: [{name: id, var: id}, {name: moveIssuesTo, var: move_issues_to}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, move_issues_to: $move_issues_to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a version's sequence within a project. The move version bean has 2 alternative field value pairs: positionAn absolute position, which may have a value of 'First', 'Last', 'Earlier' or 'Later' afterA version to place this version after. The value should be the self link of another version
#
# POST /api/2/version/{id}/move
# operationId: moveVersion
export def "move-version" [
  id: string
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
    path: "/api/2/version/{id}/move"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a bean containing the number of fixed in and affected issues for the given version.
#
# GET /api/2/version/{id}/relatedIssueCounts
# operationId: getVersionRelatedIssues
export def "get-version-related-issues" [
  id: string
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
    path: "/api/2/version/{id}/relatedIssueCounts"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a project version.
#
# POST /api/2/version/{id}/removeAndSwap
export def "post-api-2-version-id-remove-and-swap" [
  id: string
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
    path: "/api/2/version/{id}/removeAndSwap"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the number of unresolved issues for the given version
#
# GET /api/2/version/{id}/unresolvedIssueCount
# operationId: getVersionUnresolvedIssues
export def "get-version-unresolved-issues" [
  id: string
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
    path: "/api/2/version/{id}/unresolvedIssueCount"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete all remote version links for a given version ID.
#
# DELETE /api/2/version/{versionId}/remotelink
# operationId: deleteRemoteVersionLinksByVersionId
export def "delete-remote-version-links-by-version-id" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/2/version/{versionId}/remotelink"
    path_params: [{name: versionId, var: version_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    version_id: $version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the remote version links associated with the given version ID.
#
# GET /api/2/version/{versionId}/remotelink
# operationId: getRemoteVersionLinksByVersionId
export def "get-remote-version-links-by-version-id" [
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
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/version/{versionId}/remotelink"
    path_params: [{name: versionId, var: version_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    version_id: $version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a remote version link via POST. The link's global ID will be taken from the JSON payload if provided; otherwise, it will be generated.
#
# POST /api/2/version/{versionId}/remotelink
export def "post-api-2-version-version-id-remotelink" [
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
]: nothing -> any {
  http-request {
    method: post
    path: "/api/2/version/{versionId}/remotelink"
    path_params: [{name: versionId, var: version_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    version_id: $version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific remote version link with the given version ID and global ID.
#
# DELETE /api/2/version/{versionId}/remotelink/{globalId}
# operationId: deleteRemoteVersionLink
export def "delete-remote-version-link" [
  version_id: string
  global_id: string
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
    path: "/api/2/version/{versionId}/remotelink/{globalId}"
    path_params: [{name: versionId, var: version_id}, {name: globalId, var: global_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    version_id: $version_id, global_id: $global_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# A REST sub-resource representing a remote version link
#
# GET /api/2/version/{versionId}/remotelink/{globalId}
# operationId: getRemoteVersionLink
export def "get-remote-version-link" [
  version_id: string
  global_id: string
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
    path: "/api/2/version/{versionId}/remotelink/{globalId}"
    path_params: [{name: versionId, var: version_id}, {name: globalId, var: global_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    version_id: $version_id, global_id: $global_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a remote version link via POST. The link's global ID will be taken from the JSON payload if provided; otherwise, it will be generated.
#
# POST /api/2/version/{versionId}/remotelink/{globalId}
export def "post-api-2-version-version-id-remotelink-global-id" [
  version_id: string
  global_id: string
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
    path: "/api/2/version/{versionId}/remotelink/{globalId}"
    path_params: [{name: versionId, var: version_id}, {name: globalId, var: global_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    version_id: $version_id, global_id: $global_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all workflows.
#
# GET /api/2/workflow
# operationId: getAllWorkflows
export def "get-all-workflows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --workflow-name: string
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/workflow"
    query: [{name: workflowName, var: workflow_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workflow_name: $workflow_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a property from the passed transition on the passed workflow. It is not an error to delete a property that does not exist.
#
# DELETE /api/2/workflow/api/2/transitions/{id}/properties
export def "delete-api-2-workflow-api-2-transitions-id-properties" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # the name of the property to add.
  --workflow-name: string # the name of the workflow to use.
  --workflow-mode: string # the type of workflow to use. Can either be "live" or "draft".
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/2/workflow/api/2/transitions/{id}/properties"
    path_params: [{name: id, var: id}]
    query: [{name: key, var: key}, {name: workflowName, var: workflow_name}, {name: workflowMode, var: workflow_mode}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, key: $key, workflow_name: $workflow_name, workflow_mode: $workflow_mode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the property or properties associated with a transition.
#
# GET /api/2/workflow/api/2/transitions/{id}/properties
# operationId: getProperties
export def "get-properties" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-reserved-keys: oneof<nothing, bool> # some keys under the "jira." prefix are editable, some are not. Set this to true in order to include the non-editable keys in the response.
  --key: string # the name of the property key to query. Can be left off the query to return all properties.
  --workflow-name: string # the name of the workflow to use.
  --workflow-mode: string # the type of workflow to use. Can either be "live" or "draft".
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/workflow/api/2/transitions/{id}/properties"
    path_params: [{name: id, var: id}]
    query: [{name: includeReservedKeys, var: include_reserved_keys}, {name: key, var: key}, {name: workflowName, var: workflow_name}, {name: workflowMode, var: workflow_mode}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include_reserved_keys: $include_reserved_keys, key: $key, workflow_name: $workflow_name, workflow_mode: $workflow_mode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new property to a transition. Trying to add a property that already exists will fail.
#
# POST /api/2/workflow/api/2/transitions/{id}/properties
# operationId: createProperty
export def "create-property" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # the name of the property to add.
  --workflow-name: string # the name of the workflow to use.
  --workflow-mode: string # the type of workflow to use. Can either be "live" or "draft".
]: nothing -> any {
  http-request {
    method: post
    path: "/api/2/workflow/api/2/transitions/{id}/properties"
    path_params: [{name: id, var: id}]
    query: [{name: key, var: key}, {name: workflowName, var: workflow_name}, {name: workflowMode, var: workflow_mode}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, key: $key, workflow_name: $workflow_name, workflow_mode: $workflow_mode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/add new property to a transition. Trying to update a property that does not exist will result in a new property being added.
#
# PUT /api/2/workflow/api/2/transitions/{id}/properties
# operationId: updateProperty
export def "update-property" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # the name of the property to add.
  --workflow-name: string # the name of the workflow to use.
  --workflow-mode: string # the type of workflow to use. Can either be "live" or "draft".
]: nothing -> any {
  http-request {
    method: put
    path: "/api/2/workflow/api/2/transitions/{id}/properties"
    path_params: [{name: id, var: id}]
    query: [{name: key, var: key}, {name: workflowName, var: workflow_name}, {name: workflowMode, var: workflow_mode}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, key: $key, workflow_name: $workflow_name, workflow_mode: $workflow_mode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new workflow scheme. The body contains a representation of the new scheme. Values not passed are assumed to be set to their defaults.
#
# POST /api/2/workflowscheme
# operationId: createScheme
export def "create-scheme" [
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
    path: "/api/2/workflowscheme"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the passed workflow scheme.
#
# DELETE /api/2/workflowscheme/{id}
# operationId: deleteScheme
export def "delete-scheme" [
  id: int
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
    path: "/api/2/workflowscheme/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the requested workflow scheme to the caller.
#
# GET /api/2/workflowscheme/{id}
# operationId: getById
export def "get-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --return-draft-if-exists: oneof<nothing, bool> # when true indicates that a scheme's draft, if it exists, should be queried instead of the scheme itself. (default: false)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/workflowscheme/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: returnDraftIfExists, var: return_draft_if_exists}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, return_draft_if_exists: $return_draft_if_exists
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the passed workflow scheme. The body of the request is a representation of the workflow scheme. Values not passed are assumed to indicate no change for that field. The passed representation can have its updateDraftIfNeeded flag set to true to indicate that the draft should be created and/or updated when the actual scheme cannot be edited (e.g. when the scheme is being used by a project). Values not appearing the body will not be touched.
#
# PUT /api/2/workflowscheme/{id}
# operationId: update
export def "put-api-2-workflowscheme-id" [
  id: int
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
    method: put
    path: "/api/2/workflowscheme/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a draft for the passed scheme. The draft will be a copy of the state of the parent.
#
# POST /api/2/workflowscheme/{id}/createdraft
# operationId: createDraftForParent
export def "create-draft-for-parent" [
  id: int
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
    path: "/api/2/workflowscheme/{id}/createdraft"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove the default workflow from the passed workflow scheme.
#
# DELETE /api/2/workflowscheme/{id}/default
# operationId: deleteDefault
export def "delete-default" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --update-draft-if-needed: oneof<nothing, bool> # when true will create and return a draft when the workflow scheme cannot be edited (e.g. when it is being used by a project).
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/2/workflowscheme/{id}/default"
    path_params: [{name: id, var: id}]
    query: [{name: updateDraftIfNeeded, var: update_draft_if_needed}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, update_draft_if_needed: $update_draft_if_needed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the default workflow from the passed workflow scheme.
#
# GET /api/2/workflowscheme/{id}/default
# operationId: getDefault
export def "get-default" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --return-draft-if-exists: oneof<nothing, bool> # when true indicates that a scheme's draft, if it exists, should be queried instead of the scheme itself. (default: false)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/workflowscheme/{id}/default"
    path_params: [{name: id, var: id}]
    query: [{name: returnDraftIfExists, var: return_draft_if_exists}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, return_draft_if_exists: $return_draft_if_exists
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the default workflow for the passed workflow scheme. The passed representation can have its updateDraftIfNeeded flag set to true to indicate that the draft should be created/updated when the actual scheme cannot be edited.
#
# PUT /api/2/workflowscheme/{id}/default
# operationId: updateDefault
export def "update-default" [
  id: int
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
    method: put
    path: "/api/2/workflowscheme/{id}/default"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the passed draft workflow scheme.
#
# DELETE /api/2/workflowscheme/{id}/draft
# operationId: deleteDraftById
export def "delete-draft-by-id" [
  id: int
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
    path: "/api/2/workflowscheme/{id}/draft"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the requested draft workflow scheme to the caller.
#
# GET /api/2/workflowscheme/{id}/draft
# operationId: getDraftById
export def "get-draft-by-id" [
  id: int
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
    path: "/api/2/workflowscheme/{id}/draft"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a draft workflow scheme. The draft will created if necessary. The body is a representation of the workflow scheme. Values not passed are assumed to indicate no change for that field.
#
# PUT /api/2/workflowscheme/{id}/draft
# operationId: updateDraft
export def "update-draft" [
  id: int
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
    method: put
    path: "/api/2/workflowscheme/{id}/draft"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove the default workflow from the passed draft workflow scheme.
#
# DELETE /api/2/workflowscheme/{id}/draft/default
# operationId: deleteDraftDefault
export def "delete-draft-default" [
  id: int
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
    path: "/api/2/workflowscheme/{id}/draft/default"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the default workflow from the passed draft workflow scheme to the caller.
#
# GET /api/2/workflowscheme/{id}/draft/default
# operationId: getDraftDefault
export def "get-draft-default" [
  id: int
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
    path: "/api/2/workflowscheme/{id}/draft/default"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the default workflow for the passed draft workflow scheme.
#
# PUT /api/2/workflowscheme/{id}/draft/default
# operationId: updateDraftDefault
export def "update-draft-default" [
  id: int
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
    method: put
    path: "/api/2/workflowscheme/{id}/draft/default"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove the specified issue type mapping from the draft scheme.
#
# DELETE /api/2/workflowscheme/{id}/draft/issuetype/{issueType}
# operationId: deleteDraftIssueType
export def "delete-draft-issue-type" [
  id: int
  issue_type: string
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
    path: "/api/2/workflowscheme/{id}/draft/issuetype/{issueType}"
    path_params: [{name: id, var: id}, {name: issueType, var: issue_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, issue_type: $issue_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the issue type mapping for the passed draft workflow scheme.
#
# GET /api/2/workflowscheme/{id}/draft/issuetype/{issueType}
# operationId: getDraftIssueType
export def "get-draft-issue-type" [
  id: int
  issue_type: string
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
    path: "/api/2/workflowscheme/{id}/draft/issuetype/{issueType}"
    path_params: [{name: id, var: id}, {name: issueType, var: issue_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, issue_type: $issue_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the issue type mapping for the passed draft scheme. The passed representation can have its updateDraftIfNeeded flag set to true to indicate that the draft should be created/updated when the actual scheme cannot be edited.
#
# PUT /api/2/workflowscheme/{id}/draft/issuetype/{issueType}
# operationId: setDraftIssueType
export def "set-draft-issue-type" [
  id: int
  issue_type: string
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
    method: put
    path: "/api/2/workflowscheme/{id}/draft/issuetype/{issueType}"
    path_params: [{name: id, var: id}, {name: issueType, var: issue_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, issue_type: $issue_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the passed workflow from the draft workflow scheme.
#
# DELETE /api/2/workflowscheme/{id}/draft/workflow
# operationId: deleteDraftWorkflowMapping
export def "delete-draft-workflow-mapping" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --workflow-name: string # the name of the workflow to delete.
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/2/workflowscheme/{id}/draft/workflow"
    path_params: [{name: id, var: id}]
    query: [{name: workflowName, var: workflow_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, workflow_name: $workflow_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the draft workflow mappings or requested mapping to the caller.
#
# GET /api/2/workflowscheme/{id}/draft/workflow
# operationId: getDraftWorkflow
export def "get-draft-workflow" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --workflow-name: string # the workflow mapping to return. Null can be passed to return all mappings. Must be a valid workflow name.
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/workflowscheme/{id}/draft/workflow"
    path_params: [{name: id, var: id}]
    query: [{name: workflowName, var: workflow_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, workflow_name: $workflow_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the draft scheme to include the passed mapping. The body is a representation of the workflow mapping. Values not passed are assumed to indicate no change for that field.
#
# PUT /api/2/workflowscheme/{id}/draft/workflow
# operationId: updateDraftWorkflowMapping
export def "update-draft-workflow-mapping" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --workflow-name: string # the name of the workflow mapping to update.
]: nothing -> any {
  http-request {
    method: put
    path: "/api/2/workflowscheme/{id}/draft/workflow"
    path_params: [{name: id, var: id}]
    query: [{name: workflowName, var: workflow_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, workflow_name: $workflow_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove the specified issue type mapping from the scheme.
#
# DELETE /api/2/workflowscheme/{id}/issuetype/{issueType}
export def "delete-api-2-workflowscheme-id-issuetype-issue-type" [
  id: int
  issue_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --update-draft-if-needed: oneof<nothing, bool> # when true will create and return a draft when the workflow scheme cannot be edited (e.g. when it is being used by a project).
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/2/workflowscheme/{id}/issuetype/{issueType}"
    path_params: [{name: id, var: id}, {name: issueType, var: issue_type}]
    query: [{name: updateDraftIfNeeded, var: update_draft_if_needed}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, issue_type: $issue_type, update_draft_if_needed: $update_draft_if_needed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the issue type mapping for the passed workflow scheme.
#
# GET /api/2/workflowscheme/{id}/issuetype/{issueType}
export def "get-api-2-workflowscheme-id-issuetype-issue-type" [
  id: int
  issue_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --return-draft-if-exists: oneof<nothing, bool> # when true indicates that a scheme's draft, if it exists, should be queried instead of the scheme itself. (default: false)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/workflowscheme/{id}/issuetype/{issueType}"
    path_params: [{name: id, var: id}, {name: issueType, var: issue_type}]
    query: [{name: returnDraftIfExists, var: return_draft_if_exists}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, issue_type: $issue_type, return_draft_if_exists: $return_draft_if_exists
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the issue type mapping for the passed scheme. The passed representation can have its updateDraftIfNeeded flag set to true to indicate that the draft should be created/updated when the actual scheme cannot be edited.
#
# PUT /api/2/workflowscheme/{id}/issuetype/{issueType}
# operationId: setIssueType
export def "set-issue-type" [
  id: int
  issue_type: string
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
    method: put
    path: "/api/2/workflowscheme/{id}/issuetype/{issueType}"
    path_params: [{name: id, var: id}, {name: issueType, var: issue_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, issue_type: $issue_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the passed workflow from the workflow scheme.
#
# DELETE /api/2/workflowscheme/{id}/workflow
# operationId: deleteWorkflowMapping
export def "delete-workflow-mapping" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --workflow-name: string # the name of the workflow to delete.
  --update-draft-if-needed: oneof<nothing, bool> # flag to indicate if a draft should be created if necessary to delete the workflow from the scheme.
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/2/workflowscheme/{id}/workflow"
    path_params: [{name: id, var: id}]
    query: [{name: workflowName, var: workflow_name}, {name: updateDraftIfNeeded, var: update_draft_if_needed}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, workflow_name: $workflow_name, update_draft_if_needed: $update_draft_if_needed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the workflow mappings or requested mapping to the caller for the passed scheme.
#
# GET /api/2/workflowscheme/{id}/workflow
# operationId: getWorkflow
export def "get-workflow" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --workflow-name: string # the workflow mapping to return. Null can be passed to return all mappings. Must be a valid workflow name.
  --return-draft-if-exists: oneof<nothing, bool> # when true indicates that a scheme's draft, if it exists, should be queried instead of the scheme itself. (default: false)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/workflowscheme/{id}/workflow"
    path_params: [{name: id, var: id}]
    query: [{name: workflowName, var: workflow_name}, {name: returnDraftIfExists, var: return_draft_if_exists}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, workflow_name: $workflow_name, return_draft_if_exists: $return_draft_if_exists
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the scheme to include the passed mapping. The body is a representation of the workflow mapping. Values not passed are assumed to indicate no change for that field. The passed representation can have its updateDraftIfNeeded flag set to true to indicate that the draft should be created/updated when the actual scheme cannot be edited.
#
# PUT /api/2/workflowscheme/{id}/workflow
# operationId: updateWorkflowMapping
export def "update-workflow-mapping" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --workflow-name: string # the name of the workflow mapping to update.
]: nothing -> any {
  http-request {
    method: put
    path: "/api/2/workflowscheme/{id}/workflow"
    path_params: [{name: id, var: id}]
    query: [{name: workflowName, var: workflow_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, workflow_name: $workflow_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns worklogs id and delete time of worklogs that was deleted since given time. The returns set of worklogs is limited to 1000 elements. This API will not return worklogs deleted during last minute.
#
# GET /api/2/worklog/deleted
# operationId: getIdsOfWorklogsDeletedSince
export def "get-ids-of-worklogs-deleted-since" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: int # a date time in unix timestamp format since when deleted worklogs will be returned. (format: int64, default: 0)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/worklog/deleted"
    query: [{name: since, var: since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    since: $since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns worklogs for given worklog ids. Only worklogs to which the calling user has permissions, will be included in the result. The returns set of worklogs is limited to 1000 elements.
#
# POST /api/2/worklog/list
# operationId: getWorklogsForIds
export def "get-worklogs-for-ids" [
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
    path: "/api/2/worklog/list"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns worklogs id and update time of worklogs that was updated since given time. The returns set of worklogs is limited to 1000 elements. This API will not return worklogs updated during last minute.
#
# GET /api/2/worklog/updated
# operationId: getIdsOfWorklogsModifiedSince
export def "get-ids-of-worklogs-modified-since" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: int # a date time in unix timestamp format since when updated worklogs will be returned. (format: int64, default: 0)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/2/worklog/updated"
    query: [{name: since, var: since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    since: $since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Logs the current user out of JIRA, destroying the existing session, if any.
#
# DELETE /auth/1/session
# operationId: logout
export def "logout" [
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
    path: "/auth/1/session"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the currently authenticated user's session. If the caller is not authenticated they will get a 401 Unauthorized status code.
#
# GET /auth/1/session
# operationId: currentUser
export def "current-user" [
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
    path: "/auth/1/session"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new session for a user in JIRA. Once a session has been successfully created it can be used to access any of JIRA's remote APIs and also the web UI by passing the appropriate HTTP Cookie header. Note that it is generally preferrable to use HTTP BASIC authentication with the REST API. However, this resource may be used to mimic the behaviour of JIRA's log-in page (e.g. to display log-in errors to a user).
#
# POST /auth/1/session
# operationId: login
export def "login" [
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
    path: "/auth/1/session"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method invalidates the any current WebSudo session.
#
# DELETE /auth/1/websudo
# operationId: release
export def "release" [
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
    path: "/auth/1/websudo"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
