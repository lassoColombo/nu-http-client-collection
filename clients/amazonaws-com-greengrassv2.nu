# Auto-generated client for AWS IoT Greengrass V2 v2020-11-30
# Source: https://api.apis.guru/v2/specs/amazonaws.com/greengrassv2/2020-11-30/openapi.json
# Auth: --token flag or $env.AWS_IOT_GREENGRASS_V2_TOKEN

const CLIENT = {
  base_url: "http://greengrass.us-east-1.amazonaws.com"
  token_env_var: "AWS_IOT_GREENGRASS_V2_TOKEN"
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

def base-url-completer [] { ["http://greengrass.us-east-1.amazonaws.com" "http://greengrass.us-east-2.amazonaws.com" "http://greengrass.us-west-1.amazonaws.com" "http://greengrass.us-west-2.amazonaws.com" "http://greengrass.us-gov-west-1.amazonaws.com" "http://greengrass.us-gov-east-1.amazonaws.com" "http://greengrass.ca-central-1.amazonaws.com" "http://greengrass.eu-north-1.amazonaws.com" "http://greengrass.eu-west-1.amazonaws.com" "http://greengrass.eu-west-2.amazonaws.com" "http://greengrass.eu-west-3.amazonaws.com" "http://greengrass.eu-central-1.amazonaws.com" "http://greengrass.eu-south-1.amazonaws.com" "http://greengrass.af-south-1.amazonaws.com" "http://greengrass.ap-northeast-1.amazonaws.com" "http://greengrass.ap-northeast-2.amazonaws.com" "http://greengrass.ap-northeast-3.amazonaws.com" "http://greengrass.ap-southeast-1.amazonaws.com" "http://greengrass.ap-southeast-2.amazonaws.com" "http://greengrass.ap-east-1.amazonaws.com" "http://greengrass.ap-south-1.amazonaws.com" "http://greengrass.sa-east-1.amazonaws.com" "http://greengrass.me-south-1.amazonaws.com" "https://greengrass.us-east-1.amazonaws.com" "https://greengrass.us-east-2.amazonaws.com" "https://greengrass.us-west-1.amazonaws.com" "https://greengrass.us-west-2.amazonaws.com" "https://greengrass.us-gov-west-1.amazonaws.com" "https://greengrass.us-gov-east-1.amazonaws.com" "https://greengrass.ca-central-1.amazonaws.com" "https://greengrass.eu-north-1.amazonaws.com" "https://greengrass.eu-west-1.amazonaws.com" "https://greengrass.eu-west-2.amazonaws.com" "https://greengrass.eu-west-3.amazonaws.com" "https://greengrass.eu-central-1.amazonaws.com" "https://greengrass.eu-south-1.amazonaws.com" "https://greengrass.af-south-1.amazonaws.com" "https://greengrass.ap-northeast-1.amazonaws.com" "https://greengrass.ap-northeast-2.amazonaws.com" "https://greengrass.ap-northeast-3.amazonaws.com" "https://greengrass.ap-southeast-1.amazonaws.com" "https://greengrass.ap-southeast-2.amazonaws.com" "https://greengrass.ap-east-1.amazonaws.com" "https://greengrass.ap-south-1.amazonaws.com" "https://greengrass.sa-east-1.amazonaws.com" "https://greengrass.me-south-1.amazonaws.com" "http://greengrass.cn-north-1.amazonaws.com.cn" "http://greengrass.cn-northwest-1.amazonaws.com.cn" "https://greengrass.cn-north-1.amazonaws.com.cn" "https://greengrass.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def history-filter-completer [] { ["ALL" "LATEST_ONLY"] }
def recipe-output-format-completer [] { ["JSON" "YAML"] }
def scope-completer [] { ["PRIVATE" "PUBLIC"] }
def status-completer [] { ["HEALTHY" "UNHEALTHY"] }
def topology-filter-completer [] { ["ALL" "ROOT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    associate-service-role-to-account: "record<associatedAt: string>"
    disassociate-service-role-from-account: "record<disassociatedAt: string>"
    get-service-role-for-account: "record<associatedAt: string, roleArn: string>"
    batch-associate-client-device-with-core-device: "record<errorEntries: table<thingName: string, code: string, message: string>>"
    batch-disassociate-client-device-from-core-device: "record<errorEntries: table<thingName: string, code: string, message: string>>"
    cancel-deployment: "record<message: string>"
    create-component-version: "record<arn: string, componentName: string, componentVersion: string, creationTimestamp: string, status: record<componentState: string, message: string, errors: record, vendorGuidance: string, vendorGuidanceMessage: string>>"
    create-deployment: "record<deploymentId: string, iotJobId: string, iotJobArn: string>"
    list-deployments: "record<deployments: table<targetArn: string, revisionId: string, deploymentId: string, deploymentName: string, creationTimestamp: string, deploymentStatus: string, isLatestForTarget: bool, parentTargetArn: string>, nextToken: string>"
    get-component: "record<recipeOutputFormat: string, recipe: string, tags: record>"
    get-core-device: "record<coreDeviceThingName: string, coreVersion: string, platform: string, architecture: string, status: string, lastStatusUpdateTimestamp: string, tags: record>"
    get-deployment: "record<targetArn: string, revisionId: string, deploymentId: string, deploymentName: string, deploymentStatus: string, iotJobId: string, iotJobArn: string, components: record, deploymentPolicies: record<failureHandlingPolicy: string, componentUpdatePolicy: record<timeoutInSeconds: int, action: string>, configurationValidationPolicy: record<timeoutInSeconds: int>>, iotJobConfiguration: record<jobExecutionsRolloutConfig: record<exponentialRate: record, maximumPerMinute: int>, abortConfig: record<criteriaList: list>, timeoutConfig: record<inProgressTimeoutInMinutes: int>>, creationTimestamp: string, isLatestForTarget: bool, parentTargetArn: string, tags: record>"
    describe-component: "record<arn: string, componentName: string, componentVersion: string, creationTimestamp: string, publisher: string, description: string, status: record<componentState: string, message: string, errors: record, vendorGuidance: string, vendorGuidanceMessage: string>, platforms: table<name: string, attributes: record>, tags: record>"
    get-component-version-artifact: "record<preSignedUrl: string>"
    get-connectivity-info: "record<connectivityInfo: table<id: string, hostAddress: string, portNumber: int, metadata: string>, message: string>"
    update-connectivity-info: "record<version: string, message: string>"
    list-client-devices-associated-with-core-device: "record<associatedClientDevices: table<thingName: string, associationTimestamp: string>, nextToken: string>"
    list-component-versions: "record<componentVersions: table<componentName: string, componentVersion: string, arn: string>, nextToken: string>"
    list-components: "record<components: table<arn: string, componentName: string, latestVersion: record>, nextToken: string>"
    list-core-devices: "record<coreDevices: table<coreDeviceThingName: string, status: string, lastStatusUpdateTimestamp: string>, nextToken: string>"
    list-effective-deployments: "record<effectiveDeployments: table<deploymentId: string, deploymentName: string, iotJobId: string, iotJobArn: string, description: string, targetArn: string, coreDeviceExecutionStatus: string, reason: string, creationTimestamp: string, modifiedTimestamp: string, statusDetails: record>, nextToken: string>"
    list-installed-components: "record<installedComponents: table<componentName: string, componentVersion: string, lifecycleState: string, lifecycleStateDetails: string, isRoot: bool, lastStatusChangeTimestamp: string, lastReportedTimestamp: string, lastInstallationSource: string, lifecycleStatusCodes: list>, nextToken: string>"
    list-tags-for-resource: "record<tags: record>"
    tag-resource: "record"
    resolve-component-candidates: "record<resolvedComponentVersions: table<arn: string, componentName: string, componentVersion: string, recipe: string, vendorGuidance: string, message: string>>"
    untag-resource: "record"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["associate-service-role-to-account" "disassociate-service-role-from-account" "get-service-role-for-account" "batch-associate-client-device-with-core-device" "batch-disassociate-client-device-from-core-device" "cancel-deployment" "create-component-version" "create-deployment" "list-deployments" "delete-component" "get-component" "delete-core-device" "get-core-device" "delete-deployment" "get-deployment" "describe-component" "get-component-version-artifact" "get-connectivity-info" "update-connectivity-info" "list-client-devices-associated-with-core-device" "list-component-versions" "list-components" "list-core-devices" "list-effective-deployments" "list-installed-components" "list-tags-for-resource" "tag-resource" "resolve-component-candidates" "untag-resource" "commands"] | sort) } | get name | first)
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

# Associates a Greengrass service role with IoT Greengrass for your Amazon Web Services account in this Amazon Web Services Region. IoT Greengrass uses this role to verify the identity of client devices and manage core device connectivity information. The role must include the AWSGreengrassResourceAccessRolePolicy (https://console.aws.amazon.com/iam/home#/policies/arn:awsiam::aws:policy/service-role/AWSGreengrassResourceAccessRolePolicy) managed policy or a custom policy that defines equivalent permissions for the IoT Greengrass features that you use. For more information, see Greengrass service role (https://docs.aws.amazon.com/greengrass/v2/developerguide/greengrass-service-role.html) in the IoT Greengrass Version 2 Developer Guide.
#
# PUT /greengrass/servicerole
# Returns: record<associatedAt: string>
# operationId: AssociateServiceRoleToAccount
export def "associate-service-role-to-account" [
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
  role_arn: string # The Amazon Resource Name (ARN) of the service role to associate with IoT Greengrass for your Amazon Web Services account in this Amazon Web Services Region.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/greengrass/servicerole"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: RoleArn, var: role_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, role_arn: $role_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates the Greengrass service role from IoT Greengrass for your Amazon Web Services account in this Amazon Web Services Region. Without a service role, IoT Greengrass can't verify the identity of client devices or manage core device connectivity information. For more information, see Greengrass service role (https://docs.aws.amazon.com/greengrass/v2/developerguide/greengrass-service-role.html) in the IoT Greengrass Version 2 Developer Guide.
#
# DELETE /greengrass/servicerole
# Returns: record<disassociatedAt: string>
# operationId: DisassociateServiceRoleFromAccount
export def "disassociate-service-role-from-account" [
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
    path: "/greengrass/servicerole"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the service role associated with IoT Greengrass for your Amazon Web Services account in this Amazon Web Services Region. IoT Greengrass uses this role to verify the identity of client devices and manage core device connectivity information. For more information, see Greengrass service role (https://docs.aws.amazon.com/greengrass/v2/developerguide/greengrass-service-role.html) in the IoT Greengrass Version 2 Developer Guide.
#
# GET /greengrass/servicerole
# Returns: record<associatedAt: string, roleArn: string>
# operationId: GetServiceRoleForAccount
export def "get-service-role-for-account" [
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
    path: "/greengrass/servicerole"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates a list of client devices with a core device. Use this API operation to specify which client devices can discover a core device through cloud discovery. With cloud discovery, client devices connect to IoT Greengrass to retrieve associated core devices' connectivity information and certificates. For more information, see Configure cloud discovery (https://docs.aws.amazon.com/greengrass/v2/developerguide/configure-cloud-discovery.html) in the IoT Greengrass V2 Developer Guide. Client devices are local IoT devices that connect to and communicate with an IoT Greengrass core device over MQTT. You can connect client devices to a core device to sync MQTT messages and data to Amazon Web Services IoT Core and interact with client devices in Greengrass components. For more information, see Interact with local IoT devices (https://docs.aws.amazon.com/greengrass/v2/developerguide/interact-with-local-iot-devices.html) in the IoT Greengrass V2 Developer Guide.
#
# POST /greengrass/v2/coreDevices/{coreDeviceThingName}/associateClientDevices
# Returns: record<errorEntries: table<thingName: string, code: string, message: string>>
# operationId: BatchAssociateClientDeviceWithCoreDevice
export def "batch-associate-client-device-with-core-device" [
  core_device_thing_name: string
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
  --entries: list # The list of client devices to associate. — item shape: {thingName: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/greengrass/v2/coreDevices/{coreDeviceThingName}/associateClientDevices"
    path_params: [{name: coreDeviceThingName, var: core_device_thing_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: entries, var: entries}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    core_device_thing_name: $core_device_thing_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, entries: $entries
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates a list of client devices from a core device. After you disassociate a client device from a core device, the client device won't be able to use cloud discovery to retrieve the core device's connectivity information and certificates.
#
# POST /greengrass/v2/coreDevices/{coreDeviceThingName}/disassociateClientDevices
# Returns: record<errorEntries: table<thingName: string, code: string, message: string>>
# operationId: BatchDisassociateClientDeviceFromCoreDevice
export def "batch-disassociate-client-device-from-core-device" [
  core_device_thing_name: string
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
  --entries: list # The list of client devices to disassociate. — item shape: {thingName: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/greengrass/v2/coreDevices/{coreDeviceThingName}/disassociateClientDevices"
    path_params: [{name: coreDeviceThingName, var: core_device_thing_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: entries, var: entries}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    core_device_thing_name: $core_device_thing_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, entries: $entries
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels a deployment. This operation cancels the deployment for devices that haven't yet received it. If a device already received the deployment, this operation doesn't change anything for that device.
#
# POST /greengrass/v2/deployments/{deploymentId}/cancel
# Returns: record<message: string>
# operationId: CancelDeployment
export def "cancel-deployment" [
  deployment_id: string
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
    path: "/greengrass/v2/deployments/{deploymentId}/cancel"
    path_params: [{name: deploymentId, var: deployment_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    deployment_id: $deployment_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a component. Components are software that run on Greengrass core devices. After you develop and test a component on your core device, you can use this operation to upload your component to IoT Greengrass. Then, you can deploy the component to other core devices. You can use this operation to do the following: Create components from recipes Create a component from a recipe, which is a file that defines the component's metadata, parameters, dependencies, lifecycle, artifacts, and platform capability. For more information, see IoT Greengrass component recipe reference (https://docs.aws.amazon.com/greengrass/v2/developerguide/component-recipe-reference.html) in the IoT Greengrass V2 Developer Guide. To create a component from a recipe, specify inlineRecipe when you call this operation. Create components from Lambda functions Create a component from an Lambda function that runs on IoT Greengrass. This creates a recipe and artifacts from the Lambda function's deployment package. You can use this operation to migrate Lambda functions from IoT Greengrass V1 to IoT Greengrass V2. This function only accepts Lambda functions that use the following runtimes: Python 2.7 – python2.7 Python 3.7 – python3.7 Python 3.8 – python3.8 Python 3.9 – python3.9 Java 8 – java8 Java 11 – java11 Node.js 10 – nodejs10.x Node.js 12 – nodejs12.x Node.js 14 – nodejs14.x To create a component from a Lambda function, specify lambdaFunction when you call this operation. IoT Greengrass currently supports Lambda functions on only Linux core devices.
#
# POST /greengrass/v2/createComponentVersion
# Returns: record<arn: string, componentName: string, componentVersion: string, creationTimestamp: string, status: record<componentState: string, message: string, errors: record, vendorGuidance: string, vendorGuidanceMessage: string>>
# operationId: CreateComponentVersion
export def "create-component-version" [
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
  --inline-recipe: string # The recipe to use to create the component. The recipe defines the component's metadata, parameters, dependencies, lifecycle, artifacts, and platform compatibility. You must specify either inlineRecipe or lambdaFunction.
  --lambda-function: record # Contains information about an Lambda function to import to create a component. — shape: {lambdaArn?: string, componentName?: string, componentVersion?: string, componentPlatforms?: list, componentDependencies?: record, componentLambdaParameters?: record}
  --tags: record # A list of key-value pairs that contain metadata for the resource. For more information, see Tag your resources (https://docs.aws.amazon.com/greengrass/v2/developerguide/tag-resources.html) in the IoT Greengrass V2 Developer Guide.
  --client-token: string # A unique, case-sensitive identifier that you can provide to ensure that the request is idempotent. Idempotency means that the request is successfully processed only once, even if you send the request multiple times. When a request succeeds, and you specify the same client token for subsequent successful requests, the IoT Greengrass V2 service returns the successful response that it caches from the previous request. IoT Greengrass V2 caches successful responses for idempotent requests for up to 8 hours.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/greengrass/v2/createComponentVersion"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: inlineRecipe, var: inline_recipe}, {name: lambdaFunction, var: lambda_function}, {name: tags, var: tags}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, inline_recipe: $inline_recipe, lambda_function: $lambda_function, tags: $tags, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a continuous deployment for a target, which is a Greengrass core device or group of core devices. When you add a new core device to a group of core devices that has a deployment, IoT Greengrass deploys that group's deployment to the new device. You can define one deployment for each target. When you create a new deployment for a target that has an existing deployment, you replace the previous deployment. IoT Greengrass applies the new deployment to the target devices. Every deployment has a revision number that indicates how many deployment revisions you define for a target. Use this operation to create a new revision of an existing deployment. For more information, see the Create deployments (https://docs.aws.amazon.com/greengrass/v2/developerguide/create-deployments.html) in the IoT Greengrass V2 Developer Guide.
#
# POST /greengrass/v2/deployments
# Returns: record<deploymentId: string, iotJobId: string, iotJobArn: string>
# operationId: CreateDeployment
export def "create-deployment" [
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
  target_arn: string # The ARN (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the target IoT thing or thing group. When creating a subdeployment, the targetARN can only be a thing group.
  --deployment-name: string # The name of the deployment.
  --components: record # The components to deploy. This is a dictionary, where each key is the name of a component, and each key's value is the version and configuration to deploy for that component.
  --iot-job-configuration: record # Contains information about an IoT job configuration. — shape: {jobExecutionsRolloutConfig?: record, abortConfig?: record, timeoutConfig?: record}
  --deployment-policies: record # Contains information about policies that define how a deployment updates components and handles failure. — shape: {failureHandlingPolicy?: "ROLLBACK"|"DO_NOTHING", componentUpdatePolicy?: record, configurationValidationPolicy?: record}
  --parent-target-arn: string # The parent deployment's target ARN (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) within a subdeployment.
  --tags: record # A list of key-value pairs that contain metadata for the resource. For more information, see Tag your resources (https://docs.aws.amazon.com/greengrass/v2/developerguide/tag-resources.html) in the IoT Greengrass V2 Developer Guide.
  --client-token: string # A unique, case-sensitive identifier that you can provide to ensure that the request is idempotent. Idempotency means that the request is successfully processed only once, even if you send the request multiple times. When a request succeeds, and you specify the same client token for subsequent successful requests, the IoT Greengrass V2 service returns the successful response that it caches from the previous request. IoT Greengrass V2 caches successful responses for idempotent requests for up to 8 hours.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/greengrass/v2/deployments"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: targetArn, var: target_arn}, {name: deploymentName, var: deployment_name}, {name: components, var: components}, {name: iotJobConfiguration, var: iot_job_configuration}, {name: deploymentPolicies, var: deployment_policies}, {name: parentTargetArn, var: parent_target_arn}, {name: tags, var: tags}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, target_arn: $target_arn, deployment_name: $deployment_name, components: $components, iot_job_configuration: $iot_job_configuration, deployment_policies: $deployment_policies, parent_target_arn: $parent_target_arn, tags: $tags, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a paginated list of deployments.
#
# GET /greengrass/v2/deployments
# Returns: record<deployments: table<targetArn: string, revisionId: string, deploymentId: string, deploymentName: string, creationTimestamp: string, deploymentStatus: string, isLatestForTarget: bool, parentTargetArn: string>, nextToken: string>
# operationId: ListDeployments
export def "list-deployments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --target-arn: string # The ARN (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the target IoT thing or thing group.
  --history-filter: string@history-filter-completer # The filter for the list of deployments. Choose one of the following options: ALL – The list includes all deployments. LATEST_ONLY – The list includes only the latest revision of each deployment. Default: LATEST_ONLY
  --parent-target-arn: string # The parent deployment's target ARN (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) within a subdeployment.
  --max-results: int # The maximum number of results to be returned per paginated request.
  --next-token: string # The token to be used for the next set of paginated results.
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
    path: "/greengrass/v2/deployments"
    query: [{name: targetArn, var: target_arn}, {name: historyFilter, var: history_filter}, {name: parentTargetArn, var: parent_target_arn}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_arn: $target_arn, history_filter: $history_filter, parent_target_arn: $parent_target_arn, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a version of a component from IoT Greengrass. This operation deletes the component's recipe and artifacts. As a result, deployments that refer to this component version will fail. If you have deployments that use this component version, you can remove the component from the deployment or update the deployment to use a valid version.
#
# DELETE /greengrass/v2/components/{arn}
# operationId: DeleteComponent
export def "delete-component" [
  arn: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/greengrass/v2/components/{arn}"
    path_params: [{name: arn, var: arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    arn: $arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the recipe for a version of a component.
#
# GET /greengrass/v2/components/{arn}
# Returns: record<recipeOutputFormat: string, recipe: string, tags: record>
# operationId: GetComponent
export def "get-component" [
  arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --recipe-output-format: string@recipe-output-format-completer # The format of the recipe.
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
    path: "/greengrass/v2/components/{arn}"
    path_params: [{name: arn, var: arn}]
    query: [{name: recipeOutputFormat, var: recipe_output_format}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    arn: $arn, recipe_output_format: $recipe_output_format, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Greengrass core device, which is an IoT thing. This operation removes the core device from the list of core devices. This operation doesn't delete the IoT thing. For more information about how to delete the IoT thing, see DeleteThing (https://docs.aws.amazon.com/iot/latest/apireference/API_DeleteThing.html) in the IoT API Reference.
#
# DELETE /greengrass/v2/coreDevices/{coreDeviceThingName}
# operationId: DeleteCoreDevice
export def "delete-core-device" [
  core_device_thing_name: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/greengrass/v2/coreDevices/{coreDeviceThingName}"
    path_params: [{name: coreDeviceThingName, var: core_device_thing_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    core_device_thing_name: $core_device_thing_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves metadata for a Greengrass core device. IoT Greengrass relies on individual devices to send status updates to the Amazon Web Services Cloud. If the IoT Greengrass Core software isn't running on the device, or if device isn't connected to the Amazon Web Services Cloud, then the reported status of that device might not reflect its current status. The status timestamp indicates when the device status was last updated. Core devices send status updates at the following times: When the IoT Greengrass Core software starts When the core device receives a deployment from the Amazon Web Services Cloud When the status of any component on the core device becomes BROKEN At a regular interval that you can configure (https://docs.aws.amazon.com/greengrass/v2/developerguide/greengrass-nucleus-component.html#greengrass-nucleus-component-configuration-fss), which defaults to 24 hours For IoT Greengrass Core v2.7.0, the core device sends status updates upon local deployment and cloud deployment
#
# GET /greengrass/v2/coreDevices/{coreDeviceThingName}
# Returns: record<coreDeviceThingName: string, coreVersion: string, platform: string, architecture: string, status: string, lastStatusUpdateTimestamp: string, tags: record>
# operationId: GetCoreDevice
export def "get-core-device" [
  core_device_thing_name: string
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
    path: "/greengrass/v2/coreDevices/{coreDeviceThingName}"
    path_params: [{name: coreDeviceThingName, var: core_device_thing_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    core_device_thing_name: $core_device_thing_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a deployment. To delete an active deployment, you must first cancel it. For more information, see CancelDeployment (https://docs.aws.amazon.com/iot/latest/apireference/API_CancelDeployment.html). Deleting a deployment doesn't affect core devices that run that deployment, because core devices store the deployment's configuration on the device. Additionally, core devices can roll back to a previous deployment that has been deleted.
#
# DELETE /greengrass/v2/deployments/{deploymentId}
# operationId: DeleteDeployment
export def "delete-deployment" [
  deployment_id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/greengrass/v2/deployments/{deploymentId}"
    path_params: [{name: deploymentId, var: deployment_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    deployment_id: $deployment_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a deployment. Deployments define the components that run on Greengrass core devices.
#
# GET /greengrass/v2/deployments/{deploymentId}
# Returns: record<targetArn: string, revisionId: string, deploymentId: string, deploymentName: string, deploymentStatus: string, iotJobId: string, iotJobArn: string, components: record, deploymentPolicies: record<failureHandlingPolicy: string, componentUpdatePolicy: record<timeoutInSeconds: int, action: string>, configurationValidationPolicy: record<timeoutInSeconds: int>>, iotJobConfiguration: record<jobExecutionsRolloutConfig: record<exponentialRate: record, maximumPerMinute: int>, abortConfig: record<criteriaList: list>, timeoutConfig: record<inProgressTimeoutInMinutes: int>>, creationTimestamp: string, isLatestForTarget: bool, parentTargetArn: string, tags: record>
# operationId: GetDeployment
export def "get-deployment" [
  deployment_id: string
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
    path: "/greengrass/v2/deployments/{deploymentId}"
    path_params: [{name: deploymentId, var: deployment_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    deployment_id: $deployment_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves metadata for a version of a component.
#
# GET /greengrass/v2/components/{arn}/metadata
# Returns: record<arn: string, componentName: string, componentVersion: string, creationTimestamp: string, publisher: string, description: string, status: record<componentState: string, message: string, errors: record, vendorGuidance: string, vendorGuidanceMessage: string>, platforms: table<name: string, attributes: record>, tags: record>
# operationId: DescribeComponent
export def "describe-component" [
  arn: string
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
    path: "/greengrass/v2/components/{arn}/metadata"
    path_params: [{name: arn, var: arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    arn: $arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the pre-signed URL to download a public or a Lambda component artifact. Core devices call this operation to identify the URL that they can use to download an artifact to install.
#
# GET /greengrass/v2/components/{arn}/artifacts/{artifactName}
# Returns: record<preSignedUrl: string>
# operationId: GetComponentVersionArtifact
export def "get-component-version-artifact" [
  arn: string
  artifact_name: string
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
    path: "/greengrass/v2/components/{arn}/artifacts/{artifactName}"
    path_params: [{name: arn, var: arn}, {name: artifactName, var: artifact_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    arn: $arn, artifact_name: $artifact_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves connectivity information for a Greengrass core device. Connectivity information includes endpoints and ports where client devices can connect to an MQTT broker on the core device. When a client device calls the IoT Greengrass discovery API (https://docs.aws.amazon.com/greengrass/v2/developerguide/greengrass-discover-api.html), IoT Greengrass returns connectivity information for all of the core devices where the client device can connect. For more information, see Connect client devices to core devices (https://docs.aws.amazon.com/greengrass/v2/developerguide/connect-client-devices.html) in the IoT Greengrass Version 2 Developer Guide.
#
# GET /greengrass/things/{thingName}/connectivityInfo
# Returns: record<connectivityInfo: table<id: string, hostAddress: string, portNumber: int, metadata: string>, message: string>
# operationId: GetConnectivityInfo
export def "get-connectivity-info" [
  thing_name: string
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
    path: "/greengrass/things/{thingName}/connectivityInfo"
    path_params: [{name: thingName, var: thing_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thing_name: $thing_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates connectivity information for a Greengrass core device. Connectivity information includes endpoints and ports where client devices can connect to an MQTT broker on the core device. When a client device calls the IoT Greengrass discovery API (https://docs.aws.amazon.com/greengrass/v2/developerguide/greengrass-discover-api.html), IoT Greengrass returns connectivity information for all of the core devices where the client device can connect. For more information, see Connect client devices to core devices (https://docs.aws.amazon.com/greengrass/v2/developerguide/connect-client-devices.html) in the IoT Greengrass Version 2 Developer Guide.
#
# PUT /greengrass/things/{thingName}/connectivityInfo
# Returns: record<version: string, message: string>
# operationId: UpdateConnectivityInfo
export def "update-connectivity-info" [
  thing_name: string
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
  connectivity_info: list # The connectivity information for the core device. — item shape: {id?: string, hostAddress?: string, portNumber?: int, metadata?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/greengrass/things/{thingName}/connectivityInfo"
    path_params: [{name: thingName, var: thing_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ConnectivityInfo, var: connectivity_info}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thing_name: $thing_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, connectivity_info: $connectivity_info
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a paginated list of client devices that are associated with a core device.
#
# GET /greengrass/v2/coreDevices/{coreDeviceThingName}/associatedClientDevices
# Returns: record<associatedClientDevices: table<thingName: string, associationTimestamp: string>, nextToken: string>
# operationId: ListClientDevicesAssociatedWithCoreDevice
export def "list-client-devices-associated-with-core-device" [
  core_device_thing_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to be returned per paginated request.
  --next-token: string # The token to be used for the next set of paginated results.
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
    path: "/greengrass/v2/coreDevices/{coreDeviceThingName}/associatedClientDevices"
    path_params: [{name: coreDeviceThingName, var: core_device_thing_name}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    core_device_thing_name: $core_device_thing_name, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a paginated list of all versions for a component. Greater versions are listed first.
#
# GET /greengrass/v2/components/{arn}/versions
# Returns: record<componentVersions: table<componentName: string, componentVersion: string, arn: string>, nextToken: string>
# operationId: ListComponentVersions
export def "list-component-versions" [
  arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to be returned per paginated request.
  --next-token: string # The token to be used for the next set of paginated results.
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
    path: "/greengrass/v2/components/{arn}/versions"
    path_params: [{name: arn, var: arn}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    arn: $arn, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a paginated list of component summaries. This list includes components that you have permission to view.
#
# GET /greengrass/v2/components
# Returns: record<components: table<arn: string, componentName: string, latestVersion: record>, nextToken: string>
# operationId: ListComponents
export def "list-components" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope: string@scope-completer # The scope of the components to list. Default: PRIVATE
  --max-results: int # The maximum number of results to be returned per paginated request.
  --next-token: string # The token to be used for the next set of paginated results.
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
    path: "/greengrass/v2/components"
    query: [{name: scope, var: scope}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    scope: $scope, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a paginated list of Greengrass core devices. IoT Greengrass relies on individual devices to send status updates to the Amazon Web Services Cloud. If the IoT Greengrass Core software isn't running on the device, or if device isn't connected to the Amazon Web Services Cloud, then the reported status of that device might not reflect its current status. The status timestamp indicates when the device status was last updated. Core devices send status updates at the following times: When the IoT Greengrass Core software starts When the core device receives a deployment from the Amazon Web Services Cloud When the status of any component on the core device becomes BROKEN At a regular interval that you can configure (https://docs.aws.amazon.com/greengrass/v2/developerguide/greengrass-nucleus-component.html#greengrass-nucleus-component-configuration-fss), which defaults to 24 hours For IoT Greengrass Core v2.7.0, the core device sends status updates upon local deployment and cloud deployment
#
# GET /greengrass/v2/coreDevices
# Returns: record<coreDevices: table<coreDeviceThingName: string, status: string, lastStatusUpdateTimestamp: string>, nextToken: string>
# operationId: ListCoreDevices
export def "list-core-devices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thing-group-arn: string # The ARN (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the IoT thing group by which to filter. If you specify this parameter, the list includes only core devices that have successfully deployed a deployment that targets the thing group. When you remove a core device from a thing group, the list continues to include that core device.
  --status: string@status-completer # The core device status by which to filter. If you specify this parameter, the list includes only core devices that have this status. Choose one of the following options: HEALTHY – The IoT Greengrass Core software and all components run on the core device without issue. UNHEALTHY – The IoT Greengrass Core software or a component is in a failed state on the core device.
  --max-results: int # The maximum number of results to be returned per paginated request.
  --next-token: string # The token to be used for the next set of paginated results.
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
    path: "/greengrass/v2/coreDevices"
    query: [{name: thingGroupArn, var: thing_group_arn}, {name: status, var: status}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thing_group_arn: $thing_group_arn, status: $status, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a paginated list of deployment jobs that IoT Greengrass sends to Greengrass core devices.
#
# GET /greengrass/v2/coreDevices/{coreDeviceThingName}/effectiveDeployments
# Returns: record<effectiveDeployments: table<deploymentId: string, deploymentName: string, iotJobId: string, iotJobArn: string, description: string, targetArn: string, coreDeviceExecutionStatus: string, reason: string, creationTimestamp: string, modifiedTimestamp: string, statusDetails: record>, nextToken: string>
# operationId: ListEffectiveDeployments
export def "list-effective-deployments" [
  core_device_thing_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to be returned per paginated request.
  --next-token: string # The token to be used for the next set of paginated results.
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
    path: "/greengrass/v2/coreDevices/{coreDeviceThingName}/effectiveDeployments"
    path_params: [{name: coreDeviceThingName, var: core_device_thing_name}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    core_device_thing_name: $core_device_thing_name, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a paginated list of the components that a Greengrass core device runs. By default, this list doesn't include components that are deployed as dependencies of other components. To include dependencies in the response, set the topologyFilter parameter to ALL. IoT Greengrass relies on individual devices to send status updates to the Amazon Web Services Cloud. If the IoT Greengrass Core software isn't running on the device, or if device isn't connected to the Amazon Web Services Cloud, then the reported status of that device might not reflect its current status. The status timestamp indicates when the device status was last updated. Core devices send status updates at the following times: When the IoT Greengrass Core software starts When the core device receives a deployment from the Amazon Web Services Cloud When the status of any component on the core device becomes BROKEN At a regular interval that you can configure (https://docs.aws.amazon.com/greengrass/v2/developerguide/greengrass-nucleus-component.html#greengrass-nucleus-component-configuration-fss), which defaults to 24 hours For IoT Greengrass Core v2.7.0, the core device sends status updates upon local deployment and cloud deployment
#
# GET /greengrass/v2/coreDevices/{coreDeviceThingName}/installedComponents
# Returns: record<installedComponents: table<componentName: string, componentVersion: string, lifecycleState: string, lifecycleStateDetails: string, isRoot: bool, lastStatusChangeTimestamp: string, lastReportedTimestamp: string, lastInstallationSource: string, lifecycleStatusCodes: list>, nextToken: string>
# operationId: ListInstalledComponents
export def "list-installed-components" [
  core_device_thing_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to be returned per paginated request.
  --next-token: string # The token to be used for the next set of paginated results.
  --topology-filter: string@topology-filter-completer # The filter for the list of components. Choose from the following options: ALL – The list includes all components installed on the core device. ROOT – The list includes only root components, which are components that you specify in a deployment. When you choose this option, the list doesn't include components that the core device installs as dependencies of other components. Default: ROOT
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
    path: "/greengrass/v2/coreDevices/{coreDeviceThingName}/installedComponents"
    path_params: [{name: coreDeviceThingName, var: core_device_thing_name}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: topologyFilter, var: topology_filter}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    core_device_thing_name: $core_device_thing_name, max_results: $max_results, next_token: $next_token, topology_filter: $topology_filter, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the list of tags for an IoT Greengrass resource.
#
# GET /tags/{resourceArn}
# Returns: record<tags: record>
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
    path: "/tags/{resourceArn}"
    path_params: [{name: resourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds tags to an IoT Greengrass resource. If a tag already exists for the resource, this operation updates the tag's value.
#
# POST /tags/{resourceArn}
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
  tags: record # A list of key-value pairs that contain metadata for the resource. For more information, see Tag your resources (https://docs.aws.amazon.com/greengrass/v2/developerguide/tag-resources.html) in the IoT Greengrass V2 Developer Guide.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tags/{resourceArn}"
    path_params: [{name: resourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of components that meet the component, version, and platform requirements of a deployment. Greengrass core devices call this operation when they receive a deployment to identify the components to install. This operation identifies components that meet all dependency requirements for a deployment. If the requirements conflict, then this operation returns an error and the deployment fails. For example, this occurs if component A requires version >2.0.0 and component B requires version <2.0.0 of a component dependency. When you specify the component candidates to resolve, IoT Greengrass compares each component's digest from the core device with the component's digest in the Amazon Web Services Cloud. If the digests don't match, then IoT Greengrass specifies to use the version from the Amazon Web Services Cloud. To use this operation, you must use the data plane API endpoint and authenticate with an IoT device certificate. For more information, see IoT Greengrass endpoints and quotas (https://docs.aws.amazon.com/general/latest/gr/greengrass.html).
#
# POST /greengrass/v2/resolveComponentCandidates
# Returns: record<resolvedComponentVersions: table<arn: string, componentName: string, componentVersion: string, recipe: string, vendorGuidance: string, message: string>>
# operationId: ResolveComponentCandidates
export def "resolve-component-candidates" [
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
  --platform: record # Contains information about a platform that a component supports. — shape: {name?: string, attributes?: record}
  --component-candidates: list # The list of components to resolve. — item shape: {componentName?: string, componentVersion?: string, versionRequirements?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/greengrass/v2/resolveComponentCandidates"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: platform, var: platform}, {name: componentCandidates, var: component_candidates}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, platform: $platform, component_candidates: $component_candidates
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a tag from an IoT Greengrass resource.
#
# DELETE /tags/{resourceArn}
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
  --tag-keys: list<string> # A list of keys for tags to remove from the resource. (required)
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
    path: "/tags/{resourceArn}"
    path_params: [{name: resourceArn, var: resource_arn}]
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
