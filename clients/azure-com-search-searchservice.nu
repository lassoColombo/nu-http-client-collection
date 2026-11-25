# Auto-generated client for SearchServiceClient v2019-05-06-Preview
# Source: https://api.apis.guru/v2/specs/azure.com/search-searchservice/2019-05-06-Preview/swagger.json
# Auth: --token flag or $env.SEARCHSERVICECLIENT_TOKEN

const CLIENT = {
  base_url: "https://{searchServiceName}.search.windows.net"
  token_env_var: "SEARCHSERVICECLIENT_TOKEN"
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

def base-url-completer [] { ["https://{searchServiceName}.search.windows.net"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["azureblob" "azuresql" "azuretable" "cosmosdb" "mysql"] }
def prefer-completer [] { ["return=representation"] }
def analyzer-completer [] { ["ar.lucene" "ar.microsoft" "bg.lucene" "bg.microsoft" "bn.microsoft" "ca.lucene" "ca.microsoft" "cs.lucene" "cs.microsoft" "da.lucene" "da.microsoft" "de.lucene" "de.microsoft" "el.lucene" "el.microsoft" "en.lucene" "en.microsoft" "es.lucene" "es.microsoft" "et.microsoft" "eu.lucene" "fa.lucene" "fi.lucene" "fi.microsoft" "fr.lucene" "fr.microsoft" "ga.lucene" "gl.lucene" "gu.microsoft" "he.microsoft" "hi.lucene" "hi.microsoft" "hr.microsoft" "hu.lucene" "hu.microsoft" "hy.lucene" "id.lucene" "id.microsoft" "is.microsoft" "it.lucene" "it.microsoft" "ja.lucene" "ja.microsoft" "keyword" "kn.microsoft" "ko.lucene" "ko.microsoft" "lt.microsoft" "lv.lucene" "lv.microsoft" "ml.microsoft" "mr.microsoft" "ms.microsoft" "nb.microsoft" "nl.lucene" "nl.microsoft" "no.lucene" "pa.microsoft" "pattern" "pl.lucene" "pl.microsoft" "pt-BR.lucene" "pt-BR.microsoft" "pt-PT.lucene" "pt-PT.microsoft" "ro.lucene" "ro.microsoft" "ru.lucene" "ru.microsoft" "simple" "sk.microsoft" "sl.microsoft" "sr-cyrillic.microsoft" "sr-latin.microsoft" "standard.lucene" "standardasciifolding.lucene" "stop" "sv.lucene" "sv.microsoft" "ta.microsoft" "te.microsoft" "th.lucene" "th.microsoft" "tr.lucene" "tr.microsoft" "uk.microsoft" "ur.microsoft" "vi.microsoft" "whitespace" "zh-Hans.lucene" "zh-Hans.microsoft" "zh-Hant.lucene" "zh-Hant.microsoft"] }
def tokenizer-completer [] { ["classic" "edgeNGram" "keyword_v2" "letter" "lowercase" "microsoft_language_stemming_tokenizer" "microsoft_language_tokenizer" "nGram" "path_hierarchy_v2" "pattern" "standard_v2" "uax_url_email" "whitespace"] }
def format-completer [] { ["solr"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    data-sources-list: "record<value: table<\"@odata.etag\": string, container: record, credentials: record, dataChangeDetectionPolicy: record, dataDeletionDetectionPolicy: record, description: string, name: string, type: string>>"
    data-sources-create: "record<\"@odata.etag\": string, container: record<name: string, query: string>, credentials: record<connectionString: string>, dataChangeDetectionPolicy: record<\"@odata.type\": string>, dataDeletionDetectionPolicy: record<\"@odata.type\": string>, description: string, name: string, type: string>"
    data-sources-get: "record<\"@odata.etag\": string, container: record<name: string, query: string>, credentials: record<connectionString: string>, dataChangeDetectionPolicy: record<\"@odata.type\": string>, dataDeletionDetectionPolicy: record<\"@odata.type\": string>, description: string, name: string, type: string>"
    data-sources-create-or-update: "record<\"@odata.etag\": string, container: record<name: string, query: string>, credentials: record<connectionString: string>, dataChangeDetectionPolicy: record<\"@odata.type\": string>, dataDeletionDetectionPolicy: record<\"@odata.type\": string>, description: string, name: string, type: string>"
    indexers-list: "record<value: table<\"@odata.etag\": string, dataSourceName: string, description: string, disabled: bool, fieldMappings: list, name: string, outputFieldMappings: list, parameters: record, schedule: record, skillsetName: string, targetIndexName: string>>"
    indexers-create: "record<\"@odata.etag\": string, dataSourceName: string, description: string, disabled: bool, fieldMappings: table<mappingFunction: record, sourceFieldName: string, targetFieldName: string>, name: string, outputFieldMappings: table<mappingFunction: record, sourceFieldName: string, targetFieldName: string>, parameters: record<base64EncodeKeys: bool, batchSize: int, configuration: record, maxFailedItems: int, maxFailedItemsPerBatch: int>, schedule: record<interval: string, startTime: string>, skillsetName: string, targetIndexName: string>"
    indexers-get: "record<\"@odata.etag\": string, dataSourceName: string, description: string, disabled: bool, fieldMappings: table<mappingFunction: record, sourceFieldName: string, targetFieldName: string>, name: string, outputFieldMappings: table<mappingFunction: record, sourceFieldName: string, targetFieldName: string>, parameters: record<base64EncodeKeys: bool, batchSize: int, configuration: record, maxFailedItems: int, maxFailedItemsPerBatch: int>, schedule: record<interval: string, startTime: string>, skillsetName: string, targetIndexName: string>"
    indexers-create-or-update: "record<\"@odata.etag\": string, dataSourceName: string, description: string, disabled: bool, fieldMappings: table<mappingFunction: record, sourceFieldName: string, targetFieldName: string>, name: string, outputFieldMappings: table<mappingFunction: record, sourceFieldName: string, targetFieldName: string>, parameters: record<base64EncodeKeys: bool, batchSize: int, configuration: record, maxFailedItems: int, maxFailedItemsPerBatch: int>, schedule: record<interval: string, startTime: string>, skillsetName: string, targetIndexName: string>"
    indexers-get-status: "record<executionHistory: table<endTime: string, errorMessage: string, errors: list, finalTrackingState: string, initialTrackingState: string, itemsFailed: int, itemsProcessed: int, startTime: string, status: string, warnings: list>, lastResult: record<endTime: string, errorMessage: string, errors: list<record>, finalTrackingState: string, initialTrackingState: string, itemsFailed: int, itemsProcessed: int, startTime: string, status: string, warnings: list<record>>, limits: record<maxDocumentContentCharactersToExtract: float, maxDocumentExtractionSize: float, maxRunTime: string>, status: string>"
    indexes-list: "record<value: table<\"@odata.etag\": string, analyzers: list, charFilters: list, corsOptions: record, defaultScoringProfile: string, encryptionKey: record, fields: list, name: string, scoringProfiles: list, suggesters: list, tokenFilters: list, tokenizers: list>>"
    indexes-create: "record<\"@odata.etag\": string, analyzers: table<\"@odata.type\": string, name: string>, charFilters: table<\"@odata.type\": string, name: string>, corsOptions: record<allowedOrigins: list<string>, maxAgeInSeconds: int>, defaultScoringProfile: string, encryptionKey: record<accessCredentials: record<applicationId: string, applicationSecret: string>, keyVaultKeyName: string, keyVaultKeyVersion: string, keyVaultUri: string>, fields: table<analyzer: string, facetable: bool, fields: list, filterable: bool, indexAnalyzer: string, key: bool, name: string, retrievable: bool, searchAnalyzer: string, searchable: bool, sortable: bool, synonymMaps: list, type: string>, name: string, scoringProfiles: table<functionAggregation: string, functions: list, name: string, text: record>, suggesters: table<name: string, searchMode: string, sourceFields: list>, tokenFilters: table<\"@odata.type\": string, name: string>, tokenizers: table<\"@odata.type\": string, name: string>>"
    indexes-get: "record<\"@odata.etag\": string, analyzers: table<\"@odata.type\": string, name: string>, charFilters: table<\"@odata.type\": string, name: string>, corsOptions: record<allowedOrigins: list<string>, maxAgeInSeconds: int>, defaultScoringProfile: string, encryptionKey: record<accessCredentials: record<applicationId: string, applicationSecret: string>, keyVaultKeyName: string, keyVaultKeyVersion: string, keyVaultUri: string>, fields: table<analyzer: string, facetable: bool, fields: list, filterable: bool, indexAnalyzer: string, key: bool, name: string, retrievable: bool, searchAnalyzer: string, searchable: bool, sortable: bool, synonymMaps: list, type: string>, name: string, scoringProfiles: table<functionAggregation: string, functions: list, name: string, text: record>, suggesters: table<name: string, searchMode: string, sourceFields: list>, tokenFilters: table<\"@odata.type\": string, name: string>, tokenizers: table<\"@odata.type\": string, name: string>>"
    indexes-create-or-update: "record<\"@odata.etag\": string, analyzers: table<\"@odata.type\": string, name: string>, charFilters: table<\"@odata.type\": string, name: string>, corsOptions: record<allowedOrigins: list<string>, maxAgeInSeconds: int>, defaultScoringProfile: string, encryptionKey: record<accessCredentials: record<applicationId: string, applicationSecret: string>, keyVaultKeyName: string, keyVaultKeyVersion: string, keyVaultUri: string>, fields: table<analyzer: string, facetable: bool, fields: list, filterable: bool, indexAnalyzer: string, key: bool, name: string, retrievable: bool, searchAnalyzer: string, searchable: bool, sortable: bool, synonymMaps: list, type: string>, name: string, scoringProfiles: table<functionAggregation: string, functions: list, name: string, text: record>, suggesters: table<name: string, searchMode: string, sourceFields: list>, tokenFilters: table<\"@odata.type\": string, name: string>, tokenizers: table<\"@odata.type\": string, name: string>>"
    indexes-analyze: "record<tokens: table<endOffset: int, position: int, startOffset: int, token: string>>"
    indexes-get-statistics: "record<documentCount: int, storageSize: int>"
    get-service-statistics: "record<counters: record<dataSourcesCount: record<quota: int, usage: int>, documentCount: record<quota: int, usage: int>, indexersCount: record<quota: int, usage: int>, indexesCount: record<quota: int, usage: int>, storageSize: record<quota: int, usage: int>, synonymMaps: record<quota: int, usage: int>>, limits: record<maxComplexCollectionFieldsPerIndex: int, maxComplexObjectsInCollectionsPerDocument: int, maxFieldNestingDepthPerIndex: int, maxFieldsPerIndex: int>>"
    skillsets-list: "record<value: table<\"@odata.etag\": string, cognitiveServices: record, description: string, name: string, skills: list>>"
    skillsets-create: "record<\"@odata.etag\": string, cognitiveServices: record<\"@odata.type\": string, description: string>, description: string, name: string, skills: table<\"@odata.type\": string, context: string, description: string, inputs: list, name: string, outputs: list>>"
    skillsets-get: "record<\"@odata.etag\": string, cognitiveServices: record<\"@odata.type\": string, description: string>, description: string, name: string, skills: table<\"@odata.type\": string, context: string, description: string, inputs: list, name: string, outputs: list>>"
    skillsets-create-or-update: "record<\"@odata.etag\": string, cognitiveServices: record<\"@odata.type\": string, description: string>, description: string, name: string, skills: table<\"@odata.type\": string, context: string, description: string, inputs: list, name: string, outputs: list>>"
    synonym-maps-list: "record<value: table<\"@odata.etag\": string, encryptionKey: record, format: string, name: string, synonyms: string>>"
    synonym-maps-create: "record<\"@odata.etag\": string, encryptionKey: record<accessCredentials: record<applicationId: string, applicationSecret: string>, keyVaultKeyName: string, keyVaultKeyVersion: string, keyVaultUri: string>, format: string, name: string, synonyms: string>"
    synonym-maps-get: "record<\"@odata.etag\": string, encryptionKey: record<accessCredentials: record<applicationId: string, applicationSecret: string>, keyVaultKeyName: string, keyVaultKeyVersion: string, keyVaultUri: string>, format: string, name: string, synonyms: string>"
    synonym-maps-create-or-update: "record<\"@odata.etag\": string, encryptionKey: record<accessCredentials: record<applicationId: string, applicationSecret: string>, keyVaultKeyName: string, keyVaultKeyVersion: string, keyVaultUri: string>, format: string, name: string, synonyms: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["data-sources-list" "data-sources-create" "data-sources-delete" "data-sources-get" "data-sources-create-or-update" "indexers-list" "indexers-create" "indexers-delete" "indexers-get" "indexers-create-or-update" "indexers-reset" "indexers-run" "indexers-get-status" "indexes-list" "indexes-create" "indexes-delete" "indexes-get" "indexes-create-or-update" "indexes-analyze" "indexes-get-statistics" "get-service-statistics" "skillsets-list" "skillsets-create" "skillsets-delete" "skillsets-get" "skillsets-create-or-update" "synonym-maps-list" "synonym-maps-create" "synonym-maps-delete" "synonym-maps-get" "synonym-maps-create-or-update" "commands"] | sort) } | get name | first)
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

# Lists all datasources available for a search service.
#
# GET /datasources
# Docs: https://docs.microsoft.com/rest/api/searchservice/List-Data-Sources
# Returns: record<value: table<"@odata.etag": string, container: record, credentials: record, dataChangeDetectionPolicy: record, dataDeletionDetectionPolicy: record, description: string, name: string, type: string>>
# operationId: DataSources_List
export def "data-sources-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # Selects which top-level properties of the data sources to retrieve. Specified as a comma-separated list of JSON property names, or '*' for all properties. The default is all properties.
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/datasources"
    query: [{name: "$select", var: select}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    select: $select, api_version: $api_version, client_request_id: $client_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new datasource.
#
# POST /datasources
# Docs: https://docs.microsoft.com/rest/api/searchservice/Create-Data-Source
# Returns: record<"@odata.etag": string, container: record<name: string, query: string>, credentials: record<connectionString: string>, dataChangeDetectionPolicy: record<"@odata.type": string>, dataDeletionDetectionPolicy: record<"@odata.type": string>, description: string, name: string, type: string>
# operationId: DataSources_Create
export def "data-sources-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
  --odata-etag: string # The ETag of the DataSource.
  container: any # Represents information about the entity (such as Azure SQL table or CosmosDB collection) that will be indexed. — shape: {name: string, query?: string}
  credentials: any # Represents credentials that can be used to connect to a datasource. — shape: {connectionString?: string}
  --data-change-detection-policy: any # Abstract base class for data change detection policies. — shape: {@odata.type: string}
  --data-deletion-detection-policy: any # Abstract base class for data deletion detection policies. — shape: {@odata.type: string}
  --description: string # The description of the datasource.
  name: string # The name of the datasource.
  type: string@type-completer # Defines the type of a datasource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/datasources"
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: "@odata.etag", var: odata_etag}, {name: container, var: container}, {name: credentials, var: credentials}, {name: dataChangeDetectionPolicy, var: data_change_detection_policy}, {name: dataDeletionDetectionPolicy, var: data_deletion_detection_policy}, {name: description, var: description}, {name: name, var: name}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    api_version: $api_version, client_request_id: $client_request_id, odata_etag: $odata_etag, container: $container, credentials: $credentials, data_change_detection_policy: $data_change_detection_policy, data_deletion_detection_policy: $data_deletion_detection_policy, description: $description, name: $name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a datasource.
#
# DELETE /datasources('{dataSourceName}')
# Docs: https://docs.microsoft.com/rest/api/searchservice/Delete-Data-Source
# operationId: DataSources_Delete
export def "data-sources-delete" [
  data_source_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
  --if-match: string # Defines the If-Match condition. The operation will be performed only if the ETag on the server matches this value.
  --if-none-match: string # Defines the If-None-Match condition. The operation will be performed only if the ETag on the server does not match this value.
]: nothing -> any {
  http-request {
    method: delete
    path: "/datasources('{dataSourceName}')"
    path_params: [{name: dataSourceName, var: data_source_name}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    data_source_name: $data_source_name, api_version: $api_version, client_request_id: $client_request_id, if_match: $if_match, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a datasource definition.
#
# GET /datasources('{dataSourceName}')
# Docs: https://docs.microsoft.com/rest/api/searchservice/Get-Data-Source
# Returns: record<"@odata.etag": string, container: record<name: string, query: string>, credentials: record<connectionString: string>, dataChangeDetectionPolicy: record<"@odata.type": string>, dataDeletionDetectionPolicy: record<"@odata.type": string>, description: string, name: string, type: string>
# operationId: DataSources_Get
export def "data-sources-get" [
  data_source_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/datasources('{dataSourceName}')"
    path_params: [{name: dataSourceName, var: data_source_name}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    data_source_name: $data_source_name, api_version: $api_version, client_request_id: $client_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new datasource or updates a datasource if it already exists.
#
# PUT /datasources('{dataSourceName}')
# Docs: https://docs.microsoft.com/rest/api/searchservice/Update-Data-Source
# Returns: record<"@odata.etag": string, container: record<name: string, query: string>, credentials: record<connectionString: string>, dataChangeDetectionPolicy: record<"@odata.type": string>, dataDeletionDetectionPolicy: record<"@odata.type": string>, description: string, name: string, type: string>
# operationId: DataSources_CreateOrUpdate
export def "data-sources-create-or-update" [
  data_source_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
  --if-match: string # Defines the If-Match condition. The operation will be performed only if the ETag on the server matches this value.
  --if-none-match: string # Defines the If-None-Match condition. The operation will be performed only if the ETag on the server does not match this value.
  --prefer: string@prefer-completer # For HTTP PUT requests, instructs the service to return the created/updated resource on success. (required)
  --odata-etag: string # The ETag of the DataSource.
  container: any # Represents information about the entity (such as Azure SQL table or CosmosDB collection) that will be indexed. — shape: {name: string, query?: string}
  credentials: any # Represents credentials that can be used to connect to a datasource. — shape: {connectionString?: string}
  --data-change-detection-policy: any # Abstract base class for data change detection policies. — shape: {@odata.type: string}
  --data-deletion-detection-policy: any # Abstract base class for data deletion detection policies. — shape: {@odata.type: string}
  --description: string # The description of the datasource.
  name: string # The name of the datasource.
  type: string@type-completer # Defines the type of a datasource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/datasources('{dataSourceName}')"
    path_params: [{name: dataSourceName, var: data_source_name}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: Prefer, var: prefer, required: true, default: "return=representation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: "@odata.etag", var: odata_etag}, {name: container, var: container}, {name: credentials, var: credentials}, {name: dataChangeDetectionPolicy, var: data_change_detection_policy}, {name: dataDeletionDetectionPolicy, var: data_deletion_detection_policy}, {name: description, var: description}, {name: name, var: name}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    data_source_name: $data_source_name, api_version: $api_version, client_request_id: $client_request_id, if_match: $if_match, if_none_match: $if_none_match, prefer: $prefer, odata_etag: $odata_etag, container: $container, credentials: $credentials, data_change_detection_policy: $data_change_detection_policy, data_deletion_detection_policy: $data_deletion_detection_policy, description: $description, name: $name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all indexers available for a search service.
#
# GET /indexers
# Docs: https://docs.microsoft.com/rest/api/searchservice/List-Indexers
# Returns: record<value: table<"@odata.etag": string, dataSourceName: string, description: string, disabled: bool, fieldMappings: list, name: string, outputFieldMappings: list, parameters: record, schedule: record, skillsetName: string, targetIndexName: string>>
# operationId: Indexers_List
export def "indexers-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # Selects which top-level properties of the indexers to retrieve. Specified as a comma-separated list of JSON property names, or '*' for all properties. The default is all properties.
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/indexers"
    query: [{name: "$select", var: select}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    select: $select, api_version: $api_version, client_request_id: $client_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new indexer.
#
# POST /indexers
# Docs: https://docs.microsoft.com/rest/api/searchservice/Create-Indexer
# Returns: record<"@odata.etag": string, dataSourceName: string, description: string, disabled: bool, fieldMappings: table<mappingFunction: record, sourceFieldName: string, targetFieldName: string>, name: string, outputFieldMappings: table<mappingFunction: record, sourceFieldName: string, targetFieldName: string>, parameters: record<base64EncodeKeys: bool, batchSize: int, configuration: record, maxFailedItems: int, maxFailedItemsPerBatch: int>, schedule: record<interval: string, startTime: string>, skillsetName: string, targetIndexName: string>
# operationId: Indexers_Create
export def "indexers-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
  --odata-etag: string # The ETag of the Indexer.
  data_source_name: string # The name of the datasource from which this indexer reads data.
  --description: string # The description of the indexer.
  --disabled: oneof<nothing, bool> # A value indicating whether the indexer is disabled. Default is false. (default: false)
  --field-mappings: list # Defines mappings between fields in the data source and corresponding target fields in the index. — item shape: {mappingFunction?: any, sourceFieldName: string, targetFieldName?: string}
  name: string # The name of the indexer.
  --output-field-mappings: list # Output field mappings are applied after enrichment and immediately before indexing. — item shape: {mappingFunction?: any, sourceFieldName: string, targetFieldName?: string}
  --parameters: any # Represents parameters for indexer execution. — shape: {base64EncodeKeys?: bool, batchSize?: int, configuration?: record, maxFailedItems?: int, maxFailedItemsPerBatch?: int}
  --schedule: any # Represents a schedule for indexer execution. — shape: {interval: string, startTime?: string}
  --skillset-name: string # The name of the skillset executing with this indexer.
  target_index_name: string # The name of the index to which this indexer writes data.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/indexers"
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: "@odata.etag", var: odata_etag}, {name: dataSourceName, var: data_source_name}, {name: description, var: description}, {name: disabled, var: disabled}, {name: fieldMappings, var: field_mappings}, {name: name, var: name}, {name: outputFieldMappings, var: output_field_mappings}, {name: parameters, var: parameters}, {name: schedule, var: schedule}, {name: skillsetName, var: skillset_name}, {name: targetIndexName, var: target_index_name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    api_version: $api_version, client_request_id: $client_request_id, odata_etag: $odata_etag, data_source_name: $data_source_name, description: $description, disabled: $disabled, field_mappings: $field_mappings, name: $name, output_field_mappings: $output_field_mappings, parameters: $parameters, schedule: $schedule, skillset_name: $skillset_name, target_index_name: $target_index_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an indexer.
#
# DELETE /indexers('{indexerName}')
# Docs: https://docs.microsoft.com/rest/api/searchservice/Delete-Indexer
# operationId: Indexers_Delete
export def "indexers-delete" [
  indexer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
  --if-match: string # Defines the If-Match condition. The operation will be performed only if the ETag on the server matches this value.
  --if-none-match: string # Defines the If-None-Match condition. The operation will be performed only if the ETag on the server does not match this value.
]: nothing -> any {
  http-request {
    method: delete
    path: "/indexers('{indexerName}')"
    path_params: [{name: indexerName, var: indexer_name}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    indexer_name: $indexer_name, api_version: $api_version, client_request_id: $client_request_id, if_match: $if_match, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves an indexer definition.
#
# GET /indexers('{indexerName}')
# Docs: https://docs.microsoft.com/rest/api/searchservice/Get-Indexer
# Returns: record<"@odata.etag": string, dataSourceName: string, description: string, disabled: bool, fieldMappings: table<mappingFunction: record, sourceFieldName: string, targetFieldName: string>, name: string, outputFieldMappings: table<mappingFunction: record, sourceFieldName: string, targetFieldName: string>, parameters: record<base64EncodeKeys: bool, batchSize: int, configuration: record, maxFailedItems: int, maxFailedItemsPerBatch: int>, schedule: record<interval: string, startTime: string>, skillsetName: string, targetIndexName: string>
# operationId: Indexers_Get
export def "indexers-get" [
  indexer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/indexers('{indexerName}')"
    path_params: [{name: indexerName, var: indexer_name}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    indexer_name: $indexer_name, api_version: $api_version, client_request_id: $client_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new indexer or updates an indexer if it already exists.
#
# PUT /indexers('{indexerName}')
# Docs: https://docs.microsoft.com/rest/api/searchservice/Create-Indexer
# Returns: record<"@odata.etag": string, dataSourceName: string, description: string, disabled: bool, fieldMappings: table<mappingFunction: record, sourceFieldName: string, targetFieldName: string>, name: string, outputFieldMappings: table<mappingFunction: record, sourceFieldName: string, targetFieldName: string>, parameters: record<base64EncodeKeys: bool, batchSize: int, configuration: record, maxFailedItems: int, maxFailedItemsPerBatch: int>, schedule: record<interval: string, startTime: string>, skillsetName: string, targetIndexName: string>
# operationId: Indexers_CreateOrUpdate
export def "indexers-create-or-update" [
  indexer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
  --if-match: string # Defines the If-Match condition. The operation will be performed only if the ETag on the server matches this value.
  --if-none-match: string # Defines the If-None-Match condition. The operation will be performed only if the ETag on the server does not match this value.
  --prefer: string@prefer-completer # For HTTP PUT requests, instructs the service to return the created/updated resource on success. (required)
  --odata-etag: string # The ETag of the Indexer.
  data_source_name: string # The name of the datasource from which this indexer reads data.
  --description: string # The description of the indexer.
  --disabled: oneof<nothing, bool> # A value indicating whether the indexer is disabled. Default is false. (default: false)
  --field-mappings: list # Defines mappings between fields in the data source and corresponding target fields in the index. — item shape: {mappingFunction?: any, sourceFieldName: string, targetFieldName?: string}
  name: string # The name of the indexer.
  --output-field-mappings: list # Output field mappings are applied after enrichment and immediately before indexing. — item shape: {mappingFunction?: any, sourceFieldName: string, targetFieldName?: string}
  --parameters: any # Represents parameters for indexer execution. — shape: {base64EncodeKeys?: bool, batchSize?: int, configuration?: record, maxFailedItems?: int, maxFailedItemsPerBatch?: int}
  --schedule: any # Represents a schedule for indexer execution. — shape: {interval: string, startTime?: string}
  --skillset-name: string # The name of the skillset executing with this indexer.
  target_index_name: string # The name of the index to which this indexer writes data.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/indexers('{indexerName}')"
    path_params: [{name: indexerName, var: indexer_name}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: Prefer, var: prefer, required: true, default: "return=representation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: "@odata.etag", var: odata_etag}, {name: dataSourceName, var: data_source_name}, {name: description, var: description}, {name: disabled, var: disabled}, {name: fieldMappings, var: field_mappings}, {name: name, var: name}, {name: outputFieldMappings, var: output_field_mappings}, {name: parameters, var: parameters}, {name: schedule, var: schedule}, {name: skillsetName, var: skillset_name}, {name: targetIndexName, var: target_index_name}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    indexer_name: $indexer_name, api_version: $api_version, client_request_id: $client_request_id, if_match: $if_match, if_none_match: $if_none_match, prefer: $prefer, odata_etag: $odata_etag, data_source_name: $data_source_name, description: $description, disabled: $disabled, field_mappings: $field_mappings, name: $name, output_field_mappings: $output_field_mappings, parameters: $parameters, schedule: $schedule, skillset_name: $skillset_name, target_index_name: $target_index_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resets the change tracking state associated with an indexer.
#
# POST /indexers('{indexerName}')/search.reset
# Docs: https://docs.microsoft.com/rest/api/searchservice/Reset-Indexer
# operationId: Indexers_Reset
export def "indexers-reset" [
  indexer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
]: nothing -> any {
  http-request {
    method: post
    path: "/indexers('{indexerName}')/search.reset"
    path_params: [{name: indexerName, var: indexer_name}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    indexer_name: $indexer_name, api_version: $api_version, client_request_id: $client_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Runs an indexer on-demand.
#
# POST /indexers('{indexerName}')/search.run
# Docs: https://docs.microsoft.com/rest/api/searchservice/Run-Indexer
# operationId: Indexers_Run
export def "indexers-run" [
  indexer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
]: nothing -> any {
  http-request {
    method: post
    path: "/indexers('{indexerName}')/search.run"
    path_params: [{name: indexerName, var: indexer_name}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    indexer_name: $indexer_name, api_version: $api_version, client_request_id: $client_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the current status and execution history of an indexer.
#
# GET /indexers('{indexerName}')/search.status
# Docs: https://docs.microsoft.com/rest/api/searchservice/Get-Indexer-Status
# Returns: record<executionHistory: table<endTime: string, errorMessage: string, errors: list, finalTrackingState: string, initialTrackingState: string, itemsFailed: int, itemsProcessed: int, startTime: string, status: string, warnings: list>, lastResult: record<endTime: string, errorMessage: string, errors: list<record>, finalTrackingState: string, initialTrackingState: string, itemsFailed: int, itemsProcessed: int, startTime: string, status: string, warnings: list<record>>, limits: record<maxDocumentContentCharactersToExtract: float, maxDocumentExtractionSize: float, maxRunTime: string>, status: string>
# operationId: Indexers_GetStatus
export def "indexers-get-status" [
  indexer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/indexers('{indexerName}')/search.status"
    path_params: [{name: indexerName, var: indexer_name}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    indexer_name: $indexer_name, api_version: $api_version, client_request_id: $client_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all indexes available for a search service.
#
# GET /indexes
# Docs: https://docs.microsoft.com/rest/api/searchservice/List-Indexes
# Returns: record<value: table<"@odata.etag": string, analyzers: list, charFilters: list, corsOptions: record, defaultScoringProfile: string, encryptionKey: record, fields: list, name: string, scoringProfiles: list, suggesters: list, tokenFilters: list, tokenizers: list>>
# operationId: Indexes_List
export def "indexes-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # Selects which top-level properties of the index definitions to retrieve. Specified as a comma-separated list of JSON property names, or '*' for all properties. The default is all properties.
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/indexes"
    query: [{name: "$select", var: select}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    select: $select, api_version: $api_version, client_request_id: $client_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new search index.
#
# POST /indexes
# Docs: https://docs.microsoft.com/rest/api/searchservice/Create-Index
# Returns: record<"@odata.etag": string, analyzers: table<"@odata.type": string, name: string>, charFilters: table<"@odata.type": string, name: string>, corsOptions: record<allowedOrigins: list<string>, maxAgeInSeconds: int>, defaultScoringProfile: string, encryptionKey: record<accessCredentials: record<applicationId: string, applicationSecret: string>, keyVaultKeyName: string, keyVaultKeyVersion: string, keyVaultUri: string>, fields: table<analyzer: string, facetable: bool, fields: list, filterable: bool, indexAnalyzer: string, key: bool, name: string, retrievable: bool, searchAnalyzer: string, searchable: bool, sortable: bool, synonymMaps: list, type: string>, name: string, scoringProfiles: table<functionAggregation: string, functions: list, name: string, text: record>, suggesters: table<name: string, searchMode: string, sourceFields: list>, tokenFilters: table<"@odata.type": string, name: string>, tokenizers: table<"@odata.type": string, name: string>>
# operationId: Indexes_Create
export def "indexes-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
  --odata-etag: string # The ETag of the index.
  --analyzers: list # The analyzers for the index. — item shape: {@odata.type: string, name: string}
  --char-filters: list # The character filters for the index. — item shape: {@odata.type: string, name: string}
  --cors-options: any # Defines options to control Cross-Origin Resource Sharing (CORS) for an index. — shape: {allowedOrigins: list<string>, maxAgeInSeconds?: int}
  --default-scoring-profile: string # The name of the scoring profile to use if none is specified in the query. If this property is not set and no scoring profile is specified in the query, then default scoring (tf-idf) will be used.
  --encryption-key: any # A customer-managed encryption key in Azure Key Vault. Keys that you create and manage can be used to encrypt or decrypt data-at-rest in Azure Cognitive Search, such as indexes and synonym maps. — shape: {accessCredentials?: any, keyVaultKeyName: string, keyVaultKeyVersion: string, keyVaultUri: string}
  fields: list # The fields of the index. — item shape: {analyzer?: "ar.microsoft"|"ar.lucene"|"hy.lucene"|"bn.microsoft"|"eu.lucene"|"bg.microsoft"|"bg.lucene"|"ca.microsoft"|"ca.lucene"|"zh-Hans.microsoft"|"zh-Hans.lucene"|"zh-Hant.microsoft"|"zh-Hant.lucene"|"hr.microsoft"|"cs.microsoft"|"cs.lucene"|"da.microsoft"|"da.lucene"|"nl.microsoft"|"nl.lucene"|"en.microsoft"|"en.lucene"|"et.microsoft"|"fi.microsoft"|"fi.lucene"|"fr.microsoft"|"fr.lucene"|"gl.lucene"|"de.microsoft"|"de.lucene"|"el.microsoft"|"el.lucene"|"gu.microsoft"|"he.microsoft"|"hi.microsoft"|"hi.lucene"|"hu.microsoft"|"hu.lucene"|"is.microsoft"|"id.microsoft"|"id.lucene"|"ga.lucene"|"it.microsoft"|"it.lucene"|"ja.microsoft"|"ja.lucene"|"kn.microsoft"|"ko.microsoft"|"ko.lucene"|"lv.microsoft"|"lv.lucene"|"lt.microsoft"|"ml.microsoft"|"ms.microsoft"|"mr.microsoft"|"nb.microsoft"|"no.lucene"|"fa.lucene"|"pl.microsoft"|"pl.lucene"|"pt-BR.microsoft"|"pt-BR.lucene"|"pt-PT.microsoft"|"pt-PT.lucene"|"pa.microsoft"|"ro.microsoft"|"ro.lucene"|"ru.microsoft"|"ru.lucene"|"sr-cyrillic.microsoft"|"sr-latin.microsoft"|"sk.microsoft"|"sl.microsoft"|"es.microsoft"|"es.lucene"|"sv.microsoft"|"sv.lucene"|"ta.microsoft"|"te.microsoft"|"th.microsoft"|"th.lucene"|"tr.microsoft"|"tr.lucene"|"uk.microsoft"|"ur.microsoft"|"vi.microsoft"|"standard.lucene"|"standardasciifolding.lucene"|"keyword"|"pattern"|"simple"|"stop"|"whitespace", ... (12 more fields)}
  name: string # The name of the index.
  --scoring-profiles: list # The scoring profiles for the index. — item shape: {functionAggregation?: "sum"|"average"|"minimum"|"maximum"|"firstMatching", functions?: list, name: string, text?: any}
  --suggesters: list # The suggesters for the index. — item shape: {name: string, searchMode: "analyzingInfixMatching", sourceFields: list<string>}
  --token-filters: list # The token filters for the index. — item shape: {@odata.type: string, name: string}
  --tokenizers: list # The tokenizers for the index. — item shape: {@odata.type: string, name: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/indexes"
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: "@odata.etag", var: odata_etag}, {name: analyzers, var: analyzers}, {name: charFilters, var: char_filters}, {name: corsOptions, var: cors_options}, {name: defaultScoringProfile, var: default_scoring_profile}, {name: encryptionKey, var: encryption_key}, {name: fields, var: fields}, {name: name, var: name}, {name: scoringProfiles, var: scoring_profiles}, {name: suggesters, var: suggesters}, {name: tokenFilters, var: token_filters}, {name: tokenizers, var: tokenizers}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    api_version: $api_version, client_request_id: $client_request_id, odata_etag: $odata_etag, analyzers: $analyzers, char_filters: $char_filters, cors_options: $cors_options, default_scoring_profile: $default_scoring_profile, encryption_key: $encryption_key, fields: $fields, name: $name, scoring_profiles: $scoring_profiles, suggesters: $suggesters, token_filters: $token_filters, tokenizers: $tokenizers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a search index and all the documents it contains.
#
# DELETE /indexes('{indexName}')
# Docs: https://docs.microsoft.com/rest/api/searchservice/Delete-Index
# operationId: Indexes_Delete
export def "indexes-delete" [
  index_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
  --if-match: string # Defines the If-Match condition. The operation will be performed only if the ETag on the server matches this value.
  --if-none-match: string # Defines the If-None-Match condition. The operation will be performed only if the ETag on the server does not match this value.
]: nothing -> any {
  http-request {
    method: delete
    path: "/indexes('{indexName}')"
    path_params: [{name: indexName, var: index_name}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    index_name: $index_name, api_version: $api_version, client_request_id: $client_request_id, if_match: $if_match, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves an index definition.
#
# GET /indexes('{indexName}')
# Docs: https://docs.microsoft.com/rest/api/searchservice/Get-Index
# Returns: record<"@odata.etag": string, analyzers: table<"@odata.type": string, name: string>, charFilters: table<"@odata.type": string, name: string>, corsOptions: record<allowedOrigins: list<string>, maxAgeInSeconds: int>, defaultScoringProfile: string, encryptionKey: record<accessCredentials: record<applicationId: string, applicationSecret: string>, keyVaultKeyName: string, keyVaultKeyVersion: string, keyVaultUri: string>, fields: table<analyzer: string, facetable: bool, fields: list, filterable: bool, indexAnalyzer: string, key: bool, name: string, retrievable: bool, searchAnalyzer: string, searchable: bool, sortable: bool, synonymMaps: list, type: string>, name: string, scoringProfiles: table<functionAggregation: string, functions: list, name: string, text: record>, suggesters: table<name: string, searchMode: string, sourceFields: list>, tokenFilters: table<"@odata.type": string, name: string>, tokenizers: table<"@odata.type": string, name: string>>
# operationId: Indexes_Get
export def "indexes-get" [
  index_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/indexes('{indexName}')"
    path_params: [{name: indexName, var: index_name}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index_name: $index_name, api_version: $api_version, client_request_id: $client_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new search index or updates an index if it already exists.
#
# PUT /indexes('{indexName}')
# Docs: https://docs.microsoft.com/rest/api/searchservice/Update-Index
# Returns: record<"@odata.etag": string, analyzers: table<"@odata.type": string, name: string>, charFilters: table<"@odata.type": string, name: string>, corsOptions: record<allowedOrigins: list<string>, maxAgeInSeconds: int>, defaultScoringProfile: string, encryptionKey: record<accessCredentials: record<applicationId: string, applicationSecret: string>, keyVaultKeyName: string, keyVaultKeyVersion: string, keyVaultUri: string>, fields: table<analyzer: string, facetable: bool, fields: list, filterable: bool, indexAnalyzer: string, key: bool, name: string, retrievable: bool, searchAnalyzer: string, searchable: bool, sortable: bool, synonymMaps: list, type: string>, name: string, scoringProfiles: table<functionAggregation: string, functions: list, name: string, text: record>, suggesters: table<name: string, searchMode: string, sourceFields: list>, tokenFilters: table<"@odata.type": string, name: string>, tokenizers: table<"@odata.type": string, name: string>>
# operationId: Indexes_CreateOrUpdate
export def "indexes-create-or-update" [
  index_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-index-downtime: oneof<nothing, bool> # Allows new analyzers, tokenizers, token filters, or char filters to be added to an index by taking the index offline for at least a few seconds. This temporarily causes indexing and query requests to fail. Performance and write availability of the index can be impaired for several minutes after the index is updated, or longer for very large indexes.
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
  --if-match: string # Defines the If-Match condition. The operation will be performed only if the ETag on the server matches this value.
  --if-none-match: string # Defines the If-None-Match condition. The operation will be performed only if the ETag on the server does not match this value.
  --prefer: string@prefer-completer # For HTTP PUT requests, instructs the service to return the created/updated resource on success. (required)
  --odata-etag: string # The ETag of the index.
  --analyzers: list # The analyzers for the index. — item shape: {@odata.type: string, name: string}
  --char-filters: list # The character filters for the index. — item shape: {@odata.type: string, name: string}
  --cors-options: any # Defines options to control Cross-Origin Resource Sharing (CORS) for an index. — shape: {allowedOrigins: list<string>, maxAgeInSeconds?: int}
  --default-scoring-profile: string # The name of the scoring profile to use if none is specified in the query. If this property is not set and no scoring profile is specified in the query, then default scoring (tf-idf) will be used.
  --encryption-key: any # A customer-managed encryption key in Azure Key Vault. Keys that you create and manage can be used to encrypt or decrypt data-at-rest in Azure Cognitive Search, such as indexes and synonym maps. — shape: {accessCredentials?: any, keyVaultKeyName: string, keyVaultKeyVersion: string, keyVaultUri: string}
  fields: list # The fields of the index. — item shape: {analyzer?: "ar.microsoft"|"ar.lucene"|"hy.lucene"|"bn.microsoft"|"eu.lucene"|"bg.microsoft"|"bg.lucene"|"ca.microsoft"|"ca.lucene"|"zh-Hans.microsoft"|"zh-Hans.lucene"|"zh-Hant.microsoft"|"zh-Hant.lucene"|"hr.microsoft"|"cs.microsoft"|"cs.lucene"|"da.microsoft"|"da.lucene"|"nl.microsoft"|"nl.lucene"|"en.microsoft"|"en.lucene"|"et.microsoft"|"fi.microsoft"|"fi.lucene"|"fr.microsoft"|"fr.lucene"|"gl.lucene"|"de.microsoft"|"de.lucene"|"el.microsoft"|"el.lucene"|"gu.microsoft"|"he.microsoft"|"hi.microsoft"|"hi.lucene"|"hu.microsoft"|"hu.lucene"|"is.microsoft"|"id.microsoft"|"id.lucene"|"ga.lucene"|"it.microsoft"|"it.lucene"|"ja.microsoft"|"ja.lucene"|"kn.microsoft"|"ko.microsoft"|"ko.lucene"|"lv.microsoft"|"lv.lucene"|"lt.microsoft"|"ml.microsoft"|"ms.microsoft"|"mr.microsoft"|"nb.microsoft"|"no.lucene"|"fa.lucene"|"pl.microsoft"|"pl.lucene"|"pt-BR.microsoft"|"pt-BR.lucene"|"pt-PT.microsoft"|"pt-PT.lucene"|"pa.microsoft"|"ro.microsoft"|"ro.lucene"|"ru.microsoft"|"ru.lucene"|"sr-cyrillic.microsoft"|"sr-latin.microsoft"|"sk.microsoft"|"sl.microsoft"|"es.microsoft"|"es.lucene"|"sv.microsoft"|"sv.lucene"|"ta.microsoft"|"te.microsoft"|"th.microsoft"|"th.lucene"|"tr.microsoft"|"tr.lucene"|"uk.microsoft"|"ur.microsoft"|"vi.microsoft"|"standard.lucene"|"standardasciifolding.lucene"|"keyword"|"pattern"|"simple"|"stop"|"whitespace", ... (12 more fields)}
  name: string # The name of the index.
  --scoring-profiles: list # The scoring profiles for the index. — item shape: {functionAggregation?: "sum"|"average"|"minimum"|"maximum"|"firstMatching", functions?: list, name: string, text?: any}
  --suggesters: list # The suggesters for the index. — item shape: {name: string, searchMode: "analyzingInfixMatching", sourceFields: list<string>}
  --token-filters: list # The token filters for the index. — item shape: {@odata.type: string, name: string}
  --tokenizers: list # The tokenizers for the index. — item shape: {@odata.type: string, name: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/indexes('{indexName}')"
    path_params: [{name: indexName, var: index_name}]
    query: [{name: allowIndexDowntime, var: allow_index_downtime}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: Prefer, var: prefer, required: true, default: "return=representation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: "@odata.etag", var: odata_etag}, {name: analyzers, var: analyzers}, {name: charFilters, var: char_filters}, {name: corsOptions, var: cors_options}, {name: defaultScoringProfile, var: default_scoring_profile}, {name: encryptionKey, var: encryption_key}, {name: fields, var: fields}, {name: name, var: name}, {name: scoringProfiles, var: scoring_profiles}, {name: suggesters, var: suggesters}, {name: tokenFilters, var: token_filters}, {name: tokenizers, var: tokenizers}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    index_name: $index_name, allow_index_downtime: $allow_index_downtime, api_version: $api_version, client_request_id: $client_request_id, if_match: $if_match, if_none_match: $if_none_match, prefer: $prefer, odata_etag: $odata_etag, analyzers: $analyzers, char_filters: $char_filters, cors_options: $cors_options, default_scoring_profile: $default_scoring_profile, encryption_key: $encryption_key, fields: $fields, name: $name, scoring_profiles: $scoring_profiles, suggesters: $suggesters, token_filters: $token_filters, tokenizers: $tokenizers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Shows how an analyzer breaks text into tokens.
#
# POST /indexes('{indexName}')/search.analyze
# Docs: https://docs.microsoft.com/rest/api/searchservice/test-analyzer
# Returns: record<tokens: table<endOffset: int, position: int, startOffset: int, token: string>>
# operationId: Indexes_Analyze
export def "indexes-analyze" [
  index_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
  --analyzer: string@analyzer-completer # Defines the names of all text analyzers supported by Azure Cognitive Search.
  --char-filters: list<string> # An optional list of character filters to use when breaking the given text. This parameter can only be set when using the tokenizer parameter.
  text: string # The text to break into tokens.
  --token-filters: list<string> # An optional list of token filters to use when breaking the given text. This parameter can only be set when using the tokenizer parameter.
  --tokenizer: string@tokenizer-completer # Defines the names of all tokenizers supported by Azure Cognitive Search.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/indexes('{indexName}')/search.analyze"
    path_params: [{name: indexName, var: index_name}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: analyzer, var: analyzer}, {name: charFilters, var: char_filters}, {name: text, var: text}, {name: tokenFilters, var: token_filters}, {name: tokenizer, var: tokenizer}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index_name: $index_name, api_version: $api_version, client_request_id: $client_request_id, analyzer: $analyzer, char_filters: $char_filters, text: $text, token_filters: $token_filters, tokenizer: $tokenizer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns statistics for the given index, including a document count and storage usage.
#
# GET /indexes('{indexName}')/search.stats
# Docs: https://docs.microsoft.com/rest/api/searchservice/Get-Index-Statistics
# Returns: record<documentCount: int, storageSize: int>
# operationId: Indexes_GetStatistics
export def "indexes-get-statistics" [
  index_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/indexes('{indexName}')/search.stats"
    path_params: [{name: indexName, var: index_name}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index_name: $index_name, api_version: $api_version, client_request_id: $client_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets service level statistics for a search service.
#
# GET /servicestats
# Returns: record<counters: record<dataSourcesCount: record<quota: int, usage: int>, documentCount: record<quota: int, usage: int>, indexersCount: record<quota: int, usage: int>, indexesCount: record<quota: int, usage: int>, storageSize: record<quota: int, usage: int>, synonymMaps: record<quota: int, usage: int>>, limits: record<maxComplexCollectionFieldsPerIndex: int, maxComplexObjectsInCollectionsPerDocument: int, maxFieldNestingDepthPerIndex: int, maxFieldsPerIndex: int>>
# operationId: GetServiceStatistics
export def "get-service-statistics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/servicestats"
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, client_request_id: $client_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all skillsets in a search service.
#
# GET /skillsets
# Docs: https://docs.microsoft.com/rest/api/searchservice/list-skillset
# Returns: record<value: table<"@odata.etag": string, cognitiveServices: record, description: string, name: string, skills: list>>
# operationId: Skillsets_List
export def "skillsets-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # Selects which top-level properties of the skillsets to retrieve. Specified as a comma-separated list of JSON property names, or '*' for all properties. The default is all properties.
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/skillsets"
    query: [{name: "$select", var: select}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    select: $select, api_version: $api_version, client_request_id: $client_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new skillset in a search service.
#
# POST /skillsets
# Docs: https://docs.microsoft.com/rest/api/searchservice/create-skillset
# Returns: record<"@odata.etag": string, cognitiveServices: record<"@odata.type": string, description: string>, description: string, name: string, skills: table<"@odata.type": string, context: string, description: string, inputs: list, name: string, outputs: list>>
# operationId: Skillsets_Create
export def "skillsets-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
  --odata-etag: string # The ETag of the skillset.
  --cognitive-services: any # Abstract base class for describing any cognitive service resource attached to the skillset. — shape: {@odata.type: string, description?: string}
  description: string # The description of the skillset.
  name: string # The name of the skillset.
  skills: list # A list of skills in the skillset. — item shape: {@odata.type: string, context?: string, description?: string, inputs: list, name?: string, outputs: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/skillsets"
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: "@odata.etag", var: odata_etag}, {name: cognitiveServices, var: cognitive_services}, {name: description, var: description}, {name: name, var: name}, {name: skills, var: skills}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    api_version: $api_version, client_request_id: $client_request_id, odata_etag: $odata_etag, cognitive_services: $cognitive_services, description: $description, name: $name, skills: $skills
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a skillset in a search service.
#
# DELETE /skillsets('{skillsetName}')
# Docs: https://docs.microsoft.com/rest/api/searchservice/delete-skillset
# operationId: Skillsets_Delete
export def "skillsets-delete" [
  skillset_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
  --if-match: string # Defines the If-Match condition. The operation will be performed only if the ETag on the server matches this value.
  --if-none-match: string # Defines the If-None-Match condition. The operation will be performed only if the ETag on the server does not match this value.
]: nothing -> any {
  http-request {
    method: delete
    path: "/skillsets('{skillsetName}')"
    path_params: [{name: skillsetName, var: skillset_name}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    skillset_name: $skillset_name, api_version: $api_version, client_request_id: $client_request_id, if_match: $if_match, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a skillset in a search service.
#
# GET /skillsets('{skillsetName}')
# Docs: https://docs.microsoft.com/rest/api/searchservice/get-skillset
# Returns: record<"@odata.etag": string, cognitiveServices: record<"@odata.type": string, description: string>, description: string, name: string, skills: table<"@odata.type": string, context: string, description: string, inputs: list, name: string, outputs: list>>
# operationId: Skillsets_Get
export def "skillsets-get" [
  skillset_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/skillsets('{skillsetName}')"
    path_params: [{name: skillsetName, var: skillset_name}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    skillset_name: $skillset_name, api_version: $api_version, client_request_id: $client_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new skillset in a search service or updates the skillset if it already exists.
#
# PUT /skillsets('{skillsetName}')
# Docs: https://docs.microsoft.com/rest/api/searchservice/update-skillset
# Returns: record<"@odata.etag": string, cognitiveServices: record<"@odata.type": string, description: string>, description: string, name: string, skills: table<"@odata.type": string, context: string, description: string, inputs: list, name: string, outputs: list>>
# operationId: Skillsets_CreateOrUpdate
export def "skillsets-create-or-update" [
  skillset_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
  --if-match: string # Defines the If-Match condition. The operation will be performed only if the ETag on the server matches this value.
  --if-none-match: string # Defines the If-None-Match condition. The operation will be performed only if the ETag on the server does not match this value.
  --prefer: string@prefer-completer # For HTTP PUT requests, instructs the service to return the created/updated resource on success. (required)
  --odata-etag: string # The ETag of the skillset.
  --cognitive-services: any # Abstract base class for describing any cognitive service resource attached to the skillset. — shape: {@odata.type: string, description?: string}
  description: string # The description of the skillset.
  name: string # The name of the skillset.
  skills: list # A list of skills in the skillset. — item shape: {@odata.type: string, context?: string, description?: string, inputs: list, name?: string, outputs: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/skillsets('{skillsetName}')"
    path_params: [{name: skillsetName, var: skillset_name}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: Prefer, var: prefer, required: true, default: "return=representation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: "@odata.etag", var: odata_etag}, {name: cognitiveServices, var: cognitive_services}, {name: description, var: description}, {name: name, var: name}, {name: skills, var: skills}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    skillset_name: $skillset_name, api_version: $api_version, client_request_id: $client_request_id, if_match: $if_match, if_none_match: $if_none_match, prefer: $prefer, odata_etag: $odata_etag, cognitive_services: $cognitive_services, description: $description, name: $name, skills: $skills
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all synonym maps available for a search service.
#
# GET /synonymmaps
# Docs: https://docs.microsoft.com/rest/api/searchservice/List-Synonym-Maps
# Returns: record<value: table<"@odata.etag": string, encryptionKey: record, format: string, name: string, synonyms: string>>
# operationId: SynonymMaps_List
export def "synonym-maps-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # Selects which top-level properties of the synonym maps to retrieve. Specified as a comma-separated list of JSON property names, or '*' for all properties. The default is all properties.
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/synonymmaps"
    query: [{name: "$select", var: select}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    select: $select, api_version: $api_version, client_request_id: $client_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new synonym map.
#
# POST /synonymmaps
# Docs: https://docs.microsoft.com/rest/api/searchservice/Create-Synonym-Map
# Returns: record<"@odata.etag": string, encryptionKey: record<accessCredentials: record<applicationId: string, applicationSecret: string>, keyVaultKeyName: string, keyVaultKeyVersion: string, keyVaultUri: string>, format: string, name: string, synonyms: string>
# operationId: SynonymMaps_Create
export def "synonym-maps-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
  --odata-etag: string # The ETag of the synonym map.
  --encryption-key: any # A customer-managed encryption key in Azure Key Vault. Keys that you create and manage can be used to encrypt or decrypt data-at-rest in Azure Cognitive Search, such as indexes and synonym maps. — shape: {accessCredentials?: any, keyVaultKeyName: string, keyVaultKeyVersion: string, keyVaultUri: string}
  format: string@format-completer # The format of the synonym map. Only the 'solr' format is currently supported.
  name: string # The name of the synonym map.
  synonyms: string # A series of synonym rules in the specified synonym map format. The rules must be separated by newlines.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/synonymmaps"
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: "@odata.etag", var: odata_etag}, {name: encryptionKey, var: encryption_key}, {name: format, var: format}, {name: name, var: name}, {name: synonyms, var: synonyms}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    api_version: $api_version, client_request_id: $client_request_id, odata_etag: $odata_etag, encryption_key: $encryption_key, format: $format, name: $name, synonyms: $synonyms
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a synonym map.
#
# DELETE /synonymmaps('{synonymMapName}')
# Docs: https://docs.microsoft.com/rest/api/searchservice/Delete-Synonym-Map
# operationId: SynonymMaps_Delete
export def "synonym-maps-delete" [
  synonym_map_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
  --if-match: string # Defines the If-Match condition. The operation will be performed only if the ETag on the server matches this value.
  --if-none-match: string # Defines the If-None-Match condition. The operation will be performed only if the ETag on the server does not match this value.
]: nothing -> any {
  http-request {
    method: delete
    path: "/synonymmaps('{synonymMapName}')"
    path_params: [{name: synonymMapName, var: synonym_map_name}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    synonym_map_name: $synonym_map_name, api_version: $api_version, client_request_id: $client_request_id, if_match: $if_match, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a synonym map definition.
#
# GET /synonymmaps('{synonymMapName}')
# Docs: https://docs.microsoft.com/rest/api/searchservice/Get-Synonym-Map
# Returns: record<"@odata.etag": string, encryptionKey: record<accessCredentials: record<applicationId: string, applicationSecret: string>, keyVaultKeyName: string, keyVaultKeyVersion: string, keyVaultUri: string>, format: string, name: string, synonyms: string>
# operationId: SynonymMaps_Get
export def "synonym-maps-get" [
  synonym_map_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/synonymmaps('{synonymMapName}')"
    path_params: [{name: synonymMapName, var: synonym_map_name}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    synonym_map_name: $synonym_map_name, api_version: $api_version, client_request_id: $client_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new synonym map or updates a synonym map if it already exists.
#
# PUT /synonymmaps('{synonymMapName}')
# Docs: https://docs.microsoft.com/rest/api/searchservice/Update-Synonym-Map
# Returns: record<"@odata.etag": string, encryptionKey: record<accessCredentials: record<applicationId: string, applicationSecret: string>, keyVaultKeyName: string, keyVaultKeyVersion: string, keyVaultUri: string>, format: string, name: string, synonyms: string>
# operationId: SynonymMaps_CreateOrUpdate
export def "synonym-maps-create-or-update" [
  synonym_map_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
  --if-match: string # Defines the If-Match condition. The operation will be performed only if the ETag on the server matches this value.
  --if-none-match: string # Defines the If-None-Match condition. The operation will be performed only if the ETag on the server does not match this value.
  --prefer: string@prefer-completer # For HTTP PUT requests, instructs the service to return the created/updated resource on success. (required)
  --odata-etag: string # The ETag of the synonym map.
  --encryption-key: any # A customer-managed encryption key in Azure Key Vault. Keys that you create and manage can be used to encrypt or decrypt data-at-rest in Azure Cognitive Search, such as indexes and synonym maps. — shape: {accessCredentials?: any, keyVaultKeyName: string, keyVaultKeyVersion: string, keyVaultUri: string}
  format: string@format-completer # The format of the synonym map. Only the 'solr' format is currently supported.
  name: string # The name of the synonym map.
  synonyms: string # A series of synonym rules in the specified synonym map format. The rules must be separated by newlines.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/synonymmaps('{synonymMapName}')"
    path_params: [{name: synonymMapName, var: synonym_map_name}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: Prefer, var: prefer, required: true, default: "return=representation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: "@odata.etag", var: odata_etag}, {name: encryptionKey, var: encryption_key}, {name: format, var: format}, {name: name, var: name}, {name: synonyms, var: synonyms}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    synonym_map_name: $synonym_map_name, api_version: $api_version, client_request_id: $client_request_id, if_match: $if_match, if_none_match: $if_none_match, prefer: $prefer, odata_etag: $odata_etag, encryption_key: $encryption_key, format: $format, name: $name, synonyms: $synonyms
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
