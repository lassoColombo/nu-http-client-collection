# Auto-generated client for VisageCloud v1.1
# Source: https://api.apis.guru/v2/specs/visagecloud.com/1.1/swagger.json
# Auth: --token flag or $env.VISAGECLOUD_TOKEN

const CLIENT = {
  base_url: "https://visagecloud.com"
  token_env_var: "VISAGECLOUD_TOKEN"
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

def base-url-completer [] { ["https://visagecloud.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def algorithm-version-completer [] { ["V1" "V2"] }
def attribute-filters-completer [] { ["AGE_GROUP_FILTER" "GENDER_FILTER" "NO_FILTER"] }
def purposes-completer [] { ["ATTRIBUTES" "FEATURES" "LANDMARKS"] }
def method-completer [] { ["INGESTION_ENDPOINT" "WEBRTC_PULL" "WEBRTC_PUSH"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-account-by-access-key-using-get: "record<message: string, payload: record, status: string>"
    get-billing-per-account-using-get: "record<message: string, payload: record, status: string>"
    change-password-using-post: "record<message: string, payload: record, status: string>"
    login-with-email-using-post: "record<message: string, payload: record, status: string>"
    compare-faces-using-get: "record<message: string, payload: record, status: string>"
    perform-analysis-using-post: "record<message: string, payload: record, status: string>"
    retrive-latest-using-get: "record<message: string, payload: record, status: string>"
    perform-recognition-using-post: "record<message: string, payload: record, status: string>"
    retrieve-analysis-using-get: "record<message: string, payload: record, status: string>"
    counter-using-post: "record<message: string, payload: record, status: string>"
    presence-timeseries-using-post: "record<message: string, payload: record, status: string>"
    presence-total-using-post: "record<message: string, payload: record, status: string>"
    remove-classifer-using-delete: "record<message: string, payload: record, status: string>"
    get-classifer-full-using-get: "record<message: string, payload: record, status: string>"
    add-svm-classifier-using-post: "record<message: string, payload: record, status: string>"
    get-classifer-status-using-get: "record<message: string, payload: record, status: string>"
    get-all-collections-using-get: "record<message: string, payload: record, status: string>"
    add-collection-using-post: "record<message: string, payload: record, status: string>"
    get-all-collections2-using-get: "record<message: string, payload: record, status: string>"
    delete-collection2-using-delete: "record<message: string, payload: record, status: string>"
    get-collection2-using-get: "record<message: string, payload: record, status: string>"
    add-collection2-using-post: "record<message: string, payload: record, status: string>"
    export-csv-using-get: "record"
    repurpose-collection-using-put: "record<message: string, payload: record, status: string>"
    delete-collection-using-delete: "record<message: string, payload: record, status: string>"
    get-collection-using-get: "record<message: string, payload: record, status: string>"
    update-collection-using-patch: "record<message: string, payload: record, status: string>"
    update-collection2-using-post: "record<message: string, payload: record, status: string>"
    get-all-collection-profiles-using-get: "record<message: string, payload: record, status: string>"
    remove-classification-attributes-from-profile-using-delete: "record<message: string, payload: record, status: string>"
    get-classification-attributes-from-profile-using-get: "record<message: string, payload: record, status: string>"
    map-classification-attributes-to-profile-using-put: "record<message: string, payload: record, status: string>"
    get-profile-enrollment-status-using-get: "record<message: string, payload: record, status: string>"
    remove-faces-from-profile-using-delete: "record<message: string, payload: record, status: string>"
    get-faces-from-profile-using-get: "record<message: string, payload: record, status: string>"
    map-faces-to-profile-using-post: "record<message: string, payload: record, status: string>"
    delete-profile2-using-delete: "record<message: string, payload: record, status: string>"
    add-profile-using-post: "record<message: string, payload: record, status: string>"
    delete-profile-using-delete: "record<message: string, payload: record, status: string>"
    get-profile-using-get: "record<message: string, payload: record, status: string>"
    update-profile-using-patch: "record<message: string, payload: record, status: string>"
    streams-by-account-using-get: "record<message: string, payload: record, status: string>"
    get-last-n-attedance-using-get: "record<message: string, payload: record, status: string>"
    cleanup-stream-using-patch: "record<message: string, payload: record, status: string>"
    get-frame-image-using-get: "list<string>"
    get-last-n-frames-using-get: "record<message: string, payload: record, status: string>"
    start-stream-using-patch: "record<message: string, payload: record, status: string>"
    stop-stream-using-patch: "record<message: string, payload: record, status: string>"
    add-stream-using-post: "record<message: string, payload: record, status: string>"
    remove-stream-using-delete: "record<message: string, payload: record, status: string>"
    get-stream-using-get: "record<message: string, payload: record, status: string>"
    update-stream-using-patch: "record<message: string, payload: record, status: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-account-by-access-key-using-get" "get-billing-per-account-using-get" "change-password-using-post" "login-with-email-using-post" "compare-faces-using-get" "perform-analysis-using-post" "retrive-latest-using-get" "perform-recognition-using-post" "retrieve-analysis-using-get" "counter-using-post" "presence-timeseries-using-post" "presence-total-using-post" "remove-classifer-using-delete" "get-classifer-full-using-get" "add-svm-classifier-using-post" "get-classifer-status-using-get" "get-all-collections-using-get" "add-collection-using-post" "get-all-collections2-using-get" "delete-collection2-using-delete" "get-collection2-using-get" "add-collection2-using-post" "export-csv-using-get" "repurpose-collection-using-put" "delete-collection-using-delete" "get-collection-using-get" "update-collection-using-patch" "update-collection2-using-post" "get-all-collection-profiles-using-get" "remove-classification-attributes-from-profile-using-delete" "get-classification-attributes-from-profile-using-get" "map-classification-attributes-to-profile-using-put" "get-profile-enrollment-status-using-get" "remove-faces-from-profile-using-delete" "get-faces-from-profile-using-get" "map-faces-to-profile-using-post" "delete-profile2-using-delete" "add-profile-using-post" "delete-profile-using-delete" "get-profile-using-get" "update-profile-using-patch" "streams-by-account-using-get" "get-last-n-attedance-using-get" "cleanup-stream-using-patch" "get-frame-image-using-get" "get-last-n-frames-using-get" "start-stream-using-patch" "stop-stream-using-patch" "add-stream-using-post" "remove-stream-using-delete" "get-stream-using-get" "update-stream-using-patch" "commands"] | sort) } | get name | first)
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

# Get account information by accessKey and secretKey
#
# GET /rest/v1.1/account/account
# Returns: record<message: string, payload: record, status: string>
# operationId: getAccountByAccessKeyUsingGET
export def "get-account-by-access-key-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # accessKey (required)
  --secret-key: string # secretKey (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest/v1.1/account/account"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get billing information by accessKey and secretKey
#
# GET /rest/v1.1/account/billing
# Returns: record<message: string, payload: record, status: string>
# operationId: getBillingPerAccountUsingGET
export def "get-billing-per-account-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # accessKey (required)
  --secret-key: string # secretKey (required)
  --start-date-time: string # startDateTime (format: date-time)
  --end-date-time: string # endDateTime (format: date-time)
  --date-template: string # dateTemplate
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest/v1.1/account/billing"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: startDateTime, var: start_date_time}, {name: endDateTime, var: end_date_time}, {name: dateTemplate, var: date_template}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, start_date_time: $start_date_time, end_date_time: $end_date_time, date_template: $date_template
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change password for an account using old password
#
# POST /rest/v1.1/account/changePassword
# Returns: record<message: string, payload: record, status: string>
# operationId: changePasswordUsingPOST
export def "change-password-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # email (required)
  --old-password: string # oldPassword (required)
  --new-password: string # newPassword (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/rest/v1.1/account/changePassword"
    query: [{name: email, var: email, required: true}, {name: oldPassword, var: old_password, required: true}, {name: newPassword, var: new_password, required: true}]
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    email: $email, old_password: $old_password, new_password: $new_password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get account information including accessKey and secretKey by email and password
#
# POST /rest/v1.1/account/login
# Returns: record<message: string, payload: record, status: string>
# operationId: loginWithEmailUsingPOST
export def "login-with-email-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # email (required)
  --password: string # password (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/rest/v1.1/account/login"
    query: [{name: email, var: email, required: true}, {name: password, var: password, required: true}]
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    email: $email, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Compare several faces identified by faceHash, without depending on mapping faces to profiles
#
# GET /rest/v1.1/analysis/compare
# Returns: record<message: string, payload: record, status: string>
# operationId: compareFacesUsingGET
export def "compare-faces-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud (required)
  --face-hashes: list<string> # The IDs of the faces which you want compared, comma-separated (required)
  --show-details: oneof<nothing, bool> # Show details (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest/v1.1/analysis/compare"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: faceHashes, var: face_hashes, style: multi, required: true}, {name: showDetails, var: show_details}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, face_hashes: $face_hashes, show_details: $show_details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Perform detection on a given picture or picture URL
#
# POST /rest/v1.1/analysis/detection
# Returns: record<message: string, payload: record, status: string>
# operationId: performAnalysisUsingPOST
export def "perform-analysis-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud (required)
  --store-analysis-picture: oneof<nothing, bool> # Boolean value indicating whether you want the picture of the analysis to be stored for later retrieval (default: true)
  --store-face-pictures: oneof<nothing, bool> # Boolean value indicating whether you want the faces inside the picture to be stored for later retrieval (default: true)
  --store-result: oneof<nothing, bool> # Boolean value indicating whether you want the result of the analysis to be stored (default: true)
  --retention-time: int # How many seconds the results should be retained in stoarage? (format: int32)
  --picture-url: string # The URL of the picture, assuming it is served by a third party server. Server should be accesible from the Internet or through another netwoek by VisageCloud infrastructure
  --algorithm-version: string@algorithm-version-completer # Algorithm version (V2 is more performant but not backward compatible) (default: V2)
  --auto-rotate: oneof<nothing, bool> # Auto-rotate to find flipped or rotate faces (default: false)
  --skip-exif: oneof<nothing, bool> # Skip EXIF rotation procesing (default: false)
  --wait-for-picture-upload: oneof<nothing, bool> # Waits until the picture is successfully uploaded, before returning the response back the the client (default: false)
  --filters: list<string> # [For advanced users only] Change feature filters for robustness of feature extraction. Tweaking this parameter may affect per
  --options: string # [For advanced users only] Options for preprocessing of image.
  --picture: string # The multipart/form-data version of the image, in case a direct upload is used. At least one of picture or pictureURL must be present
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rest/v1.1/analysis/detection"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: storeAnalysisPicture, var: store_analysis_picture}, {name: storeFacePictures, var: store_face_pictures}, {name: storeResult, var: store_result}, {name: retentionTime, var: retention_time}, {name: pictureURL, var: picture_url}, {name: algorithmVersion, var: algorithm_version}, {name: autoRotate, var: auto_rotate}, {name: skipEXIF, var: skip_exif}, {name: waitForPictureUpload, var: wait_for_picture_upload}, {name: filters, var: filters, style: multi}, {name: options, var: options}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: picture, var: picture}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, store_analysis_picture: $store_analysis_picture, store_face_pictures: $store_face_pictures, store_result: $store_result, retention_time: $retention_time, picture_url: $picture_url, algorithm_version: $algorithm_version, auto_rotate: $auto_rotate, skip_exif: $skip_exif, wait_for_picture_upload: $wait_for_picture_upload, filters: $filters, options: $options, picture: $picture
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the last *count* operations per current account
#
# GET /rest/v1.1/analysis/listLatest
# Returns: record<message: string, payload: record, status: string>
# operationId: retriveLatestUsingGET
export def "retrive-latest-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud (required)
  --count: int # How many records to retrieve at a time (format: int32, default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest/v1.1/analysis/listLatest"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: count, var: count}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Perform labeled recognition on a given picture or picture URL
#
# POST /rest/v1.1/analysis/recognition
# Returns: record<message: string, payload: record, status: string>
# operationId: performRecognitionUsingPOST
export def "perform-recognition-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud (required)
  --store-analysis-picture: oneof<nothing, bool> # Boolean value indicating whether you want the picture of the analysis to be stored for later retrieval (default: true)
  --store-face-pictures: oneof<nothing, bool> # Boolean value indicating whether you want the faces inside the picture to be stored for later retrieval (default: true)
  --store-result: oneof<nothing, bool> # Boolean value indicating whether you want the result of the analysis to be stored (default: true)
  --retention-time: int # How many seconds the results should be retained in stoarage? (format: int32)
  --collection-id: string # Uniquely identified collection that can store multiple profiles (required)
  --labels: list<string> # Labels associated with the given picture or picture URL
  --attribute-filters: list<string>@attribute-filters-completer # Filters that will be applied on the recognition operation
  --picture-url: string # The URL of the picture
  --algorithm-version: string@algorithm-version-completer # Algorithm version (V2 is more performant but not backward compatible) (default: V2)
  --auto-rotate: oneof<nothing, bool> # Auto-rotate to find flipped or rotate faces (default: false)
  --skip-exif-rotation-processing: oneof<nothing, bool> # Skip EXIF rotation procesing (default: false)
  --wait-for-picture-upload: oneof<nothing, bool> # Waits until the picture is successfully uploaded, before returning the response back the the client (default: false)
  --filters: list<string> # [For advanced users only] Change feature filters for robustness of feature extraction. Tweaking this parameter may affect per
  --options: string # [For advanced users only] Options for preprocessing of image.
  --picture: string # The picture itself
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rest/v1.1/analysis/recognition"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: storeAnalysisPicture, var: store_analysis_picture}, {name: storeFacePictures, var: store_face_pictures}, {name: storeResult, var: store_result}, {name: retentionTime, var: retention_time}, {name: collectionId, var: collection_id, required: true}, {name: labels, var: labels, style: multi}, {name: attributeFilters, var: attribute_filters, style: multi}, {name: pictureURL, var: picture_url}, {name: algorithmVersion, var: algorithm_version}, {name: autoRotate, var: auto_rotate}, {name: "skipEXIF rotation processing", var: skip_exif_rotation_processing}, {name: waitForPictureUpload, var: wait_for_picture_upload}, {name: filters, var: filters, style: multi}, {name: options, var: options}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: picture, var: picture}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, store_analysis_picture: $store_analysis_picture, store_face_pictures: $store_face_pictures, store_result: $store_result, retention_time: $retention_time, collection_id: $collection_id, labels: $labels, attribute_filters: $attribute_filters, picture_url: $picture_url, algorithm_version: $algorithm_version, auto_rotate: $auto_rotate, skip_exif_rotation_processing: $skip_exif_rotation_processing, wait_for_picture_upload: $wait_for_picture_upload, filters: $filters, options: $options, picture: $picture
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a complete analysis object including both detection and recognition information
#
# GET /rest/v1.1/analysis/retrieve
# Returns: record<message: string, payload: record, status: string>
# operationId: retrieveAnalysisUsingGET
export def "retrieve-analysis-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud (required)
  --analysis-id: string # The ID of the analysis for which the data will be retrieved (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest/v1.1/analysis/retrieve"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: analysisId, var: analysis_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, analysis_id: $analysis_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count individuals in streams or collections
#
# POST /rest/v1.1/analytics/counting
# Returns: record<message: string, payload: record, status: string>
# operationId: counterUsingPOST
export def "counter-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud (required)
  --collection-ids: list<string> # Collection ids
  --stream-ids: list<string> # Stream Ids
  --start-date-time: string # startDateTime (format: date-time)
  --end-date-time: string # endDateTime (format: date-time)
  --visit-duration: int # visitDuration (format: int64, default: 3600000)
  --max-iterations: int # maxIterations (format: int32, default: 1)
  --max-batch-iterations: int # maxBatchIterations (format: int32, default: 1)
  --min-neighbors-merged-per-iteration: int # minNeighborsMergedPerIteration (format: int32, default: 5)
  --merging-step: float # mergingStep (format: double, default: 1)
  --shuffling: oneof<nothing, bool> # shuffling (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/rest/v1.1/analytics/counting"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: collectionIds, var: collection_ids, style: multi}, {name: streamIds, var: stream_ids, style: multi}, {name: startDateTime, var: start_date_time}, {name: endDateTime, var: end_date_time}, {name: visitDuration, var: visit_duration}, {name: maxIterations, var: max_iterations}, {name: maxBatchIterations, var: max_batch_iterations}, {name: minNeighborsMergedPerIteration, var: min_neighbors_merged_per_iteration}, {name: mergingStep, var: merging_step}, {name: shuffling, var: shuffling}]
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, collection_ids: $collection_ids, stream_ids: $stream_ids, start_date_time: $start_date_time, end_date_time: $end_date_time, visit_duration: $visit_duration, max_iterations: $max_iterations, max_batch_iterations: $max_batch_iterations, min_neighbors_merged_per_iteration: $min_neighbors_merged_per_iteration, merging_step: $merging_step, shuffling: $shuffling
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show audience (based on number of occurrences of each person) breakdown per declared attribute (age, gender).
#
# POST /rest/v1.1/analytics/presence/timeseries
# Returns: record<message: string, payload: record, status: string>
# operationId: presenceTimeseriesUsingPOST
export def "presence-timeseries-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud (required)
  --stream-ids: list<string> # Stream Ids
  --start-date-time: string # startDateTime (format: date-time)
  --end-date-time: string # endDateTime (format: date-time)
  --step: int # step (format: int64, default: 3600)
  --attributes: list<string> # attributes (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/rest/v1.1/analytics/presence/timeseries"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: streamIds, var: stream_ids, style: multi}, {name: startDateTime, var: start_date_time}, {name: endDateTime, var: end_date_time}, {name: step, var: step}, {name: attributes, var: attributes, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, stream_ids: $stream_ids, start_date_time: $start_date_time, end_date_time: $end_date_time, step: $step, attributes: $attributes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show presence (based on number of occurences of each face) breakdown per declared attribute (age, gender)
#
# POST /rest/v1.1/analytics/presence/total
# Returns: record<message: string, payload: record, status: string>
# operationId: presenceTotalUsingPOST
export def "presence-total-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud (required)
  --stream-ids: list<string> # Stream Ids (required)
  --start-date-time: string # startDateTime (format: date-time)
  --end-date-time: string # endDateTime (format: date-time)
  --attributes: list<string> # attributes (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/rest/v1.1/analytics/presence/total"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: streamIds, var: stream_ids, style: multi, required: true}, {name: startDateTime, var: start_date_time}, {name: endDateTime, var: end_date_time}, {name: attributes, var: attributes, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, stream_ids: $stream_ids, start_date_time: $start_date_time, end_date_time: $end_date_time, attributes: $attributes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete existing classifier
#
# DELETE /rest/v1.1/classifier/svm
# Returns: record<message: string, payload: record, status: string>
# operationId: removeClassiferUsingDELETE
export def "remove-classifer-using-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud (required)
  --id: string # The id of the classifier that will be removed (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/rest/v1.1/classifier/svm"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: id, var: id, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get classifier full
#
# GET /rest/v1.1/classifier/svm
# Returns: record<message: string, payload: record, status: string>
# operationId: getClassiferFullUsingGET
export def "get-classifer-full-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud (required)
  --id: string # The id of the classifier that you want the status for (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest/v1.1/classifier/svm"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: id, var: id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new SVM classifier with given name
#
# POST /rest/v1.1/classifier/svm
# Returns: record<message: string, payload: record, status: string>
# operationId: addSVMClassifierUsingPOST
export def "add-svm-classifier-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud (required)
  --name: string # The name of the SVM classifier that will be created (required)
  --collection-ids: list<string> # Collection ids (required)
  --preprocessor: string # Preprocessor (default: FeaturePreprocessor)
  --classification-attribute-name: string # Classification attribute name (required)
  --consider-view-points: oneof<nothing, bool> # Consider view point (default: false)
  --seed: int # Seed for divididing training and evaluation sets (format: int32, default: 179425537)
  --training-ratio: float # Training ratio (format: double, default: 0.8)
  --probability-parameter: int # Probability parameter (format: int32, default: 1)
  --gamma-parameter: float # Gamma parameter (format: double, default: 0.5)
  --nu-parameter: float # Nu parameter (format: double, default: 0.25)
  --c-parameter: float # c parameter (format: double, default: 1)
  --svm-type-parameter: int # SVM type parameter (format: int32, default: 0)
  --kernel-type-parameter: int # Kernel type parameter (format: int32, default: 0)
  --cache-size-parameter: float # Cache size parameter (format: double, default: 500)
  --eps-parameter: float # Eps parameter (format: double, default: 0.001)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/rest/v1.1/classifier/svm"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: name, var: name, required: true}, {name: collectionIds, var: collection_ids, style: multi, required: true}, {name: preprocessor, var: preprocessor}, {name: classificationAttributeName, var: classification_attribute_name, required: true}, {name: considerViewPoints, var: consider_view_points}, {name: seed, var: seed}, {name: trainingRatio, var: training_ratio}, {name: probabilityParameter, var: probability_parameter}, {name: gammaParameter, var: gamma_parameter}, {name: nuParameter, var: nu_parameter}, {name: cParameter, var: c_parameter}, {name: svmTypeParameter, var: svm_type_parameter}, {name: kernelTypeParameter, var: kernel_type_parameter}, {name: cacheSizeParameter, var: cache_size_parameter}, {name: epsParameter, var: eps_parameter}]
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, name: $name, collection_ids: $collection_ids, preprocessor: $preprocessor, classification_attribute_name: $classification_attribute_name, consider_view_points: $consider_view_points, seed: $seed, training_ratio: $training_ratio, probability_parameter: $probability_parameter, gamma_parameter: $gamma_parameter, nu_parameter: $nu_parameter, c_parameter: $c_parameter, svm_type_parameter: $svm_type_parameter, kernel_type_parameter: $kernel_type_parameter, cache_size_parameter: $cache_size_parameter, eps_parameter: $eps_parameter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get classifer status
#
# GET /rest/v1.1/classifier/svm/status
# Returns: record<message: string, payload: record, status: string>
# operationId: getClassiferStatusUsingGET
export def "get-classifer-status-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud (required)
  --id: string # The id of the classifier that you want the status for (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest/v1.1/classifier/svm/status"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: id, var: id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all collections
#
# GET /rest/v1.1/collection/
# Returns: record<message: string, payload: record, status: string>
# operationId: getAllCollectionsUsingGET
export def "get-all-collections-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest/v1.1/collection/"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new empty collection with given name
#
# POST /rest/v1.1/collection/
# Returns: record<message: string, payload: record, status: string>
# operationId: addCollectionUsingPOST
export def "add-collection-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  access_key: string # The accessKey provided by VisageCloud
  secret_key: string # The secretKey provided by VisageCloud
  name: string # The name of the collection that will be created
  --preload: oneof<nothing, bool> # Defined whether to preload collection
  --evictable: oneof<nothing, bool> # Defined whether the collection can be evicted
  --purposes: list<string>@purposes-completer # The newly declared purposes of the collection
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rest/v1.1/collection/"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: accessKey, var: access_key}, {name: secretKey, var: secret_key}, {name: name, var: name}, {name: preload, var: preload}, {name: evictable, var: evictable}, {name: purposes, var: purposes}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, name: $name, preload: $preload, evictable: $evictable, purposes: $purposes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all collections
#
# GET /rest/v1.1/collection/all
# DEPRECATED
# Returns: record<message: string, payload: record, status: string>
# operationId: getAllCollections2UsingGET
@deprecated
export def "get-all-collections2-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest/v1.1/collection/all"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete existing collection with associated profiles and faces.
#
# DELETE /rest/v1.1/collection/collection
# DEPRECATED
# Returns: record<message: string, payload: record, status: string>
# operationId: deleteCollection2UsingDELETE
@deprecated
export def "delete-collection2-using-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey provided by VisageCloud (required)
  --collection-id: string # The id of the collection that will be removed (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/rest/v1.1/collection/collection"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: collectionId, var: collection_id, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, collection_id: $collection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve existing collection content
#
# GET /rest/v1.1/collection/collection
# DEPRECATED
# Returns: record<message: string, payload: record, status: string>
# operationId: getCollection2UsingGET
@deprecated
export def "get-collection2-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud (required)
  --collection-id: string # The id of the collection for which the data will be retrieved (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest/v1.1/collection/collection"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: collectionId, var: collection_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, collection_id: $collection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new empty collection with given name
#
# POST /rest/v1.1/collection/collection
# DEPRECATED
# Returns: record<message: string, payload: record, status: string>
# operationId: addCollection2UsingPOST
@deprecated
export def "add-collection2-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud (required)
  --collection-name: string # The name of the collection that will be created (required)
  --preload: oneof<nothing, bool> # Defined whether to preload collection (default: false)
  --evictable: oneof<nothing, bool> # Defined whether the collection can be evicted (default: true)
  --purposes: list<string>@purposes-completer # The newly declared purposes of the collection
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/rest/v1.1/collection/collection"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: collectionName, var: collection_name, required: true}, {name: preload, var: preload}, {name: evictable, var: evictable}, {name: purposes, var: purposes, style: multi}]
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, collection_name: $collection_name, preload: $preload, evictable: $evictable, purposes: $purposes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve collection content for data analysis.
#
# GET /rest/v1.1/collection/export/csv
# Returns: record
# operationId: exportCSVUsingGET
export def "export-csv-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud (required)
  --collection-id: string # The id of the collection for which the data will be retrieved (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest/v1.1/collection/export/csv"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: collectionId, var: collection_id, required: true}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, collection_id: $collection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change purpose of existing collection
#
# PUT /rest/v1.1/collection/purpose
# DEPRECATED
# Returns: record<message: string, payload: record, status: string>
# operationId: repurposeCollectionUsingPUT
@deprecated
export def "repurpose-collection-using-put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey provided by VisageCloud (required)
  --collection-id: string # The id of the collection for which the data will be retrieved (required)
  --purposes: list<string>@purposes-completer # The newly declared purposes of the collection (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/rest/v1.1/collection/purpose"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: collectionId, var: collection_id, required: true}, {name: purposes, var: purposes, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, collection_id: $collection_id, purposes: $purposes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete existing collection with associated profiles and faces.
#
# DELETE /rest/v1.1/collection/{id}
# Returns: record<message: string, payload: record, status: string>
# operationId: deleteCollectionUsingDELETE
export def "delete-collection-using-delete" [
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
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey provided by VisageCloud (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/rest/v1.1/collection/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    id: $id, access_key: $access_key, secret_key: $secret_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve existing collection content
#
# GET /rest/v1.1/collection/{id}
# Returns: record<message: string, payload: record, status: string>
# operationId: getCollectionUsingGET
export def "get-collection-using-get" [
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
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest/v1.1/collection/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, access_key: $access_key, secret_key: $secret_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing collection with a given id
#
# PATCH /rest/v1.1/collection/{id}
# Returns: record<message: string, payload: record, status: string>
# operationId: updateCollectionUsingPATCH
export def "update-collection-using-patch" [
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
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey provided by VisageCloud (required)
  --name: string # The name of the collection that will be updated
  --purposes: list<string>@purposes-completer # The newly declared purposes of the collection
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: patch
    path: "/rest/v1.1/collection/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: name, var: name}, {name: purposes, var: purposes, style: multi}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    id: $id, access_key: $access_key, secret_key: $secret_key, name: $name, purposes: $purposes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing collection with a given id
#
# POST /rest/v1.1/collection/{id}
# DEPRECATED
# Returns: record<message: string, payload: record, status: string>
# operationId: updateCollection2UsingPOST
@deprecated
export def "update-collection2-using-post" [
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
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey provided by VisageCloud (required)
  --name: string # The name of the collection that will be updated
  --purposes: list<string>@purposes-completer # The newly declared purposes of the collection
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/rest/v1.1/collection/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: name, var: name}, {name: purposes, var: purposes, style: multi}]
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    id: $id, access_key: $access_key, secret_key: $secret_key, name: $name, purposes: $purposes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all the profiles associated to a collection
#
# GET /rest/v1.1/collection/{id}/profile
# Returns: record<message: string, payload: record, status: string>
# operationId: getAllCollectionProfilesUsingGET
export def "get-all-collection-profiles-using-get" [
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
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest/v1.1/collection/{id}/profile"
    path_params: [{name: id, var: id}]
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, access_key: $access_key, secret_key: $secret_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes classification attributes from a profile
#
# DELETE /rest/v1.1/profile/classificationAttributes
# DEPRECATED
# Returns: record<message: string, payload: record, status: string>
# operationId: removeClassificationAttributesFromProfileUsingDELETE
@deprecated
export def "remove-classification-attributes-from-profile-using-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey provided by VisageCloud (required)
  --profile-id: string # The profile associated with the classification attributes (required)
  --collection-id: string # The collection that contains the profile (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/rest/v1.1/profile/classificationAttributes"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: profileId, var: profile_id, required: true}, {name: collectionId, var: collection_id, required: true}]
    accept: ["*/*"]
    ok: [200, 204]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, profile_id: $profile_id, collection_id: $collection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets classification attributes from a profile
#
# GET /rest/v1.1/profile/classificationAttributes
# DEPRECATED
# Returns: record<message: string, payload: record, status: string>
# operationId: getClassificationAttributesFromProfileUsingGET
@deprecated
export def "get-classification-attributes-from-profile-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud (required)
  --profile-id: string # The profile associated with the classification attributes (required)
  --collection-id: string # The collection that contains the profile (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest/v1.1/profile/classificationAttributes"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: profileId, var: profile_id, required: true}, {name: collectionId, var: collection_id, required: true}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, profile_id: $profile_id, collection_id: $collection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Maps classification attributes to a profile
#
# PUT /rest/v1.1/profile/classificationAttributes
# DEPRECATED
# Returns: record<message: string, payload: record, status: string>
# operationId: mapClassificationAttributesToProfileUsingPUT
@deprecated
export def "map-classification-attributes-to-profile-using-put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey provided by VisageCloud (required)
  --profile-id: string # The profile associated with the classification attributes (required)
  --collection-id: string # The collection that contains the profile (required)
  --classification-attributes: string # Comma separated key:value classification attributes (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/rest/v1.1/profile/classificationAttributes"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: profileId, var: profile_id, required: true}, {name: collectionId, var: collection_id, required: true}, {name: classificationAttributes, var: classification_attributes, required: true}]
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, profile_id: $profile_id, collection_id: $collection_id, classification_attributes: $classification_attributes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the enrollment status of a profile: information on whether it is suitable for authentication.
#
# GET /rest/v1.1/profile/enrollmentStatus
# Returns: record<message: string, payload: record, status: string>
# operationId: getProfileEnrollmentStatusUsingGET
export def "get-profile-enrollment-status-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud (required)
  --profile-id: string # The profile that contains the faces (required)
  --collection-id: string # The collection that contains the profile (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest/v1.1/profile/enrollmentStatus"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: profileId, var: profile_id, required: true}, {name: collectionId, var: collection_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, profile_id: $profile_id, collection_id: $collection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes (unmaps) a list of faces, identified by faceHashes, from a profile, identified by profileId
#
# DELETE /rest/v1.1/profile/map
# Returns: record<message: string, payload: record, status: string>
# operationId: removeFacesFromProfileUsingDELETE
export def "remove-faces-from-profile-using-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey provided by VisageCloud (required)
  --face-hashes: string # Comma separated face hashes, that will be removed from a profile (required)
  --profile-id: string # The profile that contains the face (required)
  --collection-id: string # The collection that contains the profile (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/rest/v1.1/profile/map"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: faceHashes, var: face_hashes, required: true}, {name: profileId, var: profile_id, required: true}, {name: collectionId, var: collection_id, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, face_hashes: $face_hashes, profile_id: $profile_id, collection_id: $collection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all the faceHashes associated to a profile
#
# GET /rest/v1.1/profile/map
# Returns: record<message: string, payload: record, status: string>
# operationId: getFacesFromProfileUsingGET
export def "get-faces-from-profile-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud (required)
  --profile-id: string # The profile that contains the faces (required)
  --collection-id: string # The collection that contains the profile (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest/v1.1/profile/map"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: profileId, var: profile_id, required: true}, {name: collectionId, var: collection_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, profile_id: $profile_id, collection_id: $collection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds (maps) a list of faces, identified by faceHashes, to a profile, identified by profileId
#
# POST /rest/v1.1/profile/map
# Returns: record<message: string, payload: record, status: string>
# operationId: mapFacesToProfileUsingPOST
export def "map-faces-to-profile-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey provided by VisageCloud (required)
  --face-hashes: string # Comma separated face hashes, that will be associated to a profile (required)
  --profile-id: string # The profile that will store the face (required)
  --collection-id: string # The collection that contains the profile (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/rest/v1.1/profile/map"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: faceHashes, var: face_hashes, required: true}, {name: profileId, var: profile_id, required: true}, {name: collectionId, var: collection_id, required: true}]
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, face_hashes: $face_hashes, profile_id: $profile_id, collection_id: $collection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a profile and unmaps all its faces
#
# DELETE /rest/v1.1/profile/profile
# DEPRECATED
# Returns: record<message: string, payload: record, status: string>
# operationId: deleteProfile2UsingDELETE
@deprecated
export def "delete-profile2-using-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey provided by VisageCloud (required)
  --collection-id: string # Uniquely identified collection that can store multiple profiles (required)
  --profile-id: string # The profile id (provide this if you don't have the externalId (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/rest/v1.1/profile/profile"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: collectionId, var: collection_id, required: true}, {name: profileId, var: profile_id, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, collection_id: $collection_id, profile_id: $profile_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new profile with no faces associated to it (empty profile)
#
# POST /rest/v1.1/profile/profile
# Returns: record<message: string, payload: record, status: string>
# operationId: addProfileUsingPOST
export def "add-profile-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey provided by VisageCloud (required)
  --collection-id: string # Uniquely identified collection that can store multiple profiles (required)
  --external-id: string # External reference to additional information you don’t want to share with VisageCloud
  --screen-name: string # Human-readable label for the profile
  --labels: list<string> # Allows you to do finer filtering in face recognition
  --classification-attributes: string # Comma separated key:value classification attributes
  --details: string # Comma separated key:value details of profile
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/rest/v1.1/profile/profile"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: collectionId, var: collection_id, required: true}, {name: externalId, var: external_id}, {name: screenName, var: screen_name}, {name: labels, var: labels, style: multi}, {name: classificationAttributes, var: classification_attributes}, {name: details, var: details}]
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, collection_id: $collection_id, external_id: $external_id, screen_name: $screen_name, labels: $labels, classification_attributes: $classification_attributes, details: $details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a profile and unmaps all its faces
#
# DELETE /rest/v1.1/profile/{id}
# Returns: record<message: string, payload: record, status: string>
# operationId: deleteProfileUsingDELETE
export def "delete-profile-using-delete" [
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
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey provided by VisageCloud (required)
  --collection-id: string # Uniquely identified collection that can store multiple profiles (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/rest/v1.1/profile/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: collectionId, var: collection_id, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    id: $id, access_key: $access_key, secret_key: $secret_key, collection_id: $collection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a profile
#
# GET /rest/v1.1/profile/{id}
# Returns: record<message: string, payload: record, status: string>
# operationId: getProfileUsingGET
export def "get-profile-using-get" [
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
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud (required)
  --collection-id: string # Uniquely identified collection that can store multiple profiles (required)
  --with-faces: string # Retrieves the profile with all its associated faces (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest/v1.1/profile/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: collectionId, var: collection_id, required: true}, {name: withFaces, var: with_faces}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, access_key: $access_key, secret_key: $secret_key, collection_id: $collection_id, with_faces: $with_faces
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing profile with a given id
#
# PATCH /rest/v1.1/profile/{id}
# Returns: record<message: string, payload: record, status: string>
# operationId: updateProfileUsingPATCH
export def "update-profile-using-patch" [
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
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud (required)
  --collection-id: string # Uniquely identified collection that can store multiple profiles (required)
  --external-id: string # External reference to additional information you don’t want to share with VisageCloud
  --screen-name: string # Human-readable label for the profile
  --labels: list<string> # Allows you to do finer filtering in face recognition
  --classification-attributes: string # Comma separated key:value classification attributes
  --details: string # Comma separated key:value details of profile
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: patch
    path: "/rest/v1.1/profile/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: collectionId, var: collection_id, required: true}, {name: externalId, var: external_id}, {name: screenName, var: screen_name}, {name: labels, var: labels, style: multi}, {name: classificationAttributes, var: classification_attributes}, {name: details, var: details}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    id: $id, access_key: $access_key, secret_key: $secret_key, collection_id: $collection_id, external_id: $external_id, screen_name: $screen_name, labels: $labels, classification_attributes: $classification_attributes, details: $details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show status of all streams from account
#
# GET /rest/v1.1/stream/all
# Returns: record<message: string, payload: record, status: string>
# operationId: streamsByAccountUsingGET
export def "streams-by-account-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest/v1.1/stream/all"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get last N recognized individuals from stream
#
# GET /rest/v1.1/stream/attendance
# Returns: record<message: string, payload: record, status: string>
# operationId: getLastNAttedanceUsingGET
export def "get-last-n-attedance-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud (required)
  --stream-ids: list<string> # The id of the stream for which the frames will be retrieved
  --count: int # How many frames to retrieve at a time (format: int32, default: 10)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest/v1.1/stream/attendance"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: streamIds, var: stream_ids, style: multi}, {name: count, var: count}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, stream_ids: $stream_ids, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cleanup frames older than specified timeframe
#
# PATCH /rest/v1.1/stream/cleanup
# Returns: record<message: string, payload: record, status: string>
# operationId: cleanupStreamUsingPATCH
export def "cleanup-stream-using-patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey provided by VisageCloud (required)
  --stream-id: string # The id of the stream that will be stopped (required)
  --interval: int # Frames older than interval (seconds) will be cleaned up (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: patch
    path: "/rest/v1.1/stream/cleanup"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: streamId, var: stream_id, required: true}, {name: interval, var: interval, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, stream_id: $stream_id, interval: $interval
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get individual frame image
#
# GET /rest/v1.1/stream/frameImage
# Returns: list<string>
# operationId: getFrameImageUsingGET
export def "get-frame-image-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud (required)
  --stream-id: string # The id of the stream for which the frames will be retrieved (required)
  --timestamp: int # Timestamp of frame to retrieve (required, format: int64)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/rest/v1.1/stream/frameImage"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: streamId, var: stream_id, required: true}, {name: timestamp, var: timestamp, required: true}]
    accept: ["image/jpeg"]
    ok: [200]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, stream_id: $stream_id, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get last processed N frames from stream
#
# GET /rest/v1.1/stream/frames
# Returns: record<message: string, payload: record, status: string>
# operationId: getLastNFramesUsingGET
export def "get-last-n-frames-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud (required)
  --stream-id: string # The id of the stream for which the frames will be retrieved (required)
  --count: int # How many frames to retrieve at a time (format: int32, default: 10)
  --collection-id: string # The collection id you want to run recognition against
  --labels: list<string> # Labels associated with the given picture or picture URL
  --attribute-filters: list<string>@attribute-filters-completer # Filters that will be applied on the recognition operation
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest/v1.1/stream/frames"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: streamId, var: stream_id, required: true}, {name: count, var: count}, {name: collectionId, var: collection_id}, {name: labels, var: labels, style: multi}, {name: attributeFilters, var: attribute_filters, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, stream_id: $stream_id, count: $count, collection_id: $collection_id, labels: $labels, attribute_filters: $attribute_filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start existing stream
#
# PATCH /rest/v1.1/stream/start
# Returns: record<message: string, payload: record, status: string>
# operationId: startStreamUsingPATCH
export def "start-stream-using-patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey provided by VisageCloud (required)
  --stream-id: string # The id of the stream that will be started (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: patch
    path: "/rest/v1.1/stream/start"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: streamId, var: stream_id, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, stream_id: $stream_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop existing stream
#
# PATCH /rest/v1.1/stream/stop
# Returns: record<message: string, payload: record, status: string>
# operationId: stopStreamUsingPATCH
export def "stop-stream-using-patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey provided by VisageCloud (required)
  --stream-id: string # The id of the stream that will be stopped (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: patch
    path: "/rest/v1.1/stream/stop"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: streamId, var: stream_id, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, stream_id: $stream_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new stream with given name
#
# POST /rest/v1.1/stream/stream
# Returns: record<message: string, payload: record, status: string>
# operationId: addStreamUsingPOST
export def "add-stream-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey provided by VisageCloud (required)
  --name: string # The name of the stream that will be created (required)
  --url: string # The url of the stream (required)
  --method: string@method-completer # Streaming method (default: WEBRTC_PUSH)
  --username: string # Username
  --password: string # Password
  --skip-frames-with-no-faces: oneof<nothing, bool> # Boolean value indicating whether you want the original picture to be stored for later retrieval (default: true)
  --retention-time: int # Number of seconds for frames to be kept. Default is 605000s (7 days) (format: int32, default: 605000)
  --store-original-frames: oneof<nothing, bool> # Boolean value indicating whether you want the original picture to be stored for later retrieval (default: false)
  --store-attendance-faces: oneof<nothing, bool> # Boolean value indicating whether you want to store permanently store faces clippings of the recognized faces (default: false)
  --store-attendance-frames: oneof<nothing, bool> # Boolean value indicating whether you want to store permanently store frames with a recognized face in them (default: false)
  --is-active: oneof<nothing, bool> # Boolean value indicating whether the stream is currently active or not (default: false)
  --associated-collections: list<string> # List of collection ids which will be used to measure attendance
  --attributes: string # Attributes of the stream
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/rest/v1.1/stream/stream"
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: name, var: name, required: true}, {name: url, var: url, required: true}, {name: method, var: method}, {name: username, var: username}, {name: password, var: password}, {name: skipFramesWithNoFaces, var: skip_frames_with_no_faces}, {name: retentionTime, var: retention_time}, {name: storeOriginalFrames, var: store_original_frames}, {name: storeAttendanceFaces, var: store_attendance_faces}, {name: storeAttendanceFrames, var: store_attendance_frames}, {name: isActive, var: is_active}, {name: associatedCollections, var: associated_collections, style: multi}, {name: attributes, var: attributes}]
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    access_key: $access_key, secret_key: $secret_key, name: $name, url: $url, method: $method, username: $username, password: $password, skip_frames_with_no_faces: $skip_frames_with_no_faces, retention_time: $retention_time, store_original_frames: $store_original_frames, store_attendance_faces: $store_attendance_faces, store_attendance_frames: $store_attendance_frames, is_active: $is_active, associated_collections: $associated_collections, attributes: $attributes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete existing stream
#
# DELETE /rest/v1.1/stream/{id}
# Returns: record<message: string, payload: record, status: string>
# operationId: removeStreamUsingDELETE
export def "remove-stream-using-delete" [
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
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey provided by VisageCloud (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/rest/v1.1/stream/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    id: $id, access_key: $access_key, secret_key: $secret_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an existing stream with a given ID
#
# GET /rest/v1.1/stream/{streamId}
# Returns: record<message: string, payload: record, status: string>
# operationId: getStreamUsingGET
export def "get-stream-using-get" [
  stream_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey provided by VisageCloud (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest/v1.1/stream/{streamId}"
    path_params: [{name: streamId, var: stream_id}]
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    stream_id: $stream_id, access_key: $access_key, secret_key: $secret_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing stream with a given ID
#
# PATCH /rest/v1.1/stream/{streamId}
# Returns: record<message: string, payload: record, status: string>
# operationId: updateStreamUsingPATCH
export def "update-stream-using-patch" [
  stream_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud (required)
  --secret-key: string # The secretKey provided by VisageCloud (required)
  --name: string # The name of the stream that will be updated
  --url: string # The url of the stream
  --method: string@method-completer # Streaming method
  --username: string # Username
  --password: string # Password
  --skip-frames-with-no-faces: oneof<nothing, bool> # Boolean value indicating whether you want the original picture to be stored for later retrieval
  --retention-time: int # Number of seconds for frames to be kept (format: int32)
  --store-original-frames: oneof<nothing, bool> # Boolean value indicating whether you want the original picture to be stored for later retrieval
  --store-attendance-faces: oneof<nothing, bool> # Boolean value indicating whether you want to store permanently store faces clippings of the recognized faces
  --store-attendance-frames: oneof<nothing, bool> # Boolean value indicating whether you want to store permanently store frames with a recognized face in them
  --is-active: oneof<nothing, bool> # Boolean value indicating whether the stream is currently active or not
  --associated-collections: list<string> # List of collection ids which will be used to measure attendance
  --attributes: string # Attributes of the stream
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: patch
    path: "/rest/v1.1/stream/{streamId}"
    path_params: [{name: streamId, var: stream_id}]
    query: [{name: accessKey, var: access_key, required: true}, {name: secretKey, var: secret_key, required: true}, {name: name, var: name}, {name: url, var: url}, {name: method, var: method}, {name: username, var: username}, {name: password, var: password}, {name: skipFramesWithNoFaces, var: skip_frames_with_no_faces}, {name: retentionTime, var: retention_time}, {name: storeOriginalFrames, var: store_original_frames}, {name: storeAttendanceFaces, var: store_attendance_faces}, {name: storeAttendanceFrames, var: store_attendance_frames}, {name: isActive, var: is_active}, {name: associatedCollections, var: associated_collections, style: multi}, {name: attributes, var: attributes}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    stream_id: $stream_id, access_key: $access_key, secret_key: $secret_key, name: $name, url: $url, method: $method, username: $username, password: $password, skip_frames_with_no_faces: $skip_frames_with_no_faces, retention_time: $retention_time, store_original_frames: $store_original_frames, store_attendance_faces: $store_attendance_faces, store_attendance_frames: $store_attendance_frames, is_active: $is_active, associated_collections: $associated_collections, attributes: $attributes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
