# Auto-generated client for Oxford Dictionaries v1.11.0
# Source: https://api.apis.guru/v2/specs/oxforddictionaries.com/1.11.0/openapi.json
# Auth: --token flag or $env.OXFORD_DICTIONARIES_TOKEN

const CLIENT = {
  base_url: "https://od-api-demo.oxforddictionaries.com:443/api/v1"
  token_env_var: "OXFORD_DICTIONARIES_TOKEN"
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

def base-url-completer [] { ["https://od-api-demo.oxforddictionaries.com:443/api/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def source-domains-language-completer [] { ["de" "en" "es" "nso" "pt" "ur" "zu"] }
def target-domains-language-completer [] { ["de" "es" "id" "ms" "nso" "pt" "ro" "tn" "zu"] }
def source-language-completer [] { ["de" "en" "es" "gu" "hi" "nso" "pt" "sw" "ta" "ur" "zu"] }
def source-language-completer-1 [] { ["en" "es"] }
def source-lang-completer [] { ["en" "es" "fr" "gu" "hi" "lv" "sw" "ta"] }
def source-lang-completer-1 [] { ["en"] }
def region-completer [] { ["gb" "us"] }
def source-translation-language-completer [] { ["de" "en" "es" "id" "ms" "nso" "pt" "tn" "ur" "zu"] }
def target-translation-language-completer [] { ["de" "es" "id" "ms" "nso" "pt" "ro" "tn" "zu"] }
def endpoint-completer [] { ["entries" "inflections" "translations"] }
def source-language-completer-2 [] { ["de" "en" "es" "gu" "hi" "lv" "ms" "nso" "pt" "sw" "ta" "tn" "ur" "zu"] }
def source-lang-completer-2 [] { ["de" "en" "es" "hi" "nso" "pt" "tn" "zu"] }
def source-language-completer-3 [] { ["de" "en" "es" "gu" "hi" "id" "lv" "ms" "nso" "pt" "ro" "sw" "ta" "tn" "ur" "zu"] }
def target-language-completer [] { ["en" "es" "hi" "id" "lv" "ms" "nso" "ro" "sw" "tn" "ur" "zu"] }
def language-completer [] { ["de" "en" "es" "gu" "hi" "id" "lv" "ms" "nso" "pt" "ro" "sw" "ta" "tn" "ur" "zu"] }
def source-language-completer-4 [] { ["en"] }
def source-language-completer-5 [] { ["de" "en" "es" "gu" "hi" "id" "lv" "ms" "pt" "sw" "ta" "ur"] }
def source-register-language-completer [] { ["de" "en" "es" "id" "ms" "pt" "ur"] }
def target-register-language-completer [] { ["de" "en" "es" "id" "ms" "nso" "pt" "ro" "tn" "zu"] }
def source-lang-completer-3 [] { ["en" "es" "gu" "hi" "lv" "sw" "ta"] }
def prefix-completer [] { ["false" "true"] }
def source-search-language-completer [] { ["de" "en" "es" "id" "ms" "nso" "pt" "tn" "ur" "zu"] }
def target-search-language-completer [] { ["de" "es" "id" "ms" "nso" "pt" "ro" "tn" "zu"] }
def accept-completer [] { ["application/json" "text/csv"] }
def exact-completer [] { ["false" "true"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-domains-source-domains-language-target-domains-language: "record<metadata: record, results: record>"
    get-domains-source-language: "record<metadata: record, results: record>"
    get-entries-source-language-word-id-sentences: "record<metadata: record, results: table<id: string, language: string, lexicalEntries: list, type: string, word: string>>"
    get-entries-source-lang-word-id: "record<metadata: record, results: table<id: string, language: string, lexicalEntries: list, pronunciations: list, type: string, word: string>>"
    get-entries-source-lang-word-id-antonyms: "record<metadata: record, results: table<id: string, language: string, lexicalEntries: list, type: string, word: string>>"
    get-entries-source-lang-word-id-regions-region: "record<metadata: record, results: table<id: string, language: string, lexicalEntries: list, pronunciations: list, type: string, word: string>>"
    get-entries-source-lang-word-id-synonyms: "record<metadata: record, results: table<id: string, language: string, lexicalEntries: list, type: string, word: string>>"
    get-entries-source-lang-word-id-synonymsantonyms: "record<metadata: record, results: table<id: string, language: string, lexicalEntries: list, type: string, word: string>>"
    get-entries-source-lang-word-id-filters: "record<metadata: record, results: table<id: string, language: string, lexicalEntries: list, pronunciations: list, type: string, word: string>>"
    get-entries-source-translation-language-word-id-translations-target-translation-language: "record<metadata: record, results: table<id: string, language: string, lexicalEntries: list, pronunciations: list, type: string, word: string>>"
    get-filters: "record<metadata: record, results: record<entries: list<string>, inflections: list<string>, translations: list<string>, wordlist: list<string>>>"
    get-filters-endpoint: "record<metadata: record, results: record<entries: list<string>, inflections: list<string>, translations: list<string>, wordlist: list<string>>>"
    get-grammatical-features-source-language: "record<metadata: record, results: record>"
    get-inflections-source-lang-word-id-filters: "record<metadata: record, results: table<id: string, language: string, lexicalEntries: list, type: string, word: string>>"
    get-languages: "record<metadata: record, results: table<region: string, source: string, sourceLanguage: record, targetLanguage: record, type: string>>"
    get-lexicalcategories-language: "record<metadata: record, results: record>"
    get-regions-source-language: "record<metadata: record, results: record>"
    get-registers-source-language: "record<metadata: record, results: record>"
    get-registers-source-register-language-target-register-language: "record<metadata: record, results: record>"
    get-search-source-lang: "record<metadata: record, results: table<id: string, matchString: string, matchType: string, region: string, word: string>>"
    get-search-source-search-language-translations-target-search-language: "record<metadata: record, results: table<id: string, matchString: string, matchType: string, region: string, word: string>>"
    get-stats-frequency-ngrams-source-lang-corpus-ngram-size: "record<metadata: record, results: table<frequency: int, tokens: list>>"
    get-stats-frequency-word-source-lang: "record<metadata: record, result: record<frequency: int, lemma: string, lexicalCategory: string, matchCount: int, normalizedFrequency: int, trueCase: string, wordform: string>>"
    get-stats-frequency-words-source-lang: "record<metadata: record, results: table<frequency: int, lemma: string, lexicalCategory: string, normalizedFrequency: int, trueCase: string, wordform: string>>"
    get-wordlist-source-lang-filters-advanced: "record<metadata: record, results: table<id: string, matchString: string, matchType: string, region: string, word: string>>"
    get-wordlist-source-lang-filters-basic: "record<metadata: record, results: table<id: string, matchString: string, matchType: string, region: string, word: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-domains-source-domains-language-target-domains-language" "get-domains-source-language" "get-entries-source-language-word-id-sentences" "get-entries-source-lang-word-id" "get-entries-source-lang-word-id-antonyms" "get-entries-source-lang-word-id-regions-region" "get-entries-source-lang-word-id-synonyms" "get-entries-source-lang-word-id-synonymsantonyms" "get-entries-source-lang-word-id-filters" "get-entries-source-translation-language-word-id-translations-target-translation-language" "get-filters" "get-filters-endpoint" "get-grammatical-features-source-language" "get-inflections-source-lang-word-id-filters" "get-languages" "get-lexicalcategories-language" "get-regions-source-language" "get-registers-source-language" "get-registers-source-register-language-target-register-language" "get-search-source-lang" "get-search-source-search-language-translations-target-search-language" "get-stats-frequency-ngrams-source-lang-corpus-ngram-size" "get-stats-frequency-word-source-lang" "get-stats-frequency-words-source-lang" "get-wordlist-source-lang-filters-advanced" "get-wordlist-source-lang-filters-basic" "commands"] | sort) } | get name | first)
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

# Lists available domains in a bilingual dataset
#
# GET /domains/{source_domains_language}/{target_domains_language}
# Returns: record<metadata: record, results: record>
export def "get-domains-source-domains-language-target-domains-language" [
  source_domains_language: string@source-domains-language-completer
  target_domains_language: string@target-domains-language-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter (required, default: 5037d509)
  --app-key: string # App Key Authentication Parameter (required, default: 4dc1aebaa63721f0f8e79a55e2514bc7)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/domains/{source_domains_language}/{target_domains_language}"
    path_params: [{name: source_domains_language, var: source_domains_language}, {name: target_domains_language, var: target_domains_language}]
    header: [{name: app_id, var: app_id, required: true, default: "5037d509"}, {name: app_key, var: app_key, required: true, default: "4dc1aebaa63721f0f8e79a55e2514bc7"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_domains_language: $source_domains_language, target_domains_language: $target_domains_language, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists available domains in a monolingual dataset
#
# GET /domains/{source_language}
# Returns: record<metadata: record, results: record>
export def "get-domains-source-language" [
  source_language: string@source-language-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter (required, default: 5037d509)
  --app-key: string # App Key Authentication Parameter (required, default: 4dc1aebaa63721f0f8e79a55e2514bc7)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/domains/{source_language}"
    path_params: [{name: source_language, var: source_language}]
    header: [{name: app_id, var: app_id, required: true, default: "5037d509"}, {name: app_key, var: app_key, required: true, default: "4dc1aebaa63721f0f8e79a55e2514bc7"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_language: $source_language, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve corpus sentences for a given word
#
# GET /entries/{source_language}/{word_id}/sentences
# Docs: https://helloreverb.com/about — find more info here
# Returns: record<metadata: record, results: table<id: string, language: string, lexicalEntries: list, type: string, word: string>>
export def "get-entries-source-language-word-id-sentences" [
  source_language: string@source-language-completer-1
  word_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter (required, default: 5037d509)
  --app-key: string # App Key Authentication Parameter (required, default: 4dc1aebaa63721f0f8e79a55e2514bc7)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entries/{source_language}/{word_id}/sentences"
    path_params: [{name: source_language, var: source_language}, {name: word_id, var: word_id}]
    header: [{name: app_id, var: app_id, required: true, default: "5037d509"}, {name: app_key, var: app_key, required: true, default: "4dc1aebaa63721f0f8e79a55e2514bc7"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_language: $source_language, word_id: $word_id, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve dictionary information for a given word
#
# GET /entries/{source_lang}/{word_id}
# Docs: https://helloreverb.com/about — find more info here
# Returns: record<metadata: record, results: table<id: string, language: string, lexicalEntries: list, pronunciations: list, type: string, word: string>>
export def "get-entries-source-lang-word-id" [
  source_lang: string@source-lang-completer
  word_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter (required, default: 5037d509)
  --app-key: string # App Key Authentication Parameter (required, default: 4dc1aebaa63721f0f8e79a55e2514bc7)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entries/{source_lang}/{word_id}"
    path_params: [{name: source_lang, var: source_lang}, {name: word_id, var: word_id}]
    header: [{name: app_id, var: app_id, required: true, default: "5037d509"}, {name: app_key, var: app_key, required: true, default: "4dc1aebaa63721f0f8e79a55e2514bc7"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_lang: $source_lang, word_id: $word_id, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve words that mean the opposite
#
# GET /entries/{source_lang}/{word_id}/antonyms
# Docs: https://helloreverb.com/about — find more info here
# Returns: record<metadata: record, results: table<id: string, language: string, lexicalEntries: list, type: string, word: string>>
export def "get-entries-source-lang-word-id-antonyms" [
  source_lang: string@source-lang-completer-1
  word_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter (required, default: 5037d509)
  --app-key: string # App Key Authentication Parameter (required, default: 4dc1aebaa63721f0f8e79a55e2514bc7)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entries/{source_lang}/{word_id}/antonyms"
    path_params: [{name: source_lang, var: source_lang}, {name: word_id, var: word_id}]
    header: [{name: app_id, var: app_id, required: true, default: "5037d509"}, {name: app_key, var: app_key, required: true, default: "4dc1aebaa63721f0f8e79a55e2514bc7"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_lang: $source_lang, word_id: $word_id, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Specify GB or US dictionary for English entry search
#
# GET /entries/{source_lang}/{word_id}/regions={region}
# Docs: https://helloreverb.com/about — find more info here
# Returns: record<metadata: record, results: table<id: string, language: string, lexicalEntries: list, pronunciations: list, type: string, word: string>>
export def "get-entries-source-lang-word-id-regions-region" [
  source_lang: string@source-lang-completer-1
  word_id: string
  region: string@region-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter (required, default: 5037d509)
  --app-key: string # App Key Authentication Parameter (required, default: 4dc1aebaa63721f0f8e79a55e2514bc7)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entries/{source_lang}/{word_id}/regions={region}"
    path_params: [{name: source_lang, var: source_lang}, {name: word_id, var: word_id}, {name: region, var: region}]
    header: [{name: app_id, var: app_id, required: true, default: "5037d509"}, {name: app_key, var: app_key, required: true, default: "4dc1aebaa63721f0f8e79a55e2514bc7"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_lang: $source_lang, word_id: $word_id, region: $region, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve words that are similar
#
# GET /entries/{source_lang}/{word_id}/synonyms
# Docs: https://helloreverb.com/about — find more info here
# Returns: record<metadata: record, results: table<id: string, language: string, lexicalEntries: list, type: string, word: string>>
export def "get-entries-source-lang-word-id-synonyms" [
  source_lang: string@source-lang-completer-1
  word_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter (required, default: 5037d509)
  --app-key: string # App Key Authentication Parameter (required, default: 4dc1aebaa63721f0f8e79a55e2514bc7)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entries/{source_lang}/{word_id}/synonyms"
    path_params: [{name: source_lang, var: source_lang}, {name: word_id, var: word_id}]
    header: [{name: app_id, var: app_id, required: true, default: "5037d509"}, {name: app_key, var: app_key, required: true, default: "4dc1aebaa63721f0f8e79a55e2514bc7"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_lang: $source_lang, word_id: $word_id, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve synonyms and antonyms for a given word
#
# GET /entries/{source_lang}/{word_id}/synonyms;antonyms
# Docs: https://helloreverb.com/about — find more info here
# Returns: record<metadata: record, results: table<id: string, language: string, lexicalEntries: list, type: string, word: string>>
export def "get-entries-source-lang-word-id-synonymsantonyms" [
  source_lang: string@source-lang-completer-1
  word_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter (required, default: 5037d509)
  --app-key: string # App Key Authentication Parameter (required, default: 4dc1aebaa63721f0f8e79a55e2514bc7)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entries/{source_lang}/{word_id}/synonyms;antonyms"
    path_params: [{name: source_lang, var: source_lang}, {name: word_id, var: word_id}]
    header: [{name: app_id, var: app_id, required: true, default: "5037d509"}, {name: app_key, var: app_key, required: true, default: "4dc1aebaa63721f0f8e79a55e2514bc7"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_lang: $source_lang, word_id: $word_id, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Apply filters to response
#
# GET /entries/{source_lang}/{word_id}/{filters}
# Returns: record<metadata: record, results: table<id: string, language: string, lexicalEntries: list, pronunciations: list, type: string, word: string>>
export def "get-entries-source-lang-word-id-filters" [
  source_lang: string@source-lang-completer
  word_id: string
  filters: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter (required, default: 5037d509)
  --app-key: string # App Key Authentication Parameter (required, default: 4dc1aebaa63721f0f8e79a55e2514bc7)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entries/{source_lang}/{word_id}/{filters}"
    path_params: [{name: source_lang, var: source_lang}, {name: word_id, var: word_id}, {name: filters, var: filters}]
    header: [{name: app_id, var: app_id, required: true, default: "5037d509"}, {name: app_key, var: app_key, required: true, default: "4dc1aebaa63721f0f8e79a55e2514bc7"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_lang: $source_lang, word_id: $word_id, filters: $filters, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve translation for a given word
#
# GET /entries/{source_translation_language}/{word_id}/translations={target_translation_language}
# Returns: record<metadata: record, results: table<id: string, language: string, lexicalEntries: list, pronunciations: list, type: string, word: string>>
export def "get-entries-source-translation-language-word-id-translations-target-translation-language" [
  source_translation_language: string@source-translation-language-completer
  word_id: string
  target_translation_language: string@target-translation-language-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter (required, default: 5037d509)
  --app-key: string # App Key Authentication Parameter (required, default: 4dc1aebaa63721f0f8e79a55e2514bc7)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entries/{source_translation_language}/{word_id}/translations={target_translation_language}"
    path_params: [{name: source_translation_language, var: source_translation_language}, {name: word_id, var: word_id}, {name: target_translation_language, var: target_translation_language}]
    header: [{name: app_id, var: app_id, required: true, default: "5037d509"}, {name: app_key, var: app_key, required: true, default: "4dc1aebaa63721f0f8e79a55e2514bc7"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_translation_language: $source_translation_language, word_id: $word_id, target_translation_language: $target_translation_language, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists available filters
#
# GET /filters
# Returns: record<metadata: record, results: record<entries: list<string>, inflections: list<string>, translations: list<string>, wordlist: list<string>>>
export def "get-filters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter (required, default: 5037d509)
  --app-key: string # App Key Authentication Parameter (required, default: 4dc1aebaa63721f0f8e79a55e2514bc7)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/filters"
    header: [{name: app_id, var: app_id, required: true, default: "5037d509"}, {name: app_key, var: app_key, required: true, default: "4dc1aebaa63721f0f8e79a55e2514bc7"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists available filters for specific endpoint
#
# GET /filters/{endpoint}
# Returns: record<metadata: record, results: record<entries: list<string>, inflections: list<string>, translations: list<string>, wordlist: list<string>>>
export def "get-filters-endpoint" [
  endpoint: string@endpoint-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter (required, default: 5037d509)
  --app-key: string # App Key Authentication Parameter (required, default: 4dc1aebaa63721f0f8e79a55e2514bc7)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/filters/{endpoint}"
    path_params: [{name: endpoint, var: endpoint}]
    header: [{name: app_id, var: app_id, required: true, default: "5037d509"}, {name: app_key, var: app_key, required: true, default: "4dc1aebaa63721f0f8e79a55e2514bc7"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    endpoint: $endpoint, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists available grammatical features in a dataset
#
# GET /grammaticalFeatures/{source_language}
# Returns: record<metadata: record, results: record>
export def "get-grammatical-features-source-language" [
  source_language: string@source-language-completer-2
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter (required, default: 5037d509)
  --app-key: string # App Key Authentication Parameter (required, default: 4dc1aebaa63721f0f8e79a55e2514bc7)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/grammaticalFeatures/{source_language}"
    path_params: [{name: source_language, var: source_language}]
    header: [{name: app_id, var: app_id, required: true, default: "5037d509"}, {name: app_key, var: app_key, required: true, default: "4dc1aebaa63721f0f8e79a55e2514bc7"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_language: $source_language, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check a word exists in the dictionary and retrieve its root form
#
# GET /inflections/{source_lang}/{word_id}/{filters}
# Returns: record<metadata: record, results: table<id: string, language: string, lexicalEntries: list, type: string, word: string>>
export def "get-inflections-source-lang-word-id-filters" [
  source_lang: string@source-lang-completer-2
  word_id: string
  filters: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter (required, default: 5037d509)
  --app-key: string # App Key Authentication Parameter (required, default: 4dc1aebaa63721f0f8e79a55e2514bc7)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/inflections/{source_lang}/{word_id}/{filters}"
    path_params: [{name: source_lang, var: source_lang}, {name: word_id, var: word_id}, {name: filters, var: filters}]
    header: [{name: app_id, var: app_id, required: true, default: "5037d509"}, {name: app_key, var: app_key, required: true, default: "4dc1aebaa63721f0f8e79a55e2514bc7"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_lang: $source_lang, word_id: $word_id, filters: $filters, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists available dictionaries
#
# GET /languages
# Returns: record<metadata: record, results: table<region: string, source: string, sourceLanguage: record, targetLanguage: record, type: string>>
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
  --source-language: string@source-language-completer-3 # IANA language code. If provided output will be filtered by sourceLanguage.
  --target-language: string@target-language-completer # IANA language code. If provided output will be filtered by sourceLanguage.
  --app-id: string # App ID Authentication Parameter (required, default: 5037d509)
  --app-key: string # App Key Authentication Parameter (required, default: 4dc1aebaa63721f0f8e79a55e2514bc7)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/languages"
    query: [{name: sourceLanguage, var: source_language}, {name: targetLanguage, var: target_language}]
    header: [{name: app_id, var: app_id, required: true, default: "5037d509"}, {name: app_key, var: app_key, required: true, default: "4dc1aebaa63721f0f8e79a55e2514bc7"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_language: $source_language, target_language: $target_language, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists available lexical categories in a dataset
#
# GET /lexicalcategories/{language}
# Returns: record<metadata: record, results: record>
export def "get-lexicalcategories-language" [
  language: string@language-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter (required, default: 5037d509)
  --app-key: string # App Key Authentication Parameter (required, default: 4dc1aebaa63721f0f8e79a55e2514bc7)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/lexicalcategories/{language}"
    path_params: [{name: language, var: language}]
    header: [{name: app_id, var: app_id, required: true, default: "5037d509"}, {name: app_key, var: app_key, required: true, default: "4dc1aebaa63721f0f8e79a55e2514bc7"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    language: $language, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists available regions in a monolingual dataset
#
# GET /regions/{source_language}
# Returns: record<metadata: record, results: record>
export def "get-regions-source-language" [
  source_language: string@source-language-completer-4
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter (required, default: 5037d509)
  --app-key: string # App Key Authentication Parameter (required, default: 4dc1aebaa63721f0f8e79a55e2514bc7)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/regions/{source_language}"
    path_params: [{name: source_language, var: source_language}]
    header: [{name: app_id, var: app_id, required: true, default: "5037d509"}, {name: app_key, var: app_key, required: true, default: "4dc1aebaa63721f0f8e79a55e2514bc7"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_language: $source_language, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists available registers in a monolingual dataset
#
# GET /registers/{source_language}
# Returns: record<metadata: record, results: record>
export def "get-registers-source-language" [
  source_language: string@source-language-completer-5
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter (required, default: 5037d509)
  --app-key: string # App Key Authentication Parameter (required, default: 4dc1aebaa63721f0f8e79a55e2514bc7)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/registers/{source_language}"
    path_params: [{name: source_language, var: source_language}]
    header: [{name: app_id, var: app_id, required: true, default: "5037d509"}, {name: app_key, var: app_key, required: true, default: "4dc1aebaa63721f0f8e79a55e2514bc7"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_language: $source_language, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists available registers in a bilingual dataset
#
# GET /registers/{source_register_language}/{target_register_language}
# Returns: record<metadata: record, results: record>
export def "get-registers-source-register-language-target-register-language" [
  source_register_language: string@source-register-language-completer
  target_register_language: string@target-register-language-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter (required, default: 5037d509)
  --app-key: string # App Key Authentication Parameter (required, default: 4dc1aebaa63721f0f8e79a55e2514bc7)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/registers/{source_register_language}/{target_register_language}"
    path_params: [{name: source_register_language, var: source_register_language}, {name: target_register_language, var: target_register_language}]
    header: [{name: app_id, var: app_id, required: true, default: "5037d509"}, {name: app_key, var: app_key, required: true, default: "4dc1aebaa63721f0f8e79a55e2514bc7"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_register_language: $source_register_language, target_register_language: $target_register_language, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve possible matches to input
#
# GET /search/{source_lang}
# Docs: https://helloreverb.com/about — find more info here
# Returns: record<metadata: record, results: table<id: string, matchString: string, matchType: string, region: string, word: string>>
export def "get-search-source-lang" [
  source_lang: string@source-lang-completer-3
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Search string (default: eye)
  --prefix: oneof<nothing, bool> # Set prefix to true if you'd like to get results only starting with search string. (default: false)
  --regions: string # If searching in English, filter words with specific region(s) either 'us' or 'gb'.
  --limit: string # Limit the number of results per response. Default and maximum limit is 5000.
  --offset: string # Offset the start number of the result.
  --app-id: string # App ID Authentication Parameter (required, default: 5037d509)
  --app-key: string # App Key Authentication Parameter (required, default: 4dc1aebaa63721f0f8e79a55e2514bc7)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search/{source_lang}"
    path_params: [{name: source_lang, var: source_lang}]
    query: [{name: q, var: q}, {name: prefix, var: prefix}, {name: regions, var: regions}, {name: limit, var: limit}, {name: offset, var: offset}]
    header: [{name: app_id, var: app_id, required: true, default: "5037d509"}, {name: app_key, var: app_key, required: true, default: "4dc1aebaa63721f0f8e79a55e2514bc7"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_lang: $source_lang, q: $q, prefix: $prefix, regions: $regions, limit: $limit, offset: $offset, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve possible translation matches to input
#
# GET /search/{source_search_language}/translations={target_search_language}
# Docs: https://helloreverb.com/about — find more info here
# Returns: record<metadata: record, results: table<id: string, matchString: string, matchType: string, region: string, word: string>>
export def "get-search-source-search-language-translations-target-search-language" [
  source_search_language: string@source-search-language-completer
  target_search_language: string@target-search-language-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Search string. (default: eye)
  --prefix: oneof<nothing, bool> # Set prefix to true if you'd like to get results only starting with search string. (default: false)
  --regions: string # Filter words with specific region(s) E.g., regions=us. For now gb, us are available for en language.
  --limit: string # Limit the number of results per response. Default and maximum limit is 5000.
  --offset: string # Offset the start number of the result.
  --app-id: string # App ID Authentication Parameter (required, default: 5037d509)
  --app-key: string # App Key Authentication Parameter (required, default: 4dc1aebaa63721f0f8e79a55e2514bc7)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search/{source_search_language}/translations={target_search_language}"
    path_params: [{name: source_search_language, var: source_search_language}, {name: target_search_language, var: target_search_language}]
    query: [{name: q, var: q}, {name: prefix, var: prefix}, {name: regions, var: regions}, {name: limit, var: limit}, {name: offset, var: offset}]
    header: [{name: app_id, var: app_id, required: true, default: "5037d509"}, {name: app_key, var: app_key, required: true, default: "4dc1aebaa63721f0f8e79a55e2514bc7"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_search_language: $source_search_language, target_search_language: $target_search_language, q: $q, prefix: $prefix, regions: $regions, limit: $limit, offset: $offset, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the frequency of ngrams (1-4) derived from a corpus
#
# GET /stats/frequency/ngrams/{source_lang}/{corpus}/{ngram-size}/
# Returns: record<metadata: record, results: table<frequency: int, tokens: list>>
export def "get-stats-frequency-ngrams-source-lang-corpus-ngram-size" [
  source_lang: string
  corpus: string
  ngram_size: string
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
  --tokens: string # List of tokens to filter. The tokens are separated by spaces, the list items are separated by comma (e.g., for bigrams (n=2) tokens=this is,this was, this will) (default: a word)
  --contains: string # Find ngrams containing the given token(s). Use comma or space as token separators; the order of tokens is irrelevant.
  --punctuation: string # Flag specifying whether to lookup ngrams that include punctuation or not (possible values are "true" and "false"; default is "false")
  --format: string # Option specifying whether tokens should be returned as a single string (option "google") or as a list of strings (option "oup") (default: oup)
  --min-frequency: int # Restrict the query to entries with frequency of at least `minFrequency` (format: int64)
  --max-frequency: int # Restrict the query to entries with frequency of at most `maxFrequency` (format: int64)
  --min-document-frequency: int # Restrict the query to entries that appear in at least `minDocumentFrequency` documents (format: int64)
  --max-document-frequency: int # Restrict the query to entries that appera in at most `maxDocumentFrequency` documents (format: int64)
  --collate: string # collate the results by wordform, trueCase, lemma, lexicalCategory. Multiple values can be separated by commas (e.g., collate=trueCase,lemma,lexicalCategory).
  --sort: string # sort the resulting list by wordform, trueCase, lemma, lexicalCategory, frequency, normalizedFrequency. Descending order is achieved by prepending the value with the minus sign ('-'). Multiple values can be separated by commas (e.g., sort=lexicalCategory,-frequency)
  --offset: int # pagination - results offset (format: int64, default: 0)
  --limit: int # pagination - results limit (format: int64, default: 100)
  --app-id: string # App ID Authentication Parameter (required, default: 5037d509)
  --app-key: string # App Key Authentication Parameter (required, default: 4dc1aebaa63721f0f8e79a55e2514bc7)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/stats/frequency/ngrams/{source_lang}/{corpus}/{ngram-size}/"
    path_params: [{name: source_lang, var: source_lang}, {name: corpus, var: corpus}, {name: ngram-size, var: ngram_size}]
    query: [{name: tokens, var: tokens}, {name: contains, var: contains}, {name: punctuation, var: punctuation}, {name: format, var: format}, {name: minFrequency, var: min_frequency}, {name: maxFrequency, var: max_frequency}, {name: minDocumentFrequency, var: min_document_frequency}, {name: maxDocumentFrequency, var: max_document_frequency}, {name: collate, var: collate}, {name: sort, var: sort}, {name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: app_id, var: app_id, required: true, default: "5037d509"}, {name: app_key, var: app_key, required: true, default: "4dc1aebaa63721f0f8e79a55e2514bc7"}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    source_lang: $source_lang, corpus: $corpus, ngram_size: $ngram_size, tokens: $tokens, contains: $contains, punctuation: $punctuation, format: $format, min_frequency: $min_frequency, max_frequency: $max_frequency, min_document_frequency: $min_document_frequency, max_document_frequency: $max_document_frequency, collate: $collate, sort: $sort, offset: $offset, limit: $limit, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve the frequency of a word derived from a corpus.
#
# GET /stats/frequency/word/{source_lang}/
# Returns: record<metadata: record, result: record<frequency: int, lemma: string, lexicalCategory: string, matchCount: int, normalizedFrequency: int, trueCase: string, wordform: string>>
export def "get-stats-frequency-word-source-lang" [
  source_lang: string
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
  --corpus: string # For corpora other than 'nmc' (New Monitor Corpus) please contact api@oxforddictionaries.com (default: nmc)
  --wordform: string # The written form of the word to look up (preserving case e.g., Books vs books)
  --true-case: string # The written form of the word to look up with normalised case (Books --> books)
  --lemma: string # The lemma of the word to look up (e.g., Book, booked, books all have the lemma "book") (default: test)
  --lexical-category: string # The lexical category of the word(s) to look up (e.g., noun or verb)
  --app-id: string # App ID Authentication Parameter (required, default: 5037d509)
  --app-key: string # App Key Authentication Parameter (required, default: 4dc1aebaa63721f0f8e79a55e2514bc7)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/stats/frequency/word/{source_lang}/"
    path_params: [{name: source_lang, var: source_lang}]
    query: [{name: corpus, var: corpus}, {name: wordform, var: wordform}, {name: trueCase, var: true_case}, {name: lemma, var: lemma}, {name: lexicalCategory, var: lexical_category}]
    header: [{name: app_id, var: app_id, required: true, default: "5037d509"}, {name: app_key, var: app_key, required: true, default: "4dc1aebaa63721f0f8e79a55e2514bc7"}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    source_lang: $source_lang, corpus: $corpus, wordform: $wordform, true_case: $true_case, lemma: $lemma, lexical_category: $lexical_category, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a list of frequencies of a word/words derived from a corpus.
#
# GET /stats/frequency/words/{source_lang}/
# Returns: record<metadata: record, results: table<frequency: int, lemma: string, lexicalCategory: string, normalizedFrequency: int, trueCase: string, wordform: string>>
export def "get-stats-frequency-words-source-lang" [
  source_lang: string
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
  --corpus: string # For corpora other than 'nmc' (New Monitor Corpus) please contact api@oxforddictionaries.com (default: nmc)
  --wordform: string # The written form of the word to look up (preserving case e.g., Book vs book)
  --true-case: string # The written form of the word to look up with normalised case (Books --> books)
  --lemma: string # The lemma of the word to look up (e.g., Book, booked, books all have the lemma "book") (default: test)
  --lexical-category: string # The lexical category of the word(s) to look up (e.g., adjective or noun)
  --grammatical-features: string # The grammatical features of the word(s) to look up entered as a list of k:v (e.g., degree_type:comparative)
  --sort: string # sort the resulting list by wordform, trueCase, lemma, lexicalCategory, frequency, normalizedFrequency. Descending order is achieved by prepending the value with the minus sign ('-'). Multiple values can be separated by commas (e.g., sort=lexicalCategory,-frequency)
  --collate: string # collate the results by wordform, trueCase, lemma, lexicalCategory. Multiple values can be separated by commas (e.g., collate=trueCase,lemma,lexicalCategory).
  --min-frequency: int # Restrict the query to entries with frequency of at least `minFrequency` (format: int64)
  --max-frequency: int # Restrict the query to entries with frequency of at most `maxFrequency` (format: int64)
  --min-normalized-frequency: float # Restrict the query to entries with frequency of at least `minNormalizedFrequency` (format: float)
  --max-normalized-frequency: float # Restrict the query to entries with frequency of at most `maxNormalizedFrequency` (format: float)
  --offset: int # pagination - results offset (format: int64, default: 0)
  --limit: int # pagination - results limit (format: int64, default: 100)
  --app-id: string # App ID Authentication Parameter (required, default: 5037d509)
  --app-key: string # App Key Authentication Parameter (required, default: 4dc1aebaa63721f0f8e79a55e2514bc7)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/stats/frequency/words/{source_lang}/"
    path_params: [{name: source_lang, var: source_lang}]
    query: [{name: corpus, var: corpus}, {name: wordform, var: wordform}, {name: trueCase, var: true_case}, {name: lemma, var: lemma}, {name: lexicalCategory, var: lexical_category}, {name: grammaticalFeatures, var: grammatical_features}, {name: sort, var: sort}, {name: collate, var: collate}, {name: minFrequency, var: min_frequency}, {name: maxFrequency, var: max_frequency}, {name: minNormalizedFrequency, var: min_normalized_frequency}, {name: maxNormalizedFrequency, var: max_normalized_frequency}, {name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: app_id, var: app_id, required: true, default: "5037d509"}, {name: app_key, var: app_key, required: true, default: "4dc1aebaa63721f0f8e79a55e2514bc7"}]
    accept: ["application/json", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    source_lang: $source_lang, corpus: $corpus, wordform: $wordform, true_case: $true_case, lemma: $lemma, lexical_category: $lexical_category, grammatical_features: $grammatical_features, sort: $sort, collate: $collate, min_frequency: $min_frequency, max_frequency: $max_frequency, min_normalized_frequency: $min_normalized_frequency, max_normalized_frequency: $max_normalized_frequency, offset: $offset, limit: $limit, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve list of words for category with advanced options
#
# GET /wordlist/{source_lang}/{filters_advanced}
# Returns: record<metadata: record, results: table<id: string, matchString: string, matchType: string, region: string, word: string>>
export def "get-wordlist-source-lang-filters-advanced" [
  source_lang: string@source-lang-completer-3
  filters_advanced: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --exclude: string # Semicolon separated list of parameters-value pairs (same as filters). Excludes headwords that have any senses in specified exclusion attributes (lexical categories, domains, etc.) from results.
  --exclude-senses: string # Semicolon separated list of parameters-value pairs (same as filters). Excludes only those senses of a particular headword that match specified exclusion attributes (lexical categories, domains, etc.) from results but includes the headword if it has other permitted senses.
  --exclude-prime-senses: string # Semicolon separated list of parameters-value pairs (same as filters). Excludes a headword only if the primary sense matches the specified exclusion attributes (registers, domains only).
  --word-length: string # Parameter to speficy the minimum (>), exact or maximum (<) length of the words required. E.g., >5 - more than 5 chars; <4 - less than 4 chars; >5<10 - from 5 to 10 chars; 3 - exactly 3 chars. (default: >5,<10)
  --prefix: string # Filter words that start with prefix parameter (default: goal)
  --exact: oneof<nothing, bool> # If exact=true wordlist returns a list of entries that exactly matches the search string. Otherwise wordlist lists entries that start with prefix string. (default: false)
  --limit: string # Limit the number of results per response. Default and maximum limit is 5000.
  --offset: string # Offset the start number of the result.
  --app-id: string # App ID Authentication Parameter (required, default: 5037d509)
  --app-key: string # App Key Authentication Parameter (required, default: 4dc1aebaa63721f0f8e79a55e2514bc7)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/wordlist/{source_lang}/{filters_advanced}"
    path_params: [{name: source_lang, var: source_lang}, {name: filters_advanced, var: filters_advanced}]
    query: [{name: exclude, var: exclude}, {name: exclude_senses, var: exclude_senses}, {name: exclude_prime_senses, var: exclude_prime_senses}, {name: word_length, var: word_length}, {name: prefix, var: prefix}, {name: exact, var: exact}, {name: limit, var: limit}, {name: offset, var: offset}]
    header: [{name: app_id, var: app_id, required: true, default: "5037d509"}, {name: app_key, var: app_key, required: true, default: "4dc1aebaa63721f0f8e79a55e2514bc7"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_lang: $source_lang, filters_advanced: $filters_advanced, exclude: $exclude, exclude_senses: $exclude_senses, exclude_prime_senses: $exclude_prime_senses, word_length: $word_length, prefix: $prefix, exact: $exact, limit: $limit, offset: $offset, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of words in a category
#
# GET /wordlist/{source_lang}/{filters_basic}
# Returns: record<metadata: record, results: table<id: string, matchString: string, matchType: string, region: string, word: string>>
export def "get-wordlist-source-lang-filters-basic" [
  source_lang: string@source-lang-completer-3
  filters_basic: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Limit the number of results per response. Default and maximum limit is 5000.
  --offset: string # Offset the start number of the result
  --app-id: string # App ID Authentication Parameter (required, default: 5037d509)
  --app-key: string # App Key Authentication Parameter (required, default: 4dc1aebaa63721f0f8e79a55e2514bc7)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/wordlist/{source_lang}/{filters_basic}"
    path_params: [{name: source_lang, var: source_lang}, {name: filters_basic, var: filters_basic}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    header: [{name: app_id, var: app_id, required: true, default: "5037d509"}, {name: app_key, var: app_key, required: true, default: "4dc1aebaa63721f0f8e79a55e2514bc7"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_lang: $source_lang, filters_basic: $filters_basic, limit: $limit, offset: $offset, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
