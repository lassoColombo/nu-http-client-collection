# Auto-generated client for Radio & Music Services v1.0.0
# Source: https://api.apis.guru/v2/specs/bbc.co.uk/1.0.0/swagger.json
# Auth: --token flag or $env.RADIO_MUSIC_SERVICES_TOKEN

const CLIENT = {
  base_url: "https://rms.api.bbc.co.uk"
  token_env_var: "RADIO_MUSIC_SERVICES_TOKEN"
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

def base-url-completer [] { ["https://rms.api.bbc.co.uk"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sort-completer [] { ["-end_at" "-start_at" "end_at" "start_at"] }
def on-air-completer [] { ["next" "now" "previous"] }
def kind-completer [] { ["promoted"] }
def platform-completer [] { ["app" "responsiveweb"] }
def vendor-completer [] { ["deezer" "itunes" "spotify" "youtube"] }
def status-completer [] { ["done" "failed" "pending"] }
def action-completer [] { ["favourited" "unfavourited"] }
def type-completer [] { ["clips" "tracks"] }
def action-completer-1 [] { ["followed" "unfollowed"] }
def music-context-completer [] { ["events" "ivote" "music" "musicplaylist" "programmes" "radio" "unknown"] }
def type-completer-1 [] { ["artists" "categories" "genres" "networks" "playlists" "services"] }
def action-completer-2 [] { ["ended" "heartbeat" "paused" "started"] }
def resource-type-completer [] { ["clip" "episode"] }
def rights-completer [] { ["mobile" "web"] }
def sort-completer-1 [] { ["available_from_date" "available_to_date" "programme_titles"] }
def type-completer-2 [] { ["clips" "episodes"] }
def type-completer-3 [] { ["brands" "series"] }
def sort-completer-2 [] { ["-available_from_date" "-title" "available_from_date" "title"] }
def coverage-completer [] { ["local" "national" "regional"] }
def type-completer-4 [] { ["clip" "episode" "episode,clip"] }
def distinct-completer [] { ["tleo"] }
def group-completer [] { ["radio" "tv" "tv,radio"] }
def media-type-completer [] { ["audio" "audio,video" "video"] }
def media-set-completer [] { ["android-download-high" "apple-ios-download-high" "iptv-all" "mobile-cellular-main" "mobile-download" "mobile-phone-main" "pc"] }
def kind-completer-1 [] { ["tleo"] }
def type-completer-5 [] { ["brand" "clip" "episode" "episode,clip" "series"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-broadcasts: "record<\"$schema\": string, limit: int, offset: int, results: table<duration: int, end: string, is_audio_described: bool, is_blanked: bool, is_critical: bool, is_live: bool, is_repeat: bool, is_webcast: bool, pid: string, programme: record, service_id: string, start: string, type: string, version_pid: string>, total: int>"
    get-broadcasts-latest: "record<\"$schema\": string, limit: int, offset: int, results: table<duration: int, end: string, is_audio_described: bool, is_blanked: bool, is_critical: bool, is_live: bool, is_repeat: bool, is_webcast: bool, pid: string, programme: record, service_id: string, start: string, type: string, version_pid: string>, total: int>"
    get-broadcast-by-pid: "record<\"$schema\": string, limit: int, offset: int, results: table<duration: int, end: string, is_audio_described: bool, is_blanked: bool, is_critical: bool, is_live: bool, is_repeat: bool, is_webcast: bool, pid: string, programme: record, service_id: string, start: string, type: string, version_pid: string>, total: int>"
    get-categories: "record<\"$schema\": string, limit: int, offset: int, results: table<category_type: string, child_categories: list, depth: int, id: string, pip_id: string, title: string, type: string, url_key: string>, total: int>"
    get-categories-id: "record<\"$schema\": string, limit: int, offset: int, results: table<category_type: string, child_categories: list, depth: int, id: string, pip_id: string, title: string, type: string, url_key: string>, total: int>"
    get-collection-members: "record<\"$schema\": string, limit: int, offset: int, results: table<pid: string, type: string>, total: int>"
    get-experience-homepage: "record<\"$schema\": string, data: table<description: string, title: string, type: string, uri: string>>"
    get-music-popular-artists: "record<limit: int, method: string, offset: int, repliedAt: string, results: table<gid: string, id: string, imagePid: string, name: string, score: int, sortName: string>, schema: string, total: int>"
    get-music-popular-artist-by-id: "record<limit: int, method: string, offset: int, repliedAt: string, results: table<gid: string, id: string, imagePid: string, name: string, score: int, sortName: string>, schema: string, total: int>"
    get-music-popular-playlists: "record<limit: int, method: string, offset: int, repliedAt: string, results: table<categories: list, commentsEnabled: bool, description: string, externalPartners: list, genre: string, id: string, imagePid: string, imageUrl: string, kind: string, mood: string, oneOff: bool, playlistPlaybackType: string, score: int, serviceId: string, title: string, updatedAt: string, visibility: string, wideImagePid: string, wideImageUrl: string>, schema: string, total: int>"
    get-music-popular-playlist-by-id: "record<limit: int, method: string, offset: int, repliedAt: string, results: table<categories: list, commentsEnabled: bool, description: string, externalPartners: list, genre: string, id: string, imagePid: string, imageUrl: string, kind: string, mood: string, oneOff: bool, playlistPlaybackType: string, score: int, serviceId: string, title: string, updatedAt: string, visibility: string, wideImagePid: string, wideImageUrl: string>, schema: string, total: int>"
    get-music-popular-tracks: "record<limit: int, method: string, offset: int, repliedAt: string, results: table<album: string, artistGid: string, artistName: string, artists: list, baseTitle: string, classical: bool, id: string, mergedIds: list, preferredMultiplayRecordAudio: record, preferredRecordAudio: record, radioEdit: bool, recordAudio: list, recordImageHref: string, recordImagePid: string, score: int, title: string, type: string>, schema: string, total: int>"
    get-music-popular-track-by-id: "record<limit: int, method: string, offset: int, repliedAt: string, results: table<album: string, artistGid: string, artistName: string, artists: list, baseTitle: string, classical: bool, id: string, mergedIds: list, preferredMultiplayRecordAudio: record, preferredRecordAudio: record, radioEdit: bool, recordAudio: list, recordImageHref: string, recordImagePid: string, score: int, title: string, type: string>, schema: string, total: int>"
    get-my-categories-follows: "record<\"$schema\": string, limit: int, offset: int, total: int>"
    get-music-export: "record<created_at: string, id: string, job_id: string, status: string, vendor: string>"
    get-music-export-jobs: "record<created_at: string, id: string, job_id: string, status: string, vendor: string>"
    post-music-export-job: "record<method: string, replied_at: string, schema: string>"
    get-music-export-tracks: "record<created_at: string, id: string, job_id: string, status: string, vendor: string>"
    get-personalised-music-favourites: "record<limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: list, domain: string, id: string, meta_data: record, type: string, urn: string>, schema: string, total: int>"
    post-personalised-music-favourites-batch: "record<limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: list, domain: string, id: string, meta_data: record, type: string, urn: string>, schema: string, total: int>"
    put-personalised-music-favourites-batch: "record<method: string, replied_at: string, schema: string>"
    get-personalised-music-favourites-by-type: "record<limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: list, domain: string, id: string, meta_data: record, type: string, urn: string>, schema: string, total: int>"
    delete-personalised-music-favourites-by-type-by-id: "record<method: string, replied_at: string, schema: string>"
    get-personalised-music-favourites-by-type-by-id: "record<limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: list, domain: string, id: string, meta_data: record, type: string, urn: string>, schema: string, total: int>"
    post-personalised-music-favourites-by-type-by-id: "record<limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: list, domain: string, id: string, meta_data: record, type: string, urn: string>, schema: string, total: int>"
    put-personalised-music-favourites-by-type-by-id: "record<method: string, replied_at: string, schema: string>"
    get-personalised-music-follows: "record<limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: list, domain: string, id: string, meta_data: record, type: string, urn: string>, schema: string, total: int>"
    post-personalised-music-follows-batch: "record<method: string, replied_at: string, schema: string>"
    put-personalised-music-follows-batch: "record<method: string, replied_at: string, schema: string>"
    get-personalised-music-follows-by-type: "record<limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: list, domain: string, id: string, meta_data: record, type: string, urn: string>, schema: string, total: int>"
    delete-personalised-music-follows-by-type-by-id: "record<method: string, replied_at: string, schema: string>"
    get-personalised-music-follows-by-type-by-id: "record<limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: list, domain: string, id: string, meta_data: record, type: string, urn: string>, schema: string, total: int>"
    post-personalised-music-follows-by-type-by-id: "record<method: string, replied_at: string, schema: string>"
    put-personalised-music-follows-by-type-by-id: "record<method: string, replied_at: string, schema: string>"
    delete-music-preferences-export: "record<method: string, replied_at: string, schema: string>"
    get-music-preferences-export: "record<method: string, replied_at: string, results: table<access_expires_at: string, access_token: string, add_plus_export: bool, authorization_code: string, last_export: string, legacy_state: string, partner_id: string, refresh_token: string, terms: bool, vendor: string>, schema: string, total: int>"
    post-music-preferences-export: "record<method: string, replied_at: string, schema: string>"
    get-music-preferences-export-vendor: "record<method: string, replied_at: string, results: table<access_expires_at: string, access_token: string, add_plus_export: bool, authorization_code: string, last_export: string, legacy_state: string, partner_id: string, refresh_token: string, terms: bool, vendor: string>, schema: string, total: int>"
    get-my-networks-follows: "record<\"$schema\": string, limit: int, offset: int, results: table<created: string, type: string>, total: int>"
    suggest-container: "record<id: string, members: table<description: string, image_url: string, pid: string, title: string, type: string, version_pid: string>, title: string, type: string>"
    get-container: "record<id: string, members: table<description: string, image_url: string, pid: string, title: string, type: string, version_pid: string>, title: string, type: string>"
    get-recommendations: "record<\"$schema\": string, limit: int, offset: int, results: table<pid: string, type: string>, total: int>"
    get-personalised-radio-favourites: "record<\"$schema\": string, limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: record, domain: string, id: string, metadata: record, type: string, uas_type: string, urn: string>, total: int>"
    post-personalised-radio-batch: "record<\"$schema\": string, method: string, replied_at: string>"
    put-personalised-radio-batch: "record<\"$schema\": string, method: string, replied_at: string>"
    get-personalised-radio-favourites-by-type: "record<\"$schema\": string, limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: record, domain: string, id: string, metadata: record, type: string, uas_type: string, urn: string>, total: int>"
    delete-personalised-radio-by-activity-type-by-id: "record<\"$schema\": string, method: string, replied_at: string>"
    get-personalised-radio-by-activity-type-by-id: "record<\"$schema\": string, limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: record, domain: string, id: string, metadata: record, type: string, uas_type: string, urn: string>, total: int>"
    post-personalised-radio-by-activity-type-by-id: "record<\"$schema\": string, method: string, replied_at: string>"
    put-personalised-radio-by-activity-type-by-id: "record<\"$schema\": string, method: string, replied_at: string>"
    get-personalised-radio-follows: "record<\"$schema\": string, limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: record, domain: string, id: string, metadata: record, type: string, uas_type: string, urn: string>, total: int>"
    post-personalised-radio-follows-batch: "record<\"$schema\": string, method: string, replied_at: string>"
    put-personalised-radio-follows-batch: "record<\"$schema\": string, method: string, replied_at: string>"
    get-personalised-radio-follows-by-type: "record<\"$schema\": string, limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: record, domain: string, id: string, metadata: record, type: string, uas_type: string, urn: string>, total: int>"
    delete-personalised-radio-follows-by-type-by-id: "record<\"$schema\": string, method: string, replied_at: string>"
    get-personalised-radio-follows-by-type-by-id: "record<\"$schema\": string, limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: record, domain: string, id: string, metadata: record, type: string, uas_type: string, urn: string>, total: int>"
    post-personalised-radio-follows-by-type-by-id: "record<\"$schema\": string, method: string, replied_at: string>"
    put-personalised-radio-follows-by-type-by-id: "record<\"$schema\": string, method: string, replied_at: string>"
    get-personalised-radio-plays: "record<\"$schema\": string, limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: record, domain: string, id: string, metadata: record, type: string, uas_type: string, urn: string>, total: int>"
    get-podcasts: "record<\"$schema\": string, limit: int, offset: int, results: table<category_summaries: list, days_available: int, entity_type: string, first_published_date: string, frequency: string, images: list, latest_available_episodes: list, network_summary: record, pid: string, rss_url: string, synopses: record, territory: string, titles: record, total_available_episodes: int, type: string, updated_at: string>, total: int>"
    get-podcasts-featured: "record<\"$schema\": string, limit: float, offset: float, results: table<featured_podcasts: list, title: string, type: string>, total: float>"
    get-podcast-by-pid: "record<\"$schema\": string, limit: int, offset: int, results: table<category_summaries: list, days_available: int, entity_type: string, first_published_date: string, frequency: string, images: list, latest_available_episodes: list, network_summary: record, pid: string, rss_url: string, synopses: record, territory: string, titles: record, total_available_episodes: int, type: string, updated_at: string>, total: int>"
    get-podcast-episodes: "record<\"$schema\": string, limit: float, offset: float, results: table<asset_url: string, available_versions: list, images: list, media_type: string, network_summary: record, pid: string, release_date: string, short_synopsis: string, titles: record, type: string>, total: float>"
    get-radio-networks: "record<\"$schema\": string, limit: int, offset: int, results: table<active: bool, contacts: list, date_ranges: list, group: string, id: string, international: bool, key: string, preset: bool, promoted_category_summaries: list, services: list, short_title: string, sort: int, title: string, type: string>, total: int>"
    get-popular-episodes-clips: "record<\"$schema\": string, limit: int, offset: int, results: table<data: record, id: string, score: int, type: string>, total: int>"
    get-radio-programmes: "record<\"$schema\": string, limit: int, offset: int, results: table<pid: string, type: string>, total: int>"
    get-radio-programmes-by-pid: "record<\"$schema\": string, limit: int, offset: int, results: table<pid: string, type: string>, total: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-broadcasts" "get-broadcasts-latest" "get-broadcast-by-pid" "get-categories" "get-categories-id" "get-collection-members" "get-experience-homepage" "get-music-popular-artists" "get-music-popular-artist-by-id" "get-music-popular-playlists" "get-music-popular-playlist-by-id" "get-music-popular-tracks" "get-music-popular-track-by-id" "delete-my-categories-follows" "get-my-categories-follows" "post-my-categories-follows" "get-music-export" "get-music-export-jobs" "post-music-export-job" "get-music-export-tracks" "get-personalised-music-favourites" "post-personalised-music-favourites-batch" "put-personalised-music-favourites-batch" "get-personalised-music-favourites-by-type" "delete-personalised-music-favourites-by-type-by-id" "get-personalised-music-favourites-by-type-by-id" "post-personalised-music-favourites-by-type-by-id" "put-personalised-music-favourites-by-type-by-id" "get-personalised-music-follows" "post-personalised-music-follows-batch" "put-personalised-music-follows-batch" "get-personalised-music-follows-by-type" "delete-personalised-music-follows-by-type-by-id" "get-personalised-music-follows-by-type-by-id" "post-personalised-music-follows-by-type-by-id" "put-personalised-music-follows-by-type-by-id" "delete-music-preferences-export" "get-music-preferences-export" "post-music-preferences-export" "delete-music-preferences-export-vendor" "get-music-preferences-export-vendor" "post-music-preferences-export-vendor" "put-music-preferences-export-vendor" "delete-my-networks-follows" "get-my-networks-follows" "post-my-networks-follows" "post-my-plays" "suggest-container" "get-container" "get-recommendations" "get-personalised-radio-favourites" "post-personalised-radio-batch" "put-personalised-radio-batch" "get-personalised-radio-favourites-by-type" "delete-personalised-radio-by-activity-type-by-id" "get-personalised-radio-by-activity-type-by-id" "post-personalised-radio-by-activity-type-by-id" "put-personalised-radio-by-activity-type-by-id" "get-personalised-radio-follows" "post-personalised-radio-follows-batch" "put-personalised-radio-follows-batch" "get-personalised-radio-follows-by-type" "delete-personalised-radio-follows-by-type-by-id" "get-personalised-radio-follows-by-type-by-id" "post-personalised-radio-follows-by-type-by-id" "put-personalised-radio-follows-by-type-by-id" "get-personalised-radio-plays" "get-podcasts" "get-podcasts-featured" "get-podcast-by-pid" "get-podcast-episodes" "get-radio-networks" "get-popular-episodes-clips" "get-radio-programmes" "get-radio-programmes-by-pid" "commands"] | sort) } | get name | first)
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

# Broadcasts
#
# GET /broadcasts
# Returns: record<"$schema": string, limit: int, offset: int, results: table<duration: int, end: string, is_audio_described: bool, is_blanked: bool, is_critical: bool, is_live: bool, is_repeat: bool, is_webcast: bool, pid: string, programme: record, service_id: string, start: string, type: string, version_pid: string>, total: int>
export def "get-broadcasts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --service-id: string # Filter by Service ID. E.g. bbc_radio_fourfm
  --date: string # Filter by date. E.g. 2016-06-17
  --sort: string@sort-completer # Sort by provided query. E.g. 'start_at' sorts in ascending order, and '-start_at' sorts in descending order
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/broadcasts"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: service_id, var: service_id}, {name: date, var: date}, {name: sort, var: sort}]
    header: [{name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, service_id: $service_id, date: $date, sort: $sort, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Latest Broadcasts
#
# GET /broadcasts/latest
# Returns: record<"$schema": string, limit: int, offset: int, results: table<duration: int, end: string, is_audio_described: bool, is_blanked: bool, is_critical: bool, is_live: bool, is_repeat: bool, is_webcast: bool, pid: string, programme: record, service_id: string, start: string, type: string, version_pid: string>, total: int>
export def "get-broadcasts-latest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --service-id: string # Filter by Service ID. E.g. bbc_radio_fourfm
  --on-air: string@on-air-completer # Filter what is on air. E.g. 'now' returns current programme being broadcasted.
  --next: string # Filter what will be on air next in minutes. E.g. '240' returns programmes broadcasted in the next four hurs
  --previous: string # Filter what was on air previously in minutes. E.g. '240' returns programmes broadcasted in the previous four hurs
  --sort: string@sort-completer # Sort by provided query. E.g. 'start_at' sorts in ascending order, and '-start_at' sorts in descending order
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/broadcasts/latest"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: service_id, var: service_id}, {name: on_air, var: on_air}, {name: next, var: next}, {name: previous, var: previous}, {name: sort, var: sort}]
    header: [{name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, service_id: $service_id, on_air: $on_air, next: $next, previous: $previous, sort: $sort, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Broadcasts by PID
#
# GET /broadcasts/{pid}
# Returns: record<"$schema": string, limit: int, offset: int, results: table<duration: int, end: string, is_audio_described: bool, is_blanked: bool, is_critical: bool, is_live: bool, is_repeat: bool, is_webcast: bool, pid: string, programme: record, service_id: string, start: string, type: string, version_pid: string>, total: int>
# operationId: getBroadcastByPid
export def "get-broadcast-by-pid" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/broadcasts/{pid}"
    path_params: [{name: pid, var: pid}]
    header: [{name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pid: $pid, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of categories
#
# GET /categories
# Returns: record<"$schema": string, limit: int, offset: int, results: table<category_type: string, child_categories: list, depth: int, id: string, pip_id: string, title: string, type: string, url_key: string>, total: int>
export def "get-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --kind: string@kind-completer # Filter by provided query. E.g. 'promoted' returns promoted categories
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/categories"
    query: [{name: kind, var: kind}]
    header: [{name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    kind: $kind, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Category by ID
#
# GET /categories/{id}
# Returns: record<"$schema": string, limit: int, offset: int, results: table<category_type: string, child_categories: list, depth: int, id: string, pip_id: string, title: string, type: string, url_key: string>, total: int>
export def "get-categories-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/categories/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Collection Members
#
# GET /collections/{pid}/members
# Returns: record<"$schema": string, limit: int, offset: int, results: table<pid: string, type: string>, total: int>
# operationId: getCollectionMembers
export def "get-collection-members" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/collections/{pid}/members"
    path_params: [{name: pid, var: pid}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pid: $pid, offset: $offset, limit: $limit, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Homepage Experience
#
# GET /experience/homepage
# Returns: record<"$schema": string, data: table<description: string, title: string, type: string, uri: string>>
# operationId: getExperienceHomepage
export def "get-experience-homepage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/experience/homepage"
    header: [{name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Popular Artists
#
# GET /music/popular/artists
# Returns: record<limit: int, method: string, offset: int, repliedAt: string, results: table<gid: string, id: string, imagePid: string, name: string, score: int, sortName: string>, schema: string, total: int>
# operationId: getMusicPopularArtists
export def "get-music-popular-artists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string # ISO 8601 Date yyyy-mm-dd. Returns items between given time period and now
  --until: string # ISO 8601 Date yyyy-mm-dd. Returns items between given 'since' and 'until' date params
  --decomposed: oneof<nothing, bool> # In addition to the overall score, return a list of scores broken down by day N.B Must be used in conjunction with since and/or until and since is >= 31 days
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/music/popular/artists"
    query: [{name: since, var: since}, {name: until, var: until}, {name: decomposed, var: decomposed}, {name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    since: $since, until: $until, decomposed: $decomposed, offset: $offset, limit: $limit, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Single Artist Popularity
#
# GET /music/popular/artists/{id}
# Returns: record<limit: int, method: string, offset: int, repliedAt: string, results: table<gid: string, id: string, imagePid: string, name: string, score: int, sortName: string>, schema: string, total: int>
# operationId: getMusicPopularArtistById
export def "get-music-popular-artist-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string # ISO 8601 Date yyyy-mm-dd. Returns items between given time period and now
  --until: string # ISO 8601 Date yyyy-mm-dd. Returns items between given 'since' and 'until' date params
  --decomposed: oneof<nothing, bool> # In addition to the overall score, return a list of scores broken down by day N.B Must be used in conjunction with since and/or until and since is >= 31 days
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/music/popular/artists/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: since, var: since}, {name: until, var: until}, {name: decomposed, var: decomposed}]
    header: [{name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, since: $since, until: $until, decomposed: $decomposed, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Popular Playlists
#
# GET /music/popular/playlists
# Returns: record<limit: int, method: string, offset: int, repliedAt: string, results: table<categories: list, commentsEnabled: bool, description: string, externalPartners: list, genre: string, id: string, imagePid: string, imageUrl: string, kind: string, mood: string, oneOff: bool, playlistPlaybackType: string, score: int, serviceId: string, title: string, updatedAt: string, visibility: string, wideImagePid: string, wideImageUrl: string>, schema: string, total: int>
# operationId: getMusicPopularPlaylists
export def "get-music-popular-playlists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string # ISO 8601 Date yyyy-mm-dd. Returns items between given time period and now
  --until: string # ISO 8601 Date yyyy-mm-dd. Returns items between given 'since' and 'until' date params
  --decomposed: oneof<nothing, bool> # In addition to the overall score, return a list of scores broken down by day N.B Must be used in conjunction with since and/or until and since is >= 31 days
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/music/popular/playlists"
    query: [{name: since, var: since}, {name: until, var: until}, {name: decomposed, var: decomposed}, {name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    since: $since, until: $until, decomposed: $decomposed, offset: $offset, limit: $limit, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Single Playlist Popularity
#
# GET /music/popular/playlists/{id}
# Returns: record<limit: int, method: string, offset: int, repliedAt: string, results: table<categories: list, commentsEnabled: bool, description: string, externalPartners: list, genre: string, id: string, imagePid: string, imageUrl: string, kind: string, mood: string, oneOff: bool, playlistPlaybackType: string, score: int, serviceId: string, title: string, updatedAt: string, visibility: string, wideImagePid: string, wideImageUrl: string>, schema: string, total: int>
# operationId: getMusicPopularPlaylistById
export def "get-music-popular-playlist-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string # ISO 8601 Date yyyy-mm-dd. Returns items between given time period and now
  --until: string # ISO 8601 Date yyyy-mm-dd. Returns items between given 'since' and 'until' date params
  --decomposed: oneof<nothing, bool> # In addition to the overall score, return a list of scores broken down by day N.B Must be used in conjunction with since and/or until and since is >= 31 days
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/music/popular/playlists/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: since, var: since}, {name: until, var: until}, {name: decomposed, var: decomposed}]
    header: [{name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, since: $since, until: $until, decomposed: $decomposed, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Popular Tracks
#
# GET /music/popular/tracks
# Returns: record<limit: int, method: string, offset: int, repliedAt: string, results: table<album: string, artistGid: string, artistName: string, artists: list, baseTitle: string, classical: bool, id: string, mergedIds: list, preferredMultiplayRecordAudio: record, preferredRecordAudio: record, radioEdit: bool, recordAudio: list, recordImageHref: string, recordImagePid: string, score: int, title: string, type: string>, schema: string, total: int>
# operationId: getMusicPopularTracks
export def "get-music-popular-tracks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string # ISO 8601 Date yyyy-mm-dd. Returns items between given time period and now
  --until: string # ISO 8601 Date yyyy-mm-dd. Returns items between given 'since' and 'until' date params
  --network: string # Return items with given Network ID
  --programme: string # Items with given Programme Pid
  --artist: string # MusicBrainz artist ID
  --decomposed: oneof<nothing, bool> # In addition to the overall score, return a list of scores broken down by day N.B Must be used in conjunction with since and/or until and since is >= 31 days
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/music/popular/tracks"
    query: [{name: since, var: since}, {name: until, var: until}, {name: network, var: network}, {name: programme, var: programme}, {name: artist, var: artist}, {name: decomposed, var: decomposed}, {name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    since: $since, until: $until, network: $network, programme: $programme, artist: $artist, decomposed: $decomposed, offset: $offset, limit: $limit, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Single Track Popularity
#
# GET /music/popular/tracks/{id}
# Returns: record<limit: int, method: string, offset: int, repliedAt: string, results: table<album: string, artistGid: string, artistName: string, artists: list, baseTitle: string, classical: bool, id: string, mergedIds: list, preferredMultiplayRecordAudio: record, preferredRecordAudio: record, radioEdit: bool, recordAudio: list, recordImageHref: string, recordImagePid: string, score: int, title: string, type: string>, schema: string, total: int>
# operationId: getMusicPopularTrackById
export def "get-music-popular-track-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string # ISO 8601 Date yyyy-mm-dd. Returns items between given time period and now
  --until: string # ISO 8601 Date yyyy-mm-dd. Returns items between given 'since' and 'until' date params
  --network: string # Return items with given Network ID
  --programme: string # Items with given Programme Pid
  --artist: string # MusicBrainz artist ID
  --decomposed: oneof<nothing, bool> # In addition to the overall score, return a list of scores broken down by day N.B Must be used in conjunction with since and/or until and since is >= 31 days
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/music/popular/tracks/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: since, var: since}, {name: until, var: until}, {name: network, var: network}, {name: programme, var: programme}, {name: artist, var: artist}, {name: decomposed, var: decomposed}]
    header: [{name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, since: $since, until: $until, network: $network, programme: $programme, artist: $artist, decomposed: $decomposed, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unfollow category
#
# DELETE /my/categories/follows
export def "delete-my-categories-follows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-api-key: string # API_KEY (required)
  category_id: string
  platform: string@platform-completer
]: any -> any {
  $in | http-request {
    method: delete
    path: "/my/categories/follows"
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-API-Key, var: x_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: category_id, var: category_id}, {name: platform, var: platform}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    authorization: $authorization, x_api_key: $x_api_key, category_id: $category_id, platform: $platform
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of followed categories
#
# GET /my/categories/follows
# Returns: record<"$schema": string, limit: int, offset: int, total: int>
export def "get-my-categories-follows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/my/categories/follows"
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, authorization: $authorization, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Follow category
#
# POST /my/categories/follows
export def "post-my-categories-follows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-api-key: string # API_KEY (required)
  category_id: string
  platform: string@platform-completer
]: any -> any {
  $in | http-request {
    method: post
    path: "/my/categories/follows"
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-API-Key, var: x_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: category_id, var: category_id}, {name: platform, var: platform}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    authorization: $authorization, x_api_key: $x_api_key, category_id: $category_id, platform: $platform
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Music Exports
#
# GET /my/music/export
# Returns: record<created_at: string, id: string, job_id: string, status: string, vendor: string>
# operationId: getMusicExport
export def "get-music-export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/my/music/export"
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Music Export Jobs
#
# GET /my/music/exports/jobs
# Returns: record<created_at: string, id: string, job_id: string, status: string, vendor: string>
# operationId: getMusicExportJobs
export def "get-music-export-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --over16: oneof<nothing, bool> # Boolean age check (required)
  --vendor: string@vendor-completer # Specify Vendor Jobs
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/my/music/exports/jobs"
    query: [{name: over16, var: over16, required: true}, {name: vendor, var: vendor}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    over16: $over16, vendor: $vendor, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Music Export Jobs
#
# POST /my/music/exports/jobs
# Returns: record<method: string, replied_at: string, schema: string>
# operationId: postMusicExportJob
export def "post-music-export-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --over16: oneof<nothing, bool> # Boolean age check (required)
  --vendor: string@vendor-completer # Specify Vendor Jobs
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/my/music/exports/jobs"
    query: [{name: over16, var: over16, required: true}, {name: vendor, var: vendor}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    over16: $over16, vendor: $vendor, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Music Export Tracks
#
# GET /my/music/exports/tracks
# Returns: record<created_at: string, id: string, job_id: string, status: string, vendor: string>
# operationId: getMusicExportTracks
export def "get-music-export-tracks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --over16: oneof<nothing, bool> # Boolean age check (required)
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --vendor: string@vendor-completer # Specify Vendor Tracks
  --status: string@status-completer # Specify Track status
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/my/music/exports/tracks"
    query: [{name: over16, var: over16, required: true}, {name: offset, var: offset}, {name: limit, var: limit}, {name: vendor, var: vendor}, {name: status, var: status}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    over16: $over16, offset: $offset, limit: $limit, vendor: $vendor, status: $status, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Favourite Tracks or Clips
#
# GET /my/music/favourites
# Returns: record<limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: list, domain: string, id: string, meta_data: record, type: string, urn: string>, schema: string, total: int>
# operationId: getPersonalisedMusicFavourites
export def "get-personalised-music-favourites" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --action: string@action-completer # Filters activities based on the type of action
  --music-data: oneof<nothing, bool> # Omits music data from the response, defaults to true
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/my/music/favourites"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: action, var: action}, {name: music-data, var: music_data}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, action: $action, music_data: $music_data, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Favourite Tracks or Clips
#
# POST /my/music/favourites
# Returns: record<limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: list, domain: string, id: string, meta_data: record, type: string, urn: string>, schema: string, total: int>
# operationId: postPersonalisedMusicFavouritesBatch
export def "post-personalised-music-favourites-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/my/music/favourites"
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Favourite Tracks or Clips
#
# PUT /my/music/favourites
# Returns: record<method: string, replied_at: string, schema: string>
# operationId: putPersonalisedMusicFavouritesBatch
export def "put-personalised-music-favourites-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/my/music/favourites"
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Favourite Tracks or Clips by Type
#
# GET /my/music/favourites/{type}
# Returns: record<limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: list, domain: string, id: string, meta_data: record, type: string, urn: string>, schema: string, total: int>
# operationId: getPersonalisedMusicFavouritesByType
export def "get-personalised-music-favourites-by-type" [
  type: string@type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer # Filters activities based on the type of action
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/my/music/favourites/{type}"
    path_params: [{name: type, var: type}]
    query: [{name: action, var: action}, {name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, action: $action, offset: $offset, limit: $limit, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Favourite Track or Clip
#
# DELETE /my/music/favourites/{type}/{id}
# Returns: record<method: string, replied_at: string, schema: string>
# operationId: deletePersonalisedMusicFavouritesByTypeById
export def "delete-personalised-music-favourites-by-type-by-id" [
  type: string@type-completer
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/my/music/favourites/{type}/{id}"
    path_params: [{name: type, var: type}, {name: id, var: id}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, id: $id, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Favourite Track or Clip
#
# GET /my/music/favourites/{type}/{id}
# Returns: record<limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: list, domain: string, id: string, meta_data: record, type: string, urn: string>, schema: string, total: int>
# operationId: getPersonalisedMusicFavouritesByTypeById
export def "get-personalised-music-favourites-by-type-by-id" [
  type: string@type-completer
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/my/music/favourites/{type}/{id}"
    path_params: [{name: type, var: type}, {name: id, var: id}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, id: $id, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Favourite Track or Clip
#
# POST /my/music/favourites/{type}/{id}
# Returns: record<limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: list, domain: string, id: string, meta_data: record, type: string, urn: string>, schema: string, total: int>
# operationId: postPersonalisedMusicFavouritesByTypeById
export def "post-personalised-music-favourites-by-type-by-id" [
  type: string@type-completer
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
  action: string
  --added-at: string
  --context: string
  --meta-data: record # shape: {key: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/my/music/favourites/{type}/{id}"
    path_params: [{name: type, var: type}, {name: id, var: id}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: added_at, var: added_at}, {name: context, var: context}, {name: meta_data, var: meta_data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, id: $id, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key, action: $action, added_at: $added_at, context: $context, meta_data: $meta_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Favourite Track or Clip
#
# PUT /my/music/favourites/{type}/{id}
# Returns: record<method: string, replied_at: string, schema: string>
# operationId: putPersonalisedMusicFavouritesByTypeById
export def "put-personalised-music-favourites-by-type-by-id" [
  type: string@type-completer
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
  action: string
  --added-at: string
  --context: string
  --meta-data: record # shape: {key: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/my/music/favourites/{type}/{id}"
    path_params: [{name: type, var: type}, {name: id, var: id}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: added_at, var: added_at}, {name: context, var: context}, {name: meta_data, var: meta_data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, id: $id, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key, action: $action, added_at: $added_at, context: $context, meta_data: $meta_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Followed Networks, Categories, Artists, Playlists and Genres
#
# GET /my/music/follows
# Returns: record<limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: list, domain: string, id: string, meta_data: record, type: string, urn: string>, schema: string, total: int>
# operationId: getPersonalisedMusicFollows
export def "get-personalised-music-follows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-1 # Filters activities based on the type of action
  --music-data: oneof<nothing, bool> # Omits music data from the response, defaults to true
  --music-context: string@music-context-completer # Specify context to be passed to Music API
  --music-within-uk: oneof<nothing, bool> # Specify location to be passed to Music API
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/my/music/follows"
    query: [{name: action, var: action}, {name: music-data, var: music_data}, {name: music_context, var: music_context}, {name: music_within_uk, var: music_within_uk}, {name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action: $action, music_data: $music_data, music_context: $music_context, music_within_uk: $music_within_uk, offset: $offset, limit: $limit, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Followed Networks, Categories, Artists, Playlists and Genres
#
# POST /my/music/follows
# Returns: record<method: string, replied_at: string, schema: string>
# operationId: postPersonalisedMusicFollowsBatch
export def "post-personalised-music-follows-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-1 # Filters activities based on the type of action
  --music-data: oneof<nothing, bool> # Omits music data from the response, defaults to true
  --music-context: string@music-context-completer # Specify context to be passed to Music API
  --music-within-uk: oneof<nothing, bool> # Specify location to be passed to Music API
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/my/music/follows"
    query: [{name: action, var: action}, {name: music-data, var: music_data}, {name: music_context, var: music_context}, {name: music_within_uk, var: music_within_uk}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action: $action, music_data: $music_data, music_context: $music_context, music_within_uk: $music_within_uk, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Followed Networks, Categories, Artists, Playlists and Genres
#
# PUT /my/music/follows
# Returns: record<method: string, replied_at: string, schema: string>
# operationId: putPersonalisedMusicFollowsBatch
export def "put-personalised-music-follows-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-1 # Filters activities based on the type of action
  --music-data: oneof<nothing, bool> # Omits music data from the response, defaults to true
  --music-context: string@music-context-completer # Specify context to be passed to Music API
  --music-within-uk: oneof<nothing, bool> # Specify location to be passed to Music API
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/my/music/follows"
    query: [{name: action, var: action}, {name: music-data, var: music_data}, {name: music_context, var: music_context}, {name: music_within_uk, var: music_within_uk}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action: $action, music_data: $music_data, music_context: $music_context, music_within_uk: $music_within_uk, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Followed Networks, Categories, Artists, Playlists and Genres by Type
#
# GET /my/music/follows/{type}
# Returns: record<limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: list, domain: string, id: string, meta_data: record, type: string, urn: string>, schema: string, total: int>
# operationId: getPersonalisedMusicFollowsByType
export def "get-personalised-music-follows-by-type" [
  type: string@type-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-1 # Filters activities based on the type of action
  --music-data: oneof<nothing, bool> # Omits music data from the response, defaults to true
  --music-context: string@music-context-completer # Specify context to be passed to Music API
  --music-within-uk: oneof<nothing, bool> # Specify location to be passed to Music API
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/my/music/follows/{type}"
    path_params: [{name: type, var: type}]
    query: [{name: action, var: action}, {name: music-data, var: music_data}, {name: music_context, var: music_context}, {name: music_within_uk, var: music_within_uk}, {name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, action: $action, music_data: $music_data, music_context: $music_context, music_within_uk: $music_within_uk, offset: $offset, limit: $limit, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Followed Network, Category, Artist, Playlist and Genre
#
# DELETE /my/music/follows/{type}/{id}
# Returns: record<method: string, replied_at: string, schema: string>
# operationId: deletePersonalisedMusicFollowsByTypeById
export def "delete-personalised-music-follows-by-type-by-id" [
  type: string@type-completer-1
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --music-data: oneof<nothing, bool> # Omits music data from the response, defaults to true
  --music-context: string@music-context-completer # Specify context to be passed to Music API
  --music-within-uk: oneof<nothing, bool> # Specify location to be passed to Music API
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/my/music/follows/{type}/{id}"
    path_params: [{name: type, var: type}, {name: id, var: id}]
    query: [{name: music-data, var: music_data}, {name: music_context, var: music_context}, {name: music_within_uk, var: music_within_uk}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, id: $id, music_data: $music_data, music_context: $music_context, music_within_uk: $music_within_uk, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Followed Network, Category, Artist, Playlist and Genre
#
# GET /my/music/follows/{type}/{id}
# Returns: record<limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: list, domain: string, id: string, meta_data: record, type: string, urn: string>, schema: string, total: int>
# operationId: getPersonalisedMusicFollowsByTypeById
export def "get-personalised-music-follows-by-type-by-id" [
  type: string@type-completer-1
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --music-data: oneof<nothing, bool> # Omits music data from the response, defaults to true
  --music-context: string@music-context-completer # Specify context to be passed to Music API
  --music-within-uk: oneof<nothing, bool> # Specify location to be passed to Music API
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/my/music/follows/{type}/{id}"
    path_params: [{name: type, var: type}, {name: id, var: id}]
    query: [{name: music-data, var: music_data}, {name: music_context, var: music_context}, {name: music_within_uk, var: music_within_uk}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, id: $id, music_data: $music_data, music_context: $music_context, music_within_uk: $music_within_uk, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Followed Network, Category, Artist, Playlist and Genre
#
# POST /my/music/follows/{type}/{id}
# Returns: record<method: string, replied_at: string, schema: string>
# operationId: postPersonalisedMusicFollowsByTypeById
export def "post-personalised-music-follows-by-type-by-id" [
  type: string@type-completer-1
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --music-data: oneof<nothing, bool> # Omits music data from the response, defaults to true
  --music-context: string@music-context-completer # Specify context to be passed to Music API
  --music-within-uk: oneof<nothing, bool> # Specify location to be passed to Music API
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
  action: string
  --added-at: string
  --context: string
  --meta-data: record # shape: {key: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/my/music/follows/{type}/{id}"
    path_params: [{name: type, var: type}, {name: id, var: id}]
    query: [{name: music-data, var: music_data}, {name: music_context, var: music_context}, {name: music_within_uk, var: music_within_uk}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: added_at, var: added_at}, {name: context, var: context}, {name: meta_data, var: meta_data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, id: $id, music_data: $music_data, music_context: $music_context, music_within_uk: $music_within_uk, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key, action: $action, added_at: $added_at, context: $context, meta_data: $meta_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Followed Network, Category, Artist, Playlist and Genre
#
# PUT /my/music/follows/{type}/{id}
# Returns: record<method: string, replied_at: string, schema: string>
# operationId: putPersonalisedMusicFollowsByTypeById
export def "put-personalised-music-follows-by-type-by-id" [
  type: string@type-completer-1
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --music-data: oneof<nothing, bool> # Omits music data from the response, defaults to true
  --music-context: string@music-context-completer # Specify context to be passed to Music API
  --music-within-uk: oneof<nothing, bool> # Specify location to be passed to Music API
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
  action: string
  --added-at: string
  --context: string
  --meta-data: record # shape: {key: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/my/music/follows/{type}/{id}"
    path_params: [{name: type, var: type}, {name: id, var: id}]
    query: [{name: music-data, var: music_data}, {name: music_context, var: music_context}, {name: music_within_uk, var: music_within_uk}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: added_at, var: added_at}, {name: context, var: context}, {name: meta_data, var: meta_data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, id: $id, music_data: $music_data, music_context: $music_context, music_within_uk: $music_within_uk, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key, action: $action, added_at: $added_at, context: $context, meta_data: $meta_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Music Export Preferences
#
# DELETE /my/music/preferences/export
# Returns: record<method: string, replied_at: string, schema: string>
# operationId: deleteMusicPreferencesExport
export def "delete-music-preferences-export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/my/music/preferences/export"
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Music Export Preferences
#
# GET /my/music/preferences/export
# Returns: record<method: string, replied_at: string, results: table<access_expires_at: string, access_token: string, add_plus_export: bool, authorization_code: string, last_export: string, legacy_state: string, partner_id: string, refresh_token: string, terms: bool, vendor: string>, schema: string, total: int>
# operationId: getMusicPreferencesExport
export def "get-music-preferences-export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/my/music/preferences/export"
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Music Export Preferences
#
# POST /my/music/preferences/export
# Returns: record<method: string, replied_at: string, schema: string>
# operationId: postMusicPreferencesExport
export def "post-music-preferences-export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
  access_expires_at: string
  access_token: string
  --add-plus-export: oneof<nothing, bool>
  authorization_code: string
  last_export: string
  legacy_state: string
  partner_id: string
  refresh_token: string
  --terms: oneof<nothing, bool>
  vendor: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/my/music/preferences/export"
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: access_expires_at, var: access_expires_at}, {name: access_token, var: access_token}, {name: add_plus_export, var: add_plus_export, required: true}, {name: authorization_code, var: authorization_code}, {name: last_export, var: last_export}, {name: legacy_state, var: legacy_state}, {name: partner_id, var: partner_id}, {name: refresh_token, var: refresh_token}, {name: terms, var: terms, required: true}, {name: vendor, var: vendor}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key, access_expires_at: $access_expires_at, access_token: $access_token, add_plus_export: $add_plus_export, authorization_code: $authorization_code, last_export: $last_export, legacy_state: $legacy_state, partner_id: $partner_id, refresh_token: $refresh_token, terms: $terms, vendor: $vendor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Music Export Vendor Preferences
#
# DELETE /my/music/preferences/export/{vendor}
# operationId: deleteMusicPreferencesExportVendor
export def "delete-music-preferences-export-vendor" [
  vendor: string@vendor-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/my/music/preferences/export/{vendor}"
    path_params: [{name: vendor, var: vendor}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    vendor: $vendor, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Music Export Vendor Preferences
#
# GET /my/music/preferences/export/{vendor}
# Returns: record<method: string, replied_at: string, results: table<access_expires_at: string, access_token: string, add_plus_export: bool, authorization_code: string, last_export: string, legacy_state: string, partner_id: string, refresh_token: string, terms: bool, vendor: string>, schema: string, total: int>
# operationId: getMusicPreferencesExportVendor
export def "get-music-preferences-export-vendor" [
  vendor: string@vendor-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/my/music/preferences/export/{vendor}"
    path_params: [{name: vendor, var: vendor}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    vendor: $vendor, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Music Export Vendor Preferences
#
# POST /my/music/preferences/export/{vendor}
# operationId: postMusicPreferencesExportVendor
export def "post-music-preferences-export-vendor" [
  vendor: string@vendor-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
  access_expires_at: string
  access_token: string
  --add-plus-export: oneof<nothing, bool>
  authorization_code: string
  last_export: string
  legacy_state: string
  partner_id: string
  refresh_token: string
  --terms: oneof<nothing, bool>
  --body-vendor: string # (spec name: vendor)
]: any -> any {
  $in | http-request {
    method: post
    path: "/my/music/preferences/export/{vendor}"
    path_params: [{name: vendor, var: vendor}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: access_expires_at, var: access_expires_at}, {name: access_token, var: access_token}, {name: add_plus_export, var: add_plus_export, required: true}, {name: authorization_code, var: authorization_code}, {name: last_export, var: last_export}, {name: legacy_state, var: legacy_state}, {name: partner_id, var: partner_id}, {name: refresh_token, var: refresh_token}, {name: terms, var: terms, required: true}, {name: vendor, var: body_vendor, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    vendor: $vendor, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key, access_expires_at: $access_expires_at, access_token: $access_token, add_plus_export: $add_plus_export, authorization_code: $authorization_code, last_export: $last_export, legacy_state: $legacy_state, partner_id: $partner_id, refresh_token: $refresh_token, terms: $terms, body_vendor: $body_vendor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Music Export Vendor Preferences
#
# PUT /my/music/preferences/export/{vendor}
# operationId: putMusicPreferencesExportVendor
export def "put-music-preferences-export-vendor" [
  vendor: string@vendor-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
  access_expires_at: string
  access_token: string
  --add-plus-export: oneof<nothing, bool>
  authorization_code: string
  last_export: string
  legacy_state: string
  partner_id: string
  refresh_token: string
  --terms: oneof<nothing, bool>
  --body-vendor: string # (spec name: vendor)
]: any -> any {
  $in | http-request {
    method: put
    path: "/my/music/preferences/export/{vendor}"
    path_params: [{name: vendor, var: vendor}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: access_expires_at, var: access_expires_at}, {name: access_token, var: access_token}, {name: add_plus_export, var: add_plus_export, required: true}, {name: authorization_code, var: authorization_code}, {name: last_export, var: last_export}, {name: legacy_state, var: legacy_state}, {name: partner_id, var: partner_id}, {name: refresh_token, var: refresh_token}, {name: terms, var: terms, required: true}, {name: vendor, var: body_vendor, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    vendor: $vendor, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key, access_expires_at: $access_expires_at, access_token: $access_token, add_plus_export: $add_plus_export, authorization_code: $authorization_code, last_export: $last_export, legacy_state: $legacy_state, partner_id: $partner_id, refresh_token: $refresh_token, terms: $terms, body_vendor: $body_vendor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unfollow network
#
# DELETE /my/networks/follows
export def "delete-my-networks-follows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-api-key: string # API_KEY (required)
  platform: string@platform-completer
  service_id: string
]: any -> any {
  $in | http-request {
    method: delete
    path: "/my/networks/follows"
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-API-Key, var: x_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: platform, var: platform}, {name: service_id, var: service_id}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    offset: $offset, limit: $limit, authorization: $authorization, x_api_key: $x_api_key, platform: $platform, service_id: $service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of followed networks
#
# GET /my/networks/follows
# Returns: record<"$schema": string, limit: int, offset: int, results: table<created: string, type: string>, total: int>
export def "get-my-networks-follows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/my/networks/follows"
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, authorization: $authorization, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Follow network
#
# POST /my/networks/follows
export def "post-my-networks-follows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-api-key: string # API_KEY (required)
  platform: string@platform-completer
  service_id: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/my/networks/follows"
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-API-Key, var: x_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: platform, var: platform}, {name: service_id, var: service_id}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    offset: $offset, limit: $limit, authorization: $authorization, x_api_key: $x_api_key, platform: $platform, service_id: $service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Write Play Event
#
# POST /my/plays
export def "post-my-plays" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-api-key: string # API_KEY (required)
  action: string@action-completer-2
  elapsed_time: int
  pid: string
  resource_type: string@resource-type-completer
  version_pid: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/my/plays"
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-API-Key, var: x_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: elapsed_time, var: elapsed_time}, {name: pid, var: pid}, {name: resource_type, var: resource_type}, {name: version_pid, var: version_pid}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    authorization: $authorization, x_api_key: $x_api_key, action: $action, elapsed_time: $elapsed_time, pid: $pid, resource_type: $resource_type, version_pid: $version_pid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Suggested Playspace Container
#
# GET /my/playspace/containers/suggested
# Returns: record<id: string, members: table<description: string, image_url: string, pid: string, title: string, type: string, version_pid: string>, title: string, type: string>
# operationId: suggestContainer
export def "suggest-container" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --previous-pid: string # Clip or Episode PID of the previous or first content item in the Playspace stream. (required)
  --previous-container: string # Container ID of the previous container in the Playspace stream.
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/my/playspace/containers/suggested"
    query: [{name: previous_pid, var: previous_pid, required: true}, {name: previous_container, var: previous_container}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    previous_pid: $previous_pid, previous_container: $previous_container, authorization: $authorization, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Playspace Container by ID
#
# GET /my/playspace/containers/{id}
# Returns: record<id: string, members: table<description: string, image_url: string, pid: string, title: string, type: string, version_pid: string>, title: string, type: string>
# operationId: getContainer
export def "get-container" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/my/playspace/containers/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, authorization: $authorization, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recommended Programmes
#
# GET /my/programmes/recommendations
# Returns: record<"$schema": string, limit: int, offset: int, results: table<pid: string, type: string>, total: int>
# operationId: getRecommendations
export def "get-recommendations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --rights: string@rights-completer # Only return available results for the web/mobile. (required)
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/my/programmes/recommendations"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: rights, var: rights, required: true}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, rights: $rights, authorization: $authorization, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Favourite Episodes and Clips
#
# GET /my/radio/favourites
# Returns: record<"$schema": string, limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: record, domain: string, id: string, metadata: record, type: string, uas_type: string, urn: string>, total: int>
# operationId: getPersonalisedRadioFavourites
export def "get-personalised-radio-favourites" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --sort: string@sort-completer-1 # Sort order for Personalised Radio results
  --show-all-activity: oneof<nothing, bool> # Include items which have been 'soft' unfavourited in response. I.e items with UAS type of 'unfavourited'
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/my/radio/favourites"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: sort, var: sort}, {name: show_all_activity, var: show_all_activity}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, sort: $sort, show_all_activity: $show_all_activity, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Favourite Episodes and Clips
#
# POST /my/radio/favourites
# Returns: record<"$schema": string, method: string, replied_at: string>
# operationId: postPersonalisedRadioBatch
export def "post-personalised-radio-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/my/radio/favourites"
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Favourite Episodes and Clips
#
# PUT /my/radio/favourites
# Returns: record<"$schema": string, method: string, replied_at: string>
# operationId: putPersonalisedRadioBatch
export def "put-personalised-radio-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/my/radio/favourites"
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Favourite Episodes and Clips by Type
#
# GET /my/radio/favourites/{type}
# Returns: record<"$schema": string, limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: record, domain: string, id: string, metadata: record, type: string, uas_type: string, urn: string>, total: int>
# operationId: getPersonalisedRadioFavouritesByType
export def "get-personalised-radio-favourites-by-type" [
  type: string@type-completer-2
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort: string@sort-completer-1 # Sort order for Personalised Radio results
  --show-all-activity: oneof<nothing, bool> # Include items which have been 'soft' unfavourited in response. I.e items with UAS type of 'unfavourited'
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/my/radio/favourites/{type}"
    path_params: [{name: type, var: type}]
    query: [{name: sort, var: sort}, {name: show_all_activity, var: show_all_activity}, {name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, sort: $sort, show_all_activity: $show_all_activity, offset: $offset, limit: $limit, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Favourite Episode or Clip
#
# DELETE /my/radio/favourites/{type}/{pid}
# Returns: record<"$schema": string, method: string, replied_at: string>
# operationId: deletePersonalisedRadioByActivityTypeById
export def "delete-personalised-radio-by-activity-type-by-id" [
  type: string@type-completer-2
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/my/radio/favourites/{type}/{pid}"
    path_params: [{name: type, var: type}, {name: pid, var: pid}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, pid: $pid, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Favourite Episode or Clip
#
# GET /my/radio/favourites/{type}/{pid}
# Returns: record<"$schema": string, limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: record, domain: string, id: string, metadata: record, type: string, uas_type: string, urn: string>, total: int>
# operationId: getPersonalisedRadioByActivityTypeById
export def "get-personalised-radio-by-activity-type-by-id" [
  type: string@type-completer-2
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --show-all-activity: oneof<nothing, bool> # Include items which have been 'soft' unfavourited in response. I.e items with UAS type of 'unfavourited'
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/my/radio/favourites/{type}/{pid}"
    path_params: [{name: type, var: type}, {name: pid, var: pid}]
    query: [{name: show_all_activity, var: show_all_activity}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, pid: $pid, show_all_activity: $show_all_activity, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Favourite Episode or Clip
#
# POST /my/radio/favourites/{type}/{pid}
# Returns: record<"$schema": string, method: string, replied_at: string>
# operationId: postPersonalisedRadioByActivityTypeById
export def "post-personalised-radio-by-activity-type-by-id" [
  type: string@type-completer-2
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
  action: string
  --added-at: string
  --context: string
  --metadata: record # shape: {key: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/my/radio/favourites/{type}/{pid}"
    path_params: [{name: type, var: type}, {name: pid, var: pid}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: added_at, var: added_at}, {name: context, var: context}, {name: metadata, var: metadata}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, pid: $pid, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key, action: $action, added_at: $added_at, context: $context, metadata: $metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Favourite Episode or Clip
#
# PUT /my/radio/favourites/{type}/{pid}
# Returns: record<"$schema": string, method: string, replied_at: string>
# operationId: putPersonalisedRadioByActivityTypeById
export def "put-personalised-radio-by-activity-type-by-id" [
  type: string@type-completer-2
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
  action: string
  --added-at: string
  --context: string
  --metadata: record # shape: {key: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/my/radio/favourites/{type}/{pid}"
    path_params: [{name: type, var: type}, {name: pid, var: pid}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: added_at, var: added_at}, {name: context, var: context}, {name: metadata, var: metadata}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, pid: $pid, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key, action: $action, added_at: $added_at, context: $context, metadata: $metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Followed Brands and Series
#
# GET /my/radio/follows
# Returns: record<"$schema": string, limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: record, domain: string, id: string, metadata: record, type: string, uas_type: string, urn: string>, total: int>
# operationId: getPersonalisedRadioFollows
export def "get-personalised-radio-follows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --sort: string@sort-completer-1 # Sort order for Personalised Radio results
  --show-all-activity: oneof<nothing, bool> # Include items which have been 'soft' unfollowed in response. I.e items with UAS type of 'unfollowed'
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/my/radio/follows"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: sort, var: sort}, {name: show_all_activity, var: show_all_activity}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, sort: $sort, show_all_activity: $show_all_activity, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Followed Brands and Series
#
# POST /my/radio/follows
# Returns: record<"$schema": string, method: string, replied_at: string>
# operationId: postPersonalisedRadioFollowsBatch
export def "post-personalised-radio-follows-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/my/radio/follows"
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Followed Brands and Series
#
# PUT /my/radio/follows
# Returns: record<"$schema": string, method: string, replied_at: string>
# operationId: putPersonalisedRadioFollowsBatch
export def "put-personalised-radio-follows-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/my/radio/follows"
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Followed Brands or Series by Type
#
# GET /my/radio/follows/{type}
# Returns: record<"$schema": string, limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: record, domain: string, id: string, metadata: record, type: string, uas_type: string, urn: string>, total: int>
# operationId: getPersonalisedRadioFollowsByType
export def "get-personalised-radio-follows-by-type" [
  type: string@type-completer-3
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort: string@sort-completer-1 # Sort order for Personalised Radio results
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --show-all-activity: oneof<nothing, bool> # Include items which have been 'soft' unfollowed in response. I.e items with UAS type of 'unfollowed'
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/my/radio/follows/{type}"
    path_params: [{name: type, var: type}]
    query: [{name: sort, var: sort}, {name: offset, var: offset}, {name: limit, var: limit}, {name: show_all_activity, var: show_all_activity}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, sort: $sort, offset: $offset, limit: $limit, show_all_activity: $show_all_activity, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Followed Brand or Series
#
# DELETE /my/radio/follows/{type}/{pid}
# Returns: record<"$schema": string, method: string, replied_at: string>
# operationId: deletePersonalisedRadioFollowsByTypeById
export def "delete-personalised-radio-follows-by-type-by-id" [
  type: string@type-completer-3
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/my/radio/follows/{type}/{pid}"
    path_params: [{name: type, var: type}, {name: pid, var: pid}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, pid: $pid, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Followed Brand or Series
#
# GET /my/radio/follows/{type}/{pid}
# Returns: record<"$schema": string, limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: record, domain: string, id: string, metadata: record, type: string, uas_type: string, urn: string>, total: int>
# operationId: getPersonalisedRadioFollowsByTypeById
export def "get-personalised-radio-follows-by-type-by-id" [
  type: string@type-completer-3
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/my/radio/follows/{type}/{pid}"
    path_params: [{name: type, var: type}, {name: pid, var: pid}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, pid: $pid, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Followed Brand or Series
#
# POST /my/radio/follows/{type}/{pid}
# Returns: record<"$schema": string, method: string, replied_at: string>
# operationId: postPersonalisedRadioFollowsByTypeById
export def "post-personalised-radio-follows-by-type-by-id" [
  type: string@type-completer-3
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
  action: string
  --added-at: string
  --context: string
  --metadata: record # shape: {key: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/my/radio/follows/{type}/{pid}"
    path_params: [{name: type, var: type}, {name: pid, var: pid}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: added_at, var: added_at}, {name: context, var: context}, {name: metadata, var: metadata}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, pid: $pid, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key, action: $action, added_at: $added_at, context: $context, metadata: $metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Followed Brand or Series
#
# PUT /my/radio/follows/{type}/{pid}
# Returns: record<"$schema": string, method: string, replied_at: string>
# operationId: putPersonalisedRadioFollowsByTypeById
export def "put-personalised-radio-follows-by-type-by-id" [
  type: string@type-completer-3
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
  action: string
  --added-at: string
  --context: string
  --metadata: record # shape: {key: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/my/radio/follows/{type}/{pid}"
    path_params: [{name: type, var: type}, {name: pid, var: pid}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: added_at, var: added_at}, {name: context, var: context}, {name: metadata, var: metadata}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, pid: $pid, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key, action: $action, added_at: $added_at, context: $context, metadata: $metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Played Episode or Clip
#
# GET /my/radio/plays
# Returns: record<"$schema": string, limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: record, domain: string, id: string, metadata: record, type: string, uas_type: string, urn: string>, total: int>
# operationId: getPersonalisedRadioPlays
export def "get-personalised-radio-plays" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --sort: string@sort-completer-1 # Sort order for Personalised Radio results
  --show-all-activity: oneof<nothing, bool> # Include expired/unavailable items
  --authorization: string # Bearer OAUTH_TOKEN (required, default: Bearer OAUTH_TOKEN)
  --x-authentication-provider: string # Authentication type (required, default: idv5)
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/my/radio/plays"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: sort, var: sort}, {name: show_all_activity, var: show_all_activity}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer OAUTH_TOKEN"}, {name: X-Authentication-Provider, var: x_authentication_provider, required: true, default: idv5}, {name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, sort: $sort, show_all_activity: $show_all_activity, authorization: $authorization, x_authentication_provider: $x_authentication_provider, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# All Podcasts
#
# GET /podcasts
# Returns: record<"$schema": string, limit: int, offset: int, results: table<category_summaries: list, days_available: int, entity_type: string, first_published_date: string, frequency: string, images: list, latest_available_episodes: list, network_summary: record, pid: string, rss_url: string, synopses: record, territory: string, titles: record, total_available_episodes: int, type: string, updated_at: string>, total: int>
# operationId: getPodcasts
export def "get-podcasts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --sort: string@sort-completer-2 # Sort order for Podcasts results
  --network: string # Network Master Brand ID (mid)
  --network-url-key: string # Network URL key
  --category: string # Category ID
  --q: string # Search query String
  --coverage: string@coverage-completer # Local, National or Regional Coverage
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/podcasts"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: sort, var: sort}, {name: network, var: network}, {name: network_url_key, var: network_url_key}, {name: category, var: category}, {name: q, var: q}, {name: coverage, var: coverage}]
    header: [{name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, sort: $sort, network: $network, network_url_key: $network_url_key, category: $category, q: $q, coverage: $coverage, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Featured Podcasts
#
# GET /podcasts/featured
# Returns: record<"$schema": string, limit: float, offset: float, results: table<featured_podcasts: list, title: string, type: string>, total: float>
# operationId: getPodcastsFeatured
export def "get-podcasts-featured" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/podcasts/featured"
    header: [{name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Podcast
#
# GET /podcasts/{pid}
# Returns: record<"$schema": string, limit: int, offset: int, results: table<category_summaries: list, days_available: int, entity_type: string, first_published_date: string, frequency: string, images: list, latest_available_episodes: list, network_summary: record, pid: string, rss_url: string, synopses: record, territory: string, titles: record, total_available_episodes: int, type: string, updated_at: string>, total: int>
# operationId: getPodcastByPid
export def "get-podcast-by-pid" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/podcasts/{pid}"
    path_params: [{name: pid, var: pid}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pid: $pid, offset: $offset, limit: $limit, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Podcast Episodes
#
# GET /podcasts/{pid}/episodes
# Returns: record<"$schema": string, limit: float, offset: float, results: table<asset_url: string, available_versions: list, images: list, media_type: string, network_summary: record, pid: string, release_date: string, short_synopsis: string, titles: record, type: string>, total: float>
# operationId: getPodcastEpisodes
export def "get-podcast-episodes" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/podcasts/{pid}/episodes"
    path_params: [{name: pid, var: pid}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pid: $pid, offset: $offset, limit: $limit, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Networks
#
# GET /radio/networks.json
# Returns: record<"$schema": string, limit: int, offset: int, results: table<active: bool, contacts: list, date_ranges: list, group: string, id: string, international: bool, key: string, preset: bool, promoted_category_summaries: list, services: list, short_title: string, sort: int, title: string, type: string>, total: int>
# operationId: getRadioNetworks
export def "get-radio-networks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --preset: oneof<nothing, bool> # Returns all networks needed for iPlayer Radio responsive web navigation
  --international: oneof<nothing, bool> # Returns all networks available internationally
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/radio/networks.json"
    query: [{name: preset, var: preset}, {name: international, var: international}]
    header: [{name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    preset: $preset, international: $international, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Popular Episodes & Clips
#
# GET /radio/popular
# Returns: record<"$schema": string, limit: int, offset: int, results: table<data: record, id: string, score: int, type: string>, total: int>
# operationId: getPopularEpisodesClips
export def "get-popular-episodes-clips" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-4 # Programme type required. Accepts comma separated values
  --distinct: string@distinct-completer # Filter by deduplication rule. E.g. 'tleo' returns programmes with distinct top level episode objects
  --network: string # Filter by network master brand ID (mid). Accepts comma separated values
  --network-url-key: string # Filter by network URL key. Accepts comma separated values
  --category: string # Filter by category. Accepts comma separated values
  --format: string # Filter by format. Accepts comma separated values
  --group: string@group-completer # Filter by group. Accepts comma separated values
  --media-type: string@media-type-completer # Filter by programme media type. Accepts comma separated values
  --container: string # Filter by container. Accepts any pid e.g. brand,series,episode
  --media-set: list@media-set-completer # Filter by media set name. Accepts comma separated combinations of the following: pc,mobile-download,android-download-high,apple-ios-download-high,mobile-cellular-main,mobile-phone-main,iptv-all
  --q: string # Search query String
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/radio/popular"
    query: [{name: type, var: type}, {name: distinct, var: distinct}, {name: network, var: network}, {name: network_url_key, var: network_url_key}, {name: category, var: category}, {name: format, var: format}, {name: group, var: group}, {name: media_type, var: media_type}, {name: container, var: container}, {name: media_set, var: media_set, style: csv}, {name: q, var: q}]
    header: [{name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, distinct: $distinct, network: $network, network_url_key: $network_url_key, category: $category, format: $format, group: $group, media_type: $media_type, container: $container, media_set: $media_set, q: $q, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Radio programmes
#
# GET /radio/programmes
# Returns: record<"$schema": string, limit: int, offset: int, results: table<pid: string, type: string>, total: int>
# operationId: getRadioProgrammes
export def "get-radio-programmes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --kind: string@kind-completer-1 # Filter by provided query. E.g. 'tleo' returns top level objects, ie. brands, orphaned series, and orphaned episodes
  --network: string # Filter by network master brand ID (mid). Accepts comma separated values
  --network-url-key: string # Filter by network URL key. Accepts comma separated values
  --category: string # Filter by category id. Accepts comma separated values. See /category endpoint below for the type of response provided
  --sort: string@sort-completer-2 # Sort by provided query. E.g. 'title' sorts in ascending order, and -title sorts in descending order
  --container: string # Filter by container. Accepts any brand or series pid
  --type: string@type-completer-5 # Filter by programme type. Accepts comma separated values
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/radio/programmes"
    query: [{name: kind, var: kind}, {name: network, var: network}, {name: network_url_key, var: network_url_key}, {name: category, var: category}, {name: sort, var: sort}, {name: container, var: container}, {name: type, var: type}]
    header: [{name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    kind: $kind, network: $network, network_url_key: $network_url_key, category: $category, sort: $sort, container: $container, type: $type, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Available radio programme by Pid
#
# GET /radio/programmes/{pid}
# Returns: record<"$schema": string, limit: int, offset: int, results: table<pid: string, type: string>, total: int>
# operationId: getRadioProgrammesByPid
export def "get-radio-programmes-by-pid" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api-key: string # API_KEY (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/radio/programmes/{pid}"
    path_params: [{name: pid, var: pid}]
    header: [{name: X-API-Key, var: x_api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pid: $pid, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
