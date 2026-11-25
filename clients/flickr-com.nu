# Auto-generated client for Flickr API Schema v1.0.0
# Source: https://api.apis.guru/v2/specs/flickr.com/1.0.0/openapi.json
# Auth: --token flag or $env.FLICKR_API_SCHEMA_TOKEN

const CLIENT = {
  base_url: "https://api.flickr.com/services"
  token_env_var: "FLICKR_API_SCHEMA_TOKEN"
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

def base-url-completer [] { ["https://api.flickr.com/services"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def content-type-completer [] { ["1" "2" "3"] }
def hidden-completer [] { ["1" "2"] }
def is-family-completer [] { ["0" "1"] }
def is-friend-completer [] { ["0" "1"] }
def is-public-completer [] { ["0" "1"] }
def safety-level-completer [] { ["1" "2" "3"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-access-token: "string"
    get-request-token: "string"
    get-favorites-context-by-id: "record<count: record<_content: string>, nextphoto: record<farm: string, id: string, is_faved: bool, license: int, media: string, owner: string, safe: bool, secret: string, server: string, thumb: string, title: string, url: string>, prevphoto: record<farm: string, id: string, is_faved: bool, license: int, media: string, owner: string, safe: bool, secret: string, server: string, thumb: string, title: string, url: string>, stat: string>"
    get-favorites-by-person-id: "record<page: float, pages: float, perpage: float, photos: table<comments: record, dates: record, dateuploaded: string, description: record, editability: record, farm: string, id: string, isfavorite: bool, license: string, media: string, notes: record, originalsecret: string, owner: record, people: record, permissions: record, publiceditability: record, rotation: string, safe: bool, safety_level: string, secret: string, server: string, tags: record, title: record, urls: record, usage: record, views: string, visibility: record>, total: float>"
    get-gallery-photos-by-id: "record<photos: table<comments: record, dates: record, dateuploaded: string, description: record, editability: record, farm: string, id: string, isfavorite: bool, license: string, media: string, notes: record, originalsecret: string, owner: record, people: record, permissions: record, publiceditability: record, rotation: string, safe: bool, safety_level: string, secret: string, server: string, tags: record, title: record, urls: record, usage: record, views: string, visibility: record>>"
    get-group-topic-replies-by-id: "record<reply: record<author: string, author_is_deleted: bool, author_path_alias: string, authorname: string, can_delete: bool, can_edit: bool, datecreate: string, iconfarm: string, iconserver: string, id: string, is_pro: bool, lastedit: string, message: record<_content: string>>, stat: string>"
    get-group-topic-by-id: "record<stat: string, topic: record<author: string, author_is_deleted: bool, author_path_alias: string, authorname: string, can_delete: bool, can_edit: bool, can_reply: bool, count_replies: int, datecreate: string, datelastpost: string, iconfarm: string, iconserver: string, id: string, is_locked: bool, is_pro: bool, is_sticky: bool, last_reply: string, lastedit: string, message: record<_content: string>, role: string, subject: string>>"
    get-group-discussions-by-id: "record<iconfarm: float, iconserver: float, ispoolmoderated: bool, lang: string, members: float, name: string, page: float, pages: float, per_page: float, privacy: float, topics: table<author: string, author_is_deleted: bool, author_path_alias: string, authorname: string, can_delete: bool, can_edit: bool, can_reply: bool, count_replies: int, datecreate: string, datelastpost: string, iconfarm: string, iconserver: string, id: string, is_locked: bool, is_pro: bool, is_sticky: bool, last_reply: string, lastedit: string, message: record, role: string, subject: string>, total: float>"
    get-group-by-id: "record<group: record<blast: record<_content: string, date_blast_added: string, user_id: string>, cover: record<farm: string, id: string, isfamily: bool, isfriend: bool, ispublic: bool, owner: string, secret: string, server: string, title: string, y: string>, coverphoto_farm: string, coverphoto_server: string, coverphoto_url: record<h: string, l: string, s: string, t: string>, description: record<_content: string>, iconfarm: string, iconserver: string, id: string, is_admin: bool, is_member: bool, is_moderator: bool, ispoolmoderated: bool, lang: string, members: record<_content: string>, name: record<_content: string>, path_alias: string, pool_count: record<_content: string>, pool_rows: int, privacy: record<_content: string>, restrictions: record<art_ok: bool, has_geo: bool, images_ok: bool, moderate_ok: bool, photos_ok: bool, restricted_ok: bool, safe_ok: bool, screens_ok: bool, videos_ok: bool>, roles: record<admin: string, member: string, moderator: string>, rules: record<_content: string>, throttle: record<count: int, mode: string, remaining: string>, topic_count: record<_content: string>>, stat: string>"
    get-rest-method-flickr-groups-pools-get-context: "record<count: record<_content: string>, nextphoto: record<farm: string, id: string, is_faved: bool, license: int, media: string, owner: string, safe: bool, secret: string, server: string, thumb: string, title: string, url: string>, prevphoto: record<farm: string, id: string, is_faved: bool, license: int, media: string, owner: string, safe: bool, secret: string, server: string, thumb: string, title: string, url: string>, stat: string>"
    get-group-photos-by-id: "record<photos: table<comments: record, dates: record, dateuploaded: string, description: record, editability: record, farm: string, id: string, isfavorite: bool, license: string, media: string, notes: record, originalsecret: string, owner: record, people: record, permissions: record, publiceditability: record, rotation: string, safe: bool, safety_level: string, secret: string, server: string, tags: record, title: record, urls: record, usage: record, views: string, visibility: record>>"
    get-person-by-id: "record<person: record<can_buy_pro: bool, cover: record<farm: string, id: string, isfamily: bool, isfriend: bool, ispublic: bool, owner: string, secret: string, server: string, title: string, y: string>, coverphoto: record<h: string, l: string, s: string, t: string>, coverphoto_farm: string, coverphoto_server: string, description: record<_content: string>, disable_keyboard_shortcuts: record<_content: string>, expire: bool, has_stats: bool, iconfarm: string, iconserver: string, id: string, is_ad_free: bool, ispro: bool, location: record<_content: string>, mbox_sha1sum: record<_content: string>, mobileurl: record<_content: string>, nsid: string, path_alias: string, photos: record<count: record, firstdate: record, firstdatetaken: record, views: record>, photosurl: record<_content: string>, profileurl: record<_content: string>, realname: record<_content: string>, timezone: record<label: string, offset: string, timezone_id: string>, unread_messages: record<_content: string>, user_secret: string, username: record<_content: string>, yintl: string>, stat: string>"
    get-media-by-person-id: "record<page: float, pages: float, perpage: float, photos: table<comments: record, dates: record, dateuploaded: string, description: record, editability: record, farm: string, id: string, isfavorite: bool, license: string, media: string, notes: record, originalsecret: string, owner: record, people: record, permissions: record, publiceditability: record, rotation: string, safe: bool, safety_level: string, secret: string, server: string, tags: record, title: record, urls: record, usage: record, views: string, visibility: record>, total: float>"
    get-photolist-context-by-id: "record<count: record<_content: string>, nextphoto: record<farm: string, id: string, is_faved: bool, license: int, media: string, owner: string, safe: bool, secret: string, server: string, thumb: string, title: string, url: string>, prevphoto: record<farm: string, id: string, is_faved: bool, license: int, media: string, owner: string, safe: bool, secret: string, server: string, thumb: string, title: string, url: string>, stat: string>"
    get-photostream-context-by-id: "record<count: record<_content: string>, nextphoto: record<farm: string, id: string, is_faved: bool, license: int, media: string, owner: string, safe: bool, secret: string, server: string, thumb: string, title: string, url: string>, prevphoto: record<farm: string, id: string, is_faved: bool, license: int, media: string, owner: string, safe: bool, secret: string, server: string, thumb: string, title: string, url: string>, stat: string>"
    get-photo-exif-by-id: "record<photo: record<camera: string, exif: list<record>, farm: string, id: string, secret: string, server: string>, stat: string>"
    get-photo-by-id: "record<photo: record<comments: record<_content: string>, dates: record<lastupdate: string, posted: string, taken: string, takengranularity: string, takenunknown: bool>, dateuploaded: string, description: record<_content: string>, editability: record<canaddmeta: bool, cancomment: bool>, farm: string, id: string, isfavorite: bool, license: string, media: string, notes: record<note: list>, originalsecret: string, owner: record<iconfarm: string, iconserver: string, is_ad_free: bool, ispro: bool, location: string, noindexfollow: bool, nsid: string, path_alias: string, realname: string, username: string>, people: record<haspeople: bool>, permissions: record<permaddmeta: string, permcomment: string>, publiceditability: record<canaddmeta: bool, cancomment: bool>, rotation: string, safe: bool, safety_level: string, secret: string, server: string, tags: record<tag: list>, title: record<_content: string>, urls: record<url: list>, usage: record<canblog: bool, candownload: bool, canprint: bool, canshare: bool>, views: string, visibility: record<isfamily: bool, isfriend: bool, ispublic: bool>>, stat: string>"
    get-photo-sizes-by-id: "record<sizes: record<canblog: float, candownload: float, canprint: float, sizes: list<record>>, stat: string>"
    get-license-by-id: "record<licenses: record<license: list<record>>, stat: string>"
    get-media-by-search: "record<page: float, pages: float, perpage: float, photos: table<comments: record, dates: record, dateuploaded: string, description: record, editability: record, farm: string, id: string, isfavorite: bool, license: string, media: string, notes: record, originalsecret: string, owner: record, people: record, permissions: record, publiceditability: record, rotation: string, safe: bool, safety_level: string, secret: string, server: string, tags: record, title: record, urls: record, usage: record, views: string, visibility: record>, total: float>"
    get-album-context-by-id: "record<count: record<_content: string>, nextphoto: record<farm: string, id: string, is_faved: bool, license: int, media: string, owner: string, safe: bool, secret: string, server: string, thumb: string, title: string, url: string>, prevphoto: record<farm: string, id: string, is_faved: bool, license: int, media: string, owner: string, safe: bool, secret: string, server: string, thumb: string, title: string, url: string>, stat: string>"
    get-albums-by-person-id: "record<page: float, pages: float, perpage: float, photosets: table<can_comment: bool, count_comments: float, count_views: float, date_create: float, date_update: float, description: string, farm: string, id: string, photos: float, primary: string, secret: string, server: string, title: string, videos: float>, total: float>"
    get-album-by-id: "record<photoset: table<comments: record, dates: record, dateuploaded: string, description: record, editability: record, farm: string, id: string, isfavorite: bool, license: string, media: string, notes: record, originalsecret: string, owner: record, people: record, permissions: record, publiceditability: record, rotation: string, safe: bool, safety_level: string, secret: string, server: string, tags: record, title: record, urls: record, usage: record, views: string, visibility: record>>"
    get-rest-method-flickr-test-echo: "record<echo: record<_content: string>>"
    upload-photo: "record"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-access-token" "get-request-token" "get-favorites-context-by-id" "get-favorites-by-person-id" "get-gallery-photos-by-id" "get-group-topic-replies-by-id" "get-group-topic-by-id" "get-group-discussions-by-id" "get-group-by-id" "get-rest-method-flickr-groups-pools-get-context" "get-group-photos-by-id" "get-person-by-id" "get-media-by-person-id" "get-photolist-context-by-id" "get-photostream-context-by-id" "get-photo-exif-by-id" "get-photo-by-id" "get-photo-sizes-by-id" "get-license-by-id" "get-media-by-search" "get-album-context-by-id" "get-albums-by-person-id" "get-album-by-id" "get-rest-method-flickr-test-echo" "upload-photo" "commands"] | sort) } | get name | first)
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

# Returns an access token
#
# GET /oauth/access_token
# Returns: string
# operationId: getAccessToken
export def "get-access-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --oauth-consumer-key: string # required
  --oauth-nonce: string # required
  --oauth-timestamp: string # required
  --oauth-signature-method: string # required
  --oauth-version: string # required
  --oauth-signature: string # required
  --oauth-verifier: string # required
  --oauth-token: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/oauth/access_token"
    query: [{name: oauth_consumer_key, var: oauth_consumer_key, required: true}, {name: oauth_nonce, var: oauth_nonce, required: true}, {name: oauth_timestamp, var: oauth_timestamp, required: true}, {name: oauth_signature_method, var: oauth_signature_method, required: true}, {name: oauth_version, var: oauth_version, required: true}, {name: oauth_signature, var: oauth_signature, required: true}, {name: oauth_verifier, var: oauth_verifier, required: true}, {name: oauth_token, var: oauth_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    oauth_consumer_key: $oauth_consumer_key, oauth_nonce: $oauth_nonce, oauth_timestamp: $oauth_timestamp, oauth_signature_method: $oauth_signature_method, oauth_version: $oauth_version, oauth_signature: $oauth_signature, oauth_verifier: $oauth_verifier, oauth_token: $oauth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an oauth token and oauth token secret
#
# GET /oauth/request_token
# Returns: string
# operationId: getRequestToken
export def "get-request-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --oauth-consumer-key: string # required
  --oauth-nonce: string # required
  --oauth-timestamp: string # required
  --oauth-signature-method: string # required
  --oauth-version: string # required
  --oauth-signature: string # required
  --oauth-callback: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/oauth/request_token"
    query: [{name: oauth_consumer_key, var: oauth_consumer_key, required: true}, {name: oauth_nonce, var: oauth_nonce, required: true}, {name: oauth_timestamp, var: oauth_timestamp, required: true}, {name: oauth_signature_method, var: oauth_signature_method, required: true}, {name: oauth_version, var: oauth_version, required: true}, {name: oauth_signature, var: oauth_signature, required: true}, {name: oauth_callback, var: oauth_callback, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    oauth_consumer_key: $oauth_consumer_key, oauth_nonce: $oauth_nonce, oauth_timestamp: $oauth_timestamp, oauth_signature_method: $oauth_signature_method, oauth_version: $oauth_version, oauth_signature: $oauth_signature, oauth_callback: $oauth_callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns next and previous favorites for a photo in a user's favorites
#
# GET /rest?method=flickr.favorites.getContext
# Returns: record<count: record<_content: string>, nextphoto: record<farm: string, id: string, is_faved: bool, license: int, media: string, owner: string, safe: bool, secret: string, server: string, thumb: string, title: string, url: string>, prevphoto: record<farm: string, id: string, is_faved: bool, license: int, media: string, owner: string, safe: bool, secret: string, server: string, thumb: string, title: string, url: string>, stat: string>
# operationId: getFavoritesContextByID
export def "get-favorites-context-by-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # required
  --photo-id: string # required
  --user-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest"
    fixed_query: "method=flickr.favorites.getContext"
    query: [{name: api_key, var: api_key, required: true}, {name: photo_id, var: photo_id, required: true}, {name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key, photo_id: $photo_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of the user's favorite photos. Only photos which the calling user has permission to see are returned.
#
# GET /rest?method=flickr.favorites.getList
# Returns: record<page: float, pages: float, perpage: float, photos: table<comments: record, dates: record, dateuploaded: string, description: record, editability: record, farm: string, id: string, isfavorite: bool, license: string, media: string, notes: record, originalsecret: string, owner: record, people: record, permissions: record, publiceditability: record, rotation: string, safe: bool, safety_level: string, secret: string, server: string, tags: record, title: record, urls: record, usage: record, views: string, visibility: record>, total: float>
# operationId: getFavoritesByPersonID
export def "get-favorites-by-person-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # required
  --user-id: string # required
  --min-fave-date: float
  --max-fave-date: float
  --page: float
  --per-page: float
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest"
    fixed_query: "method=flickr.favorites.getList"
    query: [{name: api_key, var: api_key, required: true}, {name: user_id, var: user_id, required: true}, {name: min_fave_date, var: min_fave_date}, {name: max_fave_date, var: max_fave_date}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key, user_id: $user_id, min_fave_date: $min_fave_date, max_fave_date: $max_fave_date, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of photos in a gallery.
#
# GET /rest?method=flickr.galleries.getPhotos
# Returns: record<photos: table<comments: record, dates: record, dateuploaded: string, description: record, editability: record, farm: string, id: string, isfavorite: bool, license: string, media: string, notes: record, originalsecret: string, owner: record, people: record, permissions: record, publiceditability: record, rotation: string, safe: bool, safety_level: string, secret: string, server: string, tags: record, title: record, urls: record, usage: record, views: string, visibility: record>>
# operationId: getGalleryPhotosByID
export def "get-gallery-photos-by-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # required
  --gallery-id: string # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest"
    fixed_query: "method=flickr.galleries.getPhotos"
    query: [{name: api_key, var: api_key, required: true}, {name: gallery_id, var: gallery_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key, gallery_id: $gallery_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information on a group topic reply
#
# GET /rest?method=flickr.groups.discuss.replies.getInfo
# Returns: record<reply: record<author: string, author_is_deleted: bool, author_path_alias: string, authorname: string, can_delete: bool, can_edit: bool, datecreate: string, iconfarm: string, iconserver: string, id: string, is_pro: bool, lastedit: string, message: record<_content: string>>, stat: string>
# operationId: getGroupTopicRepliesByID
export def "get-group-topic-replies-by-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # required
  --group-id: string
  --topic-id: string # required
  --reply-id: string # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest"
    fixed_query: "method=flickr.groups.discuss.replies.getInfo"
    query: [{name: api_key, var: api_key, required: true}, {name: group_id, var: group_id}, {name: topic_id, var: topic_id, required: true}, {name: reply_id, var: reply_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key, group_id: $group_id, topic_id: $topic_id, reply_id: $reply_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information about a group discussion topic
#
# GET /rest?method=flickr.groups.discuss.topics.getInfo
# Returns: record<stat: string, topic: record<author: string, author_is_deleted: bool, author_path_alias: string, authorname: string, can_delete: bool, can_edit: bool, can_reply: bool, count_replies: int, datecreate: string, datelastpost: string, iconfarm: string, iconserver: string, id: string, is_locked: bool, is_pro: bool, is_sticky: bool, last_reply: string, lastedit: string, message: record<_content: string>, role: string, subject: string>>
# operationId: getGroupTopicByID
export def "get-group-topic-by-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # required
  --group-id: string
  --topic-id: string # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest"
    fixed_query: "method=flickr.groups.discuss.topics.getInfo"
    query: [{name: api_key, var: api_key, required: true}, {name: group_id, var: group_id}, {name: topic_id, var: topic_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key, group_id: $group_id, topic_id: $topic_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of discussion topics in a group.
#
# GET /rest?method=flickr.groups.discuss.topics.getList
# Returns: record<iconfarm: float, iconserver: float, ispoolmoderated: bool, lang: string, members: float, name: string, page: float, pages: float, per_page: float, privacy: float, topics: table<author: string, author_is_deleted: bool, author_path_alias: string, authorname: string, can_delete: bool, can_edit: bool, can_reply: bool, count_replies: int, datecreate: string, datelastpost: string, iconfarm: string, iconserver: string, id: string, is_locked: bool, is_pro: bool, is_sticky: bool, last_reply: string, lastedit: string, message: record, role: string, subject: string>, total: float>
# operationId: getGroupDiscussionsByID
export def "get-group-discussions-by-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # required
  --group-id: string
  --page: float
  --per-page: float
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest"
    fixed_query: "method=flickr.groups.discuss.topics.getList"
    query: [{name: api_key, var: api_key, required: true}, {name: group_id, var: group_id}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key, group_id: $group_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information about a group
#
# GET /rest?method=flickr.groups.getInfo
# Returns: record<group: record<blast: record<_content: string, date_blast_added: string, user_id: string>, cover: record<farm: string, id: string, isfamily: bool, isfriend: bool, ispublic: bool, owner: string, secret: string, server: string, title: string, y: string>, coverphoto_farm: string, coverphoto_server: string, coverphoto_url: record<h: string, l: string, s: string, t: string>, description: record<_content: string>, iconfarm: string, iconserver: string, id: string, is_admin: bool, is_member: bool, is_moderator: bool, ispoolmoderated: bool, lang: string, members: record<_content: string>, name: record<_content: string>, path_alias: string, pool_count: record<_content: string>, pool_rows: int, privacy: record<_content: string>, restrictions: record<art_ok: bool, has_geo: bool, images_ok: bool, moderate_ok: bool, photos_ok: bool, restricted_ok: bool, safe_ok: bool, screens_ok: bool, videos_ok: bool>, roles: record<admin: string, member: string, moderator: string>, rules: record<_content: string>, throttle: record<count: int, mode: string, remaining: string>, topic_count: record<_content: string>>, stat: string>
# operationId: getGroupByID
export def "get-group-by-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # required
  --group-id: string
  --group-path-alias: string
  --lang: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest"
    fixed_query: "method=flickr.groups.getInfo"
    query: [{name: api_key, var: api_key, required: true}, {name: group_id, var: group_id}, {name: group_path_alias, var: group_path_alias}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key, group_id: $group_id, group_path_alias: $group_path_alias, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns next and previous photos for a photo in a group pool
#
# GET /rest?method=flickr.groups.pools.getContext
# Returns: record<count: record<_content: string>, nextphoto: record<farm: string, id: string, is_faved: bool, license: int, media: string, owner: string, safe: bool, secret: string, server: string, thumb: string, title: string, url: string>, prevphoto: record<farm: string, id: string, is_faved: bool, license: int, media: string, owner: string, safe: bool, secret: string, server: string, thumb: string, title: string, url: string>, stat: string>
export def "get-rest-method-flickr-groups-pools-get-context" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # required
  --photo-id: string # required
  --group-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest"
    fixed_query: "method=flickr.groups.pools.getContext"
    query: [{name: api_key, var: api_key, required: true}, {name: photo_id, var: photo_id, required: true}, {name: group_id, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key, photo_id: $photo_id, group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of pool photos for a given group
#
# GET /rest?method=flickr.groups.pools.getPhotos
# Returns: record<photos: table<comments: record, dates: record, dateuploaded: string, description: record, editability: record, farm: string, id: string, isfavorite: bool, license: string, media: string, notes: record, originalsecret: string, owner: record, people: record, permissions: record, publiceditability: record, rotation: string, safe: bool, safety_level: string, secret: string, server: string, tags: record, title: record, urls: record, usage: record, views: string, visibility: record>>
# operationId: getGroupPhotosByID
export def "get-group-photos-by-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # required
  --group-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest"
    fixed_query: "method=flickr.groups.pools.getPhotos"
    query: [{name: api_key, var: api_key, required: true}, {name: group_id, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key, group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a person
#
# GET /rest?method=flickr.people.getInfo
# Returns: record<person: record<can_buy_pro: bool, cover: record<farm: string, id: string, isfamily: bool, isfriend: bool, ispublic: bool, owner: string, secret: string, server: string, title: string, y: string>, coverphoto: record<h: string, l: string, s: string, t: string>, coverphoto_farm: string, coverphoto_server: string, description: record<_content: string>, disable_keyboard_shortcuts: record<_content: string>, expire: bool, has_stats: bool, iconfarm: string, iconserver: string, id: string, is_ad_free: bool, ispro: bool, location: record<_content: string>, mbox_sha1sum: record<_content: string>, mobileurl: record<_content: string>, nsid: string, path_alias: string, photos: record<count: record, firstdate: record, firstdatetaken: record, views: record>, photosurl: record<_content: string>, profileurl: record<_content: string>, realname: record<_content: string>, timezone: record<label: string, offset: string, timezone_id: string>, unread_messages: record<_content: string>, user_secret: string, username: record<_content: string>, yintl: string>, stat: string>
# operationId: getPersonByID
export def "get-person-by-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # required
  --user-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest"
    fixed_query: "method=flickr.people.getInfo"
    query: [{name: api_key, var: api_key, required: true}, {name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return photos from the given user's photostream
#
# GET /rest?method=flickr.people.getPhotos
# Returns: record<page: float, pages: float, perpage: float, photos: table<comments: record, dates: record, dateuploaded: string, description: record, editability: record, farm: string, id: string, isfavorite: bool, license: string, media: string, notes: record, originalsecret: string, owner: record, people: record, permissions: record, publiceditability: record, rotation: string, safe: bool, safety_level: string, secret: string, server: string, tags: record, title: record, urls: record, usage: record, views: string, visibility: record>, total: float>
# operationId: getMediaByPersonID
export def "get-media-by-person-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # required
  --user-id: string # required
  --safe-search: float
  --min-upload-date: float
  --max-upload-date: float
  --min-taken-date: float
  --max-taken-date: float
  --content-type: float
  --privacy-filter: float
  --page: float
  --per-page: float
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest"
    fixed_query: "method=flickr.people.getPhotos"
    query: [{name: api_key, var: api_key, required: true}, {name: user_id, var: user_id, required: true}, {name: safe_search, var: safe_search}, {name: min_upload_date, var: min_upload_date}, {name: max_upload_date, var: max_upload_date}, {name: min_taken_date, var: min_taken_date}, {name: max_taken_date, var: max_taken_date}, {name: content_type, var: content_type}, {name: privacy_filter, var: privacy_filter}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key, user_id: $user_id, safe_search: $safe_search, min_upload_date: $min_upload_date, max_upload_date: $max_upload_date, min_taken_date: $min_taken_date, max_taken_date: $max_taken_date, content_type: $content_type, privacy_filter: $privacy_filter, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns next and previous photos in a photo list
#
# GET /rest?method=flickr.photolist.getContext
# Returns: record<count: record<_content: string>, nextphoto: record<farm: string, id: string, is_faved: bool, license: int, media: string, owner: string, safe: bool, secret: string, server: string, thumb: string, title: string, url: string>, prevphoto: record<farm: string, id: string, is_faved: bool, license: int, media: string, owner: string, safe: bool, secret: string, server: string, thumb: string, title: string, url: string>, stat: string>
# operationId: getPhotolistContextByID
export def "get-photolist-context-by-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # required
  --photo-id: string # required
  --photolist-id: string # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest"
    fixed_query: "method=flickr.photolist.getContext"
    query: [{name: api_key, var: api_key, required: true}, {name: photo_id, var: photo_id, required: true}, {name: photolist_id, var: photolist_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key, photo_id: $photo_id, photolist_id: $photolist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns next and previous photos for a photo in a photostream
#
# GET /rest?method=flickr.photos.getContext
# Returns: record<count: record<_content: string>, nextphoto: record<farm: string, id: string, is_faved: bool, license: int, media: string, owner: string, safe: bool, secret: string, server: string, thumb: string, title: string, url: string>, prevphoto: record<farm: string, id: string, is_faved: bool, license: int, media: string, owner: string, safe: bool, secret: string, server: string, thumb: string, title: string, url: string>, stat: string>
# operationId: getPhotostreamContextByID
export def "get-photostream-context-by-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # required
  --photo-id: string # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest"
    fixed_query: "method=flickr.photos.getContext"
    query: [{name: api_key, var: api_key, required: true}, {name: photo_id, var: photo_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key, photo_id: $photo_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of EXIF/TIFF/GPS tags for a given photo. The calling user must have permission to view the photo.
#
# GET /rest?method=flickr.photos.getExif
# Returns: record<photo: record<camera: string, exif: list<record>, farm: string, id: string, secret: string, server: string>, stat: string>
# operationId: getPhotoExifByID
export def "get-photo-exif-by-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # required
  --photo-id: string # required
  --secret: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest"
    fixed_query: "method=flickr.photos.getExif"
    query: [{name: api_key, var: api_key, required: true}, {name: photo_id, var: photo_id, required: true}, {name: secret, var: secret}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key, photo_id: $photo_id, secret: $secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a photo
#
# GET /rest?method=flickr.photos.getInfo
# Returns: record<photo: record<comments: record<_content: string>, dates: record<lastupdate: string, posted: string, taken: string, takengranularity: string, takenunknown: bool>, dateuploaded: string, description: record<_content: string>, editability: record<canaddmeta: bool, cancomment: bool>, farm: string, id: string, isfavorite: bool, license: string, media: string, notes: record<note: list>, originalsecret: string, owner: record<iconfarm: string, iconserver: string, is_ad_free: bool, ispro: bool, location: string, noindexfollow: bool, nsid: string, path_alias: string, realname: string, username: string>, people: record<haspeople: bool>, permissions: record<permaddmeta: string, permcomment: string>, publiceditability: record<canaddmeta: bool, cancomment: bool>, rotation: string, safe: bool, safety_level: string, secret: string, server: string, tags: record<tag: list>, title: record<_content: string>, urls: record<url: list>, usage: record<canblog: bool, candownload: bool, canprint: bool, canshare: bool>, views: string, visibility: record<isfamily: bool, isfriend: bool, ispublic: bool>>, stat: string>
# operationId: getPhotoByID
export def "get-photo-by-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # required
  --photo-id: string # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest"
    fixed_query: "method=flickr.photos.getInfo"
    query: [{name: api_key, var: api_key, required: true}, {name: photo_id, var: photo_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key, photo_id: $photo_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns photo sizes
#
# GET /rest?method=flickr.photos.getSizes
# Returns: record<sizes: record<canblog: float, candownload: float, canprint: float, sizes: list<record>>, stat: string>
# operationId: getPhotoSizesByID
export def "get-photo-sizes-by-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # required
  --photo-id: string # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest"
    fixed_query: "method=flickr.photos.getSizes"
    query: [{name: api_key, var: api_key, required: true}, {name: photo_id, var: photo_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key, photo_id: $photo_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches a list of available photo licenses for Flickr
#
# GET /rest?method=flickr.photos.licenses.getInfo
# Returns: record<licenses: record<license: list<record>>, stat: string>
# operationId: getLicenseByID
export def "get-license-by-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest"
    fixed_query: "method=flickr.photos.licenses.getInfo"
    query: [{name: api_key, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of photos matching some criteria.
#
# GET /rest?method=flickr.photos.search
# Returns: record<page: float, pages: float, perpage: float, photos: table<comments: record, dates: record, dateuploaded: string, description: record, editability: record, farm: string, id: string, isfavorite: bool, license: string, media: string, notes: record, originalsecret: string, owner: record, people: record, permissions: record, publiceditability: record, rotation: string, safe: bool, safety_level: string, secret: string, server: string, tags: record, title: record, urls: record, usage: record, views: string, visibility: record>, total: float>
# operationId: getMediaBySearch
export def "get-media-by-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # required
  --text: string # A free text search. Photos who's title, description or tags contain the text will be returned. You can exclude results that match a term by prepending it with a - character.
  --tags: string # A comma-delimited list of tags. Photos with one or more of the tags listed will be returned. You can exclude results that match a term by prepending it with a - character.
  --user-id: string # The NSID of the user who's photo to search. If this parameter isn't passed then everybody's public photos will be searched. A value of "me" will search against the calling user's photos for authenticated calls.
  --min-upload-date: string # Minimum upload date. Photos with an upload date greater than or equal to this value will be returned. The date can be in the form of a unix timestamp or mysql datetime.
  --max-upload-date: string # Maximum upload date. Photos with an upload date less than or equal to this value will be returned. The date can be in the form of a unix timestamp or mysql datetime.
  --min-taken-date: string # Minimum taken date. Photos with an taken date greater than or equal to this value will be returned. The date can be in the form of a mysql datetime or unix timestamp.
  --max-taken-date: string # Maximum taken date. Photos with an taken date less than or equal to this value will be returned. The date can be in the form of a mysql datetime or unix timestamp.
  --license: string # The license id for photos (for possible values see the flickr.photos.licenses.getInfo method). Multiple licenses may be comma-separated.
  --sort: string # The order in which to sort returned photos. Deafults to date-posted-desc (unless you are doing a radial geo query, in which case the default sorting is by ascending distance from the point specified). The possible values are: date-posted-asc, date-posted-desc, date-taken-asc, date-taken-desc, interestingness-desc, interestingness-asc, and relevance.
  --privacy-filter: float # Return photos only matching a certain privacy level. This only applies when making an authenticated call to view photos you own. Valid values are:, 1: public photos, 2: private photos visible to friends, 3: private photos visible to family, 4: private photos visible to friends & family, 5: completely private photos
  --bbox: string # A comma-delimited list of 4 values defining the Bounding Box of the area that will be searched.
  --accuracy: string # Recorded accuracy level of the location information. Current range is 1-16: World level is 1 Country is ~3 Region is ~6 City is ~11 Street is ~16
  --safe-search: float # Safe search setting: 1: for safe, 2: for moderate, 3: for restricted
  --content-type: float # Content Type setting: 1: photos only. 2: screenshots only. 3: 'other' only. 4: photos and screenshots. 5: screenshots and 'other'. 6: photos and 'other'. 7: photos, screenshots, and 'other' (all).
  --machine-tags: string # Aside from passing in a fully formed machine tag, there is a special syntax for searching on specific properties : Find photos using the 'dc' namespace : "machine_tags" => "dc:" Find photos with a title in the 'dc' namespace : "machine_tags" => "dc:title=" Find photos titled "mr. camera" in the 'dc' namespace : "machine_tags" => "dc:title=\"mr. camera\" Find photos whose value is "mr. camera" : "machine_tags" => "*:*=\"mr. camera\"" Find photos that have a title, in any namespace : "machine_tags" => "*:title=" Find photos that have a title, in any namespace, whose value is "mr. camera" : "machine_tags" => "*:title=\"mr. camera\"" Find photos, in the 'dc' namespace whose value is "mr. camera" : "machine_tags" => "dc:*=\"mr. camera\"" Multiple machine tags may be queried by passing a comma-separated list. The number of machine tags you can pass in a single query depends on the tag mode (AND or OR) that you are querying with. "AND" queries are limited to (16) machine tags. "OR" queries are limited to (8).
  --machine-tag-mode: string # Either 'any' for an OR combination of tags, or 'all' for an AND combination. Defaults to 'any' if not specified.
  --group-id: string # The id of a group who's pool to search. If specified, only matching photos posted to the group's pool will be returned.
  --contacts: string # Search your contacts. Either 'all' or 'ff' for just friends and family. (Experimental)
  --woe-id: string # A 32-bit identifier that uniquely represents spatial entities. (not used if bbox argument is present).
  --place-id: string # A Flickr place id. (not used if bbox argument is present). Geo queries require some sort of limiting agent in order to prevent the database from crying. This is basically like the check against "parameterless searches" for queries without a geo component. A tag, for instance, is considered a limiting agent as are user defined min_date_taken and min_date_upload parameters — If no limiting factor is passed we return only photos added in the last 12 hours (though we may extend the limit in the future).
  --media: string # Filter results by media type. Possible values are all (default), photos or videos
  --has-geo: string # Any photo that has been geotagged, or if the value is "0" any photo that has not been geotagged. Geo queries require some sort of limiting agent in order to prevent the database from crying. This is basically like the check against "parameterless searches" for queries without a geo component. A tag, for instance, is considered a limiting agent as are user defined min_date_taken and min_date_upload parameters — If no limiting factor is passed we return only photos added in the last 12 hours (though we may extend the limit in the future).
  --geo-context: string # Geo context is a numeric value representing the photo's geotagginess beyond latitude and longitude. For example, you may wish to search for photos that were taken "indoors" or "outdoors". The current list of context IDs is: 0, not defined. 1, indoors. 2, outdoors. Geo queries require some sort of limiting agent in order to prevent the database from crying. This is basically like the check against "parameterless searches" for queries without a geo component. A tag, for instance, is considered a limiting agent as are user defined min_date_taken and min_date_upload parameters — If no limiting factor is passed we return only photos added in the last 12 hours (though we may extend the limit in the future).
  --lat: string # A valid latitude, in decimal format, for doing radial geo queries. Geo queries require some sort of limiting agent in order to prevent the database from crying. This is basically like the check against "parameterless searches" for queries without a geo component. A tag, for instance, is considered a limiting agent as are user defined min_date_taken and min_date_upload parameters — If no limiting factor is passed we return only photos added in the last 12 hours (though we may extend the limit in the future).
  --lon: string # A valid longitude, in decimal format, for doing radial geo queries. Geo queries require some sort of limiting agent in order to prevent the database from crying. This is basically like the check against "parameterless searches" for queries without a geo component. A tag, for instance, is considered a limiting agent as are user defined min_date_taken and min_date_upload parameters — If no limiting factor is passed we return only photos added in the last 12 hours (though we may extend the limit in the future).
  --radius: float # A valid radius used for geo queries, greater than zero and less than 20 miles (or 32 kilometers), for use with point-based geo queries. The default value is 5 (km).
  --radius-units: string # The unit of measure when doing radial geo queries. Valid options are "mi" (miles) and "km" (kilometers). The default is "km".
  --is-commons: oneof<nothing, bool> # Limit the scope of the search to only photos that are part of the Flickr Commons project. Default is false.
  --in-gallery: oneof<nothing, bool> # Limit the scope of the search to only photos that are in a gallery? Default is false, search all photos.
  --is-getty: oneof<nothing, bool> # Limit the scope of the search to only photos that are for sale on Getty. Default is false.
  --per-page: float # Number of photos to return per page. If this argument is omitted, it defaults to 100. The maximum allowed value is 500.
  --page: float # The page of results to return. If this argument is omitted, it defaults to 1.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest"
    fixed_query: "method=flickr.photos.search"
    query: [{name: api_key, var: api_key, required: true}, {name: text, var: text}, {name: tags, var: tags}, {name: user_id, var: user_id}, {name: min_upload_date, var: min_upload_date}, {name: max_upload_date, var: max_upload_date}, {name: min_taken_date, var: min_taken_date}, {name: max_taken_date, var: max_taken_date}, {name: license, var: license}, {name: sort, var: sort}, {name: privacy_filter, var: privacy_filter}, {name: bbox, var: bbox}, {name: accuracy, var: accuracy}, {name: safe_search, var: safe_search}, {name: content_type, var: content_type}, {name: machine_tags, var: machine_tags}, {name: machine_tag_mode, var: machine_tag_mode}, {name: group_id, var: group_id}, {name: contacts, var: contacts}, {name: woe_id, var: woe_id}, {name: place_id, var: place_id}, {name: media, var: media}, {name: has_geo, var: has_geo}, {name: geo_context, var: geo_context}, {name: lat, var: lat}, {name: lon, var: lon}, {name: radius, var: radius}, {name: radius_units, var: radius_units}, {name: is_commons, var: is_commons}, {name: in_gallery, var: in_gallery}, {name: is_getty, var: is_getty}, {name: per_page, var: per_page}, {name: page, var: page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key, text: $text, tags: $tags, user_id: $user_id, min_upload_date: $min_upload_date, max_upload_date: $max_upload_date, min_taken_date: $min_taken_date, max_taken_date: $max_taken_date, license: $license, sort: $sort, privacy_filter: $privacy_filter, bbox: $bbox, accuracy: $accuracy, safe_search: $safe_search, content_type: $content_type, machine_tags: $machine_tags, machine_tag_mode: $machine_tag_mode, group_id: $group_id, contacts: $contacts, woe_id: $woe_id, place_id: $place_id, media: $media, has_geo: $has_geo, geo_context: $geo_context, lat: $lat, lon: $lon, radius: $radius, radius_units: $radius_units, is_commons: $is_commons, in_gallery: $in_gallery, is_getty: $is_getty, per_page: $per_page, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns next and previous photos for a photo in a set
#
# GET /rest?method=flickr.photosets.getContext
# Returns: record<count: record<_content: string>, nextphoto: record<farm: string, id: string, is_faved: bool, license: int, media: string, owner: string, safe: bool, secret: string, server: string, thumb: string, title: string, url: string>, prevphoto: record<farm: string, id: string, is_faved: bool, license: int, media: string, owner: string, safe: bool, secret: string, server: string, thumb: string, title: string, url: string>, stat: string>
# operationId: getAlbumContextByID
export def "get-album-context-by-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # required
  --photo-id: string # required
  --photoset-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest"
    fixed_query: "method=flickr.photosets.getContext"
    query: [{name: api_key, var: api_key, required: true}, {name: photo_id, var: photo_id, required: true}, {name: photoset_id, var: photoset_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key, photo_id: $photo_id, photoset_id: $photoset_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the albums belonging to the specified user
#
# GET /rest?method=flickr.photosets.getList
# Returns: record<page: float, pages: float, perpage: float, photosets: table<can_comment: bool, count_comments: float, count_views: float, date_create: float, date_update: float, description: string, farm: string, id: string, photos: float, primary: string, secret: string, server: string, title: string, videos: float>, total: float>
# operationId: getAlbumsByPersonID
export def "get-albums-by-person-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # required
  --user-id: string # required
  --page: float
  --per-page: float
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest"
    fixed_query: "method=flickr.photosets.getList"
    query: [{name: api_key, var: api_key, required: true}, {name: user_id, var: user_id, required: true}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key, user_id: $user_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of photos in an album.
#
# GET /rest?method=flickr.photosets.getPhotos
# Returns: record<photoset: table<comments: record, dates: record, dateuploaded: string, description: record, editability: record, farm: string, id: string, isfavorite: bool, license: string, media: string, notes: record, originalsecret: string, owner: record, people: record, permissions: record, publiceditability: record, rotation: string, safe: bool, safety_level: string, secret: string, server: string, tags: record, title: record, urls: record, usage: record, views: string, visibility: record>>
# operationId: getAlbumByID
export def "get-album-by-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # required
  --photoset-id: string # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest"
    fixed_query: "method=flickr.photosets.getPhotos"
    query: [{name: api_key, var: api_key, required: true}, {name: photoset_id, var: photoset_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key, photoset_id: $photoset_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Echos the input parameters back in the response
#
# GET /rest?method=flickr.test.echo
# Returns: record<echo: record<_content: string>>
# operationId: echo
export def "get-rest-method-flickr-test-echo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # required
  --echo: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest"
    fixed_query: "method=flickr.test.echo"
    query: [{name: api_key, var: api_key, required: true}, {name: echo, var: echo}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key, echo: $echo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uploads a new photo to Flickr
#
# POST /upload
# Returns: record
# operationId: uploadPhoto
export def "upload-photo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key: string
  --content-type: string@content-type-completer
  --description: string
  --hidden: string@hidden-completer
  --is-family: string@is-family-completer
  --is-friend: string@is-friend-completer
  --is-public: string@is-public-completer
  photo: string # format: binary
  --safety-level: string@safety-level-completer
  --tags: string
  --title: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/upload"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: api_key, var: api_key}, {name: content_type, var: content_type}, {name: description, var: description}, {name: hidden, var: hidden}, {name: is_family, var: is_family}, {name: is_friend, var: is_friend}, {name: is_public, var: is_public}, {name: photo, var: photo}, {name: safety_level, var: safety_level}, {name: tags, var: tags}, {name: title, var: title}], files: [photo]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key, content_type: $content_type, description: $description, hidden: $hidden, is_family: $is_family, is_friend: $is_friend, is_public: $is_public, photo: $photo, safety_level: $safety_level, tags: $tags, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
