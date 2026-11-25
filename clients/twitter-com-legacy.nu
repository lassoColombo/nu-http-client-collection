# Auto-generated client for Twitter API v1.1
# Source: https://api.apis.guru/v2/specs/twitter.com/legacy/1.1/swagger.json
# Auth: --token flag or $env.TWITTER_API_TOKEN

const CLIENT = {
  base_url: "https://api.twitter.com/1.1"
  token_env_var: "TWITTER_API_TOKEN"
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

def base-url-completer [] { ["https://api.twitter.com/1.1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def align-completer [] { ["center" "left" "none" "right"] }
def display-coordinates-completer [] { ["" "false" "true"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {}
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["account-settings-get" "account-settings-post" "account-update-delivery-device" "account-update-profile" "accounts-update-profile-background-image" "accounts-update-profile-colors" "accounts-update-profile-image" "application-rate-limit-status" "blocks-create" "blocks-destroy" "blocks-ids" "blocks-list" "direct-messages" "direct-messages-destroy" "direct-messages-new" "direct-messages-sent" "direct-messages-show" "favorites-create" "favorites-destroy" "favorites-list" "followers-ids" "friends-ids" "friendships-create" "friendships-destroy" "friendships-incoming" "friendships-lookup" "friendships-outgoing" "friendships-show" "friendships-update" "geo-place-id" "geo-places" "geo-reverse-geocode" "geo-search" "geo-similar-places" "help-configurations" "help-languages" "help-privacy" "help-tos" "lists-create" "lists-destroy" "lists-list" "lists-members" "lists-members-create" "lists-members-create-all" "lists-members-destroy" "lists-members-destroy-all" "lists-members-show" "lists-memberships" "lists-show" "lists-statuses" "lists-subscribers" "lists-subscribers-create" "lists-subscribers-destroy" "lists-subscribers-show" "lists-subscriptions" "lists-update" "saved-searches-create" "saved-searches-destroy" "saved-searches-list" "savedsearchesid" "search-tweets" "statuses-destroy" "statuses-home-timeline" "statuses-mentions-timeline" "statuses-oembed" "statusesretweetid" "statuses-retweets" "statuses-show" "statuses-update" "statuses-update-with-media" "statuses-user-timeline" "trends-available" "trends-closest" "trends-place" "users-contributees" "users-contributors" "users-lookup" "users-report-spam" "users-search" "users-show" "users-suggestions" "users-suggestions-slug" "users-suggestionsslugmembers" "commands"] | sort) } | get name | first)
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

# Returns settings (including current trend, geo and sleep time information) for the authenticating user.
#
# GET /account/settings.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/account/settings
# operationId: account.settings.get
export def "account-settings-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trend-location-woeid: string # The Yahoo! Where On Earth ID to use as the user's default trend location. Global information is available by using 1 as the WOEID. The woeid must be one of the locations returned by GET trends/available. Example Values: 1
  --sleep-time-enabled: string # When set to true, t or 1, will enable sleep time for the user. Sleep time is the time when push or SMS notifications should not be sent to the user. Example Values: true
  --start-sleep-time: string # The hour that sleep time should begin if it is enabled. The value for this parameter should be provided in ISO8601 format (i.e. 00-23). The time is considered to be in the same timezone as the user's time_zone setting. Example Values: 13
  --end-sleep-time: string # The hour that sleep time should end if it is enabled. The value for this parameter should be provided in ISO8601 format (i.e. 00-23). The time is considered to be in the same timezone as the user's time_zone setting. Example Values: 13
  --time-zone: string # The timezone dates and times should be displayed in for the user. The timezone must be one of the Rails TimeZone names. Example Values: Europe/Copenhagen, Pacific/Tongatapu
  --lang: string # The language which Twitter should render in for this user. The language must be specified by the appropriate two letter ISO 639-1 representation. Currently supported languages are provided by GET help/languages. Example Values: it, en, es
]: nothing -> any {
  http-request {
    method: get
    path: "/account/settings.json"
    query: [{name: trend_location_woeid, var: trend_location_woeid}, {name: sleep_time_enabled, var: sleep_time_enabled}, {name: start_sleep_time, var: start_sleep_time}, {name: end_sleep_time, var: end_sleep_time}, {name: time_zone, var: time_zone}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    trend_location_woeid: $trend_location_woeid, sleep_time_enabled: $sleep_time_enabled, start_sleep_time: $start_sleep_time, end_sleep_time: $end_sleep_time, time_zone: $time_zone, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the authenticating user's settings.
#
# POST /account/settings.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/account/settings
# operationId: account.settings.post
export def "account-settings-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trend-location-woeid: string # The Yahoo! Where On Earth ID to use as the user's default trend location. Global information is available by using 1 as the WOEID. The woeid must be one of the locations returned by GET trends/available. Example Values: 1
  --sleep-time-enabled: string # When set to true, t or 1, will enable sleep time for the user. Sleep time is the time when push or SMS notifications should not be sent to the user. Example Values: true
  --start-sleep-time: string # The hour that sleep time should begin if it is enabled. The value for this parameter should be provided in ISO8601 format (i.e. 00-23). The time is considered to be in the same timezone as the user's time_zone setting. Example Values: 13
  --end-sleep-time: string # The hour that sleep time should end if it is enabled. The value for this parameter should be provided in ISO8601 format (i.e. 00-23). The time is considered to be in the same timezone as the user's time_zone setting. Example Values: 13
  --time-zone: string # The timezone dates and times should be displayed in for the user. The timezone must be one of the Rails TimeZone names. Example Values: Europe/Copenhagen, Pacific/Tongatapu
  --lang: string # The language which Twitter should render in for this user. The language must be specified by the appropriate two letter ISO 639-1 representation. Currently supported languages are provided by GET help/languages. Example Values: it, en, es
]: nothing -> any {
  http-request {
    method: post
    path: "/account/settings.json"
    query: [{name: trend_location_woeid, var: trend_location_woeid}, {name: sleep_time_enabled, var: sleep_time_enabled}, {name: start_sleep_time, var: start_sleep_time}, {name: end_sleep_time, var: end_sleep_time}, {name: time_zone, var: time_zone}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    trend_location_woeid: $trend_location_woeid, sleep_time_enabled: $sleep_time_enabled, start_sleep_time: $start_sleep_time, end_sleep_time: $end_sleep_time, time_zone: $time_zone, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets which device Twitter delivers updates to for the authenticating user. Sending none as the device parameter will disable SMS updates.
#
# POST /account/update_delivery_device.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/account/update_delivery_device
# operationId: account.update_delivery_device
export def "account-update-delivery-device" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device: string # Must be one of: sms, none. Example Values: sms (required)
  --include-entities: string # When set to either true, t or 1, each tweet will include a node called "entities,". This node offers a variety of metadata about the tweet in a discreet structure, including: user_mentions, urls, and hashtags. While entities are opt-in on timelines at present, they will be made a default component of output in the future. See Tweet Entities for more detail on entities. Example Values: true
]: nothing -> any {
  http-request {
    method: post
    path: "/account/update_delivery_device.json"
    query: [{name: device, var: device, required: true}, {name: include_entities, var: include_entities}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    device: $device, include_entities: $include_entities
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets values that users are able to set under the Account tab of their settings page. Only the parameters specified will be updated.
#
# POST /account/update_profile.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/account/update_profile
# operationId: account.update_profile
export def "account-update-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Full name associated with the profile. Maximum of 20 characters. Example Values: Marcel Molina
  --url: string # URL associated with the profile. Will be prepended with "http://" if not present. Maximum of 100 characters. Example Values: http://project.ioni.st
  --location: string # The city or country describing where the user of the account is located. The contents are not normalized or geocoded in any way. Maximum of 30 characters. Example Values: San Francisco, CA
  --description: string # A description of the user owning the account. Maximum of 160 characters. Example Values: Flipped my wig at age 22 and it never grew back. Also: I work at Twitter.
  --include-entities: string # The entities node will not be included when set to false. Example Values: false
  --skip-status: string # When set to either true, t or 1 statuses will not be included in the returned user objects.
]: nothing -> any {
  http-request {
    method: post
    path: "/account/update_profile.json"
    query: [{name: name, var: name}, {name: url, var: url}, {name: location, var: location}, {name: description, var: description}, {name: include_entities, var: include_entities}, {name: skip_status, var: skip_status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, url: $url, location: $location, description: $description, include_entities: $include_entities, skip_status: $skip_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the authenticating user's profile background image. This method can also be used to enable or disable the profile background image. Although each parameter is marked as optional, at least one of image, tile or use must be provided when making this request.
#
# POST /account/update_profile_background_image.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/account/update_profile_background_image
# operationId: accounts.update_profile_background_image
export def "accounts-update-profile-background-image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tile: string # Whether or not to tile the background image. If set to true, t or 1 the background image will be displayed tiled. The image will not be tiled otherwise.
  --use: string # Determines whether to display the profile background image or not. When set to true, t or 1 the background image will be displayed if an image is being uploaded with the request, or has been uploaded previously. An error will be returned if you try to use a background image when one is not being uploaded or does not exist. If this parameter is defined but set to anything other than true, t or 1, the background image will stop being used.
  --include-entities: string # The entities node will not be included when set to false. Example Values: false
  --skip-status: string # When set to either true, t or 1 statuses will not be included in the returned user objects.
  --content-type: string # Content type header (required, default: multipart/form-data)
]: nothing -> any {
  http-request {
    method: post
    path: "/account/update_profile_background_image.json"
    query: [{name: tile, var: tile}, {name: use, var: use}, {name: include_entities, var: include_entities}, {name: skip_status, var: skip_status}]
    header: [{name: Content-Type, var: content_type, required: true, default: "multipart/form-data"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tile: $tile, use: $use, include_entities: $include_entities, skip_status: $skip_status, content_type: $content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets one or more hex values that control the color scheme of the authenticating user's profile page on twitter.com. Each parameter's value must be a valid hexidecimal value, and may be either three or six characters (ex: #fff or #ffffff).
#
# POST /account/update_profile_colors.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/account/update_profile_colors
# operationId: accounts.update_profile_colors
export def "accounts-update-profile-colors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --profile-background-color: string # Profile background color. Example Values: 3D3D3D
  --profile-link-color: string # Profile link color.Example Values: 0000FF
  --profile-sidebar-border-color: string # Profile sidebar's border color. Example Values: 0F0F0F
  --profile-sidebar-fill-color: string # Profile sidebar's background color. Example Values: 00FF00
  --profile-text-color: string # Profile text color. Example Values: 000000
  --include-entities: string # The entities node will not be included when set to false. Example Values: false
  --skip-status: string # When set to either true, t or 1 statuses will not be included in the returned user objects.
]: nothing -> any {
  http-request {
    method: post
    path: "/account/update_profile_colors.json"
    query: [{name: profile_background_color, var: profile_background_color}, {name: profile_link_color, var: profile_link_color}, {name: profile_sidebar_border_color, var: profile_sidebar_border_color}, {name: profile_sidebar_fill_color, var: profile_sidebar_fill_color}, {name: profile_text_color, var: profile_text_color}, {name: include_entities, var: include_entities}, {name: skip_status, var: skip_status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    profile_background_color: $profile_background_color, profile_link_color: $profile_link_color, profile_sidebar_border_color: $profile_sidebar_border_color, profile_sidebar_fill_color: $profile_sidebar_fill_color, profile_text_color: $profile_text_color, include_entities: $include_entities, skip_status: $skip_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the authenticating user's profile image. Note that this method expects raw multipart data, not a URL to an image. This method asynchronously processes the uploaded file before updating the user's profile image URL. You can either update your local cache the next time you request the user's information, or, at least 5 seconds after uploading the image, ask for the updated URL using GET users/profile_image/:screen_name (https://dev.twitter.com/docs/api/1/get/users/profile_image/:screen_name).
#
# POST /account/update_profile_image.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/account/update_profile_image
# operationId: accounts.update_profile_image
export def "accounts-update-profile-image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip-status: string # When set to either true, t or 1 statuses will not be included in the returned user objects.
  --content-type: string # Content type header (required, default: multipart/form-data)
]: nothing -> any {
  http-request {
    method: post
    path: "/account/update_profile_image.json"
    query: [{name: skip_status, var: skip_status}]
    header: [{name: Content-Type, var: content_type, required: true, default: "multipart/form-data"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    skip_status: $skip_status, content_type: $content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the current rate limits for methods belonging to the specified resource families. Each 1.1 API resource belongs to a "resource family" which is indicated in its method documentation. You can typically determine a method's resource family from the first component of the path after the resource version. This method responds with a map of methods belonging to the families specified by the resources parameter, the current remaining uses for each of those resources within the current rate limiting window, and its expiration time in epoch time. It also includes a rate_limit_context field that indicates the current access token context. You may also issue requests to this method without any parameters to receive a map of all rate limited GET methods. If your application only uses a few of methods, please explicitly provide a resources parameter with the specified resource families you work with.
#
# GET /application/rate_limit_status.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/application/rate_limit_status
# operationId: application.rate_limit_status
export def "application-rate-limit-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resources: string # A comma-separated list of resource families you want to know the current rate limit disposition for. For best performance, only specify the resource families pertinent to your application.Example Values: statuses,friends,trends,help
]: nothing -> any {
  http-request {
    method: get
    path: "/application/rate_limit_status.json"
    query: [{name: resources, var: resources}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resources: $resources
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Blocks the specified user from following the authenticating user. In addition the blocked user will not show in the authenticating users mentions or timeline (unless retweeted by another user). If a follow or friend relationship exists it is destroyed.
#
# POST /blocks/create.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/blocks/create
# operationId: blocks.create
export def "blocks-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-entities: string # The entities node will not be included when set to false. Example Values: false
  --skip-status: string # When set to either true, t or 1 statuses will not be included in the returned user objects.
]: nothing -> any {
  http-request {
    method: post
    path: "/blocks/create.json"
    query: [{name: include_entities, var: include_entities}, {name: skip_status, var: skip_status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    include_entities: $include_entities, skip_status: $skip_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Un-blocks the user specified in the ID parameter for the authenticating user. Returns the un-blocked user in the requested format when successful. If relationships existed before the block was instated, they will not be restored.
#
# POST /blocks/destroy.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/blocks/destroy
# operationId: blocks.destroy
export def "blocks-destroy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-entities: string # The entities node will not be included when set to false. Example Values: false
  --skip-status: string # When set to either true, t or 1 statuses will not be included in the returned user objects.
]: nothing -> any {
  http-request {
    method: post
    path: "/blocks/destroy.json"
    query: [{name: include_entities, var: include_entities}, {name: skip_status, var: skip_status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    include_entities: $include_entities, skip_status: $skip_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an array of numeric user ids the authenticating user is blocking.
#
# GET /blocks/ids.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/blocks/ids
# operationId: blocks.ids
export def "blocks-ids" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stringify-ids: string # Many programming environments will not consume our ids due to their size. Provide this option to have ids returned as strings instead. Read more about Twitter IDs, JSON and Snowflake. Example Values: true
  --cursor: string # Causes the list of blocked users to be broken into pages of no more than 5000 IDs at a time. The number of IDs returned is not guaranteed to be 5000 as suspended users are filtered out after connections are queried. If no cursor is provided, a value of -1 will be assumed, which is the first "page." The response from the API will include a previous_cursor and next_cursor to allow paging back and forth. See Using cursors to navigate collections for more information. Example Values: 12893764510938
]: nothing -> any {
  http-request {
    method: get
    path: "/blocks/ids.json"
    query: [{name: stringify_ids, var: stringify_ids}, {name: cursor, var: cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    stringify_ids: $stringify_ids, cursor: $cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows one to enable or disable retweets and device notifications from the specified user.
#
# GET /blocks/list.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/blocks/list
# operationId: blocks.list
export def "blocks-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-entities: string # The entities node will not be included when set to false. Example Values: false
  --skip-status: string # When set to either true, t or 1 statuses will not be included in the returned user objects.
  --cursor: string # Causes the list of blocked users to be broken into pages of no more than 5000 IDs at a time. The number of IDs returned is not guaranteed to be 5000 as suspended users are filtered out after connections are queried. If no cursor is provided, a value of -1 will be assumed, which is the first "page." The response from the API will include a previous_cursor and next_cursor to allow paging back and forth. See Using cursors to navigate collections for more information. Example Values: 12893764510938
]: nothing -> any {
  http-request {
    method: get
    path: "/blocks/list.json"
    query: [{name: include_entities, var: include_entities}, {name: skip_status, var: skip_status}, {name: cursor, var: cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    include_entities: $include_entities, skip_status: $skip_status, cursor: $cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the 20 most recent direct messages sent to the authenticating user. Includes detailed information about the sender and recipient user. You can request up to 200 direct messages per call, up to a maximum of 800 incoming DMs. Important: This method requires an access token with RWD (read, write and direct message) permissions. Consult The Application Permission Model for more information.
#
# GET /direct_messages.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/direct_messages
# operationId: direct_messages
export def "direct-messages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: string # Specifies the number of direct messages to try and retrieve, up to a maximum of 200. The value of count is best thought of as a limit to the number of Tweets to return because suspended or deleted content is removed after the count has been applied. Example Values: 5
  --since-id: string # Returns results with an ID greater than (that is, more recent than) the specified ID. There are limits to the number of Tweets which can be accessed through the API. If the limit of Tweets has occured since the since_id, the since_id will be forced to the oldest ID available. Example Values: 12345
  --max-id: string # Returns results with an ID less than (that is, older than) or equal to the specified ID. Example Values: 54321
  --include-entities: string # The entities node will not be included when set to false. Example Values: false
  --page: string # Specifies the page of results to retrieve. Example Values: 3
  --skip-status: string # When set to either true, t or 1 statuses will not be included in the returned user objects.
]: nothing -> any {
  http-request {
    method: get
    path: "/direct_messages.json"
    query: [{name: count, var: count}, {name: since_id, var: since_id}, {name: max_id, var: max_id}, {name: include_entities, var: include_entities}, {name: page, var: page}, {name: skip_status, var: skip_status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    count: $count, since_id: $since_id, max_id: $max_id, include_entities: $include_entities, page: $page, skip_status: $skip_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Destroys the direct message specified in the required ID parameter. The authenticating user must be the recipient of the specified direct message. Important: This method requires an access token with RWD (read, write and direct message) permissions. Consult The Application Permission Model for more information.
#
# POST /direct_messages/destroy.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/direct_messages/destroy
# operationId: direct_messages.destroy
export def "direct-messages-destroy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The ID of the direct message to delete. Example Values: 1270516771 (required)
  --include-entities: string # The entities node will not be included when set to false. Example Values: false
]: nothing -> any {
  http-request {
    method: post
    path: "/direct_messages/destroy.json"
    query: [{name: id, var: id, required: true}, {name: include_entities, var: include_entities}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include_entities: $include_entities
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends a new direct message to the specified user from the authenticating user. Requires both the user and text parameters and must be a POST. Returns the sent message in the requested format if successful.
#
# POST /direct_messages/new.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/direct_messages/new
# operationId: direct_messages.new
export def "direct-messages-new" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # The text of your direct message. Be sure to URL encode as necessary, and keep the message under 140 characters. Example Values: Meet me behind the cafeteria after school (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/direct_messages/new.json"
    query: [{name: text, var: text, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the 20 most recent direct messages sent by the authenticating user. Includes detailed information about the sender and recipient user. You can request up to 200 direct messages per call, up to a maximum of 800 outgoing DMs. Important: This method requires an access token with RWD (read, write and direct message) permissions. Consult The Application Permission Model for more information.
#
# GET /direct_messages/sent.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/direct_messages/sent
# operationId: direct_messages.sent
export def "direct-messages-sent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: string # Specifies the number of direct messages to try and retrieve, up to a maximum of 200. The value of count is best thought of as a limit to the number of Tweets to return because suspended or deleted content is removed after the count has been applied. Example Values: 5
  --since-id: string # Returns results with an ID greater than (that is, more recent than) the specified ID. There are limits to the number of Tweets which can be accessed through the API. If the limit of Tweets has occured since the since_id, the since_id will be forced to the oldest ID available. Example Values: 12345
  --max-id: string # Returns results with an ID less than (that is, older than) or equal to the specified ID. Example Values: 54321
  --include-entities: string # The entities node will not be included when set to false. Example Values: false
  --page: string # Specifies the page of results to retrieve. Example Values: 3
]: nothing -> any {
  http-request {
    method: get
    path: "/direct_messages/sent.json"
    query: [{name: count, var: count}, {name: since_id, var: since_id}, {name: max_id, var: max_id}, {name: include_entities, var: include_entities}, {name: page, var: page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    count: $count, since_id: $since_id, max_id: $max_id, include_entities: $include_entities, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a single direct message, specified by an id parameter. Like the /1.1/direct_messages.format request, this method will include the user objects of the sender and recipient. Important: This method requires an access token with RWD (read, write and direct message) permissions. Consult The Application Permission Model for more information.
#
# GET /direct_messages/show.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/direct_messages/show
# operationId: direct_messages.show
export def "direct-messages-show" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The ID of the direct message. Example Values: 587424932 (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/direct_messages/show.json"
    query: [{name: id, var: id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Favorites the status specified in the ID parameter as the authenticating user. Returns the favorite status when successful. This process invoked by this method is asynchronous. The immediately returned status may not indicate the resultant favorited status of the tweet. A 200 OK response from this method will indicate whether the intended action was successful or not.
#
# POST /favorites/create.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/favorites/create
# operationId: favorites.create
export def "favorites-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The numerical ID of the desired status. Example Values: 123 (required)
  --include-entities: string # The entities node will be omitted when set to false. Example Values: false
]: nothing -> any {
  http-request {
    method: post
    path: "/favorites/create.json"
    query: [{name: id, var: id, required: true}, {name: include_entities, var: include_entities}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include_entities: $include_entities
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Un-favorites the status specified in the ID parameter as the authenticating user. Returns the un-favorited status in the requested format when successful. This process invoked by this method is asynchronous. The immediately returned status may not indicate the resultant favorited status of the tweet. A 200 OK response from this method will indicate whether the intended action was successful or not.
#
# POST /favorites/destroy.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/favorites/destroy
# operationId: favorites.destroy
export def "favorites-destroy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The numerical ID of the desired status. Example Values: 123 (required)
  --include-entities: string # The entities node will be omitted when set to false. Example Values: false
]: nothing -> any {
  http-request {
    method: post
    path: "/favorites/destroy.json"
    query: [{name: id, var: id, required: true}, {name: include_entities, var: include_entities}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include_entities: $include_entities
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the 20 most recent Tweets favorited by the authenticating or specified user.
#
# GET /favorites/list.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/favorites/list
# operationId: favorites.list
export def "favorites-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: string # Specifies the number of records to retrieve. Must be less than or equal to 200. Defaults to 20. Example Values: 5
  --since-id: string # Returns results with an ID greater than (that is, more recent than) the specified ID. There are limits to the number of Tweets which can be accessed through the API. If the limit of Tweets has occured since the since_id, the since_id will be forced to the oldest ID available. Example Values: 12345
  --max-id: string # Returns results with an ID less than (that is, older than) or equal to the specified ID. Example Values: 54321
  --include-entities: string # The entities node will be omitted when set to false. Example Values: false
]: nothing -> any {
  http-request {
    method: get
    path: "/favorites/list.json"
    query: [{name: count, var: count}, {name: since_id, var: since_id}, {name: max_id, var: max_id}, {name: include_entities, var: include_entities}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    count: $count, since_id: $since_id, max_id: $max_id, include_entities: $include_entities
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a cursored collection of user IDs for every user following the specified user. At this time, results are ordered with the most recent following first — however, this ordering is subject to unannounced change and eventual consistency issues. Results are given in groups of 5,000 user IDs and multiple "pages" of results can be navigated through using the next_cursor value in subsequent requests. See Using cursors to navigate collections for more information. This method is especially powerful when used in conjunction with GET users/lookup, a method that allows you to convert user IDs into full user objects in bulk.
#
# GET /followers/ids.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/followers/ids
# operationId: followers.ids
export def "followers-ids" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stringify-ids: string # Many programming environments will not consume our Tweet ids due to their size. Provide this option to have ids returned as strings instead. Example Values: true
  --cursor: string # Causes the list of connections to be broken into pages of no more than 5000 IDs at a time. The number of IDs returned is not guaranteed to be 5000 as suspended users are filtered out after connections are queried. If no cursor is provided, a value of -1 will be assumed, which is the first "page." The response from the API will include a previous_cursor and next_cursor to allow paging back and forth.Example Values: 12893764510938
]: nothing -> any {
  http-request {
    method: get
    path: "/followers/ids.json"
    query: [{name: stringify_ids, var: stringify_ids}, {name: cursor, var: cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    stringify_ids: $stringify_ids, cursor: $cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a cursored collection of user IDs for every user the specified user is following (otherwise known as their "friends"). At this time, results are ordered with the most recent following first — however, this ordering is subject to unannounced change and eventual consistency issues. Results are given in groups of 5,000 user IDs and multiple "pages" of results can be navigated through using the next_cursor value in subsequent requests. See Using cursors to navigate collections for more information. This method is especially powerful when used in conjunction with GET users/lookup, a method that allows you to convert user IDs into full user objects in bulk.
#
# GET /friends/ids.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/friends/ids
# operationId: friends.ids
export def "friends-ids" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stringify-ids: string # Many programming environments will not consume our Tweet ids due to their size. Provide this option to have ids returned as strings instead. Example Values: true
  --cursor: string # Causes the list of connections to be broken into pages of no more than 5000 IDs at a time. The number of IDs returned is not guaranteed to be 5000 as suspended users are filtered out after connections are queried. If no cursor is provided, a value of -1 will be assumed, which is the first "page." The response from the API will include a previous_cursor and next_cursor to allow paging back and forth.Example Values: 12893764510938
]: nothing -> any {
  http-request {
    method: get
    path: "/friends/ids.json"
    query: [{name: stringify_ids, var: stringify_ids}, {name: cursor, var: cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    stringify_ids: $stringify_ids, cursor: $cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows the authenticating users to follow the user specified in the ID parameter. Returns the befriended user in the requested format when successful. Returns a string describing the failure condition when unsuccessful. If you are already friends with the user a HTTP 403 may be returned, though for performance reasons you may get a 200 OK message even if the friendship already exists. Actions taken in this method are asynchronous and changes will be eventually consistent.
#
# POST /friendships/create.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/friendships/create
# operationId: friendships.create
export def "friendships-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --follow: string # Enable notifications for the target user. Example Values: true
]: nothing -> any {
  http-request {
    method: post
    path: "/friendships/create.json"
    query: [{name: follow, var: follow}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    follow: $follow
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows the authenticating user to unfollow the user specified in the ID parameter. Returns the unfollowed user in the requested format when successful. Returns a string describing the failure condition when unsuccessful. Actions taken in this method are asynchronous and changes will be eventually consistent.
#
# POST /friendships/destroy.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/friendships/destroy
# operationId: friendships.destroy
export def "friendships-destroy" [
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
    path: "/friendships/destroy.json"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the relationships of the authenticating user to the comma-separated list of up to 100 screen_names or user_ids provided. Values for connections can be: following, following_requested, followed_by, none.
#
# GET /friendships/incoming.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/friendships/incoming
# operationId: friendships.incoming
export def "friendships-incoming" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stringify-ids: string # Many programming environments will not consume our Tweet ids due to their size. Provide this option to have ids returned as strings instead. Example Values: true
  --cursor: string # Causes the list of connections to be broken into pages of no more than 5000 IDs at a time. The number of IDs returned is not guaranteed to be 5000 as suspended users are filtered out after connections are queried. If no cursor is provided, a value of -1 will be assumed, which is the first "page." The response from the API will include a previous_cursor and next_cursor to allow paging back and forth.Example Values: 12893764510938
]: nothing -> any {
  http-request {
    method: get
    path: "/friendships/incoming.json"
    query: [{name: stringify_ids, var: stringify_ids}, {name: cursor, var: cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    stringify_ids: $stringify_ids, cursor: $cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the relationships of the authenticating user to the comma-separated list of up to 100 screen_names or user_ids provided. Values for connections can be: following, following_requested, followed_by, none.
#
# GET /friendships/lookup.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/friendships/lookup
# operationId: friendships.lookup
export def "friendships-lookup" [
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
    path: "/friendships/lookup.json"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a collection of numeric IDs for every protected user for whom the authenticating user has a pending follow request.
#
# GET /friendships/outgoing.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/friendships/outgoing
# operationId: friendships.outgoing
export def "friendships-outgoing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stringify-ids: string # Many programming environments will not consume our Tweet ids due to their size. Provide this option to have ids returned as strings instead. Example Values: true
  --cursor: string # Causes the list of connections to be broken into pages of no more than 5000 IDs at a time. The number of IDs returned is not guaranteed to be 5000 as suspended users are filtered out after connections are queried. If no cursor is provided, a value of -1 will be assumed, which is the first "page." The response from the API will include a previous_cursor and next_cursor to allow paging back and forth.Example Values: 12893764510938
]: nothing -> any {
  http-request {
    method: get
    path: "/friendships/outgoing.json"
    query: [{name: stringify_ids, var: stringify_ids}, {name: cursor, var: cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    stringify_ids: $stringify_ids, cursor: $cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns detailed information about the relationship between two arbitrary users.
#
# GET /friendships/show.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/friendships/show
# operationId: friendships.show
export def "friendships-show" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-id: string # The user_id of the subject user. Example Values: 3191321
  --source-screen-name: string # The screen_name of the subject user. Example Values: raffi
  --target-id: string # The user_id of the target user. Example Values: 20 (required)
  --target-screen-name: string # The screen_name of the target user. Example Values: noradio (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/friendships/show.json"
    query: [{name: source_id, var: source_id}, {name: source_screen_name, var: source_screen_name}, {name: target_id, var: target_id, required: true}, {name: target_screen_name, var: target_screen_name, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_id: $source_id, source_screen_name: $source_screen_name, target_id: $target_id, target_screen_name: $target_screen_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows one to enable or disable retweets and device notifications from the specified user.
#
# POST /friendships/update.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/friendships/update
# operationId: friendships.update
export def "friendships-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device: string # Enable/disable device notifications from the target user. Example Values: true, false (required)
  --retweets: string # Enable/disable retweets from the target user. Example Values: true, false (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/friendships/update.json"
    query: [{name: device, var: device, required: true}, {name: retweets, var: retweets, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    device: $device, retweets: $retweets
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all the information about a known place.Example Values: df51dec6f4ee2b2c
#
# GET /geo/id/{place_id}.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/geo/id/%3Aplace_id
# operationId: geo.place_id
export def "geo-place-id" [
  place_id: string
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
    path: "/geo/id/{place_id}.json"
    path_params: [{name: place_id, var: place_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    place_id: $place_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new place object at the given latitude and longitude. Before creating a place you need to query GET geo/similar_places with the latitude, longitude and name of the place you wish to create. The query will return an array of places which are similar to the one you wish to create, and a token. If the place you wish to create isn't in the returned array you can use the token with this method to create a new one.
#
# POST /geo/places.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/geo/place
# operationId: geo.places
export def "geo-places" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attribute-street-address: string # This parameter searches for places which have this given street address. There are other well-known, and application specific attributes available. Custom attributes are also permitted. Learn more about Place Attributes. Example Values: 795%20Folsom%20St
  --callback: string # If supplied, the response will use the JSONP format with a callback of the given name.
]: nothing -> any {
  http-request {
    method: post
    path: "/geo/places.json"
    query: [{name: "attribute:street_address", var: attribute_street_address}, {name: callback, var: callback}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    attribute_street_address: $attribute_street_address, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Given a latitude and a longitude, searches for up to 20 places that can be used as a place_id when updating a status. This request is an informative call and will deliver generalized results about geography
#
# GET /geo/reverse_geocode.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/geo/reverse_geocode
# operationId: geo.reverse_geocode
export def "geo-reverse-geocode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lat: string # The latitude to search around. This parameter will be ignored unless it is inside the range -90.0 to +90.0 (North is positive) inclusive. It will also be ignored if there isn't a corresponding long parameter. Example Values: 37.7821120598956 (required)
  --long: string # The longitude to search around. The valid ranges for longitude is -180.0 to +180.0 (East is positive) inclusive. This parameter will be ignored if outside that range, if it is not a number, if geo_enabled is disabled, or if there not a corresponding lat parameter. Example Values: -122.400612831116 (required)
  --accuracy: string # A hint on the "region" in which to search. If a number, then this is a radius in meters, but it can also take a string that is suffixed with ft to specify feet. If this is not passed in, then it is assumed to be 0m. If coming from a device, in practice, this value is whatever accuracy the device has measuring its location (whether it be coming from a GPS, WiFi triangulation, etc.). Example Values: 5ft
  --granularity: string # This is the minimal granularity of place types to return and must be one of: poi, neighborhood, city, admin or country. If no granularity is provided for the request neighborhood is assumed. Setting this to city, for example, will find places which have a type of city, admin or country. Example Values: city
  --max-results: string # A hint as to the number of results to return. This does not guarantee that the number of results returned will equal max_results, but instead informs how many "nearby" results to return. Ideally, only pass in the number of places you intend to display to the user here. Example Values: 3
  --callback: string # If supplied, the response will use the JSONP format with a callback of the given name.
]: nothing -> any {
  http-request {
    method: get
    path: "/geo/reverse_geocode.json"
    query: [{name: lat, var: lat, required: true}, {name: long, var: long, required: true}, {name: accuracy, var: accuracy}, {name: granularity, var: granularity}, {name: max_results, var: max_results}, {name: callback, var: callback}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    lat: $lat, long: $long, accuracy: $accuracy, granularity: $granularity, max_results: $max_results, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for places that can be attached to a statuses/update. Given a latitude and a longitude pair, an IP address, or a name, this request will return a list of all the valid places that can be used as the place_id when updating a status. Conceptually, a query can be made from the user's location, retrieve a list of places, have the user validate the location he or she is at, and then send the ID of this location with a call to POST statuses/update. This is the recommended method to use find places that can be attached to statuses/update. Unlike GET geo/reverse_geocode which provides raw data access, this endpoint can potentially re-order places with regards to the user who is authenticated. This approach is also preferred for interactive place matching with the user.
#
# GET /geo/search.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/geo/search
# operationId: geo.search
export def "geo-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accuracy: string # A hint on the "region" in which to search. If a number, then this is a radius in meters, but it can also take a string that is suffixed with ft to specify feet. If this is not passed in, then it is assumed to be 0m. If coming from a device, in practice, this value is whatever accuracy the device has measuring its location (whether it be coming from a GPS, WiFi triangulation, etc.). Example Values: 5ft
  --granularity: string # This is the minimal granularity of place types to return and must be one of: poi, neighborhood, city, admin or country. If no granularity is provided for the request neighborhood is assumed. Setting this to city, for example, will find places which have a type of city, admin or country. Example Values: city
  --contained-within: string # This is the place_id which you would like to restrict the search results to. Setting this value means only places within the given place_id will be found. Specify a place_id. For example, to scope all results to places within "San Francisco, CA USA", you would specify a place_id of "5a110d312052166f" Example Values: 247f43d441defc03
  --attribute-street-address: string # This parameter searches for places which have this given street address. There are other well-known, and application specific attributes available. Custom attributes are also permitted. Learn more about Place Attributes. Example Values: 795%20Folsom%20St
  --callback: string # If supplied, the response will use the JSONP format with a callback of the given name.
]: nothing -> any {
  http-request {
    method: get
    path: "/geo/search.json"
    query: [{name: accuracy, var: accuracy}, {name: granularity, var: granularity}, {name: contained_within, var: contained_within}, {name: "attribute:street_address", var: attribute_street_address}, {name: callback, var: callback}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    accuracy: $accuracy, granularity: $granularity, contained_within: $contained_within, attribute_street_address: $attribute_street_address, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Locates places near the given coordinates which are similar in name. Conceptually you would use this method to get a list of known places to choose from first. Then, if the desired place doesn't exist, make a request to POST geo/place to create a new one. The token contained in the response is the token needed to be able to create a new place.
#
# GET /geo/similar_places.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/geo/similar_places
# operationId: geo.similar_places
export def "geo-similar-places" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contained-within: string # This is the place_id which you would like to restrict the search results to. Setting this value means only places within the given place_id will be found. Specify a place_id. For example, to scope all results to places within "San Francisco, CA USA", you would specify a place_id of "5a110d312052166f" Example Values: 247f43d441defc03
  --attribute-street-address: string # This parameter searches for places which have this given street address. There are other well-known, and application specific attributes available. Custom attributes are also permitted. Learn more about Place Attributes. Example Values: 795%20Folsom%20St
  --callback: string # If supplied, the response will use the JSONP format with a callback of the given name.
]: nothing -> any {
  http-request {
    method: get
    path: "/geo/similar_places.json"
    query: [{name: contained_within, var: contained_within}, {name: "attribute:street_address", var: attribute_street_address}, {name: callback, var: callback}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    contained_within: $contained_within, attribute_street_address: $attribute_street_address, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the current configuration used by Twitter including twitter.com slugs which are not usernames, maximum photo resolutions, and t.co URL lengths. It is recommended applications request this endpoint when they are loaded, but no more than once a day.
#
# GET /help/configuration.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/help/configuration
# operationId: help.configurations
export def "help-configurations" [
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
    path: "/help/configuration.json"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of languages supported by Twitter along with their ISO 639-1 code. The ISO 639-1 code is the two letter value to use if you include lang with any of your requests.
#
# GET /help/languages.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/help/languages
# operationId: help.languages
export def "help-languages" [
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
    path: "/help/languages.json"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns Twitter's Privacy Policy
#
# GET /help/privacy.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/help/privacy
# operationId: help.privacy
export def "help-privacy" [
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
    path: "/help/privacy.json"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the Twitter Terms of Service in the requested format. These are not the same as the Developer Rules of the Road.
#
# GET /help/tos.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/help/tos
# operationId: help.tos
export def "help-tos" [
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
    path: "/help/tos.json"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new list for the authenticated user. Note that you can't create more than 20 lists per account.
#
# POST /lists/create.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/lists/create
# operationId: lists.create
export def "lists-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name for the list.A list's name must start with a letter and can consist only of 25 or fewer letters, numbers, "-", or "_" characters. (required)
  --mode: string # Whether your list is public or private. Values can be public or private. If no mode is specified the list will be public.
  --description: string # The description to give the list.
]: nothing -> any {
  http-request {
    method: post
    path: "/lists/create.json"
    query: [{name: name, var: name, required: true}, {name: mode, var: mode}, {name: description, var: description}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, mode: $mode, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified list. The authenticated user must own the list to be able to destroy it.
#
# POST /lists/destroy.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/lists/destroy
# operationId: lists.destroy
export def "lists-destroy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner-screen-name: string # The screen name of the user who owns the list being requested by a slug.
  --owner-id: string # The user ID of the user who owns the list being requested by a slug.
]: nothing -> any {
  http-request {
    method: post
    path: "/lists/destroy.json"
    query: [{name: owner_screen_name, var: owner_screen_name}, {name: owner_id, var: owner_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner_screen_name: $owner_screen_name, owner_id: $owner_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all lists the authenticating or specified user subscribes to, including their own. The user is specified using the user_id or screen_name parameters. If no user is given, the authenticating user is used. This method used to be GET lists in version 1.0 of the API and has been renamed for consistency with other call.
#
# GET /lists/list.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/lists/list
# operationId: lists.list
export def "lists-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --screen-name: string # The screen name of the user for whom to return results for. Helpful for disambiguating when a valid screen name is also a user ID. Example Values: noradio (required)
  --user-id: string # The ID of the user for whom to return results for. Helpful for disambiguating when a valid user ID is also a valid screen name. Example Values: 12345 Note:: Specifies the ID of the user to get lists from. Helpful for disambiguating when a valid user ID is also a valid screen name. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/lists/list.json"
    query: [{name: screen_name, var: screen_name, required: true}, {name: user_id, var: user_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    screen_name: $screen_name, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the members of the specified list. Private list members will only be shown if the authenticated user owns the specified list.
#
# GET /lists/members.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/lists/members
# operationId: lists.members
export def "lists-members" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner-screen-name: string # The screen name of the user who owns the list being requested by a slug.
  --owner-id: string # The user ID of the user who owns the list being requested by a slug.
  --include-entities: string # The entities node will be disincluded when set to false. Example Values: false
  --skip-status: string # When set to either true, t or 1 statuses will not be included in the returned user objects.
  --cursor: string # Causes the collection of list members to be broken into "pages" of somewhat consistent size. If no cursor is provided, a value of -1 will be assumed, which is the first "page." The response from the API will include a previous_cursor and next_cursor to allow paging back and forth. See Using cursors to navigate collections for more information. Example Values: 12893764510938
]: nothing -> any {
  http-request {
    method: get
    path: "/lists/members.json"
    query: [{name: owner_screen_name, var: owner_screen_name}, {name: owner_id, var: owner_id}, {name: include_entities, var: include_entities}, {name: skip_status, var: skip_status}, {name: cursor, var: cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner_screen_name: $owner_screen_name, owner_id: $owner_id, include_entities: $include_entities, skip_status: $skip_status, cursor: $cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a member to a list. The authenticated user must own the list to be able to add members to it. Note that lists can't have more than 500 members.
#
# POST /lists/members/create.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/lists/members/create
# operationId: lists.members.create
export def "lists-members-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner-screen-name: string # The screen name of the user who owns the list being requested by a slug.
  --owner-id: string # The user ID of the user who owns the list being requested by a slug.
]: nothing -> any {
  http-request {
    method: post
    path: "/lists/members/create.json"
    query: [{name: owner_screen_name, var: owner_screen_name}, {name: owner_id, var: owner_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner_screen_name: $owner_screen_name, owner_id: $owner_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds multiple members to a list, by specifying a comma-separated list of member ids or screen names. The authenticated user must own the list to be able to add members to it. Note that lists can't have more than 500 members, and you are limited to adding up to 100 members to a list at a time with this method. Please note that there can be issues with lists that rapidly remove and add memberships. Take care when using these methods such that you are not too rapidly switching between removals and adds on the same list.
#
# POST /lists/members/create_all.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/lists/members/create_all
# operationId: lists.members.create_all
export def "lists-members-create-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner-screen-name: string # The screen name of the user who owns the list being requested by a slug.
  --owner-id: string # The user ID of the user who owns the list being requested by a slug.
  --user-id: string # A comma separated list of user IDs, up to 100 are allowed in a single request.
  --screen-name: string # A comma separated list of screen names, up to 100 are allowed in a single request.
]: nothing -> any {
  http-request {
    method: post
    path: "/lists/members/create_all.json"
    query: [{name: owner_screen_name, var: owner_screen_name}, {name: owner_id, var: owner_id}, {name: user_id, var: user_id}, {name: screen_name, var: screen_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner_screen_name: $owner_screen_name, owner_id: $owner_id, user_id: $user_id, screen_name: $screen_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the specified member from the list. The authenticated user must be the list's owner to remove members from the list.
#
# POST /lists/members/destroy.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/lists/members/destroy
# operationId: lists.members.destroy
export def "lists-members-destroy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --list-id: string # The numerical id of the list. (required)
  --slug: string # You can identify a list by its slug instead of its numerical id. If you decide to do so, note that you'll also have to specify the list owner using the owner_id or owner_screen_name parameters. (required)
  --owner-screen-name: string # The screen name of the user who owns the list being requested by a slug.
  --owner-id: string # The user ID of the user who owns the list being requested by a slug.
  --user-id: string # The ID of the user to remove from the list. Helpful for disambiguating when a valid user ID is also a valid screen name.
  --screen-name: string # The screen name of the user for whom to remove from the list. Helpful for disambiguating when a valid screen name is also a user ID.
]: nothing -> any {
  http-request {
    method: post
    path: "/lists/members/destroy.json"
    query: [{name: list_id, var: list_id, required: true}, {name: slug, var: slug, required: true}, {name: owner_screen_name, var: owner_screen_name}, {name: owner_id, var: owner_id}, {name: user_id, var: user_id}, {name: screen_name, var: screen_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    list_id: $list_id, slug: $slug, owner_screen_name: $owner_screen_name, owner_id: $owner_id, user_id: $user_id, screen_name: $screen_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes multiple members from a list, by specifying a comma-separated list of member ids or screen names. The authenticated user must own the list to be able to remove members from it. Note that lists can't have more than 500 members, and you are limited to removing up to 100 members to a list at a time with this method. Please note that there can be issues with lists that rapidly remove and add memberships. Take care when using these methods such that you are not too rapidly switching between removals and adds on the same list.
#
# POST /lists/members/destroy_all.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/lists/members/destroy_all
# operationId: lists.members.destroy_all
export def "lists-members-destroy-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner-screen-name: string # The screen name of the user who owns the list being requested by a slug.
  --owner-id: string # The user ID of the user who owns the list being requested by a slug.
  --screen-name: string # A comma separated list of screen names, up to 100 are allowed in a single request.
  --user-id: string # A comma separated list of user IDs, up to 100 are allowed in a single request.
]: nothing -> any {
  http-request {
    method: post
    path: "/lists/members/destroy_all.json"
    query: [{name: owner_screen_name, var: owner_screen_name}, {name: owner_id, var: owner_id}, {name: screen_name, var: screen_name}, {name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner_screen_name: $owner_screen_name, owner_id: $owner_id, screen_name: $screen_name, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if the specified user is a member of the specified list.
#
# GET /lists/members/show.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/lists/members/show
# operationId: lists.members.show
export def "lists-members-show" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner-screen-name: string # The screen name of the user who owns the list being requested by a slug.
  --owner-id: string # The user ID of the user who owns the list being requested by a slug.
  --include-entities: string # When set to either true, t or 1, each tweet will include a node called "entities". This node offers a variety of metadata about the tweet in a discreet structure, including: user_mentions, urls, and hashtags. While entities are opt-in on timelines at present, they will be made a default component of output in the future.
  --skip-status: string # When set to either true, t or 1 statuses will not be included in the returned user objects.
]: nothing -> any {
  http-request {
    method: get
    path: "/lists/members/show.json"
    query: [{name: owner_screen_name, var: owner_screen_name}, {name: owner_id, var: owner_id}, {name: include_entities, var: include_entities}, {name: skip_status, var: skip_status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner_screen_name: $owner_screen_name, owner_id: $owner_id, include_entities: $include_entities, skip_status: $skip_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the lists the specified user has been added to. If user_id or screen_name are not provided the memberships for the authenticating user are returned.
#
# GET /lists/memberships.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/lists/memberships
# operationId: lists.memberships
export def "lists-memberships" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The ID of the user for whom to return results for. Helpful for disambiguating when a valid user ID is also a valid screen name.
  --screen-name: string # The screen name of the user for whom to return results for. Helpful for disambiguating when a valid screen name is also a user ID.
  --cursor: string # Breaks the results into pages. A single page contains 20 lists. Provide a value of -1 to begin paging. Provide values as returned in the response body's next_cursor and previous_cursor attributes to page back and forth in the list.
  --filter-to-owned-lists: string # When set to true, t or 1, will return just lists the authenticating user owns, and the user represented by user_id or screen_name is a member of.
]: nothing -> any {
  http-request {
    method: get
    path: "/lists/memberships.json"
    query: [{name: user_id, var: user_id}, {name: screen_name, var: screen_name}, {name: cursor, var: cursor}, {name: filter_to_owned_lists, var: filter_to_owned_lists}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, screen_name: $screen_name, cursor: $cursor, filter_to_owned_lists: $filter_to_owned_lists
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the specified list. Private lists will only be shown if the authenticated user owns the specified list.
#
# GET /lists/show.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/lists/show
# operationId: lists.show
export def "lists-show" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner-screen-name: string # The screen name of the user who owns the list being requested by a slug.
  --owner-id: string # The user ID of the user who owns the list being requested by a slug.
]: nothing -> any {
  http-request {
    method: get
    path: "/lists/show.json"
    query: [{name: owner_screen_name, var: owner_screen_name}, {name: owner_id, var: owner_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner_screen_name: $owner_screen_name, owner_id: $owner_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns tweet timeline for members of the specified list. Retweets are included by default. You can use the include_rts=false parameter to omit retweet objects.
#
# GET /lists/statuses.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/lists/statuses
# operationId: lists.statuses
export def "lists-statuses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner-screen-name: string # The screen name of the user who owns the list being requested by a slug.
  --owner-id: string # The user ID of the user who owns the list being requested by a slug.
  --since-id: string # Returns results with an ID greater than (that is, more recent than) the specified ID. There are limits to the number of Tweets which can be accessed through the API. If the limit of Tweets has occured since the since_id, the since_id will be forced to the oldest ID available.
  --max-id: string # Returns results with an ID less than (that is, older than) or equal to the specified ID.
  --count: string # Specifies the number of results to retrieve per "page.
  --include-entities: string # Entities are ON by default in API 1.1, each tweet includes a node called "entities". This node offers a variety of metadata about the tweet in a discreet structure, including: user_mentions, urls, and hashtags. You can omit entities from the result by using include_entities=false
  --include-rts: string # When set to either true, t or 1, the list timeline will contain native retweets (if they exist) in addition to the standard stream of tweets. The output format of retweeted tweets is identical to the representation you see in home_timeline. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/lists/statuses.json"
    query: [{name: owner_screen_name, var: owner_screen_name}, {name: owner_id, var: owner_id}, {name: since_id, var: since_id}, {name: max_id, var: max_id}, {name: count, var: count}, {name: include_entities, var: include_entities}, {name: include_rts, var: include_rts, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner_screen_name: $owner_screen_name, owner_id: $owner_id, since_id: $since_id, max_id: $max_id, count: $count, include_entities: $include_entities, include_rts: $include_rts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the subscribers of the specified list. Private list subscribers will only be shown if the authenticated user owns the specified list.
#
# GET /lists/subscribers.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/lists/subscribers
# operationId: lists.subscribers
export def "lists-subscribers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner-screen-name: string # The screen name of the user who owns the list being requested by a slug.
  --owner-id: string # The user ID of the user who owns the list being requested by a slug.
  --cursor: string # Breaks the results into pages. A single page contains 20 lists. Provide a value of -1 to begin paging. Provide values as returned in the response body's next_cursor and previous_cursor attributes to page back and forth in the list.
  --include-entities: string # When set to either true, t or 1, each tweet will include a node called "entities". This node offers a variety of metadata about the tweet in a discreet structure, including: user_mentions, urls, and hashtags. While entities are opt-in on timelines at present, they will be made a default component of output in the future. See Tweet Entities for more details.
  --skip-status: string # When set to either true, t or 1 statuses will not be included in the returned user objects.
]: nothing -> any {
  http-request {
    method: get
    path: "/lists/subscribers.json"
    query: [{name: owner_screen_name, var: owner_screen_name}, {name: owner_id, var: owner_id}, {name: cursor, var: cursor}, {name: include_entities, var: include_entities}, {name: skip_status, var: skip_status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner_screen_name: $owner_screen_name, owner_id: $owner_id, cursor: $cursor, include_entities: $include_entities, skip_status: $skip_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Subscribes the authenticated user to the specified list.
#
# POST /lists/subscribers/create.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/lists/subscribers/create
# operationId: lists.subscribers.create
export def "lists-subscribers-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner-screen-name: string # The screen name of the user who owns the list being requested by a slug.
  --owner-id: string # The user ID of the user who owns the list being requested by a slug.
]: nothing -> any {
  http-request {
    method: post
    path: "/lists/subscribers/create.json"
    query: [{name: owner_screen_name, var: owner_screen_name}, {name: owner_id, var: owner_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner_screen_name: $owner_screen_name, owner_id: $owner_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unsubscribes the authenticated user from the specified list.
#
# POST /lists/subscribers/destroy.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/lists/subscribers/destroy
# operationId: lists.subscribers.destroy
export def "lists-subscribers-destroy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner-screen-name: string # The screen name of the user who owns the list being requested by a slug.
  --owner-id: string # The user ID of the user who owns the list being requested by a slug.
]: nothing -> any {
  http-request {
    method: post
    path: "/lists/subscribers/destroy.json"
    query: [{name: owner_screen_name, var: owner_screen_name}, {name: owner_id, var: owner_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner_screen_name: $owner_screen_name, owner_id: $owner_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if the specified user is a subscriber of the specified list. Returns the user if they are subscriber.
#
# GET /lists/subscribers/show.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/lists/subscribers/show
# operationId: lists.subscribers.show
export def "lists-subscribers-show" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner-screen-name: string # The screen name of the user who owns the list being requested by a slug.
  --owner-id: string # The user ID of the user who owns the list being requested by a slug.
  --include-entities: string # When set to either true, t or 1, each tweet will include a node called "entities". This node offers a variety of metadata about the tweet in a discreet structure, including: user_mentions, urls, and hashtags. While entities are opt-in on timelines at present, they will be made a default component of output in the future. See Tweet Entities for more details.
  --skip-status: string # When set to either true, t or 1 statuses will not be included in the returned user objects.
]: nothing -> any {
  http-request {
    method: get
    path: "/lists/subscribers/show.json"
    query: [{name: owner_screen_name, var: owner_screen_name}, {name: owner_id, var: owner_id}, {name: include_entities, var: include_entities}, {name: skip_status, var: skip_status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner_screen_name: $owner_screen_name, owner_id: $owner_id, include_entities: $include_entities, skip_status: $skip_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Obtain a collection of the lists the specified user is subscribed to, 20 lists per page by default. Does not include the user's own lists.
#
# GET /lists/subscriptions.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/lists/subscriptions
# operationId: lists.subscriptions
export def "lists-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: string # The amount of results to return per page. Defaults to 20. Maximum of 1,000 when using cursors.
  --cursor: string # Breaks the results into pages. A single page contains 20 lists. Provide a value of -1 to begin paging. Provide values as returned in the response body's next_cursor and previous_cursor attributes to page back and forth in the list. It is recommended to always use cursors when the method supports them.
]: nothing -> any {
  http-request {
    method: get
    path: "/lists/subscriptions.json"
    query: [{name: count, var: count}, {name: cursor, var: cursor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    count: $count, cursor: $cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified list. The authenticated user must own the list to be able to update it.
#
# POST /lists/update.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/lists/update
# operationId: lists.update
export def "lists-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner-screen-name: string # The screen name of the user who owns the list being requested by a slug.
  --owner-id: string # The user ID of the user who owns the list being requested by a slug.
  --name: string # The name for the list.
  --mode: string # Whether your list is public or private. Values can be public or private. If no mode is specified the list will be public.
  --description: string # The description to give the list.
]: nothing -> any {
  http-request {
    method: post
    path: "/lists/update.json"
    query: [{name: owner_screen_name, var: owner_screen_name}, {name: owner_id, var: owner_id}, {name: name, var: name}, {name: mode, var: mode}, {name: description, var: description}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner_screen_name: $owner_screen_name, owner_id: $owner_id, name: $name, mode: $mode, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new saved search for the authenticated user. A user may only have 25 saved searches.
#
# POST /saved_searches/create.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/saved_searches/create
# operationId: saved_searches.create
export def "saved-searches-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The query of the search the user would like to save. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/saved_searches/create.json"
    query: [{name: query, var: query, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Destroys a saved search for the authenticating user. The authenticating user must be the owner of saved search id being destroyed.
#
# POST /saved_searches/destroy/{id}.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/saved_searches/destroy/%3Aid
# operationId: saved_searches.destroy
export def "saved-searches-destroy" [
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
    path: "/saved_searches/destroy/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the authenticated user's saved search queries.
#
# GET /saved_searches/list.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/saved_searches/list
# operationId: saved_searches.list
export def "saved-searches-list" [
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
    path: "/saved_searches/list.json"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the authenticated user's saved search queries.
#
# GET /saved_searches/show/{id}.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/saved_searches/show/%3Aid
# operationId: savedsearchesid
export def "savedsearchesid" [
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
    path: "/saved_searches/show/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a collection of relevant Tweets matching a specified query. Please note that Twitter's search service and, by extension, the Search API is not meant to be an exhaustive source of Tweets. Not all Tweets will be indexed or made available via the search interface. In API v1.1, the response format of the Search API has been improved to return Tweet objects more similar to the objects you'll find across the REST API and platform. You may need to tolerate some inconsistencies and variance in perspectival values (fields that pertain to the perspective of the authenticating user) and embedded user objects.
#
# GET /search/tweets.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/search/tweets
# operationId: search.tweets
export def "search-tweets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # A UTF-8, URL-encoded search query of 1,000 characters maximum, including operators. Queries may additionally be limited by complexity.Example: @noradio. (required)
  --geocode: string # Returns tweets by users located within a given radius of the given latitude/longitude. The location is preferentially taking from the Geotagging API, but will fall back to their Twitter profile. The parameter value is specified by "latitude,longitude,radius", where radius units must be specified as either "mi" (miles) or "km" (kilometers). Note that you cannot use the near operator via the API to geocode arbitrary locations; however you can use this geocode parameter to search near geocodes directly. A maximum of 1,000 distinct "sub-regions" will be considered when using the radius modifier.
  --lang: string # Restricts tweets to the given language, given by an ISO 639-1 code. Language detection is best-effort.Example Values: eu
  --locale: string # Specify the language of the query you are sending (only ja is currently effective). This is intended for language-specific consumers and the default should work in the majority of cases.Example Values: ja
  --result-type: string # Optional. Specifies what type of search results you would prefer to receive. The current default is "mixed." Valid values include: * mixed: Include both popular and real time results in the response. * recent: return only the most recent results in the response * popular: return only the most popular results in the response. Example Values: mixed, recent, popular
  --count: string # The number of tweets to return per page, up to a maximum of 100. Defaults to 15. This was formerly the "rpp" parameter in the old Search API. Example Values: 100
  --until: string # Returns tweets generated before the given date. Date should be formatted as YYYY-MM-DD. Keep in mind that the search index may not go back as far as the date you specify here. Example Values: 2012-09-01
  --since-id: string # Returns results with an ID greater than (that is, more recent than) the specified ID. There are limits to the number of Tweets which can be accessed through the API. If the limit of Tweets has occured since the since_id, the since_id will be forced to the oldest ID available. Example Values: 12345
  --max-id: string # Returns results with an ID less than (that is, older than) or equal to the specified ID. Example Values: 12345
  --include-entities: string # The entities node will be disincluded when set to false. Example Values: false
  --callback: string # If supplied, the response will use the JSONP format with a callback of the given name. The usefulness of this parameter is somewhat diminished by the requirement of authentication for requests to this endpoint. Example Values: processTweets
]: nothing -> any {
  http-request {
    method: get
    path: "/search/tweets.json"
    query: [{name: q, var: q, required: true}, {name: geocode, var: geocode}, {name: lang, var: lang}, {name: locale, var: locale}, {name: result_type, var: result_type}, {name: count, var: count}, {name: until, var: until}, {name: since_id, var: since_id}, {name: max_id, var: max_id}, {name: include_entities, var: include_entities}, {name: callback, var: callback}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, geocode: $geocode, lang: $lang, locale: $locale, result_type: $result_type, count: $count, until: $until, since_id: $since_id, max_id: $max_id, include_entities: $include_entities, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Destroys the status specified by the required ID parameter. The authenticating user must be the author of the specified status. Returns the destroyed status if successful.
#
# POST /statuses/destroy/{id}.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/statuses/destroy/:id
# operationId: statuses.destroy
export def "statuses-destroy" [
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
  --trim-user: string # When set to either true, t or 1, each tweet returned in a timeline will include a user object including only the status authors numerical ID. Omit this parameter to receive the complete user object.
]: nothing -> any {
  http-request {
    method: post
    path: "/statuses/destroy/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: trim_user, var: trim_user}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trim_user: $trim_user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a collection of the most recent Tweets and retweets posted by the authenticating user and the users they follow. The home timeline is central to how most users interact with the Twitter service. Up to 800 Tweets are obtainable on the home timeline. It is more volatile for users that follow many users or follow users who tweet frequently.
#
# GET /statuses/home_timeline.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/statuses/home_timeline
# operationId: statuses.home_timeline
export def "statuses-home-timeline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Specifies the number of records to retrieve. Must be less than or equal to 200.
  --max-id: int # Returns results with an ID less than (that is, older than) or equal to the specified ID. (format: int64)
  --since-id: int # Returns results with an ID greater than (that is, more recent than) the specified ID. There are limits to the number of Tweets which can be accessed through the API. If the limit of Tweets has occured since the since_id, the since_id will be forced to the oldest ID available. (format: int64)
  --trim-user: string # When set to either true, t or 1, each tweet returned in a timeline will include a user object including only the status authors numerical ID. Omit this parameter to receive the complete user object.
  --exclude-replies: string # This parameter will prevent replies from appearing in the returned timeline. Using exclude_replies with the count parameter will mean you will receive up-to count tweets — this is because the count parameter retrieves that many tweets before filtering out retweets and replies.
  --contributor-details: string # This parameter enhances the contributors element of the status response to include the screen_name of the contributor. By default only the user_id of the contributor is included.
]: nothing -> any {
  http-request {
    method: get
    path: "/statuses/home_timeline.json"
    query: [{name: count, var: count}, {name: max_id, var: max_id}, {name: since_id, var: since_id}, {name: trim_user, var: trim_user}, {name: exclude_replies, var: exclude_replies}, {name: contributor_details, var: contributor_details}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    count: $count, max_id: $max_id, since_id: $since_id, trim_user: $trim_user, exclude_replies: $exclude_replies, contributor_details: $contributor_details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the 20 most recent mentions (tweets containing a users's @screen_name) for the authenticating user.The timeline returned is the equivalent of the one seen when you view your mentions on twitter.com.This method can only return up to 800 statuses.This method will include retweets in the JSON response regardless of whether the include_rts parameter is set.
#
# GET /statuses/mentions_timeline.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/statuses/mentions_timeline
# operationId: statuses.mentions.timeline
export def "statuses-mentions-timeline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Specifies the number of tweets to try and retrieve, up to a maximum of 200. The value of count is best thought of as a limit to the number of tweets to return because suspended or deleted content is removed after the count has been applied. We include retweets in the count, even if include_rts is not supplied. It is recommended you always send include_rts=1 when using this API method.
  --since-id: int # Returns results with an ID greater than (that is, more recent than) the specified ID. There are limits to the number of Tweets which can be accessed through the API. If the limit of Tweets has occured since the since_id, the since_id will be forced to the oldest ID available. (format: int64)
  --max-id: int # Returns results with an ID less than (that is, older than) or equal to the specified ID. (format: int64)
  --trim-user: string # When set to either true, t or 1, each tweet returned in a timeline will include a user object including only the status authors numerical ID. Omit this parameter to receive the complete user object.
  --contributor-details: string # This parameter enhances the contributors element of the status response to include the screen_name of the contributor. By default only the user_id of the contributor is included.
  --include-entities: oneof<nothing, bool> # The entities node will be disincluded when set to false.
]: nothing -> any {
  http-request {
    method: get
    path: "/statuses/mentions_timeline.json"
    query: [{name: count, var: count}, {name: since_id, var: since_id}, {name: max_id, var: max_id}, {name: trim_user, var: trim_user}, {name: contributor_details, var: contributor_details}, {name: include_entities, var: include_entities}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    count: $count, since_id: $since_id, max_id: $max_id, trim_user: $trim_user, contributor_details: $contributor_details, include_entities: $include_entities
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information allowing the creation of an embedded representation of a Tweet on third party sites. See the oEmbed specification (http://oembed.com) for information about the response format. Either the id or url parameters must be specified in a request, it is not necessary to include both. While this endpoint allows a bit of customization for the final appearance of the embedded Tweet, be aware that the appearance of the rendered Tweet may change over time to be consistent with Twitter's Display Guidelines (https://dev.twitter.com/terms/display-guidelines). Do not rely on any class or id parameters to stay constant in the returned markup.
#
# GET /statuses/oembed.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/statuses/oembed
# operationId: statuses.oembed
export def "statuses-oembed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxwidth: int # The maximum width in pixels that the embed should be rendered at. This value is constrained to be between 250 and 550 pixels. Note that Twitter does not support the oEmbed maxheight parameter. Tweets are fundamentally text, and are therefore of unpredictable height that cannot be scaled like an image or video. Relatedly, the oEmbed response will not provide a value for height. Implementations that need consistent heights for Tweets should refer to the hide_thread and hide_media parameters below.
  --hide-media: string # Specifies whether the embedded Tweet should automatically expand images which were uploaded via POST statuses/update_with_media. When set to either true, t or 1 images will not be expanded. Defaults to false.
  --hide-thread: string # Specifies whether the embedded Tweet should automatically show the original message in the case that the embedded Tweet is a reply. When set to either true, t or 1 the original Tweet will not be shown. Defaults to false.
  --omit-script: string # Specifies whether the embedded Tweet HTML should include a 'script' element pointing to widgets.js. In cases where a page already includes widgets.js, setting this value to true will prevent a redundant script element from being included. When set to either true, t or 1 the 'script'element will not be included in the embed HTML, meaning that pages must include a reference to widgets.js manually. Defaults to false.
  --align: string@align-completer # Specifies whether the embedded Tweet should be left aligned, right aligned, or centered in the page. Valid values are left, right, center, and none. Defaults to none, meaning no alignment styles are specified for the Tweet.
  --related: string # A value for the TWT related parameter, as described in Web Intents (https://dev.twitter.com/docs/intents). This value will be forwarded to all Web Intents calls. Example values: twitterapi, twittermedia, twitter.
  --lang: string # Language code for the rendered embed. This will affect the text and localization of the rendered HTML. Example value: fr
]: nothing -> any {
  http-request {
    method: get
    path: "/statuses/oembed.json"
    query: [{name: maxwidth, var: maxwidth}, {name: hide_media, var: hide_media}, {name: hide_thread, var: hide_thread}, {name: omit_script, var: omit_script}, {name: align, var: align}, {name: related, var: related}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    maxwidth: $maxwidth, hide_media: $hide_media, hide_thread: $hide_thread, omit_script: $omit_script, align: $align, related: $related, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retweets a tweet. Returns the original tweet with retweet details embedded.
#
# POST /statuses/retweet/{id}.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/statuses/retweet/:id
# operationId: statusesretweetid
export def "statusesretweetid" [
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
  --trim-user: string # When set to either true, t or 1, each tweet returned in a timeline will include a user object including only the status authors numerical ID. Omit this parameter to receive the complete user object.
]: nothing -> any {
  http-request {
    method: post
    path: "/statuses/retweet/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: trim_user, var: trim_user}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trim_user: $trim_user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns up to 100 of the first retweets of a given tweet.
#
# GET /statuses/retweets/{id}.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/statuses/retweets/:id
# operationId: statuses.retweets
export def "statuses-retweets" [
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
  --count: string # Specifies the number of records to retrieve. Must be less than or equal to 100.
  --trim-user: string # When set to either true, t or 1, each tweet returned in a timeline will include a user object including only the status authors numerical ID. Omit this parameter to receive the complete user object.
]: nothing -> any {
  http-request {
    method: get
    path: "/statuses/retweets/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: count, var: count}, {name: trim_user, var: trim_user}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, count: $count, trim_user: $trim_user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a single status, specified by the id parameter below. The status's author will be returned inline.
#
# GET /statuses/show/{id}.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/statuses/show/:id
# operationId: statuses.show
export def "statuses-show" [
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
  --trim-user: string # When set to either true, t or 1, each tweet returned in a timeline will include a user object including only the status authors numerical ID. Omit this parameter to receive the complete user object.
  --include-my-retweet: string # When set to either true, t or 1, any Tweets returned that have been retweeted by the authenticating user will include an additional current_user_retweet node, containing the ID of the source status for the retweet.
  --include-entities: string # The entities node will be disincluded when set to false.
]: nothing -> any {
  http-request {
    method: get
    path: "/statuses/show/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: trim_user, var: trim_user}, {name: include_my_retweet, var: include_my_retweet}, {name: include_entities, var: include_entities}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trim_user: $trim_user, include_my_retweet: $include_my_retweet, include_entities: $include_entities
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the authenticating user's status, also known as tweeting. To upload an image to accompany the tweet, use POST statuses/update_with_media (https://dev.twitter.com/docs/api/1/post/statuses/update_with_media). For each update attempt, the update text is compared with the authenticating user's recent tweets. Any attempt that would result in duplication will be blocked, resulting in a 403 error. Therefore, a user cannot submit the same status twice in a row. While not rate limited by the API a user is limited in the number of tweets they can create at a time. If the number of updates posted by the user reaches the current allowed limit this method will return an HTTP 403 error.
#
# POST /statuses/update.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/statuses/update
# operationId: statuses.update
export def "statuses-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # The text of your status update, typically up to 140 characters. URL encode as necessary. t.co link short-url wrapping (https://dev.twitter.com/docs/tco-link-wrapper/faq) may effect character counts. (required, default: Posting from @apigee's API test console. It's like a command line for the Twitter API! #apitools)
  --in-reply-to-status-id: string # The ID of an existing status that the update is in reply to. Note: This parameter will be ignored unless the author of the tweet this parameter references is mentioned within the status text. Therefore, you must include @username, where username is the author of the referenced tweet, within the update.
  --lat: string # The latitude of the location this tweet refers to. This parameter will be ignored unless it is inside the range -90.0 to +90.0 (North is positive) inclusive. It will also be ignored if there isn't a corresponding long parameter. (default: 37.426363)
  --long: string # The longitude of the location this tweet refers to. The valid ranges for longitude is -180.0 to +180.0 (East is positive) inclusive. This parameter will be ignored if outside that range, if it is not a number, if geo_enabled is disabled, or if there not a corresponding lat parameter. (default: -122.141114)
  --place-id: string # A place in the world. These IDs can be retrieved from GET geo/reverse_geocode (https://dev.twitter.com/docs/api/1/get/geo/reverse_geocode).
  --display-coordinates: string@display-coordinates-completer # Whether or not to put a pin on the exact coordinates a tweet has been sent from. (default: false)
  --trim-user: string # When set to either true, t or 1, each tweet returned in a timeline will include a user object including only the status authors numerical ID. Omit this parameter to receive the complete user object.
]: nothing -> any {
  http-request {
    method: post
    path: "/statuses/update.json"
    query: [{name: status, var: status, required: true, default: "Posting from @apigee's API test console. It's like a command line for the Twitter API! #apitools"}, {name: in_reply_to_status_id, var: in_reply_to_status_id}, {name: lat, var: lat}, {name: long, var: long}, {name: place_id, var: place_id}, {name: display_coordinates, var: display_coordinates}, {name: trim_user, var: trim_user}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    status: $status, in_reply_to_status_id: $in_reply_to_status_id, lat: $lat, long: $long, place_id: $place_id, display_coordinates: $display_coordinates, trim_user: $trim_user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the authenticating user's status and attaches media for upload. Unlike POST statuses/update (https://dev.twitter.com/docs/api/1.1/post/statuses/update), this method expects raw multipart data. Your POST request's Content-Type should be set to multipart/form-data with the media[] parameter. The Tweet text will be rewritten to include the media URL(s), which will reduce the number of characters allowed in the Tweet text. If the URL(s) cannot be appended without text truncation, the tweet will be rejected and this method will return an HTTP 403 error. Important: Make sure that you're using upload.twitter.com as your host while posting statuses with media. It is strongly recommended to use SSL with this method.
#
# POST /statuses/update_with_media.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/statuses/update_with_media
# operationId: statuses.update_with_media
export def "statuses-update-with-media" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # The text of your status update. URL encode as necessary. t.co link wrapping (https://dev.twitter.com/docs/tco-link-wrapper/faq) may affect character counts if the post contains URLs. You must additionally account for the characters_reserved_per_media per uploaded media, additionally accounting for space characters in between finalized URLs. Note: Request the GET help/configuration (https://dev.twitter.com/docs/api/1.1/get/help/configuration) endpoint to get the current characters_reserved_per_media and max_media_per_upload values. (required)
  --media: string # Up to max_media_per_upload files may be specified in the request, each named media[]. Supported image formats are PNG, JPG and GIF. Animated GIFs are not supported. Note: Request the GET help/configuration (https://dev.twitter.com/docs/api/1.1/get/help/configuration) endpoint to get the current max_media_per_upload and photo_size_limit values. (required)
  --possibly-sensitive: string # Set to true for content which may not be suitable for every audience.
  --in-reply-to-status-id: string # The ID of an existing status that the update is in reply to. Note: This parameter will be ignored unless the author of the tweet this parameter references is mentioned within the status text. Therefore, you must include @username, where username is the author of the referenced tweet, within the update.
  --lat: string # The latitude of the location this tweet refers to. This parameter will be ignored unless it is inside the range -90.0 to +90.0 (North is positive) inclusive. It will also be ignored if there isn't a corresponding long parameter. Example value: 37.7821120598956.
  --long: string # The longitude of the location this tweet refers to. The valid ranges for longitude is -180.0 to +180.0 (East is positive) inclusive. This parameter will be ignored if outside that range, not a number, geo_enabled is disabled, or if there not a corresponding lat parameter. Example value: -122.400612831116.
  --place-id: string # A place in the world identified by a Twitter place ID. Place IDs can be retrieved from geo/reverse_geocode.
  --display-coordinates: string # Whether or not to put a pin on the exact coordinates a tweet has been sent from.
  --content-type: string # Content type. (required, default: multipart/form-data)
]: nothing -> any {
  http-request {
    method: post
    path: "/statuses/update_with_media.json"
    query: [{name: status, var: status, required: true}, {name: media, var: media, required: true}, {name: possibly_sensitive, var: possibly_sensitive}, {name: in_reply_to_status_id, var: in_reply_to_status_id}, {name: lat, var: lat}, {name: long, var: long}, {name: place_id, var: place_id}, {name: display_coordinates, var: display_coordinates}]
    header: [{name: Content-Type, var: content_type, required: true, default: "multipart/form-data"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    status: $status, media: $media, possibly_sensitive: $possibly_sensitive, in_reply_to_status_id: $in_reply_to_status_id, lat: $lat, long: $long, place_id: $place_id, display_coordinates: $display_coordinates, content_type: $content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the 20 most recent statuses posted by the authenticating user. It is also possible to request another user's timeline by using the screen_name or user_id parameter. The other users timeline will only be visible if they are not protected, or if the authenticating user's follow request was accepted by the protected user. The timeline returned is the equivalent of the one seen when you view a user's profile on twitter.com. This method can only return up to 3,200 of a user's most recent statuses. Native retweets of other statuses by the user is included in this total, regardless of whether include_rts is specified when requesting this resource. This method will not include retweets in the XML and JSON responses unless the include_rts parameter is set. The RSS and Atom responses will always include retweets as statuses prefixed with RT, regardless of provided parameters. Always specify either an user_id or screen_name when requesting a user timeline.
#
# GET /statuses/user_timeline.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/statuses/user_timeline
# operationId: statuses.user_timeline
export def "statuses-user-timeline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Specifies the number of tweets to try and retrieve, up to a maximum of 200. The value of count is best thought of as a limit to the number of tweets to return because suspended or deleted content is removed after the count has been applied. We include retweets in the count, even if include_rts is not supplied. It is recommended you always send include_rts=1 when using this API method.
  --since-id: int # Returns results with an ID greater than (that is, more recent than) the specified ID. There are limits to the number of Tweets which can be accessed through the API. If the limit of Tweets has occured since the since_id, the since_id will be forced to the oldest ID available. (format: int64)
  --max-id: int # Returns results with an ID less than (that is, older than) or equal to the specified ID. (format: int64)
  --trim-user: string # When set to either true, t or 1, each tweet returned in a timeline will include a user object including only the status authors numerical ID. Omit this parameter to receive the complete user object.
  --exclude-replies: oneof<nothing, bool> # This parameter will prevent replies from appearing in the returned timeline. Using exclude_replies with the count parameter will mean you will receive up-to count tweets — this is because the count parameter retrieves that many tweets before filtering out retweets and replies. This parameter is only supported for JSON and XML responses.
  --contributor-details: oneof<nothing, bool> # This parameter enhances the contributors element of the status response to include the screen_name of the contributor. By default only the user_id of the contributor is included.
  --include-rts: oneof<nothing, bool> # When set to false, the timeline will strip any native retweets (though they will still count toward both the maximal length of the timeline and the slice selected by the count parameter). Note: If you're using the trim_user parameter in conjunction with include_rts, the retweets will still contain a full user object.
]: nothing -> any {
  http-request {
    method: get
    path: "/statuses/user_timeline.json"
    query: [{name: count, var: count}, {name: since_id, var: since_id}, {name: max_id, var: max_id}, {name: trim_user, var: trim_user}, {name: exclude_replies, var: exclude_replies}, {name: contributor_details, var: contributor_details}, {name: include_rts, var: include_rts}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    count: $count, since_id: $since_id, max_id: $max_id, trim_user: $trim_user, exclude_replies: $exclude_replies, contributor_details: $contributor_details, include_rts: $include_rts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the locations that Twitter has trending topic information for. The response is an array of "locations" that encode the location's WOEID and some other human-readable information such as a canonical name and country the location belongs in. A WOEID is a Yahoo! Where On Earth ID.
#
# GET /trends/available.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/trends/available
# operationId: trends.available
export def "trends-available" [
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
    path: "/trends/available.json"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the locations that Twitter has trending topic information for, closest to a specified location. The response is an array of "locations" that encode the location's WOEID and some other human-readable information such as a canonical name and country the location belongs in. A WOEID is a Yahoo! Where On Earth ID.
#
# GET /trends/closest.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/trends/closest
# operationId: trends.closest
export def "trends-closest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lat: string # If provided with a long parameter the available trend locations will be sorted by distance, nearest to furthest, to the co-ordinate pair. The valid ranges for longitude is -180.0 to +180.0 (West is negative, East is positive) inclusive. Example Values: 37.781157
  --long: string # If provided with a lat parameter the available trend locations will be sorted by distance, nearest to furthest, to the co-ordinate pair. The valid ranges for longitude is -180.0 to +180.0 (West is negative, East is positive) inclusive. Example Values: -122.400612831116
]: nothing -> any {
  http-request {
    method: get
    path: "/trends/closest.json"
    query: [{name: lat, var: lat}, {name: long, var: long}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    lat: $lat, long: $long
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the top 10 trending topics for a specific WOEID, if trending information is available for it. The response is an array of "trend" objects that encode the name of the trending topic, the query parameter that can be used to search for the topic on Twitter Search, and the Twitter Search URL. This information is cached for 5 minutes. Requesting more frequently than that will not return any more data, and will count against your rate limit usage.
#
# GET /trends/place.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/trends/place
# operationId: trends.place
export def "trends-place" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The Yahoo! Where On Earth ID of the location to return trending information for. Global information is available by using 1 as the WOEID. (required)
  --exclude: string # Setting this equal to hashtags will remove all hashtags from the trends list.
]: nothing -> any {
  http-request {
    method: get
    path: "/trends/place.json"
    query: [{name: id, var: id, required: true}, {name: exclude, var: exclude}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, exclude: $exclude
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a collection of users that the specified user can contribute to.
#
# GET /users/contributees.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/users/contributees
# operationId: users.contributees
export def "users-contributees" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-entities: string # The entities node will be disincluded when set to false. Example Values: false
  --skip-status: string # When set to either true, t or 1 statuses will not be included in the returned user objects.
]: nothing -> any {
  http-request {
    method: get
    path: "/users/contributees.json"
    query: [{name: include_entities, var: include_entities}, {name: skip_status, var: skip_status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    include_entities: $include_entities, skip_status: $skip_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a collection of users who can contribute to the specified account.
#
# GET /users/contributors.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/users/contributors
# operationId: users.contributors
export def "users-contributors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-entities: string # The entities node will be disincluded when set to false. Example Values: false
  --skip-status: string # When set to either true, t or 1 statuses will not be included in the returned user objects.
]: nothing -> any {
  http-request {
    method: get
    path: "/users/contributors.json"
    query: [{name: include_entities, var: include_entities}, {name: skip_status, var: skip_status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    include_entities: $include_entities, skip_status: $skip_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns fully-hydrated user objects for up to 100 users per request, as specified by comma-separated values passed to the user_id and/or screen_name parameters. This method is especially useful when used in conjunction with collections of user IDs returned from GET friends/ids and GET followers/ids. GET users/show is used to retrieve a single user object.
#
# GET /users/lookup.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/users/lookup
# operationId: users.lookup
export def "users-lookup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --screen-name: string # A comma separated list of screen names, up to 100 are allowed in a single request. You are strongly encouraged to use a POST for larger (up to 100 screen names) requests. Example Values: twitterapi,twitter
  --user-id: string # A comma separated list of user IDs, up to 100 are allowed in a single request. You are strongly encouraged to use a POST for larger requests. Example Values: 783214,6253282
  --include-entities: string # The entities node that may appear within embedded statuses will be disincluded when set to false. Example Values: false
]: nothing -> any {
  http-request {
    method: get
    path: "/users/lookup.json"
    query: [{name: screen_name, var: screen_name}, {name: user_id, var: user_id}, {name: include_entities, var: include_entities}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    screen_name: $screen_name, user_id: $user_id, include_entities: $include_entities
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The user specified in the id is blocked by the authenticated user and reported as a spammer.
#
# POST /users/report_spam.json
# Docs: https://dev.twitter.com/docs/api/1.1/post/report_spam
# operationId: users.report_spam
export def "users-report-spam" [
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
    path: "/users/report_spam.json"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides a simple, relevance-based search interface to public user accounts on Twitter. Try querying by topical interest, full name, company name, location, or other criteria. Exact match searches are not supported. Only the first 1,000 matching results are available.
#
# GET /users/search.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/users/search
# operationId: users.search
export def "users-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The search query to run against people search. Example Values: Twitter%20API (required)
  --page: string # Specifies the page of results to retrieve. Example Values: 3
  --count: string # The number of potential user results to retrieve per page. This value has a maximum of 20. Example Values: 5
  --include-entities: string # The entities node will be disincluded when set to false. Example Values: false
]: nothing -> any {
  http-request {
    method: get
    path: "/users/search.json"
    query: [{name: q, var: q, required: true}, {name: page, var: page}, {name: count, var: count}, {name: include_entities, var: include_entities}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page: $page, count: $count, include_entities: $include_entities
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a variety of information about the user specified by the required user_id or screen_name parameter. The author's most recent Tweet will be returned inline when possible. GET users/lookup is used to retrieve a bulk collection of user objects.
#
# GET /users/show.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/users/show
# operationId: users.show
export def "users-show" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --screen-name: string # The screen name of the user for whom to return results for. Either a id or screen_name is required for this method. Example Values: noradio (required)
  --user-id: string # The ID of the user for whom to return results for. Either an id or screen_name is required for this method. Example Values: 12345 (required)
  --include-entities: string # The entities node will be disincluded when set to false. Example Values: false
]: nothing -> any {
  http-request {
    method: get
    path: "/users/show.json"
    query: [{name: screen_name, var: screen_name, required: true}, {name: user_id, var: user_id, required: true}, {name: include_entities, var: include_entities}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    screen_name: $screen_name, user_id: $user_id, include_entities: $include_entities
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Access to Twitter's suggested user list. This returns the list of suggested user categories. The category can be used in GET users/suggestions/:slug to get the users in that category.
#
# GET /users/suggestions.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/users/suggestions
# operationId: users.suggestions
export def "users-suggestions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Restricts the suggested categories to the requested language. The language must be specified by the appropriate two letter ISO 639-1 representation. Currently supported languages are provided by the GET help/languages API request. Unsupported language codes will receive English (en) results. If you use lang in this request, ensure you also include it when requesting the GET users/suggestions/:slug list.
]: nothing -> any {
  http-request {
    method: get
    path: "/users/suggestions.json"
    query: [{name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Access the users in a given category of the Twitter suggested user list. It is recommended that applications cache this data for no more than one hour.
#
# GET /users/suggestions/{slug}.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/users/suggestions/%3Aslug
# operationId: users.suggestions.slug
export def "users-suggestions-slug" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Restricts the suggested categories to the requested language. The language must be specified by the appropriate two letter ISO 639-1 representation. Currently supported languages are provided by the GET help/languages API request. Unsupported language codes will receive English (en) results. If you use lang in this request, ensure you also include it when requesting the GET users/suggestions/:slug list.
]: nothing -> any {
  http-request {
    method: get
    path: "/users/suggestions/{slug}.json"
    path_params: [{name: slug, var: slug}]
    query: [{name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    slug: $slug, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Access the users in a given category of the Twitter suggested user list and return their most recent status if they are not a protected user.
#
# GET /users/suggestions/{slug}/members.json
# Docs: https://dev.twitter.com/docs/api/1.1/get/users/suggestions/%3Aslug/members
# operationId: users.suggestionsslugmembers
export def "users-suggestionsslugmembers" [
  slug: string
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
    path: "/users/suggestions/{slug}/members.json"
    path_params: [{name: slug, var: slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
