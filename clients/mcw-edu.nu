# Auto-generated client for Rat Genome Database REST API v1.1
# Source: https://api.apis.guru/v2/specs/mcw.edu/1.1/openapi.json
# Auth: --token flag or $env.RAT_GENOME_DATABASE_REST_API_TOKEN

const CLIENT = {
  base_url: "http://localhost//rest.rgd.mcw.edu/rgdws"
  token_env_var: "RAT_GENOME_DATABASE_REST_API_TOKEN"
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

def base-url-completer [] { ["http://localhost//rest.rgd.mcw.edu/rgdws"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-affected-genomic-models-using-get: "record"
    get-alleles-for-taxon-using-get: "record"
    get-expression-for-taxon-using-get: "record"
    get-phenotypes-for-taxon-using-get: "record"
    get-variants-for-taxon-using-get: "record"
    get-genes-for-latest-assembly-using-get: "record"
    get-annotations-using-post: "table<annotatedObjectRgdId: int, annotationExtension: string, aspect: string, createdBy: int, createdDate: string, dataSrc: string, evidence: string, geneProductFormId: string, key: int, lastModifiedBy: int, lastModifiedDate: string, notes: string, objectName: string, objectSymbol: string, originalCreatedDate: string, qualifier: string, refRgdId: int, relativeTo: string, rgdObjectKey: int, speciesTypeKey: int, term: string, termAcc: string, withInfo: string, xrefSource: string>"
    get-term-acc-ids-using-get: "table<keyValue: string, stringValue: string>"
    get-annotation-count-by-acc-id-using-get: "int"
    get-annotation-count-by-acc-id-and-species-using-get: "int"
    get-annotation-count-by-acc-id-and-object-type-using-get: "int"
    get-annots-by-refrerence-using-get: "table<annotatedObjectRgdId: int, annotationExtension: string, aspect: string, createdBy: int, createdDate: string, dataSrc: string, evidence: string, geneProductFormId: string, key: int, lastModifiedBy: int, lastModifiedDate: string, notes: string, objectName: string, objectSymbol: string, originalCreatedDate: string, qualifier: string, refRgdId: int, relativeTo: string, rgdObjectKey: int, speciesTypeKey: int, term: string, termAcc: string, withInfo: string, xrefSource: string>"
    get-annotations-by-rgd-id-using-get: "table<annotatedObjectRgdId: int, annotationExtension: string, aspect: string, createdBy: int, createdDate: string, dataSrc: string, evidence: string, geneProductFormId: string, key: int, lastModifiedBy: int, lastModifiedDate: string, notes: string, objectName: string, objectSymbol: string, originalCreatedDate: string, qualifier: string, refRgdId: int, relativeTo: string, rgdObjectKey: int, speciesTypeKey: int, term: string, termAcc: string, withInfo: string, xrefSource: string>"
    get-annotations-by-rgd-id-and-ontology-using-get: "table<annotatedObjectRgdId: int, annotationExtension: string, aspect: string, createdBy: int, createdDate: string, dataSrc: string, evidence: string, geneProductFormId: string, key: int, lastModifiedBy: int, lastModifiedDate: string, notes: string, objectName: string, objectSymbol: string, originalCreatedDate: string, qualifier: string, refRgdId: int, relativeTo: string, rgdObjectKey: int, speciesTypeKey: int, term: string, termAcc: string, withInfo: string, xrefSource: string>"
    get-annotations-by-acc-id-and-rgd-id-using-get: "table<annotatedObjectRgdId: int, annotationExtension: string, aspect: string, createdBy: int, createdDate: string, dataSrc: string, evidence: string, geneProductFormId: string, key: int, lastModifiedBy: int, lastModifiedDate: string, notes: string, objectName: string, objectSymbol: string, originalCreatedDate: string, qualifier: string, refRgdId: int, relativeTo: string, rgdObjectKey: int, speciesTypeKey: int, term: string, termAcc: string, withInfo: string, xrefSource: string>"
    get-annotations-using-get: "table<annotatedObjectRgdId: int, annotationExtension: string, aspect: string, createdBy: int, createdDate: string, dataSrc: string, evidence: string, geneProductFormId: string, key: int, lastModifiedBy: int, lastModifiedDate: string, notes: string, objectName: string, objectSymbol: string, originalCreatedDate: string, qualifier: string, refRgdId: int, relativeTo: string, rgdObjectKey: int, speciesTypeKey: int, term: string, termAcc: string, withInfo: string, xrefSource: string>"
    get-enrichment-data-using-post: "record"
    get-enrichment-data-using-post-1: "record"
    get-genes-by-affy-id-using-get: "table<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool>"
    get-genes-by-alias-symbol-using-get: "table<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool>"
    get-gene-alleles-using-get: "table<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool>"
    get-annotated-genes-using-post: "table<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool>"
    get-all-annotated-genes-using-get: "table<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool>"
    get-genes-annotated-using-get: "table<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool>"
    get-genes-by-keyword-using-get: "table<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool>"
    get-gene-by-map-key-using-get: "table<chromosome: string, gene: record<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool>, mapKey: int, start: int, stop: int, strand: string>"
    get-mapped-genes-by-position-using-get: "table<chromosome: string, gene: record<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool>, mapKey: int, start: int, stop: int, strand: string>"
    get-orthologs-by-list-using-post: "record"
    get-gene-orthologs-using-get: "table<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool>"
    get-genes-in-region-using-get: "table<chromosome: string, mapKey: int, rgdId: int, start: int, stop: int, strand: string, symbol: string>"
    get-genes-by-species-using-get: "table<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool>"
    get-genes-by-position-using-get: "table<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool>"
    get-gene-by-rgd-id-using-get: "record<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool>"
    get-gene-by-symbol-using-get: "record<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool>"
    get-gene-types-using-get: "list<string>"
    get-ensembl-gene-mapping-using-post: "record"
    get-ensembl-gene-mapping-using-get: "record"
    get-ensembl-protein-mapping-using-post: "record"
    get-ensembl-protein-mapping-using-get: "record"
    get-ensembl-transcript-mapping-using-post: "record"
    get-ensembl-transcript-mapping-using-get: "record"
    get-gtex-mapping-using-post: "record"
    get-gtex-mapping-using-get: "record"
    get-gen-bank-nucleotide-mapping-using-post: "record"
    get-gen-bank-nucleotide-mapping-using-get: "record"
    get-gen-bank-protein-mapping-using-post: "record"
    get-gen-bank-protein-mapping-using-get: "record"
    get-hgnc-mapping-using-post: "record"
    get-hgnc-mapping-using-get: "record"
    get-mgi-mapping-using-post: "record"
    get-mgi-mapping-using-get: "record"
    get-ncbi-gene-mapping-using-post: "record"
    get-ncbi-gene-mapping-using-get: "record"
    get-uni-prot-mapping-using-post: "record"
    get-uni-prot-mapping-using-get: "record"
    get-maps-using-get: "table<dbsnpVersion: string, description: string, key: int, methodKey: int, name: string, notes: string, primaryRefAssembly: bool, rank: int, refSeqAssemblyAcc: string, refSeqAssemblyName: string, rgdId: int, source: string, speciesTypeKey: int, ucscAssemblyId: string, unit: string, version: string>"
    get-species-types-using-get: "record"
    get-maps-using-get-1: "string"
    get-chromosome-by-assembly-using-get: "record<chromosome: string, contigCount: int, gapCount: int, gapLength: int, genbankId: string, mapKey: int, ordinalNumber: int, refseqId: string, seqLength: int>"
    get-chromosomes-by-assembly-using-get: "list<string>"
    get-maps-by-species-using-get: "table<dbsnpVersion: string, description: string, key: int, methodKey: int, name: string, notes: string, primaryRefAssembly: bool, rank: int, refSeqAssemblyAcc: string, refSeqAssemblyName: string, rgdId: int, source: string, speciesTypeKey: int, ucscAssemblyId: string, unit: string, version: string>"
    get-ont-dags-using-get: "record"
    is-descendant-of-using-get: "bool"
    get-term-using-get: "record<accId: string, comment: string, createdBy: string, creationDate: string, definition: string, modificationDate: string, obsolete: int, ontologyId: string, term: string, xrefs: table<key: int, termAcc: string, xrefDescription: string, xrefValue: string>>"
    search-pathways-using-get: "table<description: string, hasAlteredPath: string, id: string, name: string, objectList: list<record>, pathwayCategories: list<string>, referenceList: list<record>>"
    get-pathways-with-diagrams-for-category-using-get: "table<description: string, hasAlteredPath: string, id: string, name: string, objectList: list<record>, pathwayCategories: list<string>, referenceList: list<record>>"
    get-chart-info-using-get: "record"
    get-chart-info-using-get-1: "record"
    get-mapped-qtl-by-position-using-get: "table<chromosome: string, mapKey: int, qtl: record<chromosome: string, flank1RgdId: int, flank2RgdId: int, inheritanceType: string, key: int, linkageImage: string, lod: float, lodImage: string, mostSignificantCmoTerm: string, name: string, notes: string, peakOffset: int, peakRgdId: int, pvalue: float, rgdId: int, sourceUrl: string, speciesTypeKey: int, symbol: string, variance: float>, start: int, stop: int, strand: string>"
    get-qtl-list-by-position-using-get: "table<chromosome: string, flank1RgdId: int, flank2RgdId: int, inheritanceType: string, key: int, linkageImage: string, lod: float, lodImage: string, mostSignificantCmoTerm: string, name: string, notes: string, peakOffset: int, peakRgdId: int, pvalue: float, rgdId: int, sourceUrl: string, speciesTypeKey: int, symbol: string, variance: float>"
    get-qtl-by-rgd-id-using-get: "record<chromosome: string, flank1RgdId: int, flank2RgdId: int, inheritanceType: string, key: int, linkageImage: string, lod: float, lodImage: string, mostSignificantCmoTerm: string, name: string, notes: string, peakOffset: int, peakRgdId: int, pvalue: float, rgdId: int, sourceUrl: string, speciesTypeKey: int, symbol: string, variance: float>"
    get-mapped-sslp-by-position-using-get: "table<chromosome: string, mapKey: int, sslp: record<expectedSize: int, forwardSeq: string, key: int, name: string, notes: string, reverseSeq: string, rgdId: int, speciesTypeKey: int, sslpType: string, templateSeq: string>, start: int, stop: int, strand: string>"
    get-active-object-count-using-get: "record"
    get-gene-type-count-using-get: "record"
    get-object-status-count-using-get: "record"
    get-objects-with-ref-seq-count-using-get: "record"
    get-objects-with-reference-count-using-get: "record"
    get-objects-with-xd-bs-count-using-get: "record"
    get-protein-interaction-count-using-get: "record"
    get-qtl-inheritance-type-count-using-get: "record"
    get-retired-object-count-using-get: "record"
    get-strain-type-count-using-get: "record"
    get-withdrawn-object-count-using-get: "record"
    get-xdbs-count-using-get: "record"
    get-active-object-diff-using-get: "record"
    get-gene-type-diff-using-get: "record"
    get-object-status-diff-using-get: "record"
    get-objects-with-ref-seq-diff-using-get: "record"
    get-objects-with-reference-diff-using-get: "record"
    get-objects-with-xd-bs-diff-using-get: "record"
    get-protein-interaction-diff-using-get: "record"
    get-qtl-inheritance-type-diff-using-get: "record"
    get-retired-object-diff-using-get: "record"
    get-strain-type-diff-using-get: "record"
    get-withdrawn-object-diff-using-get: "record"
    get-xdbs-diff-using-get: "record"
    get-term-stats-using-get: "record"
    get-all-strains-using-get: "table<backgroundStrainRgdId: int, chrAltered: string, color: string, geneticStatus: string, genetics: string, imageUrl: string, inbredGen: string, key: int, lastStatus: string, lastStatusObject: record<cryopreservedEmbryo: bool, cryopreservedSperm: bool, cryorecovery: bool, key: int, liveAnimals: bool, statusDate: string, strainRgdId: int>, modificationMethod: string, name: string, notes: string, origin: string, researchUse: string, rgdId: int, source: string, speciesTypeKey: int, statusLog: list<record>, strain: string, strainTypeName: string, substrain: string, symbol: string>"
    get-strains-by-position-using-get: "table<backgroundStrainRgdId: int, chrAltered: string, color: string, geneticStatus: string, genetics: string, imageUrl: string, inbredGen: string, key: int, lastStatus: string, lastStatusObject: record<cryopreservedEmbryo: bool, cryopreservedSperm: bool, cryorecovery: bool, key: int, liveAnimals: bool, statusDate: string, strainRgdId: int>, modificationMethod: string, name: string, notes: string, origin: string, researchUse: string, rgdId: int, source: string, speciesTypeKey: int, statusLog: list<record>, strain: string, strainTypeName: string, substrain: string, symbol: string>"
    get-strain-by-rgd-id-using-get: "record<backgroundStrainRgdId: int, chrAltered: string, color: string, geneticStatus: string, genetics: string, imageUrl: string, inbredGen: string, key: int, lastStatus: string, lastStatusObject: record<cryopreservedEmbryo: bool, cryopreservedSperm: bool, cryorecovery: bool, key: int, liveAnimals: bool, statusDate: string, strainRgdId: int>, modificationMethod: string, name: string, notes: string, origin: string, researchUse: string, rgdId: int, source: string, speciesTypeKey: int, statusLog: table<cryopreservedEmbryo: bool, cryopreservedSperm: bool, cryorecovery: bool, key: int, liveAnimals: bool, statusDate: string, strainRgdId: int>, strain: string, strainTypeName: string, substrain: string, symbol: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-affected-genomic-models-using-get" "get-alleles-for-taxon-using-get" "get-expression-for-taxon-using-get" "get-phenotypes-for-taxon-using-get" "get-variants-for-taxon-using-get" "get-genes-for-latest-assembly-using-get" "get-annotations-using-post" "get-term-acc-ids-using-get" "get-annotation-count-by-acc-id-using-get" "get-annotation-count-by-acc-id-and-species-using-get" "get-annotation-count-by-acc-id-and-object-type-using-get" "get-annots-by-refrerence-using-get" "get-annotations-by-rgd-id-using-get" "get-annotations-by-rgd-id-and-ontology-using-get" "get-annotations-by-acc-id-and-rgd-id-using-get" "get-annotations-using-get" "get-enrichment-data-using-post" "get-enrichment-data-using-post-1" "get-genes-by-affy-id-using-get" "get-genes-by-alias-symbol-using-get" "get-gene-alleles-using-get" "get-annotated-genes-using-post" "get-all-annotated-genes-using-get" "get-genes-annotated-using-get" "get-genes-by-keyword-using-get" "get-gene-by-map-key-using-get" "get-mapped-genes-by-position-using-get" "get-orthologs-by-list-using-post" "get-gene-orthologs-using-get" "get-genes-in-region-using-get" "get-genes-by-species-using-get" "get-genes-by-position-using-get" "get-gene-by-rgd-id-using-get" "get-gene-by-symbol-using-get" "get-gene-types-using-get" "get-ensembl-gene-mapping-using-post" "get-ensembl-gene-mapping-using-get" "get-ensembl-protein-mapping-using-post" "get-ensembl-protein-mapping-using-get" "get-ensembl-transcript-mapping-using-post" "get-ensembl-transcript-mapping-using-get" "get-gtex-mapping-using-post" "get-gtex-mapping-using-get" "get-gen-bank-nucleotide-mapping-using-post" "get-gen-bank-nucleotide-mapping-using-get" "get-gen-bank-protein-mapping-using-post" "get-gen-bank-protein-mapping-using-get" "get-hgnc-mapping-using-post" "get-hgnc-mapping-using-get" "get-mgi-mapping-using-post" "get-mgi-mapping-using-get" "get-ncbi-gene-mapping-using-post" "get-ncbi-gene-mapping-using-get" "get-uni-prot-mapping-using-post" "get-uni-prot-mapping-using-get" "get-maps-using-get" "get-species-types-using-get" "get-maps-using-get-1" "get-chromosome-by-assembly-using-get" "get-chromosomes-by-assembly-using-get" "get-maps-by-species-using-get" "get-ont-dags-using-get" "is-descendant-of-using-get" "get-term-using-get" "search-pathways-using-get" "get-pathways-with-diagrams-for-category-using-get" "get-chart-info-using-get" "get-chart-info-using-get-1" "get-mapped-qtl-by-position-using-get" "get-qtl-list-by-position-using-get" "get-qtl-by-rgd-id-using-get" "get-mapped-sslp-by-position-using-get" "get-active-object-count-using-get" "get-gene-type-count-using-get" "get-object-status-count-using-get" "get-objects-with-ref-seq-count-using-get" "get-objects-with-reference-count-using-get" "get-objects-with-xd-bs-count-using-get" "get-protein-interaction-count-using-get" "get-qtl-inheritance-type-count-using-get" "get-retired-object-count-using-get" "get-strain-type-count-using-get" "get-withdrawn-object-count-using-get" "get-xdbs-count-using-get" "get-active-object-diff-using-get" "get-gene-type-diff-using-get" "get-object-status-diff-using-get" "get-objects-with-ref-seq-diff-using-get" "get-objects-with-reference-diff-using-get" "get-objects-with-xd-bs-diff-using-get" "get-protein-interaction-diff-using-get" "get-qtl-inheritance-type-diff-using-get" "get-retired-object-diff-using-get" "get-strain-type-diff-using-get" "get-withdrawn-object-diff-using-get" "get-xdbs-diff-using-get" "get-term-stats-using-get" "get-all-strains-using-get" "get-strains-by-position-using-get" "get-strain-by-rgd-id-using-get" "commands"] | sort) } | get name | first)
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

# Get affected genomic models (rat strains with gene alleles) submitted by RGD to AGR by taxonId
#
# GET /agr/affectedGenomicModels/{taxonId}
# Returns: record
# operationId: getAffectedGenomicModelsUsingGET
export def "get-affected-genomic-models-using-get" [
  taxon_id: string
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
    path: "/agr/affectedGenomicModels/{taxonId}"
    path_params: [{name: taxonId, var: taxon_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    taxon_id: $taxon_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get gene allele records submitted by RGD to AGR by taxonId
#
# GET /agr/alleles/{taxonId}
# Returns: record
# operationId: getAllelesForTaxonUsingGET
export def "get-alleles-for-taxon-using-get" [
  taxon_id: string
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
    path: "/agr/alleles/{taxonId}"
    path_params: [{name: taxonId, var: taxon_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    taxon_id: $taxon_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get expression annotations submitted by RGD to AGR by taxonId
#
# GET /agr/expression/{taxonId}
# Returns: record
# operationId: getExpressionForTaxonUsingGET
export def "get-expression-for-taxon-using-get" [
  taxon_id: string
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
    path: "/agr/expression/{taxonId}"
    path_params: [{name: taxonId, var: taxon_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    taxon_id: $taxon_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get phenotype annotations submitted by RGD to AGR by taxonId
#
# GET /agr/phenotypes/{taxonId}
# Returns: record
# operationId: getPhenotypesForTaxonUsingGET
export def "get-phenotypes-for-taxon-using-get" [
  taxon_id: string
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
    path: "/agr/phenotypes/{taxonId}"
    path_params: [{name: taxonId, var: taxon_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    taxon_id: $taxon_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get basic variant records submitted by RGD to AGR by taxonId
#
# GET /agr/variants/{taxonId}
# Returns: record
# operationId: getVariantsForTaxonUsingGET
export def "get-variants-for-taxon-using-get" [
  taxon_id: string
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
    path: "/agr/variants/{taxonId}"
    path_params: [{name: taxonId, var: taxon_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    taxon_id: $taxon_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get gene records submitted by RGD to AGR by taxonId
#
# GET /agr/{taxonId}
# Returns: record
# operationId: getGenesForLatestAssemblyUsingGET
export def "get-genes-for-latest-assembly-using-get" [
  taxon_id: string
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
    path: "/agr/{taxonId}"
    path_params: [{name: taxonId, var: taxon_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    taxon_id: $taxon_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of genes annotated to an ontology term
#
# POST /annotations/
# Returns: table<annotatedObjectRgdId: int, annotationExtension: string, aspect: string, createdBy: int, createdDate: string, dataSrc: string, evidence: string, geneProductFormId: string, key: int, lastModifiedBy: int, lastModifiedDate: string, notes: string, objectName: string, objectSymbol: string, originalCreatedDate: string, qualifier: string, refRgdId: int, relativeTo: string, rgdObjectKey: int, speciesTypeKey: int, term: string, termAcc: string, withInfo: string, xrefSource: string>
# operationId: getAnnotationsUsingPOST
export def "get-annotations-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --evidence-codes: list<string>
  --ids: list<string>
  --species-type-keys: list<int>
  --term-acc: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/annotations/"
    body: {content_type: "application/json", kind: json, fields: [{name: evidenceCodes, var: evidence_codes}, {name: ids, var: ids}, {name: speciesTypeKeys, var: species_type_keys}, {name: termAcc, var: term_acc}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    evidence_codes: $evidence_codes, ids: $ids, species_type_keys: $species_type_keys, term_acc: $term_acc
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list ontology term accession IDs annotated to an rgd object
#
# GET /annotations/accId/{rgdId}
# Returns: table<keyValue: string, stringValue: string>
# operationId: getTermAccIdsUsingGET
export def "get-term-acc-ids-using-get" [
  rgd_id: int
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
    path: "/annotations/accId/{rgdId}"
    path_params: [{name: rgdId, var: rgd_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    rgd_id: $rgd_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns annotation count for ontology accession ID
#
# GET /annotations/count/{accId}/{includeChildren}
# Returns: int
# operationId: getAnnotationCountByAccIdUsingGET
export def "get-annotation-count-by-acc-id-using-get" [
  acc_id: string
  include_children: bool
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
    method: get
    path: "/annotations/count/{accId}/{includeChildren}"
    path_params: [{name: accId, var: acc_id}, {name: includeChildren, var: include_children}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    acc_id: $acc_id, include_children: $include_children
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns annotation count for ontology accession ID and speicies
#
# GET /annotations/count/{accId}/{speciesTypeKey}/{includeChildren}
# Returns: int
# operationId: getAnnotationCountByAccIdAndSpeciesUsingGET
export def "get-annotation-count-by-acc-id-and-species-using-get" [
  acc_id: string
  species_type_key: int
  include_children: bool
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
    method: get
    path: "/annotations/count/{accId}/{speciesTypeKey}/{includeChildren}"
    path_params: [{name: accId, var: acc_id}, {name: speciesTypeKey, var: species_type_key}, {name: includeChildren, var: include_children}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    acc_id: $acc_id, species_type_key: $species_type_key, include_children: $include_children
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns annotation count for ontology accession ID and object type
#
# GET /annotations/count/{accId}/{speciesTypeKey}/{includeChildren}/{objectType}
# Returns: int
# operationId: getAnnotationCountByAccIdAndObjectTypeUsingGET
export def "get-annotation-count-by-acc-id-and-object-type-using-get" [
  acc_id: string
  species_type_key: int
  include_children: bool
  object_type: int
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
    method: get
    path: "/annotations/count/{accId}/{speciesTypeKey}/{includeChildren}/{objectType}"
    path_params: [{name: accId, var: acc_id}, {name: speciesTypeKey, var: species_type_key}, {name: includeChildren, var: include_children}, {name: objectType, var: object_type}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    acc_id: $acc_id, species_type_key: $species_type_key, include_children: $include_children, object_type: $object_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of annotations for a reference
#
# GET /annotations/reference/{refRgdId}
# Returns: table<annotatedObjectRgdId: int, annotationExtension: string, aspect: string, createdBy: int, createdDate: string, dataSrc: string, evidence: string, geneProductFormId: string, key: int, lastModifiedBy: int, lastModifiedDate: string, notes: string, objectName: string, objectSymbol: string, originalCreatedDate: string, qualifier: string, refRgdId: int, relativeTo: string, rgdObjectKey: int, speciesTypeKey: int, term: string, termAcc: string, withInfo: string, xrefSource: string>
# operationId: getAnnotsByRefrerenceUsingGET
export def "get-annots-by-refrerence-using-get" [
  ref_rgd_id: int
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
    path: "/annotations/reference/{refRgdId}"
    path_params: [{name: refRgdId, var: ref_rgd_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    ref_rgd_id: $ref_rgd_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of annotations by RGD ID
#
# GET /annotations/rgdId/{rgdId}
# Returns: table<annotatedObjectRgdId: int, annotationExtension: string, aspect: string, createdBy: int, createdDate: string, dataSrc: string, evidence: string, geneProductFormId: string, key: int, lastModifiedBy: int, lastModifiedDate: string, notes: string, objectName: string, objectSymbol: string, originalCreatedDate: string, qualifier: string, refRgdId: int, relativeTo: string, rgdObjectKey: int, speciesTypeKey: int, term: string, termAcc: string, withInfo: string, xrefSource: string>
# operationId: getAnnotationsByRgdIdUsingGET
export def "get-annotations-by-rgd-id-using-get" [
  rgd_id: int
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
    path: "/annotations/rgdId/{rgdId}"
    path_params: [{name: rgdId, var: rgd_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    rgd_id: $rgd_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of annotations by RGD ID and ontology prefix
#
# GET /annotations/rgdId/{rgdId}/{ontologyPrefix}
# Returns: table<annotatedObjectRgdId: int, annotationExtension: string, aspect: string, createdBy: int, createdDate: string, dataSrc: string, evidence: string, geneProductFormId: string, key: int, lastModifiedBy: int, lastModifiedDate: string, notes: string, objectName: string, objectSymbol: string, originalCreatedDate: string, qualifier: string, refRgdId: int, relativeTo: string, rgdObjectKey: int, speciesTypeKey: int, term: string, termAcc: string, withInfo: string, xrefSource: string>
# operationId: getAnnotationsByRgdIdAndOntologyUsingGET
export def "get-annotations-by-rgd-id-and-ontology-using-get" [
  rgd_id: int
  ontology_prefix: string
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
    path: "/annotations/rgdId/{rgdId}/{ontologyPrefix}"
    path_params: [{name: rgdId, var: rgd_id}, {name: ontologyPrefix, var: ontology_prefix}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    rgd_id: $rgd_id, ontology_prefix: $ontology_prefix
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of annotations by RGD ID and ontology term accession ID
#
# GET /annotations/{accId}/{rgdId}
# Returns: table<annotatedObjectRgdId: int, annotationExtension: string, aspect: string, createdBy: int, createdDate: string, dataSrc: string, evidence: string, geneProductFormId: string, key: int, lastModifiedBy: int, lastModifiedDate: string, notes: string, objectName: string, objectSymbol: string, originalCreatedDate: string, qualifier: string, refRgdId: int, relativeTo: string, rgdObjectKey: int, speciesTypeKey: int, term: string, termAcc: string, withInfo: string, xrefSource: string>
# operationId: getAnnotationsByAccIdAndRgdIdUsingGET
export def "get-annotations-by-acc-id-and-rgd-id-using-get" [
  acc_id: string
  rgd_id: int
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
    path: "/annotations/{accId}/{rgdId}"
    path_params: [{name: accId, var: acc_id}, {name: rgdId, var: rgd_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    acc_id: $acc_id, rgd_id: $rgd_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list annotations for an ontology term or a term and it's children
#
# GET /annotations/{accId}/{speciesTypeKey}/{includeChildren}
# Returns: table<annotatedObjectRgdId: int, annotationExtension: string, aspect: string, createdBy: int, createdDate: string, dataSrc: string, evidence: string, geneProductFormId: string, key: int, lastModifiedBy: int, lastModifiedDate: string, notes: string, objectName: string, objectSymbol: string, originalCreatedDate: string, qualifier: string, refRgdId: int, relativeTo: string, rgdObjectKey: int, speciesTypeKey: int, term: string, termAcc: string, withInfo: string, xrefSource: string>
# operationId: getAnnotationsUsingGET
export def "get-annotations-using-get" [
  acc_id: string
  species_type_key: int
  include_children: bool
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
    path: "/annotations/{accId}/{speciesTypeKey}/{includeChildren}"
    path_params: [{name: accId, var: acc_id}, {name: speciesTypeKey, var: species_type_key}, {name: includeChildren, var: include_children}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    acc_id: $acc_id, species_type_key: $species_type_key, include_children: $include_children
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of genes annotated to the term.Genes are rgdids separated by comma.Species type is an integer value.term is the ontology
#
# POST /enrichment/annotatedGenes
# Returns: record
# operationId: getEnrichmentDataUsingPOST
export def "get-enrichment-data-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --acc-id: string
  --gene-symbols: list<string>
  --species: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/enrichment/annotatedGenes"
    body: {content_type: "application/json", kind: json, fields: [{name: accId, var: acc_id}, {name: geneSymbols, var: gene_symbols}, {name: species, var: species}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    acc_id: $acc_id, gene_symbols: $gene_symbols, species: $species
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a chart of ontology terms annotated to the genes.Genes are rgdids separated by comma.Species type is an integer value.Aspect is the Ontology group
#
# POST /enrichment/data
# Returns: record
# operationId: getEnrichmentDataUsingPOST_1
export def "get-enrichment-data-using-post-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aspect: string
  --genes: list<string>
  --species: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/enrichment/data"
    body: {content_type: "application/json", kind: json, fields: [{name: aspect, var: aspect}, {name: genes, var: genes}, {name: species, var: species}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    aspect: $aspect, genes: $genes, species: $species
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of genes for an affymetrix ID
#
# GET /genes/affyId/{affyId}/{speciesTypeKey}
# Returns: table<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool>
# operationId: getGenesByAffyIdUsingGET
export def "get-genes-by-affy-id-using-get" [
  affy_id: string
  species_type_key: int
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
    path: "/genes/affyId/{affyId}/{speciesTypeKey}"
    path_params: [{name: affyId, var: affy_id}, {name: speciesTypeKey, var: species_type_key}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    affy_id: $affy_id, species_type_key: $species_type_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of genes for an alias and species
#
# GET /genes/alias/{aliasSymbol}/{speciesTypeKey}
# Returns: table<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool>
# operationId: getGenesByAliasSymbolUsingGET
export def "get-genes-by-alias-symbol-using-get" [
  alias_symbol: string
  species_type_key: int
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
    path: "/genes/alias/{aliasSymbol}/{speciesTypeKey}"
    path_params: [{name: aliasSymbol, var: alias_symbol}, {name: speciesTypeKey, var: species_type_key}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    alias_symbol: $alias_symbol, species_type_key: $species_type_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of gene alleles
#
# GET /genes/allele/{rgdId}
# Returns: table<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool>
# operationId: getGeneAllelesUsingGET
export def "get-gene-alleles-using-get" [
  rgd_id: int
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
    path: "/genes/allele/{rgdId}"
    path_params: [{name: rgdId, var: rgd_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    rgd_id: $rgd_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of genes annotated to an ontology term
#
# POST /genes/annotation
# Returns: table<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool>
# operationId: getAnnotatedGenesUsingPOST
export def "get-annotated-genes-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --acc-id: string
  --evidence-codes: list<string>
  --species-type-keys: list<int>
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/genes/annotation"
    body: {content_type: "application/json", kind: json, fields: [{name: accId, var: acc_id}, {name: evidenceCodes, var: evidence_codes}, {name: speciesTypeKeys, var: species_type_keys}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    acc_id: $acc_id, evidence_codes: $evidence_codes, species_type_keys: $species_type_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of genes annotated to an ontology term
#
# GET /genes/annotation/{accId}
# Returns: table<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool>
# operationId: getAllAnnotatedGenesUsingGET
export def "get-all-annotated-genes-using-get" [
  acc_id: string
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
    path: "/genes/annotation/{accId}"
    path_params: [{name: accId, var: acc_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    acc_id: $acc_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of genes annotated to an ontology term
#
# GET /genes/annotation/{accId}/{speciesTypeKey}
# Returns: table<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool>
# operationId: getGenesAnnotatedUsingGET
export def "get-genes-annotated-using-get" [
  acc_id: string
  species_type_key: int
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
    path: "/genes/annotation/{accId}/{speciesTypeKey}"
    path_params: [{name: accId, var: acc_id}, {name: speciesTypeKey, var: species_type_key}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    acc_id: $acc_id, species_type_key: $species_type_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of genes by keyword and species type key
#
# GET /genes/keyword/{keyword}/{speciesTypeKey}
# Returns: table<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool>
# operationId: getGenesByKeywordUsingGET
export def "get-genes-by-keyword-using-get" [
  keyword: string
  species_type_key: int
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
    path: "/genes/keyword/{keyword}/{speciesTypeKey}"
    path_params: [{name: keyword, var: keyword}, {name: speciesTypeKey, var: species_type_key}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    keyword: $keyword, species_type_key: $species_type_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of all genes with position information for an assembly
#
# GET /genes/map/{mapKey}
# Returns: table<chromosome: string, gene: record<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool>, mapKey: int, start: int, stop: int, strand: string>
# operationId: getGeneByMapKeyUsingGET
export def "get-gene-by-map-key-using-get" [
  map_key: int
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
    path: "/genes/map/{mapKey}"
    path_params: [{name: mapKey, var: map_key}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    map_key: $map_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of genes position and map key
#
# GET /genes/mapped/{chr}/{start}/{stop}/{mapKey}
# Returns: table<chromosome: string, gene: record<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool>, mapKey: int, start: int, stop: int, strand: string>
# operationId: getMappedGenesByPositionUsingGET
export def "get-mapped-genes-by-position-using-get" [
  chr: string
  start: int
  stop: int
  map_key: int
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
    path: "/genes/mapped/{chr}/{start}/{stop}/{mapKey}"
    path_params: [{name: chr, var: chr}, {name: start, var: start}, {name: stop, var: stop}, {name: mapKey, var: map_key}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    chr: $chr, start: $start, stop: $stop, map_key: $map_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of gene orthologs
#
# POST /genes/orthologs
# Returns: record
# operationId: getOrthologsByListUsingPOST
export def "get-orthologs-by-list-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
  --species-type-keys: list<int>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/genes/orthologs"
    body: {content_type: "application/json", kind: json, fields: [{name: rgdIds, var: rgd_ids}, {name: speciesTypeKeys, var: species_type_keys}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    rgd_ids: $rgd_ids, species_type_keys: $species_type_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of gene orthologs
#
# GET /genes/orthologs/{rgdId}
# Returns: table<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool>
# operationId: getGeneOrthologsUsingGET
export def "get-gene-orthologs-using-get" [
  rgd_id: int
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
    path: "/genes/orthologs/{rgdId}"
    path_params: [{name: rgdId, var: rgd_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    rgd_id: $rgd_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of genes in region
#
# GET /genes/region/{chr}/{start}/{stop}/{mapKey}
# Returns: table<chromosome: string, mapKey: int, rgdId: int, start: int, stop: int, strand: string, symbol: string>
# operationId: getGenesInRegionUsingGET
export def "get-genes-in-region-using-get" [
  chr: string
  start: int
  stop: int
  map_key: int
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
    path: "/genes/region/{chr}/{start}/{stop}/{mapKey}"
    path_params: [{name: chr, var: chr}, {name: start, var: start}, {name: stop, var: stop}, {name: mapKey, var: map_key}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    chr: $chr, start: $start, stop: $stop, map_key: $map_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of all genes for a species in RGD
#
# GET /genes/species/{speciesTypeKey}
# Returns: table<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool>
# operationId: getGenesBySpeciesUsingGET
export def "get-genes-by-species-using-get" [
  species_type_key: int
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
    path: "/genes/species/{speciesTypeKey}"
    path_params: [{name: speciesTypeKey, var: species_type_key}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    species_type_key: $species_type_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of genes position and map key
#
# GET /genes/{chr}/{start}/{stop}/{mapKey}
# Returns: table<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool>
# operationId: getGenesByPositionUsingGET
export def "get-genes-by-position-using-get" [
  chr: string
  start: int
  stop: int
  map_key: int
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
    path: "/genes/{chr}/{start}/{stop}/{mapKey}"
    path_params: [{name: chr, var: chr}, {name: start, var: start}, {name: stop, var: stop}, {name: mapKey, var: map_key}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    chr: $chr, start: $start, stop: $stop, map_key: $map_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a gene record by RGD ID
#
# GET /genes/{rgdId}
# Returns: record<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool>
# operationId: getGeneByRgdIdUsingGET
export def "get-gene-by-rgd-id-using-get" [
  rgd_id: int
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
    path: "/genes/{rgdId}"
    path_params: [{name: rgdId, var: rgd_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    rgd_id: $rgd_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a gene record by symbol and species type key
#
# GET /genes/{symbol}/{speciesTypeKey}
# Returns: record<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool>
# operationId: getGeneBySymbolUsingGET
export def "get-gene-by-symbol-using-get" [
  symbol: string
  species_type_key: int
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
    path: "/genes/{symbol}/{speciesTypeKey}"
    path_params: [{name: symbol, var: symbol}, {name: speciesTypeKey, var: species_type_key}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    symbol: $symbol, species_type_key: $species_type_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of gene types avialable in RGD
#
# GET /lookup/geneTypes
# Returns: list<string>
# operationId: getGeneTypesUsingGET
export def "get-gene-types-using-get" [
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
    path: "/lookup/geneTypes"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Translate RGD IDs to Ensembl Gene IDs
#
# POST /lookup/id/map/EnsemblGene
# Returns: record
# operationId: getEnsemblGeneMappingUsingPOST
export def "get-ensembl-gene-mapping-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/lookup/id/map/EnsemblGene"
    body: {content_type: "application/json", kind: json, fields: [{name: rgdIds, var: rgd_ids}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    rgd_ids: $rgd_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Translate an RGD ID to an Ensembl Gene ID
#
# GET /lookup/id/map/EnsemblGene/{rgdId}
# Returns: record
# operationId: getEnsemblGeneMappingUsingGET
export def "get-ensembl-gene-mapping-using-get" [
  rgd_id: int
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
    path: "/lookup/id/map/EnsemblGene/{rgdId}"
    path_params: [{name: rgdId, var: rgd_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    rgd_id: $rgd_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Translate RGD IDs to Ensembl Protein IDs
#
# POST /lookup/id/map/EnsemblProtein
# Returns: record
# operationId: getEnsemblProteinMappingUsingPOST
export def "get-ensembl-protein-mapping-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/lookup/id/map/EnsemblProtein"
    body: {content_type: "application/json", kind: json, fields: [{name: rgdIds, var: rgd_ids}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    rgd_ids: $rgd_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Translate an RGD ID to an Ensembl Protein ID
#
# GET /lookup/id/map/EnsemblProtein/{rgdId}
# Returns: record
# operationId: getEnsemblProteinMappingUsingGET
export def "get-ensembl-protein-mapping-using-get" [
  rgd_id: int
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
    path: "/lookup/id/map/EnsemblProtein/{rgdId}"
    path_params: [{name: rgdId, var: rgd_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    rgd_id: $rgd_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Translate RGD IDs to Ensembl Transcript IDs
#
# POST /lookup/id/map/EnsemblTranscript
# Returns: record
# operationId: getEnsemblTranscriptMappingUsingPOST
export def "get-ensembl-transcript-mapping-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/lookup/id/map/EnsemblTranscript"
    body: {content_type: "application/json", kind: json, fields: [{name: rgdIds, var: rgd_ids}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    rgd_ids: $rgd_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Translate an RGD ID to an Ensembl Transcript ID
#
# GET /lookup/id/map/EnsemblTranscript/{rgdId}
# Returns: record
# operationId: getEnsemblTranscriptMappingUsingGET
export def "get-ensembl-transcript-mapping-using-get" [
  rgd_id: int
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
    path: "/lookup/id/map/EnsemblTranscript/{rgdId}"
    path_params: [{name: rgdId, var: rgd_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    rgd_id: $rgd_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Translate RGD IDs to GTEx IDs
#
# POST /lookup/id/map/GTEx
# Returns: record
# operationId: getGTEXMappingUsingPOST
export def "get-gtex-mapping-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/lookup/id/map/GTEx"
    body: {content_type: "application/json", kind: json, fields: [{name: rgdIds, var: rgd_ids}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    rgd_ids: $rgd_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Translate an RGD ID to an GTEx ID
#
# GET /lookup/id/map/GTEx/{rgdId}
# Returns: record
# operationId: getGTEXMappingUsingGET
export def "get-gtex-mapping-using-get" [
  rgd_id: int
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
    path: "/lookup/id/map/GTEx/{rgdId}"
    path_params: [{name: rgdId, var: rgd_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    rgd_id: $rgd_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Translate RGD IDs to GenBank Nucleotide IDs
#
# POST /lookup/id/map/GenBankNucleotide
# Returns: record
# operationId: getGenBankNucleotideMappingUsingPOST
export def "get-gen-bank-nucleotide-mapping-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/lookup/id/map/GenBankNucleotide"
    body: {content_type: "application/json", kind: json, fields: [{name: rgdIds, var: rgd_ids}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    rgd_ids: $rgd_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Translate an RGD ID to a GenBank Nucleotide ID
#
# GET /lookup/id/map/GenBankNucleotide/{rgdId}
# Returns: record
# operationId: getGenBankNucleotideMappingUsingGET
export def "get-gen-bank-nucleotide-mapping-using-get" [
  rgd_id: int
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
    path: "/lookup/id/map/GenBankNucleotide/{rgdId}"
    path_params: [{name: rgdId, var: rgd_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    rgd_id: $rgd_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Translate RGD IDs to GenBank Protein IDs
#
# POST /lookup/id/map/GenBankProtein
# Returns: record
# operationId: getGenBankProteinMappingUsingPOST
export def "get-gen-bank-protein-mapping-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/lookup/id/map/GenBankProtein"
    body: {content_type: "application/json", kind: json, fields: [{name: rgdIds, var: rgd_ids}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    rgd_ids: $rgd_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Translate an RGD ID to a GenBank Protein ID
#
# GET /lookup/id/map/GenBankProtein/{rgdId}
# Returns: record
# operationId: getGenBankProteinMappingUsingGET
export def "get-gen-bank-protein-mapping-using-get" [
  rgd_id: int
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
    path: "/lookup/id/map/GenBankProtein/{rgdId}"
    path_params: [{name: rgdId, var: rgd_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    rgd_id: $rgd_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Translate RGD IDs to HGNC IDs
#
# POST /lookup/id/map/HGNC
# Returns: record
# operationId: getHGNCMappingUsingPOST
export def "get-hgnc-mapping-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/lookup/id/map/HGNC"
    body: {content_type: "application/json", kind: json, fields: [{name: rgdIds, var: rgd_ids}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    rgd_ids: $rgd_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Translate an RGD ID to an HGNC ID
#
# GET /lookup/id/map/HGNC/{rgdId}
# Returns: record
# operationId: getHGNCMappingUsingGET
export def "get-hgnc-mapping-using-get" [
  rgd_id: int
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
    path: "/lookup/id/map/HGNC/{rgdId}"
    path_params: [{name: rgdId, var: rgd_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    rgd_id: $rgd_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Translate RGD IDs to MGI IDs
#
# POST /lookup/id/map/MGI
# Returns: record
# operationId: getMGIMappingUsingPOST
export def "get-mgi-mapping-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/lookup/id/map/MGI"
    body: {content_type: "application/json", kind: json, fields: [{name: rgdIds, var: rgd_ids}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    rgd_ids: $rgd_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Translate an RGD ID to an MGI ID
#
# GET /lookup/id/map/MGI/{rgdId}
# Returns: record
# operationId: getMGIMappingUsingGET
export def "get-mgi-mapping-using-get" [
  rgd_id: int
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
    path: "/lookup/id/map/MGI/{rgdId}"
    path_params: [{name: rgdId, var: rgd_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    rgd_id: $rgd_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Translate RGD IDs to NCBI Gene IDs
#
# POST /lookup/id/map/NCBIGene
# Returns: record
# operationId: getNCBIGeneMappingUsingPOST
export def "get-ncbi-gene-mapping-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/lookup/id/map/NCBIGene"
    body: {content_type: "application/json", kind: json, fields: [{name: rgdIds, var: rgd_ids}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    rgd_ids: $rgd_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Translate an RGD ID to an NCBI Gene ID
#
# GET /lookup/id/map/NCBIGene/{rgdId}
# Returns: record
# operationId: getNCBIGeneMappingUsingGET
export def "get-ncbi-gene-mapping-using-get" [
  rgd_id: int
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
    path: "/lookup/id/map/NCBIGene/{rgdId}"
    path_params: [{name: rgdId, var: rgd_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    rgd_id: $rgd_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Translate RGD IDs to UniProt IDs
#
# POST /lookup/id/map/UniProt
# Returns: record
# operationId: getUniProtMappingUsingPOST
export def "get-uni-prot-mapping-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/lookup/id/map/UniProt"
    body: {content_type: "application/json", kind: json, fields: [{name: rgdIds, var: rgd_ids}]}
    accept: ["*/*"]
    ok: [200, 201]
    auth: bearer
  } {
    rgd_ids: $rgd_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Translate an RGD ID to a UniProt ID
#
# GET /lookup/id/map/UniProt/{rgdId}
# Returns: record
# operationId: getUniProtMappingUsingGET
export def "get-uni-prot-mapping-using-get" [
  rgd_id: int
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
    path: "/lookup/id/map/UniProt/{rgdId}"
    path_params: [{name: rgdId, var: rgd_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    rgd_id: $rgd_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list assembly maps for a species
#
# GET /lookup/maps/{speciesTypeKey}
# Returns: table<dbsnpVersion: string, description: string, key: int, methodKey: int, name: string, notes: string, primaryRefAssembly: bool, rank: int, refSeqAssemblyAcc: string, refSeqAssemblyName: string, rgdId: int, source: string, speciesTypeKey: int, ucscAssemblyId: string, unit: string, version: string>
# operationId: getMapsUsingGET
export def "get-maps-using-get" [
  species_type_key: int
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
    path: "/lookup/maps/{speciesTypeKey}"
    path_params: [{name: speciesTypeKey, var: species_type_key}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    species_type_key: $species_type_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a Map of species type keys available in RGD
#
# GET /lookup/speciesTypeKeys
# Returns: record
# operationId: getSpeciesTypesUsingGET
export def "get-species-types-using-get" [
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
    path: "/lookup/speciesTypeKeys"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a standardUnit for an ontology if it exists
#
# GET /lookup/standardUnit/{accId}
# Returns: string
# operationId: getMapsUsingGET_1
export def "get-maps-using-get-1" [
  acc_id: string
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
    method: get
    path: "/lookup/standardUnit/{accId}"
    path_params: [{name: accId, var: acc_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    acc_id: $acc_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of chromosomes
#
# GET /maps/chr/{chromosome}/{mapKey}
# Returns: record<chromosome: string, contigCount: int, gapCount: int, gapLength: int, genbankId: string, mapKey: int, ordinalNumber: int, refseqId: string, seqLength: int>
# operationId: getChromosomeByAssemblyUsingGET
export def "get-chromosome-by-assembly-using-get" [
  chromosome: string
  map_key: int
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
    path: "/maps/chr/{chromosome}/{mapKey}"
    path_params: [{name: chromosome, var: chromosome}, {name: mapKey, var: map_key}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    chromosome: $chromosome, map_key: $map_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of chromosomes
#
# GET /maps/chr/{mapKey}
# Returns: list<string>
# operationId: getChromosomesByAssemblyUsingGET
export def "get-chromosomes-by-assembly-using-get" [
  map_key: int
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
    path: "/maps/chr/{mapKey}"
    path_params: [{name: mapKey, var: map_key}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    map_key: $map_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of assemblies
#
# GET /maps/{speciesTypeKey}
# Returns: table<dbsnpVersion: string, description: string, key: int, methodKey: int, name: string, notes: string, primaryRefAssembly: bool, rank: int, refSeqAssemblyAcc: string, refSeqAssemblyName: string, rgdId: int, source: string, speciesTypeKey: int, ucscAssemblyId: string, unit: string, version: string>
# operationId: getMapsBySpeciesUsingGET
export def "get-maps-by-species-using-get" [
  species_type_key: int
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
    path: "/maps/{speciesTypeKey}"
    path_params: [{name: speciesTypeKey, var: species_type_key}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    species_type_key: $species_type_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns child and parent terms for Accession ID
#
# GET /ontology/ont/{accId}
# Returns: record
# operationId: getOntDagsUsingGET
export def "get-ont-dags-using-get" [
  acc_id: string
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
    path: "/ontology/ont/{accId}"
    path_params: [{name: accId, var: acc_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    acc_id: $acc_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns true or false for terms
#
# GET /ontology/term/{accId1}/{accId2}
# Returns: bool
# operationId: isDescendantOfUsingGET
export def "is-descendant-of-using-get" [
  acc_id1: string
  acc_id2: string
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
    method: get
    path: "/ontology/term/{accId1}/{accId2}"
    path_params: [{name: accId1, var: acc_id1}, {name: accId2, var: acc_id2}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    acc_id1: $acc_id1, acc_id2: $acc_id2
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns term for Accession ID
#
# GET /ontology/term/{accId}
# Returns: record<accId: string, comment: string, createdBy: string, creationDate: string, definition: string, modificationDate: string, obsolete: int, ontologyId: string, term: string, xrefs: table<key: int, termAcc: string, xrefDescription: string, xrefValue: string>>
# operationId: getTermUsingGET
export def "get-term-using-get" [
  acc_id: string
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
    path: "/ontology/term/{accId}"
    path_params: [{name: accId, var: acc_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    acc_id: $acc_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of pathways based on search term
#
# GET /pathways/diagrams/search/{searchString}
# Returns: table<description: string, hasAlteredPath: string, id: string, name: string, objectList: list<record>, pathwayCategories: list<string>, referenceList: list<record>>
# operationId: searchPathwaysUsingGET
export def "search-pathways-using-get" [
  search_string: string
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
    path: "/pathways/diagrams/search/{searchString}"
    path_params: [{name: searchString, var: search_string}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    search_string: $search_string
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of pathways based on category provided
#
# GET /pathways/diagramsForCategory/{category}
# Returns: table<description: string, hasAlteredPath: string, id: string, name: string, objectList: list<record>, pathwayCategories: list<string>, referenceList: list<record>>
# operationId: getPathwaysWithDiagramsForCategoryUsingGET
export def "get-pathways-with-diagrams-for-category-using-get" [
  category: string
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
    path: "/pathways/diagramsForCategory/{category}"
    path_params: [{name: category, var: category}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    category: $category
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of quantitative phenotypes values based on a combination of Clinical Measurement, Experimental Condition, Rat Strain, and/or Measurement Method ontology terms. Results will be all records that match all terms submitted. Ontology ids should be submitted as a comma delimited list (ex. RS:0000029,CMO:0000155,CMO:0000139). Species type is an integer value (3=rat, 4=chinchilla). Reference RGD ID for a study works like a filter.
#
# GET /phenotype/phenominer/chart/{speciesTypeKey}/{refRgdId}/{termString}
# Returns: record
# operationId: getChartInfoUsingGET
export def "get-chart-info-using-get" [
  species_type_key: int
  ref_rgd_id: int
  term_string: string
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
    path: "/phenotype/phenominer/chart/{speciesTypeKey}/{refRgdId}/{termString}"
    path_params: [{name: speciesTypeKey, var: species_type_key}, {name: refRgdId, var: ref_rgd_id}, {name: termString, var: term_string}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    species_type_key: $species_type_key, ref_rgd_id: $ref_rgd_id, term_string: $term_string
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of quantitative phenotypes values based on a combination of Clinical Measurement, Experimental Condition, Rat Strain, and/or Measurement Method ontology terms. Results will be all records that match all terms submitted. Ontology ids should be submitted as a comma delimited list (ex. RS:0000029,CMO:0000155,CMO:0000139). Species type is an integer value (3=rat, 4=chinchilla)
#
# GET /phenotype/phenominer/chart/{speciesTypeKey}/{termString}
# Returns: record
# operationId: getChartInfoUsingGET_1
export def "get-chart-info-using-get-1" [
  species_type_key: int
  term_string: string
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
    path: "/phenotype/phenominer/chart/{speciesTypeKey}/{termString}"
    path_params: [{name: speciesTypeKey, var: species_type_key}, {name: termString, var: term_string}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    species_type_key: $species_type_key, term_string: $term_string
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list QTL for given position and assembly map
#
# GET /qtls/mapped/{chr}/{start}/{stop}/{mapKey}
# Returns: table<chromosome: string, mapKey: int, qtl: record<chromosome: string, flank1RgdId: int, flank2RgdId: int, inheritanceType: string, key: int, linkageImage: string, lod: float, lodImage: string, mostSignificantCmoTerm: string, name: string, notes: string, peakOffset: int, peakRgdId: int, pvalue: float, rgdId: int, sourceUrl: string, speciesTypeKey: int, symbol: string, variance: float>, start: int, stop: int, strand: string>
# operationId: getMappedQTLByPositionUsingGET
export def "get-mapped-qtl-by-position-using-get" [
  chr: string
  start: int
  stop: int
  map_key: int
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
    path: "/qtls/mapped/{chr}/{start}/{stop}/{mapKey}"
    path_params: [{name: chr, var: chr}, {name: start, var: start}, {name: stop, var: stop}, {name: mapKey, var: map_key}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    chr: $chr, start: $start, stop: $stop, map_key: $map_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list QTL for given position and assembly map
#
# GET /qtls/{chr}/{start}/{stop}/{mapKey}
# Returns: table<chromosome: string, flank1RgdId: int, flank2RgdId: int, inheritanceType: string, key: int, linkageImage: string, lod: float, lodImage: string, mostSignificantCmoTerm: string, name: string, notes: string, peakOffset: int, peakRgdId: int, pvalue: float, rgdId: int, sourceUrl: string, speciesTypeKey: int, symbol: string, variance: float>
# operationId: getQtlListByPositionUsingGET
export def "get-qtl-list-by-position-using-get" [
  chr: string
  start: int
  stop: int
  map_key: int
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
    path: "/qtls/{chr}/{start}/{stop}/{mapKey}"
    path_params: [{name: chr, var: chr}, {name: start, var: start}, {name: stop, var: stop}, {name: mapKey, var: map_key}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    chr: $chr, start: $start, stop: $stop, map_key: $map_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a QTL for provided RGD ID
#
# GET /qtls/{rgdId}
# Returns: record<chromosome: string, flank1RgdId: int, flank2RgdId: int, inheritanceType: string, key: int, linkageImage: string, lod: float, lodImage: string, mostSignificantCmoTerm: string, name: string, notes: string, peakOffset: int, peakRgdId: int, pvalue: float, rgdId: int, sourceUrl: string, speciesTypeKey: int, symbol: string, variance: float>
# operationId: getQTLByRgdIdUsingGET
export def "get-qtl-by-rgd-id-using-get" [
  rgd_id: int
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
    path: "/qtls/{rgdId}"
    path_params: [{name: rgdId, var: rgd_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    rgd_id: $rgd_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list SSLP for given position and assembly map
#
# GET /sslps/mapped/{chr}/{start}/{stop}/{mapKey}
# Returns: table<chromosome: string, mapKey: int, sslp: record<expectedSize: int, forwardSeq: string, key: int, name: string, notes: string, reverseSeq: string, rgdId: int, speciesTypeKey: int, sslpType: string, templateSeq: string>, start: int, stop: int, strand: string>
# operationId: getMappedSSLPByPositionUsingGET
export def "get-mapped-sslp-by-position-using-get" [
  chr: string
  start: int
  stop: int
  map_key: int
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
    path: "/sslps/mapped/{chr}/{start}/{stop}/{mapKey}"
    path_params: [{name: chr, var: chr}, {name: start, var: start}, {name: stop, var: stop}, {name: mapKey, var: map_key}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    chr: $chr, start: $start, stop: $stop, map_key: $map_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count of active objects by type, for specified species and date
#
# GET /stats/count/activeObject/{speciesTypeKey}/{dateYYYYMMDD}
# Returns: record
# operationId: getActiveObjectCountUsingGET
export def "get-active-object-count-using-get" [
  species_type_key: int
  date_yyyymmdd: string
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
    path: "/stats/count/activeObject/{speciesTypeKey}/{dateYYYYMMDD}"
    path_params: [{name: speciesTypeKey, var: species_type_key}, {name: dateYYYYMMDD, var: date_yyyymmdd}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    species_type_key: $species_type_key, date_yyyymmdd: $date_yyyymmdd
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count of gene types, for specified species and date
#
# GET /stats/count/geneType/{speciesTypeKey}/{dateYYYYMMDD}
# Returns: record
# operationId: getGeneTypeCountUsingGET
export def "get-gene-type-count-using-get" [
  species_type_key: int
  date_yyyymmdd: string
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
    path: "/stats/count/geneType/{speciesTypeKey}/{dateYYYYMMDD}"
    path_params: [{name: speciesTypeKey, var: species_type_key}, {name: dateYYYYMMDD, var: date_yyyymmdd}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    species_type_key: $species_type_key, date_yyyymmdd: $date_yyyymmdd
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count of objects with given status, for specified species and date
#
# GET /stats/count/objectStatus/{speciesTypeKey}/{dateYYYYMMDD}
# Returns: record
# operationId: getObjectStatusCountUsingGET
export def "get-object-status-count-using-get" [
  species_type_key: int
  date_yyyymmdd: string
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
    path: "/stats/count/objectStatus/{speciesTypeKey}/{dateYYYYMMDD}"
    path_params: [{name: speciesTypeKey, var: species_type_key}, {name: dateYYYYMMDD, var: date_yyyymmdd}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    species_type_key: $species_type_key, date_yyyymmdd: $date_yyyymmdd
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count of objects with reference sequence(s), by object type, for specified species and date
#
# GET /stats/count/objectWithRefSeq/{speciesTypeKey}/{dateYYYYMMDD}
# Returns: record
# operationId: getObjectsWithRefSeqCountUsingGET
export def "get-objects-with-ref-seq-count-using-get" [
  species_type_key: int
  date_yyyymmdd: string
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
    path: "/stats/count/objectWithRefSeq/{speciesTypeKey}/{dateYYYYMMDD}"
    path_params: [{name: speciesTypeKey, var: species_type_key}, {name: dateYYYYMMDD, var: date_yyyymmdd}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    species_type_key: $species_type_key, date_yyyymmdd: $date_yyyymmdd
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count of objects with reference, by object type, for specified species and date
#
# GET /stats/count/objectWithReference/{speciesTypeKey}/{dateYYYYMMDD}
# Returns: record
# operationId: getObjectsWithReferenceCountUsingGET
export def "get-objects-with-reference-count-using-get" [
  species_type_key: int
  date_yyyymmdd: string
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
    path: "/stats/count/objectWithReference/{speciesTypeKey}/{dateYYYYMMDD}"
    path_params: [{name: speciesTypeKey, var: species_type_key}, {name: dateYYYYMMDD, var: date_yyyymmdd}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    species_type_key: $species_type_key, date_yyyymmdd: $date_yyyymmdd
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count of objects with external database ids, by database id, for specified species, object type and date
#
# GET /stats/count/objectWithXdb/{speciesTypeKey}/{objectKey}/{dateYYYYMMDD}
# Returns: record
# operationId: getObjectsWithXDBsCountUsingGET
export def "get-objects-with-xd-bs-count-using-get" [
  species_type_key: int
  object_key: int
  date_yyyymmdd: string
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
    path: "/stats/count/objectWithXdb/{speciesTypeKey}/{objectKey}/{dateYYYYMMDD}"
    path_params: [{name: speciesTypeKey, var: species_type_key}, {name: objectKey, var: object_key}, {name: dateYYYYMMDD, var: date_yyyymmdd}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    species_type_key: $species_type_key, object_key: $object_key, date_yyyymmdd: $date_yyyymmdd
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count of protein interactions, for specified species and date
#
# GET /stats/count/proteinInteraction/{speciesTypeKey}/{dateYYYYMMDD}
# Returns: record
# operationId: getProteinInteractionCountUsingGET
export def "get-protein-interaction-count-using-get" [
  species_type_key: int
  date_yyyymmdd: string
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
    path: "/stats/count/proteinInteraction/{speciesTypeKey}/{dateYYYYMMDD}"
    path_params: [{name: speciesTypeKey, var: species_type_key}, {name: dateYYYYMMDD, var: date_yyyymmdd}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    species_type_key: $species_type_key, date_yyyymmdd: $date_yyyymmdd
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count of strains, by qtl inheritance type, for specified species and date
#
# GET /stats/count/qtlInheritanceType/{speciesTypeKey}/{dateYYYYMMDD}
# Returns: record
# operationId: getQtlInheritanceTypeCountUsingGET
export def "get-qtl-inheritance-type-count-using-get" [
  species_type_key: int
  date_yyyymmdd: string
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
    path: "/stats/count/qtlInheritanceType/{speciesTypeKey}/{dateYYYYMMDD}"
    path_params: [{name: speciesTypeKey, var: species_type_key}, {name: dateYYYYMMDD, var: date_yyyymmdd}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    species_type_key: $species_type_key, date_yyyymmdd: $date_yyyymmdd
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count of retired objects by type, for specified species and date
#
# GET /stats/count/retiredObject/{speciesTypeKey}/{dateYYYYMMDD}
# Returns: record
# operationId: getRetiredObjectCountUsingGET
export def "get-retired-object-count-using-get" [
  species_type_key: int
  date_yyyymmdd: string
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
    path: "/stats/count/retiredObject/{speciesTypeKey}/{dateYYYYMMDD}"
    path_params: [{name: speciesTypeKey, var: species_type_key}, {name: dateYYYYMMDD, var: date_yyyymmdd}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    species_type_key: $species_type_key, date_yyyymmdd: $date_yyyymmdd
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count of strain types, for specified species and date
#
# GET /stats/count/strainType/{speciesTypeKey}/{dateYYYYMMDD}
# Returns: record
# operationId: getStrainTypeCountUsingGET
export def "get-strain-type-count-using-get" [
  species_type_key: int
  date_yyyymmdd: string
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
    path: "/stats/count/strainType/{speciesTypeKey}/{dateYYYYMMDD}"
    path_params: [{name: speciesTypeKey, var: species_type_key}, {name: dateYYYYMMDD, var: date_yyyymmdd}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    species_type_key: $species_type_key, date_yyyymmdd: $date_yyyymmdd
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count of withdrawn objects by type, for specified species and date
#
# GET /stats/count/withdrawnObject/{speciesTypeKey}/{dateYYYYMMDD}
# Returns: record
# operationId: getWithdrawnObjectCountUsingGET
export def "get-withdrawn-object-count-using-get" [
  species_type_key: int
  date_yyyymmdd: string
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
    path: "/stats/count/withdrawnObject/{speciesTypeKey}/{dateYYYYMMDD}"
    path_params: [{name: speciesTypeKey, var: species_type_key}, {name: dateYYYYMMDD, var: date_yyyymmdd}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    species_type_key: $species_type_key, date_yyyymmdd: $date_yyyymmdd
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count of external database ids, for specied species and date
#
# GET /stats/count/xdb/{speciesTypeKey}/{dateYYYYMMDD}
# Returns: record
# operationId: getXdbsCountUsingGET
export def "get-xdbs-count-using-get" [
  species_type_key: int
  date_yyyymmdd: string
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
    path: "/stats/count/xdb/{speciesTypeKey}/{dateYYYYMMDD}"
    path_params: [{name: speciesTypeKey, var: species_type_key}, {name: dateYYYYMMDD, var: date_yyyymmdd}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    species_type_key: $species_type_key, date_yyyymmdd: $date_yyyymmdd
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count difference of active objects, by type, for specified species and date range
#
# GET /stats/diff/activeObject/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# Returns: record
# operationId: getActiveObjectDiffUsingGET
export def "get-active-object-diff-using-get" [
  species_type_key: int
  date_from_yyyymmdd: string
  date_to_yyyymmdd: string
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
    path: "/stats/diff/activeObject/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}"
    path_params: [{name: speciesTypeKey, var: species_type_key}, {name: dateFromYYYYMMDD, var: date_from_yyyymmdd}, {name: dateToYYYYMMDD, var: date_to_yyyymmdd}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    species_type_key: $species_type_key, date_from_yyyymmdd: $date_from_yyyymmdd, date_to_yyyymmdd: $date_to_yyyymmdd
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count difference of gene types, for specified species and date range
#
# GET /stats/diff/geneType/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# Returns: record
# operationId: getGeneTypeDiffUsingGET
export def "get-gene-type-diff-using-get" [
  species_type_key: int
  date_from_yyyymmdd: string
  date_to_yyyymmdd: string
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
    path: "/stats/diff/geneType/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}"
    path_params: [{name: speciesTypeKey, var: species_type_key}, {name: dateFromYYYYMMDD, var: date_from_yyyymmdd}, {name: dateToYYYYMMDD, var: date_to_yyyymmdd}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    species_type_key: $species_type_key, date_from_yyyymmdd: $date_from_yyyymmdd, date_to_yyyymmdd: $date_to_yyyymmdd
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count difference of objects with given status, for specified species and date range
#
# GET /stats/diff/objectStatus/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# Returns: record
# operationId: getObjectStatusDiffUsingGET
export def "get-object-status-diff-using-get" [
  species_type_key: int
  date_from_yyyymmdd: string
  date_to_yyyymmdd: string
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
    path: "/stats/diff/objectStatus/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}"
    path_params: [{name: speciesTypeKey, var: species_type_key}, {name: dateFromYYYYMMDD, var: date_from_yyyymmdd}, {name: dateToYYYYMMDD, var: date_to_yyyymmdd}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    species_type_key: $species_type_key, date_from_yyyymmdd: $date_from_yyyymmdd, date_to_yyyymmdd: $date_to_yyyymmdd
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count difference of objects with reference sequence(s), by object type, for specified species and date range
#
# GET /stats/diff/objectWithRefSeq/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# Returns: record
# operationId: getObjectsWithRefSeqDiffUsingGET
export def "get-objects-with-ref-seq-diff-using-get" [
  species_type_key: int
  date_from_yyyymmdd: string
  date_to_yyyymmdd: string
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
    path: "/stats/diff/objectWithRefSeq/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}"
    path_params: [{name: speciesTypeKey, var: species_type_key}, {name: dateFromYYYYMMDD, var: date_from_yyyymmdd}, {name: dateToYYYYMMDD, var: date_to_yyyymmdd}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    species_type_key: $species_type_key, date_from_yyyymmdd: $date_from_yyyymmdd, date_to_yyyymmdd: $date_to_yyyymmdd
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count difference of objects with reference, by object type, for specified species and date range
#
# GET /stats/diff/objectWithReference/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# Returns: record
# operationId: getObjectsWithReferenceDiffUsingGET
export def "get-objects-with-reference-diff-using-get" [
  species_type_key: int
  date_from_yyyymmdd: string
  date_to_yyyymmdd: string
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
    path: "/stats/diff/objectWithReference/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}"
    path_params: [{name: speciesTypeKey, var: species_type_key}, {name: dateFromYYYYMMDD, var: date_from_yyyymmdd}, {name: dateToYYYYMMDD, var: date_to_yyyymmdd}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    species_type_key: $species_type_key, date_from_yyyymmdd: $date_from_yyyymmdd, date_to_yyyymmdd: $date_to_yyyymmdd
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count difference of objects with external database ids, by database id, for specified species, object type and date range
#
# GET /stats/diff/objectWithXdb/{speciesTypeKey}/{objectKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# Returns: record
# operationId: getObjectsWithXDBsDiffUsingGET
export def "get-objects-with-xd-bs-diff-using-get" [
  species_type_key: int
  object_key: int
  date_from_yyyymmdd: string
  date_to_yyyymmdd: string
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
    path: "/stats/diff/objectWithXdb/{speciesTypeKey}/{objectKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}"
    path_params: [{name: speciesTypeKey, var: species_type_key}, {name: objectKey, var: object_key}, {name: dateFromYYYYMMDD, var: date_from_yyyymmdd}, {name: dateToYYYYMMDD, var: date_to_yyyymmdd}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    species_type_key: $species_type_key, object_key: $object_key, date_from_yyyymmdd: $date_from_yyyymmdd, date_to_yyyymmdd: $date_to_yyyymmdd
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count difference of protein interactions, for specified species and date range
#
# GET /stats/diff/proteinInteraction/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# Returns: record
# operationId: getProteinInteractionDiffUsingGET
export def "get-protein-interaction-diff-using-get" [
  species_type_key: int
  date_from_yyyymmdd: string
  date_to_yyyymmdd: string
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
    path: "/stats/diff/proteinInteraction/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}"
    path_params: [{name: speciesTypeKey, var: species_type_key}, {name: dateFromYYYYMMDD, var: date_from_yyyymmdd}, {name: dateToYYYYMMDD, var: date_to_yyyymmdd}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    species_type_key: $species_type_key, date_from_yyyymmdd: $date_from_yyyymmdd, date_to_yyyymmdd: $date_to_yyyymmdd
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count difference of strains, by qtl inheritance type, for specified species and date range
#
# GET /stats/diff/qtlInheritanceType/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# Returns: record
# operationId: getQtlInheritanceTypeDiffUsingGET
export def "get-qtl-inheritance-type-diff-using-get" [
  species_type_key: int
  date_from_yyyymmdd: string
  date_to_yyyymmdd: string
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
    path: "/stats/diff/qtlInheritanceType/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}"
    path_params: [{name: speciesTypeKey, var: species_type_key}, {name: dateFromYYYYMMDD, var: date_from_yyyymmdd}, {name: dateToYYYYMMDD, var: date_to_yyyymmdd}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    species_type_key: $species_type_key, date_from_yyyymmdd: $date_from_yyyymmdd, date_to_yyyymmdd: $date_to_yyyymmdd
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count difference of retired objects, by type, for specified species and date range
#
# GET /stats/diff/retiredObject/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# Returns: record
# operationId: getRetiredObjectDiffUsingGET
export def "get-retired-object-diff-using-get" [
  species_type_key: int
  date_from_yyyymmdd: string
  date_to_yyyymmdd: string
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
    path: "/stats/diff/retiredObject/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}"
    path_params: [{name: speciesTypeKey, var: species_type_key}, {name: dateFromYYYYMMDD, var: date_from_yyyymmdd}, {name: dateToYYYYMMDD, var: date_to_yyyymmdd}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    species_type_key: $species_type_key, date_from_yyyymmdd: $date_from_yyyymmdd, date_to_yyyymmdd: $date_to_yyyymmdd
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count difference of strain types, for specified species and date range
#
# GET /stats/diff/strainType/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# Returns: record
# operationId: getStrainTypeDiffUsingGET
export def "get-strain-type-diff-using-get" [
  species_type_key: int
  date_from_yyyymmdd: string
  date_to_yyyymmdd: string
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
    path: "/stats/diff/strainType/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}"
    path_params: [{name: speciesTypeKey, var: species_type_key}, {name: dateFromYYYYMMDD, var: date_from_yyyymmdd}, {name: dateToYYYYMMDD, var: date_to_yyyymmdd}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    species_type_key: $species_type_key, date_from_yyyymmdd: $date_from_yyyymmdd, date_to_yyyymmdd: $date_to_yyyymmdd
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count difference of withdrawn objects, by type, for specified species and date range
#
# GET /stats/diff/withdrawnObject/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# Returns: record
# operationId: getWithdrawnObjectDiffUsingGET
export def "get-withdrawn-object-diff-using-get" [
  species_type_key: int
  date_from_yyyymmdd: string
  date_to_yyyymmdd: string
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
    path: "/stats/diff/withdrawnObject/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}"
    path_params: [{name: speciesTypeKey, var: species_type_key}, {name: dateFromYYYYMMDD, var: date_from_yyyymmdd}, {name: dateToYYYYMMDD, var: date_to_yyyymmdd}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    species_type_key: $species_type_key, date_from_yyyymmdd: $date_from_yyyymmdd, date_to_yyyymmdd: $date_to_yyyymmdd
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count difference of external database ids, for specified species and date range
#
# GET /stats/diff/xdb/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# Returns: record
# operationId: getXdbsDiffUsingGET
export def "get-xdbs-diff-using-get" [
  species_type_key: int
  date_from_yyyymmdd: string
  date_to_yyyymmdd: string
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
    path: "/stats/diff/xdb/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}"
    path_params: [{name: speciesTypeKey, var: species_type_key}, {name: dateFromYYYYMMDD, var: date_from_yyyymmdd}, {name: dateToYYYYMMDD, var: date_to_yyyymmdd}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    species_type_key: $species_type_key, date_from_yyyymmdd: $date_from_yyyymmdd, date_to_yyyymmdd: $date_to_yyyymmdd
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getTermStats
#
# GET /stats/term/{accId}/{filterAccId}
# Returns: record
# operationId: getTermStatsUsingGET
export def "get-term-stats-using-get" [
  acc_id: string
  filter_acc_id: string
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
    path: "/stats/term/{accId}/{filterAccId}"
    path_params: [{name: accId, var: acc_id}, {name: filterAccId, var: filter_acc_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    acc_id: $acc_id, filter_acc_id: $filter_acc_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return all active strains in RGD
#
# GET /strains/all
# Returns: table<backgroundStrainRgdId: int, chrAltered: string, color: string, geneticStatus: string, genetics: string, imageUrl: string, inbredGen: string, key: int, lastStatus: string, lastStatusObject: record<cryopreservedEmbryo: bool, cryopreservedSperm: bool, cryorecovery: bool, key: int, liveAnimals: bool, statusDate: string, strainRgdId: int>, modificationMethod: string, name: string, notes: string, origin: string, researchUse: string, rgdId: int, source: string, speciesTypeKey: int, statusLog: list<record>, strain: string, strainTypeName: string, substrain: string, symbol: string>
# operationId: getAllStrainsUsingGET
export def "get-all-strains-using-get" [
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
    path: "/strains/all"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return all active strains by position
#
# GET /strains/{chr}/{start}/{stop}/{mapKey}
# Returns: table<backgroundStrainRgdId: int, chrAltered: string, color: string, geneticStatus: string, genetics: string, imageUrl: string, inbredGen: string, key: int, lastStatus: string, lastStatusObject: record<cryopreservedEmbryo: bool, cryopreservedSperm: bool, cryorecovery: bool, key: int, liveAnimals: bool, statusDate: string, strainRgdId: int>, modificationMethod: string, name: string, notes: string, origin: string, researchUse: string, rgdId: int, source: string, speciesTypeKey: int, statusLog: list<record>, strain: string, strainTypeName: string, substrain: string, symbol: string>
# operationId: getStrainsByPositionUsingGET
export def "get-strains-by-position-using-get" [
  chr: string
  start: int
  stop: int
  map_key: int
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
    path: "/strains/{chr}/{start}/{stop}/{mapKey}"
    path_params: [{name: chr, var: chr}, {name: start, var: start}, {name: stop, var: stop}, {name: mapKey, var: map_key}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    chr: $chr, start: $start, stop: $stop, map_key: $map_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a strain by RGD ID
#
# GET /strains/{rgdId}
# Returns: record<backgroundStrainRgdId: int, chrAltered: string, color: string, geneticStatus: string, genetics: string, imageUrl: string, inbredGen: string, key: int, lastStatus: string, lastStatusObject: record<cryopreservedEmbryo: bool, cryopreservedSperm: bool, cryorecovery: bool, key: int, liveAnimals: bool, statusDate: string, strainRgdId: int>, modificationMethod: string, name: string, notes: string, origin: string, researchUse: string, rgdId: int, source: string, speciesTypeKey: int, statusLog: table<cryopreservedEmbryo: bool, cryopreservedSperm: bool, cryorecovery: bool, key: int, liveAnimals: bool, statusDate: string, strainRgdId: int>, strain: string, strainTypeName: string, substrain: string, symbol: string>
# operationId: getStrainByRgdIdUsingGET
export def "get-strain-by-rgd-id-using-get" [
  rgd_id: int
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
    path: "/strains/{rgdId}"
    path_params: [{name: rgdId, var: rgd_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    rgd_id: $rgd_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
