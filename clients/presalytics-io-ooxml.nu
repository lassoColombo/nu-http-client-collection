# Auto-generated client for OOXML Automation v0.1.0
# Source: https://api.apis.guru/v2/specs/presalytics.io/ooxml/0.1.0/openapi.json
# Auth: --token flag or $env.OOXML_AUTOMATION_TOKEN

const CLIENT = {
  base_url: "https://api.presalytics.io/ooxml-automation"
  token_env_var: "OOXML_AUTOMATION_TOKEN"
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

def base-url-completer [] { ["https://api.presalytics.io/ooxml-automation"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/json" "text/plain"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    chart-axes-get-id: "record<axisDataTypeId: int, chartsId: string, id: string, ooxmlId: int>"
    chart-axisdatatypes-get: "table<description: string, id: string, name: string, ooxmlName: string, typeId: int>"
    chart-axisdatatypes-typeid-get-type-id: "record<description: string, id: string, name: string, ooxmlName: string, typeId: int>"
    chart-axisdatatypes-get-id: "record<description: string, id: string, name: string, ooxmlName: string, typeId: int>"
    chart-chartdata-get-id: "record<chartId: string, id: string>"
    charts-charts-chartupdate-get-id: "record<categoryNames: list<string>, chartId: string, dataPoints: list<list<float>>, seriesNames: list<string>>"
    charts-charts-childobjects-get-id: "table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string>"
    chart-columncollections-get-id: "record<chartDataId: string, id: string>"
    chart-columns-get-id: "record<axisId: string, columnCollectionId: string, id: string, index: int, name: string>"
    chart-datapoints-get-id: "record<chartDataId: string, columnId: string, id: string, rowId: string, value: float>"
    charts-charts-details-get-id: "record<axes: table<axisDataTypeId: int, chart: any, chartsId: string, dateCreated: string, dateModified: string, id: string, ooxmlId: int, titleTextContainer: record, userCreated: string, userModified: string>, baseElementBlobUrl: string, changedBaseElementBlobUrl: string, chartData: record<chart: any, chartId: string, columnCollection: record<chartData: any, chartDataId: string, columns: list, dateCreated: string, dateModified: string, id: string, userCreated: string, userModified: string>, dataPoints: list<record>, dateCreated: string, dateModified: string, id: string, rowCollection: record<axis: record, axisId: string, chartData: any, chartDataId: string, dateCreated: string, dateModified: string, id: string, nameFormatType: int, rows: list, userCreated: string, userModified: string>, userCreated: string, userModified: string>, dateCreated: string, dateModified: string, id: string, name: string, packageUri: string, parentGraphic: record<chart: any, dateCreated: string, dateModified: string, graphicTypeId: int, groupElement: record<childGroupElements: list, connector: record, dateCreated: string, dateModified: string, graphic: any, group: record, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: record, shapeTree: record, shapeTreeId: string, typeInfo: record, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementsId: string, height: int, id: string, name: string, ooxmlId: int, picture: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, fileExtension: string, graphicsId: string, id: string, imageFileBlobUrl: string, imageFill: record, imageFillsId: string, name: string, packageUri: string, parentGraphic: any, userCreated: string, userModified: string>, smartArt: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, graphicsId: string, id: string, name: string, packageUri: string, parentGraphic: any, svgBlobUrl: string, userCreated: string, userModified: string>, table: record<baseElementBlobUrl: string, cells: list, changedBaseElementBlobUrl: string, columns: list, dateCreated: string, dateModified: string, hasStylePart: bool, id: string, name: string, packageUri: string, parentGraphic: any, parentGraphicId: string, rows: list, stylePartOuterXml: string, svgBlobUrl: string, userCreated: string, userModified: string>, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, parentGraphicId: string, svgBlobUrl: string, titleTextContainer: record<axis: record<axisDataTypeId: int, chart: any, chartsId: string, dateCreated: string, dateModified: string, id: string, ooxmlId: int, titleTextContainer: any, userCreated: string, userModified: string>, axisId: string, chart: any, chartId: string, dateCreated: string, dateModified: string, id: string, outerXml: string, paragraphs: list<record>, parentShape: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, textContainer: any, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, shapeId: string, tableCell: record<border: record, column: record, columnId: string, columnSpan: int, dateCreated: string, dateModified: string, fillMap: record, id: string, isMergedHorozontal: bool, isMergedVertical: bool, row: record, rowId: string, rowSpan: int, textContainer: any, userCreated: string, userModified: string>, tableCellId: string, userCreated: string, userModified: string>, userCreated: string, userModified: string>"
    charts-charts-openofficexml-get-id-updated: "record<id: string, openOfficeXml: string, type: string>"
    chart-plottype-get: "table<id: string, plotQualifedAssy: string, plotTypeName: string, rowColTypeId: int, typeId: int>"
    chart-plottype-typeid-get-type-id: "record<id: string, plotQualifedAssy: string, plotTypeName: string, rowColTypeId: int, typeId: int>"
    chart-plottype-get-id: "record<id: string, plotQualifedAssy: string, plotTypeName: string, rowColTypeId: int, typeId: int>"
    chart-rowcol-get: "table<colName: string, colQualifiedAssy: string, id: string, rowName: string, rowQualifedAssy: string, typeId: int>"
    chart-rowcol-typeid-get-type-id: "record<colName: string, colQualifiedAssy: string, id: string, rowName: string, rowQualifedAssy: string, typeId: int>"
    chart-rowcol-get-id: "record<colName: string, colQualifiedAssy: string, id: string, rowName: string, rowQualifedAssy: string, typeId: int>"
    chart-rowcollections-get-id: "record<axisId: string, chartDataId: string, id: string, nameFormatType: int>"
    chart-rownameformattypes-get: "table<formatCode: string, id: string, powerToolsId: int, typeId: int>"
    chart-rownameformattypes-typeid-get-type-id: "record<formatCode: string, id: string, powerToolsId: int, typeId: int>"
    chart-rownameformattypes-get-id: "record<formatCode: string, id: string, powerToolsId: int, typeId: int>"
    chart-rows-get-id: "record<id: string, index: int, name: string, rowNameCollectionId: string>"
    charts-charts-get-id: "record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, id: string, name: string, packageUri: string, parentGraphicId: string, svgBlobUrl: string>"
    slides-connectionshapes-childobjects-get-id: "table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string>"
    slides-connectionshapes-details-get-id: "record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record<connectorId: string, dateCreated: string, dateModified: string, effectAttributes: list<record>, effectMap: record<dateCreated: string, dateModified: string, effect: any, id: string, intensityId: int, theme: record, themeId: string, userCreated: string, userModified: string>, effectMapId: string, id: string, name: string, parentConnector: any, parentShape: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: any, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, textContainer: record, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, shapeId: string, userCreated: string, userModified: string>, endConnectionIdx: int, endConnectionShape: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record<connectorId: string, dateCreated: string, dateModified: string, effectAttributes: list, effectMap: record, effectMapId: string, id: string, name: string, parentConnector: any, parentShape: any, shapeId: string, userCreated: string, userModified: string>, fillMap: record<connector: any, connectorId: string, dateCreated: string, dateModified: string, effectAttribute: record, effectAttributeId: string, fillTypeId: int, gradientFill: record, id: string, imageFill: record, shape: any, shapeId: string, solidFill: record, tableCell: record, tableCellId: string, themeBackgroundFill: record, themeBackgroundFillId: string, themeFill: record, themeFillId: string, userCreated: string, userModified: string>, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record<childGroupElements: list, connector: any, dateCreated: string, dateModified: string, graphic: record, group: record, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: any, shapeTree: record, shapeTreeId: string, typeInfo: record, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record<bLtoTRBorder: record, bLtoTRBorderId: string, bottomBorder: record, bottomBorderId: string, connectorId: string, dashTypeId: int, dateCreated: string, dateModified: string, headEndHeightId: int, headEndTypeId: int, headEndWidthId: int, id: string, leftBorder: record, leftBorderId: string, lineColorSolidFill: record, lineMap: record, lineMapId: string, parentConnector: any, parentShape: any, rightBorder: record, rightBorderId: string, shapeId: string, tLtoBRBorder: record, tLtoBRBorderId: string, tailEndHeightId: int, tailEndTypeId: int, tailEndWidthId: int, topBorder: record, topBorderId: string, userCreated: string, userModified: string, weight: int>, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, textContainer: record<axis: record, axisId: string, chart: record, chartId: string, dateCreated: string, dateModified: string, id: string, outerXml: string, paragraphs: list, parentShape: any, shapeId: string, tableCell: record, tableCellId: string, userCreated: string, userModified: string>, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, endConnectionShapeId: string, fillMap: record<connector: any, connectorId: string, dateCreated: string, dateModified: string, effectAttribute: record<attributesJson: string, dateCreated: string, dateModified: string, effect: record, effectId: string, effectTypeId: int, fillMap: any, id: string, userCreated: string, userModified: string>, effectAttributeId: string, fillTypeId: int, gradientFill: record<angle: int, dateCreated: string, dateModified: string, fillMap: any, fillMapId: string, gradientStops: list, id: string, isPath: bool, pathType: string, rotateWithShape: bool, userCreated: string, userModified: string>, id: string, imageFill: record<compressionState: string, dateCreated: string, dateModified: string, dpi: int, effectsJson: string, fillMap: any, fillMapId: string, id: string, picture: record, rotateWithShape: bool, sourceRectangle: string, stretch: bool, tile: string, userCreated: string, userModified: string>, shape: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, fillMap: any, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, textContainer: record, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, shapeId: string, solidFill: record<colorTransformations: record, colorTypeId: int, dateCreated: string, dateModified: string, fillMapId: string, hexValue: string, id: string, isUserColor: bool, parentFillMap: any, parentGradientStop: record, parentGradientStopId: string, parentLine: record, parentLineId: string, parentText: record, parentTextId: string, userCreated: string, userModified: string>, tableCell: record<border: record, column: record, columnId: string, columnSpan: int, dateCreated: string, dateModified: string, fillMap: any, id: string, isMergedHorozontal: bool, isMergedVertical: bool, row: record, rowId: string, rowSpan: int, textContainer: record, userCreated: string, userModified: string>, tableCellId: string, themeBackgroundFill: record<dateCreated: string, dateModified: string, fillMap: any, id: string, intensityId: int, theme: record, themeId: string, userCreated: string, userModified: string>, themeBackgroundFillId: string, themeFill: record<dateCreated: string, dateModified: string, fillMap: any, id: string, intensityId: int, theme: record, themeId: string, userCreated: string, userModified: string>, themeFillId: string, userCreated: string, userModified: string>, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record<childGroupElements: list<any>, connector: any, dateCreated: string, dateModified: string, graphic: record<chart: record, dateCreated: string, dateModified: string, graphicTypeId: int, groupElement: any, groupElementsId: string, height: int, id: string, name: string, ooxmlId: int, picture: record, smartArt: record, table: record, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, group: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, groupElement: any, groupElementId: string, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, svgBlobUrl: string, title: string, userCreated: string, userModified: string>, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: any, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, textContainer: record, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, shapeTree: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, groupElement: any, groupElementId: string, groupElements: list, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, slide: record, slideId: string, svgBlobUrl: string, title: string, userCreated: string, userModified: string>, shapeTreeId: string, typeInfo: record<dateCreated: string, dateModified: string, description: string, id: string, name: string, typeId: int, userCreated: string, userModified: string>, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementsId: string, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record<bLtoTRBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, bLtoTRBorderId: string, bottomBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, bottomBorderId: string, connectorId: string, dashTypeId: int, dateCreated: string, dateModified: string, headEndHeightId: int, headEndTypeId: int, headEndWidthId: int, id: string, leftBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, leftBorderId: string, lineColorSolidFill: record<colorTransformations: record, colorTypeId: int, dateCreated: string, dateModified: string, fillMapId: string, hexValue: string, id: string, isUserColor: bool, parentFillMap: record, parentGradientStop: record, parentGradientStopId: string, parentLine: any, parentLineId: string, parentText: record, parentTextId: string, userCreated: string, userModified: string>, lineMap: record<dateCreated: string, dateModified: string, id: string, intensityId: int, line: any, theme: record, themeId: string, userCreated: string, userModified: string>, lineMapId: string, parentConnector: any, parentShape: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: any, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, textContainer: record, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, rightBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, rightBorderId: string, shapeId: string, tLtoBRBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, tLtoBRBorderId: string, tailEndHeightId: int, tailEndTypeId: int, tailEndWidthId: int, topBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, topBorderId: string, userCreated: string, userModified: string, weight: int>, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, startConnectionIdx: int, startConnectionShape: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record<connectorId: string, dateCreated: string, dateModified: string, effectAttributes: list, effectMap: record, effectMapId: string, id: string, name: string, parentConnector: any, parentShape: any, shapeId: string, userCreated: string, userModified: string>, fillMap: record<connector: any, connectorId: string, dateCreated: string, dateModified: string, effectAttribute: record, effectAttributeId: string, fillTypeId: int, gradientFill: record, id: string, imageFill: record, shape: any, shapeId: string, solidFill: record, tableCell: record, tableCellId: string, themeBackgroundFill: record, themeBackgroundFillId: string, themeFill: record, themeFillId: string, userCreated: string, userModified: string>, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record<childGroupElements: list, connector: any, dateCreated: string, dateModified: string, graphic: record, group: record, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: any, shapeTree: record, shapeTreeId: string, typeInfo: record, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record<bLtoTRBorder: record, bLtoTRBorderId: string, bottomBorder: record, bottomBorderId: string, connectorId: string, dashTypeId: int, dateCreated: string, dateModified: string, headEndHeightId: int, headEndTypeId: int, headEndWidthId: int, id: string, leftBorder: record, leftBorderId: string, lineColorSolidFill: record, lineMap: record, lineMapId: string, parentConnector: any, parentShape: any, rightBorder: record, rightBorderId: string, shapeId: string, tLtoBRBorder: record, tLtoBRBorderId: string, tailEndHeightId: int, tailEndTypeId: int, tailEndWidthId: int, topBorder: record, topBorderId: string, userCreated: string, userModified: string, weight: int>, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, textContainer: record<axis: record, axisId: string, chart: record, chartId: string, dateCreated: string, dateModified: string, id: string, outerXml: string, paragraphs: list, parentShape: any, shapeId: string, tableCell: record, tableCellId: string, userCreated: string, userModified: string>, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, startConnectionShapeId: string, svgBlobUrl: string, userCreated: string, userModified: string>"
    slides-connectionshapes-openofficexml-get-id-updated: "record<id: string, openOfficeXml: string, type: string>"
    slides-connectionshapes-get-id: "record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, endConnectionIdx: int, endConnectionShapeId: string, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElementsId: string, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, startConnectionIdx: int, startConnectionShapeId: string, svgBlobUrl: string>"
    documents-post: "table<baseElementBlobUrl: string, blobLocation: string, changedBaseElementBlobUrl: string, documentTypeId: int, filename: string, id: string, name: string, ownerGuid: string, packageUri: string, storyId: string, tableStylesXmlBlobUrl: string, title: string>"
    documents-childobjects-get-id: "table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string>"
    documents-clone-post-id: "record<baseElementBlobUrl: string, blobLocation: string, changedBaseElementBlobUrl: string, documentTypeId: int, filename: string, id: string, name: string, ownerGuid: string, packageUri: string, storyId: string, tableStylesXmlBlobUrl: string, title: string>"
    documents-documenttype-get: "table<description: string, fileExtension: string, id: string, mimeType: string, name: string, ooxmlPackageType: string, typeId: int>"
    documents-documenttype-typeid-get-type-id: "record<description: string, fileExtension: string, id: string, mimeType: string, name: string, ooxmlPackageType: string, typeId: int>"
    documents-documenttype-get-id: "record<description: string, fileExtension: string, id: string, mimeType: string, name: string, ooxmlPackageType: string, typeId: int>"
    documents-download-get-id-orginal: "binary"
    documents-get-id: "record<baseElementBlobUrl: string, blobLocation: string, changedBaseElementBlobUrl: string, documentTypeId: int, filename: string, id: string, name: string, ownerGuid: string, packageUri: string, storyId: string, tableStylesXmlBlobUrl: string, title: string>"
    slides-groups-childobjects-get-id: "table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string>"
    slides-groups-details-get-id: "record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, groupElement: record<childGroupElements: list<any>, connector: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, endConnectionIdx: int, endConnectionShape: record, endConnectionShapeId: string, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: any, groupElementsId: string, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, startConnectionIdx: int, startConnectionShape: record, startConnectionShapeId: string, svgBlobUrl: string, userCreated: string, userModified: string>, dateCreated: string, dateModified: string, graphic: record<chart: record, dateCreated: string, dateModified: string, graphicTypeId: int, groupElement: any, groupElementsId: string, height: int, id: string, name: string, ooxmlId: int, picture: record, smartArt: record, table: record, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, group: any, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: any, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, textContainer: record, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, shapeTree: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, groupElement: any, groupElementId: string, groupElements: list, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, slide: record, slideId: string, svgBlobUrl: string, title: string, userCreated: string, userModified: string>, shapeTreeId: string, typeInfo: record<dateCreated: string, dateModified: string, description: string, id: string, name: string, typeId: int, userCreated: string, userModified: string>, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementId: string, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, svgBlobUrl: string, title: string, userCreated: string, userModified: string>"
    slides-groups-openofficexml-get-id-updated: "record<id: string, openOfficeXml: string, type: string>"
    slides-groups-get-id: "record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, groupElementId: string, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, svgBlobUrl: string, title: string>"
    shared-images-childobjects-get-id: "table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string>"
    shared-images-details-get-id: "record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, fileExtension: string, graphicsId: string, id: string, imageFileBlobUrl: string, imageFill: record<compressionState: string, dateCreated: string, dateModified: string, dpi: int, effectsJson: string, fillMap: record<connector: record, connectorId: string, dateCreated: string, dateModified: string, effectAttribute: record, effectAttributeId: string, fillTypeId: int, gradientFill: record, id: string, imageFill: any, shape: record, shapeId: string, solidFill: record, tableCell: record, tableCellId: string, themeBackgroundFill: record, themeBackgroundFillId: string, themeFill: record, themeFillId: string, userCreated: string, userModified: string>, fillMapId: string, id: string, picture: any, rotateWithShape: bool, sourceRectangle: string, stretch: bool, tile: string, userCreated: string, userModified: string>, imageFillsId: string, name: string, packageUri: string, parentGraphic: record<chart: record<axes: list, baseElementBlobUrl: string, changedBaseElementBlobUrl: string, chartData: record, dateCreated: string, dateModified: string, id: string, name: string, packageUri: string, parentGraphic: any, parentGraphicId: string, svgBlobUrl: string, titleTextContainer: record, userCreated: string, userModified: string>, dateCreated: string, dateModified: string, graphicTypeId: int, groupElement: record<childGroupElements: list, connector: record, dateCreated: string, dateModified: string, graphic: any, group: record, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: record, shapeTree: record, shapeTreeId: string, typeInfo: record, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementsId: string, height: int, id: string, name: string, ooxmlId: int, picture: any, smartArt: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, graphicsId: string, id: string, name: string, packageUri: string, parentGraphic: any, svgBlobUrl: string, userCreated: string, userModified: string>, table: record<baseElementBlobUrl: string, cells: list, changedBaseElementBlobUrl: string, columns: list, dateCreated: string, dateModified: string, hasStylePart: bool, id: string, name: string, packageUri: string, parentGraphic: any, parentGraphicId: string, rows: list, stylePartOuterXml: string, svgBlobUrl: string, userCreated: string, userModified: string>, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, userCreated: string, userModified: string>"
    shared-images-openofficexml-get-id-updated: "record<id: string, openOfficeXml: string, type: string>"
    shared-images-get-id: "record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, fileExtension: string, graphicsId: string, id: string, imageFileBlobUrl: string, imageFillsId: string, name: string, packageUri: string>"
    slides-shapetrees-childobjects-get-id: "table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string>"
    slides-shapetrees-details-get-id: "record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, groupElement: record<childGroupElements: list<any>, connector: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, endConnectionIdx: int, endConnectionShape: record, endConnectionShapeId: string, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: any, groupElementsId: string, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, startConnectionIdx: int, startConnectionShape: record, startConnectionShapeId: string, svgBlobUrl: string, userCreated: string, userModified: string>, dateCreated: string, dateModified: string, graphic: record<chart: record, dateCreated: string, dateModified: string, graphicTypeId: int, groupElement: any, groupElementsId: string, height: int, id: string, name: string, ooxmlId: int, picture: record, smartArt: record, table: record, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, group: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, groupElement: any, groupElementId: string, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, svgBlobUrl: string, title: string, userCreated: string, userModified: string>, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: any, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, textContainer: record, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, shapeTree: any, shapeTreeId: string, typeInfo: record<dateCreated: string, dateModified: string, description: string, id: string, name: string, typeId: int, userCreated: string, userModified: string>, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementId: string, groupElements: table<childGroupElements: list, connector: record, dateCreated: string, dateModified: string, graphic: record, group: record, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: record, shapeTree: any, shapeTreeId: string, typeInfo: record, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, slide: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, document: record<baseElementBlobUrl: string, blobLocation: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, documentTypeId: int, filename: string, id: string, name: string, ownerGuid: string, packageUri: string, slides: list, storyId: string, tableStylesXmlBlobUrl: string, title: string, userCreated: string, userModified: string>, documentId: string, id: string, name: string, number: int, ooxmlId: int, packageUri: string, shapeTree: any, slideDocumentUrl: string, slideMaster: record<colorMap: record, dateCreated: string, dateModified: string, id: string, parentSlide: any, slideId: string, userCreated: string, userModified: string>, svgBlobUrl: string, theme: record<backgroundFills: list, baseElementBlobUrl: string, changedBaseElementBlobUrl: string, colors: record, customColors: list, dateCreated: string, dateModified: string, effectMaps: list, fills: list, fonts: record, id: string, lineMaps: list, name: string, packageUri: string, slide: any, slideId: string, userCreated: string, userModified: string>, userCreated: string, userModified: string>, slideId: string, svgBlobUrl: string, title: string, userCreated: string, userModified: string>"
    slides-shapetrees-openofficexml-get-id-updated: "record<id: string, openOfficeXml: string, type: string>"
    slides-shapetrees-get-id: "record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, groupElementId: string, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, slideId: string, svgBlobUrl: string, title: string>"
    slides-shapes-childobjects-get-id: "table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string>"
    slides-shapes-details-get-id: "record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record<connectorId: string, dateCreated: string, dateModified: string, effectAttributes: list<record>, effectMap: record<dateCreated: string, dateModified: string, effect: any, id: string, intensityId: int, theme: record, themeId: string, userCreated: string, userModified: string>, effectMapId: string, id: string, name: string, parentConnector: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: any, endConnectionIdx: int, endConnectionShape: any, endConnectionShapeId: string, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record, groupElementsId: string, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, startConnectionIdx: int, startConnectionShape: any, startConnectionShapeId: string, svgBlobUrl: string, userCreated: string, userModified: string>, parentShape: any, shapeId: string, userCreated: string, userModified: string>, fillMap: record<connector: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, endConnectionIdx: int, endConnectionShape: any, endConnectionShapeId: string, fillMap: any, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record, groupElementsId: string, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, startConnectionIdx: int, startConnectionShape: any, startConnectionShapeId: string, svgBlobUrl: string, userCreated: string, userModified: string>, connectorId: string, dateCreated: string, dateModified: string, effectAttribute: record<attributesJson: string, dateCreated: string, dateModified: string, effect: record, effectId: string, effectTypeId: int, fillMap: any, id: string, userCreated: string, userModified: string>, effectAttributeId: string, fillTypeId: int, gradientFill: record<angle: int, dateCreated: string, dateModified: string, fillMap: any, fillMapId: string, gradientStops: list, id: string, isPath: bool, pathType: string, rotateWithShape: bool, userCreated: string, userModified: string>, id: string, imageFill: record<compressionState: string, dateCreated: string, dateModified: string, dpi: int, effectsJson: string, fillMap: any, fillMapId: string, id: string, picture: record, rotateWithShape: bool, sourceRectangle: string, stretch: bool, tile: string, userCreated: string, userModified: string>, shape: any, shapeId: string, solidFill: record<colorTransformations: record, colorTypeId: int, dateCreated: string, dateModified: string, fillMapId: string, hexValue: string, id: string, isUserColor: bool, parentFillMap: any, parentGradientStop: record, parentGradientStopId: string, parentLine: record, parentLineId: string, parentText: record, parentTextId: string, userCreated: string, userModified: string>, tableCell: record<border: record, column: record, columnId: string, columnSpan: int, dateCreated: string, dateModified: string, fillMap: any, id: string, isMergedHorozontal: bool, isMergedVertical: bool, row: record, rowId: string, rowSpan: int, textContainer: record, userCreated: string, userModified: string>, tableCellId: string, themeBackgroundFill: record<dateCreated: string, dateModified: string, fillMap: any, id: string, intensityId: int, theme: record, themeId: string, userCreated: string, userModified: string>, themeBackgroundFillId: string, themeFill: record<dateCreated: string, dateModified: string, fillMap: any, id: string, intensityId: int, theme: record, themeId: string, userCreated: string, userModified: string>, themeFillId: string, userCreated: string, userModified: string>, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record<childGroupElements: list<any>, connector: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, endConnectionIdx: int, endConnectionShape: any, endConnectionShapeId: string, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: any, groupElementsId: string, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, startConnectionIdx: int, startConnectionShape: any, startConnectionShapeId: string, svgBlobUrl: string, userCreated: string, userModified: string>, dateCreated: string, dateModified: string, graphic: record<chart: record, dateCreated: string, dateModified: string, graphicTypeId: int, groupElement: any, groupElementsId: string, height: int, id: string, name: string, ooxmlId: int, picture: record, smartArt: record, table: record, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, group: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, groupElement: any, groupElementId: string, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, svgBlobUrl: string, title: string, userCreated: string, userModified: string>, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: any, shapeTree: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, groupElement: any, groupElementId: string, groupElements: list, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, slide: record, slideId: string, svgBlobUrl: string, title: string, userCreated: string, userModified: string>, shapeTreeId: string, typeInfo: record<dateCreated: string, dateModified: string, description: string, id: string, name: string, typeId: int, userCreated: string, userModified: string>, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record<bLtoTRBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, bLtoTRBorderId: string, bottomBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, bottomBorderId: string, connectorId: string, dashTypeId: int, dateCreated: string, dateModified: string, headEndHeightId: int, headEndTypeId: int, headEndWidthId: int, id: string, leftBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, leftBorderId: string, lineColorSolidFill: record<colorTransformations: record, colorTypeId: int, dateCreated: string, dateModified: string, fillMapId: string, hexValue: string, id: string, isUserColor: bool, parentFillMap: record, parentGradientStop: record, parentGradientStopId: string, parentLine: any, parentLineId: string, parentText: record, parentTextId: string, userCreated: string, userModified: string>, lineMap: record<dateCreated: string, dateModified: string, id: string, intensityId: int, line: any, theme: record, themeId: string, userCreated: string, userModified: string>, lineMapId: string, parentConnector: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, endConnectionIdx: int, endConnectionShape: any, endConnectionShapeId: string, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record, groupElementsId: string, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: any, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, startConnectionIdx: int, startConnectionShape: any, startConnectionShapeId: string, svgBlobUrl: string, userCreated: string, userModified: string>, parentShape: any, rightBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, rightBorderId: string, shapeId: string, tLtoBRBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, tLtoBRBorderId: string, tailEndHeightId: int, tailEndTypeId: int, tailEndWidthId: int, topBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, topBorderId: string, userCreated: string, userModified: string, weight: int>, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, textContainer: record<axis: record<axisDataTypeId: int, chart: record, chartsId: string, dateCreated: string, dateModified: string, id: string, ooxmlId: int, titleTextContainer: any, userCreated: string, userModified: string>, axisId: string, chart: record<axes: list, baseElementBlobUrl: string, changedBaseElementBlobUrl: string, chartData: record, dateCreated: string, dateModified: string, id: string, name: string, packageUri: string, parentGraphic: record, parentGraphicId: string, svgBlobUrl: string, titleTextContainer: any, userCreated: string, userModified: string>, chartId: string, dateCreated: string, dateModified: string, id: string, outerXml: string, paragraphs: list<record>, parentShape: any, shapeId: string, tableCell: record<border: record, column: record, columnId: string, columnSpan: int, dateCreated: string, dateModified: string, fillMap: record, id: string, isMergedHorozontal: bool, isMergedVertical: bool, row: record, rowId: string, rowSpan: int, textContainer: any, userCreated: string, userModified: string>, tableCellId: string, userCreated: string, userModified: string>, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>"
    slides-shapes-openofficexml-get-id-updated: "record<id: string, openOfficeXml: string, type: string>"
    slides-shapes-get-id: "record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, width: int, xOffset: int, yOffset: int>"
    shared-colortransformationattributes-get-id: "record<colorTransformationsId: string, id: string, name: string, value: string>"
    shared-colortransformations-get-id: "record<id: string, name: string, solidFillsId: string>"
    shared-colortypes-get: "table<colorSchemeIndexValueEnum: int, description: string, id: string, name: string, typeId: int>"
    shared-colortypes-typeid-get-type-id: "record<colorSchemeIndexValueEnum: int, description: string, id: string, name: string, typeId: int>"
    shared-colortypes-get-id: "record<colorSchemeIndexValueEnum: int, description: string, id: string, name: string, typeId: int>"
    shared-dashtypes-get: "table<description: string, id: string, name: string, serializedAs: string, typeId: int>"
    shared-dashtypes-typeid-get-type-id: "record<description: string, id: string, name: string, serializedAs: string, typeId: int>"
    shared-dashtypes-get-id: "record<description: string, id: string, name: string, serializedAs: string, typeId: int>"
    shared-effectattributes-get-id: "record<attributesJson: string, effectId: string, effectTypeId: int, id: string>"
    shared-effecttypes-get: "table<description: string, id: string, name: string, typeId: int>"
    shared-effecttypes-typeid-get-type-id: "record<description: string, id: string, name: string, typeId: int>"
    shared-effecttypes-get-id: "record<description: string, id: string, name: string, typeId: int>"
    shared-effects-get-id: "record<connectorId: string, effectMapId: string, id: string, name: string, shapeId: string>"
    shared-fillmap-get-id: "record<connectorId: string, effectAttributeId: string, fillTypeId: int, id: string, shapeId: string, tableCellId: string, themeBackgroundFillId: string, themeFillId: string>"
    shared-filltypes-get: "table<description: string, id: string, name: string, typeId: int>"
    shared-filltypes-typeid-get-type-id: "record<description: string, id: string, name: string, typeId: int>"
    shared-filltypes-get-id: "record<description: string, id: string, name: string, typeId: int>"
    shared-gradientfills-get-id: "record<angle: int, fillMapId: string, id: string, isPath: bool, pathType: string, rotateWithShape: bool>"
    shared-gradientstops-get-id: "record<gradientFillsId: string, id: string, position: int>"
    shared-imagefills-get-id: "record<compressionState: string, dpi: int, effectsJson: string, fillMapId: string, id: string, rotateWithShape: bool, sourceRectangle: string, stretch: bool, tile: string>"
    shared-lineendsizes-get: "table<description: string, id: string, name: string, serializedAs: string, typeId: int>"
    shared-lineendsizes-typeid-get-type-id: "record<description: string, id: string, name: string, serializedAs: string, typeId: int>"
    shared-lineendsizes-get-id: "record<description: string, id: string, name: string, serializedAs: string, typeId: int>"
    shared-lineendtypes-get: "table<description: string, id: string, name: string, serializedAs: string, typeId: int>"
    shared-lineendtypes-typeid-get-type-id: "record<description: string, id: string, name: string, serializedAs: string, typeId: int>"
    shared-lineendtypes-get-id: "record<description: string, id: string, name: string, serializedAs: string, typeId: int>"
    shared-lines-get-id: "record<bLtoTRBorderId: string, bottomBorderId: string, connectorId: string, dashTypeId: int, headEndHeightId: int, headEndTypeId: int, headEndWidthId: int, id: string, leftBorderId: string, lineMapId: string, rightBorderId: string, shapeId: string, tLtoBRBorderId: string, tailEndHeightId: int, tailEndTypeId: int, tailEndWidthId: int, topBorderId: string, weight: int>"
    shared-paragraph-get-id: "record<id: string, number: int, textContainerId: string>"
    shared-solidfills-get-id: "record<colorTypeId: int, fillMapId: string, hexValue: string, id: string, isUserColor: bool, parentGradientStopId: string, parentLineId: string, parentTextId: string>"
    shared-text-get-id: "record<colorSolidFillsId: string, font: string, fontSize: int, id: string, isBold: bool, isItalic: bool, isThemeFont: bool, isUnderline: bool, paragraphId: string, rawText: string, sequence: int>"
    shared-textcontainer-get-id: "record<axisId: string, chartId: string, id: string, outerXml: string, shapeId: string, tableCellId: string>"
    slides-slides-childobjects-get-id: "table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string>"
    slides-colormaps-get-id: "record<accent1: int, accent2: int, accent3: int, accent4: int, accent5: int, accent6: int, background1: int, background2: int, followedHyperlink: int, hyperlink: int, id: string, slideMasterId: string, text1: int, text2: int>"
    slides-slides-details-get-id: "record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, document: record<baseElementBlobUrl: string, blobLocation: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, documentTypeId: int, filename: string, id: string, name: string, ownerGuid: string, packageUri: string, slides: list<any>, storyId: string, tableStylesXmlBlobUrl: string, title: string, userCreated: string, userModified: string>, documentId: string, id: string, name: string, number: int, ooxmlId: int, packageUri: string, shapeTree: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, groupElement: record<childGroupElements: list, connector: record, dateCreated: string, dateModified: string, graphic: record, group: record, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: record, shapeTree: any, shapeTreeId: string, typeInfo: record, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementId: string, groupElements: list<record>, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, slide: any, slideId: string, svgBlobUrl: string, title: string, userCreated: string, userModified: string>, slideDocumentUrl: string, slideMaster: record<colorMap: record<accent1: int, accent2: int, accent3: int, accent4: int, accent5: int, accent6: int, background1: int, background2: int, dateCreated: string, dateModified: string, followedHyperlink: int, hyperlink: int, id: string, slideMaster: any, slideMasterId: string, text1: int, text2: int, userCreated: string, userModified: string>, dateCreated: string, dateModified: string, id: string, parentSlide: any, slideId: string, userCreated: string, userModified: string>, svgBlobUrl: string, theme: record<backgroundFills: list<record>, baseElementBlobUrl: string, changedBaseElementBlobUrl: string, colors: record<accent1: string, accent2: string, accent3: string, accent4: string, accent5: string, accent6: string, dark1: string, dark2: string, dateCreated: string, dateModified: string, followedHyperlink: string, hyperlink: string, id: string, light1: string, light2: string, name: string, theme: any, themeId: string, userCreated: string, userModified: string>, customColors: list<record>, dateCreated: string, dateModified: string, effectMaps: list<record>, fills: list<record>, fonts: record<bodyFont: string, dateCreated: string, dateModified: string, headingFont: string, id: string, theme: any, themeId: string, userCreated: string, userModified: string>, id: string, lineMaps: list<record>, name: string, packageUri: string, slide: any, slideId: string, userCreated: string, userModified: string>, userCreated: string, userModified: string>"
    slides-graphictypes-get: "table<description: string, id: string, name: string, typeId: int>"
    slides-graphictypes-typeid-get-type-id: "record<description: string, id: string, name: string, typeId: int>"
    slides-graphictypes-get-id: "record<description: string, id: string, name: string, typeId: int>"
    slides-graphics-get-id: "record<graphicTypeId: int, groupElementsId: string, height: int, id: string, name: string, ooxmlId: int, width: int, xOffset: int, yOffset: int>"
    slides-groupelementtypes-get: "table<description: string, id: string, name: string, typeId: int>"
    slides-groupelementtypes-typeid-get-type-id: "record<description: string, id: string, name: string, typeId: int>"
    slides-groupelementtypes-get-id: "record<description: string, id: string, name: string, typeId: int>"
    slides-groupelements-get-id: "record<groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElementId: string, shapeTreeId: string, ultimateParentShapeTreeId: string>"
    slides-slides-openofficexml-get-id-updated: "record<id: string, openOfficeXml: string, type: string>"
    slides-slidemasters-get-id: "record<id: string, slideId: string>"
    slides-slides-get-id: "record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, documentId: string, id: string, name: string, number: int, ooxmlId: int, packageUri: string, slideDocumentUrl: string, svgBlobUrl: string>"
    slides-smartarts-childobjects-get-id: "table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string>"
    slides-smartarts-details-get-id: "record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, graphicsId: string, id: string, name: string, packageUri: string, parentGraphic: record<chart: record<axes: list, baseElementBlobUrl: string, changedBaseElementBlobUrl: string, chartData: record, dateCreated: string, dateModified: string, id: string, name: string, packageUri: string, parentGraphic: any, parentGraphicId: string, svgBlobUrl: string, titleTextContainer: record, userCreated: string, userModified: string>, dateCreated: string, dateModified: string, graphicTypeId: int, groupElement: record<childGroupElements: list, connector: record, dateCreated: string, dateModified: string, graphic: any, group: record, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: record, shapeTree: record, shapeTreeId: string, typeInfo: record, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementsId: string, height: int, id: string, name: string, ooxmlId: int, picture: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, fileExtension: string, graphicsId: string, id: string, imageFileBlobUrl: string, imageFill: record, imageFillsId: string, name: string, packageUri: string, parentGraphic: any, userCreated: string, userModified: string>, smartArt: any, table: record<baseElementBlobUrl: string, cells: list, changedBaseElementBlobUrl: string, columns: list, dateCreated: string, dateModified: string, hasStylePart: bool, id: string, name: string, packageUri: string, parentGraphic: any, parentGraphicId: string, rows: list, stylePartOuterXml: string, svgBlobUrl: string, userCreated: string, userModified: string>, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, svgBlobUrl: string, userCreated: string, userModified: string>"
    slides-smartarts-openofficexml-get-id-updated: "record<id: string, openOfficeXml: string, type: string>"
    slides-smartarts-get-id: "record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, graphicsId: string, id: string, name: string, packageUri: string, svgBlobUrl: string>"
    tables-borders-get-id: "record<cellId: string, id: string>"
    tables-cells-get-id: "record<columnId: string, columnSpan: int, id: string, isMergedHorozontal: bool, isMergedVertical: bool, rowId: string, rowSpan: int>"
    tables-tables-childobjects-get-id: "table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string>"
    tables-columns-get-id: "record<id: string, index: int, tableId: string, width: int>"
    tables-tables-details-get-id: "record<baseElementBlobUrl: string, cells: table<border: record, column: record, columnId: string, columnSpan: int, dateCreated: string, dateModified: string, fillMap: record, id: string, isMergedHorozontal: bool, isMergedVertical: bool, row: record, rowId: string, rowSpan: int, textContainer: record, userCreated: string, userModified: string>, changedBaseElementBlobUrl: string, columns: table<cells: list, dateCreated: string, dateModified: string, id: string, index: int, table: any, tableId: string, userCreated: string, userModified: string, width: int>, dateCreated: string, dateModified: string, hasStylePart: bool, id: string, name: string, packageUri: string, parentGraphic: record<chart: record<axes: list, baseElementBlobUrl: string, changedBaseElementBlobUrl: string, chartData: record, dateCreated: string, dateModified: string, id: string, name: string, packageUri: string, parentGraphic: any, parentGraphicId: string, svgBlobUrl: string, titleTextContainer: record, userCreated: string, userModified: string>, dateCreated: string, dateModified: string, graphicTypeId: int, groupElement: record<childGroupElements: list, connector: record, dateCreated: string, dateModified: string, graphic: any, group: record, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: record, shapeTree: record, shapeTreeId: string, typeInfo: record, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementsId: string, height: int, id: string, name: string, ooxmlId: int, picture: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, fileExtension: string, graphicsId: string, id: string, imageFileBlobUrl: string, imageFill: record, imageFillsId: string, name: string, packageUri: string, parentGraphic: any, userCreated: string, userModified: string>, smartArt: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, graphicsId: string, id: string, name: string, packageUri: string, parentGraphic: any, svgBlobUrl: string, userCreated: string, userModified: string>, table: any, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, parentGraphicId: string, rows: table<cells: list, dateCreated: string, dateModified: string, height: int, id: string, index: int, table: any, tableId: string, userCreated: string, userModified: string>, stylePartOuterXml: string, svgBlobUrl: string, userCreated: string, userModified: string>"
    tables-tables-openofficexml-get-id-updated: "record<id: string, openOfficeXml: string, type: string>"
    tables-rows-get-id: "record<height: int, id: string, index: int, tableId: string>"
    tables-tables-tableupdate-get-id: "record<tableData: list<list<string>>, tableId: string>"
    tables-tables-get-id: "record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, hasStylePart: bool, id: string, name: string, packageUri: string, parentGraphicId: string, stylePartOuterXml: string, svgBlobUrl: string>"
    themes-backgroundfills-get-id: "record<id: string, intensityId: int, themeId: string>"
    theme-themes-childobjects-get-id: "table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string>"
    themes-colors-get-id: "record<accent1: string, accent2: string, accent3: string, accent4: string, accent5: string, accent6: string, dark1: string, dark2: string, followedHyperlink: string, hyperlink: string, id: string, light1: string, light2: string, name: string, themeId: string>"
    themes-customcolors-get-id: "record<hexValue: string, id: string, name: string, themeId: string>"
    theme-themes-details-get-id: "record<backgroundFills: table<dateCreated: string, dateModified: string, fillMap: record, id: string, intensityId: int, theme: any, themeId: string, userCreated: string, userModified: string>, baseElementBlobUrl: string, changedBaseElementBlobUrl: string, colors: record<accent1: string, accent2: string, accent3: string, accent4: string, accent5: string, accent6: string, dark1: string, dark2: string, dateCreated: string, dateModified: string, followedHyperlink: string, hyperlink: string, id: string, light1: string, light2: string, name: string, theme: any, themeId: string, userCreated: string, userModified: string>, customColors: table<dateCreated: string, dateModified: string, hexValue: string, id: string, name: string, theme: any, themeId: string, userCreated: string, userModified: string>, dateCreated: string, dateModified: string, effectMaps: table<dateCreated: string, dateModified: string, effect: record, id: string, intensityId: int, theme: any, themeId: string, userCreated: string, userModified: string>, fills: table<dateCreated: string, dateModified: string, fillMap: record, id: string, intensityId: int, theme: any, themeId: string, userCreated: string, userModified: string>, fonts: record<bodyFont: string, dateCreated: string, dateModified: string, headingFont: string, id: string, theme: any, themeId: string, userCreated: string, userModified: string>, id: string, lineMaps: table<dateCreated: string, dateModified: string, id: string, intensityId: int, line: record, theme: any, themeId: string, userCreated: string, userModified: string>, name: string, packageUri: string, slide: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, document: record<baseElementBlobUrl: string, blobLocation: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, documentTypeId: int, filename: string, id: string, name: string, ownerGuid: string, packageUri: string, slides: list, storyId: string, tableStylesXmlBlobUrl: string, title: string, userCreated: string, userModified: string>, documentId: string, id: string, name: string, number: int, ooxmlId: int, packageUri: string, shapeTree: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, groupElement: record, groupElementId: string, groupElements: list, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, slide: any, slideId: string, svgBlobUrl: string, title: string, userCreated: string, userModified: string>, slideDocumentUrl: string, slideMaster: record<colorMap: record, dateCreated: string, dateModified: string, id: string, parentSlide: any, slideId: string, userCreated: string, userModified: string>, svgBlobUrl: string, theme: any, userCreated: string, userModified: string>, slideId: string, userCreated: string, userModified: string>"
    themes-effectmap-get-id: "record<id: string, intensityId: int, themeId: string>"
    themes-fills-get-id: "record<id: string, intensityId: int, themeId: string>"
    themes-fonts-get-id: "record<bodyFont: string, headingFont: string, id: string, themeId: string>"
    themes-intensity-get: "table<description: string, id: string, name: string, typeId: int>"
    themes-intensity-typeid-get-type-id: "record<description: string, id: string, name: string, typeId: int>"
    themes-intensity-get-id: "record<description: string, id: string, name: string, typeId: int>"
    themes-linemap-get-id: "record<id: string, intensityId: int, themeId: string>"
    theme-themes-openofficexml-get-id-updated: "record<id: string, openOfficeXml: string, type: string>"
    theme-themes-get-id: "record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, id: string, name: string, packageUri: string, slideId: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["chart-axes-get-id" "chart-axisdatatypes-get" "chart-axisdatatypes-typeid-get-type-id" "chart-axisdatatypes-get-id" "chart-chartdata-get-id" "charts-charts-chartupdate-get-id" "charts-charts-chartupdate-put-id" "charts-charts-childobjects-get-id" "chart-columncollections-get-id" "chart-columns-get-id" "chart-datapoints-get-id" "charts-charts-details-get-id" "charts-charts-openofficexml-get-id-updated" "charts-charts-openofficexml-put-id" "chart-plottype-get" "chart-plottype-typeid-get-type-id" "chart-plottype-get-id" "chart-rowcol-get" "chart-rowcol-typeid-get-type-id" "chart-rowcol-get-id" "chart-rowcollections-get-id" "chart-rownameformattypes-get" "chart-rownameformattypes-typeid-get-type-id" "chart-rownameformattypes-get-id" "chart-rows-get-id" "charts-charts-svg-get-id-use-cache" "charts-charts-get-id" "slides-connectionshapes-childobjects-get-id" "slides-connectionshapes-details-get-id" "slides-connectionshapes-openofficexml-get-id-updated" "slides-connectionshapes-openofficexml-put-id" "slides-connectionshapes-svg-get-id-use-cache" "slides-connectionshapes-get-id" "documents-post" "documents-childobjects-get-id" "documents-clone-post-id" "documents-documenttype-get" "documents-documenttype-typeid-get-type-id" "documents-documenttype-get-id" "documents-download-get-id-orginal" "documents-delete-id" "documents-get-id" "slides-groups-childobjects-get-id" "slides-groups-details-get-id" "slides-groups-openofficexml-get-id-updated" "slides-groups-openofficexml-put-id" "slides-groups-svg-get-id-use-cache" "slides-groups-get-id" "shared-images-childobjects-get-id" "shared-images-details-get-id" "shared-images-getimage-put-id" "shared-images-openofficexml-get-id-updated" "shared-images-openofficexml-put-id" "shared-images-svg-get-id-use-cache" "shared-images-get-id" "slides-shapetrees-childobjects-get-id" "slides-shapetrees-details-get-id" "slides-shapetrees-openofficexml-get-id-updated" "slides-shapetrees-openofficexml-put-id" "slides-shapetrees-svg-get-id-use-cache" "slides-shapetrees-get-id" "slides-shapes-childobjects-get-id" "slides-shapes-details-get-id" "slides-shapes-openofficexml-get-id-updated" "slides-shapes-openofficexml-put-id" "slides-shapes-svg-get-id-use-cache" "slides-shapes-get-id" "shared-colortransformationattributes-get-id" "shared-colortransformations-get-id" "shared-colortypes-get" "shared-colortypes-typeid-get-type-id" "shared-colortypes-get-id" "shared-dashtypes-get" "shared-dashtypes-typeid-get-type-id" "shared-dashtypes-get-id" "shared-effectattributes-get-id" "shared-effecttypes-get" "shared-effecttypes-typeid-get-type-id" "shared-effecttypes-get-id" "shared-effects-get-id" "shared-fillmap-get-id" "shared-filltypes-get" "shared-filltypes-typeid-get-type-id" "shared-filltypes-get-id" "shared-gradientfills-get-id" "shared-gradientstops-get-id" "shared-imagefills-get-id" "shared-lineendsizes-get" "shared-lineendsizes-typeid-get-type-id" "shared-lineendsizes-get-id" "shared-lineendtypes-get" "shared-lineendtypes-typeid-get-type-id" "shared-lineendtypes-get-id" "shared-lines-get-id" "shared-paragraph-get-id" "shared-solidfills-get-id" "shared-text-get-id" "shared-textcontainer-get-id" "slides-slides-childobjects-get-id" "slides-colormaps-get-id" "slides-slides-details-get-id" "slides-graphictypes-get" "slides-graphictypes-typeid-get-type-id" "slides-graphictypes-get-id" "slides-graphics-get-id" "slides-groupelementtypes-get" "slides-groupelementtypes-typeid-get-type-id" "slides-groupelementtypes-get-id" "slides-groupelements-get-id" "slides-slides-openofficexml-get-id-updated" "slides-slides-openofficexml-put-id" "slides-slidemasters-get-id" "slides-slides-svg-get-id-use-cache" "slides-slides-get-id" "slides-smartarts-childobjects-get-id" "slides-smartarts-details-get-id" "slides-smartarts-openofficexml-get-id-updated" "slides-smartarts-openofficexml-put-id" "slides-smartarts-svg-get-id-use-cache" "slides-smartarts-get-id" "tables-borders-get-id" "tables-cells-get-id" "tables-tables-childobjects-get-id" "tables-columns-get-id" "tables-tables-details-get-id" "tables-tables-openofficexml-get-id-updated" "tables-tables-openofficexml-put-id" "tables-rows-get-id" "tables-tables-svg-get-id-use-cache" "tables-tables-tableupdate-get-id" "tables-tables-tableupdate-put-id" "tables-tables-get-id" "themes-backgroundfills-get-id" "theme-themes-childobjects-get-id" "themes-colors-get-id" "themes-customcolors-get-id" "theme-themes-details-get-id" "themes-effectmap-get-id" "themes-fills-get-id" "themes-fonts-get-id" "themes-intensity-get" "themes-intensity-typeid-get-type-id" "themes-intensity-get-id" "themes-linemap-get-id" "theme-themes-openofficexml-get-id-updated" "theme-themes-openofficexml-put-id" "theme-themes-svg-get-id-use-cache" "theme-themes-get-id" "commands"] | sort) } | get name | first)
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

# Axes: Get by Id
#
# GET /Charts/Axes/{id}
# Returns: record<axisDataTypeId: int, chartsId: string, id: string, ooxmlId: int>
# operationId: chart_axes_get_id
export def "chart-axes-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Charts/Axes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# AxisDataTypes: List All Possible Types
#
# GET /Charts/AxisDataTypes
# Returns: table<description: string, id: string, name: string, ooxmlName: string, typeId: int>
# operationId: chart_axisdatatypes_get
export def "chart-axisdatatypes-get" [
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
    path: "/Charts/AxisDataTypes"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# AxisDataTypes: Get By Type Id
#
# GET /Charts/AxisDataTypes/TypeId/{type_id}
# Returns: record<description: string, id: string, name: string, ooxmlName: string, typeId: int>
# operationId: chart_axisdatatypes_typeid_get_type_id
export def "chart-axisdatatypes-typeid-get-type-id" [
  type_id: int
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
    path: "/Charts/AxisDataTypes/TypeId/{type_id}"
    path_params: [{name: type_id, var: type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type_id: $type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# AxisDataTypes: Get by Id
#
# GET /Charts/AxisDataTypes/{id}
# Returns: record<description: string, id: string, name: string, ooxmlName: string, typeId: int>
# operationId: chart_axisdatatypes_get_id
export def "chart-axisdatatypes-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Charts/AxisDataTypes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ChartData: Get by Id
#
# GET /Charts/ChartData/{id}
# Returns: record<chartId: string, id: string>
# operationId: chart_chartdata_get_id
export def "chart-chartdata-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Charts/ChartData/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Charts: Get Chart Data
#
# GET /Charts/ChartUpdate/{id}
# Returns: record<categoryNames: list<string>, chartId: string, dataPoints: list<list<float>>, seriesNames: list<string>>
# operationId: charts_charts_chartupdate_get_id
export def "charts-charts-chartupdate-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Charts/ChartUpdate/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Charts: Update Chart Data
#
# PUT /Charts/ChartUpdate/{id}
# operationId: charts_charts_chartupdate_put_id
export def "charts-charts-chartupdate-put-id" [
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
  --category-names: list<string> # nullable
  --chart-id: string # format: uuid
  --data-points: list # nullable
  --series-names: list<string> # nullable
]: any -> any {
  $in | http-request {
    method: put
    path: "/Charts/ChartUpdate/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: categoryNames, var: category_names}, {name: chartId, var: chart_id}, {name: dataPoints, var: data_points}, {name: seriesNames, var: series_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, category_names: $category_names, chart_id: $chart_id, data_points: $data_points, series_names: $series_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Charts: Get Dependent Objects Tree
#
# GET /Charts/ChildObjects/{id}
# Returns: table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string>
# operationId: charts_charts_childobjects_get_id
export def "charts-charts-childobjects-get-id" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Charts/ChildObjects/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ColumnCollections: Get by Id
#
# GET /Charts/ColumnCollections/{id}
# Returns: record<chartDataId: string, id: string>
# operationId: chart_columncollections_get_id
export def "chart-columncollections-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Charts/ColumnCollections/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Columns: Get by Id
#
# GET /Charts/Columns/{id}
# Returns: record<axisId: string, columnCollectionId: string, id: string, index: int, name: string>
# operationId: chart_columns_get_id
export def "chart-columns-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Charts/Columns/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DataPoints: Get by Id
#
# GET /Charts/DataPoints/{id}
# Returns: record<chartDataId: string, columnId: string, id: string, rowId: string, value: float>
# operationId: chart_datapoints_get_id
export def "chart-datapoints-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Charts/DataPoints/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Charts: Get Details
#
# GET /Charts/Details/{id}
# Returns: record<axes: table<axisDataTypeId: int, chart: any, chartsId: string, dateCreated: string, dateModified: string, id: string, ooxmlId: int, titleTextContainer: record, userCreated: string, userModified: string>, baseElementBlobUrl: string, changedBaseElementBlobUrl: string, chartData: record<chart: any, chartId: string, columnCollection: record<chartData: any, chartDataId: string, columns: list, dateCreated: string, dateModified: string, id: string, userCreated: string, userModified: string>, dataPoints: list<record>, dateCreated: string, dateModified: string, id: string, rowCollection: record<axis: record, axisId: string, chartData: any, chartDataId: string, dateCreated: string, dateModified: string, id: string, nameFormatType: int, rows: list, userCreated: string, userModified: string>, userCreated: string, userModified: string>, dateCreated: string, dateModified: string, id: string, name: string, packageUri: string, parentGraphic: record<chart: any, dateCreated: string, dateModified: string, graphicTypeId: int, groupElement: record<childGroupElements: list, connector: record, dateCreated: string, dateModified: string, graphic: any, group: record, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: record, shapeTree: record, shapeTreeId: string, typeInfo: record, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementsId: string, height: int, id: string, name: string, ooxmlId: int, picture: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, fileExtension: string, graphicsId: string, id: string, imageFileBlobUrl: string, imageFill: record, imageFillsId: string, name: string, packageUri: string, parentGraphic: any, userCreated: string, userModified: string>, smartArt: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, graphicsId: string, id: string, name: string, packageUri: string, parentGraphic: any, svgBlobUrl: string, userCreated: string, userModified: string>, table: record<baseElementBlobUrl: string, cells: list, changedBaseElementBlobUrl: string, columns: list, dateCreated: string, dateModified: string, hasStylePart: bool, id: string, name: string, packageUri: string, parentGraphic: any, parentGraphicId: string, rows: list, stylePartOuterXml: string, svgBlobUrl: string, userCreated: string, userModified: string>, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, parentGraphicId: string, svgBlobUrl: string, titleTextContainer: record<axis: record<axisDataTypeId: int, chart: any, chartsId: string, dateCreated: string, dateModified: string, id: string, ooxmlId: int, titleTextContainer: any, userCreated: string, userModified: string>, axisId: string, chart: any, chartId: string, dateCreated: string, dateModified: string, id: string, outerXml: string, paragraphs: list<record>, parentShape: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, textContainer: any, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, shapeId: string, tableCell: record<border: record, column: record, columnId: string, columnSpan: int, dateCreated: string, dateModified: string, fillMap: record, id: string, isMergedHorozontal: bool, isMergedVertical: bool, row: record, rowId: string, rowSpan: int, textContainer: any, userCreated: string, userModified: string>, tableCellId: string, userCreated: string, userModified: string>, userCreated: string, userModified: string>
# operationId: charts_charts_details_get_id
export def "charts-charts-details-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Charts/Details/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Charts: Get Underlying Xml
#
# GET /Charts/OpenOfficeXml/{id}
# Returns: record<id: string, openOfficeXml: string, type: string>
# operationId: charts_charts_openofficexml_get_id_updated
export def "charts-charts-openofficexml-get-id-updated" [
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
  --updated: oneof<nothing, bool> # Indicates whether API should return the orginal uploaded xml (false) or the actively updated version (true, default) (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Charts/OpenOfficeXml/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: updated, var: updated}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, updated: $updated
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Charts: Modify Underlying Xml
#
# PUT /Charts/OpenOfficeXml/{id}
# operationId: charts_charts_openofficexml_put_id
export def "charts-charts-openofficexml-put-id" [
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
  --body-id: string # nullable, format: uuid (spec name: id)
  --open-office-xml: string # nullable
  --type: string # nullable
]: any -> any {
  $in | http-request {
    method: put
    path: "/Charts/OpenOfficeXml/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: body_id}, {name: openOfficeXml, var: open_office_xml}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body_id: $body_id, open_office_xml: $open_office_xml, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PlotType: List All Possible Types
#
# GET /Charts/PlotType
# Returns: table<id: string, plotQualifedAssy: string, plotTypeName: string, rowColTypeId: int, typeId: int>
# operationId: chart_plottype_get
export def "chart-plottype-get" [
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
    path: "/Charts/PlotType"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PlotType: Get By Type Id
#
# GET /Charts/PlotType/TypeId/{type_id}
# Returns: record<id: string, plotQualifedAssy: string, plotTypeName: string, rowColTypeId: int, typeId: int>
# operationId: chart_plottype_typeid_get_type_id
export def "chart-plottype-typeid-get-type-id" [
  type_id: int
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
    path: "/Charts/PlotType/TypeId/{type_id}"
    path_params: [{name: type_id, var: type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type_id: $type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PlotType: Get by Id
#
# GET /Charts/PlotType/{id}
# Returns: record<id: string, plotQualifedAssy: string, plotTypeName: string, rowColTypeId: int, typeId: int>
# operationId: chart_plottype_get_id
export def "chart-plottype-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Charts/PlotType/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RowCol: List All Possible Types
#
# GET /Charts/RowCol
# Returns: table<colName: string, colQualifiedAssy: string, id: string, rowName: string, rowQualifedAssy: string, typeId: int>
# operationId: chart_rowcol_get
export def "chart-rowcol-get" [
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
    path: "/Charts/RowCol"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RowCol: Get By Type Id
#
# GET /Charts/RowCol/TypeId/{type_id}
# Returns: record<colName: string, colQualifiedAssy: string, id: string, rowName: string, rowQualifedAssy: string, typeId: int>
# operationId: chart_rowcol_typeid_get_type_id
export def "chart-rowcol-typeid-get-type-id" [
  type_id: int
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
    path: "/Charts/RowCol/TypeId/{type_id}"
    path_params: [{name: type_id, var: type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type_id: $type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RowCol: Get by Id
#
# GET /Charts/RowCol/{id}
# Returns: record<colName: string, colQualifiedAssy: string, id: string, rowName: string, rowQualifedAssy: string, typeId: int>
# operationId: chart_rowcol_get_id
export def "chart-rowcol-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Charts/RowCol/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RowCollections: Get by Id
#
# GET /Charts/RowCollections/{id}
# Returns: record<axisId: string, chartDataId: string, id: string, nameFormatType: int>
# operationId: chart_rowcollections_get_id
export def "chart-rowcollections-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Charts/RowCollections/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RowNameFormatTypes: List All Possible Types
#
# GET /Charts/RowNameFormatTypes
# Returns: table<formatCode: string, id: string, powerToolsId: int, typeId: int>
# operationId: chart_rownameformattypes_get
export def "chart-rownameformattypes-get" [
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
    path: "/Charts/RowNameFormatTypes"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RowNameFormatTypes: Get By Type Id
#
# GET /Charts/RowNameFormatTypes/TypeId/{type_id}
# Returns: record<formatCode: string, id: string, powerToolsId: int, typeId: int>
# operationId: chart_rownameformattypes_typeid_get_type_id
export def "chart-rownameformattypes-typeid-get-type-id" [
  type_id: int
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
    path: "/Charts/RowNameFormatTypes/TypeId/{type_id}"
    path_params: [{name: type_id, var: type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type_id: $type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RowNameFormatTypes: Get by Id
#
# GET /Charts/RowNameFormatTypes/{id}
# Returns: record<formatCode: string, id: string, powerToolsId: int, typeId: int>
# operationId: chart_rownameformattypes_get_id
export def "chart-rownameformattypes-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Charts/RowNameFormatTypes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rows: Get by Id
#
# GET /Charts/Rows/{id}
# Returns: record<id: string, index: int, name: string, rowNameCollectionId: string>
# operationId: chart_rows_get_id
export def "chart-rows-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Charts/Rows/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Charts: Get Svg file
#
# GET /Charts/Svg/{id}
# operationId: charts_charts_svg_get_id_use_cache
export def "charts-charts-svg-get-id-use-cache" [
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
  --use-cache: oneof<nothing, bool> # Indicates whether API should retrieve content from a cache if aviable (true, default), or force an update (false) (default: false)
]: nothing -> any {
  http-request {
    method: get
    path: "/Charts/Svg/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: use_cache, var: use_cache}]
    accept: ["image/svg+xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, use_cache: $use_cache
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Charts: Get by Id
#
# GET /Charts/{id}
# Returns: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, id: string, name: string, packageUri: string, parentGraphicId: string, svgBlobUrl: string>
# operationId: charts_charts_get_id
export def "charts-charts-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Charts/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Slides: Get Dependent Objects Tree
#
# GET /ConnectionShapes/ChildObjects/{id}
# Returns: table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string>
# operationId: slides_connectionshapes_childobjects_get_id
export def "slides-connectionshapes-childobjects-get-id" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/ConnectionShapes/ChildObjects/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Slides: Get Details
#
# GET /ConnectionShapes/Details/{id}
# Returns: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record<connectorId: string, dateCreated: string, dateModified: string, effectAttributes: list<record>, effectMap: record<dateCreated: string, dateModified: string, effect: any, id: string, intensityId: int, theme: record, themeId: string, userCreated: string, userModified: string>, effectMapId: string, id: string, name: string, parentConnector: any, parentShape: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: any, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, textContainer: record, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, shapeId: string, userCreated: string, userModified: string>, endConnectionIdx: int, endConnectionShape: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record<connectorId: string, dateCreated: string, dateModified: string, effectAttributes: list, effectMap: record, effectMapId: string, id: string, name: string, parentConnector: any, parentShape: any, shapeId: string, userCreated: string, userModified: string>, fillMap: record<connector: any, connectorId: string, dateCreated: string, dateModified: string, effectAttribute: record, effectAttributeId: string, fillTypeId: int, gradientFill: record, id: string, imageFill: record, shape: any, shapeId: string, solidFill: record, tableCell: record, tableCellId: string, themeBackgroundFill: record, themeBackgroundFillId: string, themeFill: record, themeFillId: string, userCreated: string, userModified: string>, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record<childGroupElements: list, connector: any, dateCreated: string, dateModified: string, graphic: record, group: record, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: any, shapeTree: record, shapeTreeId: string, typeInfo: record, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record<bLtoTRBorder: record, bLtoTRBorderId: string, bottomBorder: record, bottomBorderId: string, connectorId: string, dashTypeId: int, dateCreated: string, dateModified: string, headEndHeightId: int, headEndTypeId: int, headEndWidthId: int, id: string, leftBorder: record, leftBorderId: string, lineColorSolidFill: record, lineMap: record, lineMapId: string, parentConnector: any, parentShape: any, rightBorder: record, rightBorderId: string, shapeId: string, tLtoBRBorder: record, tLtoBRBorderId: string, tailEndHeightId: int, tailEndTypeId: int, tailEndWidthId: int, topBorder: record, topBorderId: string, userCreated: string, userModified: string, weight: int>, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, textContainer: record<axis: record, axisId: string, chart: record, chartId: string, dateCreated: string, dateModified: string, id: string, outerXml: string, paragraphs: list, parentShape: any, shapeId: string, tableCell: record, tableCellId: string, userCreated: string, userModified: string>, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, endConnectionShapeId: string, fillMap: record<connector: any, connectorId: string, dateCreated: string, dateModified: string, effectAttribute: record<attributesJson: string, dateCreated: string, dateModified: string, effect: record, effectId: string, effectTypeId: int, fillMap: any, id: string, userCreated: string, userModified: string>, effectAttributeId: string, fillTypeId: int, gradientFill: record<angle: int, dateCreated: string, dateModified: string, fillMap: any, fillMapId: string, gradientStops: list, id: string, isPath: bool, pathType: string, rotateWithShape: bool, userCreated: string, userModified: string>, id: string, imageFill: record<compressionState: string, dateCreated: string, dateModified: string, dpi: int, effectsJson: string, fillMap: any, fillMapId: string, id: string, picture: record, rotateWithShape: bool, sourceRectangle: string, stretch: bool, tile: string, userCreated: string, userModified: string>, shape: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, fillMap: any, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, textContainer: record, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, shapeId: string, solidFill: record<colorTransformations: record, colorTypeId: int, dateCreated: string, dateModified: string, fillMapId: string, hexValue: string, id: string, isUserColor: bool, parentFillMap: any, parentGradientStop: record, parentGradientStopId: string, parentLine: record, parentLineId: string, parentText: record, parentTextId: string, userCreated: string, userModified: string>, tableCell: record<border: record, column: record, columnId: string, columnSpan: int, dateCreated: string, dateModified: string, fillMap: any, id: string, isMergedHorozontal: bool, isMergedVertical: bool, row: record, rowId: string, rowSpan: int, textContainer: record, userCreated: string, userModified: string>, tableCellId: string, themeBackgroundFill: record<dateCreated: string, dateModified: string, fillMap: any, id: string, intensityId: int, theme: record, themeId: string, userCreated: string, userModified: string>, themeBackgroundFillId: string, themeFill: record<dateCreated: string, dateModified: string, fillMap: any, id: string, intensityId: int, theme: record, themeId: string, userCreated: string, userModified: string>, themeFillId: string, userCreated: string, userModified: string>, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record<childGroupElements: list<any>, connector: any, dateCreated: string, dateModified: string, graphic: record<chart: record, dateCreated: string, dateModified: string, graphicTypeId: int, groupElement: any, groupElementsId: string, height: int, id: string, name: string, ooxmlId: int, picture: record, smartArt: record, table: record, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, group: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, groupElement: any, groupElementId: string, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, svgBlobUrl: string, title: string, userCreated: string, userModified: string>, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: any, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, textContainer: record, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, shapeTree: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, groupElement: any, groupElementId: string, groupElements: list, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, slide: record, slideId: string, svgBlobUrl: string, title: string, userCreated: string, userModified: string>, shapeTreeId: string, typeInfo: record<dateCreated: string, dateModified: string, description: string, id: string, name: string, typeId: int, userCreated: string, userModified: string>, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementsId: string, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record<bLtoTRBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, bLtoTRBorderId: string, bottomBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, bottomBorderId: string, connectorId: string, dashTypeId: int, dateCreated: string, dateModified: string, headEndHeightId: int, headEndTypeId: int, headEndWidthId: int, id: string, leftBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, leftBorderId: string, lineColorSolidFill: record<colorTransformations: record, colorTypeId: int, dateCreated: string, dateModified: string, fillMapId: string, hexValue: string, id: string, isUserColor: bool, parentFillMap: record, parentGradientStop: record, parentGradientStopId: string, parentLine: any, parentLineId: string, parentText: record, parentTextId: string, userCreated: string, userModified: string>, lineMap: record<dateCreated: string, dateModified: string, id: string, intensityId: int, line: any, theme: record, themeId: string, userCreated: string, userModified: string>, lineMapId: string, parentConnector: any, parentShape: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: any, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, textContainer: record, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, rightBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, rightBorderId: string, shapeId: string, tLtoBRBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, tLtoBRBorderId: string, tailEndHeightId: int, tailEndTypeId: int, tailEndWidthId: int, topBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, topBorderId: string, userCreated: string, userModified: string, weight: int>, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, startConnectionIdx: int, startConnectionShape: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record<connectorId: string, dateCreated: string, dateModified: string, effectAttributes: list, effectMap: record, effectMapId: string, id: string, name: string, parentConnector: any, parentShape: any, shapeId: string, userCreated: string, userModified: string>, fillMap: record<connector: any, connectorId: string, dateCreated: string, dateModified: string, effectAttribute: record, effectAttributeId: string, fillTypeId: int, gradientFill: record, id: string, imageFill: record, shape: any, shapeId: string, solidFill: record, tableCell: record, tableCellId: string, themeBackgroundFill: record, themeBackgroundFillId: string, themeFill: record, themeFillId: string, userCreated: string, userModified: string>, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record<childGroupElements: list, connector: any, dateCreated: string, dateModified: string, graphic: record, group: record, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: any, shapeTree: record, shapeTreeId: string, typeInfo: record, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record<bLtoTRBorder: record, bLtoTRBorderId: string, bottomBorder: record, bottomBorderId: string, connectorId: string, dashTypeId: int, dateCreated: string, dateModified: string, headEndHeightId: int, headEndTypeId: int, headEndWidthId: int, id: string, leftBorder: record, leftBorderId: string, lineColorSolidFill: record, lineMap: record, lineMapId: string, parentConnector: any, parentShape: any, rightBorder: record, rightBorderId: string, shapeId: string, tLtoBRBorder: record, tLtoBRBorderId: string, tailEndHeightId: int, tailEndTypeId: int, tailEndWidthId: int, topBorder: record, topBorderId: string, userCreated: string, userModified: string, weight: int>, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, textContainer: record<axis: record, axisId: string, chart: record, chartId: string, dateCreated: string, dateModified: string, id: string, outerXml: string, paragraphs: list, parentShape: any, shapeId: string, tableCell: record, tableCellId: string, userCreated: string, userModified: string>, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, startConnectionShapeId: string, svgBlobUrl: string, userCreated: string, userModified: string>
# operationId: slides_connectionshapes_details_get_id
export def "slides-connectionshapes-details-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ConnectionShapes/Details/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Slides: Get Underlying Xml
#
# GET /ConnectionShapes/OpenOfficeXml/{id}
# Returns: record<id: string, openOfficeXml: string, type: string>
# operationId: slides_connectionshapes_openofficexml_get_id_updated
export def "slides-connectionshapes-openofficexml-get-id-updated" [
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
  --updated: oneof<nothing, bool> # Indicates whether API should return the orginal uploaded xml (false) or the actively updated version (true, default) (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ConnectionShapes/OpenOfficeXml/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: updated, var: updated}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, updated: $updated
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Slides: Modify Underlying Xml
#
# PUT /ConnectionShapes/OpenOfficeXml/{id}
# operationId: slides_connectionshapes_openofficexml_put_id
export def "slides-connectionshapes-openofficexml-put-id" [
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
  --body-id: string # nullable, format: uuid (spec name: id)
  --open-office-xml: string # nullable
  --type: string # nullable
]: any -> any {
  $in | http-request {
    method: put
    path: "/ConnectionShapes/OpenOfficeXml/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: body_id}, {name: openOfficeXml, var: open_office_xml}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body_id: $body_id, open_office_xml: $open_office_xml, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Slides: Get Svg file
#
# GET /ConnectionShapes/Svg/{id}
# operationId: slides_connectionshapes_svg_get_id_use_cache
export def "slides-connectionshapes-svg-get-id-use-cache" [
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
  --use-cache: oneof<nothing, bool> # Indicates whether API should retrieve content from a cache if aviable (true, default), or force an update (false) (default: false)
]: nothing -> any {
  http-request {
    method: get
    path: "/ConnectionShapes/Svg/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: use_cache, var: use_cache}]
    accept: ["image/svg+xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, use_cache: $use_cache
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ConnectionShapes: Get by Id
#
# GET /ConnectionShapes/{id}
# Returns: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, endConnectionIdx: int, endConnectionShapeId: string, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElementsId: string, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, startConnectionIdx: int, startConnectionShapeId: string, svgBlobUrl: string>
# operationId: slides_connectionshapes_get_id
export def "slides-connectionshapes-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ConnectionShapes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Documents: Upload
#
# POST /Documents
# Returns: table<baseElementBlobUrl: string, blobLocation: string, changedBaseElementBlobUrl: string, documentTypeId: int, filename: string, id: string, name: string, ownerGuid: string, packageUri: string, storyId: string, tableStylesXmlBlobUrl: string, title: string>
# operationId: documents_post
export def "documents-post" [
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
  file: string # The file to upload. Must be of type .pptx, ppt (format: binary)
  story_id: string # The story_id of the document being uploaded. (format: uuid)
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Documents"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}, {name: storyId, var: story_id}], files: [file]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    file: $file, story_id: $story_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DocumentsController: Get Dependent Objects Tree
#
# GET /Documents/ChildObjects/{id}
# Returns: table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string>
# operationId: documents_childobjects_get_id
export def "documents-childobjects-get-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Documents/ChildObjects/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Documents: Clone an existing Ooxml Document to new Parent Story
#
# POST /Documents/Clone/{id}
# Returns: record<baseElementBlobUrl: string, blobLocation: string, changedBaseElementBlobUrl: string, documentTypeId: int, filename: string, id: string, name: string, ownerGuid: string, packageUri: string, storyId: string, tableStylesXmlBlobUrl: string, title: string>
# operationId: documents_clone_post_id
export def "documents-clone-post-id" [
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
  --accept: string@accept-completer # Response content type
  --body-id: string # format: uuid (spec name: id)
  --story-id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Documents/Clone/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: body_id}, {name: storyId, var: story_id}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body_id: $body_id, story_id: $story_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DocumentType: List All Possible Types
#
# GET /Documents/DocumentType
# Returns: table<description: string, fileExtension: string, id: string, mimeType: string, name: string, ooxmlPackageType: string, typeId: int>
# operationId: documents_documenttype_get
export def "documents-documenttype-get" [
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
    path: "/Documents/DocumentType"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DocumentType: Get By Type Id
#
# GET /Documents/DocumentType/TypeId/{type_id}
# Returns: record<description: string, fileExtension: string, id: string, mimeType: string, name: string, ooxmlPackageType: string, typeId: int>
# operationId: documents_documenttype_typeid_get_type_id
export def "documents-documenttype-typeid-get-type-id" [
  type_id: int
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
    path: "/Documents/DocumentType/TypeId/{type_id}"
    path_params: [{name: type_id, var: type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type_id: $type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DocumentType: Get by Id
#
# GET /Documents/DocumentType/{id}
# Returns: record<description: string, fileExtension: string, id: string, mimeType: string, name: string, ooxmlPackageType: string, typeId: int>
# operationId: documents_documenttype_get_id
export def "documents-documenttype-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Documents/DocumentType/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Documents: Download
#
# GET /Documents/Download/{id}
# Returns: binary
# operationId: documents_download_get_id_orginal
export def "documents-download-get-id-orginal" [
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
  --orginal: oneof<nothing, bool> # default: false
]: nothing -> any {
  http-request {
    method: get
    path: "/Documents/Download/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: orginal, var: orginal}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id, orginal: $orginal
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Documents: Delete by Id
#
# DELETE /Documents/{id}
# operationId: documents_delete_id
export def "documents-delete-id" [
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
    path: "/Documents/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Documents: Get by Id
#
# GET /Documents/{id}
# Returns: record<baseElementBlobUrl: string, blobLocation: string, changedBaseElementBlobUrl: string, documentTypeId: int, filename: string, id: string, name: string, ownerGuid: string, packageUri: string, storyId: string, tableStylesXmlBlobUrl: string, title: string>
# operationId: documents_get_id
export def "documents-get-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Documents/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Slides: Get Dependent Objects Tree
#
# GET /Groups/ChildObjects/{id}
# Returns: table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string>
# operationId: slides_groups_childobjects_get_id
export def "slides-groups-childobjects-get-id" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Groups/ChildObjects/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Slides: Get Details
#
# GET /Groups/Details/{id}
# Returns: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, groupElement: record<childGroupElements: list<any>, connector: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, endConnectionIdx: int, endConnectionShape: record, endConnectionShapeId: string, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: any, groupElementsId: string, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, startConnectionIdx: int, startConnectionShape: record, startConnectionShapeId: string, svgBlobUrl: string, userCreated: string, userModified: string>, dateCreated: string, dateModified: string, graphic: record<chart: record, dateCreated: string, dateModified: string, graphicTypeId: int, groupElement: any, groupElementsId: string, height: int, id: string, name: string, ooxmlId: int, picture: record, smartArt: record, table: record, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, group: any, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: any, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, textContainer: record, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, shapeTree: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, groupElement: any, groupElementId: string, groupElements: list, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, slide: record, slideId: string, svgBlobUrl: string, title: string, userCreated: string, userModified: string>, shapeTreeId: string, typeInfo: record<dateCreated: string, dateModified: string, description: string, id: string, name: string, typeId: int, userCreated: string, userModified: string>, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementId: string, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, svgBlobUrl: string, title: string, userCreated: string, userModified: string>
# operationId: slides_groups_details_get_id
export def "slides-groups-details-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Groups/Details/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Slides: Get Underlying Xml
#
# GET /Groups/OpenOfficeXml/{id}
# Returns: record<id: string, openOfficeXml: string, type: string>
# operationId: slides_groups_openofficexml_get_id_updated
export def "slides-groups-openofficexml-get-id-updated" [
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
  --updated: oneof<nothing, bool> # Indicates whether API should return the orginal uploaded xml (false) or the actively updated version (true, default) (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Groups/OpenOfficeXml/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: updated, var: updated}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, updated: $updated
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Slides: Modify Underlying Xml
#
# PUT /Groups/OpenOfficeXml/{id}
# operationId: slides_groups_openofficexml_put_id
export def "slides-groups-openofficexml-put-id" [
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
  --body-id: string # nullable, format: uuid (spec name: id)
  --open-office-xml: string # nullable
  --type: string # nullable
]: any -> any {
  $in | http-request {
    method: put
    path: "/Groups/OpenOfficeXml/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: body_id}, {name: openOfficeXml, var: open_office_xml}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body_id: $body_id, open_office_xml: $open_office_xml, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Slides: Get Svg file
#
# GET /Groups/Svg/{id}
# operationId: slides_groups_svg_get_id_use_cache
export def "slides-groups-svg-get-id-use-cache" [
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
  --use-cache: oneof<nothing, bool> # Indicates whether API should retrieve content from a cache if aviable (true, default), or force an update (false) (default: false)
]: nothing -> any {
  http-request {
    method: get
    path: "/Groups/Svg/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: use_cache, var: use_cache}]
    accept: ["image/svg+xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, use_cache: $use_cache
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Groups: Get by Id
#
# GET /Groups/{id}
# Returns: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, groupElementId: string, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, svgBlobUrl: string, title: string>
# operationId: slides_groups_get_id
export def "slides-groups-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Groups/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Shared: Get Dependent Objects Tree
#
# GET /Images/ChildObjects/{id}
# Returns: table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string>
# operationId: shared_images_childobjects_get_id
export def "shared-images-childobjects-get-id" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Images/ChildObjects/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Shared: Get Details
#
# GET /Images/Details/{id}
# Returns: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, fileExtension: string, graphicsId: string, id: string, imageFileBlobUrl: string, imageFill: record<compressionState: string, dateCreated: string, dateModified: string, dpi: int, effectsJson: string, fillMap: record<connector: record, connectorId: string, dateCreated: string, dateModified: string, effectAttribute: record, effectAttributeId: string, fillTypeId: int, gradientFill: record, id: string, imageFill: any, shape: record, shapeId: string, solidFill: record, tableCell: record, tableCellId: string, themeBackgroundFill: record, themeBackgroundFillId: string, themeFill: record, themeFillId: string, userCreated: string, userModified: string>, fillMapId: string, id: string, picture: any, rotateWithShape: bool, sourceRectangle: string, stretch: bool, tile: string, userCreated: string, userModified: string>, imageFillsId: string, name: string, packageUri: string, parentGraphic: record<chart: record<axes: list, baseElementBlobUrl: string, changedBaseElementBlobUrl: string, chartData: record, dateCreated: string, dateModified: string, id: string, name: string, packageUri: string, parentGraphic: any, parentGraphicId: string, svgBlobUrl: string, titleTextContainer: record, userCreated: string, userModified: string>, dateCreated: string, dateModified: string, graphicTypeId: int, groupElement: record<childGroupElements: list, connector: record, dateCreated: string, dateModified: string, graphic: any, group: record, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: record, shapeTree: record, shapeTreeId: string, typeInfo: record, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementsId: string, height: int, id: string, name: string, ooxmlId: int, picture: any, smartArt: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, graphicsId: string, id: string, name: string, packageUri: string, parentGraphic: any, svgBlobUrl: string, userCreated: string, userModified: string>, table: record<baseElementBlobUrl: string, cells: list, changedBaseElementBlobUrl: string, columns: list, dateCreated: string, dateModified: string, hasStylePart: bool, id: string, name: string, packageUri: string, parentGraphic: any, parentGraphicId: string, rows: list, stylePartOuterXml: string, svgBlobUrl: string, userCreated: string, userModified: string>, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, userCreated: string, userModified: string>
# operationId: shared_images_details_get_id
export def "shared-images-details-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Images/Details/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Image: Download Image
#
# PUT /Images/GetImage/{Id}
# operationId: shared_images_getimage_put_id
export def "shared-images-getimage-put-id" [
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
    path: "/Images/GetImage/{Id}"
    path_params: [{name: Id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Shared: Get Underlying Xml
#
# GET /Images/OpenOfficeXml/{id}
# Returns: record<id: string, openOfficeXml: string, type: string>
# operationId: shared_images_openofficexml_get_id_updated
export def "shared-images-openofficexml-get-id-updated" [
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
  --updated: oneof<nothing, bool> # Indicates whether API should return the orginal uploaded xml (false) or the actively updated version (true, default) (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Images/OpenOfficeXml/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: updated, var: updated}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, updated: $updated
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Shared: Modify Underlying Xml
#
# PUT /Images/OpenOfficeXml/{id}
# operationId: shared_images_openofficexml_put_id
export def "shared-images-openofficexml-put-id" [
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
  --body-id: string # nullable, format: uuid (spec name: id)
  --open-office-xml: string # nullable
  --type: string # nullable
]: any -> any {
  $in | http-request {
    method: put
    path: "/Images/OpenOfficeXml/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: body_id}, {name: openOfficeXml, var: open_office_xml}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body_id: $body_id, open_office_xml: $open_office_xml, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Shared: Get Svg file
#
# GET /Images/Svg/{id}
# operationId: shared_images_svg_get_id_use_cache
export def "shared-images-svg-get-id-use-cache" [
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
  --use-cache: oneof<nothing, bool> # Indicates whether API should retrieve content from a cache if aviable (true, default), or force an update (false) (default: false)
]: nothing -> any {
  http-request {
    method: get
    path: "/Images/Svg/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: use_cache, var: use_cache}]
    accept: ["image/svg+xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, use_cache: $use_cache
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Images: Get by Id
#
# GET /Images/{id}
# Returns: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, fileExtension: string, graphicsId: string, id: string, imageFileBlobUrl: string, imageFillsId: string, name: string, packageUri: string>
# operationId: shared_images_get_id
export def "shared-images-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Images/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Slides: Get Dependent Objects Tree
#
# GET /ShapeTrees/ChildObjects/{id}
# Returns: table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string>
# operationId: slides_shapetrees_childobjects_get_id
export def "slides-shapetrees-childobjects-get-id" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/ShapeTrees/ChildObjects/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Slides: Get Details
#
# GET /ShapeTrees/Details/{id}
# Returns: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, groupElement: record<childGroupElements: list<any>, connector: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, endConnectionIdx: int, endConnectionShape: record, endConnectionShapeId: string, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: any, groupElementsId: string, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, startConnectionIdx: int, startConnectionShape: record, startConnectionShapeId: string, svgBlobUrl: string, userCreated: string, userModified: string>, dateCreated: string, dateModified: string, graphic: record<chart: record, dateCreated: string, dateModified: string, graphicTypeId: int, groupElement: any, groupElementsId: string, height: int, id: string, name: string, ooxmlId: int, picture: record, smartArt: record, table: record, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, group: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, groupElement: any, groupElementId: string, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, svgBlobUrl: string, title: string, userCreated: string, userModified: string>, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: any, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, textContainer: record, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, shapeTree: any, shapeTreeId: string, typeInfo: record<dateCreated: string, dateModified: string, description: string, id: string, name: string, typeId: int, userCreated: string, userModified: string>, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementId: string, groupElements: table<childGroupElements: list, connector: record, dateCreated: string, dateModified: string, graphic: record, group: record, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: record, shapeTree: any, shapeTreeId: string, typeInfo: record, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, slide: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, document: record<baseElementBlobUrl: string, blobLocation: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, documentTypeId: int, filename: string, id: string, name: string, ownerGuid: string, packageUri: string, slides: list, storyId: string, tableStylesXmlBlobUrl: string, title: string, userCreated: string, userModified: string>, documentId: string, id: string, name: string, number: int, ooxmlId: int, packageUri: string, shapeTree: any, slideDocumentUrl: string, slideMaster: record<colorMap: record, dateCreated: string, dateModified: string, id: string, parentSlide: any, slideId: string, userCreated: string, userModified: string>, svgBlobUrl: string, theme: record<backgroundFills: list, baseElementBlobUrl: string, changedBaseElementBlobUrl: string, colors: record, customColors: list, dateCreated: string, dateModified: string, effectMaps: list, fills: list, fonts: record, id: string, lineMaps: list, name: string, packageUri: string, slide: any, slideId: string, userCreated: string, userModified: string>, userCreated: string, userModified: string>, slideId: string, svgBlobUrl: string, title: string, userCreated: string, userModified: string>
# operationId: slides_shapetrees_details_get_id
export def "slides-shapetrees-details-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ShapeTrees/Details/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Slides: Get Underlying Xml
#
# GET /ShapeTrees/OpenOfficeXml/{id}
# Returns: record<id: string, openOfficeXml: string, type: string>
# operationId: slides_shapetrees_openofficexml_get_id_updated
export def "slides-shapetrees-openofficexml-get-id-updated" [
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
  --updated: oneof<nothing, bool> # Indicates whether API should return the orginal uploaded xml (false) or the actively updated version (true, default) (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ShapeTrees/OpenOfficeXml/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: updated, var: updated}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, updated: $updated
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Slides: Modify Underlying Xml
#
# PUT /ShapeTrees/OpenOfficeXml/{id}
# operationId: slides_shapetrees_openofficexml_put_id
export def "slides-shapetrees-openofficexml-put-id" [
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
  --body-id: string # nullable, format: uuid (spec name: id)
  --open-office-xml: string # nullable
  --type: string # nullable
]: any -> any {
  $in | http-request {
    method: put
    path: "/ShapeTrees/OpenOfficeXml/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: body_id}, {name: openOfficeXml, var: open_office_xml}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body_id: $body_id, open_office_xml: $open_office_xml, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Slides: Get Svg file
#
# GET /ShapeTrees/Svg/{id}
# operationId: slides_shapetrees_svg_get_id_use_cache
export def "slides-shapetrees-svg-get-id-use-cache" [
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
  --use-cache: oneof<nothing, bool> # Indicates whether API should retrieve content from a cache if aviable (true, default), or force an update (false) (default: false)
]: nothing -> any {
  http-request {
    method: get
    path: "/ShapeTrees/Svg/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: use_cache, var: use_cache}]
    accept: ["image/svg+xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, use_cache: $use_cache
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ShapeTrees: Get by Id
#
# GET /ShapeTrees/{id}
# Returns: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, groupElementId: string, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, slideId: string, svgBlobUrl: string, title: string>
# operationId: slides_shapetrees_get_id
export def "slides-shapetrees-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ShapeTrees/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Slides: Get Dependent Objects Tree
#
# GET /Shapes/ChildObjects/{id}
# Returns: table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string>
# operationId: slides_shapes_childobjects_get_id
export def "slides-shapes-childobjects-get-id" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Shapes/ChildObjects/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Slides: Get Details
#
# GET /Shapes/Details/{id}
# Returns: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record<connectorId: string, dateCreated: string, dateModified: string, effectAttributes: list<record>, effectMap: record<dateCreated: string, dateModified: string, effect: any, id: string, intensityId: int, theme: record, themeId: string, userCreated: string, userModified: string>, effectMapId: string, id: string, name: string, parentConnector: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: any, endConnectionIdx: int, endConnectionShape: any, endConnectionShapeId: string, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record, groupElementsId: string, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, startConnectionIdx: int, startConnectionShape: any, startConnectionShapeId: string, svgBlobUrl: string, userCreated: string, userModified: string>, parentShape: any, shapeId: string, userCreated: string, userModified: string>, fillMap: record<connector: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, endConnectionIdx: int, endConnectionShape: any, endConnectionShapeId: string, fillMap: any, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record, groupElementsId: string, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, startConnectionIdx: int, startConnectionShape: any, startConnectionShapeId: string, svgBlobUrl: string, userCreated: string, userModified: string>, connectorId: string, dateCreated: string, dateModified: string, effectAttribute: record<attributesJson: string, dateCreated: string, dateModified: string, effect: record, effectId: string, effectTypeId: int, fillMap: any, id: string, userCreated: string, userModified: string>, effectAttributeId: string, fillTypeId: int, gradientFill: record<angle: int, dateCreated: string, dateModified: string, fillMap: any, fillMapId: string, gradientStops: list, id: string, isPath: bool, pathType: string, rotateWithShape: bool, userCreated: string, userModified: string>, id: string, imageFill: record<compressionState: string, dateCreated: string, dateModified: string, dpi: int, effectsJson: string, fillMap: any, fillMapId: string, id: string, picture: record, rotateWithShape: bool, sourceRectangle: string, stretch: bool, tile: string, userCreated: string, userModified: string>, shape: any, shapeId: string, solidFill: record<colorTransformations: record, colorTypeId: int, dateCreated: string, dateModified: string, fillMapId: string, hexValue: string, id: string, isUserColor: bool, parentFillMap: any, parentGradientStop: record, parentGradientStopId: string, parentLine: record, parentLineId: string, parentText: record, parentTextId: string, userCreated: string, userModified: string>, tableCell: record<border: record, column: record, columnId: string, columnSpan: int, dateCreated: string, dateModified: string, fillMap: any, id: string, isMergedHorozontal: bool, isMergedVertical: bool, row: record, rowId: string, rowSpan: int, textContainer: record, userCreated: string, userModified: string>, tableCellId: string, themeBackgroundFill: record<dateCreated: string, dateModified: string, fillMap: any, id: string, intensityId: int, theme: record, themeId: string, userCreated: string, userModified: string>, themeBackgroundFillId: string, themeFill: record<dateCreated: string, dateModified: string, fillMap: any, id: string, intensityId: int, theme: record, themeId: string, userCreated: string, userModified: string>, themeFillId: string, userCreated: string, userModified: string>, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record<childGroupElements: list<any>, connector: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, endConnectionIdx: int, endConnectionShape: any, endConnectionShapeId: string, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: any, groupElementsId: string, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, startConnectionIdx: int, startConnectionShape: any, startConnectionShapeId: string, svgBlobUrl: string, userCreated: string, userModified: string>, dateCreated: string, dateModified: string, graphic: record<chart: record, dateCreated: string, dateModified: string, graphicTypeId: int, groupElement: any, groupElementsId: string, height: int, id: string, name: string, ooxmlId: int, picture: record, smartArt: record, table: record, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, group: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, groupElement: any, groupElementId: string, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, svgBlobUrl: string, title: string, userCreated: string, userModified: string>, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: any, shapeTree: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, groupElement: any, groupElementId: string, groupElements: list, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, slide: record, slideId: string, svgBlobUrl: string, title: string, userCreated: string, userModified: string>, shapeTreeId: string, typeInfo: record<dateCreated: string, dateModified: string, description: string, id: string, name: string, typeId: int, userCreated: string, userModified: string>, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: record<bLtoTRBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, bLtoTRBorderId: string, bottomBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, bottomBorderId: string, connectorId: string, dashTypeId: int, dateCreated: string, dateModified: string, headEndHeightId: int, headEndTypeId: int, headEndWidthId: int, id: string, leftBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, leftBorderId: string, lineColorSolidFill: record<colorTransformations: record, colorTypeId: int, dateCreated: string, dateModified: string, fillMapId: string, hexValue: string, id: string, isUserColor: bool, parentFillMap: record, parentGradientStop: record, parentGradientStopId: string, parentLine: any, parentLineId: string, parentText: record, parentTextId: string, userCreated: string, userModified: string>, lineMap: record<dateCreated: string, dateModified: string, id: string, intensityId: int, line: any, theme: record, themeId: string, userCreated: string, userModified: string>, lineMapId: string, parentConnector: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, effect: record, endConnectionIdx: int, endConnectionShape: any, endConnectionShapeId: string, fillMap: record, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElement: record, groupElementsId: string, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, line: any, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, startConnectionIdx: int, startConnectionShape: any, startConnectionShapeId: string, svgBlobUrl: string, userCreated: string, userModified: string>, parentShape: any, rightBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, rightBorderId: string, shapeId: string, tLtoBRBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, tLtoBRBorderId: string, tailEndHeightId: int, tailEndTypeId: int, tailEndWidthId: int, topBorder: record<bLtoTR: any, bottom: any, cell: record, cellId: string, dateCreated: string, dateModified: string, id: string, left: any, right: any, tLtoBR: any, top: any, userCreated: string, userModified: string>, topBorderId: string, userCreated: string, userModified: string, weight: int>, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, textContainer: record<axis: record<axisDataTypeId: int, chart: record, chartsId: string, dateCreated: string, dateModified: string, id: string, ooxmlId: int, titleTextContainer: any, userCreated: string, userModified: string>, axisId: string, chart: record<axes: list, baseElementBlobUrl: string, changedBaseElementBlobUrl: string, chartData: record, dateCreated: string, dateModified: string, id: string, name: string, packageUri: string, parentGraphic: record, parentGraphicId: string, svgBlobUrl: string, titleTextContainer: any, userCreated: string, userModified: string>, chartId: string, dateCreated: string, dateModified: string, id: string, outerXml: string, paragraphs: list<record>, parentShape: any, shapeId: string, tableCell: record<border: record, column: record, columnId: string, columnSpan: int, dateCreated: string, dateModified: string, fillMap: record, id: string, isMergedHorozontal: bool, isMergedVertical: bool, row: record, rowId: string, rowSpan: int, textContainer: any, userCreated: string, userModified: string>, tableCellId: string, userCreated: string, userModified: string>, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>
# operationId: slides_shapes_details_get_id
export def "slides-shapes-details-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Shapes/Details/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Slides: Get Underlying Xml
#
# GET /Shapes/OpenOfficeXml/{id}
# Returns: record<id: string, openOfficeXml: string, type: string>
# operationId: slides_shapes_openofficexml_get_id_updated
export def "slides-shapes-openofficexml-get-id-updated" [
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
  --updated: oneof<nothing, bool> # Indicates whether API should return the orginal uploaded xml (false) or the actively updated version (true, default) (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Shapes/OpenOfficeXml/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: updated, var: updated}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, updated: $updated
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Slides: Modify Underlying Xml
#
# PUT /Shapes/OpenOfficeXml/{id}
# operationId: slides_shapes_openofficexml_put_id
export def "slides-shapes-openofficexml-put-id" [
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
  --body-id: string # nullable, format: uuid (spec name: id)
  --open-office-xml: string # nullable
  --type: string # nullable
]: any -> any {
  $in | http-request {
    method: put
    path: "/Shapes/OpenOfficeXml/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: body_id}, {name: openOfficeXml, var: open_office_xml}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body_id: $body_id, open_office_xml: $open_office_xml, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Slides: Get Svg file
#
# GET /Shapes/Svg/{id}
# operationId: slides_shapes_svg_get_id_use_cache
export def "slides-shapes-svg-get-id-use-cache" [
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
  --use-cache: oneof<nothing, bool> # Indicates whether API should retrieve content from a cache if aviable (true, default), or force an update (false) (default: false)
]: nothing -> any {
  http-request {
    method: get
    path: "/Shapes/Svg/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: use_cache, var: use_cache}]
    accept: ["image/svg+xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, use_cache: $use_cache
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Shapes: Get by Id
#
# GET /Shapes/{id}
# Returns: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, flipHorizontal: bool, flipVertical: bool, freeFormPathXml: string, groupElementsId: string, height: int, hidden: bool, id: string, isThemeEffect: bool, isThemeFill: bool, isThemeLine: bool, name: string, ooxmlId: int, packageUri: string, presetTypeId: string, rotation: int, svgBlobUrl: string, width: int, xOffset: int, yOffset: int>
# operationId: slides_shapes_get_id
export def "slides-shapes-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Shapes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ColorTransformationAttributes: Get by Id
#
# GET /Shared/ColorTransformationAttributes/{id}
# Returns: record<colorTransformationsId: string, id: string, name: string, value: string>
# operationId: shared_colortransformationattributes_get_id
export def "shared-colortransformationattributes-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Shared/ColorTransformationAttributes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ColorTransformations: Get by Id
#
# GET /Shared/ColorTransformations/{id}
# Returns: record<id: string, name: string, solidFillsId: string>
# operationId: shared_colortransformations_get_id
export def "shared-colortransformations-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Shared/ColorTransformations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ColorTypes: List All Possible Types
#
# GET /Shared/ColorTypes
# Returns: table<colorSchemeIndexValueEnum: int, description: string, id: string, name: string, typeId: int>
# operationId: shared_colortypes_get
export def "shared-colortypes-get" [
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
    path: "/Shared/ColorTypes"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ColorTypes: Get By Type Id
#
# GET /Shared/ColorTypes/TypeId/{type_id}
# Returns: record<colorSchemeIndexValueEnum: int, description: string, id: string, name: string, typeId: int>
# operationId: shared_colortypes_typeid_get_type_id
export def "shared-colortypes-typeid-get-type-id" [
  type_id: int
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
    path: "/Shared/ColorTypes/TypeId/{type_id}"
    path_params: [{name: type_id, var: type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type_id: $type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ColorTypes: Get by Id
#
# GET /Shared/ColorTypes/{id}
# Returns: record<colorSchemeIndexValueEnum: int, description: string, id: string, name: string, typeId: int>
# operationId: shared_colortypes_get_id
export def "shared-colortypes-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Shared/ColorTypes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DashTypes: List All Possible Types
#
# GET /Shared/DashTypes
# Returns: table<description: string, id: string, name: string, serializedAs: string, typeId: int>
# operationId: shared_dashtypes_get
export def "shared-dashtypes-get" [
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
    path: "/Shared/DashTypes"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DashTypes: Get By Type Id
#
# GET /Shared/DashTypes/TypeId/{type_id}
# Returns: record<description: string, id: string, name: string, serializedAs: string, typeId: int>
# operationId: shared_dashtypes_typeid_get_type_id
export def "shared-dashtypes-typeid-get-type-id" [
  type_id: int
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
    path: "/Shared/DashTypes/TypeId/{type_id}"
    path_params: [{name: type_id, var: type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type_id: $type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DashTypes: Get by Id
#
# GET /Shared/DashTypes/{id}
# Returns: record<description: string, id: string, name: string, serializedAs: string, typeId: int>
# operationId: shared_dashtypes_get_id
export def "shared-dashtypes-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Shared/DashTypes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# EffectAttributes: Get by Id
#
# GET /Shared/EffectAttributes/{id}
# Returns: record<attributesJson: string, effectId: string, effectTypeId: int, id: string>
# operationId: shared_effectattributes_get_id
export def "shared-effectattributes-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Shared/EffectAttributes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# EffectTypes: List All Possible Types
#
# GET /Shared/EffectTypes
# Returns: table<description: string, id: string, name: string, typeId: int>
# operationId: shared_effecttypes_get
export def "shared-effecttypes-get" [
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
    path: "/Shared/EffectTypes"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# EffectTypes: Get By Type Id
#
# GET /Shared/EffectTypes/TypeId/{type_id}
# Returns: record<description: string, id: string, name: string, typeId: int>
# operationId: shared_effecttypes_typeid_get_type_id
export def "shared-effecttypes-typeid-get-type-id" [
  type_id: int
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
    path: "/Shared/EffectTypes/TypeId/{type_id}"
    path_params: [{name: type_id, var: type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type_id: $type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# EffectTypes: Get by Id
#
# GET /Shared/EffectTypes/{id}
# Returns: record<description: string, id: string, name: string, typeId: int>
# operationId: shared_effecttypes_get_id
export def "shared-effecttypes-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Shared/EffectTypes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Effects: Get by Id
#
# GET /Shared/Effects/{id}
# Returns: record<connectorId: string, effectMapId: string, id: string, name: string, shapeId: string>
# operationId: shared_effects_get_id
export def "shared-effects-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Shared/Effects/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# FillMap: Get by Id
#
# GET /Shared/FillMap/{id}
# Returns: record<connectorId: string, effectAttributeId: string, fillTypeId: int, id: string, shapeId: string, tableCellId: string, themeBackgroundFillId: string, themeFillId: string>
# operationId: shared_fillmap_get_id
export def "shared-fillmap-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Shared/FillMap/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# FillTypes: List All Possible Types
#
# GET /Shared/FillTypes
# Returns: table<description: string, id: string, name: string, typeId: int>
# operationId: shared_filltypes_get
export def "shared-filltypes-get" [
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
    path: "/Shared/FillTypes"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# FillTypes: Get By Type Id
#
# GET /Shared/FillTypes/TypeId/{type_id}
# Returns: record<description: string, id: string, name: string, typeId: int>
# operationId: shared_filltypes_typeid_get_type_id
export def "shared-filltypes-typeid-get-type-id" [
  type_id: int
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
    path: "/Shared/FillTypes/TypeId/{type_id}"
    path_params: [{name: type_id, var: type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type_id: $type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# FillTypes: Get by Id
#
# GET /Shared/FillTypes/{id}
# Returns: record<description: string, id: string, name: string, typeId: int>
# operationId: shared_filltypes_get_id
export def "shared-filltypes-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Shared/FillTypes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GradientFills: Get by Id
#
# GET /Shared/GradientFills/{id}
# Returns: record<angle: int, fillMapId: string, id: string, isPath: bool, pathType: string, rotateWithShape: bool>
# operationId: shared_gradientfills_get_id
export def "shared-gradientfills-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Shared/GradientFills/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GradientStops: Get by Id
#
# GET /Shared/GradientStops/{id}
# Returns: record<gradientFillsId: string, id: string, position: int>
# operationId: shared_gradientstops_get_id
export def "shared-gradientstops-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Shared/GradientStops/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ImageFills: Get by Id
#
# GET /Shared/ImageFills/{id}
# Returns: record<compressionState: string, dpi: int, effectsJson: string, fillMapId: string, id: string, rotateWithShape: bool, sourceRectangle: string, stretch: bool, tile: string>
# operationId: shared_imagefills_get_id
export def "shared-imagefills-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Shared/ImageFills/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# LineEndSizes: List All Possible Types
#
# GET /Shared/LineEndSizes
# Returns: table<description: string, id: string, name: string, serializedAs: string, typeId: int>
# operationId: shared_lineendsizes_get
export def "shared-lineendsizes-get" [
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
    path: "/Shared/LineEndSizes"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# LineEndSizes: Get By Type Id
#
# GET /Shared/LineEndSizes/TypeId/{type_id}
# Returns: record<description: string, id: string, name: string, serializedAs: string, typeId: int>
# operationId: shared_lineendsizes_typeid_get_type_id
export def "shared-lineendsizes-typeid-get-type-id" [
  type_id: int
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
    path: "/Shared/LineEndSizes/TypeId/{type_id}"
    path_params: [{name: type_id, var: type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type_id: $type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# LineEndSizes: Get by Id
#
# GET /Shared/LineEndSizes/{id}
# Returns: record<description: string, id: string, name: string, serializedAs: string, typeId: int>
# operationId: shared_lineendsizes_get_id
export def "shared-lineendsizes-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Shared/LineEndSizes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# LineEndTypes: List All Possible Types
#
# GET /Shared/LineEndTypes
# Returns: table<description: string, id: string, name: string, serializedAs: string, typeId: int>
# operationId: shared_lineendtypes_get
export def "shared-lineendtypes-get" [
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
    path: "/Shared/LineEndTypes"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# LineEndTypes: Get By Type Id
#
# GET /Shared/LineEndTypes/TypeId/{type_id}
# Returns: record<description: string, id: string, name: string, serializedAs: string, typeId: int>
# operationId: shared_lineendtypes_typeid_get_type_id
export def "shared-lineendtypes-typeid-get-type-id" [
  type_id: int
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
    path: "/Shared/LineEndTypes/TypeId/{type_id}"
    path_params: [{name: type_id, var: type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type_id: $type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# LineEndTypes: Get by Id
#
# GET /Shared/LineEndTypes/{id}
# Returns: record<description: string, id: string, name: string, serializedAs: string, typeId: int>
# operationId: shared_lineendtypes_get_id
export def "shared-lineendtypes-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Shared/LineEndTypes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lines: Get by Id
#
# GET /Shared/Lines/{id}
# Returns: record<bLtoTRBorderId: string, bottomBorderId: string, connectorId: string, dashTypeId: int, headEndHeightId: int, headEndTypeId: int, headEndWidthId: int, id: string, leftBorderId: string, lineMapId: string, rightBorderId: string, shapeId: string, tLtoBRBorderId: string, tailEndHeightId: int, tailEndTypeId: int, tailEndWidthId: int, topBorderId: string, weight: int>
# operationId: shared_lines_get_id
export def "shared-lines-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Shared/Lines/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Paragraph: Get by Id
#
# GET /Shared/Paragraph/{id}
# Returns: record<id: string, number: int, textContainerId: string>
# operationId: shared_paragraph_get_id
export def "shared-paragraph-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Shared/Paragraph/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SolidFills: Get by Id
#
# GET /Shared/SolidFills/{id}
# Returns: record<colorTypeId: int, fillMapId: string, hexValue: string, id: string, isUserColor: bool, parentGradientStopId: string, parentLineId: string, parentTextId: string>
# operationId: shared_solidfills_get_id
export def "shared-solidfills-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Shared/SolidFills/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Text: Get by Id
#
# GET /Shared/Text/{id}
# Returns: record<colorSolidFillsId: string, font: string, fontSize: int, id: string, isBold: bool, isItalic: bool, isThemeFont: bool, isUnderline: bool, paragraphId: string, rawText: string, sequence: int>
# operationId: shared_text_get_id
export def "shared-text-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Shared/Text/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# TextContainer: Get by Id
#
# GET /Shared/TextContainer/{id}
# Returns: record<axisId: string, chartId: string, id: string, outerXml: string, shapeId: string, tableCellId: string>
# operationId: shared_textcontainer_get_id
export def "shared-textcontainer-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Shared/TextContainer/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Slides: Get Dependent Objects Tree
#
# GET /Slides/ChildObjects/{id}
# Returns: table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string>
# operationId: slides_slides_childobjects_get_id
export def "slides-slides-childobjects-get-id" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Slides/ChildObjects/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ColorMaps: Get by Id
#
# GET /Slides/ColorMaps/{id}
# Returns: record<accent1: int, accent2: int, accent3: int, accent4: int, accent5: int, accent6: int, background1: int, background2: int, followedHyperlink: int, hyperlink: int, id: string, slideMasterId: string, text1: int, text2: int>
# operationId: slides_colormaps_get_id
export def "slides-colormaps-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Slides/ColorMaps/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Slides: Get Details
#
# GET /Slides/Details/{id}
# Returns: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, document: record<baseElementBlobUrl: string, blobLocation: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, documentTypeId: int, filename: string, id: string, name: string, ownerGuid: string, packageUri: string, slides: list<any>, storyId: string, tableStylesXmlBlobUrl: string, title: string, userCreated: string, userModified: string>, documentId: string, id: string, name: string, number: int, ooxmlId: int, packageUri: string, shapeTree: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, groupElement: record<childGroupElements: list, connector: record, dateCreated: string, dateModified: string, graphic: record, group: record, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: record, shapeTree: any, shapeTreeId: string, typeInfo: record, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementId: string, groupElements: list<record>, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, slide: any, slideId: string, svgBlobUrl: string, title: string, userCreated: string, userModified: string>, slideDocumentUrl: string, slideMaster: record<colorMap: record<accent1: int, accent2: int, accent3: int, accent4: int, accent5: int, accent6: int, background1: int, background2: int, dateCreated: string, dateModified: string, followedHyperlink: int, hyperlink: int, id: string, slideMaster: any, slideMasterId: string, text1: int, text2: int, userCreated: string, userModified: string>, dateCreated: string, dateModified: string, id: string, parentSlide: any, slideId: string, userCreated: string, userModified: string>, svgBlobUrl: string, theme: record<backgroundFills: list<record>, baseElementBlobUrl: string, changedBaseElementBlobUrl: string, colors: record<accent1: string, accent2: string, accent3: string, accent4: string, accent5: string, accent6: string, dark1: string, dark2: string, dateCreated: string, dateModified: string, followedHyperlink: string, hyperlink: string, id: string, light1: string, light2: string, name: string, theme: any, themeId: string, userCreated: string, userModified: string>, customColors: list<record>, dateCreated: string, dateModified: string, effectMaps: list<record>, fills: list<record>, fonts: record<bodyFont: string, dateCreated: string, dateModified: string, headingFont: string, id: string, theme: any, themeId: string, userCreated: string, userModified: string>, id: string, lineMaps: list<record>, name: string, packageUri: string, slide: any, slideId: string, userCreated: string, userModified: string>, userCreated: string, userModified: string>
# operationId: slides_slides_details_get_id
export def "slides-slides-details-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Slides/Details/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GraphicTypes: List All Possible Types
#
# GET /Slides/GraphicTypes
# Returns: table<description: string, id: string, name: string, typeId: int>
# operationId: slides_graphictypes_get
export def "slides-graphictypes-get" [
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
    path: "/Slides/GraphicTypes"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GraphicTypes: Get By Type Id
#
# GET /Slides/GraphicTypes/TypeId/{type_id}
# Returns: record<description: string, id: string, name: string, typeId: int>
# operationId: slides_graphictypes_typeid_get_type_id
export def "slides-graphictypes-typeid-get-type-id" [
  type_id: int
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
    path: "/Slides/GraphicTypes/TypeId/{type_id}"
    path_params: [{name: type_id, var: type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type_id: $type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GraphicTypes: Get by Id
#
# GET /Slides/GraphicTypes/{id}
# Returns: record<description: string, id: string, name: string, typeId: int>
# operationId: slides_graphictypes_get_id
export def "slides-graphictypes-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Slides/GraphicTypes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Graphics: Get by Id
#
# GET /Slides/Graphics/{id}
# Returns: record<graphicTypeId: int, groupElementsId: string, height: int, id: string, name: string, ooxmlId: int, width: int, xOffset: int, yOffset: int>
# operationId: slides_graphics_get_id
export def "slides-graphics-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Slides/Graphics/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GroupElementTypes: List All Possible Types
#
# GET /Slides/GroupElementTypes
# Returns: table<description: string, id: string, name: string, typeId: int>
# operationId: slides_groupelementtypes_get
export def "slides-groupelementtypes-get" [
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
    path: "/Slides/GroupElementTypes"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GroupElementTypes: Get By Type Id
#
# GET /Slides/GroupElementTypes/TypeId/{type_id}
# Returns: record<description: string, id: string, name: string, typeId: int>
# operationId: slides_groupelementtypes_typeid_get_type_id
export def "slides-groupelementtypes-typeid-get-type-id" [
  type_id: int
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
    path: "/Slides/GroupElementTypes/TypeId/{type_id}"
    path_params: [{name: type_id, var: type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type_id: $type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GroupElementTypes: Get by Id
#
# GET /Slides/GroupElementTypes/{id}
# Returns: record<description: string, id: string, name: string, typeId: int>
# operationId: slides_groupelementtypes_get_id
export def "slides-groupelementtypes-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Slides/GroupElementTypes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GroupElements: Get by Id
#
# GET /Slides/GroupElements/{id}
# Returns: record<groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElementId: string, shapeTreeId: string, ultimateParentShapeTreeId: string>
# operationId: slides_groupelements_get_id
export def "slides-groupelements-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Slides/GroupElements/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Slides: Get Underlying Xml
#
# GET /Slides/OpenOfficeXml/{id}
# Returns: record<id: string, openOfficeXml: string, type: string>
# operationId: slides_slides_openofficexml_get_id_updated
export def "slides-slides-openofficexml-get-id-updated" [
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
  --updated: oneof<nothing, bool> # Indicates whether API should return the orginal uploaded xml (false) or the actively updated version (true, default) (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Slides/OpenOfficeXml/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: updated, var: updated}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, updated: $updated
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Slides: Modify Underlying Xml
#
# PUT /Slides/OpenOfficeXml/{id}
# operationId: slides_slides_openofficexml_put_id
export def "slides-slides-openofficexml-put-id" [
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
  --body-id: string # nullable, format: uuid (spec name: id)
  --open-office-xml: string # nullable
  --type: string # nullable
]: any -> any {
  $in | http-request {
    method: put
    path: "/Slides/OpenOfficeXml/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: body_id}, {name: openOfficeXml, var: open_office_xml}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body_id: $body_id, open_office_xml: $open_office_xml, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SlideMasters: Get by Id
#
# GET /Slides/SlideMasters/{id}
# Returns: record<id: string, slideId: string>
# operationId: slides_slidemasters_get_id
export def "slides-slidemasters-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Slides/SlideMasters/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Slides: Get Svg file
#
# GET /Slides/Svg/{id}
# operationId: slides_slides_svg_get_id_use_cache
export def "slides-slides-svg-get-id-use-cache" [
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
  --use-cache: oneof<nothing, bool> # Indicates whether API should retrieve content from a cache if aviable (true, default), or force an update (false) (default: false)
]: nothing -> any {
  http-request {
    method: get
    path: "/Slides/Svg/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: use_cache, var: use_cache}]
    accept: ["image/svg+xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, use_cache: $use_cache
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Slides: Get by Id
#
# GET /Slides/{id}
# Returns: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, documentId: string, id: string, name: string, number: int, ooxmlId: int, packageUri: string, slideDocumentUrl: string, svgBlobUrl: string>
# operationId: slides_slides_get_id
export def "slides-slides-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Slides/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Slides: Get Dependent Objects Tree
#
# GET /SmartArts/ChildObjects/{id}
# Returns: table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string>
# operationId: slides_smartarts_childobjects_get_id
export def "slides-smartarts-childobjects-get-id" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/SmartArts/ChildObjects/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Slides: Get Details
#
# GET /SmartArts/Details/{id}
# Returns: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, graphicsId: string, id: string, name: string, packageUri: string, parentGraphic: record<chart: record<axes: list, baseElementBlobUrl: string, changedBaseElementBlobUrl: string, chartData: record, dateCreated: string, dateModified: string, id: string, name: string, packageUri: string, parentGraphic: any, parentGraphicId: string, svgBlobUrl: string, titleTextContainer: record, userCreated: string, userModified: string>, dateCreated: string, dateModified: string, graphicTypeId: int, groupElement: record<childGroupElements: list, connector: record, dateCreated: string, dateModified: string, graphic: any, group: record, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: record, shapeTree: record, shapeTreeId: string, typeInfo: record, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementsId: string, height: int, id: string, name: string, ooxmlId: int, picture: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, fileExtension: string, graphicsId: string, id: string, imageFileBlobUrl: string, imageFill: record, imageFillsId: string, name: string, packageUri: string, parentGraphic: any, userCreated: string, userModified: string>, smartArt: any, table: record<baseElementBlobUrl: string, cells: list, changedBaseElementBlobUrl: string, columns: list, dateCreated: string, dateModified: string, hasStylePart: bool, id: string, name: string, packageUri: string, parentGraphic: any, parentGraphicId: string, rows: list, stylePartOuterXml: string, svgBlobUrl: string, userCreated: string, userModified: string>, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, svgBlobUrl: string, userCreated: string, userModified: string>
# operationId: slides_smartarts_details_get_id
export def "slides-smartarts-details-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/SmartArts/Details/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Slides: Get Underlying Xml
#
# GET /SmartArts/OpenOfficeXml/{id}
# Returns: record<id: string, openOfficeXml: string, type: string>
# operationId: slides_smartarts_openofficexml_get_id_updated
export def "slides-smartarts-openofficexml-get-id-updated" [
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
  --updated: oneof<nothing, bool> # Indicates whether API should return the orginal uploaded xml (false) or the actively updated version (true, default) (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/SmartArts/OpenOfficeXml/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: updated, var: updated}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, updated: $updated
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Slides: Modify Underlying Xml
#
# PUT /SmartArts/OpenOfficeXml/{id}
# operationId: slides_smartarts_openofficexml_put_id
export def "slides-smartarts-openofficexml-put-id" [
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
  --body-id: string # nullable, format: uuid (spec name: id)
  --open-office-xml: string # nullable
  --type: string # nullable
]: any -> any {
  $in | http-request {
    method: put
    path: "/SmartArts/OpenOfficeXml/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: body_id}, {name: openOfficeXml, var: open_office_xml}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body_id: $body_id, open_office_xml: $open_office_xml, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Slides: Get Svg file
#
# GET /SmartArts/Svg/{id}
# operationId: slides_smartarts_svg_get_id_use_cache
export def "slides-smartarts-svg-get-id-use-cache" [
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
  --use-cache: oneof<nothing, bool> # Indicates whether API should retrieve content from a cache if aviable (true, default), or force an update (false) (default: false)
]: nothing -> any {
  http-request {
    method: get
    path: "/SmartArts/Svg/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: use_cache, var: use_cache}]
    accept: ["image/svg+xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, use_cache: $use_cache
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SmartArts: Get by Id
#
# GET /SmartArts/{id}
# Returns: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, graphicsId: string, id: string, name: string, packageUri: string, svgBlobUrl: string>
# operationId: slides_smartarts_get_id
export def "slides-smartarts-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/SmartArts/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Borders: Get by Id
#
# GET /Tables/Borders/{id}
# Returns: record<cellId: string, id: string>
# operationId: tables_borders_get_id
export def "tables-borders-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Tables/Borders/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cells: Get by Id
#
# GET /Tables/Cells/{id}
# Returns: record<columnId: string, columnSpan: int, id: string, isMergedHorozontal: bool, isMergedVertical: bool, rowId: string, rowSpan: int>
# operationId: tables_cells_get_id
export def "tables-cells-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Tables/Cells/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tables: Get Dependent Objects Tree
#
# GET /Tables/ChildObjects/{id}
# Returns: table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string>
# operationId: tables_tables_childobjects_get_id
export def "tables-tables-childobjects-get-id" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Tables/ChildObjects/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Columns: Get by Id
#
# GET /Tables/Columns/{id}
# Returns: record<id: string, index: int, tableId: string, width: int>
# operationId: tables_columns_get_id
export def "tables-columns-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Tables/Columns/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tables: Get Details
#
# GET /Tables/Details/{id}
# Returns: record<baseElementBlobUrl: string, cells: table<border: record, column: record, columnId: string, columnSpan: int, dateCreated: string, dateModified: string, fillMap: record, id: string, isMergedHorozontal: bool, isMergedVertical: bool, row: record, rowId: string, rowSpan: int, textContainer: record, userCreated: string, userModified: string>, changedBaseElementBlobUrl: string, columns: table<cells: list, dateCreated: string, dateModified: string, id: string, index: int, table: any, tableId: string, userCreated: string, userModified: string, width: int>, dateCreated: string, dateModified: string, hasStylePart: bool, id: string, name: string, packageUri: string, parentGraphic: record<chart: record<axes: list, baseElementBlobUrl: string, changedBaseElementBlobUrl: string, chartData: record, dateCreated: string, dateModified: string, id: string, name: string, packageUri: string, parentGraphic: any, parentGraphicId: string, svgBlobUrl: string, titleTextContainer: record, userCreated: string, userModified: string>, dateCreated: string, dateModified: string, graphicTypeId: int, groupElement: record<childGroupElements: list, connector: record, dateCreated: string, dateModified: string, graphic: any, group: record, groupElementTypeId: int, groupElementTypePk: string, id: string, parentGroupElement: any, parentGroupElementId: string, shape: record, shapeTree: record, shapeTreeId: string, typeInfo: record, ultimateParentShapeTreeId: string, userCreated: string, userModified: string>, groupElementsId: string, height: int, id: string, name: string, ooxmlId: int, picture: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, fileExtension: string, graphicsId: string, id: string, imageFileBlobUrl: string, imageFill: record, imageFillsId: string, name: string, packageUri: string, parentGraphic: any, userCreated: string, userModified: string>, smartArt: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, graphicsId: string, id: string, name: string, packageUri: string, parentGraphic: any, svgBlobUrl: string, userCreated: string, userModified: string>, table: any, userCreated: string, userModified: string, width: int, xOffset: int, yOffset: int>, parentGraphicId: string, rows: table<cells: list, dateCreated: string, dateModified: string, height: int, id: string, index: int, table: any, tableId: string, userCreated: string, userModified: string>, stylePartOuterXml: string, svgBlobUrl: string, userCreated: string, userModified: string>
# operationId: tables_tables_details_get_id
export def "tables-tables-details-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Tables/Details/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tables: Get Underlying Xml
#
# GET /Tables/OpenOfficeXml/{id}
# Returns: record<id: string, openOfficeXml: string, type: string>
# operationId: tables_tables_openofficexml_get_id_updated
export def "tables-tables-openofficexml-get-id-updated" [
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
  --updated: oneof<nothing, bool> # Indicates whether API should return the orginal uploaded xml (false) or the actively updated version (true, default) (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Tables/OpenOfficeXml/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: updated, var: updated}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, updated: $updated
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tables: Modify Underlying Xml
#
# PUT /Tables/OpenOfficeXml/{id}
# operationId: tables_tables_openofficexml_put_id
export def "tables-tables-openofficexml-put-id" [
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
  --body-id: string # nullable, format: uuid (spec name: id)
  --open-office-xml: string # nullable
  --type: string # nullable
]: any -> any {
  $in | http-request {
    method: put
    path: "/Tables/OpenOfficeXml/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: body_id}, {name: openOfficeXml, var: open_office_xml}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body_id: $body_id, open_office_xml: $open_office_xml, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rows: Get by Id
#
# GET /Tables/Rows/{id}
# Returns: record<height: int, id: string, index: int, tableId: string>
# operationId: tables_rows_get_id
export def "tables-rows-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Tables/Rows/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tables: Get Svg file
#
# GET /Tables/Svg/{id}
# operationId: tables_tables_svg_get_id_use_cache
export def "tables-tables-svg-get-id-use-cache" [
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
  --use-cache: oneof<nothing, bool> # Indicates whether API should retrieve content from a cache if aviable (true, default), or force an update (false) (default: false)
]: nothing -> any {
  http-request {
    method: get
    path: "/Tables/Svg/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: use_cache, var: use_cache}]
    accept: ["image/svg+xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, use_cache: $use_cache
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Table: Get Table Data
#
# GET /Tables/TableUpdate/{id}
# Returns: record<tableData: list<list<string>>, tableId: string>
# operationId: tables_tables_tableupdate_get_id
export def "tables-tables-tableupdate-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Tables/TableUpdate/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tables: Update Table Data
#
# PUT /Tables/TableUpdate/{id}
# operationId: tables_tables_tableupdate_put_id
export def "tables-tables-tableupdate-put-id" [
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
  --table-data: list # nullable
  --table-id: string # format: uuid
]: any -> any {
  $in | http-request {
    method: put
    path: "/Tables/TableUpdate/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: tableData, var: table_data}, {name: tableId, var: table_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, table_data: $table_data, table_id: $table_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tables: Get by Id
#
# GET /Tables/{id}
# Returns: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, hasStylePart: bool, id: string, name: string, packageUri: string, parentGraphicId: string, stylePartOuterXml: string, svgBlobUrl: string>
# operationId: tables_tables_get_id
export def "tables-tables-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Tables/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# BackgroundFills: Get by Id
#
# GET /Themes/BackgroundFills/{id}
# Returns: record<id: string, intensityId: int, themeId: string>
# operationId: themes_backgroundfills_get_id
export def "themes-backgroundfills-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Themes/BackgroundFills/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Theme: Get Dependent Objects Tree
#
# GET /Themes/ChildObjects/{id}
# Returns: table<entityId: string, entityName: string, objectType: string, parentEntityId: string, parentObjectType: string>
# operationId: theme_themes_childobjects_get_id
export def "theme-themes-childobjects-get-id" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Themes/ChildObjects/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Colors: Get by Id
#
# GET /Themes/Colors/{id}
# Returns: record<accent1: string, accent2: string, accent3: string, accent4: string, accent5: string, accent6: string, dark1: string, dark2: string, followedHyperlink: string, hyperlink: string, id: string, light1: string, light2: string, name: string, themeId: string>
# operationId: themes_colors_get_id
export def "themes-colors-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Themes/Colors/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CustomColors: Get by Id
#
# GET /Themes/CustomColors/{id}
# Returns: record<hexValue: string, id: string, name: string, themeId: string>
# operationId: themes_customcolors_get_id
export def "themes-customcolors-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Themes/CustomColors/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Theme: Get Details
#
# GET /Themes/Details/{id}
# Returns: record<backgroundFills: table<dateCreated: string, dateModified: string, fillMap: record, id: string, intensityId: int, theme: any, themeId: string, userCreated: string, userModified: string>, baseElementBlobUrl: string, changedBaseElementBlobUrl: string, colors: record<accent1: string, accent2: string, accent3: string, accent4: string, accent5: string, accent6: string, dark1: string, dark2: string, dateCreated: string, dateModified: string, followedHyperlink: string, hyperlink: string, id: string, light1: string, light2: string, name: string, theme: any, themeId: string, userCreated: string, userModified: string>, customColors: table<dateCreated: string, dateModified: string, hexValue: string, id: string, name: string, theme: any, themeId: string, userCreated: string, userModified: string>, dateCreated: string, dateModified: string, effectMaps: table<dateCreated: string, dateModified: string, effect: record, id: string, intensityId: int, theme: any, themeId: string, userCreated: string, userModified: string>, fills: table<dateCreated: string, dateModified: string, fillMap: record, id: string, intensityId: int, theme: any, themeId: string, userCreated: string, userModified: string>, fonts: record<bodyFont: string, dateCreated: string, dateModified: string, headingFont: string, id: string, theme: any, themeId: string, userCreated: string, userModified: string>, id: string, lineMaps: table<dateCreated: string, dateModified: string, id: string, intensityId: int, line: record, theme: any, themeId: string, userCreated: string, userModified: string>, name: string, packageUri: string, slide: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, document: record<baseElementBlobUrl: string, blobLocation: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, documentTypeId: int, filename: string, id: string, name: string, ownerGuid: string, packageUri: string, slides: list, storyId: string, tableStylesXmlBlobUrl: string, title: string, userCreated: string, userModified: string>, documentId: string, id: string, name: string, number: int, ooxmlId: int, packageUri: string, shapeTree: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, dateCreated: string, dateModified: string, groupElement: record, groupElementId: string, groupElements: list, hidden: bool, id: string, name: string, ooxmlId: int, packageUri: string, slide: any, slideId: string, svgBlobUrl: string, title: string, userCreated: string, userModified: string>, slideDocumentUrl: string, slideMaster: record<colorMap: record, dateCreated: string, dateModified: string, id: string, parentSlide: any, slideId: string, userCreated: string, userModified: string>, svgBlobUrl: string, theme: any, userCreated: string, userModified: string>, slideId: string, userCreated: string, userModified: string>
# operationId: theme_themes_details_get_id
export def "theme-themes-details-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Themes/Details/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# EffectMap: Get by Id
#
# GET /Themes/EffectMap/{id}
# Returns: record<id: string, intensityId: int, themeId: string>
# operationId: themes_effectmap_get_id
export def "themes-effectmap-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Themes/EffectMap/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fills: Get by Id
#
# GET /Themes/Fills/{id}
# Returns: record<id: string, intensityId: int, themeId: string>
# operationId: themes_fills_get_id
export def "themes-fills-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Themes/Fills/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fonts: Get by Id
#
# GET /Themes/Fonts/{id}
# Returns: record<bodyFont: string, headingFont: string, id: string, themeId: string>
# operationId: themes_fonts_get_id
export def "themes-fonts-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Themes/Fonts/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Intensity: List All Possible Types
#
# GET /Themes/Intensity
# Returns: table<description: string, id: string, name: string, typeId: int>
# operationId: themes_intensity_get
export def "themes-intensity-get" [
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
    path: "/Themes/Intensity"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Intensity: Get By Type Id
#
# GET /Themes/Intensity/TypeId/{type_id}
# Returns: record<description: string, id: string, name: string, typeId: int>
# operationId: themes_intensity_typeid_get_type_id
export def "themes-intensity-typeid-get-type-id" [
  type_id: int
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
    path: "/Themes/Intensity/TypeId/{type_id}"
    path_params: [{name: type_id, var: type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type_id: $type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Intensity: Get by Id
#
# GET /Themes/Intensity/{id}
# Returns: record<description: string, id: string, name: string, typeId: int>
# operationId: themes_intensity_get_id
export def "themes-intensity-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Themes/Intensity/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# LineMap: Get by Id
#
# GET /Themes/LineMap/{id}
# Returns: record<id: string, intensityId: int, themeId: string>
# operationId: themes_linemap_get_id
export def "themes-linemap-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Themes/LineMap/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Theme: Get Underlying Xml
#
# GET /Themes/OpenOfficeXml/{id}
# Returns: record<id: string, openOfficeXml: string, type: string>
# operationId: theme_themes_openofficexml_get_id_updated
export def "theme-themes-openofficexml-get-id-updated" [
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
  --updated: oneof<nothing, bool> # Indicates whether API should return the orginal uploaded xml (false) or the actively updated version (true, default) (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Themes/OpenOfficeXml/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: updated, var: updated}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, updated: $updated
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Theme: Modify Underlying Xml
#
# PUT /Themes/OpenOfficeXml/{id}
# operationId: theme_themes_openofficexml_put_id
export def "theme-themes-openofficexml-put-id" [
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
  --body-id: string # nullable, format: uuid (spec name: id)
  --open-office-xml: string # nullable
  --type: string # nullable
]: any -> any {
  $in | http-request {
    method: put
    path: "/Themes/OpenOfficeXml/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: body_id}, {name: openOfficeXml, var: open_office_xml}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body_id: $body_id, open_office_xml: $open_office_xml, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Theme: Get Svg file
#
# GET /Themes/Svg/{id}
# operationId: theme_themes_svg_get_id_use_cache
export def "theme-themes-svg-get-id-use-cache" [
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
  --use-cache: oneof<nothing, bool> # Indicates whether API should retrieve content from a cache if aviable (true, default), or force an update (false) (default: false)
]: nothing -> any {
  http-request {
    method: get
    path: "/Themes/Svg/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: use_cache, var: use_cache}]
    accept: ["image/svg+xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, use_cache: $use_cache
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Themes: Get by Id
#
# GET /Themes/{id}
# Returns: record<baseElementBlobUrl: string, changedBaseElementBlobUrl: string, id: string, name: string, packageUri: string, slideId: string>
# operationId: theme_themes_get_id
export def "theme-themes-get-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Themes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
