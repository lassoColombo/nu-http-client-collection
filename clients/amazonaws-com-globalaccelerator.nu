# Auto-generated client for AWS Global Accelerator v2018-08-08
# Source: https://api.apis.guru/v2/specs/amazonaws.com/globalaccelerator/2018-08-08/openapi.json
# Auth: --token flag or $env.AWS_GLOBAL_ACCELERATOR_TOKEN

const CLIENT = {
  base_url: "http://globalaccelerator.us-east-1.amazonaws.com"
  token_env_var: "AWS_GLOBAL_ACCELERATOR_TOKEN"
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

def base-url-completer [] { ["http://globalaccelerator.us-east-1.amazonaws.com" "http://globalaccelerator.us-east-2.amazonaws.com" "http://globalaccelerator.us-west-1.amazonaws.com" "http://globalaccelerator.us-west-2.amazonaws.com" "http://globalaccelerator.us-gov-west-1.amazonaws.com" "http://globalaccelerator.us-gov-east-1.amazonaws.com" "http://globalaccelerator.ca-central-1.amazonaws.com" "http://globalaccelerator.eu-north-1.amazonaws.com" "http://globalaccelerator.eu-west-1.amazonaws.com" "http://globalaccelerator.eu-west-2.amazonaws.com" "http://globalaccelerator.eu-west-3.amazonaws.com" "http://globalaccelerator.eu-central-1.amazonaws.com" "http://globalaccelerator.eu-south-1.amazonaws.com" "http://globalaccelerator.af-south-1.amazonaws.com" "http://globalaccelerator.ap-northeast-1.amazonaws.com" "http://globalaccelerator.ap-northeast-2.amazonaws.com" "http://globalaccelerator.ap-northeast-3.amazonaws.com" "http://globalaccelerator.ap-southeast-1.amazonaws.com" "http://globalaccelerator.ap-southeast-2.amazonaws.com" "http://globalaccelerator.ap-east-1.amazonaws.com" "http://globalaccelerator.ap-south-1.amazonaws.com" "http://globalaccelerator.sa-east-1.amazonaws.com" "http://globalaccelerator.me-south-1.amazonaws.com" "https://globalaccelerator.us-east-1.amazonaws.com" "https://globalaccelerator.us-east-2.amazonaws.com" "https://globalaccelerator.us-west-1.amazonaws.com" "https://globalaccelerator.us-west-2.amazonaws.com" "https://globalaccelerator.us-gov-west-1.amazonaws.com" "https://globalaccelerator.us-gov-east-1.amazonaws.com" "https://globalaccelerator.ca-central-1.amazonaws.com" "https://globalaccelerator.eu-north-1.amazonaws.com" "https://globalaccelerator.eu-west-1.amazonaws.com" "https://globalaccelerator.eu-west-2.amazonaws.com" "https://globalaccelerator.eu-west-3.amazonaws.com" "https://globalaccelerator.eu-central-1.amazonaws.com" "https://globalaccelerator.eu-south-1.amazonaws.com" "https://globalaccelerator.af-south-1.amazonaws.com" "https://globalaccelerator.ap-northeast-1.amazonaws.com" "https://globalaccelerator.ap-northeast-2.amazonaws.com" "https://globalaccelerator.ap-northeast-3.amazonaws.com" "https://globalaccelerator.ap-southeast-1.amazonaws.com" "https://globalaccelerator.ap-southeast-2.amazonaws.com" "https://globalaccelerator.ap-east-1.amazonaws.com" "https://globalaccelerator.ap-south-1.amazonaws.com" "https://globalaccelerator.sa-east-1.amazonaws.com" "https://globalaccelerator.me-south-1.amazonaws.com" "http://globalaccelerator.cn-north-1.amazonaws.com.cn" "http://globalaccelerator.cn-northwest-1.amazonaws.com.cn" "https://globalaccelerator.cn-north-1.amazonaws.com.cn" "https://globalaccelerator.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["GlobalAccelerator_V20180706.AddCustomRoutingEndpoints"] }
def x-amz-target-completer-1 [] { ["GlobalAccelerator_V20180706.AddEndpoints"] }
def x-amz-target-completer-2 [] { ["GlobalAccelerator_V20180706.AdvertiseByoipCidr"] }
def x-amz-target-completer-3 [] { ["GlobalAccelerator_V20180706.AllowCustomRoutingTraffic"] }
def ip-address-type-completer [] { ["DUAL_STACK" "IPV4"] }
def x-amz-target-completer-4 [] { ["GlobalAccelerator_V20180706.CreateAccelerator"] }
def x-amz-target-completer-5 [] { ["GlobalAccelerator_V20180706.CreateCustomRoutingAccelerator"] }
def x-amz-target-completer-6 [] { ["GlobalAccelerator_V20180706.CreateCustomRoutingEndpointGroup"] }
def x-amz-target-completer-7 [] { ["GlobalAccelerator_V20180706.CreateCustomRoutingListener"] }
def health-check-protocol-completer [] { ["HTTP" "HTTPS" "TCP"] }
def x-amz-target-completer-8 [] { ["GlobalAccelerator_V20180706.CreateEndpointGroup"] }
def protocol-completer [] { ["TCP" "UDP"] }
def client-affinity-completer [] { ["NONE" "SOURCE_IP"] }
def x-amz-target-completer-9 [] { ["GlobalAccelerator_V20180706.CreateListener"] }
def x-amz-target-completer-10 [] { ["GlobalAccelerator_V20180706.DeleteAccelerator"] }
def x-amz-target-completer-11 [] { ["GlobalAccelerator_V20180706.DeleteCustomRoutingAccelerator"] }
def x-amz-target-completer-12 [] { ["GlobalAccelerator_V20180706.DeleteCustomRoutingEndpointGroup"] }
def x-amz-target-completer-13 [] { ["GlobalAccelerator_V20180706.DeleteCustomRoutingListener"] }
def x-amz-target-completer-14 [] { ["GlobalAccelerator_V20180706.DeleteEndpointGroup"] }
def x-amz-target-completer-15 [] { ["GlobalAccelerator_V20180706.DeleteListener"] }
def x-amz-target-completer-16 [] { ["GlobalAccelerator_V20180706.DenyCustomRoutingTraffic"] }
def x-amz-target-completer-17 [] { ["GlobalAccelerator_V20180706.DeprovisionByoipCidr"] }
def x-amz-target-completer-18 [] { ["GlobalAccelerator_V20180706.DescribeAccelerator"] }
def x-amz-target-completer-19 [] { ["GlobalAccelerator_V20180706.DescribeAcceleratorAttributes"] }
def x-amz-target-completer-20 [] { ["GlobalAccelerator_V20180706.DescribeCustomRoutingAccelerator"] }
def x-amz-target-completer-21 [] { ["GlobalAccelerator_V20180706.DescribeCustomRoutingAcceleratorAttributes"] }
def x-amz-target-completer-22 [] { ["GlobalAccelerator_V20180706.DescribeCustomRoutingEndpointGroup"] }
def x-amz-target-completer-23 [] { ["GlobalAccelerator_V20180706.DescribeCustomRoutingListener"] }
def x-amz-target-completer-24 [] { ["GlobalAccelerator_V20180706.DescribeEndpointGroup"] }
def x-amz-target-completer-25 [] { ["GlobalAccelerator_V20180706.DescribeListener"] }
def x-amz-target-completer-26 [] { ["GlobalAccelerator_V20180706.ListAccelerators"] }
def x-amz-target-completer-27 [] { ["GlobalAccelerator_V20180706.ListByoipCidrs"] }
def x-amz-target-completer-28 [] { ["GlobalAccelerator_V20180706.ListCustomRoutingAccelerators"] }
def x-amz-target-completer-29 [] { ["GlobalAccelerator_V20180706.ListCustomRoutingEndpointGroups"] }
def x-amz-target-completer-30 [] { ["GlobalAccelerator_V20180706.ListCustomRoutingListeners"] }
def x-amz-target-completer-31 [] { ["GlobalAccelerator_V20180706.ListCustomRoutingPortMappings"] }
def x-amz-target-completer-32 [] { ["GlobalAccelerator_V20180706.ListCustomRoutingPortMappingsByDestination"] }
def x-amz-target-completer-33 [] { ["GlobalAccelerator_V20180706.ListEndpointGroups"] }
def x-amz-target-completer-34 [] { ["GlobalAccelerator_V20180706.ListListeners"] }
def x-amz-target-completer-35 [] { ["GlobalAccelerator_V20180706.ListTagsForResource"] }
def x-amz-target-completer-36 [] { ["GlobalAccelerator_V20180706.ProvisionByoipCidr"] }
def x-amz-target-completer-37 [] { ["GlobalAccelerator_V20180706.RemoveCustomRoutingEndpoints"] }
def x-amz-target-completer-38 [] { ["GlobalAccelerator_V20180706.RemoveEndpoints"] }
def x-amz-target-completer-39 [] { ["GlobalAccelerator_V20180706.TagResource"] }
def x-amz-target-completer-40 [] { ["GlobalAccelerator_V20180706.UntagResource"] }
def x-amz-target-completer-41 [] { ["GlobalAccelerator_V20180706.UpdateAccelerator"] }
def x-amz-target-completer-42 [] { ["GlobalAccelerator_V20180706.UpdateAcceleratorAttributes"] }
def x-amz-target-completer-43 [] { ["GlobalAccelerator_V20180706.UpdateCustomRoutingAccelerator"] }
def x-amz-target-completer-44 [] { ["GlobalAccelerator_V20180706.UpdateCustomRoutingAcceleratorAttributes"] }
def x-amz-target-completer-45 [] { ["GlobalAccelerator_V20180706.UpdateCustomRoutingListener"] }
def x-amz-target-completer-46 [] { ["GlobalAccelerator_V20180706.UpdateEndpointGroup"] }
def x-amz-target-completer-47 [] { ["GlobalAccelerator_V20180706.UpdateListener"] }
def x-amz-target-completer-48 [] { ["GlobalAccelerator_V20180706.WithdrawByoipCidr"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    add-custom-routing-endpoints: "record<EndpointDescriptions: table<EndpointId: string>, EndpointGroupArn: string>"
    add-endpoints: "record<EndpointDescriptions: table<EndpointId: string, Weight: int, HealthState: string, HealthReason: string, ClientIPPreservationEnabled: bool>, EndpointGroupArn: string>"
    advertise-byoip-cidr: "record<ByoipCidr: record<Cidr: string, State: string, Events: list<record>>>"
    create-accelerator: "record<Accelerator: record<AcceleratorArn: string, Name: string, IpAddressType: string, Enabled: bool, IpSets: list<record>, DnsName: string, Status: string, CreatedTime: string, LastModifiedTime: string, DualStackDnsName: string, Events: list<record>>>"
    create-custom-routing-accelerator: "record<Accelerator: record<AcceleratorArn: string, Name: string, IpAddressType: string, Enabled: bool, IpSets: list<record>, DnsName: string, Status: string, CreatedTime: string, LastModifiedTime: string>>"
    create-custom-routing-endpoint-group: "record<EndpointGroup: record<EndpointGroupArn: string, EndpointGroupRegion: string, DestinationDescriptions: list<record>, EndpointDescriptions: list<record>>>"
    create-custom-routing-listener: "record<Listener: record<ListenerArn: string, PortRanges: list<record>>>"
    create-endpoint-group: "record<EndpointGroup: record<EndpointGroupArn: string, EndpointGroupRegion: string, EndpointDescriptions: list<record>, TrafficDialPercentage: float, HealthCheckPort: int, HealthCheckProtocol: string, HealthCheckPath: string, HealthCheckIntervalSeconds: int, ThresholdCount: int, PortOverrides: list<record>>>"
    create-listener: "record<Listener: record<ListenerArn: string, PortRanges: list<record>, Protocol: string, ClientAffinity: string>>"
    deprovision-byoip-cidr: "record<ByoipCidr: record<Cidr: string, State: string, Events: list<record>>>"
    describe-accelerator: "record<Accelerator: record<AcceleratorArn: string, Name: string, IpAddressType: string, Enabled: bool, IpSets: list<record>, DnsName: string, Status: string, CreatedTime: string, LastModifiedTime: string, DualStackDnsName: string, Events: list<record>>>"
    describe-accelerator-attributes: "record<AcceleratorAttributes: record<FlowLogsEnabled: bool, FlowLogsS3Bucket: string, FlowLogsS3Prefix: string>>"
    describe-custom-routing-accelerator: "record<Accelerator: record<AcceleratorArn: string, Name: string, IpAddressType: string, Enabled: bool, IpSets: list<record>, DnsName: string, Status: string, CreatedTime: string, LastModifiedTime: string>>"
    describe-custom-routing-accelerator-attributes: "record<AcceleratorAttributes: record<FlowLogsEnabled: bool, FlowLogsS3Bucket: string, FlowLogsS3Prefix: string>>"
    describe-custom-routing-endpoint-group: "record<EndpointGroup: record<EndpointGroupArn: string, EndpointGroupRegion: string, DestinationDescriptions: list<record>, EndpointDescriptions: list<record>>>"
    describe-custom-routing-listener: "record<Listener: record<ListenerArn: string, PortRanges: list<record>>>"
    describe-endpoint-group: "record<EndpointGroup: record<EndpointGroupArn: string, EndpointGroupRegion: string, EndpointDescriptions: list<record>, TrafficDialPercentage: float, HealthCheckPort: int, HealthCheckProtocol: string, HealthCheckPath: string, HealthCheckIntervalSeconds: int, ThresholdCount: int, PortOverrides: list<record>>>"
    describe-listener: "record<Listener: record<ListenerArn: string, PortRanges: list<record>, Protocol: string, ClientAffinity: string>>"
    list-accelerators: "record<Accelerators: table<AcceleratorArn: string, Name: string, IpAddressType: string, Enabled: bool, IpSets: list, DnsName: string, Status: string, CreatedTime: string, LastModifiedTime: string, DualStackDnsName: string, Events: list>, NextToken: string>"
    list-byoip-cidrs: "record<ByoipCidrs: table<Cidr: string, State: string, Events: list>, NextToken: string>"
    list-custom-routing-accelerators: "record<Accelerators: table<AcceleratorArn: string, Name: string, IpAddressType: string, Enabled: bool, IpSets: list, DnsName: string, Status: string, CreatedTime: string, LastModifiedTime: string>, NextToken: string>"
    list-custom-routing-endpoint-groups: "record<EndpointGroups: table<EndpointGroupArn: string, EndpointGroupRegion: string, DestinationDescriptions: list, EndpointDescriptions: list>, NextToken: string>"
    list-custom-routing-listeners: "record<Listeners: table<ListenerArn: string, PortRanges: list>, NextToken: string>"
    list-custom-routing-port-mappings: "record<PortMappings: table<AcceleratorPort: int, EndpointGroupArn: string, EndpointId: string, DestinationSocketAddress: record, Protocols: list, DestinationTrafficState: string>, NextToken: string>"
    list-custom-routing-port-mappings-by-destination: "record<DestinationPortMappings: table<AcceleratorArn: string, AcceleratorSocketAddresses: list, EndpointGroupArn: string, EndpointId: string, EndpointGroupRegion: string, DestinationSocketAddress: record, IpAddressType: string, DestinationTrafficState: string>, NextToken: string>"
    list-endpoint-groups: "record<EndpointGroups: table<EndpointGroupArn: string, EndpointGroupRegion: string, EndpointDescriptions: list, TrafficDialPercentage: float, HealthCheckPort: int, HealthCheckProtocol: string, HealthCheckPath: string, HealthCheckIntervalSeconds: int, ThresholdCount: int, PortOverrides: list>, NextToken: string>"
    list-listeners: "record<Listeners: table<ListenerArn: string, PortRanges: list, Protocol: string, ClientAffinity: string>, NextToken: string>"
    list-tags-for-resource: "record<Tags: table<Key: string, Value: string>>"
    provision-byoip-cidr: "record<ByoipCidr: record<Cidr: string, State: string, Events: list<record>>>"
    tag-resource: "record"
    untag-resource: "record"
    update-accelerator: "record<Accelerator: record<AcceleratorArn: string, Name: string, IpAddressType: string, Enabled: bool, IpSets: list<record>, DnsName: string, Status: string, CreatedTime: string, LastModifiedTime: string, DualStackDnsName: string, Events: list<record>>>"
    update-accelerator-attributes: "record<AcceleratorAttributes: record<FlowLogsEnabled: bool, FlowLogsS3Bucket: string, FlowLogsS3Prefix: string>>"
    update-custom-routing-accelerator: "record<Accelerator: record<AcceleratorArn: string, Name: string, IpAddressType: string, Enabled: bool, IpSets: list<record>, DnsName: string, Status: string, CreatedTime: string, LastModifiedTime: string>>"
    update-custom-routing-accelerator-attributes: "record<AcceleratorAttributes: record<FlowLogsEnabled: bool, FlowLogsS3Bucket: string, FlowLogsS3Prefix: string>>"
    update-custom-routing-listener: "record<Listener: record<ListenerArn: string, PortRanges: list<record>>>"
    update-endpoint-group: "record<EndpointGroup: record<EndpointGroupArn: string, EndpointGroupRegion: string, EndpointDescriptions: list<record>, TrafficDialPercentage: float, HealthCheckPort: int, HealthCheckProtocol: string, HealthCheckPath: string, HealthCheckIntervalSeconds: int, ThresholdCount: int, PortOverrides: list<record>>>"
    update-listener: "record<Listener: record<ListenerArn: string, PortRanges: list<record>, Protocol: string, ClientAffinity: string>>"
    withdraw-byoip-cidr: "record<ByoipCidr: record<Cidr: string, State: string, Events: list<record>>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["add-custom-routing-endpoints" "add-endpoints" "advertise-byoip-cidr" "allow-custom-routing-traffic" "create-accelerator" "create-custom-routing-accelerator" "create-custom-routing-endpoint-group" "create-custom-routing-listener" "create-endpoint-group" "create-listener" "delete-accelerator" "delete-custom-routing-accelerator" "delete-custom-routing-endpoint-group" "delete-custom-routing-listener" "delete-endpoint-group" "delete-listener" "deny-custom-routing-traffic" "deprovision-byoip-cidr" "describe-accelerator" "describe-accelerator-attributes" "describe-custom-routing-accelerator" "describe-custom-routing-accelerator-attributes" "describe-custom-routing-endpoint-group" "describe-custom-routing-listener" "describe-endpoint-group" "describe-listener" "list-accelerators" "list-byoip-cidrs" "list-custom-routing-accelerators" "list-custom-routing-endpoint-groups" "list-custom-routing-listeners" "list-custom-routing-port-mappings" "list-custom-routing-port-mappings-by-destination" "list-endpoint-groups" "list-listeners" "list-tags-for-resource" "provision-byoip-cidr" "remove-custom-routing-endpoints" "remove-endpoints" "tag-resource" "untag-resource" "update-accelerator" "update-accelerator-attributes" "update-custom-routing-accelerator" "update-custom-routing-accelerator-attributes" "update-custom-routing-listener" "update-endpoint-group" "update-listener" "withdraw-byoip-cidr" "commands"] | sort) } | get name | first)
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

# Associate a virtual private cloud (VPC) subnet endpoint with your custom routing accelerator. The listener port range must be large enough to support the number of IP addresses that can be specified in your subnet. The number of ports required is: subnet size times the number of ports per destination EC2 instances. For example, a subnet defined as /24 requires a listener port range of at least 255 ports. Note: You must have enough remaining listener ports available to map to the subnet ports, or the call will fail with a LimitExceededException. By default, all destinations in a subnet in a custom routing accelerator cannot receive traffic. To enable all destinations to receive traffic, or to specify individual port mappings that can receive traffic, see the AllowCustomRoutingTraffic (https://docs.aws.amazon.com/global-accelerator/latest/api/API_AllowCustomRoutingTraffic.html) operation.
#
# POST /
# Returns: record<EndpointDescriptions: table<EndpointId: string>, EndpointGroupArn: string>
# operationId: AddCustomRoutingEndpoints
export def "add-custom-routing-endpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer # required
  endpoint_configurations: list # The list of endpoint objects to add to a custom routing accelerator. — item shape: {EndpointId?: string}
  endpoint_group_arn: string # The Amazon Resource Name (ARN) of the endpoint group for the custom routing endpoint.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.AddCustomRoutingEndpoints"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndpointConfigurations, var: endpoint_configurations}, {name: EndpointGroupArn, var: endpoint_group_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, endpoint_configurations: $endpoint_configurations, endpoint_group_arn: $endpoint_group_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add endpoints to an endpoint group. The AddEndpoints API operation is the recommended option for adding endpoints. The alternative options are to add endpoints when you create an endpoint group (with the CreateEndpointGroup (https://docs.aws.amazon.com/global-accelerator/latest/api/API_CreateEndpointGroup.html) API) or when you update an endpoint group (with the UpdateEndpointGroup (https://docs.aws.amazon.com/global-accelerator/latest/api/API_UpdateEndpointGroup.html) API). There are two advantages to using AddEndpoints to add endpoints: It's faster, because Global Accelerator only has to resolve the new endpoints that you're adding. It's more convenient, because you don't need to specify all of the current endpoints that are already in the endpoint group in addition to the new endpoints that you want to add.
#
# POST /
# Returns: record<EndpointDescriptions: table<EndpointId: string, Weight: int, HealthState: string, HealthReason: string, ClientIPPreservationEnabled: bool>, EndpointGroupArn: string>
# operationId: AddEndpoints
export def "add-endpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-1 # required
  endpoint_configurations: list # The list of endpoint objects. — item shape: {EndpointId?: string, Weight?: int, ClientIPPreservationEnabled?: bool}
  endpoint_group_arn: string # The Amazon Resource Name (ARN) of the endpoint group.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.AddEndpoints"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndpointConfigurations, var: endpoint_configurations}, {name: EndpointGroupArn, var: endpoint_group_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, endpoint_configurations: $endpoint_configurations, endpoint_group_arn: $endpoint_group_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Advertises an IPv4 address range that is provisioned for use with your Amazon Web Services resources through bring your own IP addresses (BYOIP). It can take a few minutes before traffic to the specified addresses starts routing to Amazon Web Services because of propagation delays. To stop advertising the BYOIP address range, use WithdrawByoipCidr (https://docs.aws.amazon.com/global-accelerator/latest/api/WithdrawByoipCidr.html). For more information, see Bring your own IP addresses (BYOIP) (https://docs.aws.amazon.com/global-accelerator/latest/dg/using-byoip.html) in the Global Accelerator Developer Guide.
#
# POST /
# Returns: record<ByoipCidr: record<Cidr: string, State: string, Events: list<record>>>
# operationId: AdvertiseByoipCidr
export def "advertise-byoip-cidr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-2 # required
  cidr: string # The address range, in CIDR notation. This must be the exact range that you provisioned. You can't advertise only a portion of the provisioned range.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.AdvertiseByoipCidr"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Cidr, var: cidr}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cidr: $cidr
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Specify the Amazon EC2 instance (destination) IP addresses and ports for a VPC subnet endpoint that can receive traffic for a custom routing accelerator. You can allow traffic to all destinations in the subnet endpoint, or allow traffic to a specified list of destination IP addresses and ports in the subnet. Note that you cannot specify IP addresses or ports outside of the range that you configured for the endpoint group. After you make changes, you can verify that the updates are complete by checking the status of your accelerator: the status changes from IN_PROGRESS to DEPLOYED.
#
# POST /
# operationId: AllowCustomRoutingTraffic
export def "allow-custom-routing-traffic" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-3 # required
  endpoint_group_arn: string # The Amazon Resource Name (ARN) of the endpoint group.
  endpoint_id: string # An ID for the endpoint. For custom routing accelerators, this is the virtual private cloud (VPC) subnet ID.
  --destination-addresses: list<string> # A list of specific Amazon EC2 instance IP addresses (destination addresses) in a subnet that you want to allow to receive traffic. The IP addresses must be a subset of the IP addresses that you specified for the endpoint group. DestinationAddresses is required if AllowAllTrafficToEndpoint is FALSE or is not specified.
  --destination-ports: list<int> # A list of specific Amazon EC2 instance ports (destination ports) that you want to allow to receive traffic.
  --allow-all-traffic-to-endpoint: oneof<nothing, bool> # Indicates whether all destination IP addresses and ports for a specified VPC subnet endpoint can receive traffic from a custom routing accelerator. The value is TRUE or FALSE. When set to TRUE, all destinations in the custom routing VPC subnet can receive traffic. Note that you cannot specify destination IP addresses and ports when the value is set to TRUE. When set to FALSE (or not specified), you must specify a list of destination IP addresses that are allowed to receive traffic. A list of ports is optional. If you don't specify a list of ports, the ports that can accept traffic is the same as the ports configured for the endpoint group. The default value is FALSE.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.AllowCustomRoutingTraffic"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndpointGroupArn, var: endpoint_group_arn}, {name: EndpointId, var: endpoint_id}, {name: DestinationAddresses, var: destination_addresses}, {name: DestinationPorts, var: destination_ports}, {name: AllowAllTrafficToEndpoint, var: allow_all_traffic_to_endpoint}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, endpoint_group_arn: $endpoint_group_arn, endpoint_id: $endpoint_id, destination_addresses: $destination_addresses, destination_ports: $destination_ports, allow_all_traffic_to_endpoint: $allow_all_traffic_to_endpoint
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an accelerator. An accelerator includes one or more listeners that process inbound connections and direct traffic to one or more endpoint groups, each of which includes endpoints, such as Network Load Balancers. Global Accelerator is a global service that supports endpoints in multiple Amazon Web Services Regions but you must specify the US West (Oregon) Region to create, update, or otherwise work with accelerators. That is, for example, specify --region us-west-2 on AWS CLI commands.
#
# POST /
# Returns: record<Accelerator: record<AcceleratorArn: string, Name: string, IpAddressType: string, Enabled: bool, IpSets: list<record>, DnsName: string, Status: string, CreatedTime: string, LastModifiedTime: string, DualStackDnsName: string, Events: list<record>>>
# operationId: CreateAccelerator
export def "create-accelerator" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-4 # required
  name: string # The name of the accelerator. The name can have a maximum of 64 characters, must contain only alphanumeric characters, periods (.), or hyphens (-), and must not begin or end with a hyphen or period.
  --ip-address-type: string@ip-address-type-completer # The IP address type that an accelerator supports. For a standard accelerator, the value can be IPV4 or DUAL_STACK.
  --ip-addresses: list<string> # Optionally, if you've added your own IP address pool to Global Accelerator (BYOIP), you can choose an IPv4 address from your own pool to use for the accelerator's static IPv4 address when you create an accelerator. After you bring an address range to Amazon Web Services, it appears in your account as an address pool. When you create an accelerator, you can assign one IPv4 address from your range to it. Global Accelerator assigns you a second static IPv4 address from an Amazon IP address range. If you bring two IPv4 address ranges to Amazon Web Services, you can assign one IPv4 address from each range to your accelerator. This restriction is because Global Accelerator assigns each address range to a different network zone, for high availability. You can specify one or two addresses, separated by a space. Do not include the /32 suffix. Note that you can't update IP addresses for an existing accelerator. To change them, you must create a new accelerator with the new addresses. For more information, see Bring your own IP addresses (BYOIP) (https://docs.aws.amazon.com/global-accelerator/latest/dg/using-byoip.html) in the Global Accelerator Developer Guide.
  --enabled: oneof<nothing, bool> # Indicates whether an accelerator is enabled. The value is true or false. The default value is true. If the value is set to true, an accelerator cannot be deleted. If set to false, the accelerator can be deleted.
  idempotency_token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency—that is, the uniqueness—of an accelerator.
  --tags: list # Create tags for an accelerator. For more information, see Tagging in Global Accelerator (https://docs.aws.amazon.com/global-accelerator/latest/dg/tagging-in-global-accelerator.html) in the Global Accelerator Developer Guide. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.CreateAccelerator"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: IpAddressType, var: ip_address_type}, {name: IpAddresses, var: ip_addresses}, {name: Enabled, var: enabled}, {name: IdempotencyToken, var: idempotency_token}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, ip_address_type: $ip_address_type, ip_addresses: $ip_addresses, enabled: $enabled, idempotency_token: $idempotency_token, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a custom routing accelerator. A custom routing accelerator directs traffic to one of possibly thousands of Amazon EC2 instance destinations running in a single or multiple virtual private clouds (VPC) subnet endpoints. Be aware that, by default, all destination EC2 instances in a VPC subnet endpoint cannot receive traffic. To enable all destinations to receive traffic, or to specify individual port mappings that can receive traffic, see the AllowCustomRoutingTraffic (https://docs.aws.amazon.com/global-accelerator/latest/api/API_AllowCustomRoutingTraffic.html) operation. Global Accelerator is a global service that supports endpoints in multiple Amazon Web Services Regions but you must specify the US West (Oregon) Region to create, update, or otherwise work with accelerators. That is, for example, specify --region us-west-2 on AWS CLI commands.
#
# POST /
# Returns: record<Accelerator: record<AcceleratorArn: string, Name: string, IpAddressType: string, Enabled: bool, IpSets: list<record>, DnsName: string, Status: string, CreatedTime: string, LastModifiedTime: string>>
# operationId: CreateCustomRoutingAccelerator
export def "create-custom-routing-accelerator" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-5 # required
  name: string # The name of a custom routing accelerator. The name can have a maximum of 64 characters, must contain only alphanumeric characters or hyphens (-), and must not begin or end with a hyphen.
  --ip-address-type: string@ip-address-type-completer # The IP address type that an accelerator supports. For a custom routing accelerator, the value must be IPV4.
  --ip-addresses: list<string> # Optionally, if you've added your own IP address pool to Global Accelerator (BYOIP), you can choose an IPv4 address from your own pool to use for the accelerator's static IPv4 address when you create an accelerator. After you bring an address range to Amazon Web Services, it appears in your account as an address pool. When you create an accelerator, you can assign one IPv4 address from your range to it. Global Accelerator assigns you a second static IPv4 address from an Amazon IP address range. If you bring two IPv4 address ranges to Amazon Web Services, you can assign one IPv4 address from each range to your accelerator. This restriction is because Global Accelerator assigns each address range to a different network zone, for high availability. You can specify one or two addresses, separated by a space. Do not include the /32 suffix. Note that you can't update IP addresses for an existing accelerator. To change them, you must create a new accelerator with the new addresses. For more information, see Bring your own IP addresses (BYOIP) (https://docs.aws.amazon.com/global-accelerator/latest/dg/using-byoip.html) in the Global Accelerator Developer Guide.
  --enabled: oneof<nothing, bool> # Indicates whether an accelerator is enabled. The value is true or false. The default value is true. If the value is set to true, an accelerator cannot be deleted. If set to false, the accelerator can be deleted.
  idempotency_token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency—that is, the uniqueness—of the request.
  --tags: list # Create tags for an accelerator. For more information, see Tagging in Global Accelerator (https://docs.aws.amazon.com/global-accelerator/latest/dg/tagging-in-global-accelerator.html) in the Global Accelerator Developer Guide. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.CreateCustomRoutingAccelerator"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: IpAddressType, var: ip_address_type}, {name: IpAddresses, var: ip_addresses}, {name: Enabled, var: enabled}, {name: IdempotencyToken, var: idempotency_token}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, ip_address_type: $ip_address_type, ip_addresses: $ip_addresses, enabled: $enabled, idempotency_token: $idempotency_token, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an endpoint group for the specified listener for a custom routing accelerator. An endpoint group is a collection of endpoints in one Amazon Web Services Region.
#
# POST /
# Returns: record<EndpointGroup: record<EndpointGroupArn: string, EndpointGroupRegion: string, DestinationDescriptions: list<record>, EndpointDescriptions: list<record>>>
# operationId: CreateCustomRoutingEndpointGroup
export def "create-custom-routing-endpoint-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-6 # required
  listener_arn: string # The Amazon Resource Name (ARN) of the listener for a custom routing endpoint.
  endpoint_group_region: string # The Amazon Web Services Region where the endpoint group is located. A listener can have only one endpoint group in a specific Region.
  destination_configurations: list # Sets the port range and protocol for all endpoints (virtual private cloud subnets) in a custom routing endpoint group to accept client traffic on. — item shape: {FromPort: int, ToPort: int, Protocols: list<string>}
  idempotency_token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency—that is, the uniqueness—of the request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.CreateCustomRoutingEndpointGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ListenerArn, var: listener_arn}, {name: EndpointGroupRegion, var: endpoint_group_region}, {name: DestinationConfigurations, var: destination_configurations}, {name: IdempotencyToken, var: idempotency_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, listener_arn: $listener_arn, endpoint_group_region: $endpoint_group_region, destination_configurations: $destination_configurations, idempotency_token: $idempotency_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a listener to process inbound connections from clients to a custom routing accelerator. Connections arrive to assigned static IP addresses on the port range that you specify.
#
# POST /
# Returns: record<Listener: record<ListenerArn: string, PortRanges: list<record>>>
# operationId: CreateCustomRoutingListener
export def "create-custom-routing-listener" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-7 # required
  accelerator_arn: string # The Amazon Resource Name (ARN) of the accelerator for a custom routing listener.
  port_ranges: list # The port range to support for connections from clients to your accelerator. Separately, you set port ranges for endpoints. For more information, see About endpoints for custom routing accelerators (https://docs.aws.amazon.com/global-accelerator/latest/dg/about-custom-routing-endpoints.html). — item shape: {FromPort?: int, ToPort?: int}
  idempotency_token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency—that is, the uniqueness—of the request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.CreateCustomRoutingListener"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceleratorArn, var: accelerator_arn}, {name: PortRanges, var: port_ranges}, {name: IdempotencyToken, var: idempotency_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accelerator_arn: $accelerator_arn, port_ranges: $port_ranges, idempotency_token: $idempotency_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an endpoint group for the specified listener. An endpoint group is a collection of endpoints in one Amazon Web Services Region. A resource must be valid and active when you add it as an endpoint.
#
# POST /
# Returns: record<EndpointGroup: record<EndpointGroupArn: string, EndpointGroupRegion: string, EndpointDescriptions: list<record>, TrafficDialPercentage: float, HealthCheckPort: int, HealthCheckProtocol: string, HealthCheckPath: string, HealthCheckIntervalSeconds: int, ThresholdCount: int, PortOverrides: list<record>>>
# operationId: CreateEndpointGroup
export def "create-endpoint-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-8 # required
  listener_arn: string # The Amazon Resource Name (ARN) of the listener.
  endpoint_group_region: string # The Amazon Web Services Region where the endpoint group is located. A listener can have only one endpoint group in a specific Region.
  --endpoint-configurations: list # The list of endpoint objects. — item shape: {EndpointId?: string, Weight?: int, ClientIPPreservationEnabled?: bool}
  --traffic-dial-percentage: float # The percentage of traffic to send to an Amazon Web Services Region. Additional traffic is distributed to other endpoint groups for this listener. Use this action to increase (dial up) or decrease (dial down) traffic to a specific Region. The percentage is applied to the traffic that would otherwise have been routed to the Region based on optimal routing. The default value is 100. (format: float)
  --health-check-port: int # The port that Global Accelerator uses to check the health of endpoints that are part of this endpoint group. The default port is the listener port that this endpoint group is associated with. If listener port is a list of ports, Global Accelerator uses the first port in the list.
  --health-check-protocol: string@health-check-protocol-completer # The protocol that Global Accelerator uses to check the health of endpoints that are part of this endpoint group. The default value is TCP.
  --health-check-path: string # If the protocol is HTTP/S, then this specifies the path that is the destination for health check targets. The default value is slash (/).
  --health-check-interval-seconds: int # The time—10 seconds or 30 seconds—between each health check for an endpoint. The default value is 30.
  --threshold-count: int # The number of consecutive health checks required to set the state of a healthy endpoint to unhealthy, or to set an unhealthy endpoint to healthy. The default value is 3.
  idempotency_token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency—that is, the uniqueness—of the request.
  --port-overrides: list # Override specific listener ports used to route traffic to endpoints that are part of this endpoint group. For example, you can create a port override in which the listener receives user traffic on ports 80 and 443, but your accelerator routes that traffic to ports 1080 and 1443, respectively, on the endpoints. For more information, see Overriding listener ports (https://docs.aws.amazon.com/global-accelerator/latest/dg/about-endpoint-groups-port-override.html) in the Global Accelerator Developer Guide. — item shape: {ListenerPort?: int, EndpointPort?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.CreateEndpointGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ListenerArn, var: listener_arn}, {name: EndpointGroupRegion, var: endpoint_group_region}, {name: EndpointConfigurations, var: endpoint_configurations}, {name: TrafficDialPercentage, var: traffic_dial_percentage}, {name: HealthCheckPort, var: health_check_port}, {name: HealthCheckProtocol, var: health_check_protocol}, {name: HealthCheckPath, var: health_check_path}, {name: HealthCheckIntervalSeconds, var: health_check_interval_seconds}, {name: ThresholdCount, var: threshold_count}, {name: IdempotencyToken, var: idempotency_token}, {name: PortOverrides, var: port_overrides}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, listener_arn: $listener_arn, endpoint_group_region: $endpoint_group_region, endpoint_configurations: $endpoint_configurations, traffic_dial_percentage: $traffic_dial_percentage, health_check_port: $health_check_port, health_check_protocol: $health_check_protocol, health_check_path: $health_check_path, health_check_interval_seconds: $health_check_interval_seconds, threshold_count: $threshold_count, idempotency_token: $idempotency_token, port_overrides: $port_overrides
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a listener to process inbound connections from clients to an accelerator. Connections arrive to assigned static IP addresses on a port, port range, or list of port ranges that you specify.
#
# POST /
# Returns: record<Listener: record<ListenerArn: string, PortRanges: list<record>, Protocol: string, ClientAffinity: string>>
# operationId: CreateListener
export def "create-listener" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-9 # required
  accelerator_arn: string # The Amazon Resource Name (ARN) of your accelerator.
  port_ranges: list # The list of port ranges to support for connections from clients to your accelerator. — item shape: {FromPort?: int, ToPort?: int}
  protocol: string@protocol-completer # The protocol for connections from clients to your accelerator.
  --client-affinity: string@client-affinity-completer # Client affinity lets you direct all requests from a user to the same endpoint, if you have stateful applications, regardless of the port and protocol of the client request. Client affinity gives you control over whether to always route each client to the same specific endpoint. Global Accelerator uses a consistent-flow hashing algorithm to choose the optimal endpoint for a connection. If client affinity is NONE, Global Accelerator uses the "five-tuple" (5-tuple) properties—source IP address, source port, destination IP address, destination port, and protocol—to select the hash value, and then chooses the best endpoint. However, with this setting, if someone uses different ports to connect to Global Accelerator, their connections might not be always routed to the same endpoint because the hash value changes. If you want a given client to always be routed to the same endpoint, set client affinity to SOURCE_IP instead. When you use the SOURCE_IP setting, Global Accelerator uses the "two-tuple" (2-tuple) properties— source (client) IP address and destination IP address—to select the hash value. The default value is NONE.
  idempotency_token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency—that is, the uniqueness—of the request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.CreateListener"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceleratorArn, var: accelerator_arn}, {name: PortRanges, var: port_ranges}, {name: Protocol, var: protocol}, {name: ClientAffinity, var: client_affinity}, {name: IdempotencyToken, var: idempotency_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accelerator_arn: $accelerator_arn, port_ranges: $port_ranges, protocol: $protocol, client_affinity: $client_affinity, idempotency_token: $idempotency_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an accelerator. Before you can delete an accelerator, you must disable it and remove all dependent resources (listeners and endpoint groups). To disable the accelerator, update the accelerator to set Enabled to false. When you create an accelerator, by default, Global Accelerator provides you with a set of two static IP addresses. Alternatively, you can bring your own IP address ranges to Global Accelerator and assign IP addresses from those ranges. The IP addresses are assigned to your accelerator for as long as it exists, even if you disable the accelerator and it no longer accepts or routes traffic. However, when you delete an accelerator, you lose the static IP addresses that are assigned to the accelerator, so you can no longer route traffic by using them. As a best practice, ensure that you have permissions in place to avoid inadvertently deleting accelerators. You can use IAM policies with Global Accelerator to limit the users who have permissions to delete an accelerator. For more information, see Identity and access management (https://docs.aws.amazon.com/global-accelerator/latest/dg/auth-and-access-control.html) in the Global Accelerator Developer Guide.
#
# POST /
# operationId: DeleteAccelerator
export def "delete-accelerator" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-10 # required
  accelerator_arn: string # The Amazon Resource Name (ARN) of an accelerator.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.DeleteAccelerator"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceleratorArn, var: accelerator_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accelerator_arn: $accelerator_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a custom routing accelerator. Before you can delete an accelerator, you must disable it and remove all dependent resources (listeners and endpoint groups). To disable the accelerator, update the accelerator to set Enabled to false. When you create a custom routing accelerator, by default, Global Accelerator provides you with a set of two static IP addresses. The IP addresses are assigned to your accelerator for as long as it exists, even if you disable the accelerator and it no longer accepts or routes traffic. However, when you delete an accelerator, you lose the static IP addresses that are assigned to the accelerator, so you can no longer route traffic by using them. As a best practice, ensure that you have permissions in place to avoid inadvertently deleting accelerators. You can use IAM policies with Global Accelerator to limit the users who have permissions to delete an accelerator. For more information, see Identity and access management (https://docs.aws.amazon.com/global-accelerator/latest/dg/auth-and-access-control.html) in the Global Accelerator Developer Guide.
#
# POST /
# operationId: DeleteCustomRoutingAccelerator
export def "delete-custom-routing-accelerator" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-11 # required
  accelerator_arn: string # The Amazon Resource Name (ARN) of the custom routing accelerator to delete.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.DeleteCustomRoutingAccelerator"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceleratorArn, var: accelerator_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accelerator_arn: $accelerator_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an endpoint group from a listener for a custom routing accelerator.
#
# POST /
# operationId: DeleteCustomRoutingEndpointGroup
export def "delete-custom-routing-endpoint-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-12 # required
  endpoint_group_arn: string # The Amazon Resource Name (ARN) of the endpoint group to delete.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.DeleteCustomRoutingEndpointGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndpointGroupArn, var: endpoint_group_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, endpoint_group_arn: $endpoint_group_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a listener for a custom routing accelerator.
#
# POST /
# operationId: DeleteCustomRoutingListener
export def "delete-custom-routing-listener" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-13 # required
  listener_arn: string # The Amazon Resource Name (ARN) of the listener to delete.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.DeleteCustomRoutingListener"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ListenerArn, var: listener_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, listener_arn: $listener_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an endpoint group from a listener.
#
# POST /
# operationId: DeleteEndpointGroup
export def "delete-endpoint-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-14 # required
  endpoint_group_arn: string # The Amazon Resource Name (ARN) of the endpoint group to delete.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.DeleteEndpointGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndpointGroupArn, var: endpoint_group_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, endpoint_group_arn: $endpoint_group_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a listener from an accelerator.
#
# POST /
# operationId: DeleteListener
export def "delete-listener" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-15 # required
  listener_arn: string # The Amazon Resource Name (ARN) of the listener.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.DeleteListener"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ListenerArn, var: listener_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, listener_arn: $listener_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Specify the Amazon EC2 instance (destination) IP addresses and ports for a VPC subnet endpoint that cannot receive traffic for a custom routing accelerator. You can deny traffic to all destinations in the VPC endpoint, or deny traffic to a specified list of destination IP addresses and ports. Note that you cannot specify IP addresses or ports outside of the range that you configured for the endpoint group. After you make changes, you can verify that the updates are complete by checking the status of your accelerator: the status changes from IN_PROGRESS to DEPLOYED.
#
# POST /
# operationId: DenyCustomRoutingTraffic
export def "deny-custom-routing-traffic" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-16 # required
  endpoint_group_arn: string # The Amazon Resource Name (ARN) of the endpoint group.
  endpoint_id: string # An ID for the endpoint. For custom routing accelerators, this is the virtual private cloud (VPC) subnet ID.
  --destination-addresses: list<string> # A list of specific Amazon EC2 instance IP addresses (destination addresses) in a subnet that you want to prevent from receiving traffic. The IP addresses must be a subset of the IP addresses allowed for the VPC subnet associated with the endpoint group.
  --destination-ports: list<int> # A list of specific Amazon EC2 instance ports (destination ports) in a subnet endpoint that you want to prevent from receiving traffic.
  --deny-all-traffic-to-endpoint: oneof<nothing, bool> # Indicates whether all destination IP addresses and ports for a specified VPC subnet endpoint cannot receive traffic from a custom routing accelerator. The value is TRUE or FALSE. When set to TRUE, no destinations in the custom routing VPC subnet can receive traffic. Note that you cannot specify destination IP addresses and ports when the value is set to TRUE. When set to FALSE (or not specified), you must specify a list of destination IP addresses that cannot receive traffic. A list of ports is optional. If you don't specify a list of ports, the ports that can accept traffic is the same as the ports configured for the endpoint group. The default value is FALSE.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.DenyCustomRoutingTraffic"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndpointGroupArn, var: endpoint_group_arn}, {name: EndpointId, var: endpoint_id}, {name: DestinationAddresses, var: destination_addresses}, {name: DestinationPorts, var: destination_ports}, {name: DenyAllTrafficToEndpoint, var: deny_all_traffic_to_endpoint}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, endpoint_group_arn: $endpoint_group_arn, endpoint_id: $endpoint_id, destination_addresses: $destination_addresses, destination_ports: $destination_ports, deny_all_traffic_to_endpoint: $deny_all_traffic_to_endpoint
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Releases the specified address range that you provisioned to use with your Amazon Web Services resources through bring your own IP addresses (BYOIP) and deletes the corresponding address pool. Before you can release an address range, you must stop advertising it by using WithdrawByoipCidr (https://docs.aws.amazon.com/global-accelerator/latest/api/WithdrawByoipCidr.html) and you must not have any accelerators that are using static IP addresses allocated from its address range. For more information, see Bring your own IP addresses (BYOIP) (https://docs.aws.amazon.com/global-accelerator/latest/dg/using-byoip.html) in the Global Accelerator Developer Guide.
#
# POST /
# Returns: record<ByoipCidr: record<Cidr: string, State: string, Events: list<record>>>
# operationId: DeprovisionByoipCidr
export def "deprovision-byoip-cidr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-17 # required
  cidr: string # The address range, in CIDR notation. The prefix must be the same prefix that you specified when you provisioned the address range.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.DeprovisionByoipCidr"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Cidr, var: cidr}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cidr: $cidr
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describe an accelerator.
#
# POST /
# Returns: record<Accelerator: record<AcceleratorArn: string, Name: string, IpAddressType: string, Enabled: bool, IpSets: list<record>, DnsName: string, Status: string, CreatedTime: string, LastModifiedTime: string, DualStackDnsName: string, Events: list<record>>>
# operationId: DescribeAccelerator
export def "describe-accelerator" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-18 # required
  accelerator_arn: string # The Amazon Resource Name (ARN) of the accelerator to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.DescribeAccelerator"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceleratorArn, var: accelerator_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accelerator_arn: $accelerator_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describe the attributes of an accelerator.
#
# POST /
# Returns: record<AcceleratorAttributes: record<FlowLogsEnabled: bool, FlowLogsS3Bucket: string, FlowLogsS3Prefix: string>>
# operationId: DescribeAcceleratorAttributes
export def "describe-accelerator-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-19 # required
  accelerator_arn: string # The Amazon Resource Name (ARN) of the accelerator with the attributes that you want to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.DescribeAcceleratorAttributes"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceleratorArn, var: accelerator_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accelerator_arn: $accelerator_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describe a custom routing accelerator.
#
# POST /
# Returns: record<Accelerator: record<AcceleratorArn: string, Name: string, IpAddressType: string, Enabled: bool, IpSets: list<record>, DnsName: string, Status: string, CreatedTime: string, LastModifiedTime: string>>
# operationId: DescribeCustomRoutingAccelerator
export def "describe-custom-routing-accelerator" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-20 # required
  accelerator_arn: string # The Amazon Resource Name (ARN) of the accelerator to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.DescribeCustomRoutingAccelerator"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceleratorArn, var: accelerator_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accelerator_arn: $accelerator_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describe the attributes of a custom routing accelerator.
#
# POST /
# Returns: record<AcceleratorAttributes: record<FlowLogsEnabled: bool, FlowLogsS3Bucket: string, FlowLogsS3Prefix: string>>
# operationId: DescribeCustomRoutingAcceleratorAttributes
export def "describe-custom-routing-accelerator-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-21 # required
  accelerator_arn: string # The Amazon Resource Name (ARN) of the custom routing accelerator to describe the attributes for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.DescribeCustomRoutingAcceleratorAttributes"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceleratorArn, var: accelerator_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accelerator_arn: $accelerator_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describe an endpoint group for a custom routing accelerator.
#
# POST /
# Returns: record<EndpointGroup: record<EndpointGroupArn: string, EndpointGroupRegion: string, DestinationDescriptions: list<record>, EndpointDescriptions: list<record>>>
# operationId: DescribeCustomRoutingEndpointGroup
export def "describe-custom-routing-endpoint-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-22 # required
  endpoint_group_arn: string # The Amazon Resource Name (ARN) of the endpoint group to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.DescribeCustomRoutingEndpointGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndpointGroupArn, var: endpoint_group_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, endpoint_group_arn: $endpoint_group_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The description of a listener for a custom routing accelerator.
#
# POST /
# Returns: record<Listener: record<ListenerArn: string, PortRanges: list<record>>>
# operationId: DescribeCustomRoutingListener
export def "describe-custom-routing-listener" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-23 # required
  listener_arn: string # The Amazon Resource Name (ARN) of the listener to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.DescribeCustomRoutingListener"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ListenerArn, var: listener_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, listener_arn: $listener_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describe an endpoint group.
#
# POST /
# Returns: record<EndpointGroup: record<EndpointGroupArn: string, EndpointGroupRegion: string, EndpointDescriptions: list<record>, TrafficDialPercentage: float, HealthCheckPort: int, HealthCheckProtocol: string, HealthCheckPath: string, HealthCheckIntervalSeconds: int, ThresholdCount: int, PortOverrides: list<record>>>
# operationId: DescribeEndpointGroup
export def "describe-endpoint-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-24 # required
  endpoint_group_arn: string # The Amazon Resource Name (ARN) of the endpoint group to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.DescribeEndpointGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndpointGroupArn, var: endpoint_group_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, endpoint_group_arn: $endpoint_group_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describe a listener.
#
# POST /
# Returns: record<Listener: record<ListenerArn: string, PortRanges: list<record>, Protocol: string, ClientAffinity: string>>
# operationId: DescribeListener
export def "describe-listener" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-25 # required
  listener_arn: string # The Amazon Resource Name (ARN) of the listener to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.DescribeListener"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ListenerArn, var: listener_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, listener_arn: $listener_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the accelerators for an Amazon Web Services account.
#
# POST /
# Returns: record<Accelerators: table<AcceleratorArn: string, Name: string, IpAddressType: string, Enabled: bool, IpSets: list, DnsName: string, Status: string, CreatedTime: string, LastModifiedTime: string, DualStackDnsName: string, Events: list>, NextToken: string>
# operationId: ListAccelerators
export def "list-accelerators" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-26 # required
  --body-max-results: int # The number of Global Accelerator objects that you want to return with this call. The default value is 10. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of results. You receive this token from a previous call. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.ListAccelerators"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the IP address ranges that were specified in calls to ProvisionByoipCidr (https://docs.aws.amazon.com/global-accelerator/latest/api/ProvisionByoipCidr.html), including the current state and a history of state changes.
#
# POST /
# Returns: record<ByoipCidrs: table<Cidr: string, State: string, Events: list>, NextToken: string>
# operationId: ListByoipCidrs
export def "list-byoip-cidrs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-27 # required
  --body-max-results: int # The maximum number of results to return with a single call. To retrieve the remaining results, make another call with the returned nextToken value. (spec name: MaxResults)
  --body-next-token: string # The token for the next page of results. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.ListByoipCidrs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the custom routing accelerators for an Amazon Web Services account.
#
# POST /
# Returns: record<Accelerators: table<AcceleratorArn: string, Name: string, IpAddressType: string, Enabled: bool, IpSets: list, DnsName: string, Status: string, CreatedTime: string, LastModifiedTime: string>, NextToken: string>
# operationId: ListCustomRoutingAccelerators
export def "list-custom-routing-accelerators" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-28 # required
  --body-max-results: int # The number of custom routing Global Accelerator objects that you want to return with this call. The default value is 10. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of results. You receive this token from a previous call. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.ListCustomRoutingAccelerators"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the endpoint groups that are associated with a listener for a custom routing accelerator.
#
# POST /
# Returns: record<EndpointGroups: table<EndpointGroupArn: string, EndpointGroupRegion: string, DestinationDescriptions: list, EndpointDescriptions: list>, NextToken: string>
# operationId: ListCustomRoutingEndpointGroups
export def "list-custom-routing-endpoint-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-29 # required
  listener_arn: string # The Amazon Resource Name (ARN) of the listener to list endpoint groups for.
  --body-max-results: int # The number of endpoint group objects that you want to return with this call. The default value is 10. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of results. You receive this token from a previous call. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.ListCustomRoutingEndpointGroups"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ListenerArn, var: listener_arn}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, listener_arn: $listener_arn, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the listeners for a custom routing accelerator.
#
# POST /
# Returns: record<Listeners: table<ListenerArn: string, PortRanges: list>, NextToken: string>
# operationId: ListCustomRoutingListeners
export def "list-custom-routing-listeners" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-30 # required
  accelerator_arn: string # The Amazon Resource Name (ARN) of the accelerator to list listeners for.
  --body-max-results: int # The number of listener objects that you want to return with this call. The default value is 10. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of results. You receive this token from a previous call. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.ListCustomRoutingListeners"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceleratorArn, var: accelerator_arn}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accelerator_arn: $accelerator_arn, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides a complete mapping from the public accelerator IP address and port to destination EC2 instance IP addresses and ports in the virtual public cloud (VPC) subnet endpoint for a custom routing accelerator. For each subnet endpoint that you add, Global Accelerator creates a new static port mapping for the accelerator. The port mappings don't change after Global Accelerator generates them, so you can retrieve and cache the full mapping on your servers. If you remove a subnet from your accelerator, Global Accelerator removes (reclaims) the port mappings. If you add a subnet to your accelerator, Global Accelerator creates new port mappings (the existing ones don't change). If you add or remove EC2 instances in your subnet, the port mappings don't change, because the mappings are created when you add the subnet to Global Accelerator. The mappings also include a flag for each destination denoting which destination IP addresses and ports are allowed or denied traffic.
#
# POST /
# Returns: record<PortMappings: table<AcceleratorPort: int, EndpointGroupArn: string, EndpointId: string, DestinationSocketAddress: record, Protocols: list, DestinationTrafficState: string>, NextToken: string>
# operationId: ListCustomRoutingPortMappings
export def "list-custom-routing-port-mappings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-31 # required
  accelerator_arn: string # The Amazon Resource Name (ARN) of the accelerator to list the custom routing port mappings for.
  --endpoint-group-arn: string # The Amazon Resource Name (ARN) of the endpoint group to list the custom routing port mappings for.
  --body-max-results: int # The number of destination port mappings that you want to return with this call. The default value is 10. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of results. You receive this token from a previous call. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.ListCustomRoutingPortMappings"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceleratorArn, var: accelerator_arn}, {name: EndpointGroupArn, var: endpoint_group_arn}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accelerator_arn: $accelerator_arn, endpoint_group_arn: $endpoint_group_arn, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the port mappings for a specific EC2 instance (destination) in a VPC subnet endpoint. The response is the mappings for one destination IP address. This is useful when your subnet endpoint has mappings that span multiple custom routing accelerators in your account, or for scenarios where you only want to list the port mappings for a specific destination instance.
#
# POST /
# Returns: record<DestinationPortMappings: table<AcceleratorArn: string, AcceleratorSocketAddresses: list, EndpointGroupArn: string, EndpointId: string, EndpointGroupRegion: string, DestinationSocketAddress: record, IpAddressType: string, DestinationTrafficState: string>, NextToken: string>
# operationId: ListCustomRoutingPortMappingsByDestination
export def "list-custom-routing-port-mappings-by-destination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-32 # required
  endpoint_id: string # The ID for the virtual private cloud (VPC) subnet.
  destination_address: string # The endpoint IP address in a virtual private cloud (VPC) subnet for which you want to receive back port mappings.
  --body-max-results: int # The number of destination port mappings that you want to return with this call. The default value is 10. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of results. You receive this token from a previous call. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.ListCustomRoutingPortMappingsByDestination"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndpointId, var: endpoint_id}, {name: DestinationAddress, var: destination_address}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, endpoint_id: $endpoint_id, destination_address: $destination_address, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the endpoint groups that are associated with a listener.
#
# POST /
# Returns: record<EndpointGroups: table<EndpointGroupArn: string, EndpointGroupRegion: string, EndpointDescriptions: list, TrafficDialPercentage: float, HealthCheckPort: int, HealthCheckProtocol: string, HealthCheckPath: string, HealthCheckIntervalSeconds: int, ThresholdCount: int, PortOverrides: list>, NextToken: string>
# operationId: ListEndpointGroups
export def "list-endpoint-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-33 # required
  listener_arn: string # The Amazon Resource Name (ARN) of the listener.
  --body-max-results: int # The number of endpoint group objects that you want to return with this call. The default value is 10. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of results. You receive this token from a previous call. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.ListEndpointGroups"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ListenerArn, var: listener_arn}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, listener_arn: $listener_arn, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the listeners for an accelerator.
#
# POST /
# Returns: record<Listeners: table<ListenerArn: string, PortRanges: list, Protocol: string, ClientAffinity: string>, NextToken: string>
# operationId: ListListeners
export def "list-listeners" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-34 # required
  accelerator_arn: string # The Amazon Resource Name (ARN) of the accelerator for which you want to list listener objects.
  --body-max-results: int # The number of listener objects that you want to return with this call. The default value is 10. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of results. You receive this token from a previous call. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.ListListeners"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceleratorArn, var: accelerator_arn}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accelerator_arn: $accelerator_arn, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all tags for an accelerator. For more information, see Tagging in Global Accelerator (https://docs.aws.amazon.com/global-accelerator/latest/dg/tagging-in-global-accelerator.html) in the Global Accelerator Developer Guide.
#
# POST /
# Returns: record<Tags: table<Key: string, Value: string>>
# operationId: ListTagsForResource
export def "list-tags-for-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-35 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the accelerator to list tags for. An ARN uniquely identifies an accelerator.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.ListTagsForResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provisions an IP address range to use with your Amazon Web Services resources through bring your own IP addresses (BYOIP) and creates a corresponding address pool. After the address range is provisioned, it is ready to be advertised using AdvertiseByoipCidr (https://docs.aws.amazon.com/global-accelerator/latest/api/AdvertiseByoipCidr.html). For more information, see Bring your own IP addresses (BYOIP) (https://docs.aws.amazon.com/global-accelerator/latest/dg/using-byoip.html) in the Global Accelerator Developer Guide.
#
# POST /
# Returns: record<ByoipCidr: record<Cidr: string, State: string, Events: list<record>>>
# operationId: ProvisionByoipCidr
export def "provision-byoip-cidr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-36 # required
  cidr: string # The public IPv4 address range, in CIDR notation. The most specific IP prefix that you can specify is /24. The address range cannot overlap with another address range that you've brought to this or another Region.
  cidr_authorization_context: record # Provides authorization for Amazon to bring a specific IP address range to a specific Amazon Web Services account using bring your own IP addresses (BYOIP). For more information, see Bring your own IP addresses (BYOIP) (https://docs.aws.amazon.com/global-accelerator/latest/dg/using-byoip.html) in the Global Accelerator Developer Guide. — shape: {Message: string, Signature: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.ProvisionByoipCidr"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Cidr, var: cidr}, {name: CidrAuthorizationContext, var: cidr_authorization_context}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cidr: $cidr, cidr_authorization_context: $cidr_authorization_context
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove endpoints from a custom routing accelerator.
#
# POST /
# operationId: RemoveCustomRoutingEndpoints
export def "remove-custom-routing-endpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-37 # required
  endpoint_ids: list<string> # The IDs for the endpoints. For custom routing accelerators, endpoint IDs are the virtual private cloud (VPC) subnet IDs.
  endpoint_group_arn: string # The Amazon Resource Name (ARN) of the endpoint group to remove endpoints from.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.RemoveCustomRoutingEndpoints"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndpointIds, var: endpoint_ids}, {name: EndpointGroupArn, var: endpoint_group_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, endpoint_ids: $endpoint_ids, endpoint_group_arn: $endpoint_group_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove endpoints from an endpoint group. The RemoveEndpoints API operation is the recommended option for removing endpoints. The alternative is to remove endpoints by updating an endpoint group by using the UpdateEndpointGroup (https://docs.aws.amazon.com/global-accelerator/latest/api/API_UpdateEndpointGroup.html) API operation. There are two advantages to using AddEndpoints to remove endpoints instead: It's more convenient, because you only need to specify the endpoints that you want to remove. With the UpdateEndpointGroup API operation, you must specify all of the endpoints in the endpoint group except the ones that you want to remove from the group. It's faster, because Global Accelerator doesn't need to resolve any endpoints. With the UpdateEndpointGroup API operation, Global Accelerator must resolve all of the endpoints that remain in the group.
#
# POST /
# operationId: RemoveEndpoints
export def "remove-endpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-38 # required
  endpoint_identifiers: list # The identifiers of the endpoints that you want to remove. — item shape: {EndpointId: string, ClientIPPreservationEnabled?: bool}
  endpoint_group_arn: string # The Amazon Resource Name (ARN) of the endpoint group.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.RemoveEndpoints"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndpointIdentifiers, var: endpoint_identifiers}, {name: EndpointGroupArn, var: endpoint_group_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, endpoint_identifiers: $endpoint_identifiers, endpoint_group_arn: $endpoint_group_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add tags to an accelerator resource. For more information, see Tagging in Global Accelerator (https://docs.aws.amazon.com/global-accelerator/latest/dg/tagging-in-global-accelerator.html) in the Global Accelerator Developer Guide.
#
# POST /
# Returns: record
# operationId: TagResource
export def "tag-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-39 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the Global Accelerator resource to add tags to. An ARN uniquely identifies a resource.
  tags: list # The tags to add to a resource. A tag consists of a key and a value that you define. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.TagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove tags from a Global Accelerator resource. When you specify a tag key, the action removes both that key and its associated value. The operation succeeds even if you attempt to remove tags from an accelerator that was already removed. For more information, see Tagging in Global Accelerator (https://docs.aws.amazon.com/global-accelerator/latest/dg/tagging-in-global-accelerator.html) in the Global Accelerator Developer Guide.
#
# POST /
# Returns: record
# operationId: UntagResource
export def "untag-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-40 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the Global Accelerator resource to remove tags from. An ARN uniquely identifies a resource.
  tag_keys: list<string> # The tag key pairs that you want to remove from the specified resources.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.UntagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: TagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an accelerator. Global Accelerator is a global service that supports endpoints in multiple Amazon Web Services Regions but you must specify the US West (Oregon) Region to create, update, or otherwise work with accelerators. That is, for example, specify --region us-west-2 on AWS CLI commands.
#
# POST /
# Returns: record<Accelerator: record<AcceleratorArn: string, Name: string, IpAddressType: string, Enabled: bool, IpSets: list<record>, DnsName: string, Status: string, CreatedTime: string, LastModifiedTime: string, DualStackDnsName: string, Events: list<record>>>
# operationId: UpdateAccelerator
export def "update-accelerator" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-41 # required
  accelerator_arn: string # The Amazon Resource Name (ARN) of the accelerator to update.
  --name: string # The name of the accelerator. The name can have a maximum of 64 characters, must contain only alphanumeric characters, periods (.), or hyphens (-), and must not begin or end with a hyphen or period.
  --ip-address-type: string@ip-address-type-completer # The IP address type that an accelerator supports. For a standard accelerator, the value can be IPV4 or DUAL_STACK.
  --enabled: oneof<nothing, bool> # Indicates whether an accelerator is enabled. The value is true or false. The default value is true. If the value is set to true, the accelerator cannot be deleted. If set to false, the accelerator can be deleted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.UpdateAccelerator"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceleratorArn, var: accelerator_arn}, {name: Name, var: name}, {name: IpAddressType, var: ip_address_type}, {name: Enabled, var: enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accelerator_arn: $accelerator_arn, name: $name, ip_address_type: $ip_address_type, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the attributes for an accelerator.
#
# POST /
# Returns: record<AcceleratorAttributes: record<FlowLogsEnabled: bool, FlowLogsS3Bucket: string, FlowLogsS3Prefix: string>>
# operationId: UpdateAcceleratorAttributes
export def "update-accelerator-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-42 # required
  accelerator_arn: string # The Amazon Resource Name (ARN) of the accelerator that you want to update.
  --flow-logs-enabled: oneof<nothing, bool> # Update whether flow logs are enabled. The default value is false. If the value is true, FlowLogsS3Bucket and FlowLogsS3Prefix must be specified. For more information, see Flow Logs (https://docs.aws.amazon.com/global-accelerator/latest/dg/monitoring-global-accelerator.flow-logs.html) in the Global Accelerator Developer Guide.
  --flow-logs-s3-bucket: string # The name of the Amazon S3 bucket for the flow logs. Attribute is required if FlowLogsEnabled is true. The bucket must exist and have a bucket policy that grants Global Accelerator permission to write to the bucket.
  --flow-logs-s3-prefix: string # Update the prefix for the location in the Amazon S3 bucket for the flow logs. Attribute is required if FlowLogsEnabled is true. If you specify slash (/) for the S3 bucket prefix, the log file bucket folder structure will include a double slash (//), like the following: s3-bucket_name//AWSLogs/aws_account_id
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.UpdateAcceleratorAttributes"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceleratorArn, var: accelerator_arn}, {name: FlowLogsEnabled, var: flow_logs_enabled}, {name: FlowLogsS3Bucket, var: flow_logs_s3_bucket}, {name: FlowLogsS3Prefix, var: flow_logs_s3_prefix}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accelerator_arn: $accelerator_arn, flow_logs_enabled: $flow_logs_enabled, flow_logs_s3_bucket: $flow_logs_s3_bucket, flow_logs_s3_prefix: $flow_logs_s3_prefix
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a custom routing accelerator.
#
# POST /
# Returns: record<Accelerator: record<AcceleratorArn: string, Name: string, IpAddressType: string, Enabled: bool, IpSets: list<record>, DnsName: string, Status: string, CreatedTime: string, LastModifiedTime: string>>
# operationId: UpdateCustomRoutingAccelerator
export def "update-custom-routing-accelerator" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-43 # required
  accelerator_arn: string # The Amazon Resource Name (ARN) of the accelerator to update.
  --name: string # The name of the accelerator. The name can have a maximum of 64 characters, must contain only alphanumeric characters, periods (.), or hyphens (-), and must not begin or end with a hyphen or period.
  --ip-address-type: string@ip-address-type-completer # The IP address type that an accelerator supports. For a custom routing accelerator, the value must be IPV4.
  --enabled: oneof<nothing, bool> # Indicates whether an accelerator is enabled. The value is true or false. The default value is true. If the value is set to true, the accelerator cannot be deleted. If set to false, the accelerator can be deleted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.UpdateCustomRoutingAccelerator"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceleratorArn, var: accelerator_arn}, {name: Name, var: name}, {name: IpAddressType, var: ip_address_type}, {name: Enabled, var: enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accelerator_arn: $accelerator_arn, name: $name, ip_address_type: $ip_address_type, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the attributes for a custom routing accelerator.
#
# POST /
# Returns: record<AcceleratorAttributes: record<FlowLogsEnabled: bool, FlowLogsS3Bucket: string, FlowLogsS3Prefix: string>>
# operationId: UpdateCustomRoutingAcceleratorAttributes
export def "update-custom-routing-accelerator-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-44 # required
  accelerator_arn: string # The Amazon Resource Name (ARN) of the custom routing accelerator to update attributes for.
  --flow-logs-enabled: oneof<nothing, bool> # Update whether flow logs are enabled. The default value is false. If the value is true, FlowLogsS3Bucket and FlowLogsS3Prefix must be specified. For more information, see Flow logs (https://docs.aws.amazon.com/global-accelerator/latest/dg/monitoring-global-accelerator.flow-logs.html) in the Global Accelerator Developer Guide.
  --flow-logs-s3-bucket: string # The name of the Amazon S3 bucket for the flow logs. Attribute is required if FlowLogsEnabled is true. The bucket must exist and have a bucket policy that grants Global Accelerator permission to write to the bucket.
  --flow-logs-s3-prefix: string # Update the prefix for the location in the Amazon S3 bucket for the flow logs. Attribute is required if FlowLogsEnabled is true. If you don’t specify a prefix, the flow logs are stored in the root of the bucket. If you specify slash (/) for the S3 bucket prefix, the log file bucket folder structure will include a double slash (//), like the following: DOC-EXAMPLE-BUCKET//AWSLogs/aws_account_id
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.UpdateCustomRoutingAcceleratorAttributes"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceleratorArn, var: accelerator_arn}, {name: FlowLogsEnabled, var: flow_logs_enabled}, {name: FlowLogsS3Bucket, var: flow_logs_s3_bucket}, {name: FlowLogsS3Prefix, var: flow_logs_s3_prefix}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, accelerator_arn: $accelerator_arn, flow_logs_enabled: $flow_logs_enabled, flow_logs_s3_bucket: $flow_logs_s3_bucket, flow_logs_s3_prefix: $flow_logs_s3_prefix
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a listener for a custom routing accelerator.
#
# POST /
# Returns: record<Listener: record<ListenerArn: string, PortRanges: list<record>>>
# operationId: UpdateCustomRoutingListener
export def "update-custom-routing-listener" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-45 # required
  listener_arn: string # The Amazon Resource Name (ARN) of the listener to update.
  port_ranges: list # The updated port range to support for connections from clients to your accelerator. If you remove ports that are currently being used by a subnet endpoint, the call fails. Separately, you set port ranges for endpoints. For more information, see About endpoints for custom routing accelerators (https://docs.aws.amazon.com/global-accelerator/latest/dg/about-custom-routing-endpoints.html). — item shape: {FromPort?: int, ToPort?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.UpdateCustomRoutingListener"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ListenerArn, var: listener_arn}, {name: PortRanges, var: port_ranges}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, listener_arn: $listener_arn, port_ranges: $port_ranges
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an endpoint group. A resource must be valid and active when you add it as an endpoint.
#
# POST /
# Returns: record<EndpointGroup: record<EndpointGroupArn: string, EndpointGroupRegion: string, EndpointDescriptions: list<record>, TrafficDialPercentage: float, HealthCheckPort: int, HealthCheckProtocol: string, HealthCheckPath: string, HealthCheckIntervalSeconds: int, ThresholdCount: int, PortOverrides: list<record>>>
# operationId: UpdateEndpointGroup
export def "update-endpoint-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-46 # required
  endpoint_group_arn: string # The Amazon Resource Name (ARN) of the endpoint group.
  --endpoint-configurations: list # The list of endpoint objects. A resource must be valid and active when you add it as an endpoint. — item shape: {EndpointId?: string, Weight?: int, ClientIPPreservationEnabled?: bool}
  --traffic-dial-percentage: float # The percentage of traffic to send to an Amazon Web Services Region. Additional traffic is distributed to other endpoint groups for this listener. Use this action to increase (dial up) or decrease (dial down) traffic to a specific Region. The percentage is applied to the traffic that would otherwise have been routed to the Region based on optimal routing. The default value is 100. (format: float)
  --health-check-port: int # The port that Global Accelerator uses to check the health of endpoints that are part of this endpoint group. The default port is the listener port that this endpoint group is associated with. If the listener port is a list of ports, Global Accelerator uses the first port in the list.
  --health-check-protocol: string@health-check-protocol-completer # The protocol that Global Accelerator uses to check the health of endpoints that are part of this endpoint group. The default value is TCP.
  --health-check-path: string # If the protocol is HTTP/S, then this specifies the path that is the destination for health check targets. The default value is slash (/).
  --health-check-interval-seconds: int # The time—10 seconds or 30 seconds—between each health check for an endpoint. The default value is 30.
  --threshold-count: int # The number of consecutive health checks required to set the state of a healthy endpoint to unhealthy, or to set an unhealthy endpoint to healthy. The default value is 3.
  --port-overrides: list # Override specific listener ports used to route traffic to endpoints that are part of this endpoint group. For example, you can create a port override in which the listener receives user traffic on ports 80 and 443, but your accelerator routes that traffic to ports 1080 and 1443, respectively, on the endpoints. For more information, see Overriding listener ports (https://docs.aws.amazon.com/global-accelerator/latest/dg/about-endpoint-groups-port-override.html) in the Global Accelerator Developer Guide. — item shape: {ListenerPort?: int, EndpointPort?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.UpdateEndpointGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndpointGroupArn, var: endpoint_group_arn}, {name: EndpointConfigurations, var: endpoint_configurations}, {name: TrafficDialPercentage, var: traffic_dial_percentage}, {name: HealthCheckPort, var: health_check_port}, {name: HealthCheckProtocol, var: health_check_protocol}, {name: HealthCheckPath, var: health_check_path}, {name: HealthCheckIntervalSeconds, var: health_check_interval_seconds}, {name: ThresholdCount, var: threshold_count}, {name: PortOverrides, var: port_overrides}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, endpoint_group_arn: $endpoint_group_arn, endpoint_configurations: $endpoint_configurations, traffic_dial_percentage: $traffic_dial_percentage, health_check_port: $health_check_port, health_check_protocol: $health_check_protocol, health_check_path: $health_check_path, health_check_interval_seconds: $health_check_interval_seconds, threshold_count: $threshold_count, port_overrides: $port_overrides
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a listener.
#
# POST /
# Returns: record<Listener: record<ListenerArn: string, PortRanges: list<record>, Protocol: string, ClientAffinity: string>>
# operationId: UpdateListener
export def "update-listener" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-47 # required
  listener_arn: string # The Amazon Resource Name (ARN) of the listener to update.
  --port-ranges: list # The updated list of port ranges for the connections from clients to the accelerator. — item shape: {FromPort?: int, ToPort?: int}
  --protocol: string@protocol-completer # The updated protocol for the connections from clients to the accelerator.
  --client-affinity: string@client-affinity-completer # Client affinity lets you direct all requests from a user to the same endpoint, if you have stateful applications, regardless of the port and protocol of the client request. Client affinity gives you control over whether to always route each client to the same specific endpoint. Global Accelerator uses a consistent-flow hashing algorithm to choose the optimal endpoint for a connection. If client affinity is NONE, Global Accelerator uses the "five-tuple" (5-tuple) properties—source IP address, source port, destination IP address, destination port, and protocol—to select the hash value, and then chooses the best endpoint. However, with this setting, if someone uses different ports to connect to Global Accelerator, their connections might not be always routed to the same endpoint because the hash value changes. If you want a given client to always be routed to the same endpoint, set client affinity to SOURCE_IP instead. When you use the SOURCE_IP setting, Global Accelerator uses the "two-tuple" (2-tuple) properties— source (client) IP address and destination IP address—to select the hash value. The default value is NONE.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.UpdateListener"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ListenerArn, var: listener_arn}, {name: PortRanges, var: port_ranges}, {name: Protocol, var: protocol}, {name: ClientAffinity, var: client_affinity}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, listener_arn: $listener_arn, port_ranges: $port_ranges, protocol: $protocol, client_affinity: $client_affinity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops advertising an address range that is provisioned as an address pool. You can perform this operation at most once every 10 seconds, even if you specify different address ranges each time. It can take a few minutes before traffic to the specified addresses stops routing to Amazon Web Services because of propagation delays. For more information, see Bring your own IP addresses (BYOIP) (https://docs.aws.amazon.com/global-accelerator/latest/dg/using-byoip.html) in the Global Accelerator Developer Guide.
#
# POST /
# Returns: record<ByoipCidr: record<Cidr: string, State: string, Events: list<record>>>
# operationId: WithdrawByoipCidr
export def "withdraw-byoip-cidr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-48 # required
  cidr: string # The address range, in CIDR notation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "GlobalAccelerator_V20180706.WithdrawByoipCidr"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Cidr, var: cidr}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cidr: $cidr
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
