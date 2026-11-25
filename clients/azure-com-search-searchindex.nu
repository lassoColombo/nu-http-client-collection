# Auto-generated client for SearchIndexClient v2019-05-06-Preview
# Source: https://api.apis.guru/v2/specs/azure.com/search-searchindex/2019-05-06-Preview/swagger.json
# Auth: --token flag or $env.SEARCHINDEXCLIENT_TOKEN

const CLIENT = {
  base_url: "https://{searchServiceName}.search.windows.net/indexes('{indexName}')"
  token_env_var: "SEARCHINDEXCLIENT_TOKEN"
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

def base-url-completer [] { ["https://{searchServiceName}.search.windows.net/indexes('{indexName}')"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def query-type-completer [] { ["full" "simple"] }
def search-mode-completer [] { ["all" "any"] }
def autocomplete-mode-completer [] { ["oneTerm" "oneTermWithContext" "twoTerms"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    documents-search-get: "record<\"@odata.count\": int, \"@odata.nextLink\": string, \"@search.coverage\": float, \"@search.facets\": record, \"@search.nextPageParameters\": record<count: bool, facets: list<string>, filter: string, highlight: string, highlightPostTag: string, highlightPreTag: string, minimumCoverage: float, orderby: string, queryType: string, scoringParameters: list<string>, scoringProfile: string, search: string, searchFields: string, searchMode: string, select: string, skip: int, top: int>, value: table<\"@search.highlights\": record, \"@search.score\": float>>"
    documents-get: "record"
    documents-count: "int"
    documents-autocomplete-get: "record<value: table<queryPlusText: string, text: string>>"
    documents-index: "record<value: table<errorMessage: string, key: string, status: bool, statusCode: int>>"
    documents-autocomplete-post: "record<value: table<queryPlusText: string, text: string>>"
    documents-search-post: "record<\"@odata.count\": int, \"@odata.nextLink\": string, \"@search.coverage\": float, \"@search.facets\": record, \"@search.nextPageParameters\": record<count: bool, facets: list<string>, filter: string, highlight: string, highlightPostTag: string, highlightPreTag: string, minimumCoverage: float, orderby: string, queryType: string, scoringParameters: list<string>, scoringProfile: string, search: string, searchFields: string, searchMode: string, select: string, skip: int, top: int>, value: table<\"@search.highlights\": record, \"@search.score\": float>>"
    documents-suggest-post: "record<\"@search.coverage\": float, value: table<\"@search.text\": string>>"
    documents-suggest-get: "record<\"@search.coverage\": float, value: table<\"@search.text\": string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["documents-search-get" "documents-get" "documents-count" "documents-autocomplete-get" "documents-index" "documents-autocomplete-post" "documents-search-post" "documents-suggest-post" "documents-suggest-get" "commands"] | sort) } | get name | first)
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

# Searches for documents in the index.
#
# GET /docs
# Docs: https://docs.microsoft.com/rest/api/searchservice/Search-Documents
# Returns: record<"@odata.count": int, "@odata.nextLink": string, "@search.coverage": float, "@search.facets": record, "@search.nextPageParameters": record<count: bool, facets: list<string>, filter: string, highlight: string, highlightPostTag: string, highlightPreTag: string, minimumCoverage: float, orderby: string, queryType: string, scoringParameters: list<string>, scoringProfile: string, search: string, searchFields: string, searchMode: string, select: string, skip: int, top: int>, value: table<"@search.highlights": record, "@search.score": float>>
# operationId: Documents_SearchGet
export def "documents-search-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # A full-text search query expression; Use "*" or omit this parameter to match all documents.
  --count: oneof<nothing, bool> # A value that specifies whether to fetch the total count of results. Default is false. Setting this value to true may have a performance impact. Note that the count returned is an approximation.
  --facet: list<string> # The list of facet expressions to apply to the search query. Each facet expression contains a field name, optionally followed by a comma-separated list of name:value pairs.
  --filter: string # The OData $filter expression to apply to the search query.
  --highlight: list<string> # The list of field names to use for hit highlights. Only searchable fields can be used for hit highlighting.
  --highlight-post-tag: string # A string tag that is appended to hit highlights. Must be set with highlightPreTag. Default is </em>.
  --highlight-pre-tag: string # A string tag that is prepended to hit highlights. Must be set with highlightPostTag. Default is <em>.
  --minimum-coverage: float # A number between 0 and 100 indicating the percentage of the index that must be covered by a search query in order for the query to be reported as a success. This parameter can be useful for ensuring search availability even for services with only one replica. The default is 100. (format: double)
  --orderby: list<string> # The list of OData $orderby expressions by which to sort the results. Each expression can be either a field name or a call to either the geo.distance() or the search.score() functions. Each expression can be followed by asc to indicate ascending, and desc to indicate descending. The default is ascending order. Ties will be broken by the match scores of documents. If no OrderBy is specified, the default sort order is descending by document match score. There can be at most 32 $orderby clauses.
  --query-type: string@query-type-completer # A value that specifies the syntax of the search query. The default is 'simple'. Use 'full' if your query uses the Lucene query syntax.
  --scoring-parameter: list<string> # The list of parameter values to be used in scoring functions (for example, referencePointParameter) using the format name-values. For example, if the scoring profile defines a function with a parameter called 'mylocation' the parameter string would be "mylocation--122.2,44.8" (without the quotes).
  --scoring-profile: string # The name of a scoring profile to evaluate match scores for matching documents in order to sort the results.
  --search-fields: list<string> # The list of field names to which to scope the full-text search. When using fielded search (fieldName:searchExpression) in a full Lucene query, the field names of each fielded search expression take precedence over any field names listed in this parameter.
  --search-mode: string@search-mode-completer # A value that specifies whether any or all of the search terms must be matched in order to count the document as a match.
  --select: list<string> # The list of fields to retrieve. If unspecified, all fields marked as retrievable in the schema are included.
  --skip: int # The number of search results to skip. This value cannot be greater than 100,000. If you need to scan documents in sequence, but cannot use $skip due to this limitation, consider using $orderby on a totally-ordered key and $filter with a range query instead. (format: int32)
  --top: int # The number of search results to retrieve. This can be used in conjunction with $skip to implement client-side paging of search results. If results are truncated due to server-side paging, the response will include a continuation token that can be used to issue another Search request for the next page of results. (format: int32)
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/docs"
    query: [{name: search, var: search}, {name: "$count", var: count}, {name: facet, var: facet, style: multi}, {name: "$filter", var: filter}, {name: highlight, var: highlight, style: csv}, {name: highlightPostTag, var: highlight_post_tag}, {name: highlightPreTag, var: highlight_pre_tag}, {name: minimumCoverage, var: minimum_coverage}, {name: "$orderby", var: orderby, style: csv}, {name: queryType, var: query_type}, {name: scoringParameter, var: scoring_parameter, style: multi}, {name: scoringProfile, var: scoring_profile}, {name: searchFields, var: search_fields, style: csv}, {name: searchMode, var: search_mode}, {name: "$select", var: select, style: csv}, {name: "$skip", var: skip}, {name: "$top", var: top}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, count: $count, facet: $facet, filter: $filter, highlight: $highlight, highlight_post_tag: $highlight_post_tag, highlight_pre_tag: $highlight_pre_tag, minimum_coverage: $minimum_coverage, orderby: $orderby, query_type: $query_type, scoring_parameter: $scoring_parameter, scoring_profile: $scoring_profile, search_fields: $search_fields, search_mode: $search_mode, select: $select, skip: $skip, top: $top, api_version: $api_version, client_request_id: $client_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a document from the index.
#
# GET /docs('{key}')
# Docs: https://docs.microsoft.com/rest/api/searchservice/lookup-document
# Returns: record
# operationId: Documents_Get
export def "documents-get" [
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
  --select: list<string> # List of field names to retrieve for the document; Any field not retrieved will be missing from the returned document.
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/docs('{key}')"
    path_params: [{name: key, var: key}]
    query: [{name: "$select", var: select, style: csv}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key, select: $select, api_version: $api_version, client_request_id: $client_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Queries the number of documents in the index.
#
# GET /docs/$count
# Docs: https://docs.microsoft.com/rest/api/searchservice/Count-Documents
# Returns: int
# operationId: Documents_Count
export def "documents-count" [
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
    method: get
    path: "/docs/$count"
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

# Autocompletes incomplete query terms based on input text and matching terms in the index.
#
# GET /docs/search.autocomplete
# Docs: https://docs.microsoft.com/rest/api/searchservice/autocomplete
# Returns: record<value: table<queryPlusText: string, text: string>>
# operationId: Documents_AutocompleteGet
export def "documents-autocomplete-get" [
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
  --search: string # The incomplete term which should be auto-completed. (required)
  --suggester-name: string # The name of the suggester as specified in the suggesters collection that's part of the index definition. (required)
  --autocomplete-mode: string@autocomplete-mode-completer # Specifies the mode for Autocomplete. The default is 'oneTerm'. Use 'twoTerms' to get shingles and 'oneTermWithContext' to use the current context while producing auto-completed terms.
  --filter: string # An OData expression that filters the documents used to produce completed terms for the Autocomplete result.
  --fuzzy: oneof<nothing, bool> # A value indicating whether to use fuzzy matching for the autocomplete query. Default is false. When set to true, the query will find terms even if there's a substituted or missing character in the search text. While this provides a better experience in some scenarios, it comes at a performance cost as fuzzy autocomplete queries are slower and consume more resources.
  --highlight-post-tag: string # A string tag that is appended to hit highlights. Must be set with highlightPreTag. If omitted, hit highlighting is disabled.
  --highlight-pre-tag: string # A string tag that is prepended to hit highlights. Must be set with highlightPostTag. If omitted, hit highlighting is disabled.
  --minimum-coverage: float # A number between 0 and 100 indicating the percentage of the index that must be covered by an autocomplete query in order for the query to be reported as a success. This parameter can be useful for ensuring search availability even for services with only one replica. The default is 80. (format: double)
  --search-fields: list<string> # The list of field names to consider when querying for auto-completed terms. Target fields must be included in the specified suggester.
  --top: int # The number of auto-completed terms to retrieve. This must be a value between 1 and 100. The default is 5. (format: int32)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/docs/search.autocomplete"
    query: [{name: api-version, var: api_version, required: true}, {name: search, var: search, required: true}, {name: suggesterName, var: suggester_name, required: true}, {name: autocompleteMode, var: autocomplete_mode}, {name: "$filter", var: filter}, {name: fuzzy, var: fuzzy}, {name: highlightPostTag, var: highlight_post_tag}, {name: highlightPreTag, var: highlight_pre_tag}, {name: minimumCoverage, var: minimum_coverage}, {name: searchFields, var: search_fields, style: csv}, {name: "$top", var: top}]
    header: [{name: client-request-id, var: client_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, search: $search, suggester_name: $suggester_name, autocomplete_mode: $autocomplete_mode, filter: $filter, fuzzy: $fuzzy, highlight_post_tag: $highlight_post_tag, highlight_pre_tag: $highlight_pre_tag, minimum_coverage: $minimum_coverage, search_fields: $search_fields, top: $top, client_request_id: $client_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends a batch of document write actions to the index.
#
# POST /docs/search.index
# Docs: https://docs.microsoft.com/rest/api/searchservice/addupdate-or-delete-documents
# Returns: record<value: table<errorMessage: string, key: string, status: bool, statusCode: int>>
# operationId: Documents_Index
export def "documents-index" [
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
  value: list # The actions in the batch. — item shape: {@search.action?: "upload"|"merge"|"mergeOrUpload"|"delete"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/docs/search.index"
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200, 207]
    auth: bearer
  } {
    api_version: $api_version, client_request_id: $client_request_id, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Autocompletes incomplete query terms based on input text and matching terms in the index.
#
# POST /docs/search.post.autocomplete
# Docs: https://docs.microsoft.com/rest/api/searchservice/autocomplete
# Returns: record<value: table<queryPlusText: string, text: string>>
# operationId: Documents_AutocompletePost
export def "documents-autocomplete-post" [
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
  --autocomplete-mode: string@autocomplete-mode-completer # Specifies the mode for Autocomplete. The default is 'oneTerm'. Use 'twoTerms' to get shingles and 'oneTermWithContext' to use the current context in producing autocomplete terms.
  --filter: string # An OData expression that filters the documents used to produce completed terms for the Autocomplete result.
  --fuzzy: oneof<nothing, bool> # A value indicating whether to use fuzzy matching for the autocomplete query. Default is false. When set to true, the query will autocomplete terms even if there's a substituted or missing character in the search text. While this provides a better experience in some scenarios, it comes at a performance cost as fuzzy autocomplete queries are slower and consume more resources.
  --highlight-post-tag: string # A string tag that is appended to hit highlights. Must be set with highlightPreTag. If omitted, hit highlighting is disabled.
  --highlight-pre-tag: string # A string tag that is prepended to hit highlights. Must be set with highlightPostTag. If omitted, hit highlighting is disabled.
  --minimum-coverage: float # A number between 0 and 100 indicating the percentage of the index that must be covered by an autocomplete query in order for the query to be reported as a success. This parameter can be useful for ensuring search availability even for services with only one replica. The default is 80. (format: double)
  --search: string # The search text on which to base autocomplete results.
  --search-fields: string # The comma-separated list of field names to consider when querying for auto-completed terms. Target fields must be included in the specified suggester.
  --suggester-name: string # The name of the suggester as specified in the suggesters collection that's part of the index definition.
  --top: int # The number of auto-completed terms to retrieve. This must be a value between 1 and 100. The default is 5. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/docs/search.post.autocomplete"
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: autocompleteMode, var: autocomplete_mode}, {name: filter, var: filter}, {name: fuzzy, var: fuzzy}, {name: highlightPostTag, var: highlight_post_tag}, {name: highlightPreTag, var: highlight_pre_tag}, {name: minimumCoverage, var: minimum_coverage}, {name: search, var: search}, {name: searchFields, var: search_fields}, {name: suggesterName, var: suggester_name}, {name: top, var: top}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, client_request_id: $client_request_id, autocomplete_mode: $autocomplete_mode, filter: $filter, fuzzy: $fuzzy, highlight_post_tag: $highlight_post_tag, highlight_pre_tag: $highlight_pre_tag, minimum_coverage: $minimum_coverage, search: $search, search_fields: $search_fields, suggester_name: $suggester_name, top: $top
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Searches for documents in the index.
#
# POST /docs/search.post.search
# Docs: https://docs.microsoft.com/rest/api/searchservice/Search-Documents
# Returns: record<"@odata.count": int, "@odata.nextLink": string, "@search.coverage": float, "@search.facets": record, "@search.nextPageParameters": record<count: bool, facets: list<string>, filter: string, highlight: string, highlightPostTag: string, highlightPreTag: string, minimumCoverage: float, orderby: string, queryType: string, scoringParameters: list<string>, scoringProfile: string, search: string, searchFields: string, searchMode: string, select: string, skip: int, top: int>, value: table<"@search.highlights": record, "@search.score": float>>
# operationId: Documents_SearchPost
export def "documents-search-post" [
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
  --count: oneof<nothing, bool> # A value that specifies whether to fetch the total count of results. Default is false. Setting this value to true may have a performance impact. Note that the count returned is an approximation.
  --facets: list<string> # The list of facet expressions to apply to the search query. Each facet expression contains a field name, optionally followed by a comma-separated list of name:value pairs.
  --filter: string # The OData $filter expression to apply to the search query.
  --highlight: string # The comma-separated list of field names to use for hit highlights. Only searchable fields can be used for hit highlighting.
  --highlight-post-tag: string # A string tag that is appended to hit highlights. Must be set with highlightPreTag. Default is </em>.
  --highlight-pre-tag: string # A string tag that is prepended to hit highlights. Must be set with highlightPostTag. Default is <em>.
  --minimum-coverage: float # A number between 0 and 100 indicating the percentage of the index that must be covered by a search query in order for the query to be reported as a success. This parameter can be useful for ensuring search availability even for services with only one replica. The default is 100. (format: double)
  --orderby: string # The comma-separated list of OData $orderby expressions by which to sort the results. Each expression can be either a field name or a call to either the geo.distance() or the search.score() functions. Each expression can be followed by asc to indicate ascending, or desc to indicate descending. The default is ascending order. Ties will be broken by the match scores of documents. If no $orderby is specified, the default sort order is descending by document match score. There can be at most 32 $orderby clauses.
  --query-type: string@query-type-completer # Specifies the syntax of the search query. The default is 'simple'. Use 'full' if your query uses the Lucene query syntax.
  --scoring-parameters: list<string> # The list of parameter values to be used in scoring functions (for example, referencePointParameter) using the format name-values. For example, if the scoring profile defines a function with a parameter called 'mylocation' the parameter string would be "mylocation--122.2,44.8" (without the quotes).
  --scoring-profile: string # The name of a scoring profile to evaluate match scores for matching documents in order to sort the results.
  --search: string # A full-text search query expression; Use "*" or omit this parameter to match all documents.
  --search-fields: string # The comma-separated list of field names to which to scope the full-text search. When using fielded search (fieldName:searchExpression) in a full Lucene query, the field names of each fielded search expression take precedence over any field names listed in this parameter.
  --search-mode: string@search-mode-completer # Specifies whether any or all of the search terms must be matched in order to count the document as a match.
  --select: string # The comma-separated list of fields to retrieve. If unspecified, all fields marked as retrievable in the schema are included.
  --skip: int # The number of search results to skip. This value cannot be greater than 100,000. If you need to scan documents in sequence, but cannot use skip due to this limitation, consider using orderby on a totally-ordered key and filter with a range query instead. (format: int32)
  --top: int # The number of search results to retrieve. This can be used in conjunction with $skip to implement client-side paging of search results. If results are truncated due to server-side paging, the response will include a continuation token that can be used to issue another Search request for the next page of results. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/docs/search.post.search"
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: count, var: count}, {name: facets, var: facets}, {name: filter, var: filter}, {name: highlight, var: highlight}, {name: highlightPostTag, var: highlight_post_tag}, {name: highlightPreTag, var: highlight_pre_tag}, {name: minimumCoverage, var: minimum_coverage}, {name: orderby, var: orderby}, {name: queryType, var: query_type}, {name: scoringParameters, var: scoring_parameters}, {name: scoringProfile, var: scoring_profile}, {name: search, var: search}, {name: searchFields, var: search_fields}, {name: searchMode, var: search_mode}, {name: select, var: select}, {name: skip, var: skip}, {name: top, var: top}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, client_request_id: $client_request_id, count: $count, facets: $facets, filter: $filter, highlight: $highlight, highlight_post_tag: $highlight_post_tag, highlight_pre_tag: $highlight_pre_tag, minimum_coverage: $minimum_coverage, orderby: $orderby, query_type: $query_type, scoring_parameters: $scoring_parameters, scoring_profile: $scoring_profile, search: $search, search_fields: $search_fields, search_mode: $search_mode, select: $select, skip: $skip, top: $top
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Suggests documents in the index that match the given partial query text.
#
# POST /docs/search.post.suggest
# Docs: https://docs.microsoft.com/rest/api/searchservice/suggestions
# Returns: record<"@search.coverage": float, value: table<"@search.text": string>>
# operationId: Documents_SuggestPost
export def "documents-suggest-post" [
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
  --filter: string # An OData expression that filters the documents considered for suggestions.
  --fuzzy: oneof<nothing, bool> # A value indicating whether to use fuzzy matching for the suggestion query. Default is false. When set to true, the query will find suggestions even if there's a substituted or missing character in the search text. While this provides a better experience in some scenarios, it comes at a performance cost as fuzzy suggestion searches are slower and consume more resources.
  --highlight-post-tag: string # A string tag that is appended to hit highlights. Must be set with highlightPreTag. If omitted, hit highlighting of suggestions is disabled.
  --highlight-pre-tag: string # A string tag that is prepended to hit highlights. Must be set with highlightPostTag. If omitted, hit highlighting of suggestions is disabled.
  --minimum-coverage: float # A number between 0 and 100 indicating the percentage of the index that must be covered by a suggestion query in order for the query to be reported as a success. This parameter can be useful for ensuring search availability even for services with only one replica. The default is 80. (format: double)
  --orderby: string # The comma-separated list of OData $orderby expressions by which to sort the results. Each expression can be either a field name or a call to either the geo.distance() or the search.score() functions. Each expression can be followed by asc to indicate ascending, or desc to indicate descending. The default is ascending order. Ties will be broken by the match scores of documents. If no $orderby is specified, the default sort order is descending by document match score. There can be at most 32 $orderby clauses.
  --search: string # The search text to use to suggest documents. Must be at least 1 character, and no more than 100 characters.
  --search-fields: string # The comma-separated list of field names to search for the specified search text. Target fields must be included in the specified suggester.
  --select: string # The comma-separated list of fields to retrieve. If unspecified, only the key field will be included in the results.
  --suggester-name: string # The name of the suggester as specified in the suggesters collection that's part of the index definition.
  --top: int # The number of suggestions to retrieve. This must be a value between 1 and 100. The default is 5. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/docs/search.post.suggest"
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: filter, var: filter}, {name: fuzzy, var: fuzzy}, {name: highlightPostTag, var: highlight_post_tag}, {name: highlightPreTag, var: highlight_pre_tag}, {name: minimumCoverage, var: minimum_coverage}, {name: orderby, var: orderby}, {name: search, var: search}, {name: searchFields, var: search_fields}, {name: select, var: select}, {name: suggesterName, var: suggester_name}, {name: top, var: top}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, client_request_id: $client_request_id, filter: $filter, fuzzy: $fuzzy, highlight_post_tag: $highlight_post_tag, highlight_pre_tag: $highlight_pre_tag, minimum_coverage: $minimum_coverage, orderby: $orderby, search: $search, search_fields: $search_fields, select: $select, suggester_name: $suggester_name, top: $top
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Suggests documents in the index that match the given partial query text.
#
# GET /docs/search.suggest
# Docs: https://docs.microsoft.com/rest/api/searchservice/suggestions
# Returns: record<"@search.coverage": float, value: table<"@search.text": string>>
# operationId: Documents_SuggestGet
export def "documents-suggest-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # The search text to use to suggest documents. Must be at least 1 character, and no more than 100 characters. (required)
  --suggester-name: string # The name of the suggester as specified in the suggesters collection that's part of the index definition. (required)
  --filter: string # An OData expression that filters the documents considered for suggestions.
  --fuzzy: oneof<nothing, bool> # A value indicating whether to use fuzzy matching for the suggestions query. Default is false. When set to true, the query will find terms even if there's a substituted or missing character in the search text. While this provides a better experience in some scenarios, it comes at a performance cost as fuzzy suggestions queries are slower and consume more resources.
  --highlight-post-tag: string # A string tag that is appended to hit highlights. Must be set with highlightPreTag. If omitted, hit highlighting of suggestions is disabled.
  --highlight-pre-tag: string # A string tag that is prepended to hit highlights. Must be set with highlightPostTag. If omitted, hit highlighting of suggestions is disabled.
  --minimum-coverage: float # A number between 0 and 100 indicating the percentage of the index that must be covered by a suggestions query in order for the query to be reported as a success. This parameter can be useful for ensuring search availability even for services with only one replica. The default is 80. (format: double)
  --orderby: list<string> # The list of OData $orderby expressions by which to sort the results. Each expression can be either a field name or a call to either the geo.distance() or the search.score() functions. Each expression can be followed by asc to indicate ascending, or desc to indicate descending. The default is ascending order. Ties will be broken by the match scores of documents. If no $orderby is specified, the default sort order is descending by document match score. There can be at most 32 $orderby clauses.
  --search-fields: list<string> # The list of field names to search for the specified search text. Target fields must be included in the specified suggester.
  --select: list<string> # The list of fields to retrieve. If unspecified, only the key field will be included in the results.
  --top: int # The number of suggestions to retrieve. The value must be a number between 1 and 100. The default is 5. (format: int32)
  --api-version: string # Client Api Version. (required)
  --client-request-id: string # The tracking ID sent with the request to help with debugging. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/docs/search.suggest"
    query: [{name: search, var: search, required: true}, {name: suggesterName, var: suggester_name, required: true}, {name: "$filter", var: filter}, {name: fuzzy, var: fuzzy}, {name: highlightPostTag, var: highlight_post_tag}, {name: highlightPreTag, var: highlight_pre_tag}, {name: minimumCoverage, var: minimum_coverage}, {name: "$orderby", var: orderby, style: csv}, {name: searchFields, var: search_fields, style: csv}, {name: "$select", var: select, style: csv}, {name: "$top", var: top}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, suggester_name: $suggester_name, filter: $filter, fuzzy: $fuzzy, highlight_post_tag: $highlight_post_tag, highlight_pre_tag: $highlight_pre_tag, minimum_coverage: $minimum_coverage, orderby: $orderby, search_fields: $search_fields, select: $select, top: $top, api_version: $api_version, client_request_id: $client_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
