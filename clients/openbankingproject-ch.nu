# Auto-generated client for Swiss NextGen Banking API-Framework v1.3.8_2020-12-14 - Swiss edition 1.3.8.1-CH
# Source: https://api.apis.guru/v2/specs/openbankingproject.ch/1.3.8_2020-12-14 - Swiss edition 1.3.8.1-CH/openapi.json
# Auth: --token flag or $env.SWISS_NEXTGEN_BANKING_API_FRAMEWORK_TOKEN

const CLIENT = {
  base_url: "https://api.dev.openbankingproject.ch"
  token_env_var: "SWISS_NEXTGEN_BANKING_API_FRAMEWORK_TOKEN"
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

def base-url-completer [] { ["https://api.dev.openbankingproject.ch"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def psu-http-method-completer [] { ["DELETE" "GET" "PATCH" "POST" "PUT"] }
def booking-status-completer [] { ["booked" "both" "information" "pending"] }
def accept-completer [] { ["application/json" "application/xml" "text/plain"] }
def payment-service-completer [] { ["bulk-payments" "payments" "periodic-payments"] }
def payment-product-completer [] { ["domestic-swiss-credit-transfers" "domestic-swiss-credit-transfers-isr" "domestic-swiss-credit-transfers-qr" "domestic-swiss-foreign-credit-transfers" "pain.001-cross-border-credit-transfers" "pain.001-sepa-credit-transfers" "pain.001-swiss-six-credit-transfers" "swiss-cross-border-credit-transfers" "swiss-sepa-credit-transfers"] }
def charge-bearer-completer [] { ["CRED" "DEBT" "SHAR" "SLEV"] }
def purpose-code-completer [] { ["PENS" "SALA"] }
def service-level-completer [] { ["PRPT" "SDVA" "SEPA" "URGP"] }
def day-of-execution-completer [] { ["1" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "2" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "3" "30" "31" "4" "5" "6" "7" "8" "9"] }
def execution-rule-completer [] { ["following" "preceding"] }
def frequency-completer [] { ["Annual" "Daily" "EveryTwoMonths" "EveryTwoWeeks" "Monthly" "MonthlyVariable" "Quarterly" "SemiAnnual" "Weekly"] }
def accept-completer-1 [] { ["application/json" "application/xml" "multipart/form-data"] }
def accept-completer-2 [] { ["application/json" "application/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-account-list: "record<accounts: table<_links: record, balances: list, bban: string, bic: string, cashAccountType: string, currency: string, details: string, displayName: string, iban: string, linkedAccounts: string, msisdn: string, name: string, ownerName: string, product: string, resourceId: string, status: string, usage: string>>"
    read-account-details: "record<account: record<_links: record<balances: record, transactions: record>, balances: list<record>, bban: string, bic: string, cashAccountType: string, currency: string, details: string, displayName: string, iban: string, linkedAccounts: string, msisdn: string, name: string, ownerName: string, product: string, resourceId: string, status: string, usage: string>>"
    get-balances: "record<account: record<cashAccountType: string, currency: string, iban: string, otherAccountIdentification: string>, balances: table<balanceAmount: record, balanceType: string, creditLimitIncluded: bool, lastChangeDateTime: string, lastCommittedTransaction: string, referenceDate: string>>"
    get-transaction-list: "record<_links: record<download: record<href: string>>, account: record<cashAccountType: string, currency: string, iban: string, otherAccountIdentification: string>, balances: table<balanceAmount: record, balanceType: string, creditLimitIncluded: bool, lastChangeDateTime: string, lastCommittedTransaction: string, referenceDate: string>, transactions: record<_links: record<account: record, first: record, last: record, next: record, previous: record>, booked: list<record>, information: list<record>, pending: list<record>>>"
    get-transaction-details: "record<transactionsDetails: record<transactionDetails: record<_links: record, additionalInformation: string, additionalInformationStructured: record, balanceAfterTransaction: record, bankTransactionCode: string, batchIndicator: bool, batchNumberOfTransactions: int, bookingDate: string, checkId: string, creditorAccount: record, creditorAgent: string, creditorId: string, creditorName: string, currencyExchange: list, debtorAccount: record, debtorAgent: string, debtorName: string, endToEndId: string, entryDetails: list, entryReference: string, mandateId: string, proprietaryBankTransactionCode: string, purposeCode: string, remittanceInformationStructured: string, remittanceInformationStructuredArray: list, remittanceInformationUnstructured: string, remittanceInformationUnstructuredArray: list, transactionAmount: record, transactionId: string, ultimateCreditor: string, ultimateDebtor: string, valueDate: string>>>"
    create-consent: "record<_links: record<confirmation: record<href: string>, scaOAuth: record<href: string>, scaRedirect: record<href: string>, scaStatus: record<href: string>, self: record<href: string>, startAuthorisation: record<href: string>, startAuthorisationWithAuthenticationMethodSelection: record<href: string>, startAuthorisationWithEncryptedPsuAuthentication: record<href: string>, startAuthorisationWithPsuAuthentication: record<href: string>, startAuthorisationWithPsuIdentification: record<href: string>, startAuthorisationWithTransactionAuthorisation: record<href: string>, status: record<href: string>>, challengeData: record<additionalInformation: string, data: list<string>, image: string, imageLink: string, otpFormat: string, otpMaxLength: int>, chosenScaMethod: record<authenticationMethodId: string, authenticationType: string, authenticationVersion: string, explanation: string, name: string>, consentId: string, consentStatus: string, psuMessage: string, scaMethods: table<authenticationMethodId: string, authenticationType: string, authenticationVersion: string, explanation: string, name: string>>"
    get-consent-information: "record<_links: record<account: record<href: string>, card-account: record<href: string>>, access: record<accounts: list<record>, additionalInformation: record<ownerName: list, trustedBeneficiaries: list>, allPsd2: string, availableAccounts: string, availableAccountsWithBalance: string, balances: list<record>, restrictedTo: list<string>, transactions: list<record>>, consentStatus: string, frequencyPerDay: int, lastActionDate: string, recurringIndicator: bool, validUntil: string>"
    get-consent-authorisation: "record<authorisationIds: list<string>>"
    start-consent-authorisation: "record<_links: record<authoriseTransaction: record<href: string>, confirmation: record<href: string>, scaOAuth: record<href: string>, scaRedirect: record<href: string>, scaStatus: record<href: string>, selectAuthenticationMethod: record<href: string>, startAuthorisationWithEncryptedPsuAuthentication: record<href: string>, startAuthorisationWithPsuAuthentication: record<href: string>, updatePsuIdentification: record<href: string>>, authorisationId: string, challengeData: record<additionalInformation: string, data: list<string>, image: string, imageLink: string, otpFormat: string, otpMaxLength: int>, chosenScaMethod: record<authenticationMethodId: string, authenticationType: string, authenticationVersion: string, explanation: string, name: string>, psuMessage: string, scaMethods: table<authenticationMethodId: string, authenticationType: string, authenticationVersion: string, explanation: string, name: string>, scaStatus: string>"
    get-consent-sca-status: "record<psuMessage: string, scaStatus: string, trustedBeneficiaryFlag: bool>"
    get-consent-status: "record<consentStatus: string, psuMessage: string>"
    check-availability-of-funds: "record<fundsAvailable: bool>"
    create-signing-basket: "record<_links: record<scaOAuth: record<href: string>, scaRedirect: record<href: string>, scaStatus: record<href: string>, self: record<href: string>, startAuthorisation: record<href: string>, startAuthorisationWithAuthenticationMethodSelection: record<href: string>, startAuthorisationWithEncryptedPsuAuthentication: record<href: string>, startAuthorisationWithPsuAuthentication: record<href: string>, startAuthorisationWithPsuIdentification: record<href: string>, startAuthorisationWithTransactionAuthorisation: record<href: string>, status: record<href: string>>, basketId: string, challengeData: record<additionalInformation: string, data: list<string>, image: string, imageLink: string, otpFormat: string, otpMaxLength: int>, chosenScaMethod: record<authenticationMethodId: string, authenticationType: string, authenticationVersion: string, explanation: string, name: string>, psuMessage: string, scaMethods: table<authenticationMethodId: string, authenticationType: string, authenticationVersion: string, explanation: string, name: string>, tppMessages: table<category: string, code: string, path: string, text: string>, transactionStatus: string>"
    get-signing-basket: "record<_links: record<scaOAuth: record<href: string>, scaRedirect: record<href: string>, scaStatus: record<href: string>, self: record<href: string>, startAuthorisation: record<href: string>, startAuthorisationWithAuthenticationMethodSelection: record<href: string>, startAuthorisationWithEncryptedPsuAuthentication: record<href: string>, startAuthorisationWithPsuAuthentication: record<href: string>, startAuthorisationWithPsuIdentification: record<href: string>, startAuthorisationWithTransactionAuthorisation: record<href: string>, status: record<href: string>>, consents: list<string>, payments: list<string>, transactionStatus: string>"
    get-signing-basket-authorisation: "record<authorisationIds: list<string>>"
    start-signing-basket-authorisation: "record<_links: record<authoriseTransaction: record<href: string>, confirmation: record<href: string>, scaOAuth: record<href: string>, scaRedirect: record<href: string>, scaStatus: record<href: string>, selectAuthenticationMethod: record<href: string>, startAuthorisationWithEncryptedPsuAuthentication: record<href: string>, startAuthorisationWithPsuAuthentication: record<href: string>, updatePsuIdentification: record<href: string>>, authorisationId: string, challengeData: record<additionalInformation: string, data: list<string>, image: string, imageLink: string, otpFormat: string, otpMaxLength: int>, chosenScaMethod: record<authenticationMethodId: string, authenticationType: string, authenticationVersion: string, explanation: string, name: string>, psuMessage: string, scaMethods: table<authenticationMethodId: string, authenticationType: string, authenticationVersion: string, explanation: string, name: string>, scaStatus: string>"
    get-signing-basket-sca-status: "record<psuMessage: string, scaStatus: string, trustedBeneficiaryFlag: bool>"
    get-signing-basket-status: "record<transactionStatus: string>"
    initiate-payment: "record<_links: record<confirmation: record<href: string>, scaOAuth: record<href: string>, scaRedirect: record<href: string>, scaStatus: record<href: string>, self: record<href: string>, startAuthorisation: record<href: string>, startAuthorisationWithAuthenticationMethodSelection: record<href: string>, startAuthorisationWithEncryptedPsuAuthentication: record<href: string>, startAuthorisationWithPsuAuthentication: record<href: string>, startAuthorisationWithPsuIdentification: record<href: string>, startAuthorisationWithTransactionAuthorisation: record<href: string>, status: record<href: string>>, challengeData: record<additionalInformation: string, data: list<string>, image: string, imageLink: string, otpFormat: string, otpMaxLength: int>, chosenScaMethod: record<authenticationMethodId: string, authenticationType: string, authenticationVersion: string, explanation: string, name: string>, currencyConversionFee: record<amount: string, currency: string>, estimatedInterbankSettlementAmount: record<amount: string, currency: string>, estimatedTotalAmount: record<amount: string, currency: string>, paymentId: string, psuMessage: string, scaMethods: table<authenticationMethodId: string, authenticationType: string, authenticationVersion: string, explanation: string, name: string>, tppMessages: table<category: string, code: string, path: string, text: string>, transactionFeeIndicator: bool, transactionFees: record<amount: string, currency: string>, transactionStatus: string>"
    cancel-payment: "record<_links: record<startAuthorisation: record<href: string>, startAuthorisationWithAuthenticationMethodSelection: record<href: string>, startAuthorisationWithEncryptedPsuAuthentication: record<href: string>, startAuthorisationWithPsuAuthentication: record<href: string>, startAuthorisationWithPsuIdentification: record<href: string>>, challengeData: record<additionalInformation: string, data: list<string>, image: string, imageLink: string, otpFormat: string, otpMaxLength: int>, chosenScaMethod: record<authenticationMethodId: string, authenticationType: string, authenticationVersion: string, explanation: string, name: string>, scaMethods: table<authenticationMethodId: string, authenticationType: string, authenticationVersion: string, explanation: string, name: string>, transactionStatus: string>"
    get-payment-initiation-authorisation: "record<authorisationIds: list<string>>"
    start-payment-authorisation: "record<_links: record<authoriseTransaction: record<href: string>, confirmation: record<href: string>, scaOAuth: record<href: string>, scaRedirect: record<href: string>, scaStatus: record<href: string>, selectAuthenticationMethod: record<href: string>, startAuthorisationWithEncryptedPsuAuthentication: record<href: string>, startAuthorisationWithPsuAuthentication: record<href: string>, updatePsuIdentification: record<href: string>>, authorisationId: string, challengeData: record<additionalInformation: string, data: list<string>, image: string, imageLink: string, otpFormat: string, otpMaxLength: int>, chosenScaMethod: record<authenticationMethodId: string, authenticationType: string, authenticationVersion: string, explanation: string, name: string>, psuMessage: string, scaMethods: table<authenticationMethodId: string, authenticationType: string, authenticationVersion: string, explanation: string, name: string>, scaStatus: string>"
    get-payment-initiation-sca-status: "record<psuMessage: string, scaStatus: string, trustedBeneficiaryFlag: bool>"
    get-payment-initiation-cancellation-authorisation-information: "record<authorisationIds: list<string>>"
    start-payment-initiation-cancellation-authorisation: "record<_links: record<authoriseTransaction: record<href: string>, confirmation: record<href: string>, scaOAuth: record<href: string>, scaRedirect: record<href: string>, scaStatus: record<href: string>, selectAuthenticationMethod: record<href: string>, startAuthorisationWithEncryptedPsuAuthentication: record<href: string>, startAuthorisationWithPsuAuthentication: record<href: string>, updatePsuIdentification: record<href: string>>, authorisationId: string, challengeData: record<additionalInformation: string, data: list<string>, image: string, imageLink: string, otpFormat: string, otpMaxLength: int>, chosenScaMethod: record<authenticationMethodId: string, authenticationType: string, authenticationVersion: string, explanation: string, name: string>, psuMessage: string, scaMethods: table<authenticationMethodId: string, authenticationType: string, authenticationVersion: string, explanation: string, name: string>, scaStatus: string>"
    get-payment-cancellation-sca-status: "record<psuMessage: string, scaStatus: string, trustedBeneficiaryFlag: bool>"
    get-payment-initiation-status: "record<fundsAvailable: bool, psuMessage: string, transactionStatus: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-account-list" "read-account-details" "get-balances" "get-transaction-list" "get-transaction-details" "create-consent" "delete-consent" "get-consent-information" "get-consent-authorisation" "start-consent-authorisation" "get-consent-sca-status" "update-consents-psu-data" "get-consent-status" "check-availability-of-funds" "create-signing-basket" "delete-signing-basket" "get-signing-basket" "get-signing-basket-authorisation" "start-signing-basket-authorisation" "get-signing-basket-sca-status" "update-signing-basket-psu-data" "get-signing-basket-status" "initiate-payment" "cancel-payment" "get-payment-information" "get-payment-initiation-authorisation" "start-payment-authorisation" "get-payment-initiation-sca-status" "update-payment-psu-data" "get-payment-initiation-cancellation-authorisation-information" "start-payment-initiation-cancellation-authorisation" "get-payment-cancellation-sca-status" "update-payment-cancellation-psu-data" "get-payment-initiation-status" "commands"] | sort) } | get name | first)
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

# Read account list
#
# GET /v1/accounts
# Returns: record<accounts: table<_links: record, balances: list, bban: string, bic: string, cashAccountType: string, currency: string, details: string, displayName: string, iban: string, linkedAccounts: string, msisdn: string, name: string, ownerName: string, product: string, resourceId: string, status: string, usage: string>>
# operationId: getAccountList
export def "get-account-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-balance: oneof<nothing, bool> # If contained, this function reads the list of accessible payment accounts including the booking balance, if granted by the PSU in the related consent and available by the ASPSP. This parameter might be ignored by the ASPSP.
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --consent-id: string # This then contains the consentId of the related AIS consent, which was performed prior to this payment initiation. (required)
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding HTTP request IP Address field between PSU and TPP. It shall be contained if and only if this request was actively initiated by the PSU. (format: ipv4, e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/accounts"
    query: [{name: withBalance, var: with_balance}]
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: Consent-ID, var: consent_id, required: true}, {name: PSU-IP-Address, var: psu_ip_address}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    with_balance: $with_balance, x_request_id: $x_request_id, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, consent_id: $consent_id, psu_ip_address: $psu_ip_address, psu_ip_port: $psu_ip_port, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Read account details
#
# GET /v1/accounts/{account-id}
# Returns: record<account: record<_links: record<balances: record, transactions: record>, balances: list<record>, bban: string, bic: string, cashAccountType: string, currency: string, details: string, displayName: string, iban: string, linkedAccounts: string, msisdn: string, name: string, ownerName: string, product: string, resourceId: string, status: string, usage: string>>
# operationId: readAccountDetails
export def "read-account-details" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-balance: oneof<nothing, bool> # If contained, this function reads the list of accessible payment accounts including the booking balance, if granted by the PSU in the related consent and available by the ASPSP. This parameter might be ignored by the ASPSP.
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --consent-id: string # This then contains the consentId of the related AIS consent, which was performed prior to this payment initiation. (required)
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding HTTP request IP Address field between PSU and TPP. It shall be contained if and only if this request was actively initiated by the PSU. (format: ipv4, e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/accounts/{account-id}"
    path_params: [{name: account-id, var: account_id}]
    query: [{name: withBalance, var: with_balance}]
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: Consent-ID, var: consent_id, required: true}, {name: PSU-IP-Address, var: psu_ip_address}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, with_balance: $with_balance, x_request_id: $x_request_id, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, consent_id: $consent_id, psu_ip_address: $psu_ip_address, psu_ip_port: $psu_ip_port, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Read balance
#
# GET /v1/accounts/{account-id}/balances
# Returns: record<account: record<cashAccountType: string, currency: string, iban: string, otherAccountIdentification: string>, balances: table<balanceAmount: record, balanceType: string, creditLimitIncluded: bool, lastChangeDateTime: string, lastCommittedTransaction: string, referenceDate: string>>
# operationId: getBalances
export def "get-balances" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --consent-id: string # This then contains the consentId of the related AIS consent, which was performed prior to this payment initiation. (required)
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding HTTP request IP Address field between PSU and TPP. It shall be contained if and only if this request was actively initiated by the PSU. (format: ipv4, e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/accounts/{account-id}/balances"
    path_params: [{name: account-id, var: account_id}]
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: Consent-ID, var: consent_id, required: true}, {name: PSU-IP-Address, var: psu_ip_address}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, x_request_id: $x_request_id, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, consent_id: $consent_id, psu_ip_address: $psu_ip_address, psu_ip_port: $psu_ip_port, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Read transaction list of an account
#
# GET /v1/accounts/{account-id}/transactions
# Returns: record<_links: record<download: record<href: string>>, account: record<cashAccountType: string, currency: string, iban: string, otherAccountIdentification: string>, balances: table<balanceAmount: record, balanceType: string, creditLimitIncluded: bool, lastChangeDateTime: string, lastCommittedTransaction: string, referenceDate: string>, transactions: record<_links: record<account: record, first: record, last: record, next: record, previous: record>, booked: list<record>, information: list<record>, pending: list<record>>>
# operationId: getTransactionList
export def "get-transaction-list" [
  account_id: string
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
  --date-from: string # Conditional: Starting date (inclusive the date dateFrom) of the transaction list, mandated if no delta access is required and if bookingStatus does not equal "information". For booked transactions, the relevant date is the booking date. For pending transactions, the relevant date is the entry date, which may not be transparent neither in this API nor other channels of the ASPSP. (format: date)
  --date-to: string # End date (inclusive the data dateTo) of the transaction list, default is "now" if not given. Might be ignored if a delta function is used. For booked transactions, the relevant date is the booking date. For pending transactions, the relevant date is the entry date, which may not be transparent neither in this API nor other channels of the ASPSP. (format: date)
  --entry-reference-from: string # This data attribute is indicating that the AISP is in favour to get all transactions after the transaction with identification entryReferenceFrom alternatively to the above defined period. This is a implementation of a delta access. If this data element is contained, the entries "dateFrom" and "dateTo" might be ignored by the ASPSP if a delta report is supported. Optional if supported by API provider.
  --booking-status: string@booking-status-completer # Permitted codes are * "information", * "booked", * "pending", and * "both" "booked" shall be supported by the ASPSP. To support the "pending" and "both" feature is optional for the ASPSP, Error code if not supported in the online banking frontend (required)
  --delta-list: oneof<nothing, bool> # This data attribute is indicating that the AISP is in favour to get all transactions after the last report access for this PSU on the addressed account. This is another implementation of a delta access-report. This delta indicator might be rejected by the ASPSP if this function is not supported. Optional if supported by API provider
  --with-balance: oneof<nothing, bool> # If contained, this function reads the list of accessible payment accounts including the booking balance, if granted by the PSU in the related consent and available by the ASPSP. This parameter might be ignored by the ASPSP.
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --consent-id: string # This then contains the consentId of the related AIS consent, which was performed prior to this payment initiation. (required)
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding HTTP request IP Address field between PSU and TPP. It shall be contained if and only if this request was actively initiated by the PSU. (format: ipv4, e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/accounts/{account-id}/transactions"
    path_params: [{name: account-id, var: account_id}]
    query: [{name: dateFrom, var: date_from}, {name: dateTo, var: date_to}, {name: entryReferenceFrom, var: entry_reference_from}, {name: bookingStatus, var: booking_status, required: true}, {name: deltaList, var: delta_list}, {name: withBalance, var: with_balance}]
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: Consent-ID, var: consent_id, required: true}, {name: PSU-IP-Address, var: psu_ip_address}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    accept: ["application/json", "application/xml", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, date_from: $date_from, date_to: $date_to, entry_reference_from: $entry_reference_from, booking_status: $booking_status, delta_list: $delta_list, with_balance: $with_balance, x_request_id: $x_request_id, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, consent_id: $consent_id, psu_ip_address: $psu_ip_address, psu_ip_port: $psu_ip_port, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Read transaction details
#
# GET /v1/accounts/{account-id}/transactions/{transactionId}
# Returns: record<transactionsDetails: record<transactionDetails: record<_links: record, additionalInformation: string, additionalInformationStructured: record, balanceAfterTransaction: record, bankTransactionCode: string, batchIndicator: bool, batchNumberOfTransactions: int, bookingDate: string, checkId: string, creditorAccount: record, creditorAgent: string, creditorId: string, creditorName: string, currencyExchange: list, debtorAccount: record, debtorAgent: string, debtorName: string, endToEndId: string, entryDetails: list, entryReference: string, mandateId: string, proprietaryBankTransactionCode: string, purposeCode: string, remittanceInformationStructured: string, remittanceInformationStructuredArray: list, remittanceInformationUnstructured: string, remittanceInformationUnstructuredArray: list, transactionAmount: record, transactionId: string, ultimateCreditor: string, ultimateDebtor: string, valueDate: string>>>
# operationId: getTransactionDetails
export def "get-transaction-details" [
  account_id: string
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --consent-id: string # This then contains the consentId of the related AIS consent, which was performed prior to this payment initiation. (required)
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding HTTP request IP Address field between PSU and TPP. It shall be contained if and only if this request was actively initiated by the PSU. (format: ipv4, e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/accounts/{account-id}/transactions/{transactionId}"
    path_params: [{name: account-id, var: account_id}, {name: transactionId, var: transaction_id}]
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: Consent-ID, var: consent_id, required: true}, {name: PSU-IP-Address, var: psu_ip_address}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, transaction_id: $transaction_id, x_request_id: $x_request_id, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, consent_id: $consent_id, psu_ip_address: $psu_ip_address, psu_ip_port: $psu_ip_port, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create consent
#
# POST /v1/consents
# Returns: record<_links: record<confirmation: record<href: string>, scaOAuth: record<href: string>, scaRedirect: record<href: string>, scaStatus: record<href: string>, self: record<href: string>, startAuthorisation: record<href: string>, startAuthorisationWithAuthenticationMethodSelection: record<href: string>, startAuthorisationWithEncryptedPsuAuthentication: record<href: string>, startAuthorisationWithPsuAuthentication: record<href: string>, startAuthorisationWithPsuIdentification: record<href: string>, startAuthorisationWithTransactionAuthorisation: record<href: string>, status: record<href: string>>, challengeData: record<additionalInformation: string, data: list<string>, image: string, imageLink: string, otpFormat: string, otpMaxLength: int>, chosenScaMethod: record<authenticationMethodId: string, authenticationType: string, authenticationVersion: string, explanation: string, name: string>, consentId: string, consentStatus: string, psuMessage: string, scaMethods: table<authenticationMethodId: string, authenticationType: string, authenticationVersion: string, explanation: string, name: string>>
# operationId: createConsent
export def "create-consent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --psu-id: string # Client ID of the PSU in the ASPSP client interface. Might be mandated in the ASPSP's documentation. It might be contained even if an OAuth2 based authentication was performed in a pre-step or an OAuth2 based SCA was performed in an preceding AIS service in the same session. In this case the ASPSP might check whether PSU-ID and token match, according to ASPSP documentation. (e.g. PSU-1234)
  --psu-id-type: string # Type of the PSU-ID, needed in scenarios where PSUs have several PSU-IDs as access possibility. In this case, the mean and use are then defined in the ASPSP's documentation.
  --psu-corporate-id: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-corporate-id-type: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --tpp-redirect-preferred: oneof<nothing, bool> # If it equals "true", the TPP prefers a redirect over an embedded SCA approach. If it equals "false", the TPP prefers not to be redirected for SCA. The ASPSP will then choose between the Embedded or the Decoupled SCA approach, depending on the choice of the SCA procedure by the TPP/PSU. If the parameter is not used, the ASPSP will choose the SCA approach to be applied depending on the SCA method chosen by the TPP/PSU.
  --tpp-redirect-uri: string # URI of the TPP, where the transaction flow shall be redirected to after a Redirect. Mandated for the Redirect SCA Approach, specifically when TPP-Redirect-Preferred equals "true". It is recommended to always use this header field. **Remark for Future:** This field might be changed to mandatory in the next version of the specification. (format: uri)
  --tpp-nok-redirect-uri: string # If this URI is contained, the TPP is asking to redirect the transaction flow to this address instead of the TPP-Redirect-URI in case of a negative result of the redirect SCA method. This might be ignored by the ASPSP. (format: uri)
  --tpp-explicit-authorisation-preferred: oneof<nothing, bool> # If it equals "true", the TPP prefers to start the authorisation process separately, e.g. because of the usage of a signing basket. This preference might be ignored by the ASPSP, if a signing basket is not supported as functionality. If it equals "false" or if the parameter is not used, there is no preference of the TPP. This especially indicates that the TPP assumes a direct authorisation of the transaction in the next step, without using a signing basket.
  --tpp-brand-logging-information: string # This header might be used by TPPs to inform the ASPSP about the brand used by the TPP towards the PSU. This information is meant for logging entries to enhance communication between ASPSP and PSU or ASPSP and TPP. This header might be ignored by the ASPSP.
  --tpp-notification-uri: string # URI for the Endpoint of the TPP-API to which the status of the payment initiation should be sent. This header field may by ignored by the ASPSP. For security reasons, it shall be ensured that the TPP-Notification-URI as introduced above is secured by the TPP eIDAS QWAC used for identification of the TPP. The following applies: URIs which are provided by TPPs in TPP-Notification-URI shall comply with the domain secured by the eIDAS QWAC certificate of the TPP in the field CN or SubjectAltName of the certificate. Please note that in case of example-TPP.com as certificate entry TPP- Notification-URI like www.example-TPP.com/xs2a-client/v1/ASPSPidentifcation/mytransaction- id/notifications or notifications.example-TPP.com/xs2a-client/v1/ASPSPidentifcation/mytransaction- id/notifications would be compliant. Wildcard definitions shall be taken into account for compliance checks by the ASPSP. ASPSPs may respond with ASPSP-Notification-Support set to false, if the provided URIs do not comply.
  --tpp-notification-content-preferred: string # The string has the form status=X1, ..., Xn where Xi is one of the constants SCA, PROCESS, LAST and where constants are not repeated. The usage of the constants supports the of following semantics: SCA: A notification on every change of the scaStatus attribute for all related authorisation processes is preferred by the TPP. PROCESS: A notification on all changes of consentStatus or transactionStatus attributes is preferred by the TPP. LAST: Only a notification on the last consentStatus or transactionStatus as available in the XS2A interface is preferred by the TPP. This header field may be ignored, if the ASPSP does not support resource notification services for the related TPP.
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. If not available, the TPP shall use the IP Address used by the TPP when submitting this request. (required, format: ipv4, e.g. 192.168.8.78)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
  access: record # Requested access services for a consent. — shape: {accounts?: list, additionalInformation?: record, allPsd2?: "allAccounts"|"allAccountsWithOwnerName", availableAccounts?: "allAccounts"|"allAccountsWithOwnerName", availableAccountsWithBalance?: "allAccounts"|"allAccountsWithOwnerName", balances?: list, restrictedTo?: list<string>, transactions?: list}
  --combined-service-indicator: oneof<nothing, bool> # If "true" indicates that a payment initiation service will be addressed in the same "session". (e.g. false)
  frequency_per_day: int # This field indicates the requested maximum frequency for an access without PSU involvement per day. For a one-off access, this attribute is set to "1". The frequency needs to be greater equal to one. If not otherwise agreed bilaterally between TPP and ASPSP, the frequency is less equal to 4. (e.g. 4)
  --recurring-indicator: oneof<nothing, bool> # "true", if the consent is for recurring access to the account data. "false", if the consent is for one access to the account data. (e.g. false)
  valid_until: string # This parameter is defining a valid until date (including the mentioned date) for the requested consent. The content is the local ASPSP date in ISO-Date format, e.g. 2017-10-30. Future dates might get adjusted by ASPSP. If a maximal available date is requested, a date in far future is to be used: "9999-12-31". In both cases the consent object to be retrieved by the get consent request will contain the adjusted date. (format: date, e.g. 2020-12-31)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/consents"
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: PSU-ID, var: psu_id}, {name: PSU-ID-Type, var: psu_id_type}, {name: PSU-Corporate-ID, var: psu_corporate_id}, {name: PSU-Corporate-ID-Type, var: psu_corporate_id_type}, {name: TPP-Redirect-Preferred, var: tpp_redirect_preferred}, {name: TPP-Redirect-URI, var: tpp_redirect_uri}, {name: TPP-Nok-Redirect-URI, var: tpp_nok_redirect_uri}, {name: TPP-Explicit-Authorisation-Preferred, var: tpp_explicit_authorisation_preferred}, {name: TPP-Brand-Logging-Information, var: tpp_brand_logging_information}, {name: TPP-Notification-URI, var: tpp_notification_uri}, {name: TPP-Notification-Content-Preferred, var: tpp_notification_content_preferred}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-IP-Address, var: psu_ip_address, required: true}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    body: {content_type: "application/json", kind: json, fields: [{name: access, var: access}, {name: combinedServiceIndicator, var: combined_service_indicator, required: true}, {name: frequencyPerDay, var: frequency_per_day}, {name: recurringIndicator, var: recurring_indicator, required: true}, {name: validUntil, var: valid_until}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_request_id: $x_request_id, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, psu_id: $psu_id, psu_id_type: $psu_id_type, psu_corporate_id: $psu_corporate_id, psu_corporate_id_type: $psu_corporate_id_type, tpp_redirect_preferred: $tpp_redirect_preferred, tpp_redirect_uri: $tpp_redirect_uri, tpp_nok_redirect_uri: $tpp_nok_redirect_uri, tpp_explicit_authorisation_preferred: $tpp_explicit_authorisation_preferred, tpp_brand_logging_information: $tpp_brand_logging_information, tpp_notification_uri: $tpp_notification_uri, tpp_notification_content_preferred: $tpp_notification_content_preferred, psu_ip_port: $psu_ip_port, psu_ip_address: $psu_ip_address, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location, access: $access, combined_service_indicator: $combined_service_indicator, frequency_per_day: $frequency_per_day, recurring_indicator: $recurring_indicator, valid_until: $valid_until
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Consent
#
# DELETE /v1/consents/{consentId}
# operationId: deleteConsent
export def "delete-consent" [
  consent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding HTTP request IP Address field between PSU and TPP. It shall be contained if and only if this request was actively initiated by the PSU. (format: ipv4, e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/consents/{consentId}"
    path_params: [{name: consentId, var: consent_id}]
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: PSU-IP-Address, var: psu_ip_address}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    consent_id: $consent_id, x_request_id: $x_request_id, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, psu_ip_address: $psu_ip_address, psu_ip_port: $psu_ip_port, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get consent request
#
# GET /v1/consents/{consentId}
# Returns: record<_links: record<account: record<href: string>, card-account: record<href: string>>, access: record<accounts: list<record>, additionalInformation: record<ownerName: list, trustedBeneficiaries: list>, allPsd2: string, availableAccounts: string, availableAccountsWithBalance: string, balances: list<record>, restrictedTo: list<string>, transactions: list<record>>, consentStatus: string, frequencyPerDay: int, lastActionDate: string, recurringIndicator: bool, validUntil: string>
# operationId: getConsentInformation
export def "get-consent-information" [
  consent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding HTTP request IP Address field between PSU and TPP. It shall be contained if and only if this request was actively initiated by the PSU. (format: ipv4, e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/consents/{consentId}"
    path_params: [{name: consentId, var: consent_id}]
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: PSU-IP-Address, var: psu_ip_address}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    consent_id: $consent_id, x_request_id: $x_request_id, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, psu_ip_address: $psu_ip_address, psu_ip_port: $psu_ip_port, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get consent authorisation sub-resources request
#
# GET /v1/consents/{consentId}/authorisations
# Returns: record<authorisationIds: list<string>>
# operationId: getConsentAuthorisation
export def "get-consent-authorisation" [
  consent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding HTTP request IP Address field between PSU and TPP. It shall be contained if and only if this request was actively initiated by the PSU. (format: ipv4, e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/consents/{consentId}/authorisations"
    path_params: [{name: consentId, var: consent_id}]
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: PSU-IP-Address, var: psu_ip_address}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    consent_id: $consent_id, x_request_id: $x_request_id, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, psu_ip_address: $psu_ip_address, psu_ip_port: $psu_ip_port, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start the authorisation process for a consent
#
# POST /v1/consents/{consentId}/authorisations
# Returns: record<_links: record<authoriseTransaction: record<href: string>, confirmation: record<href: string>, scaOAuth: record<href: string>, scaRedirect: record<href: string>, scaStatus: record<href: string>, selectAuthenticationMethod: record<href: string>, startAuthorisationWithEncryptedPsuAuthentication: record<href: string>, startAuthorisationWithPsuAuthentication: record<href: string>, updatePsuIdentification: record<href: string>>, authorisationId: string, challengeData: record<additionalInformation: string, data: list<string>, image: string, imageLink: string, otpFormat: string, otpMaxLength: int>, chosenScaMethod: record<authenticationMethodId: string, authenticationType: string, authenticationVersion: string, explanation: string, name: string>, psuMessage: string, scaMethods: table<authenticationMethodId: string, authenticationType: string, authenticationVersion: string, explanation: string, name: string>, scaStatus: string>
# operationId: startConsentAuthorisation
export def "start-consent-authorisation" [
  consent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --psu-id: string # Client ID of the PSU in the ASPSP client interface. Might be mandated in the ASPSP's documentation. It might be contained even if an OAuth2 based authentication was performed in a pre-step or an OAuth2 based SCA was performed in an preceding AIS service in the same session. In this case the ASPSP might check whether PSU-ID and token match, according to ASPSP documentation. (e.g. PSU-1234)
  --psu-id-type: string # Type of the PSU-ID, needed in scenarios where PSUs have several PSU-IDs as access possibility. In this case, the mean and use are then defined in the ASPSP's documentation.
  --psu-corporate-id: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-corporate-id-type: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --tpp-redirect-preferred: oneof<nothing, bool> # If it equals "true", the TPP prefers a redirect over an embedded SCA approach. If it equals "false", the TPP prefers not to be redirected for SCA. The ASPSP will then choose between the Embedded or the Decoupled SCA approach, depending on the choice of the SCA procedure by the TPP/PSU. If the parameter is not used, the ASPSP will choose the SCA approach to be applied depending on the SCA method chosen by the TPP/PSU.
  --tpp-redirect-uri: string # URI of the TPP, where the transaction flow shall be redirected to after a Redirect. Mandated for the Redirect SCA Approach, specifically when TPP-Redirect-Preferred equals "true". It is recommended to always use this header field. **Remark for Future:** This field might be changed to mandatory in the next version of the specification. (format: uri)
  --tpp-nok-redirect-uri: string # If this URI is contained, the TPP is asking to redirect the transaction flow to this address instead of the TPP-Redirect-URI in case of a negative result of the redirect SCA method. This might be ignored by the ASPSP. (format: uri)
  --tpp-notification-uri: string # URI for the Endpoint of the TPP-API to which the status of the payment initiation should be sent. This header field may by ignored by the ASPSP. For security reasons, it shall be ensured that the TPP-Notification-URI as introduced above is secured by the TPP eIDAS QWAC used for identification of the TPP. The following applies: URIs which are provided by TPPs in TPP-Notification-URI shall comply with the domain secured by the eIDAS QWAC certificate of the TPP in the field CN or SubjectAltName of the certificate. Please note that in case of example-TPP.com as certificate entry TPP- Notification-URI like www.example-TPP.com/xs2a-client/v1/ASPSPidentifcation/mytransaction- id/notifications or notifications.example-TPP.com/xs2a-client/v1/ASPSPidentifcation/mytransaction- id/notifications would be compliant. Wildcard definitions shall be taken into account for compliance checks by the ASPSP. ASPSPs may respond with ASPSP-Notification-Support set to false, if the provided URIs do not comply.
  --tpp-notification-content-preferred: string # The string has the form status=X1, ..., Xn where Xi is one of the constants SCA, PROCESS, LAST and where constants are not repeated. The usage of the constants supports the of following semantics: SCA: A notification on every change of the scaStatus attribute for all related authorisation processes is preferred by the TPP. PROCESS: A notification on all changes of consentStatus or transactionStatus attributes is preferred by the TPP. LAST: Only a notification on the last consentStatus or transactionStatus as available in the XS2A interface is preferred by the TPP. This header field may be ignored, if the ASPSP does not support resource notification services for the related TPP.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding HTTP request IP Address field between PSU and TPP. It shall be contained if and only if this request was actively initiated by the PSU. (format: ipv4, e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
  --psu-data: record # PSU Data for Update PSU authentication. — shape: {additionalEncryptedPassword?: string, additionalPassword?: string, encryptedPassword?: string, password?: string}
  --authentication-method-id: string # An identification provided by the ASPSP for the later identification of the authentication method selection. (e.g. myAuthenticationID)
  --sca-authentication-data: string # SCA authentication data, depending on the chosen authentication method. If the data is binary, then it is base64 encoded.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/consents/{consentId}/authorisations"
    path_params: [{name: consentId, var: consent_id}]
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: PSU-ID, var: psu_id}, {name: PSU-ID-Type, var: psu_id_type}, {name: PSU-Corporate-ID, var: psu_corporate_id}, {name: PSU-Corporate-ID-Type, var: psu_corporate_id_type}, {name: TPP-Redirect-Preferred, var: tpp_redirect_preferred}, {name: TPP-Redirect-URI, var: tpp_redirect_uri}, {name: TPP-Nok-Redirect-URI, var: tpp_nok_redirect_uri}, {name: TPP-Notification-URI, var: tpp_notification_uri}, {name: TPP-Notification-Content-Preferred, var: tpp_notification_content_preferred}, {name: PSU-IP-Address, var: psu_ip_address}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    body: {content_type: "application/json", kind: json, fields: [{name: psuData, var: psu_data}, {name: authenticationMethodId, var: authentication_method_id}, {name: scaAuthenticationData, var: sca_authentication_data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    consent_id: $consent_id, x_request_id: $x_request_id, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, psu_id: $psu_id, psu_id_type: $psu_id_type, psu_corporate_id: $psu_corporate_id, psu_corporate_id_type: $psu_corporate_id_type, tpp_redirect_preferred: $tpp_redirect_preferred, tpp_redirect_uri: $tpp_redirect_uri, tpp_nok_redirect_uri: $tpp_nok_redirect_uri, tpp_notification_uri: $tpp_notification_uri, tpp_notification_content_preferred: $tpp_notification_content_preferred, psu_ip_address: $psu_ip_address, psu_ip_port: $psu_ip_port, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location, psu_data: $psu_data, authentication_method_id: $authentication_method_id, sca_authentication_data: $sca_authentication_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Read the SCA status of the consent authorisation
#
# GET /v1/consents/{consentId}/authorisations/{authorisationId}
# Returns: record<psuMessage: string, scaStatus: string, trustedBeneficiaryFlag: bool>
# operationId: getConsentScaStatus
export def "get-consent-sca-status" [
  consent_id: string
  authorisation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding HTTP request IP Address field between PSU and TPP. It shall be contained if and only if this request was actively initiated by the PSU. (format: ipv4, e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/consents/{consentId}/authorisations/{authorisationId}"
    path_params: [{name: consentId, var: consent_id}, {name: authorisationId, var: authorisation_id}]
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: PSU-IP-Address, var: psu_ip_address}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    consent_id: $consent_id, authorisation_id: $authorisation_id, x_request_id: $x_request_id, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, psu_ip_address: $psu_ip_address, psu_ip_port: $psu_ip_port, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update PSU Data for consents
#
# PUT /v1/consents/{consentId}/authorisations/{authorisationId}
# operationId: updateConsentsPsuData
export def "update-consents-psu-data" [
  consent_id: string
  authorisation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --psu-id: string # Client ID of the PSU in the ASPSP client interface. Might be mandated in the ASPSP's documentation. It might be contained even if an OAuth2 based authentication was performed in a pre-step or an OAuth2 based SCA was performed in an preceding AIS service in the same session. In this case the ASPSP might check whether PSU-ID and token match, according to ASPSP documentation. (e.g. PSU-1234)
  --psu-id-type: string # Type of the PSU-ID, needed in scenarios where PSUs have several PSU-IDs as access possibility. In this case, the mean and use are then defined in the ASPSP's documentation.
  --psu-corporate-id: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-corporate-id-type: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding HTTP request IP Address field between PSU and TPP. It shall be contained if and only if this request was actively initiated by the PSU. (format: ipv4, e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
  --psu-data: record # PSU Data for Update PSU authentication. — shape: {additionalEncryptedPassword?: string, additionalPassword?: string, encryptedPassword?: string, password?: string}
  --authentication-method-id: string # An identification provided by the ASPSP for the later identification of the authentication method selection. (e.g. myAuthenticationID)
  --sca-authentication-data: string # SCA authentication data, depending on the chosen authentication method. If the data is binary, then it is base64 encoded.
  --confirmation-code: string # Confirmation Code as retrieved by the TPP from the redirect based SCA process.
]: any -> any {
  $in | http-request {
    method: put
    path: "/v1/consents/{consentId}/authorisations/{authorisationId}"
    path_params: [{name: consentId, var: consent_id}, {name: authorisationId, var: authorisation_id}]
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: PSU-ID, var: psu_id}, {name: PSU-ID-Type, var: psu_id_type}, {name: PSU-Corporate-ID, var: psu_corporate_id}, {name: PSU-Corporate-ID-Type, var: psu_corporate_id_type}, {name: PSU-IP-Address, var: psu_ip_address}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    body: {content_type: "application/json", kind: json, fields: [{name: psuData, var: psu_data}, {name: authenticationMethodId, var: authentication_method_id}, {name: scaAuthenticationData, var: sca_authentication_data}, {name: confirmationCode, var: confirmation_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    consent_id: $consent_id, authorisation_id: $authorisation_id, x_request_id: $x_request_id, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, psu_id: $psu_id, psu_id_type: $psu_id_type, psu_corporate_id: $psu_corporate_id, psu_corporate_id_type: $psu_corporate_id_type, psu_ip_address: $psu_ip_address, psu_ip_port: $psu_ip_port, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location, psu_data: $psu_data, authentication_method_id: $authentication_method_id, sca_authentication_data: $sca_authentication_data, confirmation_code: $confirmation_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Consent status request
#
# GET /v1/consents/{consentId}/status
# Returns: record<consentStatus: string, psuMessage: string>
# operationId: getConsentStatus
export def "get-consent-status" [
  consent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding HTTP request IP Address field between PSU and TPP. It shall be contained if and only if this request was actively initiated by the PSU. (format: ipv4, e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/consents/{consentId}/status"
    path_params: [{name: consentId, var: consent_id}]
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: PSU-IP-Address, var: psu_ip_address}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    consent_id: $consent_id, x_request_id: $x_request_id, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, psu_ip_address: $psu_ip_address, psu_ip_port: $psu_ip_port, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Confirmation of funds request
#
# POST /v1/funds-confirmations
# Returns: record<fundsAvailable: bool>
# operationId: checkAvailabilityOfFunds
export def "check-availability-of-funds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --authorization: string # This field might be used in case where a consent was agreed between ASPSP and PSU through an OAuth2 based protocol, facilitated by the TPP.
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  account: record # Reference to an account by either * IBAN, of a payment accounts, or * otherAccountIdentification, for payment accounts if there is no IBAN adapted from ISO pain.001.001.03.ch.02 CashAccount16-CH_IdTpCcy — shape: {cashAccountType?: string, currency?: string, iban?: string, otherAccountIdentification?: string}
  --card-number: string # Card Number of the card issued by the PIISP. Should be delivered if available.
  instructed_amount: record # e.g. {amount: 123, currency: EUR} — shape: {amount: string, currency: string}
  --payee: string # Name payee.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/funds-confirmations"
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Authorization, var: authorization}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}]
    body: {content_type: "application/json", kind: json, fields: [{name: account, var: account}, {name: cardNumber, var: card_number}, {name: instructedAmount, var: instructed_amount}, {name: payee, var: payee}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_request_id: $x_request_id, authorization: $authorization, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, account: $account, card_number: $card_number, instructed_amount: $instructed_amount, payee: $payee
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a signing basket resource
#
# POST /v1/signing-baskets
# Returns: record<_links: record<scaOAuth: record<href: string>, scaRedirect: record<href: string>, scaStatus: record<href: string>, self: record<href: string>, startAuthorisation: record<href: string>, startAuthorisationWithAuthenticationMethodSelection: record<href: string>, startAuthorisationWithEncryptedPsuAuthentication: record<href: string>, startAuthorisationWithPsuAuthentication: record<href: string>, startAuthorisationWithPsuIdentification: record<href: string>, startAuthorisationWithTransactionAuthorisation: record<href: string>, status: record<href: string>>, basketId: string, challengeData: record<additionalInformation: string, data: list<string>, image: string, imageLink: string, otpFormat: string, otpMaxLength: int>, chosenScaMethod: record<authenticationMethodId: string, authenticationType: string, authenticationVersion: string, explanation: string, name: string>, psuMessage: string, scaMethods: table<authenticationMethodId: string, authenticationType: string, authenticationVersion: string, explanation: string, name: string>, tppMessages: table<category: string, code: string, path: string, text: string>, transactionStatus: string>
# operationId: createSigningBasket
export def "create-signing-basket" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --psu-id: string # Client ID of the PSU in the ASPSP client interface. Might be mandated in the ASPSP's documentation. It might be contained even if an OAuth2 based authentication was performed in a pre-step or an OAuth2 based SCA was performed in an preceding AIS service in the same session. In this case the ASPSP might check whether PSU-ID and token match, according to ASPSP documentation. (e.g. PSU-1234)
  --psu-id-type: string # Type of the PSU-ID, needed in scenarios where PSUs have several PSU-IDs as access possibility. In this case, the mean and use are then defined in the ASPSP's documentation.
  --psu-corporate-id: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-corporate-id-type: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --consent-id: string # This data element may be contained, if the payment initiation transaction is part of a session, i.e. combined AIS/PIS service. This then contains the consentId of the related AIS consent, which was performed prior to this payment initiation.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. If not available, the TPP shall use the IP Address used by the TPP when submitting this request. (required, format: ipv4, e.g. 192.168.8.78)
  --tpp-redirect-preferred: oneof<nothing, bool> # If it equals "true", the TPP prefers a redirect over an embedded SCA approach. If it equals "false", the TPP prefers not to be redirected for SCA. The ASPSP will then choose between the Embedded or the Decoupled SCA approach, depending on the choice of the SCA procedure by the TPP/PSU. If the parameter is not used, the ASPSP will choose the SCA approach to be applied depending on the SCA method chosen by the TPP/PSU.
  --tpp-redirect-uri: string # URI of the TPP, where the transaction flow shall be redirected to after a Redirect. Mandated for the Redirect SCA Approach, specifically when TPP-Redirect-Preferred equals "true". It is recommended to always use this header field. **Remark for Future:** This field might be changed to mandatory in the next version of the specification. (format: uri)
  --tpp-nok-redirect-uri: string # If this URI is contained, the TPP is asking to redirect the transaction flow to this address instead of the TPP-Redirect-URI in case of a negative result of the redirect SCA method. This might be ignored by the ASPSP. (format: uri)
  --tpp-explicit-authorisation-preferred: oneof<nothing, bool> # If it equals "true", the TPP prefers to start the authorisation process separately, e.g. because of the usage of a signing basket. This preference might be ignored by the ASPSP, if a signing basket is not supported as functionality. If it equals "false" or if the parameter is not used, there is no preference of the TPP. This especially indicates that the TPP assumes a direct authorisation of the transaction in the next step, without using a signing basket.
  --tpp-notification-uri: string # URI for the Endpoint of the TPP-API to which the status of the payment initiation should be sent. This header field may by ignored by the ASPSP. For security reasons, it shall be ensured that the TPP-Notification-URI as introduced above is secured by the TPP eIDAS QWAC used for identification of the TPP. The following applies: URIs which are provided by TPPs in TPP-Notification-URI shall comply with the domain secured by the eIDAS QWAC certificate of the TPP in the field CN or SubjectAltName of the certificate. Please note that in case of example-TPP.com as certificate entry TPP- Notification-URI like www.example-TPP.com/xs2a-client/v1/ASPSPidentifcation/mytransaction- id/notifications or notifications.example-TPP.com/xs2a-client/v1/ASPSPidentifcation/mytransaction- id/notifications would be compliant. Wildcard definitions shall be taken into account for compliance checks by the ASPSP. ASPSPs may respond with ASPSP-Notification-Support set to false, if the provided URIs do not comply.
  --tpp-notification-content-preferred: string # The string has the form status=X1, ..., Xn where Xi is one of the constants SCA, PROCESS, LAST and where constants are not repeated. The usage of the constants supports the of following semantics: SCA: A notification on every change of the scaStatus attribute for all related authorisation processes is preferred by the TPP. PROCESS: A notification on all changes of consentStatus or transactionStatus attributes is preferred by the TPP. LAST: Only a notification on the last consentStatus or transactionStatus as available in the XS2A interface is preferred by the TPP. This header field may be ignored, if the ASPSP does not support resource notification services for the related TPP.
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
  --consent-ids: list<string> # A list of consentIds.
  --payment-ids: list<string> # A list of paymentIds.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/signing-baskets"
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: PSU-ID, var: psu_id}, {name: PSU-ID-Type, var: psu_id_type}, {name: PSU-Corporate-ID, var: psu_corporate_id}, {name: PSU-Corporate-ID-Type, var: psu_corporate_id_type}, {name: Consent-ID, var: consent_id}, {name: PSU-IP-Address, var: psu_ip_address, required: true}, {name: TPP-Redirect-Preferred, var: tpp_redirect_preferred}, {name: TPP-Redirect-URI, var: tpp_redirect_uri}, {name: TPP-Nok-Redirect-URI, var: tpp_nok_redirect_uri}, {name: TPP-Explicit-Authorisation-Preferred, var: tpp_explicit_authorisation_preferred}, {name: TPP-Notification-URI, var: tpp_notification_uri}, {name: TPP-Notification-Content-Preferred, var: tpp_notification_content_preferred}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    body: {content_type: "application/json", kind: json, fields: [{name: consentIds, var: consent_ids}, {name: paymentIds, var: payment_ids}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_request_id: $x_request_id, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, psu_id: $psu_id, psu_id_type: $psu_id_type, psu_corporate_id: $psu_corporate_id, psu_corporate_id_type: $psu_corporate_id_type, consent_id: $consent_id, psu_ip_address: $psu_ip_address, tpp_redirect_preferred: $tpp_redirect_preferred, tpp_redirect_uri: $tpp_redirect_uri, tpp_nok_redirect_uri: $tpp_nok_redirect_uri, tpp_explicit_authorisation_preferred: $tpp_explicit_authorisation_preferred, tpp_notification_uri: $tpp_notification_uri, tpp_notification_content_preferred: $tpp_notification_content_preferred, psu_ip_port: $psu_ip_port, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location, consent_ids: $consent_ids, payment_ids: $payment_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the signing basket
#
# DELETE /v1/signing-baskets/{basketId}
# operationId: deleteSigningBasket
export def "delete-signing-basket" [
  basket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (format: ipv4, e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/signing-baskets/{basketId}"
    path_params: [{name: basketId, var: basket_id}]
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: PSU-IP-Address, var: psu_ip_address}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    basket_id: $basket_id, x_request_id: $x_request_id, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, psu_ip_address: $psu_ip_address, psu_ip_port: $psu_ip_port, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the content of an signing basket object
#
# GET /v1/signing-baskets/{basketId}
# Returns: record<_links: record<scaOAuth: record<href: string>, scaRedirect: record<href: string>, scaStatus: record<href: string>, self: record<href: string>, startAuthorisation: record<href: string>, startAuthorisationWithAuthenticationMethodSelection: record<href: string>, startAuthorisationWithEncryptedPsuAuthentication: record<href: string>, startAuthorisationWithPsuAuthentication: record<href: string>, startAuthorisationWithPsuIdentification: record<href: string>, startAuthorisationWithTransactionAuthorisation: record<href: string>, status: record<href: string>>, consents: list<string>, payments: list<string>, transactionStatus: string>
# operationId: getSigningBasket
export def "get-signing-basket" [
  basket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (format: ipv4, e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/signing-baskets/{basketId}"
    path_params: [{name: basketId, var: basket_id}]
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: PSU-IP-Address, var: psu_ip_address}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    basket_id: $basket_id, x_request_id: $x_request_id, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, psu_ip_address: $psu_ip_address, psu_ip_port: $psu_ip_port, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get signing basket authorisation sub-resources request
#
# GET /v1/signing-baskets/{basketId}/authorisations
# Returns: record<authorisationIds: list<string>>
# operationId: getSigningBasketAuthorisation
export def "get-signing-basket-authorisation" [
  basket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (format: ipv4, e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/signing-baskets/{basketId}/authorisations"
    path_params: [{name: basketId, var: basket_id}]
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: PSU-IP-Address, var: psu_ip_address}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    basket_id: $basket_id, x_request_id: $x_request_id, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, psu_ip_address: $psu_ip_address, psu_ip_port: $psu_ip_port, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start the authorisation process for a signing basket
#
# POST /v1/signing-baskets/{basketId}/authorisations
# Returns: record<_links: record<authoriseTransaction: record<href: string>, confirmation: record<href: string>, scaOAuth: record<href: string>, scaRedirect: record<href: string>, scaStatus: record<href: string>, selectAuthenticationMethod: record<href: string>, startAuthorisationWithEncryptedPsuAuthentication: record<href: string>, startAuthorisationWithPsuAuthentication: record<href: string>, updatePsuIdentification: record<href: string>>, authorisationId: string, challengeData: record<additionalInformation: string, data: list<string>, image: string, imageLink: string, otpFormat: string, otpMaxLength: int>, chosenScaMethod: record<authenticationMethodId: string, authenticationType: string, authenticationVersion: string, explanation: string, name: string>, psuMessage: string, scaMethods: table<authenticationMethodId: string, authenticationType: string, authenticationVersion: string, explanation: string, name: string>, scaStatus: string>
# operationId: startSigningBasketAuthorisation
export def "start-signing-basket-authorisation" [
  basket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --psu-id: string # Client ID of the PSU in the ASPSP client interface. Might be mandated in the ASPSP's documentation. It might be contained even if an OAuth2 based authentication was performed in a pre-step or an OAuth2 based SCA was performed in an preceding AIS service in the same session. In this case the ASPSP might check whether PSU-ID and token match, according to ASPSP documentation. (e.g. PSU-1234)
  --psu-id-type: string # Type of the PSU-ID, needed in scenarios where PSUs have several PSU-IDs as access possibility. In this case, the mean and use are then defined in the ASPSP's documentation.
  --psu-corporate-id: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-corporate-id-type: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --tpp-redirect-preferred: oneof<nothing, bool> # If it equals "true", the TPP prefers a redirect over an embedded SCA approach. If it equals "false", the TPP prefers not to be redirected for SCA. The ASPSP will then choose between the Embedded or the Decoupled SCA approach, depending on the choice of the SCA procedure by the TPP/PSU. If the parameter is not used, the ASPSP will choose the SCA approach to be applied depending on the SCA method chosen by the TPP/PSU.
  --tpp-redirect-uri: string # URI of the TPP, where the transaction flow shall be redirected to after a Redirect. Mandated for the Redirect SCA Approach, specifically when TPP-Redirect-Preferred equals "true". It is recommended to always use this header field. **Remark for Future:** This field might be changed to mandatory in the next version of the specification. (format: uri)
  --tpp-nok-redirect-uri: string # If this URI is contained, the TPP is asking to redirect the transaction flow to this address instead of the TPP-Redirect-URI in case of a negative result of the redirect SCA method. This might be ignored by the ASPSP. (format: uri)
  --tpp-notification-uri: string # URI for the Endpoint of the TPP-API to which the status of the payment initiation should be sent. This header field may by ignored by the ASPSP. For security reasons, it shall be ensured that the TPP-Notification-URI as introduced above is secured by the TPP eIDAS QWAC used for identification of the TPP. The following applies: URIs which are provided by TPPs in TPP-Notification-URI shall comply with the domain secured by the eIDAS QWAC certificate of the TPP in the field CN or SubjectAltName of the certificate. Please note that in case of example-TPP.com as certificate entry TPP- Notification-URI like www.example-TPP.com/xs2a-client/v1/ASPSPidentifcation/mytransaction- id/notifications or notifications.example-TPP.com/xs2a-client/v1/ASPSPidentifcation/mytransaction- id/notifications would be compliant. Wildcard definitions shall be taken into account for compliance checks by the ASPSP. ASPSPs may respond with ASPSP-Notification-Support set to false, if the provided URIs do not comply.
  --tpp-notification-content-preferred: string # The string has the form status=X1, ..., Xn where Xi is one of the constants SCA, PROCESS, LAST and where constants are not repeated. The usage of the constants supports the of following semantics: SCA: A notification on every change of the scaStatus attribute for all related authorisation processes is preferred by the TPP. PROCESS: A notification on all changes of consentStatus or transactionStatus attributes is preferred by the TPP. LAST: Only a notification on the last consentStatus or transactionStatus as available in the XS2A interface is preferred by the TPP. This header field may be ignored, if the ASPSP does not support resource notification services for the related TPP.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (format: ipv4, e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
  --psu-data: record # PSU Data for Update PSU authentication. — shape: {additionalEncryptedPassword?: string, additionalPassword?: string, encryptedPassword?: string, password?: string}
  --authentication-method-id: string # An identification provided by the ASPSP for the later identification of the authentication method selection. (e.g. myAuthenticationID)
  --sca-authentication-data: string # SCA authentication data, depending on the chosen authentication method. If the data is binary, then it is base64 encoded.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/signing-baskets/{basketId}/authorisations"
    path_params: [{name: basketId, var: basket_id}]
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: PSU-ID, var: psu_id}, {name: PSU-ID-Type, var: psu_id_type}, {name: PSU-Corporate-ID, var: psu_corporate_id}, {name: PSU-Corporate-ID-Type, var: psu_corporate_id_type}, {name: TPP-Redirect-Preferred, var: tpp_redirect_preferred}, {name: TPP-Redirect-URI, var: tpp_redirect_uri}, {name: TPP-Nok-Redirect-URI, var: tpp_nok_redirect_uri}, {name: TPP-Notification-URI, var: tpp_notification_uri}, {name: TPP-Notification-Content-Preferred, var: tpp_notification_content_preferred}, {name: PSU-IP-Address, var: psu_ip_address}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    body: {content_type: "application/json", kind: json, fields: [{name: psuData, var: psu_data}, {name: authenticationMethodId, var: authentication_method_id}, {name: scaAuthenticationData, var: sca_authentication_data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    basket_id: $basket_id, x_request_id: $x_request_id, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, psu_id: $psu_id, psu_id_type: $psu_id_type, psu_corporate_id: $psu_corporate_id, psu_corporate_id_type: $psu_corporate_id_type, tpp_redirect_preferred: $tpp_redirect_preferred, tpp_redirect_uri: $tpp_redirect_uri, tpp_nok_redirect_uri: $tpp_nok_redirect_uri, tpp_notification_uri: $tpp_notification_uri, tpp_notification_content_preferred: $tpp_notification_content_preferred, psu_ip_address: $psu_ip_address, psu_ip_port: $psu_ip_port, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location, psu_data: $psu_data, authentication_method_id: $authentication_method_id, sca_authentication_data: $sca_authentication_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Read the SCA status of the signing basket authorisation
#
# GET /v1/signing-baskets/{basketId}/authorisations/{authorisationId}
# Returns: record<psuMessage: string, scaStatus: string, trustedBeneficiaryFlag: bool>
# operationId: getSigningBasketScaStatus
export def "get-signing-basket-sca-status" [
  basket_id: string
  authorisation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (format: ipv4, e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/signing-baskets/{basketId}/authorisations/{authorisationId}"
    path_params: [{name: basketId, var: basket_id}, {name: authorisationId, var: authorisation_id}]
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: PSU-IP-Address, var: psu_ip_address}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    basket_id: $basket_id, authorisation_id: $authorisation_id, x_request_id: $x_request_id, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, psu_ip_address: $psu_ip_address, psu_ip_port: $psu_ip_port, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update PSU data for signing basket
#
# PUT /v1/signing-baskets/{basketId}/authorisations/{authorisationId}
# operationId: updateSigningBasketPsuData
export def "update-signing-basket-psu-data" [
  basket_id: string
  authorisation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --psu-id: string # Client ID of the PSU in the ASPSP client interface. Might be mandated in the ASPSP's documentation. It might be contained even if an OAuth2 based authentication was performed in a pre-step or an OAuth2 based SCA was performed in an preceding AIS service in the same session. In this case the ASPSP might check whether PSU-ID and token match, according to ASPSP documentation. (e.g. PSU-1234)
  --psu-id-type: string # Type of the PSU-ID, needed in scenarios where PSUs have several PSU-IDs as access possibility. In this case, the mean and use are then defined in the ASPSP's documentation.
  --psu-corporate-id: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-corporate-id-type: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (format: ipv4, e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
  --psu-data: record # PSU Data for Update PSU authentication. — shape: {additionalEncryptedPassword?: string, additionalPassword?: string, encryptedPassword?: string, password?: string}
  --authentication-method-id: string # An identification provided by the ASPSP for the later identification of the authentication method selection. (e.g. myAuthenticationID)
  --sca-authentication-data: string # SCA authentication data, depending on the chosen authentication method. If the data is binary, then it is base64 encoded.
  --confirmation-code: string # Confirmation Code as retrieved by the TPP from the redirect based SCA process.
]: any -> any {
  $in | http-request {
    method: put
    path: "/v1/signing-baskets/{basketId}/authorisations/{authorisationId}"
    path_params: [{name: basketId, var: basket_id}, {name: authorisationId, var: authorisation_id}]
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: PSU-ID, var: psu_id}, {name: PSU-ID-Type, var: psu_id_type}, {name: PSU-Corporate-ID, var: psu_corporate_id}, {name: PSU-Corporate-ID-Type, var: psu_corporate_id_type}, {name: PSU-IP-Address, var: psu_ip_address}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    body: {content_type: "application/json", kind: json, fields: [{name: psuData, var: psu_data}, {name: authenticationMethodId, var: authentication_method_id}, {name: scaAuthenticationData, var: sca_authentication_data}, {name: confirmationCode, var: confirmation_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    basket_id: $basket_id, authorisation_id: $authorisation_id, x_request_id: $x_request_id, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, psu_id: $psu_id, psu_id_type: $psu_id_type, psu_corporate_id: $psu_corporate_id, psu_corporate_id_type: $psu_corporate_id_type, psu_ip_address: $psu_ip_address, psu_ip_port: $psu_ip_port, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location, psu_data: $psu_data, authentication_method_id: $authentication_method_id, sca_authentication_data: $sca_authentication_data, confirmation_code: $confirmation_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Read the status of the signing basket
#
# GET /v1/signing-baskets/{basketId}/status
# Returns: record<transactionStatus: string>
# operationId: getSigningBasketStatus
export def "get-signing-basket-status" [
  basket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --psu-id: string # Client ID of the PSU in the ASPSP client interface. Might be mandated in the ASPSP's documentation. It might be contained even if an OAuth2 based authentication was performed in a pre-step or an OAuth2 based SCA was performed in an preceding AIS service in the same session. In this case the ASPSP might check whether PSU-ID and token match, according to ASPSP documentation. (e.g. PSU-1234)
  --psu-id-type: string # Type of the PSU-ID, needed in scenarios where PSUs have several PSU-IDs as access possibility. In this case, the mean and use are then defined in the ASPSP's documentation.
  --psu-corporate-id: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-corporate-id-type: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (format: ipv4, e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/signing-baskets/{basketId}/status"
    path_params: [{name: basketId, var: basket_id}]
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: PSU-ID, var: psu_id}, {name: PSU-ID-Type, var: psu_id_type}, {name: PSU-Corporate-ID, var: psu_corporate_id}, {name: PSU-Corporate-ID-Type, var: psu_corporate_id_type}, {name: PSU-IP-Address, var: psu_ip_address}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    basket_id: $basket_id, x_request_id: $x_request_id, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, psu_id: $psu_id, psu_id_type: $psu_id_type, psu_corporate_id: $psu_corporate_id, psu_corporate_id_type: $psu_corporate_id_type, psu_ip_address: $psu_ip_address, psu_ip_port: $psu_ip_port, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Payment initiation request
#
# POST /v1/{payment-service}/{payment-product}
# Returns: record<_links: record<confirmation: record<href: string>, scaOAuth: record<href: string>, scaRedirect: record<href: string>, scaStatus: record<href: string>, self: record<href: string>, startAuthorisation: record<href: string>, startAuthorisationWithAuthenticationMethodSelection: record<href: string>, startAuthorisationWithEncryptedPsuAuthentication: record<href: string>, startAuthorisationWithPsuAuthentication: record<href: string>, startAuthorisationWithPsuIdentification: record<href: string>, startAuthorisationWithTransactionAuthorisation: record<href: string>, status: record<href: string>>, challengeData: record<additionalInformation: string, data: list<string>, image: string, imageLink: string, otpFormat: string, otpMaxLength: int>, chosenScaMethod: record<authenticationMethodId: string, authenticationType: string, authenticationVersion: string, explanation: string, name: string>, currencyConversionFee: record<amount: string, currency: string>, estimatedInterbankSettlementAmount: record<amount: string, currency: string>, estimatedTotalAmount: record<amount: string, currency: string>, paymentId: string, psuMessage: string, scaMethods: table<authenticationMethodId: string, authenticationType: string, authenticationVersion: string, explanation: string, name: string>, tppMessages: table<category: string, code: string, path: string, text: string>, transactionFeeIndicator: bool, transactionFees: record<amount: string, currency: string>, transactionStatus: string>
# operationId: initiatePayment
export def "initiate-payment" [
  payment_service: string@payment-service-completer
  payment_product: string@payment-product-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --psu-id: string # Client ID of the PSU in the ASPSP client interface. Might be mandated in the ASPSP's documentation. It might be contained even if an OAuth2 based authentication was performed in a pre-step or an OAuth2 based SCA was performed in an preceding AIS service in the same session. In this case the ASPSP might check whether PSU-ID and token match, according to ASPSP documentation. (e.g. PSU-1234)
  --psu-id-type: string # Type of the PSU-ID, needed in scenarios where PSUs have several PSU-IDs as access possibility. In this case, the mean and use are then defined in the ASPSP's documentation.
  --psu-corporate-id: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-corporate-id-type: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --consent-id: string # This data element may be contained, if the payment initiation transaction is part of a session, i.e. combined AIS/PIS service. This then contains the consentId of the related AIS consent, which was performed prior to this payment initiation.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. If not available, the TPP shall use the IP Address used by the TPP when submitting this request. (required, format: ipv4, e.g. 192.168.8.78)
  --tpp-redirect-preferred: oneof<nothing, bool> # If it equals "true", the TPP prefers a redirect over an embedded SCA approach. If it equals "false", the TPP prefers not to be redirected for SCA. The ASPSP will then choose between the Embedded or the Decoupled SCA approach, depending on the choice of the SCA procedure by the TPP/PSU. If the parameter is not used, the ASPSP will choose the SCA approach to be applied depending on the SCA method chosen by the TPP/PSU.
  --tpp-redirect-uri: string # URI of the TPP, where the transaction flow shall be redirected to after a Redirect. Mandated for the Redirect SCA Approach, specifically when TPP-Redirect-Preferred equals "true". It is recommended to always use this header field. **Remark for Future:** This field might be changed to mandatory in the next version of the specification. (format: uri)
  --tpp-nok-redirect-uri: string # If this URI is contained, the TPP is asking to redirect the transaction flow to this address instead of the TPP-Redirect-URI in case of a negative result of the redirect SCA method. This might be ignored by the ASPSP. (format: uri)
  --tpp-explicit-authorisation-preferred: oneof<nothing, bool> # If it equals "true", the TPP prefers to start the authorisation process separately, e.g. because of the usage of a signing basket. This preference might be ignored by the ASPSP, if a signing basket is not supported as functionality. If it equals "false" or if the parameter is not used, there is no preference of the TPP. This especially indicates that the TPP assumes a direct authorisation of the transaction in the next step, without using a signing basket.
  --tpp-rejection-no-funds-preferred: oneof<nothing, bool> # If it equals "true" then the TPP prefers a rejection of the payment initiation in case the ASPSP is providing an integrated confirmation of funds request an the result of this is that not sufficient funds are available. If it equals "false" then the TPP prefers that the ASPSP is dealing with the payment initiation like in the ASPSPs online channel, potentially waiting for a certain time period for funds to arrive to initiate the payment. This parameter might be ignored by the ASPSP.
  --tpp-brand-logging-information: string # This header might be used by TPPs to inform the ASPSP about the brand used by the TPP towards the PSU. This information is meant for logging entries to enhance communication between ASPSP and PSU or ASPSP and TPP. This header might be ignored by the ASPSP.
  --tpp-notification-uri: string # URI for the Endpoint of the TPP-API to which the status of the payment initiation should be sent. This header field may by ignored by the ASPSP. For security reasons, it shall be ensured that the TPP-Notification-URI as introduced above is secured by the TPP eIDAS QWAC used for identification of the TPP. The following applies: URIs which are provided by TPPs in TPP-Notification-URI shall comply with the domain secured by the eIDAS QWAC certificate of the TPP in the field CN or SubjectAltName of the certificate. Please note that in case of example-TPP.com as certificate entry TPP- Notification-URI like www.example-TPP.com/xs2a-client/v1/ASPSPidentifcation/mytransaction- id/notifications or notifications.example-TPP.com/xs2a-client/v1/ASPSPidentifcation/mytransaction- id/notifications would be compliant. Wildcard definitions shall be taken into account for compliance checks by the ASPSP. ASPSPs may respond with ASPSP-Notification-Support set to false, if the provided URIs do not comply.
  --tpp-notification-content-preferred: string # The string has the form status=X1, ..., Xn where Xi is one of the constants SCA, PROCESS, LAST and where constants are not repeated. The usage of the constants supports the of following semantics: SCA: A notification on every change of the scaStatus attribute for all related authorisation processes is preferred by the TPP. PROCESS: A notification on all changes of consentStatus or transactionStatus attributes is preferred by the TPP. LAST: Only a notification on the last consentStatus or transactionStatus as available in the XS2A interface is preferred by the TPP. This header field may be ignored, if the ASPSP does not support resource notification services for the related TPP.
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
  --charge-bearer: string@charge-bearer-completer # Charge Bearer. ChargeBearerType1Code from ISO20022.
  --creditor-account: record # Reference to an account by either * IBAN, of a payment accounts, or * otherAccountIdentification, for payment accounts if there is no IBAN adapted from ISO pain.001.001.03.ch.02 CashAccount16-CH_IdTpCcy — shape: {cashAccountType?: string, currency?: string, iban?: string, otherAccountIdentification?: string}
  --creditor-address: record # e.g. {buildingnNumber: 89, country: FR, postCode: 75000, streetName: rue blue, townName: Paris} — shape: {buildingNumber?: string, country: string, postCode?: string, streetName?: string, townName?: string}
  --creditor-agent: record # Reference to an creditorAgent by either * BIC, of the creditor bank, or * IID, of the creditor bank, or * IID and optional name and address of the creditor bank or * Name and address of the creditor bank adapted from ISO pain.001.001.03.ch.02 FinancialInstitutionIdentification7-CH — shape: {address?: record, bic?: string, iid?: record, name?: string}
  --creditor-agent-name: string # Creditor agent name. (e.g. Creditor Id 1234)
  --creditor-id: string # Identification of Creditors, e.g. a SEPA Creditor ID. (e.g. Creditor Id 5678)
  --creditor-name: string # Creditor name. (e.g. Creditor Name)
  --creditor-name-and-address: string # Creditor Name and Address in a free text field. (e.g. Max Masters, Main Street 1, 12345 City, Example Country)
  debtor_account: record # Reference to an account by either * IBAN, of a payment accounts, or * otherAccountIdentification, for payment accounts if there is no IBAN adapted from ISO pain.001.001.03.ch.02 CashAccount16-CH_IdTpCcy — shape: {cashAccountType?: string, currency?: string, iban?: string, otherAccountIdentification?: string}
  --debtor-agent: record # Reference to an debtorAgent by either * BIC, of the debtor bank, or * IID, of the debtor bank adapted from ISO pain.001.001.03.ch.02 FinancialInstitutionIdentification7-CH_BicOrClrId — shape: {bic?: string, iid?: record}
  --debtor-id: string # Debtor Id. (e.g. Debtor Id 1234)
  --debtor-name: string # Debtor name. (e.g. Debtor Name)
  --end-to-end-identification: string
  --equivalent-amount: record # e.g. {amount: 123, currency: EUR} — shape: {amount: string, currency: string}
  --exchange-rate-information: record # as in ISO pain.001.001.03.ch.02 ExchangeRateInformation1 — shape: {contractIdentification?: string, exchangeRate?: string, rateType?: "SPOT"|"SALE"|"AGRD"}
  --instructed-amount: record # e.g. {amount: 123, currency: EUR} — shape: {amount: string, currency: string}
  --intermediary-agent: string # BICFI (e.g. AAAADEBBXXX)
  --purpose-code: string@purpose-code-completer # ExternalPurpose1Code from ISO 20022. Values from ISO 20022 External Code List ExternalCodeSets_1Q2018 June 2018.
  --remittance-information-structured: record # Structured remittance information. — shape: {SCORorQRRorIPI?: "SCOR"|"QRR"|"IPI", additionalRemittanceInformation?: string, reference: string, referenceIssuer?: string, referenceType?: string}
  --remittance-information-unstructured: string # Unstructured remittance information. (e.g. Ref Number Merchant)
  --requested-execution-date: string # format: date
  --service-level: string@service-level-completer # Specifies the external service level code in the format of character string with a maximum length of 4 characters.
  --transaction-currency: string # ISO 4217 Alpha 3 currency code. (e.g. EUR)
  --ultimate-creditor: string # Ultimate creditor. (e.g. Ultimate Creditor)
  --ultimate-debtor: string # Ultimate debtor. (e.g. Ultimate Debtor)
  --day-of-execution: string@day-of-execution-completer # Day of execution as string. This string consists of up two characters. Leading zeroes are not allowed. 31 is ultimo of the month.
  --end-date: string # The last applicable day of execution. If not given, it is an infinite standing order. (format: date)
  --execution-rule: string@execution-rule-completer # "following" or "preceding" supported as values. This data attribute defines the behaviour when recurring payment dates falls on a weekend or bank holiday. The payment is then executed either the "preceding" or "following" working day. ASPSP might reject the request due to the communicated value, if rules in Online-Banking are not supporting this execution rule.
  --frequency: string@frequency-completer # The following codes from the "EventFrequency7Code" of ISO 20022 are supported: - "Daily" - "Weekly" - "EveryTwoWeeks" - "Monthly" - "EveryTwoMonths" - "Quarterly" - "SemiAnnual" - "Annual" - "MonthlyVariable"
  --start-date: string # The first applicable day of execution starting from this date is the first payment. (format: date)
  --batch-booking-preferred: oneof<nothing, bool> # If this element equals 'true', the PSU prefers only one booking entry. If this element equals 'false', the PSU prefers individual booking of all contained individual transactions. The ASPSP will follow this preference according to contracts agreed on with the PSU. (e.g. false)
  --payments: list # A list of generic JSON bodies payment initations for bulk payments via JSON. Note: Some fields from single payments do not occcur in a bulk payment element — item shape: {chargeBearer?: "DEBT"|"CRED"|"SHAR"|"SLEV", creditorAccount: record, creditorAddress?: record, creditorAgent?: record, creditorAgentName?: string, creditorId?: string, creditorName: string, creditorNameAndAddress?: string, debtorId?: string, debtorName: string, endToEndIdentification: string, equivalentAmount?: record, exchangeRateInformation?: record, instructedAmount?: record, intermediaryAgent?: string, purposeCode?: "SALA"|"PENS", remittanceInformationStructured?: record, ... (5 more fields)}
  --requested-execution-time: string # format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{payment-service}/{payment-product}"
    path_params: [{name: payment-service, var: payment_service}, {name: payment-product, var: payment_product}]
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: PSU-ID, var: psu_id}, {name: PSU-ID-Type, var: psu_id_type}, {name: PSU-Corporate-ID, var: psu_corporate_id}, {name: PSU-Corporate-ID-Type, var: psu_corporate_id_type}, {name: Consent-ID, var: consent_id}, {name: PSU-IP-Address, var: psu_ip_address, required: true}, {name: TPP-Redirect-Preferred, var: tpp_redirect_preferred}, {name: TPP-Redirect-URI, var: tpp_redirect_uri}, {name: TPP-Nok-Redirect-URI, var: tpp_nok_redirect_uri}, {name: TPP-Explicit-Authorisation-Preferred, var: tpp_explicit_authorisation_preferred}, {name: TPP-Rejection-NoFunds-Preferred, var: tpp_rejection_no_funds_preferred}, {name: TPP-Brand-Logging-Information, var: tpp_brand_logging_information}, {name: TPP-Notification-URI, var: tpp_notification_uri}, {name: TPP-Notification-Content-Preferred, var: tpp_notification_content_preferred}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    body: {content_type: "application/json", kind: json, fields: [{name: chargeBearer, var: charge_bearer}, {name: creditorAccount, var: creditor_account}, {name: creditorAddress, var: creditor_address}, {name: creditorAgent, var: creditor_agent}, {name: creditorAgentName, var: creditor_agent_name}, {name: creditorId, var: creditor_id}, {name: creditorName, var: creditor_name}, {name: creditorNameAndAddress, var: creditor_name_and_address}, {name: debtorAccount, var: debtor_account}, {name: debtorAgent, var: debtor_agent}, {name: debtorId, var: debtor_id}, {name: debtorName, var: debtor_name}, {name: endToEndIdentification, var: end_to_end_identification}, {name: equivalentAmount, var: equivalent_amount}, {name: exchangeRateInformation, var: exchange_rate_information}, {name: instructedAmount, var: instructed_amount}, {name: intermediaryAgent, var: intermediary_agent}, {name: purposeCode, var: purpose_code}, {name: remittanceInformationStructured, var: remittance_information_structured}, {name: remittanceInformationUnstructured, var: remittance_information_unstructured}, {name: requestedExecutionDate, var: requested_execution_date}, {name: serviceLevel, var: service_level}, {name: transactionCurrency, var: transaction_currency}, {name: ultimateCreditor, var: ultimate_creditor}, {name: ultimateDebtor, var: ultimate_debtor}, {name: dayOfExecution, var: day_of_execution}, {name: endDate, var: end_date}, {name: executionRule, var: execution_rule}, {name: frequency, var: frequency}, {name: startDate, var: start_date}, {name: batchBookingPreferred, var: batch_booking_preferred}, {name: payments, var: payments}, {name: requestedExecutionTime, var: requested_execution_time}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    payment_service: $payment_service, payment_product: $payment_product, x_request_id: $x_request_id, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, psu_id: $psu_id, psu_id_type: $psu_id_type, psu_corporate_id: $psu_corporate_id, psu_corporate_id_type: $psu_corporate_id_type, consent_id: $consent_id, psu_ip_address: $psu_ip_address, tpp_redirect_preferred: $tpp_redirect_preferred, tpp_redirect_uri: $tpp_redirect_uri, tpp_nok_redirect_uri: $tpp_nok_redirect_uri, tpp_explicit_authorisation_preferred: $tpp_explicit_authorisation_preferred, tpp_rejection_no_funds_preferred: $tpp_rejection_no_funds_preferred, tpp_brand_logging_information: $tpp_brand_logging_information, tpp_notification_uri: $tpp_notification_uri, tpp_notification_content_preferred: $tpp_notification_content_preferred, psu_ip_port: $psu_ip_port, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location, charge_bearer: $charge_bearer, creditor_account: $creditor_account, creditor_address: $creditor_address, creditor_agent: $creditor_agent, creditor_agent_name: $creditor_agent_name, creditor_id: $creditor_id, creditor_name: $creditor_name, creditor_name_and_address: $creditor_name_and_address, debtor_account: $debtor_account, debtor_agent: $debtor_agent, debtor_id: $debtor_id, debtor_name: $debtor_name, end_to_end_identification: $end_to_end_identification, equivalent_amount: $equivalent_amount, exchange_rate_information: $exchange_rate_information, instructed_amount: $instructed_amount, intermediary_agent: $intermediary_agent, purpose_code: $purpose_code, remittance_information_structured: $remittance_information_structured, remittance_information_unstructured: $remittance_information_unstructured, requested_execution_date: $requested_execution_date, service_level: $service_level, transaction_currency: $transaction_currency, ultimate_creditor: $ultimate_creditor, ultimate_debtor: $ultimate_debtor, day_of_execution: $day_of_execution, end_date: $end_date, execution_rule: $execution_rule, frequency: $frequency, start_date: $start_date, batch_booking_preferred: $batch_booking_preferred, payments: $payments, requested_execution_time: $requested_execution_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Payment cancellation request
#
# DELETE /v1/{payment-service}/{payment-product}/{paymentId}
# Returns: record<_links: record<startAuthorisation: record<href: string>, startAuthorisationWithAuthenticationMethodSelection: record<href: string>, startAuthorisationWithEncryptedPsuAuthentication: record<href: string>, startAuthorisationWithPsuAuthentication: record<href: string>, startAuthorisationWithPsuIdentification: record<href: string>>, challengeData: record<additionalInformation: string, data: list<string>, image: string, imageLink: string, otpFormat: string, otpMaxLength: int>, chosenScaMethod: record<authenticationMethodId: string, authenticationType: string, authenticationVersion: string, explanation: string, name: string>, scaMethods: table<authenticationMethodId: string, authenticationType: string, authenticationVersion: string, explanation: string, name: string>, transactionStatus: string>
# operationId: cancelPayment
export def "cancel-payment" [
  payment_service: string@payment-service-completer
  payment_product: string@payment-product-completer
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --tpp-redirect-preferred: oneof<nothing, bool> # If it equals "true", the TPP prefers a redirect over an embedded SCA approach. If it equals "false", the TPP prefers not to be redirected for SCA. The ASPSP will then choose between the Embedded or the Decoupled SCA approach, depending on the choice of the SCA procedure by the TPP/PSU. If the parameter is not used, the ASPSP will choose the SCA approach to be applied depending on the SCA method chosen by the TPP/PSU.
  --tpp-nok-redirect-uri: string # If this URI is contained, the TPP is asking to redirect the transaction flow to this address instead of the TPP-Redirect-URI in case of a negative result of the redirect SCA method. This might be ignored by the ASPSP. (format: uri)
  --tpp-redirect-uri: string # URI of the TPP, where the transaction flow shall be redirected to after a Redirect. Mandated for the Redirect SCA Approach, specifically when TPP-Redirect-Preferred equals "true". It is recommended to always use this header field. **Remark for Future:** This field might be changed to mandatory in the next version of the specification. (format: uri)
  --tpp-explicit-authorisation-preferred: oneof<nothing, bool> # If it equals "true", the TPP prefers to start the authorisation process separately, e.g. because of the usage of a signing basket. This preference might be ignored by the ASPSP, if a signing basket is not supported as functionality. If it equals "false" or if the parameter is not used, there is no preference of the TPP. This especially indicates that the TPP assumes a direct authorisation of the transaction in the next step, without using a signing basket.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (format: ipv4, e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/{payment-service}/{payment-product}/{paymentId}"
    path_params: [{name: payment-service, var: payment_service}, {name: payment-product, var: payment_product}, {name: paymentId, var: payment_id}]
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: TPP-Redirect-Preferred, var: tpp_redirect_preferred}, {name: TPP-Nok-Redirect-URI, var: tpp_nok_redirect_uri}, {name: TPP-Redirect-URI, var: tpp_redirect_uri}, {name: TPP-Explicit-Authorisation-Preferred, var: tpp_explicit_authorisation_preferred}, {name: PSU-IP-Address, var: psu_ip_address}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    payment_service: $payment_service, payment_product: $payment_product, payment_id: $payment_id, x_request_id: $x_request_id, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, tpp_redirect_preferred: $tpp_redirect_preferred, tpp_nok_redirect_uri: $tpp_nok_redirect_uri, tpp_redirect_uri: $tpp_redirect_uri, tpp_explicit_authorisation_preferred: $tpp_explicit_authorisation_preferred, psu_ip_address: $psu_ip_address, psu_ip_port: $psu_ip_port, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get payment information
#
# GET /v1/{payment-service}/{payment-product}/{paymentId}
# operationId: getPaymentInformation
export def "get-payment-information" [
  payment_service: string@payment-service-completer
  payment_product: string@payment-product-completer
  payment_id: string
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
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (format: ipv4, e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/{payment-service}/{payment-product}/{paymentId}"
    path_params: [{name: payment-service, var: payment_service}, {name: payment-product, var: payment_product}, {name: paymentId, var: payment_id}]
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: PSU-IP-Address, var: psu_ip_address}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    accept: ["application/json", "application/xml", "multipart/form-data"]
    ok: [200]
    auth: bearer
  } {
    payment_service: $payment_service, payment_product: $payment_product, payment_id: $payment_id, x_request_id: $x_request_id, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, psu_ip_address: $psu_ip_address, psu_ip_port: $psu_ip_port, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get payment initiation authorisation sub-resources request
#
# GET /v1/{payment-service}/{payment-product}/{paymentId}/authorisations
# Returns: record<authorisationIds: list<string>>
# operationId: getPaymentInitiationAuthorisation
export def "get-payment-initiation-authorisation" [
  payment_service: string@payment-service-completer
  payment_product: string@payment-product-completer
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (format: ipv4, e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{payment-service}/{payment-product}/{paymentId}/authorisations"
    path_params: [{name: payment-service, var: payment_service}, {name: payment-product, var: payment_product}, {name: paymentId, var: payment_id}]
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: PSU-IP-Address, var: psu_ip_address}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payment_service: $payment_service, payment_product: $payment_product, payment_id: $payment_id, x_request_id: $x_request_id, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, psu_ip_address: $psu_ip_address, psu_ip_port: $psu_ip_port, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start the authorisation process for a payment initiation
#
# POST /v1/{payment-service}/{payment-product}/{paymentId}/authorisations
# Returns: record<_links: record<authoriseTransaction: record<href: string>, confirmation: record<href: string>, scaOAuth: record<href: string>, scaRedirect: record<href: string>, scaStatus: record<href: string>, selectAuthenticationMethod: record<href: string>, startAuthorisationWithEncryptedPsuAuthentication: record<href: string>, startAuthorisationWithPsuAuthentication: record<href: string>, updatePsuIdentification: record<href: string>>, authorisationId: string, challengeData: record<additionalInformation: string, data: list<string>, image: string, imageLink: string, otpFormat: string, otpMaxLength: int>, chosenScaMethod: record<authenticationMethodId: string, authenticationType: string, authenticationVersion: string, explanation: string, name: string>, psuMessage: string, scaMethods: table<authenticationMethodId: string, authenticationType: string, authenticationVersion: string, explanation: string, name: string>, scaStatus: string>
# operationId: startPaymentAuthorisation
export def "start-payment-authorisation" [
  payment_service: string@payment-service-completer
  payment_product: string@payment-product-completer
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --psu-id: string # Client ID of the PSU in the ASPSP client interface. Might be mandated in the ASPSP's documentation. It might be contained even if an OAuth2 based authentication was performed in a pre-step or an OAuth2 based SCA was performed in an preceding AIS service in the same session. In this case the ASPSP might check whether PSU-ID and token match, according to ASPSP documentation. (e.g. PSU-1234)
  --psu-id-type: string # Type of the PSU-ID, needed in scenarios where PSUs have several PSU-IDs as access possibility. In this case, the mean and use are then defined in the ASPSP's documentation.
  --psu-corporate-id: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-corporate-id-type: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --tpp-redirect-preferred: oneof<nothing, bool> # If it equals "true", the TPP prefers a redirect over an embedded SCA approach. If it equals "false", the TPP prefers not to be redirected for SCA. The ASPSP will then choose between the Embedded or the Decoupled SCA approach, depending on the choice of the SCA procedure by the TPP/PSU. If the parameter is not used, the ASPSP will choose the SCA approach to be applied depending on the SCA method chosen by the TPP/PSU.
  --tpp-redirect-uri: string # URI of the TPP, where the transaction flow shall be redirected to after a Redirect. Mandated for the Redirect SCA Approach, specifically when TPP-Redirect-Preferred equals "true". It is recommended to always use this header field. **Remark for Future:** This field might be changed to mandatory in the next version of the specification. (format: uri)
  --tpp-nok-redirect-uri: string # If this URI is contained, the TPP is asking to redirect the transaction flow to this address instead of the TPP-Redirect-URI in case of a negative result of the redirect SCA method. This might be ignored by the ASPSP. (format: uri)
  --tpp-notification-uri: string # URI for the Endpoint of the TPP-API to which the status of the payment initiation should be sent. This header field may by ignored by the ASPSP. For security reasons, it shall be ensured that the TPP-Notification-URI as introduced above is secured by the TPP eIDAS QWAC used for identification of the TPP. The following applies: URIs which are provided by TPPs in TPP-Notification-URI shall comply with the domain secured by the eIDAS QWAC certificate of the TPP in the field CN or SubjectAltName of the certificate. Please note that in case of example-TPP.com as certificate entry TPP- Notification-URI like www.example-TPP.com/xs2a-client/v1/ASPSPidentifcation/mytransaction- id/notifications or notifications.example-TPP.com/xs2a-client/v1/ASPSPidentifcation/mytransaction- id/notifications would be compliant. Wildcard definitions shall be taken into account for compliance checks by the ASPSP. ASPSPs may respond with ASPSP-Notification-Support set to false, if the provided URIs do not comply.
  --tpp-notification-content-preferred: string # The string has the form status=X1, ..., Xn where Xi is one of the constants SCA, PROCESS, LAST and where constants are not repeated. The usage of the constants supports the of following semantics: SCA: A notification on every change of the scaStatus attribute for all related authorisation processes is preferred by the TPP. PROCESS: A notification on all changes of consentStatus or transactionStatus attributes is preferred by the TPP. LAST: Only a notification on the last consentStatus or transactionStatus as available in the XS2A interface is preferred by the TPP. This header field may be ignored, if the ASPSP does not support resource notification services for the related TPP.
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (format: ipv4, e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
  --psu-data: record # PSU Data for Update PSU authentication. — shape: {additionalEncryptedPassword?: string, additionalPassword?: string, encryptedPassword?: string, password?: string}
  --authentication-method-id: string # An identification provided by the ASPSP for the later identification of the authentication method selection. (e.g. myAuthenticationID)
  --sca-authentication-data: string # SCA authentication data, depending on the chosen authentication method. If the data is binary, then it is base64 encoded.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{payment-service}/{payment-product}/{paymentId}/authorisations"
    path_params: [{name: payment-service, var: payment_service}, {name: payment-product, var: payment_product}, {name: paymentId, var: payment_id}]
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: PSU-ID, var: psu_id}, {name: PSU-ID-Type, var: psu_id_type}, {name: PSU-Corporate-ID, var: psu_corporate_id}, {name: PSU-Corporate-ID-Type, var: psu_corporate_id_type}, {name: TPP-Redirect-Preferred, var: tpp_redirect_preferred}, {name: TPP-Redirect-URI, var: tpp_redirect_uri}, {name: TPP-Nok-Redirect-URI, var: tpp_nok_redirect_uri}, {name: TPP-Notification-URI, var: tpp_notification_uri}, {name: TPP-Notification-Content-Preferred, var: tpp_notification_content_preferred}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: PSU-IP-Address, var: psu_ip_address}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    body: {content_type: "application/json", kind: json, fields: [{name: psuData, var: psu_data}, {name: authenticationMethodId, var: authentication_method_id}, {name: scaAuthenticationData, var: sca_authentication_data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    payment_service: $payment_service, payment_product: $payment_product, payment_id: $payment_id, x_request_id: $x_request_id, psu_id: $psu_id, psu_id_type: $psu_id_type, psu_corporate_id: $psu_corporate_id, psu_corporate_id_type: $psu_corporate_id_type, tpp_redirect_preferred: $tpp_redirect_preferred, tpp_redirect_uri: $tpp_redirect_uri, tpp_nok_redirect_uri: $tpp_nok_redirect_uri, tpp_notification_uri: $tpp_notification_uri, tpp_notification_content_preferred: $tpp_notification_content_preferred, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, psu_ip_address: $psu_ip_address, psu_ip_port: $psu_ip_port, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location, psu_data: $psu_data, authentication_method_id: $authentication_method_id, sca_authentication_data: $sca_authentication_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Read the SCA status of the payment authorisation
#
# GET /v1/{payment-service}/{payment-product}/{paymentId}/authorisations/{authorisationId}
# Returns: record<psuMessage: string, scaStatus: string, trustedBeneficiaryFlag: bool>
# operationId: getPaymentInitiationScaStatus
export def "get-payment-initiation-sca-status" [
  payment_service: string@payment-service-completer
  payment_product: string@payment-product-completer
  payment_id: string
  authorisation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (format: ipv4, e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{payment-service}/{payment-product}/{paymentId}/authorisations/{authorisationId}"
    path_params: [{name: payment-service, var: payment_service}, {name: payment-product, var: payment_product}, {name: paymentId, var: payment_id}, {name: authorisationId, var: authorisation_id}]
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: PSU-IP-Address, var: psu_ip_address}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payment_service: $payment_service, payment_product: $payment_product, payment_id: $payment_id, authorisation_id: $authorisation_id, x_request_id: $x_request_id, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, psu_ip_address: $psu_ip_address, psu_ip_port: $psu_ip_port, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update PSU data for payment initiation
#
# PUT /v1/{payment-service}/{payment-product}/{paymentId}/authorisations/{authorisationId}
# operationId: updatePaymentPsuData
export def "update-payment-psu-data" [
  payment_service: string@payment-service-completer
  payment_product: string@payment-product-completer
  payment_id: string
  authorisation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --psu-id: string # Client ID of the PSU in the ASPSP client interface. Might be mandated in the ASPSP's documentation. It might be contained even if an OAuth2 based authentication was performed in a pre-step or an OAuth2 based SCA was performed in an preceding AIS service in the same session. In this case the ASPSP might check whether PSU-ID and token match, according to ASPSP documentation. (e.g. PSU-1234)
  --psu-id-type: string # Type of the PSU-ID, needed in scenarios where PSUs have several PSU-IDs as access possibility. In this case, the mean and use are then defined in the ASPSP's documentation.
  --psu-corporate-id: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-corporate-id-type: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (format: ipv4, e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
  --psu-data: record # PSU Data for Update PSU authentication. — shape: {additionalEncryptedPassword?: string, additionalPassword?: string, encryptedPassword?: string, password?: string}
  --authentication-method-id: string # An identification provided by the ASPSP for the later identification of the authentication method selection. (e.g. myAuthenticationID)
  --sca-authentication-data: string # SCA authentication data, depending on the chosen authentication method. If the data is binary, then it is base64 encoded.
  --confirmation-code: string # Confirmation Code as retrieved by the TPP from the redirect based SCA process.
]: any -> any {
  $in | http-request {
    method: put
    path: "/v1/{payment-service}/{payment-product}/{paymentId}/authorisations/{authorisationId}"
    path_params: [{name: payment-service, var: payment_service}, {name: payment-product, var: payment_product}, {name: paymentId, var: payment_id}, {name: authorisationId, var: authorisation_id}]
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: PSU-ID, var: psu_id}, {name: PSU-ID-Type, var: psu_id_type}, {name: PSU-Corporate-ID, var: psu_corporate_id}, {name: PSU-Corporate-ID-Type, var: psu_corporate_id_type}, {name: PSU-IP-Address, var: psu_ip_address}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    body: {content_type: "application/json", kind: json, fields: [{name: psuData, var: psu_data}, {name: authenticationMethodId, var: authentication_method_id}, {name: scaAuthenticationData, var: sca_authentication_data}, {name: confirmationCode, var: confirmation_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payment_service: $payment_service, payment_product: $payment_product, payment_id: $payment_id, authorisation_id: $authorisation_id, x_request_id: $x_request_id, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, psu_id: $psu_id, psu_id_type: $psu_id_type, psu_corporate_id: $psu_corporate_id, psu_corporate_id_type: $psu_corporate_id_type, psu_ip_address: $psu_ip_address, psu_ip_port: $psu_ip_port, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location, psu_data: $psu_data, authentication_method_id: $authentication_method_id, sca_authentication_data: $sca_authentication_data, confirmation_code: $confirmation_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Will deliver an array of resource identifications to all generated cancellation authorisation sub-resources
#
# GET /v1/{payment-service}/{payment-product}/{paymentId}/cancellation-authorisations
# Returns: record<authorisationIds: list<string>>
# operationId: getPaymentInitiationCancellationAuthorisationInformation
export def "get-payment-initiation-cancellation-authorisation-information" [
  payment_service: string@payment-service-completer
  payment_product: string@payment-product-completer
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (format: ipv4, e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{payment-service}/{payment-product}/{paymentId}/cancellation-authorisations"
    path_params: [{name: payment-service, var: payment_service}, {name: payment-product, var: payment_product}, {name: paymentId, var: payment_id}]
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: PSU-IP-Address, var: psu_ip_address}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payment_service: $payment_service, payment_product: $payment_product, payment_id: $payment_id, x_request_id: $x_request_id, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, psu_ip_address: $psu_ip_address, psu_ip_port: $psu_ip_port, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start the authorisation process for the cancellation of the addressed payment
#
# POST /v1/{payment-service}/{payment-product}/{paymentId}/cancellation-authorisations
# Returns: record<_links: record<authoriseTransaction: record<href: string>, confirmation: record<href: string>, scaOAuth: record<href: string>, scaRedirect: record<href: string>, scaStatus: record<href: string>, selectAuthenticationMethod: record<href: string>, startAuthorisationWithEncryptedPsuAuthentication: record<href: string>, startAuthorisationWithPsuAuthentication: record<href: string>, updatePsuIdentification: record<href: string>>, authorisationId: string, challengeData: record<additionalInformation: string, data: list<string>, image: string, imageLink: string, otpFormat: string, otpMaxLength: int>, chosenScaMethod: record<authenticationMethodId: string, authenticationType: string, authenticationVersion: string, explanation: string, name: string>, psuMessage: string, scaMethods: table<authenticationMethodId: string, authenticationType: string, authenticationVersion: string, explanation: string, name: string>, scaStatus: string>
# operationId: startPaymentInitiationCancellationAuthorisation
export def "start-payment-initiation-cancellation-authorisation" [
  payment_service: string@payment-service-completer
  payment_product: string@payment-product-completer
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --psu-id: string # Client ID of the PSU in the ASPSP client interface. Might be mandated in the ASPSP's documentation. It might be contained even if an OAuth2 based authentication was performed in a pre-step or an OAuth2 based SCA was performed in an preceding AIS service in the same session. In this case the ASPSP might check whether PSU-ID and token match, according to ASPSP documentation. (e.g. PSU-1234)
  --psu-id-type: string # Type of the PSU-ID, needed in scenarios where PSUs have several PSU-IDs as access possibility. In this case, the mean and use are then defined in the ASPSP's documentation.
  --psu-corporate-id: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-corporate-id-type: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --tpp-redirect-preferred: oneof<nothing, bool> # If it equals "true", the TPP prefers a redirect over an embedded SCA approach. If it equals "false", the TPP prefers not to be redirected for SCA. The ASPSP will then choose between the Embedded or the Decoupled SCA approach, depending on the choice of the SCA procedure by the TPP/PSU. If the parameter is not used, the ASPSP will choose the SCA approach to be applied depending on the SCA method chosen by the TPP/PSU.
  --tpp-redirect-uri: string # URI of the TPP, where the transaction flow shall be redirected to after a Redirect. Mandated for the Redirect SCA Approach, specifically when TPP-Redirect-Preferred equals "true". It is recommended to always use this header field. **Remark for Future:** This field might be changed to mandatory in the next version of the specification. (format: uri)
  --tpp-nok-redirect-uri: string # If this URI is contained, the TPP is asking to redirect the transaction flow to this address instead of the TPP-Redirect-URI in case of a negative result of the redirect SCA method. This might be ignored by the ASPSP. (format: uri)
  --tpp-notification-uri: string # URI for the Endpoint of the TPP-API to which the status of the payment initiation should be sent. This header field may by ignored by the ASPSP. For security reasons, it shall be ensured that the TPP-Notification-URI as introduced above is secured by the TPP eIDAS QWAC used for identification of the TPP. The following applies: URIs which are provided by TPPs in TPP-Notification-URI shall comply with the domain secured by the eIDAS QWAC certificate of the TPP in the field CN or SubjectAltName of the certificate. Please note that in case of example-TPP.com as certificate entry TPP- Notification-URI like www.example-TPP.com/xs2a-client/v1/ASPSPidentifcation/mytransaction- id/notifications or notifications.example-TPP.com/xs2a-client/v1/ASPSPidentifcation/mytransaction- id/notifications would be compliant. Wildcard definitions shall be taken into account for compliance checks by the ASPSP. ASPSPs may respond with ASPSP-Notification-Support set to false, if the provided URIs do not comply.
  --tpp-notification-content-preferred: string # The string has the form status=X1, ..., Xn where Xi is one of the constants SCA, PROCESS, LAST and where constants are not repeated. The usage of the constants supports the of following semantics: SCA: A notification on every change of the scaStatus attribute for all related authorisation processes is preferred by the TPP. PROCESS: A notification on all changes of consentStatus or transactionStatus attributes is preferred by the TPP. LAST: Only a notification on the last consentStatus or transactionStatus as available in the XS2A interface is preferred by the TPP. This header field may be ignored, if the ASPSP does not support resource notification services for the related TPP.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (format: ipv4, e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
  --psu-data: record # PSU Data for Update PSU authentication. — shape: {additionalEncryptedPassword?: string, additionalPassword?: string, encryptedPassword?: string, password?: string}
  --authentication-method-id: string # An identification provided by the ASPSP for the later identification of the authentication method selection. (e.g. myAuthenticationID)
  --sca-authentication-data: string # SCA authentication data, depending on the chosen authentication method. If the data is binary, then it is base64 encoded.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{payment-service}/{payment-product}/{paymentId}/cancellation-authorisations"
    path_params: [{name: payment-service, var: payment_service}, {name: payment-product, var: payment_product}, {name: paymentId, var: payment_id}]
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: PSU-ID, var: psu_id}, {name: PSU-ID-Type, var: psu_id_type}, {name: PSU-Corporate-ID, var: psu_corporate_id}, {name: PSU-Corporate-ID-Type, var: psu_corporate_id_type}, {name: TPP-Redirect-Preferred, var: tpp_redirect_preferred}, {name: TPP-Redirect-URI, var: tpp_redirect_uri}, {name: TPP-Nok-Redirect-URI, var: tpp_nok_redirect_uri}, {name: TPP-Notification-URI, var: tpp_notification_uri}, {name: TPP-Notification-Content-Preferred, var: tpp_notification_content_preferred}, {name: PSU-IP-Address, var: psu_ip_address}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    body: {content_type: "application/json", kind: json, fields: [{name: psuData, var: psu_data}, {name: authenticationMethodId, var: authentication_method_id}, {name: scaAuthenticationData, var: sca_authentication_data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    payment_service: $payment_service, payment_product: $payment_product, payment_id: $payment_id, x_request_id: $x_request_id, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, psu_id: $psu_id, psu_id_type: $psu_id_type, psu_corporate_id: $psu_corporate_id, psu_corporate_id_type: $psu_corporate_id_type, tpp_redirect_preferred: $tpp_redirect_preferred, tpp_redirect_uri: $tpp_redirect_uri, tpp_nok_redirect_uri: $tpp_nok_redirect_uri, tpp_notification_uri: $tpp_notification_uri, tpp_notification_content_preferred: $tpp_notification_content_preferred, psu_ip_address: $psu_ip_address, psu_ip_port: $psu_ip_port, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location, psu_data: $psu_data, authentication_method_id: $authentication_method_id, sca_authentication_data: $sca_authentication_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Read the SCA status of the payment cancellation's authorisation
#
# GET /v1/{payment-service}/{payment-product}/{paymentId}/cancellation-authorisations/{authorisationId}
# Returns: record<psuMessage: string, scaStatus: string, trustedBeneficiaryFlag: bool>
# operationId: getPaymentCancellationScaStatus
export def "get-payment-cancellation-sca-status" [
  payment_service: string@payment-service-completer
  payment_product: string@payment-product-completer
  payment_id: string
  authorisation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (format: ipv4, e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{payment-service}/{payment-product}/{paymentId}/cancellation-authorisations/{authorisationId}"
    path_params: [{name: payment-service, var: payment_service}, {name: payment-product, var: payment_product}, {name: paymentId, var: payment_id}, {name: authorisationId, var: authorisation_id}]
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: PSU-IP-Address, var: psu_ip_address}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payment_service: $payment_service, payment_product: $payment_product, payment_id: $payment_id, authorisation_id: $authorisation_id, x_request_id: $x_request_id, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, psu_ip_address: $psu_ip_address, psu_ip_port: $psu_ip_port, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update PSU data for payment initiation cancellation
#
# PUT /v1/{payment-service}/{payment-product}/{paymentId}/cancellation-authorisations/{authorisationId}
# operationId: updatePaymentCancellationPsuData
export def "update-payment-cancellation-psu-data" [
  payment_service: string@payment-service-completer
  payment_product: string@payment-product-completer
  payment_id: string
  authorisation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --psu-id: string # Client ID of the PSU in the ASPSP client interface. Might be mandated in the ASPSP's documentation. It might be contained even if an OAuth2 based authentication was performed in a pre-step or an OAuth2 based SCA was performed in an preceding AIS service in the same session. In this case the ASPSP might check whether PSU-ID and token match, according to ASPSP documentation. (e.g. PSU-1234)
  --psu-id-type: string # Type of the PSU-ID, needed in scenarios where PSUs have several PSU-IDs as access possibility. In this case, the mean and use are then defined in the ASPSP's documentation.
  --psu-corporate-id: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-corporate-id-type: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (format: ipv4, e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
  --psu-data: record # PSU Data for Update PSU authentication. — shape: {additionalEncryptedPassword?: string, additionalPassword?: string, encryptedPassword?: string, password?: string}
  --authentication-method-id: string # An identification provided by the ASPSP for the later identification of the authentication method selection. (e.g. myAuthenticationID)
  --sca-authentication-data: string # SCA authentication data, depending on the chosen authentication method. If the data is binary, then it is base64 encoded.
  --confirmation-code: string # Confirmation Code as retrieved by the TPP from the redirect based SCA process.
]: any -> any {
  $in | http-request {
    method: put
    path: "/v1/{payment-service}/{payment-product}/{paymentId}/cancellation-authorisations/{authorisationId}"
    path_params: [{name: payment-service, var: payment_service}, {name: payment-product, var: payment_product}, {name: paymentId, var: payment_id}, {name: authorisationId, var: authorisation_id}]
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: PSU-ID, var: psu_id}, {name: PSU-ID-Type, var: psu_id_type}, {name: PSU-Corporate-ID, var: psu_corporate_id}, {name: PSU-Corporate-ID-Type, var: psu_corporate_id_type}, {name: PSU-IP-Address, var: psu_ip_address}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    body: {content_type: "application/json", kind: json, fields: [{name: psuData, var: psu_data}, {name: authenticationMethodId, var: authentication_method_id}, {name: scaAuthenticationData, var: sca_authentication_data}, {name: confirmationCode, var: confirmation_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payment_service: $payment_service, payment_product: $payment_product, payment_id: $payment_id, authorisation_id: $authorisation_id, x_request_id: $x_request_id, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, psu_id: $psu_id, psu_id_type: $psu_id_type, psu_corporate_id: $psu_corporate_id, psu_corporate_id_type: $psu_corporate_id_type, psu_ip_address: $psu_ip_address, psu_ip_port: $psu_ip_port, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location, psu_data: $psu_data, authentication_method_id: $authentication_method_id, sca_authentication_data: $sca_authentication_data, confirmation_code: $confirmation_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Payment initiation status request
#
# GET /v1/{payment-service}/{payment-product}/{paymentId}/status
# Returns: record<fundsAvailable: bool, psuMessage: string, transactionStatus: string>
# operationId: getPaymentInitiationStatus
export def "get-payment-initiation-status" [
  payment_service: string@payment-service-completer
  payment_product: string@payment-product-completer
  payment_id: string
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
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (required, e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained. (format: byte)
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (format: ipv4, e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{payment-service}/{payment-product}/{paymentId}/status"
    path_params: [{name: payment-service, var: payment_service}, {name: payment-product, var: payment_product}, {name: paymentId, var: payment_id}]
    header: [{name: X-Request-ID, var: x_request_id, required: true}, {name: Digest, var: digest}, {name: Signature, var: signature}, {name: TPP-Signature-Certificate, var: tpp_signature_certificate}, {name: PSU-IP-Address, var: psu_ip_address}, {name: PSU-IP-Port, var: psu_ip_port}, {name: PSU-Accept, var: psu_accept}, {name: PSU-Accept-Charset, var: psu_accept_charset}, {name: PSU-Accept-Encoding, var: psu_accept_encoding}, {name: PSU-Accept-Language, var: psu_accept_language}, {name: PSU-User-Agent, var: psu_user_agent}, {name: PSU-Http-Method, var: psu_http_method}, {name: PSU-Device-ID, var: psu_device_id}, {name: PSU-Geo-Location, var: psu_geo_location}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    payment_service: $payment_service, payment_product: $payment_product, payment_id: $payment_id, x_request_id: $x_request_id, digest: $digest, signature: $signature, tpp_signature_certificate: $tpp_signature_certificate, psu_ip_address: $psu_ip_address, psu_ip_port: $psu_ip_port, psu_accept: $psu_accept, psu_accept_charset: $psu_accept_charset, psu_accept_encoding: $psu_accept_encoding, psu_accept_language: $psu_accept_language, psu_user_agent: $psu_user_agent, psu_http_method: $psu_http_method, psu_device_id: $psu_device_id, psu_geo_location: $psu_geo_location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
