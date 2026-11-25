# Auto-generated client for API iSendPro v1.1.1
# Source: https://api.apis.guru/v2/specs/isendpro.com/1.1.1/openapi.json
# Auth: --token flag or $env.API_ISENDPRO_TOKEN

const CLIENT = {
  base_url: "https://apirest.isendpro.com/cgi-bin"
  token_env_var: "API_ISENDPRO_TOKEN"
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

def base-url-completer [] { ["https://apirest.isendpro.com/cgi-bin" "http://apirest.isendpro.com/cgi-bin"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def rapport-campagne-completer [] { ["1"] }
def accept-completer [] { ["application/json" "file"] }
def comptage-completer [] { ["1"] }
def gmt-zone-completer [] { ["Africa/Abidjan" "Africa/Addis_Ababa" "Africa/Algiers" "Africa/Blantyre" "Africa/Cairo" "Africa/Windhoek" "America/Adak" "America/Anchorage" "America/Araguaina" "America/Argentina/Buenos_Aires" "America/Belize" "America/Bogota" "America/Campo_Grande" "America/Cancun" "America/Caracas" "America/Chicago" "America/Chihuahua" "America/Dawson_Creek" "America/Denver" "America/Ensenada" "America/Glace_Bay" "America/Godthab" "America/Goose_Bay" "America/Havana" "America/La_Paz" "America/Los_Angeles" "America/Miquelon" "America/Montevideo" "America/New_York" "America/Noronha" "America/Santiago" "America/Sao_Paulo" "America/St_Johns" "Asia/Anadyr" "Asia/Bangkok" "Asia/Beirut" "Asia/Damascus" "Asia/Dhaka" "Asia/Dubai" "Asia/Gaza" "Asia/Hong_Kong" "Asia/Irkutsk" "Asia/Jerusalem" "Asia/Kabul" "Asia/Katmandu" "Asia/Kolkata" "Asia/Krasnoyarsk" "Asia/Magadan" "Asia/Novosibirsk" "Asia/Rangoon" "Asia/Seoul" "Asia/Tashkent" "Asia/Tehran" "Asia/Tokyo" "Asia/Vladivostok" "Asia/Yakutsk" "Asia/Yekaterinburg" "Asia/Yerevan" "Atlantic/Azores" "Atlantic/Cape_Verde" "Atlantic/Stanley" "Australia/Adelaide" "Australia/Brisbane" "Australia/Darwin" "Australia/Eucla" "Australia/Hobart" "Australia/Lord_Howe" "Australia/Perth" "Chile/EasterIsland" "Etc/GMT+10" "Etc/GMT+8" "Etc/GMT-11" "Etc/GMT-12" "Europe/Amsterdam" "Europe/Belfast" "Europe/Belgrade" "Europe/Brussels" "Europe/Dublin" "Europe/Lisbon" "Europe/London" "Europe/Minsk" "Europe/Moscow" "Pacific/Auckland" "Pacific/Chatham" "Pacific/Gambier" "Pacific/Kiritimati" "Pacific/Marquesas" "Pacific/Midway" "Pacific/Norfolk" "Pacific/Tongatapu"] }
def num-azur-completer [] { ["1"] }
def smslong-completer [] { ["999"] }
def accept-completer-1 [] { ["application/json" "etat"] }
def credit-completer [] { ["1" "2"] }
def del-liste-noire-completer [] { ["1"] }
def get-liste-noire-completer [] { ["1"] }
def get-hlr-completer [] { ["1"] }
def repertoire-edit-completer [] { ["create"] }
def repertoire-edit-completer-1 [] { ["add" "del"] }
def setliste-noire-completer [] { ["1"] }
def accept-completer-2 [] { ["application/json" "exemple1"] }
def sub-account-edit-completer [] { ["addAccount"] }
def sub-account-edit-completer-1 [] { ["addCredit" "setPrice" "setRestriction"] }
def sub-account-restriction-stop-completer [] { ["0" "1"] }
def sub-account-restriction-time-completer [] { ["0" "1"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-campagne: "binary"
    comptage: "record<etat: record<etat: list<record>>>"
    get-credit: "record<etat: record<credit: float, quantite: string>>"
    del-liste-noire: "record<etat: record<etat: list<record>>>"
    get-liste-noire: "binary"
    get-hlr: "record<etat: record<etat: list<record>>>"
    repertoire-crea: "record<etat: record<etat: list<record>>>"
    repertoire: "record<etat: record<etat: list<record>>>"
    set-liste-noire: "record<etat: record<etat: list<record>>>"
    add-shortlink: "record<etat: record<etat: list<record>>>"
    send-sms: "record<etat: record<etat: list<record>>>"
    send-sms-multi: "record<etat: record<etat: list<record>>>"
    subaccount-add: "record<etat: record<etat: list<record>>>"
    subaccount-edit: "record<etat: record<etat: list<record>>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-campagne" "comptage" "get-credit" "del-liste-noire" "get-liste-noire" "get-hlr" "repertoire-crea" "repertoire" "set-liste-noire" "add-shortlink" "send-sms" "send-sms-multi" "subaccount-add" "subaccount-edit" "commands"] | sort) } | get name | first)
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

# Retourne les SMS envoyés sur une période donnée
#
# GET /campagne
# Returns: binary
# operationId: getCampagne
export def "get-campagne" [
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
  --keyid: string # Clé API (required)
  --rapport-campagne: string@rapport-campagne-completer # Doit valoir "1" (required)
  --date-deb: string # date de debut au format YYYY-MM-DD hh:mm (required)
  --date-fin: string # date de fin au format YYYY-MM-DD hh:mm (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/campagne"
    query: [{name: keyid, var: keyid, required: true}, {name: rapportCampagne, var: rapport_campagne, required: true, default: "1"}, {name: date_deb, var: date_deb, required: true}, {name: date_fin, var: date_fin, required: true}]
    accept: ["application/json", file]
    ok: [200]
    auth: bearer
  } {
    keyid: $keyid, rapport_campagne: $rapport_campagne, date_deb: $date_deb, date_fin: $date_fin
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Compter le nombre de caractère
#
# POST /comptage
# Returns: record<etat: record<etat: list<record>>>
# operationId: comptage
export def "comptage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  comptage: string@comptage-completer # default: 1
  --date-envoi: string # Date d'envoi au format YYYY-MM-DD hh:mm . Ce paramètre est optionnel, si il est omis l'envoi est réalisé immédiatement.
  --emetteur: string # - L'emetteur doit être une chaîne alphanumérique comprise entre 4 et 11 caractères. - Les caractères acceptés sont les chiffres entre 0 et 9, les lettres entre A et Z et l’espace. - Il ne peut pas comporter uniquement des chiffres. - Pour la modification de l'émetteur et dans le cadre de campagnes commerciales, les opérateurs imposent contractuellement d'ajouter en fin de message le texte "STOP XXXXX". De ce fait, le message envoyé ne pourra excéder une longueur de 148 caractères au lieu des 160 caractères, le « STOP » étant rajouté automatiquement.
  --gmt-zone: string@gmt-zone-completer # Fuseau horaire de la date d'envoi
  keyid: string # Clé API
  --nostop: string # Si le message n’est pas à but commercial, vous pouvez faire une demande pour retirer l’obligation du STOP. Une fois votre demande validée par nos services, vous pourrez supprimer la mention STOP SMS en ajoutant nostop = "1"
  num: string # Numero de téléphone au format national (exemple 0680010203) ou international (example 33680010203)
  --num-azur: string@num-azur-completer
  sms: string # Message à envoyer aux destinataires. Le message doit être encodé au format utf-8 et ne contenir que des caractères existant dans l'alphabet GSM. Il est également possible d'envoyer (à l'étranger uniquement) des SMS en UCS-2, cf paramètre ucs2 pour plus de détails.
  --smslong: string@smslong-completer # Le SMS long permet de dépasser la limite de 160 caractères en envoyant un message constitué de plusieurs SMS. Il est possible d’envoyer jusqu’à 6 SMS concaténés pour une longueur totale maximale de 918 caractères par message. Pour des raisons technique, la limite par SMS concaténé étant de 153 caractères. En cas de modification de l’émetteur, il faut considérer l’ajout automatique de 12 caractères du « STOP SMS ». Pour envoyer un smslong, il faut ajouter le paramètre smslong aux appels. La valeur de SMS doit être le nombre maximum de sms concaténé autorisé. Pour ne pas avoir ce message d’erreur et obtenir un calcul dynamique du nombre de SMS alors il faut renseigner smslong = "999" (default: 999)
  --tracker: string # Le tracker doit être une chaine alphanumérique de moins de 50 caractères. Ce tracker sera ensuite renvoyé en paramètre des urls pour les retours des accusés de réception.
  --ucs2: string # Il est également possible d’envoyer des SMS en alphabet non latin (russe, chinois, arabe, etc) sur les numéros hors France métropolitaine. Pour ce faire, la requête devrait être encodée au format UTF-8 et contenir l’argument ucs2 = "1" Du fait de contraintes techniques, 1 SMS unique ne pourra pas dépasser 70 caractères (au lieu des 160 usuels) et dans le cas de SMS long, chaque sms ne pourra dépasser 67 caractères.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/comptage"
    body: {content_type: "application/json", kind: json, fields: [{name: comptage, var: comptage}, {name: date_envoi, var: date_envoi}, {name: emetteur, var: emetteur}, {name: gmt_zone, var: gmt_zone}, {name: keyid, var: keyid}, {name: nostop, var: nostop}, {name: num, var: num}, {name: numAzur, var: num_azur}, {name: sms, var: sms}, {name: smslong, var: smslong}, {name: tracker, var: tracker}, {name: ucs2, var: ucs2}]}
    accept: ["application/json", etat]
    ok: [200]
    auth: bearer
  } {
    comptage: $comptage, date_envoi: $date_envoi, emetteur: $emetteur, gmt_zone: $gmt_zone, keyid: $keyid, nostop: $nostop, num: $num, num_azur: $num_azur, sms: $sms, smslong: $smslong, tracker: $tracker, ucs2: $ucs2
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Interrogation credit
#
# GET /credit
# Returns: record<etat: record<credit: float, quantite: string>>
# operationId: getCredit
export def "get-credit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --keyid: string # Clé API (required, format: string)
  --credit: string@credit-completer # Type de reponse demandée, 1 pour euro, 2 pour euro + estimation quantité (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/credit"
    query: [{name: keyid, var: keyid, required: true}, {name: credit, var: credit, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    keyid: $keyid, credit: $credit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ajoute un numero en liste noire
#
# POST /dellistenoire
# Returns: record<etat: record<etat: list<record>>>
# operationId: delListeNoire
export def "del-liste-noire" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --keyid: string # Clé API (required, format: string)
  --del-liste-noire: string@del-liste-noire-completer # Doit valoir "1" (required)
  --num: string # numéro de mobile à supprimer (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/dellistenoire"
    query: [{name: keyid, var: keyid, required: true}, {name: delListeNoire, var: del_liste_noire, required: true, default: "1"}, {name: num, var: num, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    keyid: $keyid, del_liste_noire: $del_liste_noire, num: $num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retourne le liste noire
#
# POST /getlistenoire
# Returns: binary
# operationId: getListeNoire
export def "get-liste-noire" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --keyid: string # Clé API (required, format: string)
  --get-liste-noire: string@get-liste-noire-completer # Doit valoir "1" (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/getlistenoire"
    query: [{name: keyid, var: keyid, required: true}, {name: getListeNoire, var: get_liste_noire, required: true, default: "1"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    keyid: $keyid, get_liste_noire: $get_liste_noire
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Vérifier la validité d'un numéro
#
# POST /hlr
# Returns: record<etat: record<etat: list<record>>>
# operationId: getHlr
export def "get-hlr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  get_hlr: string@get-hlr-completer # Doit valoir "1" (default: 1)
  keyid: string # Clé API
  num: list<string> # liste de numéros de téléphone
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/hlr"
    body: {content_type: "application/json", kind: json, fields: [{name: getHLR, var: get_hlr}, {name: keyid, var: keyid}, {name: num, var: num}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    get_hlr: $get_hlr, keyid: $keyid, num: $num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gestion repertoire (creation)
#
# POST /repertoire
# Returns: record<etat: record<etat: list<record>>>
# operationId: repertoireCrea
export def "repertoire-crea" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  keyid: string # Clé API
  repertoire_edit: string@repertoire-edit-completer # Action à réaliser doit valoir "create" ici. (default: create)
  repertoire_nom: string # Nom du répertoire (libellé) à créer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repertoire"
    body: {content_type: "application/json", kind: json, fields: [{name: keyid, var: keyid}, {name: repertoireEdit, var: repertoire_edit}, {name: repertoireNom, var: repertoire_nom}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    keyid: $keyid, repertoire_edit: $repertoire_edit, repertoire_nom: $repertoire_nom
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gestion repertoire (modification)
#
# PUT /repertoire
# Returns: record<etat: record<etat: list<record>>>
# operationId: repertoire
export def "repertoire" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --champ1: list<string> # Noms des contact
  --champ10: list<string> # Champs I des contacts
  --champ11: list<string> # Champs J des contacts
  --champ12: list<string> # Champs K des contacts
  --champ13: list<string> # Champs L des contacts
  --champ14: list<string> # Champs M des contacts
  --champ15: list<string> # Champs N des contacts
  --champ16: list<string> # Champs O des contacts
  --champ17: list<string> # Champs P des contacts
  --champ18: list<string> # Champs Q des contacts
  --champ19: list<string> # Champs R des contacts
  --champ2: list<string> # Champs A des contacts
  --champ20: list<string> # Champs S des contacts
  --champ21: list<string> # Champs T des contacts
  --champ22: list<string> # Champs U des contacts
  --champ23: list<string> # Champs V des contacts
  --champ24: list<string> # Champs W des contacts
  --champ25: list<string> # Champs X des contacts
  --champ26: list<string> # Champs Y des contacts
  --champ27: list<string> # Champs Z des contacts
  --champ3: list<string> # Champs B des contacts
  --champ4: list<string> # Champs C des contacts
  --champ5: list<string> # Champs D des contacts
  --champ6: list<string> # Champs E des contacts
  --champ7: list<string> # Champs F des contacts
  --champ8: list<string> # Champs G des contacts
  --champ9: list<string> # Champs H des contacts
  keyid: string # Clé API
  num: list<string> # liste des numéros des téléphone à ajouter ou supprimer
  repertoire_edit: string@repertoire-edit-completer-1 # action à réaliser, "add" pour l'ajout de numéros, "del" pour la suppression de numéros
  repertoire_id: string # repertoireId du répertoire cible
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/repertoire"
    body: {content_type: "application/json", kind: json, fields: [{name: champ1, var: champ1}, {name: champ10, var: champ10}, {name: champ11, var: champ11}, {name: champ12, var: champ12}, {name: champ13, var: champ13}, {name: champ14, var: champ14}, {name: champ15, var: champ15}, {name: champ16, var: champ16}, {name: champ17, var: champ17}, {name: champ18, var: champ18}, {name: champ19, var: champ19}, {name: champ2, var: champ2}, {name: champ20, var: champ20}, {name: champ21, var: champ21}, {name: champ22, var: champ22}, {name: champ23, var: champ23}, {name: champ24, var: champ24}, {name: champ25, var: champ25}, {name: champ26, var: champ26}, {name: champ27, var: champ27}, {name: champ3, var: champ3}, {name: champ4, var: champ4}, {name: champ5, var: champ5}, {name: champ6, var: champ6}, {name: champ7, var: champ7}, {name: champ8, var: champ8}, {name: champ9, var: champ9}, {name: keyid, var: keyid}, {name: num, var: num}, {name: repertoireEdit, var: repertoire_edit}, {name: repertoireId, var: repertoire_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    champ1: $champ1, champ10: $champ10, champ11: $champ11, champ12: $champ12, champ13: $champ13, champ14: $champ14, champ15: $champ15, champ16: $champ16, champ17: $champ17, champ18: $champ18, champ19: $champ19, champ2: $champ2, champ20: $champ20, champ21: $champ21, champ22: $champ22, champ23: $champ23, champ24: $champ24, champ25: $champ25, champ26: $champ26, champ27: $champ27, champ3: $champ3, champ4: $champ4, champ5: $champ5, champ6: $champ6, champ7: $champ7, champ8: $champ8, champ9: $champ9, keyid: $keyid, num: $num, repertoire_edit: $repertoire_edit, repertoire_id: $repertoire_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ajoute un numero en liste noire
#
# POST /setlistenoire
# Returns: record<etat: record<etat: list<record>>>
# operationId: setListeNoire
export def "set-liste-noire" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --keyid: string # Clé API (required, format: string)
  --setliste-noire: string@setliste-noire-completer # Doit valoir "1" (required)
  --num: string # numéro de mobile à insérer en liste noire (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/setlistenoire"
    query: [{name: keyid, var: keyid, required: true}, {name: setlisteNoire, var: setliste_noire, required: true, default: "1"}, {name: num, var: num, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    keyid: $keyid, setliste_noire: $setliste_noire, num: $num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# add a shortlink
#
# POST /shortlink
# Returns: record<etat: record<etat: list<record>>>
# operationId: addShortlink
export def "add-shortlink" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
  keyid: string
  shortlink: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/shortlink"
    body: {content_type: "application/json", kind: json, fields: [{name: keyid, var: keyid}, {name: shortlink, var: shortlink}]}
    accept: ["application/json", exemple1]
    ok: [200]
    auth: bearer
  } {
    keyid: $keyid, shortlink: $shortlink
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Envoyer un sms
#
# POST /sms
# Returns: record<etat: record<etat: list<record>>>
# operationId: sendSms
export def "send-sms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --date-envoi: string # Date d'envoi au format YYYY-MM-DD hh:mm . Ce paramètre est optionnel, si il est omis l'envoi est réalisé immédiatement.
  --emetteur: string # - L'emetteur doit être une chaîne alphanumérique comprise entre 4 et 11 caractères. - Les caractères acceptés sont les chiffres entre 0 et 9, les lettres entre A et Z et l’espace. - Il ne peut pas comporter uniquement des chiffres. - Pour la modification de l'émetteur et dans le cadre de campagnes commerciales, les opérateurs imposent contractuellement d'ajouter en fin de message le texte "STOP XXXXX". De ce fait, le message envoyé ne pourra excéder une longueur de 148 caractères au lieu des 160 caractères, le « STOP » étant rajouté automatiquement.
  --gmt-zone: string@gmt-zone-completer # Fuseau horaire de la date d'envoi
  keyid: string # Clé API
  --nostop: string # Si le message n’est pas à but commercial, vous pouvez faire une demande pour retirer l’obligation du STOP. Une fois votre demande validée par nos services, vous pourrez supprimer la mention STOP SMS en ajoutant nostop = "1"
  num: string # Numero de téléphone au format national (exemple 0680010203) ou international (example 33680010203)
  --num-azur: string@num-azur-completer
  sms: string # Message à envoyer aux destinataires. Le message doit être encodé au format utf-8 et ne contenir que des caractères existant dans l'alphabet GSM. Il est également possible d'envoyer (à l'étranger uniquement) des SMS en UCS-2, cf paramètre ucs2 pour plus de détails.
  --smslong: string # Le SMS long permet de dépasser la limite de 160 caractères en envoyant un message constitué de plusieurs SMS. Il est possible d’envoyer jusqu’à 6 SMS concaténés pour une longueur totale maximale de 918 caractères par message. Pour des raisons technique, la limite par SMS concaténé étant de 153 caractères. En cas de modification de l’émetteur, il faut considérer l’ajout automatique de 12 caractères du « STOP SMS ». Pour envoyer un smslong, il faut ajouter le paramètre smslong aux appels. La valeur de SMS doit être le nombre maximum de sms concaténé autorisé. Pour ne pas avoir ce message d’erreur et obtenir un calcul dynamique du nombre de SMS alors il faut renseigner smslong = "999"
  --tracker: string # Le tracker doit être une chaine alphanumérique de moins de 50 caractères. Ce tracker sera ensuite renvoyé en paramètre des urls pour les retours des accusés de réception.
  --ucs2: string # Il est également possible d’envoyer des SMS en alphabet non latin (russe, chinois, arabe, etc) sur les numéros hors France métropolitaine. Pour ce faire, la requête devrait être encodée au format UTF-8 et contenir l’argument ucs2 = "1" Du fait de contraintes techniques, 1 SMS unique ne pourra pas dépasser 70 caractères (au lieu des 160 usuels) et dans le cas de SMS long, chaque sms ne pourra dépasser 67 caractères.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sms"
    body: {content_type: "application/json", kind: json, fields: [{name: date_envoi, var: date_envoi}, {name: emetteur, var: emetteur}, {name: gmt_zone, var: gmt_zone}, {name: keyid, var: keyid}, {name: nostop, var: nostop}, {name: num, var: num}, {name: numAzur, var: num_azur}, {name: sms, var: sms}, {name: smslong, var: smslong}, {name: tracker, var: tracker}, {name: ucs2, var: ucs2}]}
    accept: ["application/json", etat]
    ok: [200]
    auth: bearer
  } {
    date_envoi: $date_envoi, emetteur: $emetteur, gmt_zone: $gmt_zone, keyid: $keyid, nostop: $nostop, num: $num, num_azur: $num_azur, sms: $sms, smslong: $smslong, tracker: $tracker, ucs2: $ucs2
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Envoyer des SMS
#
# POST /smsmulti
# Returns: record<etat: record<etat: list<record>>>
# operationId: sendSmsMulti
export def "send-sms-multi" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --date-envoi: string # Paramètre optionnel, date d'envoi au format YYYY-MM-DD hh:mm
  --emetteur: string # L'emetteur doit être une chaîne alphanumérique comprise entre 4 et 11 caractères. Les caractères acceptés sont les chiffres entre 0 et 9, les lettres entre A et Z et l’espace. Il ne peut pas comporter uniquement des chiffres. Pour la modification de l’émetteur et dans le cadre de campagnes commerciales, les opérateurs imposent contractuellement d’ajouter en fin de message le texte suivant : STOP XXXXX De ce fait, le message envoyé ne pourra excéder une longueur de 148 caractères au lieu des 160 caractères, le « STOP » étant rajouté automatiquement.
  --gmt-zone: string@gmt-zone-completer # Fuseau horaire de la date d'envoi
  keyid: string # Clé API
  --nostop: string # Si le message n’est pas à but commercial, vous pouvez faire une demande pour retirer l’obligation du STOP. Une fois votre demande validée par nos services, vous pourrez supprimer la mention STOP SMS en ajoutant nostop = "1"
  num: list<string>
  --num-azur: string@num-azur-completer
  --repertoire-id: string # Id du repertoire
  sms: list<string>
  --smslong: string # Le SMS long permet de dépasser la limite de 160 caractères en envoyant un message constitué de plusieurs SMS. Il est possible d’envoyer jusqu’à 6 SMS concaténés pour une longueur totale maximale de 918 caractères par message. Pour des raisons technique, la limite par SMS concaténé étant de 153 caractères. En cas de modification de l’émetteur, il faut considérer l’ajout automatique de 12 caractères du « STOP SMS ». Pour envoyer un smslong, il faut ajouter le paramètre smslong aux appels. La valeur de SMS doit être le nombre maximum de sms concaténé autorisé. Pour ne pas avoir ce message d’erreur et obtenir un calcul dynamique du nombre de SMS alors il faut renseigner smslong = "999"
  --tracker: list<string>
  --ucs2: string # Il est également possible d’envoyer des SMS en alphabet non latin (russe, chinois, arabe, etc) sur les numéros hors France métropolitaine. Pour ce faire, la requête devrait être encodée au format UTF-8 et contenir l’argument ucs2 = "1" Du fait de contraintes techniques, 1 SMS unique ne pourra pas dépasser 70 caractères (au lieu des 160 usuels) et dans le cas de SMS long, chaque sms ne pourra dépasser 67 caractères.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/smsmulti"
    body: {content_type: "application/json", kind: json, fields: [{name: date_envoi, var: date_envoi}, {name: emetteur, var: emetteur}, {name: gmt_zone, var: gmt_zone}, {name: keyid, var: keyid}, {name: nostop, var: nostop}, {name: num, var: num}, {name: numAzur, var: num_azur}, {name: repertoireId, var: repertoire_id}, {name: sms, var: sms}, {name: smslong, var: smslong}, {name: tracker, var: tracker}, {name: ucs2, var: ucs2}]}
    accept: ["application/json", etat]
    ok: [200]
    auth: bearer
  } {
    date_envoi: $date_envoi, emetteur: $emetteur, gmt_zone: $gmt_zone, keyid: $keyid, nostop: $nostop, num: $num, num_azur: $num_azur, repertoire_id: $repertoire_id, sms: $sms, smslong: $smslong, tracker: $tracker, ucs2: $ucs2
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Ajoute un sous compte
#
# POST /subaccount
# Returns: record<etat: record<etat: list<record>>>
# operationId: subaccountAdd
export def "subaccount-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
  keyid: string
  sub_account_edit: string@sub-account-edit-completer
  sub_account_login: string
  sub_account_password: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subaccount"
    body: {content_type: "application/json", kind: json, fields: [{name: keyid, var: keyid}, {name: subAccountEdit, var: sub_account_edit}, {name: subAccountLogin, var: sub_account_login}, {name: subAccountPassword, var: sub_account_password}]}
    accept: ["application/json", exemple1]
    ok: [200]
    auth: bearer
  } {
    keyid: $keyid, sub_account_edit: $sub_account_edit, sub_account_login: $sub_account_login, sub_account_password: $sub_account_password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Edit a subaccount
#
# PUT /subaccount
# Returns: record<etat: record<etat: list<record>>>
# operationId: subaccountEdit
export def "subaccount-edit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  keyid: string # Clé API
  --sub-account-add-credit: string # montant du crédit à ajouter
  --sub-account-country-code: string
  sub_account_edit: string@sub-account-edit-completer-1 # action à réaliser soit setPrice pour définir un prix ou addCredit pour ajouter du credit ou setRestriction modifier la restriction stop /
  --sub-account-key-id: string # keyid du sous-compte
  --sub-account-price: string
  --sub-account-restriction-stop: string@sub-account-restriction-stop-completer
  --sub-account-restriction-time: string@sub-account-restriction-time-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subaccount"
    body: {content_type: "application/json", kind: json, fields: [{name: keyid, var: keyid}, {name: subAccountAddCredit, var: sub_account_add_credit}, {name: subAccountCountryCode, var: sub_account_country_code}, {name: subAccountEdit, var: sub_account_edit}, {name: subAccountKeyId, var: sub_account_key_id}, {name: subAccountPrice, var: sub_account_price}, {name: subAccountRestrictionStop, var: sub_account_restriction_stop}, {name: subAccountRestrictionTime, var: sub_account_restriction_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    keyid: $keyid, sub_account_add_credit: $sub_account_add_credit, sub_account_country_code: $sub_account_country_code, sub_account_edit: $sub_account_edit, sub_account_key_id: $sub_account_key_id, sub_account_price: $sub_account_price, sub_account_restriction_stop: $sub_account_restriction_stop, sub_account_restriction_time: $sub_account_restriction_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
