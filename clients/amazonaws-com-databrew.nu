# Auto-generated client for AWS Glue DataBrew v2017-07-25
# Source: https://api.apis.guru/v2/specs/amazonaws.com/databrew/2017-07-25/openapi.json
# Auth: --token flag or $env.AWS_GLUE_DATABREW_TOKEN

const CLIENT = {
  base_url: "http://databrew.us-east-1.amazonaws.com"
  token_env_var: "AWS_GLUE_DATABREW_TOKEN"
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

def base-url-completer [] { ["http://databrew.us-east-1.amazonaws.com" "http://databrew.us-east-2.amazonaws.com" "http://databrew.us-west-1.amazonaws.com" "http://databrew.us-west-2.amazonaws.com" "http://databrew.us-gov-west-1.amazonaws.com" "http://databrew.us-gov-east-1.amazonaws.com" "http://databrew.ca-central-1.amazonaws.com" "http://databrew.eu-north-1.amazonaws.com" "http://databrew.eu-west-1.amazonaws.com" "http://databrew.eu-west-2.amazonaws.com" "http://databrew.eu-west-3.amazonaws.com" "http://databrew.eu-central-1.amazonaws.com" "http://databrew.eu-south-1.amazonaws.com" "http://databrew.af-south-1.amazonaws.com" "http://databrew.ap-northeast-1.amazonaws.com" "http://databrew.ap-northeast-2.amazonaws.com" "http://databrew.ap-northeast-3.amazonaws.com" "http://databrew.ap-southeast-1.amazonaws.com" "http://databrew.ap-southeast-2.amazonaws.com" "http://databrew.ap-east-1.amazonaws.com" "http://databrew.ap-south-1.amazonaws.com" "http://databrew.sa-east-1.amazonaws.com" "http://databrew.me-south-1.amazonaws.com" "https://databrew.us-east-1.amazonaws.com" "https://databrew.us-east-2.amazonaws.com" "https://databrew.us-west-1.amazonaws.com" "https://databrew.us-west-2.amazonaws.com" "https://databrew.us-gov-west-1.amazonaws.com" "https://databrew.us-gov-east-1.amazonaws.com" "https://databrew.ca-central-1.amazonaws.com" "https://databrew.eu-north-1.amazonaws.com" "https://databrew.eu-west-1.amazonaws.com" "https://databrew.eu-west-2.amazonaws.com" "https://databrew.eu-west-3.amazonaws.com" "https://databrew.eu-central-1.amazonaws.com" "https://databrew.eu-south-1.amazonaws.com" "https://databrew.af-south-1.amazonaws.com" "https://databrew.ap-northeast-1.amazonaws.com" "https://databrew.ap-northeast-2.amazonaws.com" "https://databrew.ap-northeast-3.amazonaws.com" "https://databrew.ap-southeast-1.amazonaws.com" "https://databrew.ap-southeast-2.amazonaws.com" "https://databrew.ap-east-1.amazonaws.com" "https://databrew.ap-south-1.amazonaws.com" "https://databrew.sa-east-1.amazonaws.com" "https://databrew.me-south-1.amazonaws.com" "http://databrew.cn-north-1.amazonaws.com.cn" "http://databrew.cn-northwest-1.amazonaws.com.cn" "https://databrew.cn-north-1.amazonaws.com.cn" "https://databrew.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def format-completer [] { ["CSV" "EXCEL" "JSON" "ORC" "PARQUET"] }
def encryption-mode-completer [] { ["SSE-KMS" "SSE-S3"] }
def log-subscription-completer [] { ["DISABLE" "ENABLE"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    batch-delete-recipe-version: "record<Name: string, Errors: table<ErrorCode: string, ErrorMessage: string, RecipeVersion: string>>"
    create-dataset: "record<Name: string>"
    list-datasets: "record<Datasets: table<AccountId: string, CreatedBy: string, CreateDate: string, Name: string, Format: string, FormatOptions: record, Input: record, LastModifiedDate: string, LastModifiedBy: string, Source: string, PathOptions: record, Tags: record, ResourceArn: string>, NextToken: string>"
    create-profile-job: "record<Name: string>"
    create-project: "record<Name: string>"
    list-projects: "record<Projects: table<AccountId: string, CreateDate: string, CreatedBy: string, DatasetName: string, LastModifiedDate: string, LastModifiedBy: string, Name: string, RecipeName: string, ResourceArn: string, Sample: record, Tags: record, RoleArn: string, OpenedBy: string, OpenDate: string>, NextToken: string>"
    create-recipe: "record<Name: string>"
    list-recipes: "record<Recipes: table<CreatedBy: string, CreateDate: string, LastModifiedBy: string, LastModifiedDate: string, ProjectName: string, PublishedBy: string, PublishedDate: string, Description: string, Name: string, ResourceArn: string, Steps: list, Tags: record, RecipeVersion: string>, NextToken: string>"
    create-recipe-job: "record<Name: string>"
    create-ruleset: "record<Name: string>"
    list-rulesets: "record<Rulesets: table<AccountId: string, CreatedBy: string, CreateDate: string, Description: string, LastModifiedBy: string, LastModifiedDate: string, Name: string, ResourceArn: string, RuleCount: int, Tags: record, TargetArn: string>, NextToken: string>"
    create-schedule: "record<Name: string>"
    list-schedules: "record<Schedules: table<AccountId: string, CreatedBy: string, CreateDate: string, JobNames: list, LastModifiedBy: string, LastModifiedDate: string, ResourceArn: string, CronExpression: string, Tags: record, Name: string>, NextToken: string>"
    delete-dataset: "record<Name: string>"
    describe-dataset: "record<CreatedBy: string, CreateDate: string, Name: string, Format: string, FormatOptions: record<Json: record<MultiLine: bool>, Excel: record<SheetNames: list, SheetIndexes: list, HeaderRow: bool>, Csv: record<Delimiter: string, HeaderRow: bool>>, Input: record<S3InputDefinition: record<Bucket: string, Key: string, BucketOwner: string>, DataCatalogInputDefinition: record<CatalogId: string, DatabaseName: string, TableName: string, TempDirectory: record>, DatabaseInputDefinition: record<GlueConnectionName: string, DatabaseTableName: string, TempDirectory: record, QueryString: string>, Metadata: record<SourceArn: string>>, LastModifiedDate: string, LastModifiedBy: string, Source: string, PathOptions: record<LastModifiedDateCondition: record<Expression: string, ValuesMap: record>, FilesLimit: record<MaxFiles: int, OrderedBy: string, Order: string>, Parameters: record>, Tags: record, ResourceArn: string>"
    update-dataset: "record<Name: string>"
    delete-job: "record<Name: string>"
    describe-job: "record<CreateDate: string, CreatedBy: string, DatasetName: string, EncryptionKeyArn: string, EncryptionMode: string, Name: string, Type: string, LastModifiedBy: string, LastModifiedDate: string, LogSubscription: string, MaxCapacity: int, MaxRetries: int, Outputs: table<CompressionFormat: string, Format: string, PartitionColumns: list, Location: record, Overwrite: bool, FormatOptions: record, MaxOutputFiles: int>, DataCatalogOutputs: table<CatalogId: string, DatabaseName: string, TableName: string, S3Options: record, DatabaseOptions: record, Overwrite: bool>, DatabaseOutputs: table<GlueConnectionName: string, DatabaseOptions: record, DatabaseOutputMode: string>, ProjectName: string, ProfileConfiguration: record<DatasetStatisticsConfiguration: record<IncludedStatistics: list, Overrides: list>, ProfileColumns: list<record>, ColumnStatisticsConfigurations: list<record>, EntityDetectorConfiguration: record<EntityTypes: list, AllowedStatistics: list>>, ValidationConfigurations: table<RulesetArn: string, ValidationMode: string>, RecipeReference: record<Name: string, RecipeVersion: string>, ResourceArn: string, RoleArn: string, Tags: record, Timeout: int, JobSample: record<Mode: string, Size: int>>"
    delete-project: "record<Name: string>"
    describe-project: "record<CreateDate: string, CreatedBy: string, DatasetName: string, LastModifiedDate: string, LastModifiedBy: string, Name: string, RecipeName: string, ResourceArn: string, Sample: record<Size: int, Type: string>, RoleArn: string, Tags: record, SessionStatus: string, OpenedBy: string, OpenDate: string>"
    update-project: "record<LastModifiedDate: string, Name: string>"
    delete-recipe-version: "record<Name: string, RecipeVersion: string>"
    delete-ruleset: "record<Name: string>"
    describe-ruleset: "record<Name: string, Description: string, TargetArn: string, Rules: table<Name: string, Disabled: bool, CheckExpression: string, SubstitutionMap: record, Threshold: record, ColumnSelectors: list>, CreateDate: string, CreatedBy: string, LastModifiedBy: string, LastModifiedDate: string, ResourceArn: string, Tags: record>"
    update-ruleset: "record<Name: string>"
    delete-schedule: "record<Name: string>"
    describe-schedule: "record<CreateDate: string, CreatedBy: string, JobNames: list<string>, LastModifiedBy: string, LastModifiedDate: string, ResourceArn: string, CronExpression: string, Tags: record, Name: string>"
    update-schedule: "record<Name: string>"
    describe-job-run: "record<Attempt: int, CompletedOn: string, DatasetName: string, ErrorMessage: string, ExecutionTime: int, JobName: string, ProfileConfiguration: record<DatasetStatisticsConfiguration: record<IncludedStatistics: list, Overrides: list>, ProfileColumns: list<record>, ColumnStatisticsConfigurations: list<record>, EntityDetectorConfiguration: record<EntityTypes: list, AllowedStatistics: list>>, ValidationConfigurations: table<RulesetArn: string, ValidationMode: string>, RunId: string, State: string, LogSubscription: string, LogGroupName: string, Outputs: table<CompressionFormat: string, Format: string, PartitionColumns: list, Location: record, Overwrite: bool, FormatOptions: record, MaxOutputFiles: int>, DataCatalogOutputs: table<CatalogId: string, DatabaseName: string, TableName: string, S3Options: record, DatabaseOptions: record, Overwrite: bool>, DatabaseOutputs: table<GlueConnectionName: string, DatabaseOptions: record, DatabaseOutputMode: string>, RecipeReference: record<Name: string, RecipeVersion: string>, StartedBy: string, StartedOn: string, JobSample: record<Mode: string, Size: int>>"
    describe-recipe: "record<CreatedBy: string, CreateDate: string, LastModifiedBy: string, LastModifiedDate: string, ProjectName: string, PublishedBy: string, PublishedDate: string, Description: string, Name: string, Steps: table<Action: record, ConditionExpressions: list>, Tags: record, ResourceArn: string, RecipeVersion: string>"
    update-recipe: "record<Name: string>"
    list-job-runs: "record<JobRuns: table<Attempt: int, CompletedOn: string, DatasetName: string, ErrorMessage: string, ExecutionTime: int, JobName: string, RunId: string, State: string, LogSubscription: string, LogGroupName: string, Outputs: list, DataCatalogOutputs: list, DatabaseOutputs: list, RecipeReference: record, StartedBy: string, StartedOn: string, JobSample: record, ValidationConfigurations: list>, NextToken: string>"
    list-jobs: "record<Jobs: table<AccountId: string, CreatedBy: string, CreateDate: string, DatasetName: string, EncryptionKeyArn: string, EncryptionMode: string, Name: string, Type: string, LastModifiedBy: string, LastModifiedDate: string, LogSubscription: string, MaxCapacity: int, MaxRetries: int, Outputs: list, DataCatalogOutputs: list, DatabaseOutputs: list, ProjectName: string, RecipeReference: record, ResourceArn: string, RoleArn: string, Timeout: int, Tags: record, JobSample: record, ValidationConfigurations: list>, NextToken: string>"
    list-recipe-versions: "record<NextToken: string, Recipes: table<CreatedBy: string, CreateDate: string, LastModifiedBy: string, LastModifiedDate: string, ProjectName: string, PublishedBy: string, PublishedDate: string, Description: string, Name: string, ResourceArn: string, Steps: list, Tags: record, RecipeVersion: string>>"
    list-tags-for-resource: "record<Tags: record>"
    tag-resource: "record"
    publish-recipe: "record<Name: string>"
    send-project-session-action: "record<Result: string, Name: string, ActionId: int>"
    start-job-run: "record<RunId: string>"
    start-project-session: "record<Name: string, ClientSessionId: string>"
    stop-job-run: "record<RunId: string>"
    untag-resource: "record"
    update-profile-job: "record<Name: string>"
    update-recipe-job: "record<Name: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["batch-delete-recipe-version" "create-dataset" "list-datasets" "create-profile-job" "create-project" "list-projects" "create-recipe" "list-recipes" "create-recipe-job" "create-ruleset" "list-rulesets" "create-schedule" "list-schedules" "delete-dataset" "describe-dataset" "update-dataset" "delete-job" "describe-job" "delete-project" "describe-project" "update-project" "delete-recipe-version" "delete-ruleset" "describe-ruleset" "update-ruleset" "delete-schedule" "describe-schedule" "update-schedule" "describe-job-run" "describe-recipe" "update-recipe" "list-job-runs" "list-jobs" "list-recipe-versions" "list-tags-for-resource" "tag-resource" "publish-recipe" "send-project-session-action" "start-job-run" "start-project-session" "stop-job-run" "untag-resource" "update-profile-job" "update-recipe-job" "commands"] | sort) } | get name | first)
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

# Deletes one or more versions of a recipe at a time. The entire request will be rejected if: The recipe does not exist. There is an invalid version identifier in the list of versions. The version list is empty. The version list size exceeds 50. The version list contains duplicate entries. The request will complete successfully, but with partial failures, if: A version does not exist. A version is being used by a job. You specify LATEST_WORKING, but it's being used by a project. The version fails to be deleted. The LATEST_WORKING version will only be deleted if the recipe has no other versions. If you try to delete LATEST_WORKING while other versions exist (or if they can't be deleted), then LATEST_WORKING will be listed as partial failure in the response.
#
# POST /recipes/{name}/batchDeleteRecipeVersion
# Returns: record<Name: string, Errors: table<ErrorCode: string, ErrorMessage: string, RecipeVersion: string>>
# operationId: BatchDeleteRecipeVersion
export def "batch-delete-recipe-version" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  recipe_versions: list<string> # An array of version identifiers, for the recipe versions to be deleted. You can specify numeric versions (X.Y) or LATEST_WORKING. LATEST_PUBLISHED is not supported.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/recipes/{name}/batchDeleteRecipeVersion"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: RecipeVersions, var: recipe_versions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, recipe_versions: $recipe_versions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new DataBrew dataset.
#
# POST /datasets
# Returns: record<Name: string>
# operationId: CreateDataset
export def "create-dataset" [
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
  name: string # The name of the dataset to be created. Valid characters are alphanumeric (A-Z, a-z, 0-9), hyphen (-), period (.), and space.
  --format: string@format-completer # The file format of a dataset that is created from an Amazon S3 file or folder.
  --format-options: record # Represents a set of options that define the structure of either comma-separated value (CSV), Excel, or JSON input. — shape: {Json?: record, Excel?: record, Csv?: record}
  input: record # Represents information on how DataBrew can find data, in either the Glue Data Catalog or Amazon S3. — shape: {S3InputDefinition?: record, DataCatalogInputDefinition?: record, DatabaseInputDefinition?: record, Metadata?: record}
  --path-options: record # Represents a set of options that define how DataBrew selects files for a given Amazon S3 path in a dataset. — shape: {LastModifiedDateCondition?: record, FilesLimit?: record, Parameters?: record}
  --tags: record # Metadata tags to apply to this dataset.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/datasets"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Format, var: format}, {name: FormatOptions, var: format_options}, {name: Input, var: input}, {name: PathOptions, var: path_options}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, format: $format, format_options: $format_options, input: $input, path_options: $path_options, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the DataBrew datasets.
#
# GET /datasets
# Returns: record<Datasets: table<AccountId: string, CreatedBy: string, CreateDate: string, Name: string, Format: string, FormatOptions: record, Input: record, LastModifiedDate: string, LastModifiedBy: string, Source: string, PathOptions: record, Tags: record, ResourceArn: string>, NextToken: string>
# operationId: ListDatasets
export def "list-datasets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return in this request.
  --next-token: string # The token returned by a previous call to retrieve the next set of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/datasets"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new job to analyze a dataset and create its data profile.
#
# POST /profileJobs
# Returns: record<Name: string>
# operationId: CreateProfileJob
export def "create-profile-job" [
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
  dataset_name: string # The name of the dataset that this job is to act upon.
  --encryption-key-arn: string # The Amazon Resource Name (ARN) of an encryption key that is used to protect the job.
  --encryption-mode: string@encryption-mode-completer # The encryption mode for the job, which can be one of the following: SSE-KMS - SSE-KMS - Server-side encryption with KMS-managed keys. SSE-S3 - Server-side encryption with keys managed by Amazon S3.
  name: string # The name of the job to be created. Valid characters are alphanumeric (A-Z, a-z, 0-9), hyphen (-), period (.), and space.
  --log-subscription: string@log-subscription-completer # Enables or disables Amazon CloudWatch logging for the job. If logging is enabled, CloudWatch writes one log stream for each job run.
  --max-capacity: int # The maximum number of nodes that DataBrew can use when the job processes data.
  --max-retries: int # The maximum number of times to retry the job after a job run fails.
  output_location: record # Represents an Amazon S3 location (bucket name, bucket owner, and object key) where DataBrew can read input data, or write output from a job. — shape: {Bucket?: string, Key?: string, BucketOwner?: string}
  --configuration: record # Configuration for profile jobs. Configuration can be used to select columns, do evaluations, and override default parameters of evaluations. When configuration is undefined, the profile job will apply default settings to all supported columns. — shape: {DatasetStatisticsConfiguration?: record, ProfileColumns?: list, ColumnStatisticsConfigurations?: list, EntityDetectorConfiguration?: record}
  --validation-configurations: list # List of validation configurations that are applied to the profile job. — item shape: {RulesetArn: string, ValidationMode?: "CHECK_ALL"}
  role_arn: string # The Amazon Resource Name (ARN) of the Identity and Access Management (IAM) role to be assumed when DataBrew runs the job.
  --tags: record # Metadata tags to apply to this job.
  --timeout: int # The job's timeout in minutes. A job that attempts to run longer than this timeout period ends with a status of TIMEOUT.
  --job-sample: record # A sample configuration for profile jobs only, which determines the number of rows on which the profile job is run. If a JobSample value isn't provided, the default is used. The default value is CUSTOM_ROWS for the mode parameter and 20,000 for the size parameter. — shape: {Mode?: "FULL_DATASET"|"CUSTOM_ROWS", Size?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/profileJobs"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: DatasetName, var: dataset_name}, {name: EncryptionKeyArn, var: encryption_key_arn}, {name: EncryptionMode, var: encryption_mode}, {name: Name, var: name}, {name: LogSubscription, var: log_subscription}, {name: MaxCapacity, var: max_capacity}, {name: MaxRetries, var: max_retries}, {name: OutputLocation, var: output_location}, {name: Configuration, var: configuration}, {name: ValidationConfigurations, var: validation_configurations}, {name: RoleArn, var: role_arn}, {name: Tags, var: tags}, {name: Timeout, var: timeout}, {name: JobSample, var: job_sample}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, dataset_name: $dataset_name, encryption_key_arn: $encryption_key_arn, encryption_mode: $encryption_mode, name: $name, log_subscription: $log_subscription, max_capacity: $max_capacity, max_retries: $max_retries, output_location: $output_location, configuration: $configuration, validation_configurations: $validation_configurations, role_arn: $role_arn, tags: $tags, timeout: $timeout, job_sample: $job_sample
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new DataBrew project.
#
# POST /projects
# Returns: record<Name: string>
# operationId: CreateProject
export def "create-project" [
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
  dataset_name: string # The name of an existing dataset to associate this project with.
  name: string # A unique name for the new project. Valid characters are alphanumeric (A-Z, a-z, 0-9), hyphen (-), period (.), and space.
  recipe_name: string # The name of an existing recipe to associate with the project.
  --sample: record # Represents the sample size and sampling type for DataBrew to use for interactive data analysis. — shape: {Size?: int, Type?: "FIRST_N"|"LAST_N"|"RANDOM"}
  role_arn: string # The Amazon Resource Name (ARN) of the Identity and Access Management (IAM) role to be assumed for this request.
  --tags: record # Metadata tags to apply to this project.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: DatasetName, var: dataset_name}, {name: Name, var: name}, {name: RecipeName, var: recipe_name}, {name: Sample, var: sample}, {name: RoleArn, var: role_arn}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, dataset_name: $dataset_name, name: $name, recipe_name: $recipe_name, sample: $sample, role_arn: $role_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the DataBrew projects that are defined.
#
# GET /projects
# Returns: record<Projects: table<AccountId: string, CreateDate: string, CreatedBy: string, DatasetName: string, LastModifiedDate: string, LastModifiedBy: string, Name: string, RecipeName: string, ResourceArn: string, Sample: record, Tags: record, RoleArn: string, OpenedBy: string, OpenDate: string>, NextToken: string>
# operationId: ListProjects
export def "list-projects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token returned by a previous call to retrieve the next set of results.
  --max-results: int # The maximum number of results to return in this request.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects"
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new DataBrew recipe.
#
# POST /recipes
# Returns: record<Name: string>
# operationId: CreateRecipe
export def "create-recipe" [
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
  --description: string # A description for the recipe.
  name: string # A unique name for the recipe. Valid characters are alphanumeric (A-Z, a-z, 0-9), hyphen (-), period (.), and space.
  steps: list # An array containing the steps to be performed by the recipe. Each recipe step consists of one recipe action and (optionally) an array of condition expressions. — item shape: {Action: record, ConditionExpressions?: list}
  --tags: record # Metadata tags to apply to this recipe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/recipes"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: Name, var: name}, {name: Steps, var: steps}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, name: $name, steps: $steps, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the DataBrew recipes that are defined.
#
# GET /recipes
# Returns: record<Recipes: table<CreatedBy: string, CreateDate: string, LastModifiedBy: string, LastModifiedDate: string, ProjectName: string, PublishedBy: string, PublishedDate: string, Description: string, Name: string, ResourceArn: string, Steps: list, Tags: record, RecipeVersion: string>, NextToken: string>
# operationId: ListRecipes
export def "list-recipes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return in this request.
  --next-token: string # The token returned by a previous call to retrieve the next set of results.
  --recipe-version: string # Return only those recipes with a version identifier of LATEST_WORKING or LATEST_PUBLISHED. If RecipeVersion is omitted, ListRecipes returns all of the LATEST_PUBLISHED recipe versions. Valid values: LATEST_WORKING | LATEST_PUBLISHED
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipes"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: recipeVersion, var: recipe_version}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, recipe_version: $recipe_version, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new job to transform input data, using steps defined in an existing Glue DataBrew recipe
#
# POST /recipeJobs
# Returns: record<Name: string>
# operationId: CreateRecipeJob
export def "create-recipe-job" [
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
  --dataset-name: string # The name of the dataset that this job processes.
  --encryption-key-arn: string # The Amazon Resource Name (ARN) of an encryption key that is used to protect the job.
  --encryption-mode: string@encryption-mode-completer # The encryption mode for the job, which can be one of the following: SSE-KMS - Server-side encryption with keys managed by KMS. SSE-S3 - Server-side encryption with keys managed by Amazon S3.
  name: string # A unique name for the job. Valid characters are alphanumeric (A-Z, a-z, 0-9), hyphen (-), period (.), and space.
  --log-subscription: string@log-subscription-completer # Enables or disables Amazon CloudWatch logging for the job. If logging is enabled, CloudWatch writes one log stream for each job run.
  --max-capacity: int # The maximum number of nodes that DataBrew can consume when the job processes data.
  --max-retries: int # The maximum number of times to retry the job after a job run fails.
  --outputs: list # One or more artifacts that represent the output from running the job. — item shape: {CompressionFormat?: "GZIP"|"LZ4"|"SNAPPY"|"BZIP2"|"DEFLATE"|"LZO"|"BROTLI"|"ZSTD"|"ZLIB", Format?: "CSV"|"JSON"|"PARQUET"|"GLUEPARQUET"|"AVRO"|"ORC"|"XML"|"TABLEAUHYPER", PartitionColumns?: list<string>, Location: record, Overwrite?: bool, FormatOptions?: record, MaxOutputFiles?: int}
  --data-catalog-outputs: list # One or more artifacts that represent the Glue Data Catalog output from running the job. — item shape: {CatalogId?: string, DatabaseName: string, TableName: string, S3Options?: record, DatabaseOptions?: record, Overwrite?: bool}
  --database-outputs: list # Represents a list of JDBC database output objects which defines the output destination for a DataBrew recipe job to write to. — item shape: {GlueConnectionName: string, DatabaseOptions: record, DatabaseOutputMode?: "NEW_TABLE"}
  --project-name: string # Either the name of an existing project, or a combination of a recipe and a dataset to associate with the recipe.
  --recipe-reference: record # Represents the name and version of a DataBrew recipe. — shape: {Name?: string, RecipeVersion?: string}
  role_arn: string # The Amazon Resource Name (ARN) of the Identity and Access Management (IAM) role to be assumed when DataBrew runs the job.
  --tags: record # Metadata tags to apply to this job.
  --timeout: int # The job's timeout in minutes. A job that attempts to run longer than this timeout period ends with a status of TIMEOUT.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/recipeJobs"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: DatasetName, var: dataset_name}, {name: EncryptionKeyArn, var: encryption_key_arn}, {name: EncryptionMode, var: encryption_mode}, {name: Name, var: name}, {name: LogSubscription, var: log_subscription}, {name: MaxCapacity, var: max_capacity}, {name: MaxRetries, var: max_retries}, {name: Outputs, var: outputs}, {name: DataCatalogOutputs, var: data_catalog_outputs}, {name: DatabaseOutputs, var: database_outputs}, {name: ProjectName, var: project_name}, {name: RecipeReference, var: recipe_reference}, {name: RoleArn, var: role_arn}, {name: Tags, var: tags}, {name: Timeout, var: timeout}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, dataset_name: $dataset_name, encryption_key_arn: $encryption_key_arn, encryption_mode: $encryption_mode, name: $name, log_subscription: $log_subscription, max_capacity: $max_capacity, max_retries: $max_retries, outputs: $outputs, data_catalog_outputs: $data_catalog_outputs, database_outputs: $database_outputs, project_name: $project_name, recipe_reference: $recipe_reference, role_arn: $role_arn, tags: $tags, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new ruleset that can be used in a profile job to validate the data quality of a dataset.
#
# POST /rulesets
# Returns: record<Name: string>
# operationId: CreateRuleset
export def "create-ruleset" [
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
  name: string # The name of the ruleset to be created. Valid characters are alphanumeric (A-Z, a-z, 0-9), hyphen (-), period (.), and space.
  --description: string # The description of the ruleset.
  target_arn: string # The Amazon Resource Name (ARN) of a resource (dataset) that the ruleset is associated with.
  rules: list # A list of rules that are defined with the ruleset. A rule includes one or more checks to be validated on a DataBrew dataset. — item shape: {Name: string, Disabled?: bool, CheckExpression: string, SubstitutionMap?: record, Threshold?: record, ColumnSelectors?: list}
  --tags: record # Metadata tags to apply to the ruleset.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rulesets"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: TargetArn, var: target_arn}, {name: Rules, var: rules}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, target_arn: $target_arn, rules: $rules, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all rulesets available in the current account or rulesets associated with a specific resource (dataset).
#
# GET /rulesets
# Returns: record<Rulesets: table<AccountId: string, CreatedBy: string, CreateDate: string, Description: string, LastModifiedBy: string, LastModifiedDate: string, Name: string, ResourceArn: string, RuleCount: int, Tags: record, TargetArn: string>, NextToken: string>
# operationId: ListRulesets
export def "list-rulesets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --target-arn: string # The Amazon Resource Name (ARN) of a resource (dataset). Using this parameter indicates to return only those rulesets that are associated with the specified resource.
  --max-results: int # The maximum number of results to return in this request.
  --next-token: string # A token generated by DataBrew that specifies where to continue pagination if a previous request was truncated. To get the next set of pages, pass in the NextToken value from the response object of the previous page call.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rulesets"
    query: [{name: targetArn, var: target_arn}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_arn: $target_arn, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new schedule for one or more DataBrew jobs. Jobs can be run at a specific date and time, or at regular intervals.
#
# POST /schedules
# Returns: record<Name: string>
# operationId: CreateSchedule
export def "create-schedule" [
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
  --job-names: list<string> # The name or names of one or more jobs to be run.
  cron_expression: string # The date or dates and time or times when the jobs are to be run. For more information, see Cron expressions (https://docs.aws.amazon.com/databrew/latest/dg/jobs.cron.html) in the Glue DataBrew Developer Guide.
  --tags: record # Metadata tags to apply to this schedule.
  name: string # A unique name for the schedule. Valid characters are alphanumeric (A-Z, a-z, 0-9), hyphen (-), period (.), and space.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/schedules"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobNames, var: job_names}, {name: CronExpression, var: cron_expression}, {name: Tags, var: tags}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, job_names: $job_names, cron_expression: $cron_expression, tags: $tags, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the DataBrew schedules that are defined.
#
# GET /schedules
# Returns: record<Schedules: table<AccountId: string, CreatedBy: string, CreateDate: string, JobNames: list, LastModifiedBy: string, LastModifiedDate: string, ResourceArn: string, CronExpression: string, Tags: record, Name: string>, NextToken: string>
# operationId: ListSchedules
export def "list-schedules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --job-name: string # The name of the job that these schedules apply to.
  --max-results: int # The maximum number of results to return in this request.
  --next-token: string # The token returned by a previous call to retrieve the next set of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/schedules"
    query: [{name: jobName, var: job_name}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_name: $job_name, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a dataset from DataBrew.
#
# DELETE /datasets/{name}
# Returns: record<Name: string>
# operationId: DeleteDataset
export def "delete-dataset" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/datasets/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the definition of a specific DataBrew dataset.
#
# GET /datasets/{name}
# Returns: record<CreatedBy: string, CreateDate: string, Name: string, Format: string, FormatOptions: record<Json: record<MultiLine: bool>, Excel: record<SheetNames: list, SheetIndexes: list, HeaderRow: bool>, Csv: record<Delimiter: string, HeaderRow: bool>>, Input: record<S3InputDefinition: record<Bucket: string, Key: string, BucketOwner: string>, DataCatalogInputDefinition: record<CatalogId: string, DatabaseName: string, TableName: string, TempDirectory: record>, DatabaseInputDefinition: record<GlueConnectionName: string, DatabaseTableName: string, TempDirectory: record, QueryString: string>, Metadata: record<SourceArn: string>>, LastModifiedDate: string, LastModifiedBy: string, Source: string, PathOptions: record<LastModifiedDateCondition: record<Expression: string, ValuesMap: record>, FilesLimit: record<MaxFiles: int, OrderedBy: string, Order: string>, Parameters: record>, Tags: record, ResourceArn: string>
# operationId: DescribeDataset
export def "describe-dataset" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/datasets/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies the definition of an existing DataBrew dataset.
#
# PUT /datasets/{name}
# Returns: record<Name: string>
# operationId: UpdateDataset
export def "update-dataset" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --format: string@format-completer # The file format of a dataset that is created from an Amazon S3 file or folder.
  --format-options: record # Represents a set of options that define the structure of either comma-separated value (CSV), Excel, or JSON input. — shape: {Json?: record, Excel?: record, Csv?: record}
  input: record # Represents information on how DataBrew can find data, in either the Glue Data Catalog or Amazon S3. — shape: {S3InputDefinition?: record, DataCatalogInputDefinition?: record, DatabaseInputDefinition?: record, Metadata?: record}
  --path-options: record # Represents a set of options that define how DataBrew selects files for a given Amazon S3 path in a dataset. — shape: {LastModifiedDateCondition?: record, FilesLimit?: record, Parameters?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/datasets/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Format, var: format}, {name: FormatOptions, var: format_options}, {name: Input, var: input}, {name: PathOptions, var: path_options}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, format: $format, format_options: $format_options, input: $input, path_options: $path_options
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified DataBrew job.
#
# DELETE /jobs/{name}
# Returns: record<Name: string>
# operationId: DeleteJob
export def "delete-job" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/jobs/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the definition of a specific DataBrew job.
#
# GET /jobs/{name}
# Returns: record<CreateDate: string, CreatedBy: string, DatasetName: string, EncryptionKeyArn: string, EncryptionMode: string, Name: string, Type: string, LastModifiedBy: string, LastModifiedDate: string, LogSubscription: string, MaxCapacity: int, MaxRetries: int, Outputs: table<CompressionFormat: string, Format: string, PartitionColumns: list, Location: record, Overwrite: bool, FormatOptions: record, MaxOutputFiles: int>, DataCatalogOutputs: table<CatalogId: string, DatabaseName: string, TableName: string, S3Options: record, DatabaseOptions: record, Overwrite: bool>, DatabaseOutputs: table<GlueConnectionName: string, DatabaseOptions: record, DatabaseOutputMode: string>, ProjectName: string, ProfileConfiguration: record<DatasetStatisticsConfiguration: record<IncludedStatistics: list, Overrides: list>, ProfileColumns: list<record>, ColumnStatisticsConfigurations: list<record>, EntityDetectorConfiguration: record<EntityTypes: list, AllowedStatistics: list>>, ValidationConfigurations: table<RulesetArn: string, ValidationMode: string>, RecipeReference: record<Name: string, RecipeVersion: string>, ResourceArn: string, RoleArn: string, Tags: record, Timeout: int, JobSample: record<Mode: string, Size: int>>
# operationId: DescribeJob
export def "describe-job" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/jobs/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing DataBrew project.
#
# DELETE /projects/{name}
# Returns: record<Name: string>
# operationId: DeleteProject
export def "delete-project" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/projects/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the definition of a specific DataBrew project.
#
# GET /projects/{name}
# Returns: record<CreateDate: string, CreatedBy: string, DatasetName: string, LastModifiedDate: string, LastModifiedBy: string, Name: string, RecipeName: string, ResourceArn: string, Sample: record<Size: int, Type: string>, RoleArn: string, Tags: record, SessionStatus: string, OpenedBy: string, OpenDate: string>
# operationId: DescribeProject
export def "describe-project" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies the definition of an existing DataBrew project.
#
# PUT /projects/{name}
# Returns: record<LastModifiedDate: string, Name: string>
# operationId: UpdateProject
export def "update-project" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --sample: record # Represents the sample size and sampling type for DataBrew to use for interactive data analysis. — shape: {Size?: int, Type?: "FIRST_N"|"LAST_N"|"RANDOM"}
  role_arn: string # The Amazon Resource Name (ARN) of the IAM role to be assumed for this request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/projects/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Sample, var: sample}, {name: RoleArn, var: role_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, sample: $sample, role_arn: $role_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a single version of a DataBrew recipe.
#
# DELETE /recipes/{name}/recipeVersion/{recipeVersion}
# Returns: record<Name: string, RecipeVersion: string>
# operationId: DeleteRecipeVersion
export def "delete-recipe-version" [
  name: string
  recipe_version: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/recipes/{name}/recipeVersion/{recipeVersion}"
    path_params: [{name: name, var: name}, {name: recipeVersion, var: recipe_version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, recipe_version: $recipe_version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a ruleset.
#
# DELETE /rulesets/{name}
# Returns: record<Name: string>
# operationId: DeleteRuleset
export def "delete-ruleset" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/rulesets/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves detailed information about the ruleset.
#
# GET /rulesets/{name}
# Returns: record<Name: string, Description: string, TargetArn: string, Rules: table<Name: string, Disabled: bool, CheckExpression: string, SubstitutionMap: record, Threshold: record, ColumnSelectors: list>, CreateDate: string, CreatedBy: string, LastModifiedBy: string, LastModifiedDate: string, ResourceArn: string, Tags: record>
# operationId: DescribeRuleset
export def "describe-ruleset" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rulesets/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates specified ruleset.
#
# PUT /rulesets/{name}
# Returns: record<Name: string>
# operationId: UpdateRuleset
export def "update-ruleset" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # The description of the ruleset.
  rules: list # A list of rules that are defined with the ruleset. A rule includes one or more checks to be validated on a DataBrew dataset. — item shape: {Name: string, Disabled?: bool, CheckExpression: string, SubstitutionMap?: record, Threshold?: record, ColumnSelectors?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/rulesets/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: Rules, var: rules}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, rules: $rules
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified DataBrew schedule.
#
# DELETE /schedules/{name}
# Returns: record<Name: string>
# operationId: DeleteSchedule
export def "delete-schedule" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/schedules/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the definition of a specific DataBrew schedule.
#
# GET /schedules/{name}
# Returns: record<CreateDate: string, CreatedBy: string, JobNames: list<string>, LastModifiedBy: string, LastModifiedDate: string, ResourceArn: string, CronExpression: string, Tags: record, Name: string>
# operationId: DescribeSchedule
export def "describe-schedule" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/schedules/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies the definition of an existing DataBrew schedule.
#
# PUT /schedules/{name}
# Returns: record<Name: string>
# operationId: UpdateSchedule
export def "update-schedule" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --job-names: list<string> # The name or names of one or more jobs to be run for this schedule.
  cron_expression: string # The date or dates and time or times when the jobs are to be run. For more information, see Cron expressions (https://docs.aws.amazon.com/databrew/latest/dg/jobs.cron.html) in the Glue DataBrew Developer Guide.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/schedules/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobNames, var: job_names}, {name: CronExpression, var: cron_expression}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, job_names: $job_names, cron_expression: $cron_expression
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Represents one run of a DataBrew job.
#
# GET /jobs/{name}/jobRun/{runId}
# Returns: record<Attempt: int, CompletedOn: string, DatasetName: string, ErrorMessage: string, ExecutionTime: int, JobName: string, ProfileConfiguration: record<DatasetStatisticsConfiguration: record<IncludedStatistics: list, Overrides: list>, ProfileColumns: list<record>, ColumnStatisticsConfigurations: list<record>, EntityDetectorConfiguration: record<EntityTypes: list, AllowedStatistics: list>>, ValidationConfigurations: table<RulesetArn: string, ValidationMode: string>, RunId: string, State: string, LogSubscription: string, LogGroupName: string, Outputs: table<CompressionFormat: string, Format: string, PartitionColumns: list, Location: record, Overwrite: bool, FormatOptions: record, MaxOutputFiles: int>, DataCatalogOutputs: table<CatalogId: string, DatabaseName: string, TableName: string, S3Options: record, DatabaseOptions: record, Overwrite: bool>, DatabaseOutputs: table<GlueConnectionName: string, DatabaseOptions: record, DatabaseOutputMode: string>, RecipeReference: record<Name: string, RecipeVersion: string>, StartedBy: string, StartedOn: string, JobSample: record<Mode: string, Size: int>>
# operationId: DescribeJobRun
export def "describe-job-run" [
  name: string
  run_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/jobs/{name}/jobRun/{runId}"
    path_params: [{name: name, var: name}, {name: runId, var: run_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, run_id: $run_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the definition of a specific DataBrew recipe corresponding to a particular version.
#
# GET /recipes/{name}
# Returns: record<CreatedBy: string, CreateDate: string, LastModifiedBy: string, LastModifiedDate: string, ProjectName: string, PublishedBy: string, PublishedDate: string, Description: string, Name: string, Steps: table<Action: record, ConditionExpressions: list>, Tags: record, ResourceArn: string, RecipeVersion: string>
# operationId: DescribeRecipe
export def "describe-recipe" [
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
  --recipe-version: string # The recipe version identifier. If this parameter isn't specified, then the latest published version is returned.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipes/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: recipeVersion, var: recipe_version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, recipe_version: $recipe_version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies the definition of the LATEST_WORKING version of a DataBrew recipe.
#
# PUT /recipes/{name}
# Returns: record<Name: string>
# operationId: UpdateRecipe
export def "update-recipe" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # A description of the recipe.
  --steps: list # One or more steps to be performed by the recipe. Each step consists of an action, and the conditions under which the action should succeed. — item shape: {Action: record, ConditionExpressions?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/recipes/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: Steps, var: steps}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, steps: $steps
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the previous runs of a particular DataBrew job.
#
# GET /jobs/{name}/jobRuns
# Returns: record<JobRuns: table<Attempt: int, CompletedOn: string, DatasetName: string, ErrorMessage: string, ExecutionTime: int, JobName: string, RunId: string, State: string, LogSubscription: string, LogGroupName: string, Outputs: list, DataCatalogOutputs: list, DatabaseOutputs: list, RecipeReference: record, StartedBy: string, StartedOn: string, JobSample: record, ValidationConfigurations: list>, NextToken: string>
# operationId: ListJobRuns
export def "list-job-runs" [
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
  --max-results: int # The maximum number of results to return in this request.
  --next-token: string # The token returned by a previous call to retrieve the next set of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/jobs/{name}/jobRuns"
    path_params: [{name: name, var: name}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the DataBrew jobs that are defined.
#
# GET /jobs
# Returns: record<Jobs: table<AccountId: string, CreatedBy: string, CreateDate: string, DatasetName: string, EncryptionKeyArn: string, EncryptionMode: string, Name: string, Type: string, LastModifiedBy: string, LastModifiedDate: string, LogSubscription: string, MaxCapacity: int, MaxRetries: int, Outputs: list, DataCatalogOutputs: list, DatabaseOutputs: list, ProjectName: string, RecipeReference: record, ResourceArn: string, RoleArn: string, Timeout: int, Tags: record, JobSample: record, ValidationConfigurations: list>, NextToken: string>
# operationId: ListJobs
export def "list-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dataset-name: string # The name of a dataset. Using this parameter indicates to return only those jobs that act on the specified dataset.
  --max-results: int # The maximum number of results to return in this request.
  --next-token: string # A token generated by DataBrew that specifies where to continue pagination if a previous request was truncated. To get the next set of pages, pass in the NextToken value from the response object of the previous page call.
  --project-name: string # The name of a project. Using this parameter indicates to return only those jobs that are associated with the specified project.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/jobs"
    query: [{name: datasetName, var: dataset_name}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: projectName, var: project_name}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dataset_name: $dataset_name, max_results: $max_results, next_token: $next_token, project_name: $project_name, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the versions of a particular DataBrew recipe, except for LATEST_WORKING.
#
# GET /recipeVersions
# Returns: record<NextToken: string, Recipes: table<CreatedBy: string, CreateDate: string, LastModifiedBy: string, LastModifiedDate: string, ProjectName: string, PublishedBy: string, PublishedDate: string, Description: string, Name: string, ResourceArn: string, Steps: list, Tags: record, RecipeVersion: string>>
# operationId: ListRecipeVersions
export def "list-recipe-versions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return in this request.
  --next-token: string # The token returned by a previous call to retrieve the next set of results.
  --name: string # The name of the recipe for which to return version information. (required)
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipeVersions"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: name, var: name, required: true}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, name: $name, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the tags for a DataBrew resource.
#
# GET /tags/{ResourceArn}
# Returns: record<Tags: record>
# operationId: ListTagsForResource
export def "list-tags-for-resource" [
  resource_arn: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tags/{ResourceArn}"
    path_params: [{name: ResourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds metadata tags to a DataBrew resource, such as a dataset, project, recipe, job, or schedule.
#
# POST /tags/{ResourceArn}
# Returns: record
# operationId: TagResource
export def "tag-resource" [
  resource_arn: string
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
  tags: record # One or more tags to be assigned to the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tags/{ResourceArn}"
    path_params: [{name: ResourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Publishes a new version of a DataBrew recipe.
#
# POST /recipes/{name}/publishRecipe
# Returns: record<Name: string>
# operationId: PublishRecipe
export def "publish-recipe" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # A description of the recipe to be published, for this version of the recipe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/recipes/{name}/publishRecipe"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Performs a recipe step within an interactive DataBrew session that's currently open.
#
# PUT /projects/{name}/sendProjectSessionAction
# Returns: record<Result: string, Name: string, ActionId: int>
# operationId: SendProjectSessionAction
export def "send-project-session-action" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --preview: oneof<nothing, bool> # If true, the result of the recipe step will be returned, but not applied.
  --recipe-step: record # Represents a single step from a DataBrew recipe to be performed. — shape: {Action?: record, ConditionExpressions?: list}
  --step-index: int # The index from which to preview a step. This index is used to preview the result of steps that have already been applied, so that the resulting view frame is from earlier in the view frame stack.
  --client-session-id: string # A unique identifier for an interactive session that's currently open and ready for work. The action will be performed on this session. (format: password)
  --view-frame: record # Represents the data being transformed during an action. — shape: {StartColumnIndex?: int, ColumnRange?: int, HiddenColumns?: list<string>, StartRowIndex?: int, RowRange?: int, Analytics?: "ENABLE"|"DISABLE"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/projects/{name}/sendProjectSessionAction"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Preview, var: preview}, {name: RecipeStep, var: recipe_step}, {name: StepIndex, var: step_index}, {name: ClientSessionId, var: client_session_id}, {name: ViewFrame, var: view_frame}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, preview: $preview, recipe_step: $recipe_step, step_index: $step_index, client_session_id: $client_session_id, view_frame: $view_frame
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Runs a DataBrew job.
#
# POST /jobs/{name}/startJobRun
# Returns: record<RunId: string>
# operationId: StartJobRun
export def "start-job-run" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/jobs/{name}/startJobRun"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an interactive session, enabling you to manipulate data in a DataBrew project.
#
# PUT /projects/{name}/startProjectSession
# Returns: record<Name: string, ClientSessionId: string>
# operationId: StartProjectSession
export def "start-project-session" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --assume-control: oneof<nothing, bool> # A value that, if true, enables you to take control of a session, even if a different client is currently accessing the project.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/projects/{name}/startProjectSession"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: AssumeControl, var: assume_control}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, assume_control: $assume_control
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops a particular run of a job.
#
# POST /jobs/{name}/jobRun/{runId}/stopJobRun
# Returns: record<RunId: string>
# operationId: StopJobRun
export def "stop-job-run" [
  name: string
  run_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/jobs/{name}/jobRun/{runId}/stopJobRun"
    path_params: [{name: name, var: name}, {name: runId, var: run_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, run_id: $run_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes metadata tags from a DataBrew resource.
#
# DELETE /tags/{ResourceArn}
# Returns: record
# operationId: UntagResource
export def "untag-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-keys: list<string> # The tag keys (names) of one or more tags to be removed. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/tags/{ResourceArn}"
    path_params: [{name: ResourceArn, var: resource_arn}]
    query: [{name: tagKeys, var: tag_keys, style: multi, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, tag_keys: $tag_keys, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies the definition of an existing profile job.
#
# PUT /profileJobs/{name}
# Returns: record<Name: string>
# operationId: UpdateProfileJob
export def "update-profile-job" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --configuration: record # Configuration for profile jobs. Configuration can be used to select columns, do evaluations, and override default parameters of evaluations. When configuration is undefined, the profile job will apply default settings to all supported columns. — shape: {DatasetStatisticsConfiguration?: record, ProfileColumns?: list, ColumnStatisticsConfigurations?: list, EntityDetectorConfiguration?: record}
  --encryption-key-arn: string # The Amazon Resource Name (ARN) of an encryption key that is used to protect the job.
  --encryption-mode: string@encryption-mode-completer # The encryption mode for the job, which can be one of the following: SSE-KMS - Server-side encryption with keys managed by KMS. SSE-S3 - Server-side encryption with keys managed by Amazon S3.
  --log-subscription: string@log-subscription-completer # Enables or disables Amazon CloudWatch logging for the job. If logging is enabled, CloudWatch writes one log stream for each job run.
  --max-capacity: int # The maximum number of compute nodes that DataBrew can use when the job processes data.
  --max-retries: int # The maximum number of times to retry the job after a job run fails.
  output_location: record # Represents an Amazon S3 location (bucket name, bucket owner, and object key) where DataBrew can read input data, or write output from a job. — shape: {Bucket?: string, Key?: string, BucketOwner?: string}
  --validation-configurations: list # List of validation configurations that are applied to the profile job. — item shape: {RulesetArn: string, ValidationMode?: "CHECK_ALL"}
  role_arn: string # The Amazon Resource Name (ARN) of the Identity and Access Management (IAM) role to be assumed when DataBrew runs the job.
  --timeout: int # The job's timeout in minutes. A job that attempts to run longer than this timeout period ends with a status of TIMEOUT.
  --job-sample: record # A sample configuration for profile jobs only, which determines the number of rows on which the profile job is run. If a JobSample value isn't provided, the default is used. The default value is CUSTOM_ROWS for the mode parameter and 20,000 for the size parameter. — shape: {Mode?: "FULL_DATASET"|"CUSTOM_ROWS", Size?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/profileJobs/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Configuration, var: configuration}, {name: EncryptionKeyArn, var: encryption_key_arn}, {name: EncryptionMode, var: encryption_mode}, {name: LogSubscription, var: log_subscription}, {name: MaxCapacity, var: max_capacity}, {name: MaxRetries, var: max_retries}, {name: OutputLocation, var: output_location}, {name: ValidationConfigurations, var: validation_configurations}, {name: RoleArn, var: role_arn}, {name: Timeout, var: timeout}, {name: JobSample, var: job_sample}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, configuration: $configuration, encryption_key_arn: $encryption_key_arn, encryption_mode: $encryption_mode, log_subscription: $log_subscription, max_capacity: $max_capacity, max_retries: $max_retries, output_location: $output_location, validation_configurations: $validation_configurations, role_arn: $role_arn, timeout: $timeout, job_sample: $job_sample
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies the definition of an existing DataBrew recipe job.
#
# PUT /recipeJobs/{name}
# Returns: record<Name: string>
# operationId: UpdateRecipeJob
export def "update-recipe-job" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --encryption-key-arn: string # The Amazon Resource Name (ARN) of an encryption key that is used to protect the job.
  --encryption-mode: string@encryption-mode-completer # The encryption mode for the job, which can be one of the following: SSE-KMS - Server-side encryption with keys managed by KMS. SSE-S3 - Server-side encryption with keys managed by Amazon S3.
  --log-subscription: string@log-subscription-completer # Enables or disables Amazon CloudWatch logging for the job. If logging is enabled, CloudWatch writes one log stream for each job run.
  --max-capacity: int # The maximum number of nodes that DataBrew can consume when the job processes data.
  --max-retries: int # The maximum number of times to retry the job after a job run fails.
  --outputs: list # One or more artifacts that represent the output from running the job. — item shape: {CompressionFormat?: "GZIP"|"LZ4"|"SNAPPY"|"BZIP2"|"DEFLATE"|"LZO"|"BROTLI"|"ZSTD"|"ZLIB", Format?: "CSV"|"JSON"|"PARQUET"|"GLUEPARQUET"|"AVRO"|"ORC"|"XML"|"TABLEAUHYPER", PartitionColumns?: list<string>, Location: record, Overwrite?: bool, FormatOptions?: record, MaxOutputFiles?: int}
  --data-catalog-outputs: list # One or more artifacts that represent the Glue Data Catalog output from running the job. — item shape: {CatalogId?: string, DatabaseName: string, TableName: string, S3Options?: record, DatabaseOptions?: record, Overwrite?: bool}
  --database-outputs: list # Represents a list of JDBC database output objects which defines the output destination for a DataBrew recipe job to write into. — item shape: {GlueConnectionName: string, DatabaseOptions: record, DatabaseOutputMode?: "NEW_TABLE"}
  role_arn: string # The Amazon Resource Name (ARN) of the Identity and Access Management (IAM) role to be assumed when DataBrew runs the job.
  --timeout: int # The job's timeout in minutes. A job that attempts to run longer than this timeout period ends with a status of TIMEOUT.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/recipeJobs/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: EncryptionKeyArn, var: encryption_key_arn}, {name: EncryptionMode, var: encryption_mode}, {name: LogSubscription, var: log_subscription}, {name: MaxCapacity, var: max_capacity}, {name: MaxRetries, var: max_retries}, {name: Outputs, var: outputs}, {name: DataCatalogOutputs, var: data_catalog_outputs}, {name: DatabaseOutputs, var: database_outputs}, {name: RoleArn, var: role_arn}, {name: Timeout, var: timeout}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, encryption_key_arn: $encryption_key_arn, encryption_mode: $encryption_mode, log_subscription: $log_subscription, max_capacity: $max_capacity, max_retries: $max_retries, outputs: $outputs, data_catalog_outputs: $data_catalog_outputs, database_outputs: $database_outputs, role_arn: $role_arn, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
