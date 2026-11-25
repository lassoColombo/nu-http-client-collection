# Auto-generated client for Mandrill v1.0
# Source: https://api.apis.guru/v2/specs/mandrillapp.com/1.0/swagger.json
# Auth: --token flag or $env.MANDRILL_TOKEN

const CLIENT = {
  base_url: "https://mandrillapp.com/api/1.0"
  token_env_var: "MANDRILL_TOKEN"
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

def base-url-completer [] { ["https://mandrillapp.com/api/1.0"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    post-exports-activity-json: "record<created_at: string, finished_at: any, id: string, result_url: any, state: string, type: string>"
    post-exports-info-json: "record<created_at: string, finished_at: string, id: string, result_url: string, state: string, type: string>"
    post-exports-list-json: "table<created_at: string, finished_at: string, id: string, result_url: string, state: string, type: string>"
    post-exports-rejects-json: "record<created_at: string, finished_at: any, id: string, result_url: any, state: string, type: string>"
    post-exports-whitelist-json: "record<created_at: string, finished_at: any, id: string, result_url: any, state: string, type: string>"
    post-inbound-add-domain-json: "record<created_at: string, domain: string, valid_mx: bool>"
    post-inbound-add-route-json: "record<id: string, pattern: string, url: string>"
    post-inbound-check-domain-json: "record<created_at: string, domain: string, valid_mx: bool>"
    post-inbound-delete-domain-json: "record<created_at: string, domain: string, valid_mx: bool>"
    post-inbound-delete-route-json: "record<id: string, pattern: string, url: string>"
    post-inbound-domains-json: "table<created_at: string, domain: string, valid_mx: bool>"
    post-inbound-routes-json: "table<id: string, pattern: string, url: string>"
    post-inbound-send-raw-json: "table<email: string, pattern: string, url: string>"
    post-inbound-update-route-json: "record<id: string, pattern: string, url: string>"
    post-ips-cancel-warmup-json: "record<created_at: string, custom_dns: record<enabled: bool, error: string, valid: bool>, domain: string, ip: string, pool: string, warmup: record<end_at: string, start_at: string, warming_up: bool>>"
    post-ips-check-custom-dns-json: "record<error: string, valid: bool>"
    post-ips-create-pool-json: "record<created_at: string, ips: table<created_at: string, custom_dns: record, domain: string, ip: string, pool: string, warmup: record>, name: string>"
    post-ips-delete-pool-json: "record<deleted: bool, pool: string>"
    post-ips-delete-json: "record<deleted: bool, ip: string>"
    post-ips-info-json: "record<created_at: string, custom_dns: record<enabled: bool, error: string, valid: bool>, domain: string, ip: string, pool: string, warmup: record<end_at: string, start_at: string, warming_up: bool>>"
    post-ips-list-pools-json: "table<created_at: string, ips: list<record>, name: string>"
    post-ips-list-json: "table<created_at: string, custom_dns: record<enabled: bool, error: string, valid: bool>, domain: string, ip: string, pool: string, warmup: record<end_at: string, start_at: string, warming_up: bool>>"
    post-ips-pool-info-json: "record<created_at: string, ips: table<created_at: string, custom_dns: record, domain: string, ip: string, pool: string, warmup: record>, name: string>"
    post-ips-provision-json: "record<requested_at: string>"
    post-ips-set-custom-dns-json: "record<created_at: string, custom_dns: record<enabled: bool, error: string, valid: bool>, domain: string, ip: string, pool: string, warmup: record<end_at: string, start_at: string, warming_up: bool>>"
    post-ips-set-pool-json: "record<created_at: string, custom_dns: record<enabled: bool, error: string, valid: bool>, domain: string, ip: string, pool: string, warmup: record<end_at: string, start_at: string, warming_up: bool>>"
    post-ips-start-warmup-json: "record<created_at: string, custom_dns: record<enabled: bool, error: string, valid: bool>, domain: string, ip: string, pool: string, warmup: record<end_at: string, start_at: string, warming_up: bool>>"
    post-messages-cancel-scheduled-json: "record<_id: string, created_at: string, from_email: string, send_at: string, subject: string, to: string>"
    post-messages-content-json: "record<_id: string, attachments: table<content: string, name: string, type: string>, from_email: string, from_name: string, headers: record<Reply-To: string>, html: string, subject: string, tags: list<string>, text: string, to: record<email: string, name: string>, ts: int>"
    post-messages-info-json: "record<_id: string, clicks: int, clicks_detail: table<ip: string, location: string, ts: int, ua: string, url: string>, email: string, metadata: record<user_id: string, website: string>, opens: int, opens_detail: table<ip: string, location: string, ts: int, ua: string>, sender: string, smtp_events: table<diag: string, ts: int, type: string>, state: string, subject: string, tags: list<string>, template: string, ts: int>"
    post-messages-list-scheduled-json: "table<_id: string, created_at: string, from_email: string, send_at: string, subject: string, to: string>"
    post-messages-parse-json: "record<attachments: table<binary: bool, content: string, name: string, type: string>, from_email: string, from_name: string, headers: record<Reply-To: string>, html: string, images: table<content: string, name: string, type: string>, subject: string, text: string, to: table<email: string, name: string>>"
    post-messages-reschedule-json: "record<_id: string, created_at: string, from_email: string, send_at: string, subject: string, to: string>"
    post-messages-search-time-series-json: "table<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, time: string, unique_clicks: int, unique_opens: int, unsubs: int>"
    post-messages-search-json: "table<_id: string, clicks: int, clicks_detail: list<record>, email: string, metadata: record<user_id: string, website: string>, opens: int, opens_detail: list<record>, sender: string, state: string, subject: string, tags: list<string>, template: string, ts: int>"
    post-messages-send-raw-json: "table<_id: string, email: string, reject_reason: string, status: string>"
    post-messages-send-template-json: "table<_id: string, email: string, reject_reason: string, status: string>"
    post-messages-send-json: "table<_id: string, email: string, reject_reason: string, status: string>"
    post-metadata-add-json: "record<name: string, state: string, view_template: string>"
    post-metadata-delete-json: "record<name: string, state: string, view_template: string>"
    post-metadata-list-json: "table<name: string, state: string, view_template: string>"
    post-metadata-update-json: "record<name: string, state: string, view_template: string>"
    post-rejects-add-json: "record<added: bool, email: string>"
    post-rejects-delete-json: "record<deleted: bool, email: string, subaccount: string>"
    post-rejects-list-json: "table<created_at: string, detail: string, email: string, expired: bool, expires_at: string, last_event_at: string, reason: string, sender: record<address: string, clicks: int, complaints: int, created_at: string, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>, subaccount: string>"
    post-senders-add-domain-json: "record<created_at: string, dkim: record<error: string, valid: bool, valid_after: string>, domain: string, last_tested_at: string, spf: record<error: string, valid: bool, valid_after: string>, valid_signing: bool, verified_at: string>"
    post-senders-check-domain-json: "record<created_at: string, dkim: record<error: string, valid: bool, valid_after: string>, domain: string, last_tested_at: string, spf: record<error: string, valid: bool, valid_after: string>, valid_signing: bool, verified_at: string>"
    post-senders-domains-json: "table<created_at: string, dkim: record<error: string, valid: bool, valid_after: string>, domain: string, last_tested_at: string, spf: record<error: string, valid: bool, valid_after: string>, valid_signing: bool, verified_at: string>"
    post-senders-info-json: "record<address: string, clicks: int, complaints: int, created_at: string, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, stats: record<last_30_days: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>, last_60_days: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>, last_7_days: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>, last_90_days: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>, today: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>>, unsubs: int>"
    post-senders-list-json: "table<address: string, clicks: int, complaints: int, created_at: string, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>"
    post-senders-time-series-json: "table<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, time: string, unique_clicks: int, unique_opens: int>"
    post-senders-verify-domain-json: "record<domain: string, email: string, status: string>"
    post-subaccounts-add-json: "record<created_at: string, custom_quota: int, first_sent_at: string, id: string, name: string, reputation: int, sent_monthly: int, sent_total: int, sent_weekly: int, status: string>"
    post-subaccounts-delete-json: "record<created_at: string, custom_quota: int, first_sent_at: string, id: string, name: string, reputation: int, sent_monthly: int, sent_total: int, sent_weekly: int, status: string>"
    post-subaccounts-info-json: "record<created_at: string, custom_quota: int, first_sent_at: string, hourly_quota: int, id: string, last_30_days: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>, name: string, notes: string, reputation: int, sent_hourly: int, sent_monthly: int, sent_total: int, sent_weekly: int, status: string>"
    post-subaccounts-list-json: "table<created_at: string, custom_quota: int, first_sent_at: string, id: string, name: string, reputation: int, sent_monthly: int, sent_total: int, sent_weekly: int, status: string>"
    post-subaccounts-pause-json: "record<created_at: string, custom_quota: int, first_sent_at: string, id: string, name: string, reputation: int, sent_monthly: int, sent_total: int, sent_weekly: int, status: string>"
    post-subaccounts-resume-json: "record<created_at: string, custom_quota: int, first_sent_at: string, id: string, name: string, reputation: int, sent_monthly: int, sent_total: int, sent_weekly: int, status: string>"
    post-subaccounts-update-json: "record<created_at: string, custom_quota: int, first_sent_at: string, id: string, name: string, reputation: int, sent_monthly: int, sent_total: int, sent_weekly: int, status: string>"
    post-tags-all-time-series-json: "table<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, time: string, unique_clicks: int, unique_opens: int, unsubs: int>"
    post-tags-delete-json: "record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, reputation: int, sent: int, soft_bounces: int, tag: string, unique_clicks: int, unique_opens: int, unsubs: int>"
    post-tags-info-json: "record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, stats: record<last_30_days: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>, last_60_days: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>, last_7_days: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>, last_90_days: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>, today: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>>, tag: string, unsubs: int>"
    post-tags-list-json: "table<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, reputation: int, sent: int, soft_bounces: int, tag: string, unique_clicks: int, unique_opens: int, unsubs: int>"
    post-tags-time-series-json: "table<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, time: string, unique_clicks: int, unique_opens: int, unsubs: int>"
    post-templates-add-json: "record<code: string, created_at: string, from_email: string, from_name: string, labels: list<string>, name: string, publish_code: string, publish_from_email: string, publish_from_name: string, publish_name: string, publish_subject: string, publish_text: string, published_at: string, slug: string, subject: string, text: string, updated_at: string>"
    post-templates-delete-json: "record<code: string, created_at: string, from_email: string, from_name: string, labels: list<string>, name: string, publish_code: string, publish_from_email: string, publish_from_name: string, publish_name: string, publish_subject: string, publish_text: string, published_at: string, slug: string, subject: string, text: string, updated_at: string>"
    post-templates-info-json: "record<code: string, created_at: string, from_email: string, from_name: string, labels: list<string>, name: string, publish_code: string, publish_from_email: string, publish_from_name: string, publish_name: string, publish_subject: string, publish_text: string, published_at: string, slug: string, subject: string, text: string, updated_at: string>"
    post-templates-list-json: "table<code: string, created_at: string, from_email: string, from_name: string, labels: list<string>, name: string, publish_code: string, publish_from_email: string, publish_from_name: string, publish_name: string, publish_subject: string, publish_text: string, published_at: string, slug: string, subject: string, text: string, updated_at: string>"
    post-templates-publish-json: "record<code: string, created_at: string, from_email: string, from_name: string, labels: list<string>, name: string, publish_code: string, publish_from_email: string, publish_from_name: string, publish_name: string, publish_subject: string, publish_text: string, published_at: string, slug: string, subject: string, text: string, updated_at: string>"
    post-templates-render-json: "record<html: string>"
    post-templates-time-series-json: "table<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, time: string, unique_clicks: int, unique_opens: int>"
    post-templates-update-json: "record<code: string, created_at: string, from_email: string, from_name: string, labels: list<string>, name: string, publish_code: string, publish_from_email: string, publish_from_name: string, publish_name: string, publish_subject: string, publish_text: string, published_at: string, slug: string, subject: string, text: string, updated_at: string>"
    post-urls-add-tracking-domain-json: "record<cname: record<error: string, valid: bool, valid_after: string>, created_at: string, domain: string, last_tested_at: string, valid_tracking: bool>"
    post-urls-check-tracking-domain-json: "record<cname: record<error: string, valid: bool, valid_after: string>, created_at: string, domain: string, last_tested_at: string, valid_tracking: bool>"
    post-urls-list-json: "table<clicks: int, sent: int, unique_clicks: int, url: string>"
    post-urls-search-json: "table<clicks: int, sent: int, unique_clicks: int, url: string>"
    post-urls-time-series-json: "table<clicks: int, sent: int, time: string, unique_clicks: int>"
    post-urls-tracking-domains-json: "table<cname: record<error: string, valid: bool, valid_after: string>, created_at: string, domain: string, last_tested_at: string, valid_tracking: bool>"
    post-users-info-json: "record<backlog: int, created_at: string, hourly_quota: int, public_id: string, reputation: int, stats: record<all_time: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>, last_30_days: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>, last_60_days: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>, last_7_days: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>, last_90_days: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>, today: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>>, username: string>"
    post-users-ping2-json: "record<PING: string>"
    post-users-senders-json: "table<address: string, clicks: int, complaints: int, created_at: string, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>"
    post-webhooks-add-json: "record<auth_key: string, batches_sent: int, created_at: string, description: string, events: list<string>, events_sent: int, id: int, last_error: string, last_sent_at: string, url: string>"
    post-webhooks-delete-json: "record<auth_key: string, batches_sent: int, created_at: string, description: string, events: list<string>, events_sent: int, id: int, last_error: string, last_sent_at: string, url: string>"
    post-webhooks-info-json: "record<auth_key: string, batches_sent: int, created_at: string, description: string, events: list<string>, events_sent: int, id: int, last_error: string, last_sent_at: string, url: string>"
    post-webhooks-list-json: "table<auth_key: string, batches_sent: int, created_at: string, description: string, events: list<string>, events_sent: int, id: int, last_error: string, last_sent_at: string, url: string>"
    post-webhooks-update-json: "record<auth_key: string, batches_sent: int, created_at: string, description: string, events: list<string>, events_sent: int, id: int, last_error: string, last_sent_at: string, url: string>"
    post-whitelists-add-json: "record<email: string, whether: bool>"
    post-whitelists-delete-json: "record<deleted: bool, email: string>"
    post-whitelists-list-json: "table<created_at: string, detail: string, email: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["post-exports-activity-json" "post-exports-info-json" "post-exports-list-json" "post-exports-rejects-json" "post-exports-whitelist-json" "post-inbound-add-domain-json" "post-inbound-add-route-json" "post-inbound-check-domain-json" "post-inbound-delete-domain-json" "post-inbound-delete-route-json" "post-inbound-domains-json" "post-inbound-routes-json" "post-inbound-send-raw-json" "post-inbound-update-route-json" "post-ips-cancel-warmup-json" "post-ips-check-custom-dns-json" "post-ips-create-pool-json" "post-ips-delete-pool-json" "post-ips-delete-json" "post-ips-info-json" "post-ips-list-pools-json" "post-ips-list-json" "post-ips-pool-info-json" "post-ips-provision-json" "post-ips-set-custom-dns-json" "post-ips-set-pool-json" "post-ips-start-warmup-json" "post-messages-cancel-scheduled-json" "post-messages-content-json" "post-messages-info-json" "post-messages-list-scheduled-json" "post-messages-parse-json" "post-messages-reschedule-json" "post-messages-search-time-series-json" "post-messages-search-json" "post-messages-send-raw-json" "post-messages-send-template-json" "post-messages-send-json" "post-metadata-add-json" "post-metadata-delete-json" "post-metadata-list-json" "post-metadata-update-json" "post-rejects-add-json" "post-rejects-delete-json" "post-rejects-list-json" "post-senders-add-domain-json" "post-senders-check-domain-json" "post-senders-domains-json" "post-senders-info-json" "post-senders-list-json" "post-senders-time-series-json" "post-senders-verify-domain-json" "post-subaccounts-add-json" "post-subaccounts-delete-json" "post-subaccounts-info-json" "post-subaccounts-list-json" "post-subaccounts-pause-json" "post-subaccounts-resume-json" "post-subaccounts-update-json" "post-tags-all-time-series-json" "post-tags-delete-json" "post-tags-info-json" "post-tags-list-json" "post-tags-time-series-json" "post-templates-add-json" "post-templates-delete-json" "post-templates-info-json" "post-templates-list-json" "post-templates-publish-json" "post-templates-render-json" "post-templates-time-series-json" "post-templates-update-json" "post-urls-add-tracking-domain-json" "post-urls-check-tracking-domain-json" "post-urls-list-json" "post-urls-search-json" "post-urls-time-series-json" "post-urls-tracking-domains-json" "post-users-info-json" "post-users-ping-json" "post-users-ping2-json" "post-users-senders-json" "post-webhooks-add-json" "post-webhooks-delete-json" "post-webhooks-info-json" "post-webhooks-list-json" "post-webhooks-update-json" "post-whitelists-add-json" "post-whitelists-delete-json" "post-whitelists-list-json" "commands"] | sort) } | get name | first)
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

# Begins an export of your activity history. The activity will be exported to a zip archive containing a single file named activity.csv in the same format as you would be able to export from your account's activity view. It includes the following fields: Date, Email Address, Sender, Subject, Status, Tags, Opens, Clicks, Bounce Detail. If you have configured any custom metadata fields, they will be included in the exported data.
#
# POST /exports/activity.json
# Returns: record<created_at: string, finished_at: any, id: string, result_url: any, state: string, type: string>
export def "post-exports-activity-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-keys: list<string>
  --date-from: string
  --date-to: string
  --key: string
  --notify-email: string
  --senders: list<string>
  --states: list<string>
  --tags: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/exports/activity.json"
    body: {content_type: "application/json", kind: json, fields: [{name: api_keys, var: api_keys}, {name: date_from, var: date_from}, {name: date_to, var: date_to}, {name: key, var: key}, {name: notify_email, var: notify_email}, {name: senders, var: senders}, {name: states, var: states}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_keys: $api_keys, date_from: $date_from, date_to: $date_to, key: $key, notify_email: $notify_email, senders: $senders, states: $states, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about an export job. If the export job's state is 'complete', the returned data will include a URL you can use to fetch the results. Every export job produces a zip archive, but the format of the archive is distinct for each job type. The api calls that initiate exports include more details about the output format for that job type.
#
# POST /exports/info.json
# Returns: record<created_at: string, finished_at: string, id: string, result_url: string, state: string, type: string>
export def "post-exports-info-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/exports/info.json"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of your exports.
#
# POST /exports/list.json
# Returns: table<created_at: string, finished_at: string, id: string, result_url: string, state: string, type: string>
export def "post-exports-list-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/exports/list.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Begins an export of your rejection blacklist. The blacklist will be exported to a zip archive containing a single file named rejects.csv that includes the following fields: email, reason, detail, created_at, expires_at, last_event_at, expires_at.
#
# POST /exports/rejects.json
# Returns: record<created_at: string, finished_at: any, id: string, result_url: any, state: string, type: string>
export def "post-exports-rejects-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --notify-email: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/exports/rejects.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: notify_email, var: notify_email}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key, notify_email: $notify_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Begins an export of your rejection whitelist. The whitelist will be exported to a zip archive containing a single file named whitelist.csv that includes the following fields: email, detail, created_at.
#
# POST /exports/whitelist.json
# Returns: record<created_at: string, finished_at: any, id: string, result_url: any, state: string, type: string>
export def "post-exports-whitelist-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --notify-email: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/exports/whitelist.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: notify_email, var: notify_email}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key, notify_email: $notify_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add an inbound domain to your account
#
# POST /inbound/add-domain.json
# Returns: record<created_at: string, domain: string, valid_mx: bool>
export def "post-inbound-add-domain-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string
  --key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/inbound/add-domain.json"
    body: {content_type: "application/json", kind: json, fields: [{name: domain, var: domain}, {name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new mailbox route to an inbound domain
#
# POST /inbound/add-route.json
# Returns: record<id: string, pattern: string, url: string>
export def "post-inbound-add-route-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string
  --key: string
  --pattern: string
  --url: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/inbound/add-route.json"
    body: {content_type: "application/json", kind: json, fields: [{name: domain, var: domain}, {name: key, var: key}, {name: pattern, var: pattern}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, key: $key, pattern: $pattern, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check the MX settings for an inbound domain. The domain must have already been added with the add-domain call
#
# POST /inbound/check-domain.json
# Returns: record<created_at: string, domain: string, valid_mx: bool>
export def "post-inbound-check-domain-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string
  --key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/inbound/check-domain.json"
    body: {content_type: "application/json", kind: json, fields: [{name: domain, var: domain}, {name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an inbound domain from the account. All mail will stop routing for this domain immediately.
#
# POST /inbound/delete-domain.json
# Returns: record<created_at: string, domain: string, valid_mx: bool>
export def "post-inbound-delete-domain-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string
  --key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/inbound/delete-domain.json"
    body: {content_type: "application/json", kind: json, fields: [{name: domain, var: domain}, {name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing inbound mailbox route
#
# POST /inbound/delete-route.json
# Returns: record<id: string, pattern: string, url: string>
export def "post-inbound-delete-route-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/inbound/delete-route.json"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the domains that have been configured for inbound delivery
#
# POST /inbound/domains.json
# Returns: table<created_at: string, domain: string, valid_mx: bool>
export def "post-inbound-domains-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/inbound/domains.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the mailbox routes defined for an inbound domain
#
# POST /inbound/routes.json
# Returns: table<id: string, pattern: string, url: string>
export def "post-inbound-routes-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string
  --key: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/inbound/routes.json"
    body: {content_type: "application/json", kind: json, fields: [{name: domain, var: domain}, {name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Take a raw MIME document destined for a domain with inbound domains set up, and send it to the inbound hook exactly as if it had been sent over SMTP
#
# POST /inbound/send-raw.json
# Returns: table<email: string, pattern: string, url: string>
export def "post-inbound-send-raw-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-address: string
  --helo: string
  --key: string
  --mail-from: string
  --raw-message: string
  --to: list<string>
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/inbound/send-raw.json"
    body: {content_type: "application/json", kind: json, fields: [{name: client_address, var: client_address}, {name: helo, var: helo}, {name: key, var: key}, {name: mail_from, var: mail_from}, {name: raw_message, var: raw_message}, {name: to, var: to}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_address: $client_address, helo: $helo, key: $key, mail_from: $mail_from, raw_message: $raw_message, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the pattern or webhook of an existing inbound mailbox route. If null is provided for any fields, the values will remain unchanged.
#
# POST /inbound/update-route.json
# Returns: record<id: string, pattern: string, url: string>
export def "post-inbound-update-route-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --key: string
  --pattern: string
  --url: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/inbound/update-route.json"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: key, var: key}, {name: pattern, var: pattern}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, key: $key, pattern: $pattern, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels the warmup process for a dedicated IP.
#
# POST /ips/cancel-warmup.json
# Returns: record<created_at: string, custom_dns: record<enabled: bool, error: string, valid: bool>, domain: string, ip: string, pool: string, warmup: record<end_at: string, start_at: string, warming_up: bool>>
export def "post-ips-cancel-warmup-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ip: string
  --key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ips/cancel-warmup.json"
    body: {content_type: "application/json", kind: json, fields: [{name: ip, var: ip}, {name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ip: $ip, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tests whether a domain name is valid for use as the custom reverse DNS for a dedicated IP.
#
# POST /ips/check-custom-dns.json
# Returns: record<error: string, valid: bool>
export def "post-ips-check-custom-dns-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string
  --ip: string
  --key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ips/check-custom-dns.json"
    body: {content_type: "application/json", kind: json, fields: [{name: domain, var: domain}, {name: ip, var: ip}, {name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, ip: $ip, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a pool and returns it. If a pool already exists with this name, no action will be performed.
#
# POST /ips/create-pool.json
# Returns: record<created_at: string, ips: table<created_at: string, custom_dns: record, domain: string, ip: string, pool: string, warmup: record>, name: string>
export def "post-ips-create-pool-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --pool: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ips/create-pool.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: pool, var: pool}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key, pool: $pool
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a pool. A pool must be empty before you can delete it, and you cannot delete your default pool.
#
# POST /ips/delete-pool.json
# Returns: record<deleted: bool, pool: string>
export def "post-ips-delete-pool-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --pool: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ips/delete-pool.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: pool, var: pool}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key, pool: $pool
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a dedicated IP. This is permanent and cannot be undone.
#
# POST /ips/delete.json
# Returns: record<deleted: bool, ip: string>
export def "post-ips-delete-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ip: string
  --key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ips/delete.json"
    body: {content_type: "application/json", kind: json, fields: [{name: ip, var: ip}, {name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ip: $ip, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about a single dedicated ip.
#
# POST /ips/info.json
# Returns: record<created_at: string, custom_dns: record<enabled: bool, error: string, valid: bool>, domain: string, ip: string, pool: string, warmup: record<end_at: string, start_at: string, warming_up: bool>>
export def "post-ips-info-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ip: string
  --key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ips/info.json"
    body: {content_type: "application/json", kind: json, fields: [{name: ip, var: ip}, {name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ip: $ip, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists your dedicated IP pools.
#
# POST /ips/list-pools.json
# Returns: table<created_at: string, ips: list<record>, name: string>
export def "post-ips-list-pools-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ips/list-pools.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists your dedicated IPs.
#
# POST /ips/list.json
# Returns: table<created_at: string, custom_dns: record<enabled: bool, error: string, valid: bool>, domain: string, ip: string, pool: string, warmup: record<end_at: string, start_at: string, warming_up: bool>>
export def "post-ips-list-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ips/list.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a single dedicated IP pool.
#
# POST /ips/pool-info.json
# Returns: record<created_at: string, ips: table<created_at: string, custom_dns: record, domain: string, ip: string, pool: string, warmup: record>, name: string>
export def "post-ips-pool-info-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --pool: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ips/pool-info.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: pool, var: pool}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key, pool: $pool
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Requests an additional dedicated IP for your account. Accounts may have one outstanding request at any time, and provisioning requests are processed within 24 hours.
#
# POST /ips/provision.json
# Returns: record<requested_at: string>
export def "post-ips-provision-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --pool: string
  --warmup: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ips/provision.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: pool, var: pool}, {name: warmup, var: warmup}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key, pool: $pool, warmup: $warmup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configures the custom DNS name for a dedicated IP.
#
# POST /ips/set-custom-dns.json
# Returns: record<created_at: string, custom_dns: record<enabled: bool, error: string, valid: bool>, domain: string, ip: string, pool: string, warmup: record<end_at: string, start_at: string, warming_up: bool>>
export def "post-ips-set-custom-dns-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string
  --ip: string
  --key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ips/set-custom-dns.json"
    body: {content_type: "application/json", kind: json, fields: [{name: domain, var: domain}, {name: ip, var: ip}, {name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, ip: $ip, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Moves a dedicated IP to a different pool.
#
# POST /ips/set-pool.json
# Returns: record<created_at: string, custom_dns: record<enabled: bool, error: string, valid: bool>, domain: string, ip: string, pool: string, warmup: record<end_at: string, start_at: string, warming_up: bool>>
export def "post-ips-set-pool-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --create-pool: oneof<nothing, bool>
  --ip: string
  --key: string
  --pool: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ips/set-pool.json"
    body: {content_type: "application/json", kind: json, fields: [{name: create_pool, var: create_pool}, {name: ip, var: ip}, {name: key, var: key}, {name: pool, var: pool}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    create_pool: $create_pool, ip: $ip, key: $key, pool: $pool
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Begins the warmup process for a dedicated IP. During the warmup process, Mandrill will gradually increase the percentage of your mail that is sent over the warming-up IP, over a period of roughly 30 days. The rest of your mail will be sent over shared IPs or other dedicated IPs in the same pool.
#
# POST /ips/start-warmup.json
# Returns: record<created_at: string, custom_dns: record<enabled: bool, error: string, valid: bool>, domain: string, ip: string, pool: string, warmup: record<end_at: string, start_at: string, warming_up: bool>>
export def "post-ips-start-warmup-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ip: string
  --key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ips/start-warmup.json"
    body: {content_type: "application/json", kind: json, fields: [{name: ip, var: ip}, {name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ip: $ip, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels a scheduled email.
#
# POST /messages/cancel-scheduled.json
# Returns: record<_id: string, created_at: string, from_email: string, send_at: string, subject: string, to: string>
export def "post-messages-cancel-scheduled-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: any
  --key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/messages/cancel-scheduled.json"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the full content of a recently sent message
#
# POST /messages/content.json
# Returns: record<_id: string, attachments: table<content: string, name: string, type: string>, from_email: string, from_name: string, headers: record<Reply-To: string>, html: string, subject: string, tags: list<string>, text: string, to: record<email: string, name: string>, ts: int>
export def "post-messages-content-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/messages/content.json"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the information for a single recently sent message
#
# POST /messages/info.json
# Returns: record<_id: string, clicks: int, clicks_detail: table<ip: string, location: string, ts: int, ua: string, url: string>, email: string, metadata: record<user_id: string, website: string>, opens: int, opens_detail: table<ip: string, location: string, ts: int, ua: string>, sender: string, smtp_events: table<diag: string, ts: int, type: string>, state: string, subject: string, tags: list<string>, template: string, ts: int>
export def "post-messages-info-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/messages/info.json"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Queries your scheduled emails by sender or recipient, or both.
#
# POST /messages/list-scheduled.json
# Returns: table<_id: string, created_at: string, from_email: string, send_at: string, subject: string, to: string>
export def "post-messages-list-scheduled-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --to: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/messages/list-scheduled.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: to, var: to}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Parse the full MIME document for an email message, returning the content of the message broken into its constituent pieces
#
# POST /messages/parse.json
# Returns: record<attachments: table<binary: bool, content: string, name: string, type: string>, from_email: string, from_name: string, headers: record<Reply-To: string>, html: string, images: table<content: string, name: string, type: string>, subject: string, text: string, to: table<email: string, name: string>>
export def "post-messages-parse-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --raw-message: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/messages/parse.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: raw_message, var: raw_message}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key, raw_message: $raw_message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reschedules a scheduled email.
#
# POST /messages/reschedule.json
# Returns: record<_id: string, created_at: string, from_email: string, send_at: string, subject: string, to: string>
export def "post-messages-reschedule-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --key: string
  --send-at: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/messages/reschedule.json"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: key, var: key}, {name: send_at, var: send_at}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, key: $key, send_at: $send_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search the content of recently sent messages and return the aggregated hourly stats for matching messages
#
# POST /messages/search-time-series.json
# Returns: table<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, time: string, unique_clicks: int, unique_opens: int, unsubs: int>
export def "post-messages-search-time-series-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string
  --date-to: string
  --key: string
  --query: string
  --senders: list<string>
  --tags: list<string>
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/messages/search-time-series.json"
    body: {content_type: "application/json", kind: json, fields: [{name: date_from, var: date_from}, {name: date_to, var: date_to}, {name: key, var: key}, {name: query, var: query}, {name: senders, var: senders}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    date_from: $date_from, date_to: $date_to, key: $key, query: $query, senders: $senders, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search the content of recently sent messages and optionally narrow by date range, tags and senders. This method may be called up to 20 times per minute. If you need the data more often, you can use /messages/info.json to get the information for a single message, or webhooks to push activity to your own application for querying.
#
# POST /messages/search.json
# Returns: table<_id: string, clicks: int, clicks_detail: list<record>, email: string, metadata: record<user_id: string, website: string>, opens: int, opens_detail: list<record>, sender: string, state: string, subject: string, tags: list<string>, template: string, ts: int>
export def "post-messages-search-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-keys: list<string>
  --date-from: string
  --date-to: string
  --key: string
  --limit: int
  --query: string
  --senders: list<string>
  --tags: list<string>
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/messages/search.json"
    body: {content_type: "application/json", kind: json, fields: [{name: api_keys, var: api_keys}, {name: date_from, var: date_from}, {name: date_to, var: date_to}, {name: key, var: key}, {name: limit, var: limit}, {name: query, var: query}, {name: senders, var: senders}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_keys: $api_keys, date_from: $date_from, date_to: $date_to, key: $key, limit: $limit, query: $query, senders: $senders, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Take a raw MIME document for a message, and send it exactly as if it were sent through Mandrill's SMTP servers
#
# POST /messages/send-raw.json
# Returns: table<_id: string, email: string, reject_reason: string, status: string>
export def "post-messages-send-raw-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --async: oneof<nothing, bool>
  --from-email: string
  --from-name: string
  --ip-pool: string
  --key: string
  --raw-message: string
  --return-path-domain: any
  --send-at: string
  --to: list<string>
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/messages/send-raw.json"
    body: {content_type: "application/json", kind: json, fields: [{name: async, var: async}, {name: from_email, var: from_email}, {name: from_name, var: from_name}, {name: ip_pool, var: ip_pool}, {name: key, var: key}, {name: raw_message, var: raw_message}, {name: return_path_domain, var: return_path_domain}, {name: send_at, var: send_at}, {name: to, var: to}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    async: $async, from_email: $from_email, from_name: $from_name, ip_pool: $ip_pool, key: $key, raw_message: $raw_message, return_path_domain: $return_path_domain, send_at: $send_at, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send a new transactional message through Mandrill using a template
#
# POST /messages/send-template.json
# Returns: table<_id: string, email: string, reject_reason: string, status: string>
export def "post-messages-send-template-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --async: oneof<nothing, bool>
  --ip-pool: string
  --key: string
  --message: record # shape: {attachments?: list, auto_html?: any, auto_text?: any, bcc_address?: string, from_email?: string, from_name?: string, global_merge_vars?: list, google_analytics_campaign?: string, google_analytics_domains?: list<string>, headers?: record, html?: string, images?: list, important?: bool, inline_css?: any, merge?: bool, merge_vars?: list, metadata?: record, preserve_recipients?: any, recipient_metadata?: list, return_path_domain?: any, signing_domain?: any, subaccount?: string, subject?: string, ... (8 more fields)}
  --send-at: string
  --template-content: list # item shape: {content?: string, name?: string}
  --template-name: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/messages/send-template.json"
    body: {content_type: "application/json", kind: json, fields: [{name: async, var: async}, {name: ip_pool, var: ip_pool}, {name: key, var: key}, {name: message, var: message}, {name: send_at, var: send_at}, {name: template_content, var: template_content}, {name: template_name, var: template_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    async: $async, ip_pool: $ip_pool, key: $key, message: $message, send_at: $send_at, template_content: $template_content, template_name: $template_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send a new transactional message through Mandrill
#
# POST /messages/send.json
# Returns: table<_id: string, email: string, reject_reason: string, status: string>
export def "post-messages-send-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --async: oneof<nothing, bool>
  --ip-pool: string
  --key: string
  --message: record # shape: {attachments?: list, auto_html?: any, auto_text?: any, bcc_address?: string, from_email?: string, from_name?: string, global_merge_vars?: list, google_analytics_campaign?: string, google_analytics_domains?: list<string>, headers?: record, html?: string, images?: list, important?: bool, inline_css?: any, merge?: bool, merge_vars?: list, metadata?: record, preserve_recipients?: any, recipient_metadata?: list, return_path_domain?: any, signing_domain?: any, subaccount?: string, subject?: string, ... (8 more fields)}
  --send-at: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/messages/send.json"
    body: {content_type: "application/json", kind: json, fields: [{name: async, var: async}, {name: ip_pool, var: ip_pool}, {name: key, var: key}, {name: message, var: message}, {name: send_at, var: send_at}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    async: $async, ip_pool: $ip_pool, key: $key, message: $message, send_at: $send_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new custom metadata field to be indexed for the account.
#
# POST /metadata/add.json
# Returns: record<name: string, state: string, view_template: string>
export def "post-metadata-add-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --name: string
  --view-template: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/metadata/add.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: name, var: name}, {name: view_template, var: view_template}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key, name: $name, view_template: $view_template
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing custom metadata field. Deletion isn't instataneous, and /metadata/list will continue to return the field until the asynchronous deletion process is complete.
#
# POST /metadata/delete.json
# Returns: record<name: string, state: string, view_template: string>
export def "post-metadata-delete-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/metadata/delete.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of custom metadata fields indexed for the account.
#
# POST /metadata/list.json
# Returns: table<name: string, state: string, view_template: string>
export def "post-metadata-list-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/metadata/list.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing custom metadata field.
#
# POST /metadata/update.json
# Returns: record<name: string, state: string, view_template: string>
export def "post-metadata-update-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --name: string
  --view-template: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/metadata/update.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: name, var: name}, {name: view_template, var: view_template}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key, name: $name, view_template: $view_template
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds an email to your email rejection blacklist. Addresses that you add manually will never expire and there is no reputation penalty for removing them from your blacklist. Attempting to blacklist an address that has been whitelisted will have no effect.
#
# POST /rejects/add.json
# Returns: record<added: bool, email: string>
export def "post-rejects-add-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string
  --email: string
  --key: string
  --subaccount: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rejects/add.json"
    body: {content_type: "application/json", kind: json, fields: [{name: comment, var: comment}, {name: email, var: email}, {name: key, var: key}, {name: subaccount, var: subaccount}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    comment: $comment, email: $email, key: $key, subaccount: $subaccount
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an email rejection. There is no limit to how many rejections you can remove from your blacklist, but keep in mind that each deletion has an affect on your reputation.
#
# POST /rejects/delete.json
# Returns: record<deleted: bool, email: string, subaccount: string>
export def "post-rejects-delete-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string
  --key: string
  --subaccount: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rejects/delete.json"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: key, var: key}, {name: subaccount, var: subaccount}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    email: $email, key: $key, subaccount: $subaccount
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves your email rejection blacklist. You can provide an email address to limit the results. Returns up to 1000 results. By default, entries that have expired are excluded from the results; set include_expired to true to include them.
#
# POST /rejects/list.json
# Returns: table<created_at: string, detail: string, email: string, expired: bool, expires_at: string, last_event_at: string, reason: string, sender: record<address: string, clicks: int, complaints: int, created_at: string, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>, subaccount: string>
export def "post-rejects-list-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string
  --include-expired: oneof<nothing, bool>
  --key: string
  --subaccount: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rejects/list.json"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: include_expired, var: include_expired}, {name: key, var: key}, {name: subaccount, var: subaccount}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    email: $email, include_expired: $include_expired, key: $key, subaccount: $subaccount
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a sender domain to your account. Sender domains are added automatically as you send, but you can use this call to add them ahead of time.
#
# POST /senders/add-domain.json
# Returns: record<created_at: string, dkim: record<error: string, valid: bool, valid_after: string>, domain: string, last_tested_at: string, spf: record<error: string, valid: bool, valid_after: string>, valid_signing: bool, verified_at: string>
export def "post-senders-add-domain-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string
  --key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/senders/add-domain.json"
    body: {content_type: "application/json", kind: json, fields: [{name: domain, var: domain}, {name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks the SPF and DKIM settings for a domain. If you haven't already added this domain to your account, it will be added automatically.
#
# POST /senders/check-domain.json
# Returns: record<created_at: string, dkim: record<error: string, valid: bool, valid_after: string>, domain: string, last_tested_at: string, spf: record<error: string, valid: bool, valid_after: string>, valid_signing: bool, verified_at: string>
export def "post-senders-check-domain-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string
  --key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/senders/check-domain.json"
    body: {content_type: "application/json", kind: json, fields: [{name: domain, var: domain}, {name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the sender domains that have been added to this account.
#
# POST /senders/domains.json
# Returns: table<created_at: string, dkim: record<error: string, valid: bool, valid_after: string>, domain: string, last_tested_at: string, spf: record<error: string, valid: bool, valid_after: string>, valid_signing: bool, verified_at: string>
export def "post-senders-domains-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/senders/domains.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return more detailed information about a single sender, including aggregates of recent stats
#
# POST /senders/info.json
# Returns: record<address: string, clicks: int, complaints: int, created_at: string, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, stats: record<last_30_days: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>, last_60_days: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>, last_7_days: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>, last_90_days: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>, today: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>>, unsubs: int>
export def "post-senders-info-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string
  --key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/senders/info.json"
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    address: $address, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the senders that have tried to use this account.
#
# POST /senders/list.json
# Returns: table<address: string, clicks: int, complaints: int, created_at: string, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>
export def "post-senders-list-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/senders/list.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the recent history (hourly stats for the last 30 days) for a sender
#
# POST /senders/time-series.json
# Returns: table<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, time: string, unique_clicks: int, unique_opens: int>
export def "post-senders-time-series-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string
  --key: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/senders/time-series.json"
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    address: $address, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends a verification email in order to verify ownership of a domain. Domain verification is an optional step to confirm ownership of a domain. Once a domain has been verified in a Mandrill account, other accounts may not have their messages signed by that domain unless they also verify the domain. This prevents other Mandrill accounts from sending mail signed by your domain.
#
# POST /senders/verify-domain.json
# Returns: record<domain: string, email: string, status: string>
export def "post-senders-verify-domain-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string
  --key: string
  --mailbox: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/senders/verify-domain.json"
    body: {content_type: "application/json", kind: json, fields: [{name: domain, var: domain}, {name: key, var: key}, {name: mailbox, var: mailbox}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, key: $key, mailbox: $mailbox
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new subaccount
#
# POST /subaccounts/add.json
# Returns: record<created_at: string, custom_quota: int, first_sent_at: string, id: string, name: string, reputation: int, sent_monthly: int, sent_total: int, sent_weekly: int, status: string>
export def "post-subaccounts-add-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-quota: int
  --id: string
  --key: string
  --name: string
  --notes: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subaccounts/add.json"
    body: {content_type: "application/json", kind: json, fields: [{name: custom_quota, var: custom_quota}, {name: id, var: id}, {name: key, var: key}, {name: name, var: name}, {name: notes, var: notes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    custom_quota: $custom_quota, id: $id, key: $key, name: $name, notes: $notes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing subaccount. Any email related to the subaccount will be saved, but stats will be removed and any future sending calls to this subaccount will fail.
#
# POST /subaccounts/delete.json
# Returns: record<created_at: string, custom_quota: int, first_sent_at: string, id: string, name: string, reputation: int, sent_monthly: int, sent_total: int, sent_weekly: int, status: string>
export def "post-subaccounts-delete-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subaccounts/delete.json"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Given the ID of an existing subaccount, return the data about it
#
# POST /subaccounts/info.json
# Returns: record<created_at: string, custom_quota: int, first_sent_at: string, hourly_quota: int, id: string, last_30_days: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>, name: string, notes: string, reputation: int, sent_hourly: int, sent_monthly: int, sent_total: int, sent_weekly: int, status: string>
export def "post-subaccounts-info-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subaccounts/info.json"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of subaccounts defined for the account, optionally filtered by a prefix
#
# POST /subaccounts/list.json
# Returns: table<created_at: string, custom_quota: int, first_sent_at: string, id: string, name: string, reputation: int, sent_monthly: int, sent_total: int, sent_weekly: int, status: string>
export def "post-subaccounts-list-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --q: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subaccounts/list.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: q, var: q}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Pause a subaccount's sending. Any future emails delivered to this subaccount will be queued for a maximum of 3 days until the subaccount is resumed.
#
# POST /subaccounts/pause.json
# Returns: record<created_at: string, custom_quota: int, first_sent_at: string, id: string, name: string, reputation: int, sent_monthly: int, sent_total: int, sent_weekly: int, status: string>
export def "post-subaccounts-pause-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subaccounts/pause.json"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resume a paused subaccount's sending
#
# POST /subaccounts/resume.json
# Returns: record<created_at: string, custom_quota: int, first_sent_at: string, id: string, name: string, reputation: int, sent_monthly: int, sent_total: int, sent_weekly: int, status: string>
export def "post-subaccounts-resume-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subaccounts/resume.json"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing subaccount
#
# POST /subaccounts/update.json
# Returns: record<created_at: string, custom_quota: int, first_sent_at: string, id: string, name: string, reputation: int, sent_monthly: int, sent_total: int, sent_weekly: int, status: string>
export def "post-subaccounts-update-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-quota: int
  --id: string
  --key: string
  --name: string
  --notes: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subaccounts/update.json"
    body: {content_type: "application/json", kind: json, fields: [{name: custom_quota, var: custom_quota}, {name: id, var: id}, {name: key, var: key}, {name: name, var: name}, {name: notes, var: notes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    custom_quota: $custom_quota, id: $id, key: $key, name: $name, notes: $notes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the recent history (hourly stats for the last 30 days) for all tags
#
# POST /tags/all-time-series.json
# Returns: table<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, time: string, unique_clicks: int, unique_opens: int, unsubs: int>
export def "post-tags-all-time-series-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tags/all-time-series.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a tag permanently. Deleting a tag removes the tag from any messages that have been sent, and also deletes the tag's stats. There is no way to undo this operation, so use it carefully.
#
# POST /tags/delete.json
# Returns: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, reputation: int, sent: int, soft_bounces: int, tag: string, unique_clicks: int, unique_opens: int, unsubs: int>
export def "post-tags-delete-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --tag: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tags/delete.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: tag, var: tag}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return more detailed information about a single tag, including aggregates of recent stats
#
# POST /tags/info.json
# Returns: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, stats: record<last_30_days: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>, last_60_days: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>, last_7_days: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>, last_90_days: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>, today: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>>, tag: string, unsubs: int>
export def "post-tags-info-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --tag: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tags/info.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: tag, var: tag}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return all of the user-defined tag information
#
# POST /tags/list.json
# Returns: table<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, reputation: int, sent: int, soft_bounces: int, tag: string, unique_clicks: int, unique_opens: int, unsubs: int>
export def "post-tags-list-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tags/list.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the recent history (hourly stats for the last 30 days) for a tag
#
# POST /tags/time-series.json
# Returns: table<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, time: string, unique_clicks: int, unique_opens: int, unsubs: int>
export def "post-tags-time-series-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --tag: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tags/time-series.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: tag, var: tag}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new template
#
# POST /templates/add.json
# Returns: record<code: string, created_at: string, from_email: string, from_name: string, labels: list<string>, name: string, publish_code: string, publish_from_email: string, publish_from_name: string, publish_name: string, publish_subject: string, publish_text: string, published_at: string, slug: string, subject: string, text: string, updated_at: string>
export def "post-templates-add-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --code: string
  --from-email: string
  --from-name: string
  --key: string
  --labels: list<string>
  --name: string
  --publish: oneof<nothing, bool>
  --subject: string
  --text: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/templates/add.json"
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: code}, {name: from_email, var: from_email}, {name: from_name, var: from_name}, {name: key, var: key}, {name: labels, var: labels}, {name: name, var: name}, {name: publish, var: publish}, {name: subject, var: subject}, {name: text, var: text}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code, from_email: $from_email, from_name: $from_name, key: $key, labels: $labels, name: $name, publish: $publish, subject: $subject, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a template
#
# POST /templates/delete.json
# Returns: record<code: string, created_at: string, from_email: string, from_name: string, labels: list<string>, name: string, publish_code: string, publish_from_email: string, publish_from_name: string, publish_name: string, publish_subject: string, publish_text: string, published_at: string, slug: string, subject: string, text: string, updated_at: string>
export def "post-templates-delete-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/templates/delete.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the information for an existing template
#
# POST /templates/info.json
# Returns: record<code: string, created_at: string, from_email: string, from_name: string, labels: list<string>, name: string, publish_code: string, publish_from_email: string, publish_from_name: string, publish_name: string, publish_subject: string, publish_text: string, published_at: string, slug: string, subject: string, text: string, updated_at: string>
export def "post-templates-info-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/templates/info.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of all the templates available to this user
#
# POST /templates/list.json
# Returns: table<code: string, created_at: string, from_email: string, from_name: string, labels: list<string>, name: string, publish_code: string, publish_from_email: string, publish_from_name: string, publish_name: string, publish_subject: string, publish_text: string, published_at: string, slug: string, subject: string, text: string, updated_at: string>
export def "post-templates-list-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --label: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/templates/list.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: label, var: label}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key, label: $label
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Publish the content for the template. Any new messages sent using this template will start using the content that was previously in draft.
#
# POST /templates/publish.json
# Returns: record<code: string, created_at: string, from_email: string, from_name: string, labels: list<string>, name: string, publish_code: string, publish_from_email: string, publish_from_name: string, publish_name: string, publish_subject: string, publish_text: string, published_at: string, slug: string, subject: string, text: string, updated_at: string>
export def "post-templates-publish-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/templates/publish.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inject content and optionally merge fields into a template, returning the HTML that results
#
# POST /templates/render.json
# Returns: record<html: string>
export def "post-templates-render-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --merge-vars: list # item shape: {content?: string, name?: string}
  --template-content: list # item shape: {content?: string, name?: string}
  --template-name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/templates/render.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: merge_vars, var: merge_vars}, {name: template_content, var: template_content}, {name: template_name, var: template_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key, merge_vars: $merge_vars, template_content: $template_content, template_name: $template_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the recent history (hourly stats for the last 30 days) for a template
#
# POST /templates/time-series.json
# Returns: table<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, time: string, unique_clicks: int, unique_opens: int>
export def "post-templates-time-series-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --name: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/templates/time-series.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the code for an existing template. If null is provided for any fields, the values will remain unchanged.
#
# POST /templates/update.json
# Returns: record<code: string, created_at: string, from_email: string, from_name: string, labels: list<string>, name: string, publish_code: string, publish_from_email: string, publish_from_name: string, publish_name: string, publish_subject: string, publish_text: string, published_at: string, slug: string, subject: string, text: string, updated_at: string>
export def "post-templates-update-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --code: string
  --from-email: string
  --from-name: string
  --key: string
  --labels: list<string>
  --name: string
  --publish: oneof<nothing, bool>
  --subject: string
  --text: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/templates/update.json"
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: code}, {name: from_email, var: from_email}, {name: from_name, var: from_name}, {name: key, var: key}, {name: labels, var: labels}, {name: name, var: name}, {name: publish, var: publish}, {name: subject, var: subject}, {name: text, var: text}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code, from_email: $from_email, from_name: $from_name, key: $key, labels: $labels, name: $name, publish: $publish, subject: $subject, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a tracking domain to your account
#
# POST /urls/add-tracking-domain.json
# Returns: record<cname: record<error: string, valid: bool, valid_after: string>, created_at: string, domain: string, last_tested_at: string, valid_tracking: bool>
export def "post-urls-add-tracking-domain-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string
  --key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/urls/add-tracking-domain.json"
    body: {content_type: "application/json", kind: json, fields: [{name: domain, var: domain}, {name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks the CNAME settings for a tracking domain. The domain must have been added already with the add-tracking-domain call
#
# POST /urls/check-tracking-domain.json
# Returns: record<cname: record<error: string, valid: bool, valid_after: string>, created_at: string, domain: string, last_tested_at: string, valid_tracking: bool>
export def "post-urls-check-tracking-domain-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string
  --key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/urls/check-tracking-domain.json"
    body: {content_type: "application/json", kind: json, fields: [{name: domain, var: domain}, {name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the 100 most clicked URLs
#
# POST /urls/list.json
# Returns: table<clicks: int, sent: int, unique_clicks: int, url: string>
export def "post-urls-list-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/urls/list.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the 100 most clicked URLs that match the search query given
#
# POST /urls/search.json
# Returns: table<clicks: int, sent: int, unique_clicks: int, url: string>
export def "post-urls-search-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --q: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/urls/search.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: q, var: q}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the recent history (hourly stats for the last 30 days) for a url
#
# POST /urls/time-series.json
# Returns: table<clicks: int, sent: int, time: string, unique_clicks: int>
export def "post-urls-time-series-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --url: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/urls/time-series.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of tracking domains set up for this account
#
# POST /urls/tracking-domains.json
# Returns: table<cname: record<error: string, valid: bool, valid_after: string>, created_at: string, domain: string, last_tested_at: string, valid_tracking: bool>
export def "post-urls-tracking-domains-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/urls/tracking-domains.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the information about the API-connected user
#
# POST /users/info.json
# Returns: record<backlog: int, created_at: string, hourly_quota: int, public_id: string, reputation: int, stats: record<all_time: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>, last_30_days: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>, last_60_days: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>, last_7_days: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>, last_90_days: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>, today: record<clicks: int, complaints: int, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>>, username: string>
export def "post-users-info-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/info.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validate an API key and respond to a ping
#
# POST /users/ping.json
export def "post-users-ping-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/users/ping.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validate an API key and respond to a ping (anal JSON parser version)
#
# POST /users/ping2.json
# Returns: record<PING: string>
export def "post-users-ping2-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/ping2.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the senders that have tried to use this account, both verified and unverified
#
# POST /users/senders.json
# Returns: table<address: string, clicks: int, complaints: int, created_at: string, hard_bounces: int, opens: int, rejects: int, sent: int, soft_bounces: int, unique_clicks: int, unique_opens: int, unsubs: int>
export def "post-users-senders-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/senders.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new webhook
#
# POST /webhooks/add.json
# Returns: record<auth_key: string, batches_sent: int, created_at: string, description: string, events: list<string>, events_sent: int, id: int, last_error: string, last_sent_at: string, url: string>
export def "post-webhooks-add-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  --events: list<string>
  --key: string
  --url: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/webhooks/add.json"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: events, var: events}, {name: key, var: key}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    description: $description, events: $events, key: $key, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing webhook
#
# POST /webhooks/delete.json
# Returns: record<auth_key: string, batches_sent: int, created_at: string, description: string, events: list<string>, events_sent: int, id: int, last_error: string, last_sent_at: string, url: string>
export def "post-webhooks-delete-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int
  --key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/webhooks/delete.json"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Given the ID of an existing webhook, return the data about it
#
# POST /webhooks/info.json
# Returns: record<auth_key: string, batches_sent: int, created_at: string, description: string, events: list<string>, events_sent: int, id: int, last_error: string, last_sent_at: string, url: string>
export def "post-webhooks-info-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int
  --key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/webhooks/info.json"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of all webhooks defined on the account
#
# POST /webhooks/list.json
# Returns: table<auth_key: string, batches_sent: int, created_at: string, description: string, events: list<string>, events_sent: int, id: int, last_error: string, last_sent_at: string, url: string>
export def "post-webhooks-list-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/webhooks/list.json"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing webhook
#
# POST /webhooks/update.json
# Returns: record<auth_key: string, batches_sent: int, created_at: string, description: string, events: list<string>, events_sent: int, id: int, last_error: string, last_sent_at: string, url: string>
export def "post-webhooks-update-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  --events: list<string>
  --id: int
  --key: string
  --url: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/webhooks/update.json"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: events, var: events}, {name: id, var: id}, {name: key, var: key}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    description: $description, events: $events, id: $id, key: $key, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds an email to your email rejection whitelist. If the address is currently on your blacklist, that blacklist entry will be removed automatically.
#
# POST /whitelists/add.json
# Returns: record<email: string, whether: bool>
export def "post-whitelists-add-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string
  --key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/whitelists/add.json"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    email: $email, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an email address from the whitelist.
#
# POST /whitelists/delete.json
# Returns: record<deleted: bool, email: string>
export def "post-whitelists-delete-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string
  --key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/whitelists/delete.json"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    email: $email, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves your email rejection whitelist. You can provide an email address or search prefix to limit the results. Returns up to 1000 results.
#
# POST /whitelists/list.json
# Returns: table<created_at: string, detail: string, email: string>
export def "post-whitelists-list-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string
  --key: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/whitelists/list.json"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    email: $email, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
