# Auto-generated client for NaviPlan API v1
# Source: https://api.apis.guru/v2/specs/naviplancentral.com/plan/v1/swagger.json
# Auth: --token flag or $env.NAVIPLAN_API_TOKEN

const CLIENT = {
  base_url: "https://demo.uat.naviplancentral.com/plan"
  token_env_var: "NAVIPLAN_API_TOKEN"
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

def base-url-completer [] { ["https://demo.uat.naviplancentral.com/plan" "http://demo.uat.naviplancentral.com/plan"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/json"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    advisors-get: "record<advisors: table<addressLine1: string, addressLine2: string, advisorId: string, advisorTitle: string, businessPhone: string, cellPhone: string, city: string, emailAddress: string, faxPhone: string, firstName: string, homePhone: string, lastName: string, links: list, middleName: string, officeName: string, officeWebsite: string, pagerNumber: string, postalCode: string, stateProvince: string>>"
    advisors-get-by-householdid-clientid: "record<advisors: table<addressLine1: string, addressLine2: string, advisorId: string, advisorTitle: string, businessPhone: string, cellPhone: string, city: string, emailAddress: string, faxPhone: string, firstName: string, homePhone: string, lastName: string, links: list, middleName: string, officeName: string, officeWebsite: string, pagerNumber: string, postalCode: string, stateProvince: string>>"
    advisors-get-by-id: "record<addressLine1: string, addressLine2: string, advisorId: string, advisorTitle: string, businessPhone: string, cellPhone: string, city: string, emailAddress: string, faxPhone: string, firstName: string, homePhone: string, lastName: string, links: table<href: string, rel: string>, middleName: string, officeName: string, officeWebsite: string, pagerNumber: string, postalCode: string, stateProvince: string>"
    assumptions-get-by-planid: "record<assumptions: record<anyHeadAlreadyRetired: bool, bothRetired: bool, bucketing: record<distributionBucketTargetBalance: record, endDate: record, indexedAt: record, returnRate: record, standardDeviation: record, startDate: record>, client: record<alreadyRetired: bool, deceasedAge: int, deceasedDate: record, estateIncomeTaxes: record, governmentPensions: record, maritalOrTaxFilingStatus: record, preRetirementIncomeTaxes: record, retirementAge: int, retirementDate: record, retirementIncomeTaxes: record>, coClient: record<alreadyRetired: bool, deceasedAge: int, deceasedDate: record, estateIncomeTaxes: record, governmentPensions: record, maritalOrTaxFilingStatus: record, preRetirementIncomeTaxes: record, retirementAge: int, retirementDate: record, retirementIncomeTaxes: record>, firstToDieDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, firstToDieMember: string, firstToRetireDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, inflationRate: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, lastToDieDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, lastToDieMember: string, lastToRetireDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, retirementYearAdjustedIfAlreadyRetired: record<raw: int>, splitSurplusSavingsStrategiesEnabled: bool, taxMethod: string>, links: table<href: string, rel: string>>"
    business-entities-get-by-planid: "record<businessEntities: table<activities: list, assetId: record, businessType: string, businessTypeFormatted: string, currentAnnualDistributions: record, currentAnnualDividends: record, currentAnnualGrowthRate: record, currentAnnualNetIncome: record, entityName: string, liquidationEvent: record, marketValuationDate: record, marketValue: record, owner: string, purchaseAmount: record, purchaseDate: record, standardDeviation: record>, links: table<href: string, rel: string>>"
    business-entities-get-by-id-planid: "record<businessEntity: record<activities: list<record>, assetId: record<rawId: int>, businessType: string, businessTypeFormatted: string, currentAnnualDistributions: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, currentAnnualDividends: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, currentAnnualGrowthRate: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, currentAnnualNetIncome: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, entityName: string, liquidationEvent: record<firstSaleDate: record, lastSaleDate: record, liquidationType: string, liquidationTypeDescription: string, saleDatesDescription: string>, marketValuationDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, marketValue: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, owner: string, purchaseAmount: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, purchaseDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, standardDeviation: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>>, links: table<href: string, rel: string>>"
    calculations-get-by-planid: "bool"
    defined-benefit-pensions-get-by-planid: "record<definedBenefitPensions: table<benefit: record, description: string, isBenefitFormula: bool, isBenefitIntegratedWithCppQpp: bool, isFormulaIntegratedWithCppQpp: bool, owner: string, pensionType: string, percentPayableToSurvivor: record, projectedYearsOfService: int, startDate: record>, links: table<href: string, rel: string>>"
    defined-benefit-pensions-get-by-id-planid: "record<definedBenefitPension: record<benefit: record<enabled: bool, populated: bool, value: record>, description: string, isBenefitFormula: bool, isBenefitIntegratedWithCppQpp: bool, isFormulaIntegratedWithCppQpp: bool, owner: string, pensionType: string, percentPayableToSurvivor: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, projectedYearsOfService: int, startDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>>, links: table<href: string, rel: string>>"
    family-get-by-planid: "record<family: record<address: record<city: string, combinedCityStateProvince: string, country: string, stateOrProvince: string, stateOrProvinceAbbrev: string, street1: string, street2: string, zipOrPostalCode: string>, client: record<address: record, ageAsOfPlanDate: int, birthdate: record, citizenship: string, email: string, employer: record, gender: record, name: record, ownershipId: string, phone: record>, coClient: record<address: record, ageAsOfPlanDate: int, birthdate: record, citizenship: string, email: string, employer: record, gender: record, name: record, ownershipId: string, phone: record>, dependents: list<record>, headFullNames: string>, links: table<href: string, rel: string>>"
    goal-adjustments-get-education-by-id-clientid-planid: "record<adjustedValues: record<duration: float, expensesCovered: float, lumpSumContribution: float, lumpSumDate: string, monthlySavingsContribution: float>, created: string, goalId: int, projectedResults: record<goalId: int, percentCovered: float, projections: list<record>>>"
    goal-adjustments-post-education-by-id-goaladjustments-planid: "record<goalAdjustments: record<adjustedValues: record<duration: float, expensesCovered: float, lumpSumContribution: float, lumpSumDate: string, monthlySavingsContribution: float>, created: string, goalId: int>, projectedResults: record<goalId: int, percentCovered: float, projections: list<record>>>"
    goal-adjustments-get-goal-success-rates-by-clientid-planid: "record<goalSuccessRateResults: table<description: string, goalId: int, successRate: float>>"
    goal-adjustments-get-major-purchase-by-id-clientid-planid: "record<adjustedValues: record<lumpSumContribution: float, lumpSumDate: string, monthlySavingsContribution: float, targetDate: string, totalNeed: float>, created: string, goalId: int, projectedResults: record<goalId: int, percentCovered: float, projections: list<record>>>"
    goal-adjustments-post-major-purchase-by-id-goaladjustments-planid: "record<goalAdjustments: record<adjustedValues: record<lumpSumContribution: float, lumpSumDate: string, monthlySavingsContribution: float, targetDate: string, totalNeed: float>, created: string, goalId: int>, projectedResults: record<goalId: int, percentCovered: float, projections: list<record>>>"
    goal-adjustments-get-goal-adjustment-restrictions-by-clientid-planid: "record<educationRestrictions: table<canChangeDuration: bool, goalId: int>>"
    goal-adjustments-get-retirement-by-clientid-planid: "record<adjustedValues: record<clientRetirementAge: float, coClientRetirementAge: float, discretionaryExpenseCoverage: float, fixedExpenseCoverage: float, lumpSumContribution: float, lumpSumDate: string, monthlySavingsContribution: float>, created: string, goalId: int, projectedResults: record<goalId: int, percentCovered: float, projections: list<record>>>"
    goal-adjustments-post-retirement-by-goaladjustments-planid: "record<goalAdjustments: record<adjustedValues: record<clientRetirementAge: float, coClientRetirementAge: float, discretionaryExpenseCoverage: float, fixedExpenseCoverage: float, lumpSumContribution: float, lumpSumDate: string, monthlySavingsContribution: float>, created: string, goalId: int>, projectedResults: record<goalId: int, percentCovered: float, projections: list<record>>>"
    goal-adjustments-get-what-are-my-options-by-id-clientid-planid: "record<additionalMonthlySavings: float, clientRetirementAge: int, clientRetirementAgeDate: string, coClientRetirementAge: int, coClientRetirementAgeDate: string, expenseCoverageDollars: float, expenseCoveragePercentage: float, lumpSumSavings: float, purchaseDate: string>"
    goals-get-by-planid: "record<goals: table<assetsRemainingAfterFundingGoal: record, coverage: record, description: string, endDate: record, identifier: record, startDate: record, type: string, yearAssetsDepleted: record>, links: table<href: string, rel: string>>"
    goals-get-by-id-planid: "record<goal: record<assetsRemainingAfterFundingGoal: record<enabled: bool, populated: bool, value: record>, coverage: record<enabled: bool, populated: bool, value: record>, description: string, endDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, identifier: record<id: int>, startDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, type: string, yearAssetsDepleted: record<enabled: bool, populated: bool, value: record>>, links: table<href: string, rel: string>>"
    holding-companies-get-by-planid: "record<holdingCompanies: table<annualDividendYield: record, ccpc: record, commonSharesOutstanding: int, contributions: record, corporateYearEnd: record, description: string, dividendType: string, dividendTypeFormatted: string, estateDetails: record, historicalData: record, id: string, investmentAccounts: list, liabilities: list, lifeInsurancePolicies: list, marketValue: record, numPreferredShareClasses: int, otherAssets: list, ownershipAsOfDate: record, ownershipDetails: record, preferredSharesOutstanding: int, provinceOfIncorporation: string, provinceOfTaxation: string, realEstateAssets: list, valueOfAllCommonShares: record, valueOfAllPreferredShares: record, withdrawals: record>, links: table<href: string, rel: string>>"
    holding-companies-get-by-id-planid: "record<holdingCompany: record<annualDividendYield: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, ccpc: record<rawValue: bool, valueAsYesNo: string>, commonSharesOutstanding: int, contributions: record<interCompanyDividendsReceived: list, sharePurchases: list, shareholderLoans: list>, corporateYearEnd: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, description: string, dividendType: string, dividendTypeFormatted: string, estateDetails: record<enableFiftyPercentSolution: record, estateFreeze: record, estateFreezeDate: record, shareOptionsAtFirstDeath: string, shareOptionsAtSecondDeathAndDeathInTheSameYear: string>, historicalData: record<generalSetups: record, notionalAccounts: record, outstandingShareholderLoans: record>, id: string, investmentAccounts: list<record>, liabilities: list<record>, lifeInsurancePolicies: list<record>, marketValue: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, numPreferredShareClasses: int, otherAssets: list<record>, ownershipAsOfDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, ownershipDetails: record<common: list, commonSharesDetails: list, preferred: list, preferredSharesDetails: list, shareholderPercentOwnership: list>, preferredSharesOutstanding: int, provinceOfIncorporation: string, provinceOfTaxation: string, realEstateAssets: list<record>, valueOfAllCommonShares: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, valueOfAllPreferredShares: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, withdrawals: record<loanRepaymentsToShareholder: list, manualDividendDistributions: list, shareRedemptions: list>>, links: table<href: string, rel: string>>"
    households-get-by-householdid: "record<households: table<accessiblePlans: list, clientDescription: string, householdId: int>, links: table<href: string, rel: string>>"
    liabilities-get-by-planid: "record<liabilities: table<annualPaymentAmount: record, balanceAsOf: record, balanceAsOfPlanDate: record, debtModStrategies: record, description: string, id: string, insuredForDisability: record, insuredForLife: record, interestRate: record, isInterestRateVariable: record, isPaymentVariable: record, linkedAssetId: string, linkedAssetName: string, loanDate: record, originalBalance: record, owner: string, paidOffByRetirement: record, payOffDate: record, payOffOptionType: record, paymentAmount: record, paymentFrequency: record, paymentType: record, type: record>, links: table<href: string, rel: string>>"
    liabilities-get-by-id-planid: "record<liability: record<annualPaymentAmount: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, balanceAsOf: record<date: record, formattedDecimal: string, formattedNoDecimal: string, raw: float>, balanceAsOfPlanDate: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, debtModStrategies: record<lumpSumDebtModStrategies: list, periodicDebtModStrategies: list>, description: string, id: string, insuredForDisability: record<rawValue: bool, valueAsYesNo: string>, insuredForLife: record<rawValue: bool, valueAsYesNo: string>, interestRate: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, isInterestRateVariable: record<rawValue: bool, valueAsYesNo: string>, isPaymentVariable: record<rawValue: bool, valueAsYesNo: string>, linkedAssetId: string, linkedAssetName: string, loanDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, originalBalance: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, owner: string, paidOffByRetirement: record<enabled: bool, populated: bool, value: record>, payOffDate: record<enabled: bool, populated: bool, value: record>, payOffOptionType: record<value: string>, paymentAmount: record<enabled: bool, populated: bool, value: record>, paymentFrequency: record<value: string>, paymentType: record<value: string>, type: record<value: string>>, links: table<href: string, rel: string>>"
    lifestyle-assets-get-by-planid: "record<lifestyleAssets: table<afterTaxProceedsAccountName: string, description: string, futureValueProjectedGrossSaleValue: record, id: string, isMajorPurchaseGoal: bool, marketValueAsOf: record, owner: string, preTaxGrowthRate: record, presentValueProjectedGrossSaleValue: record, projectedSaleDate: record, purchaseAmount: record, purchaseDate: record, sellingCostPercent: record, standardDeviation: record, type: record>, links: table<href: string, rel: string>>"
    lifestyle-assets-get-by-id-planid: "record<lifestyleAsset: record<afterTaxProceedsAccountName: string, description: string, futureValueProjectedGrossSaleValue: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, id: string, isMajorPurchaseGoal: bool, marketValueAsOf: record<date: record, formattedDecimal: string, formattedNoDecimal: string, raw: float>, owner: string, preTaxGrowthRate: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, presentValueProjectedGrossSaleValue: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, projectedSaleDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, purchaseAmount: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, purchaseDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, sellingCostPercent: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, standardDeviation: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, type: record<formatted: string, value: string>>, links: table<href: string, rel: string>>"
    live-plan-get-goals-by-clientid-planid: "record<clientDescription: string, clientId: int, goals: table<amount: float, coveragePercentage: float, description: string, endDate: string, id: int, inflationRate: float, owners: list, startDate: string, type: string>, planDescription: string, planLastUpdateTime: string>"
    live-plan-get-goal-funding-list-by-clientid-planid: "record<goals: table<description: string, fundingAccounts: list, goalId: int>>"
    live-plan-get-what-are-my-options-by-id-clientid-planid: "record<additionalMonthlySavings: float, clientRetirementAge: int, clientRetirementAgeDate: string, coClientRetirementAge: int, coClientRetirementAgeDate: string, expenseCoverageDollars: float, expenseCoveragePercentage: float, lumpSumSavings: float, purchaseDate: string>"
    live-plan-get-accounts-by-clientid-planid: "record<accounts: table<description: string, holdings: list, id: int, legacyId: string, owner: record, type: int>>"
    live-plan-get-liabilities-by-clientid-planid: "record<liabilities: table<description: string, endDate: string, id: int, legacyId: string, outstandingPrincipal: float, outstandingPrincipalAsOfDate: string, owner: record, startDate: string, type: int>>"
    live-plan-get-lifestyle-assets-by-clientid-planid: "record<lifestyleAssets: table<description: string, id: int, owner: record, purchaseDate: string, purchaseValue: float, type: int, valuationDate: string, valuationValue: float>>"
    live-plan-get-real-estate-assets-by-clientid-planid: "record<realEstateAssets: table<description: string, id: int, legacyId: string, marketValue: float, owner: record, purchaseAmount: float, purchaseDate: string, valuationDate: string>>"
    live-plan-get-projected-net-worth-by-clientid-planid: "record<netWorthProjections: table<endOfYearRetirementAssets: float, endOfYearTotalAssets: float, year: int>>"
    live-plan-get-projected-needs-vs-abilities-by-id-clientid-planid: "record<goalId: int, percentCovered: float, projections: table<projectedAbilities: float, projectedNeed: float, year: int>>"
    net-worth-get-by-planid: "record<links: table<href: string, rel: string>, netWorth: record<netWorthAtPlanDate: record<assets: record, assetsFundingRetirement: record, clientNetWorth: record, coClientNetWorth: record, communityPropertyNetWorth: record, jointNetWorth: record, liabilities: record, totalNetWorth: record>, netWorthAtPlanEnd: record<enabled: bool, populated: bool, value: record>, netWorthAtRetirement: record<enabled: bool, populated: bool, value: record>>>"
    plan-information-get-by-planid: "record<country: string, description: string, isJointAnalysis: bool, links: table<href: string, rel: string>, locale: string, planDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, planDescription: string, planId: string, planLevel: string, planModules: record<isCriticalIllnessModuleEnabled: bool, isDisabilityIncomeModuleEnabled: bool, isEstatePlanningModuleEabled: bool, isLongTermCareModuleEnabled: bool, isSurvivorIncomeModuleEnabled: bool>, planType: string, publishDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>>"
    plan-statuses-get-by-planid: "record<hasIntegratedAccounts: string, links: table<href: string, rel: string>, planDataStatus: string, serializedDataStatus: string>"
    portfolio-accounts-get-by-planid: "record<links: table<href: string, rel: string>, portfolioAccounts: table<accountReturnRatesNoLongerCorrelateToAssumedAssetMixDueToOverrideInGsm: bool, annualFee: record, applicableRangeRetirementLiquidatedAssets: record, costBasis: record, description: string, descriptionWithOwner: string, excludeInAA: bool, holdings: list, id: string, isSystemGenerated: bool, marketValue: record, owner: string, portfolioAssets: list, rateOfReturn: record, savingsStrategies: record, seppRedemptionStrategy: record, type: string, valuationDate: record>>"
    portfolio-accounts-get-by-id-planid: "record<links: table<href: string, rel: string>, portfolioAccount: record<accountReturnRatesNoLongerCorrelateToAssumedAssetMixDueToOverrideInGsm: bool, annualFee: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, applicableRangeRetirementLiquidatedAssets: record<endDate: record, startDate: record>, costBasis: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, description: string, descriptionWithOwner: string, excludeInAA: bool, holdings: list<record>, id: string, isSystemGenerated: bool, marketValue: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, owner: string, portfolioAssets: list<record>, rateOfReturn: record<preRetirement: record, retirement: record>, savingsStrategies: record<lumpSumSavingsStrategies: list, periodicSavingsStrategies: list, rrspMaximizerStrategies: list, surplusSavingsStrategies: list>, seppRedemptionStrategy: record<applicableDateRange: record, distributionMethod: record, lifeExpectancyTable: record, redemptionFrequency: record>, type: string, valuationDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>>>"
    projected-annual-summary-get-by-planid: "record<links: table<href: string, rel: string>, projections: table<annualSummary: record, links: list>>"
    projected-annual-summary-get-by-id-planid: "record<annualSummary: record<cashFlow: record<surplusDeficit: float, totalIncome: float, totalOutflowsWithTaxes: float, totalOutflowsWithoutTaxes: float, totalTaxes: float>, clientAge: int, coClientAge: int, netWorth: record<totalAssets: float, totalLiabilities: float, totalNetWorth: float>, year: int>, links: table<href: string, rel: string>>"
    projected-cash-flow-get-by-planid: "record<links: table<href: string, rel: string>, projections: table<cashFlow: record, links: list>>"
    projected-cash-flow-get-by-id-planid: "record<cashFlow: record<cashFlow: record<clientCashFlow: record, coClientCashFlow: record, totalCashFlow: record>, clientAge: int, coClientAge: int, year: int>, links: table<href: string, rel: string>>"
    projected-goals-get-assets-funding-goals-by-planid: "record<links: table<href: string, rel: string>, projections: table<clientAge: int, coClientAge: int, goals: list, year: int>>"
    projected-goals-get-needs-vs-abilities-by-planid: "record<links: table<href: string, rel: string>, projections: table<clientAge: int, coClientAge: int, goals: list, year: int>>"
    projected-net-worth-get-by-planid: "record<links: table<href: string, rel: string>, projections: table<links: list, netWorth: record>>"
    projected-net-worth-get-by-id-planid: "record<links: table<href: string, rel: string>, netWorth: record<clientAge: int, coClientAge: int, endOfYearNetWorth: record<assets: record, assetsFundingRetirement: record, clientNetWorth: record, coClientNetWorth: record, communityPropertyNetWorth: record, jointNetWorth: record, liabilities: record, totalNetWorth: record>, year: int>>"
    restricted-stocks-get-by-planid: "record<links: table<href: string, rel: string>, restrictedStocks: table<annualDividendPerUnit: record, applicableRangeRetirementLiquidatedAssets: record, awardedDate: record, currentUnitValue: record, description: string, growthRate: record, id: string, numberOfUnits: int, owner: string, pricePaidForAward: record, type: string>>"
    restricted-stocks-get-by-id-planid: "record<links: table<href: string, rel: string>, restrictedStock: record<annualDividendPerUnit: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, applicableRangeRetirementLiquidatedAssets: record<endDate: record, startDate: record>, awardedDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, currentUnitValue: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, description: string, growthRate: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, id: string, numberOfUnits: int, owner: string, pricePaidForAward: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, type: string>>"
    service-information-statistics: "record<altairConnectionStatus: bool, name: string, pomVersion: string, serviceVersion: string, status: string>"
    stock-options-get-by-planid: "record<links: table<href: string, rel: string>, stockOptions: table<annualDividendPerUnit: record, applicableRangeRetirementLiquidatedAssets: record, company: string, currentUnitPrice: record, currentUnitPriceDate: record, description: string, endOfPlanYearExercisableGrossValue: record, exerciseCost: record, expirationDate: record, grantDate: record, grantedOptions: int, growthRate: record, id: string, optionsExercisable: int, optionsExercised: int, optionsVested: int, owner: string, preTaxProfit: record, startOfYearAMTBasis: record, startOfYearCostBasis: record, startOfYearUnitPrice: record, strikePrice: record, symbol: string, type: string, typeFormatted: string, vestingSchedule: list>>"
    stock-options-get-by-id-planid: "record<links: table<href: string, rel: string>, stockOption: record<annualDividendPerUnit: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, applicableRangeRetirementLiquidatedAssets: record<endDate: record, startDate: record>, company: string, currentUnitPrice: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, currentUnitPriceDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, description: string, endOfPlanYearExercisableGrossValue: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, exerciseCost: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, expirationDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, grantDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, grantedOptions: int, growthRate: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, id: string, optionsExercisable: int, optionsExercised: int, optionsVested: int, owner: string, preTaxProfit: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, startOfYearAMTBasis: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, startOfYearCostBasis: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, startOfYearUnitPrice: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, strikePrice: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, symbol: string, type: string, typeFormatted: string, vestingSchedule: list<record>>>"
    auth-login-by-model: "record<eulaAccepted: bool, hasAccountAggregation: bool, hasGoalWhatIfing: bool, hasUserSetPassword: bool, isAdmin: bool, isAdvisor: bool, isClient: bool, isPasswordExpired: bool, userId: string, userName: string>"
    auth-resume-session: "record<eulaAccepted: bool, hasAccountAggregation: bool, hasGoalWhatIfing: bool, hasUserSetPassword: bool, isAdmin: bool, isAdvisor: bool, isClient: bool, isPasswordExpired: bool, userId: string, userName: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["advisors-get" "advisors-get-by-householdid-clientid" "advisors-get-by-id" "assumptions-get-by-planid" "business-entities-get-by-planid" "business-entities-get-by-id-planid" "calculations-get-by-planid" "defined-benefit-pensions-get-by-planid" "defined-benefit-pensions-get-by-id-planid" "eula-accept" "family-get-by-planid" "goal-adjustments-get-education-by-id-clientid-planid" "goal-adjustments-post-education-by-id-goaladjustments-planid" "goal-adjustments-get-goal-success-rates-by-clientid-planid" "goal-adjustments-get-major-purchase-by-id-clientid-planid" "goal-adjustments-post-major-purchase-by-id-goaladjustments-planid" "goal-adjustments-get-goal-adjustment-restrictions-by-clientid-planid" "goal-adjustments-get-retirement-by-clientid-planid" "goal-adjustments-post-retirement-by-goaladjustments-planid" "goal-adjustments-get-what-are-my-options-by-id-clientid-planid" "goals-get-by-planid" "goals-get-by-id-planid" "holding-companies-get-by-planid" "holding-companies-get-by-id-planid" "households-get-by-householdid" "liabilities-get-by-planid" "liabilities-get-by-id-planid" "lifestyle-assets-get-by-planid" "lifestyle-assets-get-by-id-planid" "live-plan-get-goals-by-clientid-planid" "live-plan-get-goal-funding-list-by-clientid-planid" "live-plan-get-what-are-my-options-by-id-clientid-planid" "live-plan-get-accounts-by-clientid-planid" "live-plan-get-liabilities-by-clientid-planid" "live-plan-get-lifestyle-assets-by-clientid-planid" "live-plan-get-real-estate-assets-by-clientid-planid" "live-plan-get-projected-net-worth-by-clientid-planid" "live-plan-get-projected-needs-vs-abilities-by-id-clientid-planid" "net-worth-get-by-planid" "password-has-user-set-password" "password-password-requirements" "password-reset-by-model" "password-set-by-model" "plan-information-get-by-planid" "plan-statuses-get-by-planid" "portfolio-accounts-get-by-planid" "portfolio-accounts-get-by-id-planid" "projected-annual-summary-get-by-planid" "projected-annual-summary-get-by-id-planid" "projected-cash-flow-get-by-planid" "projected-cash-flow-get-by-id-planid" "projected-goals-get-assets-funding-goals-by-planid" "projected-goals-get-needs-vs-abilities-by-planid" "projected-net-worth-get-by-planid" "projected-net-worth-get-by-id-planid" "restricted-stocks-get-by-planid" "restricted-stocks-get-by-id-planid" "service-information-statistics" "stock-options-get-by-planid" "stock-options-get-by-id-planid" "auth-login-by-model" "auth-password-requirements" "auth-logout" "auth-resume-session" "commands"] | sort) } | get name | first)
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

# Retrieve Advisors
#
# GET /api/Advisors
# Returns: record<advisors: table<addressLine1: string, addressLine2: string, advisorId: string, advisorTitle: string, businessPhone: string, cellPhone: string, city: string, emailAddress: string, faxPhone: string, firstName: string, homePhone: string, lastName: string, links: list, middleName: string, officeName: string, officeWebsite: string, pagerNumber: string, postalCode: string, stateProvince: string>>
# operationId: Advisors_Get
export def "advisors-get" [
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
    path: "/api/Advisors"
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve Advisors for a Client
#
# GET /api/Advisors/{householdId}/{clientId}
# Returns: record<advisors: table<addressLine1: string, addressLine2: string, advisorId: string, advisorTitle: string, businessPhone: string, cellPhone: string, city: string, emailAddress: string, faxPhone: string, firstName: string, homePhone: string, lastName: string, links: list, middleName: string, officeName: string, officeWebsite: string, pagerNumber: string, postalCode: string, stateProvince: string>>
# operationId: Advisors_GetByHouseholdidClientid
export def "advisors-get-by-householdid-clientid" [
  household_id: int
  client_id: string
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
    path: "/api/Advisors/{householdId}/{clientId}"
    path_params: [{name: householdId, var: household_id}, {name: clientId, var: client_id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    household_id: $household_id, client_id: $client_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve an Advisor
#
# GET /api/Advisors/{id}
# Returns: record<addressLine1: string, addressLine2: string, advisorId: string, advisorTitle: string, businessPhone: string, cellPhone: string, city: string, emailAddress: string, faxPhone: string, firstName: string, homePhone: string, lastName: string, links: table<href: string, rel: string>, middleName: string, officeName: string, officeWebsite: string, pagerNumber: string, postalCode: string, stateProvince: string>
# operationId: Advisors_GetById
export def "advisors-get-by-id" [
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
    path: "/api/Advisors/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve plan assumptions
#
# GET /api/Assumptions
# Returns: record<assumptions: record<anyHeadAlreadyRetired: bool, bothRetired: bool, bucketing: record<distributionBucketTargetBalance: record, endDate: record, indexedAt: record, returnRate: record, standardDeviation: record, startDate: record>, client: record<alreadyRetired: bool, deceasedAge: int, deceasedDate: record, estateIncomeTaxes: record, governmentPensions: record, maritalOrTaxFilingStatus: record, preRetirementIncomeTaxes: record, retirementAge: int, retirementDate: record, retirementIncomeTaxes: record>, coClient: record<alreadyRetired: bool, deceasedAge: int, deceasedDate: record, estateIncomeTaxes: record, governmentPensions: record, maritalOrTaxFilingStatus: record, preRetirementIncomeTaxes: record, retirementAge: int, retirementDate: record, retirementIncomeTaxes: record>, firstToDieDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, firstToDieMember: string, firstToRetireDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, inflationRate: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, lastToDieDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, lastToDieMember: string, lastToRetireDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, retirementYearAdjustedIfAlreadyRetired: record<raw: int>, splitSurplusSavingsStrategiesEnabled: bool, taxMethod: string>, links: table<href: string, rel: string>>
# operationId: Assumptions_GetByPlanid
export def "assumptions-get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Assumptions"
    query: [{name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve business entities
#
# GET /api/BusinessEntities
# Returns: record<businessEntities: table<activities: list, assetId: record, businessType: string, businessTypeFormatted: string, currentAnnualDistributions: record, currentAnnualDividends: record, currentAnnualGrowthRate: record, currentAnnualNetIncome: record, entityName: string, liquidationEvent: record, marketValuationDate: record, marketValue: record, owner: string, purchaseAmount: record, purchaseDate: record, standardDeviation: record>, links: table<href: string, rel: string>>
# operationId: BusinessEntities_GetByPlanid
export def "business-entities-get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/BusinessEntities"
    query: [{name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a business entity
#
# GET /api/BusinessEntities/{id}
# Returns: record<businessEntity: record<activities: list<record>, assetId: record<rawId: int>, businessType: string, businessTypeFormatted: string, currentAnnualDistributions: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, currentAnnualDividends: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, currentAnnualGrowthRate: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, currentAnnualNetIncome: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, entityName: string, liquidationEvent: record<firstSaleDate: record, lastSaleDate: record, liquidationType: string, liquidationTypeDescription: string, saleDatesDescription: string>, marketValuationDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, marketValue: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, owner: string, purchaseAmount: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, purchaseDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, standardDeviation: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>>, links: table<href: string, rel: string>>
# operationId: BusinessEntities_GetByIdPlanid
export def "business-entities-get-by-id-planid" [
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
  --accept: string@accept-completer # Response content type
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/BusinessEntities/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    id: $id, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve Monte Carlo results from standalone calc service
#
# GET /api/Calculations/MonteCarlo
# Returns: bool
# operationId: Calculations_GetByPlanid
export def "calculations-get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3). (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/Calculations/MonteCarlo"
    query: [{name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve defined benefit pensions
#
# GET /api/DefinedBenefitPensions
# Returns: record<definedBenefitPensions: table<benefit: record, description: string, isBenefitFormula: bool, isBenefitIntegratedWithCppQpp: bool, isFormulaIntegratedWithCppQpp: bool, owner: string, pensionType: string, percentPayableToSurvivor: record, projectedYearsOfService: int, startDate: record>, links: table<href: string, rel: string>>
# operationId: DefinedBenefitPensions_GetByPlanid
export def "defined-benefit-pensions-get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/DefinedBenefitPensions"
    query: [{name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a definedBenefitPension
#
# GET /api/DefinedBenefitPensions/{id}
# Returns: record<definedBenefitPension: record<benefit: record<enabled: bool, populated: bool, value: record>, description: string, isBenefitFormula: bool, isBenefitIntegratedWithCppQpp: bool, isFormulaIntegratedWithCppQpp: bool, owner: string, pensionType: string, percentPayableToSurvivor: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, projectedYearsOfService: int, startDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>>, links: table<href: string, rel: string>>
# operationId: DefinedBenefitPensions_GetByIdPlanid
export def "defined-benefit-pensions-get-by-id-planid" [
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
  --accept: string@accept-completer # Response content type
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/DefinedBenefitPensions/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    id: $id, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Accepts the EULA
#
# POST /api/Eula/Accept
# operationId: Eula_Accept
export def "eula-accept" [
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
]: nothing -> any {
  http-request {
    method: post
    path: "/api/Eula/Accept"
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve family
#
# GET /api/Family
# Returns: record<family: record<address: record<city: string, combinedCityStateProvince: string, country: string, stateOrProvince: string, stateOrProvinceAbbrev: string, street1: string, street2: string, zipOrPostalCode: string>, client: record<address: record, ageAsOfPlanDate: int, birthdate: record, citizenship: string, email: string, employer: record, gender: record, name: record, ownershipId: string, phone: record>, coClient: record<address: record, ageAsOfPlanDate: int, birthdate: record, citizenship: string, email: string, employer: record, gender: record, name: record, ownershipId: string, phone: record>, dependents: list<record>, headFullNames: string>, links: table<href: string, rel: string>>
# operationId: Family_GetByPlanid
export def "family-get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Family"
    query: [{name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve the adjustments
#
# GET /api/GoalAdjustments/Education/{id}/Adjustments
# Returns: record<adjustedValues: record<duration: float, expensesCovered: float, lumpSumContribution: float, lumpSumDate: string, monthlySavingsContribution: float>, created: string, goalId: int, projectedResults: record<goalId: int, percentCovered: float, projections: list<record>>>
# operationId: GoalAdjustments_GetEducationByIdClientidPlanid
export def "goal-adjustments-get-education-by-id-clientid-planid" [
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
  --accept: string@accept-completer # Response content type
  --client-id: string # Id of the client user for the plan. Required if current session user is an advisor. Ignored for client user sessions.
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/GoalAdjustments/Education/{id}/Adjustments"
    path_params: [{name: id, var: id}]
    query: [{name: clientId, var: client_id}, {name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, client_id: $client_id, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Perform calculations
#
# POST /api/GoalAdjustments/Education/{id}/Calculations
# Returns: record<goalAdjustments: record<adjustedValues: record<duration: float, expensesCovered: float, lumpSumContribution: float, lumpSumDate: string, monthlySavingsContribution: float>, created: string, goalId: int>, projectedResults: record<goalId: int, percentCovered: float, projections: list<record>>>
# operationId: GoalAdjustments_PostEducationByIdGoaladjustmentsPlanid
export def "goal-adjustments-post-education-by-id-goaladjustments-planid" [
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
  --accept: string@accept-completer # Response content type
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3). (required)
  --adjusted-values: record # shape: {duration?: float, expensesCovered?: float, lumpSumContribution?: float, lumpSumDate?: string, monthlySavingsContribution?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/GoalAdjustments/Education/{id}/Calculations"
    path_params: [{name: id, var: id}]
    query: [{name: planId, var: plan_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: adjustedValues, var: adjusted_values}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, plan_id: $plan_id, adjusted_values: $adjusted_values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list of goals with their relevant success rates.
#
# GET /api/GoalAdjustments/GoalSuccessRates
# Returns: record<goalSuccessRateResults: table<description: string, goalId: int, successRate: float>>
# operationId: GoalAdjustments_GetGoalSuccessRatesByClientidPlanid
export def "goal-adjustments-get-goal-success-rates-by-clientid-planid" [
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
  --client-id: string # Id of the client user for the plan. Required if current session user is an advisor. Ignored for client user sessions.
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/GoalAdjustments/GoalSuccessRates"
    query: [{name: clientId, var: client_id}, {name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve the adjustments
#
# GET /api/GoalAdjustments/MajorPurchase/{id}/Adjustments
# Returns: record<adjustedValues: record<lumpSumContribution: float, lumpSumDate: string, monthlySavingsContribution: float, targetDate: string, totalNeed: float>, created: string, goalId: int, projectedResults: record<goalId: int, percentCovered: float, projections: list<record>>>
# operationId: GoalAdjustments_GetMajorPurchaseByIdClientidPlanid
export def "goal-adjustments-get-major-purchase-by-id-clientid-planid" [
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
  --accept: string@accept-completer # Response content type
  --client-id: string # Id of the client user for the plan. Required if current session user is an advisor. Ignored for client user sessions.
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/GoalAdjustments/MajorPurchase/{id}/Adjustments"
    path_params: [{name: id, var: id}]
    query: [{name: clientId, var: client_id}, {name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, client_id: $client_id, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Perform calculations
#
# POST /api/GoalAdjustments/MajorPurchase/{id}/Calculations
# Returns: record<goalAdjustments: record<adjustedValues: record<lumpSumContribution: float, lumpSumDate: string, monthlySavingsContribution: float, targetDate: string, totalNeed: float>, created: string, goalId: int>, projectedResults: record<goalId: int, percentCovered: float, projections: list<record>>>
# operationId: GoalAdjustments_PostMajorPurchaseByIdGoaladjustmentsPlanid
export def "goal-adjustments-post-major-purchase-by-id-goaladjustments-planid" [
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
  --accept: string@accept-completer # Response content type
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3). (required)
  --adjusted-values: record # shape: {lumpSumContribution?: float, lumpSumDate?: string, monthlySavingsContribution?: float, targetDate?: string, totalNeed?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/GoalAdjustments/MajorPurchase/{id}/Calculations"
    path_params: [{name: id, var: id}]
    query: [{name: planId, var: plan_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: adjustedValues, var: adjusted_values}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, plan_id: $plan_id, adjusted_values: $adjusted_values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list of goal adjustment restrictions.
#
# GET /api/GoalAdjustments/Restrictions
# Returns: record<educationRestrictions: table<canChangeDuration: bool, goalId: int>>
# operationId: GoalAdjustments_GetGoalAdjustmentRestrictionsByClientidPlanid
export def "goal-adjustments-get-goal-adjustment-restrictions-by-clientid-planid" [
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
  --client-id: string # Id of the client user for the plan. Required if current session user is an advisor. Ignored for client user sessions.
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/GoalAdjustments/Restrictions"
    query: [{name: clientId, var: client_id}, {name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve the adjustments
#
# GET /api/GoalAdjustments/Retirement/Adjustments
# Returns: record<adjustedValues: record<clientRetirementAge: float, coClientRetirementAge: float, discretionaryExpenseCoverage: float, fixedExpenseCoverage: float, lumpSumContribution: float, lumpSumDate: string, monthlySavingsContribution: float>, created: string, goalId: int, projectedResults: record<goalId: int, percentCovered: float, projections: list<record>>>
# operationId: GoalAdjustments_GetRetirementByClientidPlanid
export def "goal-adjustments-get-retirement-by-clientid-planid" [
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
  --client-id: string # Id of the client user for the plan. Required if current session user is an advisor. Ignored for client user sessions.
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/GoalAdjustments/Retirement/Adjustments"
    query: [{name: clientId, var: client_id}, {name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Perform calculations
#
# POST /api/GoalAdjustments/Retirement/Calculations
# Returns: record<goalAdjustments: record<adjustedValues: record<clientRetirementAge: float, coClientRetirementAge: float, discretionaryExpenseCoverage: float, fixedExpenseCoverage: float, lumpSumContribution: float, lumpSumDate: string, monthlySavingsContribution: float>, created: string, goalId: int>, projectedResults: record<goalId: int, percentCovered: float, projections: list<record>>>
# operationId: GoalAdjustments_PostRetirementByGoaladjustmentsPlanid
export def "goal-adjustments-post-retirement-by-goaladjustments-planid" [
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
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3). (required)
  --adjusted-values: record # shape: {clientRetirementAge?: float, coClientRetirementAge?: float, discretionaryExpenseCoverage?: float, fixedExpenseCoverage?: float, lumpSumContribution?: float, lumpSumDate?: string, monthlySavingsContribution?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/GoalAdjustments/Retirement/Calculations"
    query: [{name: planId, var: plan_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: adjustedValues, var: adjusted_values}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    plan_id: $plan_id, adjusted_values: $adjusted_values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns WAMO values for current goal
#
# GET /api/GoalAdjustments/{id}/WhatAreMyOptions
# Returns: record<additionalMonthlySavings: float, clientRetirementAge: int, clientRetirementAgeDate: string, coClientRetirementAge: int, coClientRetirementAgeDate: string, expenseCoverageDollars: float, expenseCoveragePercentage: float, lumpSumSavings: float, purchaseDate: string>
# operationId: GoalAdjustments_GetWhatAreMyOptionsByIdClientidPlanid
export def "goal-adjustments-get-what-are-my-options-by-id-clientid-planid" [
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
  --accept: string@accept-completer # Response content type
  --client-id: string # Id of the client user for the plan. Required if current session user is an advisor. Ignored for client user sessions.
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/GoalAdjustments/{id}/WhatAreMyOptions"
    path_params: [{name: id, var: id}]
    query: [{name: clientId, var: client_id}, {name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, client_id: $client_id, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve goals
#
# GET /api/Goals
# Returns: record<goals: table<assetsRemainingAfterFundingGoal: record, coverage: record, description: string, endDate: record, identifier: record, startDate: record, type: string, yearAssetsDepleted: record>, links: table<href: string, rel: string>>
# operationId: Goals_GetByPlanid
export def "goals-get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Goals"
    query: [{name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve goals
#
# GET /api/Goals/{id}
# Returns: record<goal: record<assetsRemainingAfterFundingGoal: record<enabled: bool, populated: bool, value: record>, coverage: record<enabled: bool, populated: bool, value: record>, description: string, endDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, identifier: record<id: int>, startDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, type: string, yearAssetsDepleted: record<enabled: bool, populated: bool, value: record>>, links: table<href: string, rel: string>>
# operationId: Goals_GetByIdPlanid
export def "goals-get-by-id-planid" [
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
  --accept: string@accept-completer # Response content type
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Goals/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    id: $id, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve holding companies
#
# GET /api/HoldingCompanies
# Returns: record<holdingCompanies: table<annualDividendYield: record, ccpc: record, commonSharesOutstanding: int, contributions: record, corporateYearEnd: record, description: string, dividendType: string, dividendTypeFormatted: string, estateDetails: record, historicalData: record, id: string, investmentAccounts: list, liabilities: list, lifeInsurancePolicies: list, marketValue: record, numPreferredShareClasses: int, otherAssets: list, ownershipAsOfDate: record, ownershipDetails: record, preferredSharesOutstanding: int, provinceOfIncorporation: string, provinceOfTaxation: string, realEstateAssets: list, valueOfAllCommonShares: record, valueOfAllPreferredShares: record, withdrawals: record>, links: table<href: string, rel: string>>
# operationId: HoldingCompanies_GetByPlanid
export def "holding-companies-get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/HoldingCompanies"
    query: [{name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a holding company
#
# GET /api/HoldingCompanies/{id}
# Returns: record<holdingCompany: record<annualDividendYield: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, ccpc: record<rawValue: bool, valueAsYesNo: string>, commonSharesOutstanding: int, contributions: record<interCompanyDividendsReceived: list, sharePurchases: list, shareholderLoans: list>, corporateYearEnd: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, description: string, dividendType: string, dividendTypeFormatted: string, estateDetails: record<enableFiftyPercentSolution: record, estateFreeze: record, estateFreezeDate: record, shareOptionsAtFirstDeath: string, shareOptionsAtSecondDeathAndDeathInTheSameYear: string>, historicalData: record<generalSetups: record, notionalAccounts: record, outstandingShareholderLoans: record>, id: string, investmentAccounts: list<record>, liabilities: list<record>, lifeInsurancePolicies: list<record>, marketValue: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, numPreferredShareClasses: int, otherAssets: list<record>, ownershipAsOfDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, ownershipDetails: record<common: list, commonSharesDetails: list, preferred: list, preferredSharesDetails: list, shareholderPercentOwnership: list>, preferredSharesOutstanding: int, provinceOfIncorporation: string, provinceOfTaxation: string, realEstateAssets: list<record>, valueOfAllCommonShares: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, valueOfAllPreferredShares: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, withdrawals: record<loanRepaymentsToShareholder: list, manualDividendDistributions: list, shareRedemptions: list>>, links: table<href: string, rel: string>>
# operationId: HoldingCompanies_GetByIdPlanid
export def "holding-companies-get-by-id-planid" [
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
  --accept: string@accept-completer # Response content type
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/HoldingCompanies/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    id: $id, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve all Households associated with the user
#
# GET /api/Households
# Returns: record<households: table<accessiblePlans: list, clientDescription: string, householdId: int>, links: table<href: string, rel: string>>
# operationId: Households_GetByHouseholdid
export def "households-get-by-householdid" [
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
  --household-id: int # The Id of the specific household to retrieve (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Households"
    query: [{name: householdId, var: household_id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    household_id: $household_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve liabilities
#
# GET /api/Liabilities
# Returns: record<liabilities: table<annualPaymentAmount: record, balanceAsOf: record, balanceAsOfPlanDate: record, debtModStrategies: record, description: string, id: string, insuredForDisability: record, insuredForLife: record, interestRate: record, isInterestRateVariable: record, isPaymentVariable: record, linkedAssetId: string, linkedAssetName: string, loanDate: record, originalBalance: record, owner: string, paidOffByRetirement: record, payOffDate: record, payOffOptionType: record, paymentAmount: record, paymentFrequency: record, paymentType: record, type: record>, links: table<href: string, rel: string>>
# operationId: Liabilities_GetByPlanid
export def "liabilities-get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Liabilities"
    query: [{name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a liability
#
# GET /api/Liabilities/{id}
# Returns: record<liability: record<annualPaymentAmount: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, balanceAsOf: record<date: record, formattedDecimal: string, formattedNoDecimal: string, raw: float>, balanceAsOfPlanDate: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, debtModStrategies: record<lumpSumDebtModStrategies: list, periodicDebtModStrategies: list>, description: string, id: string, insuredForDisability: record<rawValue: bool, valueAsYesNo: string>, insuredForLife: record<rawValue: bool, valueAsYesNo: string>, interestRate: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, isInterestRateVariable: record<rawValue: bool, valueAsYesNo: string>, isPaymentVariable: record<rawValue: bool, valueAsYesNo: string>, linkedAssetId: string, linkedAssetName: string, loanDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, originalBalance: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, owner: string, paidOffByRetirement: record<enabled: bool, populated: bool, value: record>, payOffDate: record<enabled: bool, populated: bool, value: record>, payOffOptionType: record<value: string>, paymentAmount: record<enabled: bool, populated: bool, value: record>, paymentFrequency: record<value: string>, paymentType: record<value: string>, type: record<value: string>>, links: table<href: string, rel: string>>
# operationId: Liabilities_GetByIdPlanid
export def "liabilities-get-by-id-planid" [
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
  --accept: string@accept-completer # Response content type
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Liabilities/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    id: $id, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve lifestyle assets
#
# GET /api/LifestyleAssets
# Returns: record<lifestyleAssets: table<afterTaxProceedsAccountName: string, description: string, futureValueProjectedGrossSaleValue: record, id: string, isMajorPurchaseGoal: bool, marketValueAsOf: record, owner: string, preTaxGrowthRate: record, presentValueProjectedGrossSaleValue: record, projectedSaleDate: record, purchaseAmount: record, purchaseDate: record, sellingCostPercent: record, standardDeviation: record, type: record>, links: table<href: string, rel: string>>
# operationId: LifestyleAssets_GetByPlanid
export def "lifestyle-assets-get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/LifestyleAssets"
    query: [{name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve lifestyle assets
#
# GET /api/LifestyleAssets/{id}
# Returns: record<lifestyleAsset: record<afterTaxProceedsAccountName: string, description: string, futureValueProjectedGrossSaleValue: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, id: string, isMajorPurchaseGoal: bool, marketValueAsOf: record<date: record, formattedDecimal: string, formattedNoDecimal: string, raw: float>, owner: string, preTaxGrowthRate: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, presentValueProjectedGrossSaleValue: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, projectedSaleDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, purchaseAmount: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, purchaseDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, sellingCostPercent: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, standardDeviation: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, type: record<formatted: string, value: string>>, links: table<href: string, rel: string>>
# operationId: LifestyleAssets_GetByIdPlanid
export def "lifestyle-assets-get-by-id-planid" [
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
  --accept: string@accept-completer # Response content type
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/LifestyleAssets/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    id: $id, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves all goals from the live plan
#
# GET /api/LivePlan/Goals
# Returns: record<clientDescription: string, clientId: int, goals: table<amount: float, coveragePercentage: float, description: string, endDate: string, id: int, inflationRate: float, owners: list, startDate: string, type: string>, planDescription: string, planLastUpdateTime: string>
# operationId: LivePlan_GetGoalsByClientidPlanid
export def "live-plan-get-goals-by-clientid-planid" [
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
  --client-id: string # Id of the client user for the plan. Required if current session user is an advisor. Ignored for client user sessions.
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/LivePlan/Goals"
    query: [{name: clientId, var: client_id}, {name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a list of funding accounts
#
# GET /api/LivePlan/Goals/Funding
# Returns: record<goals: table<description: string, fundingAccounts: list, goalId: int>>
# operationId: LivePlan_GetGoalFundingListByClientidPlanid
export def "live-plan-get-goal-funding-list-by-clientid-planid" [
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
  --client-id: string # Id of the client user for the plan. Required if current session user is an advisor. Ignored for client user sessions.
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/LivePlan/Goals/Funding"
    query: [{name: clientId, var: client_id}, {name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve WAMO values for a given goal
#
# GET /api/LivePlan/Goals/{id}/WhatAreMyOptions
# Returns: record<additionalMonthlySavings: float, clientRetirementAge: int, clientRetirementAgeDate: string, coClientRetirementAge: int, coClientRetirementAgeDate: string, expenseCoverageDollars: float, expenseCoveragePercentage: float, lumpSumSavings: float, purchaseDate: string>
# operationId: LivePlan_GetWhatAreMyOptionsByIdClientidPlanid
export def "live-plan-get-what-are-my-options-by-id-clientid-planid" [
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
  --accept: string@accept-completer # Response content type
  --client-id: string # Id of the client user for the plan. Required if current session user is an advisor. Ignored for client user sessions.
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/LivePlan/Goals/{id}/WhatAreMyOptions"
    path_params: [{name: id, var: id}]
    query: [{name: clientId, var: client_id}, {name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, client_id: $client_id, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves accounts for a given plan
#
# GET /api/LivePlan/NetWorth/Accounts
# Returns: record<accounts: table<description: string, holdings: list, id: int, legacyId: string, owner: record, type: int>>
# operationId: LivePlan_GetAccountsByClientidPlanid
export def "live-plan-get-accounts-by-clientid-planid" [
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
  --client-id: string # Id of the client user for the plan. Required if current session user is an advisor. Ignored for client user sessions.
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/LivePlan/NetWorth/Accounts"
    query: [{name: clientId, var: client_id}, {name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves liabilities for a given plan
#
# GET /api/LivePlan/NetWorth/Liabilities
# Returns: record<liabilities: table<description: string, endDate: string, id: int, legacyId: string, outstandingPrincipal: float, outstandingPrincipalAsOfDate: string, owner: record, startDate: string, type: int>>
# operationId: LivePlan_GetLiabilitiesByClientidPlanid
export def "live-plan-get-liabilities-by-clientid-planid" [
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
  --client-id: string # Id of the client user for the plan. Required if current session user is an advisor. Ignored for client user sessions.
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/LivePlan/NetWorth/Liabilities"
    query: [{name: clientId, var: client_id}, {name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves lifestyle assets for a given plan
#
# GET /api/LivePlan/NetWorth/LifestyleAssets
# Returns: record<lifestyleAssets: table<description: string, id: int, owner: record, purchaseDate: string, purchaseValue: float, type: int, valuationDate: string, valuationValue: float>>
# operationId: LivePlan_GetLifestyleAssetsByClientidPlanid
export def "live-plan-get-lifestyle-assets-by-clientid-planid" [
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
  --client-id: string # Id of the client user for the plan. Required if current session user is an advisor. Ignored for client user sessions.
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/LivePlan/NetWorth/LifestyleAssets"
    query: [{name: clientId, var: client_id}, {name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves real estate accounts for a given plan
#
# GET /api/LivePlan/NetWorth/RealEstate
# Returns: record<realEstateAssets: table<description: string, id: int, legacyId: string, marketValue: float, owner: record, purchaseAmount: float, purchaseDate: string, valuationDate: string>>
# operationId: LivePlan_GetRealEstateAssetsByClientidPlanid
export def "live-plan-get-real-estate-assets-by-clientid-planid" [
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
  --client-id: string # Id of the client user for the plan. Required if current session user is an advisor. Ignored for client user sessions.
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/LivePlan/NetWorth/RealEstate"
    query: [{name: clientId, var: client_id}, {name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves net worth projections
#
# GET /api/LivePlan/Projections/NetWorth
# Returns: record<netWorthProjections: table<endOfYearRetirementAssets: float, endOfYearTotalAssets: float, year: int>>
# operationId: LivePlan_GetProjectedNetWorthByClientidPlanid
export def "live-plan-get-projected-net-worth-by-clientid-planid" [
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
  --client-id: string # Id of the client user for the plan. Required if current session user is an advisor. Ignored for client user sessions.
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/LivePlan/Projections/NetWorth"
    query: [{name: clientId, var: client_id}, {name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves needs vs abilities projections
#
# GET /api/LivePlan/Projections/{id}/NeedsVsAbilities
# Returns: record<goalId: int, percentCovered: float, projections: table<projectedAbilities: float, projectedNeed: float, year: int>>
# operationId: LivePlan_GetProjectedNeedsVsAbilitiesByIdClientidPlanid
export def "live-plan-get-projected-needs-vs-abilities-by-id-clientid-planid" [
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
  --accept: string@accept-completer # Response content type
  --client-id: string # Id of the client user for the plan. Required if current session user is an advisor. Ignored for client user sessions.
  --plan-id: string # Id of the Plan to retrieve or update data for (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/LivePlan/Projections/{id}/NeedsVsAbilities"
    path_params: [{name: id, var: id}]
    query: [{name: clientId, var: client_id}, {name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, client_id: $client_id, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve net worth
#
# GET /api/NetWorth
# Returns: record<links: table<href: string, rel: string>, netWorth: record<netWorthAtPlanDate: record<assets: record, assetsFundingRetirement: record, clientNetWorth: record, coClientNetWorth: record, communityPropertyNetWorth: record, jointNetWorth: record, liabilities: record, totalNetWorth: record>, netWorthAtPlanEnd: record<enabled: bool, populated: bool, value: record>, netWorthAtRetirement: record<enabled: bool, populated: bool, value: record>>>
# operationId: NetWorth_GetByPlanid
export def "net-worth-get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/NetWorth"
    query: [{name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Determines if the currently logged in user has set their own password
#
# POST /api/Password/HasUserSetPassword
# operationId: Password_HasUserSetPassword
export def "password-has-user-set-password" [
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
]: nothing -> any {
  http-request {
    method: post
    path: "/api/Password/HasUserSetPassword"
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the password complexity requirements
#
# GET /api/Password/PasswordRequirements
# operationId: Password_PasswordRequirements
export def "password-password-requirements" [
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
]: nothing -> any {
  http-request {
    method: get
    path: "/api/Password/PasswordRequirements"
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Resets the password for the supplied user name
#
# POST /api/Password/Reset
# operationId: Password_ResetByModel
export def "password-reset-by-model" [
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
  locale: string # Supported locales are: "en-US", "en-CA", and "fr-CA"
  user_name: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/Password/Reset"
    body: {content_type: "application/json", kind: json, fields: [{name: locale, var: locale}, {name: userName, var: user_name}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    locale: $locale, user_name: $user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Sets the password for the currently logged in user
#
# POST /api/Password/Set
# operationId: Password_SetByModel
export def "password-set-by-model" [
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
  --new-password: string
  --old-password: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/Password/Set"
    body: {content_type: "application/json", kind: json, fields: [{name: newPassword, var: new_password}, {name: oldPassword, var: old_password}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    new_password: $new_password, old_password: $old_password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve plan information
#
# GET /api/PlanInformation
# Returns: record<country: string, description: string, isJointAnalysis: bool, links: table<href: string, rel: string>, locale: string, planDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, planDescription: string, planId: string, planLevel: string, planModules: record<isCriticalIllnessModuleEnabled: bool, isDisabilityIncomeModuleEnabled: bool, isEstatePlanningModuleEabled: bool, isLongTermCareModuleEnabled: bool, isSurvivorIncomeModuleEnabled: bool>, planType: string, publishDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>>
# operationId: PlanInformation_GetByPlanid
export def "plan-information-get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/PlanInformation"
    query: [{name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve plan data statuses
#
# GET /api/PlanStatuses
# Returns: record<hasIntegratedAccounts: string, links: table<href: string, rel: string>, planDataStatus: string, serializedDataStatus: string>
# operationId: PlanStatuses_GetByPlanid
export def "plan-statuses-get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3) (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/PlanStatuses"
    query: [{name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve portfolio accounts
#
# GET /api/PortfolioAccounts
# Returns: record<links: table<href: string, rel: string>, portfolioAccounts: table<accountReturnRatesNoLongerCorrelateToAssumedAssetMixDueToOverrideInGsm: bool, annualFee: record, applicableRangeRetirementLiquidatedAssets: record, costBasis: record, description: string, descriptionWithOwner: string, excludeInAA: bool, holdings: list, id: string, isSystemGenerated: bool, marketValue: record, owner: string, portfolioAssets: list, rateOfReturn: record, savingsStrategies: record, seppRedemptionStrategy: record, type: string, valuationDate: record>>
# operationId: PortfolioAccounts_GetByPlanid
export def "portfolio-accounts-get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/PortfolioAccounts"
    query: [{name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a portfolio account
#
# GET /api/PortfolioAccounts/{id}
# Returns: record<links: table<href: string, rel: string>, portfolioAccount: record<accountReturnRatesNoLongerCorrelateToAssumedAssetMixDueToOverrideInGsm: bool, annualFee: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, applicableRangeRetirementLiquidatedAssets: record<endDate: record, startDate: record>, costBasis: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, description: string, descriptionWithOwner: string, excludeInAA: bool, holdings: list<record>, id: string, isSystemGenerated: bool, marketValue: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, owner: string, portfolioAssets: list<record>, rateOfReturn: record<preRetirement: record, retirement: record>, savingsStrategies: record<lumpSumSavingsStrategies: list, periodicSavingsStrategies: list, rrspMaximizerStrategies: list, surplusSavingsStrategies: list>, seppRedemptionStrategy: record<applicableDateRange: record, distributionMethod: record, lifeExpectancyTable: record, redemptionFrequency: record>, type: string, valuationDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>>>
# operationId: PortfolioAccounts_GetByIdPlanid
export def "portfolio-accounts-get-by-id-planid" [
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
  --accept: string@accept-completer # Response content type
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/PortfolioAccounts/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    id: $id, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve projected annual summaries
#
# GET /api/ProjectedAnnualSummary
# Returns: record<links: table<href: string, rel: string>, projections: table<annualSummary: record, links: list>>
# operationId: ProjectedAnnualSummary_GetByPlanid
export def "projected-annual-summary-get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/ProjectedAnnualSummary"
    query: [{name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve projected annual summary by id
#
# GET /api/ProjectedAnnualSummary/{id}
# Returns: record<annualSummary: record<cashFlow: record<surplusDeficit: float, totalIncome: float, totalOutflowsWithTaxes: float, totalOutflowsWithoutTaxes: float, totalTaxes: float>, clientAge: int, coClientAge: int, netWorth: record<totalAssets: float, totalLiabilities: float, totalNetWorth: float>, year: int>, links: table<href: string, rel: string>>
# operationId: ProjectedAnnualSummary_GetByIdPlanid
export def "projected-annual-summary-get-by-id-planid" [
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
  --accept: string@accept-completer # Response content type
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/ProjectedAnnualSummary/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    id: $id, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve projected cash flow
#
# GET /api/ProjectedCashFlow
# Returns: record<links: table<href: string, rel: string>, projections: table<cashFlow: record, links: list>>
# operationId: ProjectedCashFlow_GetByPlanid
export def "projected-cash-flow-get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/ProjectedCashFlow"
    query: [{name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve projected cash flow by id
#
# GET /api/ProjectedCashFlow/{id}
# Returns: record<cashFlow: record<cashFlow: record<clientCashFlow: record, coClientCashFlow: record, totalCashFlow: record>, clientAge: int, coClientAge: int, year: int>, links: table<href: string, rel: string>>
# operationId: ProjectedCashFlow_GetByIdPlanid
export def "projected-cash-flow-get-by-id-planid" [
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
  --accept: string@accept-completer # Response content type
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/ProjectedCashFlow/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    id: $id, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve assets funding goals over time
#
# GET /api/ProjectedGoals/AssetsFundingGoals
# Returns: record<links: table<href: string, rel: string>, projections: table<clientAge: int, coClientAge: int, goals: list, year: int>>
# operationId: ProjectedGoals_GetAssetsFundingGoalsByPlanid
export def "projected-goals-get-assets-funding-goals-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/ProjectedGoals/AssetsFundingGoals"
    query: [{name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve needs vs abilities data
#
# GET /api/ProjectedGoals/NeedsVsAbilities
# Returns: record<links: table<href: string, rel: string>, projections: table<clientAge: int, coClientAge: int, goals: list, year: int>>
# operationId: ProjectedGoals_GetNeedsVsAbilitiesByPlanid
export def "projected-goals-get-needs-vs-abilities-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/ProjectedGoals/NeedsVsAbilities"
    query: [{name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve projected net worth
#
# GET /api/ProjectedNetWorth
# Returns: record<links: table<href: string, rel: string>, projections: table<links: list, netWorth: record>>
# operationId: ProjectedNetWorth_GetByPlanid
export def "projected-net-worth-get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/ProjectedNetWorth"
    query: [{name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve projected net worth by id
#
# GET /api/ProjectedNetWorth/{id}
# Returns: record<links: table<href: string, rel: string>, netWorth: record<clientAge: int, coClientAge: int, endOfYearNetWorth: record<assets: record, assetsFundingRetirement: record, clientNetWorth: record, coClientNetWorth: record, communityPropertyNetWorth: record, jointNetWorth: record, liabilities: record, totalNetWorth: record>, year: int>>
# operationId: ProjectedNetWorth_GetByIdPlanid
export def "projected-net-worth-get-by-id-planid" [
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
  --accept: string@accept-completer # Response content type
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/ProjectedNetWorth/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    id: $id, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve restricted stocks
#
# GET /api/RestrictedStocks
# Returns: record<links: table<href: string, rel: string>, restrictedStocks: table<annualDividendPerUnit: record, applicableRangeRetirementLiquidatedAssets: record, awardedDate: record, currentUnitValue: record, description: string, growthRate: record, id: string, numberOfUnits: int, owner: string, pricePaidForAward: record, type: string>>
# operationId: RestrictedStocks_GetByPlanid
export def "restricted-stocks-get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/RestrictedStocks"
    query: [{name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a restricted stock
#
# GET /api/RestrictedStocks/{id}
# Returns: record<links: table<href: string, rel: string>, restrictedStock: record<annualDividendPerUnit: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, applicableRangeRetirementLiquidatedAssets: record<endDate: record, startDate: record>, awardedDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, currentUnitValue: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, description: string, growthRate: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, id: string, numberOfUnits: int, owner: string, pricePaidForAward: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, type: string>>
# operationId: RestrictedStocks_GetByIdPlanid
export def "restricted-stocks-get-by-id-planid" [
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
  --accept: string@accept-completer # Response content type
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/RestrictedStocks/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    id: $id, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# This resource can be used to check the status of the service.
#
# GET /api/ServiceInformation/Statistics
# Returns: record<altairConnectionStatus: bool, name: string, pomVersion: string, serviceVersion: string, status: string>
# operationId: ServiceInformation_Statistics
export def "service-information-statistics" [
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
    path: "/api/ServiceInformation/Statistics"
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve stock options
#
# GET /api/StockOptions
# Returns: record<links: table<href: string, rel: string>, stockOptions: table<annualDividendPerUnit: record, applicableRangeRetirementLiquidatedAssets: record, company: string, currentUnitPrice: record, currentUnitPriceDate: record, description: string, endOfPlanYearExercisableGrossValue: record, exerciseCost: record, expirationDate: record, grantDate: record, grantedOptions: int, growthRate: record, id: string, optionsExercisable: int, optionsExercised: int, optionsVested: int, owner: string, preTaxProfit: record, startOfYearAMTBasis: record, startOfYearCostBasis: record, startOfYearUnitPrice: record, strikePrice: record, symbol: string, type: string, typeFormatted: string, vestingSchedule: list>>
# operationId: StockOptions_GetByPlanid
export def "stock-options-get-by-planid" [
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
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/StockOptions"
    query: [{name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a stock option
#
# GET /api/StockOptions/{id}
# Returns: record<links: table<href: string, rel: string>, stockOption: record<annualDividendPerUnit: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, applicableRangeRetirementLiquidatedAssets: record<endDate: record, startDate: record>, company: string, currentUnitPrice: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, currentUnitPriceDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, description: string, endOfPlanYearExercisableGrossValue: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, exerciseCost: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, expirationDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, grantDate: record<day: int, formatted: string, formattedMMMMddyyyy: string, formattedMMMdd: string, formattedMMMddyyyy: string, formattedMMMyyyy: string, formattedNA: string, month: int, toDateTime: string, urlEncoded: string, year: int>, grantedOptions: int, growthRate: record<formattedDoubleDecimal: string, formattedNoDecimal: string, formattedSingleDecimal: string, raw: float, rawCappedAt100: float>, id: string, optionsExercisable: int, optionsExercised: int, optionsVested: int, owner: string, preTaxProfit: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, startOfYearAMTBasis: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, startOfYearCostBasis: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, startOfYearUnitPrice: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, strikePrice: record<formattedDecimal: string, formattedNoDecimal: string, raw: float>, symbol: string, type: string, typeFormatted: string, vestingSchedule: list<record>>>
# operationId: StockOptions_GetByIdPlanid
export def "stock-options-get-by-id-planid" [
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
  --accept: string@accept-completer # Response content type
  --plan-id: string # Id of the plan to retrieve data from (e.g. 1001-11-3). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/StockOptions/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: planId, var: plan_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    id: $id, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Start a session with the DomainProviders user store
#
# POST /api/auth/Login
# Returns: record<eulaAccepted: bool, hasAccountAggregation: bool, hasGoalWhatIfing: bool, hasUserSetPassword: bool, isAdmin: bool, isAdvisor: bool, isClient: bool, isPasswordExpired: bool, userId: string, userName: string>
# operationId: Auth_LoginByModel
export def "auth-login-by-model" [
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
  --password: string
  --username: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/auth/Login"
    body: {content_type: "application/json", kind: json, fields: [{name: password, var: password}, {name: username, var: username}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    password: $password, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the login rules
#
# GET /api/auth/LoginConfiguration
# operationId: Auth_PasswordRequirements
export def "auth-password-requirements" [
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
]: nothing -> any {
  http-request {
    method: get
    path: "/api/auth/LoginConfiguration"
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/auth/Logout
#
# operationId: Auth_Logout
export def "auth-logout" [
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
]: nothing -> any {
  http-request {
    method: post
    path: "/api/auth/Logout"
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Validate and extend the duration of a session
#
# POST /api/auth/ResumeSession
# Returns: record<eulaAccepted: bool, hasAccountAggregation: bool, hasGoalWhatIfing: bool, hasUserSetPassword: bool, isAdmin: bool, isAdvisor: bool, isClient: bool, isPasswordExpired: bool, userId: string, userName: string>
# operationId: Auth_ResumeSession
export def "auth-resume-session" [
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
    method: post
    path: "/api/auth/ResumeSession"
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
