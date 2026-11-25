# Auto-generated client for Mastodon API Specification (https://github.com/mastodon/mastodon) v1.0
# Source: https://api.apis.guru/v2/specs/mastodon.local/1.0/openapi.json
# Auth: --token flag or $env.MASTODON_API_SPECIFICATION_HTTPS_GITHUB_COM_MASTODON_MASTODON_TOKEN

const CLIENT = {
  base_url: "http://mastodon.local"
  token_env_var: "MASTODON_API_SPECIFICATION_HTTPS_GITHUB_COM_MASTODON_MASTODON_TOKEN"
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

def base-url-completer [] { ["http://mastodon.local" "https://mastodon.social"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["disable" "none" "silence" "suspend"] }
def order-completer [] { ["active" "new"] }
def replies-policy-completer [] { ["followed" "list" "none"] }
def type-completer-1 [] { ["accounts" "hashtags" "statuses"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-api-oembed: "record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>"
    get-api-proofs: "record<profile_url: string, proof_url: string, provider: string, provider_username: string, updated_at: string>"
    get-api-v1-accounts-relationships: "table<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool>"
    get-api-v1-accounts-search: "table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>"
    patch-api-v1-accounts-update-credentials: "record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, fields: table<name: string, value: string, verified_at: string>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list<record>, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>"
    get-api-v1-accounts-verify-credentials: "record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, fields: table<name: string, value: string, verified_at: string>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list<record>, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>"
    get-api-v1-accounts-id: "record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, fields: table<name: string, value: string, verified_at: string>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list<record>, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>"
    post-api-v1-accounts-id-block: "record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool>"
    get-api-v1-accounts-id-featured-tags: "table<id: string, last_status_at: string, name: string, statuses_count: int, url: string>"
    post-api-v1-accounts-id-follow: "record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool>"
    get-api-v1-accounts-id-followers: "table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>"
    get-api-v1-accounts-id-following: "table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>"
    get-api-v1-accounts-id-identity-proofs: "table<profile_url: string, proof_url: string, provider: string, provider_username: string, updated_at: string>"
    get-api-v1-accounts-id-lists: "table<id: string, replies_policy: string, title: string>"
    post-api-v1-accounts-id-mute: "record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool>"
    post-api-v1-accounts-id-note: "record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool>"
    post-api-v1-accounts-id-pin: "record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool>"
    get-api-v1-accounts-id-statuses: "table<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: list<record>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>"
    post-api-v1-accounts-id-unblock: "record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool>"
    post-api-v1-accounts-id-unfollow: "record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool>"
    post-api-v1-accounts-id-unmute: "record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool>"
    post-api-v1-accounts-id-unpin: "record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool>"
    get-api-v1-admin-accounts: "table<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, approved: bool, confirmed: bool, created_at: string, created_by_application_id: string, disabled: bool, email: string, id: string, invite_request: string, invited_by_account_id: string, ip: string, locale: string, role: string, silenced: bool, suspended: bool, username: string>"
    get-api-v1-admin-accounts-id: "record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, approved: bool, confirmed: bool, created_at: string, created_by_application_id: string, disabled: bool, email: string, id: string, invite_request: string, invited_by_account_id: string, ip: string, locale: string, role: string, silenced: bool, suspended: bool, username: string>"
    get-api-v1-admin-reports: "table<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, action_taken: string, assigned_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, comment: string, created_at: string, id: string, statuses: list<record>, target_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, updated_at: string>"
    get-api-v1-admin-reports-id: "record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, action_taken: string, assigned_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, comment: string, created_at: string, id: string, statuses: table<account: record, application: record, bookmarked: bool, card: record, content: string, created_at: string, emojis: list, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, target_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, updated_at: string>"
    post-api-v1-admin-reports-id-assign-to-self: "record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, action_taken: string, assigned_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, comment: string, created_at: string, id: string, statuses: table<account: record, application: record, bookmarked: bool, card: record, content: string, created_at: string, emojis: list, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, target_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, updated_at: string>"
    post-api-v1-admin-reports-id-reopen: "record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, action_taken: string, assigned_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, comment: string, created_at: string, id: string, statuses: table<account: record, application: record, bookmarked: bool, card: record, content: string, created_at: string, emojis: list, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, target_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, updated_at: string>"
    post-api-v1-admin-reports-id-resolve: "record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, action_taken: string, assigned_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, comment: string, created_at: string, id: string, statuses: table<account: record, application: record, bookmarked: bool, card: record, content: string, created_at: string, emojis: list, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, target_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, updated_at: string>"
    post-api-v1-admin-reports-id-unassign: "record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, action_taken: string, assigned_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, comment: string, created_at: string, id: string, statuses: table<account: record, application: record, bookmarked: bool, card: record, content: string, created_at: string, emojis: list, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, target_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, updated_at: string>"
    get-api-v1-announcements: "table<all_day: bool, created_at: string, ends_at: string, id: string, published: bool, read: bool, scheduled_at: string, starts_at: string, text: string, updated_at: string>"
    post-api-v1-announcements-id-dismiss: "record"
    delete-api-v1-announcements-id-reactions-name: "record"
    put-api-v1-announcements-id-reactions-name: "record"
    post-api-v1-apps: "record<client_id: string, client_secret: string, id: string, name: string, redirect_uri: string, vapid_key: string, website: string>"
    get-api-v1-apps-verify-credentials: "record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>"
    get-api-v1-blocks: "table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>"
    get-api-v1-bookmarks: "table<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: list<record>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>"
    get-api-v1-conversations: "table<accounts: list<record>, id: string, last_status: record<account: record, application: record, bookmarked: bool, card: record, content: string, created_at: string, emojis: list, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, unread: bool>"
    delete-api-v1-conversations-id: "record"
    post-api-v1-conversations-id-read: "record<accounts: table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, id: string, last_status: record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: list<record>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>, unread: bool>"
    get-api-v1-custom-emojis: "table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>"
    get-api-v1-directory: "table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>"
    delete-api-v1-domain-blocks: "record"
    get-api-v1-domain-blocks: "list<string>"
    post-api-v1-domain-blocks: "record"
    get-api-v1-endorsements: "table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>"
    get-api-v1-favourites: "table<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: list<record>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>"
    get-api-v1-featured-tags: "table<id: string, last_status_at: string, name: string, statuses_count: int, url: string>"
    post-api-v1-featured-tags: "record<id: string, last_status_at: string, name: string, statuses_count: int, url: string>"
    get-api-v1-featured-tags-suggestions: "table<id: string, last_status_at: string, name: string, statuses_count: int, url: string>"
    delete-api-v1-featured-tags-id: "record"
    get-api-v1-filters: "table<context: list<string>, expires_at: string, id: string, irreversible: bool, phrase: string, whole_word: bool>"
    post-api-v1-filters: "record<context: list<string>, expires_at: string, id: string, irreversible: bool, phrase: string, whole_word: bool>"
    get-api-v1-filters-id: "record<context: list<string>, expires_at: string, id: string, irreversible: bool, phrase: string, whole_word: bool>"
    put-api-v1-filters-id: "record<context: list<string>, expires_at: string, id: string, irreversible: bool, phrase: string, whole_word: bool>"
    get-api-v1-follow-requests: "table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>"
    post-api-v1-follow-requests-id-authorize: "record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool>"
    post-api-v1-follow-requests-id-reject: "record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool>"
    get-api-v1-instance: "record<approval_required: bool, contact_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, description: string, email: string, invites_enabled: bool, languages: list<string>, registrations: bool, short_description: string, stats: record, thumbnail: string, title: string, uri: string, urls: record, version: string>"
    get-api-v1-instance-activity: "table<logins: string, registrations: string, statuses: string, week: string>"
    get-api-v1-instance-peers: "list<string>"
    delete-api-v1-lists: "record"
    get-api-v1-lists: "table<id: string, replies_policy: string, title: string>"
    post-api-v1-lists: "record<id: string, replies_policy: string, title: string>"
    put-api-v1-lists: "record<id: string, replies_policy: string, title: string>"
    get-api-v1-lists-id: "record<id: string, replies_policy: string, title: string>"
    delete-api-v1-lists-id-accounts: "record"
    get-api-v1-lists-id-accounts: "table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>"
    post-api-v1-lists-id-accounts: "record"
    get-api-v1-markers: "record"
    post-api-v1-markers: "record"
    post-api-v1-media: "record<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>"
    get-api-v1-media-id: "record<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>"
    post-api-v1-media-id: "record<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>"
    get-api-v1-mutes: "table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>"
    get-api-v1-notifications: "table<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, created_at: string, id: string, status: record<account: record, application: record, bookmarked: bool, card: record, content: string, created_at: string, emojis: list, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, type: string>"
    post-api-v1-notifications-clear: "record"
    get-api-v1-notifications-id: "record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, created_at: string, id: string, status: record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: list<record>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>, type: string>"
    post-api-v1-notifications-id-dismiss: "record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, created_at: string, id: string, status: record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: list<record>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>, type: string>"
    get-api-v1-polls-id: "record<emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>"
    post-api-v1-polls-id: "record<emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>"
    get-api-v1-preferences: "record<\"posting:default:language\": string, \"posting:default:sensitive\": bool, \"posting:default:visibility\": string, \"reading:expand:media\": string, \"reading:expand:spoilers\": bool>"
    delete-api-v1-push-subscription: "record"
    get-api-v1-push-subscription: "record<alerts: record, endpoint: string, id: string, server_key: string>"
    post-api-v1-push-subscription: "record<alerts: record, endpoint: string, id: string, server_key: string>"
    put-api-v1-push-subscription: "record<alerts: record, endpoint: string, id: string, server_key: string>"
    post-api-v1-reports: "record<action_taken: bool, action_taken_at: string, category: string, comment: string, created_at: string, forwarded: bool, id: string, rule_ids: list<int>, status_ids: list<int>, target_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>>"
    get-api-v1-scheduled-statuses: "table<id: string, media_attachments: list<record>, params: record<application_id: string, in_reply_to_id: string, media_ids: list, scheduled_at: string, sensitive: bool, spoiler_text: string, text: string, visibility: string>, scheduled_at: string>"
    delete-api-v1-scheduled-statuses-id: "record"
    get-api-v1-scheduled-statuses-id: "record<id: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, params: record<application_id: string, in_reply_to_id: string, media_ids: list<string>, scheduled_at: string, sensitive: bool, spoiler_text: string, text: string, visibility: string>, scheduled_at: string>"
    put-api-v1-scheduled-statuses-id: "record<id: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, params: record<application_id: string, in_reply_to_id: string, media_ids: list<string>, scheduled_at: string, sensitive: bool, spoiler_text: string, text: string, visibility: string>, scheduled_at: string>"
    delete-api-v1-statuses-id: "record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string>"
    get-api-v1-statuses-id: "record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string>"
    post-api-v1-statuses-id-bookmark: "record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string>"
    get-api-v1-statuses-id-context: "record<ancestors: table<account: record, application: record, bookmarked: bool, card: record, content: string, created_at: string, emojis: list, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, descendants: table<account: record, application: record, bookmarked: bool, card: record, content: string, created_at: string, emojis: list, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>>"
    post-api-v1-statuses-id-favourite: "record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string>"
    get-api-v1-statuses-id-favourited-by: "record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, fields: table<name: string, value: string, verified_at: string>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list<record>, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>"
    post-api-v1-statuses-id-mute: "record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string>"
    post-api-v1-statuses-id-pin: "record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string>"
    post-api-v1-statuses-id-reblog: "record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string>"
    get-api-v1-statuses-id-reblogged-by: "record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, fields: table<name: string, value: string, verified_at: string>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list<record>, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>"
    post-api-v1-statuses-id-unbookmark: "record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string>"
    post-api-v1-statuses-id-unfavourite: "record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string>"
    post-api-v1-statuses-id-unmute: "record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string>"
    post-api-v1-statuses-id-unpin: "record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string>"
    post-api-v1-statuses-id-unreblog: "record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string>"
    get-api-v1-suggestions: "record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, fields: table<name: string, value: string, verified_at: string>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list<record>, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>"
    delete-api-v1-suggestions-id: "record"
    get-api-v1-timelines-home: "table<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: list<record>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>"
    get-api-v1-timelines-list-list-id: "table<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: list<record>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>"
    get-api-v1-timelines-public: "table<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: list<record>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>"
    get-api-v1-timelines-tag-hashtag: "table<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: list<record>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>"
    get-api-v1-trends: "table<history: list<record>, name: string, url: string>"
    get-api-v2-search: "record<accounts: table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, hashtags: table<account: record, application: record, bookmarked: bool, card: record, content: string, created_at: string, emojis: list, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, statuses: table<history: list, name: string, url: string>>"
    post-oauth-token: "record<access_token: string, created_at: int, scope: string, token_type: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-api-oembed" "get-api-proofs" "post-api-v1-accounts" "get-api-v1-accounts-relationships" "get-api-v1-accounts-search" "patch-api-v1-accounts-update-credentials" "get-api-v1-accounts-verify-credentials" "get-api-v1-accounts-id" "post-api-v1-accounts-id-block" "get-api-v1-accounts-id-featured-tags" "post-api-v1-accounts-id-follow" "get-api-v1-accounts-id-followers" "get-api-v1-accounts-id-following" "get-api-v1-accounts-id-identity-proofs" "get-api-v1-accounts-id-lists" "post-api-v1-accounts-id-mute" "post-api-v1-accounts-id-note" "post-api-v1-accounts-id-pin" "get-api-v1-accounts-id-statuses" "post-api-v1-accounts-id-unblock" "post-api-v1-accounts-id-unfollow" "post-api-v1-accounts-id-unmute" "post-api-v1-accounts-id-unpin" "get-api-v1-admin-accounts" "get-api-v1-admin-accounts-id" "post-api-v1-admin-accounts-id-action" "post-api-v1-admin-accounts-id-approve" "post-api-v1-admin-accounts-id-enable" "post-api-v1-admin-accounts-id-reject" "post-api-v1-admin-accounts-id-unsilence" "post-api-v1-admin-accounts-id-unsuspend" "get-api-v1-admin-reports" "get-api-v1-admin-reports-id" "post-api-v1-admin-reports-id-assign-to-self" "post-api-v1-admin-reports-id-reopen" "post-api-v1-admin-reports-id-resolve" "post-api-v1-admin-reports-id-unassign" "get-api-v1-announcements" "post-api-v1-announcements-id-dismiss" "delete-api-v1-announcements-id-reactions-name" "put-api-v1-announcements-id-reactions-name" "post-api-v1-apps" "get-api-v1-apps-verify-credentials" "get-api-v1-blocks" "get-api-v1-bookmarks" "get-api-v1-conversations" "delete-api-v1-conversations-id" "post-api-v1-conversations-id-read" "get-api-v1-custom-emojis" "get-api-v1-directory" "delete-api-v1-domain-blocks" "get-api-v1-domain-blocks" "post-api-v1-domain-blocks" "get-api-v1-endorsements" "get-api-v1-favourites" "get-api-v1-featured-tags" "post-api-v1-featured-tags" "get-api-v1-featured-tags-suggestions" "delete-api-v1-featured-tags-id" "get-api-v1-filters" "post-api-v1-filters" "delete-api-v1-filters-id" "get-api-v1-filters-id" "put-api-v1-filters-id" "get-api-v1-follow-requests" "post-api-v1-follow-requests-id-authorize" "post-api-v1-follow-requests-id-reject" "get-api-v1-instance" "get-api-v1-instance-activity" "get-api-v1-instance-peers" "delete-api-v1-lists" "get-api-v1-lists" "post-api-v1-lists" "put-api-v1-lists" "get-api-v1-lists-id" "delete-api-v1-lists-id-accounts" "get-api-v1-lists-id-accounts" "post-api-v1-lists-id-accounts" "get-api-v1-markers" "post-api-v1-markers" "post-api-v1-media" "get-api-v1-media-id" "post-api-v1-media-id" "get-api-v1-mutes" "get-api-v1-notifications" "post-api-v1-notifications-clear" "get-api-v1-notifications-id" "post-api-v1-notifications-id-dismiss" "get-api-v1-polls-id" "post-api-v1-polls-id" "get-api-v1-preferences" "delete-api-v1-push-subscription" "get-api-v1-push-subscription" "post-api-v1-push-subscription" "put-api-v1-push-subscription" "post-api-v1-reports" "get-api-v1-scheduled-statuses" "delete-api-v1-scheduled-statuses-id" "get-api-v1-scheduled-statuses-id" "put-api-v1-scheduled-statuses-id" "post-api-v1-statuses" "delete-api-v1-statuses-id" "get-api-v1-statuses-id" "post-api-v1-statuses-id-bookmark" "get-api-v1-statuses-id-context" "post-api-v1-statuses-id-favourite" "get-api-v1-statuses-id-favourited-by" "post-api-v1-statuses-id-mute" "post-api-v1-statuses-id-pin" "post-api-v1-statuses-id-reblog" "get-api-v1-statuses-id-reblogged-by" "post-api-v1-statuses-id-unbookmark" "post-api-v1-statuses-id-unfavourite" "post-api-v1-statuses-id-unmute" "post-api-v1-statuses-id-unpin" "post-api-v1-statuses-id-unreblog" "get-api-v1-suggestions" "delete-api-v1-suggestions-id" "get-api-v1-timelines-home" "get-api-v1-timelines-list-list-id" "get-api-v1-timelines-public" "get-api-v1-timelines-tag-hashtag" "get-api-v1-trends" "get-api-v2-search" "get-oauth-authorize" "post-oauth-revoke" "post-oauth-token" "commands"] | sort) } | get name | first)
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

# OEmbed as JSON
#
# GET /api/oembed
# Returns: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>
export def "get-api-oembed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --url: string # URL of a status
  --maxwidth: int # width of the iframe. Defaults to 400 (default: 400)
  --maxheight: int # height of the iframe. Defaults to null
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/oembed"
    query: [{name: url, var: url}, {name: maxwidth, var: maxwidth}, {name: maxheight, var: maxheight}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    url: $url, maxwidth: $maxwidth, maxheight: $maxheight
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View identity proof
#
# GET /api/proofs
# Returns: record<profile_url: string, proof_url: string, provider: string, provider_username: string, updated_at: string>
export def "get-api-proofs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --provider: string # The identity provider to be looked up. Currently only supports keybase (case-sensitive)
  --username: string # The username on the selected identity provider
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/proofs"
    query: [{name: provider, var: provider}, {name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    provider: $provider, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a user and account records. Returns an account access token for the app that initiated the request. The app should save this token for later, and should wait for the user to confirm their account by clicking a link in their email inbox.
#
# POST /api/v1/accounts
export def "post-api-v1-accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/accounts"
    body: {content_type: "application/form-data", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets a private note on a user.
#
# GET /api/v1/accounts/relationships
# Returns: table<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool>
export def "get-api-v1-accounts-relationships" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Array of account IDs to check (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/accounts/relationships"
    query: [{name: id, var: id, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for matching accounts by username or display name.
#
# GET /api/v1/accounts/search
# Returns: table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>
export def "get-api-v1-accounts-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # What to search for (required)
  --limit: int # Maximum number of results. Defaults to 40. (default: 40)
  --resolve: string # Attempt WebFinger lookup. Defaults to false. Use this when `q` is an exact address.
  --following: oneof<nothing, bool> # Only who the user is following. Defaults to false.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/accounts/search"
    query: [{name: q, var: q, required: true}, {name: limit, var: limit}, {name: resolve, var: resolve}, {name: following, var: following}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, limit: $limit, resolve: $resolve, following: $following
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the user's display and preferences.
#
# PATCH /api/v1/accounts/update_credentials
# Returns: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, fields: table<name: string, value: string, verified_at: string>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list<record>, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>
export def "patch-api-v1-accounts-update-credentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/v1/accounts/update_credentials"
    body: {content_type: "application/form-data", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test to make sure that the user token works.
#
# GET /api/v1/accounts/verify_credentials
# Returns: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, fields: table<name: string, value: string, verified_at: string>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list<record>, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>
export def "get-api-v1-accounts-verify-credentials" [
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
    path: "/api/v1/accounts/verify_credentials"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/v1/accounts/{id}
#
# Returns: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, fields: table<name: string, value: string, verified_at: string>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list<record>, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>
export def "get-api-v1-accounts-id" [
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
    path: "/api/v1/accounts/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Block the given account. Clients should filter statuses from this account if received (e.g. due to a boost in the Home timeline).
#
# POST /api/v1/accounts/{id}/block
# Returns: record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool>
export def "post-api-v1-accounts-id-block" [
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
    method: post
    path: "/api/v1/accounts/{id}/block"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tags featured by this account.
#
# GET /api/v1/accounts/{id}/featured_tags
# Returns: table<id: string, last_status_at: string, name: string, statuses_count: int, url: string>
export def "get-api-v1-accounts-id-featured-tags" [
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
    path: "/api/v1/accounts/{id}/featured_tags"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Follow the given account. Can also be used to update whether to show reblogs or enable notifications.
#
# POST /api/v1/accounts/{id}/follow
# Returns: record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool>
export def "post-api-v1-accounts-id-follow" [
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
  --body: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/accounts/{id}/follow"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/form-data", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accounts which follow the given account, if network is not hidden by the account owner.
#
# GET /api/v1/accounts/{id}/followers
# Returns: table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>
export def "get-api-v1-accounts-id-followers" [
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
  --max-id: string # Internal parameter. Use HTTP `Link` header for pagination.
  --since-id: string # Internal parameter. Use HTTP `Link` header for pagination.
  --limit: int # Maximum number of results to return. Defaults to 40. (default: 40)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/accounts/{id}/followers"
    path_params: [{name: id, var: id}]
    query: [{name: max_id, var: max_id}, {name: since_id, var: since_id}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, max_id: $max_id, since_id: $since_id, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accounts which the given account is following, if network is not hidden by the account owner.
#
# GET /api/v1/accounts/{id}/following
# Returns: table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>
export def "get-api-v1-accounts-id-following" [
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
  --max-id: string # Internal parameter. Use HTTP `Link` header for pagination.
  --since-id: string # Internal parameter. Use HTTP `Link` header for pagination.
  --limit: int # Maximum number of results to return. Defaults to 40. (default: 40)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/accounts/{id}/following"
    path_params: [{name: id, var: id}]
    query: [{name: max_id, var: max_id}, {name: since_id, var: since_id}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, max_id: $max_id, since_id: $since_id, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Array of IdentityProof
#
# GET /api/v1/accounts/{id}/identity_proofs
# Returns: table<profile_url: string, proof_url: string, provider: string, provider_username: string, updated_at: string>
export def "get-api-v1-accounts-id-identity-proofs" [
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
    path: "/api/v1/accounts/{id}/identity_proofs"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# User lists that you have added this account to.
#
# GET /api/v1/accounts/{id}/lists
# Returns: table<id: string, replies_policy: string, title: string>
export def "get-api-v1-accounts-id-lists" [
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
    path: "/api/v1/accounts/{id}/lists"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mute the given account. Clients should filter statuses and notifications from this account, if received (e.g. due to a boost in the Home timeline).
#
# POST /api/v1/accounts/{id}/mute
# Returns: record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool>
export def "post-api-v1-accounts-id-mute" [
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
  --body: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/accounts/{id}/mute"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/form-data", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets a private note on a user.
#
# POST /api/v1/accounts/{id}/note
# Returns: record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool>
export def "post-api-v1-accounts-id-note" [
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
  --body: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/accounts/{id}/note"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/form-data", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add the given account to the user's featured profiles. (Featured profiles are currently shown on the user's own public profile.)
#
# POST /api/v1/accounts/{id}/pin
# Returns: record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool>
export def "post-api-v1-accounts-id-pin" [
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
    method: post
    path: "/api/v1/accounts/{id}/pin"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Statuses posted to the given account.
#
# GET /api/v1/accounts/{id}/statuses
# Returns: table<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: list<record>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>
export def "get-api-v1-accounts-id-statuses" [
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
    path: "/api/v1/accounts/{id}/statuses"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Block the given account. Clients should filter statuses from this account if received (e.g. due to a boost in the Home timeline).
#
# POST /api/v1/accounts/{id}/unblock
# Returns: record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool>
export def "post-api-v1-accounts-id-unblock" [
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
    method: post
    path: "/api/v1/accounts/{id}/unblock"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unfollow the given account.
#
# POST /api/v1/accounts/{id}/unfollow
# Returns: record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool>
export def "post-api-v1-accounts-id-unfollow" [
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
    method: post
    path: "/api/v1/accounts/{id}/unfollow"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unmute the given account.
#
# POST /api/v1/accounts/{id}/unmute
# Returns: record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool>
export def "post-api-v1-accounts-id-unmute" [
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
    method: post
    path: "/api/v1/accounts/{id}/unmute"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove the given account from the user's featured profiles.
#
# POST /api/v1/accounts/{id}/unpin
# Returns: record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool>
export def "post-api-v1-accounts-id-unpin" [
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
    method: post
    path: "/api/v1/accounts/{id}/unpin"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View accounts matching certain criteria for filtering, up to 100 at a time. Pagination may be done with the HTTP Link header in the response.
#
# GET /api/v1/admin/accounts
# Returns: table<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, approved: bool, confirmed: bool, created_at: string, created_by_application_id: string, disabled: bool, email: string, id: string, invite_request: string, invited_by_account_id: string, ip: string, locale: string, role: string, silenced: bool, suspended: bool, username: string>
export def "get-api-v1-admin-accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --local: oneof<nothing, bool> # Filter for local accounts?
  --remote: oneof<nothing, bool> # Filter for remote accounts?
  --by-domain: string # Filter by the given domain
  --active: oneof<nothing, bool> # Filter for currently active accounts?
  --pending: oneof<nothing, bool> # Filter for currently pending accounts?
  --disabled: oneof<nothing, bool> # Filter for currently disabled accounts?
  --silenced: oneof<nothing, bool> # Filter for currently silenced accounts?
  --suspended: oneof<nothing, bool> # Filter for currently suspended accounts?
  --staff: oneof<nothing, bool> # Filter for staff accounts?
  --username: string # Username to search for
  --display-name: string # Display name to search for
  --email: string # Lookup a user with this email
  --ip: string # Lookup a user with this IP
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/admin/accounts"
    query: [{name: local, var: local}, {name: remote, var: remote}, {name: by_domain, var: by_domain}, {name: active, var: active}, {name: pending, var: pending}, {name: disabled, var: disabled}, {name: silenced, var: silenced}, {name: suspended, var: suspended}, {name: staff, var: staff}, {name: username, var: username}, {name: display_name, var: display_name}, {name: email, var: email}, {name: ip, var: ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    local: $local, remote: $remote, by_domain: $by_domain, active: $active, pending: $pending, disabled: $disabled, silenced: $silenced, suspended: $suspended, staff: $staff, username: $username, display_name: $display_name, email: $email, ip: $ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View admin-level information about the given account.
#
# GET /api/v1/admin/accounts/{id}
# Returns: record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, approved: bool, confirmed: bool, created_at: string, created_by_application_id: string, disabled: bool, email: string, id: string, invite_request: string, invited_by_account_id: string, ip: string, locale: string, role: string, silenced: bool, suspended: bool, username: string>
export def "get-api-v1-admin-accounts-id" [
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
    path: "/api/v1/admin/accounts/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Perform an action against an account and log this action in the moderation history.
#
# POST /api/v1/admin/accounts/{id}/action
export def "post-api-v1-admin-accounts-id-action" [
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
  --report-id: string # ID of an associated report that caused this action to be taken
  --send-email-notification: oneof<nothing, bool> # Whether an email should be sent to the user with the above information.
  --text: string # Additional text for clarification of why this action was taken
  --type: string@type-completer # Type of action to be taken. Enumerable oneOf: none disable silence suspend
  --warning-preset-id: string # ID of a preset warning
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/admin/accounts/{id}/action"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: report_id, var: report_id}, {name: send_email_notification, var: send_email_notification}, {name: text, var: text}, {name: type, var: type}, {name: warning_preset_id, var: warning_preset_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, report_id: $report_id, send_email_notification: $send_email_notification, text: $text, type: $type, warning_preset_id: $warning_preset_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Approve the given local account if it is currently pending approval.
#
# POST /api/v1/admin/accounts/{id}/approve
export def "post-api-v1-admin-accounts-id-approve" [
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
    path: "/api/v1/admin/accounts/{id}/approve"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Re-enable a local account whose login is currently disabled.
#
# POST /api/v1/admin/accounts/{id}/enable
export def "post-api-v1-admin-accounts-id-enable" [
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
    path: "/api/v1/admin/accounts/{id}/enable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reject the given local account if it is currently pending approval.
#
# POST /api/v1/admin/accounts/{id}/reject
export def "post-api-v1-admin-accounts-id-reject" [
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
    path: "/api/v1/admin/accounts/{id}/reject"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unsilence a currently silenced account.
#
# POST /api/v1/admin/accounts/{id}/unsilence
export def "post-api-v1-admin-accounts-id-unsilence" [
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
    path: "/api/v1/admin/accounts/{id}/unsilence"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unsuspend a currently suspended account.
#
# POST /api/v1/admin/accounts/{id}/unsuspend
export def "post-api-v1-admin-accounts-id-unsuspend" [
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
    path: "/api/v1/admin/accounts/{id}/unsuspend"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View all reports. Pagination may be done with HTTP Link header in the response.
#
# GET /api/v1/admin/reports
# Returns: table<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, action_taken: string, assigned_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, comment: string, created_at: string, id: string, statuses: list<record>, target_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, updated_at: string>
export def "get-api-v1-admin-reports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resolved: oneof<nothing, bool>
  --account-id: string
  --target-account-id: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/admin/reports"
    query: [{name: resolved, var: resolved}, {name: account_id, var: account_id}, {name: target_account_id, var: target_account_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resolved: $resolved, account_id: $account_id, target_account_id: $target_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View information about the report with the given ID.
#
# GET /api/v1/admin/reports/{id}
# Returns: record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, action_taken: string, assigned_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, comment: string, created_at: string, id: string, statuses: table<account: record, application: record, bookmarked: bool, card: record, content: string, created_at: string, emojis: list, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, target_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, updated_at: string>
export def "get-api-v1-admin-reports-id" [
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
    path: "/api/v1/admin/reports/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Claim the handling of this report to yourself.
#
# POST /api/v1/admin/reports/{id}/assign_to_self
# Returns: record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, action_taken: string, assigned_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, comment: string, created_at: string, id: string, statuses: table<account: record, application: record, bookmarked: bool, card: record, content: string, created_at: string, emojis: list, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, target_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, updated_at: string>
export def "post-api-v1-admin-reports-id-assign-to-self" [
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
    method: post
    path: "/api/v1/admin/reports/{id}/assign_to_self"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mark a report as resolved with no further action taken.
#
# POST /api/v1/admin/reports/{id}/reopen
# Returns: record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, action_taken: string, assigned_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, comment: string, created_at: string, id: string, statuses: table<account: record, application: record, bookmarked: bool, card: record, content: string, created_at: string, emojis: list, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, target_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, updated_at: string>
export def "post-api-v1-admin-reports-id-reopen" [
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
    method: post
    path: "/api/v1/admin/reports/{id}/reopen"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mark a report as resolved with no further action taken.
#
# POST /api/v1/admin/reports/{id}/resolve
# Returns: record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, action_taken: string, assigned_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, comment: string, created_at: string, id: string, statuses: table<account: record, application: record, bookmarked: bool, card: record, content: string, created_at: string, emojis: list, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, target_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, updated_at: string>
export def "post-api-v1-admin-reports-id-resolve" [
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
    method: post
    path: "/api/v1/admin/reports/{id}/resolve"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unassign a report so that someone else can claim it.
#
# POST /api/v1/admin/reports/{id}/unassign
# Returns: record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, action_taken: string, assigned_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, comment: string, created_at: string, id: string, statuses: table<account: record, application: record, bookmarked: bool, card: record, content: string, created_at: string, emojis: list, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, target_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, updated_at: string>
export def "post-api-v1-admin-reports-id-unassign" [
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
    method: post
    path: "/api/v1/admin/reports/{id}/unassign"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# See all currently active announcements set by admins.
#
# GET /api/v1/announcements
# Returns: table<all_day: bool, created_at: string, ends_at: string, id: string, published: bool, read: bool, scheduled_at: string, starts_at: string, text: string, updated_at: string>
export def "get-api-v1-announcements" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-dismissed: oneof<nothing, bool> # If true, response will include announcements dismissed by the user. Defaults to false.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/announcements"
    query: [{name: with_dismissed, var: with_dismissed}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    with_dismissed: $with_dismissed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows a user to mark the announcement as read.
#
# POST /api/v1/announcements/{id}/dismiss
# Returns: record
export def "post-api-v1-announcements-id-dismiss" [
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
    method: post
    path: "/api/v1/announcements/{id}/dismiss"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Undo a react emoji to an announcement.
#
# DELETE /api/v1/announcements/{id}/reactions/{name}
# Returns: record
export def "delete-api-v1-announcements-id-reactions-name" [
  id: string
  name: string
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
    method: delete
    path: "/api/v1/announcements/{id}/reactions/{name}"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows a user to mark the announcement as read.
#
# PUT /api/v1/announcements/{id}/reactions/{name}
# Returns: record
export def "put-api-v1-announcements-id-reactions-name" [
  id: string
  name: string
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
    method: put
    path: "/api/v1/announcements/{id}/reactions/{name}"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new application to obtain OAuth2 credentials.
#
# POST /api/v1/apps
# Returns: record<client_id: string, client_secret: string, id: string, name: string, redirect_uri: string, vapid_key: string, website: string>
export def "post-api-v1-apps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/apps"
    body: {content_type: "application/form-data", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Confirm that the app's OAuth2 credentials work.
#
# GET /api/v1/apps/verify_credentials
# Returns: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>
export def "get-api-v1-apps-verify-credentials" [
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
    path: "/api/v1/apps/verify_credentials"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get blocked users.
#
# GET /api/v1/blocks
# Returns: table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>
export def "get-api-v1-blocks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int
  --max-id: string
  --since-id: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/blocks"
    query: [{name: limit, var: limit}, {name: max_id, var: max_id}, {name: since_id, var: since_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, max_id: $max_id, since_id: $since_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Statuses the user has bookmarked.
#
# GET /api/v1/bookmarks
# Returns: table<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: list<record>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>
export def "get-api-v1-bookmarks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int
  --max-id: string
  --since-id: string
  --min-id: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/bookmarks"
    query: [{name: limit, var: limit}, {name: max_id, var: max_id}, {name: since_id, var: since_id}, {name: min_id, var: min_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, max_id: $max_id, since_id: $since_id, min_id: $min_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show conversation.
#
# GET /api/v1/conversations
# Returns: table<accounts: list<record>, id: string, last_status: record<account: record, application: record, bookmarked: bool, card: record, content: string, created_at: string, emojis: list, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, unread: bool>
export def "get-api-v1-conversations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Max number of results to return. Defaults to 20. (default: 20)
  --max-id: string # Return results older than ID
  --since-id: string # Return results newer than ID
  --min-id: string # Return results immediately newer than ID
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/conversations"
    query: [{name: limit, var: limit}, {name: max_id, var: max_id}, {name: since_id, var: since_id}, {name: min_id, var: min_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, max_id: $max_id, since_id: $since_id, min_id: $min_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove converstation
#
# DELETE /api/v1/conversations/{id}
# Returns: record
export def "delete-api-v1-conversations-id" [
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
    method: delete
    path: "/api/v1/conversations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove converstation
#
# POST /api/v1/conversations/{id}/read
# Returns: record<accounts: table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, id: string, last_status: record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: list<record>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>, unread: bool>
export def "post-api-v1-conversations-id-read" [
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
    method: post
    path: "/api/v1/conversations/{id}/read"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns custom emojis that are available on the server.
#
# GET /api/v1/custom_emojis
# Returns: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>
export def "get-api-v1-custom-emojis" [
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
    path: "/api/v1/custom_emojis"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List accounts visible in the directory.
#
# GET /api/v1/directory
# Returns: table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>
export def "get-api-v1-directory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # How many accounts to load. Default 40. (default: 40)
  --offset: int # How many accounts to skip before returning results. Default 0. (default: 0)
  --order: string@order-completer # the `active` to sort by most recently posted statuses (default) or `new` to sort by most recently created profiles. (default: active)
  --local: oneof<nothing, bool> # Only return local accounts.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/directory"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: order, var: order}, {name: local, var: local}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, order: $order, local: $local
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a domain block, if it exists in the user's array of blocked domains.
#
# DELETE /api/v1/domain_blocks
# Returns: record
export def "delete-api-v1-domain-blocks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # Domain to unblock. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/api/v1/domain_blocks"
    query: [{name: domain, var: domain, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View domains the user has blocked.
#
# GET /api/v1/domain_blocks
# Returns: list<string>
export def "get-api-v1-domain-blocks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int
  --max-id: string
  --since-id: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/domain_blocks"
    query: [{name: limit, var: limit}, {name: max_id, var: max_id}, {name: since_id, var: since_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, max_id: $max_id, since_id: $since_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# "Block a domain to: - hide all public posts from it - hide all notifications from it - remove all followers from it - prevent following new users from it (but does not remove existing follows)"
#
# POST /api/v1/domain_blocks
# Returns: record
export def "post-api-v1-domain-blocks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/domain_blocks"
    body: {content_type: "application/form-data", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accounts that the user is currently featuring on their profile.
#
# GET /api/v1/endorsements
# Returns: table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>
export def "get-api-v1-endorsements" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Maximum number of results to return. Defaults to 40. Paginate using the HTTP Link header. (default: 40)
  --max-id: string # Internal parameter. Use HTTP Link header from response for pagination
  --since-id: string # Internal parameter. Use HTTP Link header from response for pagination.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/endorsements"
    query: [{name: limit, var: limit}, {name: max_id, var: max_id}, {name: since_id, var: since_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, max_id: $max_id, since_id: $since_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Statuses the user has favourited.
#
# GET /api/v1/favourites
# Returns: table<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: list<record>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>
export def "get-api-v1-favourites" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string
  --max-id: string
  --min-id: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/favourites"
    query: [{name: limit, var: limit}, {name: max_id, var: max_id}, {name: min_id, var: min_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, max_id: $max_id, min_id: $min_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View your featured tags.
#
# GET /api/v1/featured_tags
# Returns: table<id: string, last_status_at: string, name: string, statuses_count: int, url: string>
export def "get-api-v1-featured-tags" [
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
    path: "/api/v1/featured_tags"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a feature a tag.
#
# POST /api/v1/featured_tags
# Returns: record<id: string, last_status_at: string, name: string, statuses_count: int, url: string>
export def "post-api-v1-featured-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/featured_tags"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Shows your 10 most-used tags, with usage history for the past week.
#
# GET /api/v1/featured_tags/suggestions
# Returns: table<id: string, last_status_at: string, name: string, statuses_count: int, url: string>
export def "get-api-v1-featured-tags-suggestions" [
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
    path: "/api/v1/featured_tags/suggestions"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unfeature a tag
#
# DELETE /api/v1/featured_tags/{id}
# Returns: record
export def "delete-api-v1-featured-tags-id" [
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
    method: delete
    path: "/api/v1/featured_tags/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/v1/filters
#
# Returns: table<context: list<string>, expires_at: string, id: string, irreversible: bool, phrase: string, whole_word: bool>
export def "get-api-v1-filters" [
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
    path: "/api/v1/filters"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/filters
#
# Returns: record<context: list<string>, expires_at: string, id: string, irreversible: bool, phrase: string, whole_word: bool>
export def "post-api-v1-filters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/filters"
    body: {content_type: "application/form-data", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a filter.
#
# DELETE /api/v1/filters/{id}
export def "delete-api-v1-filters-id" [
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
    path: "/api/v1/filters/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get one filter.
#
# GET /api/v1/filters/{id}
# Returns: record<context: list<string>, expires_at: string, id: string, irreversible: bool, phrase: string, whole_word: bool>
export def "get-api-v1-filters-id" [
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
    path: "/api/v1/filters/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a filter.
#
# PUT /api/v1/filters/{id}
# Returns: record<context: list<string>, expires_at: string, id: string, irreversible: bool, phrase: string, whole_word: bool>
export def "put-api-v1-filters-id" [
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
  --body: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/filters/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/form-data", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Pending Follows
#
# GET /api/v1/follow_requests
# Returns: table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>
export def "get-api-v1-follow-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Maximum number of results to return. Defaults to 40. Paginate using the HTTP Link header. (default: 40)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/follow_requests"
    query: [{name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accept Follow
#
# POST /api/v1/follow_requests/{id}/authorize
# Returns: record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool>
export def "post-api-v1-follow-requests-id-authorize" [
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
    method: post
    path: "/api/v1/follow_requests/{id}/authorize"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accept Follow
#
# POST /api/v1/follow_requests/{id}/reject
# Returns: record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool>
export def "post-api-v1-follow-requests-id-reject" [
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
    method: post
    path: "/api/v1/follow_requests/{id}/reject"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Information about the server.
#
# GET /api/v1/instance
# Returns: record<approval_required: bool, contact_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, description: string, email: string, invites_enabled: bool, languages: list<string>, registrations: bool, short_description: string, stats: record, thumbnail: string, title: string, uri: string, urls: record, version: string>
export def "get-api-v1-instance" [
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
    path: "/api/v1/instance"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Instance activity over the last 3 months, binned weekly.
#
# GET /api/v1/instance/activity
# Returns: table<logins: string, registrations: string, statuses: string, week: string>
export def "get-api-v1-instance-activity" [
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
    path: "/api/v1/instance/activity"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Information about the server.
#
# GET /api/v1/instance/peers
# Returns: list<string>
export def "get-api-v1-instance-peers" [
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
    path: "/api/v1/instance/peers"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a list
#
# DELETE /api/v1/lists
# Returns: record
export def "delete-api-v1-lists" [
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
    method: delete
    path: "/api/v1/lists"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch all lists that the user owns.
#
# GET /api/v1/lists
# Returns: table<id: string, replies_policy: string, title: string>
export def "get-api-v1-lists" [
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
    path: "/api/v1/lists"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new list.
#
# POST /api/v1/lists
# Returns: record<id: string, replies_policy: string, title: string>
export def "post-api-v1-lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --replies-policy: string@replies-policy-completer # Enumerable oneOf followed list none. Defaults to list. (default: list)
  title: string # The title of the list to be created.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/lists"
    body: {content_type: "application/json", kind: json, fields: [{name: replies_policy, var: replies_policy}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    replies_policy: $replies_policy, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change the title of a list, or which replies to show.
#
# PUT /api/v1/lists
# Returns: record<id: string, replies_policy: string, title: string>
export def "put-api-v1-lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --replies-policy: string@replies-policy-completer # Enumerable oneOf followed list none. Defaults to list. (default: list)
  --title: string # The title of the list to be created.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/lists"
    body: {content_type: "application/json", kind: json, fields: [{name: replies_policy, var: replies_policy}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    replies_policy: $replies_policy, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove converstation
#
# GET /api/v1/lists/{id}
# Returns: record<id: string, replies_policy: string, title: string>
export def "get-api-v1-lists-id" [
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
    path: "/api/v1/lists/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove accounts from the given list.
#
# DELETE /api/v1/lists/{id}/accounts
# Returns: record
export def "delete-api-v1-lists-id-accounts" [
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
  --account-ids: list<string> # Array of account IDs to add to the list. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/api/v1/lists/{id}/accounts"
    path_params: [{name: id, var: id}]
    query: [{name: account_ids, var: account_ids, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, account_ids: $account_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View accounts in List
#
# GET /api/v1/lists/{id}/accounts
# Returns: table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>
export def "get-api-v1-lists-id-accounts" [
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
  --limit: int # Maximum number of results. Defaults to 40. Max 40. Set to 0 in order to get all accounts without pagination. Pagination is done with the HTTP Link header. (default: 40)
  --max-id: string # Return results older than ID
  --since-id: string # Return results newer than ID
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/lists/{id}/accounts"
    path_params: [{name: id, var: id}]
    query: [{name: limit, var: limit}, {name: max_id, var: max_id}, {name: since_id, var: since_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, limit: $limit, max_id: $max_id, since_id: $since_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add accounts to the given list. Note that the user must be following these accounts.
#
# POST /api/v1/lists/{id}/accounts
# Returns: record
export def "post-api-v1-lists-id-accounts" [
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
  account_ids: list<string> # Array of account IDs to add to the list.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/lists/{id}/accounts"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: account_ids, var: account_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, account_ids: $account_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get saved timeline position
#
# GET /api/v1/markers
# Returns: record
export def "get-api-v1-markers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeline: list # Array of markers to fetch. String enum anyOf home, notifications. If not provided, an empty object will be returned. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/markers"
    query: [{name: timeline, var: timeline, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    timeline: $timeline
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get saved timeline position
#
# POST /api/v1/markers
# Returns: record
export def "post-api-v1-markers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/markers"
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an attachment to be used with a new status.
#
# POST /api/v1/media
# Returns: record<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>
export def "post-api-v1-media" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/media"
    body: {content_type: "application/form-data", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an attachement.
#
# GET /api/v1/media/{id}
# Returns: record<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>
export def "get-api-v1-media-id" [
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
    path: "/api/v1/media/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200, 206]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an Attachment, before it is attached to a status and posted.
#
# POST /api/v1/media/{id}
# Returns: record<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>
export def "post-api-v1-media-id" [
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
  --body: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/media/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/form-data", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accounts the user has muted.
#
# GET /api/v1/mutes
# Returns: table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>
export def "get-api-v1-mutes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string
  --max-id: string
  --since-id: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/mutes"
    query: [{name: limit, var: limit}, {name: max_id, var: max_id}, {name: since_id, var: since_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, max_id: $max_id, since_id: $since_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Notifications concerning the user. This API returns Link headers containing links to the next/previous page. However, the links can also be constructed dynamically using query params and id values.
#
# GET /api/v1/notifications
# Returns: table<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, created_at: string, id: string, status: record<account: record, application: record, bookmarked: bool, card: record, content: string, created_at: string, emojis: list, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, type: string>
export def "get-api-v1-notifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Max number of results to return. Defaults to 20. (default: 20)
  --max-id: string # Return results older than ID
  --since-id: string # Return results newer than ID
  --min-id: string # Return results immediately newer than ID
  --exclude-types: list<string> # Array of types to exclude (follow, favourite, reblog, mention, poll, follow_request)
  --account-id: string # Return only notifications received from this account
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/notifications"
    query: [{name: limit, var: limit}, {name: max_id, var: max_id}, {name: since_id, var: since_id}, {name: min_id, var: min_id}, {name: exclude_types, var: exclude_types, style: multi}, {name: account_id, var: account_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, max_id: $max_id, since_id: $since_id, min_id: $min_id, exclude_types: $exclude_types, account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clear all notifications from the server.
#
# POST /api/v1/notifications/clear
# Returns: record
export def "post-api-v1-notifications-clear" [
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
    method: post
    path: "/api/v1/notifications/clear"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View information about a notification with a given ID.
#
# GET /api/v1/notifications/{id}
# Returns: record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, created_at: string, id: string, status: record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: list<record>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>, type: string>
export def "get-api-v1-notifications-id" [
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
    path: "/api/v1/notifications/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clear a single notification from the server.
#
# POST /api/v1/notifications/{id}/dismiss
# Returns: record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, created_at: string, id: string, status: record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: list<record>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>, type: string>
export def "post-api-v1-notifications-id-dismiss" [
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
    method: post
    path: "/api/v1/notifications/{id}/dismiss"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View a poll.
#
# GET /api/v1/polls/{id}
# Returns: record<emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>
export def "get-api-v1-polls-id" [
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
    path: "/api/v1/polls/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Vote on a poll.
#
# POST /api/v1/polls/{id}
# Returns: record<emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>
export def "post-api-v1-polls-id" [
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
  choices: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/polls/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: choices, var: choices}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, choices: $choices
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Shows your 10 most-used tags, with usage history for the past week.
#
# GET /api/v1/preferences
# Returns: record<"posting:default:language": string, "posting:default:sensitive": bool, "posting:default:visibility": string, "reading:expand:media": string, "reading:expand:spoilers": bool>
export def "get-api-v1-preferences" [
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
    path: "/api/v1/preferences"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the current push subscription. Only the data part can be updated. To change fundamentals, a new subscription must be created instead.
#
# DELETE /api/v1/push/subscription
# Returns: record
export def "delete-api-v1-push-subscription" [
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
    method: delete
    path: "/api/v1/push/subscription"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View the PushSubscription currently associated with this access token.
#
# GET /api/v1/push/subscription
# Returns: record<alerts: record, endpoint: string, id: string, server_key: string>
export def "get-api-v1-push-subscription" [
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
    path: "/api/v1/push/subscription"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a Web Push API subscription to receive notifications. Each access token can have one push subscription. If you create a new subscription, the old subscription is deleted.
#
# POST /api/v1/push/subscription
# Returns: record<alerts: record, endpoint: string, id: string, server_key: string>
export def "post-api-v1-push-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: string
  subscription: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/push/subscription"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}, {name: subscription, var: subscription}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    data: $data, subscription: $subscription
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the current push subscription. Only the data part can be updated. To change fundamentals, a new subscription must be created instead.
#
# PUT /api/v1/push/subscription
# Returns: record<alerts: record, endpoint: string, id: string, server_key: string>
export def "put-api-v1-push-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/push/subscription"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# File a report.
#
# POST /api/v1/reports
# Returns: record<action_taken: bool, action_taken_at: string, category: string, comment: string, created_at: string, forwarded: bool, id: string, rule_ids: list<int>, status_ids: list<int>, target_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>>
export def "post-api-v1-reports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_id: string # ID of the account to report
  --comment: string # Reason for the report (default max 1000 characters)
  --forward: oneof<nothing, bool> # If the account is remote, should the report be forwarded to the remote admin?
  --status-ids: list<string> # Array of Statuses to attach to the report, for context
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/reports"
    body: {content_type: "application/json", kind: json, fields: [{name: account_id, var: account_id}, {name: comment, var: comment}, {name: forward, var: forward}, {name: status_ids, var: status_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, comment: $comment, forward: $forward, status_ids: $status_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View scheduled statuses
#
# GET /api/v1/scheduled_statuses
# Returns: table<id: string, media_attachments: list<record>, params: record<application_id: string, in_reply_to_id: string, media_ids: list, scheduled_at: string, sensitive: bool, spoiler_text: string, text: string, visibility: string>, scheduled_at: string>
export def "get-api-v1-scheduled-statuses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Max number of results to return. Defaults to 20. (default: 20)
  --max-id: string # Return results older than ID
  --since-id: string # Return results newer than ID
  --min-id: string # Return results immediately newer than ID
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/scheduled_statuses"
    query: [{name: limit, var: limit}, {name: max_id, var: max_id}, {name: since_id, var: since_id}, {name: min_id, var: min_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, max_id: $max_id, since_id: $since_id, min_id: $min_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel a scheduled status
#
# DELETE /api/v1/scheduled_statuses/{id}
# Returns: record
export def "delete-api-v1-scheduled-statuses-id" [
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
    method: delete
    path: "/api/v1/scheduled_statuses/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View a single scheduled status
#
# GET /api/v1/scheduled_statuses/{id}
# Returns: record<id: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, params: record<application_id: string, in_reply_to_id: string, media_ids: list<string>, scheduled_at: string, sensitive: bool, spoiler_text: string, text: string, visibility: string>, scheduled_at: string>
export def "get-api-v1-scheduled-statuses-id" [
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
    path: "/api/v1/scheduled_statuses/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View a single scheduled status
#
# PUT /api/v1/scheduled_statuses/{id}
# Returns: record<id: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, params: record<application_id: string, in_reply_to_id: string, media_ids: list<string>, scheduled_at: string, sensitive: bool, spoiler_text: string, text: string, visibility: string>, scheduled_at: string>
export def "put-api-v1-scheduled-statuses-id" [
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
  --scheduled-at: string # ISO 8601 Datetime at which the status will be published. Must be at least 5 minutes into the future. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/scheduled_statuses/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: scheduled_at, var: scheduled_at}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, scheduled_at: $scheduled_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/statuses
export def "post-api-v1-statuses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # Prevent duplicate submissions of the same status. Idempotency keys are stored for up to 1 hour, and can be any arbitrary string. Consider using a hash or UUID generated client-side.
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/statuses"
    header: [{name: Idempotency-Key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    idempotency_key: $idempotency_key, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /api/v1/statuses/{id}
#
# Returns: record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string>
export def "delete-api-v1-statuses-id" [
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
    method: delete
    path: "/api/v1/statuses/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/v1/statuses/{id}
#
# Returns: record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string>
export def "get-api-v1-statuses-id" [
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
    path: "/api/v1/statuses/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Privately bookmark a status.
#
# POST /api/v1/statuses/{id}/bookmark
# Returns: record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string>
export def "post-api-v1-statuses-id-bookmark" [
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
    method: post
    path: "/api/v1/statuses/{id}/bookmark"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/v1/statuses/{id}/context
#
# Returns: record<ancestors: table<account: record, application: record, bookmarked: bool, card: record, content: string, created_at: string, emojis: list, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, descendants: table<account: record, application: record, bookmarked: bool, card: record, content: string, created_at: string, emojis: list, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>>
export def "get-api-v1-statuses-id-context" [
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
    path: "/api/v1/statuses/{id}/context"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a status to your favourites list.
#
# POST /api/v1/statuses/{id}/favourite
# Returns: record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string>
export def "post-api-v1-statuses-id-favourite" [
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
    method: post
    path: "/api/v1/statuses/{id}/favourite"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View who favourited a given status.
#
# GET /api/v1/statuses/{id}/favourited_by
# Returns: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, fields: table<name: string, value: string, verified_at: string>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list<record>, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>
export def "get-api-v1-statuses-id-favourited-by" [
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
    path: "/api/v1/statuses/{id}/favourited_by"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Do not receive notifications for the thread that this status is part of. Must be a thread in which you are a participant.
#
# POST /api/v1/statuses/{id}/mute
# Returns: record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string>
export def "post-api-v1-statuses-id-mute" [
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
    method: post
    path: "/api/v1/statuses/{id}/mute"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Feature one of your own public statuses at the top of your profile.
#
# POST /api/v1/statuses/{id}/pin
# Returns: record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string>
export def "post-api-v1-statuses-id-pin" [
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
    method: post
    path: "/api/v1/statuses/{id}/pin"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reshare a status.
#
# POST /api/v1/statuses/{id}/reblog
# Returns: record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string>
export def "post-api-v1-statuses-id-reblog" [
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
  --visibility: string # any visibility except limited or direct (i.e. public, unlisted, private). Defaults to public. Currently unused in UI.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/statuses/{id}/reblog"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: visibility, var: visibility}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, visibility: $visibility
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View who boosted a given status.
#
# GET /api/v1/statuses/{id}/reblogged_by
# Returns: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, fields: table<name: string, value: string, verified_at: string>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list<record>, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>
export def "get-api-v1-statuses-id-reblogged-by" [
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
    path: "/api/v1/statuses/{id}/reblogged_by"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a status from your private bookmarks.
#
# POST /api/v1/statuses/{id}/unbookmark
# Returns: record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string>
export def "post-api-v1-statuses-id-unbookmark" [
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
    method: post
    path: "/api/v1/statuses/{id}/unbookmark"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a status from your favourites list.
#
# POST /api/v1/statuses/{id}/unfavourite
# Returns: record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string>
export def "post-api-v1-statuses-id-unfavourite" [
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
    method: post
    path: "/api/v1/statuses/{id}/unfavourite"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Status's conversation unmuted, or was already unmuted
#
# POST /api/v1/statuses/{id}/unmute
# Returns: record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string>
export def "post-api-v1-statuses-id-unmute" [
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
    method: post
    path: "/api/v1/statuses/{id}/unmute"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unfeature a status from the top of your profile.
#
# POST /api/v1/statuses/{id}/unpin
# Returns: record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string>
export def "post-api-v1-statuses-id-unpin" [
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
    method: post
    path: "/api/v1/statuses/{id}/unpin"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Undo a reshare of a status.
#
# POST /api/v1/statuses/{id}/unreblog
# Returns: record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string>
export def "post-api-v1-statuses-id-unreblog" [
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
    method: post
    path: "/api/v1/statuses/{id}/unreblog"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accounts the user has had past positive interactions with, but is not yet following.
#
# GET /api/v1/suggestions
# Returns: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, fields: table<name: string, value: string, verified_at: string>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list<record>, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>
export def "get-api-v1-suggestions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Maximum number of results to return. Defaults to 40. (default: 40)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/suggestions"
    query: [{name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete user suggestion
#
# DELETE /api/v1/suggestions/{id}
# Returns: record
export def "delete-api-v1-suggestions-id" [
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
    method: delete
    path: "/api/v1/suggestions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View statuses from followed users.
#
# GET /api/v1/timelines/home
# Returns: table<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: list<record>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>
export def "get-api-v1-timelines-home" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --local: oneof<nothing, bool> # Show only local statuses? Defaults to false. (default: false)
  --limit: int # Max number of results to return. Defaults to 20. (default: 20)
  --max-id: string # Return results older than ID
  --since-id: string # Return results newer than ID
  --min-id: string # Return results immediately newer than ID
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/timelines/home"
    query: [{name: local, var: local}, {name: limit, var: limit}, {name: max_id, var: max_id}, {name: since_id, var: since_id}, {name: min_id, var: min_id}]
    accept: ["application/json"]
    ok: [200, 206]
    auth: bearer
  } {
    local: $local, limit: $limit, max_id: $max_id, since_id: $since_id, min_id: $min_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View statuses in the given list timeline.
#
# GET /api/v1/timelines/list/{list_id}
# Returns: table<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: list<record>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>
export def "get-api-v1-timelines-list-list-id" [
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
  --limit: int # Max number of results to return. Defaults to 20. (default: 20)
  --max-id: string # Return results older than ID
  --since-id: string # Return results newer than ID
  --min-id: string # Return results immediately newer than ID
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/timelines/list/{list_id}"
    path_params: [{name: list_id, var: list_id}]
    query: [{name: limit, var: limit}, {name: max_id, var: max_id}, {name: since_id, var: since_id}, {name: min_id, var: min_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    list_id: $list_id, limit: $limit, max_id: $max_id, since_id: $since_id, min_id: $min_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Public timeline
#
# GET /api/v1/timelines/public
# Returns: table<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: list<record>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>
export def "get-api-v1-timelines-public" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --local: oneof<nothing, bool> # Show only local statuses? Defaults to false. (default: false)
  --remote: oneof<nothing, bool> # Show only local statuses? Defaults to false. (default: false)
  --only-media: oneof<nothing, bool> # Show only statuses with media attached? Defaults to false.. (default: false)
  --limit: int # Max number of results to return. Defaults to 20. (default: 20)
  --max-id: string # Return results older than ID
  --since-id: string # Return results newer than ID
  --min-id: string # Return results immediately newer than ID
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/timelines/public"
    query: [{name: local, var: local}, {name: remote, var: remote}, {name: only_media, var: only_media}, {name: limit, var: limit}, {name: max_id, var: max_id}, {name: since_id, var: since_id}, {name: min_id, var: min_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    local: $local, remote: $remote, only_media: $only_media, limit: $limit, max_id: $max_id, since_id: $since_id, min_id: $min_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View public statuses containing the given hashtag.
#
# GET /api/v1/timelines/tag/{hashtag}
# Returns: table<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: list<record>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>
export def "get-api-v1-timelines-tag-hashtag" [
  hashtag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --local: oneof<nothing, bool> # Show only local statuses? Defaults to false. (default: false)
  --remote: oneof<nothing, bool> # Show only local statuses? Defaults to false. (default: false)
  --only-media: oneof<nothing, bool> # Show only statuses with media attached? Defaults to false.. (default: false)
  --limit: int # Max number of results to return. Defaults to 20. (default: 20)
  --max-id: string # Return results older than ID
  --since-id: string # Return results newer than ID
  --min-id: string # Return results immediately newer than ID
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/timelines/tag/{hashtag}"
    path_params: [{name: hashtag, var: hashtag}]
    query: [{name: local, var: local}, {name: remote, var: remote}, {name: only_media, var: only_media}, {name: limit, var: limit}, {name: max_id, var: max_id}, {name: since_id, var: since_id}, {name: min_id, var: min_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hashtag: $hashtag, local: $local, remote: $remote, only_media: $only_media, limit: $limit, max_id: $max_id, since_id: $since_id, min_id: $min_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tags that are being used more frequently within the past week.
#
# GET /api/v1/trends
# Returns: table<history: list<record>, name: string, url: string>
export def "get-api-v1-trends" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Max number of results to return. Defaults to 10. (default: 10)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/trends"
    query: [{name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search results
#
# GET /api/v2/search
# Returns: record<accounts: table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, hashtags: table<account: record, application: record, bookmarked: bool, card: record, content: string, created_at: string, emojis: list, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, statuses: table<history: list, name: string, url: string>>
export def "get-api-v2-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # What to search for (required)
  --limit: int # Maximum number of results. Defaults to 40. (default: 20)
  --resolve: string # Attempt WebFinger lookup.
  --following: oneof<nothing, bool> # Only who the user is following. Defaults to false.
  --account-id: string # If provided, statuses returned will be authored only by this account
  --max-id: string # Return results older than this id
  --min-id: string # Return results immediately newer than this id
  --type: string@type-completer-1 # Enum(accounts, hashtags, statuses)
  --exclude-unreviewed: oneof<nothing, bool> # Filter out unreviewed tags? Defaults to false. Use true when trying to find trending tags.
  --offset: int # Offset in search results. Used for pagination. Defaults to 0.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/search"
    query: [{name: q, var: q, required: true}, {name: limit, var: limit}, {name: resolve, var: resolve}, {name: following, var: following}, {name: account_id, var: account_id}, {name: max_id, var: max_id}, {name: min_id, var: min_id}, {name: type, var: type}, {name: exclude_unreviewed, var: exclude_unreviewed}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, limit: $limit, resolve: $resolve, following: $following, account_id: $account_id, max_id: $max_id, min_id: $min_id, type: $type, exclude_unreviewed: $exclude_unreviewed, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Displays an authorization form to the user. If approved, it will create and return an authorization code, then redirect to the desired redirect_uri, or show the authorization code if urn:ietf:wg:oauth:2.0:oob was requested. The authorization code can be used while requesting a token to obtain access to user-level methods.
#
# GET /oauth/authorize
export def "get-oauth-authorize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --response-type: string # Should be set equal to code. (required)
  --client-id: string # Client ID, obtained during app registration. (required)
  --redirect-uri: string # Set a URI to redirect the user to. If this parameter is set to urn:ietf:wg:oauth:2.0:oob then the authorization code will be shown instead. Must match one of the redirect URIs declared during app registration. (required)
  --scope: string # List of requested OAuth scopes, separated by spaces (or by pluses, if using query parameters). Must be a subset of scopes declared during app registration. If not provided, defaults to read.
  --force-login: oneof<nothing, bool> # Added in 2.6.0. Forces the user to re-login, which is necessary for authorizing with multiple accounts from the same instance.
]: nothing -> any {
  http-request {
    method: get
    path: "/oauth/authorize"
    query: [{name: response_type, var: response_type, required: true}, {name: client_id, var: client_id, required: true}, {name: redirect_uri, var: redirect_uri, required: true}, {name: scope, var: scope}, {name: force_login, var: force_login}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    response_type: $response_type, client_id: $client_id, redirect_uri: $redirect_uri, scope: $scope, force_login: $force_login
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Revoke an access token to make it no longer valid for use.
#
# POST /oauth/revoke
export def "post-oauth-revoke" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/oauth/revoke"
    body: {content_type: "application/form-data", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an access token, to be used during API calls that are not public.
#
# POST /oauth/token
# Returns: record<access_token: string, created_at: int, scope: string, token_type: string>
export def "post-oauth-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/oauth/token"
    body: {content_type: "application/form-data", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
