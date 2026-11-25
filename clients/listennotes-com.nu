# Auto-generated client for Listen API: Podcast Search, Directory, and Insights API v2.0
# Source: https://api.apis.guru/v2/specs/listennotes.com/2.0/openapi.json
# Auth: --token flag or $env.LISTEN_API_PODCAST_SEARCH_DIRECTORY_AND_INSIGHTS_API_TOKEN

const CLIENT = {
  base_url: "https://listen-api.listennotes.com/api/v2"
  token_env_var: "LISTEN_API_PODCAST_SEARCH_DIRECTORY_AND_INSIGHTS_API_TOKEN"
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

def base-url-completer [] { ["https://listen-api.listennotes.com/api/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sort-completer [] { ["listen_score" "oldest_added_first" "oldest_published_first" "recent_added_first" "recent_published_first"] }
def safe-mode-completer [] { ["0" "1"] }
def top-level-only-completer [] { ["0" "1"] }
def sort-completer-1 [] { ["name_a_to_z" "name_z_to_a" "oldest_added_first" "recent_added_first"] }
def type-completer [] { ["episode_list" "podcast_list"] }
def sort-completer-2 [] { ["oldest_added_first" "oldest_published_first" "recent_added_first" "recent_published_first"] }
def show-latest-episodes-completer [] { ["0" "1"] }
def sort-completer-3 [] { ["oldest_first" "recent_first"] }
def sort-by-date-completer [] { ["0" "1"] }
def type-completer-1 [] { ["curated" "episode" "podcast"] }
def unique-podcasts-completer [] { ["0" "1"] }
def show-podcasts-completer [] { ["0" "1"] }
def show-genres-completer [] { ["0" "1"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-best-podcasts: "record<has_next: bool, has_previous: bool, id: int, listennotes_url: string, name: string, next_page_number: int, page_number: int, parent_id: int, podcasts: table<audio_length_sec: int, country: string, description: string, earliest_pub_date_ms: int, email: string, explicit_content: bool, extra: record, genre_ids: list, id: string, image: string, is_claimed: bool, itunes_id: int, language: string, latest_episode_id: string, latest_pub_date_ms: int, listen_score: int, listen_score_global_rank: string, listennotes_url: string, looking_for: record, publisher: string, rss: string, thumbnail: string, title: string, total_episodes: int, type: string, update_frequency_hours: int, website: string>, previous_page_number: int, total: int>"
    get-curated-podcasts: "record<curated_lists: table<description: string, id: string, listennotes_url: string, podcasts: list, pub_date_ms: int, source_domain: string, source_url: string, title: string, total: int>, has_next: bool, has_previous: bool, next_page_number: int, page_number: int, previous_page_number: int, total: int>"
    get-curated-podcast-by-id: "record<description: string, id: string, listennotes_url: string, podcasts: table<audio_length_sec: int, country: string, description: string, earliest_pub_date_ms: int, email: string, explicit_content: bool, extra: record, genre_ids: list, id: string, image: string, is_claimed: bool, itunes_id: int, language: string, latest_episode_id: string, latest_pub_date_ms: int, listen_score: int, listen_score_global_rank: string, listennotes_url: string, looking_for: record, publisher: string, rss: string, thumbnail: string, title: string, total_episodes: int, type: string, update_frequency_hours: int, website: string>, pub_date_ms: int, source_domain: string, source_url: string, title: string, total: int>"
    get-episodes-in-batch: "record<episodes: table<audio: string, audio_length_sec: int, description: string, explicit_content: bool, id: string, image: string, link: string, listennotes_edit_url: string, listennotes_url: string, maybe_audio_invalid: bool, podcast: record, pub_date_ms: int, thumbnail: string, title: string>>"
    get-episode-by-id: "record<audio: string, audio_length_sec: int, description: string, explicit_content: bool, id: string, image: string, link: string, listennotes_edit_url: string, listennotes_url: string, maybe_audio_invalid: bool, podcast: record<audio_length_sec: int, country: string, description: string, earliest_pub_date_ms: int, email: string, explicit_content: bool, extra: record<amazon_music_url: string, facebook_handle: string, google_url: string, instagram_handle: string, linkedin_url: string, patreon_handle: string, spotify_url: string, twitter_handle: string, url1: string, url2: string, url3: string, wechat_handle: string, youtube_url: string>, genre_ids: list<int>, id: string, image: string, is_claimed: bool, itunes_id: int, language: string, latest_episode_id: string, latest_pub_date_ms: int, listen_score: int, listen_score_global_rank: string, listennotes_url: string, looking_for: record<cohosts: bool, cross_promotion: bool, guests: bool, sponsors: bool>, publisher: string, rss: string, thumbnail: string, title: string, total_episodes: int, type: string, update_frequency_hours: int, website: string>, pub_date_ms: int, thumbnail: string, title: string, transcript: string>"
    get-episode-recommendations: "record<recommendations: table<audio: string, audio_length_sec: int, description: string, explicit_content: bool, id: string, image: string, link: string, listennotes_edit_url: string, listennotes_url: string, maybe_audio_invalid: bool, podcast: record, pub_date_ms: int, thumbnail: string, title: string>>"
    get-genres: "record<genres: table<id: int, name: string, parent_id: int>>"
    just-listen: "record<audio: string, audio_length_sec: int, description: string, explicit_content: bool, id: string, image: string, link: string, listennotes_edit_url: string, listennotes_url: string, maybe_audio_invalid: bool, podcast: record<id: string, image: string, listen_score: int, listen_score_global_rank: string, listennotes_url: string, publisher: string, thumbnail: string, title: string>, pub_date_ms: int, thumbnail: string, title: string>"
    get-languages: "record<languages: list<string>>"
    get-playlists: "record<has_next: bool, has_previous: bool, next_page_number: int, page_number: int, playlists: table<description: string, episode_count: int, id: string, image: string, last_timestamp_ms: int, listennotes_url: string, name: string, podcast_count: int, thumbnail: string, total_audio_length_sec: int, visibility: string>, previous_page_number: int, total: int>"
    get-playlist-by-id: "record<description: string, id: string, image: string, items: table<added_at_ms: int, data: any, id: int, notes: string, type: string>, last_timestamp_ms: int, listennotes_url: string, name: string, thumbnail: string, total: int, total_audio_length_sec: int, type: string, visibility: string>"
    get-podcasts-in-batch: "record<latest_episodes: table<audio: string, audio_length_sec: int, description: string, explicit_content: bool, id: string, image: string, link: string, listennotes_edit_url: string, listennotes_url: string, maybe_audio_invalid: bool, podcast: record, pub_date_ms: int, thumbnail: string, title: string>, podcasts: table<audio_length_sec: int, country: string, description: string, earliest_pub_date_ms: int, email: string, explicit_content: bool, extra: record, genre_ids: list, id: string, image: string, is_claimed: bool, itunes_id: int, language: string, latest_episode_id: string, latest_pub_date_ms: int, listen_score: int, listen_score_global_rank: string, listennotes_url: string, looking_for: record, publisher: string, rss: string, thumbnail: string, title: string, total_episodes: int, type: string, update_frequency_hours: int, website: string>>"
    submit-podcast: "record<podcast: record<id: string, image: string, listen_score: int, listen_score_global_rank: string, listennotes_url: string, publisher: string, thumbnail: string, title: string>, status: string>"
    delete-podcast-by-id: "record<status: string>"
    get-podcast-by-id: "record<audio_length_sec: int, country: string, description: string, earliest_pub_date_ms: int, email: string, episodes: table<audio: string, audio_length_sec: int, description: string, explicit_content: bool, id: string, image: string, link: string, listennotes_edit_url: string, listennotes_url: string, maybe_audio_invalid: bool, pub_date_ms: int, thumbnail: string, title: string>, explicit_content: bool, extra: record<amazon_music_url: string, facebook_handle: string, google_url: string, instagram_handle: string, linkedin_url: string, patreon_handle: string, spotify_url: string, twitter_handle: string, url1: string, url2: string, url3: string, wechat_handle: string, youtube_url: string>, genre_ids: list<int>, id: string, image: string, is_claimed: bool, itunes_id: int, language: string, latest_episode_id: string, latest_pub_date_ms: int, listen_score: int, listen_score_global_rank: string, listennotes_url: string, looking_for: record<cohosts: bool, cross_promotion: bool, guests: bool, sponsors: bool>, next_episode_pub_date: int, publisher: string, rss: string, thumbnail: string, title: string, total_episodes: int, type: string, update_frequency_hours: int, website: string>"
    get-podcast-audience: "record<by_regions: table<ratio: string, region: string>>"
    get-podcast-recommendations: "record<recommendations: table<audio_length_sec: int, country: string, description: string, earliest_pub_date_ms: int, email: string, explicit_content: bool, extra: record, genre_ids: list, id: string, image: string, is_claimed: bool, itunes_id: int, language: string, latest_episode_id: string, latest_pub_date_ms: int, listen_score: int, listen_score_global_rank: string, listennotes_url: string, looking_for: record, publisher: string, rss: string, thumbnail: string, title: string, total_episodes: int, type: string, update_frequency_hours: int, website: string>>"
    get-regions: "record<regions: record>"
    get-related-searches: "record<terms: list<string>>"
    search: "record<count: int, next_offset: int, results: list<any>, took: float, total: int>"
    spellcheck: "record<corrected_text_html: string, tokens: table<offset: int, suggestion: string, token: string>>"
    get-trending-searches: "record<terms: list<string>>"
    typeahead: "record<genres: table<id: int, name: string, parent_id: int>, podcasts: table<explicit_content: bool, id: string, image: string, publisher_highlighted: string, publisher_original: string, thumbnail: string, title_highlighted: string, title_original: string>, terms: list<string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-best-podcasts" "get-curated-podcasts" "get-curated-podcast-by-id" "get-episodes-in-batch" "get-episode-by-id" "get-episode-recommendations" "get-genres" "just-listen" "get-languages" "get-playlists" "get-playlist-by-id" "get-podcasts-in-batch" "submit-podcast" "delete-podcast-by-id" "get-podcast-by-id" "get-podcast-audience" "get-podcast-recommendations" "get-regions" "get-related-searches" "search" "spellcheck" "get-trending-searches" "typeahead" "commands"] | sort) } | get name | first)
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

# Fetch a list of best podcasts by genre
#
# GET /best_podcasts
# Returns: record<has_next: bool, has_previous: bool, id: int, listennotes_url: string, name: string, next_page_number: int, page_number: int, parent_id: int, podcasts: table<audio_length_sec: int, country: string, description: string, earliest_pub_date_ms: int, email: string, explicit_content: bool, extra: record, genre_ids: list, id: string, image: string, is_claimed: bool, itunes_id: int, language: string, latest_episode_id: string, latest_pub_date_ms: int, listen_score: int, listen_score_global_rank: string, listennotes_url: string, looking_for: record, publisher: string, rss: string, thumbnail: string, title: string, total_episodes: int, type: string, update_frequency_hours: int, website: string>, previous_page_number: int, total: int>
# operationId: getBestPodcasts
export def "get-best-podcasts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --genre-id: string # You can get the id from `GET /genres`. If not specified, it'll be the overall best podcasts, which can be considered as a special genre.
  --page: int # Page number of those podcasts in this genre.
  --region: string # Filter best podcasts by country/region. Please note that podcasts that are "best" in a country/region may not be produced in that country/region. For example, a podcast from the US may be very popular in Canada. You can get the supported country codes (e.g., us, jp, gb...) from `GET /regions`. If not specified, you'll get "best podcasts" in United States. (default: us)
  --publisher-region: string # Filter best podcasts by the publisher's country/region. This is to narrow down the results to include "best podcasts" produced in a specific country/region. You can get the supported country codes (e.g., us, jp, gb...) from `GET /regions`. If not specified, you'll get "best podcasts" produced in any country/region. If you want to get a country/region's "best podcasts" that are also produced in that country/region, then you need to specify both **region** and **publisher_region**, e.g., `region=jp` and `publisher_region=jp`.
  --language: string # Filter best podcasts by language. You can get a list of supported languages (e.g., English, Chinese, Japanese...) from `GET /languages`. If not specified, you'll get "best podcasts" in any language.
  --sort: string@sort-completer # How do you want to sort these podcasts? If you'd like to sort by popularity, please use **listen_score**. (default: recent_added_first, e.g. listen_score)
  --safe-mode: int@safe-mode-completer # Whether or not to exclude podcasts with explicit language. 1 is yes, and 0 is no. (default: 0)
  --x-listen-api-key: string # Get API Key on listennotes.com/api (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/best_podcasts"
    query: [{name: genre_id, var: genre_id}, {name: page, var: page}, {name: region, var: region}, {name: publisher_region, var: publisher_region}, {name: language, var: language}, {name: sort, var: sort}, {name: safe_mode, var: safe_mode}]
    header: [{name: X-ListenAPI-Key, var: x_listen_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    genre_id: $genre_id, page: $page, region: $region, publisher_region: $publisher_region, language: $language, sort: $sort, safe_mode: $safe_mode, x_listen_api_key: $x_listen_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch curated lists of podcasts
#
# GET /curated_podcasts
# Returns: record<curated_lists: table<description: string, id: string, listennotes_url: string, podcasts: list, pub_date_ms: int, source_domain: string, source_url: string, title: string, total: int>, has_next: bool, has_previous: bool, next_page_number: int, page_number: int, previous_page_number: int, total: int>
# operationId: getCuratedPodcasts
export def "get-curated-podcasts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of curated lists. (default: 1, e.g. 2)
  --x-listen-api-key: string # Get API Key on listennotes.com/api (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/curated_podcasts"
    query: [{name: page, var: page}]
    header: [{name: X-ListenAPI-Key, var: x_listen_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, x_listen_api_key: $x_listen_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a curated list of podcasts by id
#
# GET /curated_podcasts/{id}
# Returns: record<description: string, id: string, listennotes_url: string, podcasts: table<audio_length_sec: int, country: string, description: string, earliest_pub_date_ms: int, email: string, explicit_content: bool, extra: record, genre_ids: list, id: string, image: string, is_claimed: bool, itunes_id: int, language: string, latest_episode_id: string, latest_pub_date_ms: int, listen_score: int, listen_score_global_rank: string, listennotes_url: string, looking_for: record, publisher: string, rss: string, thumbnail: string, title: string, total_episodes: int, type: string, update_frequency_hours: int, website: string>, pub_date_ms: int, source_domain: string, source_url: string, title: string, total: int>
# operationId: getCuratedPodcastById
export def "get-curated-podcast-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-listen-api-key: string # Get API Key on listennotes.com/api (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/curated_podcasts/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: X-ListenAPI-Key, var: x_listen_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, x_listen_api_key: $x_listen_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Batch fetch basic meta data for episodes
#
# POST /episodes
# Returns: record<episodes: table<audio: string, audio_length_sec: int, description: string, explicit_content: bool, id: string, image: string, link: string, listennotes_edit_url: string, listennotes_url: string, maybe_audio_invalid: bool, podcast: record, pub_date_ms: int, thumbnail: string, title: string>>
# operationId: getEpisodesInBatch
export def "get-episodes-in-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-listen-api-key: string # Get API Key on listennotes.com/api (required)
  ids: string # Comma-separated list of episode ids.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/episodes"
    header: [{name: X-ListenAPI-Key, var: x_listen_api_key, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: ids, var: ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_listen_api_key: $x_listen_api_key, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch detailed meta data for an episode by id
#
# GET /episodes/{id}
# Returns: record<audio: string, audio_length_sec: int, description: string, explicit_content: bool, id: string, image: string, link: string, listennotes_edit_url: string, listennotes_url: string, maybe_audio_invalid: bool, podcast: record<audio_length_sec: int, country: string, description: string, earliest_pub_date_ms: int, email: string, explicit_content: bool, extra: record<amazon_music_url: string, facebook_handle: string, google_url: string, instagram_handle: string, linkedin_url: string, patreon_handle: string, spotify_url: string, twitter_handle: string, url1: string, url2: string, url3: string, wechat_handle: string, youtube_url: string>, genre_ids: list<int>, id: string, image: string, is_claimed: bool, itunes_id: int, language: string, latest_episode_id: string, latest_pub_date_ms: int, listen_score: int, listen_score_global_rank: string, listennotes_url: string, looking_for: record<cohosts: bool, cross_promotion: bool, guests: bool, sponsors: bool>, publisher: string, rss: string, thumbnail: string, title: string, total_episodes: int, type: string, update_frequency_hours: int, website: string>, pub_date_ms: int, thumbnail: string, title: string, transcript: string>
# operationId: getEpisodeById
export def "get-episode-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --show-transcript: int # To include the transcript of this episode or not? If it is 1, then include the transcript in the **transcript** field. The default value is 0 - we don't include transcript by default, because 1) it would make the response data very big, thus slow response time; 2) less than 1% of episodes have transcripts. The transcript field is available only in the PRO/ENTERPRISE plan. (default: 0)
  --x-listen-api-key: string # Get API Key on listennotes.com/api (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/episodes/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: show_transcript, var: show_transcript}]
    header: [{name: X-ListenAPI-Key, var: x_listen_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, show_transcript: $show_transcript, x_listen_api_key: $x_listen_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch recommendations for an episode
#
# GET /episodes/{id}/recommendations
# Returns: record<recommendations: table<audio: string, audio_length_sec: int, description: string, explicit_content: bool, id: string, image: string, link: string, listennotes_edit_url: string, listennotes_url: string, maybe_audio_invalid: bool, podcast: record, pub_date_ms: int, thumbnail: string, title: string>>
# operationId: getEpisodeRecommendations
export def "get-episode-recommendations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --safe-mode: int@safe-mode-completer # Whether or not to exclude podcasts with explicit language. 1 is yes, and 0 is no. (default: 0)
  --x-listen-api-key: string # Get API Key on listennotes.com/api (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/episodes/{id}/recommendations"
    path_params: [{name: id, var: id}]
    query: [{name: safe_mode, var: safe_mode}]
    header: [{name: X-ListenAPI-Key, var: x_listen_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, safe_mode: $safe_mode, x_listen_api_key: $x_listen_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a list of podcast genres
#
# GET /genres
# Returns: record<genres: table<id: int, name: string, parent_id: int>>
# operationId: getGenres
export def "get-genres" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --top-level-only: int@top-level-only-completer # Just show top level genres? If 1, yes, just show top level genres. If 0, no, show all genres. (default: 0)
  --x-listen-api-key: string # Get API Key on listennotes.com/api (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/genres"
    query: [{name: top_level_only, var: top_level_only}]
    header: [{name: X-ListenAPI-Key, var: x_listen_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    top_level_only: $top_level_only, x_listen_api_key: $x_listen_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a random podcast episode
#
# GET /just_listen
# Returns: record<audio: string, audio_length_sec: int, description: string, explicit_content: bool, id: string, image: string, link: string, listennotes_edit_url: string, listennotes_url: string, maybe_audio_invalid: bool, podcast: record<id: string, image: string, listen_score: int, listen_score_global_rank: string, listennotes_url: string, publisher: string, thumbnail: string, title: string>, pub_date_ms: int, thumbnail: string, title: string>
# operationId: justListen
export def "just-listen" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-listen-api-key: string # Get API Key on listennotes.com/api (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/just_listen"
    header: [{name: X-ListenAPI-Key, var: x_listen_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_listen_api_key: $x_listen_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a list of supported languages for podcasts
#
# GET /languages
# Returns: record<languages: list<string>>
# operationId: getLanguages
export def "get-languages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-listen-api-key: string # Get API Key on listennotes.com/api (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/languages"
    header: [{name: X-ListenAPI-Key, var: x_listen_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_listen_api_key: $x_listen_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a list of your playlists.
#
# GET /playlists
# Returns: record<has_next: bool, has_previous: bool, next_page_number: int, page_number: int, playlists: table<description: string, episode_count: int, id: string, image: string, last_timestamp_ms: int, listennotes_url: string, name: string, podcast_count: int, thumbnail: string, total_audio_length_sec: int, visibility: string>, previous_page_number: int, total: int>
# operationId: getPlaylists
export def "get-playlists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort: string@sort-completer-1 # How do you want to sort playlists? (default: recent_added_first)
  --page: int # Page number of playlists. (default: 1)
  --x-listen-api-key: string # Get API Key on listennotes.com/api (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/playlists"
    query: [{name: sort, var: sort}, {name: page, var: page}]
    header: [{name: X-ListenAPI-Key, var: x_listen_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sort: $sort, page: $page, x_listen_api_key: $x_listen_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a playlist's info and items (i.e., episodes or podcasts).
#
# GET /playlists/{id}
# Returns: record<description: string, id: string, image: string, items: table<added_at_ms: int, data: any, id: int, notes: string, type: string>, last_timestamp_ms: int, listennotes_url: string, name: string, thumbnail: string, total: int, total_audio_length_sec: int, type: string, visibility: string>
# operationId: getPlaylistById
export def "get-playlist-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer # The type of this playlist, which should be either **episode_list** or **podcast_list**. (default: episode_list)
  --last-timestamp-ms: int # For playlist items pagination. It's the value of **last_timestamp_ms** from the response of last request. If it's 0 or not specified, just return the latest or the oldest 20 items, depending on the value of the **sort** parameter. (default: 0)
  --sort: string@sort-completer-2 # How do you want to sort playlist items? (default: recent_added_first)
  --x-listen-api-key: string # Get API Key on listennotes.com/api (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/playlists/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: type, var: type}, {name: last_timestamp_ms, var: last_timestamp_ms}, {name: sort, var: sort}]
    header: [{name: X-ListenAPI-Key, var: x_listen_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, type: $type, last_timestamp_ms: $last_timestamp_ms, sort: $sort, x_listen_api_key: $x_listen_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Batch fetch basic meta data for podcasts
#
# POST /podcasts
# Returns: record<latest_episodes: table<audio: string, audio_length_sec: int, description: string, explicit_content: bool, id: string, image: string, link: string, listennotes_edit_url: string, listennotes_url: string, maybe_audio_invalid: bool, podcast: record, pub_date_ms: int, thumbnail: string, title: string>, podcasts: table<audio_length_sec: int, country: string, description: string, earliest_pub_date_ms: int, email: string, explicit_content: bool, extra: record, genre_ids: list, id: string, image: string, is_claimed: bool, itunes_id: int, language: string, latest_episode_id: string, latest_pub_date_ms: int, listen_score: int, listen_score_global_rank: string, listennotes_url: string, looking_for: record, publisher: string, rss: string, thumbnail: string, title: string, total_episodes: int, type: string, update_frequency_hours: int, website: string>>
# operationId: getPodcastsInBatch
export def "get-podcasts-in-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-listen-api-key: string # Get API Key on listennotes.com/api (required)
  --ids: string # Comma-separated list of podcast ids.
  --itunes-ids: string # Comma-separated Apple Podcasts (iTunes) ids, e.g., 659155419
  --next-episode-pub-date: int # For latest episodes pagination. It's the value of **next_episode_pub_date** from the response of last request. If not specified, just return latest 15 episodes.
  --rsses: string # Comma-separated rss urls.
  --show-latest-episodes: int@show-latest-episodes-completer # Whether or not to fetch up to 15 latest episodes from these podcasts, sorted by pub_date. 1 is yes, and 0 is no. (default: 0)
  --spotify-ids: string # Comma-separated Spotify ids, e.g., 3DDfEsKDIDrTlnPOiG4ZF4
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/podcasts"
    header: [{name: X-ListenAPI-Key, var: x_listen_api_key, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: ids, var: ids}, {name: itunes_ids, var: itunes_ids}, {name: next_episode_pub_date, var: next_episode_pub_date}, {name: rsses, var: rsses}, {name: show_latest_episodes, var: show_latest_episodes}, {name: spotify_ids, var: spotify_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_listen_api_key: $x_listen_api_key, ids: $ids, itunes_ids: $itunes_ids, next_episode_pub_date: $next_episode_pub_date, rsses: $rsses, show_latest_episodes: $show_latest_episodes, spotify_ids: $spotify_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit a podcast to Listen Notes database
#
# POST /podcasts/submit
# Returns: record<podcast: record<id: string, image: string, listen_score: int, listen_score_global_rank: string, listennotes_url: string, publisher: string, thumbnail: string, title: string>, status: string>
# operationId: submitPodcast
export def "submit-podcast" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-listen-api-key: string # Get API Key on listennotes.com/api (required)
  --email: string # A valid email address. If **email** is specified, then we'll notify this email address once the podcast is accepted.
  rss: string # A valid podcast rss url.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/podcasts/submit"
    header: [{name: X-ListenAPI-Key, var: x_listen_api_key, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: email, var: email}, {name: rss, var: rss}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_listen_api_key: $x_listen_api_key, email: $email, rss: $rss
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request to delete a podcast
#
# DELETE /podcasts/{id}
# Returns: record<status: string>
# operationId: deletePodcastById
export def "delete-podcast-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string # The reason why this podcast should be deleted, e.g., copyright violation, the podcaster wants to delete it... You can put "testing" here to indicate that you are testing this endpoint, so we will not actually delete the podcast. (e.g. the podcaster wants to delete it)
  --x-listen-api-key: string # Get API Key on listennotes.com/api (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/podcasts/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: reason, var: reason}]
    header: [{name: X-ListenAPI-Key, var: x_listen_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, reason: $reason, x_listen_api_key: $x_listen_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch detailed meta data and episodes for a podcast by id
#
# GET /podcasts/{id}
# Returns: record<audio_length_sec: int, country: string, description: string, earliest_pub_date_ms: int, email: string, episodes: table<audio: string, audio_length_sec: int, description: string, explicit_content: bool, id: string, image: string, link: string, listennotes_edit_url: string, listennotes_url: string, maybe_audio_invalid: bool, pub_date_ms: int, thumbnail: string, title: string>, explicit_content: bool, extra: record<amazon_music_url: string, facebook_handle: string, google_url: string, instagram_handle: string, linkedin_url: string, patreon_handle: string, spotify_url: string, twitter_handle: string, url1: string, url2: string, url3: string, wechat_handle: string, youtube_url: string>, genre_ids: list<int>, id: string, image: string, is_claimed: bool, itunes_id: int, language: string, latest_episode_id: string, latest_pub_date_ms: int, listen_score: int, listen_score_global_rank: string, listennotes_url: string, looking_for: record<cohosts: bool, cross_promotion: bool, guests: bool, sponsors: bool>, next_episode_pub_date: int, publisher: string, rss: string, thumbnail: string, title: string, total_episodes: int, type: string, update_frequency_hours: int, website: string>
# operationId: getPodcastById
export def "get-podcast-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-episode-pub-date: int # For episodes pagination. It's the value of **next_episode_pub_date** from the response of last request. If not specified, just return latest 10 episodes or oldest 10 episodes, depending on the value of the **sort** parameter. (e.g. 1479154463000)
  --sort: string@sort-completer-3 # How do you want to sort the episodes of this podcast? (default: recent_first, e.g. recent_first)
  --x-listen-api-key: string # Get API Key on listennotes.com/api (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/podcasts/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: next_episode_pub_date, var: next_episode_pub_date}, {name: sort, var: sort}]
    header: [{name: X-ListenAPI-Key, var: x_listen_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, next_episode_pub_date: $next_episode_pub_date, sort: $sort, x_listen_api_key: $x_listen_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch audience demographics for a podcast
#
# GET /podcasts/{id}/audience
# Returns: record<by_regions: table<ratio: string, region: string>>
# operationId: getPodcastAudience
export def "get-podcast-audience" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-listen-api-key: string # Get API Key on listennotes.com/api (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/podcasts/{id}/audience"
    path_params: [{name: id, var: id}]
    header: [{name: X-ListenAPI-Key, var: x_listen_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, x_listen_api_key: $x_listen_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch recommendations for a podcast
#
# GET /podcasts/{id}/recommendations
# Returns: record<recommendations: table<audio_length_sec: int, country: string, description: string, earliest_pub_date_ms: int, email: string, explicit_content: bool, extra: record, genre_ids: list, id: string, image: string, is_claimed: bool, itunes_id: int, language: string, latest_episode_id: string, latest_pub_date_ms: int, listen_score: int, listen_score_global_rank: string, listennotes_url: string, looking_for: record, publisher: string, rss: string, thumbnail: string, title: string, total_episodes: int, type: string, update_frequency_hours: int, website: string>>
# operationId: getPodcastRecommendations
export def "get-podcast-recommendations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --safe-mode: int@safe-mode-completer # Whether or not to exclude podcasts with explicit language. 1 is yes, and 0 is no. (default: 0)
  --x-listen-api-key: string # Get API Key on listennotes.com/api (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/podcasts/{id}/recommendations"
    path_params: [{name: id, var: id}]
    query: [{name: safe_mode, var: safe_mode}]
    header: [{name: X-ListenAPI-Key, var: x_listen_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, safe_mode: $safe_mode, x_listen_api_key: $x_listen_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a list of supported countries/regions for best podcasts
#
# GET /regions
# Returns: record<regions: record>
# operationId: getRegions
export def "get-regions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-listen-api-key: string # Get API Key on listennotes.com/api (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/regions"
    header: [{name: X-ListenAPI-Key, var: x_listen_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_listen_api_key: $x_listen_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch related search terms
#
# GET /related_searches
# Returns: record<terms: list<string>>
# operationId: getRelatedSearches
export def "get-related-searches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Search term, e.g., person, place, topic... (required)
  --x-listen-api-key: string # Get API Key on listennotes.com/api (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/related_searches"
    query: [{name: q, var: q, required: true}]
    header: [{name: X-ListenAPI-Key, var: x_listen_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, x_listen_api_key: $x_listen_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Full-text search
#
# GET /search
# Returns: record<count: int, next_offset: int, results: list<any>, took: float, total: int>
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
  --q: string # Search term, e.g., person, place, topic... You can use double quotes to do verbatim match, e.g., "game of thrones". Otherwise, it's fuzzy search. (required)
  --sort-by-date: int@sort-by-date-completer # Sort by date or not? If 0, then sort by relevance. If 1, then sort by date. (default: 0)
  --type: string@type-completer-1 # What type of contents do you want to search for? (default: episode)
  --offset: int # Offset for search results, for pagination. You'll use **next_offset** from response for this parameter. (default: 0)
  --len-min: int # Minimum audio length in minutes. Applicable only when **type** parameter is **episode** or **podcast**. If **type** parameter is **episode**, it's for audio length of an episode. If **type** parameter is **podcast**, it's for average audio length of all episodes in a podcast. (default: 0)
  --len-max: int # Maximum audio length in minutes. Applicable only when **type** parameter is **episode** or **podcast**. If **type** parameter is **episode**, it's for audio length of an episode. If **type** parameter is **podcast**, it's for average audio length of all episodes in a podcast.
  --episode-count-min: int # Minimum number of episodes. Applicable only when type parameter is **podcast**.
  --episode-count-max: int # Maximum number of episodes. Applicable only when type parameter is **podcast**.
  --update-freq-min: int # Minimum update frequency in hours (how frequently does a podcast release a new episode). For example, if you want to find "weekly" podcasts, then you can set **update_freq_min**=144 hours (or 6 days) and **update_freq_max**=192 hours (or 8 days). Applicable only when type parameter is **podcast**.
  --update-freq-max: int # Maximum update frequency in hours (how frequently does a podcast release a new episode). For example, if you want to find "weekly" podcasts, then you can set **update_freq_min**=144 hours (or 6 days) and **update_freq_max**=192 hours (or 8 days). Applicable only when type parameter is **podcast**.
  --genre-ids: string # A comma-delimited string of a list of genre ids. If not specified, then all genres are included. You can find the id and the name of all genres from `GET /genres`. It works only when **type** is *episode* or *podcast*.
  --published-before: int # Only show episodes/podcasts/curated lists published before this timestamp (in milliseconds). If **published_before** & **published_after** are used at the same time, **published_before** should be bigger than **published_after**.
  --published-after: int # Only show episodes/podcasts/curated lists published after this timestamp (in milliseconds). If **published_before** & **published_after** are used at the same time, **published_before** should be bigger than **published_after**. (default: 0)
  --only-in: string # A comma-delimited string to search only in specific fields. Allowed values are title, description, author, and audio. If not specified, then search every fields. (default: title,description,author,audio)
  --language: string # Limit search results to a specific language. If not specified, it'll be any language. You can get a list of supported languages from `GET /languages`. It works only when **type** is *episode* or *podcast*.
  --region: string # Limit search results to a specific region (e.g., us, gb, in...). If not specified, it'll be any region. You can get the supported country codes from `GET /regions`. It works only when **type** is *episode* or *podcast*.
  --ocid: string # A comma-delimited string of podcast ids (up to 5 podcasts) - you can get a podcast id from the **podcast_id** field in response. This parameter is to limit search results from only a few specific podcasts. It works only when **type** is *episode*.
  --ncid: string # A comma-delimited string of podcast ids (up to 5 podcasts) - you can get a podcast id from the **podcast_id** field in response. This parameter is to exclude search results of a few specific podcasts. It works only when **type** is *episode*.
  --safe-mode: int@safe-mode-completer # Whether or not to exclude podcasts/episodes with explicit language. 1 is yes and 0 is no. It works only when **type** is *episode* or *podcast*. (default: 0)
  --unique-podcasts: int@unique-podcasts-completer # Whether or not to keep only one episode per podcast in search results. 1 is yes and 0 is no. It works only when **type** is *episode*. (default: 0)
  --x-listen-api-key: string # Get API Key on listennotes.com/api (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search"
    query: [{name: q, var: q, required: true}, {name: sort_by_date, var: sort_by_date}, {name: type, var: type}, {name: offset, var: offset}, {name: len_min, var: len_min}, {name: len_max, var: len_max}, {name: episode_count_min, var: episode_count_min}, {name: episode_count_max, var: episode_count_max}, {name: update_freq_min, var: update_freq_min}, {name: update_freq_max, var: update_freq_max}, {name: genre_ids, var: genre_ids}, {name: published_before, var: published_before}, {name: published_after, var: published_after}, {name: only_in, var: only_in}, {name: language, var: language}, {name: region, var: region}, {name: ocid, var: ocid}, {name: ncid, var: ncid}, {name: safe_mode, var: safe_mode}, {name: unique_podcasts, var: unique_podcasts}]
    header: [{name: X-ListenAPI-Key, var: x_listen_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, sort_by_date: $sort_by_date, type: $type, offset: $offset, len_min: $len_min, len_max: $len_max, episode_count_min: $episode_count_min, episode_count_max: $episode_count_max, update_freq_min: $update_freq_min, update_freq_max: $update_freq_max, genre_ids: $genre_ids, published_before: $published_before, published_after: $published_after, only_in: $only_in, language: $language, region: $region, ocid: $ocid, ncid: $ncid, safe_mode: $safe_mode, unique_podcasts: $unique_podcasts, x_listen_api_key: $x_listen_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Spell check on a search term
#
# GET /spellcheck
# Returns: record<corrected_text_html: string, tokens: table<offset: int, suggestion: string, token: string>>
# operationId: spellcheck
export def "spellcheck" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Search term, e.g., person, place, topic... (required)
  --x-listen-api-key: string # Get API Key on listennotes.com/api (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/spellcheck"
    query: [{name: q, var: q, required: true}]
    header: [{name: X-ListenAPI-Key, var: x_listen_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, x_listen_api_key: $x_listen_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch trending search terms
#
# GET /trending_searches
# Returns: record<terms: list<string>>
# operationId: getTrendingSearches
export def "get-trending-searches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-listen-api-key: string # Get API Key on listennotes.com/api (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/trending_searches"
    header: [{name: X-ListenAPI-Key, var: x_listen_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_listen_api_key: $x_listen_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Typeahead search
#
# GET /typeahead
# Returns: record<genres: table<id: int, name: string, parent_id: int>, podcasts: table<explicit_content: bool, id: string, image: string, publisher_highlighted: string, publisher_original: string, thumbnail: string, title_highlighted: string, title_original: string>, terms: list<string>>
# operationId: typeahead
export def "typeahead" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Search term, e.g., person, place, topic... You can use double quotes to do verbatim match, e.g., "game of thrones". Otherwise, it's fuzzy search. (required)
  --show-podcasts: int@show-podcasts-completer # Autosuggest podcasts. This only searches podcast title and publisher and returns very limited info of 5 podcasts. 1 is yes, 0 is no. It's a bit slow to autosuggest podcasts, so we turn it off by default. If show_podcasts=1, you can also pass iTunes id (e.g., 474722933) to the q parameter to fetch podcast meta data. (default: 0)
  --show-genres: int@show-genres-completer # Whether or not to autosuggest genres. 1 is yes, 0 is no. (default: 0)
  --safe-mode: int@safe-mode-completer # Whether or not to exclude podcasts/episodes with explicit language. 1 is yes and 0 is no. It works only when **show_podcasts** is *1*. (default: 0)
  --x-listen-api-key: string # Get API Key on listennotes.com/api (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/typeahead"
    query: [{name: q, var: q, required: true}, {name: show_podcasts, var: show_podcasts}, {name: show_genres, var: show_genres}, {name: safe_mode, var: safe_mode}]
    header: [{name: X-ListenAPI-Key, var: x_listen_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, show_podcasts: $show_podcasts, show_genres: $show_genres, safe_mode: $safe_mode, x_listen_api_key: $x_listen_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
