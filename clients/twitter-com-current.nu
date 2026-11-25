# Auto-generated client for Twitter API v2 v2.61
# Source: https://api.apis.guru/v2/specs/twitter.com/current/2.61/openapi.json
# Auth: --token flag or $env.TWITTER_API_V2_TOKEN

const CLIENT = {
  base_url: "https://api.twitter.com"
  token_env_var: "TWITTER_API_V2_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: bearer, in: header, header_name: Authorization, prefix: Bearer}
    {name: oauth, in: header, header_name: Authorization, prefix: Oauth}
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

def base-url-completer [] { ["https://api.twitter.com"] }
def auth-scheme-completer [] { ["bearer" "oauth"] }

# Completers for enum parameters
def type-completer [] { ["tweets" "users"] }
def status-completer [] { ["complete" "created" "failed" "in_progress"] }
def accept-completer [] { ["application/json" "application/problem+json"] }
def conversation-type-completer [] { ["Group"] }
def state-completer [] { ["all" "live" "scheduled"] }
def reply-settings-completer [] { ["following" "mentionedUsers"] }
def granularity-completer [] { ["day" "hour" "minute"] }
def sort-order-completer [] { ["recency" "relevancy"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    list-batch-compliance-jobs: "record<data: table<created_at: string, download_expires_at: string, download_url: string, id: string, name: string, status: string, type: string, upload_expires_at: string, upload_url: string>, errors: table<detail: string, status: int, title: string, type: string>, meta: record<result_count: int>>"
    create-batch-compliance-job: "record<data: record<created_at: string, download_expires_at: string, download_url: string, id: string, name: string, status: string, type: string, upload_expires_at: string, upload_url: string>, errors: table<detail: string, status: int, title: string, type: string>>"
    get-batch-compliance-job: "record<data: record<created_at: string, download_expires_at: string, download_url: string, id: string, name: string, status: string, type: string, upload_expires_at: string, upload_url: string>, errors: table<detail: string, status: int, title: string, type: string>>"
    dm-conversation-id-create: "record<data: record<dm_conversation_id: string, dm_event_id: string>, errors: table<detail: string, status: int, title: string, type: string>>"
    get-dm-conversations-with-participant-id-dm-events: "record<data: table<attachments: record, created_at: string, dm_conversation_id: string, event_type: string, id: string, participant_ids: list, referenced_tweets: list, sender_id: string, text: string>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>"
    dm-conversation-with-user-event-id-create: "record<data: record<dm_conversation_id: string, dm_event_id: string>, errors: table<detail: string, status: int, title: string, type: string>>"
    dm-conversation-by-id-event-id-create: "record<data: record<dm_conversation_id: string, dm_event_id: string>, errors: table<detail: string, status: int, title: string, type: string>>"
    get-dm-conversations-id-dm-events: "record<data: table<attachments: record, created_at: string, dm_conversation_id: string, event_type: string, id: string, participant_ids: list, referenced_tweets: list, sender_id: string, text: string>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>"
    get-dm-events: "record<data: table<attachments: record, created_at: string, dm_conversation_id: string, event_type: string, id: string, participant_ids: list, referenced_tweets: list, sender_id: string, text: string>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>"
    list-id-create: "record<data: record<id: string, name: string>, errors: table<detail: string, status: int, title: string, type: string>>"
    list-id-delete: "record<data: record<deleted: bool>, errors: table<detail: string, status: int, title: string, type: string>>"
    list-id-get: "record<data: record<created_at: string, description: string, follower_count: int, id: string, member_count: int, name: string, owner_id: string, private: bool>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>>"
    list-id-update: "record<data: record<updated: bool>, errors: table<detail: string, status: int, title: string, type: string>>"
    list-get-followers: "record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>"
    list-get-members: "record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>"
    list-add-member: "record<data: record<is_member: bool>, errors: table<detail: string, status: int, title: string, type: string>>"
    list-remove-member: "record<data: record<is_member: bool>, errors: table<detail: string, status: int, title: string, type: string>>"
    lists-id-tweets: "record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>"
    get-open-api-spec: "record"
    find-spaces-by-ids: "record<data: table<created_at: string, creator_id: string, ended_at: string, host_ids: list, id: string, invited_user_ids: list, is_ticketed: bool, lang: string, participant_count: int, scheduled_start: string, speaker_ids: list, started_at: string, state: string, subscriber_count: int, title: string, topics: list, updated_at: string>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>>"
    find-spaces-by-creator-ids: "record<data: table<created_at: string, creator_id: string, ended_at: string, host_ids: list, id: string, invited_user_ids: list, is_ticketed: bool, lang: string, participant_count: int, scheduled_start: string, speaker_ids: list, started_at: string, state: string, subscriber_count: int, title: string, topics: list, updated_at: string>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<result_count: int>>"
    search-spaces: "record<data: table<created_at: string, creator_id: string, ended_at: string, host_ids: list, id: string, invited_user_ids: list, is_ticketed: bool, lang: string, participant_count: int, scheduled_start: string, speaker_ids: list, started_at: string, state: string, subscriber_count: int, title: string, topics: list, updated_at: string>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<result_count: int>>"
    find-space-by-id: "record<data: record<created_at: string, creator_id: string, ended_at: string, host_ids: list<string>, id: string, invited_user_ids: list<string>, is_ticketed: bool, lang: string, participant_count: int, scheduled_start: string, speaker_ids: list<string>, started_at: string, state: string, subscriber_count: int, title: string, topics: list<record>, updated_at: string>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>>"
    space-buyers: "record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>"
    space-tweets: "record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>"
    find-tweets-by-id: "record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>>"
    create-tweet: "record<data: record<id: string, text: string>, errors: table<detail: string, status: int, title: string, type: string>>"
    tweet-counts-full-archive-search: "record<data: table<end: string, start: string, tweet_count: int>, errors: table<detail: string, status: int, title: string, type: string>, meta: record<newest_id: string, next_token: string, oldest_id: string, total_tweet_count: int>>"
    tweet-counts-recent-search: "record<data: table<end: string, start: string, tweet_count: int>, errors: table<detail: string, status: int, title: string, type: string>, meta: record<newest_id: string, next_token: string, oldest_id: string, total_tweet_count: int>>"
    get-tweets-firehose-stream: "record<data: record<attachments: record<media_keys: list, poll_ids: list>, author_id: string, context_annotations: list<record>, conversation_id: string, created_at: string, edit_controls: record<editable_until: string, edits_remaining: int, is_edit_eligible: bool>, edit_history_tweet_ids: list<string>, entities: record<annotations: list, cashtags: list, hashtags: list, mentions: list, urls: list>, geo: record<coordinates: record, place_id: string>, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record<impression_count: int>, organic_metrics: record<impression_count: int, like_count: int, reply_count: int, retweet_count: int>, possibly_sensitive: bool, promoted_metrics: record<impression_count: int, like_count: int, reply_count: int, retweet_count: int>, public_metrics: record<impression_count: int, like_count: int, quote_count: int, reply_count: int, retweet_count: int>, referenced_tweets: list<record>, reply_settings: string, source: string, text: string, withheld: record<copyright: bool, country_codes: list, scope: string>>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>>"
    sample-stream: "record<data: record<attachments: record<media_keys: list, poll_ids: list>, author_id: string, context_annotations: list<record>, conversation_id: string, created_at: string, edit_controls: record<editable_until: string, edits_remaining: int, is_edit_eligible: bool>, edit_history_tweet_ids: list<string>, entities: record<annotations: list, cashtags: list, hashtags: list, mentions: list, urls: list>, geo: record<coordinates: record, place_id: string>, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record<impression_count: int>, organic_metrics: record<impression_count: int, like_count: int, reply_count: int, retweet_count: int>, possibly_sensitive: bool, promoted_metrics: record<impression_count: int, like_count: int, reply_count: int, retweet_count: int>, public_metrics: record<impression_count: int, like_count: int, quote_count: int, reply_count: int, retweet_count: int>, referenced_tweets: list<record>, reply_settings: string, source: string, text: string, withheld: record<copyright: bool, country_codes: list, scope: string>>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>>"
    get-tweets-sample10-stream: "record<data: record<attachments: record<media_keys: list, poll_ids: list>, author_id: string, context_annotations: list<record>, conversation_id: string, created_at: string, edit_controls: record<editable_until: string, edits_remaining: int, is_edit_eligible: bool>, edit_history_tweet_ids: list<string>, entities: record<annotations: list, cashtags: list, hashtags: list, mentions: list, urls: list>, geo: record<coordinates: record, place_id: string>, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record<impression_count: int>, organic_metrics: record<impression_count: int, like_count: int, reply_count: int, retweet_count: int>, possibly_sensitive: bool, promoted_metrics: record<impression_count: int, like_count: int, reply_count: int, retweet_count: int>, public_metrics: record<impression_count: int, like_count: int, quote_count: int, reply_count: int, retweet_count: int>, referenced_tweets: list<record>, reply_settings: string, source: string, text: string, withheld: record<copyright: bool, country_codes: list, scope: string>>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>>"
    tweets-fullarchive-search: "record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<newest_id: string, next_token: string, oldest_id: string, result_count: int>>"
    tweets-recent-search: "record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<newest_id: string, next_token: string, oldest_id: string, result_count: int>>"
    search-stream: "record<data: record<attachments: record<media_keys: list, poll_ids: list>, author_id: string, context_annotations: list<record>, conversation_id: string, created_at: string, edit_controls: record<editable_until: string, edits_remaining: int, is_edit_eligible: bool>, edit_history_tweet_ids: list<string>, entities: record<annotations: list, cashtags: list, hashtags: list, mentions: list, urls: list>, geo: record<coordinates: record, place_id: string>, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record<impression_count: int>, organic_metrics: record<impression_count: int, like_count: int, reply_count: int, retweet_count: int>, possibly_sensitive: bool, promoted_metrics: record<impression_count: int, like_count: int, reply_count: int, retweet_count: int>, public_metrics: record<impression_count: int, like_count: int, quote_count: int, reply_count: int, retweet_count: int>, referenced_tweets: list<record>, reply_settings: string, source: string, text: string, withheld: record<copyright: bool, country_codes: list, scope: string>>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, matching_rules: table<id: string, tag: string>>"
    get-rules: "record<data: table<id: string, tag: string, value: string>, meta: record<next_token: string, result_count: int, sent: string, summary: any>>"
    add-or-delete-rules: "record<data: table<id: string, tag: string, value: string>, errors: table<detail: string, status: int, title: string, type: string>, meta: record<next_token: string, result_count: int, sent: string, summary: any>>"
    delete-tweet-by-id: "record<data: record<deleted: bool>, errors: table<detail: string, status: int, title: string, type: string>>"
    find-tweet-by-id: "record<data: record<attachments: record<media_keys: list, poll_ids: list>, author_id: string, context_annotations: list<record>, conversation_id: string, created_at: string, edit_controls: record<editable_until: string, edits_remaining: int, is_edit_eligible: bool>, edit_history_tweet_ids: list<string>, entities: record<annotations: list, cashtags: list, hashtags: list, mentions: list, urls: list>, geo: record<coordinates: record, place_id: string>, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record<impression_count: int>, organic_metrics: record<impression_count: int, like_count: int, reply_count: int, retweet_count: int>, possibly_sensitive: bool, promoted_metrics: record<impression_count: int, like_count: int, reply_count: int, retweet_count: int>, public_metrics: record<impression_count: int, like_count: int, quote_count: int, reply_count: int, retweet_count: int>, referenced_tweets: list<record>, reply_settings: string, source: string, text: string, withheld: record<copyright: bool, country_codes: list, scope: string>>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>>"
    tweets-id-liking-users: "record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>"
    find-tweets-that-quote-a-tweet: "record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, result_count: int>>"
    tweets-id-retweeting-users: "record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>"
    hide-reply-by-id: "record<data: record<hidden: bool>>"
    find-users-by-id: "record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>>"
    find-users-by-username: "record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>>"
    find-user-by-username: "record<data: record<created_at: string, description: string, entities: record<description: record, url: record>, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record<followers_count: int, following_count: int, listed_count: int, tweet_count: int>, url: string, username: string, verified: bool, verified_type: string, withheld: record<country_codes: list, scope: string>>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>>"
    find-my-user: "record<data: record<created_at: string, description: string, entities: record<description: record, url: record>, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record<followers_count: int, following_count: int, listed_count: int, tweet_count: int>, url: string, username: string, verified: bool, verified_type: string, withheld: record<country_codes: list, scope: string>>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>>"
    find-user-by-id: "record<data: record<created_at: string, description: string, entities: record<description: record, url: record>, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record<followers_count: int, following_count: int, listed_count: int, tweet_count: int>, url: string, username: string, verified: bool, verified_type: string, withheld: record<country_codes: list, scope: string>>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>>"
    users-id-blocking: "record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>"
    users-id-block: "record<data: record<blocking: bool>, errors: table<detail: string, status: int, title: string, type: string>>"
    get-users-id-bookmarks: "record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>"
    post-users-id-bookmarks: "record<data: record<bookmarked: bool>, errors: table<detail: string, status: int, title: string, type: string>>"
    users-id-bookmarks-delete: "record<data: record<bookmarked: bool>, errors: table<detail: string, status: int, title: string, type: string>>"
    user-followed-lists: "record<data: table<created_at: string, description: string, follower_count: int, id: string, member_count: int, name: string, owner_id: string, private: bool>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>"
    list-user-follow: "record<data: record<following: bool>, errors: table<detail: string, status: int, title: string, type: string>>"
    list-user-unfollow: "record<data: record<following: bool>, errors: table<detail: string, status: int, title: string, type: string>>"
    users-id-followers: "record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>"
    users-id-following: "record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>"
    users-id-follow: "record<data: record<following: bool, pending_follow: bool>, errors: table<detail: string, status: int, title: string, type: string>>"
    users-id-liked-tweets: "record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>"
    users-id-like: "record<data: record<liked: bool>, errors: table<detail: string, status: int, title: string, type: string>>"
    users-id-unlike: "record<data: record<liked: bool>, errors: table<detail: string, status: int, title: string, type: string>>"
    get-user-list-memberships: "record<data: table<created_at: string, description: string, follower_count: int, id: string, member_count: int, name: string, owner_id: string, private: bool>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>"
    users-id-mentions: "record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<newest_id: string, next_token: string, oldest_id: string, previous_token: string, result_count: int>>"
    users-id-muting: "record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>"
    users-id-mute: "record<data: record<muting: bool>, errors: table<detail: string, status: int, title: string, type: string>>"
    list-user-owned-lists: "record<data: table<created_at: string, description: string, follower_count: int, id: string, member_count: int, name: string, owner_id: string, private: bool>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>"
    list-user-pinned-lists: "record<data: table<created_at: string, description: string, follower_count: int, id: string, member_count: int, name: string, owner_id: string, private: bool>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<result_count: int>>"
    list-user-pin: "record<data: record<pinned: bool>, errors: table<detail: string, status: int, title: string, type: string>>"
    list-user-unpin: "record<data: record<pinned: bool>, errors: table<detail: string, status: int, title: string, type: string>>"
    users-id-retweets: "record<data: record<retweeted: bool>, errors: table<detail: string, status: int, title: string, type: string>>"
    users-id-unretweets: "record<data: record<retweeted: bool>, errors: table<detail: string, status: int, title: string, type: string>>"
    users-id-timeline: "record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<newest_id: string, next_token: string, oldest_id: string, previous_token: string, result_count: int>>"
    users-id-tweets: "record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<newest_id: string, next_token: string, oldest_id: string, previous_token: string, result_count: int>>"
    users-id-unblock: "record<data: record<blocking: bool>, errors: table<detail: string, status: int, title: string, type: string>>"
    users-id-unfollow: "record<data: record<following: bool>, errors: table<detail: string, status: int, title: string, type: string>>"
    users-id-unmute: "record<data: record<muting: bool>, errors: table<detail: string, status: int, title: string, type: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["list-batch-compliance-jobs" "create-batch-compliance-job" "get-batch-compliance-job" "dm-conversation-id-create" "get-dm-conversations-with-participant-id-dm-events" "dm-conversation-with-user-event-id-create" "dm-conversation-by-id-event-id-create" "get-dm-conversations-id-dm-events" "get-dm-events" "list-id-create" "list-id-delete" "list-id-get" "list-id-update" "list-get-followers" "list-get-members" "list-add-member" "list-remove-member" "lists-id-tweets" "get-open-api-spec" "find-spaces-by-ids" "find-spaces-by-creator-ids" "search-spaces" "find-space-by-id" "space-buyers" "space-tweets" "find-tweets-by-id" "create-tweet" "get-tweets-compliance-stream" "tweet-counts-full-archive-search" "tweet-counts-recent-search" "get-tweets-firehose-stream" "get-tweets-label-stream" "sample-stream" "get-tweets-sample10-stream" "tweets-fullarchive-search" "tweets-recent-search" "search-stream" "get-rules" "add-or-delete-rules" "delete-tweet-by-id" "find-tweet-by-id" "tweets-id-liking-users" "find-tweets-that-quote-a-tweet" "tweets-id-retweeting-users" "hide-reply-by-id" "find-users-by-id" "find-users-by-username" "find-user-by-username" "get-users-compliance-stream" "find-my-user" "find-user-by-id" "users-id-blocking" "users-id-block" "get-users-id-bookmarks" "post-users-id-bookmarks" "users-id-bookmarks-delete" "user-followed-lists" "list-user-follow" "list-user-unfollow" "users-id-followers" "users-id-following" "users-id-follow" "users-id-liked-tweets" "users-id-like" "users-id-unlike" "get-user-list-memberships" "users-id-mentions" "users-id-muting" "users-id-mute" "list-user-owned-lists" "list-user-pinned-lists" "list-user-pin" "list-user-unpin" "users-id-retweets" "users-id-unretweets" "users-id-timeline" "users-id-tweets" "users-id-unblock" "users-id-unfollow" "users-id-unmute" "commands"] | sort) } | get name | first)
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

# List Compliance Jobs
#
# GET /2/compliance/jobs
# Docs: https://developer.twitter.com/en/docs/twitter-api/compliance/batch-compliance/api-reference/get-compliance-jobs
# Returns: record<data: table<created_at: string, download_expires_at: string, download_url: string, id: string, name: string, status: string, type: string, upload_expires_at: string, upload_url: string>, errors: table<detail: string, status: int, title: string, type: string>, meta: record<result_count: int>>
# operationId: listBatchComplianceJobs
export def "list-batch-compliance-jobs" [
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
  --type: string@type-completer # Type of Compliance Job to list. (required)
  --status: string@status-completer # Status of Compliance Job to list.
  --compliance-job-fields: list<string> # A comma separated list of ComplianceJob fields to display. (e.g. [created_at, download_expires_at, download_url, id, name, resumable, status, type, upload_expires_at, upload_url])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/compliance/jobs"
    query: [{name: type, var: type, required: true}, {name: status, var: status}, {name: "compliance_job.fields", var: compliance_job_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, status: $status, compliance_job_fields: $compliance_job_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create compliance job
#
# POST /2/compliance/jobs
# Docs: https://developer.twitter.com/en/docs/twitter-api/compliance/batch-compliance/api-reference/post-compliance-jobs
# Returns: record<data: record<created_at: string, download_expires_at: string, download_url: string, id: string, name: string, status: string, type: string, upload_expires_at: string, upload_url: string>, errors: table<detail: string, status: int, title: string, type: string>>
# operationId: createBatchComplianceJob
export def "create-batch-compliance-job" [
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
  --name: string # User-provided name for a compliance job. (e.g. my-job)
  --resumable: oneof<nothing, bool> # If true, this endpoint will return a pre-signed URL with resumable uploads enabled.
  type: string@type-completer # Type of compliance job to list.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2/compliance/jobs"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: resumable, var: resumable}, {name: type, var: type}]}
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, resumable: $resumable, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Compliance Job
#
# GET /2/compliance/jobs/{id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/compliance/batch-compliance/api-reference/get-compliance-jobs-id
# Returns: record<data: record<created_at: string, download_expires_at: string, download_url: string, id: string, name: string, status: string, type: string, upload_expires_at: string, upload_url: string>, errors: table<detail: string, status: int, title: string, type: string>>
# operationId: getBatchComplianceJob
export def "get-batch-compliance-job" [
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
  --compliance-job-fields: list<string> # A comma separated list of ComplianceJob fields to display. (e.g. [created_at, download_expires_at, download_url, id, name, resumable, status, type, upload_expires_at, upload_url])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/compliance/jobs/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "compliance_job.fields", var: compliance_job_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, compliance_job_fields: $compliance_job_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new DM Conversation
#
# POST /2/dm_conversations
# Returns: record<data: record<dm_conversation_id: string, dm_event_id: string>, errors: table<detail: string, status: int, title: string, type: string>>
# operationId: dmConversationIdCreate
export def "dm-conversation-id-create" [
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
  conversation_type: string@conversation-type-completer # The conversation type that is being created.
  message: any
  participant_ids: list<string> # Participants for the DM Conversation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2/dm_conversations"
    body: {content_type: "application/json", kind: json, fields: [{name: conversation_type, var: conversation_type}, {name: message, var: message}, {name: participant_ids, var: participant_ids}]}
    accept: ["application/json", "application/problem+json"]
    ok: [201]
    auth: bearer
  } {
    conversation_type: $conversation_type, message: $message, participant_ids: $participant_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get DM Events for a DM Conversation
#
# GET /2/dm_conversations/with/{participant_id}/dm_events
# Returns: record<data: table<attachments: record, created_at: string, dm_conversation_id: string, event_type: string, id: string, participant_ids: list, referenced_tweets: list, sender_id: string, text: string>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>
# operationId: getDmConversationsWithParticipantIdDmEvents
export def "get-dm-conversations-with-participant-id-dm-events" [
  participant_id: string
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
  --max-results: int # The maximum number of results. (format: int32, default: 100)
  --pagination-token: string # This parameter is used to get a specified 'page' of results.
  --event-types: list<string> # The set of event_types to include in the results. (default: [MessageCreate, ParticipantsLeave, ParticipantsJoin], e.g. [MessageCreate, ParticipantsLeave])
  --dm-event-fields: list<string> # A comma separated list of DmEvent fields to display. (e.g. [attachments, created_at, dm_conversation_id, event_type, id, participant_ids, referenced_tweets, sender_id, text])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, participant_ids, referenced_tweets.id, sender_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/dm_conversations/with/{participant_id}/dm_events"
    path_params: [{name: participant_id, var: participant_id}]
    query: [{name: max_results, var: max_results}, {name: pagination_token, var: pagination_token}, {name: event_types, var: event_types, style: csv}, {name: "dm_event.fields", var: dm_event_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "media.fields", var: media_fields, style: csv}, {name: "user.fields", var: user_fields, style: csv}, {name: "tweet.fields", var: tweet_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    participant_id: $participant_id, max_results: $max_results, pagination_token: $pagination_token, event_types: $event_types, dm_event_fields: $dm_event_fields, expansions: $expansions, media_fields: $media_fields, user_fields: $user_fields, tweet_fields: $tweet_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Send a new message to a user
#
# POST /2/dm_conversations/with/{participant_id}/messages
# Returns: record<data: record<dm_conversation_id: string, dm_event_id: string>, errors: table<detail: string, status: int, title: string, type: string>>
# operationId: dmConversationWithUserEventIdCreate
export def "dm-conversation-with-user-event-id-create" [
  participant_id: string
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
  --attachments: list # Attachments to a DM Event. — item shape: {media_id: string}
  --text: string # Text of the message.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2/dm_conversations/with/{participant_id}/messages"
    path_params: [{name: participant_id, var: participant_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: attachments, var: attachments}, {name: text, var: text}]}
    accept: ["application/json", "application/problem+json"]
    ok: [201]
    auth: bearer
  } {
    participant_id: $participant_id, attachments: $attachments, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Send a new message to a DM Conversation
#
# POST /2/dm_conversations/{dm_conversation_id}/messages
# Returns: record<data: record<dm_conversation_id: string, dm_event_id: string>, errors: table<detail: string, status: int, title: string, type: string>>
# operationId: dmConversationByIdEventIdCreate
export def "dm-conversation-by-id-event-id-create" [
  dm_conversation_id: string
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
  --attachments: list # Attachments to a DM Event. — item shape: {media_id: string}
  --text: string # Text of the message.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2/dm_conversations/{dm_conversation_id}/messages"
    path_params: [{name: dm_conversation_id, var: dm_conversation_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: attachments, var: attachments}, {name: text, var: text}]}
    accept: ["application/json", "application/problem+json"]
    ok: [201]
    auth: bearer
  } {
    dm_conversation_id: $dm_conversation_id, attachments: $attachments, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get DM Events for a DM Conversation
#
# GET /2/dm_conversations/{id}/dm_events
# Returns: record<data: table<attachments: record, created_at: string, dm_conversation_id: string, event_type: string, id: string, participant_ids: list, referenced_tweets: list, sender_id: string, text: string>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>
# operationId: getDmConversationsIdDmEvents
export def "get-dm-conversations-id-dm-events" [
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
  --max-results: int # The maximum number of results. (format: int32, default: 100)
  --pagination-token: string # This parameter is used to get a specified 'page' of results.
  --event-types: list<string> # The set of event_types to include in the results. (default: [MessageCreate, ParticipantsLeave, ParticipantsJoin], e.g. [MessageCreate, ParticipantsLeave])
  --dm-event-fields: list<string> # A comma separated list of DmEvent fields to display. (e.g. [attachments, created_at, dm_conversation_id, event_type, id, participant_ids, referenced_tweets, sender_id, text])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, participant_ids, referenced_tweets.id, sender_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/dm_conversations/{id}/dm_events"
    path_params: [{name: id, var: id}]
    query: [{name: max_results, var: max_results}, {name: pagination_token, var: pagination_token}, {name: event_types, var: event_types, style: csv}, {name: "dm_event.fields", var: dm_event_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "media.fields", var: media_fields, style: csv}, {name: "user.fields", var: user_fields, style: csv}, {name: "tweet.fields", var: tweet_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, max_results: $max_results, pagination_token: $pagination_token, event_types: $event_types, dm_event_fields: $dm_event_fields, expansions: $expansions, media_fields: $media_fields, user_fields: $user_fields, tweet_fields: $tweet_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get recent DM Events
#
# GET /2/dm_events
# Returns: record<data: table<attachments: record, created_at: string, dm_conversation_id: string, event_type: string, id: string, participant_ids: list, referenced_tweets: list, sender_id: string, text: string>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>
# operationId: getDmEvents
export def "get-dm-events" [
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
  --max-results: int # The maximum number of results. (format: int32, default: 100)
  --pagination-token: string # This parameter is used to get a specified 'page' of results.
  --event-types: list<string> # The set of event_types to include in the results. (default: [MessageCreate, ParticipantsLeave, ParticipantsJoin], e.g. [MessageCreate, ParticipantsLeave])
  --dm-event-fields: list<string> # A comma separated list of DmEvent fields to display. (e.g. [attachments, created_at, dm_conversation_id, event_type, id, participant_ids, referenced_tweets, sender_id, text])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, participant_ids, referenced_tweets.id, sender_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/dm_events"
    query: [{name: max_results, var: max_results}, {name: pagination_token, var: pagination_token}, {name: event_types, var: event_types, style: csv}, {name: "dm_event.fields", var: dm_event_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "media.fields", var: media_fields, style: csv}, {name: "user.fields", var: user_fields, style: csv}, {name: "tweet.fields", var: tweet_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, pagination_token: $pagination_token, event_types: $event_types, dm_event_fields: $dm_event_fields, expansions: $expansions, media_fields: $media_fields, user_fields: $user_fields, tweet_fields: $tweet_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create List
#
# POST /2/lists
# Docs: https://developer.twitter.com/en/docs/twitter-api/lists/manage-lists/api-reference/post-lists
# Returns: record<data: record<id: string, name: string>, errors: table<detail: string, status: int, title: string, type: string>>
# operationId: listIdCreate
export def "list-id-create" [
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
  --description: string
  name: string
  --private: oneof<nothing, bool> # default: false
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2/lists"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: private, var: private}]}
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    description: $description, name: $name, private: $private
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete List
#
# DELETE /2/lists/{id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/lists/manage-lists/api-reference/delete-lists-id
# Returns: record<data: record<deleted: bool>, errors: table<detail: string, status: int, title: string, type: string>>
# operationId: listIdDelete
export def "list-id-delete" [
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
    method: delete
    path: "/2/lists/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List lookup by List ID.
#
# GET /2/lists/{id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/lists/list-lookup/api-reference/get-lists-id
# Returns: record<data: record<created_at: string, description: string, follower_count: int, id: string, member_count: int, name: string, owner_id: string, private: bool>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>>
# operationId: listIdGet
export def "list-id-get" [
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
  --list-fields: list<string> # A comma separated list of List fields to display. (e.g. [created_at, description, follower_count, id, member_count, name, owner_id, private])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [owner_id])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/lists/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "list.fields", var: list_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "user.fields", var: user_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, list_fields: $list_fields, expansions: $expansions, user_fields: $user_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update List.
#
# PUT /2/lists/{id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/lists/manage-lists/api-reference/put-lists-id
# Returns: record<data: record<updated: bool>, errors: table<detail: string, status: int, title: string, type: string>>
# operationId: listIdUpdate
export def "list-id-update" [
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
  --description: string
  --name: string
  --private: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/2/lists/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: private, var: private}]}
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, description: $description, name: $name, private: $private
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns User objects that follow a List by the provided List ID
#
# GET /2/lists/{id}/followers
# Docs: https://developer.twitter.com/en/docs/twitter-api/users/follows/api-reference/get-users-id-followers
# Returns: record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>
# operationId: listGetFollowers
export def "list-get-followers" [
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
  --max-results: int # The maximum number of results. (format: int32, default: 100)
  --pagination-token: string # This parameter is used to get a specified 'page' of results.
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [pinned_tweet_id])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/lists/{id}/followers"
    path_params: [{name: id, var: id}]
    query: [{name: max_results, var: max_results}, {name: pagination_token, var: pagination_token}, {name: "user.fields", var: user_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "tweet.fields", var: tweet_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, max_results: $max_results, pagination_token: $pagination_token, user_fields: $user_fields, expansions: $expansions, tweet_fields: $tweet_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns User objects that are members of a List by the provided List ID.
#
# GET /2/lists/{id}/members
# Docs: https://developer.twitter.com/en/docs/twitter-api/lists/list-members/api-reference/get-users-id-list_memberships
# Returns: record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>
# operationId: listGetMembers
export def "list-get-members" [
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
  --max-results: int # The maximum number of results. (format: int32, default: 100)
  --pagination-token: string # This parameter is used to get a specified 'page' of results.
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [pinned_tweet_id])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/lists/{id}/members"
    path_params: [{name: id, var: id}]
    query: [{name: max_results, var: max_results}, {name: pagination_token, var: pagination_token}, {name: "user.fields", var: user_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "tweet.fields", var: tweet_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, max_results: $max_results, pagination_token: $pagination_token, user_fields: $user_fields, expansions: $expansions, tweet_fields: $tweet_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a List member
#
# POST /2/lists/{id}/members
# Docs: https://developer.twitter.com/en/docs/twitter-api/lists/list-members/api-reference/post-lists-id-members
# Returns: record<data: record<is_member: bool>, errors: table<detail: string, status: int, title: string, type: string>>
# operationId: listAddMember
export def "list-add-member" [
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
  user_id: string # Unique identifier of this User. This is returned as a string in order to avoid complications with languages and tools that cannot handle large integers. (e.g. 2244994945)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2/lists/{id}/members"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: user_id, var: user_id}]}
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove a List member
#
# DELETE /2/lists/{id}/members/{user_id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/lists/list-members/api-reference/delete-lists-id-members-user_id
# Returns: record<data: record<is_member: bool>, errors: table<detail: string, status: int, title: string, type: string>>
# operationId: listRemoveMember
export def "list-remove-member" [
  id: string
  user_id: string
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
    method: delete
    path: "/2/lists/{id}/members/{user_id}"
    path_params: [{name: id, var: id}, {name: user_id, var: user_id}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Tweets timeline by List ID.
#
# GET /2/lists/{id}/tweets
# Docs: https://developer.twitter.com/en/docs/twitter-api/lists/list-tweets/api-reference/get-lists-id-tweets
# Returns: record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>
# operationId: listsIdTweets
export def "lists-id-tweets" [
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
  --max-results: int # The maximum number of results. (format: int32, default: 100)
  --pagination-token: string # This parameter is used to get the next 'page' of results.
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, attachments.poll_ids, author_id, edit_history_tweet_ids, entities.mentions.username, geo.place_id, in_reply_to_user_id, referenced_tweets.id, referenced_tweets.id.author_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --poll-fields: list<string> # A comma separated list of Poll fields to display. (e.g. [duration_minutes, end_datetime, id, options, voting_status])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --place-fields: list<string> # A comma separated list of Place fields to display. (e.g. [contained_within, country, country_code, full_name, geo, id, name, place_type])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/lists/{id}/tweets"
    path_params: [{name: id, var: id}]
    query: [{name: max_results, var: max_results}, {name: pagination_token, var: pagination_token}, {name: "tweet.fields", var: tweet_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "media.fields", var: media_fields, style: csv}, {name: "poll.fields", var: poll_fields, style: csv}, {name: "user.fields", var: user_fields, style: csv}, {name: "place.fields", var: place_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, max_results: $max_results, pagination_token: $pagination_token, tweet_fields: $tweet_fields, expansions: $expansions, media_fields: $media_fields, poll_fields: $poll_fields, user_fields: $user_fields, place_fields: $place_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns the OpenAPI Specification document.
#
# GET /2/openapi.json
# Returns: record
# operationId: getOpenApiSpec
export def "get-open-api-spec" [
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
    path: "/2/openapi.json"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Space lookup up Space IDs
#
# GET /2/spaces
# Docs: https://developer.twitter.com/en/docs/twitter-api/spaces/lookup/api-reference/get-spaces
# Returns: record<data: table<created_at: string, creator_id: string, ended_at: string, host_ids: list, id: string, invited_user_ids: list, is_ticketed: bool, lang: string, participant_count: int, scheduled_start: string, speaker_ids: list, started_at: string, state: string, subscriber_count: int, title: string, topics: list, updated_at: string>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>>
# operationId: findSpacesByIds
export def "find-spaces-by-ids" [
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
  --ids: list<string> # The list of Space IDs to return. (required)
  --space-fields: list<string> # A comma separated list of Space fields to display. (e.g. [created_at, creator_id, ended_at, host_ids, id, invited_user_ids, is_ticketed, lang, participant_count, scheduled_start, speaker_ids, started_at, state, subscriber_count, title, topic_ids, updated_at])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [creator_id, host_ids, invited_user_ids, speaker_ids, topic_ids])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --topic-fields: list<string> # A comma separated list of Topic fields to display. (e.g. [description, id, name])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/spaces"
    query: [{name: ids, var: ids, style: multi, required: true}, {name: "space.fields", var: space_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "user.fields", var: user_fields, style: csv}, {name: "topic.fields", var: topic_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, space_fields: $space_fields, expansions: $expansions, user_fields: $user_fields, topic_fields: $topic_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Space lookup by their creators
#
# GET /2/spaces/by/creator_ids
# Docs: https://developer.twitter.com/en/docs/twitter-api/spaces/lookup/api-reference/get-spaces-by-creator-ids
# Returns: record<data: table<created_at: string, creator_id: string, ended_at: string, host_ids: list, id: string, invited_user_ids: list, is_ticketed: bool, lang: string, participant_count: int, scheduled_start: string, speaker_ids: list, started_at: string, state: string, subscriber_count: int, title: string, topics: list, updated_at: string>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<result_count: int>>
# operationId: findSpacesByCreatorIds
export def "find-spaces-by-creator-ids" [
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
  --user-ids: list<string> # The IDs of Users to search through. (required)
  --space-fields: list<string> # A comma separated list of Space fields to display. (e.g. [created_at, creator_id, ended_at, host_ids, id, invited_user_ids, is_ticketed, lang, participant_count, scheduled_start, speaker_ids, started_at, state, subscriber_count, title, topic_ids, updated_at])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [creator_id, host_ids, invited_user_ids, speaker_ids, topic_ids])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --topic-fields: list<string> # A comma separated list of Topic fields to display. (e.g. [description, id, name])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/spaces/by/creator_ids"
    query: [{name: user_ids, var: user_ids, style: multi, required: true}, {name: "space.fields", var: space_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "user.fields", var: user_fields, style: csv}, {name: "topic.fields", var: topic_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    user_ids: $user_ids, space_fields: $space_fields, expansions: $expansions, user_fields: $user_fields, topic_fields: $topic_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Search for Spaces
#
# GET /2/spaces/search
# Docs: https://developer.twitter.com/en/docs/twitter-api/spaces/search/api-reference/get-spaces-search
# Returns: record<data: table<created_at: string, creator_id: string, ended_at: string, host_ids: list, id: string, invited_user_ids: list, is_ticketed: bool, lang: string, participant_count: int, scheduled_start: string, speaker_ids: list, started_at: string, state: string, subscriber_count: int, title: string, topics: list, updated_at: string>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<result_count: int>>
# operationId: searchSpaces
export def "search-spaces" [
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
  --query: string # The search query. (required, e.g. crypto)
  --state: string@state-completer # The state of Spaces to search for. (default: all)
  --max-results: int # The number of results to return. (format: int32, default: 100)
  --space-fields: list<string> # A comma separated list of Space fields to display. (e.g. [created_at, creator_id, ended_at, host_ids, id, invited_user_ids, is_ticketed, lang, participant_count, scheduled_start, speaker_ids, started_at, state, subscriber_count, title, topic_ids, updated_at])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [creator_id, host_ids, invited_user_ids, speaker_ids, topic_ids])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --topic-fields: list<string> # A comma separated list of Topic fields to display. (e.g. [description, id, name])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/spaces/search"
    query: [{name: query, var: query, required: true}, {name: state, var: state}, {name: max_results, var: max_results}, {name: "space.fields", var: space_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "user.fields", var: user_fields, style: csv}, {name: "topic.fields", var: topic_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    query: $query, state: $state, max_results: $max_results, space_fields: $space_fields, expansions: $expansions, user_fields: $user_fields, topic_fields: $topic_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Space lookup by Space ID
#
# GET /2/spaces/{id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/spaces/lookup/api-reference/get-spaces-id
# Returns: record<data: record<created_at: string, creator_id: string, ended_at: string, host_ids: list<string>, id: string, invited_user_ids: list<string>, is_ticketed: bool, lang: string, participant_count: int, scheduled_start: string, speaker_ids: list<string>, started_at: string, state: string, subscriber_count: int, title: string, topics: list<record>, updated_at: string>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>>
# operationId: findSpaceById
export def "find-space-by-id" [
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
  --space-fields: list<string> # A comma separated list of Space fields to display. (e.g. [created_at, creator_id, ended_at, host_ids, id, invited_user_ids, is_ticketed, lang, participant_count, scheduled_start, speaker_ids, started_at, state, subscriber_count, title, topic_ids, updated_at])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [creator_id, host_ids, invited_user_ids, speaker_ids, topic_ids])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --topic-fields: list<string> # A comma separated list of Topic fields to display. (e.g. [description, id, name])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/spaces/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "space.fields", var: space_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "user.fields", var: user_fields, style: csv}, {name: "topic.fields", var: topic_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, space_fields: $space_fields, expansions: $expansions, user_fields: $user_fields, topic_fields: $topic_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve the list of Users who purchased a ticket to the given space
#
# GET /2/spaces/{id}/buyers
# Docs: https://developer.twitter.com/en/docs/twitter-api/spaces/lookup/api-reference/get-spaces-id-buyers
# Returns: record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>
# operationId: spaceBuyers
export def "space-buyers" [
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
  --pagination-token: string # This parameter is used to get a specified 'page' of results.
  --max-results: int # The maximum number of results. (format: int32, default: 100)
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [pinned_tweet_id])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/spaces/{id}/buyers"
    path_params: [{name: id, var: id}]
    query: [{name: pagination_token, var: pagination_token}, {name: max_results, var: max_results}, {name: "user.fields", var: user_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "tweet.fields", var: tweet_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, pagination_token: $pagination_token, max_results: $max_results, user_fields: $user_fields, expansions: $expansions, tweet_fields: $tweet_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve Tweets from a Space.
#
# GET /2/spaces/{id}/tweets
# Docs: https://developer.twitter.com/en/docs/twitter-api/spaces/lookup/api-reference/get-spaces-id-tweets
# Returns: record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>
# operationId: spaceTweets
export def "space-tweets" [
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
  --max-results: int # The number of Tweets to fetch from the provided space. If not provided, the value will default to the maximum of 100. (format: int32, default: 100, e.g. 25)
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, attachments.poll_ids, author_id, edit_history_tweet_ids, entities.mentions.username, geo.place_id, in_reply_to_user_id, referenced_tweets.id, referenced_tweets.id.author_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --poll-fields: list<string> # A comma separated list of Poll fields to display. (e.g. [duration_minutes, end_datetime, id, options, voting_status])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --place-fields: list<string> # A comma separated list of Place fields to display. (e.g. [contained_within, country, country_code, full_name, geo, id, name, place_type])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/spaces/{id}/tweets"
    path_params: [{name: id, var: id}]
    query: [{name: max_results, var: max_results}, {name: "tweet.fields", var: tweet_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "media.fields", var: media_fields, style: csv}, {name: "poll.fields", var: poll_fields, style: csv}, {name: "user.fields", var: user_fields, style: csv}, {name: "place.fields", var: place_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, max_results: $max_results, tweet_fields: $tweet_fields, expansions: $expansions, media_fields: $media_fields, poll_fields: $poll_fields, user_fields: $user_fields, place_fields: $place_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Tweet lookup by Tweet IDs
#
# GET /2/tweets
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/lookup/api-reference/get-tweets
# Returns: record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>>
# operationId: findTweetsById
export def "find-tweets-by-id" [
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
  --ids: list<string> # A comma separated list of Tweet IDs. Up to 100 are allowed in a single request. (required)
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, attachments.poll_ids, author_id, edit_history_tweet_ids, entities.mentions.username, geo.place_id, in_reply_to_user_id, referenced_tweets.id, referenced_tweets.id.author_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --poll-fields: list<string> # A comma separated list of Poll fields to display. (e.g. [duration_minutes, end_datetime, id, options, voting_status])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --place-fields: list<string> # A comma separated list of Place fields to display. (e.g. [contained_within, country, country_code, full_name, geo, id, name, place_type])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/tweets"
    query: [{name: ids, var: ids, style: csv, required: true}, {name: "tweet.fields", var: tweet_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "media.fields", var: media_fields, style: csv}, {name: "poll.fields", var: poll_fields, style: csv}, {name: "user.fields", var: user_fields, style: csv}, {name: "place.fields", var: place_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, tweet_fields: $tweet_fields, expansions: $expansions, media_fields: $media_fields, poll_fields: $poll_fields, user_fields: $user_fields, place_fields: $place_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creation of a Tweet
#
# POST /2/tweets
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/manage-tweets/api-reference/post-tweets
# Returns: record<data: record<id: string, text: string>, errors: table<detail: string, status: int, title: string, type: string>>
# operationId: createTweet
export def "create-tweet" [
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
  --card-uri: string # Card Uri Parameter. This is mutually exclusive from Quote Tweet Id, Poll, Media, and Direct Message Deep Link.
  --direct-message-deep-link: string # Link to take the conversation from the public timeline to a private Direct Message.
  --for-super-followers-only: oneof<nothing, bool> # Exclusive Tweet for super followers. (default: false)
  --geo: record # Place ID being attached to the Tweet for geo location. — shape: {place_id?: string}
  --media: record # Media information being attached to created Tweet. This is mutually exclusive from Quote Tweet Id, Poll, and Card URI. — shape: {media_ids: list<string>, tagged_user_ids?: list<string>}
  --nullcast: oneof<nothing, bool> # Nullcasted (promoted-only) Tweets do not appear in the public timeline and are not served to followers. (default: false)
  --poll: record # Poll options for a Tweet with a poll. This is mutually exclusive from Media, Quote Tweet Id, and Card URI. — shape: {duration_minutes: int, options: list<string>, reply_settings?: "following"|"mentionedUsers"}
  --quote-tweet-id: string # Unique identifier of this Tweet. This is returned as a string in order to avoid complications with languages and tools that cannot handle large integers. (e.g. 1346889436626259968)
  --reply: record # Tweet information of the Tweet being replied to. — shape: {exclude_reply_user_ids?: list<string>, in_reply_to_tweet_id: string}
  --reply-settings: string@reply-settings-completer # Settings to indicate who can reply to the Tweet.
  --text: string # The content of the Tweet. (e.g. Learn how to use the user Tweet timeline and user mention timeline endpoints in the Twitter API v2 to explore Tweet\u2026 https:\/\/t.co\/56a0vZUx7i)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2/tweets"
    body: {content_type: "application/json", kind: json, fields: [{name: card_uri, var: card_uri}, {name: direct_message_deep_link, var: direct_message_deep_link}, {name: for_super_followers_only, var: for_super_followers_only}, {name: geo, var: geo}, {name: media, var: media}, {name: nullcast, var: nullcast}, {name: poll, var: poll}, {name: quote_tweet_id, var: quote_tweet_id}, {name: reply, var: reply}, {name: reply_settings, var: reply_settings}, {name: text, var: text}]}
    accept: ["application/json", "application/problem+json"]
    ok: [201]
    auth: bearer
  } {
    card_uri: $card_uri, direct_message_deep_link: $direct_message_deep_link, for_super_followers_only: $for_super_followers_only, geo: $geo, media: $media, nullcast: $nullcast, poll: $poll, quote_tweet_id: $quote_tweet_id, reply: $reply, reply_settings: $reply_settings, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Tweets Compliance stream
#
# GET /2/tweets/compliance/stream
# operationId: getTweetsComplianceStream
export def "get-tweets-compliance-stream" [
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
  --backfill-minutes: int # The number of minutes of backfill requested. (format: int32)
  --partition: int # The partition number. (required, format: int32)
  --start-time: string # YYYY-MM-DDTHH:mm:ssZ. The earliest UTC timestamp from which the Tweet Compliance events will be provided. (format: date-time, e.g. 2021-02-01T18:40:40.000Z)
  --end-time: string # YYYY-MM-DDTHH:mm:ssZ. The latest UTC timestamp to which the Tweet Compliance events will be provided. (format: date-time, e.g. 2021-02-14T18:40:40.000Z)
]: nothing -> any {
  http-request {
    method: get
    path: "/2/tweets/compliance/stream"
    query: [{name: backfill_minutes, var: backfill_minutes}, {name: partition, var: partition, required: true}, {name: start_time, var: start_time}, {name: end_time, var: end_time}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    backfill_minutes: $backfill_minutes, partition: $partition, start_time: $start_time, end_time: $end_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Full archive search counts
#
# GET /2/tweets/counts/all
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/search/api-reference/get-tweets-search-all
# Returns: record<data: table<end: string, start: string, tweet_count: int>, errors: table<detail: string, status: int, title: string, type: string>, meta: record<newest_id: string, next_token: string, oldest_id: string, total_tweet_count: int>>
# operationId: tweetCountsFullArchiveSearch
export def "tweet-counts-full-archive-search" [
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
  --query: string # One query/rule/filter for matching Tweets. Refer to https://t.co/rulelength to identify the max query length. (required, e.g. (from:TwitterDev OR from:TwitterAPI) has:media -is:retweet)
  --start-time: string # YYYY-MM-DDTHH:mm:ssZ. The oldest UTC timestamp (from most recent 7 days) from which the Tweets will be provided. Timestamp is in second granularity and is inclusive (i.e. 12:00:01 includes the first second of the minute). (format: date-time)
  --end-time: string # YYYY-MM-DDTHH:mm:ssZ. The newest, most recent UTC timestamp to which the Tweets will be provided. Timestamp is in second granularity and is exclusive (i.e. 12:00:01 excludes the first second of the minute). (format: date-time)
  --since-id: string # Returns results with a Tweet ID greater than (that is, more recent than) the specified ID. (e.g. 1346889436626259968)
  --until-id: string # Returns results with a Tweet ID less than (that is, older than) the specified ID. (e.g. 1346889436626259968)
  --next-token: string # This parameter is used to get the next 'page' of results. The value used with the parameter is pulled directly from the response provided by the API, and should not be modified.
  --pagination-token: string # This parameter is used to get the next 'page' of results. The value used with the parameter is pulled directly from the response provided by the API, and should not be modified.
  --granularity: string@granularity-completer # The granularity for the search counts results. (default: hour)
  --search-count-fields: list<string> # A comma separated list of SearchCount fields to display. (e.g. [end, start, tweet_count])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/tweets/counts/all"
    query: [{name: query, var: query, required: true}, {name: start_time, var: start_time}, {name: end_time, var: end_time}, {name: since_id, var: since_id}, {name: until_id, var: until_id}, {name: next_token, var: next_token}, {name: pagination_token, var: pagination_token}, {name: granularity, var: granularity}, {name: "search_count.fields", var: search_count_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    query: $query, start_time: $start_time, end_time: $end_time, since_id: $since_id, until_id: $until_id, next_token: $next_token, pagination_token: $pagination_token, granularity: $granularity, search_count_fields: $search_count_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Recent search counts
#
# GET /2/tweets/counts/recent
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/counts/api-reference/get-tweets-counts-recent
# Returns: record<data: table<end: string, start: string, tweet_count: int>, errors: table<detail: string, status: int, title: string, type: string>, meta: record<newest_id: string, next_token: string, oldest_id: string, total_tweet_count: int>>
# operationId: tweetCountsRecentSearch
export def "tweet-counts-recent-search" [
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
  --query: string # One query/rule/filter for matching Tweets. Refer to https://t.co/rulelength to identify the max query length. (required, e.g. (from:TwitterDev OR from:TwitterAPI) has:media -is:retweet)
  --start-time: string # YYYY-MM-DDTHH:mm:ssZ. The oldest UTC timestamp (from most recent 7 days) from which the Tweets will be provided. Timestamp is in second granularity and is inclusive (i.e. 12:00:01 includes the first second of the minute). (format: date-time)
  --end-time: string # YYYY-MM-DDTHH:mm:ssZ. The newest, most recent UTC timestamp to which the Tweets will be provided. Timestamp is in second granularity and is exclusive (i.e. 12:00:01 excludes the first second of the minute). (format: date-time)
  --since-id: string # Returns results with a Tweet ID greater than (that is, more recent than) the specified ID. (e.g. 1346889436626259968)
  --until-id: string # Returns results with a Tweet ID less than (that is, older than) the specified ID. (e.g. 1346889436626259968)
  --next-token: string # This parameter is used to get the next 'page' of results. The value used with the parameter is pulled directly from the response provided by the API, and should not be modified.
  --pagination-token: string # This parameter is used to get the next 'page' of results. The value used with the parameter is pulled directly from the response provided by the API, and should not be modified.
  --granularity: string@granularity-completer # The granularity for the search counts results. (default: hour)
  --search-count-fields: list<string> # A comma separated list of SearchCount fields to display. (e.g. [end, start, tweet_count])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/tweets/counts/recent"
    query: [{name: query, var: query, required: true}, {name: start_time, var: start_time}, {name: end_time, var: end_time}, {name: since_id, var: since_id}, {name: until_id, var: until_id}, {name: next_token, var: next_token}, {name: pagination_token, var: pagination_token}, {name: granularity, var: granularity}, {name: "search_count.fields", var: search_count_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    query: $query, start_time: $start_time, end_time: $end_time, since_id: $since_id, until_id: $until_id, next_token: $next_token, pagination_token: $pagination_token, granularity: $granularity, search_count_fields: $search_count_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Firehose stream
#
# GET /2/tweets/firehose/stream
# Returns: record<data: record<attachments: record<media_keys: list, poll_ids: list>, author_id: string, context_annotations: list<record>, conversation_id: string, created_at: string, edit_controls: record<editable_until: string, edits_remaining: int, is_edit_eligible: bool>, edit_history_tweet_ids: list<string>, entities: record<annotations: list, cashtags: list, hashtags: list, mentions: list, urls: list>, geo: record<coordinates: record, place_id: string>, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record<impression_count: int>, organic_metrics: record<impression_count: int, like_count: int, reply_count: int, retweet_count: int>, possibly_sensitive: bool, promoted_metrics: record<impression_count: int, like_count: int, reply_count: int, retweet_count: int>, public_metrics: record<impression_count: int, like_count: int, quote_count: int, reply_count: int, retweet_count: int>, referenced_tweets: list<record>, reply_settings: string, source: string, text: string, withheld: record<copyright: bool, country_codes: list, scope: string>>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>>
# operationId: getTweetsFirehoseStream
export def "get-tweets-firehose-stream" [
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
  --backfill-minutes: int # The number of minutes of backfill requested. (format: int32)
  --partition: int # The partition number. (required, format: int32)
  --start-time: string # YYYY-MM-DDTHH:mm:ssZ. The earliest UTC timestamp to which the Tweets will be provided. (format: date-time, e.g. 2021-02-14T18:40:40.000Z)
  --end-time: string # YYYY-MM-DDTHH:mm:ssZ. The latest UTC timestamp to which the Tweets will be provided. (format: date-time, e.g. 2021-02-14T18:40:40.000Z)
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, attachments.poll_ids, author_id, edit_history_tweet_ids, entities.mentions.username, geo.place_id, in_reply_to_user_id, referenced_tweets.id, referenced_tweets.id.author_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --poll-fields: list<string> # A comma separated list of Poll fields to display. (e.g. [duration_minutes, end_datetime, id, options, voting_status])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --place-fields: list<string> # A comma separated list of Place fields to display. (e.g. [contained_within, country, country_code, full_name, geo, id, name, place_type])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/tweets/firehose/stream"
    query: [{name: backfill_minutes, var: backfill_minutes}, {name: partition, var: partition, required: true}, {name: start_time, var: start_time}, {name: end_time, var: end_time}, {name: "tweet.fields", var: tweet_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "media.fields", var: media_fields, style: csv}, {name: "poll.fields", var: poll_fields, style: csv}, {name: "user.fields", var: user_fields, style: csv}, {name: "place.fields", var: place_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    backfill_minutes: $backfill_minutes, partition: $partition, start_time: $start_time, end_time: $end_time, tweet_fields: $tweet_fields, expansions: $expansions, media_fields: $media_fields, poll_fields: $poll_fields, user_fields: $user_fields, place_fields: $place_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Tweets Label stream
#
# GET /2/tweets/label/stream
# operationId: getTweetsLabelStream
export def "get-tweets-label-stream" [
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
  --backfill-minutes: int # The number of minutes of backfill requested. (format: int32)
  --start-time: string # YYYY-MM-DDTHH:mm:ssZ. The earliest UTC timestamp from which the Tweet labels will be provided. (format: date-time, e.g. 2021-02-01T18:40:40.000Z)
  --end-time: string # YYYY-MM-DDTHH:mm:ssZ. The latest UTC timestamp from which the Tweet labels will be provided. (format: date-time, e.g. 2021-02-01T18:40:40.000Z)
]: nothing -> any {
  http-request {
    method: get
    path: "/2/tweets/label/stream"
    query: [{name: backfill_minutes, var: backfill_minutes}, {name: start_time, var: start_time}, {name: end_time, var: end_time}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    backfill_minutes: $backfill_minutes, start_time: $start_time, end_time: $end_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Sample stream
#
# GET /2/tweets/sample/stream
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/volume-streams/api-reference/get-tweets-sample-stream
# Returns: record<data: record<attachments: record<media_keys: list, poll_ids: list>, author_id: string, context_annotations: list<record>, conversation_id: string, created_at: string, edit_controls: record<editable_until: string, edits_remaining: int, is_edit_eligible: bool>, edit_history_tweet_ids: list<string>, entities: record<annotations: list, cashtags: list, hashtags: list, mentions: list, urls: list>, geo: record<coordinates: record, place_id: string>, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record<impression_count: int>, organic_metrics: record<impression_count: int, like_count: int, reply_count: int, retweet_count: int>, possibly_sensitive: bool, promoted_metrics: record<impression_count: int, like_count: int, reply_count: int, retweet_count: int>, public_metrics: record<impression_count: int, like_count: int, quote_count: int, reply_count: int, retweet_count: int>, referenced_tweets: list<record>, reply_settings: string, source: string, text: string, withheld: record<copyright: bool, country_codes: list, scope: string>>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>>
# operationId: sampleStream
export def "sample-stream" [
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
  --backfill-minutes: int # The number of minutes of backfill requested. (format: int32)
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, attachments.poll_ids, author_id, edit_history_tweet_ids, entities.mentions.username, geo.place_id, in_reply_to_user_id, referenced_tweets.id, referenced_tweets.id.author_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --poll-fields: list<string> # A comma separated list of Poll fields to display. (e.g. [duration_minutes, end_datetime, id, options, voting_status])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --place-fields: list<string> # A comma separated list of Place fields to display. (e.g. [contained_within, country, country_code, full_name, geo, id, name, place_type])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/tweets/sample/stream"
    query: [{name: backfill_minutes, var: backfill_minutes}, {name: "tweet.fields", var: tweet_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "media.fields", var: media_fields, style: csv}, {name: "poll.fields", var: poll_fields, style: csv}, {name: "user.fields", var: user_fields, style: csv}, {name: "place.fields", var: place_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    backfill_minutes: $backfill_minutes, tweet_fields: $tweet_fields, expansions: $expansions, media_fields: $media_fields, poll_fields: $poll_fields, user_fields: $user_fields, place_fields: $place_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Sample 10% stream
#
# GET /2/tweets/sample10/stream
# Returns: record<data: record<attachments: record<media_keys: list, poll_ids: list>, author_id: string, context_annotations: list<record>, conversation_id: string, created_at: string, edit_controls: record<editable_until: string, edits_remaining: int, is_edit_eligible: bool>, edit_history_tweet_ids: list<string>, entities: record<annotations: list, cashtags: list, hashtags: list, mentions: list, urls: list>, geo: record<coordinates: record, place_id: string>, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record<impression_count: int>, organic_metrics: record<impression_count: int, like_count: int, reply_count: int, retweet_count: int>, possibly_sensitive: bool, promoted_metrics: record<impression_count: int, like_count: int, reply_count: int, retweet_count: int>, public_metrics: record<impression_count: int, like_count: int, quote_count: int, reply_count: int, retweet_count: int>, referenced_tweets: list<record>, reply_settings: string, source: string, text: string, withheld: record<copyright: bool, country_codes: list, scope: string>>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>>
# operationId: getTweetsSample10Stream
export def "get-tweets-sample10-stream" [
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
  --backfill-minutes: int # The number of minutes of backfill requested. (format: int32)
  --partition: int # The partition number. (required, format: int32)
  --start-time: string # YYYY-MM-DDTHH:mm:ssZ. The earliest UTC timestamp to which the Tweets will be provided. (format: date-time, e.g. 2021-02-14T18:40:40.000Z)
  --end-time: string # YYYY-MM-DDTHH:mm:ssZ. The latest UTC timestamp to which the Tweets will be provided. (format: date-time, e.g. 2021-02-14T18:40:40.000Z)
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, attachments.poll_ids, author_id, edit_history_tweet_ids, entities.mentions.username, geo.place_id, in_reply_to_user_id, referenced_tweets.id, referenced_tweets.id.author_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --poll-fields: list<string> # A comma separated list of Poll fields to display. (e.g. [duration_minutes, end_datetime, id, options, voting_status])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --place-fields: list<string> # A comma separated list of Place fields to display. (e.g. [contained_within, country, country_code, full_name, geo, id, name, place_type])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/tweets/sample10/stream"
    query: [{name: backfill_minutes, var: backfill_minutes}, {name: partition, var: partition, required: true}, {name: start_time, var: start_time}, {name: end_time, var: end_time}, {name: "tweet.fields", var: tweet_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "media.fields", var: media_fields, style: csv}, {name: "poll.fields", var: poll_fields, style: csv}, {name: "user.fields", var: user_fields, style: csv}, {name: "place.fields", var: place_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    backfill_minutes: $backfill_minutes, partition: $partition, start_time: $start_time, end_time: $end_time, tweet_fields: $tweet_fields, expansions: $expansions, media_fields: $media_fields, poll_fields: $poll_fields, user_fields: $user_fields, place_fields: $place_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Full-archive search
#
# GET /2/tweets/search/all
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/search/api-reference/get-tweets-search-all
# Returns: record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<newest_id: string, next_token: string, oldest_id: string, result_count: int>>
# operationId: tweetsFullarchiveSearch
export def "tweets-fullarchive-search" [
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
  --query: string # One query/rule/filter for matching Tweets. Refer to https://t.co/rulelength to identify the max query length. (required, e.g. (from:TwitterDev OR from:TwitterAPI) has:media -is:retweet)
  --start-time: string # YYYY-MM-DDTHH:mm:ssZ. The oldest UTC timestamp from which the Tweets will be provided. Timestamp is in second granularity and is inclusive (i.e. 12:00:01 includes the first second of the minute). (format: date-time)
  --end-time: string # YYYY-MM-DDTHH:mm:ssZ. The newest, most recent UTC timestamp to which the Tweets will be provided. Timestamp is in second granularity and is exclusive (i.e. 12:00:01 excludes the first second of the minute). (format: date-time)
  --since-id: string # Returns results with a Tweet ID greater than (that is, more recent than) the specified ID. (e.g. 1346889436626259968)
  --until-id: string # Returns results with a Tweet ID less than (that is, older than) the specified ID. (e.g. 1346889436626259968)
  --max-results: int # The maximum number of search results to be returned by a request. (format: int32, default: 10)
  --next-token: string # This parameter is used to get the next 'page' of results. The value used with the parameter is pulled directly from the response provided by the API, and should not be modified.
  --pagination-token: string # This parameter is used to get the next 'page' of results. The value used with the parameter is pulled directly from the response provided by the API, and should not be modified.
  --sort-order: string@sort-order-completer # This order in which to return results.
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, attachments.poll_ids, author_id, edit_history_tweet_ids, entities.mentions.username, geo.place_id, in_reply_to_user_id, referenced_tweets.id, referenced_tweets.id.author_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --poll-fields: list<string> # A comma separated list of Poll fields to display. (e.g. [duration_minutes, end_datetime, id, options, voting_status])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --place-fields: list<string> # A comma separated list of Place fields to display. (e.g. [contained_within, country, country_code, full_name, geo, id, name, place_type])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/tweets/search/all"
    query: [{name: query, var: query, required: true}, {name: start_time, var: start_time}, {name: end_time, var: end_time}, {name: since_id, var: since_id}, {name: until_id, var: until_id}, {name: max_results, var: max_results}, {name: next_token, var: next_token}, {name: pagination_token, var: pagination_token}, {name: sort_order, var: sort_order}, {name: "tweet.fields", var: tweet_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "media.fields", var: media_fields, style: csv}, {name: "poll.fields", var: poll_fields, style: csv}, {name: "user.fields", var: user_fields, style: csv}, {name: "place.fields", var: place_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    query: $query, start_time: $start_time, end_time: $end_time, since_id: $since_id, until_id: $until_id, max_results: $max_results, next_token: $next_token, pagination_token: $pagination_token, sort_order: $sort_order, tweet_fields: $tweet_fields, expansions: $expansions, media_fields: $media_fields, poll_fields: $poll_fields, user_fields: $user_fields, place_fields: $place_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Recent search
#
# GET /2/tweets/search/recent
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/search/api-reference/get-tweets-search-recent
# Returns: record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<newest_id: string, next_token: string, oldest_id: string, result_count: int>>
# operationId: tweetsRecentSearch
export def "tweets-recent-search" [
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
  --query: string # One query/rule/filter for matching Tweets. Refer to https://t.co/rulelength to identify the max query length. (required, e.g. (from:TwitterDev OR from:TwitterAPI) has:media -is:retweet)
  --start-time: string # YYYY-MM-DDTHH:mm:ssZ. The oldest UTC timestamp from which the Tweets will be provided. Timestamp is in second granularity and is inclusive (i.e. 12:00:01 includes the first second of the minute). (format: date-time)
  --end-time: string # YYYY-MM-DDTHH:mm:ssZ. The newest, most recent UTC timestamp to which the Tweets will be provided. Timestamp is in second granularity and is exclusive (i.e. 12:00:01 excludes the first second of the minute). (format: date-time)
  --since-id: string # Returns results with a Tweet ID greater than (that is, more recent than) the specified ID. (e.g. 1346889436626259968)
  --until-id: string # Returns results with a Tweet ID less than (that is, older than) the specified ID. (e.g. 1346889436626259968)
  --max-results: int # The maximum number of search results to be returned by a request. (format: int32, default: 10)
  --next-token: string # This parameter is used to get the next 'page' of results. The value used with the parameter is pulled directly from the response provided by the API, and should not be modified.
  --pagination-token: string # This parameter is used to get the next 'page' of results. The value used with the parameter is pulled directly from the response provided by the API, and should not be modified.
  --sort-order: string@sort-order-completer # This order in which to return results.
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, attachments.poll_ids, author_id, edit_history_tweet_ids, entities.mentions.username, geo.place_id, in_reply_to_user_id, referenced_tweets.id, referenced_tweets.id.author_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --poll-fields: list<string> # A comma separated list of Poll fields to display. (e.g. [duration_minutes, end_datetime, id, options, voting_status])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --place-fields: list<string> # A comma separated list of Place fields to display. (e.g. [contained_within, country, country_code, full_name, geo, id, name, place_type])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/tweets/search/recent"
    query: [{name: query, var: query, required: true}, {name: start_time, var: start_time}, {name: end_time, var: end_time}, {name: since_id, var: since_id}, {name: until_id, var: until_id}, {name: max_results, var: max_results}, {name: next_token, var: next_token}, {name: pagination_token, var: pagination_token}, {name: sort_order, var: sort_order}, {name: "tweet.fields", var: tweet_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "media.fields", var: media_fields, style: csv}, {name: "poll.fields", var: poll_fields, style: csv}, {name: "user.fields", var: user_fields, style: csv}, {name: "place.fields", var: place_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    query: $query, start_time: $start_time, end_time: $end_time, since_id: $since_id, until_id: $until_id, max_results: $max_results, next_token: $next_token, pagination_token: $pagination_token, sort_order: $sort_order, tweet_fields: $tweet_fields, expansions: $expansions, media_fields: $media_fields, poll_fields: $poll_fields, user_fields: $user_fields, place_fields: $place_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Filtered stream
#
# GET /2/tweets/search/stream
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/filtered-stream/api-reference/get-tweets-search-stream
# Returns: record<data: record<attachments: record<media_keys: list, poll_ids: list>, author_id: string, context_annotations: list<record>, conversation_id: string, created_at: string, edit_controls: record<editable_until: string, edits_remaining: int, is_edit_eligible: bool>, edit_history_tweet_ids: list<string>, entities: record<annotations: list, cashtags: list, hashtags: list, mentions: list, urls: list>, geo: record<coordinates: record, place_id: string>, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record<impression_count: int>, organic_metrics: record<impression_count: int, like_count: int, reply_count: int, retweet_count: int>, possibly_sensitive: bool, promoted_metrics: record<impression_count: int, like_count: int, reply_count: int, retweet_count: int>, public_metrics: record<impression_count: int, like_count: int, quote_count: int, reply_count: int, retweet_count: int>, referenced_tweets: list<record>, reply_settings: string, source: string, text: string, withheld: record<copyright: bool, country_codes: list, scope: string>>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, matching_rules: table<id: string, tag: string>>
# operationId: searchStream
export def "search-stream" [
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
  --backfill-minutes: int # The number of minutes of backfill requested. (format: int32)
  --start-time: string # YYYY-MM-DDTHH:mm:ssZ. The earliest UTC timestamp from which the Tweets will be provided. (format: date-time, e.g. 2021-02-01T18:40:40.000Z)
  --end-time: string # YYYY-MM-DDTHH:mm:ssZ. The latest UTC timestamp to which the Tweets will be provided. (format: date-time, e.g. 2021-02-14T18:40:40.000Z)
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, attachments.poll_ids, author_id, edit_history_tweet_ids, entities.mentions.username, geo.place_id, in_reply_to_user_id, referenced_tweets.id, referenced_tweets.id.author_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --poll-fields: list<string> # A comma separated list of Poll fields to display. (e.g. [duration_minutes, end_datetime, id, options, voting_status])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --place-fields: list<string> # A comma separated list of Place fields to display. (e.g. [contained_within, country, country_code, full_name, geo, id, name, place_type])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/tweets/search/stream"
    query: [{name: backfill_minutes, var: backfill_minutes}, {name: start_time, var: start_time}, {name: end_time, var: end_time}, {name: "tweet.fields", var: tweet_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "media.fields", var: media_fields, style: csv}, {name: "poll.fields", var: poll_fields, style: csv}, {name: "user.fields", var: user_fields, style: csv}, {name: "place.fields", var: place_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    backfill_minutes: $backfill_minutes, start_time: $start_time, end_time: $end_time, tweet_fields: $tweet_fields, expansions: $expansions, media_fields: $media_fields, poll_fields: $poll_fields, user_fields: $user_fields, place_fields: $place_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Rules lookup
#
# GET /2/tweets/search/stream/rules
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/filtered-stream/api-reference/get-tweets-search-stream-rules
# Returns: record<data: table<id: string, tag: string, value: string>, meta: record<next_token: string, result_count: int, sent: string, summary: any>>
# operationId: getRules
export def "get-rules" [
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
  --ids: list<string> # A comma-separated list of Rule IDs.
  --max-results: int # The maximum number of results. (format: int32, default: 1000)
  --pagination-token: string # This value is populated by passing the 'next_token' returned in a request to paginate through results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/tweets/search/stream/rules"
    query: [{name: ids, var: ids, style: multi}, {name: max_results, var: max_results}, {name: pagination_token, var: pagination_token}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, max_results: $max_results, pagination_token: $pagination_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add/Delete rules
#
# POST /2/tweets/search/stream/rules
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/filtered-stream/api-reference/post-tweets-search-stream-rules
# Returns: record<data: table<id: string, tag: string, value: string>, errors: table<detail: string, status: int, title: string, type: string>, meta: record<next_token: string, result_count: int, sent: string, summary: any>>
# operationId: addOrDeleteRules
export def "add-or-delete-rules" [
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
  --qp-dry-run: oneof<nothing, bool> # Dry Run can be used with both the add and delete action, with the expected result given, but without actually taking any action in the system (meaning the end state will always be as it was when the request was submitted). This is particularly useful to validate rule changes. (spec name: dry_run)
  --add: list # item shape: {tag?: string, value: string}
  --delete: record # IDs and values of all deleted user-specified stream filtering rules. — shape: {ids?: list<string>, values?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2/tweets/search/stream/rules"
    query: [{name: dry_run, var: qp_dry_run}]
    body: {content_type: "application/json", kind: json, fields: [{name: add, var: add}, {name: delete, var: delete}]}
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    qp_dry_run: $qp_dry_run, add: $add, delete: $delete
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Tweet delete by Tweet ID
#
# DELETE /2/tweets/{id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/manage-tweets/api-reference/delete-tweets-id
# Returns: record<data: record<deleted: bool>, errors: table<detail: string, status: int, title: string, type: string>>
# operationId: deleteTweetById
export def "delete-tweet-by-id" [
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
    method: delete
    path: "/2/tweets/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Tweet lookup by Tweet ID
#
# GET /2/tweets/{id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/lookup/api-reference/get-tweets-id
# Returns: record<data: record<attachments: record<media_keys: list, poll_ids: list>, author_id: string, context_annotations: list<record>, conversation_id: string, created_at: string, edit_controls: record<editable_until: string, edits_remaining: int, is_edit_eligible: bool>, edit_history_tweet_ids: list<string>, entities: record<annotations: list, cashtags: list, hashtags: list, mentions: list, urls: list>, geo: record<coordinates: record, place_id: string>, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record<impression_count: int>, organic_metrics: record<impression_count: int, like_count: int, reply_count: int, retweet_count: int>, possibly_sensitive: bool, promoted_metrics: record<impression_count: int, like_count: int, reply_count: int, retweet_count: int>, public_metrics: record<impression_count: int, like_count: int, quote_count: int, reply_count: int, retweet_count: int>, referenced_tweets: list<record>, reply_settings: string, source: string, text: string, withheld: record<copyright: bool, country_codes: list, scope: string>>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>>
# operationId: findTweetById
export def "find-tweet-by-id" [
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
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, attachments.poll_ids, author_id, edit_history_tweet_ids, entities.mentions.username, geo.place_id, in_reply_to_user_id, referenced_tweets.id, referenced_tweets.id.author_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --poll-fields: list<string> # A comma separated list of Poll fields to display. (e.g. [duration_minutes, end_datetime, id, options, voting_status])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --place-fields: list<string> # A comma separated list of Place fields to display. (e.g. [contained_within, country, country_code, full_name, geo, id, name, place_type])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/tweets/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "tweet.fields", var: tweet_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "media.fields", var: media_fields, style: csv}, {name: "poll.fields", var: poll_fields, style: csv}, {name: "user.fields", var: user_fields, style: csv}, {name: "place.fields", var: place_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, tweet_fields: $tweet_fields, expansions: $expansions, media_fields: $media_fields, poll_fields: $poll_fields, user_fields: $user_fields, place_fields: $place_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns User objects that have liked the provided Tweet ID
#
# GET /2/tweets/{id}/liking_users
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/likes/api-reference/get-tweets-id-liking_users
# Returns: record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>
# operationId: tweetsIdLikingUsers
export def "tweets-id-liking-users" [
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
  --max-results: int # The maximum number of results. (format: int32, default: 100)
  --pagination-token: string # This parameter is used to get the next 'page' of results.
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [pinned_tweet_id])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/tweets/{id}/liking_users"
    path_params: [{name: id, var: id}]
    query: [{name: max_results, var: max_results}, {name: pagination_token, var: pagination_token}, {name: "user.fields", var: user_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "tweet.fields", var: tweet_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, max_results: $max_results, pagination_token: $pagination_token, user_fields: $user_fields, expansions: $expansions, tweet_fields: $tweet_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve Tweets that quote a Tweet.
#
# GET /2/tweets/{id}/quote_tweets
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/quote-tweets/api-reference/get-tweets-id-quote_tweets
# Returns: record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, result_count: int>>
# operationId: findTweetsThatQuoteATweet
export def "find-tweets-that-quote-a-tweet" [
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
  --max-results: int # The maximum number of results to be returned. (format: int32, default: 10)
  --pagination-token: string # This parameter is used to get a specified 'page' of results.
  --exclude: list<string> # The set of entities to exclude (e.g. 'replies' or 'retweets'). (e.g. [replies, retweets])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, attachments.poll_ids, author_id, edit_history_tweet_ids, entities.mentions.username, geo.place_id, in_reply_to_user_id, referenced_tweets.id, referenced_tweets.id.author_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --poll-fields: list<string> # A comma separated list of Poll fields to display. (e.g. [duration_minutes, end_datetime, id, options, voting_status])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --place-fields: list<string> # A comma separated list of Place fields to display. (e.g. [contained_within, country, country_code, full_name, geo, id, name, place_type])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/tweets/{id}/quote_tweets"
    path_params: [{name: id, var: id}]
    query: [{name: max_results, var: max_results}, {name: pagination_token, var: pagination_token}, {name: exclude, var: exclude, style: csv}, {name: "tweet.fields", var: tweet_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "media.fields", var: media_fields, style: csv}, {name: "poll.fields", var: poll_fields, style: csv}, {name: "user.fields", var: user_fields, style: csv}, {name: "place.fields", var: place_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, max_results: $max_results, pagination_token: $pagination_token, exclude: $exclude, tweet_fields: $tweet_fields, expansions: $expansions, media_fields: $media_fields, poll_fields: $poll_fields, user_fields: $user_fields, place_fields: $place_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns User objects that have retweeted the provided Tweet ID
#
# GET /2/tweets/{id}/retweeted_by
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/retweets/api-reference/get-tweets-id-retweeted_by
# Returns: record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>
# operationId: tweetsIdRetweetingUsers
export def "tweets-id-retweeting-users" [
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
  --max-results: int # The maximum number of results. (format: int32, default: 100)
  --pagination-token: string # This parameter is used to get the next 'page' of results.
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [pinned_tweet_id])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/tweets/{id}/retweeted_by"
    path_params: [{name: id, var: id}]
    query: [{name: max_results, var: max_results}, {name: pagination_token, var: pagination_token}, {name: "user.fields", var: user_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "tweet.fields", var: tweet_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, max_results: $max_results, pagination_token: $pagination_token, user_fields: $user_fields, expansions: $expansions, tweet_fields: $tweet_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Hide replies
#
# PUT /2/tweets/{tweet_id}/hidden
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/hide-replies/api-reference/put-tweets-id-hidden
# Returns: record<data: record<hidden: bool>>
# operationId: hideReplyById
export def "hide-reply-by-id" [
  tweet_id: string
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
  --hidden: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/2/tweets/{tweet_id}/hidden"
    path_params: [{name: tweet_id, var: tweet_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: hidden, var: hidden, required: true}]}
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    tweet_id: $tweet_id, hidden: $hidden
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# User lookup by IDs
#
# GET /2/users
# Docs: https://developer.twitter.com/en/docs/twitter-api/users/lookup/api-reference/get-users
# Returns: record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>>
# operationId: findUsersById
export def "find-users-by-id" [
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
  --ids: list<string> # A list of User IDs, comma-separated. You can specify up to 100 IDs. (required, e.g. 2244994945,6253282,12)
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [pinned_tweet_id])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/users"
    query: [{name: ids, var: ids, style: csv, required: true}, {name: "user.fields", var: user_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "tweet.fields", var: tweet_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, user_fields: $user_fields, expansions: $expansions, tweet_fields: $tweet_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# User lookup by usernames
#
# GET /2/users/by
# Docs: https://developer.twitter.com/en/docs/twitter-api/users/lookup/api-reference/get-users-by
# Returns: record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>>
# operationId: findUsersByUsername
export def "find-users-by-username" [
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
  --usernames: list<string> # A list of usernames, comma-separated. (required, e.g. TwitterDev,TwitterAPI)
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [pinned_tweet_id])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/users/by"
    query: [{name: usernames, var: usernames, style: csv, required: true}, {name: "user.fields", var: user_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "tweet.fields", var: tweet_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    usernames: $usernames, user_fields: $user_fields, expansions: $expansions, tweet_fields: $tweet_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# User lookup by username
#
# GET /2/users/by/username/{username}
# Docs: https://developer.twitter.com/en/docs/twitter-api/users/lookup/api-reference/get-users-by-username-username
# Returns: record<data: record<created_at: string, description: string, entities: record<description: record, url: record>, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record<followers_count: int, following_count: int, listed_count: int, tweet_count: int>, url: string, username: string, verified: bool, verified_type: string, withheld: record<country_codes: list, scope: string>>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>>
# operationId: findUserByUsername
export def "find-user-by-username" [
  username: string
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
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [pinned_tweet_id])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/users/by/username/{username}"
    path_params: [{name: username, var: username}]
    query: [{name: "user.fields", var: user_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "tweet.fields", var: tweet_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, user_fields: $user_fields, expansions: $expansions, tweet_fields: $tweet_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Users Compliance stream
#
# GET /2/users/compliance/stream
# operationId: getUsersComplianceStream
export def "get-users-compliance-stream" [
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
  --backfill-minutes: int # The number of minutes of backfill requested. (format: int32)
  --partition: int # The partition number. (required, format: int32)
  --start-time: string # YYYY-MM-DDTHH:mm:ssZ. The earliest UTC timestamp from which the User Compliance events will be provided. (format: date-time, e.g. 2021-02-01T18:40:40.000Z)
  --end-time: string # YYYY-MM-DDTHH:mm:ssZ. The latest UTC timestamp from which the User Compliance events will be provided. (format: date-time, e.g. 2021-02-01T18:40:40.000Z)
]: nothing -> any {
  http-request {
    method: get
    path: "/2/users/compliance/stream"
    query: [{name: backfill_minutes, var: backfill_minutes}, {name: partition, var: partition, required: true}, {name: start_time, var: start_time}, {name: end_time, var: end_time}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    backfill_minutes: $backfill_minutes, partition: $partition, start_time: $start_time, end_time: $end_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# User lookup me
#
# GET /2/users/me
# Docs: https://developer.twitter.com/en/docs/twitter-api/users/lookup/api-reference/get-users-me
# Returns: record<data: record<created_at: string, description: string, entities: record<description: record, url: record>, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record<followers_count: int, following_count: int, listed_count: int, tweet_count: int>, url: string, username: string, verified: bool, verified_type: string, withheld: record<country_codes: list, scope: string>>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>>
# operationId: findMyUser
export def "find-my-user" [
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
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [pinned_tweet_id])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/users/me"
    query: [{name: "user.fields", var: user_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "tweet.fields", var: tweet_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    user_fields: $user_fields, expansions: $expansions, tweet_fields: $tweet_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# User lookup by ID
#
# GET /2/users/{id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/users/lookup/api-reference/get-users-id
# Returns: record<data: record<created_at: string, description: string, entities: record<description: record, url: record>, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record<followers_count: int, following_count: int, listed_count: int, tweet_count: int>, url: string, username: string, verified: bool, verified_type: string, withheld: record<country_codes: list, scope: string>>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>>
# operationId: findUserById
export def "find-user-by-id" [
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
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [pinned_tweet_id])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/users/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "user.fields", var: user_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "tweet.fields", var: tweet_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, user_fields: $user_fields, expansions: $expansions, tweet_fields: $tweet_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns User objects that are blocked by provided User ID
#
# GET /2/users/{id}/blocking
# Docs: https://developer.twitter.com/en/docs/twitter-api/users/blocks/api-reference/get-users-blocking
# Returns: record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>
# operationId: usersIdBlocking
export def "users-id-blocking" [
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
  --max-results: int # The maximum number of results. (format: int32)
  --pagination-token: string # This parameter is used to get a specified 'page' of results.
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [pinned_tweet_id])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/users/{id}/blocking"
    path_params: [{name: id, var: id}]
    query: [{name: max_results, var: max_results}, {name: pagination_token, var: pagination_token}, {name: "user.fields", var: user_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "tweet.fields", var: tweet_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, max_results: $max_results, pagination_token: $pagination_token, user_fields: $user_fields, expansions: $expansions, tweet_fields: $tweet_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Block User by User ID
#
# POST /2/users/{id}/blocking
# Docs: https://developer.twitter.com/en/docs/twitter-api/users/blocks/api-reference/post-users-user_id-blocking
# Returns: record<data: record<blocking: bool>, errors: table<detail: string, status: int, title: string, type: string>>
# operationId: usersIdBlock
export def "users-id-block" [
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
  target_user_id: string # Unique identifier of this User. This is returned as a string in order to avoid complications with languages and tools that cannot handle large integers. (e.g. 2244994945)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2/users/{id}/blocking"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: target_user_id, var: target_user_id}]}
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, target_user_id: $target_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Bookmarks by User
#
# GET /2/users/{id}/bookmarks
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/bookmarks/api-reference/get-users-id-bookmarks
# Returns: record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>
# operationId: getUsersIdBookmarks
export def "get-users-id-bookmarks" [
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
  --max-results: int # The maximum number of results. (format: int32)
  --pagination-token: string # This parameter is used to get the next 'page' of results.
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, attachments.poll_ids, author_id, edit_history_tweet_ids, entities.mentions.username, geo.place_id, in_reply_to_user_id, referenced_tweets.id, referenced_tweets.id.author_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --poll-fields: list<string> # A comma separated list of Poll fields to display. (e.g. [duration_minutes, end_datetime, id, options, voting_status])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --place-fields: list<string> # A comma separated list of Place fields to display. (e.g. [contained_within, country, country_code, full_name, geo, id, name, place_type])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/users/{id}/bookmarks"
    path_params: [{name: id, var: id}]
    query: [{name: max_results, var: max_results}, {name: pagination_token, var: pagination_token}, {name: "tweet.fields", var: tweet_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "media.fields", var: media_fields, style: csv}, {name: "poll.fields", var: poll_fields, style: csv}, {name: "user.fields", var: user_fields, style: csv}, {name: "place.fields", var: place_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, max_results: $max_results, pagination_token: $pagination_token, tweet_fields: $tweet_fields, expansions: $expansions, media_fields: $media_fields, poll_fields: $poll_fields, user_fields: $user_fields, place_fields: $place_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add Tweet to Bookmarks
#
# POST /2/users/{id}/bookmarks
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/bookmarks/api-reference/post-users-id-bookmarks
# Returns: record<data: record<bookmarked: bool>, errors: table<detail: string, status: int, title: string, type: string>>
# operationId: postUsersIdBookmarks
export def "post-users-id-bookmarks" [
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
  tweet_id: string # Unique identifier of this Tweet. This is returned as a string in order to avoid complications with languages and tools that cannot handle large integers. (e.g. 1346889436626259968)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2/users/{id}/bookmarks"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: tweet_id, var: tweet_id}]}
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, tweet_id: $tweet_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove a bookmarked Tweet
#
# DELETE /2/users/{id}/bookmarks/{tweet_id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/bookmarks/api-reference/delete-users-id-bookmarks-tweet_id
# Returns: record<data: record<bookmarked: bool>, errors: table<detail: string, status: int, title: string, type: string>>
# operationId: usersIdBookmarksDelete
export def "users-id-bookmarks-delete" [
  id: string
  tweet_id: string
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
    method: delete
    path: "/2/users/{id}/bookmarks/{tweet_id}"
    path_params: [{name: id, var: id}, {name: tweet_id, var: tweet_id}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, tweet_id: $tweet_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get User's Followed Lists
#
# GET /2/users/{id}/followed_lists
# Docs: https://developer.twitter.com/en/docs/twitter-api/lists/list-follows/api-reference/get-users-id-followed_lists
# Returns: record<data: table<created_at: string, description: string, follower_count: int, id: string, member_count: int, name: string, owner_id: string, private: bool>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>
# operationId: userFollowedLists
export def "user-followed-lists" [
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
  --max-results: int # The maximum number of results. (format: int32, default: 100)
  --pagination-token: string # This parameter is used to get a specified 'page' of results.
  --list-fields: list<string> # A comma separated list of List fields to display. (e.g. [created_at, description, follower_count, id, member_count, name, owner_id, private])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [owner_id])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/users/{id}/followed_lists"
    path_params: [{name: id, var: id}]
    query: [{name: max_results, var: max_results}, {name: pagination_token, var: pagination_token}, {name: "list.fields", var: list_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "user.fields", var: user_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, max_results: $max_results, pagination_token: $pagination_token, list_fields: $list_fields, expansions: $expansions, user_fields: $user_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Follow a List
#
# POST /2/users/{id}/followed_lists
# Docs: https://developer.twitter.com/en/docs/twitter-api/lists/list-follows/api-reference/post-users-id-followed-lists
# Returns: record<data: record<following: bool>, errors: table<detail: string, status: int, title: string, type: string>>
# operationId: listUserFollow
export def "list-user-follow" [
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
  list_id: string # The unique identifier of this List. (e.g. 1146654567674912769)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2/users/{id}/followed_lists"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: list_id, var: list_id}]}
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, list_id: $list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Unfollow a List
#
# DELETE /2/users/{id}/followed_lists/{list_id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/lists/list-follows/api-reference/delete-users-id-followed-lists-list_id
# Returns: record<data: record<following: bool>, errors: table<detail: string, status: int, title: string, type: string>>
# operationId: listUserUnfollow
export def "list-user-unfollow" [
  id: string
  list_id: string
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
    method: delete
    path: "/2/users/{id}/followed_lists/{list_id}"
    path_params: [{name: id, var: id}, {name: list_id, var: list_id}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, list_id: $list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Followers by User ID
#
# GET /2/users/{id}/followers
# Docs: https://developer.twitter.com/en/docs/twitter-api/users/follows/api-reference/get-users-id-followers
# Returns: record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>
# operationId: usersIdFollowers
export def "users-id-followers" [
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
  --max-results: int # The maximum number of results. (format: int32)
  --pagination-token: string # This parameter is used to get a specified 'page' of results.
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [pinned_tweet_id])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/users/{id}/followers"
    path_params: [{name: id, var: id}]
    query: [{name: max_results, var: max_results}, {name: pagination_token, var: pagination_token}, {name: "user.fields", var: user_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "tweet.fields", var: tweet_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, max_results: $max_results, pagination_token: $pagination_token, user_fields: $user_fields, expansions: $expansions, tweet_fields: $tweet_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Following by User ID
#
# GET /2/users/{id}/following
# Docs: https://developer.twitter.com/en/docs/twitter-api/users/follows/api-reference/get-users-id-following
# Returns: record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>
# operationId: usersIdFollowing
export def "users-id-following" [
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
  --max-results: int # The maximum number of results. (format: int32)
  --pagination-token: string # This parameter is used to get a specified 'page' of results.
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [pinned_tweet_id])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/users/{id}/following"
    path_params: [{name: id, var: id}]
    query: [{name: max_results, var: max_results}, {name: pagination_token, var: pagination_token}, {name: "user.fields", var: user_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "tweet.fields", var: tweet_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, max_results: $max_results, pagination_token: $pagination_token, user_fields: $user_fields, expansions: $expansions, tweet_fields: $tweet_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Follow User
#
# POST /2/users/{id}/following
# Docs: https://developer.twitter.com/en/docs/twitter-api/users/follows/api-reference/post-users-source_user_id-following
# Returns: record<data: record<following: bool, pending_follow: bool>, errors: table<detail: string, status: int, title: string, type: string>>
# operationId: usersIdFollow
export def "users-id-follow" [
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
  target_user_id: string # Unique identifier of this User. This is returned as a string in order to avoid complications with languages and tools that cannot handle large integers. (e.g. 2244994945)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2/users/{id}/following"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: target_user_id, var: target_user_id}]}
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, target_user_id: $target_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns Tweet objects liked by the provided User ID
#
# GET /2/users/{id}/liked_tweets
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/likes/api-reference/get-users-id-liked_tweets
# Returns: record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>
# operationId: usersIdLikedTweets
export def "users-id-liked-tweets" [
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
  --max-results: int # The maximum number of results. (format: int32)
  --pagination-token: string # This parameter is used to get the next 'page' of results.
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, attachments.poll_ids, author_id, edit_history_tweet_ids, entities.mentions.username, geo.place_id, in_reply_to_user_id, referenced_tweets.id, referenced_tweets.id.author_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --poll-fields: list<string> # A comma separated list of Poll fields to display. (e.g. [duration_minutes, end_datetime, id, options, voting_status])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --place-fields: list<string> # A comma separated list of Place fields to display. (e.g. [contained_within, country, country_code, full_name, geo, id, name, place_type])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/users/{id}/liked_tweets"
    path_params: [{name: id, var: id}]
    query: [{name: max_results, var: max_results}, {name: pagination_token, var: pagination_token}, {name: "tweet.fields", var: tweet_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "media.fields", var: media_fields, style: csv}, {name: "poll.fields", var: poll_fields, style: csv}, {name: "user.fields", var: user_fields, style: csv}, {name: "place.fields", var: place_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, max_results: $max_results, pagination_token: $pagination_token, tweet_fields: $tweet_fields, expansions: $expansions, media_fields: $media_fields, poll_fields: $poll_fields, user_fields: $user_fields, place_fields: $place_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Causes the User (in the path) to like the specified Tweet
#
# POST /2/users/{id}/likes
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/likes/api-reference/post-users-id-likes
# Returns: record<data: record<liked: bool>, errors: table<detail: string, status: int, title: string, type: string>>
# operationId: usersIdLike
export def "users-id-like" [
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
  tweet_id: string # Unique identifier of this Tweet. This is returned as a string in order to avoid complications with languages and tools that cannot handle large integers. (e.g. 1346889436626259968)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2/users/{id}/likes"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: tweet_id, var: tweet_id}]}
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, tweet_id: $tweet_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Causes the User (in the path) to unlike the specified Tweet
#
# DELETE /2/users/{id}/likes/{tweet_id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/likes/api-reference/delete-users-id-likes-tweet_id
# Returns: record<data: record<liked: bool>, errors: table<detail: string, status: int, title: string, type: string>>
# operationId: usersIdUnlike
export def "users-id-unlike" [
  id: string
  tweet_id: string
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
    method: delete
    path: "/2/users/{id}/likes/{tweet_id}"
    path_params: [{name: id, var: id}, {name: tweet_id, var: tweet_id}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, tweet_id: $tweet_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a User's List Memberships
#
# GET /2/users/{id}/list_memberships
# Docs: https://developer.twitter.com/en/docs/twitter-api/lists/list-members/api-reference/get-users-id-list_memberships
# Returns: record<data: table<created_at: string, description: string, follower_count: int, id: string, member_count: int, name: string, owner_id: string, private: bool>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>
# operationId: getUserListMemberships
export def "get-user-list-memberships" [
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
  --max-results: int # The maximum number of results. (format: int32, default: 100)
  --pagination-token: string # This parameter is used to get a specified 'page' of results.
  --list-fields: list<string> # A comma separated list of List fields to display. (e.g. [created_at, description, follower_count, id, member_count, name, owner_id, private])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [owner_id])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/users/{id}/list_memberships"
    path_params: [{name: id, var: id}]
    query: [{name: max_results, var: max_results}, {name: pagination_token, var: pagination_token}, {name: "list.fields", var: list_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "user.fields", var: user_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, max_results: $max_results, pagination_token: $pagination_token, list_fields: $list_fields, expansions: $expansions, user_fields: $user_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# User mention timeline by User ID
#
# GET /2/users/{id}/mentions
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/timelines/api-reference/get-users-id-mentions
# Returns: record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<newest_id: string, next_token: string, oldest_id: string, previous_token: string, result_count: int>>
# operationId: usersIdMentions
export def "users-id-mentions" [
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
  --since-id: string # The minimum Tweet ID to be included in the result set. This parameter takes precedence over start_time if both are specified. (e.g. 1346889436626259968)
  --until-id: string # The maximum Tweet ID to be included in the result set. This parameter takes precedence over end_time if both are specified. (e.g. 1346889436626259968)
  --max-results: int # The maximum number of results. (format: int32)
  --pagination-token: string # This parameter is used to get the next 'page' of results.
  --start-time: string # YYYY-MM-DDTHH:mm:ssZ. The earliest UTC timestamp from which the Tweets will be provided. The since_id parameter takes precedence if it is also specified. (format: date-time, e.g. 2021-02-01T18:40:40.000Z)
  --end-time: string # YYYY-MM-DDTHH:mm:ssZ. The latest UTC timestamp to which the Tweets will be provided. The until_id parameter takes precedence if it is also specified. (format: date-time, e.g. 2021-02-14T18:40:40.000Z)
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, attachments.poll_ids, author_id, edit_history_tweet_ids, entities.mentions.username, geo.place_id, in_reply_to_user_id, referenced_tweets.id, referenced_tweets.id.author_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --poll-fields: list<string> # A comma separated list of Poll fields to display. (e.g. [duration_minutes, end_datetime, id, options, voting_status])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --place-fields: list<string> # A comma separated list of Place fields to display. (e.g. [contained_within, country, country_code, full_name, geo, id, name, place_type])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/users/{id}/mentions"
    path_params: [{name: id, var: id}]
    query: [{name: since_id, var: since_id}, {name: until_id, var: until_id}, {name: max_results, var: max_results}, {name: pagination_token, var: pagination_token}, {name: start_time, var: start_time}, {name: end_time, var: end_time}, {name: "tweet.fields", var: tweet_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "media.fields", var: media_fields, style: csv}, {name: "poll.fields", var: poll_fields, style: csv}, {name: "user.fields", var: user_fields, style: csv}, {name: "place.fields", var: place_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, since_id: $since_id, until_id: $until_id, max_results: $max_results, pagination_token: $pagination_token, start_time: $start_time, end_time: $end_time, tweet_fields: $tweet_fields, expansions: $expansions, media_fields: $media_fields, poll_fields: $poll_fields, user_fields: $user_fields, place_fields: $place_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns User objects that are muted by the provided User ID
#
# GET /2/users/{id}/muting
# Docs: https://developer.twitter.com/en/docs/twitter-api/users/mutes/api-reference/get-users-muting
# Returns: record<data: table<created_at: string, description: string, entities: record, id: string, location: string, name: string, pinned_tweet_id: string, profile_image_url: string, protected: bool, public_metrics: record, url: string, username: string, verified: bool, verified_type: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>
# operationId: usersIdMuting
export def "users-id-muting" [
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
  --max-results: int # The maximum number of results. (format: int32, default: 100)
  --pagination-token: string # This parameter is used to get the next 'page' of results.
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [pinned_tweet_id])
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/users/{id}/muting"
    path_params: [{name: id, var: id}]
    query: [{name: max_results, var: max_results}, {name: pagination_token, var: pagination_token}, {name: "user.fields", var: user_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "tweet.fields", var: tweet_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, max_results: $max_results, pagination_token: $pagination_token, user_fields: $user_fields, expansions: $expansions, tweet_fields: $tweet_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Mute User by User ID.
#
# POST /2/users/{id}/muting
# Docs: https://developer.twitter.com/en/docs/twitter-api/users/mutes/api-reference/post-users-user_id-muting
# Returns: record<data: record<muting: bool>, errors: table<detail: string, status: int, title: string, type: string>>
# operationId: usersIdMute
export def "users-id-mute" [
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
  target_user_id: string # Unique identifier of this User. This is returned as a string in order to avoid complications with languages and tools that cannot handle large integers. (e.g. 2244994945)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2/users/{id}/muting"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: target_user_id, var: target_user_id}]}
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, target_user_id: $target_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a User's Owned Lists.
#
# GET /2/users/{id}/owned_lists
# Docs: https://developer.twitter.com/en/docs/twitter-api/lists/list-lookup/api-reference/get-users-id-owned_lists
# Returns: record<data: table<created_at: string, description: string, follower_count: int, id: string, member_count: int, name: string, owner_id: string, private: bool>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<next_token: string, previous_token: string, result_count: int>>
# operationId: listUserOwnedLists
export def "list-user-owned-lists" [
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
  --max-results: int # The maximum number of results. (format: int32, default: 100)
  --pagination-token: string # This parameter is used to get a specified 'page' of results.
  --list-fields: list<string> # A comma separated list of List fields to display. (e.g. [created_at, description, follower_count, id, member_count, name, owner_id, private])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [owner_id])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/users/{id}/owned_lists"
    path_params: [{name: id, var: id}]
    query: [{name: max_results, var: max_results}, {name: pagination_token, var: pagination_token}, {name: "list.fields", var: list_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "user.fields", var: user_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, max_results: $max_results, pagination_token: $pagination_token, list_fields: $list_fields, expansions: $expansions, user_fields: $user_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a User's Pinned Lists
#
# GET /2/users/{id}/pinned_lists
# Docs: https://developer.twitter.com/en/docs/twitter-api/lists/pinned-lists/api-reference/get-users-id-pinned_lists
# Returns: record<data: table<created_at: string, description: string, follower_count: int, id: string, member_count: int, name: string, owner_id: string, private: bool>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<result_count: int>>
# operationId: listUserPinnedLists
export def "list-user-pinned-lists" [
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
  --list-fields: list<string> # A comma separated list of List fields to display. (e.g. [created_at, description, follower_count, id, member_count, name, owner_id, private])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [owner_id])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/users/{id}/pinned_lists"
    path_params: [{name: id, var: id}]
    query: [{name: "list.fields", var: list_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "user.fields", var: user_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, list_fields: $list_fields, expansions: $expansions, user_fields: $user_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Pin a List
#
# POST /2/users/{id}/pinned_lists
# Docs: https://developer.twitter.com/en/docs/twitter-api/lists/pinned-lists/api-reference/post-users-id-pinned-lists
# Returns: record<data: record<pinned: bool>, errors: table<detail: string, status: int, title: string, type: string>>
# operationId: listUserPin
export def "list-user-pin" [
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
  list_id: string # The unique identifier of this List. (e.g. 1146654567674912769)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2/users/{id}/pinned_lists"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: list_id, var: list_id}]}
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, list_id: $list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Unpin a List
#
# DELETE /2/users/{id}/pinned_lists/{list_id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/lists/pinned-lists/api-reference/delete-users-id-pinned-lists-list_id
# Returns: record<data: record<pinned: bool>, errors: table<detail: string, status: int, title: string, type: string>>
# operationId: listUserUnpin
export def "list-user-unpin" [
  id: string
  list_id: string
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
    method: delete
    path: "/2/users/{id}/pinned_lists/{list_id}"
    path_params: [{name: id, var: id}, {name: list_id, var: list_id}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, list_id: $list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Causes the User (in the path) to retweet the specified Tweet.
#
# POST /2/users/{id}/retweets
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/retweets/api-reference/post-users-id-retweets
# Returns: record<data: record<retweeted: bool>, errors: table<detail: string, status: int, title: string, type: string>>
# operationId: usersIdRetweets
export def "users-id-retweets" [
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
  tweet_id: string # Unique identifier of this Tweet. This is returned as a string in order to avoid complications with languages and tools that cannot handle large integers. (e.g. 1346889436626259968)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2/users/{id}/retweets"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: tweet_id, var: tweet_id}]}
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, tweet_id: $tweet_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Causes the User (in the path) to unretweet the specified Tweet
#
# DELETE /2/users/{id}/retweets/{source_tweet_id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/retweets/api-reference/delete-users-id-retweets-tweet_id
# Returns: record<data: record<retweeted: bool>, errors: table<detail: string, status: int, title: string, type: string>>
# operationId: usersIdUnretweets
export def "users-id-unretweets" [
  id: string
  source_tweet_id: string
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
    method: delete
    path: "/2/users/{id}/retweets/{source_tweet_id}"
    path_params: [{name: id, var: id}, {name: source_tweet_id, var: source_tweet_id}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, source_tweet_id: $source_tweet_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# User home timeline by User ID
#
# GET /2/users/{id}/timelines/reverse_chronological
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/timelines/api-reference/get-users-id-reverse-chronological
# Returns: record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<newest_id: string, next_token: string, oldest_id: string, previous_token: string, result_count: int>>
# operationId: usersIdTimeline
export def "users-id-timeline" [
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
  --since-id: string # The minimum Tweet ID to be included in the result set. This parameter takes precedence over start_time if both are specified. (e.g. 1346889436626259968)
  --until-id: string # The maximum Tweet ID to be included in the result set. This parameter takes precedence over end_time if both are specified. (e.g. 1346889436626259968)
  --max-results: int # The maximum number of results. (format: int32)
  --pagination-token: string # This parameter is used to get the next 'page' of results.
  --exclude: list<string> # The set of entities to exclude (e.g. 'replies' or 'retweets'). (e.g. [replies, retweets])
  --start-time: string # YYYY-MM-DDTHH:mm:ssZ. The earliest UTC timestamp from which the Tweets will be provided. The since_id parameter takes precedence if it is also specified. (format: date-time, e.g. 2021-02-01T18:40:40.000Z)
  --end-time: string # YYYY-MM-DDTHH:mm:ssZ. The latest UTC timestamp to which the Tweets will be provided. The until_id parameter takes precedence if it is also specified. (format: date-time, e.g. 2021-02-14T18:40:40.000Z)
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, attachments.poll_ids, author_id, edit_history_tweet_ids, entities.mentions.username, geo.place_id, in_reply_to_user_id, referenced_tweets.id, referenced_tweets.id.author_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --poll-fields: list<string> # A comma separated list of Poll fields to display. (e.g. [duration_minutes, end_datetime, id, options, voting_status])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --place-fields: list<string> # A comma separated list of Place fields to display. (e.g. [contained_within, country, country_code, full_name, geo, id, name, place_type])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/users/{id}/timelines/reverse_chronological"
    path_params: [{name: id, var: id}]
    query: [{name: since_id, var: since_id}, {name: until_id, var: until_id}, {name: max_results, var: max_results}, {name: pagination_token, var: pagination_token}, {name: exclude, var: exclude, style: csv}, {name: start_time, var: start_time}, {name: end_time, var: end_time}, {name: "tweet.fields", var: tweet_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "media.fields", var: media_fields, style: csv}, {name: "poll.fields", var: poll_fields, style: csv}, {name: "user.fields", var: user_fields, style: csv}, {name: "place.fields", var: place_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, since_id: $since_id, until_id: $until_id, max_results: $max_results, pagination_token: $pagination_token, exclude: $exclude, start_time: $start_time, end_time: $end_time, tweet_fields: $tweet_fields, expansions: $expansions, media_fields: $media_fields, poll_fields: $poll_fields, user_fields: $user_fields, place_fields: $place_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# User Tweets timeline by User ID
#
# GET /2/users/{id}/tweets
# Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/timelines/api-reference/get-users-id-tweets
# Returns: record<data: table<attachments: record, author_id: string, context_annotations: list, conversation_id: string, created_at: string, edit_controls: record, edit_history_tweet_ids: list, entities: record, geo: record, id: string, in_reply_to_user_id: string, lang: string, non_public_metrics: record, organic_metrics: record, possibly_sensitive: bool, promoted_metrics: record, public_metrics: record, referenced_tweets: list, reply_settings: string, source: string, text: string, withheld: record>, errors: table<detail: string, status: int, title: string, type: string>, includes: record<media: list<record>, places: list<record>, polls: list<record>, topics: list<record>, tweets: list<record>, users: list<record>>, meta: record<newest_id: string, next_token: string, oldest_id: string, previous_token: string, result_count: int>>
# operationId: usersIdTweets
export def "users-id-tweets" [
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
  --since-id: string # The minimum Tweet ID to be included in the result set. This parameter takes precedence over start_time if both are specified. (e.g. 1346889436626259968)
  --until-id: string # The maximum Tweet ID to be included in the result set. This parameter takes precedence over end_time if both are specified. (e.g. 1346889436626259968)
  --max-results: int # The maximum number of results. (format: int32)
  --pagination-token: string # This parameter is used to get the next 'page' of results.
  --exclude: list<string> # The set of entities to exclude (e.g. 'replies' or 'retweets'). (e.g. [replies, retweets])
  --start-time: string # YYYY-MM-DDTHH:mm:ssZ. The earliest UTC timestamp from which the Tweets will be provided. The since_id parameter takes precedence if it is also specified. (format: date-time, e.g. 2021-02-01T18:40:40.000Z)
  --end-time: string # YYYY-MM-DDTHH:mm:ssZ. The latest UTC timestamp to which the Tweets will be provided. The until_id parameter takes precedence if it is also specified. (format: date-time, e.g. 2021-02-14T18:40:40.000Z)
  --tweet-fields: list<string> # A comma separated list of Tweet fields to display. (e.g. [attachments, author_id, context_annotations, conversation_id, created_at, edit_controls, edit_history_tweet_ids, entities, geo, id, in_reply_to_user_id, lang, non_public_metrics, organic_metrics, possibly_sensitive, promoted_metrics, public_metrics, referenced_tweets, reply_settings, source, text, withheld])
  --expansions: list<string> # A comma separated list of fields to expand. (e.g. [attachments.media_keys, attachments.poll_ids, author_id, edit_history_tweet_ids, entities.mentions.username, geo.place_id, in_reply_to_user_id, referenced_tweets.id, referenced_tweets.id.author_id])
  --media-fields: list<string> # A comma separated list of Media fields to display. (e.g. [alt_text, duration_ms, height, media_key, non_public_metrics, organic_metrics, preview_image_url, promoted_metrics, public_metrics, type, url, variants, width])
  --poll-fields: list<string> # A comma separated list of Poll fields to display. (e.g. [duration_minutes, end_datetime, id, options, voting_status])
  --user-fields: list<string> # A comma separated list of User fields to display. (e.g. [created_at, description, entities, id, location, name, pinned_tweet_id, profile_image_url, protected, public_metrics, url, username, verified, verified_type, withheld])
  --place-fields: list<string> # A comma separated list of Place fields to display. (e.g. [contained_within, country, country_code, full_name, geo, id, name, place_type])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2/users/{id}/tweets"
    path_params: [{name: id, var: id}]
    query: [{name: since_id, var: since_id}, {name: until_id, var: until_id}, {name: max_results, var: max_results}, {name: pagination_token, var: pagination_token}, {name: exclude, var: exclude, style: csv}, {name: start_time, var: start_time}, {name: end_time, var: end_time}, {name: "tweet.fields", var: tweet_fields, style: csv}, {name: expansions, var: expansions, style: csv}, {name: "media.fields", var: media_fields, style: csv}, {name: "poll.fields", var: poll_fields, style: csv}, {name: "user.fields", var: user_fields, style: csv}, {name: "place.fields", var: place_fields, style: csv}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, since_id: $since_id, until_id: $until_id, max_results: $max_results, pagination_token: $pagination_token, exclude: $exclude, start_time: $start_time, end_time: $end_time, tweet_fields: $tweet_fields, expansions: $expansions, media_fields: $media_fields, poll_fields: $poll_fields, user_fields: $user_fields, place_fields: $place_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Unblock User by User ID
#
# DELETE /2/users/{source_user_id}/blocking/{target_user_id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/users/blocks/api-reference/delete-users-user_id-blocking
# Returns: record<data: record<blocking: bool>, errors: table<detail: string, status: int, title: string, type: string>>
# operationId: usersIdUnblock
export def "users-id-unblock" [
  source_user_id: string
  target_user_id: string
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
    method: delete
    path: "/2/users/{source_user_id}/blocking/{target_user_id}"
    path_params: [{name: source_user_id, var: source_user_id}, {name: target_user_id, var: target_user_id}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    source_user_id: $source_user_id, target_user_id: $target_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Unfollow User
#
# DELETE /2/users/{source_user_id}/following/{target_user_id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/users/follows/api-reference/delete-users-source_id-following
# Returns: record<data: record<following: bool>, errors: table<detail: string, status: int, title: string, type: string>>
# operationId: usersIdUnfollow
export def "users-id-unfollow" [
  source_user_id: string
  target_user_id: string
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
    method: delete
    path: "/2/users/{source_user_id}/following/{target_user_id}"
    path_params: [{name: source_user_id, var: source_user_id}, {name: target_user_id, var: target_user_id}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    source_user_id: $source_user_id, target_user_id: $target_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Unmute User by User ID
#
# DELETE /2/users/{source_user_id}/muting/{target_user_id}
# Docs: https://developer.twitter.com/en/docs/twitter-api/users/mutes/api-reference/delete-users-user_id-muting
# Returns: record<data: record<muting: bool>, errors: table<detail: string, status: int, title: string, type: string>>
# operationId: usersIdUnmute
export def "users-id-unmute" [
  source_user_id: string
  target_user_id: string
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
    method: delete
    path: "/2/users/{source_user_id}/muting/{target_user_id}"
    path_params: [{name: source_user_id, var: source_user_id}, {name: target_user_id, var: target_user_id}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: bearer
  } {
    source_user_id: $source_user_id, target_user_id: $target_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
